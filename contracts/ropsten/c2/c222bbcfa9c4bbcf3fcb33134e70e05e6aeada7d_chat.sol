/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity ^0.5.9;

contract chat {
    struct user {
        string name;
        address addr;
        bool isCreated;
           }

    struct Message {
        string content;
        address writtenBy;
        string senderName;
        uint256 timestamp;
        }

    mapping(address => Message[]) userMessages;
    mapping(address=>user)users;

   function createAccount(string memory _name) public {
       require (!users[msg.sender].isCreated);
       
       users[msg.sender].name=_name;
        users[msg.sender].addr=msg.sender;
         users[msg.sender].isCreated = true;
       
                }
    function writeMessage(address to, string memory _content) public {
        require(users[msg.sender].isCreated);
        
        Message memory message = Message(_content, msg.sender,users[msg.sender].name, now);
        userMessages[to].push(message);
            }
   function getMessage(uint _index) public view returns(string memory, string memory, address, uint) {
       return(userMessages[msg.sender][_index].senderName, userMessages[msg.sender][_index].content,userMessages[msg.sender][_index].writtenBy, userMessages[msg.sender][_index].timestamp);
          }
    function messagesLength() public view returns(uint) {
        return userMessages[msg.sender].length;
         }
    function userDetails() public view returns(string memory, address) {
        return (users[msg.sender].name, users[msg.sender].addr);
    }
}