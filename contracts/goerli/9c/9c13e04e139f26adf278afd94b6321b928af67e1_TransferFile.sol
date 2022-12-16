/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferFile {
    //Structure
    mapping (address=>string) public DocumentStored;
    //Events
    event NewFile(address _address, string _HashFile );
    //Modifiers
 
    
    // An empty constructor that creates an instance of the conteact
    //constructor() public{}  //Comentado por Ramses Mar20Sep2022
    constructor() {}

    //---------------Save hash in Adress
    function sendHash(string memory _HashFile)  public{
        DocumentStored[msg.sender] = _HashFile;
        emit NewFile(msg.sender, _HashFile);
    }
    /*
    function sendHash(address  _address, string memory _HashFile)  public{
        DocumentStored[_address] = _HashFile;
        emit NewFile(_address, _HashFile);
    }
    */
    //---------------retrieves hash
    function getHash(address _address) public view returns(string memory) {
        string memory _hashFile=DocumentStored[_address];         
        return _hashFile;
    }
}

//address: 0xc06928FA0300CB3782cd08372345a0aA80276506 -> Hash: 1c4628ce8e48f76606ddf0530561f16d985280a4c625ff21e596cbd6eacfe043
//address: 0x7022b235b168219eabdc50c03fec6c8b35cedaad -> Hash: f01677169e5d69fed67faf74e7c81718a2d63c119d5fc8fe828b5bae27c1dc82