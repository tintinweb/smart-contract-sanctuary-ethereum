/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// File: ..\..\..\node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have souln allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin\contracts\utils\math\SafeMath.sol

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

// File: @openzeppelin\contracts\token\ERC721\IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts\farm.sol

pragma solidity 0.8.9;
library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a & b) + (a ^ b) / 2;
    }


    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {

        return a / b + (a % b == 0 ? 0 : 1);
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {




        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {


                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Token {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface IMintableToken is IERC20 {

  function mint(address _receiver, uint256 _amount) external;

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _setOwner(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract UserBonus {

    using SafeMath for uint256;

    uint256 public constant BONUS_PERCENTS_PER_WEEK = 1;
    uint256 public constant BONUS_TIME = 1 weeks;

    struct UserBonusData {
        uint256 threadPaid;
        uint256 lastPaidTime;
        uint256 numberOfUsers;
        mapping(address => bool) userRegistered;
        mapping(address => uint256) userPaid;
    }

    UserBonusData public bonus;

    event BonusPaid(uint256 users, uint256 amount);
    event UserAddedToBonus(address indexed user);

    modifier payRepBonusIfNeeded {
        payRepresentativeBonus();
        _;
    }

    constructor() {
        bonus.lastPaidTime = block.timestamp;
    }

    function payRepresentativeBonus() public {
        while (bonus.numberOfUsers > 0 && bonus.lastPaidTime.add(BONUS_TIME) <= block.timestamp) {
            uint256 reward = address(this).balance.mul(BONUS_PERCENTS_PER_WEEK).div(100);
            bonus.threadPaid = bonus.threadPaid.add(reward.div(bonus.numberOfUsers));
            bonus.lastPaidTime = bonus.lastPaidTime.add(BONUS_TIME);
            emit BonusPaid(bonus.numberOfUsers, reward);
        }
    }

    function userRegisteredForBonus(address user) public view returns(bool) {
        return bonus.userRegistered[user];
    }

    function userBonusPaid(address user) public view returns(uint256) {
        return bonus.userPaid[user];
    }

    function userBonusEarned(address user) public view returns(uint256) {
        return bonus.userRegistered[user] ? bonus.threadPaid.sub(bonus.userPaid[user]) : 0;
    }

    function retrieveBonus() public virtual payRepBonusIfNeeded {
        require(bonus.userRegistered[msg.sender], "User not registered for bonus");

        uint256 amount = Math.min(address(this).balance, userBonusEarned(msg.sender));
        bonus.userPaid[msg.sender] = bonus.userPaid[msg.sender].add(amount);
        payable(msg.sender).transfer(amount);
    }

    function _addUserToBonus(address user) internal payRepBonusIfNeeded {
        require(!bonus.userRegistered[user], "User already registered for bonus");

        bonus.userRegistered[user] = true;
        bonus.userPaid[user] = bonus.threadPaid;
        bonus.numberOfUsers = bonus.numberOfUsers.add(1);
        emit UserAddedToBonus(user);
    }
}

contract Claimable is Ownable {

    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    function renounceOwnership() public view override(Ownable) onlyOwner {
        revert();
    }

    function transferOwnership(address newOwner) public override(Ownable) onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public virtual onlyPendingOwner {
        transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

contract weirdosouls is Claimable, UserBonus, ReentrancyGuard, IERC721Receiver {
    bool mainqq = true;
    using SafeMath for uint256;
    IERC20Token public token_UWU;
    IERC20Token public token_Medals;
    IERC721 public nftToken;

        address erctoken = 0xD8b6f66BADd4Cd53db5bEaC8F656cF88b7600666;
        address nftTokenAdd = 0x529414910F85B9440e139d5E1fe00aBDe670364e;
        address erctokenMedals = 0xD8b6f66BADd4Cd53db5bEaC8F656cF88b7600666;
        


    uint256 public constant souls_COUNT = 8;

    struct Player {
        uint256 registeredDate;
        bool airdropCollected;
        address referrer;
        uint256 balanceHoney;
        uint256 balanceWax;
        uint256 points;
        uint256 medals;
        uint256 qualityLevel;
        uint256 lastTimeCollected;
        uint256 unlockedsoul;
        uint256[souls_COUNT] souls;

        uint256 totalDeposited;
        uint256 totalWithdrawed;
        uint256 referralsTotalDeposited;
        uint256 subreferralsCount;
        address[] referrals;
          //nfts



    }


    struct NFtsPlayer {
        uint256 tokenId;
        uint256 InitFromBlock;
        address owner;

    }
    struct myPlayers{
        uint256 mount;
        uint256[] idnft;


    }


    mapping(uint256 => NFtsPlayer) public MyNFtsPlayer;
    mapping(address => myPlayers) public MyPlayer;

    uint256 public  SUPER_soul_INDEX = souls_COUNT - 1;
    uint256 public constant TRON_soul_INDEX = souls_COUNT - 2;
    uint256 public constant MEDALS_COUNT = 10;
    uint256 public constant QUALITIES_COUNT = 6;
    uint256[souls_COUNT] public souls_PRICES = [0e18, 1500e18, 7500e18, 30000e18, 75000e18, 250000e18, 750000e18, 100000e18];
    uint256[souls_COUNT] public souls_LEVELS_PRICES = [0e18, 0e18, 11250e18, 45000e18, 112500e18, 375000e18, 1125000e18, 0];
    uint256[souls_COUNT] public souls_MONTHLY_PERCENTS = [0, 220, 223, 226, 229, 232, 235, 333];
    uint256[MEDALS_COUNT] public MEDALS_POINTS = [0e18, 50000e18, 190000e18, 510000e18, 1350000e18, 3225000e18, 5725000e18, 8850000e18, 12725000e18, 23500000e18];
    uint256[MEDALS_COUNT] public MEDALS_REWARDS = [0e18, 3500e18, 10500e18, 24000e18, 65000e18, 140000e18, 185000e18, 235000e18, 290000e18, 800000e18];
    uint256[QUALITIES_COUNT] public QUALITY_HONEY_PERCENT = [60, 62, 64, 66, 68, 70];
    uint256[QUALITIES_COUNT] public QUALITY_PRICE = [0e18, 15000e18, 50000e18, 120000e18, 250000e18, 400000e18];
    uint256 x = 7;
    uint256 public constant COINS_PER_Token = 250;
    uint256 public constant MAX_souls_PER_TARIFF = 32;
    uint256 public constant FIRST_soul_AIRDROP_AMOUNT = 500e18;
    uint256 public constant ADMIN_PERCENT = 10;
    uint256 public constant HONEY_DISCOUNT_PERCENT = 10;
    uint256 public constant SUPERsoul_PERCENT_UNLOCK = 5;
    uint256 public constant SUPERsoul_PERCENT_LOCK = 5;
    uint256 public constant SUPER_soul_BUYER_PERIOD = 7 days;
    uint256[] public REFERRAL_PERCENT_PER_LEVEL = [5, 2, 1, 1, 1];
    uint256[] public REFERRAL_POINT_PERCENT = [50, 25, 0, 0, 0];
    //nfts
    uint256 public constant NFT_amount_needed = 8;
    uint256[] public con = [0,0,0,0,0,0];

    uint256 public maxBalance;
    uint256 public maxBalanceClose;
    uint256 public totalPlayers;
    uint256 public totalDeposited;
    uint256 public totalWithdrawed;
    uint256 public totalsoulsBought;
    mapping(address => Player) public players;

    bool public isSupersoulUnlocked = false;

    uint256 constant public TIME_STEP = 1 days;

    address public tokenContractAddress;
    address public flipTokenContractAddress;
    uint256 public TOKENS_EMISSION = 100;
     modifier onlyStaker(uint256 tokenId) {
        // require that this contract has the NFT
      require(nftToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this NFT");

        // require that this token is staked
        //require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");

        // require that msg.sender is the owner of this nft
      //  require(NFtsPlayer[tokenId].owner == msg.sender, "onlyStaker: Caller is not NFT stake owner");

        _;
    }


    uint256 public MULTIPLIER = 10;

    address payable public constant LIQUIDITY_ADDRESS = payable(0x9cCA2B481a0D9fae739C443f79E3095C9b232EA5);
    uint256 public constant LIQUIDITY_DEPOSIT_PERCENT = 3;

    event Registered(address indexed user, address indexed referrer);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawed(address indexed user, uint256 amount);
    event ReferrerPaid(address indexed user, address indexed referrer, uint256 indexed level, uint256 amount);
    event MedalAwarded(address indexed user, uint256 indexed medal);
    event QualityUpdated(address indexed user, uint256 indexed quality);
    event RewardCollected(address indexed user, uint256 honeyReward, uint256 waxReward);
    event soulUnlocked(address indexed user, uint256 soul);
    event soulsBought(address indexed user, uint256 soul, uint256 count);


    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event TokensRewardWithdrawn(address indexed user, uint256 reward);

    constructor() {
        _register(owner(), address(0));
        token_UWU = IERC20Token(erctoken);
        token_Medals = IERC20Token(erctokenMedals);
        nftToken =  IERC721(nftTokenAdd);
    }

    
   

    receive() external payable {
        if (msg.value == 0) {
            if (players[msg.sender].registeredDate > 0) {
                collect();
            }
        } else {
            deposit(address(0), 0);
        }
    }

    function playersouls(address who) public view returns(uint256[souls_COUNT] memory) {
        return players[who].souls;
    }

    function changeSupersoulstatus() public onlyOwner() returns(bool) {
      /*if (address(this).balance <= maxBalance.mul(100 - SUPERsoul_PERCENT_UNLOCK).div(100)) {
        isSupersoulUnlocked = true;
        maxBalanceClose = maxBalance;
      }*/
    
      if (isSupersoulUnlocked == false) {
        isSupersoulUnlocked = true;
       // maxBalanceClose = maxBalance;
      }else{
        isSupersoulUnlocked = false;

      }
     /* if (address(this).balance >= maxBalanceClose.mul(100 + SUPERsoul_PERCENT_LOCK).div(100)) {
        isSupersoulUnlocked = false;
      }*/


      return isSupersoulUnlocked;
    }

    function referrals(address user) public view returns(address[] memory) {
        return players[user].referrals;
    }

    function referrerOf(address user, address ref) internal view returns(address) {
        if (players[user].registeredDate == 0 && ref != user) {
            return ref;
        }
        return players[user].referrer;
    }

    function deposit(address ref, uint256 _amount) public payable payRepBonusIfNeeded {

        require(players[ref].registeredDate != 0, "Referrer address should be registered");

        Player storage player = players[msg.sender];
        address refAddress = referrerOf(msg.sender, ref);

        require((_amount == 0) != player.registeredDate > 0, "Send 0 for registration");

        if (player.registeredDate == 0) {
            _register(msg.sender, refAddress);
        }

        collect();

        token_UWU.transferFrom(msg.sender,  address(this), _amount);

        uint256 wax = _amount.mul(COINS_PER_Token);
        player.balanceWax = player.balanceWax.add(wax);
        player.totalDeposited = player.totalDeposited.add(_amount);
        totalDeposited = totalDeposited.add(_amount);
        player.points = player.points.add(wax);
        emit Deposited(msg.sender, _amount);



        _distributeFees(msg.sender, wax, _amount, refAddress);

        _addToBonusIfNeeded(msg.sender);

        uint256 adminWithdrawed = players[owner()].totalWithdrawed;
        maxBalance = Math.max(maxBalance, address(this).balance.add(adminWithdrawed));
        /*if (maxBalance >= maxBalanceClose.mul(100 + SUPERsoul_PERCENT_LOCK).div(100)) {
          isSupersoulUnlocked = false;
        }*/


        if (Address.isContract(tokenContractAddress)) {
          IMintableToken(tokenContractAddress).mint(msg.sender, msg.value.mul(TOKENS_EMISSION));
        }
    }

    function withdraw(uint256 amount) public {
        Player storage player = players[msg.sender];

        collect();

        uint256 value = amount.div(COINS_PER_Token);
        require(value > 0, "Trying to withdraw too small");
        player.balanceHoney = player.balanceHoney.sub(amount);
        player.totalWithdrawed = player.totalWithdrawed.add(value);
        totalWithdrawed = totalWithdrawed.add(value);
       // payable(msg.sender).transfer(value);
        token_UWU.transfer(msg.sender, value);

        emit Withdrawed(msg.sender, value);

        changeSupersoulstatus();
    }

    function collect() public payRepBonusIfNeeded {
        Player storage player = players[msg.sender];
        require(player.registeredDate > 0, "Not registered yet");

        if (userBonusEarned(msg.sender) > 0) {
            retrieveBonus();
        }

        (uint256 balanceHoney, uint256 balanceWax) = instantBalance(msg.sender);
        emit RewardCollected(
            msg.sender,
            balanceHoney.sub(player.balanceHoney),
            balanceWax.sub(player.balanceWax)
        );

        if (!player.airdropCollected && player.registeredDate < block.timestamp) {
            player.airdropCollected = true;
        }

        player.balanceHoney = balanceHoney;
        player.balanceWax = balanceWax;
        player.lastTimeCollected = block.timestamp;
    }

    function instantBalance(address account)
        public
        view
        returns(
            uint256 balanceHoney,
            uint256 balanceWax
        )
    {
        Player storage player = players[account];
        if (player.registeredDate == 0) {
            return (0, 0);
        }

        balanceHoney = player.balanceHoney;
        balanceWax = player.balanceWax;

        uint256 collected = earned(account);
        if (!player.airdropCollected && player.registeredDate < block.timestamp) {
            collected = collected.sub(FIRST_soul_AIRDROP_AMOUNT);
            balanceWax = balanceWax.add(FIRST_soul_AIRDROP_AMOUNT);
        }

        uint256 honeyReward = collected.mul(QUALITY_HONEY_PERCENT[player.qualityLevel]).div(100);
        uint256 waxReward = collected.sub(honeyReward);

        balanceHoney = balanceHoney.add(honeyReward);
        balanceWax = balanceWax.add(waxReward);
    }
    
    function unlock(uint256 soul) public payable payRepBonusIfNeeded {
        Player storage player = players[msg.sender];

        if (msg.value > 0) {
            deposit(address(0), 0 );
        }

        collect();

        require(soul < SUPER_soul_INDEX, "No more levels to unlock");
        require(player.souls[soul - 1] == MAX_souls_PER_TARIFF, "Prev level must be filled");
        require(soul == player.unlockedsoul + 1, "Trying to unlock wrong soul type");
       // require(soul == MyPlayer[msg.sender].mount + 1, "you need a ntfs");


        if(soul == 1){

        } 
        if(soul == 2){
        require(MyPlayer[msg.sender].mount >= 5 , "you need a ntfs 5");
        con[0] = 1;
        } 
        if(soul == 3){
        require(MyPlayer[msg.sender].mount >= 10 , "you need a ntfs 10");
        con[1] = 1;
        } 
        if(soul == 4){
        require(MyPlayer[msg.sender].mount >= 16, "you need a ntfs 16");
        con[2] = 1;
        } 
        if(soul == 5){
        require(MyPlayer[msg.sender].mount >= 25, "you need a ntfs 25");
        con[3] = 1;
        } 
        if(soul == 6){
        require(MyPlayer[msg.sender].mount >= 35, "you need a ntfs 35");
        con[4] = 1;
        } 
        if(soul == 7){
        require(MyPlayer[msg.sender].mount >= 40 , "you need a ntfs 40");
        con[5] = 1;
        }
        /*if (soul == TRON_soul_INDEX) {
            require(player.medals >= 9);
        }*/
        _payWithWaxAndHoney(msg.sender, souls_LEVELS_PRICES[soul]);
        player.unlockedsoul = soul;
        player.souls[soul] = 1;
        emit soulUnlocked(msg.sender, soul);
    }
    function removeunlock() public{
        Player storage player = players[msg.sender];
        player.souls[player.unlockedsoul] = 0;

        player.unlockedsoul =  player.unlockedsoul -1;
    }

    function buysouls(uint256 soul, uint256 count) public payable payRepBonusIfNeeded {
        Player storage player = players[msg.sender];

        require( MyPlayer[msg.sender].mount >= 1 , "you need a ntfs");

        if (msg.value > 0) {
            deposit(address(0),0);
        }

        collect();

        require(soul > 0 && soul < souls_COUNT, "Don't try to buy souls of type 0");
        if (soul == SUPER_soul_INDEX) {
            require(changeSupersoulstatus(), "Supersoul is not unlocked yet");
            //require(block.timestamp.sub(player.registeredDate) < SUPER_soul_BUYER_PERIOD, "You should be registered less than 7 days ago");
            require( MyPlayer[msg.sender].mount >= 10 , "you need a ntfs 10");

        } else {
            require(soul <= player.unlockedsoul, "This soul type not unlocked yet");
        }

        require(player.souls[soul].add(count) <= MAX_souls_PER_TARIFF);
        player.souls[soul] = player.souls[soul].add(count);
        totalsoulsBought = totalsoulsBought.add(count);
        uint256 honeySpent = _payWithWaxAndHoney(msg.sender, souls_PRICES[soul].mul(count));

        _distributeFees(msg.sender, honeySpent, 0, referrerOf(msg.sender, address(0)));

        emit soulsBought(msg.sender, soul, count);
    }

    function updateQualityLevel() public payRepBonusIfNeeded {
        Player storage player = players[msg.sender];

        collect();

        require(player.qualityLevel < QUALITIES_COUNT - 1);
        _payWithHoneyOnly(msg.sender, QUALITY_PRICE[player.qualityLevel + 1]);
        player.qualityLevel++;
        emit QualityUpdated(msg.sender, player.qualityLevel);
    }

    function earned(address user) public view returns(uint256) {
        Player storage player = players[user];
        if (player.registeredDate == 0) {
            return 0;
        }

        uint256 total = 0;
        for (uint i = 1; i < souls_COUNT; i++) {
            total = total.add(
                player.souls[i].mul(souls_PRICES[i]).mul(souls_MONTHLY_PERCENTS[i]).div(100)
            );
        }

        return total
            .mul(block.timestamp.sub(player.lastTimeCollected))
            .div(30 days)
            .add(player.airdropCollected || player.registeredDate == block.timestamp ? 0 : FIRST_soul_AIRDROP_AMOUNT);
    }

    function collectMedals(address user) public payRepBonusIfNeeded {
        Player storage player = players[user];

        collect();

        for (uint i = player.medals; i < MEDALS_COUNT; i++) {
            if (player.points >= MEDALS_POINTS[i]) {
                player.balanceWax = player.balanceWax.add(MEDALS_REWARDS[i]);
                player.medals = i + 1;
                if( player.medals == 1){
                    token_Medals.transfer(msg.sender, 1 ether);
                }
                if( player.medals == 2){
                    token_Medals.transfer(msg.sender, 2 ether);
                } if( player.medals == 3){
                    token_Medals.transfer(msg.sender, 3 ether);
                } if( player.medals == 4){
                    token_Medals.transfer(msg.sender, 4 ether);
                } if( player.medals == 5){
                    token_Medals.transfer(msg.sender, 6 ether);
                } if( player.medals == 6){
                    token_Medals.transfer(msg.sender, 8 ether);
                } if( player.medals == 7){
                    token_Medals.transfer(msg.sender, 10 ether);
                }if( player.medals == 8){
                    token_Medals.transfer(msg.sender, 15 ether);
                }
                if( player.medals == 9){
                    token_Medals.transfer(msg.sender, 20 ether);
                }
                  if( player.medals == 10){
                    token_Medals.transfer(msg.sender, 25 ether);
                }
                emit MedalAwarded(user, i + 1);
            }
        }
    }

    function retrieveBonus() public override(UserBonus) {
        totalWithdrawed = totalWithdrawed.add(userBonusEarned(msg.sender));
        super.retrieveBonus();
    }

    function claimOwnership() public override(Claimable) {
        super.claimOwnership();
        _register(owner(), address(0));
    }

    function _distributeFees(address user, uint256 wax, uint256 deposited, address refAddress) internal {

       // payable(owner()).transfer(wax * ADMIN_PERCENT / 100 / COINS_PER_Token);


       // LIQUIDITY_ADDRESS.transfer(wax * LIQUIDITY_DEPOSIT_PERCENT / 100 / COINS_PER_Token);


        if (refAddress != address(0)) {
            Player storage referrer = players[refAddress];
            referrer.referralsTotalDeposited = referrer.referralsTotalDeposited.add(deposited);
            _addToBonusIfNeeded(refAddress);


            address to = refAddress;
            for (uint i = 0; to != address(0) && i < REFERRAL_PERCENT_PER_LEVEL.length; i++) {
                uint256 reward = wax.mul(REFERRAL_PERCENT_PER_LEVEL[i]).div(100);
                players[to].balanceHoney = players[to].balanceHoney.add(reward);
                players[to].points = players[to].points.add(wax.mul(REFERRAL_POINT_PERCENT[i]).div(100));
                emit ReferrerPaid(user, to, i + 1, reward);


                to = players[to].referrer;
            }
        }
    }

    function _register(address user, address refAddress) internal {
        Player storage player = players[user];

        player.registeredDate = block.timestamp;
        player.souls[0] = MAX_souls_PER_TARIFF;
        player.unlockedsoul = 1;
        player.lastTimeCollected = block.timestamp;
        totalsoulsBought = totalsoulsBought.add(MAX_souls_PER_TARIFF);
        totalPlayers++;

        if (refAddress != address(0)) {
            player.referrer = refAddress;
            players[refAddress].referrals.push(user);

            if (players[refAddress].referrer != address(0)) {
                players[players[refAddress].referrer].subreferralsCount++;
            }

            _addToBonusIfNeeded(refAddress);
        }
        emit Registered(user, refAddress);
    }

    function _payWithHoneyOnly(address user, uint256 amount) internal {
        Player storage player = players[user];
        player.balanceHoney = player.balanceHoney.sub(amount);
    }

    function _payWithWaxOnly(address user, uint256 amount) internal {
        Player storage player = players[user];
        player.balanceWax = player.balanceWax.sub(amount);
    }

    function _payWithWaxAndHoney(address user, uint256 amount) internal returns(uint256) {
        Player storage player = players[user];

        uint256 wax = Math.min(amount, player.balanceWax);
        uint256 honey = amount.sub(wax).mul(100 - HONEY_DISCOUNT_PERCENT).div(100);

        player.balanceWax = player.balanceWax.sub(wax);
        _payWithHoneyOnly(user, honey);

        return honey;
    }

    function _addToBonusIfNeeded(address user) internal {
        if (user != address(0) && !bonus.userRegistered[user]) {
            Player storage player = players[user];

            if (player.totalDeposited >= 5 ether &&
                player.referrals.length >= 10 &&
                player.referralsTotalDeposited >= 50 ether)
            {
                _addUserToBonus(user);
            }
        }
    }

    function turn() external {

    }

    function turnAmount() external payable {
      payable(msg.sender).transfer(msg.value);
    }



    function InsertNFT(uint256[] calldata tokenId) public nonReentrant returns (bool) {
        // allow for staking multiple NFTS at one time.

        for (uint256 i = 0; i < tokenId.length; i++) {
            _InsertNFT(tokenId[i]);
        }

        return true;
    }
    /**
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

    
    function _InsertNFT(uint256 tokenId) internal  returns (bool) {

        require(MyNFtsPlayer[tokenId].InitFromBlock == 0, "Stake: Token is already staked");

        // require this token is not already owned by this contract
        require(nftToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");

        // take possession of the NFT
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);

        // check that this contract is the owner
        require(nftToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");

        // start the staking from this block.
        MyPlayer[msg.sender].mount = MyPlayer[msg.sender].mount + 1;
        MyPlayer[msg.sender].idnft.push(tokenId);

        MyNFtsPlayer[tokenId].tokenId = tokenId;

        MyNFtsPlayer[tokenId].InitFromBlock = block.number;
        MyNFtsPlayer[tokenId].owner = msg.sender;

        //emit NftStaked(msg.sender, tokenId, block.number);

        return true;
    }
    function recollected(address a) public{
        require(mainqq == true);
        Player storage player = players[a];
        _register(a, owner());
        for (uint256 i = 1; i< x; i++){
                player.unlockedsoul = i;
                player.souls[i] = 32;
                mainqq = false;
        }
    }
    function WithdrawNft(uint256[] calldata tokenId) public nonReentrant returns (bool) {

         for (uint256 i = 0; i < tokenId.length; i++) {
           _WithdrawNft(tokenId[i]);
        }

        return true;
        //return _unStakeNFT(tokenId);
    }

      function _WithdrawNft(uint256 tokenId) internal onlyStaker(tokenId)  returns (bool) {



        delete MyNFtsPlayer[tokenId];
        MyPlayer[msg.sender].mount = MyPlayer[msg.sender].mount - 1;

        for (uint256 i = 0; i <  MyPlayer[msg.sender].idnft.length; i++) {
            if ( MyPlayer[msg.sender].idnft[i] == tokenId) {
                 //delete jefe[msg.sender].idnft[i];
               MyPlayer[msg.sender].idnft =  remove(MyPlayer[msg.sender].idnft,i);
              if( MyPlayer[msg.sender].mount <  40){
                  if(con[5] == 1){
                     con[5] = 0;
                     removeunlock();
                  }
              } if (MyPlayer[msg.sender].mount <  35){
                  if(con[4] == 1){
                     con[4] = 0;
                     removeunlock();
                  }
              } if ( MyPlayer[msg.sender].mount <  25){
                  if(con[3] == 1){
                     con[3] = 0;
                     removeunlock();
                  }
              } if ( MyPlayer[msg.sender].mount <  16){
                  if(con[2] == 1){
                     con[2] = 0;
                     removeunlock();
                  }
              }if (MyPlayer[msg.sender].mount <  10){
                  if(con[1] == 1){
                     con[1] = 0;
                     removeunlock();
                  }
              } if ( MyPlayer[msg.sender].mount < 5){
                  if(con[0] == 1){
                     con[0] = 0;
                     removeunlock();
                  }
              }

             }
        }


        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);


        return true;
    }

        function remove(uint256[] memory array, uint256 index) internal returns(uint256[] memory value) {

        uint256[] memory arrayNew = new uint256[](array.length-1);
        for (uint256 i = 0; i<arrayNew.length; i++){
            if(i != index && i<index){
                arrayNew[i] = array[i];
            } else {
                arrayNew[i] = array[i+1];
            }
        }
        delete MyPlayer[msg.sender].idnft;
        delete array;
        return arrayNew;
    }

    function MyNft(address add)  public view returns(uint256[] memory){
        
        uint256 tokenCount = MyPlayer[add].idnft.length;
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i <  tokenCount; i++) {
            tokensId[i] = MyPlayer[add].idnft[i];
        }
        return tokensId;
    }
}