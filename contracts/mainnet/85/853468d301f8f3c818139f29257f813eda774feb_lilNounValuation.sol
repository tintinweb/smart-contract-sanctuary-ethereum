/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// version 3 of lilNouns Valuation Tool by tlogs.eth
// added 'Ownable' functionality to control treasury assets added 

// SPDX-License-Identifier: MIT

// **IMPORTANT** V3 ONLY WORKS FOR ETH WRAPPER TOKENS, NOT ALL ERC-20S, AS THERE IS NO ORACLE FUNCTIONALITY

pragma solidity ^0.8.17;

// for use in ownable

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ownable capabilities to restrict addition of treasury assets

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



// partial interface for reading balances of NOUN & LILNOUN ERC-20 treasury assets

interface PartialIERC20 {

function balanceOf(address account) external view returns (uint256);

}

// partial interface for reading token balances & total supply of NOUN & LILNOUNs & ERC-721 treasury assets

interface PartialIERC721 {

function totalSupply() external view returns (uint256);

function balanceOf(address owner) external view returns (uint256 balance);

}

contract lilNounValuation is Ownable {

// STATE VARIABLES

    // Nouns DAO 

PartialIERC721 public NOUNtoken; // NOUN token interface
address public nounsTreasury; // address holding Nouns DAO ETH
uint public NOUNholdings; // number of NOUNS held by Lil Nouns Treasury
uint public ETHvalueOfNOUNsInLILtreasury; // ETH value of NOUNs held in LIL treasury based on NBV
uint public NOUNvalueInETH; // added variable for valuation of a single NOUN in wei.

    // Lil Nouns DAO 

PartialIERC721 public LilNounsToken; // interface for Lil totalSupply
address public LilNounsTreasury; // Lil Nouns Treasury Address with assets to value
uint public LilTargetPrice;  // in wei, for use as Target Price in other Lil contracts
uint public circulatingLILs; // denominator in final LIL valuation, factors in burns

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

function addWrappedETHtoken(string memory tokenID, address addETHwrapper) external onlyOwner {
    uint256 tokenIndex = ETHwrapperTokenAddresses.length;
    ETHwrapperTokenAddresses.push(addETHwrapper); // give each token an uint ID 
    ETHwrapperToken storage p = ETHwrapperTokenIndex[tokenIndex];
    p.tokenSymbol = tokenID;  // set the token ID for the ETH wrapper
    p.tokenAddress = addETHwrapper; // set the token address for the ETH wrapper
}

// INTERNAL VIEW FUNCTIONS

function _updateLilTargetPrice() internal returns (uint newLilTargetPrice) {
    uint ETHinWeiperNoun = _updateNounValuation(); // returns 10**18 nounValueInWei
    circulatingLILs = LilNounsToken.totalSupply() - LilNounsToken.balanceOf(0x0000000000000000000000000000000000000000); // decimals 0, factor in LIL burns
    uint LilETH = LilNounsTreasury.balance; // returns 10**18 Lil Nouns DAO eth balance in wei
    uint currentNouns = _updateNounHoldings();
    uint updatedLilWeiVal = ((ETHinWeiperNoun * currentNouns) + LilETH) / circulatingLILs;
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
    ETHvalueOfNOUNsInLILtreasury = NOUNvalueInETH * NOUNholdings;
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