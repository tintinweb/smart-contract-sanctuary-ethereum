// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import './IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {

    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    uint public override totalFeeTopCoin;
    uint public override alphaTopCoin;
    uint public override betaTopCoin;
    uint public override totalFeeRegular;
    uint public override alphaRegular;
    uint public override betaRegular;

    // topCoins should hold true for WETH, WBTC, DAI, USDT, USDC
    mapping(address => bool) public override topCoins;
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event PairFeeUpdated(address indexed user, address indexed pair, uint _totalFee, uint _alpha, uint _beta);
    event FeeUpdated(string indexed which, address indexed user, uint _totalFee, uint _alpha, uint _beta);
    event SetAddress(string indexed which, address indexed user, address newAddr);
    event TopCoinUpdated(address indexed user, address indexed coinAddress, bool status);


    modifier onlyFeeToSetter() {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        _;
    }

    constructor(address _feeToSetter, address[] memory coinAddress) public {
        feeToSetter = _feeToSetter;
        uint256 len = coinAddress.length;
        for (uint256 i = 0; i < len; i++) {
            topCoins[coinAddress[i]] = true;
        }
        totalFeeTopCoin = 3;
        alphaTopCoin = 1;
        betaTopCoin = 3;

        totalFeeRegular = 3;
        alphaRegular = 1;
        betaRegular = 6;
    }

    // totalFee: total fee in BIPS levied on a swap depends
    // alpha: numerator for the fraction of protocol fee, that is reserved for TreasureFinder
    // beta: denominator for the fraction of protocol fee, that is reserved for TreasureFinder
    //
    // Returns totalFee, alpha, beta
    function getFeeInfo(address token0, address token1) internal view returns (uint, uint, uint) {
        if (topCoins[token0]== true || topCoins[token1]== true) {
            return (totalFeeTopCoin, alphaTopCoin, betaTopCoin);
        }
        return (totalFeeRegular, alphaRegular, betaRegular);
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        (uint totalFeePerThousand, uint alpha, uint beta) = getFeeInfo(token0, token1);
        UniswapV2Pair(pair).initialize(token0, token1, totalFeePerThousand, alpha, beta);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override onlyFeeToSetter {
        feeTo = _feeTo;
        emit SetAddress("FeeTo", msg.sender, _feeTo);
    }

    function setMigrator(address _migrator) external override onlyFeeToSetter {
        migrator = _migrator;
        emit SetAddress("Migrator", msg.sender, _migrator);
    }

    function setFeeToSetter(address _feeToSetter) external override onlyFeeToSetter {
        feeToSetter = _feeToSetter;
        emit SetAddress("FeeToSetter", msg.sender, _feeToSetter);
    }

    function setTopCoin(address _coinAddress, bool _status) external onlyFeeToSetter {
        topCoins[_coinAddress] = _status;
        emit TopCoinUpdated(msg.sender, _coinAddress, _status);
    }

    function setTopCoinFee(uint _totalFee, uint _alpha, uint _beta) external onlyFeeToSetter {
        require(_alpha < _beta, 'UniswapV2: IMPROPER FRACTION');
        totalFeeTopCoin = _totalFee;
        alphaTopCoin = _alpha;
        betaTopCoin = _beta;
        emit FeeUpdated("TopCoin", msg.sender, _totalFee, _alpha, _beta);
    }

    function setRegularCoinFee(uint _totalFee, uint _alpha, uint _beta) external onlyFeeToSetter {
        require(_alpha < _beta, 'UniswapV2: IMPROPER FRACTION');
        totalFeeRegular = _totalFee;
        alphaRegular = _alpha;
        betaRegular = _beta;
        emit FeeUpdated("RegularCoin", msg.sender, _totalFee, _alpha, _beta);
    }

    function updatePairFee(address token0, address token1, uint _totalFee, uint _alpha, uint _beta) external onlyFeeToSetter {
        require(_alpha < _beta, 'UniswapV2: IMPROPER FRACTION');
        address pair = getPair[token0][token1];
        require(pair != address(0), 'UniswapV2: PAIR_DOES_NOT_EXIST');
        UniswapV2Pair(pair).updateFee(_totalFee, _alpha, _beta);
        emit PairFeeUpdated(msg.sender, pair, _totalFee, _alpha, _beta);
    }

}