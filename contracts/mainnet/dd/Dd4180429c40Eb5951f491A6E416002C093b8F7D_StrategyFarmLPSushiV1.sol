// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./StrategyFarmLP.sol";


contract StrategyFarmLPSushiV1 is StrategyFarmLP {
    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient,

        address _safeFarmFeeRecipient,

        address _treasuryFeeRecipient,
        address _systemFeeRecipient
    ) StrategyFarmLP(
        _unirouter,
        _want,
        _output,
        _wbnb,

        _callFeeRecipient,
        _frfiFeeRecipient,
        _strategistFeeRecipient,

        _safeFarmFeeRecipient,

        _treasuryFeeRecipient,
        _systemFeeRecipient
    ) {
    }

    function pendingReward() public view override virtual returns (uint256 amount) {
        amount = IMasterChefSushi(masterchef).pendingSushi(poolId, address(this));
        return amount;
    }

    // skip swaps on non liquidity
    function _outputBalance() internal override returns (uint256) {
        uint256 allBal = super._outputBalance();
        uint256 outputHalf = (allBal * (MAX_FEE - poolFee) / MAX_FEE) / 2;

        if (outputHalf == 0) return 0;
        if (_checkLpOutput(lpToken0, outputToLp0Route, outputHalf) == 0) return 0;
        if (_checkLpOutput(lpToken1, outputToLp1Route, outputHalf) == 0) return 0;

        return allBal;
    }

    function _checkLpOutput(
        address lpToken,
        address[] memory route,
        uint256 amount
    ) private view returns (uint256) {
        if (lpToken == output) return amount;

        uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsOut(
            amount, route
        );

        return amounts[amounts.length - 1];
    }
}

interface IMasterChefSushi is IMasterChef {
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./IMasterChef.sol";
import "./StratManager.sol";


contract StrategyFarmLP is StratManager {
    using SafeERC20 for IERC20;

    bytes32 public constant STRATEGY_TYPE = keccak256("FARM_LP");

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public masterchef;
    uint256 public poolId;

    // Routes
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient,

        address _safeFarmFeeRecipient,

        address _treasuryFeeRecipient,
        address _systemFeeRecipient
    ) StratManager(
        _unirouter,
        _want,
        _output,
        _wbnb,

        _callFeeRecipient,
        _frfiFeeRecipient,
        _strategistFeeRecipient,

        _safeFarmFeeRecipient,

        _treasuryFeeRecipient,
        _systemFeeRecipient
    ) {}

    // initialize strategy
    function initialize(
        address _safeFarm,
        address _masterchef,
        uint256 _poolId
    ) public virtual onlyOwner {
        safeFarm = _safeFarm;
        masterchef = _masterchef;
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();

        if (lpToken0 != output) {
            if (output == wbnb || lpToken0 == wbnb) {
                outputToLp0Route = [output, lpToken0];
            }
            else {
                outputToLp0Route = [output, wbnb, lpToken0];
            }
        }

        if (lpToken1 != output) {
            if (output == wbnb || lpToken1 == wbnb) {
                outputToLp1Route = [output, lpToken1];
            }
            else {
                outputToLp1Route = [output, wbnb, lpToken1];
            }
        }

        _giveAllowances();
    }

    // withdraw the funds by account's request from safeFarm contract
    function withdraw(
        address account, uint256 share, uint256 totalShares
    ) external onlySafeFarm {
        harvest();
        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        uint256 systemFeeAmount = wantBal * systemFee / 100;
        uint256 treasuryFeeAmount = wantBal * treasuryFee / 100;
        uint256 withdrawalAmount = wantBal - systemFeeAmount - treasuryFeeAmount;

        IERC20(want).safeTransfer(account, withdrawalAmount);

        uint256 feeAmount = systemFeeAmount + treasuryFeeAmount;
        if (feeAmount > 0) {
            (uint256 amountToken0, uint256 amountToken1) = _removeLiquidity(feeAmount);

            uint256 systemFeeAmountToken0 = amountToken0 * systemFeeAmount / (feeAmount);
            IERC20(lpToken0).safeTransfer(systemFeeRecipient, systemFeeAmountToken0);
            IERC20(lpToken0).safeTransfer(treasuryFeeRecipient, amountToken0 - systemFeeAmountToken0);

            uint256 systemFeeAmountToken1 = amountToken1 * systemFeeAmount / (feeAmount);
            IERC20(lpToken1).safeTransfer(systemFeeRecipient, systemFeeAmountToken1);
            IERC20(lpToken1).safeTransfer(treasuryFeeRecipient, amountToken1 - systemFeeAmountToken1);
        }

        emit Withdraw(address(want), account, withdrawalAmount);
    }

    // safe withdraw the funds by oracle's request from safeFarm contract
    function safeSwap(
        address account, uint256 share, uint256 totalShares,
        uint256 feeAdd,
        address[] memory route0, address[] memory route1
    ) external onlySafeFarm {
        require(route0[0] == lpToken0, "invalid route0");
        require(route1[0] == lpToken1, "invalid route1");

        harvest();
        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        (uint256 amountToken0, uint256 amountToken1) = _removeLiquidity(wantBal);
        _safeSwap(account, amountToken0, route0, feeAdd);
        _safeSwap(account, amountToken1, route1, 0);
    }

    // compounds earnings and charges performance fee
    function harvest() public override whenNotPaused onlyEOA {
        _poolDeposit(0);

        uint256 toWant = _chargeFees();
        if (toWant > 0) {
            _addOutputToLiquidity(toWant);
            deposit();
        }

        emit StratHarvest(msg.sender);
    }


    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override virtual returns (uint256) {
        (uint256 _amount, ) = IMasterChef(masterchef).userInfo(poolId, address(this));
        return _amount;
    }

    function pendingReward() public view override virtual returns (uint256 amount) {
        amount = IMasterChef(masterchef).pendingCake(poolId, address(this));
        return amount * (MAX_FEE - poolFee) / MAX_FEE;
    }


// INTERNAL FUNCTIONS

    function _poolDeposit(uint256 _amount) internal override virtual {
        IMasterChef(masterchef).deposit(poolId, _amount);
    }

    function _poolWithdraw(uint256 _amount) internal override virtual {
        IMasterChef(masterchef).withdraw(poolId, _amount);
    }

    function _emergencyWithdraw() internal override virtual {
        uint256 poolBal = balanceOfPool();
        if (poolBal > 0) {
            IMasterChef(masterchef).emergencyWithdraw(poolId);
        }
    }

    function _giveAllowances() internal override virtual {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(want).safeApprove(masterchef, type(uint256).max);

        IERC20(want).safeApprove(unirouter, 0);
        IERC20(want).safeApprove(unirouter, type(uint256).max);

        IERC20(output).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal override virtual {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(want).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function _addOutputToLiquidity(uint256 toWant) internal {
        uint256 outputHalf = toWant / 2;

        if (lpToken0 != output) {
            _swapToken(outputHalf, outputToLp0Route, address(this));
        }

        if (lpToken1 != output) {
            _swapToken(toWant - outputHalf, outputToLp1Route, address(this));
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        _addLiquidity( lp0Bal, lp1Bal);
    }

    function _addLiquidity(uint256 amountToken0, uint256 amountToken1) internal virtual {
        IUniswapRouterETH(unirouter).addLiquidity(
            lpToken0,
            lpToken1,
            amountToken0,
            amountToken1,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function _removeLiquidity(uint256 amount) internal virtual returns (
        uint256 amountToken0, uint256 amountToken1
    ) {
        return IUniswapRouterETH(unirouter).removeLiquidity(
            lpToken0,
            lpToken1,
            amount,
            1,
            1,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./UniswapInterfaces.sol";


contract StratManager is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 constant public MAX_FEE = 1000;

    /**
     * @dev Contracts:
     * {safeFarm} - Address of the safeFarm that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public safeFarm;
    address public unirouter;

    address public want;
    address public output;
    address public wbnb;

    address[] public outputToWbnbRoute;

    // Fee
    uint256 public poolFee = 30; // 3%

    uint256 public callFee = 0;
    address public callFeeRecipient;
    // strategistFee = (100% - callFee - frfiFee)

    uint256 public frfiFee = 0;
    address public frfiFeeRecipient;

    address public strategistFeeRecipient;

    uint256 public safeFarmFee = 0;
    address public safeFarmFeeRecipient;

    uint256 public treasuryFee = 0;
    address public treasuryFeeRecipient;

    uint256 public systemFee = 0;
    address public systemFeeRecipient;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event Deposit(uint256 amount);
    event Withdraw(address tokenAddress, address account, uint256 amount);
    event StratHarvest(address indexed harvester);
    event SafeSwap(address indexed tokenAddress, address indexed account, uint256 amount);
    event ChargedFees(uint256 callFees, uint256 frfiFees, uint256 strategistFees);

    /**
     * @dev Initializes the base strategy.
     * @param _unirouter router to use for swaps
     */
    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient,

        address _safeFarmFeeRecipient,

        address _treasuryFeeRecipient,
        address _systemFeeRecipient
    ) {
        unirouter = _unirouter;

        want = _want;
        output = _output;
        wbnb = _wbnb;

        if (output != wbnb) {
            outputToWbnbRoute = [output, wbnb];
        }

        callFeeRecipient = _callFeeRecipient;
        frfiFeeRecipient = _frfiFeeRecipient;
        strategistFeeRecipient = _strategistFeeRecipient;

        safeFarmFeeRecipient = _safeFarmFeeRecipient;

        treasuryFeeRecipient = _treasuryFeeRecipient;
        systemFeeRecipient = _systemFeeRecipient;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(
            msg.sender == tx.origin
            || msg.sender == address(safeFarm)
            , "!EOA");
        _;
    }
    modifier onlySafeFarm() {
        require(msg.sender == address(safeFarm), "!safeFarm");
        _;
    }

// RESTRICTED FUNCTIONS

    /*function initialize(address _safeFarm) public onlyOwner {
        safeFarm = _safeFarm;
    }*/

    function migrate(address newSafeFarm) external onlySafeFarm {
        safeFarm = newSafeFarm;
    }

    function pause() public onlyOwner {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyOwner {
        _unpause();
        _giveAllowances();
        deposit();
    }


    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        _removeAllowances();
        unirouter = _unirouter;
        _giveAllowances();
    }

    function setPoolFee(uint256 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    function setCallFee(uint256 _callFee, address _callFeeRecipient) external onlyOwner {
        callFee = _callFee;
        callFeeRecipient = _callFeeRecipient;
    }

    function setFrfiFee(uint256 _frfiFee, address _frfiFeeRecipient) external onlyOwner {
        frfiFee = _frfiFee;
        frfiFeeRecipient = _frfiFeeRecipient;
    }

    function setWithdrawFees(
        uint256 _systemFee,
        uint256 _treasuryFee,
        address _systemFeeRecipient,
        address _treasuryFeeRecipient
    ) external onlyOwner {
        require(_systemFeeRecipient != address(0), "systemFeeRecipient the zero address");
        require(_treasuryFeeRecipient != address(0), "treasuryFeeRecipient the zero address");

        systemFee = _systemFee;
        systemFeeRecipient = _systemFeeRecipient;
        treasuryFee = _treasuryFee;
        treasuryFeeRecipient = _treasuryFeeRecipient;
    }

    function setSafeFarmFee(
        uint256 _safeFarmFee,
        address _safeFarmFeeRecipient
    ) external onlyOwner {
        require(_safeFarmFeeRecipient != address(0), "safeFarmFeeRecipient the zero address");

        safeFarmFee = _safeFarmFee;
        safeFarmFeeRecipient = _safeFarmFeeRecipient;
    }

    // called as part of strat migration. Sends all the available funds back to the SafeFarm.
    function retireStrat() external onlySafeFarm {
        _emergencyWithdraw();

        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            IERC20(want).transfer(safeFarm, wantBal);
        }
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() external onlyOwner {
        pause();
        _emergencyWithdraw();
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        // require(_token != want, "!safe");
        // require(_token != output, "!safe");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

// PUBLIC WRITE FUNCTIONS
    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = balanceOfWant();

        if (wantBal > 0) {
            _poolDeposit(wantBal);

            emit Deposit(wantBal);
        }
    }

// PUBLIC VIEW FUNCTIONS

    // calculate shares amount by total
    function calcSharesAmount(
        uint256 share, uint256 totalShares
    ) public view returns (uint256 amount) {
        amount = balanceOf() * share / totalShares;
        return amount;
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // calculate the total underlaying 'want' held by the strat + pool + pending reward.
    /*function balance() public view returns (uint256) {
        return balanceOf() + (pendingReward() * (MAX_FEE - poolFee) / MAX_FEE);
    }*/

    // it calculates SafeFarmFee by amount
    function safeFarmFeeAmount(uint256 amount) public view returns (uint256) {
        return (amount * safeFarmFee / MAX_FEE);
    }

// INTERNAL FUNCTIONS

    function _outputBalance() internal virtual returns (uint256) {
        return IERC20(output).balanceOf(address(this));
    }

    function _chargeFees() internal returns (uint256) {
        uint256 allBal = _outputBalance();
        if (allBal == 0) return 0;

        uint256 toNative = allBal * poolFee / MAX_FEE;
        if (output != wbnb) {
            _swapToken(toNative, outputToWbnbRoute, address(this));
            uint256 nativeBal = IERC20(wbnb).balanceOf(address(this));
            _sendPoolFees(nativeBal);
        }
        else {
            _sendPoolFees(toNative);
        }


        return (allBal - toNative);
    }

    function _sendPoolFees(uint256 nativeBal) internal {
        uint256 callFeeAmount = nativeBal * callFee / MAX_FEE;
        if (callFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(callFeeRecipient, callFeeAmount);
        }

        uint256 frfiFeeAmount = nativeBal * frfiFee / MAX_FEE;
        if (frfiFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(frfiFeeRecipient, frfiFeeAmount);
        }

        uint256 strategistFeeAmount = nativeBal - callFeeAmount - frfiFeeAmount;
        if (strategistFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(strategistFeeRecipient, strategistFeeAmount);
        }

        emit ChargedFees(callFeeAmount, frfiFeeAmount, strategistFeeAmount);
    }

    function _safeSwap(
        address account, uint256 amount, address[] memory route,
        uint256 feeAdd
    ) internal {
        address tokenB = route[route.length - 1];
        uint256 amountB;
        if (route.length == 1 || tokenB == want) {
            amountB = amount;
        }
        else {
            amountB = _swapToken(amount, route, address(this));
        }

        uint256 feeAmount = safeFarmFeeAmount(amountB) + feeAdd;
        require(amountB > feeAmount, "low profit amount");

        uint256 withdrawalAmount = amountB - feeAmount;

        IERC20(tokenB).safeTransfer(account, withdrawalAmount);
        if (feeAmount > 0) {
            IERC20(tokenB).safeTransfer(safeFarmFeeRecipient, feeAmount);
        }

        emit SafeSwap(tokenB, account, withdrawalAmount);
    }

    function _getWantBalance(uint256 amount) internal returns(uint256 wantBal) {
        wantBal = balanceOfWant();

        if (wantBal < amount) {
            _poolWithdraw(amount - wantBal);
            wantBal = balanceOfWant();
        }

        if (wantBal > amount) {
            wantBal = amount;
        }

        return wantBal;
    }

    function _swapToken(
        uint256 _amount,
        address[] memory _path,
        address _to
    ) internal virtual returns (uint256 result) {
        uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(
            _amount,
            1,
            _path,
            _to,
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }

// VIRTUAL

    function harvest() public virtual {}

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view virtual returns (uint256) {}
    function pendingReward() public view virtual returns (uint256) {}

    function _poolDeposit(uint256 amount) internal virtual {}
    function _poolWithdraw(uint256 amount) internal virtual {}
    function _emergencyWithdraw() internal virtual {}

    function _giveAllowances() internal virtual {}
    function _removeAllowances() internal virtual {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function lpToken(uint256 _pid) external view returns (address);

    function userInfo(uint256 _pid, address _user) external view returns (
        // amount, rewardDebt
        uint256, uint256
    );

    function poolInfo(uint256 _pid) external view returns (
        // lpToken, allocPoint, lastRewardBlock, accTokensPerShare
        address, uint256, uint256, uint256
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;


interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external view
        returns (uint[] memory amounts);
}


interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint256, uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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