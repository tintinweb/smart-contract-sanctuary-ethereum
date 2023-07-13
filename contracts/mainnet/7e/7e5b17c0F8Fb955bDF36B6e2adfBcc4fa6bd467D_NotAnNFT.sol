// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract NotAnNFT is ERC20, Ownable {
    constructor() ERC20("Not an NFT", "NaN") {}

    uint256 public maxSupply = 10000 ether;
    uint256 public mintFee = 0.01 ether;
    uint256 public maxPerWallet = 5;
    mapping(address => uint) public addressMintedBalance;


    function mint(uint256 quantity) external payable {
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You can't mint this many.");
        require(totalSupply() + quantity <= maxSupply, "Cannot exceed max supply");
        require(tx.origin == msg.sender, "No contracts!");
        require(msg.value >= mintFee * quantity, "Amount of Ether sent too small");
        _mint(msg.sender, quantity * 1 ether);
        addressMintedBalance[msg.sender] += quantity;
    }

    function withdraw() external {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}