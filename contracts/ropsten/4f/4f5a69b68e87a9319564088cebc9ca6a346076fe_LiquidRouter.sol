// SPDX-License-Identifier: WISE

pragma solidity ^0.8.9;

import "./LiquidTransfer.sol";

interface ILiquidPool {
    function initialize(
        address _fungibleTokenAddress,
        address _NFTAddress,
        address _multisig,
        uint256 _maxTokensPerLoan,
        uint256 _multiplicationFactor,
        uint256 _maxCollatFactor,
        bytes32 _merkleRoot,
        string memory _ipfsURL,
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external;

    function depositFundsRouter(
        uint256 _amount,
        address _depositor
    )
        external;

    function borrowFundsRouter(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address depositor
    )
        external;

    function liquidateNFT(
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice
    )
        external;

    function poolToken()
        external
        view
        returns (address);

    function nftAddress()
        external
        view
        returns (address);
}

contract LiquidRouter is LiquidTransfer {

    address public masterAddress;

    mapping(address => bool) registeredPools;

    address public factory;

    modifier onlyMaster() {
        require(
            msg.sender == masterAddress,
            'LiquidRouter: INVALID_MASTER'
        );
        _;
    }

    modifier onlyFactory() {
        require(
            msg.sender == factory,
            'LiquidRouter: INVALID_FACTORY'
        );
        _;
    }

    modifier onlyMasterOrFactory() {
        require(
            msg.sender == factory || msg.sender == factory,
            'LiquidRouter: INVALID_CALLER'
        );
        _;
    }

    constructor(
        address _factory
    ) {
        factory = _factory;
        masterAddress = msg.sender;
    }

    function updateFactory(
        address _newFactory
    )
        external
        onlyMaster
    {
        factory = _newFactory;
    }

    function registerPool(
        address _newPool
    )
        onlyMasterOrFactory
        external
    {
        registeredPools[_newPool] = true;
    }

    function deregisterPool(
        address _pool
    )
        onlyMasterOrFactory
        external
    {
        registeredPools[_pool] = false;
    }

    function depositFunds(
        uint256 _amount,
        address _pool
    )
        external
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

    function borrowFunds(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _pool
    )
        external
    {
        if(!registeredPools[_pool]) revert();

        //transfer nft first for re-entrancy safety
        _transferFromNFT(
            msg.sender,
            _pool,
            ILiquidPool(_pool).nftAddress(),
            _tokenId
        );

        ILiquidPool(_pool).borrowFundsRouter(
            _tokenAmountToBorrow,
            _timeIncrease,
            _tokenId,
            _index,
            merkleProof,
            merklePrice,
            msg.sender
        );
    }

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
            'PoolHelper: TRANSFER_FROM_FAILED'
        );
    }
}