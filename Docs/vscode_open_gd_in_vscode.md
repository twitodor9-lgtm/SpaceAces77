# הגדרת Godot לפתוח קבצי ‎.gd ב-VS Code (3 צעדים)

## 1) התקנה/ווידוא VS Code
ודא ש-VS Code מותקן (ושהקובץ `Code.exe` קיים במחשב).

## 2) הגדרה בתוך Godot (External Editor)
ב-Godot: **Editor → Editor Settings → Text Editor → External**
- הפעל **Use External Editor** = ON  
- קבע **Exec Path** לנתיב של VS Code:
  - Windows (דוגמה): `C:\Program Files\Microsoft VS Code\Code.exe`
  - (אם התקנת למשתמש בלבד: `C:\Users\<USER>\AppData\Local\Programs\Microsoft VS Code\Code.exe`)
- קבע **Exec Flags** כך:
  - `--reuse-window --goto {file}:{line}:{col}`

## 3) בדיקה
סגור/פתח מחדש את Godot (אם צריך), ואז **Double-click** על קובץ ‎`.gd` ב-FileSystem — הוא אמור להיפתח ב-VS Code ישר על השורה הרלוונטית.