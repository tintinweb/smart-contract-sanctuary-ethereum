// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernancePowerDelegationToken {
  enum GovernancePowerType {
    VOTING,
    PROPOSITION
  }

  /**
   * @dev emitted when a user delegates to another
   * @param delegator the user which delegated governance power
   * @param delegatee the delegatee
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   **/
  event DelegateChanged(
    address indexed delegator,
    address indexed delegatee,
    GovernancePowerType delegationType
  );

  // @dev we removed DelegatedPowerChanged event because to reconstruct the full state of the system,
  // is enough to have Transfer and DelegateChanged TODO: document it

  /**
   * @dev delegates the specific power to a delegatee
   * @param delegatee the user which delegated power will change
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   **/
  function delegateByType(address delegatee, GovernancePowerType delegationType) external;

  /**
   * @dev delegates all the governance powers to a specific user
   * @param delegatee the user to which the powers will be delegated
   **/
  function delegate(address delegatee) external;

  /**
   * @dev returns the delegatee of an user
   * @param delegator the address of the delegator
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   * @return address of the specified delegatee
   **/
  function getDelegateeByType(address delegator, GovernancePowerType delegationType)
    external
    view
    returns (address);

  /**
   * @dev returns delegates of an user
   * @param delegator the address of the delegator
   * @return a tuple of addresses the VOTING and PROPOSITION delegatee
   **/
  function getDelegates(address delegator)
    external
    view
    returns (address, address);

  /**
   * @dev returns the current voting or proposition power of a user.
   * @param user the user
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   * @return the current voting or proposition power of a user
   **/
  function getPowerCurrent(address user, GovernancePowerType delegationType)
    external
    view
    returns (uint256);

  /**
   * @dev returns the current voting or proposition power of a user.
   * @param user the user
   * @return the current voting and proposition power of a user
   **/
  function getPowersCurrent(address user)
    external
    view
    returns (uint256, uint256);

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param delegator the owner of the funds
   * @param delegatee the user to who owner delegates his governance power
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function metaDelegateByType(
    address delegator,
    address delegatee,
    GovernancePowerType delegationType,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param delegator the owner of the funds
   * @param delegatee the user to who delegator delegates his voting and proposition governance power
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function metaDelegate(
    address delegator,
    address delegatee,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IGovernancePowerDelegationToken} from 'aave-token-v3/interfaces/IGovernancePowerDelegationToken.sol';

import {IL1VotingStrategy} from '../interfaces/IL1VotingStrategy.sol';
import {BaseVotingStrategy} from './BaseVotingStrategy.sol';

abstract contract BaseL1VotingStrategy is
  BaseVotingStrategy,
  IL1VotingStrategy
{
  /// @inheritdoc IL1VotingStrategy
  function getFullVotingPower(address user) external view returns (uint256) {
    return
      _getFullPowerByType(
        user,
        IGovernancePowerDelegationToken.GovernancePowerType.VOTING
      );
  }

  /// @inheritdoc IL1VotingStrategy
  function getFullPropositionPower(address user)
    external
    view
    returns (uint256)
  {
    return
      _getFullPowerByType(
        user,
        IGovernancePowerDelegationToken.GovernancePowerType.PROPOSITION
      );
  }

  /**
   * @dev method to get the full weighted power by type of an user
   * @param user address of the user to get the full weighted power
   * @param powerType type of the power to get (voting, proposal)
   */
  function _getFullPowerByType(
    address user,
    IGovernancePowerDelegationToken.GovernancePowerType powerType
  ) internal view returns (uint256) {
    uint256 fullGovernancePower;

    address[] memory votingAssetList = getVotingAssetList();
    for (uint256 i; i < votingAssetList.length; i++) {
      fullGovernancePower += getWeightedPower(
        votingAssetList[i],
        0,
        IGovernancePowerDelegationToken(votingAssetList[i]).getPowerCurrent(
          user,
          powerType
        )
      );
    }

    return fullGovernancePower;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseVotingStrategy} from '../interfaces/IBaseVotingStrategy.sol';

abstract contract BaseVotingStrategy is IBaseVotingStrategy {
  uint128 public constant WEIGHT_PRECISION = 100;

  /**
  * @dev on the constructor we get all the voting assets and emit the different
         asset configurations
  */
  constructor() {
    address[] memory votingAssetList = getVotingAssetList();

    for (uint256 i; i < votingAssetList.length; i++) {
      VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(
        votingAssetList[i]
      );
      emit VotingAssetAdd(
        votingAssetList[i],
        votingAssetConfig.baseStorageSlot,
        votingAssetConfig.weight
      );
    }
  }

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetList() public view virtual returns (address[] memory);

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetConfig(address asset)
    public
    view
    virtual
    returns (VotingAssetConfig memory);

  /// @inheritdoc IBaseVotingStrategy
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power
  ) public view virtual returns (uint256) {
    VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(asset);
    if (votingAssetConfig.baseStorageSlot == baseStorageSlot) {
      return (power * votingAssetConfig.weight) / WEIGHT_PRECISION;
    }
    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseL1VotingStrategy} from './BaseL1VotingStrategy.sol';
import {IBaseVotingStrategy} from '../interfaces/IBaseVotingStrategy.sol';

contract L1VotingStrategy is BaseL1VotingStrategy {
  address public constant AAVE = 0x63242B9Bd3C22f18706d5c4E627B4735973f1f07; // TODO: Goerli aave token

  //  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  //  address public constant A_AAVE = 0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;
  //  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetList()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory votingAssets = new address[](1);

    votingAssets[0] = AAVE;
    //    votingAssets[1] = STK_AAVE;
    //    votingAssets[1] = A_AAVE;

    return votingAssets;
  }

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetConfig(address asset)
    public
    pure
    override
    returns (VotingAssetConfig memory)
  {
    VotingAssetConfig memory votingAssetConfig;

    if (
      asset == AAVE
      //      || asset == STK_AAVE
      //      || asset == A_AAVE
    ) {
      votingAssetConfig.weight = WEIGHT_PRECISION;
    }

    return votingAssetConfig;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseVotingStrategy {
  /**
   * @dev object storing the information of the asset used for the voting strategy
   * @param baseStorageSlot initial slot for the balance of the specified token.
            From that slot, by adding the address of the user, the correct balance can be taken.
   * @param weight determines the importance of the token on the vote.
   */
  struct VotingAssetConfig {
    uint128 baseStorageSlot;
    uint128 weight;
  }

  /**
   * @dev emitted when an asset is added for the voting strategy
   * @param asset address of the token to be added
   * @param storageSlot storage position of the start of the balance mapping
   * @param weight percentage of importance that the asset will have in the vote
   */
  event VotingAssetAdd(
    address indexed asset,
    uint128 storageSlot,
    uint128 weight
  );

  /**
   * @dev method to get the precision of the weights used.
   * @return the weight precision
   */
  function WEIGHT_PRECISION() external view returns (uint128);

  /**
   * @dev method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @dev method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the base storage slot, and the weight
   */
  function getVotingAssetConfig(address asset)
    external
    view
    returns (VotingAssetConfig memory);

  /**
   * @dev method to get the power of an asset, after applying the configured weight for said asset
   * @param asset address of the token to get the weighted power
   * @param baseStorageSlot storage position of the start of the balance mapping
   * @param power balance of a determined asset to be weighted for the vote
   */
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1VotingStrategy {
  /**
   * @dev method to get the full weighted voting power of an user
   * @param user address where we want to get the power from
   */
  function getFullVotingPower(address user) external view returns (uint256);

  /**
   * @dev method to get the full weighted proposal power of an user
   * @param user address where we want to get the power from
   */
  function getFullPropositionPower(address user)
    external
    view
    returns (uint256);
}