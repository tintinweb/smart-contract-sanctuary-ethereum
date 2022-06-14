// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './interfaces/IJBVeTokenUriResolver.sol';
import './libraries/JBErrors.sol';

contract JBVeTokenUriResolver is IJBVeTokenUriResolver, Ownable {
  uint8 public constant decimals = 18;
  string public baseUri = 'ipfs://QmSCaNi3VeyrV78qWiDgxdkJTUB7yitnLKHsPHudguc9kv/';

  /**
    @notice
    provides the metadata for the storefront
  */
  function contractURI() public pure override returns (string memory) {
    // TODO: Change to correct URI
    return 'https://metadata-url.com/my-metadata';
  }

  /** 
    @notice Sets the baseUri for the JBVeToken on IPFS.

    @param _baseUri The baseUri for the JBVeToken on IPFS.  
  */
  function setBaseURI(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  /** 
    @notice Computes the metadata url.

    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _lockDurationOptions The options that the duration can be.

    @return The metadata url.
  */
  function tokenURI(
    uint256,
    uint256 _amount,
    uint256 _duration,
    uint256,
    uint256[] memory _lockDurationOptions
  ) external view override returns (string memory) {
    if (_amount <= 0) revert JBErrors.INSUFFICIENT_BALANCE();

    if (_duration <= 0) revert JBErrors.INVALID_LOCK_DURATION();

    return
      string(
        abi.encodePacked(
          baseUri,
          Strings.toString(
            _getTokenRange(_amount) * 5 + _getTokenStakeMultiplier(_duration, _lockDurationOptions)
          )
        )
      );
  }

  /**
    @notice Returns the veBanny character index needed to compute the righteous veBanny on IPFS.

    @dev The range values referenced below were gleaned from the following Notion URL.  
    https://www.notion.so/juicebox/veBanny-proposal-from-Jango-2-68c6f578bef84205a9f87e3f1057aa37

    @param _amount Amount of locked Juicebox.     

    @return The token range index or veBanny character commensurate with amount of locked Juicebox.
  */
  function _getTokenRange(uint256 _amount) private pure returns (uint256) {
    // Reduce amount to exclude decimals
    _amount = _amount / 10**decimals;

    if (_amount < 100) {
      return 0;
    } else if (_amount < 200) {
      return 1;
    } else if (_amount < 300) {
      return 2;
    } else if (_amount < 400) {
      return 3;
    } else if (_amount < 500) {
      return 4;
    } else if (_amount < 600) {
      return 5;
    } else if (_amount < 700) {
      return 6;
    } else if (_amount < 800) {
      return 7;
    } else if (_amount < 900) {
      return 8;
    } else if (_amount < 1_000) {
      return 9;
    } else if (_amount < 2_000) {
      return 10;
    } else if (_amount < 3_000) {
      return 11;
    } else if (_amount < 4_000) {
      return 12;
    } else if (_amount < 5_000) {
      return 13;
    } else if (_amount < 6_000) {
      return 14;
    } else if (_amount < 7_000) {
      return 15;
    } else if (_amount < 8_000) {
      return 16;
    } else if (_amount < 9_000) {
      return 17;
    } else if (_amount < 10_000) {
      return 18;
    } else if (_amount < 12_000) {
      return 19;
    } else if (_amount < 14_000) {
      return 20;
    } else if (_amount < 16_000) {
      return 21;
    } else if (_amount < 18_000) {
      return 22;
    } else if (_amount < 20_000) {
      return 23;
    } else if (_amount < 22_000) {
      return 24;
    } else if (_amount < 24_000) {
      return 25;
    } else if (_amount < 26_000) {
      return 26;
    } else if (_amount < 28_000) {
      return 27;
    } else if (_amount < 30_000) {
      return 28;
    } else if (_amount < 40_000) {
      return 29;
    } else if (_amount < 50_000) {
      return 30;
    } else if (_amount < 60_000) {
      return 31;
    } else if (_amount < 70_000) {
      return 32;
    } else if (_amount < 80_000) {
      return 33;
    } else if (_amount < 90_000) {
      return 34;
    } else if (_amount < 100_000) {
      return 35;
    } else if (_amount < 200_000) {
      return 36;
    } else if (_amount < 300_000) {
      return 37;
    } else if (_amount < 400_000) {
      return 38;
    } else if (_amount < 500_000) {
      return 39;
    } else if (_amount < 600_000) {
      return 40;
    } else if (_amount < 700_000) {
      return 41;
    } else if (_amount < 800_000) {
      return 42;
    } else if (_amount < 900_000) {
      return 43;
    } else if (_amount < 1_000_000) {
      return 44;
    } else if (_amount < 2_000_000) {
      return 45;
    } else if (_amount < 3_000_000) {
      return 46;
    } else if (_amount < 4_000_000) {
      return 47;
    } else if (_amount < 5_000_000) {
      return 48;
    } else if (_amount < 6_000_000) {
      return 49;
    } else if (_amount < 7_000_000) {
      return 50;
    } else if (_amount < 8_000_000) {
      return 51;
    } else if (_amount < 9_000_000) {
      return 52;
    } else if (_amount < 10_000_000) {
      return 53;
    } else if (_amount < 20_000_000) {
      return 54;
    } else if (_amount < 40_000_000) {
      return 55;
    } else if (_amount < 60_000_000) {
      return 56;
    } else if (_amount < 100_000_000) {
      return 57;
    } else if (_amount < 600_000_000) {
      return 58;
    } else {
      return 59;
    }
  }

  /**
     @notice Returns the token duration multiplier needed to index into the righteous veBanny mediallion background.

     @param _duration Time in seconds corresponding with one of five acceptable staking durations. 
     The Staking durations below were gleaned from the JBVeNft.sol contract line 55-59.
     Returns the duration multiplier used to index into the proper veBanny mediallion on IPFS.
  */
  function _getTokenStakeMultiplier(uint256 _duration, uint256[] memory _lockDurationOptions)
    private
    pure
    returns (uint256)
  {
    for (uint256 _i = 0; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] == _duration) return _i + 1;
    revert JBErrors.INVALID_LOCK_DURATION();
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBVeTokenUriResolver {
  /**
    @notice
    provides the metadata for the storefront
  */
  function contractURI() external view returns (string memory);

  /**
    @notice 
    Computes the metadata url.
    @param _tokenId TokenId of the Banny
    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _lockedUntil Total lock-in period.
    @param _lockDurationOptions The options that the duration can be.

    @return The metadata url.
  */
  function tokenURI(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _duration,
    uint256 _lockedUntil,
    uint256[] memory _lockDurationOptions
  ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBErrors {
  // common errors
  error INVALID_LOCK_DURATION();
  error INSUFFICIENT_BALANCE();
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