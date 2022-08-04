// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Strings.sol";

contract Parts is ERC721, AccessControl {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    mapping(uint256 => string) private _tokenURIs;
    string private baseURI;
    using Strings for uint256;

    constructor(string memory name, string memory symbol, address admin, address predicate) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(PREDICATE_ROLE, predicate);
    }

    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), "Caller is not have a permission");
       _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory uri) external only(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI()).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI(), _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }


    // for bridge
    function mint(address user, uint256 tokenId) external only(PREDICATE_ROLE) {
        _mint(user, tokenId);
    }

    function setTokenMetadata(uint256 tokenId, bytes memory data) internal virtual {
        // This function should decode metadata obtained from L2
        // and attempt to set it for this `tokenId`
        //
        // Following is just a default implementation, feel
        // free to define your own encoding/ decoding scheme
        // for L2 -> L1 token metadata transfer
        string memory uri = abi.decode(data, (string));

        _setTokenURI(tokenId, uri);
    }

    function mint(address user, uint256 tokenId, bytes calldata metaData) external only(PREDICATE_ROLE) {
        _mint(user, tokenId);

        setTokenMetadata(tokenId, metaData);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}