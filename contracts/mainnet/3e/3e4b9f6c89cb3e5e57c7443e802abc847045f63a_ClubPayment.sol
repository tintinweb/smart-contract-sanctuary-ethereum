// SPDX-License-Identifier: MIT
// Creator: Debox Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ClubPayment is Ownable {

    using SafeMath for uint256;

    uint256 public constant MAX_AMOUNT_PER_MONTH = 10**19;  // 10 ethers
    uint256 public constant MIN_AMOUNT_PER_MONTH = 10**16;  // 0.01 ethers
    uint256 public constant SECONDS_OF_MONTH = 3600*24*30;  // 30 days

    enum RS { NORMAL, MEMBER_REFUND, OWNER_REFUND, EXPIRE }

    struct Club {
        uint256     id;
        address     owner;
        address     nftCA;
        uint256     tokenId;
        uint8       payMonths;
        uint256     amountPerMonth;
        uint256     createTime;
        uint256     balance;                // accumulative total, joined - refund
        uint256     surplus;                // refund surplus, pay_amount - refund_amount
        uint256     withdrawAmount;         // have withdrawn
        uint256     withdrawTime;
    }
    struct PayRecord {
        address     payAddr;
        uint256     payAmount;
        uint256     payTime;
        uint256     expireTime;
        uint256     refundAmount;
        RS          state;
    }

    address payable public _dAddr;
    uint256 public _incNO = 1;
    mapping(address => bool) public _stakedActive;
    mapping(address => mapping(uint256 => Club)) private _staking;
    mapping(uint256 => PayRecord[]) private _clubPayRecords;
    mapping(uint256 => mapping(address => uint256)) private _clubMemberPayIndex;

    event CreateClub(address indexed sender, address nft_ca, uint256 token_id, uint8 months, uint256 amount);
    event ModifyAmountPerMonth(address indexed sender, uint256 cid, uint256 amount);
    event JoinClub(address indexed sender, uint256 cid, uint8 pay_month, uint256 pay_amount);
    event ReleaseClub(address indexed sender, uint256 cid);
    event Refund(address indexed sender, uint256 cid, address indexed refund_addr, RS rs, uint256 amount);
    event Withdraw(address indexed sender, uint256 cid, uint256 withdraw_amount);
    event WithdrawExpire(address indexed sender, uint256 cid, uint256 withdraw_amount);
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() {
        _dAddr = payable(msg.sender);
    }

    function setAllowedContract(address nft_ca, bool state) external onlyOwner {
        _stakedActive[nft_ca] = state;
    }

    function modifyDAddr(address new_addr) external onlyOwner {
        require(new_addr != address(0), "invalid address");
        _dAddr = payable(new_addr);
    }

    function isExpire(uint256 pay_time, uint8 pay_months) internal view returns (bool) {
        return pay_time.add(SECONDS_OF_MONTH.mul(pay_months)) < block.timestamp;
    }

    // just for not expire case
    function calculateRemainMonths(uint256 pay_time, uint8 pay_months, RS rs) internal view returns (uint256) {
        uint256 months = block.timestamp.sub(pay_time).div(SECONDS_OF_MONTH);
        uint256 remain_months = pay_months - months;
        if (rs == RS.MEMBER_REFUND) {
            if (remain_months > 2) {
                remain_months = remain_months.sub(2);
            }
            else {
                remain_months = 0;
            }
        }
        return remain_months;
    }

    function getStakeInfo(address nft_ca, uint256 token_id) internal view returns (Club memory) {
        require(_staking[nft_ca][token_id].id > 0, "current nft is not staking");
        return _staking[nft_ca][token_id];
    }

    function getClubInfo(address nft_ca, uint256 token_id) external view returns (Club memory club) {
        return getStakeInfo(nft_ca, token_id);
    }

    function createClub(address nft_ca, uint256 token_id, uint8 months, uint256 amount) external callerIsUser {
        require(_stakedActive[nft_ca], "invalid contract address for staking");
        require(months == uint8(6) || months == uint8(12), "pay month just require 6 or 12");
        require(amount >= MIN_AMOUNT_PER_MONTH && amount <= MAX_AMOUNT_PER_MONTH, "amount_per_month out of range");
        require(msg.sender == IERC721(nft_ca).ownerOf(token_id), "invalid owner address for staking");
        // staking
        IERC721(nft_ca).transferFrom(msg.sender, address(this), token_id);
        Club memory club = Club(_incNO++, msg.sender, nft_ca, token_id, months, amount, block.timestamp, 0, 0, 0, block.timestamp);
        _staking[nft_ca][token_id] = club;
        _clubPayRecords[club.id].push(PayRecord(msg.sender, 0, 0, 0, 0, RS.OWNER_REFUND));
        emit CreateClub(msg.sender, nft_ca, token_id, months, amount);
    }

    function modifyAmountPerMonth(address nft_ca, uint256 token_id, uint256 amount) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        require(amount >= MIN_AMOUNT_PER_MONTH && amount <= MAX_AMOUNT_PER_MONTH, "amount_per_month out of range");
        require(amount > club.amountPerMonth, "amount_per_month less than original amount_per_month");
        club.amountPerMonth = amount;
        emit ModifyAmountPerMonth(msg.sender, club.id, amount);
    }

    function joinClub(address nft_ca, uint256 token_id) external payable callerIsUser {
        Club memory club = getStakeInfo(nft_ca, token_id);
        require(msg.sender != club.owner, "owner have joined current club");
        uint256 pay_amount = club.amountPerMonth.mul(club.payMonths);
        require(msg.value >= pay_amount, "send eth amount is less pay amount");
        uint256 member_idx = _clubMemberPayIndex[club.id][msg.sender];
        if (member_idx > 0) {
            PayRecord storage record = _clubPayRecords[club.id][member_idx];
            require(record.expireTime < block.timestamp, "have joined current club");
            if (record.state == RS.NORMAL) {
                _staking[nft_ca][token_id].surplus.add(record.payAmount);
                record.state = RS.EXPIRE;
            }
        }
        uint256 expire_time = block.timestamp.add(SECONDS_OF_MONTH.mul(club.payMonths));
        _clubPayRecords[club.id].push(PayRecord(msg.sender, pay_amount, block.timestamp, expire_time, 0, RS.NORMAL));
        _clubMemberPayIndex[club.id][msg.sender] = _clubPayRecords[club.id].length.sub(1);
        _staking[nft_ca][token_id].balance = _staking[nft_ca][token_id].balance.add(pay_amount);
        if (msg.value > pay_amount) {
            payable(msg.sender).transfer(msg.value.sub(pay_amount));
        }
        emit JoinClub(msg.sender, club.id, club.payMonths, pay_amount);
    }

    function releaseClub(address nft_ca, uint256 token_id) external callerIsUser {
        Club memory club = getStakeInfo(nft_ca, token_id);
        require(club.owner == msg.sender, "invalid owner address for current club");
        require(club.balance == club.withdrawAmount, "please to withdraw/refund before release");
        IERC721(nft_ca).transferFrom(address(this), msg.sender, token_id);
        delete _staking[nft_ca][token_id];
        delete _clubPayRecords[club.id];
        emit ReleaseClub(msg.sender, club.id);
    }

    function getBalance(address eoa, address nft_ca, uint256 token_id, RS st) internal view returns (uint256) {
        Club memory club = getStakeInfo(nft_ca, token_id);
        uint256 member_idx = _clubMemberPayIndex[club.id][eoa];
        if (member_idx > 0) {
            PayRecord memory record = _clubPayRecords[club.id][member_idx];
            if (record.state == RS.NORMAL && record.expireTime > block.timestamp) {
                uint256 remain_months = calculateRemainMonths(record.payTime, club.payMonths, st);
                return record.payAmount.mul(remain_months).div(club.payMonths);
            }
        }
        return 0;
    }

    function getBalanceByMember(address nft_ca, uint256 token_id) external view returns (uint256) {
        return getBalance(msg.sender, nft_ca, token_id, RS.MEMBER_REFUND);
    }

    function getBalanceByOwner(address eoa, address nft_ca, uint256 token_id) external view returns (uint256) {
        return getBalance(eoa, nft_ca, token_id, RS.OWNER_REFUND);
    }

    function refund(address eoa, address nft_ca, uint256 token_id, RS st) internal {
        Club storage club = _staking[nft_ca][token_id];
        uint256 member_idx = _clubMemberPayIndex[club.id][eoa];
        require(member_idx > 0, "invalid member address for current club");
        PayRecord storage record = _clubPayRecords[club.id][member_idx];
        if (record.state == RS.NORMAL && record.expireTime > block.timestamp) {
            uint256 remain_months = calculateRemainMonths(record.payTime, club.payMonths, st);
            uint256 amount = record.payAmount.mul(remain_months).div(club.payMonths);
            uint256 surplus = record.payAmount.sub(amount);
            club.balance = club.balance.sub(amount);
            club.surplus = club.surplus.add(surplus);
            record.state = st;
            record.refundAmount = amount;
            payable(eoa).transfer(amount);
            emit Refund(msg.sender, club.id, eoa, st, amount);
        }
    }

    function refundByMember(address nft_ca, uint256 token_id) external callerIsUser {
        return refund(msg.sender, nft_ca, token_id, RS.MEMBER_REFUND);
    }

    function refundByOwner(address eoa, address nft_ca, uint256 token_id) external callerIsUser {
        require(_staking[nft_ca][token_id].owner == msg.sender, "invalid owner address for current club");
        return refund(eoa, nft_ca, token_id, RS.OWNER_REFUND);
    }
    
    function batchRefund(address nft_ca, uint256 token_id, address[] calldata addrs) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        for (uint idx = 0; idx < addrs.length; ++idx) {
            uint256 member_idx = _clubMemberPayIndex[club.id][addrs[idx]];
            if (member_idx <= 0) {
                continue;
            }
            PayRecord storage record = _clubPayRecords[club.id][member_idx];
            if (record.state == RS.NORMAL && record.expireTime > block.timestamp) {
                uint256 remain_months = calculateRemainMonths(record.payTime, club.payMonths, RS.OWNER_REFUND);
                uint256 amount = record.payAmount.mul(remain_months).div(club.payMonths);
                uint256 surplus = record.payAmount.sub(amount);
                club.balance = club.balance.sub(amount);
                club.surplus = club.surplus.add(surplus);
                record.state = RS.OWNER_REFUND;
                record.refundAmount = amount;
                payable(record.payAddr).transfer(amount);
                emit Refund(msg.sender, club.id, record.payAddr, RS.OWNER_REFUND, amount);
            }
        }
    }

    function getWithdrawBalance(address nft_ca, uint256 token_id) public view returns (uint256) {
        Club memory club = getStakeInfo(nft_ca, token_id);
        uint256 amount = 0;
        PayRecord[] memory records = _clubPayRecords[club.id];
        for (uint idx = 1; idx < records.length; ++idx) {
            if (records[idx].state != RS.NORMAL) {
                continue;
            }
            if (records[idx].expireTime > block.timestamp) {
                uint256 stay_months = block.timestamp.sub(records[idx].payTime).div(SECONDS_OF_MONTH);
                amount = amount.add(records[idx].payAmount.mul(stay_months).div(club.payMonths));
            }
            else {
                amount = amount.add(records[idx].payAmount);
            }
        }
        return amount.add(club.surplus);
    }

    function withdraw(address nft_ca, uint256 token_id) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        uint256 receivable_amount = getWithdrawBalance(nft_ca, token_id);
        require(receivable_amount > club.withdrawAmount, "have no balance to withdraw");
        uint256 balance = receivable_amount.sub(club.withdrawAmount);
        club.withdrawAmount = receivable_amount;
        club.withdrawTime = block.timestamp;
        trans(balance);
        emit Withdraw(msg.sender, club.id, balance);
    }

    function withdrawExpire(address nft_ca, uint256 token_id, address[] calldata addrs) external callerIsUser {
        Club storage club = _staking[nft_ca][token_id];
        require(club.owner == msg.sender, "invalid owner address for current club");
        uint256 balance = 0;
        for (uint idx = 0; idx < addrs.length; ++idx) {
            uint256 member_idx = _clubMemberPayIndex[club.id][addrs[idx]];
            if (member_idx <= 0) {
                continue;
            }
            PayRecord storage record = _clubPayRecords[club.id][member_idx];
            if (record.state == RS.NORMAL && record.expireTime < block.timestamp) {
                record.state = RS.EXPIRE;
                if (club.withdrawTime > record.expireTime) {
                    continue;
                }
                uint256 remain_months = 0;
                if (club.withdrawTime < record.payTime) {
                    remain_months = club.payMonths;
                }
                else {
                    remain_months = club.payMonths - club.withdrawTime.sub(record.payTime).div(SECONDS_OF_MONTH);
                }
                uint256 remain_amount = record.payAmount.mul(remain_months).div(club.payMonths);
                balance = balance.add(remain_amount);
            }
        }
        club.surplus = club.surplus.add(balance);
        club.withdrawAmount = club.withdrawAmount.add(balance);
        trans(balance);
        emit WithdrawExpire(msg.sender, club.id, balance);
    }

    function trans(uint256 balance) internal {
        uint256 fees = balance.div(20);
        _dAddr.transfer(fees);
        payable(msg.sender).transfer(balance.sub(fees));
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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