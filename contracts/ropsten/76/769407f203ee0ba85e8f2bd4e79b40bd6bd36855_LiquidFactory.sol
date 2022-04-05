// SPDX-License-Identifier: WISE

pragma solidity ^0.8.9;

import "./LiquidTransfer.sol";
import "./AccessControl.sol";

interface ILiquidLocker {

    function initialize(
        uint256[] calldata _tokenId,
        address _tokenAddress,
        address _tokenOwner,
        uint256 _floorAsked,
        uint256 _totalAsked,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        external;

    function makeContribution(
        uint256 _tokenAmount,
        address _tokenHolder
    )
        external
        returns (uint256, uint256);

    function donateFunds(
        uint256 _donationAmount
    )
        external;

    function payBackFunds(
        uint256 _paymentAmount
    )
        external;

    function PAYMENT_TOKEN()
        external
        view
        returns (address);
}

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
}

interface ILiquidRouter {
    function registerPool(
        address _newPool
    )
    external;
}

/**
 * @dev LiquidFactory: Factory is responsible for deploying new LiquidLockers.
 * We use solidity assembly here to directly copy the bytes of a target contract into a new contract
 * Contributions to lockers and Paybacks to lockers go through this factory as a middle contract
 */
contract LiquidFactory is LiquidTransfer, AccessControl {

    // Contract we use an implementation if there is not a specific locker implementation for a given erc20 token address
    address public defaultLockerTarget;

    address public defaultPoolTarget;

    address public router;

    // Total number of lockers deployed
    uint256 public lockerCount;

    uint256 public poolCount;

    // This contract is used as a target for cloning new lockers. Each token has its own target implementation. These implementations can be updated.
    mapping(address => address) public implementations;

    // This mapping is set to true once a locker is created. This prevents us from trying to make calls to invalid lockers.
    mapping(address => bool) public lockers;

    mapping(address => bool) public pools;

    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    event NewLocker(
        address indexed lockerAddress,
        address indexed ownersAddress,
        address indexed tokensAddress,
        uint256 floorAsked,
        uint256 totalAsked,
        uint256 paymentTime,
        uint256 paymentRate,
        address paymentToken
    );

    event ContributeToLocker(
        address indexed lockerAddress,
        address indexed backerAddress,
        uint256 contributionAmount,
        uint256 totalIncreaseAmount
    );

    event DonateToLocker(
        address indexed lockerAddress,
        address indexed payersAddress,
        uint256 donateAmount
    );

    event PaybackToLocker(
        address indexed lockerAddress,
        address indexed payersAddress,
        uint256 paybackAmount
    );

    event ImplementationChange(
        address indexed oldImplementation,
        address indexed newImplementation,
        address indexed tokenKeyAddress
    );

    event NewEmptyLocker(
        address lockerAddress
    );

    event ReusedLocker(
        address lockerAddress
    );

    /**
     * @dev Set parameters and precompute some locker addresses.
     */
    constructor(
        uint256 _defaultCount,
        address _defaultToken,
        address _defaultLockerTarget,
        address _defaultPoolTarget,
        address _router
    ) {
        defaultLockerTarget = _defaultLockerTarget;
        defaultPoolTarget = _defaultPoolTarget;
        implementations[_defaultToken] = _defaultLockerTarget;

        _storePredictions(
            lockerCount,
            _defaultCount,
            _defaultToken
        );

        _generateLocker(
            _defaultToken
        );

        router = _router;
    }

    function storePredictions(
        uint256 _predictionStart,
        uint256 _predictionCount,
        address _predictionToken
    )
        external
    {
        _storePredictions(
            _predictionStart,
            _predictionCount,
            _predictionToken
        );
    }

    /**
     * @dev Pre store the addresses where future lockers will exist.
     * Doing this allows us to save gas on future calls.
     */
    function _storePredictions(
        uint256 _predictionStart,
        uint256 _predictionCount,
        address _predictionToken
    )
        internal
    {
        for (uint256 i = _predictionStart; i < _predictionCount; i++) {
            address predicted = predictLockerAddress(
                i,
                address(this),
                getImplementation(
                    _predictionToken
                )
            );
            lockers[predicted] = true;
        }
    }

    function updateRouter(
        address _newRouter
    )
        external
        onlyMultisigOrWorker
    {
        router = _newRouter;
    }

    /**
     * @dev Change the default target contract. Only mutlisig or worker address can do this.
     */
    function updateDefaultTarget(
        address _newDefaultTarget
    )
        external
        onlyMultisigOrWorker
    {
        defaultLockerTarget = _newDefaultTarget;
    }

    /**
     * @dev Change the default target contract. Only mutlisig or worker address can do this.
     */
    function updateDefaultPoolTarget(
        address _newDefaultTarget
    )
        external
        onlyMultisigOrWorker
    {
        defaultPoolTarget = _newDefaultTarget;
    }

    /**
     * @dev Add or modify the address used for cloning a locker based on a specific erc20 address.
     * This can be used to set an implementation for a new token when there is not yet one.
     * Only mutlisig or worker can use this function.
     */
    function updateImplementation(
        address _tokenAddress,
        address _targetAddress
    )
        external
        onlyMultisigOrWorker
    {
        implementations[_tokenAddress] = _targetAddress;
    }

    /**
    * @dev Clone the implemenation for a token into a new contract.
     * Call into initialize for the locker to begin the LiquidNFT loan process.
     * Transfer the NFT the user wants use for the loan into the locker.
     */
    function createLiquidPool(
        address _fungibleTokenAddress,  //Address of the erc20 token used for borrowing
        address _NFTAddress,            //Nft collection contract address to be borrowed against
        uint256 _maxTokensPerLoan,      //If the merkle root is empty, this value will be used for the amount to borrow for all tokens
        uint256 _multiplicationFactor,  //LASA variable @TODO update this comment with christoph
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
            _maxTokensPerLoan,
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
     * @dev Clone the implemenation for a token into a new contract.
     * Call into initialize for the locker to begin the LiquidNFT loan process.
     * Transfer the NFT the user wants use for the loan into the locker.
     */
    function createLiquidLocker(
        uint256[] calldata _tokenId,
        address _tokenAddress,
        uint256 _floorAsked,
        uint256 _totalAsked,
        uint256 _paymentTime,
        uint256 _paymentRate,
        address _paymentToken
    )
        external
        returns (address lockerAddress)
    {
        lockerAddress = _generateLocker(
            _paymentToken
        );

        ILiquidLocker(lockerAddress).initialize(
            _tokenId,
            _tokenAddress,
            msg.sender,
            _floorAsked,
            _totalAsked,
            _paymentTime,
            _paymentRate
        );

        for (uint256 i = 0; i < _tokenId.length; i++) {
            _transferFromNFT(
                msg.sender,
                lockerAddress,
                _tokenAddress,
                _tokenId[i]
            );
        }

        emit NewLocker(
            lockerAddress,
            msg.sender,
            _tokenAddress,
            _floorAsked,
            _totalAsked,
            _paymentTime,
            _paymentRate,
            _paymentToken
        );
    }

    function createEmptyLocker(
        address _paymentToken
    )
        external
        returns (address lockerAddress)
    {
        lockerAddress = _generateLocker(
            _paymentToken
        );

        emit NewEmptyLocker(
            lockerAddress
        );
    }

    /*
    function reuseLiquidLocker(...)
        external
    {
        // allows to reuse previosly deployed locker contracts
        // after they are utilized and no longer needed
        // this functionality will be available in V2
    }
    */

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
     * @dev Clone the byte code from one contract into a new contract. Uses solidity assembly.
     * This is a lot cheaper in gas than deploying a new contract.
     */
    function _generateLocker(
        address _paymentToken
    )
        internal
        returns (address lockerAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                lockerCount++
            )
        );

        bytes20 targetBytes = bytes20(
            getImplementation(_paymentToken)
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

            lockerAddress := create2(0, clone, 0x37, salt)
        }

        if (lockers[lockerAddress] == false) {
            lockers[lockerAddress] = true;
        }
    }

    /**
     * @dev Call contributeToLocker. Factory acts as a middle man between the user and the locker.
     * We do this so that the user only has to approve the factory and not each new locker.
     */
    function contributeToLocker(
        address _lockersAddress,
        uint256 _paymentAmount
    )
        external
        returns (
            uint256 totalIncrease,
            uint256 usersIncrease
        )
    {
        require(
            lockers[_lockersAddress] == true,
            'LiquidFactory: INVALID_LOCKER'
        );

        ILiquidLocker locker = ILiquidLocker(
            _lockersAddress
        );

        (totalIncrease, usersIncrease) = locker.makeContribution(
            _paymentAmount,
            msg.sender
        );

        _safeTransferFrom(
            locker.PAYMENT_TOKEN(),
            msg.sender,
            _lockersAddress,
            usersIncrease
        );

        emit ContributeToLocker(
            _lockersAddress,
            msg.sender,
            usersIncrease,
            totalIncrease
        );
    }

    /**
     * @dev Give tokens to a locker. These tokens do not go toward paying off the loan,
     * they are instead distributed among the contributors for the loan.
     * The result of this is that the value is transferred to the contributors not the owner because it does
     * not deduct from the balance the owner owes.
     */
    function donateToLocker(
        address _lockersAddress,
        uint256 _donationAmount
    )
        external
    {
        require(
            lockers[_lockersAddress] == true,
            'LiquidFactory: INVALID_LOCKER'
        );

        ILiquidLocker locker = ILiquidLocker(
            _lockersAddress
        );

        locker.donateFunds(
            _donationAmount
        );

        _safeTransferFrom(
            locker.PAYMENT_TOKEN(),
            msg.sender,
            _lockersAddress,
            _donationAmount
        );

        emit DonateToLocker(
            _lockersAddress,
            msg.sender,
            _donationAmount
        );
    }

    /**
     * @dev Call paybackToLocker. Factory acts as a middle man between the user and the locker.
     * We do this so that the user only has to approve the factory and not each new locker.
     */
    function paybackToLocker(
        address _lockersAddress,
        uint256 _paymentAmount
    )
        external
    {
        require(
            lockers[_lockersAddress] == true,
            'LiquidFactory: INVALID_LOCKER'
        );

        ILiquidLocker locker = ILiquidLocker(
            _lockersAddress
        );

        locker.payBackFunds(
            _paymentAmount
        );

        _safeTransferFrom(
            locker.PAYMENT_TOKEN(),
            msg.sender,
            _lockersAddress,
            _paymentAmount
        );

        emit PaybackToLocker(
            _lockersAddress,
            msg.sender,
            _paymentAmount
        );
    }

    /**
     * @dev Returns the address that the factory will attempt to clone a locker from for a given token.
     */
    function getImplementation(
        address _paymentToken
    )
        public
        view
        returns (address implementation)
    {
        implementation =
        implementations[_paymentToken] == ZERO_ADDRESS
            ? defaultLockerTarget
            : implementations[_paymentToken];
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
     * @dev Pre-compute what address a future locker will exist at.
     */
    function predictLockerAddress(
        uint256 _index,
        address _factory,
        address _implementation
    )
        public
        pure
        returns (address predicted)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                _index
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