// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract Tatols is Ownable, ERC721A, ReentrancyGuard {

    using Address for address;

    uint256 constant private _allowlistSize = 1000;
    uint256 constant private _auctionSize = 9000;

    uint256 constant private _collectionSize = _allowlistSize + _auctionSize;
    uint256 constant private _maxBatchSize = 20;

    uint256 public allowlistCurrentIndex = 1;
    uint256 public auctionCurrentIndex = _allowlistSize + 1;

    address public immutable recipient;

    struct SaleConfig {
        uint32 startTime;
        uint32 endTime;
        uint256 mintPrice;
    }
    SaleConfig public saleConfig;

    mapping(address => uint256) public allowlist;

    string private _baseTokenURI;

    constructor() ERC721A("Tatols","TATOLS",_maxBatchSize,_collectionSize) {
        saleConfig = SaleConfig(1650456000, 1650715200, 0.025 * 10 ** 18);
        recipient = 0x6fD4409Bdefb6FF9ce3c7f34F5EBC2Be5Ca4349c;
        //Need explicit id starting with 'auctionCurrentIndex'
        nextOwnerToExplicitlySet = auctionCurrentIndex;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Tatols: The caller is another contract");
        _;
    }

    modifier checkTime() {
        require(
            block.timestamp >= uint256(saleConfig.startTime) &&
            block.timestamp <= uint256(saleConfig.endTime), 
            "Tatols: Out of sale time");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupplyOfAuction() + totalSupplyOfAllowlist();
    }

    function allTotalSupply() public view returns (uint256, uint256) {
        return (totalSupplyOfAuction(),totalSupplyOfAllowlist());
    }

    function totalSupplyOfAuction() internal view returns(uint256) {
        return auctionCurrentIndex - _allowlistSize - 1;
    }

    function totalSupplyOfAllowlist() internal view returns(uint256) {
        return allowlistCurrentIndex - 1;
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return 
            (tokenId > 0 && tokenId <= _allowlistSize && tokenId < allowlistCurrentIndex) ||
            (tokenId > _allowlistSize && tokenId < auctionCurrentIndex);
    }

    function _safeMint(address to, uint256 quantity, uint256 startTokenId) internal {
        _safeMint(to, quantity, startTokenId, "");
    }

    function _safeMint(address to, uint256 quantity, uint256 startTokenId, bytes memory _data) internal {
        require(to != address(0), "ERC721A: mint to the zero address");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "ERC721A: token already minted");
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );

        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;
        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );
            updatedIndex++;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function auctionMint(uint256 quantity) external payable callerIsUser checkTime {
        require(
            totalSupplyOfAuction() + quantity <= _auctionSize,
            "Tatols: not enough remaining reserved for auction to support desired mint amount");
        
        uint256 totalCost = uint256(saleConfig.mintPrice) * quantity;
        _safeMint(msg.sender, quantity, auctionCurrentIndex);
        auctionCurrentIndex += quantity;
        refundIfOver(totalCost);
        
        payable(recipient).transfer(totalCost);
    }

    function allowlistMint() external payable callerIsUser checkTime {
        require(allowlist[msg.sender] > 0, "Tatols: not eligible for allowlist mint");
        require(totalSupplyOfAllowlist() + 1 <= _allowlistSize, "Tatols: reached max supply");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1, allowlistCurrentIndex);
        allowlistCurrentIndex ++;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Tatols: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length,"Tatols: addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function setSaleInfo(uint32 startTime, uint32 endTime, uint256 mintPrice) external onlyOwner {
        saleConfig = SaleConfig(startTime, endTime, mintPrice);
    }

    function setSaleTime(uint32 startTime, uint32 endTime) external onlyOwner {
        saleConfig.startTime = startTime;
        saleConfig.endTime = endTime;
    }

    function getSaleTime() external view returns(uint256,uint256) {
        return (saleConfig.startTime, saleConfig.endTime);
    }

    function setSaleMintPrice(uint256 mintPrice) external onlyOwner {
        saleConfig.mintPrice = mintPrice;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        Address.sendValue(payable(recipient), address(this).balance);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function devAllowlistMint(uint256 quantity) external onlyOwner {
        require(
            totalSupplyOfAllowlist() + quantity <= _allowlistSize, 
            "Tatols: not enough remaining reserved for auction to support desired mint amount");
        
        require(
            quantity % maxBatchSize == 0,
            "Tatols: can only mint a multiple of the maxBatchSize");

        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize, allowlistCurrentIndex);
            allowlistCurrentIndex += maxBatchSize;
        }
    }

    function devAuctionMint(uint256 quantity) external onlyOwner {
        require(
            totalSupplyOfAuction() + quantity <= _auctionSize, 
            "Tatols: not enough remaining reserved for auction to support desired mint amount");
        
        require(
            quantity % maxBatchSize == 0,
            "Tatols: can only mint a multiple of the maxBatchSize");
        
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize, auctionCurrentIndex);
            auctionCurrentIndex += maxBatchSize;
        }
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
    
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function getAllowlistQuantity(address account) external view returns(uint256) {
        return allowlist[account];
    }
}