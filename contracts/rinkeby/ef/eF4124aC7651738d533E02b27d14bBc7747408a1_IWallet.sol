//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract IWallet  {
    event Deposit(address caller, uint amount);
    event Invest( uint amount);
    event Withdraw(address caller, uint amount);
    event WithdrawInvestment(address caller, uint amount);
    uint public investTime;
    uint public investAmount;

    struct Users{
        address owner;
        uint  accountBalance;
        uint  currentIBalance;
        bool hasEarned;
    }
 
    constructor() public {

    }

    mapping(address => Users) public user;
    

    function deposit()payable  external {
       require(msg.value >= 1 ether, "invalid amount");
       investAmount = msg.value * 10 / 100 ;
       uint initialDeposit = msg.value - investAmount;
       Users storage user1 = user[msg.sender];
       user1.owner = msg.sender; 
       user1.accountBalance += initialDeposit; 
       user1.currentIBalance += investAmount;
       invest();       
       emit Deposit(msg.sender, msg.value);
   }

   function withdraw(uint _amount) external {
       Users storage user1 = user[msg.sender];
       user1.owner = msg.sender;
       require(user1.owner == msg.sender, "caller is not owner");
       require(_amount <= user1.accountBalance, "invalid amount");
       user1.accountBalance = user1.accountBalance - _amount;
       payable(msg.sender).transfer(_amount);
       emit Withdraw(msg.sender, _amount);

   }

    function invest() payable public{
        require(msg.value == investAmount, "invalid amount");
        investTime = block.timestamp;
        Users storage user1 = user[msg.sender];
        user1.currentIBalance = user1.currentIBalance + msg.value;
        user1.hasEarned = false;
        emit Invest( msg.value);

    }

    function earn() external returns(uint){
        Users storage user1 = user[msg.sender];
        require(user1.hasEarned == false, "cant earn again");
        require(block.timestamp - investTime >= 20 seconds , "cant earn now");
        uint interest = investAmount * 20/100;
        user1.currentIBalance = user1.currentIBalance + interest;
        user1.hasEarned = true;
        return user1.currentIBalance;
    }

//         // require(block.timestamp - investTime >= 20 seconds , "cant withdraw now");
    function withdrawInvestment(uint amount) external {
        Users storage user1 = user[msg.sender];
        require(user1.hasEarned == true, "have not earned yet");
        require(amount <= user1.currentIBalance, "invalid amount");
        user1.currentIBalance = user1.currentIBalance - amount;
        user1.accountBalance = user1.accountBalance + amount;    
        payable(msg.sender).transfer(amount);
        emit WithdrawInvestment(msg.sender, amount);
    }

}