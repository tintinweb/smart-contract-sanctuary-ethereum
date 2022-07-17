// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    event NewMemo(
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

    address payable owner;

    Memo[] memos;

    constructor() {
        owner = payable(msg.sender);
    }

    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0);

        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert();
        }
    }

    function getMemo() public view returns (Memo[] memory) {
        return memos;
    }
}