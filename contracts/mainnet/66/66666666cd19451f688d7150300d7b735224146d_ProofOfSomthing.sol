// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @dev Proof of Something NFT.
 */
contract ProofOfSomthing is ERC721Enumerable, Ownable {
    using Address for address;
    using Strings for uint256;

    string private _contractURI;
    string private _defaultTokenURI;

    mapping(uint256 => string) private _tokenURI;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns contract URI for marketplaces like OpenSea etc.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    /**
     * @dev Mint the very first token to the owner,
     *      and set the `defaultTokenURI_`.
     */
    function initMint(string calldata defaultTokenURI_) external onlyOwner {
        require(totalSupply() == 0, "TotalSupply: not zero");

        _safeMint(owner(), 0);
        _defaultTokenURI = defaultTokenURI_;
    }

    /**
     * @dev Safely mints a new token and transfers it to `to_`,
     *      with the `tokenURI_`;
     *
     * Emits a {Transfer} event.
     */
    function mint(address to_, string calldata tokenURI_) external onlyOwner {
        require(totalSupply() > 0, "TotalSupply: is zero");
        require(bytes(tokenURI_).length > 0, "TokenURI: length is zero");

        uint256 tokenId = totalSupply();

        _tokenURI[tokenId] = tokenURI_;
        _safeMint(to_, tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        if (bytes(_tokenURI[tokenId]).length > 0) {
            return _tokenURI[tokenId];
        }

        if (bytes(_defaultTokenURI).length > 0) {
            return _defaultTokenURI;
        }

        return "";
    }

    /**
     * @dev Default URI for every {tokenId}, if tokenURI is not set.
     */
    function _baseURI() internal view override returns (string memory) {
        return _defaultTokenURI;
    }

    function setDefaultTokenURI(string calldata defaultTokenURI_)
        external
        onlyOwner
    {
        _defaultTokenURI = defaultTokenURI_;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver_` cannot be the zero address.
     * - `feeNumerator_` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver_, uint96 feeNumerator_)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }
}