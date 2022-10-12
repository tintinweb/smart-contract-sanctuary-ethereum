/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

//SPDX LISCENSE Identifier : UNLICENSED //

pragma solidity >= 0.8.17;
contract testworld{
event Updatemessages(string oldstr, string newstr);

string public message;

constructor(string memory initMessage)
{
    message = initMessage;

}
function update(string memory newMessage) public
{
    string memory oldmsg = message;
    message = newMessage;
    emit Updatemessages(oldmsg, newMessage);

} 

}