-- ============================================
-- RaceDay Management System Database Schema
-- Created for PROG6212 Part 1
-- ============================================

-- Drop database if it exists (for clean setup)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDayDB')
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

-- Create database
CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

-- ============================================
-- CREATE TABLES
-- ============================================

-- 1. Users table (supports both Organiser and Participant roles)
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(255) NOT NULL,
    Role NVARCHAR(50) NOT NULL CHECK (Role IN ('Organiser', 'Participant')),
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL
);
GO

-- 2. Events table
CREATE TABLE Events (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserID INT NOT NULL,
    EventName NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    EventDate DATETIME NOT NULL,
    Location NVARCHAR(255) NOT NULL,
    MaxParticipants INT NOT NULL CHECK (MaxParticipants > 0),
    Status NVARCHAR(50) DEFAULT 'Upcoming' NOT NULL CHECK (Status IN ('Upcoming', 'Ongoing', 'Completed', 'Cancelled')),
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
GO

-- 3. Categories table
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    EventID INT NOT NULL,
    CategoryName NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    MinAge INT NULL,
    MaxAge INT NULL,
    GenderRestriction NVARCHAR(50) DEFAULT 'None' NOT NULL CHECK (GenderRestriction IN ('None', 'Male', 'Female')),
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Categories_Event FOREIGN KEY (EventID) REFERENCES Events(EventID) ON DELETE CASCADE,
    CONSTRAINT CK_AgeRange CHECK (MinAge <= MaxAge OR (MinAge IS NULL OR MaxAge IS NULL))
);
GO

-- 4. Enrolments table
CREATE TABLE Enrolments (
    EnrolmentID INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantID INT NOT NULL,
    CategoryID INT NOT NULL,
    EnrolmentDate DATETIME DEFAULT GETDATE() NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Pending' NOT NULL CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    PaymentStatus NVARCHAR(50) DEFAULT 'Pending' NOT NULL CHECK (PaymentStatus IN ('Pending', 'Paid', 'Refunded')),
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Enrolments_Participant FOREIGN KEY (ParticipantID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT FK_Enrolments_Category FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE CASCADE,
    CONSTRAINT UQ_Enrolment_ParticipantCategory UNIQUE (ParticipantID, CategoryID)
);
GO

-- 5. Results table
CREATE TABLE Results (
    ResultID INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentID INT NOT NULL,
    FinishTime TIME NULL,
    Position INT NULL,
    Status NVARCHAR(50) DEFAULT 'DNS' NOT NULL CHECK (Status IN ('DNS', 'DNF', 'Finished', 'Disqualified')),
    Notes NVARCHAR(MAX),
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Results_Enrolment FOREIGN KEY (EnrolmentID) REFERENCES Enrolments(EnrolmentID) ON DELETE CASCADE,
    CONSTRAINT UQ_Result_Enrolment UNIQUE (EnrolmentID)
);
GO

-- ============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Role ON Users(Role);
CREATE INDEX IX_Events_OrganiserID ON Events(OrganiserID);
CREATE INDEX IX_Events_EventDate ON Events(EventDate);
CREATE INDEX IX_Events_Status ON Events(Status);
CREATE INDEX IX_Categories_EventID ON Categories(EventID);
CREATE INDEX IX_Categories_CategoryName ON Categories(CategoryName);
CREATE INDEX IX_Enrolments_ParticipantID ON Enrolments(ParticipantID);
CREATE INDEX IX_Enrolments_CategoryID ON Enrolments(CategoryID);
CREATE INDEX IX_Enrolments_Status ON Enrolments(Status);
CREATE INDEX IX_Enrolments_PaymentStatus ON Enrolments(PaymentStatus);
CREATE INDEX IX_Results_EnrolmentID ON Results(EnrolmentID);
CREATE INDEX IX_Results_Status ON Results(Status);
GO

-- ============================================
-- SEED DATA
-- ============================================

-- 1. Create Organisers (2 organisers)
INSERT INTO Users (Email, PasswordHash, FullName, Role) VALUES
('john.organiser@raceday.com', 'hashed_password_1', 'John Organiser', 'Organiser'),
('sarah.organiser@raceday.com', 'hashed_password_2', 'Sarah Organiser', 'Organiser');
GO

-- 2. Create Participants (4 participants)
INSERT INTO Users (Email, PasswordHash, FullName, Role) VALUES
('mike.runner@email.com', 'hashed_password_3', 'Mike Runner', 'Participant'),
('emma.sprinter@email.com', 'hashed_password_4', 'Emma Sprinter', 'Participant'),
('david.jogger@email.com', 'hashed_password_5', 'David Jogger', 'Participant'),
('lisa.marathon@email.com', 'hashed_password_6', 'Lisa Marathon', 'Participant');
GO

-- 3. Create Events (3 events)
INSERT INTO Events (OrganiserID, EventName, Description, EventDate, Location, MaxParticipants, Status) VALUES
(1, 'City Marathon 2024', 'Annual city marathon event with multiple categories for runners of all levels', '2024-06-15 08:00:00', 'Central Park, New York City', 500, 'Upcoming'),
(1, 'Summer Sprint Series', 'Exciting short distance sprint events for athletes of all ages', '2024-07-20 09:00:00', 'Athletics Stadium, London', 300, 'Upcoming'),
(2, 'Trail Running Challenge', 'Challenging off-road running event through scenic mountain trails', '2024-08-10 07:30:00', 'Mountain View Park, Denver', 200, 'Upcoming');
GO

-- 4. Create Categories for each event (3 categories per event = 9 total)
-- Event 1: City Marathon 2024
INSERT INTO Categories (EventID, CategoryName, Description, MinAge, MaxAge, GenderRestriction) VALUES
(1, 'Full Marathon - Men', '42.2 km marathon for male participants', 18, 65, 'Male'),
(1, 'Full Marathon - Women', '42.2 km marathon for female participants', 18, 65, 'Female'),
(1, 'Half Marathon', '21.1 km half marathon for all participants', 16, 70, 'None');
GO

-- Event 2: Summer Sprint Series
INSERT INTO Categories (EventID, CategoryName, Description, MinAge, MaxAge, GenderRestriction) VALUES
(2, '100m Sprint', 'Short distance sprint - 100 meters', 14, 40, 'None'),
(2, '200m Sprint', 'Medium distance sprint - 200 meters', 14, 40, 'None'),
(2, '400m Track', 'One lap track event - 400 meters', 14, 45, 'None');
GO

-- Event 3: Trail Running Challenge
INSERT INTO Categories (EventID, CategoryName, Description, MinAge, MaxAge, GenderRestriction) VALUES
(3, '5km Trail Run', 'Short trail run perfect for beginners', 12, 60, 'None'),
(3, '10km Trail Run', 'Medium distance trail run for intermediate runners', 16, 65, 'None'),
(3, '15km Trail Challenge', 'Advanced trail running challenge for experienced runners', 18, 70, 'None');
GO

-- 5. Create Enrolments (sample enrolments)
-- Enrolments for City Marathon 2024
INSERT INTO Enrolments (ParticipantID, CategoryID, Status, PaymentStatus) VALUES
(3, 1, 'Confirmed', 'Paid'),    -- Mike Runner in Full Marathon - Men
(4, 2, 'Confirmed', 'Paid'),    -- Emma Sprinter in Full Marathon - Women
(5, 3, 'Pending', 'Pending'),    -- David Jogger in Half Marathon
(6, 2, 'Confirmed', 'Paid');    -- Lisa Marathon in Full Marathon - Women
GO

-- Enrolments for Summer Sprint Series
INSERT INTO Enrolments (ParticipantID, CategoryID, Status, PaymentStatus) VALUES
(3, 4, 'Confirmed', 'Paid'),    -- Mike Runner in 100m Sprint
(5, 5, 'Pending', 'Pending'),    -- David Jogger in 200m Sprint
(6, 6, 'Confirmed', 'Paid'),    -- Lisa Marathon in 400m Track
(4, 4, 'Confirmed', 'Paid');    -- Emma Sprinter in 100m Sprint
GO

-- Enrolments for Trail Running Challenge
INSERT INTO Enrolments (ParticipantID, CategoryID, Status, PaymentStatus) VALUES
(4, 7, 'Confirmed', 'Paid'),    -- Emma Sprinter in 5km Trail Run
(5, 8, 'Confirmed', 'Paid'),    -- David Jogger in 10km Trail Run
(6, 9, 'Pending', 'Pending'),    -- Lisa Marathon in 15km Trail Challenge
(3, 8, 'Confirmed', 'Paid');    -- Mike Runner in 10km Trail Run
GO

-- 6. Create Results (sample results for confirmed enrolments)
INSERT INTO Results (EnrolmentID, FinishTime, Position, Status, Notes) VALUES
(1, '03:45:20', 1, 'Finished', 'First place finish in Full Marathon - Men'),
(2, '03:50:15', 2, 'Finished', 'Second place finish in Full Marathon - Women'),
(4, '04:10:00', 3, 'Finished', 'Third place finish overall'),
(5, '00:12:30', 1, 'Finished', 'New sprint record in 100m'),
(7, '00:14:20', 2, 'Finished', 'Strong performance in 400m'),
(8, '00:11:50', 1, 'Finished', 'New personal best in 100m'),
(10, '00:42:15', 1, 'Finished', 'Excellent performance in 5km Trail'),
(11, '00:45:30', 2, 'Finished', 'Consistent pace in 10km Trail'),
(13, '01:02:00', 3, 'Finished', 'Steady performance in 10km Trail');
GO

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Display counts of each entity
SELECT 'Users' AS Entity, COUNT(*) AS Count FROM Users
UNION ALL
SELECT 'Events', COUNT(*) FROM Events
UNION ALL
SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL
SELECT 'Enrolments', COUNT(*) FROM Enrolments
UNION ALL
SELECT 'Results', COUNT(*) FROM Results;
GO

-- Detailed view: Enrolments with participant and category details
SELECT 
    u.FullName AS ParticipantName,
    e.EventName,
    c.CategoryName,
    en.Status AS EnrolmentStatus,
    en.PaymentStatus,
    CASE 
        WHEN r.ResultID IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasResult,
    r.FinishTime,
    r.Position
FROM Enrolments en
JOIN Users u ON en.ParticipantID = u.UserID
JOIN Categories c ON en.CategoryID = c.CategoryID
JOIN Events e ON c.EventID = e.EventID
LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID
ORDER BY e.EventDate, u.FullName;
GO

-- Summary by event
SELECT 
    e.EventName,
    COUNT(DISTINCT en.EnrolmentID) AS TotalEnrolments,
    COUNT(DISTINCT CASE WHEN en.Status = 'Confirmed' THEN en.EnrolmentID END) AS ConfirmedEnrolments,
    COUNT(DISTINCT r.ResultID) AS ResultsCaptured
FROM Events e
LEFT JOIN Categories c ON e.EventID = c.EventID
LEFT JOIN Enrolments en ON c.CategoryID = en.CategoryID
LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID
GROUP BY e.EventName
ORDER BY e.EventName;
GO

-- Participant summary
SELECT 
    u.FullName,
    u.Role,
    COUNT(DISTINCT en.EnrolmentID) AS TotalEnrolments,
    COUNT(DISTINCT CASE WHEN en.Status = 'Confirmed' THEN en.EnrolmentID END) AS ConfirmedEnrolments,
    COUNT(DISTINCT r.ResultID) AS ResultsCount
FROM Users u
LEFT JOIN Enrolments en ON u.UserID = en.ParticipantID
LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID
WHERE u.Role = 'Participant'
GROUP BY u.UserID, u.FullName, u.Role
ORDER BY u.FullName;
GO

-- ============================================
-- ADDITIONAL USEFUL VIEWS (Optional)
-- ============================================

-- View: Event details with enrolment counts
CREATE VIEW vw_EventSummary AS
SELECT 
    e.EventID,
    e.EventName,
    e.EventDate,
    e.Location,
    e.Status,
    u.FullName AS OrganiserName,
    COUNT(DISTINCT c.CategoryID) AS CategoryCount,
    COUNT(DISTINCT en.EnrolmentID) AS TotalEnrolments,
    COUNT(DISTINCT CASE WHEN en.Status = 'Confirmed' THEN en.EnrolmentID END) AS ConfirmedEnrolments
FROM Events e
JOIN Users u ON e.OrganiserID = u.UserID
LEFT JOIN Categories c ON e.EventID = c.EventID
LEFT JOIN Enrolments en ON c.CategoryID = en.CategoryID
GROUP BY e.EventID, e.EventName, e.EventDate, e.Location, e.Status, u.FullName;
GO

-- View: Participant enrolments with results
CREATE VIEW vw_ParticipantEnrolments AS
SELECT 
    u.UserID,
    u.FullName,
    e.EventName,
    c.CategoryName,
    en.EnrolmentDate,
    en.Status AS EnrolmentStatus,
    en.PaymentStatus,
    r.FinishTime,
    r.Position,
    r.Status AS ResultStatus,
    r.Notes
FROM Users u
JOIN Enrolments en ON u.UserID = en.ParticipantID
JOIN Categories c ON en.CategoryID = c.CategoryID
JOIN Events e ON c.EventID = e.EventID
LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID;
GO

-- View: Leaderboard for each event category
CREATE VIEW vw_CategoryLeaderboard AS
SELECT 
    e.EventName,
    c.CategoryName,
    u.FullName AS ParticipantName,
    r.FinishTime,
    r.Position,
    r.Notes
FROM Results r
JOIN Enrolments en ON r.EnrolmentID = en.EnrolmentID
JOIN Users u ON en.ParticipantID = u.UserID
JOIN Categories c ON en.CategoryID = c.CategoryID
JOIN Events e ON c.EventID = e.EventID
WHERE r.Status = 'Finished'
AND r.Position IS NOT NULL;
GO

-- ============================================
-- STORED PROCEDURES (Optional)
-- ============================================

-- Stored Procedure: Get event statistics
CREATE PROCEDURE sp_GetEventStatistics
    @EventID INT
AS
BEGIN
    SELECT 
        e.EventName,
        e.EventDate,
        COUNT(DISTINCT c.CategoryID) AS Categories,
        COUNT(DISTINCT en.EnrolmentID) AS TotalEnrolments,
        COUNT(DISTINCT CASE WHEN en.Status = 'Confirmed' THEN en.EnrolmentID END) AS Confirmed,
        COUNT(DISTINCT CASE WHEN en.Status = 'Pending' THEN en.EnrolmentID END) AS Pending,
        COUNT(DISTINCT CASE WHEN en.Status = 'Cancelled' THEN en.EnrolmentID END) AS Cancelled,
        COUNT(DISTINCT r.ResultID) AS ResultsRecorded
    FROM Events e
    LEFT JOIN Categories c ON e.EventID = c.EventID
    LEFT JOIN Enrolments en ON c.CategoryID = en.CategoryID
    LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID
    WHERE e.EventID = @EventID
    GROUP BY e.EventName, e.EventDate;
END;
GO

-- Stored Procedure: Get participant's race history
CREATE PROCEDURE sp_GetParticipantHistory
    @ParticipantID INT
AS
BEGIN
    SELECT 
        e.EventName,
        c.CategoryName,
        en.EnrolmentDate,
        en.Status AS EnrolmentStatus,
        r.FinishTime,
        r.Position,
        r.Status AS ResultStatus
    FROM Enrolments en
    JOIN Categories c ON en.CategoryID = c.CategoryID
    JOIN Events e ON c.EventID = e.EventID
    LEFT JOIN Results r ON en.EnrolmentID = r.EnrolmentID
    WHERE en.ParticipantID = @ParticipantID
    ORDER BY e.EventDate DESC;
END;
GO

-- ============================================
-- TRIGGERS (Optional - for audit)
-- ============================================

-- Trigger: Update UpdatedAt on Users
CREATE TRIGGER trg_Users_Update
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users
    SET UpdatedAt = GETDATE()
    FROM Users u
    INNER JOIN inserted i ON u.UserID = i.UserID;
END;
GO

-- Trigger: Update UpdatedAt on Events
CREATE TRIGGER trg_Events_Update
ON Events
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Events
    SET UpdatedAt = GETDATE()
    FROM Events e
    INNER JOIN inserted i ON e.EventID = i.EventID;
END;
GO

-- ============================================
-- FINAL VERIFICATION
-- ============================================

PRINT '============================================';
PRINT 'RaceDay Database Setup Complete!';
PRINT '============================================';
PRINT '';
PRINT 'Database: RaceDayDB';
PRINT 'Tables Created: Users, Events, Categories, Enrolments, Results';
PRINT '';
PRINT 'Sample Data Loaded:';
PRINT '  - 2 Organisers';
PRINT '  - 4 Participants';
PRINT '  - 3 Events';
PRINT '  - 9 Categories (3 per event)';
PRINT '  - 12 Enrolments';
PRINT '  - 9 Results';
PRINT '';
PRINT '============================================';
GO

-- Run a final verification
EXEC sp_GetEventStatistics @EventID = 1;
GO