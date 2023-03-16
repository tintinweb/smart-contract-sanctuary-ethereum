// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./OrdinalInvadersSVG.sol";

contract OrdinalInvaders is ERC721Enumerable, OrdinalInvadersSVG, Ownable, ReentrancyGuard, ERC2981 {
    using Strings for uint256;
    using SafeMath for uint256;

    // Events
    event TokenMinted(address owner, uint256 tokenId, bool hasOrdinal);

    // Has an Ordinal
    mapping(uint => bool) private invadeBitcoin;

    // Whitelist
    mapping(address => bool) private whitelist;

    // Max purchase per account each time
    uint public maxPurchase = 55;

    // Max purchase per account each time - whitelist period
    uint public maxPurchaseWhitelist = 55;

    // Mint price
    uint public mintPrice = 30000000000000000;

    // Whitelist price
    uint256 public specialPrice = 15000000000000000;

    // Define if whitelist is active
    bool public whitelistIsActive = true;

    // Define if sale is active
    bool public saleIsActive = false;

    // Max tokens supply
    uint256 public totalTokens = 9999;

    // Whitelist Max tokens supply
    uint256 public totalTokensWhitelist = 500;

    // Whitelist counter
    uint256 public whitelistCounter = 0;

    // Ordinals counter
    uint256 public ordinalsCounter = 0;

    address private wallet1 = 0xE43834E7c5BecA36ed60BF6b6cDd90515088dA4D;
    address private wallet2 = 0x99872620911cBC41B66bc5D4123e21F09ABc0C44;

    /**
     * Contract constructor
     */
    constructor(string memory _name, string memory _symbol, string memory _nftName, string memory _nftDescription) ERC721(_name, _symbol) {

        setNFTName(_nftName);
        setNFTDescription(_nftDescription);

        // Random seed to generate Invaders
        generateSeedInvader(owner());

        _setDefaultRoyalty(msg.sender, 500);
    }

    /**
     * Set NFT Name
     */
    function setNFTName(string memory _value) public onlyOwner {
        nftName = _value;
    }

    /**
     * Set NFT Description
     */
    function setNFTDescription(string memory _value) public onlyOwner {
        nftDescription = _value;
    }

    /**
     * Set SVG Dot size
     */
    function setSVGDotSize(uint8 _value) external onlyOwner {
        svgDotSize = _value;
    }

    /**
     * Set SVG View size
     */
    function setSVGViewBoxSize(uint8 _value) external onlyOwner {
        svgViewBoxSize = _value;
    }

    /**
     * Set SVG size
     */
    function setSVGViewBoxXY(uint8 _value) external onlyOwner {
        svgViewBoxXY = _value;
    }

    /**
     * Set SVG size
     */
    function setSVGSize(uint8 _value) external onlyOwner {
        svgSize = _value;
    }

    /**
     * Set SVG Dot XY
     */
    function setSVGDotXY(uint8 _value) external onlyOwner {
        svgDotXY = _value;
    }

    /**
     * Set SVG preserve aspect radio
     */
    function setSVGHeaderPreserveAR(string memory _value) external onlyOwner {
        svgHeaderPreserveAR = _value;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool _newState) external onlyOwner {
        saleIsActive = _newState;
    }

    /*
     * Pause whitelist if active, make active if paused
     */
    function setWhitelistState(bool _newState) external onlyOwner {
        whitelistIsActive = _newState;
    }

    /**
     * Set Total Tokens Supply
     */
    function setTotalTokens(uint _value) external onlyOwner {
        totalTokens = _value;
    }

    /**
     * Set Whitelist Tokens Supply
     */
    function setTotalTokensWhitelist(uint _value) external onlyOwner {
        totalTokensWhitelist = _value;
    }

    /**
     * Set Mint Price
     */
    function setMintPrice(uint _value) external onlyOwner {
        mintPrice = _value;
    }

    /**
     * Set Special Price
     */
    function setSpecialPrice(uint _value) external onlyOwner {
        specialPrice = _value;
    }

    /**
     * Set Max Purchase
     */
    function setMaxPurchase(uint _value) external onlyOwner {
        maxPurchase = _value;
    }

    /**
     * Set Max Purchase Whitelist
     */
    function setMaxPurchaseWhitelist(uint _value) external onlyOwner {
        maxPurchaseWhitelist = _value;
    }

    /**
     * Open public sale
     */
    function openPublicSale(bool _value) public onlyOwner {
        whitelistIsActive = false;
        saleIsActive = _value;
    }

    /**
     * Get Ordinal Invader
     */
    function getOrdinalInvader(uint _tokenId) external view returns(bool) {
        return invadeBitcoin[_tokenId];
    }

    /**
     * Get the token URI with the metadata extension
     */
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return generateMetadataSVG(_tokenId, invadeBitcoin[_tokenId]);
    }

    /**
     * withdraw
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
    
        uint balance = address(this).balance;
        uint wallet1Share = balance.mul(80).div(100);
        uint wallet2Share = balance.mul(20).div(100);

        (bool success, ) = wallet1.call{value: wallet1Share}("");
        require(success, "wallet1 withdrawal failed");

        (success, ) = wallet2.call{value: wallet2Share}("");
        require(success, "wallet2 withdrawal failed");
    }

    /**
     * Alt withdraw
     */
    function altWithdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Add wallets to whitelist
     */
    function addToWhitelist(address[] memory _wallets) external onlyOwner {
        require(_wallets.length > 0, "No wallets to add");
        
        for (uint i = 0; i < _wallets.length; i++) {
            whitelist[_wallets[i]] = true;
        }
    }

    /**
     * Remove wallets from whitelist
     */
    function removeFromWhitelist(address[] memory _wallets) external onlyOwner {
        require(_wallets.length > 0, "No wallets to remove");
        
        for (uint i = 0; i < _wallets.length; i++) {
            whitelist[_wallets[i]] = false;
        }
    }

    /**
     * Mint to wallets
     */
    function mintToWallets(address[] memory _owners, uint _qty) external onlyOwner {
        require(totalSupply().add(_owners.length.mul(_qty)) <= totalTokens, "Mint tokens to wallets would exceed max supply");
        uint tokenId;

        for (uint i = 0; i < _owners.length; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= totalTokens) {
                invadeBitcoin[tokenId] = getInvadeBitcoin(msg.sender, tokenId, getSeedInvaders(), block.timestamp);

                if (invadeBitcoin[tokenId])
                    ordinalsCounter++;
                
                _safeMint(_owners[i], tokenId);
                emit TokenMinted(_owners[i], tokenId, invadeBitcoin[tokenId]);
            }
        }
    }

    /**
     * Get mint Price
     */
    function getMintPrice(uint _qty) public view returns(uint) {
        require(saleIsActive || whitelistIsActive, "Mint is not available right now");

        if (whitelistIsActive) {
            uint qtyToPay = _qty;
            if (balanceOf(msg.sender) == 0) {
                // First token free
                qtyToPay--;
            }
            
            return specialPrice.mul(qtyToPay);
        }else{
            return mintPrice.mul(_qty);
        }
    }

    /**
     * Mint Tokens
     */
    function mint(uint _qty) external payable nonReentrant {
        require(saleIsActive || whitelistIsActive, "Mint is not available right now");
        uint tokenId;

        require(totalSupply().add(_qty) <= totalTokens, "Qty tokens would exceed max supply");
        require(getMintPrice(_qty) <= msg.value, "Value sent is not correct");

        if (whitelistIsActive) {
            require(whitelist[msg.sender], "Sender is not enabled to mint");
            require(whitelistCounter.add(_qty) <= totalTokensWhitelist, "Qty tokens would exceed whitelist max supply");
            require(_qty > 0 && _qty <= maxPurchaseWhitelist, "Qty exceeds max numbers of tokens to purchase at one time in whitelist");

            // Update minted amount in whitelist
            whitelistCounter = whitelistCounter.add(_qty);

            // If whitelist minted amount = totalSupplyWhitelist => Open Public Sale
            if (whitelistCounter == totalTokensWhitelist)
                openPublicSale(true);
        }else{
            require(_qty > 0 && _qty <= maxPurchase, "Qty exceeds max numbers of tokens to purchase at one time");
        }

        for (uint i = 1; i <= _qty; i++) {
            tokenId = totalSupply().add(1);

            if (tokenId <= totalTokens) {
                invadeBitcoin[tokenId] = getInvadeBitcoin(msg.sender, tokenId, getSeedInvaders(), block.timestamp);

                if (invadeBitcoin[tokenId])
                    ordinalsCounter++;

                _safeMint(msg.sender, tokenId);

                emit TokenMinted(msg.sender, tokenId, invadeBitcoin[tokenId]);
            }
        }
    }

    /**
     * Get owners list
     */
    function getOwners(uint256 _offset, uint256 _limit) external view returns(address[] memory) {
        uint tokenCount = totalSupply();

        if (_offset.add(_limit) < tokenCount) {
            tokenCount = _offset.add(_limit);
        }

        address[] memory owners = new address[](tokenCount);
        for (uint i = _offset; i <= tokenCount; i++) {
            owners[i] = ownerOf(i);
        }

        return owners;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Enumerable, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721Enumerable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}