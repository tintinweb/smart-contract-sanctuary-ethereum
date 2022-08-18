// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable} from "../lib/utils/Ownable.sol";
import {ERC1967Proxy} from "../lib/proxy/ERC1967Proxy.sol";

import {ManagerStorageV1} from "./storage/ManagerStorageV1.sol";
import {IManager} from "./IManager.sol";
import {IToken} from "../token/IToken.sol";
import {IMetadataRenderer} from "../token/metadata/IMetadataRenderer.sol";
import {IAuction} from "../auction/IAuction.sol";
import {ITimelock} from "../governance/timelock/ITimelock.sol";
import {IGovernor} from "../governance/governor/IGovernor.sol";

/// @title Manager
/// @author Rohan Kulkarni
/// @notice This contract manages DAO deployments and opt-in contract upgrades.
contract Manager is IManager, UUPS, Ownable, ManagerStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The address of the token implementation
    address public immutable tokenImpl;

    /// @notice The address of the metadata renderer implementation
    address public immutable metadataImpl;

    /// @notice The address of the auction house implementation
    address public immutable auctionImpl;

    /// @notice The address of the timelock implementation
    address public immutable timelockImpl;

    /// @notice The address of the governor implementation
    address public immutable governorImpl;

    /// @notice The hash of the metadata renderer bytecode to be deployed
    bytes32 private immutable metadataHash;

    /// @notice The hash of the auction bytecode to be deployed
    bytes32 private immutable auctionHash;

    /// @notice The hash of the timelock bytecode to be deployed
    bytes32 private immutable timelockHash;

    /// @notice The hash of the governor bytecode to be deployed
    bytes32 private immutable governorHash;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    constructor(
        address _tokenImpl,
        address _metadataImpl,
        address _auctionImpl,
        address _timelockImpl,
        address _governorImpl
    ) payable initializer {
        tokenImpl = _tokenImpl;
        metadataImpl = _metadataImpl;
        auctionImpl = _auctionImpl;
        timelockImpl = _timelockImpl;
        governorImpl = _governorImpl;

        metadataHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_metadataImpl, "")));
        auctionHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_auctionImpl, "")));
        timelockHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_timelockImpl, "")));
        governorHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_governorImpl, "")));
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes ownership of the manager contract
    /// @param _owner The address of the owner to set
    function initialize(address _owner) external initializer {
        // Ensure an owner is specified
        if (_owner == address(0)) revert ADDRESS_ZERO();

        // Set the given address as the owner
        __Ownable_init(_owner);
    }

    ///                                                          ///
    ///                          DAO DEPLOY                      ///
    ///                                                          ///

    /// @notice Deploys a DAO with custom nounish settings
    /// @param _founderParams The founders allocation
    /// @param _tokenParams The token configuration
    /// @param _auctionParams The auction configuration
    /// @param _govParams The governance configuration
    function deploy(
        FounderParams[] calldata _founderParams,
        TokenParams calldata _tokenParams,
        AuctionParams calldata _auctionParams,
        GovParams calldata _govParams
    )
        external
        returns (
            address token,
            address metadata,
            address auction,
            address timelock,
            address governor
        )
    {
        // Used to store the founder responsible for adding token properties and kicking off the first auction
        address founder;

        // Ensure at least one founder address is provided
        if (((founder = _founderParams[0].wallet)) == address(0)) revert FOUNDER_REQUIRED();

        // Deploy an instance of the DAO's ERC-721 token
        token = address(new ERC1967Proxy(tokenImpl, ""));

        // Use the token address as a salt for the remaining deploys
        bytes32 salt = bytes32(uint256(uint160(token)));

        // Deploy the remaining contracts
        metadata = address(new ERC1967Proxy{salt: salt}(metadataImpl, ""));
        auction = address(new ERC1967Proxy{salt: salt}(auctionImpl, ""));
        timelock = address(new ERC1967Proxy{salt: salt}(timelockImpl, ""));
        governor = address(new ERC1967Proxy{salt: salt}(governorImpl, ""));

        // Initialize each with the given settings
        IToken(token).initialize(_founderParams, _tokenParams.initStrings, metadata, auction);
        IMetadataRenderer(metadata).initialize(_tokenParams.initStrings, token, founder, timelock);
        IAuction(auction).initialize(token, founder, timelock, _auctionParams.duration, _auctionParams.reservePrice);
        ITimelock(timelock).initialize(governor, _govParams.timelockDelay);
        IGovernor(governor).initialize(
            timelock,
            token,
            founder,
            _govParams.votingDelay,
            _govParams.votingPeriod,
            _govParams.proposalThresholdBPS,
            _govParams.quorumVotesBPS
        );

        emit DAODeployed(token, metadata, auction, timelock, governor);
    }

    ///                                                          ///
    ///                        DAO ADDRESSES                     ///
    ///                                                          ///

    /// @notice The addresses of a DAO's contracts from
    /// @param _token The ERC-721 token address
    function getAddresses(address _token)
        external
        view
        returns (
            address metadata,
            address auction,
            address timelock,
            address governor
        )
    {
        bytes32 salt = bytes32(uint256(uint160(_token)));

        metadata = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, metadataHash)))));
        auction = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, auctionHash)))));
        timelock = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, timelockHash)))));
        governor = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, governorHash)))));
    }

    ///                                                          ///
    ///                         DAO UPGRADES                     ///
    ///                                                          ///

    /// @notice Registers an implementation as a valid upgrade
    /// @param _baseImpl The address of the base implementation
    /// @param _upgradeImpl The address of the upgrade implementation to register
    function registerUpgrade(address _baseImpl, address _upgradeImpl) external onlyOwner {
        // Register the upgrade
        isUpgrade[_baseImpl][_upgradeImpl] = true;

        emit UpgradeRegistered(_baseImpl, _upgradeImpl);
    }

    /// @notice Unregisters an implementation
    /// @param _baseImpl The address of the base implementation
    /// @param _upgradeImpl The address of the upgrade implementation to unregister
    function unregisterUpgrade(address _baseImpl, address _upgradeImpl) external onlyOwner {
        // Remove the upgrade
        delete isUpgrade[_baseImpl][_upgradeImpl];

        emit UpgradeUnregistered(_baseImpl, _upgradeImpl);
    }

    /// @notice If an upgraded implementation has been registered for its original implementation
    /// @param _baseImpl The address of the original implementation
    /// @param _upgradeImpl The address of the upgrade implementation
    function isValidUpgrade(address _baseImpl, address _upgradeImpl) external view returns (bool) {
        return isUpgrade[_baseImpl][_upgradeImpl];
    }

    ///                                                          ///
    ///                        CONTRACT UPGRADE                  ///
    ///                                                          ///

    /// @notice Allows the default DAO implementations to be updated via Builder DAO governance
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The address of the new implementation
    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPS is IERC1822Proxiable {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev keccak256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    address private immutable __self = address(this);

    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event Upgraded(address indexed impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_UPGRADE(address impl);

    error ONLY_DELEGATECALL();

    error NO_DELEGATECALL();

    error ONLY_PROXY();

    error INVALID_UUID();

    error NOT_UUPS();

    error INVALID_TARGET();

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __self) revert NO_DELEGATECALL();
        _;
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function _authorizeUpgrade(address _impl) internal virtual;

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address _impl) external onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, "", false);
    }

    function upgradeToAndCall(address _impl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, _data, true);
    }

    function _upgradeToAndCallUUPS(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_impl);
        } else {
            try IERC1822Proxiable(_impl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert INVALID_UUID();
            } catch {
                revert NOT_UUPS();
            }

            _upgradeToAndCall(_impl, _data, _forceCall);
        }
    }

    function _upgradeToAndCall(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_impl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_impl, _data);
        }
    }

    function _upgradeTo(address _impl) internal {
        _setImplementation(_impl);

        emit Upgraded(_impl);
    }

    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_TARGET();

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract OwnableStorageV1 {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is Initializable, OwnableStorageV1 {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    event OwnerPending(address indexed owner, address indexed pendingOwner);

    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    error ONLY_OWNER();

    error ONLY_PENDING_OWNER();

    error INCORRECT_PENDING_OWNER();

    modifier onlyOwner() {
        if (msg.sender != owner) revert ONLY_OWNER();
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    function __Ownable_init(address _owner) internal onlyInitializing {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(owner, _newOwner);

        owner = _newOwner;
    }

    function safeTransferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;

        emit OwnerPending(owner, _newOwner);
    }

    function cancelOwnershipTransfer(address _pendingOwner) public onlyOwner {
        if (_pendingOwner != pendingOwner) revert INCORRECT_PENDING_OWNER();

        emit OwnerCanceled(owner, _pendingOwner);

        delete pendingOwner;
    }

    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(owner, msg.sender);

        owner = pendingOwner;

        delete pendingOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/ERC1967/ERC1967Proxy.sol
contract ERC1967Proxy {
    /// @dev keccak256("eip1967.proxy.rollback") - 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256("eip1967.proxy.implementation") - 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    event Upgraded(address impl);

    error INVALID_UPGRADE(address impl);

    error INVALID_UUID();

    error NOT_UUPS();

    function _upgradeToAndCallUUPS(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert INVALID_UUID();
            } catch {
                revert NOT_UUPS();
            }
            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    function _upgradeToAndCall(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_impl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_impl, _data);
        }
    }

    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    function _setImplementation(address _newImpl) private {
        if (!Address.isContract(_newImpl)) revert INVALID_UPGRADE(_newImpl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _newImpl;
    }

    function _implementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    receive() external payable {
        _fallback();
    }

    fallback() external payable {
        _fallback();
    }

    function _fallback() internal {
        _delegate(_implementation());
    }

    function _delegate(address _impl) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @notice Manager Storage V1
/// @author Rohan Kulkarni
/// @notice Stores upgrade paths registered by the Builder DAO
contract ManagerStorageV1 {
    /// @notice If a contract has been registered as an upgrade
    /// @dev Base impl => Upgrade impl
    mapping(address => mapping(address => bool)) internal isUpgrade;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The Manager external interface
interface IManager {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice Emitted when a DAO is deployed
    /// @param token The address of the token
    /// @param metadata The address of the metadata renderer
    /// @param auction The address of the auction
    /// @param timelock The address of the timelock
    /// @param governor The address of the governor
    event DAODeployed(address token, address metadata, address auction, address timelock, address governor);

    /// @notice Emitted when an upgrade is registered
    /// @param baseImpl The address of the previous implementation
    /// @param upgradeImpl The address of the registered upgrade
    event UpgradeRegistered(address baseImpl, address upgradeImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param baseImpl The address of the base contract
    /// @param upgradeImpl The address of the upgrade
    event UpgradeUnregistered(address baseImpl, address upgradeImpl);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error FOUNDER_REQUIRED();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice The ownership config for each founder
    /// @param wallet A wallet or multisig address
    /// @param allocationFrequency The frequency of tokens minted to them (eg. Every 10 tokens to Nounders)
    /// @param vestingEnd The timestamp that their vesting will end
    struct FounderParams {
        address wallet;
        uint256 allocationFrequency;
        uint256 vestingEnd;
    }

    /// @notice The DAO's ERC-721 token and metadata config
    /// @param initStrings The encoded
    struct TokenParams {
        bytes initStrings; // name, symbol, description, contract image, renderer base
    }

    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    struct GovParams {
        uint256 timelockDelay; // The time between a proposal and its execution
        uint256 votingDelay; // The number of blocks after a proposal that voting is delayed
        uint256 votingPeriod; // The number of blocks that voting for a proposal will take place
        uint256 proposalThresholdBPS; // The number of votes required for a voter to become a proposer
        uint256 quorumVotesBPS; // The number of votes required to support a proposal
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function deploy(
        FounderParams[] calldata _founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function isValidUpgrade(address _baseImpl, address _upgradeImpl) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IManager} from "../manager/IManager.sol";
import {IMetadataRenderer} from "./metadata/IMetadataRenderer.sol";

interface IToken {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ONLY_OWNER();

    error ONLY_AUCTION();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata tokenInitStrings,
        address metadataRenderer,
        address auction
    ) external;

    // function metadataRenderer() external view returns (IMetadataRenderer);

    // function auction() external view returns (address);

    // function totalSupply() external view returns (uint256);

    // function name() external view returns (string memory);

    // function symbol() external view returns (string memory);

    // function contractURI() external view returns (string memory);

    // function tokenURI(uint256 tokenId) external view returns (string memory);

    // function balanceOf(address owner) external view returns (uint256);

    // function ownerOf(uint256 tokenId) external view returns (address);

    // function isApprovedForAll(address owner, address operator) external view returns (bool);

    // function getApproved(uint256 tokenId) external view returns (address);

    // function getVotes(address account) external view returns (uint256);

    // function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    // function delegates(address account) external view returns (address);

    // function nonces(address owner) external view returns (uint256);

    // function DOMAIN_SEPARATOR() external view returns (bytes32);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function getVotes(address user) external view returns (uint256);

    // function getPastVotes(address user, uint256 timestamp) external view returns (uint256);

    // function delegates(address _user) external view returns (address);

    // function delegate(address to) external;

    // function delegateBySig(
    //     address to,
    //     uint256 nonce,
    //     uint256 expiry,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // function mint() external returns (uint256);

    // function burn(uint256 tokenId) external;

    // function approve(address to, uint256 tokenId) external;

    // function setApprovalForAll(address operator, bool approved) external;

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external;

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRendererTypesV1} from "./types/MetadataRendererTypesV1.sol";

interface IMetadataRenderer is MetadataRendererTypesV1 {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    event PropertyAdded(uint256 id, string name);

    event ItemAdded(uint256 propertyId, uint256 index);

    event ContractImageUpdated(string prevImage, string newImage);

    event RendererBaseUpdated(string prevRendererBase, string newRendererBase);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ONLY_TOKEN();

    error TOKEN_NOT_MINTED(uint256 tokenId);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        bytes calldata initStrings,
        address token,
        address founders,
        address treasury
    ) external;

    function addProperties(
        string[] calldata names,
        ItemParam[] calldata items,
        IPFSGroup calldata ipfsGroup
    ) external;

    function updateContractImage(string memory newContractImage) external;

    function updateRendererBase(string memory newRendererBase) external;

    function propertiesCount() external view returns (uint256);

    function itemsCount(uint256 propertyId) external view returns (uint256);

    function generate(uint256 tokenId) external;

    function getAttributes(uint256 tokenId) external view returns (bytes memory aryAttributes, bytes memory queryString);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function token() external view returns (address);

    function treasury() external view returns (address);

    function contractImage() external view returns (string memory);

    function rendererBase() external view returns (string memory);

    function description() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IToken} from "../token/IToken.sol";

interface IAuction {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a bid is placed
    /// @param tokenId The ERC-721 token id
    /// @param bidder The address of the bidder
    /// @param amount The amount of ETH
    /// @param extended If the bid extended the auction
    /// @param endTime The end time of the auction
    event AuctionBid(uint256 tokenId, address bidder, uint256 amount, bool extended, uint256 endTime);

    /// @notice Emitted when an auction is settled
    /// @param tokenId The ERC-721 token id of the settled auction
    /// @param winner The address of the winning bidder
    /// @param amount The amount of ETH raised from the winning bid
    event AuctionSettled(uint256 tokenId, address winner, uint256 amount);

    /// @notice Emitted when an auction is created
    /// @param tokenId The ERC-721 token id of the created auction
    /// @param startTime The start time of the created auction
    /// @param endTime The end time of the created auction
    event AuctionCreated(uint256 tokenId, uint256 startTime, uint256 endTime);

    /// @notice Emitted when the auction duration is updated
    /// @param duration The new auction duration
    event DurationUpdated(uint256 duration);

    /// @notice Emitted when the reserve price is updated
    /// @param reservePrice The new reserve price
    event ReservePriceUpdated(uint256 reservePrice);

    /// @notice Emitted when the min bid increment percentage is updated
    /// @param minBidIncrementPercentage The new min bid increment percentage
    event MinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    /// @notice Emitted when the time buffer is updated
    /// @param timeBuffer The new time buffer
    event TimeBufferUpdated(uint256 timeBuffer);

    ///                                                          ///
    ///                           ERRORS                         ///
    ///                                                          ///

    error INVALID_TOKEN_ID();

    error AUCTION_OVER();

    error RESERVE_PRICE_NOT_MET();

    error MINIMUM_BID_NOT_MET();

    error AUCTION_NOT_STARTED();

    error AUCTION_NOT_OVER();

    error AUCTION_SETTLED();

    error INSOLVENT();

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function initialize(
        address token,
        address founder,
        address treasury,
        uint256 duration,
        uint256 reservePrice
    ) external;

    function createBid(uint256 tokenId) external payable;

    function settleCurrentAndCreateNewAuction() external;

    function settleAuction() external;

    function setDuration(uint256 duration) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinimumBidIncrement(uint256 percentage) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ITimelock {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    event TransactionScheduled(uint256 proposalId, uint256 timestamp);

    event TransactionCanceled(uint256 proposalId);

    event TransactionExecuted(uint256 proposalId, address[] targets, uint256[] values, bytes[] payloads);

    event TransactionDelayUpdated(uint256 prevDelay, uint256 newDelay);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ALREADY_QUEUED(uint256 proposalId);

    error NOT_QUEUED(uint256 proposalId);

    error TRANSACTION_NOT_READY(uint256 proposalId);

    error TRANSACTION_FAILED(address target, uint256 value, bytes data);

    error ONLY_TIMELOCK();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(address governor, uint256 txDelay) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function isOperation(uint256 proposalId) external view returns (bool);

    // function isOperationPending(uint256 proposalId) external view returns (bool);

    // function isOperationReady(uint256 proposalId) external view returns (bool);

    // function isOperationDone(uint256 proposalId) external view returns (bool);

    // function isOperationExpired(uint256 proposalId) external view returns (bool);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) external pure returns (uint256);

    function cancel(uint256 proposalId) external;

    // function schedule(
    //     address target,
    //     uint256 value,
    //     bytes calldata data,
    //     bytes32 predecessor,
    //     bytes32 salt,
    //     uint256 delay
    // ) external;

    // function scheduleBatch(
    //     address[] calldata targets,
    //     uint256[] calldata values,
    //     bytes[] calldata payloads,
    //     bytes32 predecessor,
    //     bytes32 salt,
    //     uint256 delay
    // ) external;

    // function execute(
    //     address target,
    //     uint256 value,
    //     bytes calldata data,
    //     bytes32 predecessor,
    //     bytes32 salt
    // ) external payable;

    // function executeBatch(
    //     address[] calldata targets,
    //     uint256[] calldata values,
    //     bytes[] calldata payloads,
    //     bytes32 predecessor,
    //     bytes32 salt
    // ) external payable;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function updateDelay(uint256 newDelay) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

// import {IToken} from "../../token/IToken.sol";

interface IGovernor {
    event ProposalCreated(
        uint256 proposalNumber,
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        bytes32 descriptionHash
    );

    event ProposalQueued(uint256 proposalId);

    event ProposalExecuted(uint256 proposalId);

    event ProposalCanceled(uint256 proposalId);

    event ProposalVetoed(uint256 proposalId);

    event VoteCast(address voter, uint256 proposalId, uint256 support, uint256 weight);

    event VotingDelayUpdated(uint256 prevVotingDelay, uint256 newVotingDelay);

    event VotingPeriodUpdated(uint256 prevVotingPeriod, uint256 newVotingPeriod);

    event ProposalThresholdBpsUpdated(uint256 prevBps, uint256 newBps);

    event QuorumVotesBpsUpdated(uint256 prevBps, uint256 newBps);

    event VetoerUpdated(address prevVetoer, address newVetoer);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error BELOW_PROPOSAL_THRESHOLD();

    error NO_TARGET_PROVIDED();

    error INVALID_PROPOSAL_LENGTH();

    error PROPOSAL_EXISTS(uint256 proposalId);

    error PROPOSAL_UNSUCCESSFUL();

    error PROPOSAL_NOT_QUEUED(uint256 proposalId, uint256 state);

    error ALREADY_EXECUTED();

    error PROPOSER_ABOVE_THRESHOLD();

    error ONLY_VETOER();

    error INACTIVE_PROPOSAL();

    error ALREADY_VOTED();

    error INVALID_VOTE();

    error INVALID_PROPOSAL();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        address treasury,
        address token,
        address vetoer,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 proposalThresholdBPS,
        uint256 quorumVotesBPS
    ) external;

    // function proposalThreshold() external view returns (uint256);

    // function quorum(uint256 timestamp) external view returns (uint256);

    // function votingDelay() external view returns (uint256);

    // function votingPeriod() external view returns (uint256);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function timelock() external view returns (address);

    // function name() external view returns (string memory);

    // function version() external view returns (string memory);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function propose(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     bytes[] memory calldatas,
    //     string memory description
    // ) external returns (uint256 proposalId);

    // function queue(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     bytes[] memory calldatas,
    //     bytes32 descriptionHash
    // ) external returns (uint256 proposalId);

    // function execute(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     bytes[] memory calldatas,
    //     bytes32 descriptionHash
    // ) external payable returns (uint256 proposalId);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function hashProposal(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     bytes[] memory calldatas,
    //     bytes32 descriptionHash
    // ) external pure returns (uint256);

    // enum ProposalState {
    //     Pending,
    //     Active,
    //     Canceled,
    //     Defeated,
    //     Succeeded,
    //     Queued,
    //     Expired,
    //     Executed
    // }

    // function state(uint256 proposalId) external view returns (ProposalState);

    // function proposalEta(uint256 proposalId) external view returns (uint256);

    // function proposalDeadline(uint256 proposalId) external view returns (uint256);

    // function proposalSnapshot(uint256 proposalId) external view returns (uint256);

    // function proposalVotes(uint256 proposalId)
    //     external
    //     view
    //     returns (
    //         uint256 againstVotes,
    //         uint256 forVotes,
    //         uint256 abstainVotes
    //     );

    // function hasVoted(uint256 proposalId, address account) external view returns (bool);

    // function getVotes(address account, uint256 timestamp) external view returns (uint256);

    // function getVotesWithParams(
    //     address account,
    //     uint256 timestamp,
    //     bytes memory params
    // ) external view returns (uint256);

    // function castVote(uint256 proposalId, uint256 support) external returns (uint256 balance);

    // function castVoteBySig(
    //     uint256 proposalId,
    //     uint256 support,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 balance);

    // function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    error INVALID_TARGET();

    error DELEGATE_CALL_FAILED();

    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Address} from "../utils/Address.sol";

contract InitializableStorageV1 {
    uint8 internal _initialized;
    bool internal _initializing;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol
abstract contract Initializable is InitializableStorageV1 {
    event Initialized(uint256 version);

    error ADDRESS_ZERO();

    error INVALID_INIT();

    error NOT_INITIALIZING();

    error ALREADY_INITIALIZED();

    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface MetadataRendererTypesV1 {
    struct ItemParam {
        uint256 propertyId;
        string name;
        bool isNewProperty;
    }

    struct IPFSGroup {
        string baseUri;
        string extension;
    }

    struct Item {
        uint16 referenceSlot;
        string name;
    }

    struct Property {
        string name;
        Item[] items;
    }

    struct Settings {
        address token;
        address treasury;
        string name;
        string description;
        string contractImage;
        string rendererBase;
    }
}