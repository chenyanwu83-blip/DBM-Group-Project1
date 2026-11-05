CREATE DATABASE IF NOT EXISTS ride_hailing
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ride_hailing;

DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Trip;
DROP TABLE IF EXISTS Driver;
DROP TABLE IF EXISTS Vehicle;
DROP TABLE IF EXISTS Passenger;

CREATE TABLE Passenger (
  psg_id INT PRIMARY KEY,
  name   VARCHAR(40) NOT NULL
);

CREATE TABLE Vehicle (
  vehicle_id INT PRIMARY KEY,
  plate      VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Driver (
  driver_id  INT PRIMARY KEY,
  name       VARCHAR(40) NOT NULL,
  vehicle_id INT NOT NULL UNIQUE,          -- N:1 且一人一车
  FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id)
);

CREATE TABLE Trip (
  trip_id    INT PRIMARY KEY,
  psg_id     INT NOT NULL,
  driver_id  INT NOT NULL,
  fare       DECIMAL(8,2),
  status     VARCHAR(20),
  start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (psg_id)    REFERENCES Passenger(psg_id),
  FOREIGN KEY (driver_id) REFERENCES Driver(driver_id)
);

CREATE TABLE Payment (
  pay_id  INT PRIMARY KEY,
  trip_id INT NOT NULL UNIQUE,             -- 1:1 的实现
  amount  DECIMAL(8,2) CHECK (amount >= 0),
  method  VARCHAR(20),
  FOREIGN KEY (trip_id) REFERENCES Trip(trip_id)
);