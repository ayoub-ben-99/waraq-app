import React, { useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Dialog, Portal, Text, TextInput } from 'react-native-paper';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import * as DocumentPicker from 'expo-document-picker';
import * as FS from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import {
  deleteBook,
  getBook,
  progressPercent,
  setBookStatus,
} from '../data/repos/books';
import { deleteEntry, entriesForBook } from '../data/repos/knowledge';
import { deleteSession, saveSession, sessionsForBook } from '../data/repos/sessions';
import { loadSummary } from '../data/repos/summaries';
import { documentForBook, importPdfToBook } from '../data/repos/pdf';
import { format, formatShort } from '../lib/dates';
import { bookStatusLabel, entryDisplayText, entryTypeLabel } from '../lib/labels';
import { sessionError, parseIntOrNull } from '../lib/validation';
import { t } from '../lib/strings';
import { useRefreshOnFocus } from '../lib/useRefreshOnFocus';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { shape } from '../theme/ThemeProvider';
import { BookCover } from '../components/BookCard';
import { ChoiceDialog } from '../components/ChoiceDialog';
import { EmptyState, Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'BookDetail'>;

export function BookDetailScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const bookId = route.params.bookId;
  const { colors, spacing, fonts } = useAppTheme();
  const [tab, setTab] = useState<'sessions' | 'entries' | 'summary'>('sessions');
  const [sessionOpen, setSessionOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [keepEntries, setKeepEntries] = useState(true);
  const [sessionForm, setSessionForm] = useState({ start: '', end: '', minutes: '', note: '' });
  const [sessionErrorText, setSessionErrorText] = useState<string | null>(null);
  const [statusOpen, setStatusOpen] = useState(false);

  const query = useQuery({
    queryKey: ['book-detail', bookId],
    queryFn: async () => {
      const [book, sessions, entries, summary, pdf] = await Promise.all([
        getBook(bookId),
        sessionsForBook(bookId),
        entriesForBook(bookId),
        loadSummary(bookId),
        documentForBook(bookId),
      ]);
      return { book, sessions, entries, summary, pdf };
    },
  });
  useRefreshOnFocus(query.refetch);
  const data = query.data;

  const exportNotes = async () => {
    if (!data) return;
    const entries = data.entries;
    if (entries.length === 0) {
      Alert.alert(t.bookExportEntries, t.emptyKnowledgeBody);
      return;
    }
    const lines: string[] = [data.book.title, data.book.author ?? '', ''];
    for (const entry of entries) {
      lines.push(`[${entryTypeLabel(entry.type)}] ${formatShort(entry.date)}`);
      if (entry.title?.trim()) lines.push(entry.title);
      const body = entryDisplayText(entry);
      if (body) lines.push(body);
      if (entry.comment?.trim() && entry.comment !== body) lines.push(`— ${entry.comment}`);
      if (entry.page != null) lines.push(`صفحة ${entry.page}`);
      lines.push('');
    }
    const path = `${FS.cacheDirectory}waraq-book-${bookId}-${Date.now()}.txt`;
    await FS.writeAsStringAsync(path, `\uFEFF${lines.join('\n')}`);
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(path, { mimeType: 'text/plain', dialogTitle: t.bookExportEntries });
    }
    await FS.deleteAsync(path, { idempotent: true });
  };

  const attachPdf = async (replace: boolean) => {
    try {
      const picked = await DocumentPicker.getDocumentAsync({ type: ['application/pdf'], copyToCacheDirectory: true });
      if (picked.canceled) return;
      await importPdfToBook(bookId, picked.assets[0].uri, data?.book.author ?? null, replace);
      const refreshed = await query.refetch();
      const doc = refreshed.data?.pdf;
      if (doc) navigation.navigate('PdfReader', { docId: doc.id, bookId });
    } catch (err) {
      if (err instanceof Error && err.message === 'pdf-already-linked') {
        Alert.alert(t.bookPdfImportFailed, undefined, [
          { text: t.cancel, style: 'cancel' },
          { text: t.bookChangePdf, onPress: () => attachPdf(true) },
        ]);
      } else {
        Alert.alert(t.bookPdfImportFailed);
      }
    }
  };

  const addSession = async () => {
    const start = parseIntOrNull(sessionForm.start);
    const end = parseIntOrNull(sessionForm.end);
    const minutes = parseIntOrNull(sessionForm.minutes);
    const message = sessionError(start, end, minutes, data?.book.totalPages ?? null);
    if (message) {
      setSessionErrorText(message);
      return;
    }
    try {
      const result = await saveSession(
        bookId,
        start as number,
        end as number,
        minutes as number,
        Date.now(),
        sessionForm.note.trim() || null,
        false,
      );
      setSessionOpen(false);
      setSessionForm({ start: '', end: '', minutes: '', note: '' });
      setSessionErrorText(null);
      if (result.duplicate) Alert.alert(t.sessionDuplicate);
      await query.refetch();
    } catch (err) {
      const code = err instanceof Error ? err.message : '';
      setSessionErrorText(
        code === 'beyond-total'
          ? t.sessionBeyondTotal
          : code === 'bad-end'
            ? t.sessionBadRange
            : code === 'bad-duration'
              ? t.sessionBadDuration
              : t.genericError,
      );
    }
  };

  if (query.isLoading) return <Loading />;
  if (!data) {
    return (
      <View style={{ padding: spacing.m }}>
        <EmptyState title={t.genericError} action={<Button onPress={() => query.refetch()}>{t.retry}</Button>} />
      </View>
    );
  }

  const { book, sessions, entries, summary, pdf } = data;
  const percent = progressPercent(book);
  const dates = [
    book.startedAt ? `${t.bookStarted}: ${format(book.startedAt)}` : null,
    book.finishedAt ? `${t.bookFinished}: ${format(book.finishedAt)}` : null,
  ].filter(Boolean);
  const summaryRows = summary
    ? [
      [t.summaryCore, summary.coreIdea],
      [t.summaryKeyIdeas, summary.keyIdeas],
      [t.summaryLearned, summary.learned],
      [t.summaryAgree, summary.agreeDisagree],
      [t.summaryApply, summary.applications],
      [t.summaryQuestions, summary.questions],
      [t.summaryFree, summary.freeText],
    ].filter(([, value]) => !!value && value.trim().length > 0)
    : [];

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
    >
      <View style={{ flexDirection: 'row-reverse', gap: spacing.m, alignItems: 'flex-start' }}>
        <BookCover book={book} size={92} />
        <View style={{ flex: 1 }}>
          <Text variant="headlineSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>
            {book.title}
          </Text>
          <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 2 }}>
            {book.author || '—'}
          </Text>
          <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s, flexWrap: 'wrap' }}>
            <Button compact mode="outlined" onPress={() => setStatusOpen(true)}>
              {bookStatusLabel(book.status)}
            </Button>
            <Text variant="labelMedium" style={{ color: colors.secondary, alignSelf: 'center' }}>
              {book.rating == null ? t.bookNoRating : `★ ${book.rating}`}
            </Text>
          </View>
        </View>
      </View>

      <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.s }}>
        {dates.length ? dates.join(' • ') : t.none}
      </Text>

      {book.description?.trim() ? (
        <Text variant="bodyMedium" style={{ color: colors.onSurface, textAlign: 'right', marginTop: spacing.m, lineHeight: 26 }}>
          {book.description}
        </Text>
      ) : null}

      <Card style={{ backgroundColor: colors.surfaceContainerLow, marginTop: spacing.m }}>
        <Card.Content>
          <Text variant="labelMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
            {t.bookProgress}
          </Text>
          {book.totalPages != null ? (
            <>
              <Text variant="titleLarge" style={{ color: colors.onSurface, textAlign: 'right' }}>
                {book.currentPage} / {book.totalPages}
                {percent >= 0 ? ` • ${percent}%` : ''}
              </Text>
              <View style={[styles.track, { backgroundColor: colors.surfaceContainerHigh, marginTop: spacing.s }]}>
                <View style={[styles.fill, { width: `${Math.max(0, percent)}%`, backgroundColor: colors.primary }]} />
              </View>
            </>
          ) : (
            <Text variant="titleMedium" style={{ color: colors.onSurface, textAlign: 'right' }}>
              {t.homeLastPosition(book.currentPage)}
            </Text>
          )}
        </Card.Content>
      </Card>

      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.m }}>
        <Button mode="contained-tonal" icon="book-open-variant" style={{ flex: 1 }} onPress={() => (pdf ? navigation.navigate('PdfReader', { docId: pdf.id, bookId }) : attachPdf(false))}>
          {pdf ? t.bookPdfOpen : t.bookPdfUnlinked}
        </Button>
        <Button mode="outlined" icon="pencil-outline" onPress={() => navigation.navigate('BookEdit', { bookId })}>
          {t.edit}
        </Button>
      </View>
      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s }}>
        <Button mode="outlined" icon="share-variant" style={{ flex: 1 }} onPress={exportNotes}>
          {t.bookExportEntries}
        </Button>
        <Button mode="text" textColor={colors.error} onPress={() => setDeleteOpen(true)}>
          {t.delete}
        </Button>
      </View>

      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.m }}>
        <Button mode={tab === 'sessions' ? 'contained' : 'outlined'} onPress={() => setTab('sessions')} style={{ flex: 1 }}>
          {t.bookSessions}
        </Button>
        <Button mode={tab === 'entries' ? 'contained' : 'outlined'} onPress={() => setTab('entries')} style={{ flex: 1 }}>
          {t.bookEntries}
        </Button>
        <Button mode={tab === 'summary' ? 'contained' : 'outlined'} onPress={() => setTab('summary')} style={{ flex: 1 }}>
          {t.bookSummary}
        </Button>
      </View>

      {tab === 'sessions' ? (
        <View style={{ marginTop: spacing.m }}>
          <Button mode="outlined" icon="plus" onPress={() => setSessionOpen(true)} style={{ marginBottom: spacing.s }}>
            {t.bookAddSession}
          </Button>
          {sessions.length === 0 ? (
            <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
              {t.emptySessions}
            </Text>
          ) : (
            sessions.map((session) => (
              <Card key={session.id} style={{ backgroundColor: colors.surfaceContainerLow, marginBottom: spacing.s }}>
                <Card.Content>
                  <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between' }}>
                    <Text variant="titleSmall" style={{ color: colors.onSurface }}>
                      {t.sessionPages(session.endPage - session.startPage)}
                    </Text>
                    <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
                      {session.durationMinutes} دقيقة
                    </Text>
                  </View>
                  <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 4 }}>
                    {format(session.date)} • {session.startPage}–{session.endPage}
                  </Text>
                  {session.note?.trim() ? (
                    <Text variant="bodySmall" style={{ color: colors.onSurface, textAlign: 'right', marginTop: 4 }}>
                      {session.note}
                    </Text>
                  ) : null}
                  <Button compact mode="text" textColor={colors.error} onPress={() => confirmDeleteSession(session.id)} style={{ alignSelf: 'flex-end' }}>
                    {t.sessionDelete}
                  </Button>
                </Card.Content>
              </Card>
            ))
          )}
        </View>
      ) : null}

      {tab === 'entries' ? (
        <View style={{ marginTop: spacing.m }}>
          <Button mode="outlined" icon="plus" onPress={() => navigation.navigate('EntryEdit', { bookId, type: 1 })} style={{ marginBottom: spacing.s }}>
            {t.entryNew}
          </Button>
          {entries.length === 0 ? (
            <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
              {t.emptyKnowledgeBody}
            </Text>
          ) : (
            entries.map((entry) => (
              <Card
                key={entry.id}
                style={{ backgroundColor: colors.surfaceContainerLow, marginBottom: spacing.s }}
                onPress={() => navigation.navigate('EntryEdit', { entryId: entry.id })}
                onLongPress={() =>
                  Alert.alert(t.entryDeleteTitle, t.entryDeleteMessage, [
                    { text: t.cancel, style: 'cancel' },
                    {
                      text: t.delete,
                      style: 'destructive',
                      onPress: async () => {
                        await deleteEntry(entry.id);
                        await query.refetch();
                      },
                    },
                  ])
                }
              >
                <Card.Content>
                  <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between' }}>
                    <Text variant="labelSmall" style={{ color: colors.primary }}>
                      {entryTypeLabel(entry.type)}
                    </Text>
                    <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
                      {formatShort(entry.date)}
                    </Text>
                  </View>
                  {entry.title?.trim() ? (
                    <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>
                      {entry.title}
                    </Text>
                  ) : null}
                  <Text
                    numberOfLines={4}
                    style={{
                      color: colors.onSurface,
                      textAlign: 'right',
                      fontFamily: entry.type === 0 ? fonts.quote : fonts.regular,
                      fontSize: entry.type === 0 ? 20 : 15,
                      lineHeight: entry.type === 0 ? 32 : 24,
                    }}
                  >
                    {entryDisplayText(entry)}
                  </Text>
                  {entry.page != null ? (
                    <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
                      {t.entryPageValue(entry.page)}
                    </Text>
                  ) : null}
                </Card.Content>
              </Card>
            ))
          )}
        </View>
      ) : null}

      {tab === 'summary' ? (
        <View style={{ marginTop: spacing.m }}>
          {summaryRows.length === 0 ? (
            <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginBottom: spacing.s }}>
              {t.none}
            </Text>
          ) : (
            summaryRows.map(([label, value]) => (
              <View key={String(label)} style={{ marginBottom: spacing.m }}>
                <Text variant="labelMedium" style={{ color: colors.primary, textAlign: 'right' }}>
                  {label}
                </Text>
                <Text variant="bodyMedium" style={{ color: colors.onSurface, textAlign: 'right', lineHeight: 26 }}>
                  {value}
                </Text>
              </View>
            ))
          )}
          <Button mode="outlined" onPress={() => navigation.navigate('Summary', { bookId })}>
            {t.edit}
          </Button>
        </View>
      ) : null}

      <Portal>
        <Dialog visible={sessionOpen} onDismiss={() => setSessionOpen(false)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{t.sessionTitle}</Dialog.Title>
          <Dialog.Content style={{ gap: spacing.s }}>
            <View style={{ flexDirection: 'row-reverse', gap: spacing.s }}>
              <TextInput mode="outlined" label={t.sessionStart} value={sessionForm.start} onChangeText={(start) => setSessionForm((f) => ({ ...f, start }))} keyboardType="number-pad" style={{ flex: 1, backgroundColor: colors.surface }} />
              <TextInput mode="outlined" label={t.sessionEnd} value={sessionForm.end} onChangeText={(end) => setSessionForm((f) => ({ ...f, end }))} keyboardType="number-pad" style={{ flex: 1, backgroundColor: colors.surface }} />
            </View>
            <TextInput mode="outlined" label={t.sessionDuration} value={sessionForm.minutes} onChangeText={(minutes) => setSessionForm((f) => ({ ...f, minutes }))} keyboardType="number-pad" style={{ backgroundColor: colors.surface }} />
            <TextInput mode="outlined" label={t.sessionNote} value={sessionForm.note} onChangeText={(note) => setSessionForm((f) => ({ ...f, note }))} multiline style={{ backgroundColor: colors.surface }} />
            {sessionErrorText ? <Text style={{ color: colors.error }}>{sessionErrorText}</Text> : null}
          </Dialog.Content>
          <Dialog.Actions>
            <Button mode="text" textColor={colors.onSurfaceVariant} onPress={() => setSessionOpen(false)}>{t.cancel}</Button>
            <Button mode="text" textColor={colors.primary} onPress={addSession}>{t.save}</Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>

      <ChoiceDialog
        visible={statusOpen}
        title={t.bookStatus}
        options={[0, 1, 2, 3, 4].map((s) => ({ value: s, label: bookStatusLabel(s) }))}
        value={book.status}
        onSelect={async (next) => {
          await setBookStatus(bookId, next);
          await query.refetch();
        }}
        onDismiss={() => setStatusOpen(false)}
      />

      <Portal>
        <Dialog visible={deleteOpen} onDismiss={() => setDeleteOpen(false)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{t.bookDelete}</Dialog.Title>
          <Dialog.Content>
            <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
              {t.bookDeleteMessage}
            </Text>
          </Dialog.Content>
          <Dialog.Actions style={{ flexDirection: 'column', alignItems: 'stretch', gap: 4 }}>
            <Button
              mode="text"
              textColor={colors.error}
              onPress={async () => {
                await deleteBook(bookId, true);
                navigation.goBack();
              }}
            >
              {t.bookDeleteKeepEntries}
            </Button>
            <Button
              mode="text"
              textColor={colors.error}
              onPress={async () => {
                await deleteBook(bookId, false);
                navigation.goBack();
              }}
            >
              {t.bookDeleteAll}
            </Button>
            <Button mode="text" onPress={() => setDeleteOpen(false)}>
              {t.cancel}
            </Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>
    </ScrollView>
  );

  function confirmDeleteSession(sessionId: number) {
    Alert.alert(t.sessionDelete, t.sessionDeleteMessage, [
      { text: t.cancel, style: 'cancel' },
      {
        text: t.delete,
        style: 'destructive',
        onPress: async () => {
          await deleteSession(sessionId);
          await query.refetch();
        },
      },
    ]);
  }
}

const styles = StyleSheet.create({
  track: { height: 6, borderRadius: shape.s4, overflow: 'hidden' },
  fill: { height: 6, borderRadius: shape.s4 },
});
