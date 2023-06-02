/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

contract CertificateOfMerit{

    string organizer;
    string learnerCName;
    string learnerEName;
    string title;
    string content;
    string head;
    string certificateState;
    string[2][] certificateVersion;
    uint8 version = 0;


    //上傳 發證單位,中文姓名,英文姓名,標題,內容,長官
    function setInformation(string memory _organizer, string memory _learnerCName, string memory _learnerEName, 
                            string memory _title, string memory _content, string memory _head) public {

        organizer = _organizer;
        learnerCName = _learnerCName;
        learnerEName = _learnerEName;
        title = _title;
        content = _content;
        head = _head;
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
        data = string.concat(organizer,learnerCName,learnerEName,title,content,head,certificateState,versionDate);
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