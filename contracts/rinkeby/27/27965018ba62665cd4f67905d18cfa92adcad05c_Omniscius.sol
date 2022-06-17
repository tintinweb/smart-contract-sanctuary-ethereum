// SPDX-License-Identifier: GPL-3.0

pragma solidity ^ 0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Owner.sol";
import "./Counters.sol";
import "./Pausable.sol";

contract Omniscius is ERC721, Owner, Pausable {

    uint public Max_Purchase = 1;
    uint public Max_Tokens = 575;  
    uint public Price;
    uint public Available_Tokens = 100; 
    uint public Token_Counter = 0;
    bool public Whitelist = true;
    string private BaseURI;
    event TokenMinted(uint256 Id, address Owner);
    mapping(address => uint) private mapHolder;
    mapping(address => uint) private mapWhiteList;
    using Counters for Counters.Counter;
        Counters.Counter private _tokenIdCounter;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint _Price) ERC721(_tokenName, _tokenSymbol) {
        parameterizePrice(_Price);
    }

    function setBaseURI(string memory _BaseURI) public isOwner {
        BaseURI = _BaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return BaseURI;
    }

    function pause() public isOwner {
        _pause();
    }

    function unpause() public isOwner {
        _unpause();
    }

    function parameterizePrice(uint _newPrice) public isOwner() {
        Price = _newPrice * (1 wei);
    }

    function addAvailableTokens(uint _number) public isOwner {
        Available_Tokens = Available_Tokens + _number;
    }

    function getContractBalance() public isOwner view returns(uint) {
        return address(this).balance;
    }

    function switchWhitelist() public isOwner{
        Whitelist = !Whitelist;
    }

    function addWhiteList(address[] calldata addresses) external isOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            mapWhiteList[addresses[i]] = 1;
        }
    }

    function getWhiteList(address _address) public view returns(uint){
        return mapWhiteList[_address];
    }

    function saveInfo(address _wallet) private {
        mapHolder[_wallet] = Max_Purchase;
        Token_Counter = Token_Counter + Max_Purchase;
    }

    function mint() public payable whenNotPaused {
        if (Whitelist) {
            require(mapWhiteList[msg.sender] == 1, "you do not have a white list");
        }
        require(Token_Counter < Max_Tokens, "sold out");
        require(Token_Counter < Available_Tokens, "mint suspended");
        require(mapHolder[msg.sender] == 0, "you already have one token");
        require(msg.value == Price, "insufficient funds");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        saveInfo(msg.sender);
        emit TokenMinted(tokenId, msg.sender);
    }

    function forceMint(address _wallet) public isOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_wallet, tokenId);
        Token_Counter = Token_Counter + Max_Purchase;
    }

    function withdraw(uint _amount) public isOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        payable(owner).transfer(_amount);
    }
}