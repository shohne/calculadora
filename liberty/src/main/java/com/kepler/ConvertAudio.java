package com.kepler;


import net.bramp.ffmpeg.builder.*;
import net.bramp.ffmpeg.*;

import java.net.*;
import java.io.*;
import javax.naming.InitialContext;
import java.util.UUID;
import java.net.HttpURLConnection;



public class ConvertAudio { 

    private static String PATH_FFMPEG = "/usr/bin/ffmpeg2";
    private static String PATH_FFPROBE = "/usr/bin/ffprobe2";
    private static String PATH_TEMP = "/tmp/calculadora/";
    private static String prefixFileName = "nada";
    private static String servidorFfmpeg = "";

    static {
        configurarFfmpeg();
    }

    private static void configurarFfmpeg() {
        try {

            Object objPathFfmpeg = new InitialContext().lookup("pathFfmpeg");
            Object objPathFfprob = new InitialContext().lookup("pathFfprob");
            Object objPathTemp = new InitialContext().lookup("pathTemp");
            Object objServidorFfmpeg = new InitialContext().lookup("servidorFfmpegs");


            if (objPathFfmpeg != null) PATH_FFMPEG = (String) objPathFfmpeg;
            if (objPathFfprob != null)  PATH_FFPROBE = (String) objPathFfprob;
            if (objPathTemp != null) PATH_TEMP = (String) objPathTemp;
            if (objServidorFfmpeg != null) PATH_TEMP = (String) objServidorFfmpeg;

        } catch (javax.naming.NamingException ne) {
            System.out.print("\n " + ne);
        }
    }


    public static InputStream cafToOpus(InputStream inputStream) throws IOException {

        System.out.print("\nConvertAudio.cafToOpus");

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

    public static InputStream cafToOpusRemoto(InputStream inputStream) throws IOException {
		URL url = new URL(servidorFfmpeg);
		HttpURLConnection connection = (HttpURLConnection) url.openConnection();
		connection.setRequestMethod("POST");
        connection.setDoOutput(true);
        DataOutputStream wr = new DataOutputStream(connection.getOutputStream());
        byte[] byteInputStream = org.apache.commons.io.IOUtils.toByteArray(inputStream);
		wr.write(byteInputStream);
		wr.flush();
		wr.close();
		return connection.getInputStream();
    }

}