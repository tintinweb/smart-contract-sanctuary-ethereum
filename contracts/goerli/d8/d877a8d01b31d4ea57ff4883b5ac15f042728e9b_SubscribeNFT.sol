// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";

import { Constants } from "../libraries/Constants.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { SubscribeNFTStorage } from "../storages/SubscribeNFTStorage.sol";

/**
 * @title Subscribe NFT
 * @author CyberConnect
 * @notice This contract is used to create a Subscribe NFT.
 */
// This will be deployed as beacon contracts for gas efficiency
contract SubscribeNFT is
    CyberNFTBase,
    SubscribeNFTStorage,
    IUpgradeable,
    ISubscribeNFT
{
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable PROFILE; // solhint-disable-line

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        address profileProxy = ISubscribeDeployer(msg.sender).subParams();
        require(profileProxy != address(0), "ZERO_ADDRESS");
        PROFILE = profileProxy;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISubscribeNFT
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external override initializer {
        _profileId = profileId;
        CyberNFTBase._initialize(name, symbol);
        emit Initialize(profileId, name, symbol);
    }

    /// @inheritdoc ISubscribeNFT
    function mint(address to) external override returns (uint256) {
        require(msg.sender == address(PROFILE), "ONLY_PROFILE");
        return super._mint(to);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUpgradeable
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disallows the transfer of the subscribe nft.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("TRANSFER_NOT_ALLOWED");
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return IProfileNFT(PROFILE).getSubscribeNFTTokenURI(_profileId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeNFTEvents } from "./ISubscribeNFTEvents.sol";

interface ISubscribeNFT is ISubscribeNFTEvents {
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
     * @param name The name for the Subscribe NFT.
     * @param symbol The symbol for the Subscribe NFT.
     */
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFTEvents } from "./IProfileNFTEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT is IProfileNFTEvents {
    /**
     * @notice Initializes the Profile NFT.
     *
     * @param _owner Owner of the Profile NFT.
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     */
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol
    ) external;

    /*
     * @notice Creates a profile and mints it to the recipient address.
     *
     * @param params contains all params.
     * @param data contains extra data.
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
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external payable returns (uint256);

    /**
     * @notice The subscription functionality.
     *
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @return uint256[] The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external returns (uint256[] memory);

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return uint256[] The subscription nft ids.
     */
    function subscribeWithSig(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256[] memory);

    /**
     * @notice Collect a profile's essence. Anyone can collect to another wallet
     *
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @return uint256 The collected essence nft id.
     */
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external returns (uint256);

    /**
     * @notice Collect a profile's essence with signature.
     *
     * @param sender The sender address.
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The collected essence nft id.
     */
    function collectWithSig(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Register an essence.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @return uint256 The new essence count.
     */
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Register an essence with signature.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The new essence count.
     */
    function registerEssenceWithSig(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Changes the pause state of the profile nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external;

    /**
     * @notice Set new namespace owner.
     *
     * @param owner The new owner.
     */
    function setNamespaceOwner(address owner) external;

    /**
     * @notice Sets the Profile NFT Descriptor.
     *
     * @param descriptor The new descriptor address to set.
     */
    function setNFTDescriptor(address descriptor) external;

    /**
     * @notice Sets the NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata) external;

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
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile.
     *
     * @param profileId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setSubscribeData(
        uint256 profileId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile with signature.
     *
     * @param profileId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setSubscribeDataWithSig(
        uint256 profileId,
        string calldata tokenURI,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile.
     *
     * @param profileId The profile ID.
     * @param essenceId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile with signature.
     *
     * @param profileId The profile ID.
     * @param essenceId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setEssenceDataWithSig(
        uint256 profileId,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the primary profile for the user.
     *
     * @param profileId The profile ID that is set to be primary.
     */
    function setPrimaryProfile(uint256 profileId) external;

    /**
     * @notice Sets the primary profile for the user with signature.
     *
     * @param profileId The profile ID that is set to be primary.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setPrimaryProfileWithSig(
        uint256 profileId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash with signature.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setAvatarWithSig(
        uint256 profileId,
        string calldata avatar,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the operator approval.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The approval status.
     */
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;

    /**
     * @notice Gets the profile metadata.
     *
     * @param profileId The profile ID.
     * @return string The metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile NFT descriptor.
     *
     * @return address The descriptor address.
     */
    function getNFTDescriptor() external view returns (address);

    /**
     * @notice Gets the profile avatar.
     *
     * @param profileId The profile ID.
     * @return string The avatar of the profile.
     */
    function getAvatar(uint256 profileId) external view returns (string memory);

    /**
     * @notice Gets the operator approval status.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @return bool The approval status.
     */
    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    /**
     * @notice Gets the profile handle by ID.
     *
     * @param profileId The profile ID.
     * @return string the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile ID by handle.
     *
     * @param handle The profile handle.
     * @return uint256 the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Gets a profile subscribe middleware address.
     *
     * @param profileId The profile id.
     * @return address The middleware address.
     */
    function getSubscribeMw(uint256 profileId) external view returns (address);

    /**
     * @notice Gets the primary profile of the user.
     *
     * @param user The wallet address of the user.
     * @return profileId The primary profile of the user.
     */
    function getPrimaryProfile(address user)
        external
        view
        returns (uint256 profileId);

    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param profileId The profile ID.
     * @return string The Subscribe NFT token URI.
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

    /**
     * @notice Gets the Essence NFT token URI.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return string The Essence NFT token URI.
     */
    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Essence NFT address.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return address The Essence NFT address.
     */
    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);

    /**
     * @notice Gets a profile essence middleware address.
     *
     * @param profileId The profile id.
     * @param essenceId The Essence ID.
     * @return address The middleware address.
     */
    function getEssenceMw(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);

    /**
     * @notice Gets the profile namespace owner.
     *
     * @return address The owner of this profile namespace.
     */
    function getNamespaceOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IUpgradeable {
    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     */
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeDeployer {
    /**
     * @notice Parameters when constructing a SubscribeNFT.
     *
     * @return profileProxy The ProfileNFT proxy address.
     */
    function subParams() external view returns (address profileProxy);

    /**
     * @notice Deploy a new SubscribeNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param profileProxy The ProfileNFT proxy address.
     *
     * @return addr The newly deployed SubscribeNFT address.
     */
    function deploySubscribe(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library Constants {
    // Access Control for CyberEngine
    uint8 internal constant _ENGINE_GOV_ROLE = 1;
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("_authorizeUpgrade(address)")));

    // EIP712 TypeHash
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _CREATE_PROFILE_TYPEHASH =
        keccak256(
            "createProfile(address to,string handle,string avatar,string metadata,address operator,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SUBSCRIBE_TYPEHASH =
        keccak256(
            "subscribeWithSig(uint256[] profileIds,bytes[] preDatas,bytes[] postDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _COLLECT_TYPEHASH =
        keccak256(
            "collectWithSig(address collector,uint256 profileId,uint256 essenceId,bytes data,bytes postDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _REGISTER_ESSENCE_TYPEHASH =
        keccak256(
            "registerEssenceWithSig(uint256 profileId,string name,string symbol,string essenceTokenURI,address essenceMw,bool transferable,bytes initData,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_METADATA_TYPEHASH =
        keccak256(
            "setMetadataWithSig(uint256 profileId,string metadata,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_OPERATOR_APPROVAL_TYPEHASH =
        keccak256(
            "setOperatorApprovalWithSig(uint256 profileId,address operator,bool approved,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_SUBSCRIBE_DATA_TYPEHASH =
        keccak256(
            "setSubscribeDataWithSig(uint256 profileId,string tokenURI,address mw,bytes data,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_ESSENCE_DATA_TYPEHASH =
        keccak256(
            "setEssenceDataWithSig(uint256 profileId,uint256 essenceId,string tokenURI,address mw,bytes data,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_AVATAR_TYPEHASH =
        keccak256(
            "setAvatarWithSig(uint256 profileId,string avatar,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_PRIMARY_PROFILE_TYPEHASH =
        keccak256(
            "setPrimaryProfileWithSig(uint256 profileId,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _CLAIM_BOX_TYPEHASH =
        keccak256("claimBox(address to,uint256 nonce,uint256 deadline)");
    bytes32 internal constant _CLAIM_TYPEHASH =
        keccak256(
            "claim(uint256 profileId,address to,address currency,uint256 amount,uint256 nonce,uint256 deadline)"
        );

    // Parameters
    uint8 internal constant _MAX_HANDLE_LENGTH = 20;
    uint8 internal constant _MAX_NAME_LENGTH = 20;
    uint8 internal constant _MAX_SYMBOL_LENGTH = 20;
    uint16 internal constant _MAX_URI_LENGTH = 2000;
    uint16 internal constant _MAX_BPS = 10000;

    // Access Control for UpgradeableBeacon
    bytes4 internal constant _BEACON_UPGRADE_TO =
        bytes4(keccak256(bytes("upgradeTo(address)")));

    // Subscribe NFT
    string internal constant _SUBSCRIBE_NFT_NAME_SUFFIX = "_subscriber";
    string internal constant _SUBSCRIBE_NFT_SYMBOL_SUFFIX = "_SUB";
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { ICyberNFTBase } from "../interfaces/ICyberNFTBase.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "./EIP712.sol";

/**
 * @title Cyber NFT Base
 * @author CyberConnect
 * @notice This contract is the base for all NFT contracts.
 */
abstract contract CyberNFTBase is Initializable, EIP712, ERC721, ICyberNFTBase {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    uint256 internal _currentIndex;
    uint256 internal _burnCount;
    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFTBase
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
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

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFTBase
    function totalSupply() external view virtual override returns (uint256) {
        return _currentIndex - _burnCount;
    }

    /// @inheritdoc ICyberNFTBase
    function totalMinted() external view virtual override returns (uint256) {
        return _currentIndex;
    }

    /// @inheritdoc ICyberNFTBase
    function totalBurned() external view virtual override returns (uint256) {
        return _burnCount;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFTBase
    function burn(uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner][msg.sender],
            "NOT_OWNER_OR_APPROVED"
        );
        super._burn(tokenId);
        _burnCount++;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _initialize(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        ERC721.__ERC721_Init(_name, _symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_currentIndex);
        return _currentIndex;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    function _domainSeparatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return name;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

abstract contract SubscribeNFTStorage {
    // storage
    uint256 internal _profileId;
    uint256 internal constant _VERSION = 2;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeNFTEvents {
    /**
     * @notice Emiited when the subscribe NFT is initialized
     *
     * @param profileId The profile ID for the Susbcribe NFT.
     * @param name The name for the Subscribe NFT.
     * @param symbol The symbol for the Subscribe NFT.
     */
    event Initialize(uint256 indexed profileId, string name, string symbol);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFTEvents {
    /**
     * @dev Emitted when the ProfileNFT is initialized.
     *
     * @param owner Namespace owner.
     */
    event Initialize(address indexed owner, string name, string symbol);

    /**
     * @notice Emitted when a new Profile NFT Descriptor has been set.
     *
     * @param newDescriptor The newly set descriptor address.
     */
    event SetNFTDescriptor(address indexed newDescriptor);

    /**
     * @notice Emitted when a new namespace owner has been set.
     *
     * @param preOwner The previous owner address.
     * @param newOwner The newly set owner address.
     */
    event SetNamespaceOwner(address indexed preOwner, address indexed newOwner);

    /**
     * @notice Emitted when a new metadata has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newMetadata The newly set metadata.
     */
    event SetMetadata(uint256 indexed profileId, string newMetadata);

    /**
     * @notice Emitted when a new avatar has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newAvatar The newly set avatar.
     */
    event SetAvatar(uint256 indexed profileId, string newAvatar);

    /**
     * @notice Emitted when a primary profile has been set.
     *
     * @param profileId The profile id.
     */
    event SetPrimaryProfile(address indexed user, uint256 indexed profileId);

    /**
     * @notice Emitted when the operator approval has been set.
     *
     * @param profileId The profile id.
     * @param operator The operator address.
     * @param prevApproved The previously set bool value for operator approval.
     * @param approved The newly set bool value for operator approval.
     */
    event SetOperatorApproval(
        uint256 indexed profileId,
        address indexed operator,
        bool prevApproved,
        bool approved
    );

    /**
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     * @param prepareReturnData The data used to prepare middleware.
     */
    event SetSubscribeData(
        uint256 indexed profileId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a essence middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     * @param prepareReturnData The data used to prepare middleware.
     */
    event SetEssenceData(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a new profile been created.
     *
     * @param to The receiver address.
     * @param profileId The newly generated profile id.
     * @param handle The newly set handle.
     * @param avatar The newly set avatar.
     * @param metadata The newly set metadata.
     */
    event CreateProfile(
        address indexed to,
        uint256 indexed profileId,
        string handle,
        string avatar,
        string metadata
    );

    /**
     * @notice Emitted when a new essence been created.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param name The essence name.
     * @param symbol The essence symbol.
     * @param essenceTokenURI the essence tokenURI.
     * @param essenceMw The essence middleware.
     * @param prepareReturnData The data returned from prepare.
     */
    event RegisterEssence(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        string essenceTokenURI,
        address essenceMw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a subscription has been created.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids subscribed to.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     */
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] preDatas,
        bytes[] postDatas
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

    /**
     * @notice Emitted when a new essence nft has been deployed.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param essenceNFT The newly deployed subscribe nft address.
     */
    event DeployEssenceNFT(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed essenceNFT
    );

    /**
     * @notice Emitted when an essence has been collected.
     *
     * @param collector The collector address.
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param tokenId The token id of the newly minted essent NFT.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     */
    event CollectEssence(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 tokenId,
        bytes preData,
        bytes postData
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct CreateProfileParams {
        address to;
        string handle;
        string avatar;
        string metadata;
        address operator;
    }

    struct CreateProfilePostProcessData {
        uint256 tokenID;
        bytes32 handleHash;
        address profileMw;
    }

    struct CreateNamespaceParams {
        string name;
        string symbol;
        address owner;
        ComputedAddresses addrs;
    }

    struct RegisterEssenceParams {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        address essenceMw;
        bool transferable;
        bool deployAtRegister;
    }

    struct SubscribeParams {
        uint256[] profileIds;
    }

    struct CollectParams {
        address collector;
        uint256 profileId;
        uint256 essenceId;
    }

    struct RegisterEssenceData {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        bytes initData;
        address essenceMw;
        bool transferable;
        bool deployAtRegister;
        address essBeacon;
    }

    struct SubscribeData {
        address sender;
        uint256[] profileIds;
        bytes[] preDatas;
        bytes[] postDatas;
        address subBeacon;
        address engine;
    }

    struct CollectData {
        address collector;
        uint256 profileId;
        uint256 essenceId;
        bytes preData;
        bytes postData;
        address essBeacon;
        address engine;
    }

    struct ProfileStruct {
        string handle;
        string avatar;
        uint256 essenceCount;
    }

    struct SubscribeStruct {
        string tokenURI;
        address subscribeNFT;
        address subscribeMw;
    }

    struct EssenceStruct {
        address essenceNFT;
        address essenceMw;
        string name;
        string symbol;
        string tokenURI;
        bool transferable;
    }

    struct NamespaceStruct {
        address profileMw;
        string name;
    }

    struct ConstructTokenURIParams {
        uint256 tokenId;
        string handle;
        uint256 subscribers;
    }

    struct ComputedAddresses {
        address profileProxy;
        address profileFactory;
        address subscribeFactory;
        address essenceFactory;
    }

    struct ProfileDeployParameters {
        address engine;
        address subBeacon;
        address essenceBeacon;
    }

    struct SubscribeDeployParameters {
        address profileProxy;
    }

    struct EssenceDeployParameters {
        address profileProxy;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/// @notice Adapted from Solmate's ERC721.sol with initializer replacing the constructor.

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is Initializable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

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

    function __ERC721_Init(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

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
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
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

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberNFTBase {
    /**
     * @notice Gets total number of tokens in existence, burned tokens will reduce the count.
     *
     * @return uint256 The total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the total number of minted tokens.
     *
     * @return uint256 The total minted tokens.
     */
    function totalMinted() external view returns (uint256);

    /**
     * @notice Gets the total number of burned tokens.
     *
     * @return uint256 The total burned tokens.
     */
    function totalBurned() external view returns (uint256);

    /**
     * @notice The EIP-712 permit function.
     *
     * @param spender The spender address.
     * @param tokenId The token ID to approve.
     * @param sig Must produce valid EIP712 signature with `s`, `r`, `v` and `deadline`.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Burns a token.
     *
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract EIP712 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant _HASHED_VERSION = keccak256("1");
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the contract's {EIP712} domain separator.
     *
     * @return bytes32 the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    keccak256(bytes(_domainSeparatorName())),
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_EXCEEDED");
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "INVALID_SIGNATURE_S_VAULE"
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == expectedSigner, "INVALID_SIGNATURE");
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        _requiresExpectedSigner(
            digest,
            expectedSigner,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash)
            );
    }

    function _domainSeparatorName()
        internal
        view
        virtual
        returns (string memory);
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}