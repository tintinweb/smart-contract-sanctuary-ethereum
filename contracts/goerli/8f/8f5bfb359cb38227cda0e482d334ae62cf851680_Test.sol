/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    function req() public pure {
        require(false, "111");
    }

    function ass() public pure {
        assert(false);
    }

    function rev() public pure {
            revert("222");
    }

}