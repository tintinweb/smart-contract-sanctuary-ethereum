/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity ^0.8.0;


contract Certification {
    // State Variables
    address public owner;
    Institution public institution;

    // Mappings
    mapping(bytes32 => Certificate) private certificates;

    // Events
    event certificateGenerated(bytes32 _certificateId);
    event certificateRevoked(bytes32 _certificateId);

    constructor(Institution _institution) public {
        owner = msg.sender;
        institution = _institution;
    }

    struct Certificate {
        // Individual Info
        string candidate_name;
        string course_name;
        string creation_date;

        // Institute Info
        string institute_name;
        string institute_acronym;
        string institute_link;

        // Revocation status
        bool revoked;
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }

    function generateCertificate(
        string memory _id,
        string memory _candidate_name,
        uint256 _course_index, 
        string memory _creation_date) public {
        require(institution.checkInstitutePermission(msg.sender) == true, "Institute account does not exist");
        bytes32 byte_id = stringToBytes32(_id);
        // require(certificates[byte_id].creation_date == 0, "Certificate with given id already exists");
        bytes memory tempEmptyStringNameTest = bytes(
            certificates[byte_id].creation_date
        );
        require(
            tempEmptyStringNameTest.length == 0,
            "Certificate with given id already exists"
        );
        (string memory _institute_name, string memory _institute_acronym, string memory _institute_link, Institution.Course[] memory _institute_courses) = institution.getInstituteData(msg.sender);
        require(_course_index >= 0 && _course_index < _institute_courses.length, "Invalid Course index");
        string memory _course_name = _institute_courses[_course_index].course_name;
        bool revocation_status = false;
        certificates[byte_id] = Certificate(_candidate_name, _course_name, _creation_date, _institute_name, _institute_acronym, _institute_link, revocation_status);
        emit certificateGenerated(byte_id);
    }

    function getData(string memory _id) public view returns(string memory, string memory, string memory, string memory, string memory, string memory, bool) {
        bytes32 byte_id = stringToBytes32(_id);
        Certificate memory temp = certificates[byte_id];
        // require(certificates[byte_id].creation_date != 0, "Certificate id does not exist!");
        bytes memory tempEmptyStringNameTest = bytes(
            certificates[byte_id].creation_date
        );
        require(
            tempEmptyStringNameTest.length != 0,
            "Certificate id does not exist"
        );
        return (temp.candidate_name, temp.course_name, temp.creation_date, temp.institute_name, temp.institute_acronym, temp.institute_link, temp.revoked);
    }

    function revokeCertificate(string memory _id) public {
        require(institution.checkInstitutePermission(msg.sender) == true, "Institute account does not exist");
        bytes32 byte_id = stringToBytes32(_id);
        bytes memory tempEmptyStringNameTest = bytes(
            certificates[byte_id].creation_date
        );
        require(
            tempEmptyStringNameTest.length != 0,
            "Certificate id does not exist"
        );
        certificates[byte_id].revoked = true;
        emit certificateRevoked(byte_id);
    }
}

pragma solidity ^0.8.0;


contract Institution {
    // State Variables
    address public owner;

    // Mappings
    mapping(address => Institute) private institutes; // Institutes Mapping
    mapping(address => Course[]) private instituteCourses; // Courses Mapping

    // Events
    event instituteAdded(string _instituteName);

    constructor() public {
        owner = msg.sender;
    }

    struct Course {
        string course_name;
        // Other attributes can be added
    }

    struct Institute {
        string institute_name;
        string institute_acronym;
        string institute_link;
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function addInstitute(
        address _address,
        string memory _institute_name,
        string memory _institute_acronym,
        string memory _institute_link,
        Course[] memory _institute_courses
    ) public returns (bool) {
        // Only owner can add institute
        require(
            msg.sender == owner,
            "Caller must be the owner - only owner can add an institute"
        );
        bytes memory tempEmptyStringNameTest = bytes(
            institutes[_address].institute_name
        );
        require(
            tempEmptyStringNameTest.length == 0,
            "Institute with token already exists"
        );
        require(
            _institute_courses.length > 0,
            "Atleast one course must be added"
        );
        institutes[_address] = Institute(
            _institute_name,
            _institute_acronym,
            _institute_link
        );
        for (uint256 i = 0; i < _institute_courses.length; i++) {
            instituteCourses[_address].push(_institute_courses[i]);
        }
        emit instituteAdded(_institute_name);
    }

    // Called by Institutions
    function getInstituteDataa()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            Course[] memory
        )
    {
        Institute memory temp = institutes[msg.sender];
        bytes memory tempEmptyStringNameTest = bytes(temp.institute_name);
        // require(
        //     tempEmptyStringNameTest.length > 0,
        //     "Institute account does not exist!"
        // );
        return (
            temp.institute_name,
            temp.institute_acronym,
            temp.institute_link,
            instituteCourses[msg.sender]
        );
    }

    // Called by Smart Contracts
    function getInstituteData(address _address)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            Course[] memory
        )
    {
        require(Certification(msg.sender).owner() == owner, "Incorrect smart contract & authorizations!");
        Institute memory temp = institutes[_address];
        bytes memory tempEmptyStringNameTest = bytes(temp.institute_name);
        require(
            tempEmptyStringNameTest.length > 0,
            "Institute does not exist!"
        );
        return (
            temp.institute_name,
            temp.institute_acronym,
            temp.institute_link,
            instituteCourses[_address]
        );
    }

    function checkInstitutePermission(address _address)
        public
        view
        returns (bool)
    {
        Institute memory temp = institutes[_address];
        bytes memory tempEmptyStringNameTest = bytes(temp.institute_name);
        if (tempEmptyStringNameTest.length > 0) {
            return true;
        } else {
            return false;
        }
    }
}