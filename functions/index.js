const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// 👉 Gmail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com", // 📌 ใส่อีเมล Gmail ของคุณ
    pass: "your-app-password", // 📌 ใส่ App Password (ไม่ใช่รหัส Gmail ปกติ)
  },
});

/**
 * ✅ สร้าง OTP 6 หลักแบบสุ่ม
 * @return {string} OTP
 */
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * ✅ ฟังก์ชันส่ง OTP ไปยังอีเมล
 * @param {Object} req - HTTP request object
 * @param {Object} res - HTTP response object
 */
exports.sendOtp = functions.https.onRequest(async (req, res) => {
  const {email} = req.body;

  if (!email) {
    return res.status(400).send({error: "Email is required"});
  }

  const otp = generateOtp();

  try {
    await transporter.sendMail({
      from: "your-email@gmail.com",
      to: email,
      subject: "Your OTP Code",
      text: `Your OTP code is: ${otp}`,
    });

    return res.status(200).send({message: "OTP sent", otp});
  } catch (error) {
    console.error("Error sending OTP:", error);
    return res.status(500).send({error: "Failed to send OTP"});
  }
});

/**
 * ✅ ฟังก์ชันรีเซ็ตรหัสผ่านด้วย OTP
 * @param {Object} req - HTTP request object
 * @param {Object} res - HTTP response object
 */
exports.resetPassword = functions.https.onRequest(async (req, res) => {
  const {email, newPassword} = req.body;

  if (!email || !newPassword) {
    return res.status(400).send({error: "Email and newPassword are required"});
  }

  try {
    // 📌 TODO: เพิ่ม logic เช็ค OTP ก่อนอนุญาตให้ reset password จริง
    // เช่น เก็บ OTP ใน Firestore แล้ว verify ตรงนี้

    return res.status(200).send({message: "Password reset successful"});
  } catch (error) {
    console.error("Error resetting password:", error);
    return res.status(500).send({error: "Failed to reset password"});
  }
});
