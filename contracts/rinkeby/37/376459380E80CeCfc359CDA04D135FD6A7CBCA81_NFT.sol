// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./Reveal.sol";
import "./AccessControl.sol";
import "./Ownable.sol";


contract NFT is ERC721A, AccessControl, Ownable, Reveal {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public MAX_SUPPLY;
  uint256 public MAX_RESERVED_SUPPLY;

  bool public preminted = false;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    string memory unrevealedUri,
    uint256 maxSupply,
    uint256 maxReservedSupply
  )
    ERC721A(tokenName, tokenSymbol)
    Reveal(unrevealedUri) {

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

    MAX_SUPPLY = maxSupply;
    MAX_RESERVED_SUPPLY = maxReservedSupply;
  }

  function setMaxSupply(uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(quantity > 0, "Quantity must be greater than 0");
    MAX_SUPPLY = quantity;
  }

  function premint(uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) { 
    require(preminted == false, "Reserved tokens minted already");
    require(totalSupply() + quantity <= MAX_RESERVED_SUPPLY, "MAX_RESERVED_SUPPLY exceeded");
    _safeMint(msg.sender, quantity);
    preminted = totalSupply() == MAX_RESERVED_SUPPLY;
  }

  function setMinter(address mintingRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(MINTER_ROLE, mintingRouter);
  }

  function mint(address recipient, uint256 quantity) external onlyRole(MINTER_ROLE)   {
    require(preminted == true, "TEAM_RESERVE_NOT_PREMINTED_YET");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
    _safeMint(recipient, quantity);
  }

  function burnTokens(uint256[] calldata tokenIds) external {
    for (uint i = 0; i < tokenIds.length; i++) {
      TokenOwnership memory ownership = ownershipOf(tokenIds[i]);
      if (ownership.addr != _msgSender() || ownership.burned) {
        revert("Not owner or already burned");
      }

      _burn(tokenIds[i]);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return getTokenUri(tokenId);
  }

  // Gets base URI.
  function _baseURI() internal view override returns (string memory) {
     return getBaseUri();
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}