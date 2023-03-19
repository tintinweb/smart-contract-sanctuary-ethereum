// SPDX-License-Identifier: BCOM

pragma solidity =0.8.14;

import "./ISwapsPair.sol";
import "./SwapsPair.sol";

contract SwapsFactory {

    address public feeTo;
    address public feeToSetter;
    address public immutable cloneTarget;
    address constant ZERO_ADDRESS = address(0);

    address[] public allPairs;

    mapping(address => mapping(address => address)) public getPair;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(
        address _feeToSetter
    ) {
        if (_feeToSetter == ZERO_ADDRESS) {
            revert("SwapsFactory: INVALID_INPUT");
        }

        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter;

        bytes32 salt;
        address pair;

        bytes memory bytecode = type(SwapsPair).creationCode;

        assembly {
            pair := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        cloneTarget = pair;
    }

    function allPairsLength()
        external
        view
        returns (uint256)
    {
        return allPairs.length;
    }

    function createPair(
        address _tokenA,
        address _tokenB
    )
        external
        returns (address pair)
    {
        require(
            _tokenA != _tokenB,
            "SwapsFactory: IDENTICAL"
        );

        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        require(
            token0 != ZERO_ADDRESS,
            "SwapsFactory: ZERO_ADDRESS"
        );

        require(
            getPair[token0][token1] == ZERO_ADDRESS,
            "SwapsFactory: PAIR_ALREADY_EXISTS"
        );

        bytes32 salt = keccak256(
            abi.encodePacked(
                token0,
                token1
            )
        );

        bytes20 targetBytes = bytes20(
            cloneTarget
        );

        assembly {

            let clone := mload(0x40)

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(
                add(clone, 0x14),
                targetBytes
            )

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            pair := create2(0, clone, 0x37, salt)
        }

        ISwapsPair(pair).initialize(
            token0,
            token1
        );

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(
            token0,
            token1,
            pair,
            allPairs.length
        );
    }

    function setFeeTo(
        address _feeTo
    )
        external
    {
        require(
            msg.sender == feeToSetter,
            "SwapsFactory: FORBIDDEN"
        );

        require(
            _feeTo != ZERO_ADDRESS,
            'SwapsFactory: ZERO_ADDRESS'
        );

        feeTo = _feeTo;
    }

    function setFeeToSetter(
        address _feeToSetter
    )
        external
    {
        require(
            msg.sender == feeToSetter,
            "SwapsFactory: FORBIDDEN"
        );

        require(
            _feeToSetter != ZERO_ADDRESS,
            'SwapsFactory: ZERO_ADDRESS'
        );

        feeToSetter = _feeToSetter;
    }
}

contract FactoryCodeCheck {

    function factoryCodeHash()
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            type(SwapsFactory).creationCode
        );
    }

    function pairCodeHash()
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            type(SwapsPair).creationCode
        );
    }
}