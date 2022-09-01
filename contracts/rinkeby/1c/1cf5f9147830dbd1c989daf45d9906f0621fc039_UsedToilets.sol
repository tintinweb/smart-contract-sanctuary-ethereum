// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract UsedToilets is ERC721A, Ownable {
    using Strings for uint256; 
    using SafeMath for uint256;

    enum State {
        CLOSED,
        PRESALE,
        PUBLIC
    }

    string public baseURI;
   
    uint256 public maxSupply;
    uint256 public maxMintAmount = 2;
    
    address private partners;
    address private signer = 0xeFB45a786C8A9fE6D53DdE0E3A4DB6aF54C73DA7;

    mapping(address => uint256) public nounces;

    State public saleState = State.CLOSED;
    
    constructor (
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        address _partners
    ) ERC721A(_name, _symbol){  
        setBaseURI(_initBaseURI);
        maxSupply = _maxSupply;
        partners = _partners;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, token_id.toString())) : "";
    }

    function presaleMint(uint256 _mintAmount, bytes calldata _signature, uint256 _nounce) external{ 
        require(saleState == State.PRESALE, "PRESALE unavailable"); 
        require(_mintAmount > 0);
        require(ECDSA.recover(keccak256(abi.encodePacked(saleState, msg.sender, _nounce)), _signature) == signer, "Signature Invalid");
        require(numberMinted(msg.sender) + _mintAmount <= maxMintAmount, "Exceeded mint amount");
        require((totalSupply() + _mintAmount) <= maxSupply, "PreSale sold out"); 
        nounces[msg.sender]++;
        _safeMint(msg.sender, _mintAmount); 
    }

    function publicMint(uint256 _mintAmount) external{ 
        require(saleState == State.PUBLIC, "PUBLIC sale unavailable"); 
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount, "Exceeded mint amount"); 
        require((totalSupply() + _mintAmount) <= maxSupply, "Usedtoilets sold out"); 
        _safeMint(msg.sender, _mintAmount); 
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
        return ownershipOf(tokenId);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function airdropsBulk(address[] calldata _airdropWallets, uint256[] calldata _mintAmount) external onlyOwner(){
        require(_airdropWallets.length == _mintAmount.length);
        require((totalSupply() + _airdropWallets.length) <= maxSupply, "Cannot mint more");
        for (uint i =0; i < _airdropWallets.length; i++) {
            _safeMint(_airdropWallets[i], _mintAmount[i]);
        }
    }

    function airdrop(address _airdropWallet, uint256 quantity) external onlyOwner(){
        require((totalSupply() + quantity) <= maxSupply, "Cannot mint more");
        _safeMint(_airdropWallet, quantity);
    }


    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner(){
        maxSupply = _newMaxSupply;
    }

    function setSale(uint8 _saleState) external onlyOwner(){
        saleState = State(_saleState);
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner(){
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner(){
        baseURI = _newBaseURI;
    }

    function withdrawAll() external onlyOwner(){
        require(address(this).balance > 0, "No balance");
        uint256 contractBalance = address(this).balance;

        (bool w1,) = partners.call{value: contractBalance}(""); 

        require(w1, "Withdraw failed");
    }
}