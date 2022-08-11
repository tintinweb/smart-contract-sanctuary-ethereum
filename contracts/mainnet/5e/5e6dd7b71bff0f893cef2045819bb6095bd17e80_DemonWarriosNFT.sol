// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract DemonWarriosNFT is ERC721A, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;
    error freeMintIsOver();

    uint256 public freeItems = 5;
    uint256 public maxBuyLimit = 10;
    uint256 public maxSupply = 1000;
    uint256 public freeMintMax = 555;
    uint256 public price = 0.002 ether;

    bool public paused = false;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmZnxgVrdJ44McX83eZVoUQYkvNiQDkm6q4VoZhYFcFQWx/";
    string public constant baseExtension = ".json";

    constructor() ERC721A("Demon Warriors", "DW Baliverse") {
        _safeMint(msg.sender, 10);
    }

    function freeMint() external payable {
        address _caller = _msgSender();
        if(!isFreeMint()) revert freeMintIsOver();
        require(!paused, "Contract Paused.");
        require(maxSupply >= totalSupply() + 1, "Minting exceed maxSupply.");
        require(freeItems >= uint256(_getAux(_caller)) + 5, "Mint exceed freeItems.");

        _setAux(_caller, 5);
        _safeMint(_caller, 5);
    }

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Contract Paused.");
        require(maxSupply >= totalSupply() + _amount, "Minting exceed maxSupply.");
        require(_amount > 0, "Must mint at least one token.");
        require(maxBuyLimit >= _amount , "Must mint less than maxBuyLimit.");
        require(_amount * price == msg.value, "Insufficient value.");

        _safeMint(_caller, _amount);
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
        require(success, "Failed to withdraw");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance!");
        
        _withdraw(_msgSender(), address(this).balance);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function togglePaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setFreeItems(uint256 _newFreeItems) public onlyOwner {
        freeItems = _newFreeItems;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setItems(uint256 _max) public onlyOwner {
        maxSupply = _max;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI does not exist.");
        return bytes(baseURI).length > 0 ? string( abi.encodePacked( baseURI, Strings.toString(_tokenId), baseExtension)) : "";
    }
}