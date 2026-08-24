import 'package:file_selector/file_selector.dart';

/// Type filters that work on iOS (UTIs), Android (MIME) and desktop (extensions).
const csvFileTypeGroup = XTypeGroup(
  label: 'CSV',
  extensions: ['csv', 'txt'],
  mimeTypes: [
    'text/csv',
    'text/comma-separated-values',
    'application/csv',
    'text/plain',
  ],
  uniformTypeIdentifiers: [
    'public.comma-separated-values-text',
    'public.delimited-values-text',
    'public.plain-text',
    'public.text',
  ],
);

const jsonFileTypeGroup = XTypeGroup(
  label: 'JSON',
  extensions: ['json'],
  mimeTypes: [
    'application/json',
    'text/json',
    'text/plain',
  ],
  uniformTypeIdentifiers: [
    'public.json',
    'public.text',
    'public.data',
  ],
);
