/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract CertificateOfAttendance{
    
    event certificateEvent(bytes32 learnerId, bytes32 learnerBirthday);
    string organizer;
    string learnerCName;
    string learnerEName;
    string courseName;
    string courseContent;
    string courseDate;
    string courseHours;
    string certificateState;
    string[2][] certificateVersion;
    uint8 version = 0;

    
    //上傳 發證單位,中文姓名,英文姓名,身分證字號,出生年月日,課程名稱,課程內容,上課日期,上課時數
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

    
    //上傳 證照狀態,發照日期
    function setState(string memory _certificateDate) public {

        certificateState = unicode"有效";
        certificateVersion.push([unicode"初發",_certificateDate]);
    }


    //取回資料
    function getData() public view returns (string memory){
        string memory data;
        string memory versionDate;
        for(uint i = 0; i <= version; i++){
            versionDate = string.concat(versionDate,certificateVersion[i][0],certificateVersion[i][1]);
        }
        data = string.concat(organizer,learnerCName,learnerEName,courseName,courseContent,courseDate,courseHours,certificateState,versionDate);
        return data;
    }


    //撤銷
    function revoke() public {

        certificateState = unicode"無效";
    }


    //補發
    function reissue(string memory _certificateDate) public {

        version = version+1;
        certificateVersion.push([unicode"補發",_certificateDate]);
    }
}