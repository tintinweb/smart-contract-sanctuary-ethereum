// SPDX-License-Identifier: WISE

pragma solidity ^0.8.13;

import "./LiquidTransfer.sol";
import "./AccessControl.sol";


interface ILiquidPool {

    function depositFundsRouter(
        uint256 _amount,
        address _depositor
    )
        external;

    function withdrawFundsSmartRouter(
        uint256 _shares,
        address _user
    )
        external;

    function withdrawFundsInternalSharesRouter(
        uint256 _shares,
        address _user
    )
        external;

    function withdrawFundsTokenSharesRouter(
        uint256 _shares,
        address _user
    )
        external;

    function borrowFundsRouter(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _borrower,
        address _nftAddress
    )
        external;

    function paybackFundsRouter(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        returns (uint256, uint256);

    function liquidateNFT(
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _nftAddress
    )
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
}

contract LiquidRouter is LiquidTransfer, AccessControl {

    //official Liquid Pools. Prevent any contract that corresponds to the interface from using the router
    mapping(address => bool) registeredPools;

    //Factory contract that clones liquid pools
    address public factory;

    //Function can only be called by factory address
    modifier onlyFactory() {
        require(
            msg.sender == factory,
            'LiquidRouter: INVALID_FACTORY'
        );
        _;
    }

    modifier onlyWorkerOrFactory() {
        require(
            msg.sender == factory || workers[msg.sender],
            'LiquidRouter: INVALID_CALLER'
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
        factory = _newFactory;
    }

    /**
     * @dev Register a pool as an official instant pools pool
     */
    function registerPool(
        address _newPool
    )
        onlyWorkerOrFactory
        external
    {
        registeredPools[_newPool] = true;
    }

    /**
     * @dev Deregister a pool as an official instant pools pool
     */
    function deregisterPool(
        address _pool
    )
        onlyWorkerOrFactory
        external
    {
        registeredPools[_pool] = false;
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
    {
        if(!registeredPools[_pool]) revert();

        ILiquidPool(_pool).depositFundsRouter(
            _amount,
            msg.sender
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            _amount
        );

    }

    function withdrawFundsSmart(
        uint256 _shares,
        address _pool
    )
        external
    {
        ILiquidPool(_pool).withdrawFundsSmartRouter(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsInternalShares(
        uint256 _shares,
        address _pool
    )
        external
    {
        ILiquidPool(_pool).withdrawFundsInternalSharesRouter(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsTokenShares(
        uint256 _shares,
        address _pool
    )
        external
    {
        ILiquidPool(_pool).withdrawFundsTokenSharesRouter(
            _shares,
            msg.sender
        );
    }

    /*
        I think it makes more sense here to use a share value instead of a raw token value,
        since it is easier to calculate with our current helpers
    */
    function moveFunds(
        uint256 _shares,
        address _poolToExit,
        address _poolToEnter
    )
        external
    {
        if(!registeredPools[_poolToExit]) revert("LiquidRouter: Unregistered Pool");
        if(!registeredPools[_poolToEnter]) revert("LiquidRouter: Unregistered Pool");

        //Calculate the amount that will be withdrawn
        uint256 amountToDeposit = ILiquidPool(_poolToExit).calculateWithdrawAmount(_shares);

        ILiquidPool(_poolToExit).withdrawFundsInternalSharesRouter(
            _shares,
            msg.sender
        );

        //make deposit funds public and call it
        depositFunds(
            amountToDeposit,
            _poolToEnter
        );

    }

    /**
     * @dev Call the borrowFundsRouter function of a specific pool.
     * Also handle the transferring of tokens here, only have to approve router
     * Check that pool is registered
     */
    function borrowFunds(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _pool,
        address _nftAddress
    )
        external
    {
        if(!registeredPools[_pool]) revert();

        //transfer nft first for re-entrancy safety
        _transferFromNFT(
            msg.sender,
            _pool,
            _nftAddress,
            _tokenId
        );

        ILiquidPool(_pool).borrowFundsRouter(
            _tokenAmountToBorrow,
            _timeIncrease,
            _tokenId,
            _index,
            merkleProof,
            merklePrice,
            msg.sender,
            _nftAddress
        );
    }

    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _pool,
        address _nftAddress
    )
        external
    {
        if(!registeredPools[_pool]) revert();

        (uint256 totalPayment, uint256 feeAmount) = ILiquidPool(_pool).paybackFundsRouter(
            _principalPayoff,
            _timeIncrease,
            _tokenId,
            _index,
            _merkleProof,
            _merklePrice,
            _nftAddress
        );

        address multisig = ILiquidPool(_pool).multisig();
        address poolToken = ILiquidPool(_pool).poolToken();

        _safeTransferFrom(
            poolToken,
            msg.sender,
            multisig,
            feeAmount
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            _pool,
            totalPayment
        );
    }
}