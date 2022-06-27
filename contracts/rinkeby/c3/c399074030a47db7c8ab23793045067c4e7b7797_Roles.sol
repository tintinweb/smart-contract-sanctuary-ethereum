// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../src/libraries/Constants.sol";

contract Roles is RolesAuthority {
    constructor(address owner, address engine)
        RolesAuthority(owner, Authority(address(0)))
    {
        _initSetup(engine);
    }

    function _initSetup(address engine) internal {
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_SIGNER,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_PROFILE_ADDR,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_BOX_ADDR,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_FEE_BY_TIER,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._WITHDRAW,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_BOX_OPENED,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_STATE,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._ALLOW_SUBSCRIBE_MW,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._UPGRADE_PROFILE,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._UPGRADE_BOX,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._AUTHORIZE_UPGRADE,
            true
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Adapted from Solmate's Auth.sol with initializer replacing the constructor.

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(
        address indexed user,
        Authority indexed newAuthority
    );

    address public owner;

    Authority public authority;

    function __Auth_Init(address _owner, Authority _authority) internal {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig)
        internal
        view
        virtual
        returns (bool)
    {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return
            (address(auth) != address(0) &&
                auth.canCall(user, address(this), functionSig)) ||
            user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(
            msg.sender == owner ||
                authority.canCall(msg.sender, address(this), msg.sig)
        );

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Auth, Authority } from "./Auth.sol";

/// @notice Adapted from Solmate's RolesAuthority.sol using Auth's initializer instead of constructor.

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(
        address indexed user,
        uint8 indexed role,
        bool enabled
    );

    event PublicCapabilityUpdated(
        address indexed target,
        bytes4 indexed functionSig,
        bool enabled
    );

    event RoleCapabilityUpdated(
        uint8 indexed role,
        address indexed target,
        bytes4 indexed functionSig,
        bool enabled
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) {
        Auth.__Auth_Init(_owner, _authority);
    }

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32))
        public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role)
        public
        view
        virtual
        returns (bool)
    {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return
            (uint256(getRolesWithCapability[target][functionSig]) >> role) &
                1 !=
            0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) !=
            getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Constants {
    // Access Control for CyebreEngine
    uint8 internal constant _ENGINE_GOV_ROLE = 1;
    bytes4 internal constant _SET_SIGNER =
        bytes4(keccak256(bytes("setSigner(address)")));
    bytes4 internal constant _SET_PROFILE_ADDR =
        bytes4(keccak256(bytes("setProfileAddress(address)")));
    bytes4 internal constant _SET_BOX_ADDR =
        bytes4(keccak256(bytes("setBoxAddress(address)")));
    bytes4 internal constant _SET_FEE_BY_TIER =
        bytes4(keccak256(bytes("setFeeByTier(uint8,uint256)")));
    bytes4 internal constant _SET_BOX_OPENED =
        bytes4(keccak256(bytes("setBoxGiveawayEnded(bool)")));
    bytes4 internal constant _WITHDRAW =
        bytes4(keccak256(bytes("withdraw(address,uint256)")));
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("upgradeTo(address)")));
    bytes4 internal constant _SET_STATE =
        bytes4(keccak256(bytes("setState(uint8)")));
    bytes4 internal constant _UPGRADE_PROFILE =
        bytes4(keccak256(bytes("upgradeProfile(address)")));
    bytes4 internal constant _UPGRADE_BOX =
        bytes4(keccak256(bytes("upgradeBox(address)")));
    bytes4 internal constant _ALLOW_SUBSCRIBE_MW =
        bytes4(keccak256(bytes("allowSubscribeMw(address,bool)")));

    // EIP712 TypeHash
    bytes32 internal constant _REGISTER_TYPEHASH =
        keccak256(
            "register(address to,string handle,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SUBSCRIBE_TYPEHASH =
        keccak256(
            "subscribeWithSig(uint256[] profileIds,bytes[] subDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_METADATA_TYPEHASH =
        keccak256(
            "setMetadataWithSig(uint256 profileId,string metadata,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_OPERATOR_APPROVAL_TYPEHASH =
        keccak256(
            "setOperatorApprovalWithSign(uint256 profileId,address operator,bool approved,uint256 nonce,uint256 deadline)"
        );

    // Parameters
    uint8 internal constant _MAX_HANDLE_LENGTH = 27;

    // Initial States
    uint256 internal constant _INITIAL_FEE_TIER0 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 0.06 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.03 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.01 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.006 ether;

    // Access Control for UpgradeableBeacon
    bytes4 internal constant _BEACON_UPGRADE_TO =
        bytes4(keccak256(bytes("upgradeTo(address)")));

    // Subscribe NFT
    string internal constant _SUBSCRIBE_NFT_NAME_SUFFIX = "_subscriber";
    string internal constant _SUBSCRIBE_NFT_SYMBOL_SUFFIX = "_SUB";
}