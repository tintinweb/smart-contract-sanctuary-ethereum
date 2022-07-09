/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract YugMultiSigAdmin {

    address _treasury;
    address[] public _adminList;
    mapping(address=> uint8) public _admins;

    constructor() {
        initialize();
    }


    function initialize() public {
        _admins[msg.sender] = 1;
        _adminList.push(msg.sender);
    }

    modifier validAdmin() {
        require(_admins[msg.sender] == 1, "You are not authorized.");
        _;
    }

    function isValidAdmin(address adminAddress) public view returns (bool) {
        return _admins[adminAddress] == 1;
    }

    function setTreasury(address treasury) public validAdmin {
        _treasury = treasury;
    }

    function getTreasury() public view returns (address) {
        return _treasury;
    }

    function getAdminList() public view validAdmin returns (address[] memory) {
        return _adminList;
    }


    function modifyAdmin(address adminAddress, bool add) validAdmin public {
        if(add) {
            _admins[adminAddress] = 1;
            _adminList.push(adminAddress);
        } else {
            require(adminAddress != msg.sender, "Cant remove self as admin");
            delete _admins[adminAddress];
            for(uint256 i = 0; i < _adminList.length; i++) {
                if(_adminList[i] == adminAddress) {
                    _adminList[i] = _adminList[_adminList.length - 1];
                    _adminList.pop();
                    break;
                }
            }
        }
    }

}