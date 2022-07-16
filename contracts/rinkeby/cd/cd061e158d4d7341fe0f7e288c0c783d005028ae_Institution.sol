/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity ^0.8.0;


//import "./certification.sol";

contract Institution {
    // State Variables
    address public owner;

    // Mappings
    mapping(address => Institute) private institutes; // Institutes Mapping
    mapping(address => string[]) private instituteCourses; // Courses Mapping

    // Events
    event instituteAdded(string _instituteName);

    constructor() public {
        owner = msg.sender;
    }

    // struct Course {
    //     string [] course_name;
    //     // Other attributes can be added
    // }

    struct Institute {
        string institute_name;
        string institute_acronym;
        string institute_link;
        string [] course_name;
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
        string[] memory _institute_courses
    ) public returns (bool) {
        // Only owner can add institute
        require(
            msg.sender == owner,
            "Caller must be the owner - only owner can add an institute"
        );
        
        institutes[_address] = Institute(
            _institute_name,
            _institute_acronym,
            _institute_link,
            _institute_courses

        );
        // for (uint256 i = 0; i < _institute_courses.length; i++) {
        //     instituteCourses[_address].push(_institute_courses[i]);
        // }
        // emit instituteAdded(_institute_name);
    }

    // Called by Institutions
    function getInstituteDataa()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
           string[] memory
        )
    {
        // Institute memory temp = institutes[msg.sender];
        // bytes memory tempEmptyStringNameTest = bytes(temp.institute_name);
        // require(
        //     tempEmptyStringNameTest.length > 0,
        //     "Institute account does not exist!"
        // );
        return (
            institutes[msg.sender].institute_name,
            institutes[msg.sender].institute_acronym,
            institutes[msg.sender].institute_link,
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
            string[] memory
        )
    {
        // require(Certification(msg.sender).owner() == owner, "Incorrect smart contract & authorizations!");
        // Institute memory temp = institutes[_address];
        // bytes memory tempEmptyStringNameTest = bytes(temp.institute_name);
        // require(
        //     tempEmptyStringNameTest.length > 0,
        //     "Institute does not exist!"
        // );
        return (
            institutes[msg.sender].institute_name,
            institutes[msg.sender].institute_acronym,
            institutes[msg.sender].institute_link,
            instituteCourses[msg.sender]
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