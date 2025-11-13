RESTORE DATABASE AdventureWorks2022
-- Lưu vào ổ đĩa C, đổi đường dẫn để chạy file AdventureWorks2022.bak
FROM DISK = 'C:\Khanh\AdventureWorks2022.bak' 
WITH 
    MOVE 'AdventureWorks2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2022.mdf',
    MOVE 'AdventureWorks2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AdventureWorks2022_log.ldf',
    REPLACE;
