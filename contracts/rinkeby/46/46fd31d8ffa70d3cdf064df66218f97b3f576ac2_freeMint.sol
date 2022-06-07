// SPDX-License-Identifier: GPL-3.0

pragma solidity ^ 0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Owner.sol";
import "./Counters.sol";
import "./Pausable.sol";

contract freeMint is ERC721, Owner, Pausable {

    uint public Max_Tokens = 5555;  
    uint public Max_Purchase = 10;
    uint public Price = 5000000000000000;
    uint public Token_Counter;
    bool public WhiteListActivation = true;
    mapping(address => uint) private mapMint;
    string private BaseURI;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address[] public WhiteList = [0x69248763be858Bee978158a07C73eE4510baEe0E, 0x7CFeaAa9EB06A4Beee4bAB0299200550985e7Cb9];

    constructor(string memory _tokenName, string memory _tokenSymbol) ERC721(_tokenName, _tokenSymbol) {
        pause();
    }

    function setMapMint(address _wallet) private {
        mapMint[_wallet] = 1;
        Token_Counter = Token_Counter + 1;
    }

    function mint(uint _tokens) public payable whenNotPaused {

        require(_tokens <= Max_Purchase, "Can only mint 10 tokens at a time");
        require(Token_Counter < Max_Tokens, "sold out");
        require(mapMint[msg.sender] == 0, "only one opportunity is allowed for wallet");

        if (WhiteListActivation) {
            bool _WhiteList = checkWhiteList(msg.sender);
            require(_WhiteList == true, "you dont have a whitelist spot");
        }

        for (uint i = 1; i <= _tokens; i++) {
                uint256 tokenId = _tokenIdCounter.current();

            if (Token_Counter >= 2000) {
                require(Price * _tokens <= msg.value, "insufficient funds");
            }

            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            setMapMint(msg.sender);
        }
    }

    function setBaseURI(string memory _BaseURI) public isOwner {
        BaseURI = _BaseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override isOwner returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(
            abi.encodePacked(BaseURI, Strings.toString(_tokenId), ".json"
            )
        );
    }

    function checkWhiteList(address _account) public view returns(bool) {

        bool Check = false;

        for (uint i = 0; i < WhiteList.length; i++) {
            if (WhiteList[i] == _account) {
                Check = true;
            }
        }

        return Check;
    }

    function pause() public isOwner {
        _pause();
    }

    function unpause() public isOwner {
        _unpause();
    }

    function getContractBalance() public isOwner view returns(uint) {
        return address(this).balance;
    }

    function withdraw(uint _amount) public isOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        payable(owner).transfer(_amount);
    }

    function switchWhitelist() public isOwner{
        WhiteListActivation = !WhiteListActivation;
    }

}