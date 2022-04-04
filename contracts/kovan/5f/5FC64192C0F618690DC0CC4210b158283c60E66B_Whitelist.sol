// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {

    address public admin;
    constructor () {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    mapping (address => bool) public validator;
    event AddValidator(address indexed newValidator);
    event RemoveValidator(address indexed oldValidator);

    function addValidator(address newValidator) public onlyAdmin {
        require (newValidator != address(0), "NOT_ADDRESS");
        require (msg.sender == admin, "NOT_ADMIN");
        validator[newValidator] = true;
        emit AddValidator(newValidator);
    }

    function removeValidator(address oldValidator) public onlyAdmin {
        require (msg.sender == admin, "NOT_ADMIN");
        require (validator[oldValidator] == true, "NOT EXIST");
        validator[oldValidator] = false;
        emit RemoveValidator(oldValidator);
    }

    function checkValidator(address _validator) virtual public returns (bool) {
        return validator[_validator]== true;
    }

    function transferOwner(address _admin) public onlyAdmin {
        admin = _admin;
    }
}