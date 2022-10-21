// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A2.sol";
import "./ERC721Holder.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Strings.sol";

// lazy mint onlyOwner 방식
contract TestCC is ERC721A, ERC721Holder, Pausable, ReentrancyGuard, AccessControl {
    using Strings for uint256;
    string internal baseURI;
    string internal fileExtention = ".json";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BUNRER_ROLE");

    address internal origin;
    
    constructor(string memory _ipfs, address origin_) ERC721A("TestCC", "TCCT") {
        baseURI = _ipfs;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, origin_);
        _grantRole(BURNER_ROLE, origin_);
        origin = origin_;
    }

    function _origin(
    ) internal view virtual override returns (address) {
        return origin;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string calldata newBaseURI) external {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), fileExtention)) : "";
    }

    function burn(uint256 tokenId) public virtual onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function mint(address to, uint256 amount) public {
        _safeMint(to, amount);
    }

    function sale(address to, uint256 amount) public {
        _safeMint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function grantMinterRole(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }

    function grantBurnerRole(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BURNER_ROLE, account);
    }
    
    function revokeBurnerRole(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BURNER_ROLE, account);
    }
}