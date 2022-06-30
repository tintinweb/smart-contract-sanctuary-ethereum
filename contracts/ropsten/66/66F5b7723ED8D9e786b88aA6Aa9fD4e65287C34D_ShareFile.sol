/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract ShareFile {
    struct File {
        address owner;
        address[]  sharedUsers;
    }

    modifier onlyFileOwner(string calldata fileId) {
        require(msg.sender == files[fileId].owner);
        _;
    }


    address[] users;
    string[] fileIds;
    mapping(string => bool) isFileExist;
    mapping(string => File) files;

    function uploadFile(string memory fileId) public {
        if(!isFileExist[fileId]){
        fileIds.push(fileId);
        files[fileId] = File(msg.sender, new address[](0));
        isFileExist[fileId]= true;
        }
    }

    function shareFile(string calldata fileId, address otherUser) public {
        if( !checkPer(fileId, otherUser))
        {
        files[fileId].sharedUsers.push(otherUser);
        }
    }


    function checkPer( string calldata fileId, address user) public view returns(bool) {
        if (files[fileId].owner == user) return true;

        for (uint i = 0; i < files[fileId].sharedUsers.length; i++) {
        if (files[fileId].sharedUsers[i] == user) {
            return true;
            }
        }
        return false;
    }
    
    function getSharedUsers(string calldata fileId) public view returns (address[] memory){
    return files[fileId].sharedUsers;
    }
    
    function getIndex(address[] memory  arr, address user ) public pure returns(uint){
    for (uint i = 0; i < arr.length; i++) {
        if (arr[i] == user) {
            return i+1;
            }
    }
    return 0;    
    }


    // function removePer(string memory fileId, address otherUser) public onlyFileOwner(fileId) returns (bool){
    function removePer(string calldata fileId, address otherUser) public returns (bool success){
    if (otherUser == files[fileId].owner) return false;

    uint index=0;
    while (index <= files[fileId].sharedUsers.length ) { 
     if(otherUser == files[fileId].sharedUsers[index]) {
        break;
        }
     index++;
    }
    for (uint i = index; i<files[fileId].sharedUsers.length - 1; i++){
            files[fileId].sharedUsers[i] = files[fileId].sharedUsers[i+1];
        }
    files[fileId].sharedUsers.pop();

    return true;
    }

    function getAllFiles() public view returns(string[] memory){
        return fileIds;
    }

    function getAllFilesOfOwner(address user) public view returns(string[] memory){
        string[] memory  filesOfUser = new string[](fileIds.length);
        uint256 j;
        for (uint i = 0; i< fileIds.length ; i++){
            if ( files[fileIds[i]].owner == user){
                filesOfUser[j] = fileIds[i];
                j++;
            }
        }
        return filesOfUser;
    }
    
    function getOwnerOfFile(string memory fileId) public view returns(address){
        return files[fileId].owner;
    }

    function getFilesSharedMe(address user) public view returns(string[] memory ){
        string[] memory  filesOfUser = new string[](fileIds.length);
        uint256 j;
        for (uint i = 0; i< fileIds.length ; i++){
            if ( getIndex(files[fileIds[i]].sharedUsers, user) != 0){
                filesOfUser[j] = fileIds[i];
                j++;
            }
        }
        return filesOfUser;
    }

}