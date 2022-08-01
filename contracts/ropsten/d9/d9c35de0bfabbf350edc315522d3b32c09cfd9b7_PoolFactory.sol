// SPDX-License-Identifier: WISE

pragma solidity =0.8.13;

import "./ILiquidInit.sol";
import "./ILiquidRouter.sol";
import "./AccessControl.sol";

/**
 * @dev LiquidFactory: Factory is responsible for deploying new LiquidPools.
 */
contract PoolFactory is AccessControl {

    // Contract that all pools are cloned from
    address public defaultPoolTarget;

    // Liquid router that can call into any pool
    address public router;

    // Number of pools created, used in salt for contract address
    uint256 public poolCount;

    /**
     * @dev Set default pool target and set router if router already exists
     */
    constructor(
        address _defaultPoolTarget,
        address _router
    ) {
        defaultPoolTarget = _defaultPoolTarget;
        router = _router;
    }

    event PoolCreated(
        address indexed pool,
        address indexed token
    );

    /**
     * @dev Set the address for the LiquidRouter, factory makes call to register pools with router
     */
    function updateRouter(
        address _newRouter
    )
        external
        onlyMultisig
    {
        router = _newRouter;
    }

    /**
     * @dev Change the default target contract. Only mutlisig address can do this.
     */
    function updateDefaultPoolTarget(
        address _newDefaultTarget
    )
        external
        onlyMultisig
    {
        defaultPoolTarget = _newDefaultTarget;
    }

    function createLiquidPool(
        address _poolTokenAddress,
        uint256 _multiplicationFactor,
        uint256 _maxCollateralFactor,
        address[] memory _nftAddresses,
        bytes32[] memory _merkleRoots,
        string[] memory _ipfsURLs,
        string memory _tokenName,
        string memory _tokenSymbol,
        bool _isExpandable
    )
        external
        onlyWorker
        returns (address poolAddress)
    {
        poolAddress = _generatePool(
            _poolTokenAddress
        );

        ILiquidInit(poolAddress).initialize(
            _poolTokenAddress,
            multisig,
            _multiplicationFactor,
            _maxCollateralFactor,
            _nftAddresses,
            _merkleRoots,
            _ipfsURLs,
            _tokenName,
            _tokenSymbol,
            _isExpandable
        );

        ILiquidRouter(router).addLiquidPool(
            poolAddress
        );

        emit PoolCreated(
            poolAddress,
            _poolTokenAddress
        );
    }

    function _generatePool(
        address _poolAddress
    )
        internal
        returns (address poolAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                poolCount++,
                _poolAddress
            )
        );

        bytes20 targetBytes = bytes20(
            defaultPoolTarget
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

            poolAddress := create2(
                0,
                clone,
                0x37,
                salt
            )
        }
    }

    /**
    * @dev Unregisters a pool through the router which requires the factory as caller.
     */
    function removeLiquidPool(
        address _pool
    )
        onlyMultisig
        external
    {
        ILiquidRouter(router).removeLiquidPool(
            _pool
        );
    }

    /**
    * @dev Pre-compute what address a future pool will exist at.
     */
    function predictPoolAddress(
        uint256 _index,
        address _erc20Contract,
        address _factory,
        address _implementation
    )
        public
        pure
        returns (address predicted)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                _index,
                _erc20Contract
            )
        );

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, _factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }
}