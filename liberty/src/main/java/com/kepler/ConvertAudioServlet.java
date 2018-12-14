package com.kepler; 

import java.io.IOException;
import java.io.InputStream;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;


@WebServlet(urlPatterns = "/convert")

public class ConvertAudioServlet extends HttpServlet {
    private static final long serialVersionUID = 1989907L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        System.out.println("\ndoGet");
        response.getWriter().append("Hello! How are you TODAY?");
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse responseServlet) throws ServletException, IOException {
        InputStream inputStream = request.getInputStream();
        InputStream inputStreamAudioConvertido = ConvertAudio.cafToOpus(inputStream);
        byte[] byteAudioConvertido = org.apache.commons.io.IOUtils.toByteArray(inputStreamAudioConvertido);
        responseServlet.getOutputStream().write(byteAudioConvertido);
    }
}