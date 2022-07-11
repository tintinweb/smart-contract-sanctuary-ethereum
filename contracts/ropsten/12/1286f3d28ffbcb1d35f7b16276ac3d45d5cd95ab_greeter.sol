/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/**
 *Submitted for verification at Etherscan.io on 2019-08-12
*/

pragma solidity >=0.5.7;
contract greeter{
    string greeting;
    event EmittedEvent(string);
    function greet(string memory _greeting)public {
        greeting=_greeting;
        emit EmittedEvent(_greeting);
    }
    function getGreeting() public view returns(string memory) {
        return greeting;
    }
}