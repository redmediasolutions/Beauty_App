module.exports = {
  root: true,
  env: {
    node: true,
    es2020: true,
  },

  parser: "@typescript-eslint/parser", // ✅ REQUIRED

  parserOptions: {
    ecmaVersion: 2020,
    sourceType: "module",
  },

  plugins: ["@typescript-eslint"],

  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
  ],

  ignorePatterns: ["lib/**", "node_modules/**"],

  rules: {
    "object-curly-spacing": "off",
    "operator-linebreak": "off",
    "@typescript-eslint/no-non-null-assertion": "off",
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-unused-vars": "off",
    "require-jsdoc": "off",
    "eol-last": "off"
  },
};