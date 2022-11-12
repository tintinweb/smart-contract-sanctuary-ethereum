// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract ProspectiveBuyer is IUser {
    event prospectiveBuyerCreation(address indexed buyer);

    struct Buyer {
        address brokerAddress;
        string name;
    }

    struct Data {
        bool isFilled;
        Buyer owner;
    }

    mapping(address => Data) prospectiveBuyers;

    address public admin;
    address public userContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(address _userAddress)
        external
        override
    // onlyUserContract
    {
        prospectiveBuyers[_userAddress].isFilled = true;
        emit prospectiveBuyerCreation(_userAddress);
    }

    function insertData(string memory name) public {
        prospectiveBuyers[msg.sender].isFilled = true;
        prospectiveBuyers[msg.sender].owner = Buyer(msg.sender, name);
    }

    function setUserContract(address _userContract) external override {
        require(
            userContract == address(0),
            "You are prohibited to change the existing data!"
        );
        userContract = _userContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUser {
    function registerUser(address _userAddress) external;

    function setUserContract(address _userContract) external;
}