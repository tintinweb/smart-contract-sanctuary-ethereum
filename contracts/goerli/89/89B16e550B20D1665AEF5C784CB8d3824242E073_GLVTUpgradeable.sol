// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IMintableUpgradeable.sol";
import "./ITerms.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./RoyaltiesV2.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./CountersUpgradeable.sol";


contract GLVTUpgradeable is
    Initializable, 
    ERC721AUpgradeable, 
    ERC721AQueryableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable, 
    OwnableUpgradeable,
    AccessControlUpgradeable, 
    RoyaltiesV2,
    ITerms,
    IMintableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    string public baseTokenURI;
    string private _termsAndConditionsURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * Initialises the contract.
     *
     * @param name_ Token name.
     * @param symbol_ Token symbol.
     * @param baseTokenURI_ Base component of token URI.
     * @param termsURI_ URI for terms and conditions.
     * @param royaltyFeeNumerator_ Royalty fee percentage (calculated w.r.t the fee denominator).
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        string memory termsURI_,
        uint96 royaltyFeeNumerator_
    )
        initializer
        public
    {
        __ERC721A_init(name_, symbol_);
        baseTokenURI = baseTokenURI_;
        _termsAndConditionsURI = termsURI_;

        __ERC2981_init();
        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setDefaultRoyalty(payable(msg.sender), royaltyFeeNumerator_);
    }

    /**
     * Returns the base URI for the token.
     *
     * @return baseTokenURI Base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Set the base URI for the token.
     *
     * @param uri Updated base URI.
     *
     * Requirements:
     * - Caller must have the default admin role.
     */
    function setBaseTokenURI(string memory uri) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = uri;
    }

    /**
     * Set the URI for terms and conditions.
     *
     * @param uri Updated terms and conditions URI.
     *
     * Requirements:
     * - Caller must have the default admin role.
     */
    function setTermsURI(string memory uri) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _termsAndConditionsURI = uri;
    }

    /**
     * Returns the URI for the terms and conditions.
     *
     * @return _termsAndConditionsURI Terms and conditions URI.
     */
    function termsAndConditionsURI() public view virtual override returns (string memory) {
        return _termsAndConditionsURI;
    }

    /**
     * Pauses the contract.
     *
     * Requirements:
     * - Caller must have the default admin role.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * Unpauses the contract.
     *
     * Requirements:
     * - Caller must have the default admin role.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Override to reset token royalties.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     * Requirements:
     * - Contract must not be paused.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * Mint tokens.
     *
     * @param to Recipient address.
     * @param quantity Number of tokens to mint.
     * @return tokenIds Array of newly minted token IDs.
     *
     * Requirements:
     * - Caller must have minter role.
     */
    function safeMint(address to, uint256 quantity) public virtual onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 startTokenId = _currentIndex;
        _safeMint(to, quantity);
        return startTokenId;
    }

    /**
     * Returns royalty information w.r.t. Rarible's implementation.
     *
     * @param tokenId Token ID to retrieve royalty information for.
     * @return royalties Single-element array of a struct containing royalty information.
     */
    function getRaribleV2Royalties(uint256 tokenId) override external view returns (LibPart.Part[] memory) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }
        
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royalty.royaltyFraction;
        _royalties[0].account = royalty.receiver;

        return _royalties;
    }

    /**
     * Set royalty information for a specific token.
     *
     * This implementation saves the royalty information using the ERC2981 standard,
     * but also adheres to the Rarible standard by emitting a {RoyaltiesSet} event.
     *
     * @param tokenId Token ID to set royalty information for.
     * @param royaltiesReceipientAddress Royalty recipient.
     * @param percentageBasisPoints Royalty fee percentage.
     *
     * Requirements:
     * - Caller must have default admin role.
     */
    function setRoyalties(
        uint tokenId,
        address payable royaltiesReceipientAddress,
        uint96 percentageBasisPoints
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // ERC2981 royalty
        _setTokenRoyalty(tokenId, royaltiesReceipientAddress, percentageBasisPoints);
        
        // Rarible royalty
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = percentageBasisPoints;
        _royalties[0].account = royaltiesReceipientAddress;

        emit RoyaltiesSet(tokenId, _royalties);
    }

    /**
     * Extend interface support for Rarible's royalties v2 standard.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721AUpgradeable,
            AccessControlUpgradeable,
            ERC2981Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     *
     * This implementation relies strictly on the assumption that tokens may
     * never be burned.
     *
     * Taken from Azuki (Ethereum mainnet: 0xED5AF388653567Af2F388E6224dC7C4b3241C544)
     */
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index + _startTokenId();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     *
     * This implementation relies strictly on the assumption that tokens may
     * never be burned.
     *
     * Taken from Azuki (Ethereum mainnet: 0xED5AF388653567Af2F388E6224dC7C4b3241C544)
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721A: unable to get token of owner by index");
    }
}