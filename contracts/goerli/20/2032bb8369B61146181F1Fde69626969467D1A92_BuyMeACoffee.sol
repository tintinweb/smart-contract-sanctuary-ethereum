// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BuyMeACoffee {
    // Custom errors
    error InsufficientFunds();
    error NotContractOwner();

    // Event to emit when Memo is created.
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

    // List of all memos received from friends.
    Memo[] memos;

    // Address of contract owner.
    address payable public owner;

    // Deploy logic.
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev buy a cofee for contract owner
     * @param _name name of the coffee buyer
     * @param _message a nice message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        if (msg.value < 0.001 ether) revert InsufficientFunds();

        // Add the memo to storage.
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a log event when a new memo is created.
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * @dev change the owner of the contract
     * @param _newOwner address of the new owner
     */
    function changeOwner(address _newOwner) external {
        if (msg.sender != owner) revert NotContractOwner();
        owner = payable(_newOwner);
    }

    /**
     * @dev retrieve all the memos received and stored on the blockchain
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}