// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "openzeppelin/utils/Strings.sol";
import "solmate/tokens/ERC1155B.sol";

import "./IAchievements.sol";
import "./Owned.sol";

/// @title Solarbots Guild Halls
/// @author Solarbots (https://solarbots.io)
contract GuildHalls is ERC1155B, Owned {
    enum Factions { Arboria, Illskagaard, Lacrean }

    // ---------- CONSTANTS ----------

    uint256 public constant MAX_SUPPLY_PER_FACTION_SMALL_PUBLIC = 5;
    uint256 public constant MAX_SUPPLY_PER_FACTION_SMALL_WHITELIST = 5;
    uint256 public constant MAX_SUPPLY_PER_FACTION_SMALL = 10;
    uint256 public constant MAX_SUPPLY_PER_FACTION_MEDIUM = 5;
    uint256 public constant MAX_SUPPLY_PER_FACTION_LARGE = 3;

    uint256 public constant MINT_PRICE_SMALL = 0.0001 ether;
    uint256 public constant MINT_PRICE_MEDIUM = 0.0002 ether;
    uint256 public constant MINT_PRICE_LARGE = 0.0006 ether;

    /// @notice Start of whitelist sale
    uint256 public immutable whitelistSaleDate;

    /// @notice Start of public sale
    uint256 public immutable publicSaleDate;

    /// @notice Achievements contract
    IAchievements public immutable achievements;

    uint256 public constant WHITELIST_TICKET_TOKEN_ID_SMALL_START = 1;
    uint256 public constant WHITELIST_TICKET_TOKEN_ID_MEDIUM_START = 4;
    uint256 public constant WHITELIST_TICKET_TOKEN_ID_LARGE_START = 7;

    /// @dev First 8 bits are all 1, remaining 248 bits are all 0
    uint256 private constant _TOTAL_SUPPLY_BITMASK = type(uint8).max;

    // ---------- STATE ----------

    /// @notice Metadata base URI
    string public baseURI;

    /// @notice Metadata URI suffix
    string public uriSuffix;

    /// @dev Contains total supplies of all factions and sizes,
    /// each using 8 bits, starting from large, then medium, then small.
    /// The order inside the 24 bits of each size is always:
    /// Arboria, Illskagaard, Lacrean Empire
    /// Total supplies for small guild halls are split between whitelist
    /// and public sale. Each uses 24 bits and the same faction order.
    uint256 private _totalSupplyBitField;

    // ---------- CONSTRUCTOR ----------

    /// @param owner Contract owner
    /// @param _whitelistSaleDate Start of whitelist sale
    /// @param _publicSaleDate Start of public sale
    /// @param _achievements Address of Achievements contract
    constructor(
        address owner,
        uint256 _whitelistSaleDate,
        uint256 _publicSaleDate,
        address _achievements
    ) Owned(owner) {
        whitelistSaleDate = _whitelistSaleDate;
        publicSaleDate = _publicSaleDate;
        achievements = IAchievements(_achievements);
    }

    // ---------- METADATA ----------

    /// @notice Get metadata URI
    /// @param id Token ID
    /// @return Metadata URI of token ID `id`
    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, "NO_METADATA");
		return string(abi.encodePacked(baseURI, Strings.toString(id), uriSuffix));
    }

    /// @notice Set metadata base URI
    /// @param _baseURI New metadata base URI
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Set metadata URI suffix
    /// @param _uriSuffix New metadata URI suffix
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setURISuffix(string calldata _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // ---------- TOTAL SUPPLY ----------

    function totalSupplyLarge(Factions faction) public view returns (uint256) {
        uint256 bitShift = uint256(faction) * 8;
        return _totalSupplyBitField >> bitShift & _TOTAL_SUPPLY_BITMASK;
    }

    function totalSupplyLarge() public view returns (uint256) {
        return totalSupplyLarge(Factions.Arboria) + totalSupplyLarge(Factions.Illskagaard) + totalSupplyLarge(Factions.Lacrean);
    }

    function totalSupplyMedium(Factions faction) public view returns (uint256) {
        uint256 bitShift = 24 + uint256(faction) * 8;
        return _totalSupplyBitField >> bitShift & _TOTAL_SUPPLY_BITMASK;
    }

    function totalSupplyMedium() public view returns (uint256) {
        return totalSupplyMedium(Factions.Arboria) + totalSupplyMedium(Factions.Illskagaard) + totalSupplyMedium(Factions.Lacrean);
    }

    function totalSupplySmallWhitelist(Factions faction) public view returns (uint256) {
        uint256 bitShift = 48 + uint256(faction) * 8;
        return _totalSupplyBitField >> bitShift & _TOTAL_SUPPLY_BITMASK;
    }

    function totalSupplySmallWhitelist() public view returns (uint256) {
        return totalSupplySmallWhitelist(Factions.Arboria) + totalSupplySmallWhitelist(Factions.Illskagaard) + totalSupplySmallWhitelist(Factions.Lacrean);
    }

    function totalSupplySmallPublic(Factions faction) public view returns (uint256) {
        uint256 bitShift = 72 + uint256(faction) * 8;
        return _totalSupplyBitField >> bitShift & _TOTAL_SUPPLY_BITMASK;
    }

    function totalSupplySmallPublic() public view returns (uint256) {
        return totalSupplySmallPublic(Factions.Arboria) + totalSupplySmallPublic(Factions.Illskagaard) + totalSupplySmallPublic(Factions.Lacrean);
    }

    function totalSupplySmall() public view returns (uint256) {
        return totalSupplySmallWhitelist() + totalSupplySmallPublic();
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplyLarge() + totalSupplyMedium() + totalSupplySmall();
    }

    // ---------- WHITELIST SALE ----------

    function mintWhitelistLarge(Factions faction) external payable {
        require(block.timestamp >= whitelistSaleDate, "WHITELIST_SALE_NOT_READY");
        require(msg.value == MINT_PRICE_LARGE, "WRONG_PRICE");

        uint256 whitelistTicketTokenID = WHITELIST_TICKET_TOKEN_ID_LARGE_START + uint256(faction);
        achievements.burn(msg.sender, whitelistTicketTokenID, 1);

        _mint(faction, MAX_SUPPLY_PER_FACTION_LARGE, 0, 0, MAX_SUPPLY_PER_FACTION_LARGE);
    }

    function mintWhitelistMedium(Factions faction) external payable {
        require(block.timestamp >= whitelistSaleDate, "WHITELIST_SALE_NOT_READY");
        require(msg.value == MINT_PRICE_MEDIUM, "WRONG_PRICE");

        uint256 whitelistTicketTokenID = WHITELIST_TICKET_TOKEN_ID_MEDIUM_START + uint256(faction);
        achievements.burn(msg.sender, whitelistTicketTokenID, 1);

        _mint(faction, MAX_SUPPLY_PER_FACTION_MEDIUM, 24, 9, MAX_SUPPLY_PER_FACTION_MEDIUM);
    }

    function mintWhitelistSmall(Factions faction) external payable {
        require(block.timestamp >= whitelistSaleDate, "WHITELIST_SALE_NOT_READY");
        require(msg.value == MINT_PRICE_SMALL, "WRONG_PRICE");

        uint256 whitelistTicketTokenID = WHITELIST_TICKET_TOKEN_ID_SMALL_START + uint256(faction);
        achievements.burn(msg.sender, whitelistTicketTokenID, 1);

        _mint(faction, MAX_SUPPLY_PER_FACTION_SMALL_WHITELIST, 48, 24, MAX_SUPPLY_PER_FACTION_SMALL);
    }

    // ---------- PUBLIC SALE ----------

    function mintPublicSmall(Factions faction) external payable {
        require(block.timestamp >= publicSaleDate, "PUBLIC_SALE_NOT_READY");
        require(msg.value == MINT_PRICE_SMALL, "WRONG_PRICE");
        _mint(faction, MAX_SUPPLY_PER_FACTION_SMALL_PUBLIC, 72, 29, MAX_SUPPLY_PER_FACTION_SMALL);
    }

    // ---------- MINT ----------

    function _mint(Factions faction, uint256 maxSupply, uint256 bitShiftOffset, uint256 idOffset, uint256 idRange) internal {
        require(msg.sender == tx.origin, "NO_SMART_CONTRACTS");

        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;

        unchecked {
            uint256 bitShift = bitShiftOffset + uint256(faction) * 8;

            uint256 _totalSupply = totalSupplyBitField >> bitShift & _TOTAL_SUPPLY_BITMASK;
            require(_totalSupply < maxSupply, "REACHED_MAX_SUPPLY");

            uint256 id = idOffset + idRange * uint256(faction) + _totalSupply;
            ownerOf[id ] = msg.sender;

            _totalSupplyBitField = totalSupplyBitField & ~(uint256(type(uint8).max) << bitShift) | ++_totalSupply << bitShift;
            emit TransferSingle(msg.sender, address(0), msg.sender, id, 1);
        }
    }

    // ---------- WITHDRAW ----------

    /// @notice Withdraw all Ether stored in this contract to address of contract owner
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155TokenReceiver} from "./ERC1155.sol";

/// @notice Minimalist and gas efficient ERC1155 implementation optimized for single supply ids.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155B.sol)
abstract contract ERC1155B {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                            ERC1155B STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public ownerOf;

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 bal) {
        address idOwner = ownerOf[id];

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        require(from == ownerOf[id], "WRONG_FROM"); // Can only transfer from the owner.

        // Can only transfer 1 with ERC1155B.
        require(amount == 1, "INVALID_AMOUNT");

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];
                amount = amounts[i];

                // Can only transfer from the owner.
                require(from == ownerOf[id], "WRONG_FROM");

                // Can only transfer 1 with ERC1155B.
                require(amount == 1, "INVALID_AMOUNT");

                ownerOf[id] = to;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        // Minting twice would effectively be a force transfer.
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, 1, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                // Minting twice would effectively be a force transfer.
                require(ownerOf[id] == address(0), "ALREADY_MINTED");

                ownerOf[id] = to;

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(address from, uint256[] memory ids) internal virtual {
        // Burning unminted tokens makes no sense.
        require(from != address(0), "INVALID_FROM");

        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                require(ownerOf[id] == from, "WRONG_FROM");

                ownerOf[id] = address(0);

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        ownerOf[id] = address(0);

        emit TransferSingle(msg.sender, owner, address(0), id, 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Solarbots Achievements Interface
/// @author Solarbots (https://solarbots.io)
interface IAchievements {
    function burn(address from, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Simple contract ownership module
/// @author Solarbots (https://solarbots.io)
abstract contract Owned {
    address public owner;

    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "NOT_OWNER");

        _;
    }

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransfer(address(0), _owner);
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");

        owner = newOwner;

        emit OwnershipTransfer(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}