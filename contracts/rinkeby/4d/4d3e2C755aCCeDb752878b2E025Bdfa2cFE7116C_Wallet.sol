// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Account.sol";

contract Wallet {
    address public admin;

    event Create(address);

    constructor() {
        admin = msg.sender;
    }

    modifier OnlyAdmin {
        require(msg.sender == admin, "403");
        _;
    }
    function create(address payable _to, bytes32 _salt) public OnlyAdmin {
        Account a = new Account{salt: _salt}(_to);
        emit Create(address(a));
    }
}