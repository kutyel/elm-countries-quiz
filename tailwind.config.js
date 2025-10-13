module.exports = {
  mode: "jit",
  content: ["./src/**/*.{elm,html,js}"],
  theme: {
    extend: {
      animation: {
        'slide-in-top': 'slideInTop 0.5s ease-out',
        'slide-out-top': 'slideOutTop 0.3s ease-in',
      },
      keyframes: {
        slideInTop: {
          '0%': { transform: 'translateY(-100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideOutTop: {
          '0%': { transform: 'translateY(0)', opacity: '1' },
          '100%': { transform: 'translateY(-100%)', opacity: '0' },
        },
      },
    },
  },
  variants: {},
  plugins: [
    require('tailwindcss-animate'),
  ],
};
