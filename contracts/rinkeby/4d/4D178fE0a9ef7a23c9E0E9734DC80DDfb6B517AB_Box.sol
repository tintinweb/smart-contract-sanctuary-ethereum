// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Auth form the access-control subdirectory
import "./access-control/Auth.sol";

contract Box {
    uint256 private _value;
    Auth private _auth;

    // Emmited when the store value change
    event ValueChanged(uint256 value);

    constructor() {
        _auth = new Auth(msg.sender);
    }

    // Stores a new value in the contract
    function store(uint256 value) public {
        // Require that the caller is registered as an administrator in Auth
        require(_auth.isAdminitrator(msg.sender), "Unauthorized");
        _value = value;
        emit ValueChanged(value);
    }

    //  Reads the last stored value
    function retrive() public view returns (uint256) {
        return _value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auth {
    address private _administrator;

    constructor(address deployer) {
        // Make the deployer the administrator
        _administrator = deployer;
    }

    function isAdminitrator(address user) public view returns (bool) {
        return user == _administrator;
    }
}