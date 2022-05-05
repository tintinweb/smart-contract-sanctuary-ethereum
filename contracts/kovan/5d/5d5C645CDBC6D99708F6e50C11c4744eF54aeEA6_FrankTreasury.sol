// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";
import "./interfaces/IBondManager.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IJoeROuter02.sol";
import "./interfaces/IBoostedMasterChefJoe.sol";
import "./interfaces/IJoePair.sol";
import "./other/Ownable.sol";

interface IStableJoeStaking {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;
}

interface IVeJoeStaking {
    function deposit(uint256 _amount) external;

    function claim() external;

    function withdraw(uint256 _amount) external;
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IJoePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

//Add withdraws

contract FrankTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Strategy {
        uint24[] DISTRIBUTION_BONDED_JOE; //
        uint24[] DISTRIBUTION_REINVESTMENTS;
        uint24 PROPORTION_REINVESTMENTS;
        address LIQUIDITY_POOL;
    }
    
    //IBoostedMasterChefJoe public constant BMCJ = IBoostedMasterChefJoe(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);
    IVeJoeStaking public constant VeJoeStaking = IVeJoeStaking(0xf09597ef3cEebd18905ba573E48ec9Ad3A160096);
    IStableJoeStaking public constant SJoeStaking = IStableJoeStaking(0xCF6E93c729f07019819Bc67C7ebadda4FaC3b233);
    IJoeRouter02 public constant TraderJoeRouter = IJoeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public constant JOE = IERC20(0x1217686124AA11323cC389a8BC39C170D665370b);
    IBondManager public BondManager;

    address private constant teamAddress = 0xE6461Da23098d2420Ce9A35b329FA82db0919c30;
    address private constant investorAddress = 0xE6461Da23098d2420Ce9A35b329FA82db0919c30;
    uint256 private constant FEE_PRECISION = 100_000;
    uint256 private internalFee;
    uint256 bondedTokens;
    uint256 currentRevenue;
    uint256 totalRevenue;

    uint256 DISTRIBUTE_THRESHOLD = 5_000 * 10 ** 18; 

    uint256[] activePIDs;
    mapping(uint256 => bool) isPIDActive;

    uint256 private slippage = 980;
    
    Strategy public strategy;

    constructor() {
        setFee(2000);
        setStrategy([uint24(50000),50000], [uint24(45000),45000,10000], 50000, 0x706b4f0Bf3252E946cACD30FAD779d4aa27080c0);
    }

    /// @notice Change the bond manager address.
    /// @param _bondManager New BondManager address.
    function setBondManager(address _bondManager) external onlyOwner {
        BondManager = IBondManager(_bondManager);
    }

    /// @notice Change the fee for team and investors.
    /// @param _fee New fee.
    /// @dev Team and investors will have the same fee.
    function setFee(uint256 _fee) public onlyOwner {
        internalFee = _fee;
    }

    /// @notice Change minimum amount of revenue required to call the distribute() function.
    /// @param _threshold New threshold.
    function setDistributionThreshold(uint256 _threshold) external onlyOwner {
        DISTRIBUTE_THRESHOLD = _threshold;
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    /// @notice Set the Treasury's strategy.
    /// @param _DISTRIBUTION_BONDED_JOE 2 value array storing 1. proportion of BONDED JOE staked to sJOE 2. proportion staked to veJOE
    /// @param _DISTRIBUTION_REINVESTMENTS 3 value array storing 1. proportion of REINVESTED REVENUE staked to sJOE 2. proportion staked to veJOE 3. proportion farmed in BMCJ
    /// @param _PROPORTION_REINVESTMENTS Proportion of REVENUE reinvested within the protocol.
    /// @param _LIQUIDITY_POOL Liquidity pool currently farmed on BMCJ 
    function setStrategy(uint24[2] memory _DISTRIBUTION_BONDED_JOE, uint24[3] memory _DISTRIBUTION_REINVESTMENTS, uint24 _PROPORTION_REINVESTMENTS, address _LIQUIDITY_POOL) public onlyOwner {
        require(_DISTRIBUTION_BONDED_JOE.length == 2);
        require(_DISTRIBUTION_BONDED_JOE[0] + _DISTRIBUTION_BONDED_JOE[1] == 100_000);
        strategy.DISTRIBUTION_BONDED_JOE = _DISTRIBUTION_BONDED_JOE;

        require(_DISTRIBUTION_REINVESTMENTS.length == 3);
        require(_DISTRIBUTION_REINVESTMENTS[0] + _DISTRIBUTION_REINVESTMENTS[1] + _DISTRIBUTION_REINVESTMENTS[2] == 100_000);
        strategy.DISTRIBUTION_REINVESTMENTS = _DISTRIBUTION_REINVESTMENTS;

        require(_PROPORTION_REINVESTMENTS <= 100_000);
        strategy.PROPORTION_REINVESTMENTS = _PROPORTION_REINVESTMENTS;

        strategy.LIQUIDITY_POOL = _LIQUIDITY_POOL;
    }

    /// @notice Distribute revenue to BondManager (where bond holders can later claim rewards and shares).
    /// @dev Anyone can call this function, if the current revenue is above a certain threshold (DISTRIBUTE_THRESHOLD). 
    function distribute() external {
        harvest();
        require(currentRevenue >= DISTRIBUTE_THRESHOLD);

        uint256 _currentRevenue = currentRevenue;
        uint256 _feeAmount = SafeMath.div(SafeMath.mul(_currentRevenue, internalFee), FEE_PRECISION);

        JOE.safeTransferFrom(address(this), teamAddress, _feeAmount);
        JOE.safeTransferFrom(address(this), investorAddress, _feeAmount);

        _currentRevenue = SafeMath.sub(_currentRevenue, SafeMath.mul(_feeAmount, 2));

        uint256 _reinvestedAmount = SafeMath.div(SafeMath.mul(_currentRevenue, strategy.PROPORTION_REINVESTMENTS), 100_000);
        uint256 _rewardedAmount = SafeMath.sub(_currentRevenue, _reinvestedAmount);

        _reinvest(_reinvestedAmount);

        JOE.approve(address(BondManager), _rewardedAmount);
        BondManager.depositRewards(_rewardedAmount, _reinvestedAmount);

        totalRevenue = SafeMath.add(totalRevenue, currentRevenue);
        currentRevenue = 0;
    }

    /// @notice Internal function used to reinvest part of revenue when calling distribute().
    /// @param _amount Amount of JOE tokens to reinvest.
    function _reinvest(uint256 _amount) private {
        uint256[] memory amounts = proportionDivide(_amount, strategy.DISTRIBUTION_REINVESTMENTS);

        JOE.approve(address(SJoeStaking), amounts[0]);
        JOE.approve(address(VeJoeStaking), amounts[1]);

        SJoeStaking.deposit(amounts[0]);
        VeJoeStaking.deposit(amounts[1]);
        _addAndFarmLiquidity(amounts[2], strategy.LIQUIDITY_POOL);
    }

    /// @notice Function called by BondManager contract everytime a bond is minted.
    /// @param _amount Amount of tokens deposited to the treasury,
    function bondDeposit(uint256 _amount, address _sender) external {
        require(_msgSender() == address(BondManager));

        JOE.safeTransferFrom(_sender, address(this), _amount);
        bondedTokens += _amount;

        uint256[] memory amounts = proportionDivide(_amount, strategy.DISTRIBUTION_BONDED_JOE);

        JOE.approve(address(SJoeStaking), amounts[0]);
        JOE.approve(address(VeJoeStaking), amounts[1]);
        
        SJoeStaking.deposit(amounts[0]);
        VeJoeStaking.deposit(amounts[1]);
    }

    function _addPoolAndFarmLiquidity3(uint256 _amount, address _pool) public {
        //harvest();

        IJoePair pair = IJoePair(_pool);

        address token0 = pair.token0();
        address token1 = pair.token1();

        require(token0 == address(JOE) || token1 == address(JOE));

        address tokenA = address(JOE);
        address tokenB = token0 == address(JOE) ? token1 : token0;

        uint256 _div = _amount / 2;

        uint256 safeAmount = (_div * slippage) / 1000;

        address[] memory path = new address[](2);   
        path[0] = tokenA;
        path[1] = tokenB;

        JOE.approve(address(TraderJoeRouter), safeAmount);

        uint256 amountOutMin = TraderJoeRouter.getAmountsOut(safeAmount, path)[1];
        uint256 amountsOut = TraderJoeRouter.swapExactTokensForTokens(safeAmount, amountOutMin, path, address(this), block.timestamp + 1000)[1];

        IERC20(tokenA).approve(address(TraderJoeRouter),_div);
        IERC20(tokenB).approve(address(TraderJoeRouter), amountsOut);

        (, , uint256 liquidity) = TraderJoeRouter.addLiquidity(tokenA, tokenB, _div, amountsOut, 0, 0, address(this), block.timestamp + 1000);

        //uint256 pid = getPoolIDFromLPToken(_pool);

        //if (!isPIDActive[pid]) {
        //    activePIDs.push(pid);
        //    isPIDActive[pid] = true;
        //}

        //IERC20(_pool).approve(address(BMCJ), liquidity);

        //BMCJ.deposit(pid, liquidity);
    }

    function _addPoolAndFarmLiquidity2(uint256 _amount, address _pool) public {
        //harvest();

        IJoePair pair = IJoePair(_pool);

        address token0 = pair.token0();
        address token1 = pair.token1();

        require(token0 == address(JOE) || token1 == address(JOE));

        address tokenA = address(JOE);
        address tokenB = token0 == address(JOE) ? token1 : token0;

        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();

        if(token1 == address(JOE)) {
            (reserveA, reserveB) = (reserveB, reserveA);
        }

        uint256 _div = _amount / 2;

        uint256 safeAmount = (_div * slippage) / 1000;

        uint256 quote = UniswapV2Library.quote(safeAmount, reserveA, reserveB);

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        JOE.approve(address(TraderJoeRouter), _div);

        TraderJoeRouter.swapTokensForExactTokens(quote, _div, path, address(this), block.timestamp + 1000);

        IERC20(tokenA).approve(address(TraderJoeRouter),_div);
        IERC20(token1).approve(address(TraderJoeRouter), quote);

        (, , uint256 liquidity) = TraderJoeRouter.addLiquidity(tokenA, tokenB, safeAmount, quote, 0, quote, address(this), block.timestamp + 1000);

        //uint256 pid = getPoolIDFromLPToken(_pool);

        //if (!isPIDActive[pid]) {
        //    activePIDs.push(pid);
        //    isPIDActive[pid] = true;
        //}

        //IERC20(_pool).approve(address(BMCJ), liquidity);

        //BMCJ.deposit(pid, liquidity);
    }

    /// @notice Convert treasury JOE to LP tokens and farm them on BMCJ.
    /// @param _amount Amount of JOE tokens to farm.
    /// @param _pool Boosted pool address.
    function _addAndFarmLiquidity(uint256 _amount, address _pool) private {
        harvest();

        IJoePair pair = IJoePair(_pool);

        address token0 = pair.token0();
        address token1 = pair.token1();

        address[] memory path = new address[](2);
        path[0] = address(JOE);

        uint256 minAmountOut;
        uint256 amountOutA;

        if (token0 != address(JOE)) {
            JOE.approve(address(TraderJoeRouter), (_amount/2));
            path[1] = token0;
            minAmountOut = ((TraderJoeRouter.getAmountsOut((_amount / 2), path)[1] * 95) / 100);
            amountOutA = (TraderJoeRouter.swapExactTokensForTokens((_amount / 2), minAmountOut, path, address(this), (block.timestamp + 1000)))[1];
        } else {
            amountOutA = _amount / 2;
        }

        uint256 amountOutB;

        if (token1 != address(JOE)) {
            JOE.approve(address(TraderJoeRouter), (_amount/2));
            path[1] = token1;
            minAmountOut = ((TraderJoeRouter.getAmountsOut((_amount / 2), path)[1] * 95) / 100);
            amountOutB = (TraderJoeRouter.swapExactTokensForTokens((_amount / 2), minAmountOut, path, address(this), (block.timestamp + 1000)))[1];
        } else {
            amountOutB = _amount / 2;
        }

        IERC20(token0).approve(address(TraderJoeRouter), amountOutA);
        IERC20(token1).approve(address(TraderJoeRouter), amountOutB);

        (uint256 amountOutA1, uint256 amountOutB1 , uint256 liquidity) = TraderJoeRouter.addLiquidity(token0, token1, amountOutA, amountOutB, ((amountOutA * 95) / 100), ((amountOutB * 95) / 100), address(this), block.timestamp + 1000);

        path[1] = address(JOE);
        uint256 diff = amountOutA - amountOutA1;
        if(token0 != address(JOE)) {
            IERC20(token0).approve(address(TraderJoeRouter), diff);
            path[0] = token0;
            minAmountOut = ((TraderJoeRouter.getAmountsOut(diff, path)[1] * 95) / 100);
            (TraderJoeRouter.swapExactTokensForTokens(diff, minAmountOut, path, address(this), (block.timestamp + 1000)))[1];
        }

        diff = amountOutB - amountOutB1;
        if(token1 != address(JOE)) {
            IERC20(token1).approve(address(TraderJoeRouter), diff);
            path[0] = token1;
            minAmountOut = ((TraderJoeRouter.getAmountsOut(diff, path)[1] * 95) / 100);
            (TraderJoeRouter.swapExactTokensForTokens(diff, minAmountOut, path, address(this), (block.timestamp + 1000)))[1];
        }

        //uint256 pid = getPoolIDFromLPToken(_pool);

        //if (!isPIDActive[pid]) {
        //    activePIDs.push(pid);
        //    isPIDActive[pid] = true;
        //}

        //IERC20(_pool).approve(address(BMCJ), liquidity);

        //BMCJ.deposit(pid, liquidity);
    }

    /// @notice External onlyOwner implementation of _addAndFarmLiquidity.
    /// @param _amount Amount of JOE tokens to farm.
    /// @param _pool Boosted pool address.
    /// @dev Used to reallocate protocol owned liquidity. First liquidity from a pool is removed with removeLiquidity() and then it is migrated to another pool
    /// through this function. 
    function addAndFarmLiquidity(uint256 _amount, address _pool) external onlyOwner {
        _addPoolAndFarmLiquidity2(_amount, _pool);
    }

    /// @notice Remove liquidity from Boosted pool and convert assets to JOE.
    /// @param _amount Amount of LP tokens to remove from liquidity.
    /// @param _pool Boosted pool address.
    function removeLiquidity(uint256 _amount, address _pool) external onlyOwner {
        harvest();

        uint256 liquidityBalance = IERC20(_pool).balanceOf(address(this));
        require(liquidityBalance >= _amount);
/*
        uint256 pid = getPoolIDFromLPToken(_pool);

        if (_amount == liquidityBalance) {
            isPIDActive[pid] = false;
            bool isPIDFound = false;

            for (uint256 i = 0; i < activePIDs.length; i++) {
                if (isPIDFound) {
                    activePIDs[i - i] = activePIDs[i];
                }
                if (activePIDs[i] == pid) {
                    isPIDFound = true;
                }
            }

            activePIDs.pop();
            
        }
        */

        IJoePair pair = IJoePair(_pool);

        //harvestPool(pid);

        //BMCJ.withdraw(pid, _amount);

        //SAFETY SLIPPAGE
        (uint256 amountA, uint256 amountB) = TraderJoeRouter.removeLiquidity(pair.token0(), pair.token1(), _amount, 0, 0, address(this), block.timestamp);

        address[] memory path = new address[](2);
        path[1] = address(JOE);

        if (pair.token0() != address(JOE)) {
            IERC20(pair.token0()).approve(address(TraderJoeRouter), amountA);
            path[0] = pair.token0();
            TraderJoeRouter.swapExactTokensForTokens(amountA, (amountA * 95) / 100, path, address(this), (block.timestamp + 1000));
        }

        if (pair.token1() != address(JOE)) {
            IERC20(pair.token1()).approve(address(TraderJoeRouter), amountB);
            path[0] = pair.token1();
            TraderJoeRouter.swapExactTokensForTokens(amountB, (amountB * 95) / 100, path, address(this), (block.timestamp + 1000));
        }
    }

    /// @notice Harvest rewards from sJOE and BMCJ farms
    /// @dev Anyone can call this function
    function harvest() public { 
        /*
        for(uint i = 0; i < activePIDs.length; i++) {
            harvestPool(activePIDs[i]);
        }
        */
        harvestJoe();
    }
 
    /// @notice Harvest rewards from boosted pool.
    /// @param _pid Pool PID. 
    function harvestPool(uint256 _pid) private {
        //uint256 balanceBefore = JOE.balanceOf(address(this));
        //BMCJ.deposit(_pid, 0);
        //uint256 _revenue = JOE.balanceOf(address(this)) - balanceBefore;
        //currentRevenue += _revenue;
    }

    /// @notice Harvest rewards from sJOE and harvest veJOE. 
    function harvestJoe() private {
        uint256 balanceBefore = JOE.balanceOf(address(this));
        IStableJoeStaking(SJoeStaking).withdraw(0);
        // Convert to JOE
        uint256 _revenue = JOE.balanceOf(address(this)) - balanceBefore;
        currentRevenue += _revenue; 

        IVeJoeStaking(VeJoeStaking).claim();
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = target.call{value: value}(data);
        return (success, result);
    }

    /// @notice Internal function to divide an amount into different proportions.
    /// @param amount_ Amount to divide.
    /// @param _proportions Array of the different proportions in which to divide amount_
    function proportionDivide(uint256 amount_, uint24[] memory _proportions) private pure returns (uint256[] memory _amounts) {
        uint256 amountTotal;
        uint256 proportionTotal;
        _amounts = new uint256[](_proportions.length);

        for (uint256 i = 0; i < _proportions.length; i++) {
            uint256 _amount = (amount_ * _proportions[i]) / 100_000;
            amountTotal += _amount;
            proportionTotal += _proportions[i];
            _amounts[i] = _amount;
        }

        require(proportionTotal == 100_000);

        require(amountTotal <= amount_);

        if (amountTotal < amount_) {
            _amounts[0] += (amount_ - amountTotal);
        }

        return _amounts;
    }

    /// @notice Get PID from LP token address.
    /// @param _token LP token address. 
    /*
    function getPoolIDFromLPToken(address _token) internal view returns (uint256) {
        for (uint256 i = 0; i < BMCJ.poolLength(); i++) {
            (address _lp, , , , , , , , ) = BMCJ.poolInfo(i);
            if (_lp == _token) {
                return i;
            }
        }
        revert();
    }
    */

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
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

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

interface IBoostedMasterChefJoe {
  function JOE (  ) external view returns ( address );
  function MASTER_CHEF_V2 (  ) external view returns ( address );
  function MASTER_PID (  ) external view returns ( uint256 );
  function VEJOE (  ) external view returns ( address );
  function add ( uint96 _allocPoint, uint32 _veJoeShareBp, address _lpToken, address _rewarder ) external;
  function claimableJoe ( uint256, address ) external view returns ( uint256 );
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function emergencyWithdraw ( uint256 _pid ) external;
  function harvestFromMasterChef (  ) external;
  function init ( address _dummyToken ) external;
  function initialize ( address _MASTER_CHEF_V2, address _joe, address _veJoe, uint256 _MASTER_PID ) external;
  function joePerSec (  ) external view returns ( uint256 amount );
  function massUpdatePools (  ) external;
  function owner (  ) external view returns ( address );
  function pendingTokens ( uint256 _pid, address _user ) external view returns ( uint256 pendingJoe, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken );
  function poolInfo ( uint256 ) external view returns ( address lpToken, uint96 allocPoint, uint256 accJoePerShare, uint256 accJoePerFactorPerShare, uint64 lastRewardTimestamp, address rewarder, uint32 veJoeShareBp, uint256 totalFactor, uint256 totalLpSupply );
  function poolLength (  ) external view returns ( uint256 pools );
  function renounceOwnership (  ) external;
  function set ( uint256 _pid, uint96 _allocPoint, uint32 _veJoeShareBp, address _rewarder, bool _overwrite ) external;
  function totalAllocPoint (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function updateFactor ( address _user, uint256 _newVeJoeBalance ) external;
  function updatePool ( uint256 _pid ) external;
  function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardDebt, uint256 factor );
  function withdraw ( uint256 _pid, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

interface IBondManager {

    function baseToken() external view returns (address);

    function bond() external view returns (address);

    function treasury() external view returns (address);

    function accRewardsPerWS() external view returns (uint256);

    function accSharesPerUS() external view returns (uint256);

    function isDiscountActive() external view returns (bool);

    function isDiscountPlanned() external view returns (bool);

    function isSaleActive() external view returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function totalUnweightedShares() external view returns (uint256);

    function totalWeightedShares() external view returns (uint256);

    function startDiscountAt(uint256 _startAt, uint256 _endAt, uint16 _discountRate, uint64 _updateFrequency, uint8[] memory _purchaseLimit) external;

    function startDiscountIn(uint256 _startIn, uint256 _endIn, uint16 _discountRate, uint64 _updateFrequency, uint8[] memory _purchaseLimit) external;

    function deactivateDiscount() external;

    function addBondLevel (string memory _name, uint16 _basePrice, uint16 _weight, uint32 _sellableAmount) external returns (bytes4);

    function addBondLevelAtIndex (string memory _name, uint16 _basePrice, uint16 _weight, uint32 _sellableAmount, uint16 _index) external returns (bytes4);

    function changeBondLevel (bytes4 levelID, string memory _name, uint16 _basePrice, uint16 _weight, uint32 _sellableAmount) external;

    function deactivateBondLevel (bytes4 levelID) external;

    function activateBondLevel (bytes4 levelID, uint16 _index) external;

    function rearrangeBondLevel (bytes4 levelID, uint16 _index) external;

    function setBaseURI (string memory baseURI_) external;

    function toggleSale () external;

    function createMultipleBondsWithTokens (bytes4 levelID, uint16 _amount) external;

    function depositRewards (uint256 _issuedRewards, uint256 _issuedShares) external;

    function claim (uint256 _bondID) external;

    function claimAll () external;

    function batchClaim (uint256[] memory _bondIDs) external;

    function getPrice (bytes4 levelID) external view returns (uint256, bool);

    function getClaimableAmounts (uint256 _bondID) external view returns (uint256 claimableShares, uint256 claimableRewards);

    function linkBondManager() external;

}