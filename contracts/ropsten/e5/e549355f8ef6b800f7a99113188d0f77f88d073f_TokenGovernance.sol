// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./AccessControl.sol";

import "./ITokenGovernance.sol";

/// @title The Token Governance contract is used to govern a mintable ERC20 token by restricting its launch-time initial
/// administrative privileges.
contract TokenGovernance is ITokenGovernance, AccessControl {
    // The supervisor role is used to globally govern the contract and its governing roles.
    bytes32 public constant ROLE_SUPERVISOR = keccak256("ROLE_SUPERVISOR");

    // The governor role is used to govern the minter role.
    bytes32 public constant ROLE_GOVERNOR = keccak256("ROLE_GOVERNOR");

    // The minter role is used to control who can request the mintable ERC20 token to mint additional tokens.
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");

    // The address of the mintable ERC20 token.
    IMintableToken public immutable override token;

    /// @dev Initializes the contract.
    ///
    /// @param mintableToken The address of the mintable ERC20 token.
    constructor(IMintableToken mintableToken) public {
        require(address(mintableToken) != address(0), "ERR_INVALID_ADDRESS");

        token = mintableToken;

        // Set up administrative roles.
        _setRoleAdmin(ROLE_SUPERVISOR, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_GOVERNOR, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_MINTER, ROLE_GOVERNOR);

        // Allow the deployer to initially govern the contract.
        _setupRole(ROLE_SUPERVISOR, _msgSender());
    }

    /// @dev Accepts the ownership of the token. Only allowed by the SUPERVISOR role.
    function acceptTokenOwnership() external {
        require(hasRole(ROLE_SUPERVISOR, _msgSender()), "ERR_ACCESS_DENIED");

        token.acceptOwnership();
    }

    /// @dev Mints new tokens. Only allowed by the MINTER role.
    ///
    /// @param to Account to receive the new amount.
    /// @param amount Amount to increase the supply by.
    ///
    function mint(address to, uint256 amount) external override {
        require(hasRole(ROLE_MINTER, _msgSender()), "ERR_ACCESS_DENIED");

        token.issue(to, amount);
    }

    /// @dev Burns tokens from the caller.
    ///
    /// @param amount Amount to decrease the supply by.
    ///
    function burn(uint256 amount) external override {
        token.destroy(_msgSender(), amount);
    }
}