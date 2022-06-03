/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandSale {
    string public name = "Land Sale";

    address public owner;
    address payable public treasury;
    uint256 public mintCost;

    event LandSold(address caller, uint256 nftCount, string tokenType);

    constructor() {
        owner = msg.sender;
        mintCost = 0.016748 ether; // 80 ICX
    }

    function setMintCost(uint256 _mintCost) external {
        mintCost = _mintCost;
    }

    function setTreasury(address payable _treasury) external {
        treasury = _treasury;
    }

    function buyLand(uint256 nftCount) external payable {
        require(
            msg.sender != address(0),
            "Land Sale: Caller is a zero address"
        );

        require(
            msg.value == mintCost * nftCount,
            "Land Sale: Insufficient payment"
        );
        require(treasury != address(0), "Land Sale: Treasury address not set");
        emit LandSold(msg.sender, nftCount, "eth");
    }

    function transferAllToTreasury() external {
        require(msg.sender == owner, "Land Sale: Caller is not the owner");
        treasury.transfer(address(this).balance);
    }
}