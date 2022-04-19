// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./Reveal.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

/**
 * @title The NFT smart contract.
 */
contract NFT is ERC721A, AccessControl, Ownable, Reveal {
  /// @notice Minter Access Role - allows users and smart contracts with this role to mint standard tokens (not reserves).
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  /// @notice The amount of available NFT tokens (including the reserved tokens).
  uint256 public MAX_SUPPLY;
  /// @notice The amount of reserved NFT tokens.
  uint256 public MAX_RESERVED_SUPPLY;
  /// @notice Indicates if the reserves have been minted.
  bool public preminted = false;

  /**
     * @notice The smart contract constructor that initializes the contract.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param unrevealedUri The URL of a media that is shown for unrevealed NFTs.
     * @param maxSupply The total amount of available NFT tokens (including the reserved tokens).
     * @param maxReservedSupply The amount of reserved NFT tokens.
     */
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    string memory unrevealedUri,
    uint256 maxSupply,
    uint256 maxReservedSupply
  )
    ERC721A(tokenName, tokenSymbol)
    Reveal(unrevealedUri) {
    // Set the roles.
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    // Set the variables.
    MAX_SUPPLY = maxSupply;
    MAX_RESERVED_SUPPLY = maxReservedSupply;
  }

  /**
   * @notice Sets the total amounts of tokens.
   * @param quantity The number of tokens to set.
   */
  function setMaxSupply(uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(quantity > 0, "Quantity must be greater than 0");
    MAX_SUPPLY = quantity;
  }

  /**
    * @notice Mints the reserved NFT tokens.
    * @param recipient The NFT tokens recipient.
    * @param quantity The number of NFT tokens to mint.
    */
  function premint(address recipient, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Check if there are any reserved tokens available to mint.
    require(preminted == false, "Reserved tokens minted already");
    // Check if the desired quantity of the reserved tokens to mint doesn't exceed the reserve.
    require(totalSupply() + quantity <= MAX_RESERVED_SUPPLY, "MAX_RESERVED_SUPPLY exceeded");
    // Mint the tokens.
    _safeMint(recipient, quantity);
    // Set the flag only if we have minted the whole reserve.
    preminted = totalSupply() == MAX_RESERVED_SUPPLY;
  }

  /**
   * @notice Grants the specified address the minter role.
   * @param mintingRouter The address to grant the minter role.
   */
  function setMinter(address mintingRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(MINTER_ROLE, mintingRouter);
  }

  /**
   * @notice Mints the NFT tokens.
   * @param recipient The NFT tokens recipient.
   * @param quantity The number of NFT tokens to mint.
   */
  function mint(address recipient, uint256 quantity) external onlyRole(MINTER_ROLE)   {
    // Reserves should be minted before minting standard tokens.
    require(preminted == true, "TEAM_RESERVE_NOT_PREMINTED_YET");
    // Check that the number of tokens to mint does not exceed the total amount.
    require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
    // Mint the tokens.
    _safeMint(recipient, quantity);
  }

  /**
   * @notice Burns the NFT tokens.
   * @param tokenIds The IDs of the NFTs to burn.
   */
  function burnTokens(uint256[] calldata tokenIds) external {
    for (uint i = 0; i < tokenIds.length; i++) {
      TokenOwnership memory ownership = ownershipOf(tokenIds[i]);
      if (ownership.addr != _msgSender() || ownership.burned) {
        revert("Not owner or already burned");
      }

      _burn(tokenIds[i]);
    }
  }

  /**
    * @notice Returns a URI of an NFT.
    * @param tokenId The ID of the NFT.
    * @return The URI of the token.
    */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return getTokenUri(tokenId);
  }

  /**
   * @notice Returns true if this contract implements the interface defined by interfaceId.
   * @dev The following functions are overrides required by Solidity.
   * @param interfaceId The interface ID.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice Returns the base URL.
   */
  function _baseURI() internal view override returns (string memory) {
     return getBaseUri();
  }
}