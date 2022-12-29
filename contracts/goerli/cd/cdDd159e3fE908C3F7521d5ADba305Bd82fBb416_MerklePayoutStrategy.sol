// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "../payoutStrategy/IPayoutStrategy.sol";

import "../utils/MetaPtr.sol";

/**
 * @notice Merkle Payout Strategy contract which is deployed once per round
 * and is used to upload the final match distribution.
 *
 * @dev
 *  - TODO: add function distribute() to actually distribute the funds
 */
contract MerklePayoutStrategy is IPayoutStrategy {

  // --- Data ---

  /// @notice Unix timestamp from when round can accept applications
  bytes32 public merkleRoot;

  /// @notice Unix timestamp from when round stops accepting applications
  MetaPtr public distributionMetaPtr;


  // --- Event ---

  /// @notice Emitted when the distribution is updated
  event DistributionUpdated(bytes32 merkleRoot, MetaPtr distributionMetaPtr);


  // --- Core methods ---

  /**
   * @notice Invoked by RoundImplementation to upload distribution to the
   * payout strategy
   *
   * @dev
   * - should be invoked by RoundImplementation contract
   * - ideally IPayoutStrategy implementation should emit events after
   *   distribution is updated
   * - would be invoked at the end of the roune
   *
   * @param encodedDistribution encoded distribution
   */
  function updateDistribution(bytes calldata encodedDistribution) external override isRoundContract {

    (bytes32 _merkleRoot, MetaPtr memory _distributionMetaPtr) = abi.decode(
      encodedDistribution,
      (bytes32, MetaPtr)
    );

    merkleRoot = _merkleRoot;
    distributionMetaPtr = _distributionMetaPtr;

    emit DistributionUpdated(merkleRoot, distributionMetaPtr);
  }

  // TODO: function payout()
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/**
 * @notice Defines the abstract contract for payout strategies
 * for a round. Any new payout strategy would be expected to
 * extend this abstract contract.
 * Every IPayoutStrategy contract would be unique to RoundImplementation
 * and would be deployed before creating a round 
 *
 * @dev
 *  - Deployed before creating a round
 *  - init will be invoked during round creation to link the payout
 *    strategy to the round contract 
 *  - TODO: add function distribute() to actually distribute the funds  
 */
abstract contract IPayoutStrategy {

   // --- Data ---

  /// @notice Round address
  address public roundAddress;


  // --- Modifier ---

  /// @notice modifier to check if sender is round contract.
  modifier isRoundContract() {
    require(roundAddress != address(0), "error: payout contract not linked to a round");
    require(msg.sender == roundAddress, "error: can be invoked only by round contract");
    _;
  }


  // --- Core methods ---

  /**
   * @notice Invoked by RoundImplementation on creation to
   * set the round for which the payout strategy is to be used
   *
   */
  function init() external {
    require(roundAddress == address(0), "init: roundAddress already set");
    roundAddress = msg.sender;
  }

  /**
   * @notice Invoked by RoundImplementation to upload distribution to the
   * payout strategy
   *
   * @dev
   * - should be invoked by RoundImplementation contract
   * - ideally IPayoutStrategy implementation should emit events after 
   *   distribution is updated
   * - would be invoked at the end of the round
   *
   * @param _encodedDistribution encoded distribution
   */
  function updateDistribution(bytes calldata _encodedDistribution) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

struct MetaPtr {

  /// @notice Protocol ID corresponding to a specific protocol.
  /// More info at https://github.com/gitcoinco/grants-round/tree/main/packages/contracts/docs/MetaPtrProtocol.md
  uint256 protocol;
  
  /// @notice Pointer to fetch metadata for the specified protocol
  string pointer;
}