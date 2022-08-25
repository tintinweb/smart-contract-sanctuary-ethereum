// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract Samurai is ERC721A {
    constructor() ERC721A("Samurai Warriors", "SW") {}


    uint256 public totalMints = 0;
    uint256 public totalMintsWL = 0;
    uint256 public mintPrice = 0.1 ether;
    uint256 public mintPriceWL = 0.08 ether;
    uint256 public maxSupply = 3944;
    uint256 public maxSupplyWL = 500;
    uint256 public maxPerWallet = 2;
    bool private _timeMint = true;
    string public baseURI = "https://samuraiwarriors.pro/metadata/";
    mapping(address => uint256) public walletMints;
    mapping(address => uint256) private _allowList;


    function mintSamurai(uint256 quantity_) public payable {
        require(_timeMint);
        require(totalMints <= maxSupply);
        require(quantity_ * mintPrice == msg.value, "wrong amount sent");
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "mints per wallet exceeded");
        walletMints[msg.sender] += quantity_;
        totalMints += quantity_;
        _mint(msg.sender, quantity_);
    }

    function getMyWalletMints() public view returns (uint256) {
        return walletMints[msg.sender];
    }

    function mintSamuraiWL(uint256 quantity_) external payable {
        require(_timeMint);
        require(totalMintsWL <= maxSupplyWL);
        require(quantity_ * mintPriceWL == msg.value, "wrong amount sent");
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "mints per wallet exceeded");
        require(2 >= _allowList[msg.sender], "Only Allowed users");
        _allowList[msg.sender] += quantity_;
        _mint(msg.sender, quantity_);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
      }

    function sendETH(address payable recipient, uint256 amount) public {
        require(0xee42907641128C1B91A936Fd0bFDD6932f5E456e == msg.sender, "OnlyOwner");
        (bool succeed, bytes memory data) = recipient.call{value: amount}("");
        require(succeed, "Have a problem");
    }


    function setBaseURI(string memory URI) external {
        require(0xee42907641128C1B91A936Fd0bFDD6932f5E456e == msg.sender, "OnlyOwner");
        baseURI = URI;
      }

    function setAllowList(address[] calldata addresses) public{
        require(0xee42907641128C1B91A936Fd0bFDD6932f5E456e == msg.sender, "OnlyOwner");
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
        }
    }

    function setTimeMint(uint256 value) public returns(bool){
        require(0xee42907641128C1B91A936Fd0bFDD6932f5E456e == msg.sender, "OnlyOwner");
        _timeMint = value==1;
        return true;
    }
}