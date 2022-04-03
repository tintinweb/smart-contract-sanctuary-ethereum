/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

pragma solidity >=0.7.0 <0.9.0;

contract Bridge {
    event Receivee(address indexed from, uint tokens);

    receive() external payable {
        emit Receivee(msg.sender, msg.value);
    }
}