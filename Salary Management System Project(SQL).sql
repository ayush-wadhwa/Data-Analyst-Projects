-- PROJECT
create database salary_management_system;
use salary_management_system;

create table Employee(EID int not null unique primary key,
 EName varchar(25), Gender enum('male','female','other') ,
Email varchar(255)constraint chk_email_format check (Email like '%@%.com') , JoinDate date);

 create table Salary(SID int not null unique primary key, Basic_Allowance int);
 
create table Employee_Salary(EID  int, SID int,
foreign key(EID) references Employee (EID),
foreign key(SID) references Salary (SID));

create table emp_leave(LID int, EID int, L_month date , L_days date ,
foreign key (EID) references Employee (EID));

create table Transection(TID int, EID int, Amount int, T_Date date, S_month date,
foreign key (EID) references Employee (EID));

create table Fund(FID int, Fund_amount int);

create table Fund_Audit(NewFund int, OldFund int, T_Date date);

create table EmpSalary_Audit(EID int, NewSID int, OldSID int, ChangingDate date,
foreign key (EID) references Employee (EID));
show tables;


delimiter //
create procedure ViewDetails (EmployeeID int)
begin
     select EID, EName, Gender, Email, JoinDate
     from Employee
     where EID = EmployeeID ;
	 select TID, Amount, T_Date
     from Transection
     where EID = EmployeeID;
end	 //
delimiter ;


delimiter //
create function GenerateSalary(EmployeeID int, SalaryMonth date)
returns int
deterministic
reads sql data
begin
     declare Salary int;
     set Salary = (select Basic_Allowance from Salary where SID = (select SID from Employee_Salary 
     where EID = EmployeeID));
     return Salary;
END //
delimiter ;


delimiter //
create procedure TransectSalary (EmployeeID int, SalaryMonth date)
begin
     declare Salary int;
     set Salary = dbo.GenerateSalary(EmployeeID, SalaryMonth);
	 insert into Transection (EID, Amount, T_Date, S_month)
    VALUES (EmployeeID, Salary, GETDATE(), SalaryMonth);
end// 
delimiter ;


delimiter //
create procedure AddFund (Amount int)
begin
     insert into Fund (Fund_amount)
     values (Amount);
     insert into Fund_Audit (NewFund, OldFund, T_Date)
     select Amount, ifnull(max(Fund_amount), 0), GETDATE()
     from Fund;
end //
delimiter ;


delimiter //
create procedure AddLeave(in LID int, in EID int, in L_month date, in L_days date)
begin
     insert into emp_leave (LID, EID, L_month, L_days) 
     values (LID, EID, L_month, L_days);
end //
delimiter ;


delimiter //
create procedure TransectSalary(in EID int, in Amount int, in Month date)
begin
     declare isValid int;
     set isValid = CheckValid(EID, Month);
	 if isValid = 1 then
	 insert into Transection (EID, Amount, T_Date, S_month)
     values (EID, Amount, now(), Month);
	 call UpdateFund(Amount);
end
delimiter ;


delimiter //
create procedure UpdateFund(in Amount int)
begin
     update Fund set Fund_amount = Fund_amount - Amount;
end //

delimiter ;


delimiter //
create function Generate_Salary( EID int, Month date)
returns int
deterministic 
reads sql data
begin
     declare calculatedSalary int;
     select Basic_Allowance - coalesce(sum(L_days), 0)
     into calculatedSalary
     from Salary
     left join Employee_Salary on Salary.SID = Employee_Salary.SID
     left join mp_leave on Employee_Salary.EID = emp_leave.EID
     where Employee_Salary.EID = EID and emp_leave.L_month = Month;
     return calculatedSalary;
end //
delimiter ;


delimiter // 
create function CheckValid( EID int,  Month date)
returns int
deterministic
reads sql data
begin
     declare isValid int;
     select count(*)
     into isValid
     from Employee_Salary
     where EID = EID and exists (select 1 from emp_leave where EID = Employee_Salary.EID and L_month = Month);
     return case when isValid > 0 then 1 else 2 end;
end //
delimiter ;


delimiter //
create procedure AddEmployee (EName varchar(15), Gender varchar(10), Email varchar(255),
 JoinDate date, SID int)
begin
     insert into Employee (EName, Gender, Email, JoinDate)
     values (EName, Gender, Email, JoinDate);
     insert into Employee_Salary (EID, SID)
     values (scope_identity(), SID);
end//
delimiter ;


delimiter //
create procedure ChangeEmpPost(in EID int, in SID int)
begin
     update Employee_Salary
     set SID = SID
     where EID = EID;
end //
delimiter ;



-- TRIGGERS

AddLeaves Trigger:

delimiter //
create trigger AddLeaves
after insert on emp_leave
for each row
begin
-- logic
end;
delimiter ;


ChangeEmpSalary Trigger:

delimiter //
create trigger ChangeEmpSalary
after update on Employee_Salary
for each row
begin
     insert into EmpSalary_Audit (EID, NewSID, OldSID, ChangingDate)
     select ins.EID, ins.SID as NewSID, del.SID as OldSID, GETDATE() as ChangingDate
     from INSERTED ins
     inner join DELETED del on ins.EID = del.EID;
end //
delimiter ;


AddEmp Trigger:

delimiter //
create trigger AddEmp
after insert on Employee
for each row
begin
   -- logic
end//
delimiter ;


AddEmpSalary Trigger:

delimiter//

create trigger AddEmpSalary
after insert on Employee_Salary
for each row
begin
   -- logic
end//
delimiter ;


Transect Trigger:

deimiter//
create trigger Transect
after insert on Transection
for each row
begin
    -- logic
end//
delimiter ;


 UpdateFund Trigger:

delimiter //
create trigger UpdateFund
after update on Fund
for each row
begin
     insert into Fund_Audit (NewFund, OldFund, T_Date)
     select ins.Fund_amount as NewFund, del.Fund_amount as OldFund, GETDATE() as T_Date
     from INSERTED ins
    inner join DELETED del on ins.FID = del.FID;
end//
delimiter ;
