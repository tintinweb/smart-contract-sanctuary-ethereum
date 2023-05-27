/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract CertificateOfAttendance{
    
    event certificateEvent(bytes32 learnerId, bytes32 learnerBirthday);
    string public organizer;
    string public learnerCName;
    string public learnerEName;
    string public courseName;
    string public courseContent;
    string public courseDate;
    string public courseHours;
    string public certificateState;
    string[][2] public certificateVersion;
    uint8 version = 0;

    
    function setInformation(string memory _organizer, string memory _learnerCName, string memory _learnerEName, string memory _learnerId, string memory _learnerBirthday, 
                            string memory _courseName, string memory _courseContent, string memory _courseDate, string memory _courseHours) public {
                    
        bytes32 byte_learnerId = bytes32(bytes(_learnerId));
        bytes32 byte_learnerBirthday = bytes32(bytes(_learnerBirthday));
        emit certificateEvent(byte_learnerId,byte_learnerBirthday);
        organizer = _organizer;
        learnerCName = _learnerCName;
        learnerEName = _learnerEName;
        courseName = _courseName;
        courseContent = _courseContent;
        courseDate = _courseDate;
        courseHours = _courseHours;
    }

    
    function setState(string memory _certificateState, string memory _certificateDate) public {

        certificateState = _certificateState;
        certificateVersion[version][0] = unicode"初發";
        certificateVersion[version][1] = _certificateDate;
    }
}