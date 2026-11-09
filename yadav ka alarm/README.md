# 🚨 YADAV KA ALARM — EXTREME ANTI-SNOOZE & RUNNING PROTOCOL

यह ऐप्लिकेशन **Lovable से 100% अलग (Decoupled)** है और पूरी तरह **ऑफलाइन, नेटिव Flutter UI** और **Android Kiosk Lock Engine** पर बनी है।

---

## 📦 APK फ़ाइल का पाथ (APK File Location)
आपकी तैयार APK सीधे यहाँ उपलब्ध है:
👉 `yadav ka alarm/yadav_ka_alarm.apk`  
(या आंतरिक पाथ: `yadav ka alarm/yadav_ka_alarm/build/app/outputs/flutter-apk/app-release.apk`)

---

## ⚡ प्रमुख फ़ीचर्स (Key Features)

### 1. 🏃‍♂️ Running & Step Challenge (कदम / रनिंग ट्रैकर)
- **हार्डवेयर स्टेप सेंसर:** फ़ोन की इन-बिल्ट चिप (`Sensor.TYPE_STEP_DETECTOR` और Accelerometer Peak Detection) का उपयोग करता है।
- **लाइव ट्रैकिंग:** अलार्म बजने पर लाइव कदम (उदा. `23 / 50 Steps`) और दूरी (`0.05 KM / 3.75 KM`) स्क्रीन पर दिखती है।
- **टारगेट कस्टमाइज़ेशन:** आप 20 कदम से लेकर 5000 कदम (लगभग 3.5 से 4 KM रनिंग) तक सेट कर सकते हैं।
- जब तक पूरे कदम नहीं चले जाते, अलार्म बंद नहीं होगा!

### 2. 🧠 Maths Challenge (गणित के सवाल)
- 3 अलग-अलग जोड़/घटाव के सवाल हल करने होंगे।

### 3. 📱 Phone Shake Challenge (फ़ोन हिलाना)
- फ़ोन को 30 से 50 बार ज़ोर से हिलाने पर ही अलार्म बंद होगा।

### 4. ✍️ Motivational Typing Challenge
- प्रेरणादायक वाक्य बिना किसी गलती के टाइप करना होगा।

---

## 🛡️ एंटी-स्नूज़ और लॉक सिस्टम (Anti-Cheat Engine)
1. **वॉल्यूम ट्रैप (`onKeyDown`):** अगर कोई नींद में वॉल्यूम डाउन या म्यूट बटन दबाएगा, तो ऐप उस की (key) को रोककर वॉल्यूम वापस तुरंत **100% मैक्सिमम** कर देगी।
2. **स्क्रीन पिनिंग (`startLockTask`):** होम और रीसेंट्स बटन ब्लॉक हो जाते हैं।
3. **एंटी-एस्केप (`onUserLeaveHint`):** अगर जेस्चर से ऐप बैकग्राउंड में जाने की कोशिश करेगी, तो यह तुरंत स्क्रीन के सबसे आगे (Foreground) आ जाएगी।
4. **रीबूट प्रोटेक्शन (`BootReceiver`):** फ़ोन स्विच ऑफ करके ऑन होने पर भी सारे अलार्म्स खुद-ब-खुद वापस शेड्यूल हो जाएंगे।
5. **ऑफलाइन स्टोरेज:** सारे अलार्म्स फ़ोन की मेमोरी (`SharedPreferences`) में सुरक्षित रहते हैं।

---

## 📲 फ़ोन में इंस्टॉल और ज़रूरी सेटिंग्स (Installation & Permissions)

APK को अपने Android फ़ोन में ट्रांसफर करके इंस्टॉल करें:
1. **Unknown Sources:** "Install unknown apps" को Allow करें।
2. **Display over other apps (अन्य ऐप्स के ऊपर दिखाएं):** Allow करें।
3. **Alarms & Reminders:** Allow करें।
4. **Physical Activity / Sensors:** Allow करें (ताकि कदम गिने जा सकें)।
5. **Battery Optimization:** App Info में जाकर Battery को **"Unrestricted / No Restrictions"** पर सेट करें।
6. **Autostart (MIUI / ColorOS / FuntouchOS / OxygenOS):** Settings में जाकर "Autostart" ऑन करें।

---

## 🧪 तुरंत टेस्ट कैसे करें?
ऐप खोलें और किसी भी अलार्म कार्ड पर दिए गए **"TEST NOW"** पीले बटन को दबाएं। यह तुरंत अलार्म, सायरन, वॉल्यूम लॉक और रनिंग/स्टेप काउंटर को टेस्ट मोड में खोल देगा!

