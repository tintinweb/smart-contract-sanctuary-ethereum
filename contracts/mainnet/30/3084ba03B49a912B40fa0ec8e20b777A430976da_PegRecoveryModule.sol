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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurveMetaPool is IERC20{
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external;
    function remove_liquidity(uint256 _burning_amount, uint256[2] calldata _min_amounts) external;
    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _maxBurningAmount) external;
}

interface ICurvePool {
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external;
    function remove_liquidity(uint256 _burning_amount, uint256[3] calldata _min_amounts) external;
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _maxBurningAmount) external;
    function remove_liquidity_one_coin(uint256 _3crv_token_amount, int128 i, uint256 _min_amount) external;
    function calc_token_amount(uint256[3] calldata _amounts, bool _deposit) external view returns(uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 _i) external view returns(uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IVotiumMerkleStash {
    function claim(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICurveMetaPool, ICurvePool } from "../external/CurveInterfaces.sol";
import { IVotiumMerkleStash } from "../external/VotiumInterfaces.sol";
import { VotiumShare } from "./VotiumShare.sol";

// usdm3crv 0x5B3b5DF2BF2B6543f78e053bD91C4Bdd820929f1
// 3crv 0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7
// zap tx https://etherscan.io/tx/0x4a1c6582675b2582849b3947c63f53e209f320225aa501d0347bb8bae278d365
//BASE_COINS: constant(address[3]) = [
//    0x6B175474E89094C44Da98b954EedeAC495271d0F,  # DAI
//    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,  # USDC
//    0xdAC17F958D2ee523a2206206994597C13D831ec7,  # USDT
//]

contract PegRecoveryModule is VotiumShare{
    using SafeERC20 for IERC20;

    struct BaseCoins {
        uint256 dai;
        uint256 usdc;
        uint256 usdt;
    }

    // token addresses
    IERC20 public immutable usdm; // 0x31d4Eb09a216e181eC8a43ce79226A487D6F0BA9

    IERC20 public immutable crv3; // 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490

    IERC20 public immutable dai; // 0x6B175474E89094C44Da98b954EedeAC495271d0F

    IERC20 public immutable usdc; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

    IERC20 public immutable usdt; // 0xdAC17F958D2ee523a2206206994597C13D831ec7

    // curve addresses
    ICurveMetaPool public immutable usdm3crv; // 0x5B3b5DF2BF2B6543f78e053bD91C4Bdd820929f1

    ICurvePool public immutable crv3pool; // 0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7

    // usdm deposit info

    uint256 public totalUsdm;

    uint256 public usdmProvided;

    mapping(address => uint256) public usdmShare;

    // 3crv deposit info
    uint256 public totalCrv3;

    uint256 public crv3Provided;

    mapping(address => uint256) public crv3Share;

    // reward info

    constructor(
        IERC20 _usdm,
        IERC20 _crv3,
        IERC20 _dai,
        IERC20 _usdc, 
        IERC20 _usdt,
        ICurveMetaPool _usdm3crv,
        ICurvePool _crv3pool
    ) VotiumShare(){
        usdm = _usdm;
        crv3 = _crv3;
        dai = _dai;
        usdc = _usdc;
        usdt = _usdt;
        usdm3crv = _usdm3crv;
        crv3pool = _crv3pool;
    }

    // 3crv section

    function deposit3Crv(
        uint256 _deposit
    ) external updateReward(msg.sender) {
        totalCrv3 += _deposit;
        crv3Share[msg.sender] += _deposit;
        crv3.transferFrom(msg.sender, address(this), _deposit);
    }

    function withdraw3Crv(
        uint256 _withdraw
    ) external updateReward(msg.sender) {
        totalCrv3 -= _withdraw;
        crv3Share[msg.sender] -= _withdraw;
        crv3.transfer(msg.sender, _withdraw);
    }

    function depositStable(
        uint256[3] calldata _deposit,
        uint256 _min3crv
    ) external updateReward(msg.sender){
        // convert deposit to 3crv
        if(_deposit[0] > 0) {
            dai.safeTransferFrom(msg.sender, address(this), _deposit[0]);
            dai.safeApprove(address(crv3pool), _deposit[0]);
        }
        if(_deposit[1] > 0) {
            usdc.safeTransferFrom(msg.sender, address(this), _deposit[1]);
            usdc.safeApprove(address(crv3pool), _deposit[1]);
        }
        if(_deposit[2] > 0) {
            usdt.safeTransferFrom(msg.sender, address(this), _deposit[2]);
            usdt.safeApprove(address(crv3pool), _deposit[2]);
        }

        // add liquidity to 3pool right away and hold as 3crv
        uint256 balance = crv3.balanceOf(address(this));
        crv3pool.add_liquidity(
            _deposit,
            _min3crv
        );
        // **vague name to use only 1 variable
        balance = crv3.balanceOf(address(this)) - balance;

        // update storage variables
        totalCrv3 += balance;
        crv3Share[msg.sender] += balance;
    }

    function withdrawStable(
        uint256[3] calldata _withdraw,
        uint256 _3crv_max
    ) external updateReward(msg.sender) {
        // update storage variables
        uint256 balance = crv3.balanceOf(address(this));
        crv3pool.remove_liquidity_imbalance(
            _withdraw,
            _3crv_max
        );
        balance = balance - crv3.balanceOf(address(this));
        totalCrv3 -= balance;
        crv3Share[msg.sender] -= balance;
        if(_withdraw[0] > 0){
            dai.safeTransfer(msg.sender, _withdraw[0]);
        }
        if(_withdraw[1] > 0){
            usdc.safeTransfer(msg.sender, _withdraw[1]);
        }
        if(_withdraw[2] > 0){
            usdt.safeTransfer(msg.sender, _withdraw[2]);
        }
    }

    // usdm section
    function depositUsdm(
        uint256 _usdm
    ) external updateReward(msg.sender) {
        usdmShare[msg.sender] += _usdm;
        totalUsdm += _usdm;
        usdm.transferFrom(msg.sender, address(this), _usdm);
    }

    function withdrawUsdm(
        uint256 _usdm
    ) external updateReward(msg.sender){
        usdmShare[msg.sender] -= _usdm;
        totalUsdm -= _usdm;
        usdm.transfer(msg.sender, _usdm);
    }

    // peg recovery section
    function pairLiquidity(uint256 _amount, uint256 _min_liquidity) external onlyOwner {
        uint256[2] memory amounts = [_amount, _amount];
        usdm.safeApprove(address(usdm3crv), _amount);
        crv3.safeApprove(address(usdm3crv), _amount);
        usdmProvided += _amount;
        crv3Provided += _amount;
        usdm3crv.add_liquidity(amounts, _min_liquidity);
    }

    function removeLiquidity(uint256 _amount, uint256 _max_burn) external onlyOwner {
        uint256[2] memory amounts = [_amount, _amount];
        usdmProvided -= _amount;
        crv3Provided -= _amount;
        usdm3crv.remove_liquidity_imbalance(amounts, _max_burn);
    }

    function sweepTokens() external onlyOwner {
        uint256 usdmLeftover = usdm.balanceOf(address(this)) - (totalUsdm - usdmProvided);
        usdm.transfer(msg.sender, usdmLeftover);
        uint256 crv3Leftover = crv3.balanceOf(address(this)) - (totalCrv3 - crv3Provided);
        crv3.transfer(msg.sender, crv3Leftover);
    }

    // --- votium virtual functions ---
    function _balanceOf(address _user) internal view override returns(uint256) {
        return usdmShare[_user] + crv3Share[_user];
    }

    function _supply() internal view override returns(uint256) {
        return totalUsdm + totalCrv3;
    }

    function approvedReward(IERC20 _token) public view override returns(bool) {
        return address(_token) != address(usdm) && address(_token) != address(crv3) && address(_token) != address(usdm3crv);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { BoringMath } from "./library/BoringMath.sol";
import { IVotiumMerkleStash } from "../external/VotiumInterfaces.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


abstract contract VotiumShare is Ownable {
    using BoringMath for uint256;
    using SafeERC20 for IERC20;
    // reward section
    struct Reward {
        uint256 rewardLeft;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
    }

    // claim section
    struct ClaimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[]  merkleProof;
    }
    
    // earned reward section
    struct EarnedData {
        address token;
        uint256 amount;
    }

    // votium = https://etherscan.io/address/0x378ba9b73309be80bf4c2c027aad799766a7ed5a#writeContract

    IERC20[] public rewardTokens;

    mapping(IERC20 => Reward) public rewardData;

    mapping(IERC20 => uint256) public rewardIndex;

    uint256 public constant rewardsDuration = 86400 * 14;

    address public team;

    // user -> reward token -> amount
    mapping(address => mapping(IERC20 => uint256)) public userRewardPerTokenPaid;

    mapping(address => mapping(IERC20 => uint256)) public rewards;

    constructor() {
        team = msg.sender;
    }

    modifier updateReward(address _account) {
        for (uint i = 0; i < rewardTokens.length; i++) {
            IERC20 token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = _rewardPerToken(token).to208();
            rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish).to40();
            if (_account != address(0)) {
                rewards[_account][token] = _earned(_account, token, _balanceOf(_account));
                userRewardPerTokenPaid[_account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    function changeTeam(address _team) external onlyOwner {
        team = _team;
    }

    function syncRewards(IERC20[] memory _tokens) external {
        for(uint256 i = 0; i<_tokens.length; i++){
            IERC20 token = _tokens[i];
            require(approvedReward(token), "!approvedReward");
            uint256 increasedToken = token.balanceOf(address(this)) - rewardData[token].rewardLeft;
            _notifyReward(
                token,
                increasedToken * 8 / 10
            );

            rewardData[token].rewardLeft += increasedToken;
            token.transfer(team, increasedToken * 2 / 10);

            if(rewardIndex[token] == 0) {
                rewardTokens.push(token);
                rewardIndex[token] = rewardTokens.length;
            }
        }
    }
    
    // Address and claimable amount of all reward tokens for the given account
    function claimableAmount(address _account) external view returns(EarnedData[] memory userRewards) {
        userRewards = new EarnedData[](rewardTokens.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            IERC20 token = rewardTokens[i];
            userRewards[i].token = address(token);
            userRewards[i].amount = _earned(_account, token, _balanceOf(_account));
        }
        return userRewards;
    }


    function claim() external updateReward(msg.sender) {
        for (uint i; i < rewardTokens.length; i++) {
            IERC20 _rewardsToken = IERC20(rewardTokens[i]);
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                rewardData[_rewardsToken].rewardLeft -= reward;
                _rewardsToken.safeTransfer(msg.sender, reward);
            }
        }
    }

    // --- internal functions ---

    function _notifyReward(IERC20 _rewardsToken, uint256 _reward) internal {
        Reward storage rdata = rewardData[_rewardsToken];

        if (block.timestamp >= rdata.periodFinish) {
            rdata.rewardRate = _reward.div(rewardsDuration).to208();
        } else {
            uint256 remaining = uint256(rdata.periodFinish).sub(block.timestamp);
            uint256 leftover = remaining.mul(rdata.rewardRate);
            rdata.rewardRate = _reward.add(leftover).div(rewardsDuration).to208();
        }

        rdata.lastUpdateTime = block.timestamp.to40();
        rdata.periodFinish = block.timestamp.add(rewardsDuration).to40();
    }

    function _rewardPerToken(IERC20 _rewardsToken) internal view returns(uint256) {
        if (_supply() == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        uint256(rewardData[_rewardsToken].rewardPerTokenStored).add(
            _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish).sub(
                rewardData[_rewardsToken].lastUpdateTime).mul(
                rewardData[_rewardsToken].rewardRate).mul(1e18).div(_supply())
        );

    }

    function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns(uint256) {
        return Math.min(block.timestamp, _finishTime);
    }

    function _earned(
        address _user,
        IERC20 _rewardsToken,
        uint256 _balance
    ) internal view returns(uint256) {
        return _balance.mul(
            _rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[_user][_rewardsToken])
        ).div(1e18).add(rewards[_user][_rewardsToken]);
    }

    // --- virtual internal functions ---
    function _balanceOf(address _user) internal view virtual returns(uint256);

    function _supply() internal view virtual returns(uint256);

    function approvedReward(IERC20 _token) public view virtual returns(bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked { 
            require((c = a + b) >= b, "BoringMath: Add Overflow");
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked { 
            require((c = a - b) <= a, "BoringMath: Underflow");
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked { 
            require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked { 
            require(b > 0, "BoringMath: division by zero");
            return a / b;
        }
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        unchecked { 
            require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
            c = uint128(a);
        }
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        unchecked { 
            require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
            c = uint64(a);
        }
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        unchecked { 
            require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
            c = uint32(a);
        }
    }

    function to40(uint256 a) internal pure returns (uint40 c) {
        unchecked { 
            require(a <= type(uint40).max, "BoringMath: uint40 Overflow");
            c = uint40(a);
        }
    }

    function to112(uint256 a) internal pure returns (uint112 c) {
        unchecked { 
            require(a <= type(uint112).max, "BoringMath: uint112 Overflow");
            c = uint112(a);
        }
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        unchecked { 
            require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
            c = uint224(a);
        }
    }

    function to208(uint256 a) internal pure returns (uint208 c) {
        unchecked { 
            require(a <= type(uint208).max, "BoringMath: uint208 Overflow");
            c = uint208(a);
        }
    }

    function to216(uint256 a) internal pure returns (uint216 c) {
        unchecked { 
            require(a <= type(uint216).max, "BoringMath: uint216 Overflow");
            c = uint216(a);
        }
    }
}