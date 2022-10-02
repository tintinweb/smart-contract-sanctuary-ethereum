// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./interfaces/ISmartWalletChecker.sol";

/// @author RobAnon
contract SmartWalletWhitelistV2 {
    
    mapping(address => bool) public wallets;
    
    bytes32 public constant ADMIN = "ADMIN";

    bytes32 public constant SUPER_ADMIN = "SUPER_ADMIN";

    mapping(address => bytes32) public roles;
    
    address public checker;
    address public future_checker;
    
    event ApproveWallet(address);
    event RevokeWallet(address);
    
    constructor(address _admin) {
        roles[_admin] = ADMIN;
        roles[msg.sender] = SUPER_ADMIN;
    }
    
    function commitSetChecker(address _checker) external {
        require(isSuperAdmin(msg.sender), "!sAdmin");
        future_checker = _checker;
    }

    function changeAdmin(address _admin, bool validAdmin) external {
        require(isSuperAdmin(msg.sender), "!sAdmin");
        require(!isSuperAdmin(_admin), "!auth"); // Overwrite protection
        if(validAdmin) {
            roles[_admin] = ADMIN;
        } else {
            roles[_admin] = 0x0;
        }
    }

    function transferSuperAdmin(address _newAdmin) external {
        require(isSuperAdmin(msg.sender),'!sAdmin');
        roles[msg.sender] = 0x0;
        roles[_newAdmin] = SUPER_ADMIN;
    }
    
    function applySetChecker() external {
        require(isSuperAdmin(msg.sender), "!sAdmin");
        checker = future_checker;
    }
    
    function approveWallet(address _wallet) public {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = true;
        
        emit ApproveWallet(_wallet);
    }

    function batchApproveWallets(address[] memory _wallets) public {
        require(isAdmin(msg.sender), "!admin");
        for(uint i = 0; i < _wallets.length; i++) {
            wallets[_wallets[i]] = true;
            emit ApproveWallet(_wallets[i]);
        }
    }

    function revokeWallet(address _wallet) external {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = false;
        
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return ISmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }

    function isAdmin(address checkAdd) internal view returns (bool valid) {
        valid = roles[checkAdd] == ADMIN || roles[checkAdd] == SUPER_ADMIN;
    }

    function isSuperAdmin(address checkAdd) internal view returns (bool valid) {
        valid = roles[checkAdd] == SUPER_ADMIN;
    }
   
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface ISmartWalletChecker {
    function check(address) external view returns (bool);
}