// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;

contract HelloWorld {

    address private owner = msg.sender; // add an address for "owner" // owner should equal contract deployer
    
    string private message = "Tell Chow I said, Hallo";

    event NewMessage(string message); // add an event for change of message

    error Unauthorised(); // add a custom error for != owner

    // add a modifier for onlyOwner()
    modifier onlyOwner() {
        if(msg.sender != owner)
        revert Unauthorised(); // requires custom error for != owner
        _;
    }
    
    function hellowWorld()
    external
    view
    returns (string memory) {
        return message;
    }
    
    // add a changer that's external for message
   function setMessage(string memory _str) external {
       message = _str;
       emit NewMessage(message); // emit event
    }

    // add a changer that's external and onlyOwner() protected
    function set(string memory _str) external onlyOwner {
       message = _str;
       emit NewMessage(message); // emit event
    }
}