import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/providers/language_provider.dart';
import 'providers/assistant_provider.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final state = ref.watch(assistantProvider);

    ref.listen<AssistantState>(assistantProvider, (previous, next) {
      if (next.error != null && (previous == null || previous.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTamil ? 'ஹார்வெஸ்ட்லிங்க் உதவி' : 'HarvestLink Assistant',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Chat messages
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    return _ChatBubble(
                      message: msg,
                      isTamil: isTamil,
                      onPlayTts: () {
                        ref.read(assistantProvider.notifier).playTts(msg.text);
                      },
                    );
                  },
                ),
              ),
              
              if (state.isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildProcessingIndicator(isTamil),
                ),
              
              // Text input bar
              _buildInputBar(context, ref, state, isTamil),
            ],
          ),
          
          // Voice overlay
          if (state.isListening)
            _buildVoiceOverlay(context, ref, state, isTamil),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator(bool isTamil) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.turmeric,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isTamil ? 'சிந்தித்துக் கொண்டிருக்கிறேன்...' : 'Thinking...',
            style: const TextStyle(color: AppColors.sub, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, WidgetRef ref, AssistantState state, bool isTamil) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          // Mic button
          GestureDetector(
            onTap: () {
              ref.read(assistantProvider.notifier).toggleListening();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.turmeric,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                ],
              ),
              child: const Icon(Icons.mic, color: AppColors.ink, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: isTamil ? 'இங்கே தட்டச்சு செய்யுங்கள்...' : 'Type here...',
                  hintStyle: const TextStyle(color: AppColors.sub),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    ref.read(assistantProvider.notifier).sendTextMessage(text);
                    _textController.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Send button
          GestureDetector(
            onTap: () {
              final text = _textController.text;
              if (text.trim().isNotEmpty) {
                ref.read(assistantProvider.notifier).sendTextMessage(text);
                _textController.clear();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.leaf,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                ],
              ),
              child: const Icon(Icons.send, color: AppColors.textLight, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOverlay(BuildContext context, WidgetRef ref, AssistantState state, bool isTamil) {
    return Container(
      color: AppColors.indigo,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Farmer avatar
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.turmeric, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(5, 5)),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/farmer_tools.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 22),
            
            // Listening animation bars
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => _WaveBar(delay: i * 150)),
              ),
            ),
            const SizedBox(height: 22),
            
            // Recognized text
            if (state.recognizedText != null && state.recognizedText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  state.recognizedText!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textLight,
                  ),
                ),
              )
            else
              Text(
                isTamil ? 'கேட்டுக் கொண்டிருக்கிறேன்...' : 'Listening...',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                ),
              ),
            
            const SizedBox(height: 30),
            
            // Stop button
            GestureDetector(
              onTap: () {
                ref.read(assistantProvider.notifier).toggleListening();
              },
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                  ],
                ),
                child: const Icon(Icons.stop, size: 32, color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isTamil;
  final VoidCallback onPlayTts;

  const _ChatBubble({
    required this.message,
    required this.isTamil,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.indigo : AppColors.card,
          border: Border.all(
            color: message.isError ? AppColors.error : AppColors.ink,
            width: 2,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser ? AppColors.indigo.withValues(alpha: 0.5) : AppColors.ink,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isUser ? AppColors.textLight : AppColors.ink,
              ),
            ),
            if (!isUser && !message.isError) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onPlayTts,
                child: Icon(
                  Icons.volume_up,
                  size: 20,
                  color: AppColors.turmeric,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaveBar extends StatefulWidget {
  final int delay;
  const _WaveBar({required this.delay});

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 10, end: 52).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 9,
          height: _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          decoration: BoxDecoration(
            color: AppColors.turmeric,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      },
    );
  }
}
