# SPDX-License-Identifier: Apache-2.0
# Copyright (c) Maktab-e-Digital Systems Lahore
import re
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pywt
import neurokit2 as nk


LOG_FILE = "xrun.log"

N_SAMPLES = 200
FS = 200
SCALE = 8000.0
OFFSET = 2000.0

# Synthetic ECG 

np.random.seed(42)
ecg_float = nk.ecg_simulate(duration=N_SAMPLES / FS + 0.5, sampling_rate=FS,
                             heart_rate=72, noise=0.02, random_state=42)
ecg_float = ecg_float[:N_SAMPLES]
ecg_fixed = np.round(ecg_float * SCALE + OFFSET).astype(np.int32)
ecg_fixed = np.clip(ecg_fixed, -32768, 32767).astype(np.int16)
ecg = ecg_fixed.astype(np.float64)

print(f"Generated ECG: {len(ecg)} samples, range [{ecg.min():.0f}, {ecg.max():.0f}]")


# Python reference model 

cA1, cD1 = pywt.dwt(ecg, 'sym6', mode='symmetric')
cA2, cD2 = pywt.dwt(cA1, 'sym6', mode='symmetric')
cA3, cD3 = pywt.dwt(cA2, 'sym6', mode='symmetric')

ref_l1 = list(zip(np.round(cD1).astype(int), np.round(cA1).astype(int)))
ref_l2 = list(zip(np.round(cD2).astype(int), np.round(cA2).astype(int)))
ref_l3 = list(zip(np.round(cD3).astype(int), np.round(cA3).astype(int)))

print(f"Reference counts -> L1: {len(ref_l1)}, L2: {len(ref_l2)}, L3: {len(ref_l3)}")


LOG_RE = re.compile(r'^(L1|L2|L3),(-?\d+),DETAIL=(-?\d+),APPROX=(-?\d+)$', re.IGNORECASE)

def parse_log(log_text):
    streams = {"L1": [], "L2": [], "L3": []}
    for raw_line in log_text.strip().splitlines():
        m = LOG_RE.match(raw_line.strip())
        if m:
            tag, _idx, detail, approx = m.group(1).upper(), m.group(2), int(m.group(3)), int(m.group(4))
            streams[tag].append((detail, approx))
    return streams["L1"], streams["L2"], streams["L3"]

with open(LOG_FILE, "r") as f:
    log_text = f.read()

rtl_l1, rtl_l2, rtl_l3 = parse_log(log_text)
print(f"\nParsed RTL counts -> L1: {len(rtl_l1)}, L2: {len(rtl_l2)}, L3: {len(rtl_l3)}")


# ECG Reconstruction

if rtl_l1 and rtl_l2 and rtl_l3:
    rtl_cA3 = np.array([x[1] for x in rtl_l3], dtype=np.float64)
    rtl_cD3 = np.array([x[0] for x in rtl_l3], dtype=np.float64)
    rtl_cD2 = np.array([x[0] for x in rtl_l2], dtype=np.float64)
    rtl_cD1 = np.array([x[0] for x in rtl_l1], dtype=np.float64)

    n3 = min(len(rtl_cA3), len(rtl_cD3))
    recon_cA2 = pywt.idwt(rtl_cA3[:n3], rtl_cD3[:n3], 'sym6', mode='symmetric')

    n2 = min(len(recon_cA2), len(rtl_cD2))
    recon_cA1 = pywt.idwt(recon_cA2[:n2], rtl_cD2[:n2], 'sym6', mode='symmetric')

    n1 = min(len(recon_cA1), len(rtl_cD1))
    recon = pywt.idwt(recon_cA1[:n1], rtl_cD1[:n1], 'sym6', mode='symmetric')

    common_len = min(len(recon), len(ecg))
    recon = recon[:common_len]
    ecg_target = ecg[:common_len]
    data_label = "RTL"
else:
    ref_coeffs = pywt.wavedec(ecg, 'sym6', mode='symmetric', level=3)
    recon = pywt.waverec(ref_coeffs, 'sym6', mode='symmetric')[:len(ecg)]
    ecg_target = ecg
    data_label = "reference"

err = recon - ecg_target
print(f"\n{data_label} round-trip reconstruction max abs error: {np.max(np.abs(err)):.2e}")


l1_detail = np.array([x[0] for x in (rtl_l1 if rtl_l1 else ref_l1)])
l1_approx = np.array([x[1] for x in (rtl_l1 if rtl_l1 else ref_l1)])
l2_detail = np.array([x[0] for x in (rtl_l2 if rtl_l2 else ref_l2)])
l2_approx = np.array([x[1] for x in (rtl_l2 if rtl_l2 else ref_l2)])
l3_detail = np.array([x[0] for x in (rtl_l3 if rtl_l3 else ref_l3)])
l3_approx = np.array([x[1] for x in (rtl_l3 if rtl_l3 else ref_l3)])

fig, axes = plt.subplots(5, 1, figsize=(11, 14))

axes[0].plot(ecg_target, label="Original ECG (fixed-point trimmed)", color="#1f77b4", lw=1.4)
axes[0].plot(recon, label=f"Reconstructed (sym6 IDWT, {data_label})", color="#d62728", lw=1.0, linestyle="--")
axes[0].set_title(f"Original vs Reconstructed ECG ({data_label} Data)")
axes[0].legend(loc="upper right", fontsize=8)

axes[1].plot(err, color="#7f7f7f", lw=1.0)
axes[1].set_title(f"{data_label} reconstruction error (max abs = {np.max(np.abs(err)):.2e})")
axes[1].set_xlabel("Sample index")

axes[2].plot(l1_detail, color="#2ca02c", lw=1.0, label=f"L1 detail ({data_label})")
axes[2].plot(l1_approx, color="#9467bd", lw=1.0, alpha=0.7, label=f"L1 approx ({data_label})")
axes[2].set_title(f"Level 1 subbands ({data_label}, n={len(l1_detail)})")
axes[2].legend(loc="upper right", fontsize=8)

axes[3].plot(l2_detail, color="#2ca02c", lw=1.0, label=f"L2 detail ({data_label})")
axes[3].plot(l2_approx, color="#9467bd", lw=1.0, alpha=0.7, label=f"L2 approx ({data_label})")
axes[3].set_title(f"Level 2 subbands ({data_label}, n={len(l2_detail)})")
axes[3].legend(loc="upper right", fontsize=8)

axes[4].plot(l3_detail, color="#2ca02c", lw=1.0, label=f"L3 detail ({data_label})")
axes[4].plot(l3_approx, color="#9467bd", lw=1.0, alpha=0.7, label=f"L3 approx ({data_label})")
axes[4].set_title(f"Level 3 subbands ({data_label}, n={len(l3_detail)})")
axes[4].legend(loc="upper right", fontsize=8)
axes[4].set_xlabel("Sample index")

plt.tight_layout()
plt.savefig("ecg_dwt_verification.png", dpi=130)
print("\nSaved plot: ecg_dwt_verification.png")
