const double kDesktopBreakpoint = 900;

double contentMaxWidthFor(double screenWidth, {double compact = 720}) {
  if (screenWidth >= 1400) return 1180;
  if (screenWidth >= 1100) return 1040;
  if (screenWidth >= kDesktopBreakpoint) return 860;
  return compact;
}
