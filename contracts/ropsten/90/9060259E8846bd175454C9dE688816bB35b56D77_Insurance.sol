// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Insurance is Ownable {
    // variable general
    address payable private admin;
    uint256 public totalInsurance;
    uint256 public quantity_nain_eligible_for_incentives;
    address public address_nain;
    bool private enable_nain;
    IERC20 token_nain;
    IERC20 usdt;

    // 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 address USDT bsc testnet
    // 0x539CAFC25E2983bcFC47503F5FD582B20Cbb56c7 address sc NAIN bsc testnet
    // 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83 ropsten testnet

    constructor() {
        admin = payable(msg.sender);
        totalInsurance = 0;
        usdt = IERC20(0x110a13FC3efE6A245B50102D2d79B3E76125Ae83);
        quantity_nain_eligible_for_incentives = 99 * 10**18;
        enable_nain = false;
    }

    // insurance struct
    struct InsuranceStruct {
        uint256 idInsurance;
        address buyer;
        string asset;
        uint256 margin;
        uint256 q_covered;
        uint256 p_market;
        uint256 p_claim;
        string state;
        uint256 period;
        uint256 recognition_date;
        uint256 expired;
        bool isUseNain;
    }

    // map id to insurance
    mapping(uint256 => InsuranceStruct) private insurance;

    /*
     @event
    **/
    event EBuyInsurance(
        uint256 idInsurance,
        address buyer,
        string asset,
        uint256 margin,
        uint256 q_covered,
        uint256 p_market,
        uint256 p_claim,
        string state,
        uint256 period,
        uint256 recognition_date,
        bool isUseNain
    );
    event EUpdateStateInsurance(uint256 idInsurance);
    event EUpdateQuantityNainEligibleForIncentives(
        uint256 quantity_nain_eligible_for_incentives
    );

    // Only admin has permission to perform this function
    modifier onlyContractCaller(address _caller) {
        require(
            msg.sender == _caller,
            "Only the person who is calling the contract will be executed"
        );
        _;
    }
    modifier checkAllowanceUSDT(uint256 amount) {
        require(
            usdt.allowance(msg.sender, address(this)) >= amount,
            "Error allowance"
        );
        _;
    }

    function configAddressNain(address _address_nain) external onlyOwner {
        address_nain = _address_nain;
        token_nain = IERC20(_address_nain);
        enable_nain = true;
    }

    function renounceNain() external onlyOwner {
        enable_nain = false;
    }

    function updateQuantityNainEligibleForIncentives(uint256 _quantity)
        external
        onlyOwner
    {
        quantity_nain_eligible_for_incentives = _quantity;
    }

    function insuranceState(uint256 _insuranceId)
        external
        view
        returns (InsuranceStruct memory)
    {
        return insurance[_insuranceId];
    }

    function createInsurance(
        address _buyer,
        string memory _asset,
        uint256 _margin,
        uint256 _q_covered,
        uint256 _p_market,
        uint256 _p_claim,
        uint256 _period,
        bool _isUseNain
    )
        external
        payable
        onlyContractCaller(_buyer)
        checkAllowanceUSDT(_margin)
        returns (InsuranceStruct memory)
    {
        require(
            _period >= 2 && _period <= 15,
            "The time must be within the specified range 2 - 15"
        );
        require(
            usdt.balanceOf(address(msg.sender)) >= _margin,
            "USDT does't enough or not approve please check again!"
        );

        if (_isUseNain && !enable_nain) {
            revert("This feature is disabled");
        }

        if (_isUseNain && enable_nain) {
            require(
                token_nain.balanceOf(address(msg.sender)) >=
                    quantity_nain_eligible_for_incentives,
                "NAIN does't enough, please check again!"
            );

            // transfer nain
            token_nain.transferFrom(
                msg.sender,
                admin,
                quantity_nain_eligible_for_incentives
            );
        }

        InsuranceStruct memory newInsurance = InsuranceStruct(
            totalInsurance + 1,
            _buyer,
            _asset,
            _margin,
            _q_covered,
            _p_market,
            _p_claim,
            "Available",
            _period,
            block.timestamp,
            block.timestamp,
            _isUseNain
        );

        usdt.transferFrom(msg.sender, admin, _margin);

        insurance[totalInsurance + 1] = newInsurance;

        emit EBuyInsurance(
            totalInsurance + 1,
            _buyer,
            _asset,
            _margin,
            _q_covered,
            _p_market,
            _p_claim,
            "Available",
            _period,
            block.timestamp,
            _isUseNain
        );

        // increase insurance identifier
        totalInsurance++;

        return newInsurance;
    }

    function updateStateInsurance(uint256 _idInsurance, string memory _state)
        external
        onlyOwner
        returns (bool)
    {
        require(
            compareString(_state, "Claim_waiting") ||
                compareString(_state, "Claimed") ||
                compareString(_state, "Refunded") ||
                compareString(_state, "Liquidated") ||
                compareString(_state, "Expired"),
            "State does not exist"
        );

        if (
            compareString(insurance[_idInsurance].state, "Claimed") ||
            compareString(insurance[_idInsurance].state, "Refunded") ||
            compareString(insurance[_idInsurance].state, "Liquidated") ||
            compareString(insurance[_idInsurance].state, "Expired")
        ) {
            revert("State has been update");
        }

        insurance[_idInsurance].state = _state;
        insurance[_idInsurance].recognition_date = block.timestamp;

        emit EUpdateStateInsurance(_idInsurance);

        return true;
    }

    /*
     @helper
    **/
    function compareString(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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