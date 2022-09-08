// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract Iexist is ERC721, Ownable, ERC721Enumerable {

    string private BaseURI;
    uint public TotalMaxSupply = 322;
    uint public MaxPublic = 240;
    uint public Price;
    uint[] public Prices = [0.08 ether, 0.1 ether, 0.2 ether];
    mapping(address => uint) private MapMint;
    mapping(address => uint) private MapWhiteList;
    bool public _WhiteList = false;
    bool public _PublicMint = false;

    event TokenMinted(uint256 Id, address Owner);

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint _price) ERC721(_tokenName, _tokenSymbol) {
        selectPrice(_price);
    }

    modifier PausedWhiteList() {
        require(_WhiteList, "Paused whitelist");
        _;
    }

    modifier PausedPublicMint() {
        require(_PublicMint, "Paused Public Mint");
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }

    function setBaseURI(string memory _BaseURI) public onlyOwner {
        BaseURI = _BaseURI;
    }

    function whiteListMint() public payable PausedWhiteList {
        require(MapWhiteList[msg.sender] == 1, "you do not have a white list");
        require(totalSupply() < TotalMaxSupply, "reached max supply");
        require(Price <= msg.value, "insufficient funds");
        require(MapMint[msg.sender] == 0, "only one opportunity is allowed for wallet");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        saveInfo(msg.sender);
        emit TokenMinted(tokenId, msg.sender);
    }

    function publicMint() public payable PausedPublicMint {
        require(totalSupply() < MaxPublic, "reached max supply");
        require(Price <= msg.value, "insufficient funds");
        require(MapMint[msg.sender] == 0, "only one opportunity is allowed for wallet");
        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        saveInfo(msg.sender);
        emit TokenMinted(tokenId, msg.sender);
    }

    function airdrop(address _wallet, uint _amount) public onlyOwner{
        for (uint256 i = 0; i < _amount; i++) {
            require(totalSupply() < TotalMaxSupply, "reached max supply");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_wallet, tokenId);
        }        
    }

    function saveInfo(address _wallet) internal{
        MapMint[_wallet] = 1;
    }

    function switchWhiteList() public onlyOwner {
        _WhiteList = !_WhiteList;
    }

    function switchPublicMint() public onlyOwner {
        _PublicMint = !_PublicMint;
    }

    function selectPrice(uint _index) public onlyOwner{
        Price = Prices[_index];
    }

    function addWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            MapWhiteList[addresses[i]] = 1;
        }
    }

    function getWhiteList(address _wallet) public view returns(uint){
        return MapWhiteList[_wallet];
    }

    function getBalance() public view onlyOwner returns(uint) {
      return address(this).balance; 
    }

    function withdraw() public onlyOwner {
        uint _balance = address(this).balance; 
        address _wallet1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        payable(_wallet1).transfer(_balance);
    }

    function selectWithdraw(address _wallet, uint _amount) public onlyOwner {
        payable(_wallet).transfer(_amount);
    }

    function getTotalSupply() public view returns(uint){
        return totalSupply();
    }

}