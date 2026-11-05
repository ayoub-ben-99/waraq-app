// Ported from app/src/main/java/com/waraq/app/ui/knowledge/KnowledgeFragment.java
import React, { useMemo, useState } from 'react';
import { Alert, View } from 'react-native';
import { Button, Text, TextInput } from 'react-native-paper';
import { FlashList } from '@shopify/flash-list';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import {
  allBooks,
} from '../data/repos/books';
import {
  allEntryTags,
  deleteEntry,
  listEntries,
  SORT_NEWEST,
  SORT_OLDEST,
  SORT_TITLE,
  toggleEntryFavorite,
  usedTags,
} from '../data/repos/knowledge';
import { allAudio } from '../features/audio/audioRepository';
import { entryTypeList, entryTypeLabel } from '../lib/labels';
import { t } from '../lib/strings';
import { useRefreshOnFocus } from '../lib/useRefreshOnFocus';
import type { RootStackParamList, TabParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { EntryCard } from '../components/EntryCard';
import { ChoiceDialog, ConfirmDialog } from '../components/ChoiceDialog';
import { EmptyState, Loading } from '../components/Layout';
import { FilterPills } from '../components/FilterPills';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<TabParamList, 'Knowledge'>;

export function KnowledgeScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const { colors, spacing } = useAppTheme();
  const [query, setQuery] = useState('');
  const [type, setType] = useState<number>(-1);
  const [tagId, setTagId] = useState<number | null>(null);
  const [sort, setSort] = useState(SORT_NEWEST);
  const [tagOpen, setTagOpen] = useState(false);
  const [sortOpen, setSortOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<number | null>(null);
  const [pendingTag, setPendingTag] = useState(route.params?.tag ?? null);

  const entries = useQuery({
    queryKey: ['knowledge', type, query, tagId, sort],
    queryFn: () => listEntries(type, false, query, tagId, sort),
  });
  const tags = useQuery({ queryKey: ['used-tags'], queryFn: usedTags });
  const links = useQuery({ queryKey: ['entry-tags'], queryFn: allEntryTags });
  const books = useQuery({ queryKey: ['all-books'], queryFn: allBooks });
  const audios = useQuery({ queryKey: ['audio'], queryFn: allAudio });
  useRefreshOnFocus(entries.refetch);
  useRefreshOnFocus(tags.refetch);
  useRefreshOnFocus(links.refetch);
  useRefreshOnFocus(audios.refetch);

  const tagOptions = useMemo(
    () => [{ value: null as number | null, label: t.knowledgeTagAll }, ...(tags.data ?? []).map((tag) => ({ value: tag.id as number | null, label: tag.name }))],
    [tags.data],
  );
  const typeOptions = useMemo(
    () => [
      { value: -1, label: t.all },
      ...entryTypeList.map((x) => ({ value: x as number, label: entryTypeLabel(x) })),
    ],
    [],
  );
  const sortOptions = [
    { value: SORT_NEWEST, label: t.sortRecent },
    { value: SORT_OLDEST, label: t.sortAdded },
    { value: SORT_TITLE, label: t.sortTitle },
  ];
  const tagsByEntry = useMemo(() => {
    const map = new Map<number, string[]>();
    for (const row of links.data ?? []) {
      const list = map.get(row.entryId) ?? [];
      list.push(row.name);
      map.set(row.entryId, list);
    }
    return map;
  }, [links.data]);
  React.useEffect(() => {
    if (!pendingTag || !tags.data) return;
    const match = tags.data.find((x) => x.name === pendingTag);
    if (match) setTagId(match.id);
    setPendingTag(null);
  }, [pendingTag, tags.data]);
  const bookNames = useMemo(() => new Map((books.data ?? []).map((b) => [b.id, b.title])), [books.data]);
  const audioIds = useMemo(() => new Set((audios.data ?? []).map((a) => a.entryId)), [audios.data]);
  const list = entries.data ?? [];

  const remove = async (id: number) => {
    await deleteEntry(id);
    await entries.refetch();
    await links.refetch();
    await tags.refetch();
    await audios.refetch();
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.background, paddingTop: spacing.s }}>
      <View style={{ paddingHorizontal: spacing.m }}>
        <TextInput
          mode="outlined"
          placeholder={t.search}
          value={query}
          onChangeText={setQuery}
          right={<TextInput.Icon icon="magnify" />}
          style={{ backgroundColor: colors.surface, textAlign: 'right' }}
          outlineColor={colors.outline}
          activeOutlineColor={colors.primary}
        />
        <View style={{ marginTop: spacing.s }}>
          <FilterPills options={typeOptions} value={type} onChange={setType} />
        </View>
        <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s }}>
          <Button mode="outlined" compact icon="tag-outline" onPress={() => setTagOpen(true)}>
            {tagId == null ? t.knowledgeTagAll : tags.data?.find((x) => x.id === tagId)?.name ?? t.knowledgeTagAll}
          </Button>
          <Button mode="outlined" compact icon="sort" onPress={() => setSortOpen(true)}>
            {sortOptions.find((x) => x.value === sort)?.label ?? t.sort}
          </Button>
          <Button
            mode="contained-tonal"
            compact
            icon="plus"
            onPress={() => navigation.navigate('EntryEdit', { type: 1 })}
          >
            {t.entryNew}
          </Button>
        </View>
        <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, marginTop: spacing.s, textAlign: 'right' }}>
          {t.libraryCount(list.length)}
        </Text>
      </View>

      {entries.isLoading ? (
        <Loading />
      ) : list.length === 0 ? (
        <View style={{ padding: spacing.m }}>
          <EmptyState
            title={tagId != null ? t.knowledgeEmptyTagTitle : t.emptyKnowledgeTitle}
            body={tagId != null ? t.knowledgeEmptyTagBody : t.emptyKnowledgeBody}
            action={
              <Button mode="contained" onPress={() => navigation.navigate('EntryEdit', { type: 1 })}>
                {t.entryNew}
              </Button>
            }
          />
        </View>
      ) : (
        <FlashList
          data={list}
          keyExtractor={(item) => String(item.id)}
          contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
          renderItem={({ item }) => {
            const isAudio = audioIds.has(item.id);
            const open = () =>
              isAudio
                ? navigation.navigate('AudioNote', { entryId: item.id, bookId: item.bookId ?? undefined, type: item.type })
                : navigation.navigate('EntryEdit', { entryId: item.id });
            return (
              <EntryCard
                entry={item}
                bookName={item.bookId ? bookNames.get(item.bookId) : undefined}
                tags={tagsByEntry.get(item.id)}
                hasAudio={isAudio}
                onPress={open}
                onLongPress={() =>
                  Alert.alert(item.title || entryTypeLabel(item.type), undefined, [
                    ...(isAudio
                      ? [{ text: t.audioPlay, onPress: open }]
                      : []),
                    { text: t.edit, onPress: () => navigation.navigate('EntryEdit', { entryId: item.id }) },
                    {
                      text: t.entryFavorite,
                      onPress: async () => {
                        await toggleEntryFavorite(item.id);
                        await entries.refetch();
                      },
                    },
                    { text: t.delete, style: 'destructive', onPress: () => setDeleteTarget(item.id) },
                    { text: t.cancel, style: 'cancel' },
                  ])
                }
              />
            );
          }}
        />
      )}

      <ChoiceDialog
        visible={tagOpen}
        title={t.entryTags}
        options={tagOptions}
        value={tagId}
        onSelect={setTagId}
        onDismiss={() => setTagOpen(false)}
      />
      <ChoiceDialog
        visible={sortOpen}
        title={t.sort}
        options={sortOptions}
        value={sort}
        onSelect={setSort}
        onDismiss={() => setSortOpen(false)}
      />
      <ConfirmDialog
        visible={deleteTarget != null}
        title={t.entryDeleteTitle}
        message={t.entryDeleteMessage}
        confirmLabel={t.delete}
        destructive
        onDismiss={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget != null && remove(deleteTarget)}
      />
    </View>
  );
}
