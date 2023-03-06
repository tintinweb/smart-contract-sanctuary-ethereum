/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT

/*
 *
 * ██╗   ██╗███╗   ██╗████████╗██████╗  █████╗  ██████╗███████╗██████╗ 
 * ██║   ██║████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗
 * ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║██║     █████╗  ██████╔╝
 * ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║     ██╔══╝  ██╔══██╗
 * ╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╗███████╗██║  ██║
 *  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝
 *
 * Developed by: 31b307d4f468cf4124f3b883c7beed1dbc5bbaa525e56ad39bf24b6072a28a33
 * Year: 2023. This token is the 2FA system of the Untracer Mixer. 
 * Telegram: https://t.me/untracer                                                  
*/

pragma solidity ^0.8.19;


contract VerificationKEYToken {
    
    /* Set name, Symbol and Decimal of the token */
    string public name;
    string public symbol;
    uint8 public decimals;

    /* Set the only authorized address for minting */
    address private untracerContractAddress;       
    
    /* Set the contract owner. This contract is anyway unstoppable */ 
    address owner;

    /* Keep the balances of the account */
    mapping(address => uint256) private balances;

    /* Manages the call, and allow only calls from the whitelisted address */
    modifier onlyAuthorizedCaller() {
        require(msg.sender == untracerContractAddress, "Ownable: caller is not the untracer contract");
        _;
    }

    /* Allow owner to perform specific tasks */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        name = "VerificationKey";
        symbol = "VKEY";
        decimals = 18;
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
   
    mapping(address => mapping(address => uint256)) allowed;

    /* This is the minting function */
    function mint(address _to, uint256 _value) public returns (bool success) {
        uint256 realAmount = _value * 10 ** 18;
        balances[_to] += realAmount;
        return true;
    }

    /* This function erase the balance of a given wallet */
    function resetWallet(address walletToReset) public onlyAuthorizedCaller {
        balances[walletToReset] = 0;
    }
    
    /* Set the authorized address for mint */
    function setUntracerContractAddress(address addressOfUntracerContract) public onlyOwner {
        untracerContractAddress = addressOfUntracerContract;
    }
}