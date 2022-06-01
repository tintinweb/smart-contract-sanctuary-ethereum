/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity ^0.8.13;

contract TerraformStaking is Ownable {
    using SafeMath for uint256;

    struct Bracket {
        uint256 lockedDays;
        uint256 APYRewards;
        bool enabled;
    }

    struct DepositInfo {
        uint256 amount;
        uint256 timestamp;
    }
 
    struct TruthStake {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }

    struct Deposit {
        DepositInfo info;
        Bracket bracket;
        TruthStake truth;
        uint256 claimed;
        bool active;
        bool truthcircle;
    }
   

    uint256 private PRECISION_FACTOR = 10000;
    IERC20 public depositToken;
    IERC20 public rewardsToken;
    IERC721 public truthToken;
    bool public terraFormInitiated = false;

    address[] public depositAddresses;
    uint256[] public stakedTokenIds;
    mapping (uint256 => Bracket) public brackets;
    mapping (address => Deposit) public deposits;

    event UserDeposit(address wallet, uint256 amount);
    event RewardsWithdraw(address wallet, uint256 rewardsAmount);
    event FullWithdraw(address wallet, uint256 depositAmount, uint256 rewardsAmount, uint256 tokenId);
    event ExtendLock(address wallet, uint256 duration);
    event UserTruthStake(address wallet, uint256 tokenId);

    function calculateRewards(address wallet) public view returns (uint256) {
        uint256 rewards = 0;
        Deposit memory userDeposit = deposits[wallet];
        if (userDeposit.active) {
            uint256 depositSeconds = block.timestamp.sub(userDeposit.info.timestamp);
            uint256 APYRate = userDeposit.bracket.APYRewards;
            if (userDeposit.truthcircle) {
                APYRate = APYRate + APYRate.div(100).mul(5);   
                uint256 baseSeconds = userDeposit.truth.timestamp.sub(userDeposit.info.timestamp);
                uint256 truthSeconds = block.timestamp.sub(userDeposit.truth.timestamp);
                uint256 grossrewards = userDeposit.info.amount.mul(userDeposit.bracket.APYRewards).mul(baseSeconds) + userDeposit.info.amount.mul(APYRate).mul(truthSeconds);
                rewards = grossrewards.div(365).div(86400).div(PRECISION_FACTOR);
            }
            else {
                //figure out total tokens to earn
                uint256 calcdrewards = userDeposit.info.amount.mul(APYRate).mul(depositSeconds);
                //break rewards down to rewards per second
                rewards = calcdrewards.div(365).div(86400).div(PRECISION_FACTOR);
            }
        }
        return rewards.sub(userDeposit.claimed);
    }

    function deposit(uint256 tokenAmount, uint256 bracket) external {
        require(!deposits[_msgSender()].active, "user has already deposited");
        require(brackets[bracket].enabled, "bracket is not enabled");
        require(terraFormInitiated, "Terraform Staking Not Live");

        // transfer tokens
        uint256 previousBalance = depositToken.balanceOf(address(this));
        depositToken.transferFrom(_msgSender(), address(this), tokenAmount);
        uint256 deposited = depositToken.balanceOf(address(this)).sub(previousBalance);

        // deposit logic
        DepositInfo memory info = DepositInfo(deposited, block.timestamp);
        TruthStake memory truth = TruthStake(0,0,0);
        deposits[_msgSender()] = Deposit(info, brackets[bracket], truth, 0, true, false);
        depositAddresses.push(_msgSender());
        emit UserDeposit(_msgSender(), deposited);
    }

    function updateDeposit(address _wallet, uint256 _bracket, uint256 _lockedDays, uint256 _APYRewards) external onlyOwner {
        require(deposits[_wallet].active, "user has no active deposits");
        require(brackets[_bracket].enabled, "bracket is not enabled");
        deposits[_wallet].bracket.lockedDays = _lockedDays;
        deposits[_wallet].bracket.APYRewards = _APYRewards.mul(PRECISION_FACTOR);
    }

    function currentTimstamp() external view returns (uint256) {
        return block.timestamp;
    }

    function checkCalculations(address wallet) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        uint256 earnedrewards = 0;
        uint256 grossrewards;
        uint256 toclaim;
        uint256 unlocktime;
        uint256 locked;
        Deposit memory userDeposit = deposits[wallet];
        uint256 depositSeconds = block.timestamp.sub(userDeposit.info.timestamp);

        uint256 APYRate = userDeposit.bracket.APYRewards;
        if (userDeposit.truthcircle) {
            APYRate = APYRate + APYRate.div(100).mul(5);
            uint256 baseSeconds = userDeposit.truth.timestamp.sub(userDeposit.info.timestamp);
            uint256 truthSeconds = block.timestamp.sub(userDeposit.truth.timestamp);
            grossrewards = userDeposit.info.amount.mul(userDeposit.bracket.APYRewards).mul(baseSeconds) + userDeposit.info.amount.mul(APYRate).mul(truthSeconds);
            earnedrewards = grossrewards.div(365).div(86400).div(PRECISION_FACTOR);
            toclaim = earnedrewards.sub(userDeposit.claimed);
            unlocktime = userDeposit.info.timestamp + userDeposit.bracket.lockedDays * 1 days;
            locked = userDeposit.info.timestamp;
        }
        else {
            //figure out total tokens to earn
            grossrewards = userDeposit.info.amount.mul(APYRate).mul(depositSeconds);
            //break rewards down to rewards per second
            earnedrewards = grossrewards.div(365).div(86400).div(PRECISION_FACTOR);
            toclaim = earnedrewards.sub(userDeposit.claimed);
            unlocktime = userDeposit.info.timestamp + userDeposit.bracket.lockedDays * 1 days;
            locked = userDeposit.info.timestamp;
        }
        return (depositSeconds,APYRate,grossrewards,earnedrewards,toclaim,locked,unlocktime);
    }

    function claimRewards() external {
        Deposit memory userDeposit = deposits[_msgSender()];
        require(userDeposit.active, "user has no active deposits");
        uint256 rewardsAmount = calculateRewards(_msgSender());
        require (rewardsToken.balanceOf(address(this)) >= rewardsAmount, "insufficient rewards balance");
        deposits[_msgSender()].claimed += rewardsAmount;
        rewardsToken.transfer(_msgSender(), rewardsAmount);
        emit RewardsWithdraw(_msgSender(), rewardsAmount);
    }

    function stakeTruth(uint256 _tokenId) external {
        Deposit memory userDeposit = deposits[_msgSender()];
        require(userDeposit.active, "user has no active deposits");
        require(userDeposit.truth.amount == 0, "user has already staked their Truth");
        // transfer NFT
        truthToken.safeTransferFrom(_msgSender(), address(this), _tokenId);
        deposits[_msgSender()].truth.tokenId = _tokenId;
        deposits[_msgSender()].truth.amount = 1;
        deposits[_msgSender()].truth.timestamp = block.timestamp;
        deposits[_msgSender()].truthcircle = true;
        stakedTokenIds.push(_tokenId);
        emit UserTruthStake(_msgSender(), _tokenId);
    }

    function extendStake(uint256 _bracket) external {
        Deposit memory userDeposit = deposits[_msgSender()];
        require(userDeposit.active, "user has no active deposits");
        require(brackets[_bracket].enabled, "bracket is not enabled");

        uint256 oldDuration = userDeposit.info.timestamp + userDeposit.bracket.lockedDays * 1 days;
        uint256 newDuration = block.timestamp + brackets[_bracket].lockedDays * 1 days;

        require(newDuration > oldDuration, "cannot reduce lock duration, ur trying to lock for a shorter time");

        uint256 rewardsAmount = calculateRewards(_msgSender());
        require (rewardsToken.balanceOf(address(this)) >= rewardsAmount, "insufficient rewards balance");
        deposits[_msgSender()].claimed = rewardsAmount;
        rewardsToken.transfer(_msgSender(), rewardsAmount);

        deposits[_msgSender()].bracket.lockedDays = brackets[_bracket].lockedDays;
        deposits[_msgSender()].bracket.APYRewards = brackets[_bracket].APYRewards;
        deposits[_msgSender()].info.timestamp = block.timestamp;
        deposits[_msgSender()].truth.timestamp = block.timestamp;
        deposits[_msgSender()].claimed = 0;
        emit ExtendLock(_msgSender(),newDuration);

    }

    function withdraw() external {
        Deposit memory userDeposit = deposits[_msgSender()];
        require(userDeposit.active, "user has no active deposits");
        require(block.timestamp >= userDeposit.info.timestamp + userDeposit.bracket.lockedDays * 1 days, "Can't withdraw yet");
        uint256 depositedAmount = userDeposit.info.amount;
        uint256 rewardsAmount = calculateRewards(_msgSender());
        uint256 tokenId = 0;
        require (rewardsToken.balanceOf(address(this)) >= rewardsAmount, "insufficient rewards balance");

        deposits[_msgSender()].info.amount = 0;
        deposits[_msgSender()].claimed = 0;
        deposits[_msgSender()].active = false;
        rewardsToken.transfer(_msgSender(), rewardsAmount);
        depositToken.transfer(_msgSender(), depositedAmount);
        if (deposits[_msgSender()].truthcircle) {
            tokenId = deposits[_msgSender()].truth.tokenId;
            truthToken.safeTransferFrom(address(this), _msgSender(), deposits[_msgSender()].truth.tokenId);
            deposits[_msgSender()].truth.tokenId = 0;
            deposits[_msgSender()].truthcircle = false;
            deposits[_msgSender()].truth.amount = 0;
            for (uint i=0;i<stakedTokenIds.length;i++) {
                if (stakedTokenIds[i] == deposits[_msgSender()].truth.tokenId) {
                    delete stakedTokenIds[i];
                }
            }
        }

        emit FullWithdraw(_msgSender(), depositedAmount, rewardsAmount, tokenId);
    }

    function addBracket(uint256 id, uint256 lockedDays, uint256 APYRewards) external onlyOwner {
        // add rewards number based an an APY (ie 4000 is 4000% APY)
        APYRewards = APYRewards.mul(PRECISION_FACTOR).div(100);
        //later on in the code, we'll flip to rewards per second)
        brackets[id] = Bracket(lockedDays, APYRewards, true);
    }

    function addMultipleBrackets(uint256[] memory id, uint256[] memory lockedDays, uint256[] memory APYRewards) external onlyOwner {
        uint256 i = 0;
        require(id.length == lockedDays.length, "must be same length");
        require(APYRewards.length == id.length, "must be same length");
        while (i < id.length) {
            uint256 _APYRewards = APYRewards[i].mul(PRECISION_FACTOR).div(100);
            brackets[id[i]] = Bracket(lockedDays[i], _APYRewards, true);
            i +=1;
        }
    }

    function setTokens(address depositAddress, address rewardsAddress, address truthAddress) external onlyOwner {
        depositToken = IERC20(depositAddress);
        truthToken = IERC721(truthAddress);
        rewardsToken = IERC20(rewardsAddress);
    }

    function beginTerraform(bool _terraformInitiated) external onlyOwner {
        terraFormInitiated = _terraformInitiated;
        
    }

    function rescueTokens() external onlyOwner {
        if (rewardsToken.balanceOf(address(this)) > 0) {
            rewardsToken.transfer(_msgSender(), rewardsToken.balanceOf(address(this)));
        }

        if (depositToken.balanceOf(address(this)) > 0) {
            depositToken.transfer(_msgSender(), depositToken.balanceOf(address(this)));
        }
        for (uint i=0;i<stakedTokenIds.length;i++) {
            if (stakedTokenIds[i] != 0) {
                truthToken.safeTransferFrom(address(this), _msgSender(), stakedTokenIds[i]);
            }
        }
        delete stakedTokenIds;
    }

     function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}