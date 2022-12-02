// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {

    mapping(address => bool) public wallets;
    address public dao;
    address public future_dao;
    address public checker;
    address public future_checker;

    event ApproveWallet(address);
    event RevokeWallet(address);
    event ChangeDao(address);

    constructor(address _dao) public {
        dao = _dao;
    }

    function commitSetChecker(address _checker) external {
        require(msg.sender == dao, "!dao");
        future_checker = _checker;
    }

    function applySetChecker() external {
        require(msg.sender == dao, "!dao");
        checker = future_checker;
    }

    function approveWallet(address _wallet) public {
        require(msg.sender == dao, "!dao");
        wallets[_wallet] = true;

        emit ApproveWallet(_wallet);
    }
    function revokeWallet(address _wallet) external {
        require(msg.sender == dao, "!dao");
        wallets[_wallet] = false;

        emit RevokeWallet(_wallet);
    }

    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return SmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }

    function commitSetDao(address _dao) public {
        require(msg.sender == dao, "!dao");
        require(_dao != address(0), "Ownable: new dao is the zero address");
        future_dao = _dao;
    }

    function applySetDao() public {
        require(msg.sender == dao, "!dao");
        dao = future_dao;
        emit ChangeDao(future_dao);
    }
}