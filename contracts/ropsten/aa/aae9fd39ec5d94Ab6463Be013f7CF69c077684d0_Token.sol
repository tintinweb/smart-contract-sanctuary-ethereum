/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract Token {
    string public constant tokenName = "My Sale Token";
    string public constant tokenSymbol = "MSTN";

    uint256 public initialNumberOfTokens = 25000;
    address public marketingDepartment;
    address public admin_HolderOfTokens;
    uint public pastStakeTime = block.timestamp;
    bool public sale;

    address[] public stakeHolder;
    mapping(address => uint256) entityBalances;
    mapping(address => uint256) stakeholderBalance;

    //constructor for initializing Token smartcontract

    constructor() {
        //there should be someone who will be the holder of tokens
        entityBalances[msg.sender] = initialNumberOfTokens;
        admin_HolderOfTokens = msg.sender;
    }

    function transferToken(uint256 _tokens, address _receiver)
        external
        payable
        checkSale
    {
        //as a safe side to check if the no of tokens already assigned to admin
        require(
            entityBalances[admin_HolderOfTokens] > _tokens,
            "check if admin have enough tokens"
        );
        //getting no of tokens from the admin and sending to the receiver
        entityBalances[admin_HolderOfTokens] -= _tokens;
        uint256 fourthOfTokens = _tokens / 4;
        uint256 newAmountOfTokens = _tokens - fourthOfTokens;
        entityBalances[_receiver] += newAmountOfTokens;
        entityBalances[marketingDepartment] += fourthOfTokens;
    }

    function stakeToken(uint _amount, address _staker) external payable {
        require(block.timestamp - pastStakeTime > 1 minutes, "please wait for 1 minutes");
        //as a record that this stakeholder staked this amount
        stakeholderBalance[_staker] += _amount;
        //all the amounts must have the authority of admin
        entityBalances[admin_HolderOfTokens] += _amount;
        //pushing the stakeholder in our stake holder address
        stakeHolder.push(_staker);
        pastStakeTime = block.timestamp;
    }

    function onSale() public returns (bool) {
        require(sale == false);
        return sale = true;
    }

    function setMarketingDepartmentAddress(address _marketing) external {
        marketingDepartment = _marketing;
    }

    function getMarketingDepartmentAddress() external view returns (address) {
        return marketingDepartment;
    }

    function getMarketingDepartmentBalance() external view returns (uint256) {
        return entityBalances[marketingDepartment];
    }

    function getAdminBalance() external view returns (uint256) {
        return entityBalances[admin_HolderOfTokens];
    }

    function getStakeHolderBalance(address _staker) external view returns (uint256) {
        return stakeholderBalance[_staker];
    }

    modifier checkSale() {
        require(sale == true, "Please wait for the sale to take off");
        _;
    }
}