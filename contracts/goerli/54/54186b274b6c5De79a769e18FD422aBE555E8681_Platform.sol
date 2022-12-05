// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlatform {
    event TransferReciver(address from, address to);
    event TransferOwner(address from, address to);
    event ChangedManageFee(uint older, uint renew);
    event ClaimManagerFee(address indexed caller, uint amount);

    function receiver() external view returns (address);

    function manageFee() external view returns (uint);

    function setOwner(address manager_) external;

    function setReceiver(address manager_) external;

    function changeManageFee(uint manageFee_) external;

    function withdrew(address mananger_, uint amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlatform.sol";

contract Platform is IPlatform {
    address public receiver; // receive native token
    address public owner;
    uint public manageFee; // 10**18 = 100%

    constructor() {
        owner = msg.sender;
        receiver = address(this);
        manageFee = 0; // 3%
    }

    function setOwner(address owner_) external override onlyOwner {
        emit TransferOwner(receiver, owner_);
        owner = owner_;
    }

    function setReceiver(address receiver_) external override onlyOwner {
        emit TransferReciver(receiver, receiver_);
        receiver = receiver_;
    }

    function changeManageFee(uint manageFee_) external override onlyOwner {
        emit ChangedManageFee(manageFee, manageFee_);
        manageFee = manageFee_;
    }

    // if this contract is reciver
    function withdrew(address mananger_, uint amount_) external override onlyOwner {
        require(address(this).balance >= amount_, "ERR_NOT_ENOUGH");
        (bool isSuccess, ) = mananger_.call{value: amount_}("");
        require(isSuccess, "ERR_SYSTEM_ERROR");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR_NOT_OWNER");
        _;
    }

    // if this contract is receiver
    receive() external payable {}
}