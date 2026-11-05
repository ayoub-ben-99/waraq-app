// Ported from app/src/main/java/com/waraq/app/ui/knowledge/AudioNoteActivity.java
import React, { useEffect, useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Text, TextInput } from 'react-native-paper';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import {
  AudioModule,
  RecordingPresets,
  setAudioModeAsync,
  useAudioPlayer,
  useAudioRecorder,
  useAudioRecorderState,
} from 'expo-audio';
import { attachAudio, audioUri, deleteRecording, getEntryAudio, renameAudioEntry } from '../features/audio/audioRepository';
import { getEntry } from '../data/repos/knowledge';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';

type Nav = NativeStackNavigationProp<RootStackParamList>;
type Route = RouteProp<RootStackParamList, 'AudioNote'>;

export function AudioNoteScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute<Route>();
  const entryId = route.params?.entryId ?? 0;
  const { colors, spacing } = useAppTheme();
  const [title, setTitle] = useState('');
  const [savedUri, setSavedUri] = useState<string | null>(null);
  const [savedDuration, setSavedDuration] = useState(0);
  const [hasSaved, setHasSaved] = useState(false);
  const [busy, setBusy] = useState(false);

  const recorder = useAudioRecorder(RecordingPresets.HIGH_QUALITY);
  const recorderState = useAudioRecorderState(recorder, 200);
  const player = useAudioPlayer(savedUri);

  useEffect(() => {
    void (async () => {
      const permission = await AudioModule.requestRecordingPermissionsAsync();
      if (!permission.granted) {
        Alert.alert(t.audioPermission);
        navigation.goBack();
        return;
      }
      await setAudioModeAsync({ playsInSilentMode: true, allowsRecording: true });
      if (entryId) {
        const [entry, audio] = await Promise.all([getEntry(entryId), getEntryAudio(entryId)]);
        if (entry?.title) setTitle(entry.title);
        if (audio) {
          setSavedUri(audioUri(audio.fileName));
          setSavedDuration(audio.durationMs);
          setHasSaved(true);
        }
      }
    })();
  }, [entryId, navigation]);

  const start = async () => {
    try {
      await recorder.prepareToRecordAsync();
      recorder.record();
    } catch {
      Alert.alert(t.genericError);
    }
  };

  const stop = async () => {
    try {
      const duration = recorderState.durationMillis;
      await recorder.stop();
      const uri = recorder.uri;
      if (!uri) return;
      setSavedDuration(duration);
      setSavedUri(uri);
      setHasSaved(true);
    } catch {
      Alert.alert(t.genericError);
    }
  };

  const save = async () => {
    if (!savedUri) {
      Alert.alert(t.audioRecord);
      return;
    }
    setBusy(true);
    try {
      await attachAudio(entryId, savedUri, savedDuration);
      if (title.trim()) await renameAudioEntry(entryId, title);
      Alert.alert(t.audioSaved);
      navigation.goBack();
    } catch {
      Alert.alert(t.genericError);
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    await deleteRecording(entryId);
    setSavedUri(null);
    setSavedDuration(0);
    setHasSaved(false);
  };

  return (
    <ScrollView style={{ backgroundColor: colors.bg }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}>
      <Text variant="titleLarge" style={{ color: colors.textPrimary, textAlign: 'right' }}>{t.audioTitle}</Text>
      <TextInput
        mode="outlined"
        label={t.entryTitle}
        value={title}
        onChangeText={setTitle}
        style={{ backgroundColor: colors.surface, textAlign: 'right', marginTop: spacing.m }}
      />

      <Card style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginTop: spacing.m }}>
        <Card.Content style={{ alignItems: 'center' }}>
          <Text variant="displaySmall" style={{ color: colors.accent, fontVariant: ['tabular-nums'] }}>
            {clock(recorderState.isRecording ? recorderState.durationMillis : savedDuration)}
          </Text>
          <Text variant="labelSmall" style={{ color: colors.textSecondary, marginBottom: spacing.m }}>
            {recorderState.isRecording ? t.audioRecord : hasSaved ? t.audioSaved : t.none}
          </Text>
          <View style={{ flexDirection: 'row-reverse', gap: spacing.s, flexWrap: 'wrap', justifyContent: 'center' }}>
            {!recorderState.isRecording ? (
              <Button mode="contained" icon="microphone" onPress={start}>{t.audioRecord}</Button>
            ) : (
              <Button mode="contained" buttonColor={colors.danger} textColor={colors.onDanger} icon="stop" onPress={stop}>
                {t.audioStop}
              </Button>
            )}
            {hasSaved && !recorderState.isRecording ? (
              <Button
                mode="outlined"
                icon={player.playing ? 'pause' : 'play'}
                onPress={() => {
                  if (player.playing) player.pause();
                  else {
                    player.seekTo(0);
                    player.play();
                  }
                }}
              >
                {player.playing ? t.audioPause : t.audioPlay}
              </Button>
            ) : null}
            {hasSaved && !recorderState.isRecording ? (
              <Button mode="text" textColor={colors.danger} onPress={remove}>{t.audioDelete}</Button>
            ) : null}
          </View>
        </Card.Content>
      </Card>

      <Button mode="contained" onPress={save} loading={busy} disabled={busy || recorderState.isRecording} style={{ marginTop: spacing.m }}>
        {t.audioAttach}
      </Button>
    </ScrollView>
  );
}

function clock(ms: number): string {
  const total = Math.max(0, Math.round(ms / 1000));
  const minutes = Math.floor(total / 60);
  const seconds = total % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}
