// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./bridge.sol";
import "./baseControl.sol";
import "./nft.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract EraHeroNFT is ERANFT, Bridge, ERC721Enumerable, BaseControl, ReentrancyGuard {
    string public baseURI;
    uint256 public maxSupply = 1000;

    constructor() ERC721("ERA Hero", "EH") {}

    event BridgeFrom(
        address indexed caller,
        uint256 indexed tokenId,
        uint256 indexed time
    );

    event BridgeTo(
        address indexed caller,
        uint256 indexed tokenId,
        uint256 indexed time
    );

    function mint(address to, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(to, tokenId);
    }

    function claim(address to, uint256 tokenId)
        public
        override
        nonReentrant
        onlyRole(MINTER_ROLE)
    {
        require(totalSupply() < maxSupply, "Total supply reached");
        _safeMint(to, tokenId);
    }

    function BridgeClaim(
        uint256 tokenId,
        uint256 timestamp,
        uint256 chainId,
        address caller,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 code
    ) public {
        require(totalSupply() < maxSupply, "Total supply reached");
        require(bridgeHash[code] != code, "hash already used");
        _verifyInput(tokenId, timestamp, chainId, caller, v, r, s, code);
        bridgeHash[code] = code;
        _safeMint(caller, tokenId);
        emit BridgeTo(caller, tokenId, timestamp);
    }

    function BridgeAcross(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Only owner can burn token");
        _burn(tokenId);
        emit BridgeFrom(_msgSender(), tokenId, block.timestamp);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _uri;
    }

    function setMaxSupply(uint256 _maxSupply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxSupply = _maxSupply;
    }

    function transferDefaultAdminRole(address account_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEFAULT_ADMIN_ROLE, account_);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        transferOwnership(account_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}