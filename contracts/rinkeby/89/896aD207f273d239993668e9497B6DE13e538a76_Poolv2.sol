/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Poolv2 {
    address public immutable TEAM_ADDR;
    uint256 public totalFunds = 0;
    
    struct Deposit {
        uint256 amount; // The number of weis deposited
        uint256 reward; // The rewards this user gets
        uint256 index;
    }

    event DepositEvent(address indexed sender, uint amount, uint balance);

    mapping(address => Deposit) deposits;
    address[] userAddress;

    constructor(address team) payable {
        TEAM_ADDR = team;
    }

    modifier onlyTeam() {
        require(msg.sender == TEAM_ADDR, "Only team can add rewards");
        _;
    }

    modifier notTeam() {
        require(msg.sender != TEAM_ADDR, "Team cannot withdraw/deposit from/to pool");
        _;
    }

     modifier hasDeposited() {
        require(deposits[msg.sender].amount > 0 && userAddress[deposits[msg.sender].index] == msg.sender, "User does not have deposits in the pool to withdraw");
        _;
    }

    function viewPoolAmount() public view returns (uint){
        return address(this).balance;
    }

    function viewTeamAddress() public view returns (address){
        return TEAM_ADDR;
    }
    
    receive() external payable {
        emit DepositEvent(msg.sender, msg.value, address(this).balance);
    }

    //Assumption : for user struct with amount = 0 , funds was never deposited or has been withdrawn.

    function makeDeposit(uint amount) public notTeam payable {
       (bool success, ) = address(this).call{value: amount}("");
       require(success, "Failed to deposit to pool.");
       uint256 _index;
       if (deposits[msg.sender].amount > 0 && userAddress[deposits[msg.sender].index] == msg.sender) {
            deposits[msg.sender].amount += amount;
       }
       else {
            userAddress.push(msg.sender);
            _index = userAddress.length - 1;
            deposits[msg.sender] = Deposit(amount, 0, _index);
       }
       totalFunds += amount;
    }

    function addRewards(uint amount) public onlyTeam payable {
       (bool success, ) = address(this).call{value: amount}("");
       require(success, "Failed to add rewards to pool");
       //Calculate and update rewards
       uint256 rewardAmt;
       address userAddressValue;
       for(uint256 i=0 ; i < userAddress.length; i++){
            userAddressValue = userAddress[i];
            if(deposits[userAddressValue].amount > 0 && userAddress[deposits[userAddressValue].index] == userAddressValue){
                  rewardAmt = amount * deposits[userAddressValue].amount/totalFunds;
                  deposits[userAddressValue].reward += rewardAmt;
            }
       }
    }

    function withdraw() notTeam hasDeposited public {
        uint256 _amount = deposits[msg.sender].amount;
        uint256 _rewards = deposits[msg.sender].reward;
        uint256 _index = deposits[msg.sender].index;
        uint256 withdrawAmount = _amount + _rewards;
       
        (bool success, ) = msg.sender.call{value: withdrawAmount}(""); 
        require(success, "Failed to withdraw money from contract.");
        deposits[msg.sender] = Deposit(0, 0, 0);
        totalFunds -= _amount;
        uint256 lastIndex = userAddress.length - 1 >= 0 ? userAddress.length - 1 : 0;
        userAddress[_index] = userAddress[lastIndex]; // Moving user address from end of array to that pos
        deposits[userAddress[_index]].index = _index;
        userAddress.pop();
    }
}