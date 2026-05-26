# Mainline Kernel Status: Motorola Kiev (SM7225)

## Overview
Final documented state of the Linux Mainline (Kernel 7.0) bringup for the Motorola Kiev (Moto G 5G). The project has been paused/abandoned due to insurmountable architectural limitations without massive modifications to the kernel's C code.

- **Author:** anyeloxd13 <anyeloxd13@gmail.com>
- **Architecture:** arm64
- **SoC:** Qualcomm Snapdragon 750G (SM7225 / Lagoon)
- **Kernel:** 7.0.0-dirty (Mainline)

## Final Component Status (Hardware Bringup)

| Component | Status | Notes / Block Cause |
|-----------|--------|-------|
| **CPU / UART** | 🟢 OK | Functional serial console (`ttyMSM0` @ 115200n8). |
| **UFS Storage** | 🟢 OK | Fully functional. Operational rootfs mount with LDO12/LDO7. |
| **IOMMU (SMMU)** | 🟢 OK | Functional. `apps_smmu` re-enabled by restoring `qcom,msa-fixed-perm` permissions. |
| **Remoteproc (pd-mapper)** | 🟢 OK | Operational. Slave processors (Modem/WLAN) load their blobs from `/lib/firmware/qcom/sm7225`. |
| **Wi-Fi (`wlan0`)** | 🔴 ABANDONED | **Firmware/WMI Blocker.** The generic Linux driver (`ath10k_snoc`) brings up the physical chip but fatally crashes (hard reboot) during the WMI handshake. This occurs because the signed Motorola firmware (`wlanmdsp.mbn`) requires the proprietary Android implementation (`qcacld-3.0`). |
| **USB (`dwc3`)** | 🔴 ABANDONED | **Electrical/Quirks Blocker (C).** The controller starts and ConfigFS binds, but endpoints fail with timeout (`failed to enable ep0out`). The DWC3 hangs infinitely waiting for the `utmi_clk` clock. The `qusb2` PHY requires very specific voltages (1.8V and 3.075V) and a hexadecimal calibration matrix that the Mainline driver completely ignores unless its internal C code is reprogrammed. Modifying the regulators in the DTS caused a panic in RPMh (error -131), destroying UFS support. |

---

## Kiev (SM7225) Specific Hardware Quirks

### 1. Absence of SuperSpeed USB
Motorola crippled the port physically and logically. The QMP PHY (`usb_1_qmpphy`) is unused, leaving the device tied to USB 2.0 (High-Speed) via the QUSB2 PHY.

### 2. VBUS Detection (Blind)
The hardware lacks generic Type-C controllers. It relies entirely on hacks like `qcom,vbus-valid-override` in the Android driver or `UTMI_OTG_VBUS_VALID` injected via software.

### 3. Power Management Sensitivity (RPMh)
Any attempt to force fixed voltages on LDO2 (PLL) or LDO3 (PHY DPDM) from the Device Tree causes the PMIC arbiter to abort its initialization (error -131). When the PMIC crashes, all dependent regulators die, taking UFS storage with them and crashing the system.

## Notes for Future Developers
If anyone resumes this bringup, the viable solutions are:
1. **For Wi-Fi:** Port or package the CAF `qcacld-3.0` driver *out-of-tree*, or reverse-engineer the Motorola WMI commands so `ath10k` tolerates them.
2. **For USB:** Write a native C patch (`drivers/phy/qualcomm/phy-qcom-qusb2.c`) that introduces the `"qcom,sm7225-qusb2-phy"` compatible string, defines the Motorola register injection table, and makes manual API calls to `regulator_set_voltage()` to power up LDO2 and LDO3 without crashing the Device Tree.
