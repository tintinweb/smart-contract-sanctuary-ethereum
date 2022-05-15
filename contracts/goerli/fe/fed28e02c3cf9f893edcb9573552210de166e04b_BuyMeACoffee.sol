/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {

  // Event to emit when a memo is created
  event NewMemo(
    address indexed from,
    uint256 timestamp,
    string name,
    string message
  );

  // Memot structure
  struct Memo {
    address from;
    uint256 timestamp;
    string name;
    string message;
  }

  // List of all memos
  Memo[] memos;

  // Address of contract deployer
  address payable owner;

  // Address of coffee recipient
  address payable recipient;

  //Deploy logic
  constructor() {
    owner = payable(msg.sender);
    recipient = payable(msg.sender);
  }

  /**
  * @dev buy a coffee for the contract owner
  * @param _name name of the buyer
  * @param _message nice message from the coffee buyer
  */
  function buyCoffee(string memory _name, string memory _message) public payable  {
    require(msg.value > 0, "Can not buy coffee with monkey money");

    //add the memos to storage
    memos.push(Memo(
      msg.sender,
      block.timestamp,
      _name,
      _message
    ));

    // emit the vent of new memo
    emit NewMemo(
      msg.sender,
      block.timestamp,
      _name,
      _message);
    }

    /**
    * @dev send the entire balance stored to the owner
    */
    function withdrawTips() public {
      address(this).balance;
      require(recipient.send(address(this).balance),"failed");
    }

    /**
    * @dev retrieve all memos
    */
    function getMemos() public view returns(Memo[] memory) {
      return memos;
    }

    /**
    * @dev set a new coffee recipient
    */
    function setNewCoffeeRecipient(address payable _newRecipient) public {
      require(msg.sender == owner,"Only contract owner can change recipient");
      require(recipient != address(0), "already recipient");
      recipient = _newRecipient;
    }
  }