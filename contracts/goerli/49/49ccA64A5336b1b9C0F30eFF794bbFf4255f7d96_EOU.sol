// SPDX-License-Identifier: MIT

/*
This Solidity smart contract is a custom implementation of an ERC20 token called 
"Exodus Our Universe" (EOU), which inherits from the OpenZeppelin ERC20 contract. 
It includes additional functionalities like a staking system, tax on transactions, 
and white-listed accounts.

Here's a brief summary of some of the important functions and state variables of 
this contract:

State Variables:

owner: The address of the contract owner.
marketingWallet: The address of the marketing wallet.
liquidityWallet: The address of the liquidity wallet.
developerWallet: The address of the developer wallet.
taxRate: The transaction tax rate as a percentage.
whiteListedAccounts: A mapping of accounts that are exempt from transaction taxes.
taxRates: A mapping of the tax rates for specific wallets.
stakerAddressList: A list of wallet addresses that have staked EOU tokens.
staking: A mapping of the amount of EOU tokens staked by each wallet.
Functions:

constructor: Initializes the contract state variables and mints an initial 
supply of EOU tokens.
addWhiteListedAccountAddress: Adds an account to the white-listed accounts mapping.
setTotalTaxRate: Sets the tax rate for all transactions.
setTaxRate: Sets the tax rate for a specific wallet.
setMarketingWalletAddress: Sets the address of the marketing wallet and adds it to the staker list.
setLiquidityWalletAddress: Sets the address of the liquidity wallet and adds it to the staker list.
setDeveloperWalletAddress: Sets the address of the developer wallet and adds it to the staker list.
transfer: Overrides the transfer function of the ERC20 contract to include transaction taxes and 
staking rewards. Calculates the tax on the transaction based on the tax rate and tax rates of the 
specific wallets, distributes the tax to staker wallets, and transfers the remaining tokens to the 
recipient. Also updates the staker list and removes a wallet from the list if it has a balance of 0.
_distributeTokens: Distributes the tax amount among all the staker wallets.
_addStaker: Adds a wallet to the staker list.
_removeStaker: Removes a wallet from the staker list.
_calculatePercentage: Calculates the percentage of one value relative to another value.
In summary, this contract implements a custom ERC20 token that includes transaction taxes and 
staking rewards for staker wallets. The contract owner can set the tax rates for specific wallets 
and modify the wallet addresses, while also being able to add accounts to the white-listed 
accounts mapping. The stakerAddressList can be used to retrieve a list of wallets that have staked
EOU tokens, and the claimStakingRewards function allows stakers to claim their staking rewards.
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract EOU is ERC20 {
    address public owner;
    address public marketingWallet;
    address public liquidityWallet;
    address public developerWallet;
    uint256 public taxRate;
    mapping(address => bool) public whiteListedAccounts;
    mapping(address => uint256) public taxRates;
    address[] public stakerAddressList;
    mapping(address => uint256) public staking;

    constructor(address _marketingWallet, address _liquidityWallet, address _developerWallet) ERC20("Exodus Our Universe", "EOU") {
        owner = msg.sender;
        
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        developerWallet = _developerWallet;

        stakerAddressList.push(marketingWallet);
        stakerAddressList.push(liquidityWallet);
        stakerAddressList.push(developerWallet);

        // Initialize the tax rates
        taxRate = 10;
        taxRates[marketingWallet] = 2;
        taxRates[liquidityWallet] = 2;
        taxRates[developerWallet] = 5;

        _mint(msg.sender, 100000000000000000000000000);
    }

    function addWhiteListedAccountAddress(address wallet) public {
        require(msg.sender == owner, "Must be set by contract owner only.");
        whiteListedAccounts[wallet] = true;
    }

    function setTotalTaxRate(uint256 rate) public {
        require(msg.sender == owner, "Must be set by contract owner only.");
        taxRate = rate;
    }

    function setTaxRate(address wallet, uint256 rate) public {
        require(msg.sender == owner, "Must be set by contract owner only.");
        require(wallet == marketingWallet || wallet == liquidityWallet || wallet == developerWallet, "Invalid wallet");
        taxRates[wallet] = rate;
    }

    function setMarketingWalletAddress(address wallet) public {
        require(msg.sender == owner, "Must be set by contract owner only.");

        if (marketingWallet.balance == 0) {
            _removeStaker(marketingWallet);
        }

        marketingWallet = wallet;

        _addStaker(marketingWallet);
    }

    function setLiquidityWalletAddress(address wallet) public {
        require(msg.sender == owner, "Must be set by contract owner only.");

        if (liquidityWallet.balance == 0) {
            _removeStaker(liquidityWallet);
        }

        liquidityWallet = wallet;

        _addStaker(liquidityWallet);
    }

    function setDeveloperWalletAddress(address wallet) public {
        require(msg.sender == owner, "Must be set by contract owner only.");

        if (developerWallet.balance == 0) {
            _removeStaker(developerWallet);
        }

        developerWallet = wallet;

        _addStaker(developerWallet);
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Must be set by contract owner only.");
        owner = newOwner;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 taxAmount = 0;
        uint256 tokensToTransfer = 0;

        _transfer(msg.sender, address(this), amount);

        if (whiteListedAccounts[msg.sender] || msg.sender == owner || msg.sender == address(this)) {
            tokensToTransfer = amount;
        } else {
            taxAmount = _calculatePercentage(amount, taxRate);

            uint256 marketingTaxAmount = _calculatePercentage(amount, taxRates[marketingWallet]);
            uint256 liquidityTaxAmount = _calculatePercentage(amount, taxRates[liquidityWallet]);
            uint256 developerTaxAmount = _calculatePercentage(amount, taxRates[developerWallet]);
            
            tokensToTransfer = amount - taxAmount;
            staking[marketingWallet] += marketingTaxAmount;
            staking[liquidityWallet] += liquidityTaxAmount;
            staking[developerWallet] += developerTaxAmount;
            taxAmount = taxAmount - (marketingTaxAmount + liquidityTaxAmount + developerTaxAmount);
        }

        _addStaker(recipient);
        
        _transfer(address(this), recipient, tokensToTransfer);

        if (msg.sender != marketingWallet && msg.sender != liquidityWallet && msg.sender != developerWallet) {
            if (msg.sender.balance == 0) {
                _removeStaker(msg.sender);
            }
        }

        if (!(whiteListedAccounts[msg.sender] || msg.sender == owner || msg.sender == address(this))) {
            uint256 tokensToDistribute = taxAmount / stakerAddressList.length;
            _distributeTokens(tokensToDistribute);
        }

        return true;
    }

    function _distributeTokens(uint256 amount) private {
        uint256 share = amount / stakerAddressList.length;

        for (uint256 i = 0; i < stakerAddressList.length; i++) {
            staking[stakerAddressList[i]] += share;
        }
    }

    function _addStaker(address wallet) private{
        bool notFound = true;

        for (uint256 i = 0; i < stakerAddressList.length; i++) {
            if (stakerAddressList[i] == wallet) {
                notFound = false;
            }
        }

        if (notFound) {
            stakerAddressList.push(wallet);
        }
    }

    function _removeStaker(address wallet) private {
        for (uint256 i = 0; i < stakerAddressList.length; i++) {
            if (stakerAddressList[i] == wallet) {
                delete stakerAddressList[i];
                for (uint256 j = i; j < stakerAddressList.length - 1; j++) {
                    stakerAddressList[j] = stakerAddressList[j+1];
                }
                stakerAddressList.pop();
                break;
            }
        }
    }

    function _calculatePercentage(uint256 value, uint256 percentagePoints) private pure returns (uint256) {
        uint256 percentage = (value * percentagePoints) / 100;
        return percentage;
    }

    function claimStakingRewards() public {
        require(staking[msg.sender] > 0, "No staking rewards to claim");
        uint256 rewards = staking[msg.sender];
        staking[msg.sender] = 0;
        _transfer(address(this), msg.sender, rewards);
    }
}