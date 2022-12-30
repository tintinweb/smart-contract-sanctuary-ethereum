/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// version 2 of lilNouns Valuation Tool by tlogs.eth
// changed LilTargetPrice to wei from mwei
// added functionality for addition of erc-20 & erc-721 treasury assets
// SPDX-License-Identifier: MIT

// TO DO: add functions to update all Addresses

pragma solidity ^0.8.17;

// partial interface for reading balances of NOUN & LILNOUN ERC-20 treasury assets

interface PartialIERC20 {

function balanceOf(address account) external view returns (uint256);

}

// partial interface for reading token balances & total supply of NOUN & LILNOUNs & ERC-721 treasury assets

interface PartialIERC721 {

function totalSupply() external view returns (uint256);

function balanceOf(address owner) external view returns (uint256 balance);

}

contract lilNounValuation {

// STATE VARIABLES



    // Nouns DAO 

PartialIERC721 public NOUNtoken; // NOUN token interface
address public nounsTreasury; // address holding Nouns DAO ETH
uint public NOUNholdings; // number of NOUNS held by Lil Nouns Treasury
uint public NOUNvalueInETH; // added variable for valuation of a single NOUN in wei.

    // Lil Nouns DAO 

PartialIERC721 public LilNounsToken; // interface for Lil totalSupply
address public LilNounsTreasury; // Lil Nouns Treasury Address with assets to value
uint public LilTargetPrice;  // in wei, for use as Target Price in other Lil contracts

    // Treasury Asset Variables

struct ETHwrapperToken{
    string tokenSymbol;
    address tokenAddress;
}

mapping (uint => ETHwrapperToken) ETHwrapperTokenIndex; // used in 'for' loop in _updateNOUNvaluation

address[] public ETHwrapperTokenAddresses; // used in 'for' loop in _updateNOUNvaluation

// CONSTRUCTOR

// TO DO: ADD functions for owner to change addresses from constructor

constructor (PartialIERC721 _NOUNtoken, address _nounsTreasury, PartialIERC721 _LilNounsToken, address lilTreasury){
    NOUNtoken = _NOUNtoken;
    nounsTreasury = _nounsTreasury;
    LilNounsToken = _LilNounsToken;
    LilNounsTreasury = lilTreasury;
}


// EXTERNAL STATE CHANGES - NEED OWNER CONTRACT / MODIFIER

function updateLilTargetPrice() external {
    uint updatedPrice = _updateLilTargetPrice();
    LilTargetPrice = updatedPrice;
}

function addWrappedETHtoken(string memory tokenID, address addETHwrapper) external  {
    uint256 tokenIndex = ETHwrapperTokenAddresses.length;
    ETHwrapperTokenAddresses.push(addETHwrapper); // give each token an uint ID 
    ETHwrapperToken storage p = ETHwrapperTokenIndex[tokenIndex];
    p.tokenSymbol = tokenID;  // set the token ID for the ETH wrapper
    p.tokenAddress = addETHwrapper; // set the token address for the ETH wrapper
}

// INTERNAL VIEW FUNCTIONS

function _updateLilTargetPrice() internal returns (uint newLilTargetPrice) {
    uint ETHinWeiperNoun = _updateNounValuation(); // returns 10**18 nounValueInWei
    uint256 LilSupply = LilNounsToken.totalSupply(); // decimals 0
    uint LilETH = LilNounsTreasury.balance; // returns 10**18 Lil Nouns DAO eth balance in wei
    uint currentNouns = _updateNounHoldings();
    uint updatedLilWeiVal = ((ETHinWeiperNoun * currentNouns) + LilETH) / LilSupply;
    LilTargetPrice = updatedLilWeiVal; // returns wei
    return LilTargetPrice;
}

    // function for rough ETH Value of a single NOUN based on Nouns DAO treasury holdings & NOUN totalSupply
    // called in _updateLilValuation
    // IMPORTANT: currently only works for wrapped-versions of ETH, as conversion to wei is direct.


function _updateNounValuation() internal returns (uint newNounValueinWei) {
    uint nounETH = nounsTreasury.balance; // returns 10 ** 18, NOUN DAO eth balance in WEI
    uint valueofWrappers; // currently only works for wrapped ETH tokens. Would need to call a price oracle for true ERC20 valuation

    for (uint i = 0; i < ETHwrapperTokenAddresses.length; i++) {
        uint WrapperValue = PartialIERC20(ETHwrapperTokenIndex[i].tokenAddress).balanceOf(nounsTreasury);
        valueofWrappers += WrapperValue;
        }

    uint nounSupply = NOUNtoken.totalSupply(); // returns decimal = 0, get current NOUN supply
    uint nounValueInWei = (nounETH + valueofWrappers) / nounSupply; // decimals 10**18
    NOUNvalueInETH = nounValueInWei / 10**18; // update the public variable for single noun valuation in ETH
    return nounValueInWei; // decimals 10**18
}

    // Updates the qty of NOUNs in Lil Noun treasury
    // called in _updatedLilValuation

function _updateNounHoldings() internal returns (uint nounsHeld) {
    uint _updatedHoldings = NOUNtoken.balanceOf(LilNounsTreasury); // returns decimal = 0 NOUN qty
    NOUNholdings = _updatedHoldings;
    return _updatedHoldings;
}

}