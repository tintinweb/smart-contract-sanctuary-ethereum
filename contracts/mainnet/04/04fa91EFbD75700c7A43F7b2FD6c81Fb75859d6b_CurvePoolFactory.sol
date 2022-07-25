// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface ICurveBasePool {
    function initialize(
        address _config,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _curveSwap,
        address _zap,
        uint256[][] calldata _corrspondedCoins
    ) external;
}

interface ICurveMetaPool {
    function initialize(
        address _config,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _baseSwap,
        address _curveSwap,
        address _curveZap,
        address _baseToken,
        bool _isV2, // tusd,frax,busdv2,alusd,mim
        uint256[][] calldata _corrspondedCoins
    ) external;
}

contract CurvePoolFactory {
    address public owner;
    address public config;

    struct Data {
        uint256 tag;
        address pool;
    }

    uint256 public index;

    mapping(uint256 => Data) public pools;

    event CreatePool(address newClone);

    constructor(address _owner, address _config) {
        owner = _owner;
        config = _config;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "CurvePoolFactory: !authorized");

        owner = _owner;
    }

    function createBasePool(
        address _master,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _curveSwap,
        address _zap,
        uint256[][] calldata _corrspondedCoins
    ) external returns (address) {
        require(msg.sender == owner, "CurvePoolFactory: !authorized");

        address instance = Clones.clone(address(_master));

        ICurveBasePool(instance).initialize(config, _precisionIndent, _tokens, _curveSwap, _zap, _corrspondedCoins);

        emit CreatePool(instance);

        pools[++index] = Data(0, instance);

        return instance;
    }

    function createMetaPool(
        address _master,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _baseSwap,
        address _curveSwap,
        address _curveZap,
        address _baseToken,
        bool _isV2, // tusd,frax,busdv2,alusd,mim
        uint256[][] calldata _corrspondedCoins
    ) external returns (address) {
        require(msg.sender == owner, "CurvePoolFactory: !authorized");

        address instance = Clones.clone(address(_master));

        ICurveMetaPool(instance).initialize(
            config,
            _precisionIndent,
            _tokens,
            _baseSwap,
            _curveSwap,
            _curveZap,
            _baseToken,
            _isV2, // tusd,frax,busdv2,alusd,mim
            _corrspondedCoins
        );

        emit CreatePool(instance);

        pools[++index] = Data(1, instance);

        return instance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}