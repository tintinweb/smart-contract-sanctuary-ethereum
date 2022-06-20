// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "openzeppelin/utils/Strings.sol";
import "solmate/tokens/ERC1155B.sol";

import "./IAchievements.sol";
import "./ILockManager.sol";
import "./Owned.sol";

/// @title Solarbots Player Housing
/// @author Solarbots (https://solarbots.io)
contract PlayerHousing is ERC1155B, Owned {
    // ---------- CONSTANTS ----------

    /// @notice Maximum amount of tokens per faction that can be minted in total
    /// Arboria tokens use IDs 0-5999, Illskagaard tokens use IDs 6000-11999,
    /// and Lacrean Empire tokens use IDs 12000-17999 for a total of 18000 tokens
    uint256 public constant MAX_SUPPLY_PER_FACTION = 6000;

    /// @notice Maximum amount of tokens that can be minted per transaction
    uint256 public constant MAX_MINT_AMOUNT_PER_TX = 5;

    /// @notice Price to mint one token
    uint256 public constant MINT_PRICE = 0.1 ether;

    /// @notice FOA rewards emitted per second per token
    /// @dev 600_000_000*1e18/18_000/10/365/24/60/60
    uint256 public constant REWARDS_PER_SECOND = 105699306612548;

    /// @notice End of FOA rewards emittance
    uint256 public immutable rewardsEndTimestamp;

    /// @notice Start of whitelist sale
    uint256 public immutable whitelistSaleDate;

    /// @notice Start of public sale
    uint256 public immutable publicSaleDate;

    /// @notice Achievements contract
    address public immutable achievements;

    /// @notice Token ID of whitelist ticket in achievements contract
    uint256 public immutable whitelistTicketTokenID;

    /// @dev First 16 bits are all 1, remaining 240 bits are all 0
    uint256 private constant _TOTAL_SUPPLY_BITMASK = type(uint16).max;

    // ---------- STATE ----------

    mapping(address => uint256) public rewardsBitField;
    mapping(address => bool) public isApprovedForRewards;

    address public lockManager;

    /// @notice Metadata base URI
    string public baseURI;

    /// @notice Metadata URI suffix
    string public uriSuffix;

    /// @dev First 16 bits contain total supply of Arboria tokens,
    /// second 16 bits contain total supply of Illskagard tokens,
    /// and third 16 bits contain total supply of Lacrean Empire tokens
    uint256 private _totalSupplyBitField;

    // ---------- EVENTS ----------

    event ApprovalForRewards(address indexed operator, bool approved);

    event LockManagerTransfer(address indexed previousLockManager, address indexed newLockManager);

    // ---------- CONSTRUCTOR ----------

    /// @param owner Contract owner
    /// @param _whitelistSaleDate Start of whitelist sale
    /// @param _publicSaleDate Start of public sale
    /// @param _rewardsEndTimestamp End of FOA rewards emittance
    /// @param _achievements Address of Achievements contract
    /// @param _whitelistTicketTokenID Token ID of whitelist ticket in Achievements contract
    /// @param _lockManager Address of Lock Manager contract
    constructor(
        address owner,
        uint256 _whitelistSaleDate,
        uint256 _publicSaleDate,
        uint256 _rewardsEndTimestamp,
        address _achievements,
        uint256 _whitelistTicketTokenID,
        address _lockManager
    ) Owned(owner) {
        whitelistSaleDate = _whitelistSaleDate;
        publicSaleDate = _publicSaleDate;
        rewardsEndTimestamp = _rewardsEndTimestamp;
        achievements = _achievements;
        whitelistTicketTokenID = _whitelistTicketTokenID;
        lockManager = _lockManager;
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

    function totalSupplyArboria() public view returns (uint256) {
        return _totalSupplyBitField & _TOTAL_SUPPLY_BITMASK;
    }

    function totalSupplyIllskagaard() public view returns (uint256) {
        return _totalSupplyBitField >> 16 & _TOTAL_SUPPLY_BITMASK;
    }

    function totalSupplyLacrean() public view returns (uint256) {
        return _totalSupplyBitField >> 32;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplyArboria() + totalSupplyIllskagaard() + totalSupplyLacrean();
    }

    // ---------- LOCK MANAGER ----------

    function setLockManager(address _lockManager) public onlyOwner {
        emit LockManagerTransfer(lockManager, _lockManager);
        lockManager = _lockManager;
    }

    // ---------- REWARDS ----------

    function setApprovalForRewards(address operator, bool approved) public onlyOwner {
        isApprovedForRewards[operator] = approved;
        emit ApprovalForRewards(operator, approved);
    }

    function setRewardsBitField(address owner, uint256 _rewardsBitField) public {
        require(isApprovedForRewards[msg.sender], "NOT_AUTHORIZED");
        rewardsBitField[owner] = _rewardsBitField;
    }

    /// @notice Returns the token balance of the given address
    /// @param owner Address to check
    function balanceOf(address owner) public view returns (uint256) {
        return rewardsBitField[owner] & type(uint16).max;
    }

    /// @notice Returns the FOA rewards balance of the given address
    /// @param owner Address to check
    function rewardsOf(address owner) public view returns (uint256 rewardsBalance) {
        rewardsBalance = rewardsBitField[owner] >> 48;
        uint256 lastUpdated = rewardsBitField[owner] >> 16 & type(uint32).max;

        if (lastUpdated != rewardsEndTimestamp) {
            // Use current block timestamp or rewards end timestamp if reached
            uint256 timestamp = block.timestamp < rewardsEndTimestamp ? block.timestamp : rewardsEndTimestamp;
            uint256 tokenBalance = balanceOf(owner);

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
            }
        }
    }

    function _updateRewardsForTransfer(address from, address to, uint256 tokenAmount) internal {
        // Use current block timestamp or rewards end timestamp if reached
        uint256 timestamp = block.timestamp < rewardsEndTimestamp ? block.timestamp : rewardsEndTimestamp;

        // Store bit field in memory to reduce number of SLOADs
        uint256 _rewardsBitField = rewardsBitField[from];
        uint256 lastUpdated = _rewardsBitField >> 16 & type(uint32).max;

        if (lastUpdated != rewardsEndTimestamp) {
            uint256 tokenBalance = _rewardsBitField & type(uint16).max;
            uint256 rewardsBalance = _rewardsBitField >> 48;

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                unchecked {
                    rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
                }
            }

            unchecked {
                rewardsBitField[from] = tokenBalance - tokenAmount | timestamp << 16 | rewardsBalance << 48;
            }
        }

        // Store bit field in memory to reduce number of SLOADs
        _rewardsBitField = rewardsBitField[to];
        lastUpdated = _rewardsBitField >> 16 & type(uint32).max;

        if (lastUpdated != rewardsEndTimestamp) {
            uint256 tokenBalance = _rewardsBitField & type(uint16).max;
            uint256 rewardsBalance = _rewardsBitField >> 48;

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                unchecked {
                    rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
                }
            }

            unchecked {
                rewardsBitField[to] = tokenBalance + tokenAmount | timestamp << 16 | rewardsBalance << 48;
            }
        }
    }

    function _updateRewardsForMint(address owner, uint256 tokenAmount) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 _rewardsBitField = rewardsBitField[owner];
        uint256 tokenBalance = _rewardsBitField & type(uint16).max;
        uint256 lastUpdated = _rewardsBitField >> 16 & type(uint32).max;
        uint256 rewardsBalance = _rewardsBitField >> 48;

        // Calculate rewards collected since last update and add them to balance
        if (lastUpdated > 0) {
            uint256 secondsSinceLastUpdate = block.timestamp - lastUpdated;
            unchecked {
                rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
            }
        }

        unchecked {
            rewardsBitField[owner] = tokenBalance + tokenAmount | block.timestamp << 16 | rewardsBalance << 48;
        }
    }

    // ---------- TRANSFER ----------

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
        require(from == ownerOf[id], "NOT_TOKEN_OWNER");
        require(amount == 1, "INVALID_AMOUNT");
        require(!ILockManager(lockManager).isLocked(from, to, id), "TOKEN_LOCKED");

        ownerOf[id] = to;
        _updateRewardsForTransfer(from, to, amount);
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
    ) public override {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");
        require(!ILockManager(lockManager).isLocked(from, to, ids), "TOKEN_LOCKED");

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
                require(from == ownerOf[id], "NOT_TOKEN_OWNER");

                // Can only transfer 1 with ERC1155B.
                require(amount == 1, "INVALID_AMOUNT");

                ownerOf[id] = to;
            }
        }

        _updateRewardsForTransfer(from, to, ids.length);
        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    // ---------- WHITELIST SALE ----------

    /// @notice Mint a single Arboria token during whitelist sale
    function mintWhitelistArboria() external payable {
        require(block.timestamp >= whitelistSaleDate, "Whitelist sale not ready");

        // Burn whitelist ticket
        IAchievements(achievements).burn(msg.sender, whitelistTicketTokenID, 1);

        _mintArboria();
    }

    /// @notice Mint a single Illskagaard token during whitelist sale
    function mintWhitelistIllskagaard() external payable {
        require(block.timestamp >= whitelistSaleDate, "Whitelist sale not ready");

        // Burn whitelist ticket
        IAchievements(achievements).burn(msg.sender, whitelistTicketTokenID, 1);

        _mintIllskagaard();
    }

    /// @notice Mint a single Lacrean Empire token during whitelist sale
    function mintWhitelistLacrean() external payable {
        require(block.timestamp >= whitelistSaleDate, "Whitelist sale not ready");

        // Burn whitelist ticket
        IAchievements(achievements).burn(msg.sender, whitelistTicketTokenID, 1);

        _mintLacrean();
    }

    /// @notice Batch mint specified amount of tokens during whitelist sale
    /// @param arboriaAmount Amount of Arboria tokens to mint
    /// @param illskagaardAmount Amount of Illskagaard tokens to mint
    /// @param lacreanAmount Amount of Lacrean tokens to mint
    function batchMintWhitelist(uint256 arboriaAmount, uint256 illskagaardAmount, uint256 lacreanAmount) external payable {
        require(block.timestamp >= whitelistSaleDate, "Whitelist sale not ready");

        // Burn whitelist tickets
        IAchievements(achievements).burn(msg.sender, whitelistTicketTokenID, arboriaAmount + illskagaardAmount + lacreanAmount);

        _batchMint(arboriaAmount, illskagaardAmount, lacreanAmount);
    }

    // ---------- PUBLIC SALE ----------

    /// @notice Mint a single Arboria token during public sale
    function mintPublicArboria() external payable {
        require(block.timestamp >= publicSaleDate, "Public sale not ready");
        _mintArboria();
    }

    /// @notice Mint a single Illskagaard token during public sale
    function mintPublicIllskagaard() external payable {
        require(block.timestamp >= publicSaleDate, "Public sale not ready");
        _mintIllskagaard();
    }

    /// @notice Mint a single Lacrean Empire token during public sale
    function mintPublicLacrean() external payable {
        require(block.timestamp >= publicSaleDate, "Public sale not ready");
        _mintLacrean();
    }

    /// @notice Batch mint specified amount of tokens during public sale
    /// @param arboriaAmount Amount of Arboria tokens to mint
    /// @param illskagaardAmount Amount of Illskagaard tokens to mint
    /// @param lacreanAmount Amount of Lacrean tokens to mint
    function batchMintPublic(uint256 arboriaAmount, uint256 illskagaardAmount, uint256 lacreanAmount) external payable {
        require(block.timestamp >= publicSaleDate, "Public sale not ready");
        _batchMint(arboriaAmount, illskagaardAmount, lacreanAmount);
    }

    // ---------- MINT ----------

    /// @dev Mint a single Arboria token
    function _mintArboria() internal {
        require(msg.sender == tx.origin, "Smart contract minting not allowed");
        require(msg.value == MINT_PRICE, "Wrong price");
        // Total supply of Arboria tokens is stored in the first 16 bits of the bit field
        uint256 tokenId = _totalSupplyBitField & _TOTAL_SUPPLY_BITMASK;
        require(tokenId < MAX_SUPPLY_PER_FACTION, "Reached max Arboria supply");

        ownerOf[tokenId] = msg.sender;
        unchecked {
            // Incrementing the whole bit field increments just the total supply of
            // Arboria tokens, because only the value stored in the first bits gets updated
            _totalSupplyBitField++;
        }

        _updateRewardsForMint(msg.sender, 1);
        emit TransferSingle(msg.sender, address(0), msg.sender, tokenId, 1);
    }

    /// @dev Mint a single Illskagaard token
    function _mintIllskagaard() internal {
        require(msg.sender == tx.origin, "Smart contract minting not allowed");
        require(msg.value == MINT_PRICE, "Wrong price");
        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // Total supply of Illskagaard tokens is stored in the second 16 bits of the bit field
        uint256 _totalSupplyIllskagaard = totalSupplyBitField >> 16 & _TOTAL_SUPPLY_BITMASK;
        require(_totalSupplyIllskagaard < MAX_SUPPLY_PER_FACTION, "Reached max Illskagaard supply");

        unchecked {
            // Illskagaard token IDs start at 6000
            uint256 tokenId = MAX_SUPPLY_PER_FACTION + _totalSupplyIllskagaard;
            ownerOf[tokenId] = msg.sender;

            // Second 16 bits need to be all set to 0 before the new total supply of
            // Illskagaard tokens can be stored
            _totalSupplyBitField = totalSupplyBitField & ~(uint256(type(uint16).max) << 16) | ++_totalSupplyIllskagaard << 16;

            _updateRewardsForMint(msg.sender, 1);
            emit TransferSingle(msg.sender, address(0), msg.sender, tokenId, 1);
        }
    }

    /// @dev Mint a single Lacrean Empire token
    function _mintLacrean() internal {
        require(msg.sender == tx.origin, "Smart contract minting not allowed");
        require(msg.value == MINT_PRICE, "Wrong price");
        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // Total supply of Lacrean Empire tokens is stored in the third 16 bits of the bit field
        uint256 _totalSupplyLacrean = totalSupplyBitField >> 32;
        require(_totalSupplyLacrean < MAX_SUPPLY_PER_FACTION, "Reached max Lacrean supply");

        unchecked {
            // Lacrean Empire token IDs start at 12000
            uint256 tokenId = MAX_SUPPLY_PER_FACTION * 2 + _totalSupplyLacrean;
            ownerOf[tokenId] = msg.sender;

            // Third 16 bits need to be all set to 0 before the new total supply of
            // Lacrean Empire tokens can be stored
            _totalSupplyBitField = totalSupplyBitField & ~(uint256(type(uint16).max) << 32) | ++_totalSupplyLacrean << 32;

            _updateRewardsForMint(msg.sender, 1);
            emit TransferSingle(msg.sender, address(0), msg.sender, tokenId, 1);
        }
    }

    /// @notice Batch mint specified amount of tokens
    /// @param arboriaAmount Amount of Arboria tokens to mint
    /// @param illskagaardAmount Amount of Illskagaard tokens to mint
    /// @param lacreanAmount Amount of Lacrean tokens to mint
    function _batchMint(uint256 arboriaAmount, uint256 illskagaardAmount, uint256 lacreanAmount) internal {
        require(msg.sender == tx.origin, "Smart contract minting not allowed");
        // Doing these checks and later calculating the total amount unchecked costs less gas
        // than not doing these checks and calculating the total amount checked
        require(arboriaAmount <= MAX_MINT_AMOUNT_PER_TX, "Arboria amount over maximum allowed per transaction");
        require(illskagaardAmount <= MAX_MINT_AMOUNT_PER_TX, "Illskagaard amount over maximum allowed per transaction");
        require(lacreanAmount <= MAX_MINT_AMOUNT_PER_TX, "Lacrean amount over maximum allowed per transaction");

        // Once the supplied amounts are known to be under certain limits,
        // all following calculations are safe and can be performed unchecked
        unchecked {
            uint256 totalAmount = arboriaAmount + illskagaardAmount + lacreanAmount;
            require(totalAmount > 1, "Total amount must be at least 2");
            require(totalAmount <= MAX_MINT_AMOUNT_PER_TX, "Total amount over maximum allowed per transaction");
            require(msg.value == totalAmount * MINT_PRICE, "Wrong price");

            // Token IDs and amounts are collected in arrays to later emit the TransferBatch event
            uint256[] memory tokenIds = new uint256[](totalAmount);
            // Token amounts are all 1
            uint256[] memory amounts = new uint256[](totalAmount);
            // Keeps track of the current index of both arrays
            uint256 currentArrayIndex;

            // Store bit field in memory to reduce number of SLOADs
            uint256 totalSupplyBitField = _totalSupplyBitField;
            // New bit field gets updated in memory to reduce number of SSTOREs
            // _totalSupplyBitField is only updated once after all tokens are minted
            uint256 newTotalSupplyBitField = totalSupplyBitField;

            if (arboriaAmount > 0) {
                // Total supply of Arboria tokens is stored in the first 16 bits of the bit field
                uint256 _totalSupplyArboria = totalSupplyBitField & _TOTAL_SUPPLY_BITMASK;
                uint256 newTotalSupplyArboria = _totalSupplyArboria + arboriaAmount;
                require(newTotalSupplyArboria <= MAX_SUPPLY_PER_FACTION, "Reached max Arboria supply");

                for (uint256 i = 0; i < arboriaAmount; i++) {
                    uint256 tokenId = _totalSupplyArboria + i;
                    tokenIds[i] = tokenId;
                    amounts[i] = 1;
                    ownerOf[tokenId] = msg.sender;
                }
                currentArrayIndex = arboriaAmount;

                // First 16 bits need to be all set to 0 before the new total supply of Arboria tokens can be stored
                newTotalSupplyBitField = newTotalSupplyBitField & uint16(0) | newTotalSupplyArboria;
            }

            if (illskagaardAmount > 0) {
                // Total supply of Illskagaard tokens is stored in the second 16 bits of the bit field
                uint256 _totalSupplyIllskagaard = totalSupplyBitField >> 16 & _TOTAL_SUPPLY_BITMASK;
                uint256 newTotalSupplyIllskagaard = _totalSupplyIllskagaard + illskagaardAmount;
                require(newTotalSupplyIllskagaard <= MAX_SUPPLY_PER_FACTION, "Reached max Illskagaard supply");

                for (uint256 i = 0; i < illskagaardAmount; i++) {
                    // Illskagaard token IDs start at 6000
                    uint256 tokenId = MAX_SUPPLY_PER_FACTION + _totalSupplyIllskagaard + i;
                    tokenIds[currentArrayIndex] = tokenId;
                    amounts[currentArrayIndex] = 1;
                    ownerOf[tokenId] = msg.sender;
                    currentArrayIndex++;
                }

                // Second 16 bits need to be all set to 0 before the new total supply of Illskagaard tokens can be stored
                newTotalSupplyBitField = newTotalSupplyBitField & ~(uint256(type(uint16).max) << 16) | newTotalSupplyIllskagaard << 16;
            }

            if (lacreanAmount > 0) {
                // Total supply of Lacrean Empire tokens is stored in the third 16 bits of the bit field
                uint256 _totalSupplyLacrean = totalSupplyBitField >> 32;
                uint256 newTotalSupplyLacrean = _totalSupplyLacrean + lacreanAmount;
                require(newTotalSupplyLacrean <= MAX_SUPPLY_PER_FACTION, "Reached max Lacrean supply");

                for (uint256 i = 0; i < lacreanAmount; i++) {
                    // Lacrean Empire token IDs start at 12000
                    uint256 tokenId = MAX_SUPPLY_PER_FACTION * 2 + _totalSupplyLacrean + i;
                    tokenIds[currentArrayIndex] = tokenId;
                    amounts[currentArrayIndex] = 1;
                    ownerOf[tokenId] = msg.sender;
                    currentArrayIndex++;
                }

                // Third 16 bits need to be all set to 0 before the new total supply of Lacrean Empire tokens can be stored
                newTotalSupplyBitField = newTotalSupplyBitField & ~(uint256(type(uint16).max) << 32) | newTotalSupplyLacrean << 32;
            }

            _totalSupplyBitField = newTotalSupplyBitField;
            _updateRewardsForMint(msg.sender, totalAmount);
            emit TransferBatch(msg.sender, address(0), msg.sender, tokenIds, amounts);
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

/// @title Solarbots Lock Manager Interface
/// @author Solarbots (https://solarbots.io)
interface ILockManager {
    function isLocked(address from, address to, uint256 id) external returns (bool);
    function isLocked(address from, address to, uint256[] calldata ids) external returns (bool);
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