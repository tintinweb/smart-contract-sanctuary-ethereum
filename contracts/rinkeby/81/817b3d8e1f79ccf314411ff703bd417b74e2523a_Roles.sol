// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../libraries/Constants.sol";
import { CyberEngine } from "./CyberEngine.sol";

/**
 * @title Roles
 * @author CyberConnect
 * @notice This contract is used to set roles.
 */
contract Roles is RolesAuthority {
    constructor(address owner, address engine)
        RolesAuthority(owner, Authority(address(0)))
    {
        _initSetup(engine);
    }

    /**
     * @notice Initializes the roles.
     *
     * @param engine The engine address
     */
    function _initSetup(address engine) internal {
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setSigner.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setProfileAddress.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setBoxAddress.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setFeeByTier.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.withdraw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setState.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.allowSubscribeMw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.allowEssenceMw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.upgradeProfile.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.upgradeBox.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._AUTHORIZE_UPGRADE,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setAnimationTemplate.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setImageTemplate.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.pauseBox.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.pauseProfile.selector,
            true
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

// SPDX-License-Identifier: GPL-3.0-or-later
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library Constants {
    // Access Control for CyebreEngine
    uint8 internal constant _ENGINE_GOV_ROLE = 1;
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("_authorizeUpgrade(address)")));

    // EIP712 TypeHash
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _REGISTER_TYPEHASH =
        keccak256(
            "register(address to,string handle,string avatar,string metadata,uint256 nonce,uint256 deadline)"
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
    bytes32 internal constant _CLAIM_BOX_TYPEHASH =
        keccak256("claimBox(address to,uint256 nonce,uint256 deadline)");

    // Parameters
    uint8 internal constant _MAX_HANDLE_LENGTH = 20;
    uint16 internal constant _MAX_URI_LENGTH = 2000;

    // Initial States
    uint256 internal constant _INITIAL_FEE_TIER0 = 10 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 2 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 1 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.01 ether;

    // Access Control for UpgradeableBeacon
    bytes4 internal constant _BEACON_UPGRADE_TO =
        bytes4(keccak256(bytes("upgradeTo(address)")));

    // Subscribe NFT
    string internal constant _SUBSCRIBE_NFT_NAME_SUFFIX = "_subscriber";
    string internal constant _SUBSCRIBE_NFT_SYMBOL_SUFFIX = "_SUB";
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { EIP712 } from "../dependencies/openzeppelin/EIP712.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "../upgradeability/Initializable.sol";
import { IBoxNFT } from "../interfaces/IBoxNFT.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { ISubscribeMiddleware } from "../interfaces/ISubscribeMiddleware.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { ProfileNFT } from "./ProfileNFT.sol";
import { BoxNFT } from "../periphery/BoxNFT.sol";
import { Auth } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Constants } from "../libraries/Constants.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { CyberEngineStorage } from "../storages/CyberEngineStorage.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice This is the main entry point for the CyberConnect contract.
 */
contract CyberEngine is
    Initializable,
    Auth,
    EIP712,
    UUPSUpgradeable,
    CyberEngineStorage,
    IUpgradeable,
    ICyberEngine
{
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the CyberEngine.
     *
     * @param _owner Owner to set for CyberEngine.
     * @param _profileAddress Profile address to set for CyberEngine.
     * @param _boxAddress Box Address animation url to set for CyberEngine.
     * @param _subscribeNFTBeacon Subscribe NFT beacon to set for CyberEngine.
     * @param _essenceNFTBeacon Subscribe NFT beacon to set for CyberEngine.
     */
    function initialize(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        address _subscribeNFTBeacon,
        address _essenceNFTBeacon,
        RolesAuthority _rolesAuthority
    ) external initializer {
        Auth.__Auth_Init(_owner, _rolesAuthority);
        EIP712.__EIP712_Init("CyberEngine", _VERSION_STRING);

        signer = _owner;
        profileAddress = _profileAddress;
        boxAddress = _boxAddress;
        subscribeNFTBeacon = _subscribeNFTBeacon;
        essenceNFTBeacon = _essenceNFTBeacon;
        _setInitialFees();

        emit Initialize(
            _owner,
            _profileAddress,
            _boxAddress,
            _subscribeNFTBeacon,
            _essenceNFTBeacon
        );
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param _signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address _signer) external requiresAuth {
        require(_signer != address(0), "zero address signer");
        address preSigner = signer;
        signer = _signer;

        emit SetSigner(preSigner, _signer);
    }

    /**
     * @notice Sets the new profile address.
     *
     * @param _profileAddress The profile address.
     * @dev The address can not be zero address.
     */
    function setProfileAddress(address _profileAddress) external requiresAuth {
        require(_profileAddress != address(0), "zero address profile");
        address preProfileAddr = profileAddress;
        profileAddress = _profileAddress;

        emit SetProfileAddress(preProfileAddr, _profileAddress);
    }

    /**
     * @notice Sets the new box address.
     *
     * @param _boxAddress The box address.
     * @dev The address can not be zero address.
     */
    function setBoxAddress(address _boxAddress) external requiresAuth {
        require(_boxAddress != address(0), "zero address box");
        address preBoxAddr = boxAddress;
        boxAddress = _boxAddress;

        emit SetBoxAddress(preBoxAddr, _boxAddress);
    }

    /**
     * @notice Sets the fee for tiers.
     *
     * @param tier The tier number.
     * @param amount The fee amount to set.
     */
    function setFeeByTier(DataTypes.Tier tier, uint256 amount)
        external
        requiresAuth
    {
        _setFeeByTier(tier, amount);
    }

    /**
     * @notice Claims a box nft for a profile.
     *
     * @param to The claimer address.
     * @param sig The EIP712 signature.
     * @return uint256 The box id.
     */
    // TODO: comment
    function claimBox(address to, DataTypes.EIP712Signature calldata sig)
        external
        payable
        returns (uint256)
    {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_BOX_TYPEHASH,
                        to,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );

        uint256 boxId = IBoxNFT(boxAddress).mint(to);
        emit ClaimBox(to, boxId);

        return boxId;
    }

    /**
     * @notice Register a new profile.
     *
     * @param params The new profile parameters.
     * @param sig The EIP712 signature.
     * @return uint256 The profile id.
     */
    function register(
        DataTypes.CreateProfileParams calldata params,
        DataTypes.EIP712Signature calldata sig
    ) external payable returns (uint256) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        nonces[params.to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );

        _requireEnoughFee(params.handle, msg.value);

        (uint256 profileId, bool primaryProfileSet) = IProfileNFT(
            profileAddress
        ).createProfile(params);
        emit Register(
            params.to,
            profileId,
            params.handle,
            params.avatar,
            params.metadata
        );
        if (primaryProfileSet) {
            emit SetPrimaryProfile(params.to, profileId);
        }

        return profileId;
    }

    /**
     * @notice Withdraw to an address.
     *
     * @param to The receiver address.
     * @param amount The amount sent.
     */
    function withdraw(address to, uint256 amount) external requiresAuth {
        require(to != address(0), "withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);

        emit Withdraw(to, amount);
    }

    /**
     * @notice Sets the tier fee.
     *
     * @param tier The tier number.
     * @param amount The fee amount.
     */
    function _setFeeByTier(DataTypes.Tier tier, uint256 amount) internal {
        uint256 preAmount = feeMapping[tier];
        feeMapping[tier] = amount;

        emit SetFeeByTier(tier, preAmount, amount);
    }

    /**
     * @notice Sets the initial tier fee.
     */
    function _setInitialFees() internal {
        _setFeeByTier(DataTypes.Tier.Tier0, Constants._INITIAL_FEE_TIER0);
        _setFeeByTier(DataTypes.Tier.Tier1, Constants._INITIAL_FEE_TIER1);
        _setFeeByTier(DataTypes.Tier.Tier2, Constants._INITIAL_FEE_TIER2);
        _setFeeByTier(DataTypes.Tier.Tier3, Constants._INITIAL_FEE_TIER3);
        _setFeeByTier(DataTypes.Tier.Tier4, Constants._INITIAL_FEE_TIER4);
        _setFeeByTier(DataTypes.Tier.Tier5, Constants._INITIAL_FEE_TIER5);
    }

    /**
     * @notice Checks if the EIP712 signature is valid.
     *
     * @param digest The data digest
     * @param expectedSigner The expected signer address.
     * @param sig The signature data type
     */
    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Deadline expired");
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == expectedSigner, "Invalid signature");
    }

    /**
     * @notice Checks if the fee is enough.
     *
     * @param handle The profile handle.
     * @param amount The msg value.
     */
    function _requireEnoughFee(string calldata handle, uint256 amount)
        internal
        view
    {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = feeMapping[DataTypes.Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = feeMapping[DataTypes.Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "Insufficient fee");
    }

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids to subscribed to.
     * @param subDatas The subscription data set.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return memory The subscription nft ids.
     */
    function subscribeWithSig(
        uint256[] calldata profileIds,
        bytes[] calldata subDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused returns (uint256[] memory) {
        uint256 length = subDatas.length;
        bytes32[] memory hashes = new bytes32[](length);
        for (uint256 i = 0; i < length; ) {
            hashes[i] = keccak256(subDatas[i]);
            unchecked {
                ++i;
            }
        }

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SUBSCRIBE_TYPEHASH,
                        keccak256(abi.encodePacked(profileIds)),
                        keccak256(abi.encodePacked(hashes)),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _subscribe(sender, profileIds, subDatas);
    }

    /**
     * @notice The subscription functionality.
     *
     * @param profileIds The profile ids to subscribed to.
     * @param subDatas The subscription data set.
     * @return memory The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(uint256[] calldata profileIds, bytes[] calldata subDatas)
        external
        whenNotPaused
        returns (uint256[] memory)
    {
        return _subscribe(msg.sender, profileIds, subDatas);
    }

    /**
     * @notice The subscription functionality.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids to subscribed to.
     * @param subDatas The subscription data set.
     * @return memory The subscription nft ids.
     */
    function _subscribe(
        address sender,
        uint256[] calldata profileIds,
        bytes[] calldata subDatas
    ) internal returns (uint256[] memory) {
        require(profileIds.length > 0, "No profile ids provided");
        require(
            profileIds.length == subDatas.length,
            "Length missmatch ids & sub datas"
        );
        uint256[] memory result = new uint256[](profileIds.length);
        for (uint256 i = 0; i < profileIds.length; i++) {
            address subscribeNFT = _subscribeByProfileId[profileIds[i]]
                .subscribeNFT;
            address subscribeMw = _subscribeByProfileId[profileIds[i]]
                .subscribeMw;

            // lazy deploy subscribe NFT
            if (subscribeNFT == address(0)) {
                bytes memory initData = abi.encodeWithSelector(
                    ISubscribeNFT.initialize.selector,
                    profileIds[i]
                );
                subscribeNFT = address(
                    new BeaconProxy(subscribeNFTBeacon, initData)
                );
                _subscribeByProfileId[profileIds[i]]
                    .subscribeNFT = subscribeNFT;
                emit DeploySubscribeNFT(profileIds[i], subscribeNFT);
            }
            // run middleware before subscribe
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).preProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    subDatas[i]
                );
            }
            result[i] = ISubscribeNFT(subscribeNFT).mint(sender);
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).postProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    subDatas[i]
                );
            }
        }

        emit Subscribe(sender, profileIds, subDatas);
        return result;
    }

    /**
     * @notice Checks that the state is not paused.
     */
    modifier whenNotPaused() {
        require(_state != DataTypes.State.Paused, "Contract is paused");
        _;
    }

    // TODO: maybe remove essence
    modifier whenEssensePaused() {
        require(_state != DataTypes.State.EssensePaused, "Essense is paused");
        _;
    }

    /**
     * @notice Gets the contract state.
     *
     * @return State The contract state.
     */
    function getState() external view returns (DataTypes.State) {
        return _state;
    }

    /**
     * @notice Sets the contract state.
     *
     * @param state The new state to set.
     */
    function setState(DataTypes.State state) external requiresAuth {
        DataTypes.State preState = _state;
        _state = state;

        emit SetState(preState, state);
    }

    /**
     * @notice Checks that the profile owner is the sender address.
     */
    modifier onlyProfileOwner(uint256 profileId) {
        require(
            ERC721(profileAddress).ownerOf(profileId) == msg.sender,
            "Only profile owner"
        );
        _;
    }

    /**
     * @notice Checks that the profile owner or operator is the sender address.
     */
    modifier onlyOwnerOrOperator(uint256 profileId) {
        require(
            ERC721(profileAddress).ownerOf(profileId) == msg.sender ||
                IProfileNFT(profileAddress).getOperatorApproval(
                    profileId,
                    msg.sender
                ),
            "Only profile owner or operator"
        );
        _;
    }

    /**
     * @notice Sets the Profile NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        onlyOwnerOrOperator(profileId)
    {
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);

        emit SetMetadata(profileId, metadata);
    }

    /**
     * @notice Sets the primary profile id for the user
     *
     * @param profileId The profile ID.
     */
    function setPrimaryProfile(uint256 profileId)
        external
        onlyProfileOwner(profileId)
    {
        IProfileNFT(profileAddress).setPrimaryProfile(msg.sender, profileId);

        emit SetPrimaryProfile(msg.sender, profileId);
    }

    /**
     * @param user the user address
     * @return uint256 the primary profile id
     */
    function getPrimaryProfile(address user) external view returns (uint256) {
        return IProfileNFT(profileAddress).getPrimaryProfile(user);
    }

    /**
     * @notice Sets the Profile NFT avatar.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar url to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        onlyOwnerOrOperator(profileId)
    {
        IProfileNFT(profileAddress).setAvatar(profileId, avatar);

        emit SetAvatar(profileId, avatar);
    }

    /**
     * @notice Sets the Profile NFT animation url.
     *
     * @param template The new template url to set.
     */
    function setAnimationTemplate(string calldata template)
        external
        requiresAuth
    {
        IProfileNFT(profileAddress).setAnimationTemplate(template);

        emit SetAnimationTemplate(template);
    }

    /**
     * @notice Sets the Profile NFT image.
     *
     * @param template The new template url to set.
     */
    function setImageTemplate(string calldata template) external requiresAuth {
        IProfileNFT(profileAddress).setImageTemplate(template);

        emit SetImageTemplate(template);
    }

    /**
     * @notice Sets the profile metadata with a signture.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to be set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external {
        address owner = ERC721(profileAddress).ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_METADATA_TYPEHASH,
                        profileId,
                        keccak256(bytes(metadata)),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);

        emit SetMetadata(profileId, metadata);
    }

    /**
     * @notice Sets the operator approval.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The new state of the approval.
     */
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external onlyProfileOwner(profileId) {
        IProfileNFT(profileAddress).setOperatorApproval(
            profileId,
            operator,
            approved
        );

        emit SetOperatorApproval(profileId, operator, approved);
    }

    /**
     * @notice Sets the operator approval with a signature.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The new state of the approval.
     * @param sig The EIP712 signature.
     */
    function setOperatorApprovalWithSig(
        uint256 profileId,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external {
        address owner = ERC721(profileAddress).ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                        profileId,
                        operator,
                        approved,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        IProfileNFT(profileAddress).setOperatorApproval(
            profileId,
            operator,
            approved
        );
        emit SetOperatorApproval(profileId, operator, approved);
    }

    // upgrade
    function upgradeProfile(address newImpl) external requiresAuth {
        UUPSUpgradeable(profileAddress).upgradeTo(newImpl);
    }

    function upgradeBox(address newImpl) external requiresAuth {
        UUPSUpgradeable(boxAddress).upgradeTo(newImpl);
    }

    // pause
    function pauseProfile(bool toPause) external requiresAuth {
        ProfileNFT(profileAddress).pause(toPause);
    }

    function pauseBox(bool toPause) external requiresAuth {
        BoxNFT(boxAddress).pause(toPause);
    }

    /// @inheritdoc ICyberEngine
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _subscribeByProfileId[profileId].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getSubscribeNFT(uint256 profileId)
        external
        view
        virtual
        override
        returns (address)
    {
        return _subscribeByProfileId[profileId].subscribeNFT;
    }

    /**
     * @notice Allows the subscriber middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowSubscribeMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _subscribeMwAllowlist[mw];
        _subscribeMwAllowlist[mw] = allowed;
        emit AllowSubscribeMw(mw, preAllowed, allowed);
    }

    /**
     * @notice Checks if the subscriber middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isSubscribeMwAllowed(address mw) external view returns (bool) {
        return _subscribeMwAllowlist[mw];
    }

    /**
     * @notice Allows the essence middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowEssenceMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _essenceMwAllowlist[mw];
        _essenceMwAllowlist[mw] = allowed;
        emit AllowEssenceMw(mw, preAllowed, allowed);
    }

    /**
     * @notice Checks if the essence middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isEssenceMwAllowed(address mw) external view returns (bool) {
        return _essenceMwAllowlist[mw];
    }

    /**
     * @notice Gets a profile subscribe middleware address.
     *
     * @param profileId The profile id.
     * @return address The middleware address.
     */
    function getSubscribeMw(uint256 profileId) external view returns (address) {
        return _subscribeByProfileId[profileId].subscribeMw;
    }

    // TODO: withSig
    function setSubscribeMw(uint256 profileId, address mw)
        external
        onlyProfileOwner(profileId)
    {
        require(_subscribeMwAllowlist[mw], "Subscribe middleware not allowed");
        address preMw = _subscribeByProfileId[profileId].subscribeMw;
        _subscribeByProfileId[profileId].subscribeMw = mw;
        emit SetSubscribeMw(profileId, preMw, mw);
    }

    // UUPS upgradeability
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}

    // UUPS upgradeability
    modifier canUpgrade() {
        require(
            isAuthorized(msg.sender, Constants._AUTHORIZE_UPGRADE),
            "UNAUTHORIZED"
        );

        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/// @notice Adapted from OpenZeppelin's draft-EIP712.sol with initializer replacing the constructor.

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_Init(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * Inspired by Openzeppelin's Initializable contract, but simplified for our use case.
 * Explicitly removed support for modifier `initializer` on constructor.
 * Only use `initializer` modifier on the outermost contract and use `onlyInitializing` on the
 * dependencies's init functions.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract Parent, Initializable {
 *     uint256 key;
 *     function __Parent_Init(uint256 _key) onlyInitializing public {
 *         key = _key;
 *     }
 * }
 * contract Child is Parent, Initializable {
 *     function initialize(uint256 _key) initializer external {
 *         __Parent_Init(_key);
 *     }
 * }
 * ```
 */
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            isTopLevelCall && _initialized < 1,
            "Contract already initialized"
        );
        _initialized = 1;
        _initializing = true;
        _;
        _initializing = false;
    }

    // For internal base contracts' initialize function
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    // For constructor
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IBoxNFT {
    /**
     * @notice Mints the Box NFT.
     *
     * @param _to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address _to) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    /**
     * @notice Creates a profile and mints it to the recipient address.
     *
     * @param params contains the recipient, handle, avatar and metadata.
     * @return uint256 profile id of the newly minted profile.
     *
     * @dev The current function validates the caller address and the handle before minting
     * and the following conditions must be met:
     * - The caller address must be the engine address.
     * - The recipient address must be a valid Ethereum address.
     * - The handle must contain only a-z, A-Z, 0-9.
     * - The handle must not be already used.
     * - The handle must not be longer than 27 bytes.
     * - The handle must not be empty.
     */
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256, bool);

    /**
     * @notice Gets the profile handle by ID.
     *
     * @param profileId The profile ID.
     * @return memory the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile ID by handle.
     *
     * @param handle The profile handle.
     * @return memory the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Sets the NFT animation url.
     *
     * @param template The new template url to set.
     */
    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Sets the NFT image.
     *
     * @param template The new template url to set.
     */
    function setImageTemplate(string calldata template) external;

    /**
     * @notice Sets the NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar) external;

    /**
     * @notice Gets the profile metadata.
     *
     * @param profileId The profile ID.
     * @return memory The metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the animation template url.
     *
     * @return memory The animation template url.
     */
    function getAnimationTemplate() external view returns (string memory);

    /**
     * @notice Gets the image template url.
     *
     * @return memory The image template url.
     */
    function getImageTemplate() external view returns (string memory);

    /**
     * @notice Gets the profile avatar.
     *
     * @param profileId The profile ID.
     * @return memory The avatar of the profile.
     */
    function getAvatar(uint256 profileId) external view returns (string memory);

    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;

    /**
     * @notice Sets the primary profile for the user
     *
     * @param user The address of the user
     * @param profileId The profile ID that is set to be primary
     */
    function setPrimaryProfile(address user, uint256 profileId) external;

    /**
     * @notice Gets the primary profile of the user
     *
     * @param user The wallet address of the user
     * @return profileId The primary profile of the user
     */
    function getPrimaryProfile(address user)
        external
        view
        returns (uint256 profileId);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeNFT {
    /**
     * @notice Mints the Subscribe NFT.
     *
     * @param to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Initializes the Subscribe NFT.
     *
     * @param profileId The profile ID to set for the Subscribe NFT.
     */
    function initialize(uint256 profileId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeMiddleware {
    /**
     * @notice Proccess that runs before the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscrbeNFT The subscribe nft address.
     * @param data The subscription data.
     */
    function preProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Proccess that runs after the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscrbeNFT The subscribe nft address.
     * @param data The subscription data.
     */
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

interface ICyberEngine is ICyberEngineEvents {
    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param profileId The profile ID.
     * @return memory The Subscribe NFT token URI.
     */
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Subscribe NFT address.
     *
     * @param profileId The profile ID.
     * @return address The Subscribe NFT address.
     */
    function getSubscribeNFT(uint256 profileId) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { LibString } from "../libraries/LibString.sol";
import { Base64 } from "../dependencies/openzeppelin/Base64.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ProfileNFTStorage } from "../storages/ProfileNFTStorage.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { CyberEngine } from "./CyberEngine.sol";
import { StaticNFTSVG } from "../libraries/StaticNFTSVG.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */

contract ProfileNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    // Immutable
    address public immutable ENGINE; // solhint-disable-line

    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
        _disableInitializers();
    }

    /**
     * @notice Initializes the Profile NFT.
     *
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     * @param animationTemplate Template animation url to set for the Profile NFT.
     * @param imageTemplate symbol to set for the Profile NFT.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        string calldata animationTemplate,
        string calldata imageTemplate
    ) external initializer {
        CyberNFTBase._initialize(name, symbol, _VERSION_STR);
        _animationTemplate = animationTemplate;
        _imageTemplate = imageTemplate;
        // start with paused
        _pause();
    }

    /// @inheritdoc IProfileNFT
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        override
        onlyEngine
        returns (uint256 id, bool primaryProfileSet)
    {
        _requiresValidHandle(params.handle);

        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "Handle taken");

        id = _mint(params.to);

        _profileById[_totalCount] = DataTypes.ProfileStruct({
            handle: params.handle,
            avatar: params.avatar
        });

        _profileIdByHandleHash[handleHash] = _totalCount;
        _metadataById[_totalCount] = params.metadata;

        if (_addressToPrimaryProfile[params.to] == 0) {
            _setPrimaryProfile(params.to, id);
            primaryProfileSet = true;
        }
    }

    /// @inheritdoc IProfileNFT
    function getHandleByProfileId(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        require(_exists(profileId), "ERC721: invalid token ID");
        return _profileById[profileId].handle;
    }

    /// @inheritdoc IProfileNFT
    function getProfileIdByHandle(string calldata handle)
        external
        view
        override
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
    }

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return memory The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory handle = _profileById[tokenId].handle;
        string memory formattedName = string(abi.encodePacked("@", handle));
        string memory animationURL = string(
            abi.encodePacked(_animationTemplate, "?handle=", handle)
        );
        string memory imageURL = string(
            abi.encodePacked(_imageTemplate, "?handle=", handle)
        );
        address subscribeNFT = CyberEngine(ENGINE).getSubscribeNFT(tokenId);
        uint256 subscribers;
        if (subscribeNFT == address(0)) {
            subscribers = 0;
        } else {
            subscribers = CyberNFTBase(subscribeNFT).totalSupply();
        }
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            formattedName,
                            '","description":"CyberConnect profile for ',
                            formattedName,
                            '","image":"',
                            StaticNFTSVG.draw(handle),
                            '","animation_url":"',
                            animationURL,
                            '","attributes":',
                            _genAttributes(
                                LibString.toString(tokenId),
                                LibString.toString(bytes(handle).length),
                                LibString.toString(subscribers),
                                formattedName
                            ),
                            "}"
                        )
                    )
                )
            );
    }

    function _genAttributes(
        string memory tokenId,
        string memory length,
        string memory subscribers,
        string memory name
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type":"id","value":"',
                tokenId,
                '"},{"trait_type":"length","value":"',
                length,
                '"},{"trait_type":"subscribers","value":"',
                subscribers,
                '"},{"trait_type":"handle","value":"',
                name,
                '"}]'
            );
    }

    /**
     * @notice Verifies a handle for length and invalid characters.
     *
     * @param handle The handle to verify.
     * @dev Throws if:
     * - handle is empty
     * - handle is too long
     * - handle contains invalid characters
     */
    function _requiresValidHandle(string calldata handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
                byteHandle.length > 0,
            "Handle has invalid length"
        );

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            require(
                (b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_",
                "Handle has invalid character"
            );
            // optimation
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IProfileNFT
    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        override
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    /// @inheritdoc IProfileNFT
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external override onlyEngine {
        require(operator != address(0), "Operator address cannot be 0");
        _operatorApproval[profileId][operator] = approved;
    }

    /// @inheritdoc IProfileNFT
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        override
        onlyEngine
    {
        require(
            bytes(metadata).length <= Constants._MAX_URI_LENGTH,
            "Metadata has invalid length"
        );
        _metadataById[profileId] = metadata;
    }

    /// @inheritdoc IProfileNFT
    function getMetadata(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _metadataById[profileId];
    }

    /// @inheritdoc IProfileNFT
    function getAvatar(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].avatar;
    }

    /// @inheritdoc IProfileNFT
    function setAnimationTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        _animationTemplate = template;
    }

    /// @inheritdoc IProfileNFT
    function setImageTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        _imageTemplate = template;
    }

    /// @inheritdoc IProfileNFT
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        override
        onlyEngine
    {
        require(
            bytes(avatar).length <= Constants._MAX_URI_LENGTH,
            "Avatar has invalid length"
        );
        _profileById[profileId].avatar = avatar;
    }

    /// @inheritdoc IProfileNFT
    function getAnimationTemplate()
        external
        view
        override
        returns (string memory)
    {
        return _animationTemplate;
    }

    /// @inheritdoc IProfileNFT
    function getImageTemplate() external view override returns (string memory) {
        return _imageTemplate;
    }

    // TODO: write a test for upgrade profile nft
    // UUPS upgradeability
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}

    // pausable
    function pause(bool toPause) external onlyEngine {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    // @inheritdoc IProfileNFT
    // sets a primary profile id for the user
    function setPrimaryProfile(address user, uint256 profileId)
        public
        override
        onlyEngine
    {
        _requireMinted(profileId);
        _setPrimaryProfile(user, profileId);
    }

    function _setPrimaryProfile(address user, uint256 profileId) internal {
        _addressToPrimaryProfile[user] = profileId;
    }

    // @inheritdoc IProfileNFT
    // returns the primary profile id associated with the user
    function getPrimaryProfile(address user)
        external
        view
        override
        returns (uint256)
    {
        return _addressToPrimaryProfile[user];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IBoxNFT } from "../interfaces/IBoxNFT.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { BoxNFTStorage } from "../storages/BoxNFTStorage.sol";

/**
 * @title Box NFT
 * @author CyberConnect
 * @notice This contract is used to create Box NFT.
 */
contract BoxNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    BoxNFTStorage,
    IUpgradeable,
    IBoxNFT
{
    address public immutable ENGINE; // solhint-disable-line

    /**
     * @notice Checks that sender is engine address.
     */
    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    // ENGINE for mint
    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
        _disableInitializers();
    }

    /**
     * @notice Initializes the Box NFT.
     *
     * @param _name The name to set for the Box NFT.
     * @param _symbol The symbol to set for the Box NFT.
     */
    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        CyberNFTBase._initialize(_name, _symbol, _VERSION_STR);
        // start with paused
        _pause();
    }

    /// @inheritdoc IBoxNFT
    function mint(address _to) external override onlyEngine returns (uint256) {
        return super._mint(_to);
    }

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return memory The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return "";
    }

    // TODO: write a test for upgrade box nft
    // UUPS upgradeability
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}

    /**
     * @notice Changes the pause state of the box nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external onlyEngine {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    /**
     * @notice Transfers the box nft.
     *
     * @param from The initial owner address.
     * @param to The receipient address.
     * @param from The nft id.
     * @dev It requires the state to be unpaused
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    struct CreateProfileParams {
        address to;
        string handle;
        string avatar;
        string metadata;
    }

    struct ProfileStruct {
        string handle;
        string avatar;
    }

    struct SubscribeStruct {
        address subscribeNFT;
        address subscribeMw;
        string tokenURI;
    }

    struct EssenceStruct {
        address essenceNFT;
        address essenceMw;
        string tokenURI;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    enum State {
        Operational, // green light, all running
        EssensePaused, // cannot issue new essense, TODO: maybe remove for now
        Paused // everything paused
    }

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

/// @notice Adapted from Solmate's ERC721.sol with initializer replacing the constructor.
// Also used getter function for name and symbol for downstream customization

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string internal _name;

    string internal _symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function __ERC721_Init(string calldata name_, string calldata symbol_)
        internal
    {
        _name = name_;
        _symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) == ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract CyberEngineStorage {
    // constant
    string internal constant _VERSION_STRING = "1"; // for 712, should never  change
    uint256 internal constant _VERSION = 1;

    // storage
    DataTypes.State internal _state;
    address public profileAddress;
    address public boxAddress;
    address public signer;

    // Shared between register and other withSig functions. Always query onchain to get the current nounce
    mapping(uint256 => DataTypes.SubscribeStruct)
        internal _subscribeByProfileId;
    mapping(address => uint256) public nonces;
    address public subscribeNFTBeacon;
    mapping(DataTypes.Tier => uint256) public feeMapping;
    mapping(address => bool) internal _subscribeMwAllowlist;
    address public essenceNFTBeacon;
    mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByProfileId;
    mapping(address => bool) internal _essenceMwAllowlist;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IUpgradeable {
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)
// Use the gas efficient LibString library

pragma solidity ^0.8.0;

import "../../libraries/LibString.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", LibString.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    /**
     * @dev Emitted when the CyberEngine is initialized.
     *
     * @param owner Owner to set for CyberEngine.
     * @param profileAddress Profile address to set for CyberEngine.
     * @param boxAddress Box Address to set for CyberEngine.
     * @param subscribeNFTBeacon Subscribe NFT beacon to set for CyberEngine.
     * @param essenceNFTBeacon Essence NFT beacon to set for CyberEngine.
     */
    event Initialize(
        address indexed owner,
        address profileAddress,
        address boxAddress,
        address subscribeNFTBeacon,
        address essenceNFTBeacon
    );

    /**
     * @dev Emitted when a new signer has been set.
     *
     * @param preSigner The previous signer address.
     * @param newSigner The newly set signer address.
     */
    event SetSigner(address indexed preSigner, address indexed newSigner);

    /**
     * @dev Emitted when a new profile address has been set.
     *
     * @param preProfileAddr The previous profile address.
     * @param newProfileAddr The newly set profile address.
     */
    event SetProfileAddress(
        address indexed preProfileAddr,
        address indexed newProfileAddr
    );

    /**
     * @dev Emitted when a new box address has been set.
     *
     * @param preBoxAddr The previous box address.
     * @param newBoxAddress The newly set box address.
     */
    event SetBoxAddress(
        address indexed preBoxAddr,
        address indexed newBoxAddress
    );

    /**
     * @notice Emitted when a new fee for tiers has been set.
     *
     * @param tier The tier number.
     * @param preAmount The previous fee amount.
     * @param newAmount The newly set fee amount.
     */
    event SetFeeByTier(
        DataTypes.Tier indexed tier,
        uint256 indexed preAmount,
        uint256 indexed newAmount
    );

    /**
     * @notice Emitted when the box giveaway state has been set to `ended`.
     *
     * @param preEnded The previous box giveaway state.
     * @param newEnded The newly set box giveaway state.
     */
    event SetBoxGiveawayEnded(bool indexed preEnded, bool indexed newEnded);

    /**
     * @notice Emitted when a new state has been set.
     *
     * @param preState The previous state.
     * @param newState The newly set state.
     */
    event SetState(
        DataTypes.State indexed preState,
        DataTypes.State indexed newState
    );

    /**
     * @notice Emitted when a new animation template has been set.
     *
     * @param newTemplate The newly set animation template.
     */
    event SetAnimationTemplate(string indexed newTemplate);

    /**
     * @notice Emitted when a new image template has been set.
     *
     * @param newTemplate The newly set image template.
     */
    event SetImageTemplate(string indexed newTemplate);

    /**
     * @notice Emitted when a new metadata has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newMetadata The newly set metadata.
     */
    event SetMetadata(uint256 indexed profileId, string newMetadata);

    /**
     * @notice Emitted when a primary profile has been set.
     *
     * @param profileId The profile id.
     */
    event SetPrimaryProfile(address indexed user, uint256 indexed profileId);

    /**
     * @notice Emitted when a new avatar has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newAvatar The newly set avatar.
     */
    event SetAvatar(uint256 indexed profileId, string indexed newAvatar);

    /**
     * @notice Emitted when the operator approval has been set.
     *
     * @param profileId The profile id.
     * @param operator The operator address.
     * @param approved The newly set bool value for operator approval.
     */
    event SetOperatorApproval(
        uint256 indexed profileId,
        address indexed operator,
        bool indexed approved
    );

    /**
     * @notice Emitted when a new registration been created.
     *
     * @param to The receiver address.
     * @param profileId The newly generated profile id.
     * @param handle The newly set handle.
     * @param avatar The newly set avatar.
     * @param metadata The newly set metadata.
     */
    event Register(
        address indexed to,
        uint256 indexed profileId,
        string handle,
        string avatar,
        string metadata
    );

    /**
     * @notice Emitted when a profile claims a box nft.
     *
     * @param to The claimer address.
     * @param boxId The box id that has been claimed.
     */
    event ClaimBox(address indexed to, uint256 indexed boxId);

    /**
     * @notice Emitted when an address has withdrawed.
     *
     * @param to The receiver address.
     * @param amount The amount sent.
     */
    event Withdraw(address indexed to, uint256 indexed amount);

    /**
     * @notice Emitted when a subscription has been created.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids subscribed to.
     * @param subDatas The subscription data set.
     */
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] subDatas
    );

    /**
     * @notice Emitted when a subscription middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowSubscribeMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a essence middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowEssenceMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param preMw The previous middleware.
     * @param newMw The newly set middleware.
     */
    event SetSubscribeMw(
        uint256 indexed profileId,
        address preMw,
        address newMw
    );

    /**
     * @notice Emitted when a new subscribe nft has been deployed.
     *
     * @param profileId The profile id.
     * @param subscribeNFT The newly deployed subscribe nft address.
     */
    event DeploySubscribeNFT(
        uint256 indexed profileId,
        address indexed subscribeNFT
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { EIP712 } from "../dependencies/openzeppelin/EIP712.sol";
import { Initializable } from "../upgradeability/Initializable.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

// Sequential mint ERC721
// TODO: Put EIP712 permit logic here
// TODO: Might need to fork ERC721 for to store startTimeStamp like
// https://github.com/chiru-labs/ERC721A/blob/538817040d98c6464afa0be7cc625cef44776668/contracts/IERC721A.sol#L75
abstract contract CyberNFTBase is Initializable, EIP712, ERC721 {
    uint256 internal _totalCount = 0;
    mapping(address => uint256) public nonces;

    constructor() {
        _disableInitializers();
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalCount;
    }

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        string memory _version
    ) internal onlyInitializing {
        ERC721.__ERC721_Init(_name, _symbol);
        EIP712.__EIP712_Init(_name, _version);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._mint(_to, ++_totalCount);
        return _totalCount;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    // Permit
    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Deadline expired");
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == expectedSigner, "Invalid signature");
    }

    // Permit
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        // solhint-disable-line
        return _domainSeparatorV4();
    }

    // Permit
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external payable {
        address owner = ownerOf(tokenId);
        require(owner != spender, "CANNOT_PERMIT_OWNER");
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        // approve and emit
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// adapted from 721A contracts
library LibString {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)
            // Cache the end of the memory to calculate the length later.
            let end := ptr
            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            let start := mload(0x40)
            // We need length * 2 bytes for the digits, 2 bytes for the prefix,
            // and 32 bytes for the length. We add 32 to the total and round down
            // to a multiple of 32. (32 + 2 + 32) = 66.
            str := add(start, and(add(shl(1, length), 66), not(31)))

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                // Initialize and perform the first pass without check.
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                length := sub(length, 1)
            } length {
                length := sub(length, 1)
            } {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            }

            if temp {
                mstore(0x00, "\x08\xc3\x79\xa0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 23) // Length of the error string.
                mstore(0x44, "HEX_LENGTH_INSUFFICIENT") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(uint256 value)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 64 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 64) is 128.
            str := add(start, 128)

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            } temp {
                // prettier-ignore
            } {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(address value)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 40 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 40) is 96.
            str := add(start, 96)

            // Allocate the memory.
            mstore(0x40, str)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                // Initialize and perform the first pass without check.
                let length := 20
                let temp := value
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                length := sub(length, 1)
            } length {
                length := sub(length, 1)
            } {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= "A") && (bStr[i] <= "Z")) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= "a") && (bStr[i] <= "z")) {
                bLower[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract ProfileNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;
    string internal constant _VERSION_STR = "1";

    // storage
    string internal _animationTemplate;
    string internal _imageTemplate;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => string) internal _metadataById;
    mapping(uint256 => mapping(address => bool)) internal _operatorApproval; // TODO: reconsider if useful
    mapping(address => uint256) internal _addressToPrimaryProfile;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev modified from OpenZeppelin Pausable.sol
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "./LibString.sol";
import "../dependencies/openzeppelin/Base64.sol";
import "./QRSVG.sol";

pragma solidity 0.8.14;

library StaticNFTSVG {
    string internal constant BASE_URL = "https://link3.to/";

    function draw(string memory handle) internal pure returns (string memory) {
        uint16 handleBackgroundWidth = 0;
        string memory handleSVGElement = "";
        string memory handleInLink = handle;
        string memory qrCode = QRSVG.generateQRCode(
            string(abi.encodePacked(BASE_URL, handle))
        );

        if (bytes(handle).length > 13) {
            string memory headString = substring(handle, 0, 12);

            handleSVGElement = string(
                abi.encodePacked(
                    getHandleSVGtext(headString, 0),
                    getHandleSVGtext(
                        substring(handle, 13, bytes(handle).length),
                        90
                    )
                )
            );
            handleInLink = string(abi.encodePacked(headString, ".."));
            handleBackgroundWidth = 188;
        } else {
            handleSVGElement = getHandleSVGtext(handle, 0);
            handleBackgroundWidth = uint16(bytes(handle).length - 1) * 13 + 30;
        }

        string memory fontStyleSVGElement = getFontStyleSVGElement();
        string memory backgroundPath = getBackgroundPath();
        string memory qrCodeSVGElement = getQRCodeSVGElement(qrCode);
        string memory linkSVGElement = getLinkSVGElement(
            handleBackgroundWidth,
            handleInLink
        );

        string memory svg = compose(
            fontStyleSVGElement,
            handleSVGElement,
            backgroundPath,
            qrCodeSVGElement,
            linkSVGElement
        );

        string memory uri = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(abi.encodePacked(svg))
            )
        );

        return uri;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getFontStyleSVGElement() internal pure returns (string memory) {
        return
            "<style>@font-face {font-family='\"Outfit\", sans-serif;'}</style>";
    }

    function getBackgroundPath() internal pure returns (string memory) {
        return
            "<path d='M59 104.826C59 92.0806 62.0452 79.5197 67.882 68.1894L84.3299 36.2613C89.4741 26.2754 99.766 20 110.999 20H177.569H421.276C432.322 20 441.276 28.9543 441.276 40V428.566C441.276 437.981 436.856 446.85 429.339 452.519L406.262 469.921C397.588 476.462 387.02 480 376.157 480H182.724H79C67.9543 480 59 471.046 59 460V104.826Z' fill='black'/>";
    }

    function getQRCodeSVGElement(string memory base64String)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<image x='20.69%' y='42.72%' href='",
                    base64String,
                    "' width='32.305%' height='32.305%' opacity='0.3'/>"
                )
            );
    }

    function getLinkSVGElement(uint16 backgroundWidth, string memory handle)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<g style='transform:translate(19.626%, 83.8%)'>",
                    "<text dominant-baseline='hanging' x='0' y='0' fill='#fff' font-size='22px' font-weight='700' font-family='\"Outfit\", sans-serif'>link3.to/</text>",
                    "<rect width='",
                    LibString.toString(backgroundWidth),
                    "px' height='24px' rx='4px' ry='4px' fill='#fff' transform='skewX(-25)' x='95' y='-3'/>",
                    "<text dominant-baseline='hanging' text-anchor='start' x='100' y='-1' font-weight='400' font-family='\"Outfit\", sans-serif' font-size='22px' fill='#000'>",
                    handle,
                    "</text></g>"
                )
            );
    }

    function compose(
        string memory fontStyleSVGElement,
        string memory handleSVGElement,
        string memory backgroundPath,
        string memory qrCodeSVGElement,
        string memory linkSVGElement
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<svg width='500' height='500' viewBox='0 0 500 500' fill='none' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>",
                    fontStyleSVGElement,
                    backgroundPath,
                    handleSVGElement,
                    qrCodeSVGElement,
                    linkSVGElement,
                    "</svg>"
                )
            );
    }

    function getHandleSVGtext(string memory handle, uint16 yValue)
        internal
        pure
        returns (string memory)
    {
        uint16 y = yValue > 0 ? yValue : 50;

        return
            string(
                abi.encodePacked(
                    "<text text-anchor='end' dominant-baseline='hanging' x='412' y='",
                    LibString.toString(y),
                    "' fill='#fff' font-weight='700' font-family='\"Outfit\", sans-serif' font-size='32'>",
                    handle,
                    "</text>"
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

abstract contract BoxNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;
    string internal constant _VERSION_STR = "1";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
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

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "./LibString.sol";
import "../dependencies/openzeppelin/Base64.sol";

pragma solidity 0.8.14;

library QRSVG {
    uint256 internal constant SIZE = 29;

    struct QRMatrix {
        uint256[SIZE][SIZE] matrix;
        uint256[SIZE][SIZE] reserved;
    }

    // For testing, will change it to pure later
    function generateQRCode(string memory url)
        internal
        pure
        returns (string memory)
    {
        // 1. Create base matrix
        QRMatrix memory qrMatrix = createBaseMatrix();

        // 2. Encode Data
        uint8[] memory encoded = encode(url);

        // 3. Generate buff
        uint256[55] memory buf = generateBuf(encoded);

        // 4. Augument ECCs
        uint256[70] memory bufWithECCs = augumentECCs(buf);

        // 5. put data into matrix
        putData(qrMatrix, bufWithECCs);

        // 6. Put format info
        putFormatInfo(qrMatrix);
        // emit MatrixCreated(qrMatrix.matrix);

        // 7. Compose SVG and convert to base64
        string memory qrCodeUri = generateQRURI(qrMatrix);

        return qrCodeUri;
    }

    function generateBuf(uint8[] memory data)
        internal
        pure
        returns (uint256[55] memory)
    {
        uint256[55] memory buf;
        uint256 dataLen = data.length;
        uint8 maxBufLen = 44;

        uint256 bits = 0;
        uint256 remaining = 8;

        (buf, bits, remaining) = pack(buf, bits, remaining, 4, 4, 0);
        (buf, bits, remaining) = pack(buf, bits, remaining, dataLen, 8, 0);

        for (uint8 i = 0; i < dataLen; ++i) {
            (buf, bits, remaining) = pack(
                buf,
                bits,
                remaining,
                data[i],
                8,
                i + 1
            );
        }

        (buf, bits, remaining) = pack(buf, bits, remaining, 0, 4, dataLen + 1);

        for (uint256 i = data.length + 2; i < maxBufLen - 1; i++) {
            buf[i] = 0xec;
            buf[i + 1] = 0x11;
        }

        return buf;
    }

    function augumentECCs(uint256[55] memory poly)
        internal
        pure
        returns (uint256[70] memory)
    {
        uint8[15] memory genpoly = [
            8,
            183,
            61,
            91,
            202,
            37,
            51,
            58,
            58,
            237,
            140,
            124,
            5,
            99,
            105
        ];

        uint256[70] memory result;
        uint256[26] memory eccs = calculateECC(poly, genpoly);

        // Put message code words
        for (uint8 i = 0; i < 55; ++i) {
            result[i] = poly[i];
        }
        // Put error correction code words
        for (uint8 i = 0; i < 15; ++i) {
            result[i + 55] = eccs[i];
        }

        return result;
    }

    function calculateECC(uint256[55] memory poly, uint8[15] memory genpoly)
        internal
        pure
        returns (uint256[26] memory)
    {
        uint256[256] memory gf256Map;
        uint256[256] memory gf256InvMap;
        uint256[70] memory modulus;
        uint8 polylen = uint8(poly.length);
        uint8 genpolylen = uint8(genpoly.length);
        uint256[26] memory result;
        uint256 gf256Value = 1;

        gf256InvMap[0] = 0;
        for (uint256 i = 0; i < 255; ++i) {
            gf256Map[i] = gf256Value;
            gf256InvMap[gf256Value] = i;
            gf256Value = (gf256Value * 2) ^ (gf256Value >= 128 ? 0x11d : 0);
        }
        gf256Map[255] = 1;

        for (uint8 i = 0; i < 55; i++) {
            modulus[i] = poly[i];
        }

        for (uint8 i = 55; i < 70; ++i) {
            modulus[i] = 0;
        }

        for (uint8 i = 0; i < polylen; ) {
            uint256 idx = modulus[i++];
            if (idx > 0) {
                uint256 quotient = gf256InvMap[idx];
                for (uint8 j = 0; j < genpolylen; ++j) {
                    modulus[i + j] ^= gf256Map[(quotient + genpoly[j]) % 255];
                }
            }
        }

        for (uint8 i = 0; i < modulus.length - polylen; i++) {
            result[i] = modulus[polylen + i];
        }

        return result;
    }

    function pack(
        uint256[55] memory buf,
        uint256 bits,
        uint256 remaining,
        uint256 x,
        uint256 n,
        uint256 index
    )
        internal
        pure
        returns (
            uint256[55] memory,
            uint256,
            uint256
        )
    {
        uint256[55] memory newBuf = buf;
        uint256 newBits = bits;
        uint256 newRemaining = remaining;

        if (n >= remaining) {
            newBuf[index] = bits | (x >> (n -= remaining));
            newBits = 0;
            newRemaining = 8;
        }
        if (n > 0) {
            newBits |= (x & ((1 << n) - 1)) << (newRemaining -= n);
        }

        return (newBuf, newBits, newRemaining);
    }

    function encode(string memory str) internal pure returns (uint8[] memory) {
        bytes memory byteString = bytes(str);
        uint8[] memory encodedArr = new uint8[](byteString.length);

        for (uint8 i = 0; i < encodedArr.length; i++) {
            encodedArr[i] = uint8(byteString[i]);
        }

        return encodedArr;
    }

    // Creating finder patterns, timing pattern and alignment patterns
    function createBaseMatrix() internal pure returns (QRMatrix memory) {
        QRMatrix memory qrMatrix;
        uint8[2] memory aligns = [4, 20];

        // Top-Left finder pattern
        blit(
            qrMatrix,
            0,
            0,
            9,
            9,
            [0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x17f, 0x00, 0x40]
        );

        // Top-Right finder pattern
        blit(
            qrMatrix,
            SIZE - 8,
            0,
            8,
            9,
            [0x100, 0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x7f, 0x00]
        );

        // Bottom-Right finder pattern
        blit(
            qrMatrix,
            0,
            SIZE - 8,
            9,
            8,
            [
                uint16(0xfe),
                uint16(0x82),
                uint16(0xba),
                uint16(0xba),
                uint16(0xba),
                uint16(0x82),
                uint16(0xfe),
                uint16(0x00),
                uint16(0x00)
            ]
        );

        // Timing pattern
        for (uint256 i = 9; i < SIZE - 8; ++i) {
            qrMatrix.matrix[6][i] = qrMatrix.matrix[i][6] = ~i & 1;
            qrMatrix.reserved[6][i] = qrMatrix.reserved[i][6] = 1;
        }

        // alignment patterns
        for (uint8 i = 0; i < 2; ++i) {
            uint8 minj = i == 0 || i == 1 ? 1 : 0;
            uint8 maxj = i == 0 ? 1 : 2;
            for (uint8 j = minj; j < maxj; ++j) {
                blit(
                    qrMatrix,
                    aligns[i],
                    aligns[j],
                    5,
                    5,
                    [
                        uint16(0x1f),
                        uint16(0x11),
                        uint16(0x15),
                        uint16(0x11),
                        uint16(0x1f),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00)
                    ]
                );
            }
        }

        return qrMatrix;
    }

    function blit(
        QRMatrix memory qrMatrix,
        uint256 y,
        uint256 x,
        uint256 h,
        uint256 w,
        uint16[9] memory data
    ) internal pure {
        for (uint256 i = 0; i < h; ++i) {
            for (uint256 j = 0; j < w; ++j) {
                qrMatrix.matrix[y + i][x + j] = (data[i] >> j) & 1;
                qrMatrix.reserved[y + i][x + j] = 1;
            }
        }
    }

    function putFormatInfo(QRMatrix memory qrMatrix) internal pure {
        uint8[15] memory infoA = [
            0,
            1,
            2,
            3,
            4,
            5,
            7,
            8,
            22,
            23,
            24,
            25,
            26,
            27,
            28
        ];

        uint8[15] memory infoB = [
            28,
            27,
            26,
            25,
            24,
            23,
            22,
            21,
            7,
            5,
            4,
            3,
            2,
            1,
            0
        ];

        for (uint8 i = 0; i < 15; ++i) {
            uint8 r = infoA[i];
            uint8 c = infoB[i];
            qrMatrix.matrix[r][8] = qrMatrix.matrix[8][c] = (32170 >> i) & 1;
            // we don't have to mark those bits reserved; always done
            // in makebasematrix above.
        }
    }

    function putData(QRMatrix memory qrMatrix, uint256[70] memory data)
        internal
        pure
        returns (QRMatrix memory)
    {
        uint256 k = 0;
        int8 dir = -1;

        // i will go below 0
        for (int256 i = int256(SIZE - 1); i >= 0; i = i - 2) {
            // skip the entire timing pattern column
            if (i == 6) {
                --i;
            }
            int256 jj = dir < 0 ? int256(SIZE - 1) : int256(0);
            for (uint256 j = 0; j < SIZE; j++) {
                // ii  will go below 0
                for (int256 ii = int256(i); ii > int256(i) - 2; ii--) {
                    // uint256(jj) and uint256(ii) will never underflow here
                    if (
                        qrMatrix.reserved[uint256(jj)][uint256(ii)] == 0 &&
                        k >> 3 < 70
                    ) {
                        qrMatrix.matrix[uint256(jj)][uint256(ii)] =
                            ((data[k >> 3] >> (~k & 7)) & 1) ^
                            (ii % 3 == 0 ? 1 : 0);
                        ++k;
                    }
                }

                if (dir == -1) {
                    // jj will go below 0 at end of loop
                    jj = jj - 1;
                } else {
                    jj = jj + 1;
                }
            }

            dir = -dir;
        }

        return qrMatrix;
    }

    function generateQRURI(QRMatrix memory qrMatrix)
        internal
        pure
        returns (string memory)
    {
        // using stroke width = 1 to draw will get 0.5 px out of bound, so we shift y + 1 and shift viewBox + 0.5
        bytes memory qrSvg = abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0.5 29 29"><path d="'
        );

        for (uint256 row = 0; row < SIZE; row += 1) {
            uint256 startY = row + 1;
            uint256 blackBlockCount;
            uint256 startX;
            for (uint256 col = 0; col < SIZE; col += 1) {
                if (qrMatrix.matrix[row][col] == 1) {
                    // Record the first black block coordinate in a consecutive black blocks
                    if (blackBlockCount == 0) {
                        startX = col;
                    }
                    blackBlockCount++;
                }
                // Draw svg when meets the white block after some black block
                else if (blackBlockCount > 0) {
                    qrSvg = abi.encodePacked(
                        qrSvg,
                        "M",
                        LibString.toString(startX),
                        ",",
                        LibString.toString(startY),
                        "l",
                        LibString.toString(blackBlockCount),
                        ",0 "
                    );
                    blackBlockCount = 0;
                }
            }
            // Draw if end of the line is reached and the last block is black
            if (blackBlockCount > 0) {
                qrSvg = abi.encodePacked(
                    qrSvg,
                    "M",
                    LibString.toString(startX),
                    ",",
                    LibString.toString(startY),
                    "l",
                    LibString.toString(blackBlockCount),
                    ",0 "
                );
            }
        }

        qrSvg = abi.encodePacked(
            qrSvg,
            '" stroke="white" stroke-width="1" fill="none"/></svg>'
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(qrSvg)
                )
            );
    }
}