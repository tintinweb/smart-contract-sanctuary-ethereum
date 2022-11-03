// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

error BuyMeACoffee__NotEnoughFunds();

contract BuyMeACoffee {
    event newMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    address payable immutable i_owner;
    Memo[] public memos;

    constructor() {
        i_owner = payable(msg.sender);
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function buyCoffee(
        string memory name,
        string memory message
    ) public payable {
        if (msg.value == 0) {
            revert BuyMeACoffee__NotEnoughFunds();
        }
        Memo memory memo = Memo(msg.sender, block.timestamp, name, message);
        memos.push(memo);
        emit newMemo(msg.sender, block.timestamp, name, message);
    }

    function withdrawTips() public {
        require(i_owner.send(address(this).balance));
    }
}