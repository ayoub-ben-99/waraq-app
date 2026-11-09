import { useRef } from "react";
import { Animated, StyleSheet } from "react-native";
import * as SplashScreen from "expo-splash-screen";
import { useTheme } from "react-native-paper";
import { motion } from "../../theme/motion";

export function AnimatedSplash({ onDone }: { onDone: () => void }) {
    const theme = useTheme();
    const scale = useRef(new Animated.Value(0.85)).current;
    const opacity = useRef(new Animated.Value(1)).current;
    const started = useRef(false);

    const start = () => {
        if (started.current) return;
        started.current = true;
        SplashScreen.hideAsync();
        Animated.sequence([
            Animated.spring(scale, {
                toValue: 1,
                friction: motion.spring.friction,
                tension: motion.spring.tension,
                useNativeDriver: true,
            }),
            Animated.delay(500),
            Animated.timing(opacity, {
                toValue: 0,
                duration: motion.duration.medium,
                easing: motion.easing.accelerate,
                useNativeDriver: true,
            }),
        ]).start(onDone);
    };

    return (
        <Animated.View
            onLayout={start}
            pointerEvents="none"
            style={[
                StyleSheet.absoluteFill,
                {
                    backgroundColor: theme.colors.background,
                    alignItems: "center",
                    justifyContent: "center",
                    opacity,
                },
            ]}
        >
            <Animated.Image
                source={require("../../../assets/splash-icon.png")}
                resizeMode="contain"
                style={{ width: 200, height: 200, transform: [{ scale }] }}
            />
        </Animated.View>
    );
}