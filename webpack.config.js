const createExpoWebpackConfigAsync = require('@expo/webpack-config');

module.exports = async function(env, argv) {
  const config = await createExpoWebpackConfigAsync(env, argv);
  // Add rule for .wasm files so expo-sqlite can load its WebAssembly module.
  config.module.rules.push({
    test: /\.wasm$/,
    type: 'asset/resource',
    generator: {
      filename: 'static/media/[name].[hash][ext]',
    },
  });
  config.resolve.extensions.push('.wasm');
};
