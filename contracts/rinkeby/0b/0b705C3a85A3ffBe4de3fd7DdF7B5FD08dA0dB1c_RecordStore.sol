pragma solidity ^0.8.1;

contract RecordStore
{
    address owner;
    uint [] dataglobal;

    constructor()
    {
        owner = msg.sender;
    }

    struct student
    {
        string Name;
        string Email;
        string DOB;
        string Class;
        string Section;
    }

    student[] public StudentRecord;
    // student[] public dataArray;

    // // Create an stdrecord event 
    // event stdrecord( string [] stdArray);
    event stdlength(uint stdLength);

    function setStudentRecords(string calldata _name, string calldata _email,
        string calldata _DOB, string calldata _class, string calldata _section) public
        {
            StudentRecord.push(  // resize the array and store new item
                student(         // of type `student`
                    _name,
                    _email,
                    _DOB,
                    _class,
                    _section
                )
            );
            // emit stdrecord(student.dataArray);
        }

    function GetStudentRecord(uint index) public view returns(student memory)
    {
        return StudentRecord[index];
    }

    function studentCount() public returns(uint)
    {
        emit stdlength(StudentRecord.length);
        return StudentRecord.length;
    }
}