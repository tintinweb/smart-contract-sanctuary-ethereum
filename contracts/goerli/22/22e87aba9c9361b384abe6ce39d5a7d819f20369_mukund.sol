/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

pragma solidity ^0.8.0;

contract mukund{
    string greeting = "ur mother";
    mapping(string => address payable) internal discorders;
    address payable maker;
    event iWantToGetPayed(address by, string because);
    constructor(string memory _greeting) payable{
        greeting=_greeting;
        maker = payable( msg.sender);
    }

    function sendGreetingWithATransaction(string calldata to)public payable{
        discorders[to].call{value: msg.value}(abi.encodeWithSignature( greeting));
    }
    function relayIntentOfRecievingMoolah(address by, string memory because)external{
        emit iWantToGetPayed(by, because);
    }
    function addUser(string memory discordName, address addressToUser)external{
        discorders[discordName] = payable(addressToUser);
    }

}