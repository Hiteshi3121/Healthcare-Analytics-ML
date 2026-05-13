# =============================================================================
# risk_model2_app.py  —  PRODUCTION VERSION
# =============================================================================
# This app ONLY loads pre-trained models from the models/ folder.
# It never trains anything. Results are always in sync with the notebook.
#
# Folder structure required:
#   your_project/
#   ├── risk_model2_app.py          ← this file
#   └── models/
#       ├── rf_model.pkl
#       ├── knn_model.pkl
#       ├── dt_model.pkl
#       ├── nb_model.pkl
#       ├── scaler.pkl
#       ├── label_encoder_diagnosis.pkl
#       └── model_metadata.pkl
#
# Run:
#   streamlit run risk_model2_app.py
# =============================================================================

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import os
import warnings
warnings.filterwarnings('ignore')

from sklearn.metrics import ConfusionMatrixDisplay
from sklearn.tree import plot_tree

# ─────────────────────────────────────────────────────────────────────────────
# PAGE CONFIG
# ─────────────────────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Healthcare Risk Prediction",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ─────────────────────────────────────────────────────────────────────────────
# STYLING
# ─────────────────────────────────────────────────────────────────────────────
st.markdown("""
<style>
    .main-title  { font-size:2.1rem; font-weight:700; color:#1a5276; text-align:center; margin-bottom:.1rem; }
    .sub-title   { font-size:.95rem; color:#666; text-align:center; margin-bottom:1.2rem; }
    .section-head { font-size:1.2rem; font-weight:600; color:#1a5276;
                    border-bottom:2px solid #2980b9; padding-bottom:4px; margin-top:1.2rem; }
    .risk-high { background:#fdecea; border-left:5px solid #e74c3c;
                 padding:16px 20px; border-radius:8px; }
    .risk-low  { background:#eafaf1; border-left:5px solid #27ae60;
                 padding:16px 20px; border-radius:8px; }
    .sidebar-note { background:#eaf4fb; border-radius:6px; padding:10px 12px;
                    font-size:.82rem; color:#2c3e50; margin-top:.5rem; }
    div[data-testid="stButton"] > button {
        background:#2980b9; color:white; border-radius:6px;
        font-size:1rem; padding:10px 0; width:100%;
    }
    div[data-testid="stButton"] > button:hover { background:#1a5276; }
</style>
""", unsafe_allow_html=True)

# ─────────────────────────────────────────────────────────────────────────────
# LOAD PRE-TRAINED ARTIFACTS
# ─────────────────────────────────────────────────────────────────────────────
MODELS_DIR = 'models'

@st.cache_resource(show_spinner="Loading trained models …")
def load_artifacts():
    required = [
        'rf_model.pkl', 'knn_model.pkl', 'dt_model.pkl', 'nb_model.pkl',
        'scaler.pkl', 'label_encoder_diagnosis.pkl', 'model_metadata.pkl'
    ]
    missing = [f for f in required if not os.path.exists(os.path.join(MODELS_DIR, f))]
    if missing:
        return None, missing
    return {
        'rf':      joblib.load(f'{MODELS_DIR}/rf_model.pkl'),
        'knn':     joblib.load(f'{MODELS_DIR}/knn_model.pkl'),
        'dt':      joblib.load(f'{MODELS_DIR}/dt_model.pkl'),
        'nb':      joblib.load(f'{MODELS_DIR}/nb_model.pkl'),
        'scaler':  joblib.load(f'{MODELS_DIR}/scaler.pkl'),
        'diag_le': joblib.load(f'{MODELS_DIR}/label_encoder_diagnosis.pkl'),
        'meta':    joblib.load(f'{MODELS_DIR}/model_metadata.pkl'),
    }, []

artifacts, missing_files = load_artifacts()

# Guard: models not trained yet
if artifacts is None:
    st.error("⚠️ Trained model files not found. Please run the training script first:")
    st.code("python train_and_save_models.py", language="bash")
    st.write("**Missing files:**")
    for f in missing_files:
        st.write(f"  • `models/{f}`")
    st.stop()

# Unpack
meta              = artifacts['meta']
FEATURES          = meta['features']
diagnosis_classes = meta['diagnosis_classes']
y_test            = np.array(meta['y_test'])
MODEL_KEYS        = ['Random Forest', 'KNN', 'Decision Tree', 'Naive Bayes']
MODEL_COLORS      = {
    'Random Forest': '#2ecc71', 'KNN': '#3498db',
    'Decision Tree': '#e67e22', 'Naive Bayes': '#9b59b6'
}

# ─────────────────────────────────────────────────────────────────────────────
# SIDEBAR
# ─────────────────────────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("## ⚙️ Settings")
    selected_model = st.selectbox("Prediction model", MODEL_KEYS)
    st.markdown("---")
    st.markdown("### 📊 Model Accuracies")
    for m in MODEL_KEYS:
        acc = meta[m]['accuracy']
        st.write(f"**{m}:** {acc:.1f}%")
    st.markdown("---")
    st.markdown("### ℹ️ About")
    st.markdown(
        '<div class="sidebar-note">'
        'Production app — models are pre-trained and saved as <code>.pkl</code> files. '
        'Results are always in sync with <b>Risk_Model2.ipynb</b>.'
        '</div>',
        unsafe_allow_html=True
    )

# ─────────────────────────────────────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────────────────────────────────────
st.markdown('<p class="main-title">🏥 Healthcare Risk Prediction</p>', unsafe_allow_html=True)
st.markdown(
    '<p class="sub-title">Production app · Pre-trained models: Random Forest · KNN · Decision Tree · Naive Bayes</p>',
    unsafe_allow_html=True
)

# ─────────────────────────────────────────────────────────────────────────────
# TABS
# ─────────────────────────────────────────────────────────────────────────────
tab1, tab2, tab3 = st.tabs(["🔮  Predict Patient Risk", "📊  Model Performance", "📈  Model Comparison"])

# ══════════════════════════════════════════════════════════════════════════════
# TAB 1 — PREDICTION
# ══════════════════════════════════════════════════════════════════════════════
with tab1:
    st.markdown('<p class="section-head">Enter Patient Details</p>', unsafe_allow_html=True)

    c1, c2, c3 = st.columns(3)
    with c1:
        age            = st.number_input("🧑 Age", 0, 120, 45)
        length_of_stay = st.number_input("🛏️ Length of Stay (days)", 0, 365, 5)
        treatment_cost = st.number_input("💰 Treatment Cost (Rs.)", 0.0, value=5000.0, step=500.0)
    with c2:
        abnormal_lab = st.number_input("🧪 Abnormal Lab Count", 0, 20, 2)
        gender       = st.selectbox("⚧ Gender", ["Male", "Female"])
    with c3:
        diagnosis_name = st.selectbox("🩺 Diagnosis", diagnosis_classes)
        st.markdown("<br>", unsafe_allow_html=True)
        st.info(f"**Active model:** {selected_model}  \n**Accuracy:** {meta[selected_model]['accuracy']:.1f}%")

    st.markdown("---")
    predict_btn = st.button("🔮 Predict Risk", use_container_width=True)

    if predict_btn:
        # Encode inputs
        gender_enc = 1 if gender == "Male" else 0
        try:
            diag_enc = artifacts['diag_le'].transform([diagnosis_name])[0]
        except Exception:
            diag_enc = diagnosis_classes.index(diagnosis_name)

        input_df = pd.DataFrame([[
            age, length_of_stay, treatment_cost, abnormal_lab,
            gender_enc, diag_enc
        ]], columns=FEATURES)
        input_sc = pd.DataFrame(
            artifacts['scaler'].transform(input_df), columns=FEATURES
        )

        # Select correct model & input format
        model_input_map = {
            'Random Forest': (artifacts['rf'],  input_df),   # RF: raw features
            'KNN':           (artifacts['knn'], input_sc),   # others: scaled
            'Decision Tree': (artifacts['dt'],  input_sc),
            'Naive Bayes':   (artifacts['nb'],  input_sc),
        }
        model_obj, X_in = model_input_map[selected_model]
        prediction  = model_obj.predict(X_in)[0]
        probability = model_obj.predict_proba(X_in)[0][1]

        # Result layout
        st.markdown("### 🧾 Prediction Result")
        r1, r2, r3 = st.columns([1.2, 1.2, 1])

        with r1:
            if prediction == 1:
                st.markdown(
                    f'<div class="risk-high"><h3>🚨 HIGH RISK</h3>'
                    f'Risk probability: <b>{probability*100:.1f}%</b><br>'
                    f'Model: <b>{selected_model}</b></div>',
                    unsafe_allow_html=True
                )
            else:
                st.markdown(
                    f'<div class="risk-low"><h3>✅ LOW RISK</h3>'
                    f'Risk probability: <b>{probability*100:.1f}%</b><br>'
                    f'Model: <b>{selected_model}</b></div>',
                    unsafe_allow_html=True
                )

        with r2:
            fig_g, ax_g = plt.subplots(figsize=(4.5, 2))
            bar_color = '#e74c3c' if probability > 0.5 else '#27ae60'
            ax_g.barh([''], [probability],     color=bar_color, height=0.4)
            ax_g.barh([''], [1 - probability], left=[probability],
                       color='#ecf0f1', height=0.4)
            ax_g.axvline(0.5, color='black', linestyle='--', linewidth=1.2,
                          label='Threshold 0.5')
            ax_g.set_xlim(0, 1)
            ax_g.set_xlabel('Predicted Probability of High Risk')
            ax_g.set_title('Risk Gauge', fontsize=10, fontweight='bold')
            ax_g.text(probability / 2, 0, f'{probability*100:.1f}%',
                       ha='center', va='center', color='white',
                       fontsize=9, fontweight='bold')
            ax_g.legend(fontsize=7, loc='upper right')
            fig_g.tight_layout()
            st.pyplot(fig_g)
            plt.close(fig_g)

        with r3:
            st.markdown("**Patient Summary**")
            for k, v in {
                "Age": age, "LOS (days)": length_of_stay,
                "Cost (Rs.)": f"{treatment_cost:,.0f}",
                "Abnormal Labs": abnormal_lab,
                "Gender": gender, "Diagnosis": diagnosis_name,
            }.items():
                st.write(f"**{k}:** {v}")

        # Risk flags
        flags = []
        if age > 65:            flags.append(f"Age {age} > 65")
        if length_of_stay > 7:  flags.append(f"LOS {length_of_stay} > 7 days")
        if abnormal_lab > 3:    flags.append(f"{abnormal_lab} abnormal labs")
        if flags:
            st.warning("⚠️ Risk flags: " + " · ".join(flags))

        # All-models quick view for this patient
        st.markdown("---")
        st.markdown("**📋 All models on this patient:**")
        cols = st.columns(4)
        for i, (mname, (mobj, xinp)) in enumerate(model_input_map.items()):
            pred_i = mobj.predict(xinp)[0]
            prob_i = mobj.predict_proba(xinp)[0][1]
            icon   = "🚨" if pred_i == 1 else "✅"
            with cols[i]:
                st.metric(
                    label=mname,
                    value=f"{icon} {'High' if pred_i==1 else 'Low'}",
                    delta=f"{prob_i*100:.1f}% risk"
                )

# ══════════════════════════════════════════════════════════════════════════════
# TAB 2 — MODEL PERFORMANCE
# ══════════════════════════════════════════════════════════════════════════════
with tab2:
    st.markdown('<p class="section-head">Model Performance Details</p>', unsafe_allow_html=True)

    perf_model = st.selectbox("Select model", MODEL_KEYS, key='perf_sel')
    res = meta[perf_model]

    m1, m2, m3, m4 = st.columns(4)
    m1.metric("Accuracy",              f"{res['accuracy']:.1f}%")
    m2.metric("Precision (High Risk)", f"{res['report']['High Risk']['precision']*100:.1f}%")
    m3.metric("Recall (High Risk)",    f"{res['report']['High Risk']['recall']*100:.1f}%")
    m4.metric("F1 Score (High Risk)",  f"{res['report']['High Risk']['f1-score']*100:.1f}%")

    col_a, col_b = st.columns(2)

    with col_a:
        fig_cm, ax_cm = plt.subplots(figsize=(5, 4))
        ConfusionMatrixDisplay(
            confusion_matrix=np.array(res['cm']),
            display_labels=['Low Risk', 'High Risk']
        ).plot(cmap='Blues', ax=ax_cm, colorbar=False)
        ax_cm.set_title(f'Confusion Matrix — {perf_model}', fontweight='bold')
        fig_cm.tight_layout()
        st.pyplot(fig_cm)
        plt.close(fig_cm)

    with col_b:
        fig_roc, ax_roc = plt.subplots(figsize=(5, 4))
        ax_roc.plot(res['fpr'], res['tpr'], color=MODEL_COLORS[perf_model],
                     lw=2, label=f"AUC = {res['auc']:.2f}")
        ax_roc.plot([0, 1], [0, 1], 'r--', lw=1.5, label='Random')
        ax_roc.set_xlabel('False Positive Rate')
        ax_roc.set_ylabel('True Positive Rate')
        ax_roc.set_title(f'ROC Curve — {perf_model}', fontweight='bold')
        ax_roc.legend(loc='lower right')
        fig_roc.tight_layout()
        st.pyplot(fig_roc)
        plt.close(fig_roc)

    # Model-specific bonus plots
    st.markdown("---")
    if perf_model == 'Random Forest':
        st.markdown("**🌲 Feature Importance**")
        feat_imp = pd.Series(
            np.array(meta['rf_importances']), index=FEATURES
        ).sort_values(ascending=False)
        fig_fi, ax_fi = plt.subplots(figsize=(8, 4))
        sns.barplot(x=feat_imp.values, y=feat_imp.index, ax=ax_fi, palette='Blues_r')
        ax_fi.set_title("Feature Importance — Random Forest", fontweight='bold')
        ax_fi.set_xlabel("Importance Score")
        fig_fi.tight_layout()
        st.pyplot(fig_fi)
        plt.close(fig_fi)

    elif perf_model == 'KNN':
        st.markdown(f"**📐 K vs CV Accuracy  (best k = {meta['best_k']})**")
        fig_k, ax_k = plt.subplots(figsize=(8, 4))
        ax_k.plot(meta['k_range'], [s * 100 for s in meta['k_scores']],
                   marker='o', color='steelblue', lw=2, markersize=4)
        ax_k.axvline(meta['best_k'], color='red', linestyle='--',
                      label=f"Best k = {meta['best_k']}")
        ax_k.set_xlabel('Number of Neighbours (k)')
        ax_k.set_ylabel('CV Accuracy (%)')
        ax_k.set_title('KNN: Choosing the Best k', fontweight='bold')
        ax_k.legend()
        fig_k.tight_layout()
        st.pyplot(fig_k)
        plt.close(fig_k)

    elif perf_model == 'Decision Tree':
        st.markdown("**🌳 Decision Tree Structure**")
        fig_dt, ax_dt = plt.subplots(figsize=(22, 9))
        plot_tree(
            artifacts['dt'], feature_names=FEATURES,
            class_names=['Low Risk', 'High Risk'],
            filled=True, rounded=True, fontsize=7, ax=ax_dt
        )
        ax_dt.set_title("Decision Tree (max_depth=6)", fontsize=13, fontweight='bold')
        fig_dt.tight_layout()
        st.pyplot(fig_dt)
        plt.close(fig_dt)

    elif perf_model == 'Naive Bayes':
        st.markdown("**📊 Predicted Probability Distribution**")
        nb_prob_arr = np.array(meta['nb_prob'])
        fig_nb, ax_nb = plt.subplots(figsize=(8, 4))
        ax_nb.hist(nb_prob_arr[y_test == 0], bins=25, alpha=0.6,
                    color='steelblue', label='Low Risk (actual)')
        ax_nb.hist(nb_prob_arr[y_test == 1], bins=25, alpha=0.6,
                    color='salmon', label='High Risk (actual)')
        ax_nb.axvline(0.5, color='black', linestyle='--', label='Decision boundary')
        ax_nb.set_xlabel('Predicted Probability of High Risk')
        ax_nb.set_ylabel('Count')
        ax_nb.set_title('Naive Bayes: Probability Distribution', fontweight='bold')
        ax_nb.legend()
        fig_nb.tight_layout()
        st.pyplot(fig_nb)
        plt.close(fig_nb)

# ══════════════════════════════════════════════════════════════════════════════
# TAB 3 — MODEL COMPARISON
# ══════════════════════════════════════════════════════════════════════════════
with tab3:
    st.markdown('<p class="section-head">All-Models Comparison</p>', unsafe_allow_html=True)

    col_x, col_y = st.columns(2)

    with col_x:
        fig_bar, ax_bar = plt.subplots(figsize=(6, 4))
        accuracies = [meta[m]['accuracy'] for m in MODEL_KEYS]
        bars = ax_bar.bar(
            MODEL_KEYS, accuracies,
            color=[MODEL_COLORS[m] for m in MODEL_KEYS],
            edgecolor='black', linewidth=0.7
        )
        ax_bar.set_ylim([50, 105])
        ax_bar.set_ylabel('Accuracy (%)')
        ax_bar.set_title('Model Accuracy Comparison', fontweight='bold')
        ax_bar.tick_params(axis='x', rotation=15)
        for bar, acc in zip(bars, accuracies):
            ax_bar.text(
                bar.get_x() + bar.get_width() / 2,
                bar.get_height() + 0.4,
                f'{acc:.1f}%', ha='center', va='bottom',
                fontweight='bold', fontsize=9
            )
        fig_bar.tight_layout()
        st.pyplot(fig_bar)
        plt.close(fig_bar)

    with col_y:
        fig_roc2, ax_roc2 = plt.subplots(figsize=(6, 4))
        for m in MODEL_KEYS:
            ax_roc2.plot(
                meta[m]['fpr'], meta[m]['tpr'],
                label=f"{m} (AUC={meta[m]['auc']:.2f})",
                color=MODEL_COLORS[m], lw=2
            )
        ax_roc2.plot([0, 1], [0, 1], 'k--', lw=1.5, label='Random')
        ax_roc2.set_xlabel('False Positive Rate')
        ax_roc2.set_ylabel('True Positive Rate')
        ax_roc2.set_title('ROC Curves — All Models', fontweight='bold')
        ax_roc2.legend(loc='lower right', fontsize=8)
        fig_roc2.tight_layout()
        st.pyplot(fig_roc2)
        plt.close(fig_roc2)

    st.markdown("### 📋 Summary Table")
    summary_df = pd.DataFrame([{
        'Model':     m,
        'Accuracy':  f"{meta[m]['accuracy']:.2f}%",
        'Precision': f"{meta[m]['report']['High Risk']['precision']*100:.2f}%",
        'Recall':    f"{meta[m]['report']['High Risk']['recall']*100:.2f}%",
        'F1 Score':  f"{meta[m]['report']['High Risk']['f1-score']*100:.2f}%",
        'AUC':       f"{meta[m]['auc']:.3f}",
    } for m in MODEL_KEYS]).sort_values('Accuracy', ascending=False).reset_index(drop=True)

    st.dataframe(summary_df, use_container_width=True)
    best_model = summary_df.iloc[0]['Model']
    best_acc   = summary_df.iloc[0]['Accuracy']
    st.success(f"🏆 Best Model: **{best_model}** with accuracy **{best_acc}**")