// SPDX-License-Identifier: WISE

pragma solidity ^0.8.13;

import "./LiquidTransfer.sol";
import "./AccessControl.sol";

interface ILiquidPool {
    function initialize(
        address _poolToken,
        address[] memory _nftAddresses,
        address _multisig,
        uint256[] memory _maxTokensPerNft,
        uint256 _multiplicationFactor,  //Determine how quickly the interest rate changes with changes to utilization and resonanzFactor
        uint256 _maxCollatFactor,       //Maximal factor every NFT can be collateralized in this pool
        bytes32[] memory _merkleRoots,  //The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        string[] memory _ipfsURL,
        string memory _tokenName,       //Name for erc20 representing shares of this pool
        string memory _tokenSymbol,      //Symbol for erc20 representing shares of this pool
        bool _isExpandable
    )
    external;
}

interface ILiquidRouter {
    function registerPool(
        address _newPool
    )
    external;
}

/**
 * @dev LiquidFactory: Factory is responsible for deploying new LiquidPools.
 * We use solidity assembly here to directly copy the bytes of a target contract into a new contract
 */
contract PoolFactory is LiquidTransfer, AccessControl {

    event PoolCreated(
        address indexed pool,
        address indexed token
    );

    //Contract that all pools are cloned from
    address public defaultPoolTarget;

    //Liquid router that can call into any pool
    address public router;

    //Number of pools created, used in salt for contract address
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

    /**
     * @dev Set the address for the LiquidRouter, factory makes call to register pools with router
     */
    function updateRouter(
        address _newRouter
    )
        external
        onlyWorker
    {
        router = _newRouter;
    }

    /**
     * @dev Change the default target contract. Only mutlisig or worker address can do this.
     */
    function updateDefaultPoolTarget(
        address _newDefaultTarget
    )
        external
        onlyMultisig
    {
        defaultPoolTarget = _newDefaultTarget;
    }

    /**
    * @dev Clone the implemenation for a token into a new contract.
     * Call into initialize for the locker to begin the LiquidNFT loan process.
     * Transfer the NFT the user wants use for the loan into the locker.
     */
    function createLiquidPool(
        address _fungibleTokenAddress,  //Address of the erc20 token used for borrowing
        address[] memory _nftAddresses,
        uint256[] memory _maxTokensPerNft,
        uint256 _multiplicationFactor,  //Determine how quickly the interest rate changes with changes to utilization and resonanzFactor
        uint256 _maxCollatFactor,       //Maximal factor every NFT can be collateralized in this pool
        bytes32[] memory _merkleRoots,  //The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        string[] memory _ipfsURLs,
        string memory _tokenName,       //Name for erc20 representing shares of this pool
        string memory _tokenSymbol,      //Symbol for erc20 representing shares of this pool
        bool _isExpandable
    )
        external
        onlyWorker
        returns (address poolAddress)
    {
        poolAddress = _generatePool(
            _fungibleTokenAddress
        );

        ILiquidPool(poolAddress).initialize(
            _fungibleTokenAddress,
            _nftAddresses,
            multisig,
            _maxTokensPerNft,
            _multiplicationFactor,
            _maxCollatFactor,
            _merkleRoots,
            _ipfsURLs,
            _tokenName,
            _tokenSymbol,
            _isExpandable
        );

        ILiquidRouter(router).registerPool(poolAddress);

        emit PoolCreated(poolAddress, _fungibleTokenAddress);
    }

    /**
     * @dev Clone the byte code from one contract into a new contract. Uses solidity assembly.
     * This is a lot cheaper in gas than deploying a new contract.
     */
    function _generatePool(
        address _fungibleAddress
    )
        internal
        returns (address poolAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                poolCount++,
                _fungibleAddress
            )
        );

        bytes20 targetBytes = bytes20( defaultPoolTarget );

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

            poolAddress := create2(0, clone, 0x37, salt)
        }
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