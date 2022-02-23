// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ITeste_2.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract teste_11 is ERC721A, Ownable {
    using Strings for uint256; 
    using SafeMath for uint256;

    string public baseURI;  //the base uri --> link do IPFS
    uint256 public publicCost = 0.02 ether;   
    uint256 public preCost = 0.02 ether;  
    uint256 public maxSupply;
    uint256 public maxPreSupply;
    uint256 public maxBabyMallows;

    uint256 public maxPublicMintAmount = 10;  
    uint256 public maxPreMintAmount = 5;

    bool public paused = false;
    uint8 public saleState = 0;
    uint8 public airdropsNumber = 0;
    address[] public whiteListed;

    address public partner1;
    address public partner2;
    address public partner3;
    address public partner4;

    ITeste_2 public Iteste_2;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _maxPreSupply,
        uint256 _maxSupply,
        uint8 _airdropsNumber,
        address _partner1,
        address _partner2,
        address _partner3,
        address _partner4
    ) ERC721A(_name, _symbol){  
        setBaseURI(_initBaseURI);
        maxPreSupply = _maxPreSupply;
        maxSupply = _maxSupply;
        airdropsNumber = _airdropsNumber;
        partner1 = _partner1;
        partner2 = _partner2;
        partner3 = _partner3;
        partner4 = _partner4;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, token_id.toString())) : "";
    }
    function mint(uint256 _mintAmount) external payable{ 
        require(!paused);
        require(saleState==1 || saleState==2, "Mint not available"); 
        require(_mintAmount > 0);
        if(saleState == 1){   //presale
            require(isWhiteListed(msg.sender), "Address not whiteListed");
            require(_mintAmount <= maxPreMintAmount, "Exceeded mint amount");
            require(numberMinted(msg.sender) + _mintAmount <= maxPreMintAmount, "Cannot mint more");
            require(totalSupply() + _mintAmount <= maxPreSupply, "PreSale sold out"); 
            require(msg.value >= (preCost * _mintAmount), "Not enough ether to mint"); 
        }  
        if(saleState == 2){   //public
            require(_mintAmount <= maxPublicMintAmount, "Exceeded mint amount"); 
            require((totalSupply() + _mintAmount) <= maxSupply, "Metamallows sold out"); 
            require(msg.value >= (publicCost * _mintAmount), "Not enough ether to mint");
        }
        _safeMint(msg.sender, _mintAmount);
    }
    function airdrops(address[] calldata _airdropWallets) public onlyOwner(){
        require(_airdropWallets.length == airdropsNumber, "Number of airdrops not corresponding");
        uint256 supply = maxSupply + 1;
        for (uint i =0; i < _airdropWallets.length; i++) {
            _safeMint(_airdropWallets[i], supply + i);
        }

    }
    function updateMaxPreSupply(uint256 _newMaxPreSupply) public onlyOwner(){
        require(_newMaxPreSupply <=maxSupply, "PreSupply cannot be greater than the total supply");
        maxPreSupply = _newMaxPreSupply;
    }
    function setDependeciesAddresses(address _teste_2Address) public onlyOwner{
        Iteste_2 = ITeste_2(_teste_2Address);
    }
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
        return ownershipOf(tokenId);
    }
    function isWhiteListed(address _wallet) public view returns (bool) {
        for (uint i = 0; i < whiteListed.length; i++) {
            if (whiteListed[i] == _wallet) {
                return true;
            }
        }
        return false;
    }
    function setWhiteLists(address[] calldata _whiteListedWallets) public onlyOwner(){
        delete whiteListed;
        whiteListed = _whiteListedWallets;
    }
    function setSale(uint8 _saleState) public onlyOwner(){
        /*
        0 - inactive
        1 - presale
        2 - public
        */
        require(_saleState>=0 && _saleState<=2, "Value not in range. Must be between 0 and 2");
        saleState = _saleState;
    }
    /*function setPreSale(bool _activate) public onlyOwner(){
        preSale = _activate;
    }
    function setPublicSale(bool _activate) public onlyOwner(){
        publicSale = _activate;
    }*/
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }
    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner(){
        maxPublicMintAmount = _newmaxMintAmount;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner(){
        baseURI = _newBaseURI;
    }
    function pause(bool _state) public onlyOwner(){
        paused = _state;
    }
    function withdrawAll() external onlyOwner(){
        require(address(this).balance > 0, "No balance");
        uint256 contractBalance = address(this).balance;

        (bool w1,) = partner1.call{value: contractBalance.mul(25).div(100)}(""); 
        (bool w2,) = partner2.call{value: contractBalance.mul(25).div(100)}(""); 
        (bool w3,) = partner3.call{value: contractBalance.mul(25).div(100)}(""); 
        (bool w4,) = partner4.call{value: contractBalance.mul(25).div(100)}("");

        require(w1 && w2 && w3 && w4, "Withdraw failed");
    }
    function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
    ) public virtual override{
    // Override the approvals so that users don't have to waste gas approving when staking
    if (_msgSender() != address(Iteste_2)){
      require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
    }
    _transfer(_from, _to, _tokenId);
  }
}