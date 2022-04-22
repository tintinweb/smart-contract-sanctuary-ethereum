/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

pragma solidity ^0.8.0;

contract Test {
    event TestA(string indexed str);

    function test() public {
        emit TestA("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
    }
}