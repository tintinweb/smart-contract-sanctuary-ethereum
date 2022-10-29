// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract BuyMeACoffee {
    // Event to emit when a Memo is created
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

    // List of all memos received from friends
    Memo[] memos;

    // Address of contract deployer
    address payable owner;

    // Deploy
    constructor() {
        owner = payable(msg.sender);
    }


    /**
     * @dev function used by the owner of a contract to modify the withdrawal address
     * @param _new_owner : new address where to send the tips
     */
    function changeOwner(address _new_owner) public{
        require(owner == msg.sender);
        owner = payable(_new_owner);
    }
    
    /**
     * @dev buy a coffee for contract owner
     * @param _name : name of the buyer
     * @param _message : message of the buyer
    */
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "can't buy a coffee with 0 eth");

        //add the memo to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        //emit log event
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance to the contract owner
    */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * @dev retrieve all memos
    */
    function getMemos() public view returns(Memo[] memory){
        return memos;
    }
}