// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./base/EternalStorage.sol";
import "./base/ECDSA.sol";
import "./base/Controller.sol";
import "./base/IDiamondFacet.sol";
import "./base/IPolicyApprovalsFacet.sol";
import "./base/IPolicyCoreFacet.sol";
import ".//PolicyFacetBase.sol";

/**
 * @dev Business-logic for Policy approvals
 */
contract PolicyApprovalsFacet is EternalStorage, Controller, IDiamondFacet, IPolicyApprovalsFacet, PolicyFacetBase {
    using ECDSA for bytes32;

    modifier assertInApprovableState() {
        require(dataUint256["state"] == POLICY_STATE_IN_APPROVAL || dataUint256["state"] == POLICY_STATE_CREATED, "must be in approvable state");
        _;
    }

    /**
     * Constructor
     */
    constructor(address _settings) Controller(_settings) {
        // empty
    }

    // IDiamondFacet

    function getSelectors() public pure override returns (bytes memory) {
        return abi.encodePacked(IPolicyApprovalsFacet.bulkApprove.selector, IPolicyApprovalsFacet.approve.selector, IPolicyApprovalsFacet.getApprovalsInfo.selector);
    }

    // IPolicyApprovalsFacet

    function bulkApprove(bytes[] calldata _signatures) external override assertInApprovableState {
        bytes32 h = dataBytes32["id"];

        bytes32[4] memory roles = [ROLE_PENDING_BROKER, ROLE_PENDING_UNDERWRITER, ROLE_PENDING_CLAIMS_ADMIN, ROLE_PENDING_INSURED_PARTY];

        require(_signatures.length == roles.length, "wrong number of signatures");

        for (uint256 i = 0; i < roles.length; i += 1) {
            _approve(roles[i], h.toEthSignedMessageHash().recover(_signatures[i]));
        }

        _setPolicyState(POLICY_STATE_APPROVED);

        emit BulkApproved(msg.sender);
    }

    function approve(bytes32 _role) external override assertInApprovableState {
        bytes32 newRole = _approve(_role, msg.sender);

        // update state
        if (_isFullyApproved()) {
            _setPolicyState(POLICY_STATE_APPROVED);
        } else {
            _setPolicyState(POLICY_STATE_IN_APPROVAL);
        }

        emit Approved(msg.sender, newRole);
    }

    function getApprovalsInfo()
        public
        view
        override
        returns (
            bool approved_,
            bool insuredPartyApproved_,
            bool underwriterApproved_,
            bool brokerApproved_,
            bool claimsAdminApproved_
        )
    {
        approved_ = _isFullyApproved();
        insuredPartyApproved_ = dataBool["insuredPartyApproved"];
        underwriterApproved_ = dataBool["underwriterApproved"];
        brokerApproved_ = dataBool["brokerApproved"];
        claimsAdminApproved_ = dataBool["claimsAdminApproved"];
    }

    // Internal methods

    function _approve(bytes32 _role, address _approver) private assertBelongsToEntityWithRole(_approver, _role) returns (bytes32) {
        address entity = _getEntityWithRole(_role);

        bytes32 newRole;

        // replace pending role with non-pending version
        if (_role == ROLE_PENDING_UNDERWRITER) {
            newRole = ROLE_UNDERWRITER;
            dataBool["underwriterApproved"] = true;
        } else if (_role == ROLE_PENDING_BROKER) {
            newRole = ROLE_BROKER;
            dataBool["brokerApproved"] = true;
        } else if (_role == ROLE_PENDING_INSURED_PARTY) {
            newRole = ROLE_INSURED_PARTY;
            dataBool["insuredPartyApproved"] = true;
        } else if (_role == ROLE_PENDING_CLAIMS_ADMIN) {
            newRole = ROLE_CLAIMS_ADMIN;
            dataBool["claimsAdminApproved"] = true;
        }

        acl().assignRole(aclContext(), entity, newRole);

        return newRole;
    }

    function _isFullyApproved() private view returns (bool) {
        uint256 numApprovals = dataBool["underwriterApproved"] ? 1 : 0;
        numApprovals += dataBool["insuredPartyApproved"] ? 1 : 0;
        numApprovals += dataBool["brokerApproved"] ? 1 : 0;
        numApprovals += dataBool["claimsAdminApproved"] ? 1 : 0;
        return numApprovals == 4;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Base contract for any upgradeable contract that wishes to store data.
 */
contract EternalStorage {
    // scalars
    mapping(string => address) dataAddress;
    mapping(string => bytes32) dataBytes32;
    mapping(string => int256) dataInt256;
    mapping(string => uint256) dataUint256;
    mapping(string => bool) dataBool;
    mapping(string => string) dataString;
    mapping(string => bytes) dataBytes;
    // arrays
    mapping(string => address[]) dataManyAddresses;
    mapping(string => bytes32[]) dataManyBytes32s;
    mapping(string => int256[]) dataManyInt256;
    mapping(string => uint256[]) dataManyUint256;

    // helpers
    function __i(uint256 i1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, s));
    }

    function __a(address a1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, s));
    }

    function __aa(
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, a2, s));
    }

    function __b(bytes32 b1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(b1, s));
    }

    function __ii(
        uint256 i1,
        uint256 i2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, i2, s));
    }

    function __ia(
        uint256 i1,
        address a1,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, s));
    }

    function __iaa(
        uint256 i1,
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, s));
    }

    function __iaaa(
        uint256 i1,
        address a1,
        address a2,
        address a3,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, a3, s));
    }

    function __ab(address a1, bytes32 b1) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, b1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 *
 * From https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/cryptography/ECDSA.sol
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./SettingsControl.sol";
import "./AccessControl.sol";

/**
 * @dev Base contract for interacting with the ACL and Settings contracts.
 */
contract Controller is AccessControl, SettingsControl {
    /**
     * @dev Constructor.
     * @param _settings Settings address.
     */
    constructor(address _settings) AccessControl(_settings) SettingsControl(_settings) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IDiamondFacet {
    function getSelectors() external pure returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Policy approvals code.
 */
interface IPolicyApprovalsFacet {
    /**
     * @dev Bulk-approve this policy.
     *
     * @param _signatures Signatures in order: broker, underwriter, claims admin, insured party
     */
    function bulkApprove(bytes[] calldata _signatures) external;

    /**
     * @dev Approve this policy.
     *
     * Caller must be a representative of given entity.
     *
     * @param _role Type of pending role the entity of the caller has.
     */
    function approve(bytes32 _role) external;

    /**
     * @dev Get approvals info.
     *
     * @return approved_ Whether the policy has been fully approved.
     * @return insuredPartyApproved_ Whether the insured party has approved the policy.
     * @return underwriterApproved_ Whether the capital provider has approved the policy.
     * @return brokerApproved_ Whether the broker has approved the policy.
     * @return claimsAdminApproved_ Whether the claims administrator has approved the policy.
     */
    function getApprovalsInfo()
        external
        view
        returns (
            bool approved_,
            bool insuredPartyApproved_,
            bool underwriterApproved_,
            bool brokerApproved_,
            bool claimsAdminApproved_
        );

    // events

    /**
     * @dev Emitted when a bulk approval occurs.
     *
     * @param caller The caller.
     */
    event BulkApproved(address indexed caller);

    /**
     * @dev Emitted when an approval occurs.
     *
     * @param approver The approver.
     * @param role The role which approved.
     */
    event Approved(address indexed approver, bytes32 indexed role);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Policy core logic.
 */
interface IPolicyCoreFacet {
    /**
     * @dev Create tranche.
     *
     * @param _numShares No. of shares in this tranche.
     * @param _pricePerShareAmount Price of each share during the initial sale period.
     * @param _premiums Premium payment amounts in chronological order.
     */
    function createTranche(
        uint256 _numShares,
        uint256 _pricePerShareAmount,
        uint256[] calldata _premiums
    ) external;

    /**
     * @dev Get policy info.
     *
     * @return id_ The policy id.
     * @return treasury_ The Entity which acts as this policy's treasury.
     * @return initiationDate_ Initiation date  (seconds since epoch).
     * @return startDate_ Start date  (seconds since epoch).
     * @return maturationDate_ Maturation date (seconds since epoch).
     * @return unit_ Payment unit (for tranche sale, premiums, claim payouts, etc).
     * @return numTranches_ No. of tranches created.
     * @return state_ Current policy state.
     * @return type_ Policy type.
     */
    //  * @return premiumIntervalSeconds_ Time between premium payments (seconds).
    function getInfo()
        external
        view
        returns (
            bytes32 id_,
            address treasury_,
            uint256 initiationDate_,
            uint256 startDate_,
            uint256 maturationDate_,
            address unit_,
            uint256 numTranches_,
            uint256 state_,
            uint256 type_
        );

    /**
     * @dev Get tranche info.
     *
     * @param _index Tranche index.
     * @return token_ Tranche ERC-20 token address.
     * @return state_ Current tranche state.
     * @return numShares_ No. of shares.
     * @return initialPricePerShare_ Initial price per share.
     * @return balance_ Current tranche balance (of the payment unit)
     * @return sharesSold_ No. of shared sold (during the initial sale period).
     * @return initialSaleOfferId_ Market offer id of the initial sale.
     * @return finalBuybackofferId_ Market offer id of the post-maturation/cancellation token buyback.
     * @return buybackCompleted_ True once token buyback has completed.
     */
    function getTrancheInfo(uint256 _index)
        external
        view
        returns (
            address token_,
            uint256 state_,
            uint256 numShares_,
            uint256 initialPricePerShare_,
            uint256 balance_,
            uint256 sharesSold_,
            uint256 initialSaleOfferId_,
            uint256 finalBuybackofferId_,
            bool buybackCompleted_
        );

    /**
     * @dev Get whether the initiation date has passed.
     *
     * @return true if so, false otherwise.
     */
    function initiationDateHasPassed() external view returns (bool);

    /**
     * @dev Get whether the start date has passed.
     *
     * @return true if so, false otherwise.
     */
    function startDateHasPassed() external view returns (bool);

    /**
     * @dev Get whether the maturation date has passed.
     *
     * @return true if so, false otherwise.
     */
    function maturationDateHasPassed() external view returns (bool);

    /**
     * @dev Heartbeat: Ensure the policy and tranche states are up-to-date.
     */
    function checkAndUpdateState() external;

    // events

    /**
     * @dev Emitted when a new tranche has been created.
     * @param index The tranche index.
     */
    event CreateTranche(uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./base/EternalStorage.sol";
import "./base/IPolicyStates.sol";
import "./base/IPolicyTreasury.sol";
import "./base/AccessControl.sol";

/**
 * @dev Policy facet base class
 */
abstract contract PolicyFacetBase is EternalStorage, IPolicyStates, AccessControl {
    modifier assertBelongsToEntityWithRole(address _user, bytes32 _role) {
        require(_belongsToEntityWithRole(_user, _role), "not a rep of associated entity");
        _;
    }

    function _belongsToEntityWithRole(address _user, bytes32 _role) internal view returns (bool) {
        address entity = _getEntityWithRole(_role);
        return _isRepOfEntity(_user, entity);
    }

    function _getEntityWithRole(bytes32 _role) internal view returns (address) {
        address[] memory entities = acl().getUsersForRole(aclContext(), _role);
        require(entities.length > 0, "no entity with role");
        return entities[0];
    }

    function _isRepOfEntity(address _user, address _entity) internal view returns (bool) {
        // check they are a rep
        bytes32 ctx = AccessControl(_entity).aclContext();
        return inRoleGroupWithContext(ctx, _user, ROLEGROUP_ENTITY_REPS);
    }

    function _setPolicyState(uint256 _newState) internal {
        if (dataUint256["state"] != _newState) {
            dataUint256["state"] = _newState;
            emit PolicyStateUpdated(_newState, msg.sender);
        }
    }

    function _setTrancheState(uint256 _trancheIndex, uint256 _newState) internal {
        if (dataUint256[__i(_trancheIndex, "state")] != _newState) {
            dataUint256[__i(_trancheIndex, "state")] = _newState;
            emit TrancheStateUpdated(_trancheIndex, _newState, msg.sender);
        }
    }

    function _getTreasury() internal view returns (IPolicyTreasury) {
        return IPolicyTreasury(dataAddress["treasury"]);
    }

    function _getNumberOfTranchePaymentsMissed(uint256 _index) internal view returns (uint256) {
        uint256 numPremiums = dataUint256[__i(_index, "numPremiums")];
        uint256 numPremiumsPaid = dataUint256[__i(_index, "numPremiumsPaid")];

        uint256 expectedNumPremiumsPaid = 0;

        for (uint256 i = 0; numPremiums > i; i += 1) {
            uint256 dueAt = dataUint256[__ii(_index, i, "premiumDueAt")];

            if (dueAt <= block.timestamp) {
                expectedNumPremiumsPaid += 1;
            }
        }

        if (expectedNumPremiumsPaid >= numPremiumsPaid) {
            return expectedNumPremiumsPaid - numPremiumsPaid;
        } else {
            return 0;
        }
    }

    function _tranchePaymentsAllMade(uint256 _index) internal view returns (bool) {
        uint256 numPremiums = dataUint256[__i(_index, "numPremiums")];
        uint256 numPremiumsPaid = dataUint256[__i(_index, "numPremiumsPaid")];
        return (numPremiumsPaid == numPremiums);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./EternalStorage.sol";
import "./ISettings.sol";
import "./ISettingsControl.sol";
import "./ISettingsKeys.sol";

/**
 * @dev Base contract for interacting with Settings.
 */
contract SettingsControl is EternalStorage, ISettingsControl, ISettingsKeys {
    /**
     * @dev Constructor.
     * @param _settings Settings address.
     */
    constructor(address _settings) {
        dataAddress["settings"] = _settings;
    }

    /**
     * @dev Get Settings reference.
     * @return Settings reference.
     */
    function settings() public view override returns (ISettings) {
        return ISettings(dataAddress["settings"]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./Address.sol";
import "./EternalStorage.sol";
import "./ISettings.sol";
import "./IACL.sol";
import "./IAccessControl.sol";
import "./IACLConstants.sol";

/**
 * @dev Base contract for interacting with the ACL.
 */
contract AccessControl is EternalStorage, IAccessControl, IACLConstants {
    using Address for address;

    /**
     * @dev Constructor.
     * @param _settings Address of Settings.
     */
    constructor(address _settings) {
        dataAddress["settings"] = _settings;
        dataBytes32["aclContext"] = acl().generateContextFromAddress(address(this));
    }

    /**
     * @dev Check that sender is an admin.
     */
    modifier assertIsAdmin() {
        require(isAdmin(msg.sender), "must be admin");
        _;
    }

    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) public view override returns (bool) {
        return acl().isAdmin(_addr);
    }

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) public view override returns (bool) {
        return inRoleGroupWithContext(aclContext(), _addr, _roleGroup);
    }

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) public view override returns (bool) {
        return acl().hasRoleInGroup(_ctx, _addr, _roleGroup);
    }

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() public view override returns (IACL) {
        return ISettings(dataAddress["settings"]).acl();
    }

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() public view override returns (bytes32) {
        return dataBytes32["aclContext"];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./ISettingsKeys.sol";
import "./IACL.sol";

/**
 * @dev Settings.
 */
abstract contract ISettings is ISettingsKeys {
    /**
     * @dev Get ACL.
     */
    function acl() public view virtual returns (IACL);

    /**
     * @dev Get an address.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getAddress(address _context, bytes32 _key) public view virtual returns (address);

    /**
     * @dev Get an address in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootAddress(bytes32 _key) public view virtual returns (address);

    /**
     * @dev Set an address.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setAddress(
        address _context,
        bytes32 _key,
        address _value
    ) external virtual;

    /**
     * @dev Get an address.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getAddresses(address _context, bytes32 _key) public view virtual returns (address[] memory);

    /**
     * @dev Get an address in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootAddresses(bytes32 _key) public view virtual returns (address[] memory);

    /**
     * @dev Set an address.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setAddresses(
        address _context,
        bytes32 _key,
        address[] calldata _value
    ) external virtual;

    /**
     * @dev Get a boolean.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getBool(address _context, bytes32 _key) public view virtual returns (bool);

    /**
     * @dev Get a boolean in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootBool(bytes32 _key) public view virtual returns (bool);

    /**
     * @dev Set a boolean.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setBool(
        address _context,
        bytes32 _key,
        bool _value
    ) external virtual;

    /**
     * @dev Get a number.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getUint256(address _context, bytes32 _key) public view virtual returns (uint256);

    /**
     * @dev Get a number in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootUint256(bytes32 _key) public view virtual returns (uint256);

    /**
     * @dev Set a number.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setUint256(
        address _context,
        bytes32 _key,
        uint256 _value
    ) external virtual;

    /**
     * @dev Get a string.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getString(address _context, bytes32 _key) public view virtual returns (string memory);

    /**
     * @dev Get a string in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootString(bytes32 _key) public view virtual returns (string memory);

    /**
     * @dev Set a string.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setString(
        address _context,
        bytes32 _key,
        string memory _value
    ) external virtual;

    /**
     * @dev Get current block time.
     *
     * @return Block time.
     */
    function getTime() external view virtual returns (uint256);

    // events

    /**
     * @dev Emitted when a setting gets updated.
     * @param context The context.
     * @param key The key.
     * @param caller The caller.
     * @param keyType The type of setting which changed.
     */
    event SettingChanged(address indexed context, bytes32 indexed key, address indexed caller, string keyType);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./ISettings.sol";

interface ISettingsControl {
    /**
     * @dev Get Settings reference.
     * @return Settings reference.
     */
    function settings() external view returns (ISettings);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Settings keys.
 */
contract ISettingsKeys {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant SETTING_MARKET = 0x6f244974cc67342b1bd623d411fd8100ec9eddbac05348e71d1a9296de6264a5;
    bytes32 public constant SETTING_FEEBANK = 0x6a4d660b9f1720511be22f039683db86d0d0d207c2ad9255325630800d4fb539;
    bytes32 public constant SETTING_ETHER_TOKEN = 0xa449044fc5332c1625929b3afecb2f821955279285b4a8406a6ffa8968c1b7cf;
    bytes32 public constant SETTING_ENTITY_IMPL = 0x098afcb3a137a2ba8835fbf7daecb275af5afb3479f12844d5b7bfb8134e7ced;
    bytes32 public constant SETTING_POLICY_IMPL = 0x0e8925aa0bfe65f831f6c9099dd95b0614eb69312630ef3497bee453d9ed40a9;
    bytes32 public constant SETTING_MARKET_IMPL = 0xc72bfe3e0f1799ce0d90c4c72cf8f07d0cfa8121d51cb05d8c827f0896d8c0b6;
    bytes32 public constant SETTING_FEEBANK_IMPL = 0x9574e138325b5c365da8d5cc75cf22323ed6f3ce52fac5621225020a162a4c61;
    bytes32 public constant SETTING_ENTITY_DEPLOYER = 0x1bf52521006d8a3718b0692b7f32c8ee781bfed9e9215eb5b8fc3b34749fb5b5;
    bytes32 public constant SETTING_ENTITY_DELEGATE = 0x063693c9545b949ff498535f9e0aa95ada8e88c062d28e2f219b896e151e1266;
    bytes32 public constant SETTING_POLICY_DELEGATE = 0x5c6c7d4897f0ae38084370e7a61ea386e95c7f54629c0b793a0ac47751f12405;
    // END: Generated by script outputConstants.js
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev ACL (Access Control List).
 */
interface IACL {
    // admin

    /**
     * @dev Check if given address has the admin role.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Assign admin role to given address.
     * @param _addr Address to assign to.
     */
    function addAdmin(address _addr) external;

    /**
     * @dev Remove admin role from given address.
     * @param _addr Address to remove from.
     */
    function removeAdmin(address _addr) external;

    // contexts

    /**
     * @dev Get the no. of existing contexts.
     * @return no. of contexts
     */
    function getNumContexts() external view returns (uint256);

    /**
     * @dev Get context at given index.
     * @param _index Index into list of all contexts.
     * @return context name
     */
    function getContextAtIndex(uint256 _index) external view returns (bytes32);

    /**
     * @dev Get the no. of addresses belonging to (i.e. who have been assigned roles in) the given context.
     * @param _context Name of context.
     * @return no. of addresses
     */
    function getNumUsersInContext(bytes32 _context) external view returns (uint256);

    /**
     * @dev Get the address at the given index in the list of addresses belonging to the given context.
     * @param _context Name of context.
     * @param _index Index into the list of addresses
     * @return the address
     */
    function getUserInContextAtIndex(bytes32 _context, uint256 _index) external view returns (address);

    // users

    /**
     * @dev Get the no. of contexts the given address belongs to (i.e. has an assigned role in).
     * @param _addr Address.
     * @return no. of contexts
     */
    function getNumContextsForUser(address _addr) external view returns (uint256);

    /**
     * @dev Get the contexts at the given index in the list of contexts the address belongs to.
     * @param _addr Address.
     * @param _index Index of context.
     * @return Context name
     */
    function getContextForUserAtIndex(address _addr, uint256 _index) external view returns (bytes32);

    /**
     * @dev Get whether given address has a role assigned in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @return true if so
     */
    function userSomeHasRoleInContext(bytes32 _context, address _addr) external view returns (bool);

    // role groups

    /**
     * @dev Get whether given address has a role in the given rolegroup in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roleGroup The role group.
     * @return true if so
     */
    function hasRoleInGroup(
        bytes32 _context,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Set the roles for the given role group.
     * @param _roleGroup The role group.
     * @param _roles List of roles.
     */
    function setRoleGroup(bytes32 _roleGroup, bytes32[] calldata _roles) external;

    /**
     * @dev Get whether given given name represents a role group.
     * @param _roleGroup The role group.
     * @return true if so
     */
    function isRoleGroup(bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Get the list of roles in the given role group
     * @param _roleGroup The role group.
     * @return role list
     */
    function getRoleGroup(bytes32 _roleGroup) external view returns (bytes32[] memory);

    /**
     * @dev Get the list of role groups which contain given role
     * @param _role The role.
     * @return rolegroup list
     */
    function getRoleGroupsForRole(bytes32 _role) external view returns (bytes32[] memory);

    // roles

    /**
     * @dev Get whether given address has given role in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     * @return either `DOES_NOT_HAVE_ROLE` or one of the `HAS_ROLE_...` constants
     */
    function hasRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external view returns (uint256);

    /**
     * @dev Get whether given address has any of the given roles in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roles The role list.
     * @return true if so
     */
    function hasAnyRole(
        bytes32 _context,
        address _addr,
        bytes32[] calldata _roles
    ) external view returns (bool);

    /**
     * @dev Assign a role to the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     */
    function assignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

    /**
     * @dev Assign a role to the given address in the given context and id.
     * @param _context Context name.
     * @param _id Id.
     * @param _addr Address.
     * @param _role The role.
     */
    // function assignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

    /**
     * @dev Remove a role from the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role to unassign.
     */
    function unassignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

    /**
     * @dev Remove a role from the given address in the given context.
     * @param _context Context name.
     * @param _id Id.
     * @param _addr Address.
     * @param _role The role to unassign.
     */
    // function unassignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

    /**
     * @dev Get all role for given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @return list of roles
     */
    function getRolesForUser(bytes32 _context, address _addr) external view returns (bytes32[] memory);

    /**
     * @dev Get all addresses for given role in the given context.
     * @param _context Context name.
     * @param _role Role.
     * @return list of roles
     */
    function getUsersForRole(bytes32 _context, bytes32 _role) external view returns (address[] memory);

    // who can assign roles

    /**
     * @dev Add given rolegroup as an assigner for the given role.
     * @param _roleToAssign The role.
     * @param _assignerRoleGroup The role group that should be allowed to assign this role.
     */
    function addAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;

    /**
     * @dev Remove given rolegroup as an assigner for the given role.
     * @param _roleToAssign The role.
     * @param _assignerRoleGroup The role group that should no longer be allowed to assign this role.
     */
    function removeAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;

    /**
     * @dev Get all rolegroups that are assigners for the given role.
     * @param _role The role.
     * @return list of rolegroups
     */
    function getAssigners(bytes32 _role) external view returns (bytes32[] memory);

    /**
   * @dev Get whether given address can assign given role within the given context.

   * @param _context Context name.
   * @param _assigner Assigner address.
   * @param _assignee Assignee address.
   * @param _role The role to assign.
   * @return one of the `CANNOT_ASSIGN...` or `CAN_ASSIGN_...` constants
   */
    function canAssign(
        bytes32 _context,
        address _assigner,
        address _assignee,
        bytes32 _role
    ) external view returns (uint256);

    // utility methods

    /**
     * @dev Generate the context name which represents the given address.
     *
     * @param _addr Address.
     * @return context name.
     */
    function generateContextFromAddress(address _addr) external pure returns (bytes32);

    /**
     * @dev Emitted when a role group gets updated.
     * @param roleGroup The rolegroup which got updated.
     */
    event RoleGroupUpdated(bytes32 indexed roleGroup);

    /**
     * @dev Emitted when a role gets assigned.
     * @param context The context within which the role got assigned.
     * @param addr The address the role got assigned to.
     * @param role The role which got assigned.
     */
    event RoleAssigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

    /**
     * @dev Emitted when a role gets unassigned.
     * @param context The context within which the role got assigned.
     * @param addr The address the role got assigned to.
     * @param role The role which got unassigned.
     */
    event RoleUnassigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

    /**
     * @dev Emitted when a role assigner gets added.
     * @param role The role that can be assigned.
     * @param roleGroup The rolegroup that will be able to assign this role.
     */
    event AssignerAdded(bytes32 indexed role, bytes32 indexed roleGroup);

    /**
     * @dev Emitted when a role assigner gets removed.
     * @param role The role that can be assigned.
     * @param roleGroup The rolegroup that will no longer be able to assign this role.
     */
    event AssignerRemoved(bytes32 indexed role, bytes32 indexed roleGroup);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Collection of functions related to the address type
 *
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
library Address {
    /**
     * @dev Returns true if `_account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address _account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(_account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function toPayable(address _account) internal pure returns (address payable) {
        return payable(address(uint160(_account)));
    }

    /**
     * @dev Converts an `address` into `string` hex representation.
     * From https://ethereum.stackexchange.com/a/58341/56159
     */
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IACL.sol";

interface IAccessControl {
    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() external view returns (IACL);

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev ACL Constants.
 */
abstract contract IACLConstants {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant ROLE_APPROVED_USER = 0x9c259f9342405d034b902fd5e1bba083f008e305ea4eb6a0dce9ac9a6256b63a;
    bytes32 public constant ROLE_PENDING_UNDERWRITER = 0xad56f8a5432d383c3e2c11b7b248f889e6ec544090486b3623f0f4ae1fad763b;
    bytes32 public constant ROLE_PENDING_BROKER = 0x3bd41a6d84c7de1e9d18694bd113405090439b9e32d5ab69d575821d513d83b5;
    bytes32 public constant ROLE_PENDING_INSURED_PARTY = 0x052b977cd6067e43b9140f08c53a22b88418f4d3ab7bd811716130d5a20cd8a3;
    bytes32 public constant ROLE_PENDING_CLAIMS_ADMIN = 0x325a96ceff51ae6b22de25dd7b4c8b9532dddf936add8ef16fc99219ff666a84;
    bytes32 public constant ROLE_UNDERWRITER = 0x8858a0dfcbfa158449ee0a3b5dae898cecc0746569152b05bbab9526bcc16864;
    bytes32 public constant ROLE_CAPITAL_PROVIDER = 0x428fa9969c6b3fab7bbdac20b73706f1f670a386be0a76d4060c185898b2aa22;
    bytes32 public constant ROLE_BROKER = 0x2623111b4a77e415ab5147aeb27da976c7a27950b6ec4022b4b9e77176266992;
    bytes32 public constant ROLE_INSURED_PARTY = 0x737de6bdef2e959d9f968f058e3e78b7365d4eda8e4023ecac2d51e3dbfb1401;
    bytes32 public constant ROLE_CLAIMS_ADMIN = 0x391db9b692991836c38aedfd24d7f4c9837739d4ee0664fe4ee6892a51e025a7;
    bytes32 public constant ROLE_ENTITY_ADMIN = 0x0922a3d5a8713fcf92ec8607b882fd2fcfefd8552a3c38c726d96fcde8b1d053;
    bytes32 public constant ROLE_ENTITY_MANAGER = 0xcfd13d23f7313d54f3a6d98c505045c58749561dd04531f9f2422a8818f0c5f8;
    bytes32 public constant ROLE_ENTITY_REP = 0xcca1ad0e9fb374bbb9dc3d0cbfd073ef01bd1d01d5a35bd0a93403fbee64318d;
    bytes32 public constant ROLE_POLICY_OWNER = 0x7f7cc8b2bac31c0e372310212be653d159f17ff3c41938a81446553db842afb6;
    bytes32 public constant ROLE_POLICY_CREATOR = 0x1d60d7146dec74c1b1a9dc17243aaa3b56533f607c16a718bcd78d8d852d6e52;
    bytes32 public constant ROLE_SYSTEM_ADMIN = 0xd708193a9c8f5fbde4d1c80a1e6f79b5f38a27f85ca86eccac69e5a899120ead;
    bytes32 public constant ROLE_SYSTEM_MANAGER = 0x807c518efb8285611b15c88a7701e4f40a0e9a38ce3e59946e587a8932410af8;
    bytes32 public constant ROLEGROUP_APPROVED_USERS = 0x9c687089ee5ebd0bc2ba9c954ebc7a0304b4046890b9064e5742c8c6c7afeab2;
    bytes32 public constant ROLEGROUP_CAPITAL_PROVIDERS = 0x2db57b52c5f263c359ba92194f5590b4a7f5fc1f1ca02f10cea531182851fe28;
    bytes32 public constant ROLEGROUP_POLICY_CREATORS = 0xdd53f360aa973c3daf7ff269398ced1ce7713d025c750c443c2abbcd89438f83;
    bytes32 public constant ROLEGROUP_BROKERS = 0x8d632412946eb879ebe5af90230c7db3f6d17c94c0ecea207c97e15fa9bb77c5;
    bytes32 public constant ROLEGROUP_INSURED_PARTYS = 0x65d0db34d07de31cfb8ca9f95dabc0463ce6084a447abb757f682f36ae3682e3;
    bytes32 public constant ROLEGROUP_CLAIMS_ADMINS = 0x5c7c2bcb0d2dfef15c423063aae2051d462fcd269b5e9b8c1733b3211e17bc8a;
    bytes32 public constant ROLEGROUP_ENTITY_ADMINS = 0x251766d8c7c7a6b927647b0f20c99f490db1c283eb0c482446085aaaa44b5e73;
    bytes32 public constant ROLEGROUP_ENTITY_MANAGERS = 0xa33a59233069411012cc12aa76a8a426fe6bd113968b520118fdc9cb6f49ae30;
    bytes32 public constant ROLEGROUP_ENTITY_REPS = 0x610cf17b5a943fc722922fc6750fb40254c24c6b0efd32554aa7c03b4ca98e9c;
    bytes32 public constant ROLEGROUP_POLICY_OWNERS = 0xc59d706f362a04b6cf4757dd3df6eb5babc7c26ab5dcc7c9c43b142f25da10a5;
    bytes32 public constant ROLEGROUP_SYSTEM_ADMINS = 0xab789755f97e00f29522efbee9df811265010c87cf80f8fd7d5fc5cb8a847956;
    bytes32 public constant ROLEGROUP_SYSTEM_MANAGERS = 0x7c23ac65f971ee875d4a6408607fabcb777f38cf73b3d6d891648646cee81f05;
    bytes32 public constant ROLEGROUP_TRADERS = 0x9f4d1dc1107c7d9d9f533f41b5aa5dbbb3b830e3b597338a8aee228ab083eb3a;
    bytes32 public constant ROLEGROUP_UNDERWRITERS = 0x18ecf8d2173ca8a5766fd7dde3bdb54017dc5413dc07cd6ba1785b63e9c62b82;
    // END: Generated by script outputConstants.js

    // used by canAssign() method
    uint256 public constant CANNOT_ASSIGN = 0;
    uint256 public constant CANNOT_ASSIGN_USER_NOT_APPROVED = 100;
    uint256 public constant CAN_ASSIGN_IS_ADMIN = 1;
    uint256 public constant CAN_ASSIGN_IS_OWN_CONTEXT = 2;
    uint256 public constant CAN_ASSIGN_HAS_ROLE = 3;

    // used by hasRole() method
    uint256 public constant DOES_NOT_HAVE_ROLE = 0;
    uint256 public constant HAS_ROLE_CONTEXT = 1;
    uint256 public constant HAS_ROLE_SYSTEM_CONTEXT = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Policy states
 */
abstract contract IPolicyStates {
    /**
     * @dev State: The policy has just been created.
     */
    uint256 public constant POLICY_STATE_CREATED = 0;
    /**
     * @dev State: The policy is undergoing approval.
     */
    uint256 public constant POLICY_STATE_IN_APPROVAL = 5;
    /**
     * @dev State: All policy approvals have been obtained.
     */
    uint256 public constant POLICY_STATE_APPROVED = 6;
    /**
     * @dev State: The policy initial sale is in progress.
     */
    uint256 public constant POLICY_STATE_INITIATED = 1;
    /**
     * @dev State: The policy initial sale has completed and it is now active.
     */
    uint256 public constant POLICY_STATE_ACTIVE = 2;
    /**
     * @dev State: The policy has matured, but there are pending claims.
     */
    uint256 public constant POLICY_STATE_MATURED = 3;
    /**
     * @dev State: Policy has matured, no pending claims, and shares are being bought back from the market.
     */
    uint256 public constant POLICY_STATE_BUYBACK = 7;
    /**
     * @dev State: Policy has matured, no pending blaims, and all shares have been bought back.
     */
    uint256 public constant POLICY_STATE_CLOSED = 8;
    /**
     * @dev State: The policy got cancelled.
     */
    uint256 public constant POLICY_STATE_CANCELLED = 4;

    /**
     * @dev State: The tranche has just been created.
     */
    uint256 public constant TRANCHE_STATE_CREATED = 0;
    /**
     * @dev State: The tranche initial sale is in progress.
     */
    uint256 public constant TRANCHE_STATE_SELLING = 1;
    /**
     * @dev State: The tranche initial sale has completed it is now active.
     */
    uint256 public constant TRANCHE_STATE_ACTIVE = 2;
    /**
     * @dev State: The tranche has matured.
     */
    uint256 public constant TRANCHE_STATE_MATURED = 3;
    /**
     * @dev State: The tranche has been cancelled.
     */
    uint256 public constant TRANCHE_STATE_CANCELLED = 4;

    // events

    event PolicyStateUpdated(uint256 indexed state, address indexed caller);
    event TrancheStateUpdated(uint256 indexed trancheIndex, uint256 indexed state, address indexed caller);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IPolicyTreasury {
    /**
     * @dev Get aggregate treasury info for given token.
     *
     * @param _unit Token unit.
     * @return realBalance_ Current real balance.
     * @return virtualBalance_ Current virtual balance (sum of all policy balances).
     * @return minBalance_ Current minimum balance needed (sum of all policy minimum balances).
     */
    function getEconomics(address _unit)
        external
        view
        returns (
            uint256 realBalance_,
            uint256 virtualBalance_,
            uint256 minBalance_
        );

    /**
     * @dev Get treasury info for given policy.
     *
     * @param _policy Policy address.
     * @return unit_ Token.
     * @return balance_ Current balance.
     * @return minBalance_ Min. requried balance to fully collateralize policy.
     * @return claimsUnpaidTotalAmount_ Total amount unpaid across all claims for policy.
     */
    function getPolicyEconomics(address _policy)
        external
        view
        returns (
            address unit_,
            uint256 balance_,
            uint256 minBalance_,
            uint256 claimsUnpaidTotalAmount_
        );

    /**
     * @dev Get claim queue info.
     *
     * @param _unit Token unit.
     * @return count_ No. of pending claims (both paid and unpaid).
     * @return unpaidCount_ No. of unpaid pending claims.
     * @return unpaidTotalAmount_ Total amount unpaid across all claims.
     */
    function getClaims(address _unit)
        external
        view
        returns (
            uint256 count_,
            uint256 unpaidCount_,
            uint256 unpaidTotalAmount_
        );

    /**
     * @dev Get queued claim.
     *
     * @param _unit Token unit.
     * @param _index 1-based claim index.
     * @return policy_ The policy.
     * @return recipient_ Claim recipient.
     * @return amount_ Claim amount.
     * @return paid_ Whether claim has been paid yet.
     */
    function getClaim(address _unit, uint256 _index)
        external
        view
        returns (
            address policy_,
            address recipient_,
            uint256 amount_,
            bool paid_
        );

    /**
     * @dev Create a market order.
     *
     * @param _type Order type.
     * @param _sellUnit Unit to sell.
     * @param _sellAmount Amount to sell.
     * @param _buyUnit Unit to buy.
     * @param _buyAmount Amount to buy.
     * @param _feeSchedule Fee schedule to use.
     * @param _notify Observer to notify of trade and/or closure.
     * @param _notifyData Extra metadata to pass to observer.
     *
     * @return Market order id.
     */
    function createOrder(
        bytes32 _type,
        address _sellUnit,
        uint256 _sellAmount,
        address _buyUnit,
        uint256 _buyAmount,
        uint256 _feeSchedule,
        address _notify,
        bytes calldata _notifyData
    ) external returns (uint256);

    /**
     * @dev Cancel token sale order.
     *
     * @param _orderId Market order id
     */
    function cancelOrder(uint256 _orderId) external;

    /**
     * Pay a claim for the callig policy.
     *
     * Once paid the internal minimum collateral level required for the policy will be automatically reduced.
     *
     * @param _recipient Recipient address.
     * @param _amount Amount to pay.
     */
    function payClaim(address _recipient, uint256 _amount) external;

    /**
     * Increase calling policy treasury balance.
     *
     * This should only be called by a policy to inform the treasury to update its
     * internal record of the policy's current balance, e.g. after premium payments are sent to the treasury.
     *
     * @param _amount Amount to add or remove.
     */
    function incPolicyBalance(uint256 _amount) external;

    /**
     * Set minimum balance required to fully collateralize the calling policy.
     *
     * This can only be called once.
     *
     * @param _amount Amount to increase by.
     */
    function setMinPolicyBalance(uint256 _amount) external;

    /**
     * Get whether the given policy is fully collaterlized without any "debt" (e.g. pending claims that are yet to be paid out).
     */
    function isPolicyCollateralized(address _policy) external view returns (bool);

    /**
     * Resolve all unpaid claims with available treasury funds.
     *
     * @param _unit Token unit.
     */
    function resolveClaims(address _unit) external;
}