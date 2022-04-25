// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// Imports
import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";

/// @title MOD - Token
contract MOD is ERC20, ERC20Snapshot, AccessControl {
  // Available Access Roles
  // Only address with MINTER_ROLE can mint new tokens
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @param _tokenName The token name
   * @param _tokenSymbol The token symbol
   * @dev The contract constructor
   */
  constructor(string memory _tokenName, string memory _tokenSymbol) ERC20(_tokenName, _tokenSymbol) {
    // Granting the deployer a DEFAULT_ADMIN_ROLE
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // Granting the deployer a MINTER_ROLE
    _grantRole(MINTER_ROLE, msg.sender);
  }

  /**
   * @param minter The minter address to grant a MINTER_ROLE
   * @dev Sets the address to be able mint
   */
  function setMinterRole(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setupRole(MINTER_ROLE, minter);
  }

  /// @dev Creates a new snapshot.
  function snapshot() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _snapshot();
  }

  /**
   * @param recipient The address of a MOD receiver
   * @param amount The number of MOD to mint
   * @dev Mints MOD tokens
   */
  function mint(address recipient, uint256 amount) external onlyRole(MINTER_ROLE) {
    _mint(recipient, amount);
  }

  /**
    * @dev The following functions are overrides required by Solidity
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
    super._beforeTokenTransfer(from, to, amount);
  }
}