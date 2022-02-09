/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.8.7;

contract MarksheetSolution{
    // string marksheetURL;
    struct studentData {
        
        // bytes32 bidId;
        // address payable bidder;
        string marksheetURL;
        // string studentName;
        // string studentID;
        // string class;
        // uint256 bidPrice;
        
       
    }

    mapping(uint256 => mapping(uint256 => studentData)) public studentDataByStudentID;  

    // mapping(uint256 => Bid) public urlbyStudentID;

    function uploadMarksheet (string memory  _url, uint256 _studentID, uint256 _classID) public {
        studentDataByStudentID[_classID][_studentID].marksheetURL = _url;
    }
    function getMarksheet(uint256 _studentID, uint256 _classID) public view returns( string memory)
    {
        return studentDataByStudentID[_classID][_studentID].marksheetURL;
    }
}