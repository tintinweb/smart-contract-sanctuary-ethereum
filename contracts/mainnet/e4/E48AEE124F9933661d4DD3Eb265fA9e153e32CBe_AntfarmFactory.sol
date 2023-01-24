// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./AntfarmPair.sol";
import "./AntfarmAtfPair.sol";
import "../utils/AntfarmFactoryErrors.sol";

/// @title Antfarm Factory
/// @notice The Factory is used to create new Pair contracts for each unique ERC20 token pair
contract AntfarmFactory is IAntfarmFactory {
    uint16[8] public possibleFees = [10, 50, 100, 150, 250, 500, 750, 1000];
    address[] public allPairs;
    address public antfarmToken;

    mapping(address => mapping(address => mapping(uint16 => address)))
        public getPair;

    mapping(address => mapping(address => uint16[8])) public feesForPair;

    constructor(address _antfarmToken) {
        require(_antfarmToken != address(0), "NULL_ATF_ADDRESS");
        antfarmToken = _antfarmToken;
    }

    /// @notice Get list of fees for existing Antfarm Pair of a specific pair
    /// @param _token0 token0 from the pair
    /// @param _token1 token1 from the pair
    /// @return uint16 Fixed fees array
    function getFeesForPair(address _token0, address _token1)
        external
        view
        override
        returns (uint16[8] memory)
    {
        return feesForPair[_token0][_token1];
    }

    /// @notice Get total number of Antfarm Pairs
    /// @return uint Number of created pairs
    function allPairsLength() public view returns (uint256) {
        return allPairs.length;
    }

    /// @notice Get Antfarm Pairs addresses
    /// @param startIndex Index of the first pair to query
    /// @param numOfPairs Number of pairs to be queried
    /// @return pairs Addresses of created pairs
    /// @return newIndex New index for chained calls
    function getPairs(uint256 startIndex, uint256 numOfPairs)
        external
        view
        returns (address[] memory pairs, uint256 newIndex)
    {
        if (numOfPairs > allPairsLength() - startIndex) {
            numOfPairs = allPairsLength() - startIndex;
        }

        pairs = new address[](numOfPairs);
        for (uint256 i; i < numOfPairs; ++i) {
            pairs[i] = allPairs[startIndex + i];
        }

        newIndex = startIndex + numOfPairs;
    }

    /// @notice Get all possible fees
    /// @return uint16[8] List of possible fees
    function getPossibleFees() external view returns (uint16[8] memory) {
        return possibleFees;
    }

    /// @notice Create new Antfarm Pair
    /// @param tokenA token0 to be used for the new Antfarm Pair
    /// @param tokenB token1 to be used for the new Antfarm Pair
    /// @param fee Fee to be used in the new Antfarm Pair
    /// @return address The address of the deployed Antfarm Pair
    function createPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external returns (address) {
        uint16 feeIndex = validateFee(fee);
        if (tokenA == tokenB) revert IdenticalAddresses();
        address token0;
        address token1;
        if (tokenA == antfarmToken || tokenB == antfarmToken) {
            (token0, token1) = tokenA == antfarmToken
                ? (antfarmToken, tokenB)
                : (antfarmToken, tokenA);
            if (token1 == address(0)) revert ZeroAddress(); // antfarmToken can't be 0 but other could
            if (fee == 1000) revert ForbiddenFee();
        } else {
            (token0, token1) = tokenA < tokenB
                ? (tokenA, tokenB)
                : (tokenB, tokenA);
            if (token0 == address(0)) revert ZeroAddress();
        }
        if (getPair[token0][token1][fee] != address(0)) revert PairExists();

        address pair;
        bytes memory bytecode = token0 == antfarmToken
            ? type(AntfarmAtfPair).creationCode
            : type(AntfarmPair).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(token0, token1, fee, antfarmToken)
        );
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getPair[token0][token1][fee] = pair;
        getPair[token1][token0][fee] = pair;
        writeFee(token0, token1, feeIndex);
        allPairs.push(pair);

        token0 == antfarmToken
            ? IAntfarmAtfPair(pair).initialize(token0, token1, fee)
            : IAntfarmPair(pair).initialize(token0, token1, fee, antfarmToken);
        emit PairCreated(token0, token1, pair, fee, allPairs.length);
        return pair;
    }

    // updates the fee array for a pair with the fee amount in its index
    function writeFee(
        address token0,
        address token1,
        uint16 index
    ) internal {
        uint16[8] memory fees = feesForPair[token0][token1];
        fees[index] = possibleFees[index];
        feesForPair[token0][token1] = fees;
        feesForPair[token1][token0] = fees;
    }

    // check the fee provided is one of the available ones
    function validateFee(uint16 fee) internal view returns (uint16) {
        for (uint16 i; i < 8; ++i) {
            if (fee == possibleFees[i]) {
                return i;
            }
        }
        revert IncorrectFee();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/IAntfarmFactory.sol";
import "../interfaces/IAntfarmPair.sol";
import "../interfaces/IAntfarmAtfPair.sol";
import "../interfaces/IAntfarmOracle.sol";
import "../interfaces/IAntfarmToken.sol";
import "../libraries/math.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/TransferHelper.sol";
import "../utils/AntfarmPairErrors.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

/// @title Core contract for Antfarm
/// @notice Low-level contract to mint/burn/swap and claim
contract AntfarmPair is IAntfarmPair, ReentrancyGuard, Math {
    using UQ112x112 for uint224;

    /// @inheritdoc IAntfarmPairState
    address public immutable factory;

    /// @inheritdoc IAntfarmPairState
    address public token0;

    /// @inheritdoc IAntfarmPairState
    address public token1;

    /// @inheritdoc IAntfarmPairState
    uint16 public fee;

    /// @inheritdoc IAntfarmPairState
    uint256 public totalSupply;

    /// @inheritdoc IAntfarmPairState
    uint256 public antfarmTokenReserve;

    /// @inheritdoc IAntfarmPair
    address public antfarmToken;

    /// @inheritdoc IAntfarmPair
    address public antfarmOracle;

    uint112 private reserve0;
    uint112 private reserve1;

    // DIVIDEND VARIABLES
    uint256 private totalDividendPoints;
    uint256 private constant POINT_MULTIPLIER = 1 ether;

    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    struct Position {
        uint128 lp;
        uint256 dividend;
        uint256 lastDividendPoints;
    }

    mapping(address => mapping(uint256 => Position)) public positions;

    modifier updateDividend(address operator, uint256 positionId) {
        if (positions[operator][positionId].lp > 0) {
            uint256 owing = newDividends(
                operator,
                positionId,
                totalDividendPoints
            );
            if (owing > 0) {
                positions[operator][positionId].dividend += owing;
                positions[operator][positionId]
                    .lastDividendPoints = totalDividendPoints;
            }
        } else {
            positions[operator][positionId]
                .lastDividendPoints = totalDividendPoints;
        }
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _token0,
        address _token1,
        uint16 _fee,
        address _antfarmToken
    ) external {
        if (msg.sender != factory) revert SenderNotFactory();
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        antfarmToken = _antfarmToken;
    }

    /// @inheritdoc IAntfarmPairActions
    function mint(address to, uint256 positionId)
        external
        override
        nonReentrant
        updateDividend(to, positionId)
        returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 liquidity;

        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            totalSupply = MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }
        if (liquidity == 0) revert InsufficientLiquidityMinted();
        positions[to][positionId].lp += uint128(liquidity);
        totalSupply = totalSupply + liquidity;

        _update(balance0, balance1);
        if (_totalSupply == 0) {
            setOracleInstance();
        }

        emit Mint(to, amount0, amount1);
        return liquidity;
    }

    /// @inheritdoc IAntfarmPairActions
    function burn(
        address to,
        uint256 positionId,
        uint256 liquidity
    )
        external
        override
        nonReentrant
        updateDividend(msg.sender, positionId)
        returns (uint256, uint256)
    {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        if (positions[msg.sender][positionId].lp < liquidity) {
            revert InsufficientLiquidity();
        }

        positions[msg.sender][positionId].lp -= uint128(liquidity);

        if (liquidity == 0) revert InsufficientLiquidity();

        uint256 _totalSupply = totalSupply; // gas savings
        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;
        totalSupply = totalSupply - liquidity;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        TransferHelper.safeTransfer(_token0, to, amount0);
        TransferHelper.safeTransfer(_token1, to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1, to);
        return (amount0, amount1);
    }

    /// @inheritdoc IAntfarmPairActions
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external nonReentrant {
        if (amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }

        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1) {
            revert InsufficientLiquidity();
        }

        uint256 balance0;
        uint256 balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            if (to == _token0 || to == _token1) revert InvalidReceiver();
            if (amount0Out > 0)
                TransferHelper.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0)
                TransferHelper.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);

        uint256 feeToPay;

        feeToPay = getFees(amount0Out, amount0In, amount1Out, amount1In);
        if (feeToPay < MINIMUM_LIQUIDITY) revert SwapAmountTooLow();
        if (
            IERC20(antfarmToken).balanceOf(address(this)) -
                antfarmTokenReserve <
            feeToPay
        ) {
            revert InsufficientFee();
        }

        if (balance0 * balance1 < uint256(_reserve0) * _reserve1) revert K();
        _update(balance0, balance1);

        uint256 feeToDisburse = (feeToPay * 8500) / 10000;
        uint256 feeToBurn = feeToPay - feeToDisburse;

        _disburse(feeToDisburse);
        IAntfarmToken(antfarmToken).burn(feeToBurn);
    }

    /// @inheritdoc IAntfarmPairActions
    function claimDividend(address to, uint256 positionId)
        external
        override
        nonReentrant
        updateDividend(msg.sender, positionId)
        returns (uint256 claimAmount)
    {
        claimAmount = positions[msg.sender][positionId].dividend;
        if (claimAmount != 0) {
            positions[msg.sender][positionId].dividend = 0;
            antfarmTokenReserve -= claimAmount;
            TransferHelper.safeTransfer(antfarmToken, to, claimAmount);
        }
    }

    /// @inheritdoc IAntfarmPairActions
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        TransferHelper.safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)) - reserve0
        );
        TransferHelper.safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    /// @inheritdoc IAntfarmPairActions
    function sync() external nonReentrant {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    /// @inheritdoc IAntfarmPairDerivedState
    function getPositionLP(address operator, uint256 positionId)
        external
        view
        override
        returns (uint128)
    {
        return positions[operator][positionId].lp;
    }

    /// @inheritdoc IAntfarmPair
    function updateOracle() public {
        address actualOracle;
        uint112 maxReserve;
        if (antfarmOracle != address(0)) {
            actualOracle = IAntfarmOracle(antfarmOracle).pair();
            (maxReserve, , ) = IAntfarmAtfPair(actualOracle).getReserves();
        }

        address bestOracle = scanOracles(maxReserve);
        if (bestOracle == address(0)) revert NoOracleFound();
        if (bestOracle == antfarmOracle) revert NoBetterOracle();
        antfarmOracle = bestOracle;
    }

    /// @inheritdoc IAntfarmPairDerivedState
    function getReserves()
        public
        view
        override
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = 0;
    }

    /// @inheritdoc IAntfarmPair
    function getFees(
        uint256 amount0Out,
        uint256 amount0In,
        uint256 amount1Out,
        uint256 amount1In
    ) public view returns (uint256 feeToPay) {
        if (IAntfarmOracle(antfarmOracle).token1() == token0) {
            feeToPay = IAntfarmOracle(antfarmOracle).consult(
                token0,
                ((amount0In + amount0Out) * fee) / MINIMUM_LIQUIDITY
            );
        } else {
            feeToPay = IAntfarmOracle(antfarmOracle).consult(
                token1,
                ((amount1In + amount1Out) * fee) / MINIMUM_LIQUIDITY
            );
        }
    }

    /// @inheritdoc IAntfarmPairDerivedState
    function claimableDividends(address operator, uint256 positionId)
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 tempTotalDividendPoints = totalDividendPoints;

        uint256 newDividend = newDividends(
            operator,
            positionId,
            tempTotalDividendPoints
        );
        amount = positions[operator][positionId].dividend + newDividend;
    }

    /// @inheritdoc IAntfarmPair
    function scanOracles(uint112 maxReserve)
        public
        view
        override
        returns (address bestOracle)
    {
        address[2] memory tokens = [token0, token1];

        for (uint256 token; token < 2; ++token) {
            address pairAddress = IAntfarmFactory(factory).getPair(
                antfarmToken,
                tokens[token],
                uint16(10)
            );

            if (pairAddress == address(0)) {
                continue;
            }

            IAntfarmAtfPair pair = IAntfarmAtfPair(pairAddress);

            if (AntfarmOracle(pair.antfarmOracle()).firstUpdateCall()) {
                continue;
            }

            (uint112 _reserve0, , ) = pair.getReserves();

            if (_reserve0 >= maxReserve) {
                bestOracle = address(pair.antfarmOracle());
                maxReserve = _reserve0;
            }
        }
    }

    function newDividends(
        address operator,
        uint256 positionId,
        uint256 tempTotalDividendPoints
    ) internal view returns (uint256 amount) {
        uint256 newDividendPoints = tempTotalDividendPoints -
            positions[operator][positionId].lastDividendPoints;
        amount =
            (positions[operator][positionId].lp * newDividendPoints) /
            POINT_MULTIPLIER;
    }

    function setOracleInstance() internal {
        updateOracle();
        if (antfarmOracle == address(0)) {
            revert NoOracleFound();
        }
    }

    function _update(uint256 balance0, uint256 balance1) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) {
            revert BalanceOverflow();
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    function _disburse(uint256 amount) private {
        totalDividendPoints =
            totalDividendPoints +
            ((amount * POINT_MULTIPLIER) / (totalSupply - MINIMUM_LIQUIDITY));
        antfarmTokenReserve = antfarmTokenReserve + amount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/IAntfarmFactory.sol";
import "../interfaces/IAntfarmAtfPair.sol";
import "../interfaces/IAntfarmOracle.sol";
import "../interfaces/IAntfarmToken.sol";
import "../libraries/math.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/TransferHelper.sol";
import "../utils/AntfarmPairErrors.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

/// @title Core contract for Antfarm Pairs with ATF token
/// @notice Low-level contract to mint/burn/swap and claim
contract AntfarmAtfPair is IAntfarmAtfPair, ReentrancyGuard, Math {
    using UQ112x112 for uint224;

    /// @inheritdoc IAntfarmPairState
    address public immutable factory;

    /// @inheritdoc IAntfarmPairState
    address public token0;

    /// @inheritdoc IAntfarmPairState
    address public token1;

    /// @inheritdoc IAntfarmPairState
    uint16 public fee;

    /// @inheritdoc IAntfarmPairState
    uint256 public totalSupply;

    /// @inheritdoc IAntfarmAtfPair
    uint256 public price1CumulativeLast;

    /// @inheritdoc IAntfarmPairState
    uint256 public antfarmTokenReserve;

    /// @inheritdoc IAntfarmAtfPair
    address public antfarmOracle;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    // DIVIDEND VARIABLES
    uint256 private totalDividendPoints;
    uint256 private constant POINT_MULTIPLIER = 1 ether;

    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    struct Position {
        uint128 lp;
        uint256 dividend;
        uint256 lastDividendPoints;
    }

    mapping(address => mapping(uint256 => Position)) public positions;

    modifier updateDividend(address operator, uint256 positionId) {
        if (positions[operator][positionId].lp > 0) {
            uint256 owing = newDividends(
                operator,
                positionId,
                totalDividendPoints
            );
            if (owing > 0) {
                positions[operator][positionId].dividend += owing;
                positions[operator][positionId]
                    .lastDividendPoints = totalDividendPoints;
            }
        } else {
            positions[operator][positionId]
                .lastDividendPoints = totalDividendPoints;
        }
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _token0,
        address _token1,
        uint16 _fee
    ) external {
        if (msg.sender != factory) revert SenderNotFactory();
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
    }

    /// @inheritdoc IAntfarmPairActions
    function mint(address to, uint256 positionId)
        external
        override
        nonReentrant
        updateDividend(to, positionId)
        returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this)) -
            antfarmTokenReserve;
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 liquidity;

        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            totalSupply = MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }
        if (liquidity == 0) revert InsufficientLiquidityMinted();
        positions[to][positionId].lp += uint128(liquidity);
        totalSupply = totalSupply + liquidity;

        _update(balance0, balance1, _reserve0, _reserve1);
        if (_totalSupply == 0) {
            if (fee == 10) {
                setOracleInstance();
            }
        }
        emit Mint(to, amount0, amount1);
        return liquidity;
    }

    /// @inheritdoc IAntfarmPairActions
    function burn(
        address to,
        uint256 positionId,
        uint256 liquidity
    )
        external
        override
        nonReentrant
        updateDividend(msg.sender, positionId)
        returns (uint256, uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings

        uint256 balance0 = IERC20(token0).balanceOf(address(this)) -
            antfarmTokenReserve;
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (positions[msg.sender][positionId].lp < liquidity) {
            revert InsufficientLiquidity();
        }

        positions[msg.sender][positionId].lp -= uint128(liquidity);

        if (liquidity == 0) revert InsufficientLiquidity();

        uint256 _totalSupply = totalSupply; // gas savings
        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;
        totalSupply = totalSupply - liquidity;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        TransferHelper.safeTransfer(token0, to, amount0);
        TransferHelper.safeTransfer(token1, to, amount1);

        balance0 =
            IERC20(token0).balanceOf(address(this)) -
            antfarmTokenReserve;
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
        return (amount0, amount1);
    }

    /// @inheritdoc IAntfarmPairActions
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external nonReentrant {
        if (amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }

        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1) {
            revert InsufficientLiquidity();
        }

        uint256 balance0;
        uint256 balance1;
        address _token0 = token0;
        {
            address _token1 = token1;
            if (to == _token0 || to == _token1) revert InvalidReceiver();
            if (amount0Out > 0)
                TransferHelper.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0)
                TransferHelper.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            balance0 =
                IERC20(_token0).balanceOf(address(this)) -
                antfarmTokenReserve;
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);

        // MINIMUM_LIQUIDITY is used instead of 1000
        uint256 feeToPay = ((amount0In * fee) / (MINIMUM_LIQUIDITY + fee)) +
            ((amount0Out * fee) / (MINIMUM_LIQUIDITY - fee));
        if (feeToPay < MINIMUM_LIQUIDITY) revert SwapAmountTooLow();
        balance0 -= feeToPay;

        if (balance0 * balance1 < uint256(_reserve0) * _reserve1) revert K();
        _update(balance0, balance1, _reserve0, _reserve1);

        // only 1% pool have oracles
        if (fee == 10) {
            IAntfarmOracle(antfarmOracle).update(
                price1CumulativeLast,
                blockTimestampLast
            );
        }

        uint256 feeToDisburse = (feeToPay * 8500) / 10000;
        uint256 feeToBurn = feeToPay - feeToDisburse;

        _disburse(feeToDisburse);
        // burned to reduce totalSupply isntead of sending to addressZero
        IAntfarmToken(_token0).burn(feeToBurn);
    }

    /// @inheritdoc IAntfarmPairActions
    function claimDividend(address to, uint256 positionId)
        external
        override
        nonReentrant
        updateDividend(msg.sender, positionId)
        returns (uint256 claimAmount)
    {
        claimAmount = positions[msg.sender][positionId].dividend;
        if (claimAmount != 0) {
            positions[msg.sender][positionId].dividend = 0;
            antfarmTokenReserve -= claimAmount;
            TransferHelper.safeTransfer(token0, to, claimAmount);
        }
    }

    /// @inheritdoc IAntfarmPairActions
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        TransferHelper.safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)) -
                reserve0 -
                antfarmTokenReserve
        );
        TransferHelper.safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    /// @inheritdoc IAntfarmPairActions
    function sync() external nonReentrant {
        _update(
            IERC20(token0).balanceOf(address(this)) - antfarmTokenReserve,
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    /// @inheritdoc IAntfarmPairDerivedState
    function getPositionLP(address operator, uint256 positionId)
        external
        view
        override
        returns (uint128)
    {
        return positions[operator][positionId].lp;
    }

    /// @inheritdoc IAntfarmPairDerivedState
    function getReserves()
        public
        view
        override
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /// @inheritdoc IAntfarmPairDerivedState
    function claimableDividends(address operator, uint256 positionId)
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 tempTotalDividendPoints = totalDividendPoints;

        uint256 newDividend = newDividends(
            operator,
            positionId,
            tempTotalDividendPoints
        );
        amount = positions[operator][positionId].dividend + newDividend;
    }

    function newDividends(
        address operator,
        uint256 positionId,
        uint256 tempTotalDividendPoints
    ) internal view returns (uint256 amount) {
        uint256 newDividendPoints = tempTotalDividendPoints -
            positions[operator][positionId].lastDividendPoints;
        amount =
            (positions[operator][positionId].lp * newDividendPoints) /
            POINT_MULTIPLIER;
    }

    function setOracleInstance() internal {
        antfarmOracle = address(
            new AntfarmOracle(token1, price1CumulativeLast, blockTimestampLast)
        );
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) {
            revert BalanceOverflow();
        }
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed;

        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        }

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price1CumulativeLast =
                price1CumulativeLast +
                (uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                    timeElapsed);
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _disburse(uint256 amount) private {
        totalDividendPoints =
            totalDividendPoints +
            ((amount * POINT_MULTIPLIER) / (totalSupply - MINIMUM_LIQUIDITY));
        antfarmTokenReserve = antfarmTokenReserve + amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

error IdenticalAddresses();
error ZeroAddress();
error PairExists();
error IncorrectFee();
error ForbiddenFee();

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint16 fee,
        uint256 allPairsLength
    );

    function possibleFees(uint256) external view returns (uint16);

    function allPairs(uint256) external view returns (address);

    function antfarmToken() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external view returns (address pair);

    function feesForPair(
        address tokenA,
        address tokenB,
        uint256
    ) external view returns (uint16);

    function getFeesForPair(address tokenA, address tokenB)
        external
        view
        returns (uint16[8] memory fees);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IAntfarmBase.sol";

interface IAntfarmPair is IAntfarmBase {
    /// @notice Initialize the pair
    /// @dev Can only be called by the factory
    function initialize(
        address,
        address,
        uint16,
        address
    ) external;

    /// @notice The Antfarm token address
    /// @return address Address
    function antfarmToken() external view returns (address);

    /// @notice The Oracle instance used to compute swap's fees
    /// @return AntfarmOracle Oracle instance
    function antfarmOracle() external view returns (address);

    /// @notice Calcul fee to pay
    /// @param amount0Out The token0 amount going out of the pool
    /// @param amount0In The token0 amount going in the pool
    /// @param amount1Out The token1 amount going out of the pool
    /// @param amount1In The token1 amount going in the pool
    /// @return feeToPay Calculated fee to be paid
    function getFees(
        uint256 amount0Out,
        uint256 amount0In,
        uint256 amount1Out,
        uint256 amount1In
    ) external view returns (uint256 feeToPay);

    /// @notice Check for the best Oracle to use to perform fee calculation for a swap
    /// @dev Returns address(0) if no better oracle is found.
    /// @param maxReserve Actual oracle reserve0
    /// @return bestOracle Address from the best oracle found
    function scanOracles(uint112 maxReserve)
        external
        view
        returns (address bestOracle);

    /// @notice Update oracle for token
    /// @custom:usability Update the current Oracle with a more suitable one. Revert if the current Oracle is already the more suitable
    function updateOracle() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../antfarm/AntfarmOracle.sol";
import "./IAntfarmBase.sol";

interface IAntfarmAtfPair is IAntfarmBase {
    /// @notice Initialize the pair
    /// @dev Can only be called by the factory
    function initialize(
        address,
        address,
        uint16
    ) external;

    /// @notice The Oracle instance associated to the AntfarmPair
    /// @return AntfarmOracle Oracle instance
    function antfarmOracle() external view returns (address);

    /// @notice Average token0 price depending on the AntfarmOracle's period
    /// @return uint token0 Average price
    function price1CumulativeLast() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmOracle {
    function pair() external view returns (address);

    function token1() external view returns (address);

    function consult(address, uint256) external view returns (uint256);

    function update(uint256, uint32) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

error SenderNotFactory();
error InsufficientOutputAmount();
error InsufficientLiquidity();
error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InvalidReceiver();
error InsufficientInputAmount();
error InsufficientFee();
error K();
error SwapAmountTooLow();
error NoOracleFound();
error NoBetterOracle();
error BalanceOverflow();

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

// a library for performing various math operations

contract Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./pair/IAntfarmPairState.sol";
import "./pair/IAntfarmPairEvents.sol";
import "./pair/IAntfarmPairActions.sol";
import "./pair/IAntfarmPairDerivedState.sol";

interface IAntfarmBase is
    IAntfarmPairState,
    IAntfarmPairEvents,
    IAntfarmPairActions,
    IAntfarmPairDerivedState
{}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;
import "../IAntfarmToken.sol";

interface IAntfarmPairState {
    /// @notice The contract that deployed the AntfarmPair, which must adhere to the IAntfarmFactory interface
    /// @return address The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the AntfarmPair, sorted by address
    /// @return address The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the AntfarmPair, sorted by address
    /// @return address The token contract address
    function token1() external view returns (address);

    /// @notice Fee associated to the AntfarmPair instance
    /// @return uint16 Fee
    function fee() external view returns (uint16);

    /// @notice The LP tokens total circulating supply
    /// @return uint Total LP tokens
    function totalSupply() external view returns (uint256);

    /// @notice The AntFarmPair AntFarm's tokens cumulated fees
    /// @return uint Total Antfarm tokens
    function antfarmTokenReserve() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairEvents {
    /// @notice Emitted when a position's liquidity is removed
    /// @param sender The address that initiated the burn call
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    /// @param to The address to send token0 & token1
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that initiated the mint call
    /// @param amount0 Required token0 for the minted liquidity
    /// @param amount1 Required token1 for the minted liquidity
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call
    /// @param amount0In Amount of token0 sent to the pair
    /// @param amount1In Amount of token1 sent to the pair
    /// @param amount0Out Amount of token0 going out of the pair
    /// @param amount1Out Amount of token1 going out of the pair
    /// @param to Address to transfer the swapped amount
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @notice Emitted by the pool for any call to Sync function
    /// @param reserve0 reserve0 updated from the pair
    /// @param reserve1 reserve1 updated from the pair
    event Sync(uint112 reserve0, uint112 reserve1);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairActions {
    /// @notice Mint liquidity for a specific position
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param to The address to mint liquidity
    /// @param positionId The ID to store the position to allow multiple positions for a single address
    /// @return liquidity Minted liquidity
    function mint(address to, uint256 positionId)
        external
        returns (uint256 liquidity);

    /// @notice Burn liquidity from a specific position
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param to The address to return the liquidity to
    /// @param positionId The ID of the position to burn liquidity from
    /// @param liquidity Liquidity amount to be burned
    /// @return amount0 The token0 amount received from the liquidity burn
    /// @return amount1 The token1 amount received from the liquidity burn
    function burn(
        address to,
        uint256 liquidity,
        uint256 positionId
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap tokens
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param amount0Out token0 amount to be swapped
    /// @param amount1Out token1 amount to be swapped
    /// @param to The address to send the swapped tokens
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    /// @notice Force balances to match reserves
    /// @param to The address to send excessive tokens
    function skim(address to) external;

    /// @notice Force reserves to match balances
    function sync() external;

    /// @notice Claim dividends for a specific position
    /// @param to The address to receive claimed dividends
    /// @param positionId The ID of the position to claim
    /// @return claimedAmount The amount claimed
    function claimDividend(address to, uint256 positionId)
        external
        returns (uint256 claimedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairDerivedState {
    /// @notice Get position LP tokens
    /// @param operator Position owner
    /// @param positionId ID of the position
    /// @return uint128 LP tokens owned by the operator
    function getPositionLP(address operator, uint256 positionId)
        external
        view
        returns (uint128);

    /// @notice Get pair reserves
    /// @return reserve0 Reserve for token0
    /// @return reserve1 Reserve for token1
    /// @return blockTimestampLast Last block proceeded
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    /// @notice Get Dividend from a specific position
    /// @param operator The address used to get dividends
    /// @param positionId Specific position
    /// @return amount Dividends owned by the address
    function claimableDividends(address operator, uint256 positionId)
        external
        view
        returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../libraries/fixedpoint/FixedPoint.sol";

error InvalidToken();

/// @title Antfarm Oracle for AntfarmPair
/// @notice Fixed window oracle that recomputes the average price for the entire period once every period
contract AntfarmOracle {
    using FixedPoint for *;

    uint256 public constant PERIOD = 1 hours;

    address public token1;
    address public pair;

    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price1Average;

    bool public firstUpdateCall;

    constructor(
        address _token1,
        uint256 _price1CumulativeLast,
        uint32 _blockTimestampLast
    ) {
        token1 = _token1;
        pair = msg.sender;
        price1CumulativeLast = _price1CumulativeLast; // fetch the current accumulated price value (1 / 0)
        blockTimestampLast = _blockTimestampLast;
        firstUpdateCall = true;
    }

    /// @notice Average price update
    /// @param price1Cumulative Price cumulative for the associated AntfarmPair's token1
    /// @param blockTimestamp Last block timestamp for the associated AntfarmPair
    /// @dev Only usable by the associated AntfarmPair
    function update(uint256 price1Cumulative, uint32 blockTimestamp) external {
        require(msg.sender == pair);
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            // ensure that at least one full period has passed since the last update
            if (timeElapsed >= PERIOD || firstUpdateCall) {
                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                price1Average = FixedPoint.uq112x112(
                    uint224(
                        (price1Cumulative - price1CumulativeLast) / timeElapsed
                    )
                );
                price1CumulativeLast = price1Cumulative;
                blockTimestampLast = blockTimestamp;
                if (firstUpdateCall) {
                    firstUpdateCall = false;
                }
            }
        }
    }

    /// @notice Consult the average price for a given token
    /// @param token Price cumulative for the associated AntfarmPair's token
    /// @param amountIn The amount to get the value of
    /// @return amountOut Return the calculated amount (always return 0 before update has been called successfully for the first time)
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        if (token == token1) {
            amountOut = price1Average.mul(amountIn).decode144();
        } else {
            revert InvalidToken();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "./FullMath.sol";
import "./Babylonian.sol";
import "./BitMath.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint::mul: overflow");
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, "FixedPoint::muli: overflow");
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= type(uint112).max, "FixedPoint::muluq: upper overflow");

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, "FixedPoint::muluq: sum overflow");

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, "FixedPoint::divuq: division by zero");
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, "FixedPoint::divuq: overflow");
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, "FixedPoint::divuq: overflow");
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint::reciprocal: reciprocal of zero");
        require(self._x != 1, "FixedPoint::reciprocal: overflow");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.8.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (type(uint256).max - d + 1) & d;
        d /= pow2;
        l /= pow2;
        l += h * (((type(uint256).max - pow2 + 1) & pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, "FullMath: FULLDIV_OVERFLOW");
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint16).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}