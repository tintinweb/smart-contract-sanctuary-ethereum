// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";

/**
 * @dev Contract module defining the ERC721 NFT Token.
 * There is a total supply of N tokens to be minted, each unit costs ETH.
 * some are reserved for presale and promo purposes.
 */
contract AndreyWeb3MintGas is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string _baseTokenURI;
    uint256 public _cardPrice = 5000000000000000;   // .005 ETH
    bool public _saleIsActive = true;
    // Reserve units for team - Giveaways/Prizes/Presales etc
    uint public _cardReserve = 5;
    uint public _mainCardCnt = 100;

    constructor(string memory baseURI) ERC721("AndreyWeb3 Mint Gas Test", "AW3MG") {
        setBaseURI(baseURI);
    }

    function totalSupply() public override view returns (uint256) {
        return supply.current();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /** 
     * Mint a number of cards straight in target wallet.
     * @param _to: The target wallet address, make sure it's the correct wallet.
     * @param _numberOfTokens: The number of tokens to mint.
     * @dev This function can only be called by the contract owner as it is a free mint.
     */
    function mintFreeCards(address _to, uint _numberOfTokens) public onlyOwner {
        uint currSupply = supply.current();
        require(_numberOfTokens <= _cardReserve, "Not enough cards left in reserve");
        require(currSupply >= _mainCardCnt);
        require(currSupply + _numberOfTokens <= _mainCardCnt + _cardReserve, "Purchase would exceed max supply of cards");
        _mintLoop(_to, _numberOfTokens);
        _cardReserve -= _numberOfTokens;
    }
    /** 
     * Mint a number of cards straight in the caller's wallet.
     * @param _numberOfTokens: The number of tokens to mint.
     */
    function mintCard(uint _numberOfTokens) public payable {
        require(_saleIsActive, "Sale must be active to mint a Card");
        require(_numberOfTokens < 6, "Can only mint 5 tokens at a time");
        require(supply.current() + _numberOfTokens <= _mainCardCnt, "Purchase would exceed max supply of cards");
        require(msg.value >= _cardPrice * _numberOfTokens, "Ether value sent is not correct");
        _mintLoop(msg.sender, _numberOfTokens);
    }

    function _mintLoop(address _receiver, uint256 _numberOfTokens) internal {
        for(uint256 i = 0; i < _numberOfTokens; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }
    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    // Might wanna adjust price later on.
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _cardPrice = _newPrice;
    }
    
    function getBaseURI() public view returns(string memory) {
        return _baseTokenURI;
    }
    function getPrice() public view returns(uint256){
        return _cardPrice;
    }
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }
}