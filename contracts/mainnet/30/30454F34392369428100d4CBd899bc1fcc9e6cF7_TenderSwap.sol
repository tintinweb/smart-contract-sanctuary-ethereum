// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { Multicall } from "../helpers/Multicall.sol";
import { SelfPermit } from "../helpers/SelfPermit.sol";

import "./LiquidityPoolToken.sol";
import "./SwapUtils.sol";
import "./ITenderSwap.sol";

// TODO: flat withdraw LP token fee ?

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

/**
 * @title TenderSwap
 * @dev TenderSwap is a light-weight StableSwap implementation for two assets.
 * See the Curve StableSwap paper for more details (https://curve.fi/files/stableswap-paper.pdf).
 * that trade 1:1 with eachother (e.g. USD stablecoins or tenderToken derivatives vs their underlying assets).
 * It supports Elastic Supply ERC20 tokens, which are tokens of which the balances can change
 * as the total supply of the token 'rebases'.
 */

contract TenderSwap is OwnableUpgradeable, ReentrancyGuardUpgradeable, ITenderSwap, Multicall, SelfPermit {
    using SwapUtils for SwapUtils.Amplification;
    using SwapUtils for SwapUtils.PooledToken;
    using SwapUtils for SwapUtils.FeeParams;

    // Fee parameters
    SwapUtils.FeeParams public feeParams;

    // Amplification coefficient parameters
    SwapUtils.Amplification public amplificationParams;

    // Pool Tokens
    SwapUtils.PooledToken private token0;
    SwapUtils.PooledToken private token1;

    // Liquidity pool shares
    LiquidityPoolToken public override lpToken;

    /*** MODIFIERS ***/

    /**
     * @notice Modifier to check deadline against current timestamp
     * @param _deadline latest timestamp to accept this transaction
     */
    modifier deadlineCheck(uint256 _deadline) {
        _deadlineCheck(_deadline);
        _;
    }

    /// @inheritdoc ITenderSwap
    function initialize(
        IERC20 _token0,
        IERC20 _token1,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        LiquidityPoolToken lpTokenTargetAddress
    ) external override initializer returns (bool) {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        // Check token addresses are different and not 0
        require(_token0 != _token1, "DUPLICATE_TOKENS");
        require(address(_token0) != address(0), "TOKEN0_ZEROADDRESS");
        require(address(_token1) != address(0), "TOKEN1_ZEROADDRESS");

        // Set precision multipliers
        uint8 _tenderTokenDecimals = IERC20Decimals(address(_token0)).decimals();
        require(_tenderTokenDecimals > 0);
        token0 = SwapUtils.PooledToken({
            token: _token0,
            precisionMultiplier: 10**(SwapUtils.POOL_PRECISION_DECIMALS - _tenderTokenDecimals)
        });

        uint8 _tokenDecimals = IERC20Decimals(address(_token1)).decimals();
        require(_tokenDecimals > 0);
        token1 = SwapUtils.PooledToken({
            token: _token1,
            precisionMultiplier: 10**(SwapUtils.POOL_PRECISION_DECIMALS - _tokenDecimals)
        });

        // Check _a and Set Amplifaction Parameters
        require(_a < SwapUtils.MAX_A, "_a exceeds maximum");
        amplificationParams.initialA = _a * SwapUtils.A_PRECISION;
        amplificationParams.futureA = _a * SwapUtils.A_PRECISION;

        // Check _fee, _adminFee and set fee parameters
        require(_fee < SwapUtils.MAX_SWAP_FEE, "_fee exceeds maximum");
        require(_adminFee < SwapUtils.MAX_ADMIN_FEE, "_adminFee exceeds maximum");
        feeParams = SwapUtils.FeeParams({ swapFee: _fee, adminFee: _adminFee });

        // Clone an existing LP token deployment in an immutable way
        // see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/proxy/Clones.sol
        lpToken = LiquidityPoolToken(Clones.clone(address(lpTokenTargetAddress)));
        require(lpToken.initialize(lpTokenName, lpTokenSymbol), "could not init lpToken clone");

        return true;
    }

    /*** VIEW FUNCTIONS ***/

    /// @inheritdoc ITenderSwap
    function getA() external view override returns (uint256) {
        return amplificationParams.getA();
    }

    /// @inheritdoc ITenderSwap
    function getAPrecise() external view override returns (uint256) {
        return amplificationParams.getAPrecise();
    }

    /// @inheritdoc ITenderSwap
    function getToken0() external view override returns (IERC20) {
        return token0.token;
    }

    /// @inheritdoc ITenderSwap
    function getToken1() external view override returns (IERC20) {
        return token1.token;
    }

    /// @inheritdoc ITenderSwap
    function getToken0Balance() external view override returns (uint256) {
        return token0.getTokenBalance();
    }

    /// @inheritdoc ITenderSwap
    function getToken1Balance() external view override returns (uint256) {
        return token1.getTokenBalance();
    }

    /// @inheritdoc ITenderSwap
    function getVirtualPrice() external view override returns (uint256) {
        return SwapUtils.getVirtualPrice(token0, token1, amplificationParams, lpToken);
    }

    /// @inheritdoc ITenderSwap
    function calculateSwap(IERC20 _tokenFrom, uint256 _dx) external view override returns (uint256) {
        return
            _tokenFrom == token0.token
                ? SwapUtils.calculateSwap(token0, token1, _dx, amplificationParams, feeParams)
                : SwapUtils.calculateSwap(token1, token0, _dx, amplificationParams, feeParams);
    }

    /// @inheritdoc ITenderSwap
    function calculateRemoveLiquidity(uint256 amount) external view override returns (uint256[2] memory) {
        SwapUtils.PooledToken[2] memory tokens_ = [token0, token1];
        return SwapUtils.calculateRemoveLiquidity(amount, tokens_, lpToken);
    }

    /// @inheritdoc ITenderSwap
    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, IERC20 tokenReceive)
        external
        view
        override
        returns (uint256)
    {
        return
            tokenReceive == token0.token
                ? SwapUtils.calculateWithdrawOneToken(
                    tokenAmount,
                    token0,
                    token1,
                    amplificationParams,
                    feeParams,
                    lpToken
                )
                : SwapUtils.calculateWithdrawOneToken(
                    tokenAmount,
                    token1,
                    token0,
                    amplificationParams,
                    feeParams,
                    lpToken
                );
    }

    /// @inheritdoc ITenderSwap
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view override returns (uint256) {
        SwapUtils.PooledToken[2] memory tokens_ = [token0, token1];

        return SwapUtils.calculateTokenAmount(tokens_, amounts, deposit, amplificationParams, lpToken);
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /// @inheritdoc ITenderSwap
    function swap(
        IERC20 _tokenFrom,
        uint256 _dx,
        uint256 _minDy,
        uint256 _deadline
    ) external override nonReentrant deadlineCheck(_deadline) returns (uint256) {
        if (_tokenFrom == token0.token) {
            return SwapUtils.swap(token0, token1, _dx, _minDy, amplificationParams, feeParams);
        } else if (_tokenFrom == token1.token) {
            return SwapUtils.swap(token1, token0, _dx, _minDy, amplificationParams, feeParams);
        } else {
            revert("BAD_TOKEN_FROM");
        }
    }

    /// @inheritdoc ITenderSwap
    function addLiquidity(
        uint256[2] calldata _amounts,
        uint256 _minToMint,
        uint256 _deadline
    ) external override nonReentrant deadlineCheck(_deadline) returns (uint256) {
        SwapUtils.PooledToken[2] memory tokens_ = [token0, token1];

        return SwapUtils.addLiquidity(tokens_, _amounts, _minToMint, amplificationParams, feeParams, lpToken);
    }

    /// @inheritdoc ITenderSwap
    function removeLiquidity(
        uint256 amount,
        uint256[2] calldata minAmounts,
        uint256 deadline
    ) external override nonReentrant deadlineCheck(deadline) returns (uint256[2] memory) {
        SwapUtils.PooledToken[2] memory tokens_ = [token0, token1];

        return SwapUtils.removeLiquidity(amount, tokens_, minAmounts, lpToken);
    }

    /// @inheritdoc ITenderSwap
    function removeLiquidityOneToken(
        uint256 _tokenAmount,
        IERC20 _tokenReceive,
        uint256 _minAmount,
        uint256 _deadline
    ) external override nonReentrant deadlineCheck(_deadline) returns (uint256) {
        if (_tokenReceive == token0.token) {
            return
                SwapUtils.removeLiquidityOneToken(
                    _tokenAmount,
                    token0,
                    token1,
                    _minAmount,
                    amplificationParams,
                    feeParams,
                    lpToken
                );
        } else {
            return
                SwapUtils.removeLiquidityOneToken(
                    _tokenAmount,
                    token1,
                    token0,
                    _minAmount,
                    amplificationParams,
                    feeParams,
                    lpToken
                );
        }
    }

    /// @inheritdoc ITenderSwap
    function removeLiquidityImbalance(
        uint256[2] calldata _amounts,
        uint256 _maxBurnAmount,
        uint256 _deadline
    ) external override nonReentrant deadlineCheck(_deadline) returns (uint256) {
        SwapUtils.PooledToken[2] memory tokens_ = [token0, token1];

        return
            SwapUtils.removeLiquidityImbalance(
                tokens_,
                _amounts,
                _maxBurnAmount,
                amplificationParams,
                feeParams,
                lpToken
            );
    }

    /*** ADMIN FUNCTIONS ***/

    /// @inheritdoc ITenderSwap
    function setAdminFee(uint256 newAdminFee) external override onlyOwner {
        feeParams.setAdminFee(newAdminFee);
    }

    /// @inheritdoc ITenderSwap
    function setSwapFee(uint256 newSwapFee) external override onlyOwner {
        feeParams.setSwapFee(newSwapFee);
    }

    /// @inheritdoc ITenderSwap
    function rampA(uint256 futureA, uint256 futureTime) external override onlyOwner {
        amplificationParams.rampA(futureA, futureTime);
    }

    /// @inheritdoc ITenderSwap
    function stopRampA() external override onlyOwner {
        amplificationParams.stopRampA();
    }

    /*** INTERNAL FUNCTIONS ***/

    function _deadlineCheck(uint256 _deadline) internal view {
        require(block.timestamp <= _deadline, "Deadline not met");
    }

    /// @inheritdoc ITenderSwap
    function transferOwnership(address _newOwnner) public override(OwnableUpgradeable, ITenderSwap) onlyOwner {
        OwnableUpgradeable.transferOwnership(_newOwnner);
    }
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param _data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata _data) external payable returns (bytes[] memory results);
}

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata _data) external payable override returns (bytes[] memory results) {
        results = new bytes[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(_data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param _token The address of the token spent
    /// @param _value The amount that can be spent of token
    /// @param _deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param _token The address of the token spent
    /// @param _value The amount that can be spent of token
    /// @param _deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;
}

abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable override {
        IERC20Permit(_token).permit(msg.sender, address(this), _value, _deadline, _v, _r, _s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable override {
        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        if (allowance < _value) selfPermit(_token, _value - allowance, _deadline, _v, _r, _s);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

contract LiquidityPoolToken is OwnableUpgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable {
    /**
     * @notice Initializes this LPToken contract with the given name and symbol
     * @dev The caller of this function will become the owner. A Swap contract should call this
     * in its initializer function.
     * @param name name of this token
     * @param symbol symbol of this token
     */
    function initialize(string memory name, string memory symbol) external initializer returns (bool) {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
        __Ownable_init_unchained();
        return true;
    }

    /**
     * @notice Mints the given amount of LPToken to the recipient.
     * @dev only owner can call this mint function.
     * @param recipient address of account to receive the tokens
     * @param amount amount of tokens to mint
     */

    function mint(address recipient, uint256 amount) external onlyOwner {
        require(amount != 0, "LPToken: cannot mint 0");
        _mint(recipient, amount);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libs/MathUtils.sol";
import "./LiquidityPoolToken.sol";

pragma solidity 0.8.4;

library SwapUtils {
    using MathUtils for uint256;
    using SafeERC20 for IERC20;

    // =============================================
    //                   EVENTS
    // =============================================
    event Swap(address indexed buyer, IERC20 tokenSold, uint256 amountSold, uint256 amountReceived);
    event AddLiquidity(
        address indexed provider,
        uint256[2] tokenAmounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(address indexed provider, uint256[2] tokenAmounts, uint256 lpTokenSupply);
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        IERC20 tokenReceived,
        uint256 receivedAmount
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] tokenAmounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);

    // =============================================
    //                 SWAP LOGIC
    // =============================================

    // the precision all pools tokens will be converted to
    uint8 public constant POOL_PRECISION_DECIMALS = 18;

    // the denominator used to calculate admin and LP fees. For example, an
    // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
    uint256 private constant FEE_DENOMINATOR = 10**10;

    // Max swap fee is 1% or 100bps of each swap
    uint256 public constant MAX_SWAP_FEE = 10**8;

    // Max adminFee is 100% of the swapFee
    // adminFee does not add additional fee on top of swapFee
    // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
    // users but only on the earnings of LPs
    uint256 public constant MAX_ADMIN_FEE = 10**10;

    // Constant value used as max loop limit
    uint256 private constant MAX_LOOP_LIMIT = 256;

    uint256 internal constant NUM_TOKENS = 2;

    struct FeeParams {
        uint256 swapFee;
        uint256 adminFee;
    }

    struct PooledToken {
        IERC20 token;
        uint256 precisionMultiplier;
    }

    // Struct storing variables used in calculations in the
    // {add,remove}Liquidity functions to avoid stack too deep errors
    struct ManageLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
        LiquidityPoolToken lpToken;
        uint256 totalSupply;
        PooledToken[2] tokens;
        uint256[2] oldBalances;
        uint256[2] newBalances;
    }

    // Struct storing variables used in calculations in the
    // calculateWithdrawOneTokenDY function to avoid stack too deep errors
    struct CalculateWithdrawOneTokenDYInfo {
        uint256 d0;
        uint256 d1;
        uint256 newY;
        uint256 feePerToken;
        uint256 preciseA;
    }

    /**
     * @notice swap two tokens in the pool
     * @param tokenFrom the token to sell
     * @param tokenTo the token to buy
     * @param dx the number of tokens to sell
     * @param minDy the min amount the user would like to receive (revert if not met)
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @return amount of token user received on swap
     */
    function swap(
        PooledToken storage tokenFrom,
        PooledToken storage tokenTo,
        uint256 dx,
        uint256 minDy,
        Amplification storage amplificationParams,
        FeeParams storage feeParams
    ) external returns (uint256) {
        require(dx <= tokenFrom.token.balanceOf(msg.sender), "ERC20: transfer amount exceeds balance");
        uint256 dy;
        uint256 dyFee;
        (dy, dyFee) = _calculateSwap(tokenFrom, tokenTo, dx, amplificationParams, feeParams);

        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee = (dyFee * feeParams.adminFee) / FEE_DENOMINATOR / tokenTo.precisionMultiplier;
        // TODO: Need to handle keeping track of admin fees or transfer them instantly

        // transfer tokens
        tokenFrom.token.safeTransferFrom(msg.sender, address(this), dx);
        tokenTo.token.safeTransfer(msg.sender, dy);

        emit Swap(msg.sender, tokenFrom.token, dx, dy);

        return dy;
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @param token0 token0 in the pool
     * @param token1 token1 in the pool
     * @param amplificationParams amplification parameters for the pool
     * @param lpToken Liquidity pool token
     * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice(
        PooledToken storage token0,
        PooledToken storage token1,
        Amplification storage amplificationParams,
        LiquidityPoolToken lpToken
    ) external view returns (uint256) {
        uint256 xp0 = _xp(_getTokenBalance(token0.token), token0.precisionMultiplier);
        uint256 xp1 = _xp(_getTokenBalance(token1.token), token1.precisionMultiplier);

        uint256 d = getD(xp0, xp1, _getAPrecise(amplificationParams));
        uint256 supply = lpToken.totalSupply();
        if (supply > 0) {
            return (d * (10**POOL_PRECISION_DECIMALS)) / supply;
        }
        return 0;
    }

    /**
     * @notice Externally calculates a swap between two tokens.
     * @param tokenFrom the token to sell
     * @param tokenTo the token to buy
     * @param dx the number of tokens to sell
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @return dy the number of tokens the user will get
     */
    function calculateSwap(
        PooledToken storage tokenFrom,
        PooledToken storage tokenTo,
        uint256 dx,
        Amplification storage amplificationParams,
        FeeParams storage feeParams
    ) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(tokenFrom, tokenTo, dx, amplificationParams, feeParams);
    }

    /**
     * @notice Add liquidity to the pool
     * @param tokens Array of [token0, token1]
     * @param amounts the amounts of each token to add, in their native precision
     * according to the cardinality of 'tokens'
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @param lpToken Liquidity pool token contract
     * @return amount of LP token user received
     */
    function addLiquidity(
        PooledToken[2] memory tokens,
        uint256[2] memory amounts,
        uint256 minToMint,
        Amplification storage amplificationParams,
        FeeParams storage feeParams,
        LiquidityPoolToken lpToken
    ) external returns (uint256) {
        // current state
        ManageLiquidityInfo memory v = ManageLiquidityInfo(
            0,
            0,
            0,
            _getAPrecise(amplificationParams),
            lpToken,
            0,
            tokens,
            [uint256(0), uint256(0)],
            [uint256(0), uint256(0)]
        );
        v.totalSupply = v.lpToken.totalSupply();

        // Get the current pool invariant d0
        if (v.totalSupply != 0) {
            uint256 _bal0 = _getTokenBalance(tokens[0].token);
            uint256 _bal1 = _getTokenBalance(tokens[1].token);
            v.oldBalances = [_bal0, _bal1];
            uint256 xp0 = _xp(_bal0, tokens[0].precisionMultiplier);
            uint256 xp1 = _xp(_bal1, tokens[1].precisionMultiplier);
            v.d0 = getD(xp0, xp1, v.preciseA);
        }

        // Transfer the tokens
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].token.safeTransferFrom(msg.sender, address(this), amounts[i]);
        }

        // calculate pool invariant after balance changes d1
        {
            uint256 _bal0 = _getTokenBalance(tokens[0].token);
            uint256 _bal1 = _getTokenBalance(tokens[1].token);
            v.newBalances = [_bal0, _bal1];
            uint256 _xp0 = _xp(_bal0, tokens[0].precisionMultiplier);
            uint256 _xp1 = _xp(_bal1, tokens[1].precisionMultiplier);
            v.d1 = getD(_xp0, _xp1, v.preciseA);
            require(v.d1 > v.d0, "D1 <= D0");
        }

        // calculate swap fees
        v.d2 = v.d1;

        // first entrant doesn't pay fees
        uint256[2] memory fees;
        if (v.totalSupply != 0) {
            uint256 feePerToken = _feePerToken(feeParams.swapFee);

            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 idealBal = (v.d1 * v.oldBalances[i]) / v.d0;
                (feePerToken * idealBal.difference(v.newBalances[i])) / FEE_DENOMINATOR;
                fees[i] = (feePerToken * idealBal.difference(v.newBalances[i])) / FEE_DENOMINATOR;
                v.newBalances[i] = v.newBalances[i] - fees[i];
                // TODO: handle admin fee
            }

            // calculate invariant after subtracting fees, d2
            {
                uint256 _xp0 = _xp(v.newBalances[0], tokens[0].precisionMultiplier);
                uint256 _xp1 = _xp(v.newBalances[1], tokens[1].precisionMultiplier);
                v.d2 = getD(_xp0, _xp1, v.preciseA);
            }
        }

        uint256 toMint;
        if (v.totalSupply == 0) {
            toMint = v.d1;
        } else {
            toMint = ((v.d2 - v.d0) * v.totalSupply) / v.d0;
        }

        require(toMint >= minToMint, "Couldn't mint min requested");

        // mint the user's LP tokens
        v.lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(msg.sender, amounts, fees, v.d1, v.totalSupply + toMint);

        return toMint;
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param tokens Array of [token0, token1]
     * @param minAmounts the minimum amounts of each token in the pool
     * acceptable for this burn. Useful as a front-running mitigation.
     * Should be according to the cardinality of 'tokens'
     * @param lpToken Liquidity pool token contract
     * @return amounts of tokens the user receives for each token in the pool
     * according to [token0, token1] cardinality
     */
    function removeLiquidity(
        uint256 amount,
        PooledToken[2] calldata tokens,
        uint256[2] calldata minAmounts,
        LiquidityPoolToken lpToken
    ) external returns (uint256[2] memory) {
        uint256 totalSupply = lpToken.totalSupply();

        uint256[2] memory amounts = _calculateRemoveLiquidity(amount, tokens, totalSupply);

        lpToken.burnFrom(msg.sender, amount);

        for (uint256 i = 0; i < tokens.length; i++) {
            require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
            tokens[i].token.safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidity(msg.sender, amounts, totalSupply - amount);

        return amounts;
    }

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param tokenAmount the amount of the lp tokens to burn
     * @param tokenReceive  the token you want to receive
     * @param tokenCounterpart the counterpart token in the pool of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @param lpToken Liquidity pool token contract
     * @return amount chosen token that user received
     */
    function removeLiquidityOneToken(
        uint256 tokenAmount,
        PooledToken storage tokenReceive,
        PooledToken storage tokenCounterpart,
        uint256 minAmount,
        Amplification storage amplificationParams,
        FeeParams storage feeParams,
        LiquidityPoolToken lpToken
    ) external returns (uint256) {
        uint256 totalSupply = lpToken.totalSupply();
        require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");

        (
            uint256 dy, /*uint256 dyFee*/

        ) = _calculateWithdrawOneToken(
                tokenAmount,
                tokenReceive,
                tokenCounterpart,
                totalSupply,
                amplificationParams,
                feeParams
            );

        require(dy >= minAmount, "dy < minAmount");

        // TODO: Handle admin fee from dyFee

        // Transfer tokens
        tokenReceive.token.safeTransfer(msg.sender, dy);

        // Burn LP tokens
        lpToken.burnFrom(msg.sender, tokenAmount);

        emit RemoveLiquidityOne(msg.sender, tokenAmount, totalSupply, tokenReceive.token, dy);

        return dy;
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     *
     * @param tokens Array of [token0, token1]
     * @param amounts how much of each token to withdraw according to cardinality of pooled tokens
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @param lpToken Liquidity pool token contract
     * @return actual amount of LP tokens burned in the withdrawal
     */
    function removeLiquidityImbalance(
        PooledToken[2] memory tokens,
        uint256[2] memory amounts,
        uint256 maxBurnAmount,
        Amplification storage amplificationParams,
        FeeParams storage feeParams,
        LiquidityPoolToken lpToken
    ) public returns (uint256) {
        ManageLiquidityInfo memory v = ManageLiquidityInfo({
            d0: 0,
            d1: 0,
            d2: 0,
            preciseA: _getAPrecise(amplificationParams),
            lpToken: lpToken,
            totalSupply: 0,
            tokens: tokens,
            oldBalances: [uint256(0), uint256(0)],
            newBalances: [uint256(0), uint256(0)]
        });

        v.totalSupply = v.lpToken.totalSupply();

        // Get the current pool invariant d0
        if (v.totalSupply != 0) {
            uint256 _bal0 = _getTokenBalance(tokens[0].token);
            uint256 _bal1 = _getTokenBalance(tokens[1].token);
            v.oldBalances = [_bal0, _bal1];
            uint256 xp0 = _xp(_bal0, tokens[0].precisionMultiplier);
            uint256 xp1 = _xp(_bal1, tokens[1].precisionMultiplier);
            v.d0 = getD(xp0, xp1, v.preciseA);
        }

        // calculate pool invariant after balance changes d1
        {
            require(v.oldBalances[0] >= amounts[0], "AMOUNT_EXCEEDS_BALANCE");
            require(v.oldBalances[1] >= amounts[1], "AMOUNT_EXCEEDS_BALANCE");

            uint256 _bal0 = v.oldBalances[0] - amounts[0];
            uint256 _bal1 = v.oldBalances[1] - amounts[1];
            v.newBalances = [_bal0, _bal1];
            uint256 _xp0 = _xp(_bal0, tokens[0].precisionMultiplier);
            uint256 _xp1 = _xp(_bal1, tokens[1].precisionMultiplier);
            v.d1 = getD(_xp0, _xp1, v.preciseA);
        }

        // calculate swap fees
        v.d2 = v.d1;

        // first entrant doesn't pay fees
        uint256[2] memory fees;
        uint256 feePerToken = _feePerToken(feeParams.swapFee);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 idealBal = (v.d1 * v.oldBalances[i]) / v.d0;
            (feePerToken * idealBal.difference(v.newBalances[i])) / FEE_DENOMINATOR;
            fees[i] = (feePerToken * idealBal.difference(v.newBalances[i])) / FEE_DENOMINATOR;
            v.newBalances[i] = v.newBalances[i] - fees[i];
            // TODO: handle admin fee
        }

        // calculate invariant after subtracting fees, d2
        {
            uint256 _xp0 = _xp(v.newBalances[0], tokens[0].precisionMultiplier);
            uint256 _xp1 = _xp(v.newBalances[1], tokens[1].precisionMultiplier);
            v.d2 = getD(_xp0, _xp1, v.preciseA);
        }

        uint256 tokenAmount = ((v.d0 - v.d2) * v.totalSupply) / v.d0;
        require(tokenAmount != 0, "Burnt amount cannot be zero");

        require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

        v.lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].token.safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(msg.sender, amounts, fees, v.d1, v.totalSupply - tokenAmount);

        return tokenAmount;
    }

    /**
     * @notice Calculate the dy, the amount of selected token that user receives and
     * the fee of withdrawing in one token
     * @param tokenAmount the amount to withdraw in the pool's precision
     * @param tokenReceive which token will be withdrawn
     * @param tokenCounterpart the token we need to swap for
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @param lpToken liquidity pool token
     * @return the amount of token user will receive
     */
    function calculateWithdrawOneToken(
        uint256 tokenAmount,
        PooledToken storage tokenReceive,
        PooledToken storage tokenCounterpart,
        Amplification storage amplificationParams,
        FeeParams storage feeParams,
        LiquidityPoolToken lpToken
    ) internal view returns (uint256) {
        (uint256 availableAmount, ) = _calculateWithdrawOneToken(
            tokenAmount,
            tokenReceive,
            tokenCounterpart,
            lpToken.totalSupply(),
            amplificationParams,
            feeParams
        );
        return availableAmount;
    }

    /**
     * @notice Calculate the dy, the amount of selected token that user receives and
     * the fee of withdrawing in one token
     * @param tokenAmount the amount to withdraw in the pool's precision
     * @param tokenReceive which token will be withdrawn
     * @param tokenCounterpart the token we need to swap for
     * @param totalSupply total supply of LP tokens
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @return the amount of token user will receive
     */
    function _calculateWithdrawOneToken(
        uint256 tokenAmount,
        PooledToken storage tokenReceive,
        PooledToken storage tokenCounterpart,
        uint256 totalSupply,
        Amplification storage amplificationParams,
        FeeParams storage feeParams
    ) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 newY;
        uint256 currentY;

        (dy, newY, currentY) = calculateWithdrawOneTokenDY(
            tokenAmount,
            tokenReceive,
            tokenCounterpart,
            totalSupply,
            _getAPrecise(amplificationParams),
            feeParams.swapFee
        );

        // dy_0 (without fees)
        // dy, dy_0 - dy

        uint256 dySwapFee = (currentY - newY) / tokenReceive.precisionMultiplier - dy;

        return (dy, dySwapFee);
    }

    /**
     * @notice Calculate the dy of withdrawing in one token
     * @param tokenAmount the amount to withdraw in the pools precision
     * @param tokenReceive Swap struct to read from
     * @param tokenCounterpart which token will be withdrawn
     * @param totalSupply total supply of the lp token
     * @return the d and the new y after withdrawing one token
     */
    function calculateWithdrawOneTokenDY(
        uint256 tokenAmount,
        PooledToken storage tokenReceive,
        PooledToken storage tokenCounterpart,
        uint256 totalSupply,
        uint256 preciseA,
        uint256 swapFee
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Get the current D, then solve the stableswap invariant
        // y_i for D - tokenAmount
        uint256 trBal = _getTokenBalance(tokenReceive.token);
        uint256 xpR = _xp(trBal, tokenReceive.precisionMultiplier);

        uint256 tcBal = _getTokenBalance(tokenCounterpart.token);
        uint256 xpC = _xp(tcBal, tokenCounterpart.precisionMultiplier);

        CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
        v.preciseA = preciseA;
        // swap from counterpart to receive (so counterpart is from and receive is to)
        v.d0 = getD(xpC, xpR, v.preciseA);
        v.d1 = v.d0 - ((tokenAmount * v.d0) / totalSupply);

        require(tokenAmount <= xpR, "AMOUNT_EXCEEDS_AVAILABLE");

        v.newY = getYD(v.preciseA, xpC, v.d1);

        v.feePerToken = _feePerToken(swapFee);

        // For xpR => dxExpected = xpR * d1 / d0 - newY
        // For xpC => dxExpected = xpC - (xpC * d1 / d0)
        // xpReduced -= dxExpected * fee / FEE_DENOMINATOR
        uint256 xpRReduced = xpR - (((xpR * v.d1) / v.d0 - v.newY) * v.feePerToken) / FEE_DENOMINATOR;
        uint256 xpCReduced = xpC - ((xpC - ((xpC * v.d1) / v.d0)) * v.feePerToken) / FEE_DENOMINATOR;

        uint256 dy = xpRReduced - getYD(v.preciseA, xpCReduced, v.d1);

        dy = (dy - 1) / tokenReceive.precisionMultiplier;

        return (dy, v.newY, xpR);
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param tokens Array of tokens in the pool
     *          according to pool cardinality [token0, token1]
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to tokens. The amount should be in each
     * pooled token's native precision.
     * @param deposit whether this is a deposit or a withdrawal
     * @param amplificationParams amplification parameters for the pool
     * @param lpToken liquidity pool token
     * @return if deposit was true, total amount of lp token that will be minted and if
     * deposit was false, total amount of lp token that will be burned
     */
    function calculateTokenAmount(
        PooledToken[2] memory tokens,
        uint256[] calldata amounts,
        bool deposit,
        Amplification storage amplificationParams,
        LiquidityPoolToken lpToken
    ) external view returns (uint256) {
        uint256 a = _getAPrecise(amplificationParams);

        uint256 xp0;
        uint256 xp0_;
        {
            uint256 prec0 = tokens[0].precisionMultiplier;
            uint256 bal0 = _getTokenBalance(tokens[0].token);
            xp0 = _xp(bal0, prec0);
            if (!deposit && bal0 < amounts[0]) revert("AMOUNT_EXCEEDS_SUPPLY");
            xp0_ = _xp(deposit ? bal0 + amounts[0] : bal0 - amounts[0], prec0);
        }

        uint256 xp1;
        uint256 xp1_;
        {
            uint256 prec1 = tokens[1].precisionMultiplier;
            uint256 bal1 = _getTokenBalance(tokens[1].token);
            xp1 = _xp(bal1, prec1);
            if (!deposit && bal1 < amounts[1]) revert("AMOUNT_EXCEEDS_SUPPLY");
            xp1_ = _xp(deposit ? bal1 + amounts[1] : bal1 - amounts[1], prec1);
        }

        uint256 d0 = getD(xp0, xp1, a);
        uint256 d1 = getD(xp0_, xp1_, a);

        uint256 totalSupply = lpToken.totalSupply();

        if (deposit) {
            return totalSupply == 0 ? d1 : ((d1 - d0) * totalSupply) / d0;
        } else {
            return ((d0 - d1) * totalSupply) / d0;
        }
    }

    /**
     * @notice Calculate the price of a token in the pool with given
     * precision-adjusted balances and a particular D.
     *
     * @dev This is accomplished via solving the invariant iteratively.
     * See the StableSwap paper and Curve.fi implementation for further details.
     *
     * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     * x_1**2 + b*x_1 = c
     * x_1 = (x_1**2 + c) / (2*x_1 + b)
     *
     * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
     * @param xpFrom a precision-adjusted balance of the token to send
     * @param d the stableswap invariant
     * @return the price of the token, in the same precision as in xp
     */
    function getYD(
        uint256 a,
        uint256 xpFrom,
        uint256 d
    ) internal pure returns (uint256) {
        uint256 c = (d * d) / (xpFrom * NUM_TOKENS);
        uint256 s = xpFrom;
        uint256 nA = a * NUM_TOKENS;

        c = (c * d * A_PRECISION) / (nA * NUM_TOKENS);

        uint256 b = s + ((d * A_PRECISION) / nA);

        uint256 yPrev;
        uint256 y = d;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            uint256 num = y * y + c;
            uint256 denom = y * 2 + b - d;
            y = num / denom;
            // y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Internally calculates a swap between two tokens.
     *
     * @dev The caller is expected to transfer the actual amounts (dx and dy)
     * using the token contracts.
     *
     * @param tokenFrom the token to sell
     * @param tokenTo the token to buy
     * @param dx the number of tokens to sell
     * @param amplificationParams amplification parameters for the pool
     * @param feeParams fee parameters for the pool
     * @return dy the number of tokens the user will get
     * @return dyFee the associated fee
     */
    function _calculateSwap(
        PooledToken storage tokenFrom,
        PooledToken storage tokenTo,
        uint256 dx,
        Amplification storage amplificationParams,
        FeeParams storage feeParams
    ) internal view returns (uint256 dy, uint256 dyFee) {
        // tokenFrom balance
        uint256 fromBalance = _getTokenBalance(tokenFrom.token);
        // precision adjusted balance
        uint256 fromXp = _xp(fromBalance, tokenFrom.precisionMultiplier);

        // tokenTo balance
        uint256 toBalance = _getTokenBalance(tokenTo.token);
        // precision adjusted balance
        uint256 toXp = _xp(toBalance, tokenTo.precisionMultiplier);

        // x is the new total amount of tokenFrom
        uint256 x = _xp(dx, tokenFrom.precisionMultiplier) + fromXp;

        uint256 y = getY(_getAPrecise(amplificationParams), fromXp, toXp, x);

        dy = toXp - y - 1;
        dyFee = (dy * feeParams.swapFee) / FEE_DENOMINATOR;
        dy = (dy - dyFee) / tokenTo.precisionMultiplier;
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of
     * LP tokens
     *
     * @param amount the amount of LP tokens that would to be burned on
     * withdrawal
     * @param tokens the tokens of the pool in their cardinality [token0, token1]
     * @param lpToken Liquidity pool token
     * @return array of amounts of tokens user will receive
     */
    function calculateRemoveLiquidity(
        uint256 amount,
        PooledToken[2] calldata tokens,
        LiquidityPoolToken lpToken
    ) external view returns (uint256[2] memory) {
        uint256 totalSupply = lpToken.totalSupply();
        uint256[2] memory amounts = _calculateRemoveLiquidity(amount, tokens, totalSupply);
        return amounts;
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of
     * LP tokens
     *
     * @param amount the amount of LP tokens that would to be burned on
     * withdrawal
     * @param tokens the tokens of the pool in their cardinality [token0, token1]
     * @param totalSupply total supply of the LP token
     * @return array of amounts of tokens user will receive
     */
    function _calculateRemoveLiquidity(
        uint256 amount,
        PooledToken[2] calldata tokens,
        uint256 totalSupply
    ) internal view returns (uint256[2] memory) {
        require(amount <= totalSupply, "Cannot exceed total supply");

        uint256[2] memory outAmounts;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = _getTokenBalance(tokens[i].token);
            outAmounts[i] = (balance * amount) / totalSupply;
        }
        return outAmounts;
    }

    /**
     * @notice Calculate the new balances of the tokens given FROM and TO tokens.
     * This function is used as a helper function to calculate how much TO token
     * the user should receive on swap.
     *
     * @param preciseA precise form of amplification coefficient
     * @param fromXp FROM precision-adjusted balance in the pool
     * @param toXp TO precision-adjusted balance in the pool
     * @param x the new total amount of precision-adjusted FROM token
     * @return the amount of TO token that should remain in the pool
     */
    function getY(
        uint256 preciseA,
        uint256 fromXp,
        uint256 toXp,
        uint256 x
    ) internal pure returns (uint256) {
        // d is the invariant of the pool
        uint256 d = getD(fromXp, toXp, preciseA);
        uint256 nA = NUM_TOKENS * preciseA;
        uint256 c = (d * d) / (x * NUM_TOKENS);
        c = (c * d * A_PRECISION) / (nA * NUM_TOKENS);

        uint256 b = x + ((d * A_PRECISION) / nA);
        uint256 yPrev;
        uint256 y = d;

        // iterative approximation
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (y * 2 + b - d);
            // y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
     * @param fromXp a precision-adjusted balance of the token to sell
     * @param toXp a precision-adjusted balance of the token to buy
     * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
     * See the StableSwap paper for details
     * @return the invariant, at the precision of the pool
     */
    function getD(
        uint256 fromXp,
        uint256 toXp,
        uint256 a
    ) internal pure returns (uint256) {
        uint256 s = fromXp + toXp;
        if (s == 0) return 0;

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a * NUM_TOKENS;

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = d;

            // dP = dP.mul(d).div(xp[j].mul(numTokens));

            dP = (dP * d) / (fromXp * NUM_TOKENS);
            dP = (dP * d) / (toXp * NUM_TOKENS);

            prevD = d;

            uint256 num = ((nA * s) / A_PRECISION + (dP * NUM_TOKENS)) * d;
            uint256 denom = ((nA - A_PRECISION) * d) / A_PRECISION + (NUM_TOKENS + 1) * dP;
            d = num / denom;
            // d = nA
            //     .mul(s)
            //     .div(A_PRECISION)
            //     .add(dP.mul(NUM_TOKENS))
            //     .mul(d)
            //     .div(
            //         nA
            //             .sub(A_PRECISION)
            //             .mul(d)
            //             .div(A_PRECISION)
            //             .add(NUM_TOKENS.add(1).mul(dP))
            //     );
            if (d.within1(prevD)) {
                return d;
            }
        }

        // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
        // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
        // function which does not rely on D.
        revert("D does not converge");
    }

    /**
     * @notice Given a a balance and precision multiplier, return the
     * precision-adjusted balance.
     *
     * @param balance a token balance in its native precision
     *
     * @param precisionMultiplier a precision multiplier for the token, When multiplied together they
     * should yield amounts at the pool's precision.
     *
     * @return an amount  "scaled" to the pool's precision
     */
    function _xp(uint256 balance, uint256 precisionMultiplier) internal pure returns (uint256) {
        return balance * precisionMultiplier;
    }

    /**
     * @notice internal helper function to calculate fee per token multiplier used in
     * swap fee calculations
     * @param swapFee swap fee for the tokens
     */
    function _feePerToken(uint256 swapFee) internal pure returns (uint256) {
        return swapFee / NUM_TOKENS;
    }

    // =============================================
    //             AMPLIFICATION LOGIC
    // =============================================

    // Constant values used in ramping A calculations
    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10**6;
    uint256 private constant MAX_A_CHANGE = 2;
    uint256 private constant MIN_RAMP_TIME = 14 days;

    struct Amplification {
        // variables around the ramp management of A,
        // the amplification coefficient * n * (n - 1)
        // see https://www.curve.fi/stableswap-paper.pdf for details
        uint256 initialA;
        uint256 futureA;
        uint256 initialATime;
        uint256 futureATime;
    }

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter
     */
    function getA(Amplification storage self) external view returns (uint256) {
        return _getAPrecise(self) / A_PRECISION;
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function getAPrecise(Amplification storage self) external view returns (uint256) {
        return _getAPrecise(self);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function _getAPrecise(Amplification storage self) internal view returns (uint256) {
        uint256 t1 = self.futureATime; // time when ramp is finished
        uint256 a1 = self.futureA; // final A value when ramp is finished

        if (block.timestamp < t1) {
            uint256 t0 = self.initialATime; // time when ramp is started
            uint256 a0 = self.initialA; // initial A value when ramp is started
            if (a1 > a0) {
                // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
                return a0 + ((a1 - a0) * (block.timestamp - t0)) / (t1 - t0);
            } else {
                // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
                return a0 - ((a0 - a1) * (block.timestamp - t0)) / (t1 - t0);
            }
        } else {
            return a1;
        }
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param self Swap struct to update
     * @param futureA_ the new A to ramp towards
     * @param futureTime_ timestamp when the new A should be reached
     */
    function rampA(
        Amplification storage self,
        uint256 futureA_,
        uint256 futureTime_
    ) external {
        require(block.timestamp >= self.initialATime + 1 days, "Wait 1 day before starting ramp");
        require(futureTime_ >= block.timestamp + MIN_RAMP_TIME, "Insufficient ramp time");
        require(futureA_ > 0 && futureA_ < MAX_A, "futureA_ must be > 0 and < MAX_A");

        uint256 initialAPrecise = _getAPrecise(self);
        uint256 futureAPrecise = futureA_ * A_PRECISION;

        if (futureAPrecise < initialAPrecise) {
            require(futureAPrecise * MAX_A_CHANGE >= initialAPrecise, "futureA_ is too small");
        } else {
            require(futureAPrecise <= initialAPrecise * MAX_A_CHANGE, "futureA_ is too large");
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureTime_;

        emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureTime_);
    }

    /**
     * @notice Stops ramping A immediately. Once this function is called, rampA()
     * cannot be called for another 24 hours
     * @param self Swap struct to update
     */
    function stopRampA(Amplification storage self) external {
        require(self.futureATime > block.timestamp, "Ramp is already stopped");

        uint256 currentA = _getAPrecise(self);
        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }

    // =============================================
    //            TOKEN INTERACTIONS
    // =============================================

    function getTokenBalance(PooledToken storage _token) external view returns (uint256) {
        return _getTokenBalance(_token.token);
    }

    function _getTokenBalance(IERC20 _token) internal view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    // =============================================
    //            FEE MANAGEMENT
    // =============================================

    /**
     * @notice Sets the admin fee
     * @dev adminFee cannot be higher than 100% of the swap fee
     * @param self Swap struct to update
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(FeeParams storage self, uint256 newAdminFee) external {
        require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
        self.adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }

    /**
     * @notice update the swap fee
     * @dev fee cannot be higher than 1% of each swap
     * @param self Swap struct to update
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(FeeParams storage self, uint256 newSwapFee) external {
        require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
        self.swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LiquidityPoolToken.sol";

pragma solidity 0.8.4;

/**
 * @title TenderSwap
 * @dev TenderSwap is a light-weight StableSwap implementation for two assets.
 * See the Curve StableSwap paper for more details (https://curve.fi/files/stableswap-paper.pdf).
 * that trade 1:1 with eachother (e.g. USD stablecoins or tenderToken derivatives vs their underlying assets).
 * It supports Elastic Supply ERC20 tokens, which are tokens of which the balances can change
 * as the total supply of the token 'rebases'.
 */

interface ITenderSwap {
    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients

    /**
     * @notice Swap gets emitted when an accounts exchanges tokens.
     * @param buyer address of the account initiating the swap
     * @param tokenSold address of the swapped token
     * @param amountSold amount of tokens swapped
     * @param amountReceived amount of tokens received in exchange
     */
    event Swap(address indexed buyer, IERC20 tokenSold, uint256 amountSold, uint256 amountReceived);

    /**
     * @notice AddLiquidity gets emitted when liquidity is added to the pool.
     * @param provider address of the account providing liquidity
     * @param tokenAmounts array of token amounts provided corresponding to pool cardinality of [token0, token1]
     * @param fees fees deducted for each of the tokens added corresponding to pool cardinality of [token0, token1]
     * @param invariant pool invariant after adding liquidity
     * @param lpTokenSupply the lpToken supply after minting
     */
    event AddLiquidity(
        address indexed provider,
        uint256[2] tokenAmounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    /**
     * @notice RemoveLiquidity gets emitted when liquidity for both tokens 
     * is removed from the pool.
     * @param provider address of the account removing liquidity
     * @param tokenAmounts array of token amounts removed corresponding to pool cardinality of [token0, token1]
     * @param lpTokenSupply total supply of liquidity pool token after removing liquidity
     */
    event RemoveLiquidity(address indexed provider, uint256[2] tokenAmounts, uint256 lpTokenSupply);

    /**
     * @notice RemoveLiquidityOne gets emitted when single-sided liquidity is removed 
     * @param provider address of the account removing liquidity
     * @param lpTokenAmount amount of liquidity pool tokens burnt
     * @param lpTokenSupply total supply of liquidity pool token after removing liquidity

     * @param tokenReceived address of the token for which liquidity was removed
     * @param receivedAmount amount of tokens received
     */
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        IERC20 tokenReceived,
        uint256 receivedAmount
    );

    /**
     * @notice RemoveLiquidityImbalance gets emitted when liquidity is removed weighted differently than the
     * pool's current balances.
     * with different weights than that of the pool.
     * @param provider address of the the account removing liquidity imbalanced
     * @param tokenAmounts array of amounts of tokens being removed corresponding 
     * to pool cardinality of [token0, token1]
     * @param fees fees for each of the tokens removed corresponding to pool cardinality of [token0, token1]
     * @param invariant pool invariant after removing liquidity
     * @param lpTokenSupply total supply of liquidity pool token after removing liquidity
     */
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] tokenAmounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    /**
     * @notice NewAdminFee gets emitted when the admin fee is updated.
     * @param newAdminFee admin fee after update
     */
    event NewAdminFee(uint256 newAdminFee);

    /**
     * @notice NewSwapFee gets emitted when the swap fee is updated.
     * @param newSwapFee swap fee after update
     */
    event NewSwapFee(uint256 newSwapFee);

    /**
     * @notice RampA gets emitted when A has started ramping up.
     * @param oldA initial A value
     * @param newA target value of A to ramp up to
     * @param initialTime ramp start timestamp
     * @param futureTime ramp end timestamp
     */
    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    /**
     * @notice StopRampA gets emitted when ramping A is stopped manually
     * @param currentA current value of A
     * @param time timestamp of when ramp is stopped
     */
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _token0 First token in the pool
     * @param _token1 Second token in the pool
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param lpTokenTargetAddress the address of an existing LiquidityPoolToken contract to use as a target
     * @return success true is successfully initialized
     */
    function initialize(
        IERC20 _token0,
        IERC20 _token1,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        LiquidityPoolToken lpTokenTargetAddress
    ) external returns (bool success);

    /*** VIEW FUNCTIONS ***/
    /**
     * @notice Returns the liquidity pool token contract.
     * @return lpTokenContract Liquidity pool token contract.
     */
    function lpToken() external view returns (LiquidityPoolToken lpTokenContract);

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @return a the amplifaction coefficient
     */
    function getA() external view returns (uint256 a);

    /**
     * @notice Return A in its raw precision form
     * @dev See the StableSwap paper for details
     * @return aPrecise A parameter in its raw precision form
     */
    function getAPrecise() external view returns (uint256 aPrecise);

    /**
     * @notice Returns the contract address for token0
     * @dev EVM return type is IERC20
     * @return token0 contract address
     */
    function getToken0() external view returns (IERC20 token0);

    /**
     * @notice Returns the contract address for token1
     * @dev EVM return type is IERC20
     * @return token1 contract address
     */
    function getToken1() external view returns (IERC20 token1);

    /**
     * @notice Return current balance of token0 (tender) in the pool
     * @return token0Balance current balance of the pooled tendertoken
     */
    function getToken0Balance() external view returns (uint256 token0Balance);

    /**
     * @notice Return current balance of token1 (underlying) in the pool
     * @return token1Balance current balance of the pooled underlying token
     */
    function getToken1Balance() external view returns (uint256 token1Balance);

    /**
     * @notice Get the override price, to help calculate profit
     * @return virtualPrice the override price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice() external view returns (uint256 virtualPrice);

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param _tokenFrom the token the user wants to sell
     * @param _dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return tokensToReceive amount of tokens the user will receive
     */
    function calculateSwap(IERC20 _tokenFrom, uint256 _dx) external view returns (uint256 tokensToReceive);

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param amount the amount of LP tokens that would be burned on withdrawal
     * @return tokensToReceive array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[2] memory tokensToReceive);

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param tokenAmount the amount of LP token to burn
     * @param tokenReceive the token to receive
     * @return tokensToReceive calculated amount of underlying token to be received.
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, IERC20 tokenReceive)
        external
        view
        returns (uint256 tokensToReceive);

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pool cardinality of [token0, token1]. The amount should be in each
     * pooled token's native precision.
     * @param deposit whether this is a deposit or a withdrawal
     * @return tokensToReceive token amount the user will receive
     */
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256 tokensToReceive);

    /*** POOL FUNCTIONALITY ***/

    /**
     * @notice Swap two tokens using this pool
     * @dev revert is token being sold is not in the pool.
     * @param _tokenFrom the token the user wants to sell
     * @param _dx the amount of tokens the user wants to swap from
     * @param _minDy the min amount the user would like to receive, or revert
     * @param _deadline latest timestamp to accept this transaction
     * @return _dy amount of tokens received
     */
    function swap(
        IERC20 _tokenFrom,
        uint256 _dx,
        uint256 _minDy,
        uint256 _deadline
    ) external returns (uint256 _dy);

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param _amounts the amounts of each token to add, in their native precision
     *          according to the cardinality of the pool [token0, token1]
     * @param _minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param _deadline latest timestamp to accept this transaction
     * @return lpMinted amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[2] calldata _amounts,
        uint256 _minToMint,
        uint256 _deadline
    ) external returns (uint256 lpMinted);

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     *        according to the cardinality of the pool [token0, token1]
     * @param deadline latest timestamp to accept this transaction
     * @return tokensReceived is the amounts of tokens user received
     */
    function removeLiquidity(
        uint256 amount,
        uint256[2] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[2] memory tokensReceived);

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param _tokenAmount the amount of the token you want to receive
     * @param _tokenReceive the  token you want to receive
     * @param _minAmount the minimum amount to withdraw, otherwise revert
     * @param _deadline latest timestamp to accept this transaction
     * @return tokensReceived amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 _tokenAmount,
        IERC20 _tokenReceive,
        uint256 _minAmount,
        uint256 _deadline
    ) external returns (uint256 tokensReceived);

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     * @param _amounts how much of each token to withdraw
     * @param _maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param _deadline latest timestamp to accept this transaction
     * @return lpBurned amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[2] calldata _amounts,
        uint256 _maxBurnAmount,
        uint256 _deadline
    ) external returns (uint256 lpBurned);

    /*** ADMIN FUNCTIONALITY ***/
    /**
     * @notice Update the admin fee. Admin fee takes portion of the swap fee.
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(uint256 newAdminFee) external;

    /**
     * @notice Update the swap fee to be applied on swaps
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(uint256 newSwapFee) external;

    /**
     * @notice Start ramping up or down A parameter towards given futureA and futureTime
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param futureA the new A to ramp towards
     * @param futureTime timestamp when the new A should be reached
     */
    function rampA(uint256 futureA, uint256 futureTime) external;

    /**
     * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
     */
    function stopRampA() external;

    /**
     * @notice Changes the owner of the contract
     * @param _newOwner address of the new owner
     */
    function transferOwnership(address _newOwner) external;
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
interface IERC20PermitUpgradeable {
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

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library MathUtils {
    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 10**21;

    /**
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(
        uint256 _amount,
        uint256 _fracNum,
        uint256 _fracDenom
    ) internal pure returns (uint256) {
        return (_amount * percPoints(_fracNum, _fracDenom)) / PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return (_amount * _fracNum) / PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return (_fracNum * PERC_DIVISOR) / _fracDenom;
    }

    /**
     * @notice Compares a and b and returns true if the difference between a and b
     *         is less than 1 or equal to each other.
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return True if the difference between a and b is less than 1 or equal,
     *         otherwise return false
     */
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        return (difference(a, b) <= 1);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        }
        return b - a;
    }
}