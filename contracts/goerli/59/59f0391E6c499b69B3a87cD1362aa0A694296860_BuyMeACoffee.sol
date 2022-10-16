/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    
    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    
    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;

    // Address where to withdraw the tips to
    address payable withdrawalAddress;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    //Deployer is the owner of the contract and the initial address to withdraw to
    constructor() {
        owner = payable(msg.sender);
        withdrawalAddress = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
    
    /**
     * @dev fetch the owner of the contract
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev fetch the withdrawalAddress 
     */
    function getWithdrawalAddress() public view returns (address) {
        return withdrawalAddress;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the memo to storage!
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * @dev change the withdrawal address for tips. Only the owner can do this
     */
    function setWithdrawalAddress (address _withdrawalAddress) public {
        require(msg.sender == owner, "Only the owner can call this function");
        require(_withdrawalAddress != address(0), "Invalid withdrawal address");
        withdrawalAddress = payable(_withdrawalAddress);
    }
}