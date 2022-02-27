// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

contract ForestToken is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, ERC1155SupplyUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    address private _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC1155_init("ForestToken");
        __AccessControl_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);

        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    //    function setURI(string memory newuri) public {
    //        _setURI(newuri);
    //    }

    function uri(uint256 tokenId) public view virtual returns (string memory) {
        require(exists(tokenId), "ERC1155URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mint(address account, uint256 amount, string memory _uri)
    public
    onlyRole(MINTER_ROLE)
    {
        // Generating new tokenId using auto increment
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _setTokenURI(tokenId, _uri);
        _mint(account, tokenId, amount, '');
    }

    //    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //        public
    //        onlyRole(MINTER_ROLE)
    //    {
    //        _mintBatch(to, ids, amounts, data);
    //    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}