/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract Trans{
    function kill(address payable add) payable public {
        selfdestruct(add);
    }

}