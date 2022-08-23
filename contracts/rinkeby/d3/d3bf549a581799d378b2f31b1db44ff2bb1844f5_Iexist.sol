// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";

contract Iexist is ERC721, Pausable, Ownable{

    string private BaseURI;
    uint public TotalMaxSupply = 220;
    uint public MaxPublic = 40;
    uint public TokenCounter;
    uint public PublicCounter;
    uint public Price;
    uint[] public Prices = [0.08 ether, 0.1 ether, 0.2 ether];
    // bool public Whitelist = true;
    mapping(address => uint) private MapMint;
    mapping(address => uint) private MapWhiteList;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint _price) ERC721(_tokenName, _tokenSymbol) {
        selectPrice(_price);
        pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }

    function setBaseURI(string memory _BaseURI) public onlyOwner {
        BaseURI = _BaseURI;
    }

    // function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    //     require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     return string(
    //         abi.encodePacked(BaseURI, Strings.toString(_tokenId), ".json"
    //         )
    //     );
    // }

    function whiteListMint() public payable {

        require(MapWhiteList[msg.sender] == 1, "you do not have a white list");
        require(TokenCounter < TotalMaxSupply, "reached max supply");
        require(Price <= msg.value, "insufficient funds");
        require(MapMint[msg.sender] == 0, "only one opportunity is allowed for wallet");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        saveInfo(msg.sender, 1);
    }

    function publicMint() public payable whenNotPaused {
        require(PublicCounter < MaxPublic, "reached max supply");
        require(Price <= msg.value, "insufficient funds");
        require(MapMint[msg.sender] == 0, "only one opportunity is allowed for wallet");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        saveInfo(msg.sender, 1);
        PublicCounter = PublicCounter + 1;
    }

    function airdrop(address _wallet, uint _amount) public onlyOwner{
        for (uint256 i = 0; i < _amount; i++) {
            require(TokenCounter < TotalMaxSupply, "reached max supply");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_wallet, tokenId);
            saveInfo(_wallet, 1);
        }        
    }

    function saveInfo(address _wallet, uint _count) internal{
        MapMint[_wallet] = 1;
        TokenCounter = TokenCounter + _count;
    }

    function selectPrice(uint _index) public onlyOwner{
        Price = Prices[_index];
    }

    function addWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            MapWhiteList[addresses[i]] = 1;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getBalance() public view onlyOwner returns(uint) {
      return address(this).balance; 
    }

    function withdraw() public onlyOwner {
      uint Percent = address(this).balance / 1000; 
      address payable wallet1 = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
      address payable wallet2 = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
      
      wallet1.transfer(Percent*300);  
      wallet2.transfer(Percent*700);      
    }

}