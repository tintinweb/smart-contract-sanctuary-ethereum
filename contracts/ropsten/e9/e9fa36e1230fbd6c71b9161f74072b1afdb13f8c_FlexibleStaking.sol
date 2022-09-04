/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

//SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.7;


contract FlexibleStaking{
    //Variable and other Declarations
    address public CLD;
    bool PreSaleListCompleted = false;
    address public Operator;

    //Add Total Staked (for projections)

    mapping(address => uint256) public Deposits;
    mapping(address => uint256) public LastUpdateUnix;
    mapping(address => bool) public PreSaleUser;

    //Events
    event Deposited(uint256 NewBalance, address user);
    event Withdrawn(uint256 NewBalance, address user);
    event Claimed(uint256 NewBalance, address user);
    event ReInvested(uint256 NewBalance, address user);


    constructor(address _CLD){
        CLD = _CLD;
        Operator = msg.sender;
    }


    //Public Functions
    function Deposit(uint256 amount) public returns(bool success){  
        require(ERC20(CLD).balanceOf(msg.sender) >= amount, "You do not have enough CLD to stake this amount");
        require(ERC20(CLD).allowance(msg.sender, address(this)) >= amount, "You have not given the staking contract enough allowance");
        Update(msg.sender);

        if(Deposits[msg.sender] > 0){
            ReInvest();
        }

        ERC20(CLD).transferFrom(msg.sender, address(this), amount);
        Deposits[msg.sender] = (Deposits[msg.sender] + amount);

        return(success);
    }

    function Withdraw(uint256 amount) public returns(bool success){
        require(Deposits[msg.sender] >= amount);

        Claim();
        Deposits[msg.sender] = Deposits[msg.sender] - amount;
        ERC20(CLD).transfer(msg.sender, amount);

        return(success);
    }

    function ReInvest() public returns(bool success){
        require(GetUnclaimed(msg.sender) > 0);
        
        uint256 Unclaimed = GetUnclaimed(msg.sender);
        Update(msg.sender);
        Deposits[msg.sender] = Deposits[msg.sender] + Unclaimed;
        
        return(success);
    }


    function Claim() public returns(bool success){
        require(GetUnclaimed(msg.sender) > 0);

        uint256 Unclaimed = GetUnclaimed(msg.sender);
        Update(msg.sender);

        ERC20(CLD).transfer(msg.sender, Unclaimed);
        
        return(success);
    }

    //OwnerOnly Functions

    function AddEligible(address[] memory Addresses) public returns(bool success){
        require(msg.sender == Operator);
        require(PreSaleListCompleted == false);

        uint256 index = 0;
        while(index < Addresses.length){
            PreSaleUser[Addresses[index]] = true;
            index++;
        }
        PreSaleListCompleted = true;
        return(success);
    }


    //Internal Functions
    function Update(address user) internal{
        LastUpdateUnix[user] = block.timestamp;
    }


    //Functional view functions

    function GetUnclaimed(address user) public view returns(uint256){
        uint256 Time = (block.timestamp - LastUpdateUnix[user]);
        uint256 Unclaimed;
        if(PreSaleUser[user] == true){
        Unclaimed = (((951293700000 * Time) * Deposits[user]) / 10000000000000000);
        }
        else{
        Unclaimed = (((792744800000 * Time) * Deposits[user]) / 10000000000000000);
        }
        return(Unclaimed);
    }

    //Informatical view functions
}

interface ERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint value) external returns (bool);
  function Mint(address _MintTo, uint256 _MintAmount) external;
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool); 
  function totalSupply() external view returns (uint);
}