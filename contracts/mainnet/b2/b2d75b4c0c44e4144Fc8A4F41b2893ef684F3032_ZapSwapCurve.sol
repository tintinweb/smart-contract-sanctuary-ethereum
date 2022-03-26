// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import "../libraries/Authorizable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ICurvePool.sol";

// TODO Due to the nature of the curve contracts, there are a number of design
// decisions made in this contract which primarily aim to generalize integration
// with curve. Curve contracts have often an inconsistent interface to many
// functions in their contracts which has influenced the design of this contract
// to target curve pool functions using function signatures computed off-chain.
// The validation of this and other features of this contract stem from this
// problem, for instance, the curve pool contracts target their underlying
// tokens using fixed-length dimensional arrays of length 2 or 3. We could
// harden this contract further by utilizing the "coins" function on the curve
// contract which would enable this contract validate that our input structure
// is correct. However, this would also run into problems as the guarantee of
// consistency of the "coins" function is also in question across the suite of
// pools in the curve ecosystem. There may be a solution to mitigate this
// problem but may be more trouble than it's worth.

/// @title ZapCurveTokenToPrincipalToken
/// @notice Allows the user to buy and sell principal tokens using a wider
/// array of tokens
/// @dev This contract introduces the concept of "root tokens" which are the
/// set of constituent tokens for a given curve pool. Each principal token
/// is constructed by a yield-generating position which in this case will be
/// represented by a curve LP token. This is referred to as the "base token"
/// and in the case where the user wishes to purchase or sell a principal token,
/// it can only be done so by using this token.
///
/// What this contract intends to do is enable the user purchase or sell
/// a position using those "root tokens" which would garner significant UX
/// improvements. The flow in the case of purchasing is as follows, the root
/// tokens are added as liquidity into the correct curve pool, giving a curve
/// "LP token" or "base token". Subsequently this is then used to purchase the
/// principal token. Selling works similarly but in the reverse direction.
///
/// Ex- Alice bought (x) amount curve LP token (let's say crvLUSD token) using LUSD (root token)
/// purchased (x) amount can be used to purchase the principal token by putting that amount
/// in the wrapped position contract.
contract ZapSwapCurve is Authorizable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    // Store the accessibility state of the contract
    bool public isFrozen;

    // A constant to represent ether
    address internal constant _ETH_CONSTANT =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Reference to the main balancer vault
    IVault internal immutable _balancer;

    /////////////////////////
    /// Zap In Data Structure
    /////////////////////////

    struct ZapInInfo {
        // The balancerPoolId references the particular pool in the balancer
        // contract which is used to exchange for the principal token
        bytes32 balancerPoolId;
        // The recipient is a target address the sender can send the resulting
        // principal tokens to
        address recipient;
        // Address of the principalToken
        IAsset principalToken;
        // The minimum amount of principal tokens the user expects to receive
        uint256 minPtAmount;
        // The time into the future for which the trade can happen
        uint256 deadline;
        // Some curvePools have themselves a dependent lpToken "root" which
        // this contract accommodates zapping through. This flag indicates if
        // such an action is necessary
        bool needsChildZap;
    }

    struct ZapCurveLpIn {
        // Address of target curvePool for which liquidity will be added
        // giving this contract the lpTokens necessary to swap for the
        // principalTokens
        address curvePool;
        // The target lpToken which will be received
        IERC20 lpToken;
        // Array of amounts which are structured in reference to the
        // "add_liquidity" function in the related curvePool. These in all
        // cases come in either fixed-length arrays of length 2 or 3
        uint256[] amounts;
        // Similar to "amounts", these are the reference token contract
        // addresses also ordered as per the inconsistent interface of the
        // "add_liquidity" curvePool function
        address[] roots;
        // Only relevant when there is a childZap, it references what
        // index in the amounts array of the main "zap" the resultant
        // number of lpTokens should be added to
        uint256 parentIdx;
        // The minimum amount of LP tokens expected to receive when adding
        // liquidity
        uint256 minLpAmount;
    }

    ///////////////////////////
    /// Zap Out Data Structure
    //////////////////////////

    struct ZapCurveLpOut {
        // Address of the curvePool for which an amount of lpTokens
        // is swapped for an amount of single root tokens
        address curvePool;
        // The contract address of the curve pools lpToken
        IERC20 lpToken;
        // This is the index of the target root we are swapping for
        int128 rootTokenIdx;
        // Address of the rootToken we are swapping for
        address rootToken;
        // This is the selector for deciding between the two differing curve
        // interfaces for the add
        bool curveRemoveLiqFnIsUint256;
    }

    struct ZapOutInfo {
        // Pool id of balancer pool that is used to exchange a users
        // amount of principal tokens
        bytes32 balancerPoolId;
        // Address of the principal token
        IAsset principalToken;
        // Amount of principal tokens the user wishes to swap for
        uint256 principalTokenAmount;
        // The recipient is the address the tokens which are to be swapped for
        // will be sent to
        address payable recipient;
        // The minimum amount base tokens the user is expecting
        uint256 minBaseTokenAmount;
        // The minimum amount root tokens the user is expecting
        uint256 minRootTokenAmount;
        // Timestamp into the future for which a transaction is valid for
        uint256 deadline;
        // If the target root token is sourced via two curve pool swaps, then
        // this is to be flagged as true
        bool targetNeedsChildZap;
    }

    /// @notice Memory encoding of the permit data
    struct PermitData {
        IERC20Permit tokenContract;
        address spender;
        uint256 amount;
        uint256 expiration;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @notice Sets the msg.sender as authorized and also set it as the owner
    ///         in the authorizable contract.
    /// @param __balancer The balancer vault contract
    constructor(IVault __balancer) {
        _authorize(msg.sender);
        _balancer = __balancer;
        isFrozen = false;
    }

    /// @notice Requires that the contract is not frozen
    modifier notFrozen() {
        require(!isFrozen, "Contract frozen");
        _;
    }

    // Allow this contract to receive ether
    receive() external payable {}

    /// @notice Allows an authorized address to freeze or unfreeze this contract
    /// @param _newState True for frozen and false for unfrozen
    function setIsFrozen(bool _newState) external onlyAuthorized {
        isFrozen = _newState;
    }

    /// @notice Takes the input permit calls and executes them
    /// @param data The array which encodes the set of permit calls to make
    modifier preApproval(PermitData[] memory data) {
        // If permit calls are provided we make try to make them
        _permitCall(data);
        _;
    }

    /// @notice Makes permit calls indicated by a struct
    /// @param data the struct which has the permit calldata
    function _permitCall(PermitData[] memory data) internal {
        // Make the permit call to the token in the data field using
        // the fields provided.
        if (data.length != 0) {
            // We make permit calls for each indicated call
            for (uint256 i = 0; i < data.length; i++) {
                data[i].tokenContract.permit(
                    msg.sender,
                    data[i].spender,
                    data[i].amount,
                    data[i].expiration,
                    data[i].v,
                    data[i].r,
                    data[i].s
                );
            }
        }
    }

    /// @notice This function sets approvals on all ERC20 tokens.
    /// @param tokens An array of token addresses which are to be approved
    /// @param spenders An array of contract addresses, most likely curve and
    /// balancer pool addresses
    /// @param amounts An array of amounts for which at each index, the spender
    /// from the same index in the spenders array is approved to use the token
    /// at the equivalent index of the token array on behalf of this contract
    function setApprovalsFor(
        address[] memory tokens,
        address[] memory spenders,
        uint256[] memory amounts
    ) external onlyAuthorized {
        require(tokens.length == spenders.length, "Incorrect length");
        require(tokens.length == amounts.length, "Incorrect length");
        for (uint256 i = 0; i < tokens.length; i++) {
            // Below call is to make sure that previous allowance shouldn't revert the transaction
            // It is just a safety pattern to use.
            IERC20(tokens[i]).safeApprove(spenders[i], uint256(0));
            IERC20(tokens[i]).safeApprove(spenders[i], amounts[i]);
        }
    }

    /// @notice zapIn Exchanges a number of tokens which are used in a specific
    /// curve pool(s) for a principal token.
    /// @param _info See ZapInInfo struct
    /// @param _zap See ZapCurveLpIn struct - This is the "main" or parent zap
    /// which produces the lp token necessary to swap for the principal token
    /// @param _childZap See ZapCurveLpIn - This is used only in cases where
    /// the "main" or "parent" zap itself is composed of another curve lp token
    /// which can be accessed more readily via another swap via curve
    function zapIn(
        ZapInInfo memory _info,
        ZapCurveLpIn memory _zap,
        ZapCurveLpIn memory _childZap,
        PermitData[] memory _permitData
    )
        external
        payable
        nonReentrant
        notFrozen
        preApproval(_permitData)
        returns (uint256 ptAmount)
    {
        // Instantiation of the context amount container which is used to track
        // amounts to be swapped in the final curve zap.
        uint256[3] memory ctx;

        // Only execute the childZap if it is necessary
        if (_info.needsChildZap) {
            uint256 _amount = _zapCurveLpIn(
                _childZap,
                // The context array is unnecessary for the childZap and so we
                // can just put a dud array in place of it
                [uint256(0), uint256(0), uint256(0)]
            );
            // When a childZap happens, we add the amount of lpTokens gathered
            // from it to the relevant root index of the "main" zap
            ctx[_childZap.parentIdx] += _amount;
        }

        // Swap an amount of "root" tokens on curve for the lp token that is
        // used to then purchase the principal token
        uint256 baseTokenAmount = _zapCurveLpIn(_zap, ctx);

        // Purchase of "ptAmount" of principal tokens
        ptAmount = _balancer.swap(
            IVault.SingleSwap({
                poolId: _info.balancerPoolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(_zap.lpToken)),
                assetOut: _info.principalToken,
                amount: baseTokenAmount,
                userData: "0x00"
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(_info.recipient),
                toInternalBalance: false
            }),
            _info.minPtAmount,
            _info.deadline
        );
    }

    /// @notice This function will add liquidity to a target curve pool,
    /// returning some amount of LP tokens as a result. This is effectively
    /// swapping amounts of the dependent curve pool tokens for the LP token
    /// which will be used elsewhere
    /// @param _zap ZapCurveLpIn struct
    /// @param _ctx fixed length array used as an amounts container between the
    /// zap and childZap and also makes the transition from a dynamic-length
    /// array to a fixed-length which is required for the actual call to add
    /// liquidity to the curvePool
    function _zapCurveLpIn(ZapCurveLpIn memory _zap, uint256[3] memory _ctx)
        internal
        returns (uint256)
    {
        // All curvePools have either 2 or 3 "root" tokens
        require(
            _zap.amounts.length == 2 || _zap.amounts.length == 3,
            "!(2 >= amounts.length <= 3)"
        );

        // Flag to detect if a zap to curve should be made
        bool shouldMakeZap = false;
        for (uint8 i = 0; i < _zap.amounts.length; i++) {
            bool zapIndexHasAmount = _zap.amounts[i] > 0;
            // If either the _ctx or zap amounts array has an index with an
            // amount > 0 we must zap curve
            shouldMakeZap = (zapIndexHasAmount || _ctx[i] > 0)
                ? true
                : shouldMakeZap;

            // if there is no amount at this index we can escape the loop earlier
            if (!zapIndexHasAmount) continue;

            if (_zap.roots[i] == _ETH_CONSTANT) {
                // Must check we do not unintentionally send ETH
                require(msg.value == _zap.amounts[i], "incorrect value");

                // We build the context container with our amounts
                _ctx[i] += _zap.amounts[i];
            } else {
                uint256 beforeAmount = _getBalanceOf(IERC20(_zap.roots[i]));

                // In the case of swapping an ERC20 "root" we must transfer them
                // to this contract in order to make the exchange
                IERC20(_zap.roots[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _zap.amounts[i]
                );

                // Due to rounding issues of some tokens, we use the
                // differential token balance of this contract
                _ctx[i] += _getBalanceOf(IERC20(_zap.roots[i])) - beforeAmount;
            }
        }

        // When there is nothing to swap for on curve we short-circuit
        if (!shouldMakeZap) {
            return 0;
        }
        uint256 beforeLpTokenBalance = _getBalanceOf(_zap.lpToken);

        if (_zap.amounts.length == 2) {
            ICurvePool(_zap.curvePool).add_liquidity{ value: msg.value }(
                [_ctx[0], _ctx[1]],
                _zap.minLpAmount
            );
        } else {
            ICurvePool(_zap.curvePool).add_liquidity{ value: msg.value }(
                [_ctx[0], _ctx[1], _ctx[2]],
                _zap.minLpAmount
            );
        }

        return _getBalanceOf(_zap.lpToken) - beforeLpTokenBalance;
    }

    /// @notice zapOut Allows users sell their principalTokens and subsequently
    /// swap the resultant curve LP token for one of its dependent "root tokens"
    /// @param _info See ZapOutInfo
    /// @param _zap See ZapCurveLpOut
    /// @param _childZap See ZapCurveLpOut
    function zapOut(
        ZapOutInfo memory _info,
        ZapCurveLpOut memory _zap,
        ZapCurveLpOut memory _childZap,
        PermitData[] memory _permitData
    )
        external
        payable
        nonReentrant
        notFrozen
        preApproval(_permitData)
        returns (uint256 amount)
    {
        // First, principalTokenAmount of principal tokens transferred
        // from sender to this contract
        IERC20(address(_info.principalToken)).safeTransferFrom(
            msg.sender,
            address(this),
            _info.principalTokenAmount
        );

        // Swaps an amount of users principal tokens for baseTokens, which
        // are the lpToken specified in the zap argument
        uint256 baseTokenAmount = _balancer.swap(
            IVault.SingleSwap({
                poolId: _info.balancerPoolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: _info.principalToken,
                assetOut: IAsset(address(_zap.lpToken)),
                amount: _info.principalTokenAmount,
                userData: "0x00"
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            _info.minBaseTokenAmount,
            _info.deadline
        );

        // Swap the baseTokens for a target root. In the case of where the
        // specified token the user wants is part of the childZap, the zap that
        // occurs is to swap the baseTokens to the lpToken specified in the
        // childZap struct. If there is no childZap, then the contract sends
        // the tokens to the recipient
        amount = _zapCurveLpOut(
            _zap,
            baseTokenAmount,
            _info.targetNeedsChildZap ? 0 : _info.minRootTokenAmount,
            _info.targetNeedsChildZap ? payable(address(this)) : _info.recipient
        );

        // Execute the childZap is specified to do so
        if (_info.targetNeedsChildZap) {
            amount = _zapCurveLpOut(
                _childZap,
                amount,
                _info.minRootTokenAmount,
                _info.recipient
            );
        }
    }

    /// @notice Swaps an amount of curve LP tokens for a single root token
    /// @param _zap See ZapCurveLpOut
    /// @param _lpTokenAmount This is the amount of lpTokens we are swapping
    /// with
    /// @param _minRootTokenAmount This is the minimum amount of "root" tokens
    /// the user expects to swap for. Used only in the final zap when executed
    /// under zapOut
    /// @param _recipient The address which the outputs tokens are to be sent
    /// to. When there is a second zap to occur, in the first zap the recipient
    /// should be this address
    function _zapCurveLpOut(
        ZapCurveLpOut memory _zap,
        uint256 _lpTokenAmount,
        uint256 _minRootTokenAmount,
        address payable _recipient
    ) internal returns (uint256 rootAmount) {
        // Flag to detect if we are sending to recipient
        bool transferToRecipient = address(this) != _recipient;
        uint256 beforeAmount = _zap.rootToken == _ETH_CONSTANT
            ? address(this).balance
            : _getBalanceOf(IERC20(_zap.rootToken));

        if (_zap.curveRemoveLiqFnIsUint256) {
            ICurvePool(_zap.curvePool).remove_liquidity_one_coin(
                _lpTokenAmount,
                uint256(int256(_zap.rootTokenIdx)),
                _minRootTokenAmount
            );
        } else {
            ICurvePool(_zap.curvePool).remove_liquidity_one_coin(
                _lpTokenAmount,
                _zap.rootTokenIdx,
                _minRootTokenAmount
            );
        }

        // ETH case
        if (_zap.rootToken == _ETH_CONSTANT) {
            // Get ETH balance of current contract
            rootAmount = address(this).balance - beforeAmount;
            // if address does not equal this contract we send funds to recipient
            if (transferToRecipient) {
                // Send rootAmount of ETH to the user-specified recipient
                _recipient.transfer(rootAmount);
            }
        } else {
            // Get balance of root token that was swapped
            rootAmount = _getBalanceOf(IERC20(_zap.rootToken)) - beforeAmount;
            // Send tokens to recipient
            if (transferToRecipient) {
                IERC20(_zap.rootToken).safeTransferFrom(
                    address(this),
                    _recipient,
                    rootAmount
                );
            }
        }
    }

    function _getBalanceOf(IERC20 _token) internal view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "./IAsset.sol";

// This interface is used instead of importing one from balancer contracts to
// resolve version conflicts
interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function getPool(bytes32 poolId)
        external
        view
        returns (address, PoolSpecialization);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICurvePool {
    function add_liquidity(uint256[2] memory amountCtx, uint256 minAmount)
        external
        payable;

    function add_liquidity(uint256[3] memory amountCtx, uint256 minAmount)
        external
        payable;

    function remove_liquidity_one_coin(
        uint256 amountLp,
        uint256 idx,
        uint256 minAmount
    ) external payable;

    function remove_liquidity_one_coin(
        uint256 amount,
        int128 idx,
        uint256 minAmount
    ) external payable;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// This interface is used instead of importing one from balancer contracts to
// resolve version conflicts
interface IAsset {

}