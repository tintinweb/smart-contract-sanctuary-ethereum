/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract BuyMeACoffee {
    //Event to emit when memo is struct
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    //Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    //list of all recieved friends memo
    Memo[] memos;

    // address of contract deployer
    address payable owner;

    //deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
    @dev buy a cofee for contract owner
    @param _name name of coffee buyer
    @param _message nice text from the coffee buyer
    */

    function buyCoffee(string memory _name, string memory _message)public payable{
       require(msg.value > 0 ,"can't buy coffee with 0 ETH");
   
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // emit a log event when a new memo is created!
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }
    function buyLargeCoffee() public payable{
        require(msg.value == 3,"Thanks for the Large coffee");
    }

    /**
         @dev send the entire balance stored in this contract to the owner
        */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
        @dev retrieve all the memos recieved and stored on the blockchain
        */

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}