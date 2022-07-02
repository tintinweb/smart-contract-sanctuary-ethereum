// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./console.sol";
import "./ExternalContract.sol";

contract Staker {

     ExternalContract public externalContract;
     address owner ;
    /**
*  @notice Contract Constructor
  * @param ExternalContractAddress Address of the external contract that will hold stacked funds
  */
    constructor(address payable ExternalContractAddress) public {
        owner = msg.sender;
        externalContract = ExternalContract(ExternalContractAddress);
    }
    //constants
    mapping ( address => uint256 ) public balances;

    uint256 public constant threshold = 0.01 ether;

    mapping(address => bool) public is_exhibit;

    bool status;

    uint256 public deadline = block.timestamp + 30 seconds;
    event Stake(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //转移合约所有权
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake(bytes32 _id) public payable {
        balances[msg.sender]+=msg.value;
        emit Stake(msg.sender, _id,msg.value);
    }

    function exhibit(address _Address, bool isExhibit) external onlyOwner {
        is_exhibit[_Address] = isExhibit;
    }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function setSatus(bool newStatus) external onlyOwner{
        status = newStatus;
    }
//没有实现的函数必须virtual在接口之外进行标记。在接口中，所有功能都会被自动考虑virtual
    function execute(address recipient,uint amount ) public {
        uint time=block.timestamp;
        //have end
        console.log("time",time);
        require(time > deadline,"have no reached time!");
    uint mybalance =address(this).balance;
//    (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0)
          if (mybalance > threshold && msg.sender == owner){
              //get another contract
              externalContract.complete{value: address(this).balance}();
          }else{
                require(!status,"withdraw close!");
                //must in white lists
               _transfer(msg.sender, recipient, amount);
          }

    }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  // Add a `withdraw()` function to let users withdraw their balance
      function withdraw() public payable {
          if (msg.sender==owner){
              payable(msg.sender).transfer(address(this).balance);
          }else{
              uint mybalance= balances[msg.sender];
              if (mybalance>0){
                  payable(msg.sender).transfer(mybalance);
              }
          }
    }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!is_exhibit[sender], "ERC20: Recipient address is Invalid ");
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
      //  Solidity 0.8.0开始，所有的算术运算默认就会进行溢出检查，额外引入库将不再必要。
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}