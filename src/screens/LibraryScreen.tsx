// Ported from app/src/main/java/com/waraq/app/ui/library/LibraryFragment.java
import React, { useMemo, useState } from 'react';
import { Alert, StyleSheet, View } from 'react-native';
import { ActivityIndicator, Button, Text, TextInput } from 'react-native-paper';
import { FlashList } from '@shopify/flash-list';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import * as DocumentPicker from 'expo-document-picker';
import {
  categoryUsage,
  deleteBook,
  FILTER_ALL,
  loadBooks,
  SORT_ADDED,
  SORT_AUTHOR,
  SORT_LAST_READ,
  SORT_PROGRESS,
  SORT_RATING,
  SORT_RECENT,
  SORT_TITLE,
  toggleBookFavorite,
} from '../data/repos/books';
import { importPdfToBook } from '../data/repos/pdf';
import { getLibraryView, setLibraryView } from '../lib/prefs';
import { bookStatusLabel, bookStatusList } from '../lib/labels';
import { t } from '../lib/strings';
import { useRefreshOnFocus } from '../lib/useRefreshOnFocus';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { BookCard } from '../components/BookCard';
import { ChoiceDialog, ConfirmDialog } from '../components/ChoiceDialog';
import { EmptyState, Loading } from '../components/Layout';
import { FilterPills } from '../components/FilterPills';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function LibraryScreen() {
  const navigation = useNavigation<Nav>();
  const { colors, spacing } = useAppTheme();
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<number>(FILTER_ALL);
  const [sort, setSort] = useState(SORT_RECENT);
  const [categoryId, setCategoryId] = useState<number | null>(null);
  const [grid, setGrid] = useState(() => getLibraryView() === 'grid');
  const [sortOpen, setSortOpen] = useState(false);
  const [categoryOpen, setCategoryOpen] = useState(false);
  const [importing, setImporting] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<{ bookId: number; title: string } | null>(null);

  const books = useQuery({
    queryKey: ['library', query, status, categoryId, sort],
    queryFn: () => loadBooks(query, status, categoryId, sort),
  });
  const categories = useQuery({ queryKey: ['categories-usage'], queryFn: categoryUsage });
  useRefreshOnFocus(books.refetch);
  useRefreshOnFocus(categories.refetch);

  const categoryOptions = useMemo(
    () => [
      { value: null as number | null, label: t.all },
      ...(categories.data ?? []).map((c) => ({ value: c.id as number | null, label: c.name })),
    ],
    [categories.data],
  );
  const statusOptions = useMemo(
    () => [
      { value: FILTER_ALL as number, label: t.all },
      ...bookStatusList.map((s) => ({ value: s as number, label: bookStatusLabel(s) })),
    ],
    [],
  );
  const sortOptions = [
    { value: SORT_RECENT, label: t.sortRecent },
    { value: SORT_TITLE, label: t.sortTitle },
    { value: SORT_AUTHOR, label: t.sortAuthor },
    { value: SORT_PROGRESS, label: t.sortProgress },
    { value: SORT_RATING, label: t.sortRating },
    { value: SORT_LAST_READ, label: t.sortLastRead },
    { value: SORT_ADDED, label: t.sortAdded },
  ];

  const toggleView = () => {
    const next = grid ? 'list' : 'grid';
    setGrid(next === 'grid');
    setLibraryView(next);
  };

  const pickPdf = async () => {
    try {
      const picked = await DocumentPicker.getDocumentAsync({ type: ['application/pdf'], copyToCacheDirectory: true });
      if (picked.canceled) return;
      setImporting(true);
      const doc = await importPdfToBook(0, picked.assets[0].uri, null, false);
      await books.refetch();
      navigation.navigate('PdfReader', { docId: doc.id, bookId: doc.bookId });
    } catch {
      Alert.alert(t.bookPdfImportFailed);
    } finally {
      setImporting(false);
    }
  };

  const showActions = (bookId: number, title: string) => {
    Alert.alert(title, undefined, [
      { text: t.edit, onPress: () => navigation.navigate('BookEdit', { bookId }) },
      {
        text: t.delete,
        style: 'destructive',
        onPress: () => setDeleteTarget({ bookId, title }),
      },
      {
        text: t.bookFavorite,
        onPress: async () => {
          await toggleBookFavorite(bookId);
          await books.refetch();
        },
      },
      { text: t.cancel, style: 'cancel' },
    ]);
  };

  const confirmDelete = async (bookId: number) => {
    await deleteBook(bookId, true);
    await books.refetch();
    await categories.refetch();
  };

  const list = books.data ?? [];
  const filtering = status !== FILTER_ALL || categoryId != null || query.trim().length > 0;

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: spacing.s }}>
      <View style={{ paddingHorizontal: spacing.m }}>
        <TextInput
          mode="outlined"
          placeholder={t.search}
          value={query}
          onChangeText={setQuery}
          right={<TextInput.Icon icon="magnify" />}
          style={{ backgroundColor: colors.surface, textAlign: 'right' }}
          outlineColor={colors.outline}
          activeOutlineColor={colors.accent}
        />
        <View style={{ marginTop: spacing.s }}>
          <FilterPills options={statusOptions} value={status} onChange={setStatus} />
        </View>
        <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s, flexWrap: 'wrap' }}>
          <Button mode="outlined" compact onPress={() => setSortOpen(true)} icon="sort">
            {sortOptions.find((x) => x.value === sort)?.label ?? t.sort}
          </Button>
          <Button mode="outlined" compact onPress={() => setCategoryOpen(true)} icon="tag-outline">
            {categoryId == null ? t.bookCategory : categories.data?.find((c) => c.id === categoryId)?.name ?? t.bookCategory}
          </Button>
          <Button mode="outlined" compact onPress={toggleView} icon={grid ? 'view-list' : 'view-grid'}>
            {t.libraryView}
          </Button>
        </View>
        <View style={{ flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between', marginTop: spacing.s }}>
          <Text variant="labelSmall" style={{ color: colors.textSecondary }}>
            {t.libraryCount(list.length)}
          </Text>
          <Button mode="contained-tonal" compact icon="file-pdf-box" onPress={pickPdf} loading={importing} disabled={importing}>
            {t.bookPickPdf}
          </Button>
        </View>
      </View>

      {books.isLoading ? (
        <Loading />
      ) : list.length === 0 ? (
        <View style={{ padding: spacing.m }}>
          <EmptyState
            title={filtering ? t.libraryNoMatch : t.emptyLibraryTitle}
            body={filtering ? t.librarySearchHint : t.emptyLibraryBody}
            action={
              filtering ? undefined : (
                <Button mode="contained" onPress={() => navigation.navigate('BookEdit')}>
                  {t.bookAdd}
                </Button>
              )
            }
          />
        </View>
      ) : (
        <FlashList
          key={grid ? 'grid' : 'list'}
          data={list}
          numColumns={grid ? 2 : 1}
          keyExtractor={(item) => String(item.id)}
          contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
          renderItem={({ item }) => (
            <BookCard
              book={item}
              grid={grid}
              onPress={() => navigation.navigate('BookDetail', { bookId: item.id })}
              onLongPress={() => showActions(item.id, item.title)}
            />
          )}
        />
      )}
      {importing ? (
        <View style={styles.overlay} pointerEvents="none">
          <ActivityIndicator color={colors.accent} />
          <Text variant="bodySmall" style={{ color: colors.textPrimary, marginTop: 8 }}>
            {t.bookPdfImporting}
          </Text>
        </View>
      ) : null}
      <ChoiceDialog
        visible={sortOpen}
        title={t.sort}
        options={sortOptions}
        value={sort}
        onSelect={setSort}
        onDismiss={() => setSortOpen(false)}
      />
      <ChoiceDialog
        visible={categoryOpen}
        title={t.bookCategory}
        options={categoryOptions}
        value={categoryId}
        onSelect={setCategoryId}
        onDismiss={() => setCategoryOpen(false)}
      />
      <ConfirmDialog
        visible={deleteTarget != null}
        title={t.bookDelete}
        message={t.bookDeleteMessage}
        confirmLabel={t.bookDeleteKeepEntries}
        destructive
        onConfirm={() => deleteTarget && confirmDelete(deleteTarget.bookId)}
        onDismiss={() => setDeleteTarget(null)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    bottom: 24,
    alignSelf: 'center',
    backgroundColor: 'rgba(0,0,0,0.08)',
    borderRadius: 16,
    paddingHorizontal: 20,
    paddingVertical: 12,
    alignItems: 'center',
  },
});
