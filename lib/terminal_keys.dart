/// Applies sticky on-screen CTRL / ALT modifiers to text typed on the soft
/// keyboard, which the terminal otherwise sends verbatim.
String applyModifiers(String text, {required bool ctrl, required bool alt}) {
  if (text.length != 1) return text;
  var out = text;
  if (ctrl) {
    final c = text.toLowerCase().codeUnitAt(0);
    if (c >= 0x61 && c <= 0x7a) {
      out = String.fromCharCode(c - 0x60); // a-z -> ^A-^Z
    } else if (c >= 0x40 && c <= 0x5f) {
      out = String.fromCharCode(c - 0x40); // @ [ \ ] ^ _
    } else if (c == 0x20) {
      out = '\x00'; // ^Space
    } else if (c == 0x3f) {
      out = '\x7f'; // ^?
    }
  }
  if (alt) out = '\x1b$out';
  return out;
}
