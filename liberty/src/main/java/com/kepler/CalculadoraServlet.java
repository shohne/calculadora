package com.kepler;

import java.net.*;
import java.io.*;
import javax.naming.InitialContext;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.cloud.dialogflow.v2.SessionsSettings;
import com.google.cloud.dialogflow.v2.QueryInput;
import com.google.cloud.dialogflow.v2.QueryResult;
import com.google.cloud.dialogflow.v2.SessionName;
import com.google.cloud.dialogflow.v2.SessionsClient;
import com.google.cloud.dialogflow.v2.DetectIntentResponse;
import com.google.cloud.dialogflow.v2.AudioEncoding;
import com.google.cloud.dialogflow.v2.InputAudioConfig;
import com.google.cloud.dialogflow.v2.DetectIntentRequest;
import com.google.cloud.texttospeech.v1.AudioConfig;
import com.google.cloud.texttospeech.v1.SsmlVoiceGender;
import com.google.cloud.texttospeech.v1.SynthesisInput;
import com.google.cloud.texttospeech.v1.SynthesizeSpeechResponse;
import com.google.cloud.texttospeech.v1.TextToSpeechClient;
import com.google.cloud.texttospeech.v1.VoiceSelectionParams;
import com.google.cloud.texttospeech.v1.TextToSpeechSettings;

import com.google.protobuf.ByteString;

import com.google.api.gax.core.*;
import com.google.auth.oauth2.*;

import net.bramp.ffmpeg.builder.*;
import net.bramp.ffmpeg.*;

import java.util.UUID;

@WebServlet(urlPatterns = "/voice")

public class CalculadoraServlet extends HttpServlet {
    private static final long serialVersionUID = 1989907L;

    private static String PATH_FFMPEG = "/usr/local/bin/ffmpeg";
    private static String PATH_FFPROBE = "/usr/local/bin/ffprobe";
    private static String PATH_TEMP = "/tmp/calculadora/";
    private static String prefixFileName = "nada";

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.getWriter().append("Hello! How are you today?");
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse responseServlet)
            throws ServletException, IOException {
        InputStream inputStream = request.getInputStream();
        inputStream = convertFile(inputStream);

        configureProxy();
        SessionsClient sessionsClient = getSessionClient();

        SessionName session = SessionName.of("smalltalk-5f2ca", UUID.randomUUID().toString());
        System.out.println("Session Path: " + session.toString());

        AudioEncoding audioEncoding = AudioEncoding.AUDIO_ENCODING_OGG_OPUS;
        int sampleRateHertz = 48000;

        InputAudioConfig inputAudioConfig = InputAudioConfig.newBuilder().setAudioEncoding(audioEncoding) // audioEncoding
                .setLanguageCode("pt-BR").setSampleRateHertz(sampleRateHertz).build();

        QueryInput queryInput = QueryInput.newBuilder().setAudioConfig(inputAudioConfig).build();

        byte[] inputAudio = org.apache.commons.io.IOUtils.toByteArray(inputStream);
        System.out.print("\ninputAudio.length = " + inputAudio.length);

        DetectIntentRequest intentRequest = DetectIntentRequest.newBuilder().setSession(session.toString())
                .setQueryInput(queryInput).setInputAudio(ByteString.copyFrom(inputAudio)).build();

        DetectIntentResponse response = sessionsClient.detectIntent(intentRequest);
        System.out.print("\nresponse: " + response.toString());

        QueryResult queryResult = response.getQueryResult();
        System.out.print("\nqueryResult: " + queryResult.toString());

        System.out.println("====================");
        System.out.format("Query Text: '%s'\n", queryResult.getQueryText());
        System.out.format("Detected Intent: %s (confidence: %f)\n", queryResult.getIntent().getDisplayName(),
                queryResult.getIntentDetectionConfidence());
        System.out.format("Fulfillment Text: '%s'\n", queryResult.getFulfillmentText());

        com.google.protobuf.Struct parameters = queryResult.getParameters();
        java.util.Map<java.lang.String, com.google.protobuf.Value> mapFieldXValue = parameters.getFields();
        int number1 = (int) mapFieldXValue.get("number1").getNumberValue();
        int number2 = (int) mapFieldXValue.get("number2").getNumberValue();

        int resultado = 0;
        String nomeOperacao = "";

        if (queryResult.getIntent().getDisplayName().equals("adicao")) {
            resultado = number1 + number2;
            nomeOperacao = "mais";
        } else if (queryResult.getIntent().getDisplayName().equals("divisao")) {
            resultado = number1 / number2;
            nomeOperacao = "dividido por";
        } else if (queryResult.getIntent().getDisplayName().equals("subtracao")) {
            resultado = number1 - number2;
            nomeOperacao = "menos";
        } else if (queryResult.getIntent().getDisplayName().equals("multiplicacao")) {
            resultado = number1 * number2;
            nomeOperacao = "vezes";
        }

        // synthesizeText(queryResult.getFulfillmentText());
        try {
            byte[] result = synthesizeText("pt-BR",
                    "" + number1 + " " + nomeOperacao + " " + number2 + " é igual à " + resultado);
            responseServlet.getOutputStream().write(result);
            return;
        } catch (Exception e) {
            System.out.print("\nerro = " + e);
        }

        responseServlet.getWriter()
                .append("" + number1 + " " + nomeOperacao + " " + number2 + " é igual à " + resultado);
    }

    private static SessionsClient getSessionClient() throws IOException {
        InputStream credentialsStream = CalculadoraServlet.class.getClassLoader()
                .getResourceAsStream("smalltalk-5f2ca-43687be985e0.json");
        GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsStream);
        FixedCredentialsProvider credentialsProvider = FixedCredentialsProvider.create(credentials);
        SessionsSettings sessionSettings = SessionsSettings.newBuilder().setCredentialsProvider(credentialsProvider)
                .build();
        return SessionsClient.create(sessionSettings);
    }

    public static byte[] synthesizeText(String linguagem, String text) throws Exception {
        configureProxy();

        System.out.print("\nsynthesizeText: " + linguagem + " " + text);

        InputStream credentialsStream = CalculadoraServlet.class.getClassLoader()
                .getResourceAsStream("clippingglass-70c99205aba3.json");
        GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsStream);
        FixedCredentialsProvider credentialsProvider = FixedCredentialsProvider.create(credentials);
        TextToSpeechSettings sessionSettings = TextToSpeechSettings.newBuilder()
                .setCredentialsProvider(credentialsProvider).build();

        try (TextToSpeechClient textToSpeechClient = TextToSpeechClient.create(sessionSettings)) {
            SynthesisInput input = SynthesisInput.newBuilder().setText(text).build();
            VoiceSelectionParams voice = VoiceSelectionParams.newBuilder().setLanguageCode(linguagem)
                    .setSsmlGender(SsmlVoiceGender.FEMALE).build();

            AudioConfig audioConfig = AudioConfig.newBuilder()
                    .setAudioEncoding(com.google.cloud.texttospeech.v1.AudioEncoding.MP3) // .OGG_OPUS) // MP3 audio.
                    .setVolumeGainDb(10.0).build();

            SynthesizeSpeechResponse response = textToSpeechClient.synthesizeSpeech(input, voice, audioConfig);
            ByteString audioContents = response.getAudioContent();
            byte[] result = audioContents.toByteArray();
            org.apache.commons.io.FileUtils.writeByteArrayToFile(new File(PATH_TEMP + prefixFileName + ".mp3"), result);

            return result;
        }
    }

    private static void configureProxy() {
        try {
            Object objUtilizaProxy = new InitialContext().lookup("utilizaProxy");
            Object objUsuarioProxy = new InitialContext().lookup("usuarioProxy");
            Object objSenhaProxy = new InitialContext().lookup("senhaProxy");
            Object objEnderecoProxy = new InitialContext().lookup("enderecoProxy");
            Object objPortaProxy = new InitialContext().lookup("portaProxy");

            if (objUtilizaProxy != null && objUtilizaProxy.toString().toUpperCase().equals("TRUE")) {
                System.out.print("\nobjUsuarioProxy: " + objUsuarioProxy);
                System.out.print("\nobjEnderecoProxy: " + objEnderecoProxy);
                System.out.print("\nobjPortaProxy: " + objPortaProxy);

                System.setProperty("http.proxyHost", objEnderecoProxy.toString());
                System.setProperty("http.proxyPort", objPortaProxy.toString());
                System.setProperty("https.proxyHost", objEnderecoProxy.toString());
                System.setProperty("https.proxyPort", objPortaProxy.toString());

                Proxy proxy = new Proxy(Proxy.Type.HTTP,
                        new InetSocketAddress(objEnderecoProxy.toString(), Integer.parseInt(objPortaProxy.toString())));
                Authenticator authenticator = new Authenticator() {

                    public PasswordAuthentication getPasswordAuthentication() {
                        return (new PasswordAuthentication(objUsuarioProxy.toString(),
                                objSenhaProxy.toString().toCharArray()));
                    }
                };

                Authenticator.setDefault(authenticator);
            } else {
                System.out.print("\nNao utiliza proxy na chamada do DialogFlow");
            }
        } catch (javax.naming.NamingException ne) {
            System.out.print("\n " + ne);
        }
    }

    private static InputStream convertFile(InputStream inputStream) throws IOException {

        System.out.print("\nconvertFile");
        prefixFileName = UUID.randomUUID().toString();
        System.out.print("\nconvertFile prefixFileName: " + prefixFileName);

        org.apache.commons.io.FileUtils.copyInputStreamToFile(inputStream, new File(PATH_TEMP + prefixFileName + ".caf"));

        FFmpeg ffmpeg = new FFmpeg(PATH_FFMPEG);
        FFprobe ffprobe = new FFprobe(PATH_FFPROBE);

        FFmpegBuilder builder = new FFmpegBuilder().setInput(PATH_TEMP + prefixFileName + ".caf")
                .overrideOutputFiles(true).addOutput(PATH_TEMP + prefixFileName + "_response.opus").disableSubtitle()
                .setAudioChannels(1).setAudioCodec("libopus").setAudioSampleRate(48_000)
                .setStrict(FFmpegBuilder.Strict.EXPERIMENTAL).done();

        FFmpegExecutor executor = new FFmpegExecutor(ffmpeg, ffprobe);
        executor.createJob(builder).run();

        return org.apache.commons.io.FileUtils.openInputStream(new File(PATH_TEMP + prefixFileName + "_response.opus"));

    }

}
