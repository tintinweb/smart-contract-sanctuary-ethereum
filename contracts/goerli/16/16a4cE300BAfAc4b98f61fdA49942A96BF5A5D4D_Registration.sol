/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
// File: contracts/Managed.sol

pragma solidity ^0.8.12;

error notOwner();

contract Managed {
    /**
     * @notice CONTRACT MODIFIERS
     */
    modifier onlyAdmin(address[] memory admins) {
        bool isAdmin = false;
        for (uint256 i; i < admins.length; i++) {
            if (msg.sender == admins[i]) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin == true, "This Function Can Only Be Called by Admins");
        _;
    }

    modifier onlyOwner(address _Owner) {
        if (msg.sender != _Owner) {
            revert notOwner();
        }
        _;
    }

    modifier instructorRegistrationFeeCompliance(
        uint256 instructorRegistrationFee
    ) {
        require(
            msg.value == instructorRegistrationFee,
            "Insufficient Amount to register as an Instructor"
        );
        _;
    }

    modifier blankCompliance(
        string memory _name,
        string memory _symbol,
        string memory _duration,
        uint256 _value,
        uint8 _level
    ) {
        require(
            bytes(_name).length > 0 &&
                bytes(_duration).length > 0 &&
                bytes(_symbol).length > 0 &&
                _value > 0 &&
                _level > 0,
            "Parameters can;t be left blank"
        );
        _;
    }

    modifier registerInstructorCompliance(
        string memory _valueA,
        string memory _valueB,
        string memory _valueC,
        string memory _valueD,
        uint256 _valueE
    ) {
        require(
            bytes(_valueA).length > 0 &&
                bytes(_valueB).length > 0 &&
                bytes(_valueC).length > 0 &&
                bytes(_valueC).length > 0 &&
                bytes(_valueD).length > 0 &&
                _valueE > 0,
            "Parameters can't be left empty"
        );
        _;
    }

    modifier paymentCompliance(uint256 _amount) {
        require(msg.value == _amount, "Insufficient Funds");
        _;
    }
}

// File: contracts/Registration.sol


pragma solidity ^0.8.12;


/**
* @title Registration Contract
* @notice This Contract is to be imported hence why the states are private
// // * TODO: Write a function to remove an instructor
// // * TODO: write function to unverify an Instructor
*/
contract Registration is Managed {
    /**
     * @notice 💡 CONTRACT EVENTS
     */
    event studentRegistered(address indexed _hash);
    event instructorRegistered(
        address indexed hash,
        uint256 indexed experience
    );
    event instructorVerified(address indexed hash, string _lastName);

    /**
     * @notice 💡CONTRACT CONSTRUCTOR
     */

    constructor() {
        Owner = msg.sender;
    }

    /**
     * @notice 💡 CONTRACT STATES
     */
    address[] public admins;
    address private immutable Owner;
    uint256 public immutable instructorRegistrationFee = 0.01 ether;
    uint256 private studentCount;
    uint256 private instructorCount;
    uint256 private verifiedInstructorCount;

    /**
     * @notice 💡CONTRACT ARRAYS
     */
    Student[] public students;
    Instructor[] public instructors;
    Instructor[] public verifiedInstructors;

    /**
     * @notice 💡 MAPPINGS
     */
    mapping(address => bool) public isStudent;
    mapping(address => bool) public isInstructor;
    mapping(address => bool) public isInstructorVerified;

    /**
     * @notice 💡 CONTRACT ENUMS
     */
    enum VerificationState {
        PENDING,
        VERIFIED
    }
    /**
     * @notice 💡CONTRACT STRUCTS
     */

    struct Student {
        string firstName;
        string lastName;
        string Gender;
        string emailAddress;
        uint256 id;
        address hash;
    }

    struct Instructor {
        string Firstname;
        string Lastname;
        string Gender;
        string emailAddress;
        uint256 experience;
        address hash;
        VerificationState verificationState;
    }

    /**
     * @notice 🔐 CONTRACT MODIFIERS
     */
    modifier onlyVerifiedInstructors() {
        require(
            isInstructorVerified[msg.sender] = true,
            "Only Verified Instructors can call this function"
        );
        _;
    }

    /**
     * @notice 🔌 WRITE FUNCTIONS
     */
    function addAdmin(address[] memory _adminAddresses)
        public
        onlyOwner(Owner)
    {
        for (uint256 i; i < _adminAddresses.length; i++) {
            admins.push(_adminAddresses[i]);
        }
    }

    function enrollStudent(
        string memory _firstName,
        string memory _lastName,
        string memory _gender,
        string memory _emailAddress
    ) public {
        require(
            !isStudent[msg.sender],
            "The address is already registered as a student"
        );
        Student memory newStudent = Student({
            firstName: _firstName,
            lastName: _lastName,
            Gender: _gender,
            emailAddress: _emailAddress,
            id: studentCount++,
            hash: msg.sender
        });
        students.push(newStudent);
        studentCount = newStudent.id;

        emit studentRegistered(newStudent.hash);
    }

    function registerInstructor(
        string memory _firstName,
        string memory _lastName,
        string memory _gender,
        string memory _emailAddress,
        uint256 _experience
    )
        public
        payable
        instructorRegistrationFeeCompliance(instructorRegistrationFee)
        registerInstructorCompliance(
            _firstName,
            _lastName,
            _gender,
            _emailAddress,
            _experience
        )
    {
        require(
            !isInstructor[msg.sender],
            "The address is already registered as an instructor"
        );
        Instructor memory newInstructor = Instructor({
            Firstname: _firstName,
            Lastname: _lastName,
            Gender: _gender,
            emailAddress: _emailAddress,
            experience: _experience,
            hash: msg.sender,
            verificationState: VerificationState.PENDING
        });
        instructors.push(newInstructor);
        verifiedInstructorCount++;

        emit instructorRegistered(newInstructor.hash, newInstructor.experience);
    }

    function fireInstructor(address _instructorAddress)
        public
        onlyAdmin(admins)
    {
        for (uint256 i; i < instructors.length; i++) {
            if (instructors[i].hash == _instructorAddress) {
                instructors[i] = instructors[instructors.length - 1];
                instructors.pop();
                break;
            }
        }
    }

    function verifyInstructors(Instructor[] memory _instructors)
        public
        onlyAdmin(admins)
    {
        for (uint256 i; i < _instructors.length; i++) {
            uint256 index = getInstructorIndex(_instructors[i].hash);
            instructors[index].verificationState = VerificationState.VERIFIED;
            verifiedInstructors.push(_instructors[index]);
            emit instructorVerified(
                _instructors[index].hash,
                _instructors[index].Lastname
            );
        }
    }

    function unVerifyInstructor(Instructor[] memory _instructors)
        public
        onlyAdmin(admins)
    {
        for (uint256 i; i < _instructors.length; i++) {
            uint256 index = getInstructorIndex(_instructors[i].hash);
            verifiedInstructors[index].verificationState = VerificationState
                .PENDING;
            verifiedInstructors[index] = verifiedInstructors[
                verifiedInstructors.length - 1
            ];
            verifiedInstructors.pop();
            isInstructorVerified[verifiedInstructors[index].hash] = false;
        }
    }

    /**
     * @notice 🔌 READ FUNCTIONS
     */
    function getStudentCount() public view returns (uint256) {
        return studentCount;
    }

    function getInstructorCount() public view returns (uint256) {
        return instructorCount;
    }

    function getVerifiedInstructorCount() public view returns (uint256) {
        return verifiedInstructorCount;
    }

    function isAddressStudent(address _hash)
        public
        view
        onlyAdmin(admins)
        returns (bool)
    {
        return isStudent[_hash];
    }

    function isAddressInstructor(address _instructor)
        public
        view
        onlyAdmin(admins)
        returns (bool)
    {
        return isInstructor[_instructor];
    }

    function getInstructorIndex(address _instructor)
        internal
        view
        onlyAdmin(admins)
        returns (uint256)
    {
        for (uint256 i; i < instructors.length; i++) {
            if (_instructor == instructors[i].hash) {
                return i;
            }
        }
        revert("Not an Instructor");
    }

    /**
     * @notice 💰 WITHDRAWAL FUNCTIONS
     */
    function withdraw() public virtual onlyOwner(Owner) {
        (bool success, ) = payable(Owner).call{value: address(this).balance}(
            ""
        );
        require(success, "Sorry, This Transaction Failed");
    }

    /**
     * @notice THE RECEIVE AND FALLBACK FUNCTIONS
     */
    receive() external virtual payable {}

    fallback() external virtual payable {}
}