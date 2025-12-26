# SMS Logs Directory

هذا المجلد يحتوي على ملفات الـ logs الخاصة بإرسال الرسائل النصية (SMS).

## ملفات الـ Logs

- **sms_YYYY-MM-DD.log** - ملف log لكل يوم يحتوي على جميع محاولات إرسال SMS في ذلك اليوم

## تنسيق الـ Log

كل إدخال في الـ log يحتوي على:
- **timestamp** - التاريخ والوقت
- **phone_number** - رقم الهاتف المرسل إليه
- **otp** - كود OTP المرسل
- **api_url** - رابط API المستخدم
- **request_data** - البيانات المرسلة للـ API:
  - recipient - رقم المستلم (مع إضافة 2 في البداية)
  - sender_id - اسم المرسل
  - type - نوع الرسالة
  - message - محتوى الرسالة
- **response** - استجابة API:
  - http_code - كود HTTP
  - body - محتوى الاستجابة (JSON decoded)
  - raw_response - الاستجابة الخام
- **curl_error** - أي أخطاء من cURL (إن وجدت)
- **success** - true/false حسب نجاح العملية

## مثال على الـ Log

```json
{
    "timestamp": "2024-01-15 14:30:25",
    "phone_number": "201234567890",
    "otp": "1234",
    "api_url": "https://bulk.whysms.com/api/v3/sms/send",
    "request_data": {
        "recipient": "2201234567890",
        "sender_id": "StudyOnline",
        "type": "plain",
        "message": "Your verification code is: 1234"
    },
    "response": {
        "http_code": 200,
        "body": {...},
        "raw_response": "..."
    },
    "curl_error": null,
    "success": true
}
```

## ملاحظات أمنية

- ملفات الـ logs تحتوي على معلومات حساسة (أرقام هواتف، OTP codes)
- تم منع الوصول المباشر إلى ملفات الـ logs عبر .htaccess
- يُنصح بحذف ملفات الـ logs القديمة بانتظام

