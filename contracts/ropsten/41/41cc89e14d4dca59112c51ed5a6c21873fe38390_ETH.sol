/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

pragma solidity ^ 0.8.12;

contract ETH
{
    address public  buyer;
    uint public amt;
    address public seller;
    bool public state;
    constructor() 
    {
        seller = msg.sender;
    }
    function setPause(bool _state) public
    {
        require(msg.sender == seller,"Administrator permission required...");
        state = _state;
    }
    function add(address payable _buyer) payable public
    {
        require(!state,"The contract is in paused state!!! :(");
        buyer = _buyer;
        payable(buyer).transfer(msg.value);
    }
    function bal() view public returns(uint)
    {
        require(!state,"The contract is in paused state!!! :(");
        return buyer.balance;
    }
    function s() payable public returns(uint)
    {
        require(!state,"The contract is in paused state!!! :(");
        return msg.value;
    }
}