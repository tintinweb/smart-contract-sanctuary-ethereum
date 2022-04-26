// SPDX-License-Identifier: WISE

pragma solidity ^0.8.13;

import "./LiquidTransfer.sol";
import "./AccessControl.sol";

interface ILiquidPool {
    function initialize(
        address _fungibleTokenAddress,
        address _NFTAddress,
        address _multisig,
        uint256 _maxTokensPerNft,
        uint256 _multiplicationFactor,
        uint256 _maxCollatFactor,
        bytes32 _merkleRoot,
        string memory _ipfsURL,
        string memory _tokenName,
        string memory _tokenSymbol
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

    address public defaultPoolTarget;

    address public router;

    uint256 public poolCount;

    mapping(address => bool) public pools;

    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    /**
     * @dev Set parameters and precompute some locker addresses.
     */
    constructor(
        address _defaultPoolTarget,
        address _router
    ) {
        defaultPoolTarget = _defaultPoolTarget;
        router = _router;
    }

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
        onlyWorker
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
        address _NFTAddress,            //Nft collection contract address to be borrowed against
        uint256 _maxTokensPerNft,      //If the merkle root is empty, this value will be used for the amount to borrow for all tokens
        uint256 _multiplicationFactor,  //Determine how quickly the interest rate changes with changes to utilization and resonanzFactor
        uint256 _maxCollatFactor,       //Maximal factor every NFT can be collateralized in this pool
        bytes32 _merkleRoot,            //The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        string memory _ipfsURL,
        string memory _tokenName,       //Name for erc20 representing shares of this pool
        string memory _tokenSymbol      //Symbol for erc20 representing shares of this pool
    )
        external
        returns (address poolAddress)
    {
        poolAddress = _generatePool(
            _fungibleTokenAddress,
            _NFTAddress
        );

        ILiquidPool(poolAddress).initialize(
            _fungibleTokenAddress,
            _NFTAddress,
            msg.sender,
            _maxTokensPerNft,
            _multiplicationFactor,
            _maxCollatFactor,
            _merkleRoot,
            _ipfsURL,
            _tokenName,
            _tokenSymbol
        );

        ILiquidRouter(router).registerPool(poolAddress);
    }

    /**
     * @dev Clone the byte code from one contract into a new contract. Uses solidity assembly.
     * This is a lot cheaper in gas than deploying a new contract.
     */
    function _generatePool(
        address _fungibleAddress,
        address _NFTAddress
    )
        internal
        returns (address poolAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                poolCount++,
                _fungibleAddress,
                _NFTAddress
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

        if (pools[poolAddress] == false) {
            pools[poolAddress] = true;
        }
    }

    /**
    * @dev Pre-compute what address a future pool will exist at.
     */
    function predictPoolAddress(
        uint256 _index,
        address _erc20Contract,
        address _NFTContract,
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
                _erc20Contract,
                _NFTContract
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

    /**
     * @dev Call ERC20 transferFrom and then check the returned bool for success.
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
        data.length == 0 || abi.decode(
            data, (bool)
        )
        ),
            'LiquidFactory: TRANSFER_FROM_FAILED'
        );
    }
}