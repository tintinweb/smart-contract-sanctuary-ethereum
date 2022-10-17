/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotOwner();

contract BuyMeACoffee {
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Event to emit when a memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // list of memos received
    Memo[] memos;

    // address of contract deployer
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev buy a coffee for the contract owner
     * @param _name name of the coffee buyer
     * @param _message a memo from coffee buyer to the owner
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "can't buy coffee with 0 eth");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev Send the entire balance of the contract to the contract owner
     */
    function withdrawTips() public onlyOwner {
        // require(owner.send(address(this).balance), "failed to transfer");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev retireve all the memo received and stored on the blockchain
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function fund() public payable {
        require(msg.value > 0, "can't buy coffee with 0 eth");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}