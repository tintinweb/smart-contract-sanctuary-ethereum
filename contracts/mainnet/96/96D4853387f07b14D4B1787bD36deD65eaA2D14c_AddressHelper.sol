//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AddressHelper
 * @author gotbit
 */

library AddressHelper {
    function hasCode(address[] memory accounts) external view returns(bool[] memory) {
        uint256 len = accounts.length;
        bool[] memory results = new bool[](len);
        for (uint256 i; i < len; ++i) {
            results[i] = _isContract(accounts[i]);
        }
        return results;
    }

    function hasCodeSingle(address account) external view returns(bool) {
        return _isContract(account);
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}