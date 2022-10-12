// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./TurfShopEligibilityChecker.sol";

contract CheckerWithStorage is TurfShopEligibilityChecker {
  
  address turfShopAddress;
  mapping(address => uint256) private _mintedPerAddress;

  constructor(address turfShopAddress_) {
    require(turfShopAddress_ != address(0), "Set the Turf Shop address!");
    turfShopAddress = turfShopAddress_;
  }

  function check(address addr, bytes32[] memory merkleProof, bytes memory data) external view returns (bool, uint) {
    require(_mintedPerAddress[addr] == 0, "already minted");
    return (true, 1);
  }

  function confirmMint(address addr, uint256 count) external {
    require(msg.sender == turfShopAddress, "nope");
    _mintedPerAddress[addr] = count;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/*
  Each TurfShop object's mint can be configured to refer to an external contract for eligiblity checks.
  This way we can arrange mints' "allow list" flexibly as the need arises, without having to hard code
  all possible situations in the primary TurfShop contract.

  For example, we might want a "Get a free item for every Turf plot you own" give away,
  which would entail that a Checker contract get a user's balance from the original Turf contract.

  Or we might just have a snapshot of some arbitrary data, stored in a Merkle Tree.

  Or maybe we want to interface with another community's contract, etc.

  Either way, we can develop that later, on a per-Turf Object basis.

  In our "get a plant for every Turf Plot" example, we'd return (true, 5)
  for a person that held 5 plots. This would inform TurfShop.sol to give that person
  5 plants. Or, if they held no Turf Plots, we'd return (false, 0).
*/

interface TurfShopEligibilityChecker {
  // @notice Confirms if the given address can mint this object, and, if so, how many items can they mint?
  // @param addr The address being checked.
  // @param merkleProof If a Merkle Tree is involved, pass in the proof.
  // @param data An optional chunk of data that can be used by Checker in any way.
  function check(address addr, bytes32[] memory merkleProof, bytes memory data) external view returns (bool, uint);

  /**
  @notice A method that TurfShop can call back to, following a succesful mint, to let this Checker know that the
  address minted a given amount of items. This might be used to update storage in this contract in order to prevent the address
  from minting more than once. 
  NOTE: Be sure to setup some logic to prevent this method from being called globally.
  For example, store TurfShop's address in the constructor, and check that it's the `msg.sender` inside this method.
  */
  // @param addr The address that minted.
  // @param count How many items were minted.
  function confirmMint(address addr, uint256 count) external;
}