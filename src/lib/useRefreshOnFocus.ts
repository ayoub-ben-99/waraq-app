// Ported from app/src/main/java/com/waraq/app/WaraqApp.java
import { useCallback } from 'react';
import { useFocusEffect } from '@react-navigation/native';

export function useRefreshOnFocus(refetch: () => unknown) {
  useFocusEffect(
    useCallback(() => {
      void refetch();
    }, [refetch]),
  );
}
