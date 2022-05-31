// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./AccessControlEnumerable.sol";

contract ROTL is AccessControlEnumerable, ERC721A, ERC721ABurnable, ERC721AQueryable {
    event SetBaseTokenURI(string uri);

    string private _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721A("Ruler of the Land", "ROTL") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, uint256 quantity) external payable onlyRole(MINTER_ROLE) {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(to, quantity);
    }

    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, minter);
    }

    function setBaseTokenURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = uri;
        emit SetBaseTokenURI(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}