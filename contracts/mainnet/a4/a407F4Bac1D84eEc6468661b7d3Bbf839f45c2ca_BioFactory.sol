pragma solidity 0.8.16;
// SPDX-License-Identifier: MIT

import "./Pair.sol";

interface IBioPair {
    function initialize(address, address, address) external;
}

contract BioFactory {

    bytes32 public INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(BioPair).creationCode));

    address public feeTo;
    address public feeToSetter;
    address public BIONIC;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _BIONIC) {
        feeToSetter = _feeToSetter;
        BIONIC = _BIONIC;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Bio: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Bio: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Bio: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(BioPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IBioPair(pair).initialize(token0, token1, BIONIC);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Bio: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Bio: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setNewPairCode(bytes32 newCreationCode) external{
        require(msg.sender == feeToSetter, 'Bio: FORBIDDEN');
        INIT_CODE_PAIR_HASH = newCreationCode;
    }

    function setBionicAddress(address newAddr) external {
        require(msg.sender == feeToSetter, 'Bio: FORBIDDEN');
        BIONIC = newAddr;
    }
}