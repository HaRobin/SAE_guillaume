import 'package:flutter/material.dart';

class DescriptionPage extends StatelessWidget {
  final String description =
      "Ce projet a été réalisé par des étudiants de BUT en informatique dans le cadre de leur SAE (Situation d''Apprentissage et d''Evaluation) afin d''implémenter de l''Intelligence Artificielle dans un projet de développement mobile. Le modèle d''IA utilisé a été formé par les étudiants pour reconnaître spécifiquement les cartes d''un jeu de carte classique de 52 cartes. \n Les cartes du jeu classique sont utilisés dans de nombreux jeux, notamment dans de nombreux jeux de casinos avec le poker ou le black jack. Il n''est pas difficile de trouver une utilité à un programme de reconnaissance de cartes dans de tels contextes, que ce soit pour tracer les cartes déjà passées et estimer des probabilités pour les mains suivantes ou tout simplement tricher en regardant les mains de ses adversaires. Si l''éthique de cette utilisation est discutable, elle ne l''est pas moins que les jeux de hasard voire plus largement l''utilisation de l''Intelligence Artificielle. \n Nous avons réussi à implémenter l''IA formée aux cartes dans les deux modèles, celui de la reconnaissance en direct et celui de l''import d''image, et nous pensons avoir réussi à combler les lacunes de ce projet qui existaient à la fin du semestre précédent.";

  const DescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Description"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
