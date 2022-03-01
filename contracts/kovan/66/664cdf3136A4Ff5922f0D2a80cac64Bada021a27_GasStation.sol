//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@plasma-fi/contracts/interfaces/ITokensApprover.sol";
import "./interfaces/ISwapV2Router.sol";
import "./interfaces/IGasStationTokensStore.sol";
import "./interfaces/IExchange.sol";
import "./utils/FeePayerGuard.sol";

import "./utils/LondonTxSupport.sol";
//import "./utils/LegacyTxSupport.sol";

contract GasStation is Ownable, FeePayerGuard, LondonTxSupport {

    using SafeMath for uint256;

    IExchange public exchange;

    IGasStationTokensStore public feeTokensStore;

    ITokensApprover public approver;

    bytes32 public DOMAIN_SEPARATOR;
    // Commission as a percentage of the transaction fee, for processing one transaction.
    uint256 public txRelayFeePercent;
    // Post call gas limit (Prevents overspending of gas)
    uint256 public maxPostCallGasUsage = 350000;
    // Gas usage by tokens
    mapping(address => uint256) postCallGasUsage;

    event GasStationTxExecuted(
        address indexed from,
        address to,
        address feeToken,
        uint256 totalFeeInTokens,
        uint256 txRelayFeeInEth
    );
    event GasStationExchangeUpdated(address indexed newExchange);
    event GasStationFeeTokensStoreUpdated(address indexed newFeeTokensStore);
    event GasStationApproverUpdated(address indexed newApprover);
    event GasStationTxRelayFeePercentUpdated(uint256 newTxRelayFeePercent);
    event GasStationMaxPostCallGasUsageUpdated(uint256 newMaxPostCallGasUsage);

    constructor(address _exchange, address _feeTokensStore, address _approver, address _feePayer, uint256 _txRelayFeePercent) {
        exchange = IExchange(_exchange);
        feeTokensStore = IGasStationTokensStore(_feeTokensStore);
        approver = ITokensApprover(_approver);
        txRelayFeePercent = _txRelayFeePercent;

        if (_feePayer != address(0)) {
            feePayers[_feePayer] = true;
        }

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function setExchange(address _exchange) external onlyOwner {
        exchange = IExchange(_exchange);
        emit GasStationExchangeUpdated(_exchange);
    }

    function setFeeTokensStore(IGasStationTokensStore _feeTokensStore) external onlyOwner {
        feeTokensStore = _feeTokensStore;
        emit GasStationFeeTokensStoreUpdated(address(_feeTokensStore));
    }

    function setApprover(ITokensApprover _approver) external onlyOwner {
        approver = _approver;
        emit GasStationApproverUpdated(address(_approver));
    }

    function setTxRelayFeePercent(uint256 _txRelayFeePercent) external onlyOwner {
        txRelayFeePercent = _txRelayFeePercent;
        emit GasStationTxRelayFeePercentUpdated(_txRelayFeePercent);
    }

    function setMaxPostCallGasUsage(uint256 _maxPostCallGasUsage) external onlyOwner {
        maxPostCallGasUsage = _maxPostCallGasUsage;
        emit GasStationMaxPostCallGasUsageUpdated(_maxPostCallGasUsage);
    }

    function getEstimatedPostCallGas(address _token) external view returns (uint256) {
        require(feeTokensStore.isAllowedToken(_token), "Fee token not supported");
        return _getEstimatedPostCallGas(_token);
    }
    /**
     * @notice Perform a transaction, take payment for gas with tokens, and exchange tokens back to ETH
     */
    function sendTransaction(TxRequest calldata _tx, TxFee calldata _fee, bytes calldata _sign) external onlyFeePayer {
        uint256 initialGas = gasleft();
        address txSender = _tx.from;
        IERC20 token = IERC20(_fee.token);

        // Verify sign and fee token
        _verify(_tx, _sign);
        require(feeTokensStore.isAllowedToken(address(token)), "Fee token not supported");

        // Execute user's transaction
        _call(txSender, _tx.to, _tx.value, _tx.data);

        // Total gas usage for call.
        uint256 callGasUsed = initialGas.sub(gasleft());
        uint256 estimatedGasUsed = callGasUsed.add(_getEstimatedPostCallGas(address(token)));
        require(estimatedGasUsed < _tx.gas, "Not enough gas");

        // Approve fee token with permit method
        _permit(_fee.token, _fee.approvalData);

        // We calculate and collect tokens to pay for the transaction
        (uint256 maxFeeInEth,) = _calculateCharge(_tx.gas, txRelayFeePercent, _tx);
        uint256 maxFeeInTokens = exchange.getEstimatedTokensForETH(token, maxFeeInEth);
        require(token.transferFrom(txSender, address(exchange), maxFeeInTokens), "Transfer fee failed");

        // Exchange user's tokens to ETH and emit executed event
        (uint256 totalFeeInEth, uint256 txRelayFeeInEth) = _calculateCharge(estimatedGasUsed, txRelayFeePercent, _tx);
        uint256 spentTokens = exchange.swapTokensToETH(token, totalFeeInEth, maxFeeInTokens, msg.sender, txSender);
        emit GasStationTxExecuted(txSender, _tx.to, _fee.token, spentTokens, txRelayFeeInEth);

        // We check the gas consumption, and save it for calculation in the following transactions
        _setUpEstimatedPostCallGas(_fee.token, initialGas.sub(gasleft()).sub(callGasUsed));
    }
    /**
     * @notice Executes a transaction.
     * @dev Used to calculate the gas required to complete the transaction.
     */
    function execute(address from, address to, uint256 value, bytes calldata data) external onlyFeePayer {
        _call(from, to, value, data);
    }

    function _permit(address token, bytes calldata approvalData) internal {
        if (approvalData.length > 0 && approver.hasConfigured(token)) {
            (bool success,) = approver.callPermit(token, approvalData);
            require(success, "Permit Method Call Error");
        }
    }

    function _call(address from, address to, uint256 value, bytes calldata data) internal {
        bytes memory callData = abi.encodePacked(data, from);
        (bool success,) = to.call{value : value}(callData);

        require(success, "Transaction Call Error");
    }

    function _verify(TxRequest calldata _tx, bytes calldata _sign) internal {
        require(_tx.deadline == 0 || _tx.deadline > block.timestamp, "Request expired");
        require(nonces[_tx.from]++ == _tx.nonce, "Nonce mismatch");

        address signer = _getSigner(DOMAIN_SEPARATOR, _tx, _sign);

        require(signer != address(0) && signer == _tx.from, 'Invalid signature');
    }

    function _getEstimatedPostCallGas(address _token) internal view returns (uint256) {
        return postCallGasUsage[_token] > 0 ? postCallGasUsage[_token] : maxPostCallGasUsage;
    }

    function _setUpEstimatedPostCallGas(address _token, uint256 _postCallGasUsed) internal {
        require(_postCallGasUsed < maxPostCallGasUsage, "Post call gas overspending");
        postCallGasUsage[_token] = _max(postCallGasUsage[_token], _postCallGasUsed);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EIP712Library.sol";

abstract contract LondonTxSupport is EIP712Library {
    using SafeMath for uint256;

    struct TxRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 deadline;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    int public constant TX_VERSION = 2;

    bytes32 public constant TX_REQUEST_TYPEHASH = keccak256("TxRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 deadline,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas)");

    function _getSigner(bytes32 _ds, TxRequest calldata _tx, bytes calldata _sign) internal pure returns (address) {
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                _ds,
                keccak256(abi.encodePacked(
                    TX_REQUEST_TYPEHASH,
                    uint256(uint160(_tx.from)),
                    uint256(uint160(_tx.to)),
                    _tx.value,
                    _tx.gas,
                    _tx.nonce,
                    keccak256(_tx.data),
                    _tx.deadline,
                    _tx.maxFeePerGas,
                    _tx.maxPriorityFeePerGas
                ))
            ));

        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(_sign);
        return ecrecover(digest, v, r, s);
    }

    function _calculateCharge(uint256 _gasUsed, uint256 _txRelayFeePercent, TxRequest calldata _tx) internal view returns (uint256, uint256) {
        uint256 baseFee = block.basefee.add(_tx.maxPriorityFeePerGas);
        uint256 feePerGas = baseFee < _tx.maxFeePerGas ? baseFee : _tx.maxFeePerGas;

        uint256 feeForAllGas = _gasUsed.mul(feePerGas);
        uint256 totalFee = feeForAllGas.mul(_txRelayFeePercent.add(100)).div(100);
        uint256 txRelayFee = totalFee.sub(feeForAllGas);

        return (totalFee, txRelayFee);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeePayerGuard is Ownable {

    mapping(address => bool) internal feePayers;

    modifier onlyFeePayer() {
        require(feePayers[msg.sender], "Unknown fee payer address");
        require(msg.sender == tx.origin, "Fee payer must be sender of transaction");
        _;
    }

    function addFeePayer(address _feePayer) external onlyOwner {
        if (_feePayer != address(0)) {
            feePayers[_feePayer] = true;
        }
    }

    function removeFeePayer(address _feePayer) external onlyOwner {
        feePayers[_feePayer] = false;
    }

    function hasFeePayer(address _feePayer) external view returns (bool) {
        return feePayers[_feePayer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

abstract contract EIP712Library {

    struct TxFee {
        address token;
        bytes approvalData;
    }

    string public constant name = 'Plasma Gas Station';
    string public constant version = '1';
    mapping(address => uint256) public nonces;

    function getNonce(address from) external view returns (uint256) {
        return nonces[from];
    }

    function _splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "Signature invalid length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature invalid v byte");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapV2Router {
    function WETH() external returns (address);
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IGasStationTokensStore {
    function feeTokens() external view returns (address[] memory);
    function addFeeToken(address _token) external;
    function removeFeeToken(address _token) external;
    function isAllowedToken(address _token) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExchange {
    /// @dev Calculation of the number of tokens that you need to spend to get _ethAmount
    /// @param _token - The address of the token that we exchange for ETH.
    /// @param _ethAmount - The amount of ETH to be received.
    /// @return The number of tokens you need to get ETH.
    function getEstimatedTokensForETH(IERC20 _token, uint256 _ethAmount) external returns (uint256);

    /// @dev Exchange tokens for ETH
    /// @param _token - The address of the token that we exchange for ETH.
    /// @param _receiveEthAmount - The exact amount of ETH to be received.
    /// @param _tokensMaxSpendAmount - The maximum number of tokens allowed to spend.
    /// @param _ethReceiver - The wallet address to send ETH to after the exchange.
    /// @param _tokensReceiver - Wallet address, to whom to send the remaining unused tokens from the exchange.
    /// @return Number of tokens spent.
    function swapTokensToETH(IERC20 _token, uint256 _receiveEthAmount, uint256 _tokensMaxSpendAmount, address _ethReceiver, address _tokensReceiver) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ITokensApprover {
    /**
     * @notice Data for issuing permissions for the token
     */
    struct ApproveConfig {
        string name;
        string version;
        string domainType;
        string primaryType;
        string noncesMethod;
        string permitMethod;
        bytes4 permitMethodSelector;
    }

    function addConfig(ApproveConfig calldata config) external returns (uint256);

    function setConfig(uint256 id, ApproveConfig calldata config) external returns (uint256);

    function setToken(uint256 id, address token) external;

    function getConfig(address token) view external returns (ApproveConfig memory);

    function getConfigById(uint256 id) view external returns (ApproveConfig memory);

    function configsLength() view external returns (uint256);

    function hasConfigured(address token) view external returns (bool);

    function callPermit(address token, bytes calldata permitCallData) external returns (bool, bytes memory);
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