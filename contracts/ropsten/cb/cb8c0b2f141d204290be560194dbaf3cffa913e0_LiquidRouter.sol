// SPDX-License-Identifier: WISE

pragma solidity =0.8.13;

import "./ILiquidPool.sol";
import "./RouterEvents.sol";
import "./AccessControl.sol";
import "./LiquidTransfer.sol";

contract LiquidRouter is LiquidTransfer, AccessControl, RouterEvents {

    address public constant ZERO_ADDRESS = address(0x0);
    // Factory contract that clones liquid pools
    address public factory;

    // Official pools that are added to the router
    mapping(address => bool) public registeredPools;

    // Function can only be called by factory address
    modifier onlyFactory() {
        require(
            msg.sender == factory,
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
        address _factory
    ) {
        factory = _factory;
    }

    /**
     * @dev Set the address of the factory. Only master address can do this.
     * Since either the router or factory must be deployed first one or the either must update their
     * knowledge of where the other is afterwards
     */
    function updateFactory(
        address _newFactory
    )
        external
        onlyMultisig
    {
        address currentFactory = factory;

        factory = _newFactory;

        emit FactoryUpdated(
            currentFactory,
            _newFactory,
            multisig,
            block.timestamp
        );
    }

    /**
     * @dev Register a pool as an official instant pools pool
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
     * @dev Deregister a pool as an official instant pools pool
     */
    function removeLiquidPool(
        address _pool
    )
        onlyFactory
        external
    {
        registeredPools[_pool] = false;

        emit LiquidPoolUnRegistered(
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
        uint256 _timeIncrease,
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
            _timeIncrease,
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
            _timeIncrease,
            _borrowAmount,
            block.timestamp
        );
    }

    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
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
            _timeIncrease,
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
            _timeIncrease,
            _tokenId,
            block.timestamp
        );
    }
}