/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity >= 0.8.0 < 0.9.0;

contract KingFun{
    bool alreadyKing = false;

    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable{
        require(!alreadyKing, "King!");
        alreadyKing = true;
    }
}