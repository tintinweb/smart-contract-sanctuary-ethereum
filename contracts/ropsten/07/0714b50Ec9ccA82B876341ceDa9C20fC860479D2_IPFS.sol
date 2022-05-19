pragma solidity >=0.7.3;
contract IPFS {

    event UpdatedMessages(string oldHash, string newHash);
    string public message;

    constructor(string memory hash) {

      // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
      message = hash;
   }
   
    
    /*function sendHash(string memory x) public {
        message = x;
    }*/
    
    /*function getHash() public view returns (string memory) {
        return message;
    }*/
    function update(string memory updateHash) public {
      string memory oldMsg = message;
      message = updateHash;
      emit UpdatedMessages(oldMsg, updateHash);
   }
}