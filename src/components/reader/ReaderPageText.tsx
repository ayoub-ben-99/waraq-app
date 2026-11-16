import React, { useEffect, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { ActivityIndicator, Text } from 'react-native-paper';
import { pageText } from '../../features/pdf/native';
import { t } from '../../lib/strings';
import type { ReaderTextFont } from '../../lib/prefs';
import { fonts } from '../../theme/tokens';

type Props = {
  path: string;
  page: number;
  textSize: number;
  lineSpacing: number;
  fontFamily: ReaderTextFont;
  textColor: string;
  hintColor: string;
  loadingColor: string;
};

function fontName(value: ReaderTextFont): string | undefined {
  if (value === 'amiri') return fonts.quote;
  if (value === 'plex') return fonts.regular;
  return undefined;
}

/**
 * صفحة واحدة في وضع النص: نص مستخرج من الملف يُعاد تنسيقه بحجم الخط
 * والتباعد ونوع الخط، مع تمرير عمودي مريح. لا يغيّر محتوى الملف أبدًا.
 */
export function ReaderPageText(props: Props) {
  const [text, setText] = useState<string | null>(null);
  const [error, setError] = useState<'no-text' | 'failed' | null>(null);

  useEffect(() => {
    let active = true;
    setText(null);
    setError(null);
    void (async () => {
      try {
        const extracted = await pageText(props.path, props.page);
        if (!active) return;
        const trimmed = extracted.replace(/[ \t]+\n/g, '\n').trim();
        if (trimmed.length === 0) setError('no-text');
        else setText(trimmed);
      } catch (err) {
        if (!active) return;
        const message = err instanceof Error ? err.message : '';
        setError(message.includes('page-no-text') ? 'no-text' : 'failed');
      }
    })();
    return () => {
      active = false;
    };
  }, [props.path, props.page]);

  if (error) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 }}>
        <Text style={{ color: props.hintColor, textAlign: 'center', fontSize: 14, lineHeight: 22 }}>
          {error === 'no-text' ? t.pdfNoText : t.genericError}
        </Text>
      </View>
    );
  }

  if (text == null) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator color={props.loadingColor} />
        <Text style={{ color: props.hintColor, marginTop: 12, fontSize: 13 }}>{t.readerLoadingText}</Text>
      </View>
    );
  }

  const paragraphs = text.split(/\n{2,}/);
  return (
    <ScrollView
      style={{ flex: 1 }}
      contentContainerStyle={{ padding: 20, paddingBottom: 48 }}
      showsVerticalScrollIndicator={false}
    >
      <View>
        {paragraphs.map((paragraph, index) => (
          <Text
            key={index}
            style={{
              color: props.textColor,
              fontFamily: fontName(props.fontFamily),
              fontSize: props.textSize,
              lineHeight: Math.round(props.textSize * (props.lineSpacing / 10)),
              textAlign: 'right',
              writingDirection: 'rtl',
              marginBottom: 12,
            }}
          >
            {paragraph.replace(/\n/g, ' ')}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
}
