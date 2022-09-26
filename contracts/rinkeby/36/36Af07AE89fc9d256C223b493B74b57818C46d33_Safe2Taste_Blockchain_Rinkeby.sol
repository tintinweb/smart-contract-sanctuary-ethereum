pragma solidity >=0.7.3;
contract Safe2Taste_Blockchain_Rinkeby {
    event UpdatedMessages(string oldStr, string newStr);
    string public message;
    constructor(string memory initMessage) {
        message = initMessage;
    }
    function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}