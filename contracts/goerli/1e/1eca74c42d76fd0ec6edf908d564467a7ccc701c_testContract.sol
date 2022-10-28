/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

pragma solidity ^0.8.7;

contract testContract {
    function rejFunc() public {
        revert();
    }

    function reqNX() public {
        require(false);
    }
}