import React, { useEffect, useRef, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Text, TextInput } from 'react-native-paper';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { getBook } from '../data/repos/books';
import { loadSummary, saveSummary } from '../data/repos/summaries';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'Summary'>;

type Form = {
  coreIdea: string;
  keyIdeas: string;
  learned: string;
  agreeDisagree: string;
  applications: string;
  questions: string;
  freeText: string;
};

const empty: Form = {
  coreIdea: '',
  keyIdeas: '',
  learned: '',
  agreeDisagree: '',
  applications: '',
  questions: '',
  freeText: '',
};

export function SummaryScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const bookId = route.params.bookId;
  const { colors, spacing } = useAppTheme();
  const [mode, setMode] = useState<'template' | 'free'>('template');
  const [form, setForm] = useState<Form>(empty);
  const loaded = useRef(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [status, setStatus] = useState('');

  const query = useQuery({
    queryKey: ['summary', bookId],
    queryFn: async () => {
      const [book, summary] = await Promise.all([getBook(bookId), loadSummary(bookId)]);
      return { book, summary };
    },
  });

  useEffect(() => {
    if (!query.data || loaded.current) return;
    const summary = query.data.summary;
    if (summary) {
      setForm({
        coreIdea: summary.coreIdea ?? '',
        keyIdeas: summary.keyIdeas ?? '',
        learned: summary.learned ?? '',
        agreeDisagree: summary.agreeDisagree ?? '',
        applications: summary.applications ?? '',
        questions: summary.questions ?? '',
        freeText: summary.freeText ?? '',
      });
      const hasFree = !!summary.freeText?.trim();
      const hasTemplate = [summary.coreIdea, summary.keyIdeas, summary.learned, summary.agreeDisagree, summary.applications, summary.questions].some((v) => !!v?.trim());
      setMode(hasFree && !hasTemplate ? 'free' : 'template');
    }
    loaded.current = true;
  }, [query.data]);

  useEffect(() => {
    if (!loaded.current) return;
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => {
      void persist(false);
    }, 900);
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
  }, [form]);

  const persist = async (showToast: boolean) => {
    await saveSummary({
      bookId,
      coreIdea: form.coreIdea || null,
      keyIdeas: form.keyIdeas || null,
      learned: form.learned || null,
      agreeDisagree: form.agreeDisagree || null,
      applications: form.applications || null,
      questions: form.questions || null,
      freeText: form.freeText || null,
    });
    setStatus(t.summarySaved);
    if (showToast) navigation.goBack();
  };

  if (query.isLoading) return <Loading />;

  const field = (key: keyof Form, label: string, lines = 3) => (
    <TextInput
      mode="outlined"
      label={label}
      value={form[key]}
      onChangeText={(value) => {
        setStatus('');
        setForm((f) => ({ ...f, [key]: value }));
      }}
      multiline
      numberOfLines={lines}
      style={{ backgroundColor: colors.surface, textAlign: 'right' }}
      outlineColor={colors.outline}
      activeOutlineColor={colors.primary}
    />
  );

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
      keyboardShouldPersistTaps="handled"
    >
      <Text variant="titleLarge" style={{ color: colors.onSurface, textAlign: 'right' }}>
        {query.data?.book.title ?? ''}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.primary, textAlign: 'right', marginBottom: spacing.m }}>
        {t.bookSummary}
      </Text>

      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginBottom: spacing.m }}>
        <Button mode={mode === 'template' ? 'contained' : 'outlined'} onPress={() => setMode('template')} style={{ flex: 1 }}>
          {t.summaryTemplate}
        </Button>
        <Button mode={mode === 'free' ? 'contained' : 'outlined'} onPress={() => setMode('free')} style={{ flex: 1 }}>
          {t.summaryFree}
        </Button>
      </View>

      <Card style={{ backgroundColor: colors.surfaceContainerLow }}>
        <Card.Content style={{ gap: spacing.s }}>
          {mode === 'template' ? (
            <>
              {field('coreIdea', t.summaryCore)}
              {field('keyIdeas', t.summaryKeyIdeas, 4)}
              {field('learned', t.summaryLearned)}
              {field('agreeDisagree', t.summaryAgree)}
              {field('applications', t.summaryApply)}
              {field('questions', t.summaryQuestions)}
            </>
          ) : (
            field('freeText', t.summaryFree, 12)
          )}
        </Card.Content>
      </Card>

      <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.s }}>
        {status}
      </Text>
      <Button mode="contained" onPress={() => persist(true)} style={{ marginTop: spacing.m }}>
        {t.save}
      </Button>
    </ScrollView>
  );
}
