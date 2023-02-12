/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AdministratorContract {

    struct Administrator {
        uint256 idAdministrator;
        address administratorAddress;
        uint256 taxId;
        string name;
        State stateOf;
    }

    enum State { Inactive, Active }
    mapping (uint256 => Administrator) private administrators;
    address[] private addsAdministrators;

    constructor(uint256 _taxId, string memory _name) {
        addsAdministrators.push(msg.sender);
        administrators[0] = 
                Administrator(0, msg.sender, _taxId, _name, State.Active);
    }

    // HANDLING ADMINISTRATOR //

    function addAdministrator(address _address, string memory _name, uint256 _taxId) public{
        require(checkIfAdministratorExists(msg.sender), "Sender is not administrator.");
        require(!checkIfAdministratorExists(_address), "Administrator already exists.");

        administrators[addsAdministrators.length] = 
                Administrator(addsAdministrators.length, msg.sender, _taxId, _name, State.Active);
        addsAdministrators.push(_address);
    }

    function getAdministrator(uint256 _id) public view returns(Administrator memory) {
        return administrators[_id];
    }

    function updateAdministrator (address _address, uint256 _taxId, string memory _name, State _state) public {
        require(checkIfAdministratorExists(msg.sender), "Sender is not administrator.");
        require(_address != address(0), "Address not given.");
        require(_taxId != 0, "TaxId not given.");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Name not given.");
        require(checkIfAdministratorExists(_address), "Administrator not exists.");

        bool difAdd;
        address add;
        uint256 _id;

        for (uint256 i = 0; i < addsAdministrators.length; i++) {
            if (addsAdministrators[i] ==  _address) {
                _id = i;
                break;
            }
        }

        if (administrators[_id].administratorAddress != _address) {
            difAdd = true;
            add = administrators[_id].administratorAddress;
        }

        administrators[_id] = Administrator(_id, _address, _taxId, _name, _state);

        if (difAdd) {
            for (uint256 i = 0; i < addsAdministrators.length; i++) {
                if (addsAdministrators[i] == add) {
                    addsAdministrators[i] = _address;
                    break;
                }
            }
        }
    }

    function getAllAdministrators() public view returns (Administrator[] memory) {
        Administrator[] memory result = new Administrator[](addsAdministrators.length);
        for (uint i = 0; i < addsAdministrators.length; i++) {
            result[i] = administrators[i];
        }
        return result;
    }

    function checkIfAdministratorExists(address _address) public view returns (bool){
        for (uint i = 0; i < addsAdministrators.length; i++)
            if(addsAdministrators[i] == _address)
                return true;

        return false;
    }

    // END HANDLING ADMINISTRATOR //    
}