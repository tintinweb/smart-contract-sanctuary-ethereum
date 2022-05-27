// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./bridge.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract PERSONAnimalsNFT is
    Bridge,
    ERC721Enumerable,
    ReentrancyGuard,
    Pausable
{
    string public baseURI;
    uint256 public maxSupply = 5000;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event BridgeNotice(
        address indexed caller,
        uint256 indexed tokenId,
        uint256 indexed time
    );

    constructor() ERC721("PERSONAnimals", "PA") {}

    function claim(address to, uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        require(to != address(0), "Invalid address");
        require(!_exists(tokenId), "Token already claimed");
        require(totalSupply() < maxSupply, "Total supply reached");
        _safeMint(to, tokenId);
    }

    function bridgeClaim(
        uint256 tokenId,
        uint256 timestamp,
        uint256 chainId,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 code
    ) public whenNotPaused {
        require(!_exists(tokenId), "Token already claimed");
        require(totalSupply() < maxSupply, "Total supply reached");
        require(bridgeHash[code] != code, "Invalid hash");
        _verifyInput(tokenId, timestamp, chainId, v, r, s, code);
        bridgeHash[code] = code;
        _safeMint(_msgSender(), tokenId);
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

    //only owner of tokenId can call this function in bridge, will check owner of tokenId
    function BridgeAcross(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Only owner can burn token");
        _burn(tokenId);
        emit BridgeNotice(_msgSender(), tokenId, block.timestamp);
    }

    function setBridgePauseChange(bool status_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (status_) {
            _pause();
        } else {
            _unpause();
        }
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