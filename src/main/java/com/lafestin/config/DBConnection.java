package com.lafestin.config;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * DBConnection — JDBC singleton for La Festin.
 *
 * Usage anywhere in the project:
 *   Connection conn = DBConnection.getInstance().getConnection();
 */
public class DBConnection {

    // DB conn instance
    private static DBConnection instance;

    // Live JDBC conn
    private Connection connection;

    // config.properties
    private String url;
    private String user;
    private String password;

    private DBConnection() {
        loadProperties();
        connect();
    }

    // Loads db.url / db.user / db.password from config.propertie
    private void loadProperties() {
        Properties props = new Properties();

        // getResourceAsStream looks inside src/main/resources/ at runtime
        try (InputStream input = getClass()
                .getClassLoader()
                .getResourceAsStream("config.properties")) {

            if (input == null) {
                throw new RuntimeException(
                    "[DBConnection] config.properties not found in resources/. " +
                    "Did you copy config.properties.example and fill in your credentials?"
                );
            }

            props.load(input);
            this.url = props.getProperty("db.url");
            this.user = props.getProperty("db.user");
            this.password = props.getProperty("db.password");

            // Catch missing keys early — better than a cryptic NullPointerException later
            if (url == null || user == null || password == null) {
                throw new RuntimeException(
                    "[DBConnection] config.properties is missing one or more keys: " +
                    "db.url, db.user, db.password"
                );
            }

        } catch (IOException e) {
            throw new RuntimeException("[DBConnection] Failed to read config.properties.", e);
        }
    }

    // Open JDBC conn
    private void connect() {
        try {
            this.connection = DriverManager.getConnection(url, user, password);
            System.out.println("[DBConnection] Connected to MySQL successfully.");
        } catch (SQLException e) {
            throw new RuntimeException(
                "[DBConnection] Could not connect to the database. " +
                "Check that MySQL is running and your credentials in config.properties are correct.\n" +
                "URL attempted: " + url, e
            );
        }
    }

    // This is the public access point — creates the instance on first call
    public static DBConnection getInstance() {
        if (instance == null) {
            instance = new DBConnection();
        }
        return instance;
    }

    public Connection getConnection() {
        try {
            // isValid(2) pings the DB with a 2-second timeout
            if (connection == null || !connection.isValid(2)) {
                System.out.println("[DBConnection] Connection lost — reconnecting...");
                connect();
            }
        } catch (SQLException e) {
            System.out.println("[DBConnection] Could not validate connection — reconnecting...");
            connect();
        }
        return connection;
    }

    // Call on APP SHUTDOWN
    public void close() {
        if (connection != null) {
            try {
                connection.close();
                System.out.println("[DBConnection] Connection closed.");
            } catch (SQLException e) {
                System.err.println("[DBConnection] Error closing connection: " + e.getMessage());
            }
        }
    }
}