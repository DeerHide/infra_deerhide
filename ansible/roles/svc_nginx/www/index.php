<?php
$servername = "mysql";
$username = "app_user";
$password = "app_password";
$dbname = "app_db";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: ". $conn->connect_error);
}

echo "Connected successfully to MySQL!";
