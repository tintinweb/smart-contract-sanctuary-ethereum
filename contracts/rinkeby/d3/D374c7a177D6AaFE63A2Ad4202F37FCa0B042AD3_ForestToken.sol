// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./ERC1155URIStorageUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract ForestToken is Initializable, ERC1155Upgradeable,
    ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable,
    AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC1155_init("");
        __ERC1155URIStorage_init();
        __ERC1155Supply_init();

        __AccessControl_init();

        // Granted default admin role to the msg.sender
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN);
    }

    function mint(address account, uint256 amount, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        // Generating new tokenId using auto increment
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Passing default data to mint function, since it is not useful for the current implementation
        _mint(account, tokenId, amount, '');
        _setTokenURI(tokenId, uri);
    }

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