/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

pragma solidity ^0.8.12;


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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

interface IFeeDB {
    event UpdateFeeAndRecipient(uint256 newFee, address newRecipient);
    event UpdatePaysFeeWhenSending(bool newType);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function paysFeeWhenSending() external view returns (bool);

    function userDiscountRate(address user) external view returns (uint256);

    function userFee(address user, uint256 amount, address nft) external view returns (uint256);
}

interface IAPMReservoir {
    function token() external returns (address);

    event AddSigner(address signer);
    event RemoveSigner(address signer);
    event UpdateFeeDB(IFeeDB newFeeDB);
    event UpdateQuorum(uint256 newQuorum);
    event SendToken(
        address indexed sender,
        uint256 indexed toChainId,
        address indexed receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeeCollected
    );
    event ReceiveToken(
        address indexed sender,
        uint256 indexed fromChainId,
        address indexed receiver,
        uint256 amount,
        uint256 sendingId
    );

    function signers(uint256 id) external view returns (address);

    function signerIndex(address signer) external view returns (uint256);

    function quorum() external view returns (uint256);

    function feeDB() external view returns (IFeeDB);

    function signersLength() external view returns (uint256);

    function isSigner(address signer) external view returns (bool);

    function sendingData(
        address sender,
        uint256 toChainId,
        address receiver,
        uint256 sendingId
    ) external view returns (uint256 sendedAmount, uint256 sendingBlock);

    function isTokenReceived(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 sendingId
    ) external view returns (bool);

    function sendingCounts(
        address sender,
        uint256 toChainId,
        address receiver
    ) external view returns (uint256);

    function sendToken(
        uint256 toChainId,
        address receiver,
        uint256 amount,
        address nft
    ) external returns (uint256 sendingId);

    function receiveToken(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        address nft,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external;
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

library Signature {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid signature 's' value"
        );
        require(v == 27 || v == 28, "invalid signature 'v' value");

        signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "invalid signature");
    }
}

contract APMReservoir is Ownable, IAPMReservoir {
    using SafeMath for uint256;

    address[] public signers;
    mapping(address => uint256) public signerIndex;
    uint256 public signingNonce;
    uint256 public quorum;

    IFeeDB public feeDB;
    address public token;

    constructor(
        address _token,
        uint256 _quorum,
        address[] memory _signers
    ) {
        require(_token != address(0));
        token = _token;

        require(_quorum > 0);
        quorum = _quorum;
        emit UpdateQuorum(_quorum);

        require(_signers.length >= _quorum);
        signers = _signers;

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0));
            require(signerIndex[signer] == 0);

            if (i > 0) require(signer != _signers[0]);

            signerIndex[signer] = i;
            emit AddSigner(signer);
        }
    }

    function signersLength() public view returns (uint256) {
        return signers.length;
    }

    function isSigner(address signer) public view returns (bool) {
        return (signerIndex[signer] > 0) || (signers[0] == signer);
    }

    function _checkSigners(
        bytes32 message,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) private view {
        uint256 length = vs.length;
        require(length == rs.length && length == ss.length);
        require(length >= quorum);

        for (uint256 i = 0; i < length; i++) {
            require(isSigner(Signature.recover(message, vs[i], rs[i], ss[i])));
        }
    }

    function addSigner(
        address signer,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(signer != address(0));
        require(!isSigner(signer));

        bytes32 hash = keccak256(abi.encodePacked("addSigner", block.chainid, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        signerIndex[signer] = signersLength();
        signers.push(signer);
        emit AddSigner(signer);
    }

    function removeSigner(
        address signer,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(signer != address(0));
        require(isSigner(signer));

        bytes32 hash = keccak256(abi.encodePacked("removeSigner", block.chainid, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        uint256 lastIndex = signersLength().sub(1);
        require(lastIndex >= quorum);

        uint256 targetIndex = signerIndex[signer];
        if (targetIndex != lastIndex) {
            address lastSigner = signers[lastIndex];
            signers[targetIndex] = lastSigner;
            signerIndex[lastSigner] = targetIndex;
        }

        signers.pop();
        delete signerIndex[signer];

        emit RemoveSigner(signer);
    }

    function updateQuorum(
        uint256 newQuorum,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(newQuorum > 0);

        bytes32 hash = keccak256(abi.encodePacked("updateQuorum", block.chainid, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        quorum = newQuorum;
        emit UpdateQuorum(newQuorum);
    }

    function updateFeeDB(IFeeDB newDB) public onlyOwner {
        feeDB = newDB;
        emit UpdateFeeDB(newDB);
    }

    struct SendingData {
        uint256 sendedAmount;
        uint256 sendingBlock;
    }
    mapping(address => mapping(uint256 => mapping(address => SendingData[]))) public sendingData;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public isTokenReceived;

    function sendingCounts(
        address sender,
        uint256 toChainId,
        address receiver
    ) public view returns (uint256) {
        return sendingData[sender][toChainId][receiver].length;
    }

    function sendToken(
        uint256 toChainId,
        address receiver,
        uint256 amount,
        address nft
    ) public returns (uint256 sendingId) {
        sendingId = sendingCounts(msg.sender, toChainId, receiver);
        sendingData[msg.sender][toChainId][receiver].push(SendingData({sendedAmount: amount, sendingBlock: block.number}));

        bool paysFee = feeDB.paysFeeWhenSending();
        _takeAmount(msg.sender, amount, paysFee, nft);
        emit SendToken(msg.sender, toChainId, receiver, amount, sendingId, paysFee);
    }

    function receiveToken(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        address nft,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(!isTokenReceived[sender][fromChainId][receiver][sendingId]);

        bytes32 hash = keccak256(
            abi.encodePacked(fromChainId, sender, block.chainid, receiver, amount, sendingId, isFeePayed, nft)
        );
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        isTokenReceived[sender][fromChainId][receiver][sendingId] = true;
        _giveAmount(receiver, amount, isFeePayed, nft);

        emit ReceiveToken(sender, fromChainId, receiver, amount, sendingId);
    }

    function _takeAmount(
        address user,
        uint256 amount,
        bool paysFee,
        address nft
    ) private {
        uint256 fee;
        if (paysFee) {
            address feeRecipient;
            (fee, feeRecipient) = _getFeeData(user, amount, nft);
            if (fee != 0 && feeRecipient != address(0)) IERC20(token).transferFrom(user, feeRecipient, fee);
        }
        IERC20(token).transferFrom(user, address(this), amount);
    }

    function _giveAmount(
        address user,
        uint256 amount,
        bool isFeePayed,
        address nft
    ) private {
        uint256 fee;
        if (!isFeePayed) {
            address feeRecipient;
            (fee, feeRecipient) = _getFeeData(user, amount, nft);
            if (fee != 0 && feeRecipient != address(0)) IERC20(token).transfer(feeRecipient, fee);
        }
        IERC20(token).transfer(user, amount.sub(fee));
    }

    function _getFeeData(
        address user,
        uint256 amount,
        address nft
    ) private view returns (uint256 fee, address feeRecipient) {
        fee = feeDB.userFee(user, amount, nft);
        feeRecipient = feeDB.protocolFeeRecipient();
    }
}