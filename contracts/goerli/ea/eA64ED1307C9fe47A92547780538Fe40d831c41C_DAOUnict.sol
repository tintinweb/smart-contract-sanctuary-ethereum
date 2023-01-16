// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

library sharedObjects {
    struct Professor {
        string name;
        string surname;
        string role; // ex. Associate Professor of Information Processing Systems
        string office;
        string email;
        int telephone;
        string website;
    }

    struct Secretariat {
        string personInCharge; // responsible
        string area;
        string office;
        string email;
        int telephone;
    }

    struct Student {
        string name;
        string surname;
        string courseSubscribed; // expressed as identifier like "LM32" and not like "ing. inf."
        string email;
        int telephone;
    }

    struct ExamRegistration {
        string date;
        int grade;
        int codeSub;
    }

    struct ExamBooking {
        address studentAddress;
        int codeSubject;
        string date;
    }
}

library SafeMath {
    // Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library structSubject {
    struct Subject {
        string name;
        int cfu;
        int didacticHours;
        address teacherAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./DegreeCourse.sol";
import {sharedObjects, structSubject} from "./CommonLibrary.sol";
import "./TokenUnict.sol";

contract DAOUnict {
    address immutable i_admin_address;
    TokenUnict immutable i_uniToken;
    uint256 constant INITIAL_TOKEN_AMOUNT = 10000000;
    uint256 constant INITIAL_TEACHER_TOKEN = 1000;
    uint8 private codeBookingForExam;

    mapping(string => DegreeCourse) public unictDegreeCourses; // example: "LM32" is the identifier for the course degree "ing.inf.magistrale"

    mapping(address => sharedObjects.Professor) public unictProfessors; // professors, students and secretariats will be recognized by associated public key

    mapping(address => sharedObjects.Secretariat) public unictSecretariats;

    mapping(address => sharedObjects.Student) public unictStudents;

    mapping(uint8 => sharedObjects.ExamBooking) public examBookings;

    constructor() {
        i_admin_address = msg.sender;
        i_uniToken = new TokenUnict(
            INITIAL_TOKEN_AMOUNT,
            "Token UNICT",
            "UNICT",
            msg.sender
        );
    }

    // adding/delete degree courses
    function addDegreeCourse(string memory courseId) public onlyAdmin {
        unictDegreeCourses[courseId] = new DegreeCourse();
    }

    function deleteDegreeCourse(string memory courseId) public onlyAdmin {
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        delete unictDegreeCourses[courseId];
    }

    // checking degree course
    function checkDegreeCourse(
        string memory courseId
    ) public view returns (bool) {
        address checkingDegreeCourse = address(unictDegreeCourses[courseId]);
        if (checkingDegreeCourse != address(0x0)) {
            return true;
        } else {
            return false;
        }
    }

    // adding or delete subject to some courses
    function addSubjectToCourse(
        string memory courseId,
        string memory _name,
        int _cfu,
        int _didacticHours,
        address _teacherAddress,
        int code
    ) public onlyAdmin {
        bool checkTeacher = checkExistingProfessor(_teacherAddress);
        require(
            checkTeacher == true,
            "The address of this teacher was not found!"
        );
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        unictDegreeCourses[courseId].addSubject(
            _name,
            _cfu,
            _didacticHours,
            _teacherAddress,
            code
        );
    }

    function deleteSubjectFromCourse(
        string memory courseId,
        int code
    ) public onlyAdmin {
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        unictDegreeCourses[courseId].deleteSubject(code);
    }

    // control functions for the subjects
    function checkSubjectIntoCourse(
        string memory courseId,
        int code
    ) public view returns (bool) {
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        return unictDegreeCourses[courseId].checkSubject(code);
    }

    function infoSubject(
        string memory courseId,
        int code
    ) public view returns (structSubject.Subject memory) {
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        return unictDegreeCourses[courseId].infoExistingSubject(code);
    }

    // editing subjects already submitted (available only for secretary)
    function modifyCFU(
        string memory courseId,
        int code,
        int newCFU
    ) public onlySecretariat {
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        unictDegreeCourses[courseId].editCfuSubject(code, newCFU);
    }

    function modifyTeacher(
        string memory courseId,
        int code,
        address newProfessorAddr
    ) public onlySecretariat {
        require(
            checkDegreeCourse(courseId) == true,
            "The identifier of this course was not found"
        );
        unictDegreeCourses[courseId].editProfessorAddress(
            code,
            newProfessorAddr
        );
    }

    // adding teacher to Unict
    function addProfessor(
        string memory _name,
        string memory _surname,
        string memory _role,
        string memory _office,
        string memory _email,
        int _telephone,
        string memory _website,
        address pubKey
    ) public onlyAdmin {
        unictProfessors[pubKey] = sharedObjects.Professor(
            _name,
            _surname,
            _role,
            _office,
            _email,
            _telephone,
            _website
        );
        bool giveTokens = i_uniToken.approve(
            pubKey,
            INITIAL_TEACHER_TOKEN,
            i_admin_address
        );
        require(
            giveTokens == true,
            "Error in the assignments of the tokens for the prof"
        );
    }

    // control functions for teachers
    function checkExistingProfessor(
        address PubKeyProf
    ) public view returns (bool) {
        bytes memory checkTeacher = bytes(unictProfessors[PubKeyProf].email);
        if (checkTeacher.length != 0) {
            return true;
        } else {
            return false;
        }
    }

    function infoExistingProfessor(
        address PubKeyProf
    ) public view returns (sharedObjects.Professor memory) {
        bytes memory checkTeacher = bytes(unictProfessors[PubKeyProf].email);
        require(
            checkTeacher.length != 0,
            "The address of this teacher was not found!"
        );
        return unictProfessors[PubKeyProf];
    }

    // register an exam for a student
    function registerExam(
        address studAddr,
        string memory courseId,
        int codeSubject,
        string memory date,
        int grade
    ) public onlyTeacher returns (sharedObjects.ExamRegistration memory) {
        // check 1: student registered to Unict
        require(
            checkExistingStudent(studAddr) == true,
            "The address of this student was not found!"
        );
        // check 2: student registered to the degree course containing the subject
        sharedObjects.Student memory stud = infoExistingStudent(studAddr);
        bool checkCourse = compare(stud.courseSubscribed, courseId);
        require(
            checkCourse == true,
            "The student is not subscribed in this course"
        );
        // check 3: student already registered the exam
        require(
            i_uniToken.checkSubjectAlreadyRegistered(studAddr, codeSubject) ==
                false,
            "The student already registered this subject"
        );

        structSubject.Subject memory subj = infoSubject(courseId, codeSubject);
        require(
            subj.cfu != 0,
            "Error: code subject not found for this degree course!"
        );
        uint256 _cfu = uint256(subj.cfu);
        i_uniToken.transferFrom(
            i_admin_address,
            studAddr,
            _cfu,
            msg.sender,
            codeSubject
        );
        return sharedObjects.ExamRegistration(date, grade, codeSubject);
    }

    // checking the students' exam bookings
    function checkStudentExamBooking(
        uint8 bookingCode
    ) public view onlyTeacher returns (sharedObjects.ExamBooking memory) {
        require(
            examBookings[bookingCode].codeSubject != 0,
            "This code doesn't belong to any exam booking"
        );
        return examBookings[bookingCode];
    }

    // adding secretariat
    function addSecretary(
        string memory _personInCharge,
        string memory _area,
        string memory _office,
        string memory _email,
        int _telephone,
        address pubKey
    ) public onlyAdmin {
        unictSecretariats[pubKey] = sharedObjects.Secretariat(
            _personInCharge,
            _area,
            _office,
            _email,
            _telephone
        );
    }

    // control functions for secretariats
    function checkExistingSecretariat(
        address PubKeySecretary
    ) public view returns (bool) {
        bytes memory checkSecretary = bytes(
            unictSecretariats[PubKeySecretary].email
        );
        if (checkSecretary.length != 0) {
            return true;
        } else {
            return false;
        }
    }

    function infoExistingSecretariat(
        address PubKeySecretary
    ) public view returns (sharedObjects.Secretariat memory) {
        bytes memory checkSecretary = bytes(
            unictSecretariats[PubKeySecretary].email
        );
        require(
            checkSecretary.length != 0,
            "The address of this secretariat was not found!"
        );
        return unictSecretariats[PubKeySecretary];
    }

    // adding a student
    function addStudent(
        string memory _name,
        string memory _surname,
        string memory _courseSubscribed,
        string memory _email,
        int telephone,
        address pubKey
    ) public onlySecretariat {
        require(
            checkDegreeCourse(_courseSubscribed),
            "The identifier of this course was not found"
        );
        unictStudents[pubKey] = sharedObjects.Student(
            _name,
            _surname,
            _courseSubscribed,
            _email,
            telephone
        );
    }

    // control functions for students
    function infoExistingStudent(
        address PubKeyStudent
    ) public view returns (sharedObjects.Student memory) {
        bytes memory checkStudent = bytes(unictStudents[PubKeyStudent].email);
        require(
            checkStudent.length != 0,
            "The address of this student was not found!"
        );
        return unictStudents[PubKeyStudent];
    }

    function checkExistingStudent(
        address PubKeyStudent
    ) public view returns (bool) {
        bytes memory checkStudent = bytes(unictStudents[PubKeyStudent].email);
        if (checkStudent.length != 0) {
            return true;
        } else {
            return false;
        }
    }

    // booking to an exam
    function registerToExam(
        string memory date,
        int codeSubject
    ) public onlyStudent {
        sharedObjects.Student memory stud = infoExistingStudent(msg.sender);
        require(
            checkSubjectIntoCourse(stud.courseSubscribed, codeSubject) == true,
            "Error: code subject not found for your degree course!"
        );
        codeBookingForExam++; // simulate a code that is an identifier for the bookings
        examBookings[codeBookingForExam] = sharedObjects.ExamBooking(
            msg.sender,
            codeSubject,
            date
        );
    }

    function getCodeBookingForExam() public view returns (uint8) {
        return codeBookingForExam; // the student must keep this code because the professor can check the booking with this
    }

    // check cfu acquired and subject already done
    function checkCfuAcquired() public view onlyStudent returns (uint256) {
        return checkTokenBalance(msg.sender);
    }

    function checkSubjectsDone()
        public
        view
        onlyStudent
        returns (int[] memory)
    {
        return i_uniToken.infoSubectAlreadyRegistered(msg.sender);
    }

    modifier onlyAdmin() {
        require(
            i_admin_address == msg.sender,
            "Function available only for admin"
        );
        _;
    }
    modifier onlySecretariat() {
        require(
            checkExistingSecretariat(msg.sender) == true,
            "Function available only for the secretariat"
        );
        _;
    }
    modifier onlyTeacher() {
        require(
            checkExistingProfessor(msg.sender) == true,
            "Function available only for the professors"
        );
        _;
    }
    modifier onlyStudent() {
        require(
            checkExistingStudent(msg.sender) == true,
            "Function available only for the students"
        );
        _;
    }

    // comparing strings
    function compare(
        string memory str1,
        string memory str2
    ) private pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    function checkAdmin(address addr) public view returns (bool) {
        if (addr == i_admin_address) {
            return true;
        } else {
            return false;
        }
    }

    // utility functions about ERC20 token
    function checkAvailableTokenPerProfessor(
        address pubKeyProf
    ) public view onlyTeacher returns (uint256) {
        return i_uniToken.allowance(i_admin_address, pubKeyProf);
    }

    function checkTokenBalance(address addr) public view returns (uint256) {
        return i_uniToken.balanceOf(addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import {structSubject} from "./CommonLibrary.sol";

contract DegreeCourse {
    mapping(int => structSubject.Subject) private studyPlan;

    function addSubject(
        string calldata _name,
        int _cfu,
        int _didacticHours,
        address _teacherAddress,
        int code
    ) public {
        studyPlan[code] = structSubject.Subject(
            _name,
            _cfu,
            _didacticHours,
            _teacherAddress
        );
    }

    function deleteSubject(int code) public {
        require(
            checkSubject(code) == true,
            "Cannot delete the subjects with this code: it was not found on the study plan"
        );
        delete studyPlan[code];
    }

    // check if the subject is already in the study plan
    function checkSubject(int code) public view returns (bool) {
        int checkCfuSubject = studyPlan[code].cfu;
        if (checkCfuSubject != 0) {
            return true;
        } else {
            return false;
        }
    }

    function infoExistingSubject(
        int code
    ) public view returns (structSubject.Subject memory) {
        int checkCfuSubject = studyPlan[code].cfu;
        require(
            checkCfuSubject != 0,
            "This course degree has not this subject's code"
        );
        return studyPlan[code];
    }

    // list of functions for editing a subject already submitted
    function editCfuSubject(int code, int newCfu) public {
        require(
            checkSubject(code) == true,
            "Cannot edit the subject with this code: it was not found on the study plan"
        );
        studyPlan[code].cfu = newCfu;
    }

    function editProfessorAddress(int code, address newProfAddr) public {
        require(
            checkSubject(code) == true,
            "Cannot edit the subject with this code: it was not found on the study plan"
        );
        studyPlan[code].teacherAddress = newProfAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import {SafeMath} from "./CommonLibrary.sol";

contract TokenUnict {
    struct codeRegistered {
        address student;
        int codeSubject;
    }

    using SafeMath for uint256; //using this library for prevent overflow attacks

    string name;
    string symbol;
    uint256 totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    codeRegistered[] codeRegisters;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 total,
        string memory tokenName,
        string memory tokenSymbol,
        address tokenOwner
    ) {
        totalSupply = total;
        balances[tokenOwner] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(
        address owner,
        address delegate
    ) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    // transfer token from the balance of the contract owner to another address
    function transfer(
        address receiver,
        uint256 numTokens,
        address tokenOwner
    ) public returns (bool) {
        require(receiver != address(0x0)); // Prevent transfer to 0x0 address. Use burn() instead
        require(numTokens <= balances[tokenOwner]); // check if has a sufficient balance to execute the transfer
        uint256 previousBalances = balances[tokenOwner] + balanceOf(receiver); // var for the next asserts
        balances[tokenOwner] = balances[tokenOwner].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(tokenOwner, receiver, numTokens);
        assert(balances[tokenOwner] + balances[receiver] == previousBalances); // this should never fail
        return true;
    }

    // allow an owner (msg.sender) to approve a delegate account to withdraw tokens from his account and to transfer them to other accounts.
    function approve(
        address delegate,
        uint256 numTokens,
        address tokenOwner
    ) public returns (bool) {
        allowed[tokenOwner][delegate] = numTokens;
        emit Approval(tokenOwner, delegate, numTokens);
        return true;
    }

    // allows a delegate approved for withdrawal to transfer owner funds to a third account.
    function transferFrom(
        address owner,
        address receiver,
        uint256 numTokens,
        address delegate,
        int codeSubject
    ) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][delegate]);
        uint256 previousBalances = balances[owner] + balanceOf(receiver); // var for the next asserts

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][delegate] = allowed[owner][delegate].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(owner, receiver, numTokens);
        assert(balances[owner] + balances[receiver] == previousBalances); // this should never fail
        codeRegisters.push(codeRegistered(receiver, codeSubject));
        return true;
    }

    // Destroy tokens
    function burn(
        uint256 _value,
        address tokenOwner
    ) public returns (bool success) {
        require(balances[tokenOwner] >= _value); // Check if the sender has enough
        balances[tokenOwner] = balances[tokenOwner].sub(_value); // Subtract from the sender
        totalSupply = totalSupply.sub(_value); // Updates totalSupply
        emit Burn(tokenOwner, _value);
        return true;
    }

    function checkSubjectAlreadyRegistered(
        address studAddr,
        int codeSub
    ) public view returns (bool) {
        for (uint256 i = 0; i < codeRegisters.length; i++) {
            if (
                codeRegisters[i].student == studAddr &&
                codeRegisters[i].codeSubject == codeSub
            ) {
                return true;
            }
        }
        return false;
    }

    function infoSubectAlreadyRegistered(
        address studAddr
    ) public view returns (int[] memory) {
        int[] memory arrCode = new int[](codeRegisters.length);
        for (uint256 i = 0; i < codeRegisters.length; i++) {
            if (codeRegisters[i].student == studAddr) {
                arrCode[i] = codeRegisters[i].codeSubject;
            }
        }
        return arrCode;
    }
}