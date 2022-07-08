// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.11;

/**
    @title Handles access control per contract function.
    @author ChainSafe Systems.
    @notice This contract is intended to be used by the Bridge contract.
 */
contract AccessControlSegregator {
    // function signature => address has access
    mapping(bytes4 => address) public functionAccess;

    bytes4 public constant GRANT_ACCESS_SIG = AccessControlSegregator(address(0)).grantAccess.selector;

    /**
        @notice Initializes access control to functions and sets initial
        access to grantAccess function.
        @param functions List of functions to be granted access to.
        @param accounts List of accounts.
    */
    constructor(bytes4[] memory functions, address[] memory accounts) public {
        require(accounts.length == functions.length, "array length should be equal");

        _grantAccess(GRANT_ACCESS_SIG, msg.sender);
        for (uint i=0; i < accounts.length; i++) {
            _grantAccess(functions[i], accounts[i]);
        }
    }

    /**
        @notice Returns boolean value if account has access to function.
        @param sig Function identifier.
        @param account Address of account.
        @return Boolean value depending if account has access.
    */
    function hasAccess(bytes4 sig, address account) public view returns (bool)  {
        return functionAccess[sig] == account;
    }

    /**
        @notice Grants access to an account for a function.
        @notice Set account to zero address to revoke access.
        @param sig Function identifier.
        @param account Address of account.
    */
    function grantAccess(bytes4 sig, address account) public {
        require(hasAccess(GRANT_ACCESS_SIG, msg.sender), "sender doesn't have grant access rights");

        _grantAccess(sig, account);
    }

    function _grantAccess(bytes4 sig, address account) private {
        functionAccess[sig] = account;
    }
}