pragma solidity >=0.4.25;

contract Attendance {

    // instantiation of structure
    struct AttendeesStructure {
        uint256 id;
        address public_key;
        string name;
        uint256 authenticated; // 1 = authenticated 2 = not Authenticated
        uint256 attendanceCount; 
    }
    struct TeacherStructure {
        uint256 id;
        address public_key;
        string name; 
    }
    event AttendanceCheck(address indexed addr, bytes32 indexed count);

    mapping(uint256 => TeacherStructure) public teachers;
    address owner;
    
    //mapping of structure for storing the attendees
    mapping(uint256 => AttendeesStructure) public attendees;
    uint256 public numberOfAttendees;
    uint256 public numberOfTeachers;
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
    modifier isTeacher(address _user_add){
        for (uint256 i = 1; i <= numberOfTeachers; i++) {
            if (teachers[i].public_key == _user_add) {
               _;
            }
        }
    }

    event AddingAttendee(address indexed _address,string _name,uint256 numberID );
    // add attendee to attendees mapping
    function addAttendee(string memory _name, 
        address _public_key,
        uint256 authenticated) isTeacher(msg.sender) public {
        numberOfAttendees++;
        attendees[numberOfAttendees] = AttendeesStructure(numberOfAttendees, _public_key, _name, authenticated, 0);
        emit AddingAttendee(_public_key,_name,numberOfAttendees);
    }

    function addTeacher(string memory _name, 
        address _public_key
        ) onlyOwner public {
        numberOfTeachers++;
        teachers[numberOfTeachers] = TeacherStructure(numberOfTeachers, _public_key, _name);
    }
    

    // isAuthenticated, params: studentAddress
    function isAuthenticated(address _user_add) public view returns (bool) {
        for (uint256 i = 1; i <= numberOfAttendees; i++) {
            if (attendees[i].public_key == _user_add) return true;
        }
        return false;
    }

    // updating students
    function updateAttendee(address _user_add,
        string memory _name,
        uint256 status
        ,uint256 attendanceCount) public {
        for (uint256 i = 1; i <= numberOfAttendees; i++) {
            if (attendees[i].public_key == _user_add) {
                attendees[i] = AttendeesStructure(i, _user_add, _name, status, attendanceCount);
            }
        }
    }
    //authenticating students
    function authenticateUser(address _employeeAdd, uint256 authenticated) onlyOwner public returns (bool) {
        for (uint256 i = 1; i <= numberOfAttendees; i++) {
            if (attendees[i].public_key == _employeeAdd) {
                attendees[i].authenticated = authenticated;
//                
                return true;
            }
        }
        return false;
    }

    struct Subject {
        address attendance_giver;
        string subject_id;
        uint256 numberOfStudents;
        mapping(uint256 => AttendeesStructure) studentsEnrolled;
        uint256 numberOfSessions;
    }

    //mapping of structure  for storing the attendeeDetails
    mapping(uint256 => Subject) public listOfSubjects;
    uint256 public subjectNumber;

    // yeni ders ekleme
    function addNewSubject(address _attendance_giver, string memory _subject_id) onlyOwner public {
        Subject memory s;
        s.attendance_giver = _attendance_giver;
        s.subject_id = _subject_id;
        s.numberOfStudents = 1;
        s.numberOfSessions = 0;
        subjectNumber++;
        listOfSubjects[subjectNumber] = s;
    }


    //derse öğrenci kaydetme işlemi
    //address attendance giver parametresi silindi
    function addStudentEnrolled( string memory _subject_id, address _public_key) isTeacher(msg.sender) public {
        for (uint256 i = 1; i <= subjectNumber; i++) {
            if ((keccak256(abi.encodePacked(listOfSubjects[i].subject_id))) == (keccak256(abi.encodePacked(_subject_id))))
            {
                for (uint256 j = 1; j <= numberOfAttendees; j++) {
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

        for (uint256 i = 1; i <= subjectNumber; i++) {
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
        for (uint256 i = 1; i <= subjectNumber; i++) {
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
    //derse session ekleme
    function addSessionToSubject(string memory _subject_id) isTeacher(msg.sender) public{
        for (uint256 i = 1; i <= subjectNumber; i++) {
            if ((keccak256(abi.encodePacked(listOfSubjects[i].subject_id))) == (keccak256(abi.encodePacked(_subject_id))))
            {
                listOfSubjects[i].numberOfSessions++;
            }
        }
    }
    //solidity float desteklemiyor sonuc frontta hesaplanacak. Bu sadece session sayısını dondurecek
    function getAttendancePercentage(string memory _subject_id, address _public_key) public view returns (uint256) {
        for (uint256 i = 1; i <= subjectNumber; i++) {
            if ((keccak256(abi.encodePacked(listOfSubjects[i].subject_id))) == (keccak256(abi.encodePacked(_subject_id))))
            {
                for (uint256 j = 1; j < listOfSubjects[i].numberOfStudents; j++) {
                    if (listOfSubjects[i].studentsEnrolled[j].public_key == _public_key) {
                        
                        return listOfSubjects[i].numberOfSessions;
                    }
                }
            }
        }
    }

}