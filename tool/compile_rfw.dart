// Build-time script to compile .rfwtxt files to .rfw binary format
// Per DESIGN.md Section 3 Phase 2 Step 1 and QUESTIONS.md Section 3
//
// Usage: dart run tool/compile_rfw.dart

import 'dart:io';
import 'package:rfw/formats.dart';

void main() async {
  final sourceDir = Directory('assets/rfw/source');
  final outputDir = Directory('assets/rfw/defaults');

  // Ensure output directory exists
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  if (!await sourceDir.exists()) {
    print('Source directory not found: ${sourceDir.path}');
    exit(1);
  }

  var compiledCount = 0;
  var errorCount = 0;

  await for (final entity in sourceDir.list()) {
    if (entity is File && entity.path.endsWith('.rfwtxt')) {
      final fileName = entity.path.split('/').last;
      final baseName = fileName.replaceFirst('.rfwtxt', '');
      final outputPath = '${outputDir.path}/$baseName.rfw';

      try {
        print('Compiling: ${entity.path}');

        // Read source file
        final source = await entity.readAsString();

        // Parse the text format
        final stopwatch = Stopwatch()..start();
        final parsed = parseLibraryFile(source);
        final parseTime = stopwatch.elapsedMilliseconds;

        // Encode to binary format
        stopwatch.reset();
        final binary = encodeLibraryBlob(parsed);
        final encodeTime = stopwatch.elapsedMilliseconds;

        // Write binary output
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(binary);

        final sourceSize = await entity.length();
        final binarySize = binary.length;
        final compressionRatio = (binarySize / sourceSize * 100).toStringAsFixed(1);

        print('  -> $outputPath');
        print('     Source: $sourceSize bytes, Binary: $binarySize bytes ($compressionRatio%)');
        print('     Parse: ${parseTime}ms, Encode: ${encodeTime}ms');

        compiledCount++;
      } catch (e, stack) {
        print('  ERROR compiling $fileName: $e');
        print('  Stack trace: $stack');
        errorCount++;
      }
    }
  }

  print('');
  print('Compilation complete:');
  print('  Compiled: $compiledCount files');
  print('  Errors: $errorCount files');

  if (errorCount > 0) {
    exit(1);
  }
}
