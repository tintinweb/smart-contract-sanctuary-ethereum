/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// lilNouns Valuation Tool by tlogs.eth via Crypto Learn Lab
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// implemented for stETH

interface PartialIERC20 {

function balanceOf(address account) external view returns (uint256);

}

// implemented for NOUN & LILNOUN 

interface PartialIERC721 {

function totalSupply() external view returns (uint256);

function balanceOf(address owner) external view returns (uint256 balance);

}

contract lilNounsValuation {

// STATE VARIABLES

    // Treasury Assets

PartialIERC20 public stETHaddress; // for valuing NOUN holdings

    // Nouns DAO 

PartialIERC721 public NOUNtoken; // NOUN token interface
address public nounsTreasury; // address holding Nouns DAO ETH

    // Lil Nouns DAO 

PartialIERC721 public LilNounsToken; // interface for Lil totalSupply
address public LilNounsTreasury; // Lil Nouns Treasury Address with assets to value

    // Target Price variable is the only dynamic variable in the contract

uint public LilTargetPrice;  // in milliether (0.001 ETH)

// CONSTRUCTOR

constructor (PartialIERC20 _stETHaddress, PartialIERC721 _NOUNtoken, address _nounsTreasury, PartialIERC721 _LilNounsToken, address lilTreasury){
    stETHaddress = _stETHaddress;
    NOUNtoken = _NOUNtoken;
    nounsTreasury = _nounsTreasury;
    LilNounsToken = _LilNounsToken;
    LilNounsTreasury = lilTreasury;
}

// EXTERNAL VIEW functions (no state change intended)

// what variable do we want here

function GetLilTargetPrice() external view returns (uint TargetAquired) {
    return LilTargetPrice;
}

function updateAndGetLilTargetPrice() external returns (uint TargetAquired) {
    uint updatedPrice = _updateLilTargetPrice();
    LilTargetPrice = updatedPrice;
    return LilTargetPrice;
}

// INTERNAL VIEW FUNCTIONS

function _updateLilTargetPrice() internal returns (uint newLilTargetPrice) {
    uint ETHinWeiperNoun = _updateNounValuation(); // returns 10**18 nounValueInWei
    uint256 LilSupply = LilNounsToken.totalSupply(); // decimals 0
    uint LilETH = LilNounsTreasury.balance; // returns 10**18 Lil Nouns DAO eth balance in wei
    uint currentNouns = _updateNounHoldings();
    uint updatedLilWeiVal = ((ETHinWeiperNoun * currentNouns) + LilETH) / LilSupply;
    LilTargetPrice = updatedLilWeiVal / 10**16; // to convert to millieth
    return LilTargetPrice;
}

    // function for rough ETH Value of a single NOUN based on Nouns DAO treasury holdings & NOUN totalSupply
    // called in _updateLilValuation

function _updateNounValuation() internal view returns (uint newNounValueinWei) {
    uint nounETH = nounsTreasury.balance; // returns 10 ** 18, NOUN DAO eth balance in WEI?
    uint nounStETH = stETHaddress.balanceOf(nounsTreasury); // returns 10 ** 18, Nouns DAO stETH holdings
    uint nounSupply = NOUNtoken.totalSupply(); // returns decimal = 0, get current NOUN supply
    uint nounValueInWei = (nounETH + nounStETH) / nounSupply; // decimals 10**18
    return nounValueInWei; // decimals 10**18
}

    // called in _updatedLilValuation

function _updateNounHoldings() internal view returns (uint nounsHeld) {
    uint _updatedHoldings = NOUNtoken.balanceOf(LilNounsTreasury); // returns decimal = 0 NOUN qty
    return _updatedHoldings;
}

}