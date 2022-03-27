// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ETHPool {
    
    

    uint256 public lastRewardDate;
    uint256 public totalReward;
    uint256 public totalUserDeposits;

    struct detailUser {
        uint256 deposit;
        uint256 dateDeposit;
    }
    mapping(address => detailUser) public users;

    mapping(address => bool) public usersTeam;

    event DepositRewardTeam(
        address from,
        uint256 value,
        uint256 date
    );

    event DepositEthUser(
        address from, 
        uint256 value, 
        uint256 date);

    event Withdraw(
        address from,
        uint256 value,
        uint256 date);


    modifier onlyTeam() {
        require(
            usersTeam[msg.sender] == true,
            "Exclusive function of the team"
        );
        _;
    }
  

    
    constructor() {
        lastRewardDate = block.timestamp;
        usersTeam[msg.sender] = true;
    }


    function depositRewardTeam() public payable onlyTeam {
        require(
            block.timestamp > (lastRewardDate + 1 weeks),
            "It hasn't been a week"
        );
        
        totalReward += msg.value;
        lastRewardDate = block.timestamp;
        emit DepositRewardTeam(
            msg.sender,
            msg.value,
            block.timestamp
        );
    }

    function depositEthUser() public payable {
      
        users[msg.sender].deposit += msg.value;
        users[msg.sender].dateDeposit = block.timestamp;

        totalUserDeposits += msg.value;

        emit DepositEthUser(msg.sender, msg.value,  block.timestamp);
    }


    function withdraw() public {
      
        require(
            users[msg.sender].deposit > 0,
            "The user has not deposited"
        );
       
        if (users[msg.sender].dateDeposit < lastRewardDate) {
            uint256 porcentagePool = (users[msg.sender].deposit * 1 ether) /
                totalUserDeposits;

            uint256 earningsAndDeposit = users[msg.sender].deposit +
                (totalReward * porcentagePool) /
                1 ether;

            totalUserDeposits -= users[msg.sender].deposit;

            totalReward =
                totalReward -
                (totalReward * porcentagePool) /
                1 ether;

            users[msg.sender].deposit = 0;

            (bool success, ) = payable(msg.sender).call{
                value: earningsAndDeposit
            }("");

            require(success, "Transfer failed");

            emit Withdraw(
                msg.sender,
                earningsAndDeposit,
                block.timestamp
            );
        } else {
            (bool success, ) = payable(msg.sender).call{
                value: users[msg.sender].deposit
            }("");

            require(success, "Transfer failed");
        }
    }
}