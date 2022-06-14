// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernment.sol";

contract Government is IGovernment {
    
    modifier onlyGovernment() {
        require(msg.sender == _adminAddress, "You're not Government !!!");
        _;
    }

    address private _adminAddress;
    mapping(address => bool) private government;
    mapping(string => address) private local;

    constructor() {
        _adminAddress = msg.sender;
        government[msg.sender] = true;
        local["admin"] = msg.sender;
    }

    function addAllowance(address _address, string memory _local) public onlyGovernment {
        government[_address] = true;
        local[_local] = _address;
    }
    
    function _isAllowed(address _address) external override view returns (bool) {
        return government[_address];
    }

    function _localNameAddress(string memory localName) external override view returns (address) {
        return local[localName];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernment {
    function _isAllowed(address _address) external view returns (bool);

    function _localNameAddress(string memory localName) external view returns (address);
}