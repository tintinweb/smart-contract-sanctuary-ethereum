pragma solidity =0.5.16;

import "./interfaces/IFactory.sol";
import "./interfaces/IBDeployer.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICDeployer.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ITarotPriceOracle.sol";

contract Factory is IFactory {
    address public admin;
    address public pendingAdmin;
    address public reservesAdmin;
    address public reservesPendingAdmin;
    address public reservesManager;

    struct LendingPool {
        bool initialized;
        uint24 lendingPoolId;
        address collateral;
        address borrowable0;
        address borrowable1;
    }
    mapping(address => LendingPool) public getLendingPool; // get by UniswapV2Pair
    address[] public allLendingPools; // address of the UniswapV2Pair

    function allLendingPoolsLength() external view returns (uint256) {
        return allLendingPools.length;
    }

    IBDeployer public bDeployer;
    ICDeployer public cDeployer;
    ITarotPriceOracle public tarotPriceOracle;

    event LendingPoolInitialized(
        address indexed uniswapV2Pair,
        address indexed token0,
        address indexed token1,
        address collateral,
        address borrowable0,
        address borrowable1,
        uint256 lendingPoolId
    );
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewReservesPendingAdmin(
        address oldReservesPendingAdmin,
        address newReservesPendingAdmin
    );
    event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
    event NewReservesManager(
        address oldReservesManager,
        address newReservesManager
    );

    constructor(
        address _admin,
        address _reservesAdmin,
        IBDeployer _bDeployer,
        ICDeployer _cDeployer,
        ITarotPriceOracle _tarotPriceOracle
    ) public {
        admin = _admin;
        reservesAdmin = _reservesAdmin;
        bDeployer = _bDeployer;
        cDeployer = _cDeployer;
        tarotPriceOracle = _tarotPriceOracle;
        emit NewAdmin(address(0), _admin);
        emit NewReservesAdmin(address(0), _reservesAdmin);
    }

    function _getTokens(address uniswapV2Pair)
        private
        view
        returns (address token0, address token1)
    {
        token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        token1 = IUniswapV2Pair(uniswapV2Pair).token1();
    }

    function _createLendingPool(address uniswapV2Pair) private {
        if (getLendingPool[uniswapV2Pair].lendingPoolId != 0) return;
        allLendingPools.push(uniswapV2Pair);
        getLendingPool[uniswapV2Pair] = LendingPool(
            false,
            uint24(allLendingPools.length),
            address(0),
            address(0),
            address(0)
        );
    }

    function createCollateral(address uniswapV2Pair)
        external
        returns (address collateral)
    {
        _getTokens(uniswapV2Pair);
        require(
            getLendingPool[uniswapV2Pair].collateral == address(0),
            "Tarot: ALREADY_EXISTS"
        );
        collateral = cDeployer.deployCollateral(uniswapV2Pair);
        ICollateral(collateral)._setFactory();
        _createLendingPool(uniswapV2Pair);
        getLendingPool[uniswapV2Pair].collateral = collateral;
    }

    function createBorrowable0(address uniswapV2Pair)
        external
        returns (address borrowable0)
    {
        _getTokens(uniswapV2Pair);
        require(
            getLendingPool[uniswapV2Pair].borrowable0 == address(0),
            "Tarot: ALREADY_EXISTS"
        );
        borrowable0 = bDeployer.deployBorrowable(uniswapV2Pair, 0);
        IBorrowable(borrowable0)._setFactory();
        _createLendingPool(uniswapV2Pair);
        getLendingPool[uniswapV2Pair].borrowable0 = borrowable0;
    }

    function createBorrowable1(address uniswapV2Pair)
        external
        returns (address borrowable1)
    {
        _getTokens(uniswapV2Pair);
        require(
            getLendingPool[uniswapV2Pair].borrowable1 == address(0),
            "Tarot: ALREADY_EXISTS"
        );
        borrowable1 = bDeployer.deployBorrowable(uniswapV2Pair, 1);
        IBorrowable(borrowable1)._setFactory();
        _createLendingPool(uniswapV2Pair);
        getLendingPool[uniswapV2Pair].borrowable1 = borrowable1;
    }

    function initializeLendingPool(address uniswapV2Pair) external {
        (address token0, address token1) = _getTokens(uniswapV2Pair);
        LendingPool memory lPool = getLendingPool[uniswapV2Pair];
        require(!lPool.initialized, "Tarot: ALREADY_INITIALIZED");

        require(
            lPool.collateral != address(0),
            "Tarot: COLLATERALIZABLE_NOT_CREATED"
        );
        require(
            lPool.borrowable0 != address(0),
            "Tarot: BORROWABLE0_NOT_CREATED"
        );
        require(
            lPool.borrowable1 != address(0),
            "Tarot: BORROWABLE1_NOT_CREATED"
        );

        (, , , , , bool oracleInitialized) =
            tarotPriceOracle.getPair(uniswapV2Pair);
        if (!oracleInitialized) tarotPriceOracle.initialize(uniswapV2Pair);

        ICollateral(lPool.collateral)._initialize(
            "Tarot Collateral",
            "cTAROT",
            uniswapV2Pair,
            lPool.borrowable0,
            lPool.borrowable1
        );
        IBorrowable(lPool.borrowable0)._initialize(
            "Tarot Borrowable",
            "bTAROT",
            token0,
            lPool.collateral
        );
        IBorrowable(lPool.borrowable1)._initialize(
            "Tarot Borrowable",
            "bTAROT",
            token1,
            lPool.collateral
        );

        getLendingPool[uniswapV2Pair].initialized = true;
        emit LendingPoolInitialized(
            uniswapV2Pair,
            token0,
            token1,
            lPool.collateral,
            lPool.borrowable0,
            lPool.borrowable1,
            lPool.lendingPoolId
        );
    }

    function _setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "Tarot: UNAUTHORIZED");
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() external {
        require(msg.sender == pendingAdmin, "Tarot: UNAUTHORIZED");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, address(0));
    }

    function _setReservesPendingAdmin(address newReservesPendingAdmin)
        external
    {
        require(msg.sender == reservesAdmin, "Tarot: UNAUTHORIZED");
        address oldReservesPendingAdmin = reservesPendingAdmin;
        reservesPendingAdmin = newReservesPendingAdmin;
        emit NewReservesPendingAdmin(
            oldReservesPendingAdmin,
            newReservesPendingAdmin
        );
    }

    function _acceptReservesAdmin() external {
        require(msg.sender == reservesPendingAdmin, "Tarot: UNAUTHORIZED");
        address oldReservesAdmin = reservesAdmin;
        address oldReservesPendingAdmin = reservesPendingAdmin;
        reservesAdmin = reservesPendingAdmin;
        reservesPendingAdmin = address(0);
        emit NewReservesAdmin(oldReservesAdmin, reservesAdmin);
        emit NewReservesPendingAdmin(oldReservesPendingAdmin, address(0));
    }

    function _setReservesManager(address newReservesManager) external {
        require(msg.sender == reservesAdmin, "Tarot: UNAUTHORIZED");
        address oldReservesManager = reservesManager;
        reservesManager = newReservesManager;
        emit NewReservesManager(oldReservesManager, newReservesManager);
    }
}

pragma solidity >=0.5.0;

interface IFactory {
	event LendingPoolInitialized(address indexed uniswapV2Pair, address indexed token0, address indexed token1,
		address collateral, address borrowable0, address borrowable1, uint lendingPoolId);
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewReservesPendingAdmin(address oldReservesPendingAdmin, address newReservesPendingAdmin);
	event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
	event NewReservesManager(address oldReservesManager, address newReservesManager);
	
	function admin() external view returns (address);
	function pendingAdmin() external view returns (address);
	function reservesAdmin() external view returns (address);
	function reservesPendingAdmin() external view returns (address);
	function reservesManager() external view returns (address);

	function getLendingPool(address uniswapV2Pair) external view returns (
		bool initialized, 
		uint24 lendingPoolId, 
		address collateral, 
		address borrowable0, 
		address borrowable1
	);
	function allLendingPools(uint) external view returns (address uniswapV2Pair);
	function allLendingPoolsLength() external view returns (uint);
	
	function bDeployer() external view returns (address);
	function cDeployer() external view returns (address);
	function tarotPriceOracle() external view returns (address);

	function createCollateral(address uniswapV2Pair) external returns (address collateral);
	function createBorrowable0(address uniswapV2Pair) external returns (address borrowable0);
	function createBorrowable1(address uniswapV2Pair) external returns (address borrowable1);
	function initializeLendingPool(address uniswapV2Pair) external;

	function _setPendingAdmin(address newPendingAdmin) external;
	function _acceptAdmin() external;
	function _setReservesPendingAdmin(address newPendingAdmin) external;
	function _acceptReservesAdmin() external;
	function _setReservesManager(address newReservesManager) external;
}

pragma solidity >=0.5.0;

interface IBDeployer {
	function deployBorrowable(address uniswapV2Pair, uint8 index) external returns (address borrowable);
}

pragma solidity >=0.5.0;

interface IBorrowable {
    /*** Tarot ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

    /*** Pool Token ***/

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /*** Borrowable ***/

    event BorrowApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 seizeTokens,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    function BORROW_FEE() external pure returns (uint256);

    function collateral() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function exchangeRateLast() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowAllowance(address owner, address spender)
        external
        view
        returns (uint256);

    function borrowBalance(address borrower) external view returns (uint256);

    function borrowTracker() external view returns (address);

    function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);

    function borrowApprove(address spender, uint256 value)
        external
        returns (bool);

    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function liquidate(address borrower, address liquidator)
        external
        returns (uint256 seizeTokens);

    function trackBorrow(address borrower) external;

    /*** Borrowable Interest Rate Model ***/

    event AccrueInterest(
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );
    event CalculateKink(uint256 kinkRate);
    event CalculateBorrowRate(uint256 borrowRate);

    function KINK_BORROW_RATE_MAX() external pure returns (uint256);

    function KINK_BORROW_RATE_MIN() external pure returns (uint256);

    function KINK_MULTIPLIER() external pure returns (uint256);

    function borrowRate() external view returns (uint256);

    function kinkBorrowRate() external view returns (uint256);

    function kinkUtilizationRate() external view returns (uint256);

    function adjustSpeed() external view returns (uint256);

    function rateUpdateTimestamp() external view returns (uint32);

    function accrualTimestamp() external view returns (uint32);

    function accrueInterest() external;

    /*** Borrowable Setter ***/

    event NewReserveFactor(uint256 newReserveFactor);
    event NewKinkUtilizationRate(uint256 newKinkUtilizationRate);
    event NewAdjustSpeed(uint256 newAdjustSpeed);
    event NewBorrowTracker(address newBorrowTracker);

    function RESERVE_FACTOR_MAX() external pure returns (uint256);

    function KINK_UR_MIN() external pure returns (uint256);

    function KINK_UR_MAX() external pure returns (uint256);

    function ADJUST_SPEED_MIN() external pure returns (uint256);

    function ADJUST_SPEED_MAX() external pure returns (uint256);

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _collateral
    ) external;

    function _setReserveFactor(uint256 newReserveFactor) external;

    function _setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;

    function _setAdjustSpeed(uint256 newAdjustSpeed) external;

    function _setBorrowTracker(address newBorrowTracker) external;
}

pragma solidity >=0.5.0;

interface ICDeployer {
	function deployCollateral(address uniswapV2Pair) external returns (address collateral);
}

pragma solidity >=0.5.0;

interface ICollateral {
    /*** Tarot ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

    /*** Pool Token ***/

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /*** Collateral ***/

    function borrowable0() external view returns (address);

    function borrowable1() external view returns (address);

    function tarotPriceOracle() external view returns (address);

    function safetyMarginSqrt() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);

    function getPrices() external returns (uint256 price0, uint256 price1);

    function tokensUnlocked(address from, uint256 value)
        external
        returns (bool);

    function accountLiquidityAmounts(
        address account,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 liquidity, uint256 shortfall);

    function accountLiquidity(address account)
        external
        returns (uint256 liquidity, uint256 shortfall);

    function canBorrow(
        address account,
        address borrowable,
        uint256 accountBorrows
    ) external returns (bool);

    function seize(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 seizeTokens);

    function flashRedeem(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external;

    /*** Collateral Setter ***/

    event NewSafetyMargin(uint256 newSafetyMarginSqrt);
    event NewLiquidationIncentive(uint256 newLiquidationIncentive);

    function SAFETY_MARGIN_SQRT_MIN() external pure returns (uint256);

    function SAFETY_MARGIN_SQRT_MAX() external pure returns (uint256);

    function LIQUIDATION_INCENTIVE_MIN() external pure returns (uint256);

    function LIQUIDATION_INCENTIVE_MAX() external pure returns (uint256);

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _borrowable0,
        address _borrowable1
    ) external;

    function _setSafetyMarginSqrt(uint256 newSafetyMarginSqrt) external;

    function _setLiquidationIncentive(uint256 newLiquidationIncentive) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);
}

pragma solidity >=0.5.0;

interface ITarotPriceOracle {
    event PriceUpdate(
        address indexed pair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    function MIN_T() external pure returns (uint32);

    function getPair(address uniswapV2Pair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    function initialize(address uniswapV2Pair) external;

    function getResult(address uniswapV2Pair)
        external
        returns (uint224 price, uint32 T);
}