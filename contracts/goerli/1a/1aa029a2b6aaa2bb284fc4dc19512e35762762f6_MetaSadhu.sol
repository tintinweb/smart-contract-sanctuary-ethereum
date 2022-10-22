// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title MetaSadhu
 */
contract MetaSadhu is ERC721, Ownable {
    using Strings for uint256;

    uint256 public _cardPrice = 10800000000000000;   // 0,0108 ETH
    bool public _saleIsActive = true;
    // Reserve units for team - Giveaways/Prizes/Presales etc
    uint public _cardReserve = 1000;
    uint public _mainCardCnt = 8108;
    // Reveal settings
    bool public _isRevealed = false;
    string private _hiddenURI;
    string private _baseTokenURI;
    // Set owners
    address payable private _teamAddress;
    address payable private _investorAddress;
    uint16 private _investorShare;
    uint256 private _maxInvestorWithdraw;

    constructor(string memory hiddenURI, address payable teamAddress, address payable investorAddress, 
        uint16 investorShare, uint256 maxInvestorWithdraw) 
        ERC721("Meta Sadhu", "SADHU") {
        setHiddenMetaURI(hiddenURI);
        _teamAddress = teamAddress;
        _investorAddress = investorAddress;
        _investorShare = investorShare;
        _maxInvestorWithdraw = maxInvestorWithdraw;
    }

    function withdrawShares() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 investorSend = _maxInvestorWithdraw <= balance ? _maxInvestorWithdraw : balance;
        if (investorSend > 0) {
            _maxInvestorWithdraw -= investorSend;
        }
        investorSend += uint256((balance - investorSend) * _investorShare / 100);
        (bool invs, ) = _investorAddress.call{value: investorSend}('');
        require(invs);
        
        (bool ts, ) = _teamAddress.call{value: address(this).balance}('');
        require(ts);
    }
    /** 
     * Mint a number of cards straight in target wallet.
     * @param _to: The target wallet address, make sure it's the correct wallet.
     * @param _numberOfTokens: The number of tokens to mint.
     * @dev This function can only be called by the contract owner as it is a free mint.
     */
    function mintFree(address _to, uint _numberOfTokens) public onlyOwner {
        uint supply = totalSupply();
        require(_numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(_numberOfTokens <= _cardReserve, "Not enough cards left in reserve");
        require(supply + _numberOfTokens <= _mainCardCnt, "Purchase would exceed max supply of cards");
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = supply + i;
            _safeMint(_to, mintIndex);
        }
        _cardReserve -= _numberOfTokens;
    }
    /** 
     * Mint a number of cards straight in the caller's wallet.
     * @param _numberOfTokens: The number of tokens to mint.
     */
    function mint(uint _numberOfTokens) public payable {
        uint supply = totalSupply();
        require(_saleIsActive, "Sale must be active to mint a Card");
        require(_numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(supply + _numberOfTokens <= _mainCardCnt, "Purchase would exceed max supply of cards");
        require(msg.value >= _cardPrice * _numberOfTokens, "Ether value sent is not correct");
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = supply + i;
            _safeMint(msg.sender, mintIndex);
        }
    }
    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    // Might wanna adjust price later on.
    function setPrice(uint256 _newPrice) public onlyOwner {
        _cardPrice = _newPrice;
    }
    function getPrice() public view returns(uint256){
        return _cardPrice;
    }
    
    function getBaseURI() public onlyOwner view returns(string memory) {
        return _baseTokenURI;
    }
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        if (!_isRevealed) {
            return _hiddenURI;
        }
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
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
    function setCardCnt(uint _cnt) public onlyOwner() {
        require(totalSupply() <= _cnt, "Cant set count less than current cnt");
        _mainCardCnt = _cnt;
    }

    function setHiddenMetaURI(string memory hiddenURI) public onlyOwner {
        _hiddenURI = hiddenURI;
    }
    function getHiddenMeteURI() public view returns(string memory) {
        return _hiddenURI;
    }
    function flipReveal() public onlyOwner {
        _isRevealed = !_isRevealed;
    }
}