// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakedPurchase {
  using SafeMath for uint256;
  uint256 maxAssetId = 0;
  struct StakeInfo {
    uint256 amount;
    uint256 since;
  }
  struct Asset {
    uint256 id;
    string name;
    string uri;
    uint256 price;
    address payable seller;
  }

  // AssetId=>(Staker => stakes)
  mapping(uint256 => mapping(address => StakeInfo)) intendedStakesMapping;
  // AssetId=>(Staker => stakes)
  mapping(uint256 => mapping(address => StakeInfo)) finalizedStakeMapping;
  // AssetId=>(Staker => stakes)
  mapping(uint256 => address payable[]) intendedStakeholders;
  // AssetId => Asset
  mapping(uint256 => Asset) assetMaping;

  /**
   * @dev Throws if called by any account other than the seller.
   * @param _assetId Asset ID
   */
  modifier onlySeller(uint256 _assetId) {
    Asset storage asset = assetMaping[_assetId];
    require(asset.seller == msg.sender, "caller is not the seller");
    _;
  }

  /**
   * @dev Throws if intended stakes are not valid
   * @param _assetId Asset ID
   */
  modifier validIntendedStakes(uint256 _assetId) {
    uint256 allStakes = getAllIntendedStakes(_assetId);
    Asset storage asset = assetMaping[_assetId];
    require(allStakes >= asset.price, "price is higher than all stakes combined");
    _;
  }

  /**
   * @notice A method to check if an address is an intended stakeholder.
   * @param _assetId The asset ID to verify
   * @param _address The address to verify.
   * @return bool, uint256 Whether the address is a stakeholder,
   * and if so its position in the stakeholders array.
   */
  function isIntendedStakeholder(uint256 _assetId, address _address)
    public
    view
    returns (bool, uint256)
  {
    for (uint256 s = 0; s < intendedStakeholders[_assetId].length; s += 1) {
      if (_address == intendedStakeholders[_assetId][s]) return (true, s);
    }
    return (false, 0);
  }

  /**
   * @notice A method to retrieve the intended stake for a stakeholder.
   * @param _address The address
   * @param _assetId The asset ID
   * @return Stake The amount staked and the time since when it's staked.
   */
  function intendedStakeOf(uint256 _assetId, address _address)
    public
    view
    returns (StakeInfo memory)
  {
    return intendedStakesMapping[_assetId][_address];
  }

  /**
   * @notice A method to retrieve the all intended stakes for a stakeholder.
   * @param _assetId The asset ID
   * @return Stake The amount staked and the time since when it's staked.
   */
  function allIntendedStakesOf(uint256 _assetId) public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < intendedStakeholders[_assetId].length; i++) {
      total = intendedStakesMapping[_assetId][intendedStakeholders[_assetId][i]].amount.add(total);
    }
    return total;
  }

  /**
   * @notice A method to retrieve the finalized stake for a finalized stakeholder.
   * @param _address The address
   * @param _assetId The asset ID
   * @return Stake The amount staked and the time since when it's staked.
   */
  function finalizedStakeOf(uint256 _assetId, address _address)
    public
    view
    returns (StakeInfo memory)
  {
    return finalizedStakeMapping[_assetId][_address];
  }

  /**
   * @notice A method to publish asset
   * @param _name Name of the Asset
   * @param _uri URI of the Asset
   * @param _price Price of the Asset
   * @return Asset
   */
  function publishAsset(
    string calldata _name,
    string calldata _uri,
    uint256 _price
  ) external returns (Asset memory) {
    maxAssetId = maxAssetId.add(1);
    Asset memory asset = Asset(maxAssetId, _name, _uri, _price, payable(msg.sender));
    assetMaping[maxAssetId] = asset;
    return asset;
  }

  /**
   * @notice A method to get asset from ID
   * @param _assetId Asset of ID
   * @return Asset
   */
  function assetOfId(uint256 _assetId) external view returns (Asset memory) {
    return assetMaping[_assetId];
  }

  /**
   * @notice A method to get assets of seller
   * @param _sellerAddress Address of seller
   * @return Asset[] memory
   */
  function assetsOfSeller(address _sellerAddress) external view returns (Asset[] memory) {
    Asset[] memory assets = new Asset[](assetsCountOfSeller(_sellerAddress));
    uint256 currentIndex = 0;
    for (uint256 i = 1; i <= maxAssetId; i++) {
      if (assetMaping[i].seller == _sellerAddress) {
        assets[currentIndex] = assetMaping[i];
        currentIndex += 1;
      }
    }
    return assets;
  }

  function assetsCountOfSeller(address _sellerAddress) internal view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 1; i <= maxAssetId; i++) {
      if (assetMaping[i].seller == _sellerAddress) {
        count += 1;
      }
    }
    return count;
  }

  /**
   * @notice A method to stake on the asset
   * @param _assetId Asset ID
   */
  function stake(uint256 _assetId) external payable {
    StakeInfo storage stake = intendedStakesMapping[_assetId][msg.sender];
    uint256 since = block.timestamp;
    if (stake.since > 0) {
      since = stake.since;
    }
    intendedStakesMapping[_assetId][msg.sender] = StakeInfo(stake.amount + msg.value, since);
    addIntendedStakeholder(_assetId, payable(msg.sender));
  }

  /**
   * @notice A method to add a stakeholder.
   * @param _assetId The asset ID to verify
   * @param _stakeholder The stakeholder to add.
   */
  function addIntendedStakeholder(uint256 _assetId, address payable _stakeholder) internal {
    (bool _isStakeholder, ) = isIntendedStakeholder(_assetId, _stakeholder);
    if (!_isStakeholder) intendedStakeholders[_assetId].push(_stakeholder);
  }

  /**
   * @notice A method to finalize a sale
   * @param _assetId The asset ID to sell
   */
  function finalize(uint256 _assetId) external onlySeller(_assetId) validIntendedStakes(_assetId) {
    uint256 remainingStakes = assetMaping[_assetId].price;
    for (uint256 i = 0; i < intendedStakeholders[_assetId].length; i++) {
      StakeInfo storage stake = intendedStakesMapping[_assetId][intendedStakeholders[_assetId][i]];
      if (remainingStakes >= stake.amount) {
        finalizedStakeMapping[_assetId][intendedStakeholders[_assetId][i]] = StakeInfo(
          stake.amount,
          stake.since
        );
      } else if (remainingStakes > 0) {
        finalizedStakeMapping[_assetId][intendedStakeholders[_assetId][i]] = StakeInfo(
          remainingStakes,
          stake.since
        );
        intendedStakeholders[_assetId][i].transfer(stake.amount - remainingStakes);
      } else {
        intendedStakeholders[_assetId][i].transfer(stake.amount);
      }
    }
    assetMaping[_assetId].seller.transfer(assetMaping[_assetId].price);
  }

  function getAllIntendedStakes(uint256 _assetId) internal view returns (uint256) {
    uint256 stakeAmount = 0;
    for (uint256 i = 0; i < intendedStakeholders[_assetId].length; i++) {
      StakeInfo storage stake = intendedStakesMapping[_assetId][intendedStakeholders[_assetId][i]];
      stakeAmount = stake.amount.add(stake.amount);
    }
    return stakeAmount;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}