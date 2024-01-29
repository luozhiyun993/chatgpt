import 'dart:async';

import 'package:chat_gpt_flutter/chat_gpt_flutter.dart';
import 'package:chatgpt/api_key.dart';
import 'package:chatgpt/model/question_answer.dart';
import 'package:chatgpt/theme.dart';
import 'package:chatgpt/view/components/chatgpt_answer_widget.dart';
import 'package:chatgpt/view/components/loading_widget.dart';
import 'package:chatgpt/view/components/text_input_widget.dart';
import 'package:chatgpt/view/components/user_question_widget.dart';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';




class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? answer;
  final loadingNotifier = ValueNotifier<bool>(false);
  final List<QuestionAnswer> questionAnswers = [];
  bool _hasSpeech = false;
  late ScrollController scrollController;
  late ChatGpt chatGpt;
  late TextEditingController inputQuestionController;
  bool _isRecording = false;
  Stream<List<int>>? stream;
  StreamSubscription<CompletionResponse>? streamSubscription;
  stt.SpeechToText _speechToText = stt.SpeechToText();
  List<stt.LocaleName> _localeNames = [];
  String _currentLocaleId = '';


  @override
  void initState() {
    inputQuestionController = TextEditingController();
    scrollController = ScrollController();
    chatGpt = ChatGpt(apiKey: openAIApiKey);
    super.initState();
  }

  @override
  void dispose() {
    inputQuestionController.dispose();
    loadingNotifier.dispose();
    scrollController.dispose();
    streamSubscription?.cancel();
    super.dispose();
  }


  Future<void> initSpeechState() async {
    print('Initialize initSpeechState');
    try {
      var hasSpeech = await _speechToText.initialize(
        onStatus: (status) => print('SpeechToText status: $status'),
        onError: (errorNotification) => print('SpeechToText error: $errorNotification'),
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await _speechToText.locales();

        var systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        _hasSpeech = false;
      });
      print(e.toString());
    }
  }

  void _toggleStartRecording() async {
    if (_hasSpeech) {
      setState(() => _isRecording = true);
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            inputQuestionController.text = result.recognizedWords;
            print(inputQuestionController.text);
          });
        },
      );
    }
  }

  void _toggleStopRecording() {
    _speechToText.stop();
    print("_toggleStopRecording");
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg500Color,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.white12,
        centerTitle: true,
        title: Text(
          "ChatGPT",
          style: kWhiteText.copyWith(fontSize: 20, fontWeight: kSemiBold),
        ),
        backgroundColor: kBg300Color,
      ),
      body: SafeArea(
        child: Column(
          children: [
            buildChatList(),
            TextInputWidget(
              textController: inputQuestionController,
              onSubmitted: () => _sendMessage(),
              toggleStartRecording: () => _hasSpeech ? _toggleStartRecording() : initSpeechState() ,
              toggleStopRecording: () => _toggleStopRecording(),
              isRecording: _isRecording,
            )
          ],
        ),
      ),
    );
  }

  Expanded buildChatList() {
    return Expanded(
      child: ListView.separated(
        controller: scrollController,
        separatorBuilder: (context, index) => const SizedBox(
          height: 12,
        ),
        physics: const BouncingScrollPhysics(),
        padding:
            const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 16),
        itemCount: questionAnswers.length,
        itemBuilder: (BuildContext context, int index) {
          final question = questionAnswers[index].question;
          final answer = questionAnswers[index].answer;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              UserQuestionWidget(question: question),
              const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: loadingNotifier,
                builder: (_, bool isLoading, __) {
                  if (answer.isEmpty && isLoading) {
                    _scrollToBottom();
                    return const LoadingWidget();
                  } else {
                    return ChatGptAnswerWidget(
                      answer: answer.toString().trim(),
                    );
                  }
                },
              )
            ],
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  void _sendMessage() async {
    final question = inputQuestionController.text;
    inputQuestionController.clear();
    loadingNotifier.value = true;

    setState(() => questionAnswers
        .add(QuestionAnswer(question: question, answer: StringBuffer())));

    final testRequest = CompletionRequest(
      prompt: [question],
      stream: true,
      maxTokens: 500,
      temperature: 1,
      model: ChatGptModel.textDavinci003.modelName,
    );
    await _streamResponse(testRequest)
        .whenComplete(() => loadingNotifier.value = true);
  }

  Future _streamResponse(CompletionRequest request) async {
    streamSubscription?.cancel();
    try {
      final stream = await chatGpt.createCompletionStream(request);
      streamSubscription = stream?.listen((event) {
        if (event.streamMessageEnd) {
          streamSubscription?.cancel();
        } else {
          setState(() {
            questionAnswers.last.answer.write(event.choices?.first.text);
            _scrollToBottom();
          });
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => questionAnswers.last.answer.write("error"));
    }
  }
}
