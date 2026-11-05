// Ported from app/src/main/java/com/waraq/app/ui/knowledge/EntryEditActivity.java
import React, { useEffect, useRef, useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Checkbox, Text, TextInput } from 'react-native-paper';
import { DateTimePickerAndroid } from '@react-native-community/datetimepicker';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { allBooks, getBook } from '../data/repos/books';
import {
  getEntry,
  joinTags,
  parseTags,
  saveEntry,
  tagsOf,
} from '../data/repos/knowledge';
import { addToReview, isInReview, removeFromReview } from '../data/repos/review';
import { clearDraft, hasDraftContent, loadDraft, saveDraft, type Draft } from '../data/draftStore';
import { entryTypes } from '../lib/arabicText';
import { format, startOfDay } from '../lib/dates';
import { entryTypeLabel, entryTypeList } from '../lib/labels';
import { t } from '../lib/strings';
import { parseIntOrNull } from '../lib/validation';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { ChoiceDialog } from '../components/ChoiceDialog';
import { FilterPills } from '../components/FilterPills';
import { Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'EntryEdit'>;

export function EntryEditScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const entryId = route.params?.entryId ?? 0;
  const { colors, spacing, fonts } = useAppTheme();

  const [type, setType] = useState(route.params?.type ?? entryTypes.BENEFIT);
  const [title, setTitle] = useState('');
  const [quote, setQuote] = useState('');
  const [comment, setComment] = useState('');
  const [page, setPage] = useState(route.params?.page ? String(route.params.page) : '');
  const [tags, setTags] = useState('');
  const [favorite, setFavorite] = useState(false);
  const [inReview, setInReview] = useState(false);
  const [review, setReview] = useState(false);
  const [date, setDate] = useState(startOfDay(Date.now()));
  const [bookId, setBookId] = useState<number | null>(route.params?.bookId ?? null);
  const [bookOpen, setBookOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const loaded = useRef(false);
  const stateRef = useRef({ type, title, quote, comment, tags, page, date, bookId });
  stateRef.current = { type, title, quote, comment, tags, page, date, bookId };

  const query = useQuery({
    queryKey: ['entry-edit', entryId],
    queryFn: async () => {
      if (!entryId) return { entry: null, tagText: '', inReview: false, books: await allBooks(), book: null };
      const [entry, tagRows, reviewing, books] = await Promise.all([
        getEntry(entryId),
        tagsOf(entryId),
        isInReview(entryId),
        allBooks(),
      ]);
      const book = entry?.bookId ? await getBook(entry.bookId) : null;
      return { entry, tagText: joinTags(tagRows), inReview: reviewing, books, book };
    },
  });

  useEffect(() => {
    const data = query.data;
    if (!data || loaded.current) return;
    if (data.entry) {
      const entry = data.entry;
      setType(entry.type);
      setTitle(entry.title ?? '');
      setQuote(entry.quoteText ?? '');
      setComment(entry.comment ?? '');
      setPage(entry.page == null ? '' : String(entry.page));
      setTags(data.tagText);
      setFavorite(!!entry.favorite);
      setDate(entry.date);
      setBookId(entry.bookId);
      setInReview(data.inReview);
      setReview(data.inReview);
      const draft = loadDraft(entryId);
      if (draft && draft.savedAt > entry.updatedAt) {
        applyDraft(draft);
        Alert.alert(t.entryDraftRestored);
      }
    } else {
      const draft = loadDraft(0);
      if (draft && hasDraftContent(draft)) {
        applyDraft(draft);
        Alert.alert(t.entryDraftRestored);
      }
    }
    loaded.current = true;
  }, [query.data, entryId]);

  const applyDraft = (draft: Draft) => {
    setType(draft.type);
    setTitle(draft.title);
    setQuote(draft.quote);
    setComment(draft.comment);
    setTags(draft.tags);
    setPage(draft.page == null ? '' : String(draft.page));
    setDate(draft.date);
    setBookId(draft.bookId || null);
  };

  useEffect(() => {
    if (!loaded.current) return;
    const timer = setTimeout(() => {
      const snapshot = stateRef.current;
      const draft: Draft = {
        entryId,
        type: snapshot.type,
        title: snapshot.title,
        quote: snapshot.quote,
        comment: snapshot.comment,
        tags: snapshot.tags,
        page: parseIntOrNull(snapshot.page),
        bookId: snapshot.bookId ?? 0,
        date: snapshot.date,
        savedAt: Date.now(),
      };
      if (hasDraftContent(draft)) saveDraft(draft);
    }, 700);
    return () => clearTimeout(timer);
  }, [type, title, quote, comment, tags, page, date, bookId, entryId]);

  useEffect(
    () => () => {
      const snapshot = stateRef.current;
      const draft: Draft = {
        entryId,
        type: snapshot.type,
        title: snapshot.title,
        quote: snapshot.quote,
        comment: snapshot.comment,
        tags: snapshot.tags,
        page: parseIntOrNull(snapshot.page),
        bookId: snapshot.bookId ?? 0,
        date: snapshot.date,
        savedAt: Date.now(),
      };
      if (hasDraftContent(draft)) saveDraft(draft);
    },
    [entryId],
  );

  const pickDate = () => {
    DateTimePickerAndroid.open({
      value: new Date(date),
      mode: 'date',
      is24Hour: true,
      onChange: (_event, selected) => {
        if (selected) setDate(startOfDay(selected.getTime()));
      },
    });
  };

  const save = async () => {
    if (saving) return;
    if (!quote.trim() && !comment.trim() && !title.trim()) {
      setError(t.entryTextRequired);
      return;
    }
    const pageValue = parseIntOrNull(page);
    if (pageValue != null && pageValue < 0) {
      setError(t.errorPagePositive);
      return;
    }
    setError(null);
    setSaving(true);
    try {
      const id = await saveEntry(
        {
          id: entryId || undefined,
          type,
          title: title.trim() || null,
          quoteText: quote.trim() || null,
          comment: comment.trim() || null,
          bookId,
          page: pageValue,
          date,
          favorite,
        },
        parseTags(tags),
      );
      if (review) {
        await addToReview(id);
      } else if (inReview) {
        await removeFromReview(id);
      }
      clearDraft(entryId);
      Alert.alert(t.entrySaved);
      navigation.goBack();
    } catch {
      setError(t.genericError);
    } finally {
      setSaving(false);
    }
  };

  if (query.isLoading) return <Loading />;
  const data = query.data;
  const bookOptions = [
    { value: null as number | null, label: t.entryBookNone },
    ...(data?.books ?? []).map((book) => ({ value: book.id as number | null, label: book.title })),
  ];
  const selectedBook = data?.books.find((book) => book.id === bookId);
  const isQuote = type === entryTypes.QUOTE;

  return (
    <ScrollView
      style={{ backgroundColor: colors.bg }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
      keyboardShouldPersistTaps="handled"
    >
      <Text variant="labelMedium" style={{ color: colors.accent, textAlign: 'right', marginBottom: spacing.s }}>
        {entryId ? t.entryEdit : t.entryNew}
      </Text>
      <FilterPills
        options={entryTypeList.map((x) => ({ value: x as number, label: entryTypeLabel(x) }))}
        value={type}
        onChange={setType}
      />

      <TextInput mode="outlined" label={t.entryTitle} value={title} onChangeText={setTitle} style={inputStyle(colors)} />
      <TextInput
        mode="outlined"
        label={t.entryQuoteText}
        value={quote}
        onChangeText={setQuote}
        multiline
        numberOfLines={isQuote ? 6 : 4}
        style={[inputStyle(colors), { marginTop: spacing.s, fontFamily: isQuote ? fonts.quote : fonts.regular, fontSize: isQuote ? 19 : 15 }]}
      />
      <TextInput
        mode="outlined"
        label={t.entryComment}
        value={comment}
        onChangeText={setComment}
        multiline
        numberOfLines={4}
        style={[inputStyle(colors), { marginTop: spacing.s }]}
      />
      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s }}>
        <TextInput
          mode="outlined"
          label={t.entryPage}
          value={page}
          onChangeText={setPage}
          keyboardType="number-pad"
          style={[inputStyle(colors), { flex: 1 }]}
        />
        <Button mode="outlined" icon="calendar" onPress={pickDate} style={{ flex: 1, justifyContent: 'center' }}>
          {format(date)}
        </Button>
      </View>
      <TextInput
        mode="outlined"
        label={t.entryTags}
        value={tags}
        onChangeText={setTags}
        placeholder={t.entryTagsHint}
        style={[inputStyle(colors), { marginTop: spacing.s }]}
      />
      <Button mode="outlined" icon="book-outline" onPress={() => setBookOpen(true)} style={{ marginTop: spacing.s }}>
        {bookId ? selectedBook?.title ?? data?.book?.title ?? t.entryBook : t.entryBookNone}
      </Button>

      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between', marginTop: spacing.s }}>
        <Checkbox.Item
          label={t.entryFavorite}
          status={favorite ? 'checked' : 'unchecked'}
          onPress={() => setFavorite((v) => !v)}
          labelStyle={{ color: colors.textPrimary }}
          style={{ flexDirection: 'row-reverse' }}
        />
        <Checkbox.Item
          label={review ? t.entryInReview : t.entryAddReview}
          status={review ? 'checked' : 'unchecked'}
          onPress={() => setReview((v) => !v)}
          labelStyle={{ color: colors.textPrimary }}
          style={{ flexDirection: 'row-reverse' }}
        />
      </View>

      {error ? <Text style={{ color: colors.danger, textAlign: 'right', marginTop: spacing.s }}>{error}</Text> : null}
      <Button mode="contained" onPress={save} loading={saving} disabled={saving} style={{ marginTop: spacing.m }}>
        {t.save}
      </Button>
      <Button mode="text" onPress={() => navigation.goBack()} style={{ marginTop: spacing.xs }}>
        {t.cancel}
      </Button>

      <ChoiceDialog
        visible={bookOpen}
        title={t.pickBook}
        options={bookOptions}
        value={bookId}
        onSelect={setBookId}
        onDismiss={() => setBookOpen(false)}
      />
    </ScrollView>
  );
}

function inputStyle(colors: ReturnType<typeof useAppTheme>['colors']) {
  return { backgroundColor: colors.surface, textAlign: 'right' as const };
}
