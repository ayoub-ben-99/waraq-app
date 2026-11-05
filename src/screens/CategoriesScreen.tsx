// Ported from app/src/main/java/com/waraq/app/ui/library/CategoriesActivity.java
import React, { useState } from 'react';
import { Alert, ScrollView, StyleSheet } from 'react-native';
import { Button, Dialog, Portal, Text, TextInput } from 'react-native-paper';
import { useQuery } from '@tanstack/react-query';
import { categoryUsage, createCategory, deleteCategory, type CategoryUsage } from '../data/repos/books';
import { t } from '../lib/strings';
import { useAppTheme } from '../theme/ThemeProvider';
import { Loading } from '../components/Layout';

export function CategoriesScreen() {
  const { colors, spacing } = useAppTheme();
  const [name, setName] = useState('');
  const [addOpen, setAddOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<CategoryUsage | null>(null);

  const query = useQuery({ queryKey: ['categories'], queryFn: categoryUsage });

  const add = async () => {
    try {
      const created = await createCategory(name);
      if (!created) {
        setError(t.categoryExists);
        return;
      }
      setName('');
      setError(null);
      setAddOpen(false);
      await query.refetch();
    } catch {
      setError(t.genericError);
    }
  };

  const remove = async (category: CategoryUsage) => {
    setSelected(null);
    await deleteCategory(category.id);
    await query.refetch();
    Alert.alert(t.categoryDeleted);
  };

  if (query.isLoading) return <Loading />;

  return (
    <ScrollView style={{ backgroundColor: colors.background }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}>
      <Button mode="contained" icon="plus" onPress={() => setAddOpen(true)} style={{ marginBottom: spacing.m }}>
        {t.categoryNew}
      </Button>
      {(query.data ?? []).map((category) => (
        <Button
          key={category.id}
          mode="outlined"
          onPress={() => setSelected(category)}
          style={{ marginBottom: spacing.s, backgroundColor: colors.surface, borderColor: colors.outline }}
        >
          {category.name}
        </Button>
      ))}
      {query.data?.length === 0 ? (
        <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
          {t.none}
        </Text>
      ) : null}

      <Portal>
        <Dialog visible={addOpen} onDismiss={() => setAddOpen(false)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{t.categoryNew}</Dialog.Title>
          <Dialog.Content style={{ gap: spacing.s }}>
            <TextInput
              mode="outlined"
              label={t.categoryName}
              value={name}
              onChangeText={(value) => {
                setName(value);
                setError(null);
              }}
              style={{ backgroundColor: colors.surface, textAlign: 'right' }}
            />
            {error ? <Text style={{ color: colors.error }}>{error}</Text> : null}
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setAddOpen(false)}>{t.cancel}</Button>
            <Button mode="contained" onPress={add}>
              {t.add}
            </Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>

      <Portal>
        <Dialog visible={selected != null} onDismiss={() => setSelected(null)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{selected?.name}</Dialog.Title>
          <Dialog.Content>
            <Text style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
              {t.categoryUsed(selected?.count ?? 0)}
            </Text>
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setSelected(null)}>{t.cancel}</Button>
            <Button textColor={colors.error} onPress={() => selected && remove(selected)}>
              {t.delete}
            </Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>
    </ScrollView>
  );
}
