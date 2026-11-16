// Ported from app/src/main/java/com/waraq/app/ui/pdf/PdfReaderActivity.java
import React, { useCallback, useEffect, useState } from 'react';
import { View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { Button, Text } from 'react-native-paper';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import * as FS from 'expo-file-system/legacy';
import { documentById, savePosition } from '../data/repos/pdf';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { Loading } from '../components/Layout';
import { ReaderToolbar } from '../components/reader/ReaderToolbar';
import { ReaderPager } from '../components/reader/ReaderPager';
import { ReaderSettingsSheet } from '../components/reader/ReaderSettingsSheet';
import { ReaderNavSheet } from '../components/reader/ReaderNavSheet';
import {
  getReaderDark,
  getReaderTextFont,
  getReaderTextMode,
  getReaderTextSize,
  getReaderTextSpacing,
  setReaderDark,
  setReaderTextFont,
  setReaderTextMode,
  setReaderTextSize,
  setReaderTextSpacing,
  type ReaderTextFont,
} from '../lib/prefs';
import { md3DarkColors, md3LightColors } from '../theme/md3Colors';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'PdfReader'>;

export function PdfReaderScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const { docId, bookId } = route.params;
  const { spacing } = useAppTheme();
  const [error, setError] = useState<string | null>(null);
  const [loaded, setLoaded] = useState<{ displayName: string; path: string; pageCount: number; lastPage: number } | null>(null);
  const [page, setPage] = useState(0);
  const [dark, setDark] = useState(() => getReaderDark());
  const [textMode, setTextMode] = useState(() => getReaderTextMode(docId));
  const [textSize, setTextSize] = useState(() => getReaderTextSize());
  const [lineSpacing, setLineSpacing] = useState(() => getReaderTextSpacing());
  const [textFont, setTextFont] = useState<ReaderTextFont>(() => getReaderTextFont());
  const [settingsVisible, setSettingsVisible] = useState(false);
  const [navVisible, setNavVisible] = useState(false);

  useEffect(() => {
    let active = true;
    void (async () => {
      try {
        const doc = await documentById(docId);
        if (!active) return;
        if (!doc || !doc.localPath || doc.pageCount <= 0) {
          setError(t.pdfMissing);
          return;
        }
        const uri = `${FS.documentDirectory}${doc.localPath}`;
        const fileInfo = await FS.getInfoAsync(uri);
        if (!active) return;
        if (!fileInfo.exists) {
          setError(t.pdfMissing);
          return;
        }
        // الوحدة الأصلية تفتح الملف بمسار النظام لا بـ file:// URI.
        const path = uri.startsWith('file://') ? decodeURIComponent(uri.slice('file://'.length)) : uri;
        setLoaded({
          displayName: doc.displayName,
          path,
          pageCount: doc.pageCount,
          lastPage: Math.min(doc.lastPage, Math.max(0, doc.pageCount - 1)),
        });
        setPage(Math.min(doc.lastPage, Math.max(0, doc.pageCount - 1)));
      } catch {
        if (active) setError(t.genericError);
      }
    })();
    return () => {
      active = false;
    };
  }, [docId]);

  const onPageSelected = useCallback(
    (selected: number) => {
      setPage(selected);
      void savePosition(docId, bookId, selected, 0);
    },
    [docId, bookId],
  );

  const toggleDark = useCallback(() => {
    setDark((current) => {
      setReaderDark(!current);
      return !current;
    });
  }, []);

  const toggleTextMode = useCallback(() => {
    setTextMode((current) => {
      setReaderTextMode(docId, !current);
      return !current;
    });
  }, [docId]);

  // القارئ يستخدم لوحته اللونية الخاصة المستقلة عن ثيم التطبيق، كما في التطبيق الأصلي،
  // مع عكس ألوان الصفحات في الوضع الداكن ليكون العكس متناسقًا.
  const palette = dark ? md3DarkColors : md3LightColors;

  if (error) {
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: palette.background,
          alignItems: 'center',
          justifyContent: 'center',
          padding: spacing.m,
        }}
      >
        <StatusBar style={dark ? 'light' : 'dark'} />
        <Text style={{ color: palette.onSurfaceVariant, textAlign: 'center' }}>{error}</Text>
        <Button onPress={() => navigation.goBack()} style={{ marginTop: spacing.s }}>
          {t.back}
        </Button>
      </View>
    );
  }

  if (!loaded) {
    return (
      <View style={{ flex: 1, backgroundColor: palette.background, alignItems: 'center', justifyContent: 'center' }}>
        <Loading />
      </View>
    );
  }

  const pageCount = loaded.pageCount;
  const progress = Math.round(((page + 1) / pageCount) * 100);

  return (
    <View style={{ flex: 1, backgroundColor: palette.background }}>
      <StatusBar style={dark ? "light" : "dark"} />
      <View style={{ backgroundColor: palette.surface }}>
        <ReaderToolbar
          title={loaded.displayName}
          pageLabel={t.pdfPageOf(page + 1, pageCount, progress)}
          titleColor={palette.onSurface}
          labelColor={palette.onSurfaceVariant}
          iconColor={palette.onSurfaceVariant}
          dark={dark}
          textMode={textMode}
          onBack={() => navigation.goBack()}
          onToggleDark={toggleDark}
          onToggleTextMode={toggleTextMode}
          onOpenNavigation={() => setNavVisible(true)}
          onOpenSettings={() => setSettingsVisible(true)}
        />
      </View>
      <ReaderPager
        path={loaded.path}
        pageCount={pageCount}
        initialPage={loaded.lastPage}
        textMode={textMode}
        invert={dark}
        textSize={textSize}
        lineSpacing={lineSpacing}
        textFont={textFont}
        colors={{
          loading: palette.primary,
          hint: palette.onSurfaceVariant,
          text: palette.onSurface,
        }}
        onPageSelected={onPageSelected}
      />
      <ReaderSettingsSheet
        visible={settingsVisible}
        onDismiss={() => setSettingsVisible(false)}
        textMode={textMode}
        onTextModeChange={toggleTextMode}
        textSize={textSize}
        onTextSizeChange={(value) => {
          setTextSize(value);
          setReaderTextSize(value);
        }}
        lineSpacing={lineSpacing}
        onLineSpacingChange={(value) => {
          setLineSpacing(value);
          setReaderTextSpacing(value);
        }}
        textFont={textFont}
        onTextFontChange={(value) => {
          setTextFont(value);
          setReaderTextFont(value);
        }}
        onDone={() => setSettingsVisible(false)}
        colors={{
          surface: palette.surfaceContainerHigh,
          onSurface: palette.onSurface,
          hint: palette.onSurfaceVariant,
          primary: palette.primary,
          outlineVariant: palette.outlineVariant,
        }}
      />
      <ReaderNavSheet
        visible={navVisible}
        onDismiss={() => setNavVisible(false)}
        pageCount={pageCount}
        currentPage={page}
        path={loaded.path}
        invert={dark}
        onSelect={(selected) => {
          setNavVisible(false);
          setPage(selected);
          void savePosition(docId, bookId, selected, 0);
        }}
      />
    </View>
  );
}
