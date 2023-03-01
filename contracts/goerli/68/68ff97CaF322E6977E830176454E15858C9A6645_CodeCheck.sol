/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;


contract CodeCheck {
    address public owner; 
    address[] public clients;


    struct Table {
        string tableName;
        string typeOfScript;
        string releaseVersion;
        string[] encryptedData;
    }



    mapping (address => bool) clientAddressess;

    mapping(string => Table) tables;   

     constructor () {
        owner = msg.sender;
    }


    function storeEncryptedData(string memory _appName, string memory _tableName , string memory _typeOfScript , string memory _releaseVersion , string[] memory _encryptedData) public {
        require(msg.sender == owner, 'Unauthorized to store data');
        tables[_appName] = Table ({
            tableName: _tableName,
            typeOfScript : _typeOfScript,
            releaseVersion : _releaseVersion,
            encryptedData : _encryptedData
        });      
    } 

    function getEncryptedData (string memory _appName)public view returns (  string memory ,  string memory ,  string memory,  string[] memory){
       require(msg.sender == owner || clientAddressess[msg.sender]==true );
       return (tables[_appName].tableName, tables[_appName].typeOfScript, tables[_appName].releaseVersion, tables[_appName].encryptedData ) ;
    }

    function addClients(address _clientAddress) public {
        require(msg.sender == owner);
        clientAddressess[_clientAddress] = true;
    }


}