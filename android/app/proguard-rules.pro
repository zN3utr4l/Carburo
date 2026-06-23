# google_mlkit_text_recognition references optional script recognizers (Chinese,
# Devanagari, Japanese, Korean). We bundle only the Latin model, so those classes
# are absent. R8 runs for release (core-library desugaring is enabled for
# flutter_local_notifications) and does a whole-program check, failing with
# "Missing classes" — debug uses D8 and skips the check, which is why debug built
# fine but the release CD did not. We don't use those scripts; tell R8 not to fail.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
