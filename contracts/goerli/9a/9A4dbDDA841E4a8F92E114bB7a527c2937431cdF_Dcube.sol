// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Owner{

    event OwnershipTransferred(address _previousOwner,address _newOwner);

    address _owner;

    constructor(){
        _owner = msg.sender;
        emit OwnershipTransferred(address(0),_owner);
    }

    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner returns(bool){
        _owner = _newOwner;
        emit OwnershipTransferred(_owner,_newOwner);
        return true;

    }

    function renounceOwnership() public onlyOwner returns(bool){
          transferOwnership(address(0));
          return true;
    }

}

contract Dcube{

    event CidGenerate(address indexed User,string indexed CID,uint TimeStamp,string FileName);


    struct uploadedFile{
        string CID;
        uint timeStamp;
        string fileName;
    }

    struct importedFile{
        string CID;
        uint timeStamp;
        string fileName;
    }


    struct user{
       uploadedFile[] UploadedFiles;
       importedFile[] ImportedFiles;
    }

    mapping (address => user) users;
    
    function uploadfile(string calldata _cid,string memory _fileName) public returns(bool){
        users[msg.sender].UploadedFiles.push(uploadedFile(_cid,block.timestamp,_fileName));
        emit CidGenerate(msg.sender,_cid,block.timestamp,_fileName);
        return true;
    }


    function importfile(string calldata _cid,string memory _fileName) public returns(bool){
        users[msg.sender].ImportedFiles.push(importedFile(_cid,block.timestamp,_fileName));
         emit CidGenerate(msg.sender,_cid,block.timestamp,_fileName);
        return true;
    }

    function getUploadFile() external view returns(uploadedFile[] memory){
        return users[msg.sender].UploadedFiles;
    }

    function getImportFile() external view returns(importedFile[] memory){
        return users[msg.sender].ImportedFiles;
    }



}