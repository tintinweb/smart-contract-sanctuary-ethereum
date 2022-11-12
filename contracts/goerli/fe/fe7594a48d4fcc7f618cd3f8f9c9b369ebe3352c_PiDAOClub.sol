// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract PiDAOClub is ERC721A, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public cost = 0.0025 ether;
    uint256 public maxMintAmount = 20;
    uint256 public maxPerTxFree = 5;
    uint256 public maxSupply = 3000;
    uint256 public freeMintAmount = 2000;
    bool public paused = true;

    string public constant baseExtension = ".json";
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmVMYND2hkx9LhZ4m7iEeMpTzfjTrVPTZ6him3X4UUXUG5/";
    
    error freeMintIsOver();

    constructor() ERC721A("Pi DAO Club", "Pi NFT") {}

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Contract Paused.");
        require(maxSupply >= totalSupply() + _amount, "Minting would exceed maxSupply.");
        require(_amount > 0, "Must mint at least one token.");
        require(maxMintAmount >= _amount , "Must mint less than maxMintAmount.");
        
        if(freeMintAmount >= totalSupply()){
            require(maxPerTxFree >= _amount , "Minting would exceed maxPerTxFree.");
        }else{
            require(maxMintAmount >= _amount , "Minting would exceed maxMintAmount.");
            require(_amount * cost == msg.value, "Insufficient value.");
        }
        _safeMint(_caller, _amount);
    }
    
    function devMint(uint256 _number) external onlyOwner {
        require(totalSupply() + _number <= maxSupply, "Minting would exceed maxSupply.");
        _safeMint(_msgSender(), _number);
    }

    function setMaxFreeMint(uint256 _max) public onlyOwner {
        freeMintAmount = _max;
    }

    function setMaxPaidPerTx(uint256 _max) public onlyOwner {
        maxMintAmount = _max;
    }

    function setMaxFreePerTx(uint256 _max) public onlyOwner {
        maxPerTxFree = _max;
    }

    function setMaxSupply(uint256 _max) public onlyOwner {
        maxSupply = _max;
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

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        
        _withdraw(_msgSender(), address(this).balance);
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
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