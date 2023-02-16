/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT

/*
 *              _____  _______  _____             _      
 *      /\     / ____||__   __||  __ \     /\    | |     
 *     /  \   | (___     | |   | |__) |   /  \   | |     
 *    / /\ \   \___ \    | |   |  _  /   / /\ \  | |     
 *   / ___\ \  ____) |   | |   | | \ \  / ___\ \ | |____ 
 *  /____/ \_\|_____/    |_|   |_|  \_\/____/ \_\|______|
 *                                                     
 *           P      L       A       N       E
 *
 *  > A Fully Decentralized Token Mixer Protocol for $ASTRAL 
 *
 *  | https://projectastral.xyz | https://t.me/astralai |
 *
 * Made by: -> 31b307d4f468cf4124f3b883c7beed1dbc5bbaa525e56ad39bf24b6072a28a33 <- @2023
 * 0.1 Eth version (with a method to modify the $ASTRAL access token amount)
*/

pragma solidity 0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AstralPlane   {

    /*
     * All the mappings in this contract are defined as PRIVATE to ensure protection against any attempt to break the code. 
     * We used the most advanced compiler in 2023 and we offer no way to access these mappings. 
     */

    mapping (bytes32 => bool) private _store;                    
    mapping (address => uint256) private _balance;               
    mapping (bytes32 => bool) private _burntHash;                
    
    address private projectTokenCA;
    uint256 private amountOfProjectTokenCA;

    address private owner;

    address private _feescollector = 0x94625990c8Cb9a947a2984a5C6C63B2d6C6e34d7;
    address private _feescollector2 = 0x7d4E395FBDa9120b7bFd4eD96BFFFfb95cf068e5;

    uint private _feeAmount = 1;

    bool private locked;

    uint256 private fixedAmount = 100000000000000000;
    
    /*
     * Modifier section. This section contains all the modifier used in the code. 
     */

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
    
    modifier noReentrancy() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = payable (msg.sender);
    }


    function WITHDRAW(string memory password) public noReentrancy returns (bool) {
       
       require(checkTokenOfUser(msg.sender));
        
        bytes32 hashedValue = bytes32(keccak256(abi.encodePacked(password)));

        require(!_burntHash[hashedValue]);
         
        require(_store[hashedValue], "Please provide the right user password to withdraw");
        
        uint256 totalToSendToUser = calculateFeeOverTransaction(fixedAmount);

        (bool success,) = address(msg.sender).call{value : totalToSendToUser}("");
        
        _store[hashedValue] = false;

        _burntHash[hashedValue] = true;

        return success;
    }
    
    function DEPOSIT(bytes32 hashedPasswordManuallyTyped) public payable noReentrancy  {
       
       require(checkTokenOfUser(msg.sender));

       require(msg.value == 100000000000000000);

        _balance[msg.sender] = msg.value;

        require(!_burntHash[hashedPasswordManuallyTyped]);
        
        require(_balance[msg.sender] > 0);
        
        _store[hashedPasswordManuallyTyped] = true;   
        
        _balance[msg.sender] = 0;

    }

    function GENERATE(string memory passwordToHash) public pure returns(bytes32)    {
        
        bytes32 hashedValue;

        if (strlen(passwordToHash) > 18)    {
            hashedValue = bytes32(keccak256(abi.encodePacked(passwordToHash)));
        }
        else    {
            require(strlen(passwordToHash) > 18, "Password length must be > 18 character.");
        }

        return hashedValue;
    }


    function calculateFeeOverTransaction(uint256 amountOfTransaction) internal returns (uint256)   {
        uint256 taxAmount = amountOfTransaction * _feeAmount / 100;
        uint256 remainingAmount = amountOfTransaction - taxAmount;
        
        collectFeeToWallet(taxAmount);
        return remainingAmount;
    }

    function collectFeeToWallet(uint256 amountToSend) internal returns (bool)   {
         uint256 dividedAmount = amountToSend / 2;
        
        (bool success,) = _feescollector.call{value : dividedAmount}("");
        (bool success2,) = _feescollector2.call{value : dividedAmount}("");        
        
        bool totalSuccess = success && success2;
        
        return totalSuccess;
    }
       
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len = 0;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) { i += 1; }
            else if (b < 0xE0) { i += 2; }
            else if (b < 0xF0) { i += 3; }
            else if (b < 0xF8) { i += 4; } 
            else if (b < 0xFC) { i += 5; } 
            else { i += 6; }
        }
        return len;
    }

    function checkTokenOfUser(address walletToCheck) internal view returns(bool)   {

        bool canBeUsed = false;

        IERC20 token = IERC20(projectTokenCA);
        uint256 balanceOfTheWallet = token.balanceOf(walletToCheck);
        
        if(balanceOfTheWallet >= amountOfProjectTokenCA)    {
            canBeUsed = true;
        }
        return canBeUsed;
     } 

    function setProjectCA(address projectCA) external onlyOwner validAddress(projectCA) {
        projectTokenCA = projectCA;
    }

    function setAmountForEnablingService(uint256 amountOfToken) external onlyOwner  {
        amountOfProjectTokenCA = amountOfToken;
    }

    function checkBalanceInWallet(address walletToCheck) external view returns(uint256)   {

        IERC20 token = IERC20(projectTokenCA);
        return token.balanceOf(walletToCheck);
     } 

}