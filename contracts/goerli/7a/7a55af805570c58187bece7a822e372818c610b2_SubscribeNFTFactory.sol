// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";
import { SubscribeNFT } from "../core/SubscribeNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract SubscribeNFTFactory is ISubscribeDeployer {
    DataTypes.SubscribeDeployParameters public override subParams;

    function setSubParameters(address profileProxy) external override {
        subParams.profileProxy = profileProxy;
    }

    function deploy(bytes32 salt) external override returns (address addr) {
        addr = address(new SubscribeNFT{ salt: salt }());
        delete subParams;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IDeployer } from "../interfaces/IDeployer.sol";

interface ISubscribeDeployer is IDeployer {
    function subParams() external view returns (address profileProxy);

    function setSubParameters(address profileProxy) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { Constants } from "../libraries/Constants.sol";
import { LibString } from "../libraries/LibString.sol";
import { SubscribeNFTStorage } from "../storages/SubscribeNFTStorage.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";

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
    address public immutable PROFILE; // solhint-disable-line

    constructor() {
        address profileProxy = ISubscribeDeployer(msg.sender).subParams();
        require(profileProxy != address(0), "ZERO_ADDRESS");
        PROFILE = profileProxy;
        _disableInitializers();
    }

    /// @inheritdoc ISubscribeNFT
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external override initializer {
        _profileId = profileId;
        CyberNFTBase._initialize(name, symbol);
    }

    /// @inheritdoc ISubscribeNFT
    function mint(address to) external override returns (uint256) {
        require(msg.sender == address(PROFILE), "Only profile could mint");
        return super._mint(to);
    }

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     * @dev This contract can be upgraded with UUPS upgradeability
     */
    function version() external pure virtual override returns (uint256) {
        return 1;
    }

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

    /**
     * @notice Disallows the transfer of the subscribe nft.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("Transfer is not allowed");
    }
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
    }

    struct CreateNamespaceParams {
        string name;
        string symbol;
        address owner;
        ComputedAddresses addrs;
    }

    struct SubscribeData {
        address sender;
        uint256[] profileIds;
        bytes[] preDatas;
        bytes[] postDatas;
        address subBeacon;
    }

    struct CollectData {
        address collector;
        uint256 profileId;
        uint256 essenceId;
        bytes preData;
        bytes postData;
        address essBeacon;
    }

    struct RegisterEssenceData {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        address essenceMw;
        bytes prepareData;
    }

    struct ProfileStruct {
        string handle;
        string avatar;
        uint256 essenceCount;
    }

    struct SubscribeStruct {
        address subscribeNFT;
        address subscribeMw;
        string tokenURI;
    }

    struct EssenceStruct {
        address essenceNFT;
        address essenceMw;
        string name;
        string symbol;
        string tokenURI;
    }

    struct NamespaceStruct {
        address owner;
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
        // address subscribeImpl;
        // address essenceImpl;
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

pragma solidity 0.8.14;

interface IDeployer {
    function deploy(bytes32 salt) external returns (address addr);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { EIP712 } from "./EIP712.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { Initializable } from "../upgradeability/Initializable.sol";

// Sequential mint ERC721
// TODO: Put EIP712 permit logic here
// TODO: Might need to fork ERC721 for to store startTimeStamp like
// https://github.com/chiru-labs/ERC721A/blob/538817040d98c6464afa0be7cc625cef44776668/contracts/IERC721A.sol#L75
abstract contract CyberNFTBase is Initializable, EIP712, ERC721 {
    bytes32 internal constant EIP712_REVISION_HASH = keccak256("1");

    uint256 internal _totalCount = 0;
    mapping(address => uint256) public nonces;

    constructor() {
        _disableInitializers();
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalCount;
    }

    function _initialize(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        ERC721.__ERC721_Init(_name, _symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_totalCount);
        return _totalCount;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    // Permit
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external {
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

    function _domainSeperatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _name;
    }
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

import { DataTypes } from "../libraries/DataTypes.sol";
import { IProfileNFTEvents } from "./IProfileNFTEvents.sol";

interface IProfileNFT is IProfileNFTEvents {
    /**
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
        bytes calldata data
    ) external payable returns (uint256);

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
     * @notice Sets the profile NFT animation template.
     *
     * @param template The new template.
     */
    function setAnimationTemplate(string calldata template) external;

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
     * @notice Sets the primary profile for the user.
     *
     * @param profileId The profile ID that is set to be primary.
     */
    function setPrimaryProfile(uint256 profileId) external;

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

    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        returns (string memory);

    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library Constants {
    // Access Control for CyebreEngine
    uint8 internal constant _PROFILE_GOV_ROLE = 1;
    uint8 internal constant _ENGINE_GOV_ROLE = 2;
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("_authorizeUpgrade(address)")));

    // EIP712 TypeHash
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _CREATE_PROFILE_TYPEHASH =
        keccak256(
            "createProfile(address to,string handle,string avatar,string metadata,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SUBSCRIBE_TYPEHASH =
        keccak256(
            "subscribeWithSig(uint256[] profileIds,bytes[] preDatas,bytes[] postDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _COLLECT_TYPEHASH =
        keccak256(
            "collectWithSig(uint256 profileId,uint256 essenceId, bytes data,bytes[] postDatas,uint256 nonce,uint256 deadline)"
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
    uint8 internal constant _MAX_NAMESPACE_LENGTH = 20;
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

pragma solidity 0.8.14;

abstract contract SubscribeNFTStorage {
    // storage
    uint256 internal _profileId;
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

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract EIP712 {
    bytes32 internal constant _HASHED_VERSION = keccak256("1");
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_EXCEEDED");
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

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    keccak256(bytes(_domainSeperatorName())),
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
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

    function _domainSeperatorName()
        internal
        view
        virtual
        returns (string memory);
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

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFTEvents {
    /**
     * @dev Emitted when the CyberEngine is initialized.
     *
     * @param owner Owner to set for CyberEngine.
     */
    event Initialize(address indexed owner);

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
     * @notice Emitted when a new Profile NFT Descriptor has been set.
     *
     * @param newDescriptor The newly set descriptor address.
     */
    event SetNFTDescriptor(address indexed newDescriptor);

    /**
     * @notice Emitted when a new animation template has been set.
     *
     * @param newTemplate The newly set animation template.
     */
    event SetAnimationTemplate(string indexed newTemplate);

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
    event SetAvatar(uint256 indexed profileId, string indexed newAvatar);

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
     * @param mw The new middleware.
     * @param prepareReturnData The data used to prepare middleware.
     */
    event SetSubscribeMw(
        uint256 indexed profileId,
        address mw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param subscribeTokenURI The token URI for subscribe NFT.
     */
    event SetSubscribeTokenURI(
        uint256 indexed profileId,
        string subscribeTokenURI
    );
}