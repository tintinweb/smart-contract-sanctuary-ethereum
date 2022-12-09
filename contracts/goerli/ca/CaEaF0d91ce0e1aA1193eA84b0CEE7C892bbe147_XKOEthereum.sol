// SPDX-License-Identifier: MIT
//    _/      _/  _/    _/    _/_/
//     _/  _/    _/  _/    _/    _/
//      _/      _/_/      _/    _/
//   _/  _/    _/  _/    _/    _/
//_/      _/  _/    _/    _/_/
pragma solidity ^0.8.17;

import "./XKO.sol";

/**
  * @dev Polygon > Ethereum bridge requirement
  */
interface IMintableERC20 is IERC20 {
    /**
     * @notice called by predicate contract to mint tokens while withdrawing
     * @dev Should be callable only by MintableERC20Predicate
     * Make sure minting is done only by this function
     * @param user user address for whom token is being minted
     * @param amount amount of token being minted
     */
    function mint(address user, uint256 amount) external;
}

/// @custom:security-contact [email protected]
contract XKOEthereum is XKO, IMintableERC20 {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    address public predicateProxy;

    constructor(string memory name, string memory symbol) XKO(name, symbol) {}

    function setPredicateProxy(address proxy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(hasRole(PREDICATE_ROLE, predicateProxy)){
            _revokeRole(PREDICATE_ROLE, predicateProxy);
        }
        predicateProxy = proxy;
        _grantRole(PREDICATE_ROLE, predicateProxy);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override onlyRole(PREDICATE_ROLE) {
        _mint(user, amount);
    }
}