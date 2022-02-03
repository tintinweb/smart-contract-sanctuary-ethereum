//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20WithPermit.sol";
import "./interfaces/IUniswapV2Router02.sol";

import "./utils/LondonTxSupport.sol";
// import "./utils/LegacyTxSupport.sol";

contract PlasmaGasStation is Ownable, LondonTxSupport {

    using SafeMath for uint256;

    mapping(address => bool) private feePayers;
    mapping(address => bool) private feeAllowedTokens;
    mapping(address => uint256) private preCallGasUsage;
    mapping(address => uint256) private postCallGasUsage;

    IUniswapV2Router02 private router;

    bytes32 public DOMAIN_SEPARATOR;
    // Used to prevent overspending of gas
    uint256 private maxPreCallGasUsage = 230000;
    uint256 private maxPostCallGasUsage = 120000;

    modifier onlyFeePayer() {
        require(feePayers[msg.sender], "Unknown fee payer address");
        require(msg.sender == tx.origin, "Fee payer must be sender of transaction");
        _;
    }

    event TransactionExecuted(
        address indexed from,
        address to,
        address feeToken,
        uint256 feeAmount
    );

    constructor(address _router, address _feePayer) {
        router = IUniswapV2Router02(_router);
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

    function setRouter(IUniswapV2Router02 _router) external onlyOwner {
        router = _router;
    }

    function getRouter() external view returns (address) {
        return address(router);
    }

    function addTrustedFeePayer(address _feePayer) external onlyOwner {
        if (_feePayer != address(0)) {
            feePayers[_feePayer] = true;
        }
    }

    function removeTrustedFeePayer(address _feePayer) external onlyOwner {
        feePayers[_feePayer] = false;
    }

    function hasTrustedFeePayer(address _feePayer) external view returns (bool) {
        return feePayers[_feePayer];
    }

    function setMaxPreCallGasUsage(uint256 _maxPreCallGasUsage) external onlyOwner {
        maxPreCallGasUsage = _maxPreCallGasUsage;
    }

    function getMaxPreCallGasUsage() external view returns (uint256) {
        return maxPreCallGasUsage;
    }

    function setMaxPostCallGasUsage(uint256 _maxPostCallGasUsage) external onlyOwner {
        maxPostCallGasUsage = _maxPostCallGasUsage;
    }

    function getMaxPostCallGasUsage() external view returns (uint256) {
        return maxPostCallGasUsage;
    }

    function hasFeeToken(address _feeToken) external view returns (bool) {
        return feeAllowedTokens[_feeToken];
    }

    function addFeeToken(address _feeToken) external onlyOwner {
        require(_feeToken != address(0), 'Cannot use zero address');
        require(!feeAllowedTokens[_feeToken], 'Token already allowed');

        feeAllowedTokens[_feeToken] = true;
        preCallGasUsage[_feeToken] = 0;
        postCallGasUsage[_feeToken] = 0;
    }

    function removeFeeToken(address _feeToken) external onlyOwner {
        require(_feeToken != address(0), 'Cannot use zero address');
        require(feeAllowedTokens[_feeToken], 'Token already deny');

        feeAllowedTokens[_feeToken] = false;
    }

    function getEstimateGas(address _feeToken) external view returns (uint256) {
        require(feeAllowedTokens[_feeToken], "Fee token not supported");
        return _getEstimatedPostGallGas(_feeToken).add(_getEstimatedPreGallGas(_feeToken));
    }

    /**
     * @notice Perform a transaction, take payment for gas with tokens, and exchange tokens back to ETH
     */
    function sendTransaction(TxRequest calldata _tx, TxFee calldata _fee, bytes calldata _sign) external onlyFeePayer {
        uint256 initialGas = gasleft();
        _verify(_tx, _sign);
        require(feeAllowedTokens[_fee.token], "Fee token not supported");

        IERC20WithPermit token = IERC20WithPermit(_fee.token);

        // Approve fee token by EIP712
        if (_fee.approvalData.length == 160) {
            (uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(_fee.approvalData, (uint256, uint256, uint8, bytes32, bytes32));
            token.permit(_tx.from, address(this), value, deadline, v, r, s);
        }

        // We calculate and collect tokens to pay for the transaction
        uint256 maxFeeInEth = _calculateCharge(_tx.gas, _tx);
        uint256 maxFeeInTokens = router.getAmountsIn(maxFeeInEth, _getSwapPair(address(token)))[0];
        token.transferFrom(_tx.from, address(this), maxFeeInTokens);

        // Pre call gas usage
        uint256 preCallGasUsed = initialGas.sub(gasleft());
        require(initialGas.sub(gasleft()) < maxPreCallGasUsage, "Pre call gas overspending");
        preCallGasUsage[_fee.token] = _max(preCallGasUsage[_fee.token], preCallGasUsed);

        // Execute user's transaction
        _call(_tx.from, _tx.to, _tx.value, _tx.data);

        uint256 callGasUsed = initialGas.sub(gasleft());
        uint256 estimatedGasUsed = callGasUsed.add(_getEstimatedPostGallGas(_fee.token));

        // Exchange user's tokens to ETH
        require(token.approve(address(router), maxFeeInTokens), "Approve router failed");
        uint256 feeInEth = _calculateCharge(estimatedGasUsed, _tx);
        uint256 spentTokens = router.swapTokensForExactETH(feeInEth, maxFeeInTokens, _getSwapPair(address(token)), msg.sender, block.timestamp)[0];

        // Send rest of tokens to user
        if (spentTokens < maxFeeInTokens) {
            require(token.transfer(_tx.from, maxFeeInTokens.sub(spentTokens)));
        }

        emit TransactionExecuted(_tx.from, _tx.to, _fee.token, spentTokens);

        // We check the gas consumption, and save it for calculation in the following transactions
        uint256 postCallGasUsed = initialGas.sub(gasleft()).sub(preCallGasUsed);
        require(postCallGasUsed < maxPostCallGasUsage, "Post call gas overspending");
        postCallGasUsage[_fee.token] = _max(postCallGasUsage[_fee.token], postCallGasUsed);
    }

    /**
     * @notice Executes a transaction.
     * @dev Used to calculate the gas required to complete the transaction.
     */
    function execute(address from, address to, uint256 value, bytes calldata data) external onlyFeePayer {
        _call(from, to, value, data);
    }

    function _call(address from, address to, uint256 value, bytes calldata data) internal {
        bytes memory callData = abi.encodePacked(data, from);
        (bool success,) = to.call{value : value}(callData);

        require(success, "Transaction Call Error");
    }

    function _getSwapPair(address tokenAddress) internal returns (address[] memory) {
        address[] memory swapPair = new address[](2);

        swapPair[0] = tokenAddress;
        swapPair[1] = router.WETH();
        return swapPair;
    }

    function _verify(TxRequest calldata _tx, bytes calldata _sign) internal {
        require(_tx.deadline == 0 || _tx.deadline > block.timestamp, "Request expired");
        require(nonces[_tx.from]++ == _tx.nonce, "Nonce mismatch");

        address signer = _getSigner(DOMAIN_SEPARATOR, _tx, _sign);

        require(signer != address(0) && signer == _tx.from, 'Invalid signature');
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function _getEstimatedPreGallGas(address _feeToken) internal view returns (uint256) {
        return preCallGasUsage[_feeToken] > 0 ? preCallGasUsage[_feeToken] : maxPreCallGasUsage;
    }

    function _getEstimatedPostGallGas(address _feeToken) internal view returns (uint256) {
        return postCallGasUsage[_feeToken] > 0 ? postCallGasUsage[_feeToken] : maxPostCallGasUsage;
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

    function _calculateCharge(uint256 _gasUsed, TxRequest calldata _tx) internal pure returns (uint256) {
        return _gasUsed.mul(_tx.maxFeePerGas);
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

interface IUniswapV2Router02 {
    function factory() external returns (address);

    function WETH() external returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] memory path, address to, uint256 deadline)
    external
    payable
    returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] memory path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20WithPermit is IERC20, IERC20Permit {}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
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
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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