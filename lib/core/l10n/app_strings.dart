import 'package:flutter/widgets.dart';

/// Small, dependency-free string catalog. Waraq ships right-to-left by
/// default, so every label exists in English and Arabic and all layouts are
/// built with edge-aware widgets.
class AppStrings {
  const AppStrings(this.locale);

  factory AppStrings.of(BuildContext context) {
    return AppStrings(Localizations.maybeLocaleOf(context) ?? const Locale('en'));
  }

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  String _t(String en, String ar) => isArabic ? ar : en;

  // ---------------------------------------------------------------- brand ---
  String get appName => _t('Waraq', 'وَرَق');
  String get appTagline => _t('A quiet place to read PDFs', 'مكان هادئ لقراءة ملفات PDF');
  String get wordmark => _t('WARAQ', 'وَرَق');

  // --------------------------------------------------------------- common ---
  String get cancel => _t('Cancel', 'إلغاء');
  String get delete => _t('Delete', 'حذف');
  String get close => _t('Close', 'إغلاق');
  String get done => _t('Done', 'تم');
  String get open => _t('Open', 'فتح');
  String get retry => _t('Try again', 'إعادة المحاولة');
  String get importPdf => _t('Import PDF', 'استيراد PDF');
  String get importing => _t('Importing…', 'جارٍ الاستيراد…');
  String get back => _t('Back', 'رجوع');

  // ----------------------------------------------------------- navigation ---
  String get navHome => _t('Home', 'الرئيسية');
  String get navLibrary => _t('Library', 'المكتبة');
  String get navSettings => _t('Settings', 'الإعدادات');

  // ----------------------------------------------------------------- home ---
  String get greetingMorning => _t('Good morning', 'صباح الخير');
  String get greetingAfternoon => _t('Good afternoon', 'مساء الخير');
  String get greetingEvening => _t('Good evening', 'طاب مساؤك');
  String get greetingNight => _t('Still reading?', 'لا تزال تقرأ؟');
  String get continueReading => _t('Continue reading', 'متابعة القراءة');
  String get startReading => _t('Start reading', 'ابدأ القراءة');
  String get sectionRecent => _t('Recent', 'الأخيرة');
  String get recentEmpty => _t('Nothing read yet', 'لم تقرأ شيئًا بعد');
  String get emptyLibraryTitle => _t('Your shelf is empty', 'رفّك فارغ');
  String get emptyLibraryBody => _t(
        'Import a PDF to start reading. Everything stays on this device.',
        'استورد ملف PDF لتبدأ القراءة. كل شيء يبقى على هذا الجهاز.',
      );
  String get emptyRecentBody => _t(
        'Documents you open will appear here.',
        'ستظهر هنا الملفات التي تفتحها.',
      );

  String librarySummary(int documents, String size) => _t(
        '$documents ${documents == 1 ? 'document' : 'documents'} · $size',
        '$documents ملفات · $size',
      );

  String pagesLabel(int count) => _t(
        '$count ${count == 1 ? 'page' : 'pages'}',
        '$count صفحة',
      );

  String pageOf(int page, int total) =>
      _t('Page $page of $total', 'صفحة $page من $total');

  String percent(int value) => _t('$value%', '$value٪');

  String lastRead(String relative) => _t('Last read $relative', 'آخر قراءة $relative');

  // -------------------------------------------------------------- library ---
  String get libraryTitle => _t('Library', 'المكتبة');
  String get searchHint => _t('Search your library', 'ابحث في مكتبتك');
  String get sortRecent => _t('Recent', 'الأحدث');
  String get sortTitle => _t('Title', 'العنوان');
  String get sortLabel => _t('Sort', 'ترتيب');

  String noResults(String query) => _t('No matches for “$query”', 'لا نتائج لـ «$query»');

  String documentsCount(int count) => _t(
        '$count ${count == 1 ? 'document' : 'documents'}',
        '$count ملفات',
      );

  String get deleteDocumentTitle => _t('Delete this document?', 'حذف هذا الملف؟');
  String get deleteDocumentBody => _t(
        'The PDF, its reading position and its bookmarks will be removed from this device.',
        'سيُحذف الملف وموضع القراءة والعلامات من هذا الجهاز.',
      );
  String get deleted => _t('Document deleted', 'تم حذف الملف');
  String addedToLibrary(String title) =>
      _t('“$title” added to your library', 'أُضيف «$title» إلى مكتبتك');
  String get fileMissing => _t('This file is no longer available', 'هذا الملف لم يعد متاحًا');
  String get openFailed => _t('Could not open this document', 'تعذّر فتح هذا الملف');
  String get importFailed => _t('That file could not be imported', 'تعذّر استيراد هذا الملف');

  // --------------------------------------------------------------- reader ---
  String get readerPages => _t('Pages', 'الصفحات');
  String get readerBookmarks => _t('Marks', 'العلامات');
  String get readerAutoScroll => _t('Auto', 'تمرير');
  String get readerDisplay => _t('Display', 'العرض');
  String get bookmarkTooltip => _t('Bookmark this page', 'أضف علامة لهذه الصفحة');
  String get removeBookmarkTooltip => _t('Remove bookmark', 'إزالة العلامة');
  String get bookmarkAdded => _t('Bookmark saved', 'تم حفظ العلامة');
  String get bookmarkRemoved => _t('Bookmark removed', 'تمت إزالة العلامة');
  String get bookmarksEmptyTitle => _t('No marks yet', 'لا علامات بعد');
  String get bookmarksEmptyBody => _t(
        'Tap the marker at the top to keep a page.',
        'اضغط على العلامة في الأعلى لحفظ صفحة.',
      );

  String get pagesSheetTitle => _t('All pages', 'كل الصفحات');
  String get goToPage => _t('Go to page', 'انتقل إلى صفحة');
  String get go => _t('Go', 'انتقل');
  String get pageNumberHint => _t('Page number', 'رقم الصفحة');

  String get autoScrollTitle => _t('Auto-scroll', 'التمرير التلقائي');
  String get autoScrollStart => _t('Start', 'ابدأ');
  String get autoScrollPause => _t('Pause', 'إيقاف');
  String get speedLabel => _t('Speed', 'السرعة');
  String get speedSlow => _t('Slow', 'بطيء');
  String get speedFast => _t('Fast', 'سريع');
  String get autoScrollHint => _t(
        'Scrolling stops the moment you touch the page.',
        'يتوقف التمرير بمجرد لمس الصفحة.',
      );

  String get displayTitle => _t('Display', 'العرض');
  String get pageToneTitle => _t('Page tone', 'لون الصفحة');
  String get toneOriginal => _t('Original', 'الأصلي');
  String get toneSepia => _t('Sepia', 'بني فاتح');
  String get toneNight => _t('Night', 'ليلي');
  String get brightnessTitle => _t('Brightness', 'السطوع');
  String get brightnessHint => _t(
        'Dims the page so it matches the room.',
        'يخفّف إضاءة الصفحة لتناسب المكان.',
      );
  String get scrollModeTitle => _t('Scrolling', 'التمرير');
  String get scrollModeVertical => _t('Continuous', 'متواصل');
  String get scrollModeHorizontal => _t('Paged', 'صفحات');
  String get scrollModeVerticalHint => _t(
        'One long column, like a scroll.',
        'عمود واحد طويل، كالطومار.',
      );
  String get scrollModeHorizontalHint => _t(
        'One page at a time, swiped sideways.',
        'صفحة واحدة في كل مرة، تُسحب جانبيًا.',
      );

  String get preparingPages => _t('Preparing pages', 'تجهيز الصفحات');
  String get preparingPagesHint => _t(
        'Measuring the document so scrolling stays smooth.',
        'قياس المستند ليبقى التمرير سلسًا.',
      );
  String get documentErrorTitle => _t('This document could not be opened', 'تعذّر فتح هذا الملف');
  String get documentErrorBody => _t(
        'The file may be damaged, password protected or not a PDF.',
        'قد يكون الملف تالفًا أو محميًا بكلمة مرور أو ليس ملف PDF.',
      );

  // ------------------------------------------------------------- settings ---
  String get sectionAppearance => _t('Appearance', 'المظهر');
  String get themeModeTitle => _t('Theme', 'السمة');
  String get themeSystem => _t('System', 'النظام');
  String get themeLight => _t('Light', 'فاتح');
  String get themeDark => _t('Dark', 'داكن');
  String get themeAmoled => _t('AMOLED', 'أسود');
  String get themeSystemHint => _t('Follows the device', 'يتبع الجهاز');
  String get themeAmoledHint => _t('True black for OLED', 'أسود كامل لشاشات OLED');
  String get dynamicColorTitle => _t('Wallpaper colors', 'ألوان الخلفية');
  String get dynamicColorSubtitle => _t(
        'Tint the app with the palette of your wallpaper',
        'لوّن التطبيق بألوان خلفية جهازك',
      );
  String get dynamicColorUnavailable => _t(
        'Not available on this device',
        'غير متاح على هذا الجهاز',
      );
  String get accentTitle => _t('Accent color', 'لون التمييز');
  String get sectionReading => _t('Reading', 'القراءة');
  String get defaultScrollTitle => _t('Default scrolling', 'التمرير الافتراضي');
  String get defaultToneTitle => _t('Default page tone', 'لون الصفحة الافتراضي');
  String get languageTitle => _t('Language', 'اللغة');
  String get languageSystem => _t('System', 'النظام');
  String get languageEnglish => 'English';
  String get languageArabic => 'العربية';
  String get sectionStorage => _t('Storage', 'التخزين');
  String get storageUsed => _t('Used by your library', 'المستخدم في مكتبتك');
  String get clearReadingData => _t('Forget reading positions', 'مسح مواضع القراءة');
  String get clearReadingDataBody => _t(
        'Positions and bookmarks are removed. Documents stay.',
        'تُحذف المواضع والعلامات، وتبقى الملفات.',
      );
  String get readingDataCleared => _t('Reading data cleared', 'تم مسح بيانات القراءة');
  String get sectionAbout => _t('About', 'حول');
  String get aboutBody => _t(
        'Waraq is a local-first reader. No account, no sync, no tracking. PDF rendering by pdfx.',
        'وَرَق قارئ يعمل محليًا. بلا حساب ولا مزامنة ولا تتبّع. عرض PDF بواسطة pdfx.',
      );
  String get versionLabel => _t('Version', 'الإصدار');

  // ------------------------------------------------------ shape & motion ---
  String get sectionShape => _t('Shape', 'الأشكال');
  String get shapeTitle => _t('Corner style', 'شكل الزوايا');
  String get shapeSubtitle => _t(
        'How rounded cards, sheets and buttons are',
        'مقدار استدارة البطاقات والألواح والأزرار',
      );
  String get shapeSoft => _t('Soft', 'هادئة');
  String get shapeRounded => _t('Rounded', 'دائرية');
  String get shapeSquare => _t('Square', 'حادة');
  String get shapeHint => _t(
        'Applies across the whole app, including the reader',
        'يُطبَّق على التطبيق كاملًا بما فيه القارئ',
      );
  String get sectionMotion => _t('Motion', 'الحركة');
  String get motionTitle => _t('Animation level', 'مستوى الحركة');
  String get motionSubtitle => _t(
        'Reveals, sliding chrome and theme cross-fades',
        'الظهور التدريجي وحركة الأدوات وانتقال الثيم',
      );
  String get motionFull => _t('Full', 'كاملة');
  String get motionReduced => _t('Reduced', 'مخفّفة');
  String get motionOff => _t('Off', 'بدون');
  String get motionHint => _t(
        'Turn motion off for a still, distraction-free interface',
        'أوقف الحركة لواجهة ساكنة بلا تشتيت',
      );

  // --------------------------------------------------------- statistics ---
  String get sectionStats => _t('On your shelf', 'على رفّك');
  String get statsDocuments => _t('Documents', 'ملفات');
  String get statsPages => _t('Pages', 'صفحات');
  String get statsBookmarks => _t('Bookmarks', 'علامات');
  String get statsStorage => _t('Storage', 'تخزين');
  String get statsReadPages => _t('Pages read', 'صفحات مقروءة');
  String get statsProgress => _t('Average progress', 'متوسط التقدم');

  // --------------------------------------------------------------- notes ---
  String get navNotes => _t('Notes', 'ملاحظات');
  String get notesTitle => _t('Notes', 'الملاحظات');
  String get notesSearchHint => _t('Search notes', 'ابحث في الملاحظات');
  String get notesEmptyTitle => _t('No notes yet', 'لا ملاحظات بعد');
  String get notesEmptyBody => _t(
        'Mark a page while reading, then tap "Add note" on the bookmark to keep a thought next to it.',
        'علّم صفحة أثناء القراءة ثم اضغط «أضف ملاحظة» على العلامة لتحفظ فكرة بجانبها.',
      );
  String get notesNoMatchTitle => _t('Nothing matches', 'لا نتائج مطابقة');
  String get notesNoMatchBody => _t(
        'Try a different word.',
        'جرّب كلمة أخرى.',
      );
  String get noteAddTitle => _t('New note', 'ملاحظة جديدة');
  String get noteEditTitle => _t('Edit note', 'تعديل الملاحظة');
  String get noteHint => _t(
        'What do you want to remember about this page?',
        'ماذا تريد أن تتذكّر عن هذه الصفحة؟',
      );
  String get noteSave => _t('Save', 'حفظ');
  String get noteSaved => _t('Note saved', 'تم حفظ الملاحظة');
  String get noteDelete => _t('Delete note', 'حذف الملاحظة');
  String get noteDeleted => _t('Note deleted', 'تم حذف الملاحظة');
  String get noteDeleteTitle => _t('Delete this note?', 'حذف هذه الملاحظة؟');
  String get noteDeleteBody => _t(
        'The page stays bookmarked and only the text is removed.',
        'ستبقى الصفحة معلَّمة ويُحذف النص فقط.',
      );
  String get noteAddAction => _t('Add note', 'أضف ملاحظة');
  String get noteEditAction => _t('Edit note', 'تعديل الملاحظة');

  // ----------------------------------------------------------- community ---
  String get sectionCommunity => _t('Community', 'المجتمع');
  String get whatsappGroup => _t('WhatsApp group', 'مجموعة واتساب');
  String get whatsappGroupHint => _t(
        'Ask questions and share what you are reading',
        'اسأل وشارك ما تقرأه',
      );
  String get sourceCode => _t('Source code', 'الكود المصدري');
  String get sourceCodeHint => _t('Waraq on GitHub', 'وَرَق على GitHub');
  String get linkError => _t('Could not open the link', 'تعذّر فتح الرابط');
}

extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
