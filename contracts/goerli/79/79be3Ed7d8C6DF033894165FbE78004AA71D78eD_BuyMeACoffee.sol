/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract BuyMeACoffee {

    event NewMemo(
        address indexed from,
        uint timestamp,
        string name,
        string message
    );

    struct Memo {
        address from;
        uint timestamp;
        string name;
        string message;
    }

    Memo[] memos;

    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    /**
      @dev Can buy a coffee for the owner of this contract
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value>0, "Value must be greater than 0");

        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance), "Withdrawal Failed");
    }

    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }

    fallback() external payable{}

    receive() external payable{}
}