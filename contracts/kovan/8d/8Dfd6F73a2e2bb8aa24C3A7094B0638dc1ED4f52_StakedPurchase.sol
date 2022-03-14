// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakedPurchase is Ownable {
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
   */
  modifier onlySeller(uint256 _assetId) {
    Asset storage asset = assetMaping[_assetId];
    require(asset.seller == msg.sender, "caller is not the seller");
    _;
  }

  /**
   * @dev Throws if intended stakes are not valid
   */
  modifier validIntendedStakes(uint256 _assetId) {
    uint256 allStakes = getAllIntendedStakes(_assetId);
    Asset storage asset = assetMaping[_assetId];
    require(allStakes >= asset.price, "price is higher than all stakes combined");
    _;
  }

  /**
   * @notice A method to check if an address is a stakeholder.
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
   * @param _address The address to verify.
   * @param _assetId The asset ID to verify
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
   * @notice A method to retrieve the finalized stake for a stakeholder.
   * @param _address The address to verify.
   * @param _assetId The asset ID to verify
   * @return Stake The amount staked and the time since when it's staked.
   */
  function finalizedStakeOf(uint256 _assetId, address _address)
    public
    view
    returns (StakeInfo memory)
  {
    return finalizedStakeMapping[_assetId][_address];
  }

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

  function assetOfId(uint256 _assetId) external view returns (Asset memory) {
    return assetMaping[_assetId];
  }

  function assetsOfSeller(address _sellerAddress) external view returns (Asset[] memory) {
    Asset[] memory assets=new Asset[](assetsCountOfSeller(_sellerAddress));
    uint256 currentIndex = 0;
    for (uint256 i = 1; i <= maxAssetId; i++) {
      if (assetMaping[i].seller == _sellerAddress) {
        assets[currentIndex]=assetMaping[i];
        currentIndex+=1;
      }
    }
    return assets;
  }

  function assetsCountOfSeller(address _sellerAddress) internal view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 1; i <= maxAssetId; i++) {
      if (assetMaping[i].seller == _sellerAddress) {
        count+=1;
      }
    }
    return count;
  }

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
   * @notice A method to add a stakeholder.
   * @param _assetId The asset ID to verify
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}