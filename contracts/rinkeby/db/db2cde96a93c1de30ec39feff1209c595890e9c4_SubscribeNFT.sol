// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { ICyberEngine } from "./interfaces/ICyberEngine.sol";
import { ISubscribeNFT } from "./interfaces/ISubscribeNFT.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { Constants } from "./libraries/Constants.sol";
import { LibString } from "./libraries/LibString.sol";

// This will be deployed as beacon contracts for gas efficiency
contract SubscribeNFT is CyberNFTBase, ISubscribeNFT {
    // TODO: use address or ICyberEngine
    address public immutable ENGINE;
    address public immutable PROFILE_NFT;

    uint256 internal _profileId;

    constructor(address engine, address profileNFT) {
        require(engine != address(0), "Engine address cannot be 0");
        require(profileNFT != address(0), "Profile NFT address cannot be 0");
        ENGINE = engine;
        PROFILE_NFT = profileNFT;
        _disableInitializers();
    }

    function initialize(uint256 profileId) external initializer {
        _profileId = profileId;
        // Don't need to initialize CyberNFTBase with name and symbol since they are dynamic
    }

    function mint(address to) external returns (uint256) {
        require(msg.sender == address(ENGINE), "Only Engine could mint");
        super._mint(to);
        return _totalCount;
    }

    function name() external view override returns (string memory) {
        string memory handle = IProfileNFT(PROFILE_NFT).getHandleByProfileId(
            _profileId
        );
        return
            string(
                abi.encodePacked(handle, Constants._SUBSCRIBE_NFT_NAME_SUFFIX)
            );
    }

    function symbol() external view override returns (string memory) {
        string memory handle = IProfileNFT(PROFILE_NFT).getHandleByProfileId(
            _profileId
        );
        return
            string(
                abi.encodePacked(
                    LibString.toUpper(handle),
                    Constants._SUBSCRIBE_NFT_SYMBOL_SUFFIX
                )
            );
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return ICyberEngine(ENGINE).subscribeNFTTokenURI(_profileId);
    }

    // Subscribe NFT cannot be transferred
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("Transfer is not allowed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ERC721 } from "./ERC721.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

// Sequential mint ERC721
// TODO: Put EIP712 permit logic here
// TODO: Might need to fork ERC721 for to store startTimeStamp like
// https://github.com/chiru-labs/ERC721A/blob/538817040d98c6464afa0be7cc625cef44776668/contracts/IERC721A.sol#L75
abstract contract CyberNFTBase is ERC721, Initializable {
    uint256 internal _totalCount = 0;

    function totalSupply() external view virtual returns (uint256) {
        return _totalCount;
    }

    function _initialize(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        ERC721.__ERC721_Init(_name, _symbol);
    }

    function _mint(address _to) internal virtual {
        super._mint(_to, ++_totalCount);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ICyberEngine {
    function subscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    function subscribeNFTImpl() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ISubscribeNFT {
    function mint(address to) external returns (uint256);

    function initialize(uint256 profileId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    function createProfile(
        address to,
        DataTypes.CreateProfileParams calldata vars
    ) external returns (uint256);

    function getHandleByProfileId(uint256 profildId)
        external
        view
        returns (string memory);

    function getSubscribeAddrAndMwByProfileId(uint256 profileId)
        external
        view
        returns (address, address);

    function setSubscribeNFTAddress(uint256 profileId, address subscribeNFT)
        external;

    function setMetadata(uint256 profileId, string calldata metadata) external;

    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;
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

    // EIP712 TypeHash
    bytes4 internal constant _REGISTER_TYPEHASH =
        bytes4(
            keccak256(
                bytes(
                    "register(address to,string handle,uint256 nonce,uint256 deadline)"
                )
            )
        );
    bytes4 internal constant _SUBSCRIBE_TYPEHASH =
        bytes4(
            keccak256(
                bytes(
                    "subscribeWithSig(uint256[] profileIds,bytes[] subDatas,uint256 nonce,uint256 deadline)"
                )
            )
        );
    bytes4 internal constant _SET_METADATA_TYPEHASH =
        bytes4(
            keccak256(
                bytes(
                    "setMetadataWithSig(uint256 profileId,string metadata,uint256 nonce,uint256 deadline)"
                )
            )
        );
    bytes4 internal constant _SET_OPERATOR_APPROVAL_TYPEHASH =
        bytes4(
            keccak256(
                bytes(
                    "setOperatorApprovalWithSign(uint256 profileId,address operator,bool approved,uint256 nonce,uint256 deadline)"
                )
            )
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

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
        // TODO: this is dead code after we removed modifier initializer on constructor, kept for now
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        // TODO: this is dead code after we removed modifier initializer on constructor, kept for now
        if (isTopLevelCall) {
            _initializing = false;
        }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library DataTypes {
    struct CreateProfileParams {
        string handle;
        string imageURI;
        address subscribeMw;
    }

    struct ProfileStruct {
        string handle;
        string imageURI;
        address subscribeNFT;
        address subscribeMw;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}