/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

pragma solidity ^0.8.15;



interface USDCInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Alyst {

    event updatedAlystedAmount(uint newAmount);

    string public name;
    uint public fundAmount;
    uint public campaignPeriod;
    uint public timeCreated;
    uint public alystedAmount;

    address public alystTreasury =  0xFf5EA14b025C1998C13209A33317e030fB9cAdD5;

    address[] public Alysters;

    mapping(address => uint) public alysterAmount;
    mapping(address => bool) public hasAlysted;
    mapping(address => bool) public isAlysting;

    address public USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    USDCInterface USDC = USDCInterface(USDCAddress);


    constructor(string memory _name, uint _fundAmount, uint _campaignPeriod ) public {
        _name = name;
        _fundAmount = fundAmount;
        _campaignPeriod = campaignPeriod;
    }

    function invest(uint _amount) public  {
        require(_amount > 0, "Invalid amount");
        require(alystedAmount < fundAmount, "Project fully funded");
        // deposit stable coin
        USDC.allowance(msg.sender, address(this));

        USDC.transferFrom(msg.sender, address(this), _amount);

        if(!hasAlysted[msg.sender]) {
            Alysters.push(msg.sender);
        } 
        hasAlysted[msg.sender] = true;
        isAlysting[msg.sender] = true;

        alystedAmount = alystedAmount + _amount ;
        emit updatedAlystedAmount(alystedAmount);
        

    }

    function withdraw(address _projectTreasury) public {
        require(alystedAmount == fundAmount);

        uint _alystServiceCharge = address(this).balance * 3 / 200  ;
        uint projectFund = address(this).balance - _alystServiceCharge;

        USDC.transferFrom(address(this), _projectTreasury, projectFund);
        USDC.transferFrom(address(this), alystTreasury, _alystServiceCharge);


    }
}