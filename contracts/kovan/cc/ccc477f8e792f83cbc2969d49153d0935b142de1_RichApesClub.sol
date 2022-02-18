// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";

interface IExternalContract {
    function balanceOf(address owner) external view returns (uint256);
}

contract RichApesClub is ERC721A, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxMintSupply = 10000;
    uint256 public limitPerWallet = 30;

    string public baseURI;

    bool public publicState = true;

    uint256 immutable price = 77700000000000000; //0.0777 ETH

    // interaction with external contract
    address public externalContractAddress; // hardcoded, from constructor or set by method?

    function setExternalContractAddress(address contractAddress) external onlyOwner {
        externalContractAddress = contractAddress;
    }

    function externalBalanceOf(address owner) internal view returns (uint256) {
        return IExternalContract(externalContractAddress).balanceOf(owner);
    }

    // new mint
    function newMint(uint256 _amount) external payable {
        require(publicState, "mint disabled");
        require(_amount > 0, "zero amount");
        require(_amount <= limitPerWallet, "can't mint so much tokens"); // this is per tx or overall? if overall we need to change to `_amount <= limitPerWallet - balanceOf(msg.sender)`
        require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");
        require(msg.value >= price * _amount , "value sent is not correct");

       _safeMint(_msgSender(), _amount);
    }

    function claim() external payable {
        // add bool claimState and require?
        require(externalBalanceOf(msg.sender) > 0, "nothing to claim");
        require(externalBalanceOf(msg.sender) != balanceOf(msg.sender), "already claimed"); // this is weak, should we store addresses which claimed?
        require(externalBalanceOf(msg.sender) <= limitPerWallet, "can't mint so much tokens"); // this is per tx or overall? if overall we need to change to `externalBalanceOf(msg.sender) <= limitPerWallet - balanceOf(msg.sender)`
        require(totalSupply() + externalBalanceOf(msg.sender) <= maxMintSupply, "max supply exceeded");

        _safeMint(_msgSender(), externalBalanceOf(msg.sender));
    }

    // new set baseURI method
    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    // ------------------------------------
    // rest

    constructor()
        ERC721A("RichApesClub", "RAC", limitPerWallet, maxMintSupply) {
        _transferOwnership(0x9530EcAaF1A01Ad6034e5aA6a36B06a6b8a103bf);
    }

    function enable() public onlyOwner {
        publicState = true;
    }

    function disable() public onlyOwner {
        publicState = false;
    }

    function mint(uint256 _amount) external payable {
        require(publicState, "mint disabled");
        require(_amount > 0, "zero amount");
        require(_amount <= limitPerWallet, "can't mint so much tokens");
        require(totalSupply() + _amount <= maxMintSupply, "max supply exceeded");
        require(msg.value >= price * _amount , "value sent is not correct");

        _safeMint(_msgSender(), _amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}