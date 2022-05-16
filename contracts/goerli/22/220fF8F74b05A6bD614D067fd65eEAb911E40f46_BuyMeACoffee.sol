//SPDX-License-Identifier: MIT
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

    Memo[] private memos;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev Returns all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev Sends ETH to this contract and creates a memo
     * @param _name name of the tipper
     * @param _message the tipper's message
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "must include ETH");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev Sends the contract's balance to the owner
     */
    function withdrawTips() public {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner can't be zero address");
        owner = payable(newOwner);
    }
}