//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract deployed at 0x80E4BA86c74Fa658146281d44382DdfD42aC8b3F

contract BuyMeACoffee {

    //memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    //address of contract deployer
    address payable public owner;

    //list of all memos received 
    Memo[] memos;

    //Event to emti when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    event OwnerChanged(address oldOwner, address newOwner);

    //deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev buy a coffe for contract owner
     * @param _name name of the coffe buyer
     * @param _message a nice message from the coffe buyer
     */
    function buyCoffee(string memory _name, string memory _message) public payable{
        require(msg.value > 0, "Can't buy coffe with 0 eth.");

        // add the memo to storage
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        //emit a log event
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * @dev retrieve all the memos received and stored on the blockchain
     */
    function getMemos() public view returns(Memo[] memory){
        return memos;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only owner can change ownership.");
        address oldOwner = owner;
        owner = payable(newOwner);

        emit OwnerChanged(oldOwner, newOwner);
    }
}