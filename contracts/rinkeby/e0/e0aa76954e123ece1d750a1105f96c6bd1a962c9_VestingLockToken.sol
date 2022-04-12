/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File contracts/utils/VersionedInitializable.sol

pragma solidity 0.8.9;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Bitcoinnami, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 internal lastInitializedRevision;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(revision > lastInitializedRevision, "Contract instance has already been initialized");

    lastInitializedRevision = revision;

    _;
  }

  /// @dev returns the revision number of the contract.
  /// Needs to be defined in the inherited class as a constant.
  function getRevision() internal pure virtual returns (uint256);

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// File contracts/private-sale/VestingLockToken.sol

pragma solidity 0.8.9;
pragma abicoder v2;



/**
 * @title Vestiong Lock XX token
 * @dev Contract
 * - Validate whitelist seller
 * - Validate timelock
 * @author XX
 **/
contract VestingLockToken is VersionedInitializable {
	using SafeMath for uint256;

	struct UserData {
		uint256 lockAmount;
		uint256 claimedAmount;
		uint256 firstReleaseAmount;
		uint256 totalUnlockBlock;
		uint256 totalCiffBlock;
		uint256 firstReleaseBlock;
		bool isEnable;
	}

	uint256 public constant REVISION = 1;
	address public lockedToken;
	address public admin;
	mapping(address => UserData) public lockUser;

	modifier onlyAdmin() {
		require(msg.sender == admin, "INVALID ADMIN");
		_;
	}

	constructor() {}

	/**
	 * @dev Called by the proxy contract
	 **/
	function initialize(address admin_, address lockToken_) external initializer {
		admin = admin_;
		lockedToken = lockToken_;
	}

	/**
	 * @dev returns the revision of the implementation contract
	 * @return The revision
	 */
	function getRevision() internal pure override returns (uint256) {
		return REVISION;
	}

	/**
	 * @dev Withdraw Token in contract to an address, revert if it fails.
	 * @param recipient recipient of the transfer
	 * @param token token withdraw
	 */
	function withdrawFunc(address recipient, address token) public onlyAdmin {
		IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
	}

	/**
	 * @dev Withdraw ETH to an address, revert if it fails.
	 * @param recipient recipient of the transfer
	 * @param amountETH amount of the transfer
	 */
	function withdrawETH(address recipient, uint256 amountETH) public onlyAdmin {
		if (amountETH > 0) {
			_safeTransferETH(recipient, amountETH);
		} else {
			_safeTransferETH(recipient, address(this).balance);
		}
	}

	/**
	 * @dev transfer ETH to an address, revert if it fails.
	 * @param to recipient of the transfer
	 * @param value the amount to send
	 */
	function _safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "ETH_TRANSFER_FAILED");
	}

	/**
	 * @dev Set Token for lock.
	 * @param lock_token token for sale
	 */
	function setLockToken(address lock_token) public onlyAdmin {
		lockedToken = lock_token;
	}

	/**
	 * @dev Skipp first release wtih TGE=0
	 * @param recipient ref
	 */
	function skippFirstRelease(address recipient) public onlyAdmin {
		lockUser[recipient].firstReleaseBlock = block.number;
	}

	/**
   * @dev Enable Claim when TGE
    * @param vestingAddress vestingAddress
   * @param enable enable

   */
	function enableClaim(address[] calldata vestingAddress, bool enable) public onlyAdmin {
		for (uint256 i = 0; i < vestingAddress.length; i++) {
			lockUser[vestingAddress[i]].isEnable = enable;
		}
	}

	/**
	 * @dev Set lock adress with amount and TGE
	 * @param recipient lock address
	 * @param lockAmount Lock amount
	 * @param firstReleaseAmount TGE amount
	 */
	function setLockUser(
		address recipient,
		uint256 lockAmount,
		uint256 firstReleaseAmount,
		bool enable,
		uint256 totalCiffBlock,
		uint256 totalUnlockBlock
	) public onlyAdmin {
		lockUser[recipient].isEnable = enable;
		lockUser[recipient].lockAmount = lockAmount;
		lockUser[recipient].firstReleaseAmount = firstReleaseAmount;
		lockUser[recipient].totalCiffBlock = totalCiffBlock;
		lockUser[recipient].totalUnlockBlock = totalUnlockBlock;
	}

	/**
	 * @dev Get Claimable sell oken
	 * @param buyerAddress Adddress of buyer
	 * @return Amount sell token can claimed
	 **/
	function getClaimable(address buyerAddress) public view returns (uint256) {
		require(lockUser[buyerAddress].isEnable, "Address must be unlock");
		if (lockUser[buyerAddress].firstReleaseBlock == 0) {
			return lockUser[buyerAddress].firstReleaseAmount;
		}

		uint256 startUnlockBlock = lockUser[buyerAddress].firstReleaseBlock + lockUser[buyerAddress].totalCiffBlock;
		if (block.number < startUnlockBlock) {
			return 0;
		}
		uint256 progressBlock = block.number - startUnlockBlock;
		if (progressBlock < lockUser[buyerAddress].totalUnlockBlock) {
			uint256 tokenPerBlock = lockUser[buyerAddress].lockAmount / lockUser[buyerAddress].totalUnlockBlock;
			return tokenPerBlock * progressBlock - lockUser[buyerAddress].claimedAmount;
		} else {
			return lockUser[buyerAddress].lockAmount - lockUser[buyerAddress].claimedAmount;
		}
	}

	/**
	 * @dev Set total unlock block
	 * @param recipient receipt address token
	 */
	function claim(address recipient) public {
		require(lockUser[recipient].isEnable, "White list invalid");
		uint256 claimableAmount = getClaimable(recipient);
		require(claimableAmount > 0, "Claim amount must be greater than zero");
		if (lockUser[recipient].firstReleaseBlock == 0) {
			lockUser[recipient].firstReleaseBlock = block.number;
		} else {
			lockUser[recipient].claimedAmount += claimableAmount;
		}
		IERC20(lockedToken).transfer(recipient, claimableAmount);
	}
}