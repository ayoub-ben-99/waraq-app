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

  /// English and Arabic are written at the call site; French and Spanish come
  /// from the overlays below, keyed by the English text, so a new string falls
  /// back to English until it is translated instead of breaking.
  String _t(String en, String ar, [String? fr, String? es]) {
    switch (locale.languageCode) {
      case 'ar':
        return ar;
      case 'fr':
        return fr ?? _fr[en] ?? en;
      case 'es':
        return es ?? _es[en] ?? en;
      default:
        return en;
    }
  }

  // ---------------------------------------------------------------- brand ---
  String get appName => _t('Waraq', 'وَرَق');
  String get appTagline => _t('A quiet place to read PDFs', 'مكان هادئ لقراءة ملفات PDF');
  String get wordmark => _t('WARAQ', 'وَرَق');

  // --------------------------------------------------------------- common ---
  String get cancel => _t('Cancel', 'إلغاء');
  String get delete => _t('Delete', 'حذف');
  String get save => _t('Save', 'حفظ');
  String get close => _t('Close', 'إغلاق');
  String get done => _t('Done', 'تم');
  String get open => _t('Open', 'فتح');
  String get retry => _t('Try again', 'إعادة المحاولة');
  String get importPdf => _t('Import PDF', 'استيراد PDF');
  String get importing => _t('Importing…', 'جارٍ الاستيراد…');
  String get back => _t('Back', 'رجوع');
  String get fabActions => _t('Quick actions', 'إجراءات سريعة');

  // ------------------------------------------------------------- languages ---
  String get languageTitle => _t('Language', 'اللغة');
  String get languageSystem => _t('Follow the device', 'لغة الجهاز');
  String get languageEnglish => _t('English', 'الإنجليزية');
  String get languageArabic => _t('Arabic', 'العربية');
  String get languageFrench => _t('French', 'الفرنسية');
  String get languageSpanish => _t('Spanish', 'الإسبانية');
  String get languageHint => _t(
        'The interface and reading direction follow this choice',
        'تتبع الواجهة واتجاه القراءة هذا الاختيار',
      );
  String get languageArabicNative => 'العربية';
  String get languageEnglishNative => 'English';
  String get languageFrenchNative => 'Français';
  String get languageSpanishNative => 'Español';

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

  // --------------------------------------------------------- reading stats ---
  String get statsTitle => _t('Reading stats', 'إحصاءات القراءة');
  String statsStreak(int days) => days == 1
      ? _t('1 day streak', 'يوم واحد متتالٍ')
      : _t('$days day streak', '$days أيام متتالية');
  String get statsStreakNone => _t('No streak yet', 'لا سلسلة بعد');
  String get statsStreakBody => _t(
        'Read a little every day to keep it going',
        'اقرأ قليلًا كل يوم لتبقيها مستمرة',
      );
  String get statsLastSevenDays => _t('Last 7 days', 'آخر ٧ أيام');
  String get statsToday => _t('Today', 'اليوم');
  String get statsThisWeek => _t('This week', 'هذا الأسبوع');
  String get statsPagesRead => _t('Pages turned', 'صفحات مقروءة');
  String get statsSpeed => _t('Pace', 'السرعة');
  String statsPagesPerHour(int pages) => _t('$pages p/h', '$pages ص/س');
  String get statsTotalTime => _t('Total time', 'إجمالي الوقت');
  String get statsSessions => _t('Sessions', 'جلسات');
  String get statsEmptyTitle => _t('No reading yet', 'لا قراءة بعد');
  String get statsEmptyBody => _t(
        'Open a book and stay a little while; every session shows up here.',
        'افتح كتابًا واقرأ قليلًا؛ ستظهر كل جلسة هنا.',
      );

  // -------------------------------------------------------------- search ---
  String get searchEverything => _t('Search', 'بحث');
  String get searchEverythingHint => _t(
        'Books, notes and tags',
        'الكتب والملاحظات والوسوم',
      );
  String get searchIntro => _t(
        'Type any word from a book title, a note, or a tag. Arabic is matched regardless of diacritics and alef forms.',
        'اكتب أي كلمة من عنوان كتاب أو ملاحظة أو وسم. تُطابَق العربية بصرف النظر عن التشكيل وشكل الألف.',
      );
  String searchBooks(int count) => _t('Books · $count', 'كتب · $count');
  String searchNotes(int count) => _t('Notes · $count', 'ملاحظات · $count');
  String get searchTags => _t('Tags', 'الوسوم');
  String get searchNoResultsTitle => _t('Nothing found', 'لا نتائج');
  String searchNoResultsBody(String query) => _t(
        'No book, note or tag matches “$query”.',
        'لا كتاب ولا ملاحظة ولا وسم يطابق «$query».',
      );

  // ---------------------------------------------------------------- tags ---
  String get noteTagsLabel => _t('Tags', 'الوسوم');
  String get tagNew => _t('New tag', 'وسم جديد');
  String get tagNewTitle => _t('Name the tag', 'اسم الوسم');
  String get tagNameHint => _t('e.g. Idea, Quote', 'مثل: فكرة، اقتباس');
  String get tagCreate => _t('Create', 'إنشاء');
  String get tagManageTitle => _t('Edit tag', 'تعديل الوسم');
  String get notesAllTags => _t('All', 'الكل');
  String get tagLongPressHint => _t(
        'Long-press a tag to rename or delete it',
        'اضغط مطوّلًا على الوسم لتعديله أو حذفه',
      );

  // ---------------------------------------------------------- categories ---
  String get bookTitleLabel => _t('Title', 'العنوان');
  String get bookCategoryLabel => _t('Shelf', 'الرف');
  String get bookCategoryHint => _t(
        'e.g. Novels, Work, Study',
        'مثل: روايات، عمل، دراسة',
      );
  String get bookSaved => _t('Book updated', 'تم تحديث الكتاب');
  String get allCategories => _t('All shelves', 'كل الأرفف');
  String get bookDetailsHint => _t(
        'Long-press a book to rename it or move it to a shelf',
        'اضغط مطوّلًا على كتاب لتغيير اسمه أو نقله إلى رف',
      );

  // -------------------------------------------------------------- review ---
  String get reviewTitle => _t('Review', 'المراجعة');
  String get reviewDueSection => _t('Due now', 'مستحقة الآن');
  String get reviewUpcoming => _t('Coming up', 'قادمة');
  String get reviewStart => _t('Start review', 'ابدأ المراجعة');
  String get reviewEmptyTitle => _t('Nothing to review', 'لا شيء للمراجعة');
  String get reviewEmptyBody => _t(
        'Write a note on any page first. Notes then come back on their own schedule: 1, 3, 7, 16, then 35 days.',
        'اكتب ملاحظة على أي صفحة أولًا. بعدها تعود الملاحظات وفق جدولها: يوم، ٣، ٧، ١٦ ثم ٣٥ يومًا.',
      );
  String reviewDueCount(int count, int total) => _t(
        '$count of $total notes are due',
        '$count من $total ملاحظة مستحقة',
      );
  String reviewProgress(int index, int total) => _t(
        '$index / $total',
        '$index / $total',
      );
  String get reviewForgot => _t('Forgot', 'لم أتذكّر');
  String get reviewPartial => _t('Almost', 'تقريبًا');
  String get reviewGood => _t('I know it', 'أتذكّرها');
  String get reviewSkip => _t('Skip', 'تخطّي');
  String get reviewDoneTitle => _t('Session complete', 'انتهت المراجعة');
  String reviewDoneBody(int total, int known) => _t(
        '$total notes reviewed · $known known well',
        '$total ملاحظة راجعتها · $known متقنة',
      );
  String get reviewDone => _t('Done', 'تم');
  String get reviewPostpone => _t('Postpone', 'تأجيل');
  String get reviewPostponeDay => _t('1 day', 'يوم');
  String get reviewPostponeThree => _t('3 days', '٣ أيام');
  String get reviewPostponeWeek => _t('1 week', 'أسبوع');
  String reviewPostponed(int days) => _t(
        'Postponed $days days',
        'أُجّلت $days أيام',
      );
  String reviewNextIn(int days) {
    if (days <= 0) {
      return _t('Due now', 'مستحقة الآن');
    }
    if (days == 1) {
      return _t('Tomorrow', 'غدًا');
    }
    return _t('In $days days', 'بعد $days يوم');
  }

  String get homeReviewTitle => _t('Today’s review', 'مراجعة اليوم');
  String homeReviewBody(int count) => count == 0
      ? _t(
          'Nothing is due. Keep writing notes.',
          'لا شيء مستحق. واصل تدوين الملاحظات.',
        )
      : _t(
          '$count notes are ready to revisit',
          '$count ملاحظة جاهزة للمراجعة',
        );
  String get reviewOpenPage => _t('Open the page', 'افتح الصفحة');

  // -------------------------------------------------------------- backup ---
  String get backupTitle => _t('Backup', 'النسخ الاحتياطي');
  String get backupSubtitle => _t(
        'Export or restore everything as one file',
        'صدّر كل شيء أو استعده في ملف واحد',
      );
  String get backupIntro => _t(
        'One file holds your library, reading positions, notes and settings. Keep it in Drive or on your computer; nothing is uploaded anywhere.',
        'ملف واحد يحمل مكتبتك ومواضع القراءة والملاحظات والإعدادات. احفظه في Drive أو على حاسوبك؛ لا يُرفع شيء إلى أي مكان.',
      );
  String get backupIncludePdfs => _t('Include PDF files', 'تضمين ملفات PDF');
  String get backupIncludePdfsBody => _t(
        'The backup can reopen every book on a new device. Turn off to get a small file with only data.',
        'تتيح النسخة فتح كل الكتب على جهاز جديد. أوقفها لتحصل على ملف صغير للبيانات فقط.',
      );
  String backupContentsSummary(int documents, int notes) => _t(
        '$documents documents · $notes notes',
        '$documents ملفًا · $notes ملاحظة',
      );
  String get exportBackup => _t('Export', 'تصدير');
  String get backupRestoreSection => _t('Restore', 'استعادة');
  String get backupRestoreHint => _t(
        'Adds what is missing and keeps the newer reading position. Nothing in your library is deleted.',
        'يضيف الناقص ويحفظ أحدث موضع قراءة. لا يُحذف شيء من مكتبتك.',
      );
  String get restore => _t('Restore', 'استعادة');
  String get backupRestoreTitle => _t('Restore from a file?', 'استعادة من ملف؟');
  String get backupRestoreBody => _t(
        'Pick a .waraq.zip file exported by Waraq. Existing books, notes and settings stay unless the file has a newer version of them.',
        'اختر ملف ‎.waraq.zip‎ صدّره وَرَق. تبقى كتبك وملاحظاتك وإعداداتك الحالية إلا ما كان أحدث في الملف.',
      );
  String backupExported(String size, int documents) => _t(
        'Backup saved · $size · $documents documents',
        'حُفظت النسخة · $size · $documents ملفًا',
      );
  String backupRestored(int documents, int notes, int skipped) => _t(
        'Restored $documents documents and $notes notes'
            '${skipped > 0 ? ' · $skipped skipped (no PDF in the file)' : ''}',
        'استُعيدت $documents ملفًا و$notes ملاحظة'
            '${skipped > 0 ? ' · $skipped لم تُستعد (لا يوجد PDF في الملف)' : ''}',
      );
  String get backupFailed => _t('The backup failed', 'فشلت العملية');
  String get backupNotAFile => _t(
        'That file is not a Waraq backup',
        'هذا الملف ليس نسخة احتياطية من وَرَق',
      );
  String get backupNewerVersion => _t(
        'This backup was made by a newer version of Waraq',
        'هذه النسخة أُنشئت بإصدار أحدث من وَرَق',
      );
  String get backupPrivacyNote => _t(
        'Backups are written straight to the place you choose. Waraq has no servers and no account.',
        'تُكتب النسخة مباشرة في المكان الذي تختاره. وَرَق بلا خوادم وبلا حساب.',
      );

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

/// French copy, keyed by the English source string.
const Map<String, String> _fr = <String, String>{
  'Waraq': 'Waraq',
  'A quiet place to read PDFs': 'Un endroit calme pour lire des PDF',
  'WARAQ': 'WARAQ',
  'Cancel': 'Annuler',
  'Delete': 'Supprimer',
  'Save': 'Enregistrer',
  'Close': 'Fermer',
  'Done': 'Terminé',
  'Open': 'Ouvrir',
  'Try again': 'Réessayer',
  'Import PDF': 'Importer un PDF',
  'Importing…': 'Importation…',
  'Back': 'Retour',
  'Quick actions': 'Actions rapides',
  'Home': 'Accueil',
  'Library': 'Bibliothèque',
  'Settings': 'Réglages',
  'Good morning': 'Bonjour',
  'Good afternoon': 'Bon après-midi',
  'Good evening': 'Bonsoir',
  'Still reading?': 'Encore en train de lire ?',
  'Continue reading': 'Reprendre la lecture',
  'Start reading': 'Commencer la lecture',
  'Recent': 'Récents',
  'Nothing read yet': 'Rien de lu pour le moment',
  'Your shelf is empty': 'Votre étagère est vide',
  'Import a PDF to start reading. Everything stays on this device.':
      'Importez un PDF pour commencer. Tout reste sur cet appareil.',
  'Documents you open will appear here.':
      'Les documents que vous ouvrez apparaîtront ici.',
  'Page $page of $total': 'Page $page sur $total',
  'Last read $relative': 'Lu $relative',
  'Search your library': 'Rechercher dans la bibliothèque',
  'Title': 'Titre',
  'Sort': 'Trier',
  'No matches for “$query”': 'Aucun résultat pour « $query »',
  'Delete this document?': 'Supprimer ce document ?',
  'The PDF, its reading position and its bookmarks will be removed from this device.':
      'Le PDF, sa position de lecture et ses signets seront retirés de cet appareil.',
  'Document deleted': 'Document supprimé',
  '“$title” added to your library': '« $title » ajouté à votre bibliothèque',
  'This file is no longer available': 'Ce fichier n’est plus disponible',
  'Could not open this document': 'Impossible d’ouvrir ce document',
  'That file could not be imported': 'Ce fichier n’a pas pu être importé',
  'Pages': 'Pages',
  'Marks': 'Signets',
  'Auto': 'Auto',
  'Display': 'Affichage',
  'Bookmark this page': 'Marquer cette page',
  'Remove bookmark': 'Retirer le signet',
  'Bookmark saved': 'Signet enregistré',
  'Bookmark removed': 'Signet retiré',
  'No marks yet': 'Aucun signet',
  'Tap the marker at the top to keep a page.':
      'Touchez le marqueur en haut pour garder une page.',
  'All pages': 'Toutes les pages',
  'Go to page': 'Aller à la page',
  'Go': 'Aller',
  'Page number': 'Numéro de page',
  'Auto-scroll': 'Défilement auto',
  'Start': 'Démarrer',
  'Pause': 'Pause',
  'Speed': 'Vitesse',
  'Slow': 'Lent',
  'Fast': 'Rapide',
  'Scrolling stops the moment you touch the page.':
      'Le défilement s’arrête dès que vous touchez la page.',
  'Page tone': 'Teinte de la page',
  'Original': 'Original',
  'Sepia': 'Sépia',
  'Night': 'Nuit',
  'Brightness': 'Luminosité',
  'Dims the page so it matches the room.':
      'Atténue la page pour l’adapter à la pièce.',
  'Scrolling': 'Défilement',
  'Continuous': 'Continu',
  'Paged': 'Par page',
  'One long column, like a scroll.': 'Une longue colonne, comme un parchemin.',
  'One page at a time, swiped sideways.': 'Une page à la fois, balayée sur le côté.',
  'Preparing pages': 'Préparation des pages',
  'Measuring the document so scrolling stays smooth.':
      'Mesure du document pour un défilement fluide.',
  'This document could not be opened': 'Ce document n’a pas pu être ouvert',
  'The file may be damaged, password protected or not a PDF.':
      'Le fichier est peut-être endommagé, protégé par mot de passe ou n’est pas un PDF.',
  'Appearance': 'Apparence',
  'Theme': 'Thème',
  'System': 'Système',
  'Light': 'Clair',
  'Dark': 'Sombre',
  'AMOLED': 'AMOLED',
  'Follows the device': 'Suit l’appareil',
  'True black for OLED': 'Noir absolu pour OLED',
  'Wallpaper colors': 'Couleurs du fond d’écran',
  'Tint the app with the palette of your wallpaper':
      'Teinter l’application avec le fond d’écran',
  'Not available on this device': 'Indisponible sur cet appareil',
  'Accent color': 'Couleur d’accent',
  'Reading': 'Lecture',
  'Default scrolling': 'Défilement par défaut',
  'Default page tone': 'Teinte de page par défaut',
  'Language': 'Langue',
  'Storage': 'Stockage',
  'Used by your library': 'Utilisé par votre bibliothèque',
  'Forget reading positions': 'Oublier les positions de lecture',
  'Positions and bookmarks are removed. Documents stay.':
      'Les positions et signets sont retirés. Les documents restent.',
  'Reading data cleared': 'Données de lecture effacées',
  'About': 'À propos',
  'Waraq is a local-first reader. No account, no sync, no tracking. PDF rendering by pdfx.':
      'Waraq est un lecteur local. Sans compte, sans synchronisation, sans pistage. Rendu PDF par pdfx.',
  'Version': 'Version',
  'Shape': 'Formes',
  'Corner style': 'Style des coins',
  'How rounded cards, sheets and buttons are':
      'Arrondi des cartes, feuilles et boutons',
  'Soft': 'Doux',
  'Rounded': 'Arrondi',
  'Square': 'Carré',
  'Applies across the whole app, including the reader':
      'S’applique à toute l’application, y compris le lecteur',
  'Motion': 'Animations',
  'Animation level': 'Niveau d’animation',
  'Reveals, sliding chrome and theme cross-fades':
      'Apparitions, barres coulissantes et fondus de thème',
  'Full': 'Complètes',
  'Reduced': 'Réduites',
  'Off': 'Aucune',
  'Turn motion off for a still, distraction-free interface':
      'Désactivez les animations pour une interface immobile',
  'On your shelf': 'Sur votre étagère',
  'Documents': 'Documents',
  'Bookmarks': 'Signets',
  'Pages read': 'Pages lues',
  'Average progress': 'Progression moyenne',
  'Notes': 'Notes',
  'Search notes': 'Rechercher dans les notes',
  'No notes yet': 'Aucune note',
  'Mark a page while reading, then tap "Add note" on the bookmark to keep a thought next to it.':
      'Marquez une page pendant la lecture, puis touchez « Ajouter une note ».',
  'Nothing matches': 'Aucun résultat',
  'Try a different word.': 'Essayez un autre mot.',
  'New note': 'Nouvelle note',
  'Edit note': 'Modifier la note',
  'What do you want to remember about this page?':
      'Que voulez-vous retenir de cette page ?',
  'Note saved': 'Note enregistrée',
  'Delete note': 'Supprimer la note',
  'Note deleted': 'Note supprimée',
  'Delete this note?': 'Supprimer cette note ?',
  'The page stays bookmarked and only the text is removed.':
      'La page reste marquée, seul le texte est retiré.',
  'Add note': 'Ajouter une note',
  'Reading stats': 'Statistiques de lecture',
  'No streak yet': 'Pas encore de série',
  'Read a little every day to keep it going':
      'Lisez un peu chaque jour pour la maintenir',
  'Last 7 days': '7 derniers jours',
  'Today': 'Aujourd’hui',
  'This week': 'Cette semaine',
  'Pages turned': 'Pages tournées',
  'Pace': 'Rythme',
  'Total time': 'Temps total',
  'Sessions': 'Sessions',
  'No reading yet': 'Aucune lecture',
  'Open a book and stay a little while; every session shows up here.':
      'Ouvrez un livre et restez un moment ; chaque session apparaîtra ici.',
  'Search': 'Rechercher',
  'Books, notes and tags': 'Livres, notes et étiquettes',
  'Type any word from a book title, a note, or a tag. Arabic is matched regardless of diacritics and alef forms.':
      'Tapez un mot d’un titre, d’une note ou d’une étiquette. L’arabe est comparé sans diacritiques.',
  'Tags': 'Étiquettes',
  'Nothing found': 'Rien trouvé',
  'New tag': 'Nouvelle étiquette',
  'Name the tag': 'Nom de l’étiquette',
  'e.g. Idea, Quote': 'ex. Idée, Citation',
  'Create': 'Créer',
  'Edit tag': 'Modifier l’étiquette',
  'All': 'Tout',
  'Long-press a tag to rename or delete it':
      'Appui long sur une étiquette pour la renommer ou la supprimer',
  'Shelf': 'Étagère',
  'e.g. Novels, Work, Study': 'ex. Romans, Travail, Études',
  'Book updated': 'Livre mis à jour',
  'All shelves': 'Toutes les étagères',
  'Long-press a book to rename it or move it to a shelf':
      'Appui long sur un livre pour le renommer ou le déplacer',
  'Review': 'Révision',
  'Due now': 'À réviser',
  'Coming up': 'À venir',
  'Start review': 'Commencer la révision',
  'Nothing to review': 'Rien à réviser',
  'Forgot': 'Oublié',
  'Almost': 'Presque',
  'I know it': 'Je sais',
  'Skip': 'Passer',
  'Session complete': 'Session terminée',
  'Postpone': 'Reporter',
  '1 day': '1 jour',
  '3 days': '3 jours',
  '1 week': '1 semaine',
  'Tomorrow': 'Demain',
  'Today’s review': 'Révision du jour',
  'Nothing is due. Keep writing notes.': 'Rien à réviser. Continuez à écrire.',
  'Open the page': 'Ouvrir la page',
  'Backup': 'Sauvegarde',
  'Export or restore everything as one file':
      'Exporter ou restaurer tout en un fichier',
  'Include PDF files': 'Inclure les fichiers PDF',
  'Export': 'Exporter',
  'Restore': 'Restaurer',
  'Restore from a file?': 'Restaurer depuis un fichier ?',
  'The backup failed': 'La sauvegarde a échoué',
  'That file is not a Waraq backup': 'Ce fichier n’est pas une sauvegarde Waraq',
  'This backup was made by a newer version of Waraq':
      'Cette sauvegarde vient d’une version plus récente de Waraq',
  'Community': 'Communauté',
  'WhatsApp group': 'Groupe WhatsApp',
  'Ask questions and share what you are reading':
      'Posez vos questions et partagez vos lectures',
  'Source code': 'Code source',
  'Waraq on GitHub': 'Waraq sur GitHub',
  'Could not open the link': 'Impossible d’ouvrir le lien',
};

/// Spanish copy, keyed by the English source string.
const Map<String, String> _es = <String, String>{
  'A quiet place to read PDFs': 'Un lugar tranquilo para leer PDF',
  'Cancel': 'Cancelar',
  'Delete': 'Eliminar',
  'Save': 'Guardar',
  'Close': 'Cerrar',
  'Done': 'Listo',
  'Open': 'Abrir',
  'Try again': 'Reintentar',
  'Import PDF': 'Importar PDF',
  'Importing…': 'Importando…',
  'Back': 'Atrás',
  'Quick actions': 'Acciones rápidas',
  'Home': 'Inicio',
  'Library': 'Biblioteca',
  'Settings': 'Ajustes',
  'Good morning': 'Buenos días',
  'Good afternoon': 'Buenas tardes',
  'Good evening': 'Buenas noches',
  'Still reading?': '¿Sigues leyendo?',
  'Continue reading': 'Continuar leyendo',
  'Start reading': 'Empezar a leer',
  'Recent': 'Recientes',
  'Nothing read yet': 'Nada leído todavía',
  'Your shelf is empty': 'Tu estantería está vacía',
  'Import a PDF to start reading. Everything stays on this device.':
      'Importa un PDF para empezar. Todo se queda en este dispositivo.',
  'Documents you open will appear here.':
      'Los documentos que abras aparecerán aquí.',
  'Page $page of $total': 'Página $page de $total',
  'Last read $relative': 'Leído $relative',
  'Search your library': 'Buscar en la biblioteca',
  'Title': 'Título',
  'Sort': 'Ordenar',
  'No matches for “$query”': 'Sin resultados para «$query»',
  'Delete this document?': '¿Eliminar este documento?',
  'The PDF, its reading position and its bookmarks will be removed from this device.':
      'El PDF, su posición de lectura y sus marcadores se quitarán del dispositivo.',
  'Document deleted': 'Documento eliminado',
  '“$title” added to your library': '«$title» añadido a tu biblioteca',
  'This file is no longer available': 'Este archivo ya no está disponible',
  'Could not open this document': 'No se pudo abrir este documento',
  'That file could not be imported': 'No se pudo importar ese archivo',
  'Pages': 'Páginas',
  'Marks': 'Marcadores',
  'Auto': 'Auto',
  'Display': 'Visualización',
  'Bookmark this page': 'Marcar esta página',
  'Remove bookmark': 'Quitar marcador',
  'Bookmark saved': 'Marcador guardado',
  'Bookmark removed': 'Marcador quitado',
  'No marks yet': 'Aún no hay marcadores',
  'Tap the marker at the top to keep a page.':
      'Toca el marcador de arriba para guardar una página.',
  'All pages': 'Todas las páginas',
  'Go to page': 'Ir a la página',
  'Go': 'Ir',
  'Page number': 'Número de página',
  'Auto-scroll': 'Desplazamiento automático',
  'Start': 'Iniciar',
  'Pause': 'Pausa',
  'Speed': 'Velocidad',
  'Slow': 'Lento',
  'Fast': 'Rápido',
  'Scrolling stops the moment you touch the page.':
      'El desplazamiento se detiene al tocar la página.',
  'Page tone': 'Tono de página',
  'Original': 'Original',
  'Sepia': 'Sepia',
  'Night': 'Noche',
  'Brightness': 'Brillo',
  'Dims the page so it matches the room.':
      'Atenúa la página para adaptarla a la habitación.',
  'Scrolling': 'Desplazamiento',
  'Continuous': 'Continuo',
  'Paged': 'Por página',
  'One long column, like a scroll.': 'Una columna larga, como un pergamino.',
  'One page at a time, swiped sideways.': 'Una página a la vez, deslizando.',
  'Preparing pages': 'Preparando páginas',
  'Measuring the document so scrolling stays smooth.':
      'Midiendo el documento para un desplazamiento fluido.',
  'This document could not be opened': 'No se pudo abrir este documento',
  'The file may be damaged, password protected or not a PDF.':
      'El archivo puede estar dañado, protegido o no ser un PDF.',
  'Appearance': 'Apariencia',
  'Theme': 'Tema',
  'System': 'Sistema',
  'Light': 'Claro',
  'Dark': 'Oscuro',
  'Follows the device': 'Sigue al dispositivo',
  'True black for OLED': 'Negro real para OLED',
  'Wallpaper colors': 'Colores del fondo',
  'Tint the app with the palette of your wallpaper':
      'Tiñe la app con los colores de tu fondo',
  'Not available on this device': 'No disponible en este dispositivo',
  'Accent color': 'Color de acento',
  'Reading': 'Lectura',
  'Default scrolling': 'Desplazamiento predeterminado',
  'Default page tone': 'Tono de página predeterminado',
  'Language': 'Idioma',
  'Storage': 'Almacenamiento',
  'Used by your library': 'Usado por tu biblioteca',
  'Forget reading positions': 'Olvidar posiciones de lectura',
  'Positions and bookmarks are removed. Documents stay.':
      'Se quitan posiciones y marcadores. Los documentos se quedan.',
  'Reading data cleared': 'Datos de lectura borrados',
  'About': 'Acerca de',
  'Waraq is a local-first reader. No account, no sync, no tracking. PDF rendering by pdfx.':
      'Waraq es un lector local. Sin cuenta, sin sincronización, sin rastreo. PDF con pdfx.',
  'Version': 'Versión',
  'Shape': 'Formas',
  'Corner style': 'Estilo de esquinas',
  'How rounded cards, sheets and buttons are':
      'Cuánto se redondean tarjetas, hojas y botones',
  'Soft': 'Suave',
  'Rounded': 'Redondeado',
  'Square': 'Recto',
  'Applies across the whole app, including the reader':
      'Se aplica a toda la app, incluido el lector',
  'Motion': 'Movimiento',
  'Animation level': 'Nivel de animación',
  'Reveals, sliding chrome and theme cross-fades':
      'Apariciones, barras deslizantes y fundidos de tema',
  'Full': 'Completo',
  'Reduced': 'Reducido',
  'Off': 'Sin',
  'Turn motion off for a still, distraction-free interface':
      'Desactiva el movimiento para una interfaz quieta',
  'On your shelf': 'En tu estantería',
  'Documents': 'Documentos',
  'Bookmarks': 'Marcadores',
  'Pages read': 'Páginas leídas',
  'Average progress': 'Progreso medio',
  'Notes': 'Notas',
  'Search notes': 'Buscar en las notas',
  'No notes yet': 'Aún no hay notas',
  'Mark a page while reading, then tap "Add note" on the bookmark to keep a thought next to it.':
      'Marca una página mientras lees y toca «Añadir nota».',
  'Nothing matches': 'Sin coincidencias',
  'Try a different word.': 'Prueba otra palabra.',
  'New note': 'Nota nueva',
  'Edit note': 'Editar nota',
  'What do you want to remember about this page?':
      '¿Qué quieres recordar de esta página?',
  'Note saved': 'Nota guardada',
  'Delete note': 'Eliminar nota',
  'Note deleted': 'Nota eliminada',
  'Delete this note?': '¿Eliminar esta nota?',
  'The page stays bookmarked and only the text is removed.':
      'La página sigue marcada y solo se quita el texto.',
  'Add note': 'Añadir nota',
  'Reading stats': 'Estadísticas de lectura',
  'No streak yet': 'Aún sin racha',
  'Read a little every day to keep it going':
      'Lee un poco cada día para mantenerla',
  'Last 7 days': 'Últimos 7 días',
  'Today': 'Hoy',
  'This week': 'Esta semana',
  'Pages turned': 'Páginas pasadas',
  'Pace': 'Ritmo',
  'Total time': 'Tiempo total',
  'Sessions': 'Sesiones',
  'No reading yet': 'Aún sin lectura',
  'Open a book and stay a little while; every session shows up here.':
      'Abre un libro y quédate un rato; cada sesión aparecerá aquí.',
  'Search': 'Buscar',
  'Books, notes and tags': 'Libros, notas y etiquetas',
  'Type any word from a book title, a note, or a tag. Arabic is matched regardless of diacritics and alef forms.':
      'Escribe una palabra de un título, una nota o una etiqueta. El árabe se compara sin diacríticos.',
  'Tags': 'Etiquetas',
  'Nothing found': 'Nada encontrado',
  'New tag': 'Etiqueta nueva',
  'Name the tag': 'Nombre de la etiqueta',
  'e.g. Idea, Quote': 'p. ej. Idea, Cita',
  'Create': 'Crear',
  'Edit tag': 'Editar etiqueta',
  'All': 'Todo',
  'Long-press a tag to rename or delete it':
      'Mantén pulsada una etiqueta para renombrarla o borrarla',
  'Shelf': 'Estante',
  'e.g. Novels, Work, Study': 'p. ej. Novelas, Trabajo, Estudio',
  'Book updated': 'Libro actualizado',
  'All shelves': 'Todos los estantes',
  'Long-press a book to rename it or move it to a shelf':
      'Mantén pulsado un libro para renombrarlo o moverlo',
  'Review': 'Repaso',
  'Due now': 'Para hoy',
  'Coming up': 'Próximas',
  'Start review': 'Empezar repaso',
  'Nothing to review': 'Nada que repasar',
  'Forgot': 'Olvidé',
  'Almost': 'Casi',
  'I know it': 'Lo sé',
  'Skip': 'Saltar',
  'Session complete': 'Sesión completada',
  'Postpone': 'Posponer',
  '1 day': '1 día',
  '3 days': '3 días',
  '1 week': '1 semana',
  'Tomorrow': 'Mañana',
  'Today’s review': 'Repaso de hoy',
  'Nothing is due. Keep writing notes.': 'Nada pendiente. Sigue escribiendo.',
  'Open the page': 'Abrir la página',
  'Backup': 'Copia de seguridad',
  'Export or restore everything as one file':
      'Exporta o restaura todo en un archivo',
  'Include PDF files': 'Incluir archivos PDF',
  'Export': 'Exportar',
  'Restore': 'Restaurar',
  'Restore from a file?': '¿Restaurar desde un archivo?',
  'The backup failed': 'La copia falló',
  'That file is not a Waraq backup': 'Ese archivo no es una copia de Waraq',
  'This backup was made by a newer version of Waraq':
      'Esta copia viene de una versión más reciente de Waraq',
  'Community': 'Comunidad',
  'WhatsApp group': 'Grupo de WhatsApp',
  'Ask questions and share what you are reading':
      'Pregunta y comparte lo que lees',
  'Source code': 'Código fuente',
  'Waraq on GitHub': 'Waraq en GitHub',
  'Could not open the link': 'No se pudo abrir el enlace',
};
