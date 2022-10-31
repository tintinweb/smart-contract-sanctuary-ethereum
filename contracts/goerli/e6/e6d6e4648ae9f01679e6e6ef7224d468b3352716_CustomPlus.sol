/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

pragma solidity >=0.7.3;

contract CustomPlus {
    event notifyzhoulinplus(string message);

    function zhoulinCustomPlus(string calldata message) public {
        emit notifyzhoulinplus(message);
    }
}