import React, { useEffect, useState } from 'react';
import { Alert, Image, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Switch, Text, TextInput } from 'react-native-paper';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import * as DocumentPicker from 'expo-document-picker';
import * as ImagePicker from 'expo-image-picker';
import {
  createCategory,
  getBook,
  loadCategories,
  removeCover,
  saveBook,
  saveCover,
} from '../data/repos/books';
import { importPdfToBook } from '../data/repos/pdf';
import { bookStatusLabel, bookStatusList } from '../lib/labels';
import { bookStatuses } from '../lib/arabicText';
import { t } from '../lib/strings';
import { pagesError, parseIntOrNull, ratingError, titleError } from '../lib/validation';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { coverUri } from '../components/BookCard';
import { FilterPills } from '../components/FilterPills';
import { Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'BookEdit'>;

export function BookEditScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const bookId = route.params?.bookId ?? 0;
  const { colors, spacing, shape } = useAppTheme();

  const [title, setTitle] = useState('');
  const [author, setAuthor] = useState('');
  const [description, setDescription] = useState('');
  const [totalPages, setTotalPages] = useState('');
  const [currentPage, setCurrentPage] = useState('');
  const [categoryId, setCategoryId] = useState<number | null>(null);
  const [newCategory, setNewCategory] = useState('');
  const [status, setStatus] = useState<number>(bookStatuses.TO_READ);
  const [rating, setRating] = useState<number | null>(null);
  const [favorite, setFavorite] = useState(false);
  const [cover, setCover] = useState<string | null>(null);
  const [pendingCover, setPendingCover] = useState<string | null>(null);
  const [coverRemoved, setCoverRemoved] = useState(false);
  const [pdf, setPdf] = useState<{ uri: string; name: string } | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const book = useQuery({ queryKey: ['book-edit', bookId], queryFn: () => getBook(bookId), enabled: bookId > 0 });
  const categories = useQuery({ queryKey: ['categories'], queryFn: loadCategories });

  useEffect(() => {
    const data = book.data;
    if (!data) return;
    setTitle(data.title);
    setAuthor(data.author ?? '');
    setDescription(data.description ?? '');
    setTotalPages(data.totalPages == null ? '' : String(data.totalPages));
    setCurrentPage(String(data.currentPage));
    setCategoryId(data.categoryId);
    setStatus(data.status);
    setRating(data.rating);
    setFavorite(!!data.favorite);
    setCover(data.coverPath);
  }, [book.data]);

  const pickCover = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.9 });
    if (result.canceled) return;
    setPendingCover(result.assets[0].uri);
    setCoverRemoved(false);
  };

  const pickPdf = async () => {
    const picked = await DocumentPicker.getDocumentAsync({ type: ['application/pdf'], copyToCacheDirectory: true });
    if (picked.canceled) return;
    const asset = picked.assets[0];
    const name = asset.name ?? 'PDF';
    setPdf({ uri: asset.uri, name });
    if (!title.trim()) setTitle(name.replace(/\.pdf$/i, ''));
  };

  const save = async () => {
    if (saving) return;
    const titleMessage = titleError(title.trim());
    if (titleMessage) {
      setError(titleMessage);
      return;
    }
    const total = parseIntOrNull(totalPages);
    const current = parseIntOrNull(currentPage) ?? 0;
    if (totalPages.trim() && total == null) {
      setError('إجمالي الصفحات يجب أن يكون أكبر من صفر');
      return;
    }
    const pagesMessage = pagesError(total, current);
    if (pagesMessage) {
      setError(pagesMessage);
      return;
    }
    const ratingMessage = ratingError(rating);
    if (ratingMessage) {
      setError(ratingMessage);
      return;
    }
    setError(null);
    setSaving(true);
    try {
      const id = await saveBook({
        id: bookId || undefined,
        title: title.trim(),
        author: author.trim() || null,
        description: description.trim() || null,
        coverPath: coverRemoved ? null : cover,
        categoryId,
        status,
        rating,
        totalPages: total,
        currentPage: current,
        favorite: favorite ? 1 : 0,
        createdAt: book.data?.createdAt ?? Date.now(),
        updatedAt: Date.now(),
        startedAt: book.data?.startedAt ?? null,
        finishedAt: book.data?.finishedAt ?? null,
      });
      if (coverRemoved) await removeCover(id);
      if (pendingCover) await saveCover(id, pendingCover);
      const categoryName = newCategory.trim();
      if (categoryName) {
        await createCategory(categoryName);
        const refreshed = await loadCategories();
        const match = refreshed.find((c) => c.name.trim() === categoryName);
        if (match) {
          await saveBook({
            ...(await getBook(id)),
            categoryId: match.id,
          });
        }
      }
      if (pdf) {
        try {
          await importPdfToBook(id, pdf.uri, author.trim() || null, false);
        } catch (err) {
          if (err instanceof Error && err.message === 'pdf-already-linked') {
            Alert.alert(t.bookPdfImportFailed);
          } else {
            Alert.alert(t.bookPdfImportFailed);
          }
        }
      }
      navigation.goBack();
    } catch {
      setError(t.genericError);
    } finally {
      setSaving(false);
    }
  };

  if (bookId > 0 && book.isLoading) return <Loading />;

  const categoryOptions = [
    { value: -1, label: t.none },
    ...(categories.data ?? []).map((c) => ({ value: c.id, label: c.name })),
  ];

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
      keyboardShouldPersistTaps="handled"
    >
      <Card style={{ backgroundColor: colors.surfaceContainerLow, marginBottom: spacing.m }}>
        <Card.Content style={{ gap: spacing.s }}>
          <TextInput mode="outlined" label={t.bookTitle} value={title} onChangeText={setTitle} error={!!error && !title.trim()} style={inputStyle(colors)} />
          <TextInput mode="outlined" label={t.bookAuthor} value={author} onChangeText={setAuthor} style={inputStyle(colors)} />
          <TextInput
            mode="outlined"
            label={t.bookDescription}
            value={description}
            onChangeText={setDescription}
            multiline
            numberOfLines={4}
            style={inputStyle(colors)}
          />
          <View style={{ flexDirection: 'row-reverse', gap: spacing.s }}>
            <TextInput
              mode="outlined"
              label={t.bookTotalPages}
              value={totalPages}
              onChangeText={setTotalPages}
              keyboardType="number-pad"
              style={[inputStyle(colors), { flex: 1 }]}
            />
            <TextInput
              mode="outlined"
              label={t.bookCurrentPage}
              value={currentPage}
              onChangeText={setCurrentPage}
              keyboardType="number-pad"
              style={[inputStyle(colors), { flex: 1 }]}
            />
          </View>
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between' }}>
            <Text variant="bodyMedium" style={{ color: colors.onSurface }}>
              {t.bookFavorite}
            </Text>
            <Switch value={favorite} onValueChange={setFavorite} color={colors.primary} />
          </View>
        </Card.Content>
      </Card>

      <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right', marginBottom: spacing.s }}>
        {t.bookStatus}
      </Text>
      <FilterPills
        options={bookStatusList.map((s) => ({ value: s as number, label: bookStatusLabel(s) }))}
        value={status}
        onChange={setStatus}
      />

      <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right', marginTop: spacing.m, marginBottom: spacing.s }}>
        {t.bookRating}
      </Text>
      <FilterPills
        options={[0, 1, 2, 3, 4, 5].map((r) => ({ value: r, label: r === 0 ? t.bookNoRating : String(r) }))}
        value={rating ?? 0}
        onChange={(v) => setRating(v === 0 ? null : v)}
      />

      <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right', marginTop: spacing.m, marginBottom: spacing.s }}>
        {t.bookCategory}
      </Text>
      <FilterPills options={categoryOptions} value={categoryId ?? -1} onChange={(value) => setCategoryId(value === -1 ? null : Number(value))} />
      <TextInput
        mode="outlined"
        label={t.categoryNew}
        value={newCategory}
        onChangeText={setNewCategory}
        style={[inputStyle(colors), { marginTop: spacing.s }]}
      />

      <Card style={{ backgroundColor: colors.surfaceContainerLow, marginTop: spacing.m }}>
        <Card.Content style={{ gap: spacing.s }}>
          <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>
            {t.bookOrganize}
          </Text>
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.m }}>
            {pendingCover || (!coverRemoved && cover) ? (
              <Image
                source={{ uri: pendingCover ?? coverUri(cover) ?? undefined }}
                style={{ width: 72, height: 100, borderRadius: shape.s8, backgroundColor: colors.surfaceContainerHigh }}
              />
            ) : (
              <View style={{ width: 72, height: 100, borderRadius: shape.s8, backgroundColor: colors.surfaceContainerHigh }} />
            )}
            <View style={{ flex: 1, gap: spacing.s }}>
              <Button mode="outlined" icon="image-outline" onPress={pickCover}>
                الغلاف
              </Button>
              {pendingCover || (!coverRemoved && cover) ? (
                <Button
                  mode="text"
                  textColor={colors.error}
                  onPress={() => {
                    setPendingCover(null);
                    setCover(null);
                    setCoverRemoved(true);
                  }}
                >
                  إزالة الغلاف
                </Button>
              ) : null}
            </View>
          </View>
          <Button mode="outlined" icon="file-pdf-box" onPress={pickPdf}>
            {pdf ? t.bookPdfChosen(pdf.name) : t.bookPickPdf}
          </Button>
          <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
            {t.bookPdfNone}
          </Text>
        </Card.Content>
      </Card>

      {error ? (
        <Text variant="bodyMedium" style={{ color: colors.error, textAlign: 'right', marginTop: spacing.s }}>
          {error}
        </Text>
      ) : null}
      <Button mode="contained" onPress={save} loading={saving} disabled={saving} style={{ marginTop: spacing.m }}>
        {t.save}
      </Button>
    </ScrollView>
  );
}

function inputStyle(colors: ReturnType<typeof useAppTheme>['colors']) {
  return { backgroundColor: colors.surface, textAlign: 'right' as const };
}
