//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SoyCata is ERC721A, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    // Token detail
    struct ArtworkDetail {
        uint256 serie;
    }

    // Events
    event TokenMinted(address owner, uint256 tokenId, uint256 serie);

    // art Detail
    mapping(uint256 => ArtworkDetail) private _artworkDetails;

    // Max amount of token to purchase per account each time
    uint public MAX_PURCHASE = 500;

    // Price for serie 1
    uint256 public PRICE_T1 = 50000000000000000;

    // Price for serie 2
    uint256 public PRICE_T2 = 150000000000000000;

    // Price for serie 3
    uint256 public PRICE_T3 = 250000000000000000;

    // Max tokens for serie 1
    uint256 public TOTAL_TOKENS_T1 = 8000;

    // Max tokens for serie 2
    uint256 public TOTAL_TOKENS_T2 = 6000;

    // Max tokens for serie 3
    uint256 public TOTAL_TOKENS_T3 = 1000;

    // QTY minted tokens for serie 1
    uint256 public QTY_TOKENS_T1 = 0;

    // QTY minted tokens for serie 2
    uint256 public QTY_TOKENS_T2 = 0;

    // QTY minted tokens for serie 3
    uint256 public QTY_TOKENS_T3 = 0;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    string public baseExtension = ".json";

    address private foundationAddress = 0x5789BC64f27f0b55104C07e13458C2B4965CEde8;
    address private mktAddress = 0xC447b807B8e6853d647E13dE9532C601c7034719;
    address private pressAddress = 0xd32aDb61843c326Ed29B5E3dac6919c543CC541E;
    address private devAddress = 0x1f188e7333f3A531214c42a71D8Ffdd9Fb203652;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol, string memory uri) ERC721A(name, symbol) {
        setBaseURI(uri);
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /*
     * Set max purchase
     */
    function setMaxPurchase(uint256 maxPurchase) public onlyOwner {
        MAX_PURCHASE = maxPurchase;
    }

    /**
     * Set token price for serie 1
     */
    function setPriceT1(uint256 price) public onlyOwner {
        PRICE_T1 = price;
    }

    /**
     * Set token price for serie 2
     */
    function setPriceT2(uint256 price) public onlyOwner {
        PRICE_T2 = price;
    }

    /**
     * Set token price for serie 3
     */
    function setPriceT3(uint256 price) public onlyOwner {
        PRICE_T3 = price;
    }

    /**
     * Set total tokens for serie 1
     */
    function setTotalTokensT1(uint256 qty) public onlyOwner {
        TOTAL_TOKENS_T1 = qty;
    }

    /**
     * Set total tokens for serie 2
     */
    function setTotalTokensT2(uint256 qty) public onlyOwner {
        TOTAL_TOKENS_T2 = qty;
    }

    /**
     * Set total tokens for serie 3
     */
    function setTotalTokensT3(uint256 qty) public onlyOwner {
        TOTAL_TOKENS_T3 = qty;
    }

    /**
     * Set qty minted tokens for serie 1
     */
    function setQtyTokensT1(uint256 qty) public onlyOwner {
        QTY_TOKENS_T1 = qty;
    }

    /**
     * Set qty minted tokens for serie 2
     */
    function setQtyTokensT2(uint256 qty) public onlyOwner {
        QTY_TOKENS_T2 = qty;
    }

    /**
     * Set qty minted tokens for serie 3
     */
    function setQtyTokensT3(uint256 qty) public onlyOwner {
        QTY_TOKENS_T3 = qty;
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) onlyOwner public {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    /**
     * Get the token URI with the metadata extension
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    /**
     * Get art detail
     */
    function getArtworkDetail(uint256 tokenId) public view returns(ArtworkDetail memory detail) {
        require(_exists(tokenId), "Token was not minted");

        return _artworkDetails[tokenId];
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
    
        uint balance = address(this).balance;
        uint foundationShare = balance.mul(50).div(100);
        uint mktShare = balance.mul(25).div(100).div(2);
        uint pressShare = mktShare;
        uint devShare = balance.mul(25).div(100);

        (bool success, ) = foundationAddress.call{value: foundationShare}("");
        require(success, "foundationAddress Withdrawal failed");

        (success, ) = mktAddress.call{value: mktShare}("");
        require(success, "mktAddress Withdrawal failed");
                
        (success, ) = pressAddress.call{value: pressShare}("");
        require(success, "pressAddress Withdrawal failed");
                
        (success, ) = devAddress.call{value: devShare}("");
        require(success, "devAddress Withdrawal failed");
    }

    /**
     * Emergency Withdraw
     */
    function withdrawAlt() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Emergency: Set tokens serie.
     */
    function setTokensSerie(uint256 idx, uint256 qtyTokens, uint256 serie) public onlyOwner {
        for (uint i = idx; i < qtyTokens; i++) {
            _artworkDetails[i] = ArtworkDetail(serie);
        }
    }

    /**
     * Increment tokens qty for a specific for serie
     */
    function incrementSerie(uint256 qtyTokens, uint256 serie) internal {
        if (serie == 1) {
            QTY_TOKENS_T1 = QTY_TOKENS_T1.add(qtyTokens);
        }else if (serie == 2) {
            QTY_TOKENS_T2 = QTY_TOKENS_T2.add(qtyTokens);
        }else{
            QTY_TOKENS_T3 = QTY_TOKENS_T3.add(qtyTokens);
        }
    }

    /**
     * Verify tokens qty doesn't exceed max tokens for the serie
     */
    function verifyTokenQtySerie(uint256 qtyTokens, uint256 serie) internal view returns(bool) {
        if (serie == 1) {
            if(QTY_TOKENS_T1.add(qtyTokens) <= TOTAL_TOKENS_T1) {
                return true;
            }
        }else if (serie == 2) {
            if(QTY_TOKENS_T2.add(qtyTokens) <= TOTAL_TOKENS_T2) {
                return true;
            }
        }else{
            if(QTY_TOKENS_T3.add(qtyTokens) <= TOTAL_TOKENS_T3) {
                return true;
            }
        }
        return false;
    }

    /**
     * Team reserved tokens.
     */
    function reserve(uint256 qtyTokens, uint256 serie) public onlyOwner {
        require(verifyTokenQtySerie(qtyTokens, serie), "Qty tokens exceed max supply for the Serie");

        internalMint(msg.sender, qtyTokens, serie);
    }

    /**
     * Mint token to wallets.
     */
    function mintToWallets(address[] memory owners, uint256 qtyTokens, uint256 serie) public onlyOwner {
        require(verifyTokenQtySerie(owners.length.mul(qtyTokens), serie), "Purchase exceed max supply for the Serie");
        
        for (uint i = 0; i < owners.length; i++) {
            internalMint(owners[i], qtyTokens, serie);
        }
    }

    /**
     * Internal mint function.
     */
    function internalMint(address owner, uint256 qtyTokens, uint256 serie) internal {
        uint256 currentToken = totalSupply();

        incrementSerie(qtyTokens, serie);
        _safeMint(owner, qtyTokens);

        // set the serie onchain
        uint256 tokenId;
        for (uint i = 0; i < qtyTokens; i++) {
            tokenId = currentToken.add(i);
            _artworkDetails[tokenId] = ArtworkDetail(serie);
            emit TokenMinted(msg.sender, tokenId, serie);
        }
    }

    /**
     * Get serie price.
     */
    function getPrice(uint256 serie) internal view returns(uint256) {
        if (serie == 1) {
            return PRICE_T1;
        }else if (serie == 2) {
            return PRICE_T2;
        }else{
            return PRICE_T3;
        }
    }

    /**
     * Get qty tokens available for each serie.
     */
    function getQtyAvailable() public view returns(uint256[] memory) {
        uint256[] memory available = new uint256[](3);

        // serie == 1
        available[0] = TOTAL_TOKENS_T1.sub(QTY_TOKENS_T1);
        // serie == 2
        available[1] = TOTAL_TOKENS_T2.sub(QTY_TOKENS_T2);
        // serie == 3
        available[2] = TOTAL_TOKENS_T3.sub(QTY_TOKENS_T3);
        
        return available;
    }

    /**
     * Mint a Token
     */
    function mint(uint qtyTokens, uint256 serie) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(qtyTokens > 0 && qtyTokens <= MAX_PURCHASE, "Qty tokens exceed max purchase");
        require(serie >= 1 && serie <= 3, "Invalid serie");

        uint256 price = getPrice(serie);
        require(price.mul(qtyTokens) <= msg.value, "Value sent is not correct");

        require(verifyTokenQtySerie(qtyTokens, serie), "Qty tokens exceed max supply for the serie");

        internalMint(msg.sender, qtyTokens, serie);
    }

    /**
     * Get owner balance.
     */
    function getTokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
     * Get owners list.
     */
    function getOwners(uint256 offset, uint256 limit) public view returns(address[] memory) {
        uint tokenCount = totalSupply();

        if (offset.add(limit) < tokenCount) {
            tokenCount = offset.add(limit);
        }

        address[] memory owners = new address[](tokenCount);
        for (uint i = offset; i < tokenCount; i++) {
            owners[i] = ownerOf(i);
        }

        return owners;
    }

    /**
     * Get tokens artwork.
     */
    function getTokensArtworks(uint256 idx, uint256 qtyTokens) public view returns(ArtworkDetail[] memory) {
        require(idx.add(qtyTokens) < TOTAL_TOKENS_T1.add(TOTAL_TOKENS_T2).add(TOTAL_TOKENS_T3), 'qtyTokens exceed total supply');

        ArtworkDetail[] memory artworks = new ArtworkDetail[](qtyTokens);
        for (uint i = 0; i < qtyTokens; i++) {
            artworks[i] = _artworkDetails[idx + i];
        }

        return artworks;
    }
}