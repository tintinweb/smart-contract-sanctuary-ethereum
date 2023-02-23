// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Deployed to Goerli at 0xC89313bA55526f59bC85dFa1B1D8cabEf70EA6A2

contract BuyMeACoffee {
    //Event to emit when a Memo is created.
    event NewMemo(
      address indexed from,
      uint256 timestamp,
      string name,
      string leavemessage,
      bool isBigCoffee
    );

    // Memo struct.
    struct Memo {
      address from;
      uint256 timestamp;
      string name;
      string leavemessage;
      bool isBigCoffee;
    }
     
    // List of all memos received from friends
    Memo[] memos;

    // address of contract deployer
    address payable owner;

    // Deploy logic
    // 构造函数是在部署合约时恰好部署一次的,它永远不会再次运行,所以owner地址只会更新一次
    constructor(){
      owner = payable(msg.sender);
    }

    /**
     * @dev buy a coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message a nice message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
       require(msg.value > 0, "you can't buy coffee with 0 eth");
       bool  isBig;

       if( msg.value == 0.001 ether){
        isBig = false;
       } else {
        isBig = true;
       }
       // pass then add Memo to storage
      memos.push(Memo(
          msg.sender,
          block.timestamp,
          _name,
          _message,
          isBig
      ));

      // emit a log event when a new memo is created
      emit NewMemo(
        msg.sender,
        block.timestamp,
        _name,
        _message,
        isBig
      );
    }

    /**
     * @dev 验证是否是合约部署者,是的话应许更换owner
     */
    function changeOwner(address payable newOwner) public{
      require( msg.sender == owner, "Only the contract owner can call this method.");
      owner = newOwner;
    }

    /**
     * @dev 将合约中的所有余额发送给合约所有者
     */
    function withdrawTips() public {
      require(owner.send(address(this).balance), "fail");
    } 

    /**
     * @dev 取回所有存储在区块链上的备忘录
     */
    function getMemos() public  view returns( Memo[] memory){
      return memos;
    }
}