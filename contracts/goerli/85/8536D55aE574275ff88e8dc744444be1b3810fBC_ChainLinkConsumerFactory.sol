// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/allianceblock/oracle/consumers/IBaseConsumer.sol";
import "contracts/allianceblock/oracle/consumers/chainlink/BaseChainLinkConsumer.sol";

contract ChainLinkConsumerFactory is Ownable {
    string public name = "ChainLinkConsumer";
    address public oracle;
    BaseChainLinkConsumer public consumerImplementation;

    // consumer name => consumer address
    mapping(string => address) public getConsumer;
    // msg.sender => consumer address[]
    mapping(address => address[]) public getCreatorConsumer;

    event ConsumerCreated(address consumer, string name);

    modifier onlyConsumerCreator(BaseChainLinkConsumer consumer) {
        bool result;
        if (getCreatorConsumer[msg.sender].length > 0) {
            uint256 length = getCreatorConsumer[msg.sender].length;
            for (uint256 i = 0; i < length; i++) {
                if (getCreatorConsumer[msg.sender][i] == msg.sender) {
                    result = true;
                    break;
                }
            }
        }
        require(result, "Only consumer creator can call this function");
        _;
    }

    constructor(address oracle_, BaseChainLinkConsumer consumerImplementation_) {
        oracle = oracle_;
        consumerImplementation = consumerImplementation_;
        _transferOwnership(_msgSender());
    }

    function getCreatorConsumerLength(address creator) public view returns (uint256) {
        return getCreatorConsumer[creator].length;
    }

    function predictConsumerAddress(string memory name_) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(name_));
        return Clones.predictDeterministicAddress(address(consumerImplementation), salt);
    }

    function create(string calldata name_, address priceFeedAddress) external returns (address) {
        require(getConsumer[name_] == address(0), "Consumer already exists");
        require(bytes(name_).length < 32, "name too long");

        BaseChainLinkConsumer consumer = BaseChainLinkConsumer(Clones.clone(address(consumerImplementation)));
        consumer.initialize(msg.sender, oracle, priceFeedAddress, name, name_);

        getConsumer[name_] = address(consumer);
        getCreatorConsumer[msg.sender].push(address(consumer));

        emit ConsumerCreated(address(consumer), name_);

        return address(consumer);
    }

    /* ============================================================= Clones access ============================================================ */

    function setAdmin(address admin, BaseChainLinkConsumer consumer) external onlyConsumerCreator(consumer) {
        consumer.setAdmin(admin);
    }

    function revokeAdmin(address admin, BaseChainLinkConsumer consumer) external onlyConsumerCreator(consumer) {
        consumer.revokeAdmin(admin);
    }

    /* ============================================================= . ============================================================ */

    /*

    function setDiamondOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }

    function getCreatorConsumerLength(address creator) public view returns (uint256) {
        return getCreatorConsumer[creator].length;
    }

    function create(string calldata name_) external onlyOwner returns (address) {
        require(getConsumer[name_] == address(0), "Consumer already exists");

        BaseChainLinkConsumer consumer = new BaseChainLinkConsumer(_msgSender(), oracle, name, name_);

        emit ConsumerCreated(address(consumer), name_);

        return address(consumer);
    }

    */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseConsumer {
    //function getType() external view returns (Type);

    struct Request {
        uint256 id; // identical to the requestId in Oracle contract
        uint256 timestampMin; // Minimum timestamp for the data to be valid
    }

    event UpdateRequested(uint256 requestId);
    event UpdateReceived(uint256 timestamp, bytes data);

    function getName() external view returns (string memory);

    function getFactoryName() external view returns (string memory);

    /**
     * @notice Request an update from the oracle
     * @param requestId The requestId to be used in the oracle
     * @param age max age of the data to be fulfilled (in seconds) => if 0, request must be fulfilled immediately
     */
    function requestUpdate(uint256 requestId, uint256 age) external;

    //function update(bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/allianceblock/oracle/consumers/IBaseConsumer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/allianceblock/oracle/consumers/chainlink/IPriceFeed.sol";
import "contracts/allianceblock/oracle/libs/LibEncodeDecodeData.sol";

/// @title Consumer for external data sources
/// @notice Updated by backend services
contract BaseChainLinkConsumer is IBaseConsumer, AccessControl {
    /// @notice Name of the consumer
    string public name;
    string public factoryName;
    bool isInitialized;

    address public priceFeed;
    address public oracle;
    ChainLinkPrice public price;

    uint256[] pendingRequestsIds;
    mapping(uint256 => Request) pendingRequests;

    struct ChainLinkPrice {
        int256 price;
        uint256 timestamp;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * DUPLICATE EVENTS FROM ORACLE FOR TESTING PURPOSES
     */
    event RequestFulfilled(uint256 indexed id, bytes data, address consumer);

    /**
     * TODO : Delete in production
     */

    function initialize(
        address admin_,
        address oracle_,
        address priceFeedAddress_,
        string calldata factoryName_,
        string calldata name_
    ) external {
        require(!isInitialized, "Already initialized");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, admin_);
        oracle = oracle_;
        priceFeed = priceFeedAddress_;
        factoryName = factoryName_;
        name = name_;
        isInitialized = true;
    }

    /* ============================================================= Getters ============================================================ */
    function getName() external view returns (string memory) {
        return name;
    }

    function getFactoryName() external view returns (string memory) {
        return factoryName;
    }

    function getPendingRequestsLength() external view returns (uint256) {
        return pendingRequestsIds.length;
    }

    function getRequest(uint256 id) external view returns (Request memory) {
        require(pendingRequests[id].id != 0, "No request with this id");
        return pendingRequests[id];
    }

    /* ============================================================= Consumer functions ============================================================ */
    function update() external onlyRole(ADMIN_ROLE) {
        price.price = IPriceFeed(priceFeed).latestAnswer();
        price.timestamp = IPriceFeed(priceFeed).latestTimestamp();

        // For each pending request, fulfill it
        if (pendingRequestsIds.length > 0) {
            uint256 counter;

            for (uint256 i = 0; i < pendingRequestsIds.length; i++) {
                uint256 requestId = pendingRequestsIds[i];
                uint256 timestampMin = pendingRequests[requestId].timestampMin;

                // Verify age => not update if too old || Delete from pending requests if the request does not exist anymore
                if ((_fulfill(requestId) && price.timestamp >= timestampMin) || !_isRequestPending(requestId)) {
                    delete pendingRequests[requestId];
                } else {
                    counter++;
                }
            }

            if (counter > 0) {
                uint256[] memory stillPendingRequestsIds = new uint256[](counter);
                for (uint256 i = 0; i < pendingRequestsIds.length; i++) {
                    if (pendingRequests[pendingRequestsIds[i]].id != 0) {
                        stillPendingRequestsIds[i] = pendingRequestsIds[i];
                    }
                }
                pendingRequestsIds = stillPendingRequestsIds;
            } else {
                // Reset totally the array
                pendingRequestsIds = new uint256[](0);
            }
        }

        emit UpdateReceived(price.timestamp, LibEncodeDecodeData.encodePrice(price.price));
    }

    /**
     * @notice This function is used to request data from the oracle
     * @param requestId The ID of the request (identical to the one stored in the oracle)
     * @param age Request data no older than age (in seconds) => if 0, request must be fulfilled immediately
     */
    function requestUpdate(uint256 requestId, uint256 age) external {
        require(_msgSender() == oracle, "Only Oracle can call this function");
        require(pendingRequests[requestId].id == 0, "Request already pending");

        uint256 timestampMin = block.timestamp - age;

        // If never updated, price will be 0 => request update
        if (price.timestamp < timestampMin || price.price == 0) {
            if (age == 0) {
                revert("data too old");
            } // If age is 0, request must be fulfilled immediately TODO : Minimum time range (will never be on the same block)
            pendingRequestsIds.push(requestId);
            pendingRequests[requestId] = Request(requestId, timestampMin);
            emit UpdateRequested(requestId);
        } else {
            _fulfill(requestId);
        }
    }

    /* ============================================================= Admin functions ============================================================ */
    function setAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, admin);
    }

    function revokeAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, admin);
    }

    function _fulfill(uint256 requestId) internal returns (bool) {
        bytes memory data_ = LibEncodeDecodeData.encodePrice(price.price);
        bytes memory data = abi.encodeWithSignature("fulfill(uint256,bytes)", requestId, data_); //Encode a call to OracleFacet.fulfill()
        (bool success, ) = oracle.call(data);
        if (!success) {
            return false;
        } else {
            return true;
        }
    }

    function _isRequestPending(uint256 requestId) internal returns (bool) {
        bytes memory data = abi.encodeWithSignature("isFullfilled(uint256)", requestId); //Encode a call to OracleFacet.fulfill()
        (bool success, bytes memory returnData) = oracle.call(data);
        if (!success) {
            return false;
        } else {
            bool isFullfilled = abi.decode(returnData, (bool));
            return !isFullfilled;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/utils/StringNumberUtils.sol";

library LibEncodeDecodeData {
    // TYPE :
    // 0x01 = PythPrice : int64 price + int32expo
    // 0x02 = ChainlinkPrice : int256 price

    // Bytes array structure :
    // 1 byte : TYPE of data
    // 1:32 bytes : data (in case of price, 32 bytes for price + 32 bytes for expo)
    // 33:64 bytes : expo (in case of price, 32 bytes for price + 32 bytes for expo)

    function getType(bytes memory data) internal pure returns (uint8) {
        return uint8(data[0]);
    }

    // Used for chainlinks feeds
    function encodePrice(int256 price) internal pure returns (bytes memory) {
        bytes memory data = new bytes(66);
        data[0] = bytes1(0x01);
        bytes32 priceBytes = bytes32(uint256(price));

        bytes32 expoBytes = bytes32(uint256(int256(-8)));

        for (uint256 i = 0; i < 32; i++) {
            data[i + 1] = priceBytes[i];
            data[i + 33] = expoBytes[i];
        }

        return data;
    }

    // Used for pyth feeds
    function encodePrice(int64 price, int32 expo) internal pure returns (bytes memory) {
        bytes memory data = new bytes(66);
        data[0] = bytes1(0x01);
        bytes32 priceBytes = bytes32(uint256(uint64(price)));

        bytes32 expoBytes = bytes32(uint256(uint32(expo)));

        for (uint256 i = 0; i < 32; i++) {
            data[i + 1] = priceBytes[i];
            data[i + 33] = expoBytes[i];
        }

        return data;
    }

    function decodePrice(bytes memory data) internal pure returns (int64 price, int32 expo) {
        require(data[0] == bytes1(0x01) || data[0] == bytes1(0x02), "Wrong type of data");

        bytes memory priceBytes = new bytes(32);
        bytes memory expoBytes = new bytes(32);

        bytes32 price32;
        bytes32 expo32;

        if (data[0] == bytes1(0x01)) {
            for (uint256 i = 0; i < 32; i++) {
                priceBytes[i] = data[i + 1];
                expoBytes[i] = data[i + 33];
            }

            assembly {
                price32 := mload(add(priceBytes, 32))
                expo32 := mload(add(expoBytes, 32))
            }
        } else {
            for (uint256 i = 0; i < 32; i++) {
                priceBytes[i] = data[i + 1];
            }

            assembly {
                price32 := mload(add(priceBytes, 32))
            }
        }

        price = int64(uint64(uint256(price32)));
        expo = int32(uint32(uint256(expo32)));

        /*
        console.log("price");
        console.logInt(price);
        console.log("expo");
        console.logInt(expo);
        */

        return (price, expo);
    }

    function pricetoString(int64 price, int32 expo) internal pure returns (string memory) {
        uint256 convertedPrice = uint256(uint64(price));
        bool isNegative = expo < 0;

        uint256 rounded;

        if (isNegative) {
            uint256 positiveExpo = (expo == type(int256).min)
                ? uint256(uint32(type(int32).max + 1)) //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                : uint256(-1 * int256(expo));

            rounded = convertedPrice / 10**(positiveExpo - 2); // Let 2 decimals
        } else {
            rounded = convertedPrice * 10**uint256(uint32(expo));
        }

        return StringNumberUtils.fromUint256(rounded, 2, 2, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Provides functions to generate convert numbers to string
 */
library StringNumberUtils {
    function fromInt64(int64 value) internal pure returns (string memory) {
        if (value < 0) {
            uint256 positiveValue = (value == type(int64).min)?
                uint256(uint64(type(int64).max)+1): //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                uint256(uint64(-1 * value));
            return string(abi.encodePacked("-", Strings.toString(positiveValue)));
        } else {
            return Strings.toString(uint256(uint64(value)));
        }
    }

    function fromInt256(
        int256 value,
        uint8 decimals,
        uint8 precision,
        bool truncate
    ) internal pure returns (string memory) {
        if (value < 0) {
            uint256 positiveValue = (value == type(int256).min)?
                uint256(type(int256).max+1): //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                uint256(-1 * value);
            return string(abi.encodePacked("-", fromUint256(positiveValue, decimals, precision, truncate)));
        } else {
            return fromUint256(uint256(value), decimals, precision, truncate);
        }
    }

    /**
     * @param value value to convert
     * @param decimals how many decimals the number has
     * @param precision how many decimals we should show (see also truncate)
     * @param truncate if we need to remove zeroes after the last significant digit
     */
    function fromUint256(
        uint256 value,
        uint8 decimals,
        uint8 precision,
        bool truncate
    ) internal pure returns (string memory) {
        require(precision <= decimals, "StringNumberUtils: incorrect precision");
        if (value == 0) return "0";
        
        if(truncate) {
            uint8 counter;
            uint256 countDigits = value;

            while (countDigits != 0) {
                countDigits /= 10;
                counter++;
            }
            value = value/10**(counter-precision);
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        if (digits <= decimals) {
            digits = decimals + 2; //add "0."
        } else {
            digits = digits + 1; //add "."
        }
        uint256 truncateDecimals = decimals - precision;        
        uint256 bufferLen = digits - truncateDecimals;
        uint256 dotIndex = bufferLen - precision - 1;
        bytes memory buffer = new bytes(bufferLen);
        uint256 index = bufferLen;
        temp = value / 10**truncateDecimals;
        while (temp != 0) {
            index--;
            if (index == dotIndex) {
                buffer[index] = ".";
                index--;
            }
            buffer[index] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        while (index > 0) {
            index--;
            if (index == dotIndex) {
                buffer[index] = ".";
            } else {
                buffer[index] = "0";
            }
        }
        return string(buffer);
        //TODO handle truncate
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}