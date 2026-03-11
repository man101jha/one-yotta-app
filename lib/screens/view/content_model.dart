class UnbordingContent {
  String image;
  String title;
  String discription;

  UnbordingContent({required this.image, required this.title, required this.discription});
}

List<UnbordingContent> contents = [
  UnbordingContent(
    title: '100% Uptime with Colocation',
    image: 'assets/images/building.png',
    discription: "Leading organizations host their critical IT infrastructure in Yotta data centers – the highest quality, fault-tolerant facilities in India."
  ),
  UnbordingContent(
    title: 'Yotta Enterprise Cloud',
    image: 'assets/images/oneYotta.png',
    discription: "It’s packed with features and comes with an infrastructure uptime SLA of 99.99%. And yes, the self-service portal gives you complete control"
  ),
  UnbordingContent(
    title: 'Hosted Network Services',
    image: 'assets/images/oneYotta.png',
    discription: "Your Network is the critical backbone of your business, and you need to achieve efficiency and service agility to stay ahead of the competition."
  ),
];
