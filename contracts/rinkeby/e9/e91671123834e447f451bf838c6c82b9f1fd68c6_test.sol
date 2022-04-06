/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity 0.8.7;

contract test {
    event EventTest(uint256 id);
    constructor()
    {
    }
    function id(uint256 id) public
    {
        emit EventTest(id);
    }
}