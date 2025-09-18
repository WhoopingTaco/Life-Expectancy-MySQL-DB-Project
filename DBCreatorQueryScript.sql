create database amazon_book;
use amazon_book;

-- Author table with primary key as author ID
CREATE TABLE Authors (
  AuthorID INT AUTO_INCREMENT PRIMARY KEY,
  AuthorName VARCHAR(255) NOT NULL
);

-- Genre table
CREATE TABLE Genres (
  GenreID INT AUTO_INCREMENT PRIMARY KEY,
  GenreName VARCHAR(100) NOT NULL
);

-- Overall book table
CREATE TABLE Books (
  Name VARCHAR(255) NOT NULL,
  PublicationYear INT NOT NULL,
  AuthorID INT NOT NULL,
  UserRating DECIMAL(3,2),
  Reviews INT,
  Price DECIMAL(10,2),
  GenreID INT NOT NULL,
  PRIMARY KEY (Name, PublicationYear),
  FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID),
  FOREIGN KEY (GenreID) REFERENCES Genres(GenreID)
);

-- Data staging table
CREATE TABLE staging_csv (
    Name VARCHAR(255),
    AuthorName VARCHAR(255),
    UserRating DECIMAL(3,2),
    Reviews INT,
    Price DECIMAL(10,2),
    PublicationYear INT,
    GenreName VARCHAR(100)
);

-- Loading command (replace with file path)
LOAD DATA LOCAL INFILE "C:/***/Amazon.csv"
INTO TABLE staging_csv
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Inserting into authors
INSERT IGNORE INTO Authors (AuthorName)
SELECT DISTINCT AuthorName
FROM staging_csv;

-- Inserting into genres
INSERT IGNORE INTO Genres (GenreName)
SELECT DISTINCT GenreName
FROM staging_csv;

-- Inserting into Books 
INSERT INTO Books (Name, PublicationYear, AuthorID, UserRating, Reviews, Price, GenreID)
SELECT
    s.Name,
    s.PublicationYear,
    a.AuthorID,
    s.UserRating,
    s.Reviews,
    s.Price,
    g.GenreID
FROM staging_csv s
JOIN Authors a ON s.AuthorName = a.AuthorName
JOIN Genres g ON s.GenreName = g.GenreName
ON DUPLICATE KEY UPDATE
    AuthorID   = VALUES(AuthorID),
    UserRating = VALUES(UserRating),
    Reviews    = VALUES(Reviews),
    Price      = VALUES(Price),
    GenreID    = VALUES(GenreID);

-- Database check
SELECT 
    b.Name AS BookName,
    b.PublicationYear,
    a.AuthorName,
    b.UserRating,
    b.Reviews,
    b.Price,
    g.GenreName
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
JOIN Genres g  ON b.GenreID = g.GenreID;

-- Top 50 unique books (top-selling) by review counts shown with user rating
SELECT 
    b.Name AS Title,
    MAX(b.PublicationYear) AS Year,
    a.AuthorName AS Author,
    MAX(b.Reviews) AS ReviewCount
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
GROUP BY b.Name, a.AuthorName
ORDER BY ReviewCount DESC
LIMIT 50;

-- A user rating greater than 4 in 2019
SELECT 
    b.Name AS BookName,
    b.PublicationYear,
    a.AuthorName,
    b.UserRating,
    b.Reviews,
    b.Price,
    g.GenreName
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
JOIN Genres g  ON b.GenreID = g.GenreID
WHERE b.UserRating > 4
  AND b.PublicationYear = 2019;

-- Greater than 10k reviews in 2018
SELECT 
    b.Name AS BookName,
    b.PublicationYear,
    a.AuthorName,
    b.UserRating,
    b.Reviews,
    b.Price,
    g.GenreName
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
JOIN Genres g  ON b.GenreID = g.GenreID
WHERE b.Reviews > 10000
  AND b.PublicationYear = 2018;

-- Authors with most books
SELECT 
    a.AuthorName,
    COUNT(*) AS BookCount
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
GROUP BY a.AuthorName
ORDER BY BookCount DESC
LIMIT 10;

-- Yearly count of books per genre
SELECT 
    b.PublicationYear AS Year,
    g.GenreName,
    COUNT(*) AS NumBooks
FROM Books b
JOIN Genres g ON b.GenreID = g.GenreID
GROUP BY b.PublicationYear, g.GenreName
ORDER BY Year, g.GenreName;

-- Books priced over $40 with more than 5,000 reviews
SELECT b.Name, a.AuthorName, b.Price, b.Reviews, b.UserRating, b.PublicationYear
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
WHERE b.Price > 40 AND b.Reviews > 5000;

-- Books released before 2015 with rating above 4.2
SELECT b.Name, a.AuthorName, b.PublicationYear, b.UserRating, b.Reviews
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
WHERE b.PublicationYear < 2015 AND b.UserRating > 4.2;

-- Books priced less than $10 with rating above 3.5
SELECT b.Name, a.AuthorName, b.PublicationYear, b.Price, b.UserRating, b.Reviews
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
WHERE b.Price < 10 AND b.UserRating > 3.5;
