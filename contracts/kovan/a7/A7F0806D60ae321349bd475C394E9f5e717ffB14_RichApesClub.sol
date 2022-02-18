// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";

interface IExternalContract {
    function balanceOf(address owner) external view returns (uint256);
}

contract RichApesClub is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // interaction with external contract
    address externalContractAddress; // hardcoded, from constructor or set by method?

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

        if ( externalBalanceOf(msg.sender) > 0 && balanceOf(msg.sender) == 0 ) {
            require(msg.value >= price * (_amount - 1) , "value sent is not correct");
        } else {
            require(msg.value >= price * _amount , "value sent is not correct");
        }

       _safeMint(_msgSender(), _amount);
    }

    // new set baseURI method
    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    // ------------------------------------
    // rest

    uint256 public maxMintSupply = 10000;
    uint256 public limitPerWallet = 30;

    string public baseURI;

    bool public publicState = true;

    uint256 immutable price = 100000000000000000; //0.1 ETH

    uint256[] private _teamShares = [100];

    address[] private _team = [
        0x9530EcAaF1A01Ad6034e5aA6a36B06a6b8a103bf
    ];

    constructor()
        ERC721A("RichApesClub", "RAC", limitPerWallet, maxMintSupply)
        PaymentSplitter(_team, _teamShares) {
        _transferOwnership(_team[0]);
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