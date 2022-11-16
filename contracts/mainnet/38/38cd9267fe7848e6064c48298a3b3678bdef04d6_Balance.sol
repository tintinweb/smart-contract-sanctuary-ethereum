/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Balance {
    struct Result {
        address _address;
        uint256 balance;
    }

    function balance_info(address _address)
        external
        view
        returns (uint256 _balance)
    {
        _balance = _address.balance;
    }

    function balance_info_list(address[] memory _address_list)
        external
        view
        returns (Result[] memory balance_arr)
    {
        balance_arr = new Result[](_address_list.length);

        for (uint256 i = 0; i < _address_list.length; i++) {
            address _address = _address_list[i];
            balance_arr[i] = Result(_address, _address.balance);
        }
    }
}