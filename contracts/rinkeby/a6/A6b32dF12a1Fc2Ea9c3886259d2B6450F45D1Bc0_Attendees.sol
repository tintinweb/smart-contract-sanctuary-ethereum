pragma solidity >=0.4.25;

contract Attendees {

    // instantiation of structure
    struct AttendeesStructure {
        uint256 uid;
        address public_key;
        string name;
        string roll;
        string email;
        uint256 imei;
        uint256 status; // 1 = Active 2 = deleted
        uint256 attendanceCount;
    }

    address owner;

    //mapping of structure for storing the attendees
    mapping(uint256 => AttendeesStructure) public attendees;
    uint256 public attendeesCount;

    //1540944000
    // constructor to save some attendees
    constructor() public {
        owner = msg.sender;
    }

    // modifier to add the attendee by owner only
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }


    // add attendee to attendees mapping
    function addAttendee(string memory _name, 
        string memory _roll, 
        string memory _email, 
        uint256 _imei,
        address _public_key,
        uint256 status) onlyOwner public {

        attendeesCount++;
        attendees[attendeesCount] = AttendeesStructure(attendeesCount, _public_key, _name, _roll, _email, _imei, status, 0);
    }

    // authenticate users
    function authenticateUser(address _user_add) public view returns (bool) {
        for (uint256 i = 1; i <= attendeesCount; i++) {
            if (attendees[i].public_key == _user_add) return true;
        }
        return false;
    }

    // for updating attendee
    function updateAttendee(address _user_add,
        string memory _name,
        string memory _roll, 
        string memory _email, 
        uint256 _imei,
        uint256 status) public {
        for (uint256 i = 1; i <= attendeesCount; i++) {
            if (attendees[i].public_key == _user_add) {
                attendees[i] = AttendeesStructure(i, _user_add, _name, _roll, _email, _imei, status, 0);
            }
        }
    }

    function changeStatusEmployee(address _employeeAdd, uint256 status) onlyOwner public returns (bool) {
        for (uint256 i = 1; i <= attendeesCount; i++) {
            if (attendees[i].public_key == _employeeAdd) {
                attendees[i].status = status;
//                attendees[i].public_key = 0*0;
                return true;
            }
        }
        return false;
    }

    struct Subject {
        address attendance_giver;
        string subject_id;
        string batch_id;
        uint256 numberOfStudents;
        mapping(uint256 => AttendeesStructure) studentsEnrolled;
    }

    //mapping of structure  for storing the attendeeDetails
    mapping(uint256 => Subject) public listOfSubjects;
    uint256 public subjectSerialNumber;

    // yeni ders ekleme
    function addNewSubject(address _attendance_giver, string memory _subject_id, string memory _batch_id) public {
        Subject memory s;
        s.attendance_giver = _attendance_giver;
        s.subject_id = _subject_id;
        s.batch_id = _batch_id;
        s.numberOfStudents = 1;

        subjectSerialNumber++;
        listOfSubjects[subjectSerialNumber] = s;
    }


    //derse öğrenci kaydetme işlemi
    //address attendance giver parametresi silindi
    function addStudentEnrolled( string memory _subject_id, address _public_key) public {
        for (uint256 i = 1; i <= subjectSerialNumber; i++) {
            if ((keccak256(abi.encodePacked(listOfSubjects[i].subject_id))) == (keccak256(abi.encodePacked(_subject_id))))
            {
                for (uint256 j = 1; j <= attendeesCount; j++) {
                    if (attendees[j].public_key == _public_key) {
                    	uint256 index = listOfSubjects[i].numberOfStudents;
                        listOfSubjects[i].studentsEnrolled[index] = attendees[j];
                        listOfSubjects[i].numberOfStudents++;
                    }
                }
            }
        }
    }


    //ilgili ders için ogrencinin yoklama vermesi -> yoklama sayısını 1 artırır.
    function markAttendanceBySubject(string memory _subject_id, address _public_key) public {

        for (uint256 i = 1; i <= subjectSerialNumber; i++) {
            if ((keccak256(abi.encodePacked(listOfSubjects[i].subject_id))) == (keccak256(abi.encodePacked(_subject_id))))
            {
                for (uint256 j = 1; j < listOfSubjects[i].numberOfStudents; j++) {
                    if (listOfSubjects[i].studentsEnrolled[j].public_key == _public_key) {
                        listOfSubjects[i].studentsEnrolled[j].attendanceCount++;
                    }
                }
            }
        }
    }
        //ilgili ders için ogrencinin yoklama kaydını getirir
    function getStudentAttendanceForSubject(string memory _subject_id, address _public_key) public view returns (uint256) {
        for (uint256 i = 1; i <= subjectSerialNumber; i++) {
            if ((keccak256(abi.encodePacked(listOfSubjects[i].subject_id))) == (keccak256(abi.encodePacked(_subject_id))))
            {
                for (uint256 j = 1; j < listOfSubjects[i].numberOfStudents; j++) {
                    if (listOfSubjects[i].studentsEnrolled[j].public_key == _public_key) {
                        return listOfSubjects[i].studentsEnrolled[j].attendanceCount;
                    }
                }
            }
        }
    }

}