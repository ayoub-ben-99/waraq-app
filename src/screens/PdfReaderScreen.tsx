import React, { useEffect, useRef, useState } from 'react';
import { View } from 'react-native';
import { Button, Text } from 'react-native-paper';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import * as FS from 'expo-file-system/legacy';
import {
  onReaderClosed,
  onReaderHighlight,
  onReaderProgress,
  openReader,
} from '../features/pdf/native';
import {
  addHighlight,
  documentById,
  highlightsFor,
  savePosition,
} from '../data/repos/pdf';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'PdfReader'>;

export function PdfReaderScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const { docId, bookId } = route.params;
  const { colors, spacing } = useAppTheme();
  const [error, setError] = useState<string | null>(null);
  const docRef = useRef<Awaited<ReturnType<typeof documentById>>>(null);

  useEffect(() => {
    const subscriptions = [onReaderClosed(() => navigation.goBack())];
    let active = true;
    void (async () => {
      try {
        const doc = await documentById(docId);
        docRef.current = doc;
        if (!doc || !active) {
          setError(t.genericError);
          return;
        }
        const highlights = await highlightsFor(doc.id);
        if (!active) return;
        subscriptions.push(
          onReaderProgress((payload) => {
            if (payload.bookId !== bookId) return;
            void savePosition(docId, bookId, payload.page, payload.offset);
          }),
          onReaderHighlight((payload) => {
            if (payload.bookId !== bookId) return;
            void addHighlight(doc, payload.page, payload.rects, payload.text, payload.color);
          }),
        );
        const path = doc.localPath ? `${FS.documentDirectory}${doc.localPath}` : null;
        if (!path) {
          setError(t.genericError);
          return;
        }
        await openReader(bookId, path, doc.lastPage, JSON.stringify(highlights));
      } catch {
        if (active) setError(t.genericError);
      }
    })();
    return () => {
      active = false;
      for (const subscription of subscriptions) subscription.remove();
    };
  }, [bookId, docId, navigation]);

  if (error) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center', padding: spacing.m }}>
        <Text style={{ color: colors.onSurfaceVariant, textAlign: 'center' }}>{error}</Text>
        <Button onPress={() => navigation.goBack()} style={{ marginTop: spacing.s }}>{t.back}</Button>
      </View>
    );
  }
  return (
    <View style={{ flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' }}>
      <Loading />
    </View>
  );
}
