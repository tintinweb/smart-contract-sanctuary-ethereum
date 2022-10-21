/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: contracts/UpStake.sol


pragma solidity ^0.8.7;






contract UpStake is Pausable {

    using Counters for Counters.Counter;

    struct Case {
        string Name;
        string TokenSymbol;
        address TokenAddress;
        uint64 ApplyingStart;
        uint64 ApplyingEnd;
        uint32 Duration; // days
        uint16 APR;
        uint256 SupplyTotal;
        uint256 SupplyBalance;
        uint256 AccountLimitMin;
        uint256 AccountLimitMax;
        bool OnlyHolder; // only for seaman / captain holders
        uint8 Status; // 0:ok, 1:paused, 2:abandoned
    }

    Counters.Counter private _caseIdTracker; // case id tracker, auto increment
    mapping(uint256 => Case) private _cases; // case list
    mapping(address => mapping(uint256 => uint256)) private _accountsToCases; // accounts to cases

    IERC721 private _seaman;  // erc721 contract - seaman
    IERC721 private _captain; // erc721 contract - captain

    event caseAdded(
        uint256 indexed caseId,
        string name,
        string indexed tokenSymbol,
        uint256 supplyTotal,
        uint16 indexed apr,
        bool onlyHolder
    );

    event caseStatusSet(
        uint256 indexed caseId,
        uint8 indexed status
    );

    event caseLimitsSet(
        uint256 indexed caseId,
        uint256 indexed accountLimitMin,
        uint256 indexed accountLimitMax,
        bool onlyHolder
    );

    event deposited(
        address indexed account,
        uint256 indexed caseId,
        uint256 indexed amount,
        uint256 balance
    );

    event withdrew(
        uint256 indexed caseId,
        address to,
        uint256 indexed amount,
        string indexed symbol
    );

    event aborted(
        address indexed account,
        uint256 indexed caseId,
        uint256 indexed amount
    );

    event claimed(
        address indexed account,
        uint256 indexed caseId,
        uint256 indexed amount,
        uint256 profit
    );

    /// @notice Emitted after super operator is updated
    event AuthorizedOperator(address indexed operator, address indexed holder);

    /// @notice Emitted after super operator is updated
    event RevokedOperator(address indexed operator, address indexed holder);

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;
    address private owner;

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    constructor(address captain, address seaman) {
        superOperators[msg.sender] = true;
        owner = msg.sender;
        _captain = IERC721(captain);
        _seaman = IERC721(seaman);
    }

    function pause() public isSuperOperator whenNotPaused {
        _pause();
    }

    function unpause() public isSuperOperator whenPaused {
        _unpause();
    }

    function addCase(Case memory theCase) public isSuperOperator whenNotPaused returns (uint256) {
        require(
            bytes(theCase.Name).length > 0 
            && bytes(theCase.TokenSymbol).length > 0,
            "empty string"
        );
        require(
            theCase.ApplyingEnd > theCase.ApplyingStart 
            && theCase.ApplyingEnd > block.timestamp, 
            "wrong start or end"
        );
        require(
            theCase.SupplyTotal > 0 
            && theCase.AccountLimitMax >= theCase.AccountLimitMin
            && theCase.AccountLimitMax <= theCase.SupplyTotal,
            "wrong total / min / max"
        );
        require(theCase.Duration > 0, "duration is zero");
        require(theCase.TokenAddress != address(0), "token address is zero");
        require(theCase.Status <= 2, "wrong status");
        theCase.SupplyBalance = theCase.SupplyTotal;
        _caseIdTracker.increment();
        uint256 newId = _caseIdTracker.current();
        _cases[newId] = theCase;
        emit caseAdded(newId, theCase.Name, theCase.TokenSymbol, theCase.SupplyTotal, theCase.APR, theCase.OnlyHolder);
        return newId;
    }

    function lastCaseId() public view returns (uint256) {
        return _caseIdTracker.current();
    }

    function getCaseById(uint256 caseId) public view returns (Case memory) {
        return _cases[caseId];
    }

    function setCaseStatus(uint256 caseId, uint8 status) public isSuperOperator whenNotPaused {
        require(status <= 2, "wrong status");
        _cases[caseId].Status = status;
        emit caseStatusSet(caseId, status);
    }

    function setCaseLimits(uint256 caseId, uint256 min, uint256 max, bool onlyHolder) public isSuperOperator whenNotPaused {
        require(
            max >= min && max <= _cases[caseId].SupplyTotal,
            "wrong number"
        );
        _cases[caseId].AccountLimitMin = min;
        _cases[caseId].AccountLimitMax = max;
        _cases[caseId].OnlyHolder = onlyHolder;
        emit caseLimitsSet(caseId, min, max, onlyHolder);
    }

    function setCaseApplyingEnd(uint256 caseId, uint64 endAt) public isSuperOperator whenNotPaused {
        _cases[caseId].ApplyingEnd = endAt;
    }

    function balanceOf(address account, uint256 caseId) public view returns (uint256) {
        return _accountsToCases[account][caseId];
    }

    function profitPerDay(uint16 apr, uint256 amount) public pure returns (uint256) {
        (, uint256 ret) = SafeMath.tryMul(apr, amount);
        return ret / 3650000;
    }

    function getDiffDays(uint256 tsFrom, uint256 tsTo) internal pure returns (uint256) {
        if (tsFrom >= tsTo) {
            return 0;
        }
        return (tsTo - tsFrom) / 86400;
    }

    function profitOf(address account, uint256 caseId) public view returns (uint256) {
        uint256 amount = balanceOf(account, caseId);
        if (amount == 0) {
            return 0;
        }
        Case memory theCase = getCaseById(caseId);
        if (theCase.APR == 0) {
            return 0;
        }
        uint256 diffDays = getDiffDays(theCase.ApplyingEnd, block.timestamp);
        if (diffDays == 0) {
            return 0;
        }
        if (diffDays >= theCase.Duration) {
            diffDays = theCase.Duration;
        }
        (, uint256 ret) = SafeMath.tryMul(profitPerDay(theCase.APR, amount), diffDays);
        return ret;
    }

    function canDeposit(address account, uint256 caseId, uint256 amount) public view returns (bool, string memory) {
        if (paused()) {
            return (false, "contract paused");
        }
        if (account == address(0)) {
            return (false, "account is zero");
        }
        Case memory theCase = getCaseById(caseId);
        if (theCase.SupplyTotal == 0) {
            return (false, "case is not exists");
        }
        if (theCase.Status != 0) {
            return (false, "case status is not ok");
        }
        if (block.timestamp < theCase.ApplyingStart || block.timestamp > theCase.ApplyingEnd) {
            return (false, "applying is not opening");
        }
        if (amount == 0) {
            return (false, "amount is zero");
        }
        if (amount > theCase.SupplyBalance) {
            return (false, "amount is more than remain balance");
        }
        (, uint256 sumAmount) = SafeMath.tryAdd(balanceOf(account, caseId), amount);
        if (sumAmount == 0) {
            return (false, "wrong amount when try add");
        }
        if (sumAmount < theCase.AccountLimitMin || sumAmount > theCase.AccountLimitMax) {
            return (false, "amount should be between min and max");
        }
        IERC20 tokenContract = IERC20(theCase.TokenAddress);
        if (tokenContract.allowance(account, address(this)) < amount) {
            return (false, "amount is less than allowance");
        }
        if (theCase.OnlyHolder && _captain.balanceOf(account) == 0 && _seaman.balanceOf(account) == 0) {
            return (false, "only for holders");
        }
        return (true, "");
    }

    function deposit(uint256 caseId, uint256 amount) public {
        (bool ok, string memory errMsg) = canDeposit(msg.sender, caseId, amount);
        require(ok, errMsg);
        Case memory theCase = getCaseById(caseId);
        IERC20 tokenContract = IERC20(theCase.TokenAddress);
        require(
            tokenContract.transferFrom(msg.sender, address(this), amount),
            "Fail to transfer tokens"
        );
        unchecked {
            _cases[caseId].SupplyBalance -= amount;
            _accountsToCases[msg.sender][caseId] += amount;
        }
        emit deposited(msg.sender, caseId, amount, _accountsToCases[msg.sender][caseId]);
    }

    function canAbortOrClaim(address account, uint256 caseId) public view returns (uint8, string memory, uint256) {
        if (paused()) {
            return (0, "contract paused", 0);
        }
        if (account == address(0)) {
            return (0, "account is zero", 0);
        }
        Case memory theCase = getCaseById(caseId);
        if (theCase.SupplyTotal == 0) {
            return (0, "case is not exists", 0);
        }
        if (theCase.Status != 0) {
            return (0, "case status is not ok", 0);
        }
        uint256 amount = balanceOf(account, caseId);
        if (amount == 0) {
            return (0, "account balance is zero", 0);
        }
        if (getDiffDays(theCase.ApplyingEnd, block.timestamp) >= theCase.Duration) {
            return (2, "can claim", amount);
        } else {
            return (1, "only can abort", amount);
        }
    }

    function abort(uint256 caseId) public {
        (uint8 which, string memory errMsg, uint256 amount) = canAbortOrClaim(msg.sender, caseId);
        require(which == 1, errMsg);
        _accountsToCases[msg.sender][caseId] = 0;
        _cases[caseId].SupplyBalance += amount;
        Case memory theCase = getCaseById(caseId);
        IERC20 tokenContract = IERC20(theCase.TokenAddress);
        require(tokenContract.transfer(msg.sender, amount), "fail to transfer");
        emit aborted(msg.sender, caseId, amount);
    }

    function claim(uint256 caseId) public {
        (uint8 which, string memory errMsg, uint256 amount) = canAbortOrClaim(msg.sender, caseId);
        require(which == 2, errMsg);
        _accountsToCases[msg.sender][caseId] = 0;
        Case memory theCase = getCaseById(caseId);
        IERC20 tokenContract = IERC20(theCase.TokenAddress);
        uint256 profit = profitOf(msg.sender, caseId);
        require(tokenContract.transfer(msg.sender, amount + profit), "fail to transfer");
        emit claimed(msg.sender, caseId, amount, profit);
    }

    function tokenAmountByCase(uint256 caseId) public view returns (uint256) {
        Case memory theCase = getCaseById(caseId);
        IERC20 tokenContract = IERC20(theCase.TokenAddress);
        return tokenContract.balanceOf(address(this));
    }

    function withdraw(uint256 caseId, uint256 amount, address to) public isSuperOperator {
        Case memory theCase = getCaseById(caseId);
        IERC20 tokenContract = IERC20(theCase.TokenAddress);
        require(tokenContract.transfer(to, amount));
        emit withdrew(caseId, to, amount, theCase.TokenSymbol);
    }

     /// @notice Allows super operator to update super operator
    function authorizeOperator(address _operator) external isSuperOperator {
        superOperators[_operator] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Allows super operator to update super operator
    function revokeOperator(address _operator) external isSuperOperator {
        superOperators[_operator] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    receive() external payable {
        payable(owner).transfer(msg.value);
    }

}