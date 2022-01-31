// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@api3/airnode-protocol/contracts/rrp/requesters/interfaces/IRrpBeaconServer.sol";
import "./interfaces/ISelfServeRrpBeaconServerWhitelister.sol";

/// @title Contract that allows to whitlist readers on the RrpBeaconServer
/// @dev The SelfServeRrpBeaconServerWhitelister contract has the WhitelistExpirationSetterRole
/// and the IndefiniteWhitelisterRole of the RrpBeaconServer contract. The deployer of this contract
/// can specify the beaconIds for which readers can whitelist themselves. The deployer (also the owner)
/// can also add new beaconIds later for readers to self whitelist themselves.
contract SelfServeRrpBeaconServerWhitelister is
    Ownable,
    ISelfServeRrpBeaconServerWhitelister
{
    address public rrpBeaconServer;

    mapping(bytes32 => uint64) public beaconIdToExpirationTimestamp;
    mapping(bytes32 => bool) public beaconIdToIndefiniteWhitelistStatus;

    /// @param rrpBeaconServerAddress The RrpBeaconServer contract to whitelist readers
    constructor(address rrpBeaconServerAddress) {
        require(
            rrpBeaconServerAddress != address(0),
            "RrpBeaconServer address zero"
        );
        rrpBeaconServer = rrpBeaconServerAddress;
    }

    /// @notice Adds a new beaconId with an expiration timestamp
    /// that can be whitelisted by readers
    /// @param beaconId The beaconId to set an expiration timestamp for
    /// @param expirationTimestamp The expiration timestamp for the beaconId
    function setBeaconIdToExpirationTimestamp(
        bytes32 beaconId,
        uint64 expirationTimestamp
    ) external override onlyOwner {
        beaconIdToExpirationTimestamp[beaconId] = expirationTimestamp;
        emit SetBeaconIdToExpirationTimestamp(beaconId, expirationTimestamp);
    }

    /// @notice Adds a new beaconId with an indefinite whitelist status
    /// that can be whitelisted by readers indefinetly
    /// @param beaconId The beaconId to set an indefinite whitelist status for
    /// @param indefiniteWhitelistStatus The indefinite whitelist status for the beaconId
    function setBeaconIdToIndefiniteWhitelistStatus(
        bytes32 beaconId,
        bool indefiniteWhitelistStatus
    ) external override onlyOwner {
        beaconIdToIndefiniteWhitelistStatus[
            beaconId
        ] = indefiniteWhitelistStatus;
        emit SetBeaconIdToIndefiniteWhitelistStatus(
            beaconId,
            indefiniteWhitelistStatus
        );
    }

    /// @notice Whitelists a reader on the RrpBeaconServer with an expiration timestamp
    /// @param beaconId The beaconId to whitelist
    /// @param reader The reader to whitelist on the beaconId
    function whitelistReader(bytes32 beaconId, address reader)
        external
        override
    {
        uint64 expirationTimestamp = beaconIdToExpirationTimestamp[beaconId];
        bool indefiniteWhitelistStatus = beaconIdToIndefiniteWhitelistStatus[
            beaconId
        ];
        require(
            expirationTimestamp > block.timestamp || indefiniteWhitelistStatus,
            "Cannot whitelist"
        );
        IRrpBeaconServer(rrpBeaconServer).setWhitelistExpiration(
            beaconId,
            reader,
            expirationTimestamp
        );
        IRrpBeaconServer(rrpBeaconServer).setIndefiniteWhitelistStatus(
            beaconId,
            reader,
            indefiniteWhitelistStatus
        );
        emit WhitelistedReader(
            beaconId,
            reader,
            expirationTimestamp,
            indefiniteWhitelistStatus
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity 0.8.9;

interface IRrpBeaconServer {
    event ExtendedWhitelistExpiration(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed sender,
        uint256 expiration
    );

    event SetWhitelistExpiration(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed sender,
        uint256 expiration
    );

    event SetIndefiniteWhitelistStatus(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed sender,
        bool status,
        uint192 indefiniteWhitelistCount
    );

    event RevokedIndefiniteWhitelistStatus(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed setter,
        address sender,
        uint192 indefiniteWhitelistCount
    );

    event SetUpdatePermissionStatus(
        address indexed sponsor,
        address indexed updateRequester,
        bool status
    );

    event RequestedBeaconUpdate(
        bytes32 indexed beaconId,
        address indexed sponsor,
        address indexed requester,
        bytes32 requestId,
        bytes32 templateId,
        address sponsorWallet,
        bytes parameters
    );

    event UpdatedBeacon(
        bytes32 indexed beaconId,
        bytes32 requestId,
        int224 value,
        uint32 timestamp
    );

    function extendWhitelistExpiration(
        bytes32 beaconId,
        address reader,
        uint64 expirationTimestamp
    ) external;

    function setWhitelistExpiration(
        bytes32 beaconId,
        address reader,
        uint64 expirationTimestamp
    ) external;

    function setIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        bool status
    ) external;

    function revokeIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        address setter
    ) external;

    function setUpdatePermissionStatus(address updateRequester, bool status)
        external;

    function requestBeaconUpdate(
        bytes32 beaconId,
        address requester,
        address designatedWallet,
        bytes calldata parameters
    ) external;

    function fulfill(bytes32 requestId, bytes calldata data) external;

    function readBeacon(bytes32 beaconId)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readerCanReadBeacon(bytes32 beaconId, address reader)
        external
        view
        returns (bool);

    function beaconIdToReaderToWhitelistStatus(bytes32 beaconId, address reader)
        external
        view
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount);

    function beaconIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        address setter
    ) external view returns (bool indefiniteWhitelistStatus);

    function sponsorToUpdateRequesterToPermissionStatus(
        address sponsor,
        address updateRequester
    ) external view returns (bool permissionStatus);

    function deriveBeaconId(bytes32 templateId, bytes calldata parameters)
        external
        pure
        returns (bytes32 beaconId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISelfServeRrpBeaconServerWhitelister {
    event SetBeaconIdToExpirationTimestamp(
        bytes32 indexed beaconId,
        uint64 expirationTimestamp
    );
    event SetBeaconIdToIndefiniteWhitelistStatus(
        bytes32 indexed beaconId,
        bool indefiniteWhitelistStatus
    );
    event WhitelistedReader(
        bytes32 indexed beaconId,
        address indexed reader,
        uint64 expirationTimestamp,
        bool indefiniteWhitelistStatus
    );

    function setBeaconIdToExpirationTimestamp(
        bytes32 _beaconId,
        uint64 _expirationTimestamp
    ) external;

    function setBeaconIdToIndefiniteWhitelistStatus(
        bytes32 _beaconId,
        bool _indefiniteWhitelistStatus
    ) external;

    function whitelistReader(bytes32 _beaconId, address _reader) external;

    function beaconIdToExpirationTimestamp(bytes32 _beaconId)
        external
        view
        returns (uint64);

    function beaconIdToIndefiniteWhitelistStatus(bytes32 _beaconId)
        external
        view
        returns (bool);
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