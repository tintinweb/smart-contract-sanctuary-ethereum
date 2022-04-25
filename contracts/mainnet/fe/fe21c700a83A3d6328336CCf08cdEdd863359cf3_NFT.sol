// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// Imports
import "./ERC721A.sol";
import "./Reveal.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

/// @title MOD - The NFT contract.
contract NFT is ERC721A, AccessControl, Ownable, Reveal {
  // Available Access Roles
  // Only address with MINTER_ROLE cant mint new tokens
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @param _tokenName The token name
   * @param _tokenSymbol The token symbol
   * @param _unrevealedUri The unrevealed URI
   * @dev The contract constructor
   */
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _unrevealedUri
  ) ERC721A(_tokenName, _tokenSymbol) Reveal(_unrevealedUri) {
    // Set the roles.
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  /**
   * @param minter The minter address to grant a MINTER_ROLE
   * @dev Sets the address to be able mint
   */
  function setMinterRole(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(MINTER_ROLE, minter);
  }

  /**
   * @param recipient The user's address
   * @param quantity The number of NFTs to mint
   * @dev Mints NFTs
   */
  function mint(address recipient, uint256 quantity) external onlyRole(MINTER_ROLE) {
    _safeMint(recipient, quantity);
  }

  /**
   * @param tokenId The ID of an NFT to burn
   * @dev Burns NFTs
   */
  function burnToken(uint256 tokenId) external {
    // Check token exists
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    // Check if owner is really the owner
    require(ownerOf(tokenId) == _msgSender(), "Caller is not owner of token!");

    _burn(tokenId);
  }

  /**
   * @param tokenId The ID of an NFT
   * @dev Returns the URI of an NFT
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return getTokenUri(tokenId);
  }

  /**
   * @param interfaceId The interface ID
    * @dev The following functions are overrides required by Solidity
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns the base URI
   */
  function _baseURI() internal view override returns (string memory) {
    return getBaseUri();
  }
}