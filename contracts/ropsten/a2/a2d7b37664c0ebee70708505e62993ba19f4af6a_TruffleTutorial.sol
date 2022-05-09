/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity >=0.4.4 <0.9.0;

contract TruffleTutorial {
    address public owner = msg.sender;
    string public message;

    constructor(){
        message = "Hello ETH";
    }


    modifier ownerOnly() {
        require(msg.sender == owner, "");
        _;
    }

    function setMessage(string memory _message) public ownerOnly returns (string memory) {
        require(bytes(_message).length > 0);
        message = _message;
        return message;
    }
}