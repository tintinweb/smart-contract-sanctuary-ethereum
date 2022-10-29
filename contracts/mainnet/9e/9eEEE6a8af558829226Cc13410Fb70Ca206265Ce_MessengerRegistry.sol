// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import './interfaces/IMessenger.sol';
import './interfaces/IMessengerRegistry.sol';

/**
 * @title MessengerRegistry
 * @notice MessengerRegistry is a contract to register openly distributed Messengers
 */
contract MessengerRegistry is IMessengerRegistry {
    /// @notice struct to store the definition of Messenger
    struct Messenger {
        address ownerAddress;
        address messengerAddress;
        string specificationUrl;
        uint256 precision;
        uint256 requestsCounter;
        uint256 fulfillsCounter;
        uint256 id;
    }

    /// @notice messengers
    Messenger[] private _messengers;
    /// @notice (messengerAddress=>bool) to check if the Messenger was registered
    mapping(address => bool) private _registeredMessengers;
    /// @notice (userAddress=>messengerAddress[]) to register the messengers of an owner
    mapping(address => uint256[]) private _ownerMessengers;
    /// @notice SLARegistry address
    address private _slaRegistry;

    /// @notice an event that is emitted when SLARegistry registers a new messenger
    event MessengerRegistered(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    /// @notice an event that is emitted when Messenger owner modifies the messenger
    event MessengerModified(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    /**
     * @notice function to set SLARegistry address
     * @dev this function can be called only once
     */
    function setSLARegistry() external override {
        require(
            address(_slaRegistry) == address(0),
            'SLARegistry address has already been set'
        );

        _slaRegistry = msg.sender;
    }

    /**
     * @notice function to register a new Messenger
     * @dev only SLARegistry can call this function
     * @param callerAddress_ messenger owner address
     * @param messengerAddress_ messenger address
     * @param specificationUrl_ specification url of messenger
     */
    function registerMessenger(
        address callerAddress_,
        address messengerAddress_,
        string calldata specificationUrl_
    ) external override {
        require(
            msg.sender == _slaRegistry,
            'Should only be called using the SLARegistry contract'
        );
        require(messengerAddress_ != address(0x0), 'invalid messenger address');
        require(
            !_registeredMessengers[messengerAddress_],
            'messenger already registered'
        );

        IMessenger messenger = IMessenger(messengerAddress_);
        address messengerOwner = messenger.owner();
        require(
            messengerOwner == callerAddress_,
            'Should only be called by the messenger owner'
        );
        uint256 precision = messenger.messengerPrecision();
        uint256 requestsCounter = messenger.requestsCounter();
        uint256 fulfillsCounter = messenger.fulfillsCounter();
        _registeredMessengers[messengerAddress_] = true;
        uint256 id = _messengers.length;
        _ownerMessengers[messengerOwner].push(id);

        require(
            precision % 100 == 0 && precision != 0,
            'invalid messenger precision, cannot register messanger'
        );

        _messengers.push(
            Messenger({
                ownerAddress: messengerOwner,
                messengerAddress: messengerAddress_,
                specificationUrl: specificationUrl_,
                precision: precision,
                requestsCounter: requestsCounter,
                fulfillsCounter: fulfillsCounter,
                id: id
            })
        );

        emit MessengerRegistered(
            messengerOwner,
            messengerAddress_,
            specificationUrl_,
            precision,
            id
        );
    }

    /**
     * @notice function to modify messenger
     * @dev only messenger owner can call this function
     * @param _specificationUrl new specification url to update
     */
    function modifyMessenger(
        string calldata _specificationUrl,
        uint256 _messengerId
    ) external {
        Messenger storage storedMessenger = _messengers[_messengerId];
        require(
            msg.sender == IMessenger(storedMessenger.messengerAddress).owner(),
            'Can only be modified by the owner'
        );
        storedMessenger.specificationUrl = _specificationUrl;
        storedMessenger.ownerAddress = msg.sender;
        emit MessengerModified(
            storedMessenger.ownerAddress,
            storedMessenger.messengerAddress,
            storedMessenger.specificationUrl,
            storedMessenger.precision,
            storedMessenger.id
        );
    }

    /**
     * @notice external view function that returns registered messengers
     * @return array of Messenger struct
     */
    function getMessengers(uint256 skip, uint256 num)
        external
        view
        returns (Messenger[] memory)
    {
        if (skip >= _messengers.length) num = 0;
        if (skip + num > _messengers.length) num = _messengers.length - skip;
        Messenger[] memory returnMessengers = new Messenger[](num);

        for (uint256 index = skip; index < skip + num; index++) {
            IMessenger messenger = IMessenger(
                _messengers[index].messengerAddress
            );
            returnMessengers[index - skip] = Messenger({
                ownerAddress: _messengers[index].ownerAddress,
                messengerAddress: _messengers[index].messengerAddress,
                specificationUrl: _messengers[index].specificationUrl,
                precision: _messengers[index].precision,
                requestsCounter: messenger.requestsCounter(),
                fulfillsCounter: messenger.fulfillsCounter(),
                id: _messengers[index].id
            });
        }
        return returnMessengers;
    }

    /**
     * @notice external view function that returns the number of registered messengers
     * @return number of registered messengers
     */
    function getMessengersLength() external view returns (uint256) {
        return _messengers.length;
    }

    /**
     * @notice external view function that returns the registration state by address
     * @param messengerAddress_ messenger address to check
     * @return bool registered or not
     */
    function registeredMessengers(address messengerAddress_)
        external
        view
        override
        returns (bool)
    {
        return _registeredMessengers[messengerAddress_];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title IMessenger
 * @dev Interface to create new Messenger contract to add lo Messenger lists
 */

abstract contract IMessenger is Ownable {
    struct SLIRequest {
        address slaAddress;
        uint256 periodId;
    }

    /**
     * @dev event emitted when created a new chainlink request
     * @param caller 1. Requester's address
     * @param requestsCounter 2. total count of requests
     * @param requestId 3. id of the Chainlink request
     */
    event SLIRequested(
        address indexed caller,
        uint256 requestsCounter,
        bytes32 requestId
    );

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param slaAddress 1. SLA address to store the SLI
     * @param periodId 2. period id
     * @param requestId 3. id of the Chainlink request
     * @param chainlinkResponse 4. response from Chainlink
     */
    event SLIReceived(
        address indexed slaAddress,
        uint256 periodId,
        bytes32 indexed requestId,
        bytes32 chainlinkResponse
    );

    /**
     * @dev event emitted when updating Chainlink Job ID
     * @param owner 1. Oracle Owner
     * @param jobId 2. Updated job id
     * @param fee 3. Chainlink request fee
     */
    event JobIdModified(address indexed owner, bytes32 jobId, uint256 fee);

    /**
     * @dev sets the SLARegistry contract address and can only be called once
     */
    function setSLARegistry() external virtual;

    /**
     * @dev creates a ChainLink request to get a new SLI value for the
     * given params. Can only be called by the SLARegistry contract or Chainlink Oracle.
     * @param _periodId 1. id of the period to be queried
     * @param _slaAddress 2. address of the receiver SLA
     * @param _slaAddress 2. if approval by owner or msg.sender
     */
    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _ownerApproval,
        address _callerAddress
    ) external virtual;

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param answer response object from Chainlink Oracles
     */
    function fulfillSLI(bytes32 _requestId, uint256 answer) external virtual;

    /**
     * @dev gets the interfaces precision
     */
    function messengerPrecision() external view virtual returns (uint256);

    /**
     * @dev gets the slaRegistryAddress
     */
    function slaRegistryAddress() external view virtual returns (address);

    /**
     * @dev gets the chainlink oracle contract address
     */
    function oracle() external view virtual returns (address);

    /**
     * @dev gets the chainlink job id
     */
    function jobId() external view virtual returns (bytes32);

    /**
     * @dev gets the fee amount of LINK token
     */
    function fee() external view virtual returns (uint256);

    /**
     * @dev returns the requestsCounter
     */
    function requestsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the fulfillsCounter
     */
    function fulfillsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the name of DSLA-LP token
     */
    function lpName() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-LP token
     */
    function lpSymbol() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-LP token with slaId
     */
    function lpSymbolSlaId(uint128 slaId)
        external
        view
        virtual
        returns (string memory);

    /**
     * @dev returns the name of DSLA-SP token
     */
    function spName() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-SP token
     */
    function spSymbol() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-SP token with slaId
     */
    function spSymbolSlaId(uint128 slaId)
        external
        view
        virtual
        returns (string memory);

    function setChainlinkJobID(bytes32 _newJobId, uint256 _feeMultiplier)
        external
        virtual;

    function retryRequest(address _slaAddress, uint256 _periodId)
        external
        virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface IMessengerRegistry {
    function setSLARegistry() external;

    function registerMessenger(
        address callerAddress_,
        address messengerAddress_,
        string calldata specificationUrl_
    ) external;

    function registeredMessengers(address messengerAddress_)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}