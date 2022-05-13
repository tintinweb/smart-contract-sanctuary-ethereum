// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IERC20Metadata.sol';

contract Transfer {

    mapping(string => address) public tokenList;
    address private owner;
    uint public cost;

    constructor() {
        owner = msg.sender;
    }
    // Add, Remove or Edit token address
    function editToken(string memory _name, address _address) external onlyOwner {
        tokenList[_name] = _address;
    }
    // Setup new price per 1 NFT
    function editCost(uint _amount) external onlyOwner {
        cost = _amount;
    }
    // Transfer money to owner and mint NFT after that.
    // You must approve tokens before for contract address before call this function
    function Pay(string memory _name) external {
        IERC20Metadata token = IERC20Metadata(tokenList[_name]);
        require(
            token.transferFrom(
                msg.sender,
                owner,
                cost * (10 ** token.decimals())
                )
            );
        // **
        // mint NFT
        // ** 
    }

    // Make function affordable only for Owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}