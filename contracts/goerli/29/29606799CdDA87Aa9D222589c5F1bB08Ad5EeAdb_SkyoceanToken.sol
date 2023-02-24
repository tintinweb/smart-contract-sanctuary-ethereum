/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ERC20 Interface
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SkyoceanToken {
    string public constant name = "Skyocean Token";
    string public constant symbol = "SKO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public constant INITIAL_SUPPLY = 5000000000 * (10 ** uint256(decimals)); // Total supply: 5 billion SKO tokens

    // Tokenomics
    uint256 public constant MAX_TOKENS_SOLD = 2500000000 * (10 ** uint256(decimals)); // Maximum tokens sold in ICO: 2.5 billion SKO tokens
    uint256 public constant ICO_TOKEN_PRICE = 1000000000000000 wei; // 1 SKO token = 0.001 ETH
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether; // Minimum contribution: 0.1 ETH
    uint256 public constant MAX_CONTRIBUTION = 1000 ether; // Maximum contribution: 1000 ETH
    uint256 public constant PRESALE_TOKENS = 500000000 * (10 ** uint256(decimals)); // Number of tokens allocated for presale: 500 million SKO tokens
    uint256 public constant PRESALE_TOKEN_PRICE = 800000000000000 wei; // 1 SKO token = 0.0008 ETH in presale
    uint256 public constant TEAM_TOKENS = 500000000 * (10 ** uint256(decimals)); // Number of tokens allocated for team: 500 million SKO tokens
    uint256 public constant ADVISORS_TOKENS = 250000000 * (10 ** uint256(decimals)); // Number of tokens allocated for advisors: 250 million SKO tokens
    uint256 public constant RESERVED_TOKENS = 1250000000 * (10 ** uint256(decimals)); // Number of tokens reserved for future use: 1.25 billion SKO tokens
    uint256 public constant VESTING_DURATION = 180 days; // Team and advisors tokens vesting duration: 180 days
    uint256 public constant VESTING_CLIFF = 90 days; // Team and advisors tokens vesting cliff: 90 days;
    
    address payable public owner;
    address public presaleContract;
    uint256 public tokensSold = 0;
    uint256 public weiRaised = 0;
    uint256 public presaleTokensSold = 0;
    uint256 public teamTokensClaimed = 0;
    uint256 public advisorsTokensClaimed = 0;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public presaleBalances;
    mapping(address => uint256) public teamTokenBalances;
    mapping(address => uint256) public advisorsTokenBalances;
    mapping(address => uint256) public teamTokenVestingDates;
    mapping(address => uint256) public advisorsTokenVestingDates;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensSold(uint256 indexed amount, uint256 indexed weiRaised);
    event PresaleTokensSold(uint256 indexed amount);
}