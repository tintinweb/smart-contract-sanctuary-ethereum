// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

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
    address public routerAddress;

    // Number of pools created, used in salt for contract address
    uint256 public poolCount;

    /**
     * @dev Set default pool target and set router if router already exists
     */
    constructor(
        address _defaultPoolTarget,
        address _routerAddress
    ) {
        defaultPoolTarget = _defaultPoolTarget;
        routerAddress = _routerAddress;
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
        routerAddress = _newRouter;
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

        uint8 tokenDecimals = IERC20(
            _poolTokenAddress
        ).decimals();

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
            tokenDecimals,
            _isExpandable
        );

        ILiquidRouter(routerAddress).addLiquidPool(
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

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

interface ILiquidRouter {

    function addLiquidPool(
        address _poolAddress
    )
        external;
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

interface ILiquidInit {

    function initialize(
        address _poolToken,
        // Address of our multisignature wallet
        address _multisig,
        // Determine how quickly the interest rate changes with changes to utilization and resonanceFactor
        uint256 _multiplicationFactor,
        // Maximal factor every NFT can be collateralized in this pool
        uint256 _maxCollateralFactor,
        // Address of the NFT contract
        address[] memory _nftAddresses,
        // The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        bytes32[] memory _merkleRoots,
         // Where you can lookup the details of the data used in merkle tree
        string[] memory _ipfsURL,
        // Name for erc20 representing shares of this pool
        string memory _tokenName,
        // Symbol for erc20 representing shares of this pool
        string memory _tokenSymbol,
        // Decimals for erc20 representing shares of this pool
        uint8 _tokenDecimals,
        // Should we allot to add more collections to the pool
        bool _isExpandable
    )
        external;
}

interface IERC20 {

    function decimals()
        external
        returns (uint8);
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract AccessControl {

    address public multisig;

    mapping(address => bool) public workers;

    event MultisigUpdated(
        address newMultisig
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    /**
     * @dev set the msg.sender as multisig, set msg.sender as worker
     */
    constructor() {
        workers[msg.sender] = true;
        _updateMultisig(
            msg.sender
        );
    }

    /**
     * @dev Revert if msg.sender if not multisig
     */
    modifier onlyMultisig() {
        require(
            msg.sender == multisig,
            "AccessControl: NOT_MULTISIG"
        );
        _;
    }

    /**
     * @dev require that sender is authorized in the worker mapping
     */
    modifier onlyWorker() {
        require(
            workers[msg.sender] == true,
            "AccessControl: NOT_WORKER"
        );
        _;
    }

    /**
     * @dev Transfer Multisig permission
     * Call internal function that does the work
     */
    function updateMultisig(
        address _newMultisig
    )
        external
        onlyMultisig
    {
        _updateMultisig(
            _newMultisig
        );
    }

    /**
     * @dev Internal function that handles the logic of updating the multisig
     */
    function _updateMultisig(
        address _newMultisig
    )
        internal
    {
        multisig = _newMultisig;

        emit MultisigUpdated(
            _newMultisig
        );
    }

    /**
     * @dev Add a worker address to the system. Set the bool for the worker to true
     * Only multisig can do this
     */
    function addWorker(
        address _newWorker
    )
        external
        onlyMultisig
    {
        workers[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    /**
    * @dev Remove a worker address from the system. Set the bool for the worker to false
     * Only multisig can do this
     */
    function removeWorker(
        address _worker
    )
        external
        onlyMultisig
    {
        workers[_worker] = false;

        emit WorkerRemoved(
            _worker
        );
    }
}