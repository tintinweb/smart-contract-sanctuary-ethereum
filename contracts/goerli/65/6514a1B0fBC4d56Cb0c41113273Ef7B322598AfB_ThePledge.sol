// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ECDSA.sol";

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity) external payable;
}

contract ThePledge is IERC721Pledge, Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;
    /**
     * @dev Pre-sale price
     */
    uint256 public PRESALE_PRICE;
    /**
     * @dev public mint price
     */
    uint256 public MINT_PRICE;
    /**
     * @dev The max amount of tokens that can be minted.
     */
    uint32 public MAX_SUPPLY;
    /**
     * @dev The max amount of tokens per wallet.
     */
    uint8 public MAX_PER_WALLET;
    /**
     * @dev Pledge contract address.
     */
    address public pledgeContractAddress;
    /**
     * @dev controls which CID to show.
     */
    bool public revealed = false;
    /**
     * @dev public mint.
     */
    bool public isPublicMint = false;
    /**
     * @dev URI Prefix.
     */
    string public uriPrefix = "";

    /**
     * @dev URI Suffix.
     */
    string public uriSuffix = ".json";

    /**
     * @dev Hidden Metadata URI.
     */
    string public hiddenMetadataUri;

    constructor(address pledgeContractAddress_) ERC721A("ThePledge", "TP") {
        pledgeContractAddress = pledgeContractAddress_;
    }

    /**
     * @dev Check if caller is End User.
     */
    modifier callerIsEndUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev Check if caller is PledgeMint.
     */
    modifier onlyPledgeContract() {
        require(
            pledgeContractAddress == msg.sender,
            "The caller is not PledgeMint"
        );
        _;
    }

    /**
     * @dev PledgeMint.
     */
    function pledgeMint(address to, uint8 quantity)
        external
        payable
        override
        onlyPledgeContract
    {
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
        require(
            msg.value >= PRESALE_PRICE * quantity,
            "Need to send more ETH."
        );
        _mint(to, quantity);
    }

    /**
     * @dev Public Mint.
     */
    function publicMint(uint256 quantity) external payable callerIsEndUser {
        require(isPublicMint, "General sale has not yet started");
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
        require(
            tokensOf(msg.sender) + quantity <= MAX_PER_WALLET,
            "cannot mint this quantity"
        );
        _mint(msg.sender, quantity);
        refundIfOver(MINT_PRICE * quantity);
    }

    /**
     * @dev Returns the token URI for `tokenId`.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length != 0) {
            uint256 imageId = uint256(_ownershipOf(_tokenId).extraData);
            return
                string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(imageId),
                        uriSuffix
                    )
                );
        }
        revert("Base URI not set.");
    }

    /**
     * @dev Sets minted index to start at `index 1`.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev revealed metadata `URI`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /**
     * @dev Total minted by address.
     */
    function tokensOf(address value) public view returns (uint256) {
        return _numberMinted(value);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // -------------------------------------------------
    // Admin functions for contract owner.
    // -------------------------------------------------

    function setPledgeContractAddress(address _value) public onlyOwner {
        pledgeContractAddress = _value;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setPresalePrice(uint256 _value) public onlyOwner {
        PRESALE_PRICE = _value;
    }

    function setMintPrice(uint256 _value) public onlyOwner {
        MINT_PRICE = _value;
    }

    function setMaxPerWallet(uint8 _value) public onlyOwner {
        MAX_PER_WALLET = _value;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMaxSupply(uint32 _value) external onlyOwner {
        MAX_SUPPLY = _value;
    }

    function setPublicMint(bool _state) external onlyOwner {
        isPublicMint = _state;
    }

    function withdrawETH() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}