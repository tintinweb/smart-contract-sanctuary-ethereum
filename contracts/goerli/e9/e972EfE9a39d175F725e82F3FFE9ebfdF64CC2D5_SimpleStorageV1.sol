// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract SimpleStorageV1 {
    uint256 favoriteNumber;
    bool _isActive = true;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
    address public owner;

    // the first person to deploy the contract is
    // the owner
    constructor() {
        owner = msg.sender;
    }

    function store(uint256 _favoriteNumber) public canOperate{
        favoriteNumber = _favoriteNumber;
        emit ValueChanged(favoriteNumber);
    }

    function retrieve() public view canOperate returns (uint256) {
        return favoriteNumber;
    }

    function destroySmartContract() public canOperate {
        selfdestruct(payable(owner));
        setActive(false);
    }

    function setActive(bool isActive) public canOperate {
        // restrict access to this function
        _isActive = isActive;
    }

    modifier canOperate {
        require(msg.sender == owner, "You are not the contract owner");
        require(_isActive == true, "This contract is disabled");
        _;
    }
    
}