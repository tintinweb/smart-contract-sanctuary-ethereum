// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

import "./ILiquidPool.sol";
import "./RouterEvents.sol";
import "./AccessControl.sol";
import "./LiquidTransfer.sol";

contract LiquidRouter is LiquidTransfer, AccessControl, RouterEvents {

    address public constant ZERO_ADDRESS = address(0x0);

    // Factory contract that clones liquid pools
    address public factoryAddress;

    // Official pools that are added to the router
    mapping(address => bool) public registeredPools;

    // Function can only be called by factory address
    modifier onlyFactory() {
        require(
            msg.sender == factoryAddress,
            'LiquidRouter: NOT_FACTORY'
        );
        _;
    }

    modifier onlyKnownPools(
        address _pool
    ) {
        require(
            registeredPools[_pool] == true,
            "LiquidRouter: UNKNOWN_POOL"
        );
        _;
    }

    /**
     * @dev Set the address of the factory, and permission addresses
     */
    constructor(
        address _factoryAddress
    ) {
        factoryAddress = _factoryAddress;
    }

    /**
     * @dev Changes the address which receives fees deonominated in shares */
    function changeFeeDestinationAddress(
        address _newFeeDestinationAddress,
        address _pool
    )
        public
        onlyMultisig
        onlyKnownPools(_pool)
    {
        ILiquidPool(_pool).changeFeeDestinationAddress(_newFeeDestinationAddress);
    }

    /**
     * @dev Changes the address which receives fees deonominated in shares bulk */
    function changeFeeDestinationAddressBulk(
        address[] calldata _newFeeDestinationAddress,
        address[] calldata _pools
    )
        external
    {
        for (uint64 i = 0; i < _pools.length; i++) {

            changeFeeDestinationAddress(
                _newFeeDestinationAddress[i],
                _pools[i]
            );

        }
    }

    /**
     * @dev Set the address of the factory. Only master address can do this.
     * Since either the router or factory must be deployed first one or the either must update their
     * knowledge of where the other is afterwards
     */
    function updateFactory(
        address _newAddress
    )
        external
        onlyMultisig
    {
        address oldAddress = factoryAddress;
        factoryAddress = _newAddress;

        emit FactoryUpdated(
            oldAddress,
            _newAddress,
            multisig,
            block.timestamp
        );
    }

    /**
     * @dev Register an address as officially recognized pool
     */
    function addLiquidPool(
        address _pool
    )
        onlyFactory
        external
    {
        registeredPools[_pool] = true;

        emit LiquidPoolRegistered(
            _pool,
            block.timestamp
        );
    }

    /**
     * @dev Call the depositFundsRouter function of a specific pool.
     * Also handle the transferring of tokens here, only have to approve router
     * Check that pool is registered
     */
    function depositFunds(
        uint256 _amount,
        address _pool
    )
        public
        onlyKnownPools(_pool)
    {
        uint256 shares = ILiquidPool(_pool).depositFunds(
            _amount,
            msg.sender
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            _amount
        );

        emit FundsDeposited(
            _pool,
            msg.sender,
            _amount,
            shares,
            block.timestamp
        );
    }

    function withdrawFunds(
        uint256 _shares,
        address _pool
    )
        public
        onlyKnownPools(_pool)
    {
        uint256 withdrawAmount = ILiquidPool(_pool).withdrawFunds(
            _shares,
            msg.sender
        );

        emit FundsWithdrawn(
            _pool,
            msg.sender,
            withdrawAmount,
            _shares,
            block.timestamp
        );
    }

    /**
     * @dev moves funds as lender from one
     registered pool to another with requirement being
     same poolToken
    */
    function moveFunds(
        uint256 _shares,
        address _poolToExit,
        address _poolToEnter
    )
        external
    {
        require(
            ILiquidPool(_poolToExit).poolToken() ==
            ILiquidPool(_poolToEnter).poolToken(),
            "LiquidRouter: TOKENS_MISMATCH"
        );

        uint256 amountToDeposit = ILiquidPool(
            _poolToExit
        ).calculateWithdrawAmount(
            _shares
        );

        withdrawFunds(
            _shares,
            _poolToExit
        );

        depositFunds(
            amountToDeposit,
            _poolToEnter
        );
    }

    /**
     * @dev Call the borrowFunds function of a specific pool.
     * Also handle the transferring of tokens here, only have to approve router
     * Check that pool is registered
     */
    function borrowFunds(
        uint256 _borrowAmount,
        uint256 _tokenId,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _pool,
        address _nftAddress
    )
        external
        onlyKnownPools(_pool)
    {
        _transferFromNFT(
            msg.sender,
            _pool,
            _nftAddress,
            _tokenId
        );

        ILiquidPool(_pool).borrowFunds(
            _borrowAmount,
            _tokenId,
            _merkleIndex,
            _merkleProof,
            _merklePrice,
            msg.sender,
            _nftAddress
        );

        emit FundsBorrowed(
            _pool,
            _nftAddress,
            msg.sender,
            _tokenId,
            _borrowAmount,
            block.timestamp
        );
    }

    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _tokenId,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _pool,
        address _nftAddress
    )
        external
        onlyKnownPools(_pool)
    {
        uint256 transferAmount = ILiquidPool(_pool).paybackFunds(
            _principalPayoff,
            _tokenId,
            _merkleIndex,
            _merkleProof,
            _merklePrice,
            _nftAddress
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            transferAmount
        );

        emit FundsReturned(
            _pool,
            _nftAddress,
            ILiquidPool(_pool).loanOwner(
                _nftAddress,
                _tokenId
            ),
            transferAmount,
            _tokenId,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract RouterEvents {

    event FundsDeposited(
        address indexed pool,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed pool,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed pool,
        address indexed nftAddress,
        address indexed borrower,
        uint256 tokenID,
        uint256 amount,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed pool,
        address indexed nftAddress,
        address indexed tokenOwner,
        uint256 transferAmount,
        uint256 tokenID,
        uint256 timestamp
    );

    event FactoryUpdated(
        address indexed oldAddress,
        address indexed newAddress,
        address multisig,
        uint256 timestamp
    );

    event LiquidPoolRegistered(
        address indexed liquidPool,
        uint256 timestamp
    );

}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract LiquidTransfer {

    /* @dev
    * Checks if contract is nonstandard, does transfer according to contract implementation
    */
    function _transferNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data = abi.encodeWithSignature(
            'safeTransferFrom(address,address,uint256)',
            _from,
            _to,
            _tokenId
        );

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            'LiquidTransfer: NFT_TRANSFER_FAILED'
        );
    }

    /* @dev
    * Checks if contract is nonstandard, does transferFrom according to contract implementation
    */
    function _transferFromNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data = abi.encodeWithSignature(
            'safeTransferFrom(address,address,uint256)',
            _from,
            _to,
            _tokenId
        );

        (bool success, bytes memory resultData) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            string(resultData)
        );
    }

    /**
     * @dev encoding for transfer
     */
    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for transferFrom
     */
    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for balanceOf
     */
    bytes4 private constant BALANCE_OF = bytes4(
        keccak256(
            bytes(
                'balanceOf(address)'
            )
        )
    );

    /**
     * @dev does an erc20 transfer then check for success
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))),
            'LiquidTransfer: TRANSFER_FAILED'
        );
    }

    /**
     * @dev does an erc20 transferFrom then check for success
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
            success && (data.length == 0 || abi.decode(data, (bool))),
            'LiquidTransfer: TRANSFER_FROM_FAILED'
        );
    }

    /**
     * @dev does an erc20 balanceOf then check for success
     */
    function _safeBalance(
        address _token,
        address _owner
    )
        internal
        returns (uint256)
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                BALANCE_OF,
                _owner
            )
        );

        if (success == false) return 0;

        return abi.decode(
            data,
            (uint256)
        );
    }

    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(
            _operator,
            _from,
            _tokenId,
            _data
        );

        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

interface ILiquidPool {

    function depositFunds(
        uint256 _amount,
        address _depositor
    )
        external
        returns (uint256);

    function withdrawFunds(
        uint256 _shares,
        address _user
    )
        external
        returns (uint256);

    function borrowFunds(
        uint256 _tokenAmountToBorrow,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _borrower,
        address _nftAddress
    )
        external;

    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        returns (uint256);

    function liquidateNFT(
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external;

    function loanOwner(
        address _nft,
        uint256 _tokenID
    )
        external
        view
        returns (address);

    function withdrawFee()
        external;

    function poolToken()
        external
        view
        returns (address);

    function calculateWithdrawAmount(
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function multisig()
        external
        view
        returns (address);

    function changeFeeDestinationAddress(
        address _newFeeDestinationAddress
    )
        external;

    function feeDestinationAddress()
        external
        view
        returns (address);
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