# ChatGPT Workflow

המסמך הזה נועד לשמש כפתיח קבוע לשיחות חדשות על הפרויקט.

## 1. פתיח מומלץ לשיחה חדשה

```text
אנחנו עובדים בעברית.

Repo: [REPO_NAME]
Branch: [BRANCH_NAME]

Workflow:
- דבר איתי בעברית בלבד.
- פלט טכני, קוד, נתיבי קבצים, שמות nodes, ושמות קבצים יכולים להיות באנגלית.
- התייחס ל-GodotContextOutput כ-source of truth היחיד למצב הנוכחי של הפרויקט.
- אם יש סתירה בין זיכרון קודם, הנחות, או שיחה קודמת לבין ה-context, ה-context קובע.
- עבוד רק לפי הקבצים, הנתיבים והתוכן שמופיעים ב-context.
- שנה רק קבצים שאני מאשר במפורש.
- אל תשנה balance, speed, damage, cooldowns, survivability, או enemy balance אלא אם ביקשתי במפורש.
- לפני כל שינוי, הסבר בקצרה מה אתה עומד לשנות ובאילו קבצים.
- תעדיף Patch קטן ובטוח על פני Replace מלא, אלא אם ברור שעדיף להחליף קובץ שלם.
- אם ה-context של קובץ הוא חלקי בלבד, אל תנחש. בקש context מלא או תזהיר שה-patch לא בטוח.
- אם אני מבקש פקודת פלאג-אין, תחזיר פלט שמתאים ל-Godot plugin workflow:
  1) הסבר קצר בעברית
  2) ואז רק block של <GodotContextCommand> בלי טקסט אחר אחריו
- אם אני לא מבקש XML לפלאג-אין, תחזיר קוד מוכן להדבקה או קובץ מלא מעודכן, עם הסבר קצר איפה להדביק.
- תסביר כמו למתחיל מוחלט ב-Godot.
- אחרי כל שינוי, תן checklist קצר ופשוט לבדיקה בתוך Godot.
- אם GitHub direct write נכשל, אל תגיד שעודכן. במקום זה תחזיר את הקובץ המלא/ה-patch המדויק + commit message.
- תעדיף פתרון אחד, קצר, בטוח ופרקטי.
```

## 2. גרסה קצרה מאוד

```text
אנחנו עובדים בעברית.
רק קוד, נתיבים, שמות קבצים, nodes, ופלט טכני של Godot Context plugin יכולים להיות באנגלית.
Repo: [REPO_NAME]
Branch: [BRANCH_NAME]

השתמש ב-GodotContextOutput כ-source of truth היחיד.
אל תניח שום דבר שלא מופיע ב-context.
שנה רק קבצים מאושרים.
אל תשנה balance בלי אישור מפורש.
הסבר בקצרה מה תשנה.
העדף Patch קטן ובטוח.
אם context חלקי, אל תנחש.
אם אני מבקש XML לפלאג-אין: הסבר קצר בעברית ואז רק <GodotContextCommand>.
אם GitHub update נכשל: תחזיר patch/full file + commit message ואל תגיד שעודכן.
אחרי כל שינוי תן checklist קצר לבדיקה ב-Godot.
```

## 3. כללי עבודה קבועים

- שפת השיחה: עברית.
- קוד, paths, node names, file names, ו-context plugin output יכולים להיות באנגלית.
- ה-context של הפלאג-אין הוא מקור האמת היחיד למצב הפרויקט.
- לא משנים מערכות שלא אושרו.
- אם מבוקש שינוי קטן, מעדיפים patch קטן ובטוח.
- אם הכתיבה ל-GitHub נכשלה, חייבים לומר שלא עודכן בפועל.

## 4. תבנית בקשה לפאץ' קטן

```text
Patch קטן ובטוח בלבד.
שנה רק את הקובץ: [FILE_PATH]
אל תיגע בקבצים אחרים.
אל תשנה balance.
הסבר בקצרה מה תשנה, ואז תחזיר קוד מוכן להדבקה.
בסוף תן checklist קצר לבדיקה.
```

## 5. תבנית בקשה לקובץ מלא

```text
תחזיר את הקובץ המלא המעודכן בלבד עבור: [FILE_PATH]
שמור על כל המערכות הקיימות שלא ביקשתי לשנות.
אחרי זה תן checklist קצר לבדיקה.
```

## 6. תבנית בקשה לפקודת פלאג-אין

```text
אני רוצה פלט לפלאג-אין.
תן קודם הסבר קצר בעברית,
ואז רק block אחד של <GodotContextCommand> בלי טקסט אחר אחריו.
```

## 7. Commit message מומלץ

```text
[type]: short clear summary
```

דוגמאות:

```text
player: add gentle turn smoothing and visual bank polish
boss: fix missile hit explosion timing
ui: add stage clear prompt spacing
docs: update ChatGPT workflow guide
```

## 8. Checklist קצר אחרי כל שינוי

- הקובץ נטען בלי שגיאות parser.
- הסצנה הרלוונטית נפתחת ב-Godot.
- ההתנהגות שביקשתי השתנתה.
- מערכות שלא ביקשתי לגעת בהן עדיין עובדות.
- אין שינוי balance לא מתוכנן.
