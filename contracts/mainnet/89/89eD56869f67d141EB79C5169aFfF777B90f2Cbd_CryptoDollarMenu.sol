// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Crypto Dollar Menu: Great Deals For Tough Times
/// @author cryptodollarmenu.com
/// @notice Claim, contribute and burn $CDM with a maximum of 5_500_000_000.
contract CryptoDollarMenu is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    /// @notice The minted amount of $CDM tokens that are burned.
    /// @dev This $CDM is burned using the ERC20 contract method.
    uint256 public burnedAmount;

    /// @notice A count of the number of $CDM claims made.
    /// @dev claimCount will always be below MAX_CLAIMS.
    uint256 public claimCount;

    /// @notice The minted amount of $CDM tokens allocated for staking rewards.
    /// @dev This $CDM is sent directly to the rewards conract.
    uint256 public createdStakingRewards;

    /// @notice The amount of $CDM tokens created.
    /// @dev Includes claimed, contributed and burned $CDM.
    uint256 public currentCreated;

    /// @notice The claimed amount of $CDM tokens.
    /// @dev Includes only minted and claimed $CDM while excluding burned and contibuted.
    uint256 public currentClaimed;

    /// @notice The IERC721 conctract to which $CDM rewards contributions are sent.
    /// @dev Deployed prior to the deployment of this contract so that it can be set permanently.
    address public rewardsContract = 0xAFfa8fA8a7D54e4a55fCF8CdaDC2b1113a724a20;

    /// @notice The maximum number of $CDM claims available + 1.
    uint256 public constant MAX_CLAIMS = 10_001;

    /// @notice The maximum amount of $CDM that can be created.
    /// @dev This differs from the current totalSupply as it includes all burned tokens.
    uint256 public constant MAX_CREATED = 5500000000000000000000000000; // 5_500_000_000 in Ether


    /// @notice The claim rewards base value to be used starting at 5_000 claims.
    function getClaimRewardBaseHigh(uint256 current) public pure returns (uint256) {
        // Define the values that should be assigned to `claimRewardBase`
        // Based on which range `current` falls into
        uint256 CLAIM_REWARD_BASE_1 = 500000000000000000000000;
        uint256 CLAIM_REWARD_BASE_2 = 400000000000000000000000;
        uint256 CLAIM_REWARD_BASE_3 = 300000000000000000000000;
        uint256 CLAIM_REWARD_BASE_4 = 200000000000000000000000;
        uint256 CLAIM_REWARD_BASE_5 = 100000000000000000000000;

        uint256 claimRewardBase;

        if (current > 4_999 && current < 6_000) {
            claimRewardBase = CLAIM_REWARD_BASE_1;
        } else if (current > 5_999 && current < 7_000) {
            claimRewardBase = CLAIM_REWARD_BASE_2;
        } else if (current > 6_999 && current < 8_000) {
            claimRewardBase = CLAIM_REWARD_BASE_3;
        } else if (current > 7_999 && current < 9_000) {
            claimRewardBase = CLAIM_REWARD_BASE_4;
        } else if (current > 8_999 && current < 10_001) {
            claimRewardBase = CLAIM_REWARD_BASE_5;
        }

        return claimRewardBase;
    }

    /// @notice The claim rewards base value to be used below 5_000 claims.
    function getClaimRewardBaseLow(uint256 current) public pure returns (uint256) {
        // Define the values that should be assigned to `claimRewardBase`
        // Based on which range `current` falls into
        uint256 CLAIM_REWARD_BASE_1 = 1000000000000000000000000;
        uint256 CLAIM_REWARD_BASE_2 = 900000000000000000000000;
        uint256 CLAIM_REWARD_BASE_3 = 800000000000000000000000;
        uint256 CLAIM_REWARD_BASE_4 = 700000000000000000000000;
        uint256 CLAIM_REWARD_BASE_5 = 600000000000000000000000;

        uint256 claimRewardBase;

        if (current < 1_000) {
            claimRewardBase = CLAIM_REWARD_BASE_1;
        } else if (current > 999 && current < 2_000) {
            claimRewardBase = CLAIM_REWARD_BASE_2;
        } else if (current > 1_999 && current < 3_000) {
            claimRewardBase = CLAIM_REWARD_BASE_3;
        } else if (current > 2_999 && current < 4_000) {
            claimRewardBase = CLAIM_REWARD_BASE_4;
        } else if (current > 3_999 && current < 5_000) {
            claimRewardBase = CLAIM_REWARD_BASE_5;
        }

        return claimRewardBase;
    }

    /// @notice A struct indicating that an address has made a claim and their count when they made it.
    struct ClaimDetail {
        address user;
        uint256 count;
    }

    /// @notice An address is used a key to each struct of information for a given user claim.
    /// @dev Adding an address to user claims restricts multiple claims per wallet.
    mapping(address => ClaimDetail) public userClaims;

    /// @notice Emitted when a claim is made.
    event UserClaim(address indexed user, uint256 count, uint256 claimAmount);

    /// @notice Create the $CDM ERC20 contract.
    constructor() ERC20("Crypto Dollar Menu", "CDM") {}

    /// @notice A random claim of $CDM that sends the remaining base claim amount to staking rewards.
    /// @param picked A random uint256 input by a user to give an added degree of randomness.
    function claimContribute(uint256 picked) external {
        uint256 _claimCount = claimCount;
        uint256 _createdStakingRewards = createdStakingRewards;
        uint256 _currentCreated = currentCreated;
        uint256 _currentClaimed = currentClaimed;
        uint256 _claimRewardBase;

        _claimRewardBase = (_claimCount < 5_000) ? getClaimRewardBaseLow(_claimCount) : getClaimRewardBaseHigh(_claimCount);

        uint256 generatedValue = getGenerated(picked, _claimCount);
        uint256 amountRequired = _currentCreated + _claimRewardBase;
        uint256 claimAmount = randomClaim(picked, _claimCount, generatedValue, _claimRewardBase);
        uint256 unclaimedAmount = _claimRewardBase - claimAmount;

        require(amountRequired < MAX_CREATED);
        require(_claimCount < MAX_CLAIMS, "Max claims reached");
        require(userClaims[_msgSender()].count == 0, "Wallet already claimed");

        _mint(_msgSender(), claimAmount);
        _mint(rewardsContract, unclaimedAmount);

        _claimCount++;
        claimCount = _claimCount;

        _currentCreated += _claimRewardBase;
        currentCreated = _currentCreated;

        _currentClaimed += claimAmount;
        currentClaimed = _currentClaimed;

        _createdStakingRewards += unclaimedAmount;
        createdStakingRewards = _createdStakingRewards;

        // Create and store new ClaimDetail
        ClaimDetail memory claimDetail = ClaimDetail({
            user: _msgSender(),
            count: _claimCount
        });

        userClaims[_msgSender()] = claimDetail;

        emit UserClaim(_msgSender(), _claimCount, claimAmount);
    }

    /// @notice A random claim of $CDM that burns the remaining base claim amount.
    /// @param picked A random uint256 input by a user to give an added degree of randomness.
    /// @dev This is only available at 5_000 claims and above.
    function claimBurn(uint256 picked) external {
        uint256 _burnedAmount = burnedAmount;
        uint256 _claimCount = claimCount;
        uint256 _currentCreated = currentCreated;
        uint256 _currentClaimed = currentClaimed;
        uint256 _claimRewardBase = getClaimRewardBaseHigh(_claimCount);
        uint256 amountRequired = _currentCreated + _claimRewardBase;
        uint256 generatedValue = getGenerated(picked, _claimCount);
        uint256 claimAmount = randomClaim(picked, _claimCount, generatedValue, _claimRewardBase);
        uint256 unclaimedAmount = _claimRewardBase - claimAmount;

        require(_claimCount > 4_999, "Burn not yet available");
        require(_claimCount < MAX_CLAIMS, "Max claims reached");
        require(amountRequired < MAX_CREATED);
        require(userClaims[_msgSender()].count == 0, "Wallet already claimed");

        _mint(_msgSender(), claimAmount);
        _mint(_msgSender(), unclaimedAmount);
        _burn(_msgSender(), unclaimedAmount);

        _claimCount++;
        claimCount = _claimCount;

        _currentCreated += _claimRewardBase;
        currentCreated = _currentCreated;

        _currentClaimed += claimAmount;
        currentClaimed = _currentClaimed;

        _burnedAmount += unclaimedAmount;
        burnedAmount = _burnedAmount;

        // Create and store new ClaimDetail
        ClaimDetail memory claimDetail = ClaimDetail({
            user: _msgSender(),
            count: _claimCount
        });

        userClaims[_msgSender()] = claimDetail;

        emit UserClaim(_msgSender(), _claimCount, claimAmount);
    }

    /// @notice Determine if claim and burn is available using a boolean.
    /// @return A boolean indicating whether claim and burn is available.
    function getBurnAvailable() external view returns (bool) {
        uint256 _claimCount = claimCount;
        bool status = (_claimCount < 5000) ? false : true;
        return status;
    }

    /// @notice Provides a statement used to display if claim and burn is available.
    /// @return A statement indicating the availability of claim and burn.
    function getBurnStatement() external view returns (string memory) {
        string memory available = "Burn available.";
        string memory notAvailable = "Burn not available.";
        uint256 _claimCount = claimCount;
        string memory status = (_claimCount < 5000) ? notAvailable : available;
        return status;
    }

    /// @notice An explicit function to determine the amount of $CDM contributed for rewards.
    /// @return The amount of $CDM currently contributed as rewards expressed in Wei.
    function getCreatedStakingRewards() external view returns (uint256) {
        return createdStakingRewards;
    }

    /// @notice An explicit function to determine the amount of $CDM created.
    /// @dev Includes claimed, contributed and burned tokens.
    /// @return The amount of currently created $CDM tokens expressed in Wei.
    function getCurrentCreated() external view returns (uint256) {
        return currentCreated;
    }

    /// @notice An explicit function to determine the amount of $CDM claimed.
    /// @dev Excludes contributed and burned $CDM.
    /// @return The amount of currently claimed $CDM tokens expressed in Wei.
    function getCurrentClaimed() external view returns (uint256) {
        return currentClaimed;
    }

    /// @notice An explicit function to determine the current max claim.
    /// @return The maximum amount of $CDM that can currently be claimed.
    function getCurrentMaxClaim() external view returns (uint256) {
        uint256 _claimCount = claimCount;
        uint256 _claimRewardBase;
        _claimRewardBase = (_claimCount < 5_000) ? getClaimRewardBaseLow(_claimCount) : getClaimRewardBaseHigh(_claimCount);
        return _claimRewardBase;
    }

    /// @notice Get struct providing the information for a speciic user claim.
    /// @return The claim detail for a specific address.
    function getUserClaim(address user) external view returns (ClaimDetail memory) {
        return userClaims[user];
    }

    /// @notice An explicit function to return the maximum about of $CDM that can be created.
    /// @return The maximum amount of $CDM that can be created expressed in Wei.
    function getMaximumCreated() external pure returns (uint256) {
        return MAX_CREATED;
    }

    /// @notice An explicit function to provide the current total supply of $CDM.
    /// @dev This does not include burned $CDM.
    /// @return Retuns the current total supply of $CDM.
    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    /// @notice A function to generate a random uint256 value using two uint256 inputs.
    function getGenerated(uint256 a, uint256 b) private view returns (uint256) {
        uint256 generated = random(string(abi.encodePacked("9b96e70d-c72a-47de-b5ed-6e325b14a60c", block.timestamp, _msgSender(), toString(a), toString(b))));
        return generated;
    }

    /// @notice Create a random claim amount between 0 and the claim reward base amount.
    /// @param a A variable input to create randomness.
    /// @param b A variable input to create randomness.
    /// @param c A variable input to create randomness.
    /// @param reward The claim reward base value.
    /// @return A random claim value.
    function randomClaim(uint256 a, uint256 b, uint256 c, uint256 reward) private view returns (uint256) {
        uint256 v = uint(keccak256(abi.encodePacked("459ead19-8da5-40a6-b958-4ae8f04786c7", block.timestamp, toString(a), toString(b), toString(c)))) % reward;
        return v;
    }

    /// @notice A general random function to be used to shuffle and generate values.
    /// @param input Any string value to be randomized.
    /// @return The output of a random hash using keccak256.
    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /// @notice Returns an uint256 value as a string.
    /// @param value The uint256 value to have a type change.
    /// @return A string of the inputted uint256 value.
    function toString(uint256 value) private pure returns (string memory) {
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

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}