// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IBoostedVaultWithLockup } from "../../interfaces/IBoostedVaultWithLockup.sol";
import { IFeederPool } from "../../interfaces/IFeederPool.sol";
import { IMasset } from "../../interfaces/IMasset.sol";
import { ISavingsContractV3 } from "../../interfaces/ISavingsContract.sol";
import { IUniswapV2Router02 } from "../../peripheral/Uniswap/IUniswapV2Router02.sol";
import { IBasicToken } from "../../shared/IBasicToken.sol";
import { ImmutableModule } from "../../shared/ImmutableModule.sol";

// FLOWS
// 0 - mAsset -> Savings Vault
// 1 - bAsset -> Save/Savings Vault via Mint
// 2 - fAsset -> Save/Savings Vault via Feeder Pool
// 3 - ETH    -> Save/Savings Vault via Uniswap
contract SaveWrapper is ImmutableModule {
    using SafeERC20 for IERC20;

    constructor(address _nexus) ImmutableModule(_nexus) {}

    /**
     * @dev 0. Simply saves an mAsset and then into the vault
     * @param _mAsset   mAsset address
     * @param _save     Save address
     * @param _vault    Boosted Savings Vault address
     * @param _amount   Units of mAsset to deposit to savings
     */
    function saveAndStake(
        address _mAsset,
        address _save,
        address _vault,
        uint256 _amount
    ) external {
        _saveAndStake(_mAsset, _save, _vault, _amount, true, address(0));
    }

    /**
     * @dev 0. Simply saves an mAsset and then into the vault
     * @param _mAsset   mAsset address
     * @param _save     Save address
     * @param _vault    Boosted Savings Vault address
     * @param _amount   Units of mAsset to deposit to savings
     * @param _referrer Referrer address for this deposit.
     */
    function saveAndStake(
        address _mAsset,
        address _save,
        address _vault,
        uint256 _amount,
        address _referrer
    ) external {
        _saveAndStake(_mAsset, _save, _vault, _amount, true, _referrer);
    }

    /**
     * @dev 1. Mints an mAsset and then deposits to Save/Savings Vault
     * @param _mAsset       mAsset address
     * @param _bAsset       bAsset address
     * @param _save         Save address
     * @param _vault        Boosted Savings Vault address
     * @param _amount       Amount of bAsset to mint with
     * @param _minOut       Min amount of mAsset to get back
     * @param _stake        Add the imAsset to the Boosted Savings Vault?
     */
    function saveViaMint(
        address _mAsset,
        address _save,
        address _vault,
        address _bAsset,
        uint256 _amount,
        uint256 _minOut,
        bool _stake
    ) external {
        _saveViaMint(_mAsset, _save, _vault, _bAsset, _amount, _minOut, _stake, address(0));
    }

    /**
     * @dev 1. Mints an mAsset and then deposits to Save/Savings Vault
     * @param _mAsset       mAsset address
     * @param _bAsset       bAsset address
     * @param _save         Save address
     * @param _vault        Boosted Savings Vault address
     * @param _amount       Amount of bAsset to mint with
     * @param _minOut       Min amount of mAsset to get back
     * @param _stake        Add the imAsset to the Boosted Savings Vault?
     * @param _referrer     Referrer address for this deposit.
     */
    function saveViaMint(
        address _mAsset,
        address _save,
        address _vault,
        address _bAsset,
        uint256 _amount,
        uint256 _minOut,
        bool _stake,
        address _referrer
    ) external {
        _saveViaMint(_mAsset, _save, _vault, _bAsset, _amount, _minOut, _stake, _referrer);
    }

    /**
     * @dev 2. Swaps fAsset for mAsset and then deposits to Save/Savings Vault
     * @param _mAsset             mAsset address
     * @param _save               Save address
     * @param _vault              Boosted Savings Vault address
     * @param _feeder             Feeder Pool address
     * @param _fAsset             fAsset address
     * @param _fAssetQuantity     Quantity of fAsset sent
     * @param _minOutputQuantity  Min amount of mAsset to be swapped and deposited
     * @param _stake              Deposit the imAsset in the Savings Vault?
     */
    function saveViaSwap(
        address _mAsset,
        address _save,
        address _vault,
        address _feeder,
        address _fAsset,
        uint256 _fAssetQuantity,
        uint256 _minOutputQuantity,
        bool _stake
    ) external {
        _saveViaSwap(
            _mAsset,
            _save,
            _vault,
            _feeder,
            _fAsset,
            _fAssetQuantity,
            _minOutputQuantity,
            _stake,
            address(0)
        );
    }

    /**
     * @dev 2. Swaps fAsset for mAsset and then deposits to Save/Savings Vault
     * @param _mAsset             mAsset address
     * @param _save               Save address
     * @param _vault              Boosted Savings Vault address
     * @param _feeder             Feeder Pool address
     * @param _fAsset             fAsset address
     * @param _fAssetQuantity     Quantity of fAsset sent
     * @param _minOutputQuantity  Min amount of mAsset to be swapped and deposited
     * @param _stake              Deposit the imAsset in the Savings Vault?
     * @param _referrer       Referrer address for this deposit.
     */
    function saveViaSwap(
        address _mAsset,
        address _save,
        address _vault,
        address _feeder,
        address _fAsset,
        uint256 _fAssetQuantity,
        uint256 _minOutputQuantity,
        bool _stake,
        address _referrer
    ) external {
        _saveViaSwap(
            _mAsset,
            _save,
            _vault,
            _feeder,
            _fAsset,
            _fAssetQuantity,
            _minOutputQuantity,
            _stake,
            _referrer
        );
    }

    /**
     * @dev 3. Buys a bAsset on Uniswap with ETH, then mints imAsset via mAsset,
     *         optionally staking in the Boosted Savings Vault
     * @param _mAsset         mAsset address
     * @param _save           Save address
     * @param _vault          Boosted vault address
     * @param _uniswap        Uniswap router address
     * @param _amountOutMin   Min uniswap output in bAsset units
     * @param _path           Sell path on Uniswap (e.g. [WETH, DAI])
     * @param _minOutMStable  Min amount of mAsset to receive
     * @param _stake          Add the imAsset to the Savings Vault?
     */
    function saveViaUniswapETH(
        address _mAsset,
        address _save,
        address _vault,
        address _uniswap,
        uint256 _amountOutMin,
        address[] calldata _path,
        uint256 _minOutMStable,
        bool _stake
    ) external payable {
        _saveViaUniswapETH(
            _mAsset,
            _save,
            _vault,
            _uniswap,
            _amountOutMin,
            _path,
            _minOutMStable,
            _stake,
            address(0)
        );
    }

    /**
     * @dev 3. Buys a bAsset on Uniswap with ETH, then mints imAsset via mAsset,
     *         optionally staking in the Boosted Savings Vault
     * @param _mAsset         mAsset address
     * @param _save           Save address
     * @param _vault          Boosted vault address
     * @param _uniswap        Uniswap router address
     * @param _amountOutMin   Min uniswap output in bAsset units
     * @param _path           Sell path on Uniswap (e.g. [WETH, DAI])
     * @param _minOutMStable  Min amount of mAsset to receive
     * @param _stake          Add the imAsset to the Savings Vault?
     * @param _referrer       Referrer address for this deposit.
     */
    function saveViaUniswapETH(
        address _mAsset,
        address _save,
        address _vault,
        address _uniswap,
        uint256 _amountOutMin,
        address[] calldata _path,
        uint256 _minOutMStable,
        bool _stake,
        address _referrer
    ) external payable {
        _saveViaUniswapETH(
            _mAsset,
            _save,
            _vault,
            _uniswap,
            _amountOutMin,
            _path,
            _minOutMStable,
            _stake,
            _referrer
        );
    }

    /**
     * @dev Gets estimated mAsset output from a WETH > bAsset > mAsset trade
     * @param _mAsset       mAsset address
     * @param _uniswap      Uniswap router address
     * @param _ethAmount    ETH amount to sell
     * @param _path         Sell path on Uniswap (e.g. [WETH, DAI])
     */
    function estimate_saveViaUniswapETH(
        address _mAsset,
        address _uniswap,
        uint256 _ethAmount,
        address[] calldata _path
    ) external view returns (uint256 out) {
        require(_mAsset != address(0), "Invalid mAsset");
        require(_uniswap != address(0), "Invalid uniswap");

        uint256 estimatedBasset = _getAmountOut(_uniswap, _ethAmount, _path);
        return IMasset(_mAsset).getMintOutput(_path[_path.length - 1], estimatedBasset);
    }

    /**
     * @dev 0. Simply saves an mAsset and then into the vault
     * @param _mAsset   mAsset address
     * @param _save     Save address
     * @param _vault    Boosted Savings Vault address
     * @param _amount   Units of mAsset to deposit to savings
     * @param _referrer Referrer address for this deposit.
     */
    function _saveAndStake(
        address _mAsset,
        address _save,
        address _vault,
        uint256 _amount,
        bool _stake,
        address _referrer
    ) internal {
        require(_mAsset != address(0), "Invalid mAsset");
        require(_save != address(0), "Invalid save");
        require(_vault != address(0), "Invalid vault");

        // 1. Get the input mAsset
        IERC20(_mAsset).safeTransferFrom(msg.sender, address(this), _amount);

        // 2. Mint imAsset and stake in vault
        _depositAndStake(_save, _vault, _amount, _stake, _referrer);
    }

    /** @dev Internal func to deposit into Save and optionally stake in the vault
     * @param _save       Save address
     * @param _vault      Boosted vault address
     * @param _amount     Amount of mAsset to deposit
     * @param _stake      Add the imAsset to the Savings Vault?
     * @param _referrer   Referrer address for this deposit, if any.
     */
    function _depositAndStake(
        address _save,
        address _vault,
        uint256 _amount,
        bool _stake,
        address _referrer
    ) internal {
        if (_stake && _referrer != address(0)) {
            uint256 credits = ISavingsContractV3(_save).depositSavings(
                _amount,
                address(this),
                _referrer
            );
            IBoostedVaultWithLockup(_vault).stake(msg.sender, credits);
        } else if (_stake && _referrer == address(0)) {
            uint256 credits = ISavingsContractV3(_save).depositSavings(_amount, address(this));
            IBoostedVaultWithLockup(_vault).stake(msg.sender, credits);
        } else if (!_stake && _referrer != address(0)) {
            ISavingsContractV3(_save).depositSavings(_amount, msg.sender, _referrer);
        } else {
            ISavingsContractV3(_save).depositSavings(_amount, msg.sender);
        }
    }

    /**
     * @dev 1. Mints an mAsset and then deposits to Save/Savings Vault
     * @param _mAsset       mAsset address
     * @param _bAsset       bAsset address
     * @param _save         Save address
     * @param _vault        Boosted Savings Vault address
     * @param _amount       Amount of bAsset to mint with
     * @param _minOut       Min amount of mAsset to get back
     * @param _stake        Add the imAsset to the Boosted Savings Vault?
     * @param _referrer     Referrer address for this deposit.
     */
    function _saveViaMint(
        address _mAsset,
        address _save,
        address _vault,
        address _bAsset,
        uint256 _amount,
        uint256 _minOut,
        bool _stake,
        address _referrer
    ) internal {
        require(_mAsset != address(0), "Invalid mAsset");
        require(_save != address(0), "Invalid save");
        require(_vault != address(0), "Invalid vault");
        require(_bAsset != address(0), "Invalid bAsset");

        // 1. Get the input bAsset
        IERC20(_bAsset).safeTransferFrom(msg.sender, address(this), _amount);

        // 2. Mint
        uint256 massetsMinted = IMasset(_mAsset).mint(_bAsset, _amount, _minOut, address(this));

        // 3. Mint imAsset and optionally stake in vault
        _depositAndStake(_save, _vault, massetsMinted, _stake, _referrer);
    }

    /**
     * @dev 2. Swaps fAsset for mAsset and then deposits to Save/Savings Vault
     * @param _mAsset             mAsset address
     * @param _save               Save address
     * @param _vault              Boosted Savings Vault address
     * @param _feeder             Feeder Pool address
     * @param _fAsset             fAsset address
     * @param _fAssetQuantity     Quantity of fAsset sent
     * @param _minOutputQuantity  Min amount of mAsset to be swapped and deposited
     * @param _stake              Deposit the imAsset in the Savings Vault?
     * @param _referrer           Referrer address for this deposit.
     */
    function _saveViaSwap(
        address _mAsset,
        address _save,
        address _vault,
        address _feeder,
        address _fAsset,
        uint256 _fAssetQuantity,
        uint256 _minOutputQuantity,
        bool _stake,
        address _referrer
    ) internal {
        require(_feeder != address(0), "Invalid feeder");
        require(_mAsset != address(0), "Invalid mAsset");
        require(_save != address(0), "Invalid save");
        require(_vault != address(0), "Invalid vault");
        require(_fAsset != address(0), "Invalid input");

        // 0. Transfer the fAsset here
        IERC20(_fAsset).safeTransferFrom(msg.sender, address(this), _fAssetQuantity);

        // 1. Swap the fAsset for mAsset with the feeder pool
        uint256 mAssetQuantity = IFeederPool(_feeder).swap(
            _fAsset,
            _mAsset,
            _fAssetQuantity,
            _minOutputQuantity,
            address(this)
        );

        // 2. Deposit the mAsset into Save and optionally stake in the vault
        _depositAndStake(_save, _vault, mAssetQuantity, _stake, _referrer);
    }

    /**
     * @dev 3. Buys a bAsset on Uniswap with ETH, then mints imAsset via mAsset,
     *         optionally staking in the Boosted Savings Vault
     * @param _mAsset         mAsset address
     * @param _save           Save address
     * @param _vault          Boosted vault address
     * @param _uniswap        Uniswap router address
     * @param _amountOutMin   Min uniswap output in bAsset units
     * @param _path           Sell path on Uniswap (e.g. [WETH, DAI])
     * @param _minOutMStable  Min amount of mAsset to receive
     * @param _stake          Add the imAsset to the Savings Vault?
     * @param _referrer       Referrer address for this deposit.
     */
    function _saveViaUniswapETH(
        address _mAsset,
        address _save,
        address _vault,
        address _uniswap,
        uint256 _amountOutMin,
        address[] calldata _path,
        uint256 _minOutMStable,
        bool _stake,
        address _referrer
    ) internal {
        require(_mAsset != address(0), "Invalid mAsset");
        require(_save != address(0), "Invalid save");
        require(_vault != address(0), "Invalid vault");
        require(_uniswap != address(0), "Invalid uniswap");

        // 1. Get the bAsset
        uint256[] memory amounts = IUniswapV2Router02(_uniswap).swapExactETHForTokens{
            value: msg.value
        }(_amountOutMin, _path, address(this), block.timestamp + 1000);

        // 2. Purchase mAsset
        uint256 massetsMinted = IMasset(_mAsset).mint(
            _path[_path.length - 1],
            amounts[amounts.length - 1],
            _minOutMStable,
            address(this)
        );

        // 3. Mint imAsset and optionally stake in vault
        _depositAndStake(_save, _vault, massetsMinted, _stake, _referrer);
    }

    /** @dev Internal func to get estimated Uniswap output from WETH to token trade */
    function _getAmountOut(
        address _uniswap,
        uint256 _amountIn,
        address[] memory _path
    ) internal view returns (uint256) {
        uint256[] memory amountsOut = IUniswapV2Router02(_uniswap).getAmountsOut(_amountIn, _path);
        return amountsOut[amountsOut.length - 1];
    }

    /**
     * @dev Approve mAsset and bAssets, Feeder Pools and fAssets, and Save/vault
     */
    function approve(
        address _mAsset,
        address[] calldata _bAssets,
        address[] calldata _fPools,
        address[] calldata _fAssets,
        address _save,
        address _vault
    ) external onlyKeeperOrGovernor {
        _approve(_mAsset, _save);
        _approve(_save, _vault);
        _approve(_bAssets, _mAsset);

        require(_fPools.length == _fAssets.length, "Mismatching fPools/fAssets");
        for (uint256 i = 0; i < _fPools.length; i++) {
            _approve(_fAssets[i], _fPools[i]);
        }
    }

    /**
     * @dev Approve one token/spender
     */
    function approve(address _token, address _spender) external onlyKeeperOrGovernor {
        _approve(_token, _spender);
    }

    /**
     * @dev Approve multiple tokens/one spender
     */
    function approve(address[] calldata _tokens, address _spender) external onlyKeeperOrGovernor {
        _approve(_tokens, _spender);
    }

    function _approve(address _token, address _spender) internal {
        require(_spender != address(0), "Invalid spender");
        require(_token != address(0), "Invalid token");
        IERC20(_token).safeApprove(_spender, 2**256 - 1);
    }

    function _approve(address[] calldata _tokens, address _spender) internal {
        require(_spender != address(0), "Invalid spender");
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "Invalid token");
            IERC20(_tokens[i]).safeApprove(_spender, 2**256 - 1);
        }
    }
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostedVaultWithLockup {
    /**
     * @notice Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stake(address _beneficiary, uint256 _amount) external;

    /**
     * @notice Withdraws stake from pool and claims any unlocked rewards.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function exit() external;

    /**
     * @notice Withdraws stake from pool and claims any unlocked rewards.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function exit(uint256 _first, uint256 _last) external;

    /**
     * @notice Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Redeems staked interest-bearing asset tokens for either bAsset or fAsset tokens.
     * Withdraws a given staked amount of interest-bearing assets from the vault,
     * redeems the interest-bearing asset for the underlying mAsset and either
     * 1. Redeems the underlying mAsset tokens for bAsset tokens.
     * 2. Swaps the underlying mAsset tokens for fAsset tokens in a Feeder Pool.
     * @param _amount         Units of the staked interest-bearing asset tokens to withdraw. eg imUSD or imBTC.
     * @param _minAmountOut   Minimum units of `output` tokens to be received by the beneficiary. This is to the same decimal places as the `output` token.
     * @param _output         Asset to receive in exchange for the redeemed mAssets. This can be a bAsset or a fAsset. For example:
        - bAssets (USDC, DAI, sUSD or USDT) or fAssets (GUSD, BUSD, alUSD, FEI or RAI) for mainnet imUSD Vault.
        - bAssets (USDC, DAI or USDT) or fAsset FRAX for Polygon imUSD Vault.
        - bAssets (WBTC, sBTC or renBTC) or fAssets (HBTC or TBTCV2) for mainnet imBTC Vault.
     * @param _beneficiary    Address to send `output` tokens to.
     * @param _router         mAsset address if the `output` is a bAsset. Feeder Pool address if the `output` is a fAsset.
     * @param _isBassetOut    `true` if `output` is a bAsset. `false` if `output` is a fAsset.
     * @return outputQuantity Units of `output` tokens sent to the beneficiary. This is to the same decimal places as the `output` token.
     */
    function withdrawAndUnwrap(
        uint256 _amount,
        uint256 _minAmountOut,
        address _output,
        address _beneficiary,
        address _router,
        bool _isBassetOut
    ) external returns (uint256 outputQuantity);

    /**
     * @notice Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external;

    /**
     * @notice Claims all unlocked rewards for sender.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function claimRewards() external;

    /**
     * @notice Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last) external;

    /**
     * @notice Pokes a given account to reset the boost
     */
    function pokeBoost(address _account) external;

    /**
     * @notice Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice Calculates the amount of unclaimed rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) external view returns (uint256);

    /**
     * @notice Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 first,
            uint256 last
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;
pragma abicoder v2;

import "../masset/MassetStructs.sol";

abstract contract IFeederPool {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemProportionately(
        uint256 _fpTokenQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _fpTokenQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function mAsset() external view virtual returns (address);

    function getPrice() public view virtual returns (uint256 price, uint256 k);

    function getConfig() external view virtual returns (FeederConfig memory config);

    function getBasset(address _token)
        external
        view
        virtual
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        virtual
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    // SavingsManager
    function collectPlatformInterest()
        external
        virtual
        returns (uint256 mintAmount, uint256 newSupply);

    function collectPendingFees() external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;
pragma abicoder v2;

import { BassetData, BassetPersonal } from "../masset/MassetStructs.sol";

abstract contract IMasset {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemMasset(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function getBasket() external view virtual returns (bool, bool);

    function getBasset(address _token)
        external
        view
        virtual
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        virtual
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    function bAssetIndexes(address) external view virtual returns (uint8);

    function getPrice() external view virtual returns (uint256 price, uint256 k);

    // SavingsManager
    function collectInterest() external virtual returns (uint256 swapFeesGained, uint256 newSupply);

    function collectPlatformInterest()
        external
        virtual
        returns (uint256 mintAmount, uint256 newSupply);

    // Admin
    function setCacheSize(uint256 _cacheSize) external virtual;

    function setFees(uint256 _swapFee, uint256 _redemptionFee) external virtual;

    function setTransferFeesFlag(address _bAsset, bool _flag) external virtual;

    function migrateBassets(address[] calldata _bAssets, address _newIntegration) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISavingsContractV1 {
    function depositInterest(uint256 _amount) external;

    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued);

    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    function exchangeRate() external view returns (uint256);

    function creditBalances(address) external view returns (uint256);
}

interface ISavingsContractV2 {
    // DEPRECATED but still backwards compatible
    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    function creditBalances(address) external view returns (uint256); // V1 & V2 (use balanceOf)

    // --------------------------------------------

    function depositInterest(uint256 _amount) external; // V1 & V2

    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued); // V1 & V2

    function depositSavings(uint256 _amount, address _beneficiary)
        external
        returns (uint256 creditsIssued); // V2

    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2

    function redeemUnderlying(uint256 _amount) external returns (uint256 creditsBurned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2

    function balanceOfUnderlying(address _user) external view returns (uint256 underlying); // V2

    function underlyingToCredits(uint256 _underlying) external view returns (uint256 credits); // V2

    function creditsToUnderlying(uint256 _credits) external view returns (uint256 underlying); // V2

    function underlying() external view returns (IERC20 underlyingMasset); // V2
}

interface ISavingsContractV3 {
    // DEPRECATED but still backwards compatible
    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    function creditBalances(address) external view returns (uint256); // V1 & V2 (use balanceOf)

    // --------------------------------------------

    function depositInterest(uint256 _amount) external; // V1 & V2

    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued); // V1 & V2

    function depositSavings(uint256 _amount, address _beneficiary)
        external
        returns (uint256 creditsIssued); // V2

    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2

    function redeemUnderlying(uint256 _amount) external returns (uint256 creditsBurned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2

    function balanceOfUnderlying(address _user) external view returns (uint256 underlying); // V2

    function underlyingToCredits(uint256 _underlying) external view returns (uint256 credits); // V2

    function creditsToUnderlying(uint256 _credits) external view returns (uint256 underlying); // V2

    function underlying() external view returns (IERC20 underlyingMasset); // V2

    // --------------------------------------------

    function redeemAndUnwrap(
        uint256 _amount,
        bool _isCreditAmt,
        uint256 _minAmountOut,
        address _output,
        address _beneficiary,
        address _router,
        bool _isBassetOut
    )
        external
        returns (
            uint256 creditsBurned,
            uint256 massetRedeemed,
            uint256 outputQuantity
        );

    function depositSavings(
        uint256 _underlying,
        address _beneficiary,
        address _referrer
    ) external returns (uint256 creditsIssued);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin, // calculated off chain
        address[] calldata path, // also worked out off chain
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

interface IBasicToken {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ModuleKeys } from "./ModuleKeys.sol";
import { INexus } from "../interfaces/INexus.sol";

/**
 * @title   ImmutableModule
 * @author  mStable
 * @dev     Subscribes to module updates from a given publisher and reads from its registry.
 *          Contract is used for upgradable proxy contracts.
 */
abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governor or the Keeper EOA.
     */
    modifier onlyKeeperOrGovernor() {
        _keeperOrGovernor();
        _;
    }

    function _keeperOrGovernor() internal view {
        require(msg.sender == _keeper() || msg.sender == _governor(), "Only keeper or governor");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Keeper address from the Nexus.
     *      This account is used for operational transactions that
     *      don't need multiple signatures.
     * @return  Address of the Keeper externally owned account.
     */
    function _keeper() internal view returns (address) {
        return nexus.getModule(KEY_KEEPER);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }

    /**
     * @dev Return Liquidator Module address from the Nexus
     * @return  Address of the Liquidator Module contract
     */
    function _liquidator() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

struct BassetPersonal {
    // Address of the bAsset
    address addr;
    // Address of the bAsset
    address integrator;
    // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
    bool hasTxFee; // takes a byte in storage
    // Status of the bAsset
    BassetStatus status;
}

struct BassetData {
    // 1 Basset * ratio / ratioScale == x Masset (relative value)
    // If ratio == 10e8 then 1 bAsset = 10 mAssets
    // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
    uint128 ratio;
    // Amount of the Basset that is held in Collateral
    uint128 vaultBalance;
}

// Status of the Basset - has it broken its peg?
enum BassetStatus {
    Default,
    Normal,
    BrokenBelowPeg,
    BrokenAbovePeg,
    Blacklisted,
    Liquidating,
    Liquidated,
    Failed
}

struct BasketState {
    bool undergoingRecol;
    bool failed;
}

struct FeederConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
}

struct InvariantConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
    uint256 recolFee;
}

struct BasicConfig {
    uint256 a;
    WeightLimits limits;
}

struct WeightLimits {
    uint128 min;
    uint128 max;
}

struct AmpData {
    uint64 initialA;
    uint64 targetA;
    uint64 rampStartTime;
    uint64 rampEndTime;
}

struct FeederData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 govFee;
    uint256 pendingFees;
    uint256 cacheSize;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct MassetData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 cacheSize;
    uint256 surplus;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    BasketState basket;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct AssetData {
    uint8 idx;
    uint256 amt;
    BassetPersonal personal;
}

struct Asset {
    uint8 idx;
    address addr;
    bool exists;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title  ModuleKeys
 * @author mStable
 * @notice Provides system wide access to the byte32 represntations of system modules
 *         This allows each system module to be able to reference and update one another in a
 *         friendly way
 * @dev    keccak256() values are hardcoded to avoid re-evaluation of the constants at runtime.
 */
contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
    // keccak256("Keeper");
    bytes32 internal constant KEY_KEEPER =
        0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title INexus
 * @dev Basic interface for interacting with the Nexus i.e. SystemKernel
 */
interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}