import 'package:flutter/material.dart';

import '../models/tutor_message.dart';

class AiTutorPage extends StatefulWidget {
  const AiTutorPage({
    super.key,
    required this.messages,
    required this.mode,
    required this.isLoading,
    required this.error,
    required this.personalWordCount,
    required this.onModeChanged,
    required this.onSend,
    required this.onOpenSource,
  });

  final List<TutorMessage> messages;
  final String mode;
  final bool isLoading;
  final String? error;
  final int personalWordCount;
  final ValueChanged<String> onModeChanged;
  final Future<void> Function(String question) onSend;
  final ValueChanged<TutorSource> onOpenSource;

  @override
  State<AiTutorPage> createState() => _AiTutorPageState();
}

class _AiTutorPageState extends State<AiTutorPage> {
  static const _starterPrompts = [
    'Teach me a useful greeting',
    'How do I pronounce a new word?',
    'Quiz me on everyday vocabulary',
  ];

  final _composerController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant AiTutorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length ||
        oldWidget.isLoading != widget.isLoading ||
        oldWidget.error != widget.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    if (widget.isLoading) return;
    final question = (prompt ?? _composerController.text).trim();
    if (question.isEmpty) return;
    _composerController.clear();
    await widget.onSend(question);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E5D4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: colors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Tutor',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text(
                      'Learn Amassoma, one question at a time.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFF65635D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'ask',
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Ask'),
              ),
              ButtonSegment(
                value: 'practice',
                icon: Icon(Icons.psychology_outlined),
                label: Text('Practice'),
              ),
            ],
            selected: {widget.mode},
            onSelectionChanged: (selection) =>
                widget.onModeChanged(selection.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 16, color: colors.secondary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.personalWordCount == 0
                      ? 'Grounded in the approved dictionary and vocabulary'
                      : 'Dictionary plus ${widget.personalWordCount} saved or recent words',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF65635D),
                      ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE6DFD2)),
        Expanded(child: _conversation(context)),
        _composer(context),
      ],
    );
  }

  Widget _conversation(BuildContext context) {
    final showStarters = widget.messages.length == 1 &&
        !widget.isLoading &&
        widget.error == null;
    final itemCount = widget.messages.length +
        (showStarters ? 1 : 0) +
        (widget.isLoading ? 1 : 0) +
        (widget.error == null ? 0 : 1);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < widget.messages.length) {
          return _messageBubble(context, widget.messages[index]);
        }
        var nextIndex = widget.messages.length;
        if (showStarters && index == nextIndex++) {
          return _starterPromptList(context);
        }
        if (widget.isLoading && index == nextIndex++) {
          return _thinkingIndicator(context);
        }
        return _errorMessage(context);
      },
    );
  }

  Widget _messageBubble(BuildContext context, TutorMessage message) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.role == 'user';
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.84,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? colors.primary : Colors.white,
        border: isUser ? null : Border.all(color: const Color(0xFFE6DFD2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isUser ? Colors.white : const Color(0xFF18232C),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          if (!isUser && message.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: message.sources.map((source) {
                return Tooltip(
                  message: source.translation,
                  child: ActionChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 15),
                    label: Text(source.word,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: () => widget.onOpenSource(source),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFFE6DFD2)),
                    backgroundColor: const Color(0xFFFCF9F2),
                  ),
                );
              }).toList(),
            ),
          ],
          if (!isUser && message.followUpQuestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...message.followUpQuestions.map((question) => Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: widget.isLoading ? null : () => _send(question),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(question, textAlign: TextAlign.left),
                  ),
                )),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }

  Widget _starterPromptList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        children: _starterPrompts
            .map((prompt) => ActionChip(
                  label: Text(prompt),
                  onPressed: () => _send(prompt),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE6DFD2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ))
            .toList(),
      ),
    );
  }

  Widget _thinkingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6DFD2)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Preparing your lesson…',
                style: TextStyle(color: Color(0xFF65635D), fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _errorMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'The tutor could not respond: ${widget.error}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        12,
        MediaQuery.viewInsetsOf(context).bottom > 0 ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6DFD2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composerController,
              enabled: !widget.isLoading,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: widget.mode == 'practice'
                    ? 'Answer or ask for a quiz…'
                    : 'Ask about Amassoma…',
                filled: true,
                fillColor: const Color(0xFFFCF9F2),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6DFD2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6DFD2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.secondary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send question',
            onPressed: widget.isLoading ? null : () => _send(),
            style: IconButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(46, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}
