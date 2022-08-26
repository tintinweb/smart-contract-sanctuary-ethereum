/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.15;

// Works functionally. We're using wrapped erc-20 coins of the chain. Only deploy this using owner address!
// Make sure that the quoteContracts and baseContracts don't have the same

// Contract address on Rinkeby: 

// UNI on rinkeby: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, USDC on rinkeby: 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b, WETH on rinkeby: 0xc778417e063141139fce010982780140aa0cd5ab, 

// Any base contract can be traded using the contract. If it's taxable or wrong coin, we just don't show it in our books! 

contract pairs {
    // The quote contract MUST include the nativeWrappedContract, along with the stables. 
    
    mapping(address => string) public allQuotes;
    address[] private allowedQuoteContracts;
    address private nativeWrappedContract;
    
    address public owner;
    
    constructor(address _nativeWrappedContract, string memory _nativeWrappedContractSymbol) {
        owner = msg.sender;
        nativeWrappedContract = _nativeWrappedContract;
        allowedQuoteContracts.push(nativeWrappedContract);
        allQuotes[nativeWrappedContract] = _nativeWrappedContractSymbol;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == address(this));
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event QuoteAdded(address indexed quoteAddress, string indexed quoteName);
    event QuoteDeleted(address indexed deletedAddress);

    function addNewQuotePair(string memory _coinName, address _quoteContract) external onlyOwner {
        // Add it to the mapping
        allQuotes[_quoteContract] = _coinName;
        allowedQuoteContracts.push(_quoteContract);
        emit QuoteAdded(_quoteContract, _coinName);
    }

    function deleteQuotePair(address _quoteContract, uint256 _keyOfQuoteCoinBase0) external onlyOwner {
        delete allQuotes[_quoteContract];
        delete allowedQuoteContracts[_keyOfQuoteCoinBase0];
        emit QuoteDeleted(_quoteContract);
    }

    function getQuoteContracts() public view returns(address[] memory) {
        return allowedQuoteContracts;
    }

    function getNativeWrappedContract() public view returns(address) {
        return nativeWrappedContract;
    }

    function totalQuoteCoins() public view returns(uint256) {
        return allowedQuoteContracts.length;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
}