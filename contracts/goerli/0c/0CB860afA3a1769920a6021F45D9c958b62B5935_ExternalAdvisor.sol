// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract ExternalAdvisor is IUser {
    event externalAdvisorCreation(address indexed externalAdvisor);

    struct ExternalAdvisorUser {
        address brokerAddress;
        string name;
    }

    struct Data {
        bool isFilled;
        ExternalAdvisorUser owner;
    }

    mapping(address => Data) externalAdvisors;

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
        externalAdvisors[_userAddress].isFilled = true;
        emit externalAdvisorCreation(_userAddress);
    }

    function insertData(string memory name) public {
        externalAdvisors[msg.sender].isFilled = true;
        externalAdvisors[msg.sender].owner = ExternalAdvisorUser(
            msg.sender,
            name
        );
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