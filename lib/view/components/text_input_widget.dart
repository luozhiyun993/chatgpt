import 'package:chatgpt/theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';



class TextInputWidget extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSubmitted;
  final GestureTapCallback toggleStartRecording;
  final GestureTapCallback toggleStopRecording;
  final bool isRecording;

  const TextInputWidget(
      {required this.textController, required this.onSubmitted, Key? key,
      required this.toggleStartRecording, required this.toggleStopRecording,
        required this.isRecording,})
      : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12, left: 12),
            decoration: const BoxDecoration(
              color: kBg100Color,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12), bottom: Radius.circular(12)),
            ),
            child: TextFormField(
              controller: textController,
              minLines: 1,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              style: kWhiteText.copyWith(fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: kBg100Color,
                hintText: 'Type in...',
                hintStyle: kWhiteText.copyWith(fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(left: 12.0),
              ),
              onFieldSubmitted: (_) => onSubmitted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap:() {
            if (isRecording) {
              toggleStopRecording();
            } else {
              toggleStartRecording();
            }
          } ,
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 12, right: 12),
          decoration:
              const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
          child: GestureDetector(
            onTap: onSubmitted,
            child: const Icon(
              Iconsax.send_24,
              color: Colors.white,
            ),
          ),
        )
      ],
    );
  }
}
