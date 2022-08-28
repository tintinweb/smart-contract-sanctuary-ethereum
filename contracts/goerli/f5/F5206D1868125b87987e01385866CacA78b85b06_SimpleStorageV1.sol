// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract SimpleStorageV1 {
    uint256 favoriteNumber;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
    address public owner;

    // the first person to deploy the contract is
    // the owner
    constructor() {
        owner = msg.sender;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        emit ValueChanged(favoriteNumber);
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function destroySmartContract(address payable to) public {
        selfdestruct(to);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the contract owner");
        _;
    }
    
}