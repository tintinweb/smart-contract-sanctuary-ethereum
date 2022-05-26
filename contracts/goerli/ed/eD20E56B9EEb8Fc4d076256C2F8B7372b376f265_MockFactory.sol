//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IRegistryClient.sol";
import "./MockPair.sol";

contract MockFactory {
    address public immutable registry;
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeToSetter, address _registry) {
        feeToSetter = _feeToSetter;
        registry = _registry;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS"); // single check is sufficient

        //---------------------------TokenScope----------------------------------//
        require(
            IRegistryClient(registry).tokenIsValidERC20(tokenA),
            "Token A is not a valid ERC20 implementation"
        );
        require(
            IRegistryClient(registry).tokenIsValidERC20(tokenB),
            "Token B is not a valid ERC20 implementation"
        );
        //---------------------------TokenScope----------------------------------//

        bytes memory bytecode = type(MockPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        MockPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

pragma solidity ^0.8.0;

interface IRegistryClient {
    function tokenIsRegistered(address _token) external view returns (bool);

    function tokenIsValidERC20(address _token) external view returns (bool);

    function factsAreValidated(address _token, uint8[] calldata _facts)
        external
        view
        returns (bool);

    function factSetIsValidated(address _token, uint256 _factSet)
        external
        view
        returns (bool);

    function factsToFactSet(uint8[] calldata _facts)
        external
        pure
        returns (uint256 factSet);

    function factSetToFacts(uint256 _factSet)
        external
        pure
        returns (uint8[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title  MockPair
/// @notice Mock contract to showcase TokenScope features

contract MockPair {
    constructor() {}

    function initialize(address token1, address token2) public {}
}