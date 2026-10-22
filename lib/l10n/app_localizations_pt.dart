// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get tests => 'Provas';

  @override
  String get stats => 'Estatísticas';

  @override
  String get classes => 'Turmas';

  @override
  String get settings => 'Configurações';

  @override
  String get noCamerasFound => 'Nenhuma câmera achada no dispostivo.';

  @override
  String get name => 'Nome';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Língua';

  @override
  String get system => 'Sistema';

  @override
  String get lightMode => 'Claro';

  @override
  String get darkMode => 'Escuro';

  @override
  String get alignAnswerKey => 'Alinhe o gabarito';

  @override
  String get newClass => 'Nova turma';

  @override
  String get className => 'Nome da turma';

  @override
  String get renameClass => 'Renomear turma';

  @override
  String get deleteClass => 'Excluir turma';

  @override
  String deleteClassConfirm(String name) {
    return 'Isso remove a turma \"$name\" e todos os seus alunos.';
  }

  @override
  String get addStudent => 'Adicionar aluno';

  @override
  String get studentName => 'Nome do aluno';

  @override
  String get studentExists => 'Este aluno já está na turma';

  @override
  String get renameStudent => 'Renomear aluno';

  @override
  String get deleteStudent => 'Excluir aluno';

  @override
  String deleteStudentConfirm(String name) {
    return 'Remover \"$name\" desta turma?';
  }

  @override
  String studentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alunos',
      one: '$count aluno',
      zero: '0 alunos',
    );
    return '$_temp0';
  }

  @override
  String get noClasses => 'Nenhuma turma ainda.\nToque em + para criar uma.';

  @override
  String get noStudents => 'Nenhum aluno ainda';

  @override
  String get classExists => 'Já existe uma turma com esse nome';

  @override
  String get deleteTest => 'Excluir prova';

  @override
  String deleteTestConfirm(String name) {
    return 'Isso remove a prova \"$name\" e todos os seus resultados.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get edit => 'Editar';

  @override
  String get rename => 'Renomear';

  @override
  String get open => 'Abrir';

  @override
  String get fieldEmpty => 'Este campo não pode ficar vazio';

  @override
  String get testExists => 'Já existe uma prova com esse nome';

  @override
  String get numberOfQuestions => 'Número de questões';

  @override
  String get numberOfOptions => 'Número de opções';

  @override
  String get numberBoxTitle => 'Título da caixa de número';

  @override
  String get numberBoxDigits => 'Quantidade de dígitos do número';

  @override
  String get minOne => 'O número deve ser 1 ou mais';

  @override
  String get maxTen => 'O número deve ser 10 ou menos';

  @override
  String get optionBoxTitle => 'Título da caixa de turmas';

  @override
  String get optionBoxOptions => 'Turmas da caixa';

  @override
  String get classOptionsHint =>
      'Digite até 5 turmas. As turmas existentes são sugeridas enquanto você digita.';

  @override
  String get newTest => 'Nova prova';

  @override
  String get saveTest => 'Salvar prova';

  @override
  String get openGallery => 'Abrir galeria';

  @override
  String get classLabel => 'Turma';

  @override
  String get average => 'Média';

  @override
  String get highestScore => 'Maior nota';

  @override
  String get lowestScore => 'Menor nota';

  @override
  String get criticalAnalysis => 'Análise crítica por questão';

  @override
  String mostCorrectTitle(String number) {
    return 'Questão $number (Mais acertos)';
  }

  @override
  String mostWrongTitle(String number) {
    return 'Questão $number (Mais erros)';
  }

  @override
  String classPercentTotal(String percent) {
    return '$percent% da turma';
  }

  @override
  String get asPng => 'como .png';

  @override
  String get asPdf => 'como .pdf';

  @override
  String get foundResults => 'Resultados encontrados';

  @override
  String get studentNumber => 'Número';

  @override
  String get markedOption => 'Opção marcada';

  @override
  String get scoreLabel => 'Nota';

  @override
  String get notAvailable => 'N/D';

  @override
  String get numberUncertain => 'Número ilegível - revise os valores';

  @override
  String get editValues => 'Editar valores';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get numberWritten => 'Número (digitado)';

  @override
  String get cameraInitError => 'Não foi possível iniciar a câmera.';

  @override
  String get back => 'Voltar';

  @override
  String get flashUnavailable => 'Lanterna indisponível neste dispositivo.';

  @override
  String readImageError(String error) {
    return 'Falha ao ler a imagem: $error';
  }

  @override
  String captureError(String error) {
    return 'Falha ao capturar: $error';
  }

  @override
  String get alignedReady => 'Alinhado! Processando...';

  @override
  String get adjustSheet => 'Ajuste a folha';

  @override
  String linkedStudent(String name) {
    return 'Aluno: $name';
  }

  @override
  String linkedClass(String name) {
    return 'Turma: $name';
  }

  @override
  String get notLinked => 'Sem turma vinculada';
}
