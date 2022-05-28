// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Counters.sol";
import "./ERC721.sol";

contract NftMinter is ERC721, AccessControl {
    using Counters for Counters.Counter;
    bytes32 public constant PAYOUT_ROLE = keccak256("PAYOUT_ROLE");

    Counters.Counter private _tokenIds;
    uint256 public maxSupply;
    uint256 public pricePerNft;
    address private _creatorAddress;
    string private _baseUri;
    bool private _baseUriSettable = true;
    uint64 public mintStartTime = 0;
    // The default end time is 2030/12/31 at 23:59:59.
    uint64 public mintEndTime = 1925009999;
    bool public mintingAllowed = true;

    /**
     * @dev Emitted when tokens are minted via the mint() function.
     */
    event TokensMinted(uint256 numTokensMinted, string clientInfo);

    /**
     * @dev Initializes the NftMinter with default admin and payout roles.
     *
     * @param name_ the name of the NFT collection.
     * @param symbol_ the symbol of the NFT collection.
     * @param maxSupply_ the maximum number of items in the collection.
     * @param pricePerNft_ the price per NFT.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 pricePerNft_
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        maxSupply = maxSupply_;
        pricePerNft = pricePerNft_;
        _baseUri = "";
    }

    /** @dev Public facing minting function.
     *
     * This is typically used to create NFTs for sale on third-party marketplaces like OpenSea.
     *
     */
    function mint(uint256 numTokensToMint, string memory clientInfo)
        public
        payable
    {
        uint256 currentPayment = computeCost(numTokensToMint);
        require(msg.value == currentPayment, "Invalid payment amount.");

        uint256 startTokenId = _tokenIds.current();
        _mintCommon(numTokensToMint);
        emit TokensMinted(_tokenIds.current() - startTokenId, clientInfo);
    }

    /**
     * @dev Irreversibly stops all future minting.
     */
    function stopFutureMinting() public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingAllowed = false;
    }

    /**
     * @dev Allows token holders to burn their tokens. This is irreversible.
     */
    function burn(uint256 tokenId) public {
        require(
            super.ownerOf(tokenId) == msg.sender,
            "Only the owner of a token can burn it."
        );
        super._burn(tokenId);
    }

    /**
     * @dev Remaining number of tokens that can be minted.
     */
    function remainingMintableTokens() public view returns (uint256) {
        return maxSupply - _tokenIds.current();
    }

    /**
     * @dev Withdraw ETH from this contract to an account in `PAYOUT_ROLL`.
     */
    function withdraw() public onlyRole(PAYOUT_ROLE) {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Sending eth failed.");
    }

    /**
     * @dev Updates the baseUri of the NFTs. For example, when artwork is ready.
     */
    function setBaseUri(string memory baseUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_baseUriSettable, "URIs are frozen.");
        _baseUri = baseUri;
    }

    /**
     * @dev Prohibits future updating of the metadata.
     */
    function freezeMetadata() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_baseUriSettable, "URIs are frozen.");
        _baseUriSettable = false;
    }

    /**
     * @dev Sets when minting can begin.
     */
    function setMintStartTime(uint64 mintStartTime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintStartTime = mintStartTime_;
    }

    /**
     * @dev Sets when minting can end.
     */
    function setMintEndTime(uint64 mintEndTime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            mintEndTime_ <= mintEndTime,
            "Mint end time can only be made sooner."
        );
        mintEndTime = mintEndTime_;
    }

    /**
     * @dev Computes the cost of minting `numTokensToMint` NFTs.
     */
    function computeCost(uint256 numTokensToMint)
        public
        view
        returns (uint256)
    {
        return numTokensToMint * pricePerNft;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _mintCommon(uint256 numTokensToMint) internal {
        require(mintingAllowed, "Minting is not allowed.");
        require(mintStartTime <= block.timestamp, "Minting is not open yet.");
        require(block.timestamp <= mintEndTime, "Minting has closed.");
        for (uint256 i = 0; i < numTokensToMint; ++i) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            require(newItemId <= maxSupply, "Can't mint that many NFTs.");

            super._safeMint(msg.sender, newItemId);
        }
    }
}