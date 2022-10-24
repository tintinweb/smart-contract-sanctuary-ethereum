// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721Holder.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Strings.sol";

// 일괄 batch pre-minting
contract TestCC2 is ERC721A, ERC721Holder, Pausable, ReentrancyGuard, AccessControl {
    string internal fileExtention = ".json";
    string private baseURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BUNRER_ROLE");

    constructor (
        string memory baseTokenURI_
    ) ERC721A("TestCC2", "TCCT2") {
        baseURI = baseTokenURI_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseTokenURI_;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI_, _toString(tokenId), fileExtention)) : '';
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function burn(uint256 tokenId) public virtual onlyRole(BURNER_ROLE) {
        _burn(tokenId, true);
    }

    function mint(address _to, uint256 _quantity) external onlyRole(MINTER_ROLE) {
        _safeMint(_to, _quantity);
    }

    // 보유 시간 기록이 나온다
    function viewOwnerShip(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function tokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}