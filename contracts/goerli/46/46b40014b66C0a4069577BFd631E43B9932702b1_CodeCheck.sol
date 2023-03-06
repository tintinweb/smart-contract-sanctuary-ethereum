/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;


contract CodeCheck {
    address public owner; 


    struct Table {
        string tableName;
        string[] encryptedData;
    }





    mapping (address => bool) public clientAddressess;

    mapping(string => mapping(string=> mapping(string => Table)))   public tables; 

    address[] public arrayOfClientAddresses;


     constructor () {
        owner = msg.sender;
    }


    function storeEncryptedData(string memory _appName, string memory _tableName , string memory _typeOfScript , string memory _releaseVersion , string[] memory _encryptedData) public {
        require(msg.sender == owner, 'Unauthorized to store data');
        tables[_appName][_typeOfScript][_releaseVersion] = Table ({
            tableName: _tableName,
            encryptedData : _encryptedData
        }); 
    } 

    function getEncryptedData (string memory _appName , string memory _typeOfScript, string memory _releaseVersion)public view returns (  string memory ,  string[] memory){
       require(msg.sender == owner || clientAddressess[msg.sender]==true );
       return (tables[_appName][_typeOfScript][_releaseVersion].tableName,  tables[_appName][_typeOfScript][_releaseVersion].encryptedData ) ;
    }

    function addClients(address _clientAddress) public {
        require(msg.sender == owner);
        clientAddressess[_clientAddress] = true;
        arrayOfClientAddresses.push(_clientAddress);
    }

    function getClientAddress()public view returns (address[] memory) {
        return arrayOfClientAddresses;
    }


}