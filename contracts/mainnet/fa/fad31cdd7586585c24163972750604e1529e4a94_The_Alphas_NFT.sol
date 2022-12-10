// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creators: Chiru Labs

pragma solidity ^0.8.17;

import './ERC721A.sol';
import './Ownable.sol';
import './AggregatorV3Interface.sol';
import {UpdatableOperatorFilterer} from './UpdatableOperatorFilterer.sol';
import {RevokableDefaultOperatorFilterer} from './RevokableDefaultOperatorFilterer.sol';

contract The_Alphas_NFT is ERC721A, Ownable, RevokableDefaultOperatorFilterer {

    string  public              baseURI;
    string  public              provenance;
    bool    public              isReveal            = false;
    
    address payable public      payee1              = payable(0x2d197b021DA9Ae657Ebad44126b0C94eCE03F609); //485
    address payable public      payee2              = payable(0x0Fd6A2b5c2EcBD911b42770D89F4EC2475bCE864); //500
    address payable public      payee3              = payable(0x9025F0De302c257B9841EeE863C1577bA9f788B7); //15

    uint256 public              saleStatus          = 0; // 0 closed, 1 AL, 2 PUBLIC
    uint256 public constant     MAX_SUPPLY          = 10000;
    uint256 public              MAX_GIVEAWAY        = 508;

    uint256 public constant     MAX_PER_TX          = 5;
    uint256 public              alPriceInUSD        = 444; // 444
    uint256 public              publicPriceInUSD    = 888; // 888

    AggregatorV3Interface internal priceFeed;

    mapping(address => uint) public addressToMinted;

    constructor(string memory _baseURI) ERC721A('THE_ALPHAS', 'ALPHAS_NFT') {
        baseURI = _baseURI;
        // Goerli: ETH/USD: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    // gets _amount in USd in gwei
    function getPriceRate(uint _amount) public view returns (uint) {
        (, int price,,,) = priceFeed.latestRoundData();
        uint adjust_price = uint(price) * 1e10;
        uint usd = _amount * 1e18;
        uint rate = (usd * 1e18) / adjust_price;
        return rate;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setAlPriceInUSD (uint256 _newPrice) public onlyOwner {
        alPriceInUSD = _newPrice;
    }

    function setPublicPriceInUSD (uint256 _newPrice) public onlyOwner {
        publicPriceInUSD = _newPrice;
    }

    function setReveal(bool _isReveal) public onlyOwner {
        isReveal = _isReveal;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function addAllowlist(address[] calldata addressList) external onlyOwner {
        for (uint i = 0; i < addressList.length; i++) {
            addressToMinted[addressList[i]] = 1;
        }
    }

    function setSaleStatus(uint256 _status) external onlyOwner {
        require(saleStatus < 3 && saleStatus >= 0, "Invalid status.");
        saleStatus = _status;
    }

    function allowlistMint() public payable {
        require(saleStatus == 1, "Sale is not active.");
        require(totalMinted() + 1 <= MAX_SUPPLY, "Exceeds max supply.");
        require(addressToMinted[msg.sender] == 1, "Not on allowlist or allowlist already minted.");
        require(msg.value >= getPriceRate(alPriceInUSD), "Not enough ETH sent.");
        addressToMinted[msg.sender] = 0;
        _safeMint(msg.sender, 1, "");
    }

    function mint(uint256 _qty) public payable {
        require(totalMinted() + _qty <= MAX_SUPPLY, "Excedes max supply.");
        require(_qty <= MAX_PER_TX, "Exceeds max per transaction.");
        require(saleStatus == 2, "Public sale not started.");
        require(msg.value >= getPriceRate(publicPriceInUSD * _qty), "Not enough ETH sent.");
        _safeMint(msg.sender, _qty, "");
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        require(totalMinted() + _qty <= MAX_SUPPLY, "Exceeds max supply");
        _safeMint(_to, _qty, "");
        MAX_GIVEAWAY -= _qty;
    }

    function withdraw() public  {
        uint value1 = address(this).balance * 485 / 1000;
        uint value2 = address(this).balance * 500 / 1000;
        uint value3 = address(this).balance * 15 / 1000;
        (bool success1, ) = payee1.call{value: value1}("");
        (bool success2, ) = payee2.call{value: value2}("");
        (bool success3, ) = payee3.call{value: value3}("");
        require(success1, "Failed to send to payee.");
        require(success2, "Failed to send to payee.");
        require(success3, "Failed to send to payee.");
    }


    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        if (isReveal) {
            return string(abi.encodePacked(baseURI, toString(_tokenId), ".json"));
        } 
        else {
            return string(abi.encodePacked(baseURI, "unrevealed.json"));
        }
    }


    // 721A standard functions below //
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getAux(address _owner) public view returns (uint64) {
        return _getAux(_owner);
    }

    function setAux(address _owner, uint64 aux) public {
        _setAux(_owner, aux);
    }

    function directApprove(address to, uint256 tokenId) public {
        _approve(to, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function toString(uint256 x) public pure returns (string memory) {
        return _toString(x);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function initializeOwnershipAt(uint256 index) public {
        _initializeOwnershipAt(index);
    }


    // Opensea revokable registry functions below //
        function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public  payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    // end opensea revokable registery functions //
}