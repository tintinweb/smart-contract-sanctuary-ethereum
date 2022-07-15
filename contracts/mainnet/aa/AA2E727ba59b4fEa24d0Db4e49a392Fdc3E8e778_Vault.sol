// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ICorePool } from "./interfaces/ICorePool.sol";
import { ICorePoolV1 } from "./interfaces/ICorePoolV1.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { IUniswapV2Router02 } from "./interfaces/IUniswapV2Router02.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Illuvium Vault.
 *
 * @dev The Vault is responsible to gather revenue from the protocol, swap to ILV
 *      periodically and distribute to core pool users from time to time.
 * @dev The contract connects with Sushi's router in order to buy ILV from the
 *      ILV/ETH liquidity pool.
 * @dev Since we can change the vault address in the staking pools (see VaultRecipient),
 *      the Vault contract doesn't need to implement upgradeability.
 * @dev It receives ETH from the receive() function and allows conversion to ILV by
 *      the address with the role ROLE_VAULT_MANAGER (0x0001_0000). This conversion
 *      can be done in multiple steps, which means it doesn’t require converting
 *      all ETH balance in 1 function call. The vault is also responsible to be
 *      calling receiveVaultRewards() function in the core pools, which takes care
 *      of calculations of how much ILV should be sent to each pool as revenue distribution.
 * @notice The contract uses Ownable implementation, so only the eDAO is able to handle
 *         the ETH => ILV swaps and distribution schedules.
 *
 */
contract Vault is Ownable {
    using ErrorHandler for bytes4;

    /**
     * @dev Auxiliary data structure to store ILV, LP and Locked pools,
     *      linked to this smart contract and receiving vault rewards
     */
    struct Pools {
        ICorePool ilvPool;
        ICorePool pairPool;
        ICorePool lockedPoolV1;
    }

    /**
     * @dev struct with each core pool address
     */
    Pools public pools;

    /**
     * @dev Link to Sushiswap's router deployed instance
     */
    IUniswapV2Router02 private _sushiRouter;

    /**
     * @dev Link to IlluviumERC20 token deployed instance
     */
    IERC20Upgradeable private _ilv;

    /**
     * @dev Internal multiplier used to calculate amount to send
     *      to each staking pool
     */
    uint256 internal constant AMOUNT_TO_SEND_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _swapEthForIlv() and sendIlvRewards() (via swapEthForIlv)
     *
     * @param by an address which executed the function
     * @param ethSpent ETH amount sent to Sushiswap
     * @param ilvReceived ILV amount received from Sushiswap
     */
    event LogSwapEthForILV(address indexed by, uint256 ethSpent, uint256 ilvReceived);

    /**
     * @dev Fired in sendIlvRewards()
     *
     * @param by an address which executed the function
     * @param value ILV amount sent to the pool
     */
    event LogSendILVRewards(address indexed by, uint256 value);

    /**
     * @dev Fired in default payable receive()
     *
     * @param by an address which sent ETH into the vault (this contract)
     * @param value ETH amount received
     */
    event LogEthReceived(address indexed by, uint256 value);

    /**
     * @dev Fired in setCorePools()
     *
     * @param by address who executed the setup
     * @param ilvPool deployed ILV core pool address
     * @param pairPool deployed ILV/ETH pair (LP) pool address
     * @param lockedPoolV1 deployed locked pool V1 address
     */
    event LogSetCorePools(address indexed by, address ilvPool, address pairPool, address lockedPoolV1);

    /**
     * @notice Creates (deploys) Vault linked to Sushi AMM Router and IlluviumERC20 token
     *
     * @param sushiRouter_ an address of the IUniswapV2Router02 to use for ETH -> ILV exchange
     * @param ilv_ an address of the IlluviumERC20 token to use
     */
    constructor(address sushiRouter_, address ilv_) {
        // we're using  a fake selector in the constructor to simplify
        // input and state validation
        bytes4 fnSelector = bytes4(0);

        // verify the inputs are set
        fnSelector.verifyNonZeroInput(uint160(sushiRouter_), 0);
        fnSelector.verifyNonZeroInput(uint160(ilv_), 1);

        // assign the values
        _sushiRouter = IUniswapV2Router02(sushiRouter_);
        _ilv = IERC20Upgradeable(ilv_);
    }

    /**
     * @dev Auxiliary function used as part of the contract setup process to setup core pools,
     *      executed by `owner()` after deployment
     *
     * @param _ilvPool deployed ILV core pool address
     * @param _pairPool deployed ILV/ETH pair (LP) pool address
     * @param _lockedPoolV1 deployed locked pool V1 address
     */
    function setCorePools(
        ICorePool _ilvPool,
        ICorePool _pairPool,
        ICorePool _lockedPoolV1
    ) external onlyOwner {
        bytes4 fnSelector = this.setCorePools.selector;

        // verify all the pools are set/supplied
        fnSelector.verifyNonZeroInput(uint160(address(_ilvPool)), 2);
        fnSelector.verifyNonZeroInput(uint160(address(_pairPool)), 3);
        fnSelector.verifyNonZeroInput(uint160(address(_lockedPoolV1)), 4);

        // set up
        pools.ilvPool = _ilvPool;
        pools.pairPool = _pairPool;
        pools.lockedPoolV1 = _lockedPoolV1;

        // emit an event
        emit LogSetCorePools(msg.sender, address(_ilvPool), address(_pairPool), address(_lockedPoolV1));
    }

    /**
     * @notice Exchanges ETH balance present on the contract into ILV via Sushiswap
     *
     * @dev Logs operation via `EthIlvSwapped` event
     *
     * @param _ilvOut expected ILV amount to be received from Sushiswap swap
     * @param _deadline maximum timestamp to wait for Sushiswap swap (inclusive)
     */
    function swapETHForILV(
        uint256 _ethIn,
        uint256 _ilvOut,
        uint256 _deadline
    ) external onlyOwner {
        _swapETHForILV(_ethIn, _ilvOut, _deadline);
    }

    /**
     * @notice Converts an entire contract's ETH balance into ILV via Sushiswap and
     *      sends the entire contract's ILV balance to the Illuvium Yield Pool
     *
     * @dev Uses `swapEthForIlv` internally to exchange ETH -> ILV
     *
     * @dev Logs operation via `RewardsDistributed` event
     *
     * @dev Set `ilvOut` or `deadline` to zero to skip `swapEthForIlv` call
     *
     * @param _ilvOut expected ILV amount to be received from Sushiswap swap
     * @param _deadline maximum timeout to wait for Sushiswap swap
     */
    function sendILVRewards(
        uint256 _ethIn,
        uint256 _ilvOut,
        uint256 _deadline
    ) external onlyOwner {
        // we treat set `ilvOut` and `deadline` as a flag to execute `swapEthForIlv`
        // in the same time we won't execute the swap if contract balance is zero
        if (_ilvOut > 0 && _deadline > 0 && address(this).balance > 0) {
            // exchange ETH on the contract's balance into ILV via Sushi - delegate to `swapEthForIlv`
            _swapETHForILV(_ethIn, _ilvOut, _deadline);
        }

        // reads core pools
        (ICorePool ilvPool, ICorePool pairPool, ICorePool lockedPoolV1) = (
            pools.ilvPool,
            pools.pairPool,
            pools.lockedPoolV1
        );

        // read contract's ILV balance
        uint256 ilvBalance = _ilv.balanceOf(address(this));
        // approve the entire ILV balance to be sent into the pool
        if (_ilv.allowance(address(this), address(ilvPool)) < ilvBalance) {
            _ilv.approve(address(ilvPool), ilvBalance);
        }
        if (_ilv.allowance(address(this), address(pairPool)) < ilvBalance) {
            _ilv.approve(address(pairPool), ilvBalance);
        }
        if (_ilv.allowance(address(this), address(lockedPoolV1)) < ilvBalance) {
            _ilv.approve(address(lockedPoolV1), ilvBalance);
        }

        // gets poolToken reserves in each pool
        uint256 reserve0 = ilvPool.getTotalReserves();
        uint256 reserve1 = estimatePairPoolReserve(address(pairPool));
        uint256 reserve2 = lockedPoolV1.poolTokenReserve();

        // ILV in ILV core pool + ILV in ILV/ETH core pool representation + ILV in locked pool
        uint256 totalReserve = reserve0 + reserve1 + reserve2;

        // amount of ILV to send to ILV core pool
        uint256 amountToSend0 = _getAmountToSend(ilvBalance, reserve0, totalReserve);
        // amount of ILV to send to ILV/ETH core pool
        uint256 amountToSend1 = _getAmountToSend(ilvBalance, reserve1, totalReserve);
        // amount of ILV to send to locked ILV pool V1
        uint256 amountToSend2 = _getAmountToSend(ilvBalance, reserve2, totalReserve);

        // makes sure we are sending a valid amount
        assert(amountToSend0 + amountToSend1 + amountToSend2 <= ilvBalance);

        // sends ILV to both core pools
        ilvPool.receiveVaultRewards(amountToSend0);
        pairPool.receiveVaultRewards(amountToSend1);
        lockedPoolV1.receiveVaultRewards(amountToSend2);

        // emit an event
        emit LogSendILVRewards(msg.sender, ilvBalance);
    }

    /**
     * @dev Auxiliary function used to estimate LP core pool share among the other core pools.
     *
     * @dev Expected to estimate how much ILV is represented by the number of LP tokens staked
     *      in the pair pool in order to determine how much revenue distribution should be allocated
     *      to the Sushi LP pool.
     *
     * @param _pairPool LP core pool extracted from pools structure (gas saving optimization)
     * @return ilvAmount ILV estimate of the LP pool share among the other pools
     */
    function estimatePairPoolReserve(address _pairPool) public view returns (uint256 ilvAmount) {
        // 1. Store the amount of LP tokens staked in the ILV/ETH pool
        //    and the LP token total supply (total amount of LP tokens in circulation).
        //    With these two values we will be able to estimate how much ILV each LP token
        //    is worth.
        uint256 lpAmount = ICorePool(_pairPool).getTotalReserves();
        uint256 lpTotal = IERC20Upgradeable(ICorePool(_pairPool).poolToken()).totalSupply();

        // 2. We check how much ILV the LP token contract holds, that way
        //    based on the total value of ILV tokens represented by the total
        //    supply of LP tokens, we are able to calculate through a simple rule
        //    of 3 how much ILV the amount of staked LP tokens represent.
        uint256 ilvTotal = _ilv.balanceOf(ICorePool(_pairPool).poolToken());
        // we store the result
        ilvAmount = (ilvTotal * lpAmount) / lpTotal;
    }

    /**
     * @dev Auxiliary function to calculate amount of rewards to send to the pool
     *      based on ILV rewards available to be split between the pools,
     *      particular pool reserve and total reserve of all the pools
     *
     * @dev A particular pool receives an amount proportional to its reserves
     *
     * @param _ilvBalance available amount of rewards to split between the pools
     * @param _poolReserve particular pool reserves
     * @param _totalReserve total cumulative reserves of all the pools to split rewards between
     */
    function _getAmountToSend(
        uint256 _ilvBalance,
        uint256 _poolReserve,
        uint256 _totalReserve
    ) private pure returns (uint256) {
        return (_ilvBalance * ((_poolReserve * AMOUNT_TO_SEND_MULTIPLIER) / _totalReserve)) / AMOUNT_TO_SEND_MULTIPLIER;
    }

    function _swapETHForILV(
        uint256 _ethIn,
        uint256 _ilvOut,
        uint256 _deadline
    ) private {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_swapETHForILV(uint256,uint256,uint256)"))`
        bytes4 fnSelector = 0x45b603e4;

        // verify the inputs
        fnSelector.verifyNonZeroInput(_ethIn, 0);
        fnSelector.verifyNonZeroInput(_ilvOut, 1);
        fnSelector.verifyInput(_deadline >= block.timestamp, 2);

        // checks if there's enough balance
        fnSelector.verifyState(address(this).balance > _ethIn, 3);

        // create and initialize path array to be used in Sushiswap
        // first element of the path determines an input token (what we send to Sushiswap),
        // last element determines output token (what we receive from uniwsap)
        address[] memory path = new address[](2);
        // we send ETH wrapped as WETH into Sushiswap
        path[0] = _sushiRouter.WETH();
        // we receive ILV from Sushiswap
        path[1] = address(_ilv);

        // exchange ETH -> ILV via Sushiswap
        uint256[] memory amounts = _sushiRouter.swapExactETHForTokens{ value: _ethIn }(
            _ilvOut,
            path,
            address(this),
            _deadline
        );
        // asserts that ILV amount bought wasn't invalid
        assert(amounts[1] > 0);

        // emit an event logging the operation
        emit LogSwapEthForILV(msg.sender, amounts[0], amounts[1]);
    }

    /**
     * @dev Overrides `Ownable.renounceOwnership()`, to avoid accidentally
     *      renouncing ownership of the Vault contract.
     */
    function renounceOwnership() public virtual override {}

    /**
     * @notice Default payable function, allows to top up contract's ETH balance
     *      to be exchanged into ILV via Sushiswap
     *
     * @dev Logs operation via `LogEthReceived` event
     */
    receive() external payable {
        // emit an event
        emit LogEthReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Stake } from "../libraries/Stake.sol";

interface ICorePool {
    function users(address _user)
        external
        view
        returns (
            uint128,
            uint128,
            uint128,
            uint248,
            uint8,
            uint256,
            uint256
        );

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user) external view returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId) external view returns (Stake.Data memory);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICorePoolV1 {
    struct V1Stake {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
        // @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    struct V1User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
        // @dev An array of holder's deposits
        V1Stake[] deposits;
    }

    function users(address _who)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getDeposit(address _from, uint256 _stakeId)
        external
        view
        returns (
            uint256,
            uint256,
            uint64,
            uint64,
            bool
        );

    function poolToken() external view returns (address);

    function usersLockingWeight() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);
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
pragma solidity 0.8.4;

/**
 * @title Errors Library.
 *
 * @notice Introduces some very common input and state validation for smart contracts,
 *      such as non-zero input validation, general boolean expression validation, access validation.
 *
 * @notice Throws pre-defined errors instead of string error messages to reduce gas costs.
 *
 * @notice Since the library handles only very common errors, concrete smart contracts may
 *      also introduce their own error types and handling.
 *
 * @author Basil Gorin
 */
library ErrorHandler {
    /**
     * @notice Thrown on zero input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error ZeroInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error InvalidInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid state in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param errorCode unique error code determining the exact place in code where error was thrown
     */
    error InvalidState(bytes4 fnSelector, uint256 errorCode);

    /**
     * @notice Thrown on invalid access to a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param addr an address which access was denied, usually transaction sender
     */
    error AccessDenied(bytes4 fnSelector, address addr);

    /**
     * @notice Verifies an input is set (non-zero).
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param value a value to check if it's set (non-zero)
     * @param paramIndex function parameter index which is verified
     */
    function verifyNonZeroInput(
        bytes4 fnSelector,
        uint256 value,
        uint8 paramIndex
    ) internal pure {
        if (value == 0) {
            revert ZeroInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies an input is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the input
     * @param paramIndex function parameter index which is verified
     */
    function verifyInput(
        bytes4 fnSelector,
        bool expr,
        uint8 paramIndex
    ) internal pure {
        if (!expr) {
            revert InvalidInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies smart contract state is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the contract state
     * @param errorCode unique error code determining the exact place in code which is verified
     */
    function verifyState(
        bytes4 fnSelector,
        bool expr,
        uint256 errorCode
    ) internal pure {
        if (!expr) {
            revert InvalidState(fnSelector, errorCode);
        }
    }

    /**
     * @notice Verifies an access to the function.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the access
     */
    function verifyAccess(bytes4 fnSelector, bool expr) internal view {
        if (!expr) {
            revert AccessDenied(fnSelector, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IUniswapV2Router01 } from "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Stake library used by ILV pool and Sushi LP Pool.
 *
 * @dev Responsible to manage weight calculation and store important constants
 *      related to stake period, base weight and multipliers utilized.
 */
library Stake {
    struct Data {
        /// @dev token amount staked
        uint120 value;
        /// @dev locking period - from
        uint64 lockedFrom;
        /// @dev locking period - until
        uint64 lockedUntil;
        /// @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    /**
     * @dev Stake weight is proportional to stake value and time locked, precisely
     *      "stake value wei multiplied by (fraction of the year locked plus one)".
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer.
     * @dev Corner case 1: if time locked is zero, weight is stake value multiplied by 1e6 + base weight
     * @dev Corner case 2: if time locked is two years, division of
            (lockedUntil - lockedFrom) / MAX_STAKE_PERIOD is 1e6, and
     *      weight is a stake value multiplied by 2 * 1e6.
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev Minimum weight value, if result of multiplication using WEIGHT_MULTIPLIER
     *      is 0 (e.g stake flexible), then BASE_WEIGHT is used.
     */
    uint256 internal constant BASE_WEIGHT = 1e6;
    /**
     * @dev Minimum period that someone can lock a stake for.
     */
    uint256 internal constant MIN_STAKE_PERIOD = 30 days;

    /**
     * @dev Maximum period that someone can lock a stake for.
     */
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;

    /**
     * @dev Rewards per weight are stored multiplied by 1e20 as uint.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;

    /**
     * @dev When we know beforehand that staking is done for yield instead of
     *      executing `weight()` function we use the following constant.
     */
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * 1e6;

    function weight(Data storage _self) internal view returns (uint256) {
        return
            uint256(
                (((_self.lockedUntil - _self.lockedFrom) * WEIGHT_MULTIPLIER) / MAX_STAKE_PERIOD + BASE_WEIGHT) *
                    _self.value
            );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      ILV reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param _rewardPerWeight ILV reward per weight
     * @param _rewardPerWeightPaid last reward per weight value used for user earnings
     * @return reward value normalized to 10^12
     */
    function earned(
        uint256 _weight,
        uint256 _rewardPerWeight,
        uint256 _rewardPerWeightPaid
    ) internal pure returns (uint256) {
        // apply the formula and return
        return (_weight * (_rewardPerWeight - _rewardPerWeightPaid)) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward ILV value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward.
     *      - OR -
     * @dev Converts reward ILV value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight.
     *
     * @param _reward yield reward
     * @param _globalWeight total weight in the pool
     * @return reward per weight value
     */
    function getRewardPerWeight(uint256 _reward, uint256 _globalWeight) internal pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_WEIGHT_MULTIPLIER) / _globalWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

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
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

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