/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Interface for checking whether address belongs to a whitelisted type of a smart wallet.
 * When new types are added - the whole contract is changed
 * The check() method is modifying to be able to use caching
 * for individual wallet addresses
*/
interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {
    address public admin;
    address public checker;

    mapping(address => bool) public wallets;
    
    event ApproveWallet(address);
    event RevokeWallet(address);

    event CheckerChanged(address oldChecker, address newChecker);
    
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function setChecker(address _checker) external onlyAdmin {
        address currentChecker = checker;
        require(_checker == address(0), "Can't set zero address");
        emit CheckerChanged(currentChecker, checker);
        checker = _checker;
    }
    
    function approveWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Can't approve zero address");
        wallets[_wallet] = true;
        emit ApproveWallet(_wallet);
    }

    function revokeWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Can't revoke zero address");
        wallets[_wallet] = false;
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        if (wallets[_wallet]) {
            return true;
        } else if (checker != address(0)) {
            return SmartWalletChecker(checker).check(_wallet);
        }
        return false;
    }
}