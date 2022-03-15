/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Storage{
    string public str = 'f';

    function storeStr(string calldata _data) external{
        str = _data;
    }

    function reset () external {
      delete str;
    }
}