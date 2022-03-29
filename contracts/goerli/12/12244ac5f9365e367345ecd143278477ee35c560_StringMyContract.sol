/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.8.7;

contract StringMyContract {
    string public store = "hi hi !";

    function setMyString (string memory ms) public {
        store = ms;
    }
}