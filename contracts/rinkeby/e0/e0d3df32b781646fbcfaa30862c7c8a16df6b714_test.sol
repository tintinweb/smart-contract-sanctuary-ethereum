/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity 0.8.7;

contract test {
    event EventTest(uint256 id);
    event Mint(address sender, uint256 count);
    event Reroll(address sender, uint256 id);
    uint256 constant public m = 0.000001 ether;

    constructor()
    {
    }
    function id(uint256 id) public
    {
        emit EventTest(id);
    }

    function mint(uint256 count) public payable 
    {
        require(count * m == msg.value, "Invalid funds");
        emit Mint(msg.sender, count);
    }

    function reroll(uint256 id) public payable
    {
        require(1 * m == msg.value, "Invalid funds");
        emit Reroll(msg.sender, id);
    }
}