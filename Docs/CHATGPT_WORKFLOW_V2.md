# ChatGPT Workflow V2

המסמך הזה נועד לשמש כפתיח קבוע לשיחות חדשות על הפרויקט, עם כללים קשיחים לפלט XML של Godot plugin ולעדכון קבצים בצורה בטוחה.

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
- אם אני לא מבקש XML לפלאג-אין, תחזיר קוד מוכן להדבקה או קובץ מלא מעודכן, עם הסבר קצר איפה להדביק.
- תסביר כמו למתחיל מוחלט ב-Godot.
- אחרי כל שינוי, תן checklist קצר ופשוט לבדיקה בתוך Godot.
- אם GitHub direct write נכשל, אל תגיד שעודכן. במקום זה תחזיר את הקובץ המלא/ה-patch המדויק + commit message.
- תעדיף פתרון אחד, קצר, בטוח ופרקטי.

כלל קשיח לפלט פלאג-אין:
- אם אני מבקש XML, GodotContextCommand, או פלט לפלאג-אין, כל התשובה שלך חייבת להיות בדיוק code block אחד בלבד עם syntax של xml.
- אסור לכתוב שום טקסט לפני ה-code block.
- אסור לכתוב שום טקסט אחרי ה-code block.
- כל ה-<GodotContextCommand> חייב להיות בתוך אותו block יחיד.
- אסור לפצל את ה-XML לכמה blocks.
- כל הפאץ' חייב להיות בתוך חלון XML שחור נפרד אחד.

כלל קשיח לעריכת קבצים דרך הפלאג-אין:
- אם יש ספק לגבי תמיכה ב-PatchFiles / SEARCH / REPLACE, תעדיף תמיד ReplaceFiles עם קובץ מלא ומלא תקין.
- אל תחזיר markers כמו <<<<<<<, =======, >>>>>>> בתוך קוד GDScript.
- אם מבוקש patch חלקי, השתמש בו רק אם ברור שהפלאג-אין תומך בו בבטחה.
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
אם GitHub update נכשל: תחזיר patch/full file + commit message ואל תגיד שעודכן.
אחרי כל שינוי תן checklist קצר לבדיקה ב-Godot.

אם אני מבקש XML / GodotContextCommand / פלט לפלאג-אין:
- תחזיר רק code block אחד של xml.
- בלי שום טקסט לפניו או אחריו.
- כל ה-XML חייב להיות בתוך אותו block יחיד.

אם יש ספק לגבי PatchFiles:
- תעדיף ReplaceFiles עם קובץ מלא.
- אל תחזיר conflict markers בתוך הקוד.
```

## 3. כללי עבודה קבועים

- שפת השיחה: עברית.
- קוד, paths, node names, file names, ו-context plugin output יכולים להיות באנגלית.
- ה-context של הפלאג-אין הוא מקור האמת היחיד למצב הפרויקט.
- לא משנים מערכות שלא אושרו.
- אם מבוקש שינוי קטן, מעדיפים patch קטן ובטוח.
- אם הכתיבה ל-GitHub נכשלה, חייבים לומר שלא עודכן בפועל.
- אם מבוקש XML לפלאג-אין, מחזירים רק בלוק xml אחד בלי טקסט נוסף.
- אם יש ספק לגבי patch חלקי, מחזירים ReplaceFiles מלא.

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
אני רוצה פלט XML לפלאג-אין.
תחזיר את כל התשובה כ-code block אחד בלבד של xml.
בלי שום טקסט לפניו.
בלי שום טקסט אחריו.
כל ה-<GodotContextCommand> חייב להיות בתוך אותו block יחיד.
אם יש ספק לגבי PatchFiles, תעדיף ReplaceFiles עם קובץ מלא תקין.
```

## 7. Commit message מומלץ

```text
[type]: short clear summary
```

דוגמאות:

```text
player: add gentle turn smoothing and visual bank polish
docs: add strict XML workflow rule
docs: prefer replace-files when patch support is uncertain
```

## 8. Checklist קצר אחרי כל שינוי

- הקובץ נטען בלי שגיאות parser.
- הסצנה הרלוונטית נפתחת ב-Godot.
- ההתנהגות שביקשתי השתנתה.
- מערכות שלא ביקשתי לגעת בהן עדיין עובדות.
- אין שינוי balance לא מתוכנן.
