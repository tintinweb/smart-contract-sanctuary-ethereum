// SPDX-License-Identifier: MIT

// ████████████████████████████████████
// █─▄─▄─█▄─▄▄─█─▄─▄─██─▄▄▀█▄─▄█─▄▄▄▄██
// ███─████─▄█▀███─████─▄─▄██─██▄▄▄▄─██
// ██▄▄▄██▄▄▄▄▄██▄▄▄██▄▄█▄▄█▄▄▄█▄▄▄▄▄██
// █████████████████████████████
// ██─▄▄▄▄██─▄─██▄─▀█▀─▄█▄─▄▄▄██
// ██─██▄─██─▀─███─█▄█─███─▄▄███
// ██▄▄▄▄▄█▄▄█▄▄█▄▄▄█▄▄▄█▄▄▄▄▄██
// ███████████████████████
// ██▄─▀█▄─▄█▄─▄▄▄█─▄─▄─██
// ███─█▄▀─███─▄▄████─████
// ██▄▄▄██▄▄█▄▄▄████▄▄▄███
// ███████████████████████


pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract TetrisGameNFT is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public maxFreePerWallet = 2;
    uint256 public maxPerTx = 10;
    uint256 public maxSupply = 2000;
    uint256 public freeMintMax = 1500;
    uint256 public price = 0.005 ether;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmeHg5KSgwFv1VeMP37EVwEcBJ6gjJJnrTwTzEwirJN3uk/";
    string public constant baseExtension = ".json";

    bool public paused = true;
    error freeMintIsOver();

    constructor() ERC721A("Tetris Game NFT", "TGNFT") {}

    function freeMint() external payable {
        address _caller = _msgSender();
        if(!isFreeMint()) revert freeMintIsOver();
        require(!paused, "Contract Paused.");
        require(maxSupply >= totalSupply() + 2, "Minting would exceed maxSupply.");
        require(maxFreePerWallet >= uint256(_getAux(_caller)) + 2, "Mint would exceed maxFreePerWallet.");

        _setAux(_caller, 2);
        _safeMint(_caller, 2);
    }

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Contract Paused.");
        require(maxSupply >= totalSupply() + _amount, "Minting would exceed maxSupply.");
        require(_amount > 0, "Must mint at least one token.");
        require(maxPerTx >= _amount , "Must mint less than maxPerTx.");
        require(_amount * price == msg.value, "Insufficient value.");

        _safeMint(_caller, _amount);
    }

    function devMint(uint256 _number) external onlyOwner {
        require(totalSupply() + _number <= maxSupply, "Minting would exceed maxSupply");
        _safeMint(_msgSender(), _number);
    }

    function isFreeMint() public view returns (bool) {
        return totalSupply() < freeMintMax;
    }

    function setMaxFreeMint(uint256 _max) public onlyOwner {
        freeMintMax = _max;
    }
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function minted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        
        _withdraw(_msgSender(), address(this).balance);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxFreePerWallet(uint256 _newMaxFreePerWallet) public onlyOwner {
        maxFreePerWallet = _newMaxFreePerWallet;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI does not exist.");
        return bytes(baseURI).length > 0 ? string( abi.encodePacked( baseURI, Strings.toString(_tokenId), baseExtension)) : "";
    }
}