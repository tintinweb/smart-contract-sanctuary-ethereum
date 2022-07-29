/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Contract Address on Goerli: 0xEcDcCA54aEAfcF622411E15bc13AB9b82efCC2Cc

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

    // List of all memos received from coffee purchases.
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message, uint256 _payableAmount)
        public
        payable
    {   
        uint256 cost = 0.001 ether;
        require(_payableAmount < cost, "Can't buy a coffee");
        
        // Add the memo to storage!
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * @dev change the owner
     * @param _newAddress address of the new owner
     */
    function changeOwner(address _newAddress) public {
        require(msg.sender == owner, "Only owner can change the owner.");
        owner = payable(_newAddress);
    }
}