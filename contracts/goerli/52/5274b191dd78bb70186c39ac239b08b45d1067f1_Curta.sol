// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";
import "./IFrameGenerator.sol";
import "./IFieldGenerator.sol";
import "./IHardwareGenerator.sol";
import "./IShieldBadgeSVGs.sol";

interface IEmblemWeaver {
    function fieldGenerator() external returns (IFieldGenerator);

    function hardwareGenerator() external returns (IHardwareGenerator);

    function frameGenerator() external returns (IFrameGenerator);

    function shieldBadgeSVGGenerator() external returns (IShieldBadgeSVGs);

    function generateShieldURI(IShields.Shield memory shield)
        external
        view
        returns (string memory);

    function generateShieldBadgeURI(IShields.ShieldBadge shieldBadge)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFieldGenerator {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }
    struct FieldData {
        string title;
        FieldCategories fieldType;
        string svgString;
    }

    function generateField(uint16 field, uint24[4] memory colors)
        external
        view
        returns (FieldData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFrameGenerator {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }

    function generateFrame(uint16 Frame)
        external
        view
        returns (FrameData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IHardwareGenerator {
    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
    struct HardwareData {
        string title;
        HardwareCategories hardwareType;
        string svgString;
    }

    function generateHardware(uint16 hardware)
        external
        view
        returns (HardwareData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";

interface IShieldBadgeSVGs {
    function generateShieldBadgeSVG(IShields.ShieldBadge shieldBadge)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IEmblemWeaver.sol";

interface IShields {
    enum ShieldBadge {
        MAKER,
        STANDARD
    }

    struct Shield {
        bool built;
        uint16 field;
        uint16 hardware;
        uint16 frame;
        ShieldBadge shieldBadge;
        uint24[4] colors;
    }

    function emblemWeaver() external view returns (IEmblemWeaver);

    function shields(uint256 tokenId)
        external
        view
        returns (
            uint16 field,
            uint16 hardware,
            uint16 frame,
            uint24 color1,
            uint24 color2,
            uint24 color3,
            uint24 color4,
            ShieldBadge shieldBadge
        );
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";
import "./IFieldGenerator.sol";
import "./IHardwareGenerator.sol";
import "./IFrameGenerator.sol";

interface IShieldsAPI {
    function getShield(uint256 shieldId)
        external
        view
        returns (IShields.Shield memory);

    function getShieldSVG(uint256 shieldId)
        external
        view
        returns (string memory);

    function getShieldSVG(
        uint16 field,
        uint24[4] memory colors,
        uint16 hardware,
        uint16 frame
    ) external view returns (string memory);

    function isShieldBuilt(uint256 shieldId) external view returns (bool);

    function getField(uint16 field, uint24[4] memory colors)
        external
        view
        returns (IFieldGenerator.FieldData memory);

    function getFieldTitle(uint16 field, uint24[4] memory colors)
        external
        view
        returns (string memory);

    function getFieldSVG(uint16 field, uint24[4] memory colors)
        external
        view
        returns (string memory);

    function getHardware(uint16 hardware)
        external
        view
        returns (IHardwareGenerator.HardwareData memory);

    function getHardwareTitle(uint16 hardware)
        external
        view
        returns (string memory);

    function getHardwareSVG(uint16 hardware)
        external
        view
        returns (string memory);

    function getFrame(uint16 frame)
        external
        view
        returns (IFrameGenerator.FrameData memory);

    function getFrameTitle(uint16 frame) external view returns (string memory);

    function getFrameSVG(uint16 frame) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
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

    constructor(string memory _name, string memory _symbol) {
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IShieldsAPI } from "shields-api/interfaces/IShieldsAPI.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { LibString } from "solmate/utils/LibString.sol";

import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { Base64 } from "@/contracts/utils/Base64.sol";

/// @title The Authorship Token ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice ``Authorship Tokens'' are ERC-721 tokens that are required to add
/// puzzles to Curta. Each Authorship Token may be used like a ticket once.
/// After an Authorship Token has been used to add a puzzle, it can never be
/// used again to add another puzzle. As soon as a puzzle has been deployed and
/// added to Curta, anyone may attempt to solve it.
/// @dev Other than the initial distribution, the only way to obtain an
/// Authorship Token will be to be the first solver to any puzzle on Curta.
contract AuthorshipToken is ERC721, Owned {
    using LibString for uint256;

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The shields API contract.
    /// @dev This is the mainnet address.
    IShieldsAPI constant shieldsAPI = IShieldsAPI(0x740CBbF0116a82F64e83E1AE68c92544870B0C0F);

    /// @notice Salt used to compute the seed in {AuthorshipToken-tokenURI}.
    bytes32 constant SALT = bytes32("Curta.AuthorshipToken");

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when there are no tokens available to claim.
    error NoTokensAvailable();

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @notice The Curta / Flags contract.
    address public immutable curta;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 public immutable issueLength;

    /// @notice The timestamp of when the contract was deployed.
    uint256 public immutable deployTimestamp;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The number of tokens that have been claimed by the owner.
    uint256 public numClaimedByOwner;

    /// @notice The total supply of tokens.
    uint256 public totalSupply;

    /// @notice Mapping to keep track of which addresses have claimed from
    // the mint list.
    mapping(address => bool) public hasClaimed;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _curta The Curta / Flags contract.
    /// @param _issueLength The number of seconds until an additional token is
    /// made available for minting by the author.
    /// @param _authors The list of authors in the initial batch.
    constructor(address _curta, uint256 _issueLength, address[] memory _authors)
        ERC721("Authorship Token", "AUTH")
        Owned(msg.sender)
    {
        curta = _curta;
        issueLength = _issueLength;
        deployTimestamp = block.timestamp;

        // Mint tokens to the initial batch of authors.
        uint256 length = _authors.length;
        for (uint256 i = 1; i <= length;) {
            _mint(_authors[i], i);
            unchecked {
                ++i;
            }
        }
        totalSupply = length;
    }

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a token to `_to`.
    /// @dev Only the Curta contract can call this function.
    /// @param _to The address to mint the token to.
    function curtaMint(address _to) external {
        // Revert if the sender is not the Curta contract.
        if (msg.sender != curta) revert Unauthorized();

        unchecked {
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    /// @notice Mints a token to `_to`.
    /// @dev Only the owner can call this function. The owner may claim a token
    /// every `issueLength` seconds.
    /// @param _to The address to mint the token to.
    function ownerMint(address _to) external onlyOwner {
        unchecked {
            uint256 numIssued = (block.timestamp - deployTimestamp) / issueLength;
            uint256 numMintable = numIssued - numClaimedByOwner++;

            // Revert if no tokens are available to mint.
            if (numMintable == 0) revert NoTokensAvailable();

            // Mint token
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _tokenId The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_ownerOf[_tokenId] != address(0), "NOT_MINTED");

        // Generate seed.
        uint256 seed = uint256(keccak256(abi.encodePacked(_tokenId, SALT)));

        // Bitpacked colors.
        uint256 colors = 0x6351CEFF00FFB300FF6B00B5000A007FFF78503C323232FE7FFF6C28A2FF007A;

        // Shuffle `colors` by performing 4 iterations of Fisher-Yates shuffle.
        // We do this to pick 4 unique colors from `colors`.
        unchecked {
            uint256 shift = 24 * (seed % 11);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ 0xFFFFFF))
                | ((colors & 0xFFFFFF) << shift) | ((colors >> shift) & 0xFFFFFF);
            seed >>= 4;

            shift = 24 * (seed % 10);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 24)))
                | (((colors >> 24) & 0xFFFFFF) << shift) | (((colors >> shift) & 0xFFFFFF) << 24);
            seed >>= 4;

            shift = 24 * (seed % 9);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 48)))
                | (((colors >> 48) & 0xFFFFFF) << shift) | (((colors >> shift) & 0xFFFFFF) << 48);
            seed >>= 4;

            shift = 24 * (seed & 7);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 72)))
                | (((colors >> 72) & 0xFFFFFF) << shift) | (((colors >> shift) & 0xFFFFFF) << 72);
            seed >>= 3;
        }

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"Authorship Token #',
                    _tokenId.toString(),
                    '","description":"This token allows 1 puzzle to be added to Curta. Once it has '
                    'been used, it can never be used again.","image_data":"data:image/svg+xml;base6'
                    "4,",
                    Base64.encode(
                        abi.encodePacked(
                            '<svg width="320" height="620" viewBox="0 0 320 620" fill="none" xmlns='
                            '"http://www.w3.org/2000/svg"><style>rect.a{filter:url(#c)drop-shadow(0'
                            " 0 32px #007fff);rx:32px;fill:#fff;width:64px}rect.b{filter:drop-shado"
                            "w(0 0 8px #007fff);rx:24px;fill:#000;width:48px}rect.c{height:208px}re"
                            "ct.d{height:96px}rect.e{height:64px}rect.f{height:192px}rect.g{height:"
                            "80px}rect.h{height:48px}rect.i{width:320px;height:620px;rx:20px}circle"
                            '.j{cx:160px;r:20px}</style><defs><radialGradient id="b"><stop style="s'
                            'top-color:#007fff;stop-opacity:1"/><stop offset="100%" style="stop-opa'
                            'city:0"/></radialGradient><filter id="c"><feGaussianBlur stdDeviation='
                            '"8" in="SourceGraphic" result="offset-blur"/><feComposite operator="ou'
                            't" in="SourceGraphic" in2="offset-blur" result="inverse"/><feFlood flo'
                            'od-color="#007FFF" flood-opacity=".95" result="color"/><feComposite op'
                            'erator="in" in="color" in2="inverse" result="shadow"/><feComposite in='
                            '"shadow" in2="SourceGraphic"/><feComposite operator="atop" in="shadow"'
                            ' in2="SourceGraphic"/></filter><mask id="a"><rect class="i" fill="#fff'
                            '"/><circle class="j" fill="#000"/><circle class="j" cy="620" fill="#00'
                            '0"/></mask></defs><rect class="i" fill="#0D1017" mask="url(#a)"/><circ'
                            'le fill="url(#b)" cx="160" cy="320" r="200"/><circle fill="#0D1017" cl'
                            'ass="j" cy="60" stroke="#27303D"/><g transform="translate(144 45) scal'
                            'e(.0625)"><rect width="512" height="512" fill="#0D1017" rx="256"/><rec'
                            't class="a c" x="128" y="112"/><rect class="b f" x="136" y="120"/><rec'
                            't class="a e" x="128" y="336"/><rect class="b h" x="136" y="344"/><rec'
                            't class="a d" x="224" y="112"/><rect class="b g" x="232" y="120"/><rec'
                            't class="a e" x="224" y="224"/><rect class="b h" x="232" y="232"/><rec'
                            't class="a d" x="224" y="304"/><rect class="b g" x="232" y="312"/><rec'
                            't class="a c" x="320" y="192"/><rect class="b f" x="328" y="200"/><rec'
                            't class="a e" x="320" y="112"/><rect class="b h" x="328" y="120"/></g>'
                            '<path d="M123.814 103.856c-.373 0-.718-.063-1.037-.191a2.829 2.829 0 0'
                            " 1-.878-.606 2.828 2.828 0 0 1-.606-.878 2.767 2.767 0 0 1-.193-1.037v"
                            "-.336c0-.372.064-.723.192-1.053.138-.319.34-.611.606-.877a2.59 2.59 0 "
                            "0 1 .878-.59 2.58 2.58 0 0 1 1.038-.208h4.26c.245 0 .48.032.703.096.21"
                            "2.053.425.143.638.27.223.118.415.256.574.416.16.16.304.345.431.558.043"
                            ".064.07.133.08.208a.301.301 0 0 1-.016.095.346.346 0 0 1-.175.256.42.4"
                            "2 0 0 1-.32.032.333.333 0 0 1-.239-.192 3.016 3.016 0 0 0-.303-.399 2."
                            "614 2.614 0 0 0-.415-.303 1.935 1.935 0 0 0-.463-.191 1.536 1.536 0 0 "
                            "0-.495-.048c-.712 0-1.42-.006-2.122-.016-.713 0-1.425.005-2.138.016-.2"
                            "66 0-.51.042-.734.127-.234.096-.442.24-.623.431a1.988 1.988 0 0 0-.43."
                            "623 1.961 1.961 0 0 0-.144.75v.335a1.844 1.844 0 0 0 .574 1.356 1.844 "
                            "1.844 0 0 0 1.356.574h4.261c.17 0 .33-.015.48-.047a2.02 2.02 0 0 0 .44"
                            "6-.192c.149-.074.282-.165.399-.271.106-.107.207-.229.303-.367a.438.438"
                            " 0 0 1 .255-.144c.096-.01.187.01.272.064a.35.35 0 0 1 .16.24.306.306 0"
                            " 0 1-.033.27 2.653 2.653 0 0 1-.43.527c-.16.139-.346.266-.559.383-.213"
                            ".117-.42.197-.622.24-.213.053-.436.08-.67.08h-4.262Zm17.553 0c-.713 0-"
                            "1.324-.266-1.835-.797a2.69 2.69 0 0 1-.766-1.931v-2.665c0-.117.037-.21"
                            "3.112-.287a.37.37 0 0 1 .27-.112c.118 0 .214.037.288.112a.39.39 0 0 1 "
                            ".112.287v2.664c0 .533.18.99.542 1.373a1.71 1.71 0 0 0 1.293.559h3.878c"
                            ".51 0 .941-.187 1.292-.559a1.93 1.93 0 0 0 .543-1.372v-2.665a.39.39 0 "
                            "0 1 .111-.287.389.389 0 0 1 .288-.112.37.37 0 0 1 .271.112.39.39 0 0 1"
                            " .112.287v2.664c0 .756-.256 1.4-.766 1.932-.51.531-1.128.797-1.851.797"
                            "h-3.894Zm23.824-.718a.456.456 0 0 1 .16.192c.01.042.016.09.016.143a.47"
                            ".47 0 0 1-.016.112.355.355 0 0 1-.143.208.423.423 0 0 1-.24.063h-.048a"
                            ".141.141 0 0 1-.064-.016c-.02 0-.037-.005-.047-.016a104.86 104.86 0 0 "
                            "1-1.18-.83c-.374-.265-.746-.531-1.118-.797-.011 0-.016-.006-.016-.016-"
                            ".01 0-.016-.005-.016-.016-.01 0-.016-.005-.016-.016h-5.553v1.324a.39.3"
                            "9 0 0 1-.112.288.425.425 0 0 1-.287.111.37.37 0 0 1-.272-.111.389.389 "
                            "0 0 1-.111-.288v-4.946c0-.054.005-.107.016-.16a.502.502 0 0 1 .095-.12"
                            "8.374.374 0 0 1 .128-.08.316.316 0 0 1 .144-.031h6.893c.256 0 .49.048."
                            "702.143.224.085.42.218.59.4.182.18.32.377.416.59.085.223.127.457.127.7"
                            "02v.335c0 .223-.032.43-.095.622a2.107 2.107 0 0 1-.32.527c-.138.18-.29"
                            "2.319-.462.415-.17.106-.362.186-.575.24l.702.51c.234.17.469.345.703.52"
                            "6Zm-8.281-4.228v2.425h6.494a.954.954 0 0 0 .4-.08.776.776 0 0 0 .334-."
                            "223c.107-.106.186-.218.24-.335.053-.128.08-.266.08-.415v-.32a.954.954 "
                            "0 0 0-.08-.398 1.232 1.232 0 0 0-.224-.351 1.228 1.228 0 0 0-.35-.224."
                            "954.954 0 0 0-.4-.08h-6.494Zm24.67-.782c.106 0 .202.037.287.111a.37.37"
                            " 0 0 1 .112.272.39.39 0 0 1-.112.287.425.425 0 0 1-.287.112h-3.64v4.57"
                            "9a.37.37 0 0 1-.111.272.348.348 0 0 1-.271.127.397.397 0 0 1-.288-.127"
                            ".37.37 0 0 1-.111-.272V98.91h-3.639a.37.37 0 0 1-.271-.111.39.39 0 0 1"
                            "-.112-.287.37.37 0 0 1 .112-.272.37.37 0 0 1 .271-.111h8.058Zm15.782-."
                            "048c.723 0 1.34.266 1.85.798.511.532.767 1.17.767 1.915v2.68a.37.37 0 "
                            "0 1-.112.272.397.397 0 0 1-.287.127.348.348 0 0 1-.272-.127.348.348 0 "
                            "0 1-.127-.272v-1.196h-7.532v1.196a.348.348 0 0 1-.128.272.348.348 0 0 "
                            "1-.271.127.348.348 0 0 1-.271-.127.348.348 0 0 1-.128-.272v-2.68c0-.74"
                            "5.255-1.383.766-1.915.51-.532 1.128-.798 1.851-.798h3.894Zm-5.697 3.41"
                            "5h7.548v-.702c0-.532-.176-.984-.527-1.357-.362-.383-.792-.574-1.292-.5"
                            "74H193.5c-.51 0-.942.191-1.293.574a1.875 1.875 0 0 0-.542 1.357v.702ZM"
                            "82.898 139.5h4.16l1.792-5.152h9.408l1.824 5.152h4.448l-8.704-23.2h-4.2"
                            "88l-8.64 23.2Zm10.624-18.496 3.52 9.952h-7.008l3.488-9.952Zm22.81 18.4"
                            "96h3.807v-17.216h-3.808v9.184c0 3.104-1.024 5.344-3.872 5.344s-3.168-2"
                            ".272-3.168-4.608v-9.92h-3.808v10.848c0 4.096 1.664 6.784 5.76 6.784 2."
                            "336 0 4.096-.992 5.088-2.784v2.368Zm7.678-17.216h-2.56v2.752h2.56v9.95"
                            "2c0 3.52.736 4.512 4.416 4.512h2.816v-2.912h-1.376c-1.632 0-2.048-.416"
                            "-2.048-2.176v-9.376h3.456v-2.752h-3.456v-4.544h-3.808v4.544Zm13.179-5."
                            "984h-3.809v23.2h3.808v-9.152c0-3.104 1.088-5.344 4-5.344s3.264 2.272 3"
                            ".264 4.608v9.888h3.808v-10.816c0-4.096-1.696-6.784-5.856-6.784-2.4 0-4"
                            ".224.992-5.216 2.784V116.3Zm16.86 14.624c0-3.968 2.144-5.92 4.544-5.92"
                            " 2.4 0 4.544 1.952 4.544 5.92s-2.144 5.888-4.544 5.888c-2.4 0-4.544-1."
                            "92-4.544-5.888Zm4.544-9.024c-4.192 0-8.48 2.816-8.48 9.024 0 6.208 4.2"
                            "88 8.992 8.48 8.992s8.48-2.784 8.48-8.992c0-6.208-4.288-9.024-8.48-9.0"
                            "24Zm20.057.416a10.32 10.32 0 0 0-.992-.064c-2.08.032-3.744 1.184-4.672"
                            " 3.104v-3.072h-3.744V139.5h3.808v-9.024c0-3.456 1.376-4.416 3.776-4.41"
                            "6.576 0 1.184.032 1.824.096v-3.84Zm14.665 4.672c-.704-3.456-3.776-5.08"
                            "8-7.136-5.088-3.744 0-7.008 1.952-7.008 4.992 0 3.136 2.272 4.448 5.18"
                            "4 5.024l2.592.512c1.696.32 2.976.96 2.976 2.368s-1.472 2.24-3.456 2.24"
                            "c-2.24 0-3.52-1.024-3.872-2.784h-3.712c.416 3.264 3.232 5.664 7.456 5."
                            "664 3.904 0 7.296-1.984 7.296-5.568 0-3.36-2.656-4.448-6.144-5.12l-2.4"
                            "32-.48c-1.472-.288-2.304-.896-2.304-2.048 0-1.152 1.536-1.888 3.2-1.88"
                            "8 1.92 0 3.36.608 3.776 2.176h3.584Zm6.284-10.688h-3.808v23.2h3.808v-9"
                            ".152c0-3.104 1.088-5.344 4-5.344s3.264 2.272 3.264 4.608v9.888h3.808v-"
                            "10.816c0-4.096-1.696-6.784-5.856-6.784-2.4 0-4.224.992-5.216 2.784V116"
                            ".3Zm14.076 0v3.84h3.808v-3.84h-3.808Zm0 5.984V139.5h3.808v-17.216h-3.8"
                            "08Zm10.781 8.608c0-3.968 1.952-5.888 4.448-5.888 2.656 0 4.256 2.272 4"
                            ".256 5.888 0 3.648-1.6 5.92-4.256 5.92-2.496 0-4.448-1.952-4.448-5.92Z"
                            "m-3.648-8.608V145.1h3.808v-7.872c1.024 1.696 2.816 2.688 5.12 2.688 4."
                            "192 0 7.392-3.488 7.392-9.024 0-5.504-3.2-8.992-7.392-8.992-2.304 0-4."
                            '096.992-5.12 2.688v-2.304h-3.808Z" fill="#F0F6FC"/><path stroke="#2730'
                            '3D" stroke-dasharray="10" d="M-5 480h325"/>',
                            shieldsAPI.getShieldSVG({
                                field: uint16(seed % 300),
                                colors: [
                                    uint24(colors & 0xFFFFFF),
                                    uint24((colors >> 24) & 0xFFFFFF),
                                    uint24((colors >> 48) & 0xFFFFFF),
                                    uint24((colors >> 72) & 0xFFFFFF)
                                ],
                                hardware: uint16((seed >> 9) % 120),
                                frame: uint16((seed >> 17) % 5)
                            }),
                            '<text x="50%" y="560" fill="#F0F6FC" font-family="monospace" style="fo'
                            'nt-size:40px" dominant-baseline="bottom" text-anchor="middle">#',
                            _zfill(_tokenId),
                            '</text><rect class="i" mask="url(#a)" stroke="#27303D" stroke-width="2'
                            '"/><circle class="j" stroke="#27303D"/><circle class="j" cy="620" stro'
                            'ke="#27303D"/></svg>'
                        )
                    ),
                    '","attributes":[{"trait_type":"Used","value":',
                    ICurta(curta).hasUsedAuthorshipToken(_tokenId) ? "true" : "false",
                    "}]}"
                )
            )
        );
    }

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @notice Converts `_value` to a string with leading zeros to reach a
    /// minimum of 7 characters.
    /// @param _value Number to convert.
    /// @return string memory The string representation of `_value` with leading
    /// zeros.
    function _zfill(uint256 _value) internal pure returns (string memory) {
        string memory result = _value.toString();

        if (_value < 10) return string.concat("000000", result);
        else if (_value < 100) return string.concat("00000", result);
        else if (_value < 1000) return string.concat("0000", result);
        else if (_value < 10_000) return string.concat("000", result);
        else if (_value < 100_000) return string.concat("00", result);
        else if (_value < 1_000_000) return string.concat("0", result);

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// .===========================================================================.
// | The Curta is a hand-held mechanical calculator designed by Curt           |
// | Herzstark. It is known for its extremely compact design: a small cylinder |
// | that fits in the palm of the hand.                                        |
// |---------------------------------------------------------------------------|
// | The nines' complement math breakthrough eliminated the significant        |
// | mechanical complexity created when ``borrowing'' during subtraction. This |
// | drum was the key to miniaturizing the Curta.                              |
// '==========================================================================='

import { Owned } from "solmate/auth/Owned.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { AuthorshipToken } from "./AuthorshipToken.sol";
import { FlagsERC721 } from "./FlagsERC721.sol";
import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { IPuzzle } from "@/contracts/interfaces/IPuzzle.sol";
import { ITokenRenderer } from "@/contracts/interfaces/ITokenRenderer.sol";
import { Base64 } from "@/contracts/utils/Base64.sol";

/// @title Curta
/// @author fiveoutofnine
/// @notice An extensible CTF, where each part is a generative puzzle, and each
/// solution is minted as an NFT (``Flag'').
contract Curta is ICurta, FlagsERC721, Owned {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The length of Phase 1 in seconds.
    uint256 constant PHASE_ONE_LENGTH = 2 days;

    /// @notice The length of Phase 1 and Phase 2 combined (i.e. the solving
    /// period) in seconds.
    uint256 constant SUBMISSION_LENGTH = 5 days;

    /// @notice The minimum fee required to submit a solution during Phase 2.
    /// @dev This fee is transferred to the author of the relevant puzzle. Any
    /// excess fees will also be transferred to the author. Note that the author
    /// will receive at least 0.01 ether per Phase 2 solve.
    uint256 constant PHASE_TWO_MINIMUM_FEE = 0.02 ether;

    /// @notice The protocol fee required to submit a solution during Phase 2.
    /// @dev This fee is transferred to the address returned by `owner`.
    uint256 constant PHASE_TWO_PROTOCOL_FEE = 0.01 ether;

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurta
    AuthorshipToken public immutable override authorshipToken;

    /// @inheritdoc ICurta
    ITokenRenderer public immutable override baseRenderer;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurta
    uint32 public override puzzleId = 0;

    /// @inheritdoc ICurta
    Fermat public override fermat;

    /// @inheritdoc ICurta
    mapping(uint32 => PuzzleSolves) public override getPuzzleSolves;

    /// @inheritdoc ICurta
    mapping(uint32 => PuzzleData) public override getPuzzle;

    /// @inheritdoc ICurta
    mapping(uint32 => address) public override getPuzzleAuthor;

    /// @inheritdoc ICurta
    mapping(uint32 => ITokenRenderer) public override getPuzzleTokenRenderer;

    /// @inheritdoc ICurta
    mapping(address => mapping(uint32 => bool)) public override hasSolvedPuzzle;

    /// @inheritdoc ICurta
    mapping(uint256 => bool) public override hasUsedAuthorshipToken;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    /// @param _authorshipToken The address of the Authorship Token contract.
    /// @param _baseRenderer The address of the fallback token renderer
    /// contract.
    constructor(AuthorshipToken _authorshipToken, ITokenRenderer _baseRenderer)
        FlagsERC721("Curta", "CTF")
        Owned(msg.sender)
    {
        authorshipToken = _authorshipToken;
        baseRenderer = _baseRenderer;
    }

    /// @inheritdoc ICurta
    function solve(uint32 _puzzleId, uint256 _solution) external payable {
        // Revert if `msg.sender` has already solved the puzzle.
        if (hasSolvedPuzzle[msg.sender][_puzzleId]) {
            revert PuzzleAlreadySolved(_puzzleId);
        }

        PuzzleData memory puzzleData = getPuzzle[_puzzleId];
        IPuzzle puzzle = puzzleData.puzzle;

        // Revert if the puzzle does not exist.
        if (address(puzzle) == address(0)) revert PuzzleDoesNotExist(_puzzleId);

        // Revert if submissions are closed.
        uint40 firstSolveTimestamp = puzzleData.firstSolveTimestamp;
        uint40 solveTimestamp = uint40(block.timestamp);
        uint8 phase = _computePhase(firstSolveTimestamp, solveTimestamp);
        if (phase == 3) revert SubmissionClosed(_puzzleId);

        // Revert if the solution is incorrect.
        if (!puzzle.verify(puzzle.generate(msg.sender), _solution)) {
            revert IncorrectSolution();
        }

        // Update the puzzle's first solve timestamp if it was previously unset.
        if (firstSolveTimestamp == 0) {
            getPuzzle[_puzzleId].firstSolveTimestamp = solveTimestamp;
            ++getPuzzleSolves[_puzzleId].phase0Solves;

            // Give first solver an Authorship Token
            authorshipToken.curtaMint(msg.sender);
        }

        // Mark the puzzle as solved.
        hasSolvedPuzzle[msg.sender][_puzzleId] = true;

        uint256 ethRemaining = msg.value;
        unchecked {
            // Mint NFT.
            _mint({
                _to: msg.sender,
                _id: (uint256(_puzzleId) << 128) | getPuzzleSolves[_puzzleId].solves++,
                _puzzleId: _puzzleId,
                _phase: phase
            });

            if (phase == 1) {
                ++getPuzzleSolves[_puzzleId].phase1Solves;
            } else if (phase == 2) {
                // Revert if the puzzle is in Phase 2, and insufficient funds
                // were sent.
                if (ethRemaining < PHASE_TWO_MINIMUM_FEE) revert InsufficientFunds();
                ++getPuzzleSolves[_puzzleId].phase2Solves;

                // Transfer protocol fee to `owner`.
                SafeTransferLib.safeTransferETH(owner, PHASE_TWO_PROTOCOL_FEE);

                // Subtract protocol fee from total value.
                ethRemaining -= PHASE_TWO_PROTOCOL_FEE;
            }
        }

        // Transfer untransferred funds to the puzzle author. Refunds are not
        // checked, in case someone wants to ``tip'' the author.
        SafeTransferLib.safeTransferETH(getPuzzleAuthor[_puzzleId], ethRemaining);

        // Emit event
        emit SolvePuzzle({id: _puzzleId, solver: msg.sender, solution: _solution, phase: phase});
    }

    /// @inheritdoc ICurta
    function addPuzzle(IPuzzle _puzzle, uint256 _tokenId) external {
        // Revert if the Authorship Token doesn't belong to sender.
        if (msg.sender != authorshipToken.ownerOf(_tokenId)) revert Unauthorized();

        // Revert if the puzzle has already been used.
        if (hasUsedAuthorshipToken[_tokenId]) revert AuthorshipTokenAlreadyUsed(_tokenId);

        // Mark token as used.
        hasUsedAuthorshipToken[_tokenId] = true;

        unchecked {
            uint32 curPuzzleId = ++puzzleId;

            // Add puzzle.
            getPuzzle[curPuzzleId] = PuzzleData({
                puzzle: _puzzle,
                addedTimestamp: uint40(block.timestamp),
                firstSolveTimestamp: 0
            });

            // Add puzzle author.
            getPuzzleAuthor[curPuzzleId] = msg.sender;

            // Emit events.
            emit AddPuzzle(curPuzzleId, msg.sender, _puzzle);
        }
    }

    /// @inheritdoc ICurta
    function setPuzzleTokenRenderer(uint32 _puzzleId, ITokenRenderer _tokenRenderer) external {
        // Revert if `msg.sender` is not the author of the puzzle.
        if (getPuzzleAuthor[_puzzleId] != msg.sender) revert Unauthorized();

        // Set token renderer.
        getPuzzleTokenRenderer[_puzzleId] = _tokenRenderer;

        // Emit events.
        emit UpdatePuzzleTokenRenderer(_puzzleId, _tokenRenderer);
    }

    /// @inheritdoc ICurta
    function setFermat(uint32 _puzzleId) external {
        // Revert if the puzzle has never been solved.
        PuzzleData memory puzzleData = getPuzzle[_puzzleId];
        if (puzzleData.firstSolveTimestamp == 0) revert PuzzleNotSolved(_puzzleId);

        // Revert if the puzzle is already Fermat.
        if (fermat.puzzleId == _puzzleId) revert PuzzleAlreadyFermat(_puzzleId);

        unchecked {
            uint40 timeTaken = puzzleData.firstSolveTimestamp - puzzleData.addedTimestamp;

            // Revert if the puzzle is not Fermat.
            if (timeTaken < fermat.timeTaken) revert PuzzleNotFermat(_puzzleId);

            // Set Fermat.
            fermat.puzzleId = _puzzleId;
            fermat.timeTaken = timeTaken;
        }

        // Transfer Fermat to puzzle author.
        address puzzleAuthor = getPuzzleAuthor[_puzzleId];
        address currentOwner = getTokenData[0].owner;

        unchecked {
            // Delete ownership information about Fermat, if the owner is not
            // `address(0)`.
            if (currentOwner != address(0)) {
                getUserBalances[currentOwner].balance--;

                delete getApproved[0];

                // Emit burn event.
                emit Transfer(currentOwner, address(0), 0);
            }

            // Increment new Fermat author's balance.
            getUserBalances[puzzleAuthor].balance++;
        }

        // Set new Fermat owner.
        getTokenData[0].owner = puzzleAuthor;

        // Emit mint event.
        emit Transfer(address(0), puzzleAuthor, 0);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc FlagsERC721
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        require(getTokenData[_tokenId].owner != address(0), "NOT_MINTED");

        return "";
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// @notice Computes the phase the puzzle was at at some timestamp.
    /// @param _firstSolveTimestamp The timestamp of the first solve.
    /// @param _solveTimestamp The timestamp of the solve.
    /// @return phase The phase of the puzzle: ``Phase 0'' refers to the period
    /// before the puzzle has been solved, ``Phase 1'' refers to the period 2
    /// days after the first solve, ``Phase 2'' refers to the period 3 days
    /// after the end of ``Phase 1,'' and ``Phase 3'' is when submissions are
    /// closed.
    function _computePhase(uint40 _firstSolveTimestamp, uint40 _solveTimestamp)
        internal
        pure
        returns (uint8 phase)
    {
        // Equivalent to:
        // ```sol
        // if (_firstSolveTimestamp == 0) {
        //     phase = 0;
        // } else {
        //     if (_solveTimestamp > _firstSolveTimestamp + SUBMISSION_LENGTH) {
        //         phase = 3;
        //     } else if (_solveTimestamp > _firstSolveTimestamp + PHASE_ONE_LENGTH) {
        //         phase = 2;
        //     } else {
        //         phase = 1;
        //     }
        // }
        // ```
        assembly {
            phase :=
                mul(
                    iszero(iszero(_firstSolveTimestamp)),
                    add(
                        1,
                        add(
                            gt(_solveTimestamp, add(_firstSolveTimestamp, PHASE_ONE_LENGTH)),
                            gt(_solveTimestamp, add(_firstSolveTimestamp, SUBMISSION_LENGTH))
                        )
                    )
                )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

/// @title The Flags ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice A ``Flag'' is an NFT minted to a player when they successfuly solve
/// a puzzle.
/// @dev The NFT with token ID 0 is reserved to denote ``Fermat''—the author's
/// whose puzzle went the longest unsolved.
abstract contract FlagsERC721 {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @param owner The owner of the token.
    /// @param puzzleId The ID of the puzzle that the token represents.
    /// @param solveTimestamp The timestamp of when the token was solved/minted.
    struct TokenData {
        address owner;
        uint32 puzzleId;
        uint40 solveTimestamp;
    }

    /// @param phase0Solves The number of puzzles someone solved during Phase 0.
    /// @param phase1Solves The number of puzzles someone solved during Phase 1.
    /// @param phase2Solves The number of puzzles someone solved during Phase 2.
    /// @param solves The total number of solves someone has.
    /// @param balance The number of tokens someone owns.
    struct UserBalance {
        uint32 phase0Solves;
        uint32 phase1Solves;
        uint32 phase2Solves;
        uint32 solves;
        uint32 balance;
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata Storage
    // -------------------------------------------------------------------------

    /// @notice The name of the contract.
    string public name;

    /// @notice An abbreviated name for the contract.
    string public symbol;

    // -------------------------------------------------------------------------
    // ERC721 Storage (+ Custom)
    // -------------------------------------------------------------------------

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => TokenData) public getTokenData;

    mapping(address => UserBalance) public getUserBalances;

    // -------------------------------------------------------------------------
    // Constructor + Functions
    // -------------------------------------------------------------------------

    /// @param _name The name of the contract.
    /// @param _symbol An abbreviated name for the contract.
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// @notice Mints a Flag token to `_to`.
    /// @dev This function is only called by {Curta}, so it makes a few
    /// assumptions. For example, the ID of the token is always in the form
    /// `(puzzleId << 128) + zeroIndexedSolveRanking`.
    /// @param _to The address to mint the token to.
    /// @param _id The ID of the token.
    /// @param _puzzleId The ID of the puzzle that the token represents.
    /// @param _phase The phase the token was solved in.
    function _mint(address _to, uint256 _id, uint32 _puzzleId, uint8 _phase) internal {
        // We do not check whether the `_to` is `address(0)` or that the token
        // was previously minted because {Curta} ensures these conditions are
        // never true.

        unchecked {
            ++getUserBalances[_to].balance;

            // `_mint` is only called when a puzzle is solved, so we can safely
            // increment the solve count.
            ++getUserBalances[_to].solves;

            // Same logic as the previous comment here.
            if (_phase == 0) ++getUserBalances[_to].phase0Solves;
            else if (_phase == 1) ++getUserBalances[_to].phase1Solves;
            else ++getUserBalances[_to].phase2Solves;
        }

        getTokenData[_id] =
            TokenData({owner: _to, puzzleId: _puzzleId, solveTimestamp: uint40(block.timestamp)});

        // Emit event.
        emit Transfer(address(0), _to, _id);
    }

    // -------------------------------------------------------------------------
    // ERC721
    // -------------------------------------------------------------------------

    function ownerOf(uint256 _id) public view returns (address owner) {
        require((owner = getTokenData[_id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ZERO_ADDRESS");

        return getUserBalances[_owner].balance;
    }

    function approve(address _spender, uint256 _id) external {
        address owner = getTokenData[_id].owner;

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        // Set the spender as approved for the token.
        getApproved[_id] = _spender;

        // Emit event.
        emit Approval(owner, _spender, _id);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        // Set the operator as approved for the sender.
        isApprovedForAll[msg.sender][_operator] = _approved;

        // Emit event.
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(address _from, address _to, uint256 _id) public virtual {
        // Revert if the token is not being transferred from the current owner.
        require(_from == getTokenData[_id].owner, "WRONG_FROM");

        // Revert if the recipient is the zero address.
        require(_to != address(0), "INVALID_RECIPIENT");

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(
            msg.sender == _from || isApprovedForAll[_from][msg.sender]
                || msg.sender == getApproved[_id],
            "NOT_AUTHORIZED"
        );

        // Update balances.
        unchecked {
            // Will never underflow because of the token ownership check above.
            getUserBalances[_from].balance--;

            getUserBalances[_to].balance++;
        }

        // Set new owner.
        getTokenData[_id].owner = _to;

        // Clear previous approval data for the token.
        delete getApproved[_id];

        // Emit event.
        emit Transfer(_from, _to, _id);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, bytes calldata _data)
        external
    {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, _data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _tokenId The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory);

    // -------------------------------------------------------------------------
    // ERC165
    // -------------------------------------------------------------------------

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01FFC9A7 // ERC165 Interface ID for ERC165
            || _interfaceId == 0x80AC58CD // ERC165 Interface ID for ERC721
            || _interfaceId == 0x5B5E139F; // ERC165 Interface ID for ERC721Metadata
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPuzzle } from "./IPuzzle.sol";
import { ITokenRenderer } from "./ITokenRenderer.sol";
import { AuthorshipToken } from "@/contracts/AuthorshipToken.sol";

/// @title The interface for Curta
/// @notice A CTF protocol, where players create and solve EVM puzzles to earn
/// NFTs.
/// @dev Each solve is represented by an NFT. However, the NFT with token ID 0
/// is reserved to denote ``Fermat''—the author's whose puzzle went the longest
/// unsolved.
interface ICurta {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when an Authorship Token has already been used to add a
    /// puzzle to Curta.
    /// @param _tokenId The ID of an Authorship Token.
    error AuthorshipTokenAlreadyUsed(uint256 _tokenId);

    /// @notice Emitted when a puzzle's solution is incorrect.
    error IncorrectSolution();

    /// @notice Emitted when insufficient funds are sent during "Phase 2"
    /// submissions.
    error InsufficientFunds();

    /// @notice Emitted when a puzzle is already marked as Fermat.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleAlreadyFermat(uint32 _puzzleId);

    /// @notice Emitted when a solver has already solved a puzzle.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleAlreadySolved(uint32 _puzzleId);

    /// @notice Emitted when a puzzle does not exist.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleDoesNotExist(uint32 _puzzleId);

    /// @notice Emitted when the puzzle was not the one that went longest
    /// unsolved.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleNotFermat(uint32 _puzzleId);

    /// @notice Emitted when a puzzle has not been solved yet.
    /// @param _puzzleId The ID of a puzzle.
    error PuzzleNotSolved(uint32 _puzzleId);

    /// @notice Emitted when submissions for a puzzle is closed.
    /// @param _puzzleId The ID of a puzzle.
    error SubmissionClosed(uint32 _puzzleId);

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice A struct containing data about the puzzle corresponding to
    /// Fermat (i.e. the puzzle that went the longest unsolved).
    /// @param puzzleId The ID of the puzzle.
    /// @param timeTaken The number of seconds it took to first solve the
    /// puzzle.
    struct Fermat {
        uint32 puzzleId;
        uint40 timeTaken;
    }

    /// @notice A struct containing data about a puzzle.
    /// @param puzzle The address of the puzzle.
    /// @param addedTimestamp The timestamp at which the puzzle was added.
    /// @param firstSolveTimestamp The timestamp at which the first valid
    /// solution was submitted.
    struct PuzzleData {
        IPuzzle puzzle;
        uint40 addedTimestamp;
        uint40 firstSolveTimestamp;
    }

    /// @notice A struct containing the number of solves a puzzle has.
    /// @param phase0Solves The total number of Phase 0 solves a puzzle has.
    /// @param phase1Solves The total number of Phase 1 solves a puzzle has.
    /// @param phase2Solves The total number of Phase 2 solves a puzzle has.
    /// @param solves The total number of solves a puzzle has.
    struct PuzzleSolves {
        uint32 phase0Solves;
        uint32 phase1Solves;
        uint32 phase2Solves;
        uint32 solves;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a puzzle is added.
    /// @param id The ID of the puzzle.
    /// @param author The address of the puzzle author.
    /// @param puzzle The address of the puzzle.
    event AddPuzzle(uint32 indexed id, address indexed author, IPuzzle puzzle);

    /// @notice Emitted when a puzzle is solved.
    /// @param id The ID of the puzzle.
    /// @param solver The address of the solver.
    /// @param solution The solution.
    /// @param phase The phase in which the puzzle was solved.
    event SolvePuzzle(uint32 indexed id, address indexed solver, uint256 solution, uint8 phase);

    /// @notice Emitted when a puzzle's token renderer is updated.
    /// @param id The ID of the puzzle.
    /// @param tokenRenderer The token renderer.
    event UpdatePuzzleTokenRenderer(uint32 indexed id, ITokenRenderer tokenRenderer);

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @dev Puzzle authors can set custom token renderer contracts for their
    /// puzzles. If they do not set one, it defaults to the fallback renderer
    /// this function returns.
    /// @return The contract of the fallback token renderer contract.
    function baseRenderer() external view returns (ITokenRenderer);

    /// @return The Authorship Token contract.
    function authorshipToken() external view returns (AuthorshipToken);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @return The total number of puzzles.
    function puzzleId() external view returns (uint32);

    /// @return puzzleId The ID of the puzzle corresponding to Fermat.
    /// @return timeTaken The number of seconds it took to solve the puzzle.
    function fermat() external view returns (uint32 puzzleId, uint40 timeTaken);

    /// @param _puzzleId The ID of a puzzle.
    /// @return phase0Solves The total number of Phase 0 solves a puzzle has.
    /// @return phase1Solves The total number of Phase 1 solves a puzzle has.
    /// @return phase2Solves The total number of Phase 2 solves a puzzle has.
    /// @return solves The total number of solves a puzzle has.
    function getPuzzleSolves(uint32 _puzzleId)
        external
        view
        returns (uint32 phase0Solves, uint32 phase1Solves, uint32 phase2Solves, uint32 solves);

    /// @param _puzzleId The ID of a puzzle.
    /// @return puzzle The address of the puzzle.
    /// @return addedTimestamp The timestamp at which the puzzle was added.
    /// @return firstSolveTimestamp The timestamp at which the first solution
    /// was submitted.
    function getPuzzle(uint32 _puzzleId)
        external
        view
        returns (IPuzzle puzzle, uint40 addedTimestamp, uint40 firstSolveTimestamp);

    /// @param _puzzleId The ID of a puzzle.
    /// @return The address of the puzzle author.
    function getPuzzleAuthor(uint32 _puzzleId) external view returns (address);

    /// @dev If the token renderer does not exist, it defaults to the fallback
    /// token renderer (i.e. the one returned by {ICurta-baseRenderer}).
    /// @param _puzzleId The ID of a puzzle.
    /// @return The puzzle's token renderer.
    function getPuzzleTokenRenderer(uint32 _puzzleId) external view returns (ITokenRenderer);

    /// @param _solver The address of a solver.
    /// @param _puzzleId The ID of a puzzle.
    /// @return Whether `_solver` has solved the puzzle of ID `_puzzleId`.
    function hasSolvedPuzzle(address _solver, uint32 _puzzleId) external view returns (bool);

    /// @param _tokenId The ID of an Authorship Token.
    /// @return Whether the Authorship Token of ID `_tokenId` has been used to
    /// add a puzzle.
    function hasUsedAuthorshipToken(uint256 _tokenId) external view returns (bool);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a Flag NFT if the provided solution solves the puzzle.
    /// @param _puzzleId The ID of the puzzle.
    /// @param _solution The solution.
    function solve(uint32 _puzzleId, uint256 _solution) external payable;

    /// @notice Adds a puzzle to the contract. Note that an unused Authorship
    /// Token is required to add a puzzle (see {AuthorshipToken}).
    /// @param _puzzle The address of the puzzle.
    /// @param _id The ID of the Authorship Token to burn.
    function addPuzzle(IPuzzle _puzzle, uint256 _id) external;

    /// @notice Sets the fallback token renderer for a puzzle.
    /// @dev Only the author of the puzzle of ID `_puzzleId` may set its token
    /// renderer.
    /// @param _puzzleId The ID of the puzzle.
    /// @param _tokenRenderer The token renderer.
    function setPuzzleTokenRenderer(uint32 _puzzleId, ITokenRenderer _tokenRenderer) external;

    /// @notice Burns and mints NFT #0 to the author of the puzzle of ID
    /// `_puzzleId` if it is the puzzle that went longest unsolved.
    /// @dev The puzzle of ID `_puzzleId` must have been solved at least once.
    /// @param _puzzleId The ID of the puzzle.
    function setFermat(uint32 _puzzleId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for a puzzle on Curta
/// @notice The goal of players is to view the source code of the puzzle (may
/// range from just the bytecode to Solidity—whatever the author wishes to
/// provide), interpret the code, solve it as if it was a regular puzzle, then
/// verify the solution on-chain.
/// @dev Since puzzles are on-chain, everyone can view everyone else's
/// submissions. The generative aspect prevents front-running and allows for
/// multiple winners: even if players view someone else's solution, they still
/// have to figure out what the rules/constraints of the puzzle are and apply
/// the solution to their respective starting position.
interface IPuzzle {
    /// @notice Returns the puzzle's name.
    /// @return The puzzle's name.
    function name() external pure returns (string memory);

    /// @notice Generates the puzzle's starting position based on a seed.
    /// @dev The seed is intended to be `msg.sender` of some wrapper function or
    /// call.
    /// @param _seed The seed to use to generate the puzzle.
    /// @return The puzzle's starting position.
    function generate(address _seed) external returns (uint256);

    /// @notice Verifies that a solution is valid for the puzzle.
    /// @dev `_start` is intended to be an output from {IPuzzle-generate}.
    /// @param _start The puzzle's starting position.
    /// @param _solution The solution to the puzzle.
    /// @return Whether the solution is valid.
    function verify(uint256 _start, uint256 _solution) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for puzzle's token renderers on Curta
/// @notice A token renderer is responsible for generating a token's image URI,
/// which will be returned as part of the token's URI. Curta comes with a base
/// renderer initialized at deploy, but a puzzle author may set a custom token
/// renderer contract. If it is not set, Curta's base renderer will be used.
/// @dev The image URI must be a valid SVG image.
interface ITokenRenderer {
    /// @notice Generates a string of some token's SVG image.
    /// @param _id The ID of a token.
    /// @param _phase The phase the token was solved in.
    /// @return The new URI of a token.
    function render(uint256 _id, uint8 _phase) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz012345678" "9+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLength = ((data.length + 2) / 3) << 2;
        string memory result = new string(encodedLength + 0x20);

        assembly {
            mstore(result, encodedLength)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 0x20)

            for { } lt(dataPtr, endPtr) { } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0x12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0xC, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(0xF0, 0x3D3D)) }
            case 2 { mstore(sub(resultPtr, 1), shl(0xF8, 0x3D)) }
        }

        return result;
    }
}