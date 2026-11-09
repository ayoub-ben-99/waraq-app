import { Easing } from 'react-native';

export const motion = {
  duration: { short: 150, medium: 280, long: 400 },
  easing: {
    emphasized: Easing.bezier(0.2, 0, 0, 1),
    decelerate: Easing.bezier(0.05, 0.7, 0.1, 1),
    accelerate: Easing.bezier(0.3, 0, 0.8, 0.15),
  },
  spring: { friction: 7, tension: 120 },
  stagger: 40,
  maxStaggered: 8,
} as const;
