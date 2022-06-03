/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity =0.6.12;
// SPDX-License-Identifier: GPL-3.0

contract TestJoePair {
    address sender;
    uint256 amount0In;
    uint256 amount1In;
    uint256 amount0Out;
    uint256 amount1Out;
    address to;

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function setSwapArgs(
        address _sender,
        uint256 _amount0In,
        uint256 _amount1In,
        uint256 _amount0Out,
        uint256 _amount1Out,
        address _to
    ) external {
        sender = _sender;
        amount0In = _amount0In;
        amount1In = _amount1In;
        amount0Out = _amount0Out;
        amount1Out = _amount1Out;
        to = _to;
    }

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Joe: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function emitSwap() external {
        emit Swap(
            sender,
            amount0In,
            amount1In,
            amount0Out,
            amount1Out,
            to
        );
    }

    function setTokens(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
    }

    function getReserves()
        public
        view
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
}

contract TestJoeFactory {

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "Joe: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Joe: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Joe: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(TestJoePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        TestJoePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

}