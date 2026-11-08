import type { NavigatorScreenParams } from '@react-navigation/native';

export type TabParamList = {
  Home: undefined;
  Library: undefined;
  Knowledge: { tag?: string } | undefined;
  Review: undefined;
  Stats: undefined;
};

export type RootStackParamList = {
  Tabs: NavigatorScreenParams<TabParamList> | undefined;
  BookEdit: { bookId?: number } | undefined;
  BookDetail: { bookId: number };
  Categories: undefined;
  EntryEdit: { entryId?: number; bookId?: number; type?: number; page?: number } | undefined;
  Summary: { bookId: number };
  ReviewSession: undefined;
  Search: undefined;
  Settings: undefined;
  Backup: undefined;
  ClearData: undefined;
  AudioNote: { entryId: number; bookId?: number; type?: number } | undefined;
  PdfReader: { docId: number; bookId: number };
};

declare global {
  namespace ReactNavigation {
    interface RootParamList extends RootStackParamList {}
  }
}
