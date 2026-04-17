package com.lafestin;

import javax.swing.SwingUtilities;

import com.lafestin.config.DBConnection;

public class Main {
    public static void main(String[] args) {
        // Shut down the DB connection (upon Window close)
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            DBConnection.getInstance().close();
        }));

        SwingUtilities.invokeLater(() -> {
            System.out.println("La Festin starting...");
        });
    }
}
