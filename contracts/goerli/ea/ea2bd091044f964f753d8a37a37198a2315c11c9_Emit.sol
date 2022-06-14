/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity 0.8.13;



contract Emit {
    event Say(address indexed);
    function say(address who) external {
        emit Say(who);
    }
    event Count(uint256 count);
    function count(uint256 from) external {
        unchecked {
            while (from --> 0) {
                emit Count(from);
            }
        }
    }
}