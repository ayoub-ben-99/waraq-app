import React from 'react';
import { View } from 'react-native';
import { IconButton, Modal, Portal, SegmentedButtons, Surface, Text, TouchableRipple } from 'react-native-paper';
import { t } from '../../lib/strings';
import {
  READER_TEXT_SIZE_MAX,
  READER_TEXT_SIZE_MIN,
  READER_TEXT_SPACING_MAX,
  READER_TEXT_SPACING_MIN,
  type ReaderTextFont,
} from '../../lib/prefs';

type Props = {
  visible: boolean;
  onDismiss: () => void;
  textMode: boolean;
  onTextModeChange: (value: boolean) => void;
  textSize: number;
  onTextSizeChange: (value: number) => void;
  lineSpacing: number;
  onLineSpacingChange: (value: number) => void;
  textFont: ReaderTextFont;
  onTextFontChange: (value: ReaderTextFont) => void;
  onDone: () => void;
  colors: {
    surface: string;
    onSurface: string;
    hint: string;
    primary: string;
    outlineVariant: string;
  };
};

/**
 * إعدادات القراءة: نمط العرض، حجم الخط، تباعد الأسطر، ونوع الخط —
 * بمعاينة فورية. الإعدادات مشتركة بين الكتب كما في التطبيق الأصلي.
 * الخط والتباعد بأزرار خطوة (لا يوجد Slider في Paper v5 ولا مكتبة أخرى).
 */
export function ReaderSettingsSheet(props: Props) {
  const previewFont = props.textFont === 'amiri' ? 'Amiri' : props.textFont === 'plex' ? 'PlexRegular' : undefined;
  return (
    <Portal>
      <Modal
        visible={props.visible}
        onDismiss={props.onDismiss}
        contentContainerStyle={{ marginTop: 'auto', marginHorizontal: 12, marginBottom: 12 }}
      >
        <Surface
          elevation={3}
          style={{ borderRadius: 28, padding: 24, paddingBottom: 12, backgroundColor: props.colors.surface }}
        >
          <Text style={{ fontSize: 20, color: props.colors.onSurface, textAlign: 'center', marginBottom: 16 }}>
            {t.readerSettings}
          </Text>

          <Text style={{ fontSize: 13, color: props.colors.hint, marginBottom: 6 }}>{t.readerModeTitle}</Text>
          <SegmentedButtons
            value={props.textMode ? 'text' : 'pages'}
            onValueChange={(value) => props.onTextModeChange(value === 'text')}
            buttons={[
              { value: 'pages', label: t.readerModePages, icon: 'book-open-page-variant' },
              { value: 'text', label: t.readerModeText, icon: 'format-annotations' },
            ]}
            style={{ marginBottom: 20 }}
          />

          {props.textMode && (
            <>
              <StepperRow
                label={t.readerFontSize}
                value={t.readerFontPx(props.textSize)}
                canDecrease={props.textSize > READER_TEXT_SIZE_MIN}
                canIncrease={props.textSize < READER_TEXT_SIZE_MAX}
                onDecrease={() => props.onTextSizeChange(Math.max(READER_TEXT_SIZE_MIN, props.textSize - 1))}
                onIncrease={() => props.onTextSizeChange(Math.min(READER_TEXT_SIZE_MAX, props.textSize + 1))}
                colors={{ onSurface: props.colors.onSurface, hint: props.colors.hint, primary: props.colors.primary }}
              />
              <StepperRow
                label={t.readerLineSpacing}
                value={(props.lineSpacing / 10).toFixed(1)}
                canDecrease={props.lineSpacing > READER_TEXT_SPACING_MIN}
                canIncrease={props.lineSpacing < READER_TEXT_SPACING_MAX}
                onDecrease={() => props.onLineSpacingChange(Math.max(READER_TEXT_SPACING_MIN, props.lineSpacing - 1))}
                onIncrease={() => props.onLineSpacingChange(Math.min(READER_TEXT_SPACING_MAX, props.lineSpacing + 1))}
                colors={{ onSurface: props.colors.onSurface, hint: props.colors.hint, primary: props.colors.primary }}
                last
              />

              <Text style={{ fontSize: 13, color: props.colors.hint, marginBottom: 6 }}>{t.readerFontFamily}</Text>
              <SegmentedButtons
                value={props.textFont}
                onValueChange={(value) => props.onTextFontChange(value as ReaderTextFont)}
                buttons={[
                  { value: 'system', label: t.readerFontSystem },
                  { value: 'amiri', label: t.readerFontAmiri },
                  { value: 'plex', label: t.readerFontPlex },
                ]}
                style={{ marginBottom: 20 }}
              />

              <Text style={{ fontSize: 12, color: props.colors.hint, marginBottom: 4 }}>{t.readerPreviewHint}</Text>
              <View
                style={{
                  borderRadius: 12,
                  borderWidth: 1,
                  borderColor: props.colors.outlineVariant,
                  padding: 16,
                  marginBottom: 12,
                }}
              >
                <Text
                  style={{
                    color: props.colors.onSurface,
                    fontFamily: previewFont,
                    fontSize: props.textSize,
                    lineHeight: Math.round(props.textSize * (props.lineSpacing / 10)),
                    textAlign: 'right',
                    writingDirection: 'rtl',
                  }}
                >
                  {'وَرَق يوثّق قراءتك: اقتباس وفائدة ورأي في مكان واحد، مع مراجعة لما حفظته.'}
                </Text>
              </View>
            </>
          )}

          <TouchableRipple onPress={props.onDone} style={{ borderRadius: 16, padding: 8 }}>
            <Text style={{ color: props.colors.primary, textAlign: 'center', fontSize: 16 }}>{t.done}</Text>
          </TouchableRipple>
        </Surface>
      </Modal>
    </Portal>
  );
}

function StepperRow(props: {
  label: string;
  value: string;
  canDecrease: boolean;
  canIncrease: boolean;
  onDecrease: () => void;
  onIncrease: () => void;
  last?: boolean;
  colors: { onSurface: string; hint: string; primary: string };
}) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: props.last ? 20 : 12 }}>
      <Text style={{ flex: 1, fontSize: 14, color: props.colors.hint }}>{props.label}</Text>
      <IconButton
        icon="minus"
        onPress={props.onDecrease}
        disabled={!props.canDecrease}
        accessibilityLabel={`${props.label}: إنقاص`}
        iconColor={props.colors.primary}
      />
      <Text style={{ minWidth: 56, textAlign: 'center', fontSize: 15, color: props.colors.onSurface }}>
        {props.value}
      </Text>
      <IconButton
        icon="plus"
        onPress={props.onIncrease}
        disabled={!props.canIncrease}
        accessibilityLabel={`${props.label}: زيادة`}
        iconColor={props.colors.primary}
      />
    </View>
  );
}
