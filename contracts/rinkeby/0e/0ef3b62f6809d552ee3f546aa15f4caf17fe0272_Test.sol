/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Test {
    bool public TRUE = true;
    bool public FALSE = false;

    function alwaysTruePure() public pure returns (bool){
        return true;
    }

    function alwaysFalsePure() public pure returns (bool){
        return false;
    }

    function alwaysTrueView() public view returns (bool){
        return TRUE;
    }

    function alwaysFalseView() public view returns (bool){
        return FALSE;
    }


}