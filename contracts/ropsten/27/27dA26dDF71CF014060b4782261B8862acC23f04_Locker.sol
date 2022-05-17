// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20.sol";

contract Locker is Ownable {
    using SafeMath for uint256;

    struct Deposit {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    address[] tokenAddressesWithFees;

    mapping(uint256 => Deposit) public lockedToken;
    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(address => uint256[]) public depositsByTokenAddress;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    event TokensLocked(
        address indexed tokenAddress,
        address indexed sender,
        uint256 amount,
        uint256 unlockTime,
        uint256 depositId
    );
    event TokensWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);
    event EmergencyTokensWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);
    event WithdrawSpecificToken(address indexed token, address indexed receiver, uint256 amount);
    event Renewed(uint256 indexed id, uint256 unlockeTime);

    function lockTokens(
        address _tokenAddress,
        uint256 _amount,
        address _withdrawalAddress,
        uint256 _unlockTime
    ) external payable onlyOwner {
        _lockTokens(_tokenAddress, _amount, _withdrawalAddress, _unlockTime);
    }

    function lockTokenMultiple(
        address _tokenAddress,
        uint256[] calldata _amounts,
        address[] calldata _withdrawalAddresses,
        uint256[] calldata _unlockTimes
    ) external payable onlyOwner {
        for (uint8 i = 0; i < _amounts.length; i++) {
            _lockTokens(_tokenAddress, _amounts[i], _withdrawalAddresses[i], _unlockTimes[i]);
        }
    }

    function _lockTokens(
        address _tokenAddress,
        uint256 _amount,
        address _withdrawalAddress,
        uint256 _unlockTime
    ) internal returns (uint256 _id) {
        require(_amount > 0, "Tokens amount must be greater than 0");
        require(_unlockTime < 10000000000, "Unix timestamp must be in seconds, not milliseconds");
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        require(
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
            "Failed to transfer tokens to locker"
        );

        uint256 lockAmount = _amount;

        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress]
            .add(_amount);

        _id = ++depositId;

        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = lockAmount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);

        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        depositsByTokenAddress[_tokenAddress].push(_id);

        emit TokensLocked(_tokenAddress, _withdrawalAddress, _amount, _unlockTime, depositId);
    }

    function emergencyWithdrawTokens(uint256 _id, address _receiver) external onlyOwner {
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        require(address(0) != _receiver, "Invalid receiver address");

        address tokenAddress = lockedToken[_id].tokenAddress;
        address withdrawalAddress = lockedToken[_id].withdrawalAddress;
        uint256 amount = lockedToken[_id].tokenAmount;

        require(IERC20(tokenAddress).transfer(_receiver, amount), "Failed to transfer tokens");

        lockedToken[_id].withdrawn = true;

        uint256 previousBalance = walletTokenBalance[tokenAddress][msg.sender];

        walletTokenBalance[tokenAddress][msg.sender] = previousBalance.sub(amount);

        uint256 i;
        uint256 j;
        uint256 byWLength = depositsByWithdrawalAddress[withdrawalAddress].length;
        uint256[] memory newDepositsByWithdrawal = new uint256[](byWLength - 1);

        for (j = 0; j < byWLength; j++) {
            if (depositsByWithdrawalAddress[withdrawalAddress][j] == _id) {
                for (i = j; i < byWLength - 1; i++) {
                    newDepositsByWithdrawal[i] = depositsByWithdrawalAddress[withdrawalAddress][i + 1];
                }
                break;
            } else {
                newDepositsByWithdrawal[j] = depositsByWithdrawalAddress[withdrawalAddress][j];
            }
        }

        depositsByWithdrawalAddress[withdrawalAddress] = newDepositsByWithdrawal;

        uint256 byTLength = depositsByTokenAddress[tokenAddress].length;
        uint256[] memory newDepositsByToken = new uint256[](byTLength - 1);

        for (j = 0; j < byTLength; j++) {
            if (depositsByTokenAddress[tokenAddress][j] == _id) {
                for (i = j; i < byTLength - 1; i++) {
                    newDepositsByToken[i] = depositsByTokenAddress[tokenAddress][i + 1];
                }
                break;
            } else {
                newDepositsByToken[j] = depositsByTokenAddress[tokenAddress][j];
            }
        }

        depositsByTokenAddress[tokenAddress] = newDepositsByToken;

        emit EmergencyTokensWithdrawn(tokenAddress, withdrawalAddress, amount);
    }

    function renewLock(uint256 _id, uint256 _unlockTime) external onlyOwner {
        require(block.timestamp >= lockedToken[_id].unlockTime, "Tokens are locked");
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        require(msg.sender == lockedToken[_id].withdrawalAddress, "Can withdraw from the address used for locking");
        require(_unlockTime > block.timestamp, "Unlock time must be in future");

        lockedToken[_id].unlockTime = _unlockTime;

        emit Renewed(_id, _unlockTime);
    }

    function withdrawDeposit(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTime, "Tokens are locked");
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        require(msg.sender == lockedToken[_id].withdrawalAddress, "Can withdraw from the address used for locking");

        address tokenAddress = lockedToken[_id].tokenAddress;
        address withdrawalAddress = lockedToken[_id].withdrawalAddress;
        uint256 amount = lockedToken[_id].tokenAmount;
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        if (balance < amount) {
            require(IERC20(tokenAddress).transfer(withdrawalAddress, balance), "Failed to transfer tokens");
        } else {
            require(IERC20(tokenAddress).transfer(withdrawalAddress, amount), "Failed to transfer tokens");
        }

        lockedToken[_id].withdrawn = true;

        uint256 previousBalance = walletTokenBalance[tokenAddress][msg.sender];

        walletTokenBalance[tokenAddress][msg.sender] = previousBalance.sub(amount);

        uint256 i;
        uint256 j;
        uint256 byWLength = depositsByWithdrawalAddress[withdrawalAddress].length;
        uint256[] memory newDepositsByWithdrawal = new uint256[](byWLength - 1);

        for (j = 0; j < byWLength; j++) {
            if (depositsByWithdrawalAddress[withdrawalAddress][j] == _id) {
                for (i = j; i < byWLength - 1; i++) {
                    newDepositsByWithdrawal[i] = depositsByWithdrawalAddress[withdrawalAddress][i + 1];
                }
                break;
            } else {
                newDepositsByWithdrawal[j] = depositsByWithdrawalAddress[withdrawalAddress][j];
            }
        }

        depositsByWithdrawalAddress[withdrawalAddress] = newDepositsByWithdrawal;

        uint256 byTLength = depositsByTokenAddress[tokenAddress].length;
        uint256[] memory newDepositsByToken = new uint256[](byTLength - 1);

        for (j = 0; j < byTLength; j++) {
            if (depositsByTokenAddress[tokenAddress][j] == _id) {
                for (i = j; i < byTLength - 1; i++) {
                    newDepositsByToken[i] = depositsByTokenAddress[tokenAddress][i + 1];
                }
                break;
            } else {
                newDepositsByToken[j] = depositsByTokenAddress[tokenAddress][j];
            }
        }

        depositsByTokenAddress[tokenAddress] = newDepositsByToken;

        emit TokensWithdrawn(tokenAddress, withdrawalAddress, amount);
    }

    function withdrawSpecificDeposit(
        address token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(address(0) != receiver, "Invalid receiver address");
        require(address(0) != token, "Invalid receiver address");
        require(amount >= 0, "Invaild amount");
        require(IERC20(token).transfer(receiver, amount));

        emit WithdrawSpecificToken(token, receiver, amount);
    }

    function getTotalTokenBalance(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) public view returns (uint256) {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    function getAllDepositIds() public view returns (uint256[] memory) {
        return allDepositIds;
    }

    function getDepositDetails(uint256 _id)
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        return (
            lockedToken[_id].tokenAddress,
            lockedToken[_id].withdrawalAddress,
            lockedToken[_id].tokenAmount,
            lockedToken[_id].unlockTime,
            lockedToken[_id].withdrawn
        );
    }

    function getDepositsByWithdrawalAddress(address _withdrawalAddress) public view returns (uint256[] memory) {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }

    function getDepositsByTokenAddress(address _tokenAddress) public view returns (uint256[] memory) {
        return depositsByTokenAddress[_tokenAddress];
    }

    function getCurrentEpochtime() public view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function rate() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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