// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";

import "./ERC1155B.sol";
import "./ILockManager.sol";
import "./ITickets.sol";

/// @title Solarbots Player Housing
/// @author Solarbots (https://solarbots.io)
contract PlayerHousing is ERC1155B, Ownable {
    // ---------- CONSTANTS ----------

    /// @notice Maximum amount of tokens that can be minted per faction
    /// Arboria tokens use IDs 0-5999, Illskagaard tokens use IDs 6000-11999,
    /// and Lacrean Empire tokens use IDs 12000-17999 for a total of 18000 tokens
    uint256 public constant MAX_SUPPLY_PER_FACTION = 6000;

    /// @notice Illskagaard tokens use IDs 6000-11999
    uint256 public constant ID_OFFSET_ILLSKAGAARD = 6000;

    /// @notice Lacrean Empire tokens use IDs 12000-17999
    uint256 public constant ID_OFFSET_LACREAN = 12000;

    /// @notice Maximum amount of tokens that can be minted per transaction
    uint256 public constant MAX_MINT_AMOUNT_PER_TX = 5;

    /// @notice Price to mint one token
    uint256 public constant MINT_PRICE = 0.1 ether;

    /// @notice Token ID of whitelist ticket in tickets contract
    uint256 public constant WHITELIST_TICKET_ID = 0;

    /// @notice FOA rewards emitted per second per token
    /// @dev 600_000_000e18 / 18_000 / 10 / 365 / 24 / 60 / 60
    uint256 public constant REWARDS_PER_SECOND = 105699306612548;

    string public constant ERROR_LOCKED = "LOCKED";
    string public constant ERROR_NO_CONTRACT_MINTING = "NO_CONTRACT_MINTING";
    string public constant ERROR_NO_METADATA = "NO_METADATA";
    string public constant ERROR_NOT_APPROVED_FOR_REWARDS = "NOT_APPROVED_FOR_REWARDS";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_ARBORIA = "OVER_MAX_AMOUNT_PER_TX_ARBORIA";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD = "OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_LACREAN = "OVER_MAX_AMOUNT_PER_TX_LACREAN";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_TOTAL = "OVER_MAX_AMOUNT_PER_TX_TOTAL";
    string public constant ERROR_REACHED_MAX_SUPPLY_ARBORIA = "REACHED_MAX_SUPPLY_ARBORIA";
    string public constant ERROR_REACHED_MAX_SUPPLY_ILLSKAGAARD = "REACHED_MAX_SUPPLY_ILLSKAGAARD";
    string public constant ERROR_REACHED_MAX_SUPPLY_LACREAN = "REACHED_MAX_SUPPLY_LACREAN";
    string public constant ERROR_SALE_NOT_READY_WHITELIST = "SALE_NOT_READY_WHITELIST";
    string public constant ERROR_SALE_NOT_READY_PUBLIC = "SALE_NOT_READY_PUBLIC";
    string public constant ERROR_TOTAL_AMOUNT_BELOW_TWO = "TOTAL_AMOUNT_BELOW_TWO";
    string public constant ERROR_WRONG_PRICE = "WRONG_PRICE";

    /// @notice End of FOA rewards emittance
    uint256 public immutable TIMESTAMP_REWARDS_END;

    /// @notice Start of whitelist sale
    uint256 public immutable TIMESTAMP_SALE_WHITELIST;

    /// @notice Start of public sale
    uint256 public immutable TIMESTAMP_SALE_PUBLIC;

    /// @notice Tickets contract
    /// @custom:security non-reentrant
    ITickets public immutable TICKETS;

    uint256 private constant _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD = 16;
    uint256 private constant _BITSHIFT_TOTAL_SUPPLY_LACREAN = 32;

    uint256 private constant _BITSHIFT_REWARDS_LAST_UPDATED = 16;
    uint256 private constant _BITSHIFT_REWARDS_BALANCE = 48;

    uint256 private constant _BITMASK_TOTAL_SUPPLY = type(uint16).max;
    uint256 private constant _BITMASK_TOTAL_SUPPLY_ARBORIA = ~_BITMASK_TOTAL_SUPPLY;
    uint256 private constant _BITMASK_TOTAL_SUPPLY_ILLSKAGAARD = ~(_BITMASK_TOTAL_SUPPLY << _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD);
    uint256 private constant _BITMASK_TOTAL_SUPPLY_LACREAN = ~(_BITMASK_TOTAL_SUPPLY << _BITSHIFT_TOTAL_SUPPLY_LACREAN);

    uint256 private constant _BITMASK_REWARDS_TOKEN_BALANCE = type(uint16).max;
    uint256 private constant _BITMASK_REWARDS_LAST_UPDATED = type(uint32).max;

    // ---------- STATE ----------

    /// @notice Contains rewards balance, token balance, and timestamp of last rewards update for each token owner
    /// @dev Bit Layout:
    /// [0-15] Token balance - `tokenBalance`
    /// [16-47] Timestamp of last rewards update - `lastUpdated`
    /// [48-255] Rewards balance - `rewardsBalance`
    mapping(address => uint256) public rewardsBitField;

    /// @notice Approved addresses have write access to `rewardsBitField`
    /// @custom:security write-protection="onlyOwner()"
    mapping(address => bool) public isApprovedForRewards;

    /// @notice Lock manager contract
    /// @custom:security non-reentrant
    /// @custom:security write-protection="onlyOwner()"
    ILockManager public lockManager;

    /// @notice Metadata base URI
    /// @custom:security write-protection="onlyOwner()"
    string public baseURI;

    /// @notice Metadata URI suffix
    /// @custom:security write-protection="onlyOwner()"
    string public uriSuffix;

    /// @notice Contains total supply of each faction
    /// @dev Bit Layout:
    /// [0-15] Total supply of Arboria tokens - `totalSupplyArboria`
    /// [16-31] Total supply of Illskagard tokens - `totalSupplyIllskagard`
    /// [32-47] Total supply of Lacrean Empire tokens - `totalSupplyLacrean`
    uint256 private _totalSupplyBitField;

    // ---------- EVENTS ----------

    event ApprovalForRewards(address indexed operator, bool approved);

    event LockManagerTransfer(address indexed previousLockManager, address indexed newLockManager);

    // ---------- CONSTRUCTOR ----------

    /// @param owner Contract owner
    /// @param timestampSaleWhitelist Start of whitelist sale
    /// @param timestampSalePublic Start of public sale
    /// @param timestampRewardsEnd End of FOA rewards emittance
    /// @param tickets Address of tickets contract
    /// @param _lockManager Address of lock manager contract
    // slither-disable-next-line protected-vars
    constructor(
        address owner,
        uint256 timestampSaleWhitelist,
        uint256 timestampSalePublic,
        uint256 timestampRewardsEnd,
        address tickets,
        address _lockManager
    ) {
        _transferOwnership(owner);
        TIMESTAMP_SALE_WHITELIST = timestampSaleWhitelist;
        TIMESTAMP_SALE_PUBLIC = timestampSalePublic;
        TIMESTAMP_REWARDS_END = timestampRewardsEnd;
        TICKETS = ITickets(tickets);
        lockManager = ILockManager(_lockManager);
    }

    // ---------- METADATA ----------

    /// @notice Get metadata URI
    /// @param id Token ID
    /// @return Metadata URI of token ID `id`
    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, ERROR_NO_METADATA);
        require(id < MAX_SUPPLY, ERROR_INVALID_ID);
        return string(abi.encodePacked(baseURI, Strings.toString(id), uriSuffix));
    }

    /// @notice Set metadata base URI
    /// @param _baseURI New metadata base URI
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Set metadata URI suffix
    /// @param _uriSuffix New metadata URI suffix
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setURISuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // ---------- TOTAL SUPPLY ----------

    function totalSupplyArboria() public view returns (uint256) {
        return _totalSupplyBitField & _BITMASK_TOTAL_SUPPLY;
    }

    function totalSupplyIllskagaard() public view returns (uint256) {
        return _totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD & _BITMASK_TOTAL_SUPPLY;
    }

    function totalSupplyLacrean() public view returns (uint256) {
        return _totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_LACREAN;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupplyArboria() + totalSupplyIllskagaard() + totalSupplyLacrean();
    }

    // ---------- LOCK MANAGER ----------

    function setLockManager(address _lockManager) external onlyOwner {
        emit LockManagerTransfer(address(lockManager), _lockManager);
        lockManager = ILockManager(_lockManager);
    }

    // ---------- REWARDS ----------

    function setApprovalForRewards(address operator, bool approved) external onlyOwner {
        isApprovedForRewards[operator] = approved;
        emit ApprovalForRewards(operator, approved);
    }

    function setRewardsBitField(address owner, uint256 _rewardsBitField) external {
        require(isApprovedForRewards[msg.sender], ERROR_NOT_APPROVED_FOR_REWARDS);
        rewardsBitField[owner] = _rewardsBitField;
    }

    /// @notice Returns the token balance of the given address
    /// @param owner Address to check
    function balanceOf(address owner) public view returns (uint256) {
        return rewardsBitField[owner] & _BITMASK_REWARDS_TOKEN_BALANCE;
    }

    /// @notice Returns the FOA rewards balance of the given address
    /// @param owner Address to check
    function rewardsOf(address owner) external view returns (uint256 rewardsBalance) {
        rewardsBalance = rewardsBitField[owner] >> _BITSHIFT_REWARDS_BALANCE;
        uint256 lastUpdated = rewardsBitField[owner] >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;

        if (lastUpdated != TIMESTAMP_REWARDS_END) {
            // Use current block timestamp or rewards end timestamp if reached
            uint256 timestamp = block.timestamp < TIMESTAMP_REWARDS_END ? block.timestamp : TIMESTAMP_REWARDS_END;
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
        uint256 timestamp = block.timestamp < TIMESTAMP_REWARDS_END ? block.timestamp : TIMESTAMP_REWARDS_END;

        // Store bit field in memory to reduce number of SLOADs
        uint256 _rewardsBitField = rewardsBitField[from];
        uint256 lastUpdated = _rewardsBitField >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;

        // Update rewards bit field of `from`, unless it has already been updated since the reward emittence ended
        if (lastUpdated != TIMESTAMP_REWARDS_END) {
            uint256 tokenBalance = _rewardsBitField & _BITMASK_REWARDS_TOKEN_BALANCE;
            uint256 rewardsBalance = _rewardsBitField >> _BITSHIFT_REWARDS_BALANCE;

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                unchecked {
                    rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
                }
            }

            unchecked {
                // Update rewards bit field of `from` with new token balance, last updated timestamp, and rewards balance
                rewardsBitField[from] = tokenBalance - tokenAmount | timestamp << _BITSHIFT_REWARDS_LAST_UPDATED | rewardsBalance << _BITSHIFT_REWARDS_BALANCE;
            }
        }

        // Store bit field in memory to reduce number of SLOADs
        _rewardsBitField = rewardsBitField[to];
        lastUpdated = _rewardsBitField >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;

        // Update rewards bit field of `to`, unless it has already been updated since the reward emittence ended
        if (lastUpdated != TIMESTAMP_REWARDS_END) {
            uint256 tokenBalance = _rewardsBitField & _BITMASK_REWARDS_TOKEN_BALANCE;
            uint256 rewardsBalance = _rewardsBitField >> _BITSHIFT_REWARDS_BALANCE;

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                unchecked {
                    rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
                }
            }

            unchecked {
                // Update rewards bit field of `to` with new token balance, last updated timestamp, and rewards balance
                rewardsBitField[to] = tokenBalance + tokenAmount | timestamp << _BITSHIFT_REWARDS_LAST_UPDATED | rewardsBalance << _BITSHIFT_REWARDS_BALANCE;
            }
        }
    }

    function _updateRewardsForMint(address to, uint256 tokenAmount) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 _rewardsBitField = rewardsBitField[to];
        uint256 tokenBalance = _rewardsBitField & _BITMASK_REWARDS_TOKEN_BALANCE;
        uint256 lastUpdated = _rewardsBitField >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;
        uint256 rewardsBalance = _rewardsBitField >> _BITSHIFT_REWARDS_BALANCE;

        // Calculate rewards collected since last update and add them to balance
        if (lastUpdated > 0) {
            uint256 secondsSinceLastUpdate = block.timestamp - lastUpdated;
            unchecked {
                rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
            }
        }

        unchecked {
            // Update rewards bit field of `to` with new token balance, last updated timestamp, and rewards balance
            rewardsBitField[to] = tokenBalance + tokenAmount | block.timestamp << _BITSHIFT_REWARDS_LAST_UPDATED | rewardsBalance << _BITSHIFT_REWARDS_BALANCE;
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
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);
        require(id < MAX_SUPPLY, ERROR_INVALID_ID);
        require(amount == 1, ERROR_INVALID_AMOUNT);
        require(!lockManager.isLocked(address(this), msg.sender, from, to, id), ERROR_LOCKED);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Load address stored in `ownerOf[id]`
            let ownerOfId := sload(ownerOfIdSlot)
            // Make sure we're only using the first 160 bits of the storage slot
            // as the remaining 96 bits might not be zero
            ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

            // Revert with message "FROM_NOT_OWNER" if `ownerOf[id]` is not `from`
            if xor(ownerOfId, from) {
                // Load free memory position
                let freeMemory := mload(0x40)
                // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                // Store data offset
                mstore(add(freeMemory, 0x04), 0x20)
                // Store length of revert message
                mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_OWNER)
                // Store revert message
                mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_OWNER)
                revert(freeMemory, 0x64)
            }

            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        _updateRewardsForTransfer(from, to, amount);
        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        require(ids.length == amounts.length, ERROR_ARRAY_LENGTH_MISMATCH);
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);
        require(!lockManager.isLocked(address(this), msg.sender, from, to, ids), ERROR_LOCKED);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let id := calldataload(add(ids.offset, indexOffset))

                // Revert with message "INVALID_ID" if `id` is higher than `MAX_ID`
                if gt(id, MAX_ID) {
                    // Load free memory position
                    // slither-disable-next-line variable-scope
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_ID)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_ID)
                    revert(freeMemory, 0x64)
                }

                // Revert with message "INVALID_AMOUNT" if amount is not 1
                if xor(calldataload(add(amounts.offset, indexOffset)), 1) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_AMOUNT)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_AMOUNT)
                    revert(freeMemory, 0x64)
                }

                // Calculate storage slot of `ownerOf[id]`
                let ownerOfIdSlot := add(ownerOf.slot, id)
                // Load address stored in `ownerOf[id]`
                let ownerOfId := sload(ownerOfIdSlot)
                // Make sure we're only using the first 160 bits of the storage slot
                // as the remaining 96 bits might not be zero
                ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

                // Revert with message "FROM_NOT_OWNER" if `ownerOf[id]` is not `from`
                if xor(ownerOfId, from) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_OWNER)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_OWNER)
                    revert(freeMemory, 0x64)
                }

                // Store address of `to` in `ownerOf[id]`
                sstore(ownerOfIdSlot, to)
            }
        }

        _updateRewardsForTransfer(from, to, ids.length);
        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // ---------- WHITELIST SALE ----------

    /// @notice Mint a single Arboria token during whitelist sale
    function mintWhitelistArboria() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);

        // Burn whitelist ticket
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, 1);

        _mintArboria(msg.sender);
    }

    /// @notice Mint a single Illskagaard token during whitelist sale
    function mintWhitelistIllskagaard() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);

        // Burn whitelist ticket
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, 1);

        _mintIllskagaard(msg.sender);
    }

    /// @notice Mint a single Lacrean Empire token during whitelist sale
    function mintWhitelistLacrean() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);

        // Burn whitelist ticket
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, 1);

        _mintLacrean(msg.sender);
    }

    /// @notice Batch mint specified amount of tokens during whitelist sale
    /// @param amountArboria Amount of Arboria tokens to mint
    /// @param amountIllskagaard Amount of Illskagaard tokens to mint
    /// @param amountLacrean Amount of Lacrean tokens to mint
    function batchMintWhitelist(uint256 amountArboria, uint256 amountIllskagaard, uint256 amountLacrean) external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);

        // Doing these checks and later calculating the total amount unchecked costs less gas
        // than not doing these checks and calculating the total amount checked
        require(amountArboria <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ARBORIA);
        require(amountIllskagaard <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD);
        require(amountLacrean <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_LACREAN);

        uint256 amountTotal;
        unchecked {
            amountTotal = amountArboria + amountIllskagaard + amountLacrean;
        }
        require(amountTotal <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_TOTAL);
        require(amountTotal > 1, ERROR_TOTAL_AMOUNT_BELOW_TWO);
        unchecked {
            require(msg.value == amountTotal * MINT_PRICE, ERROR_WRONG_PRICE);
        }

        // Burn whitelist tickets
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, amountTotal);

        _batchMint(msg.sender, amountArboria, amountIllskagaard, amountLacrean, amountTotal);
    }

    // ---------- PUBLIC SALE ----------

    /// @notice Mint a single Arboria token during public sale
    function mintPublicArboria() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);
        _mintArboria(msg.sender);
    }

    /// @notice Mint a single Illskagaard token during public sale
    function mintPublicIllskagaard() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);
        _mintIllskagaard(msg.sender);
    }

    /// @notice Mint a single Lacrean Empire token during public sale
    function mintPublicLacrean() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);
        _mintLacrean(msg.sender);
    }

    /// @notice Batch mint specified amount of tokens during public sale
    /// @param amountArboria Amount of Arboria tokens to mint
    /// @param amountIllskagaard Amount of Illskagaard tokens to mint
    /// @param amountLacrean Amount of Lacrean tokens to mint
    function batchMintPublic(uint256 amountArboria, uint256 amountIllskagaard, uint256 amountLacrean) external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);

        // Doing these checks and later calculating the total amount unchecked costs less gas
        // than not doing these checks and calculating the total amount checked
        require(amountArboria <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ARBORIA);
        require(amountIllskagaard <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD);
        require(amountLacrean <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_LACREAN);

        uint256 amountTotal;
        unchecked {
            amountTotal = amountArboria + amountIllskagaard + amountLacrean;
        }
        require(amountTotal <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_TOTAL);
        require(amountTotal > 1, ERROR_TOTAL_AMOUNT_BELOW_TWO);
        unchecked {
            require(msg.value == amountTotal * MINT_PRICE, ERROR_WRONG_PRICE);
        }

        _batchMint(msg.sender, amountArboria, amountIllskagaard, amountLacrean, amountTotal);
    }

    // ---------- MINT ----------

    /// @notice Mint a single Lacrean Empire token as contract owner
    /// @param to Receiver of minted token
    function mintOwnerLacrean(address to) external onlyOwner {
        _mintLacrean(to);
    }

    /// @notice Batch mint as contract owner
    /// @param tos Receivers of minted tokens
    /// @param amountsArboria Amounts of Arboria tokens to mint
    /// @param amountsIllskagaard Amounts of Illskagaard tokens to mint
    /// @param amountsLacrean Amounts of Lacrean tokens to mint
    function batchMintOwner(
        address[] calldata tos,
        uint256[] calldata amountsArboria,
        uint256[] calldata amountsIllskagaard,
        uint256[] calldata amountsLacrean
    ) external onlyOwner {
        require(
            tos.length == amountsArboria.length &&
            amountsArboria.length == amountsIllskagaard.length &&
            amountsIllskagaard.length == amountsLacrean.length,
            ERROR_ARRAY_LENGTH_MISMATCH
        );

        // Calculate array length in bytes
        uint256 arrayLength;
        unchecked {
            arrayLength = tos.length * 0x20;
        }

        for (uint256 indexOffset = 0x00; indexOffset < arrayLength;) {
            address to;
            uint256 amountArboria;
            uint256 amountIllskagaard;
            uint256 amountLacrean;

            /// @solidity memory-safe-assembly
            assembly {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                to := calldataload(add(tos.offset, indexOffset))
                amountArboria := calldataload(add(amountsArboria.offset, indexOffset))
                amountIllskagaard := calldataload(add(amountsIllskagaard.offset, indexOffset))
                amountLacrean := calldataload(add(amountsLacrean.offset, indexOffset))

                // Increment index offset by 32 for next iteration
                indexOffset := add(indexOffset, 0x20)
            }

            unchecked {
                uint256 amountTotal = amountArboria + amountIllskagaard + amountLacrean;
                _batchMint(to, amountArboria, amountIllskagaard, amountLacrean, amountTotal);
            }
        }
    }

    /// @dev Mint a single Arboria token
    /// @param to Receiver of minted token
    function _mintArboria(address to) internal {
        // Total supply of Arboria tokens is stored in the first 16 bits of the bit field
        uint256 id = _totalSupplyBitField & _BITMASK_TOTAL_SUPPLY;
        require(id < MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ARBORIA);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        unchecked {
            // Incrementing the whole bit field increments just the total supply of
            // Arboria tokens, because only the value stored in the first bits gets updated
            _totalSupplyBitField++;
        }

        _updateRewardsForMint(to, 1);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    /// @dev Mint a single Illskagaard token
    /// @param to Receiver of minted token
    function _mintIllskagaard(address to) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // Total supply of Illskagaard tokens is stored in the second 16 bits of the bit field
        uint256 _totalSupplyIllskagaard = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD & _BITMASK_TOTAL_SUPPLY;
        require(_totalSupplyIllskagaard < MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ILLSKAGAARD);

        uint256 id;
        unchecked {
            // Illskagaard token IDs start at 6000
            id = ID_OFFSET_ILLSKAGAARD + _totalSupplyIllskagaard;
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        unchecked {
            // Second 16 bits need to be all set to 0 before the new total supply of
            // Illskagaard tokens can be stored
            _totalSupplyBitField = totalSupplyBitField & _BITMASK_TOTAL_SUPPLY_ILLSKAGAARD | ++_totalSupplyIllskagaard << _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD;
        }

        _updateRewardsForMint(to, 1);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    /// @dev Mint a single Lacrean Empire token
    /// @param to Receiver of minted token
    function _mintLacrean(address to) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // Total supply of Lacrean Empire tokens is stored in the third 16 bits of the bit field
        uint256 _totalSupplyLacrean = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_LACREAN;
        require(_totalSupplyLacrean < MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_LACREAN);

        uint256 id;
        unchecked {
            // Lacrean Empire token IDs start at 12000
            id = ID_OFFSET_LACREAN + _totalSupplyLacrean;
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        unchecked {
            // Third 16 bits need to be all set to 0 before the new total supply of
            // Lacrean Empire tokens can be stored
            _totalSupplyBitField = totalSupplyBitField & _BITMASK_TOTAL_SUPPLY_LACREAN | ++_totalSupplyLacrean << _BITSHIFT_TOTAL_SUPPLY_LACREAN;
        }

        _updateRewardsForMint(to, 1);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    /// @notice Batch mint specified amount of tokens
    /// @param to Receiver of minted tokens
    /// @param amountArboria Amount of Arboria tokens to mint
    /// @param amountIllskagaard Amount of Illskagaard tokens to mint
    /// @param amountLacrean Amount of Lacrean tokens to mint
    /// @param amountTotal Total amount of tokens to mint
    function _batchMint(
        address to,
        uint256 amountArboria,
        uint256 amountIllskagaard,
        uint256 amountLacrean,
        uint256 amountTotal
    ) internal {
        // Token IDs and amounts are collected in arrays to later emit the TransferBatch event
        uint256[] memory ids = new uint256[](amountTotal);
        // Token amounts are all 1
        uint256[] memory amounts = new uint256[](amountTotal);

        // Keep track of the current index offsets for each array
        uint256 offsetIds;
        uint256 offsetAmounts;

        /// @solidity memory-safe-assembly
        assembly {
            // Skip the first 32 bytes containing the array length
            offsetIds := add(ids, 0x20)
            offsetAmounts := add(amounts, 0x20)
        }

        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // New bit field gets updated in memory to reduce number of SSTOREs
        // _totalSupplyBitField is only updated once after all tokens are minted
        uint256 newTotalSupplyBitField = totalSupplyBitField;

        if (amountArboria > 0) {
            // Total supply of Arboria tokens is stored in the first 16 bits of the bit field
            uint256 _totalSupplyArboria = totalSupplyBitField & _BITMASK_TOTAL_SUPPLY;
            uint256 newTotalSupplyArboria;
            unchecked {
                newTotalSupplyArboria = _totalSupplyArboria + amountArboria;
            }
            require(newTotalSupplyArboria <= MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ARBORIA);

            /// @solidity memory-safe-assembly
            assembly {
                // Set owner of Arboria token IDs
                for { let id := _totalSupplyArboria } lt(id, newTotalSupplyArboria) { id := add(id, 1) } {
                    // Calculate storage slot of `ownerOf[id]`
                    let ownerOfIdSlot := add(ownerOf.slot, id)
                    // Store address of `to` in `ownerOf[id]`
                    sstore(ownerOfIdSlot, to)

                    // Store id and amount in the corresponding memory arrays
                    mstore(offsetIds, id)
                    mstore(offsetAmounts, 1)

                    // Increment index offsets by 32 for next iteration
                    offsetIds := add(offsetIds, 0x20)
                    offsetAmounts := add(offsetAmounts, 0x20)
                }
            }

            // First 16 bits need to be all set to 0 before the new total supply of Arboria tokens can be stored
            newTotalSupplyBitField = newTotalSupplyBitField & _BITMASK_TOTAL_SUPPLY_ARBORIA | newTotalSupplyArboria;
        }

        if (amountIllskagaard > 0) {
            // Total supply of Illskagaard tokens is stored in the second 16 bits of the bit field
            uint256 _totalSupplyIllskagaard = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD & _BITMASK_TOTAL_SUPPLY;
            uint256 newTotalSupplyIllskagaard;
            unchecked {
                newTotalSupplyIllskagaard = _totalSupplyIllskagaard + amountIllskagaard;
            }
            require(newTotalSupplyIllskagaard <= MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ILLSKAGAARD);

            /// @solidity memory-safe-assembly
            assembly {
                // Set owner of Illskagaard token IDs
                for { let i := _totalSupplyIllskagaard } lt(i, newTotalSupplyIllskagaard) { i := add(i, 1) } {
                    // Illskagaard token IDs start at 6000
                    let id := add(ID_OFFSET_ILLSKAGAARD, i)

                    // Calculate storage slot of `ownerOf[id]`
                    let ownerOfIdSlot := add(ownerOf.slot, id)
                    // Store address of `to` in `ownerOf[id]`
                    sstore(ownerOfIdSlot, to)

                    // Store id and amount in the corresponding memory arrays
                    mstore(offsetIds, id)
                    mstore(offsetAmounts, 1)

                    // Increment index offsets by 32 for next iteration
                    offsetIds := add(offsetIds, 0x20)
                    offsetAmounts := add(offsetAmounts, 0x20)
                }
            }

            // Second 16 bits need to be all set to 0 before the new total supply of Illskagaard tokens can be stored
            newTotalSupplyBitField = newTotalSupplyBitField & _BITMASK_TOTAL_SUPPLY_ILLSKAGAARD | newTotalSupplyIllskagaard << _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD;
        }

        if (amountLacrean > 0) {
            // Total supply of Lacrean Empire tokens is stored in the third 16 bits of the bit field
            uint256 _totalSupplyLacrean = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_LACREAN;
            uint256 newTotalSupplyLacrean;
            unchecked {
                newTotalSupplyLacrean = _totalSupplyLacrean + amountLacrean;
            }
            require(newTotalSupplyLacrean <= MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_LACREAN);

            /// @solidity memory-safe-assembly
            assembly {
                // Set owner of Lacrean Empire token IDs
                for { let i := _totalSupplyLacrean } lt(i, newTotalSupplyLacrean) { i := add(i, 1) } {
                    // Lacrean Empire token IDs start at 12000
                    let id := add(ID_OFFSET_LACREAN, i)

                    // Calculate storage slot of `ownerOf[id]`
                    let ownerOfIdSlot := add(ownerOf.slot, id)
                    // Store address of `to` in `ownerOf[id]`
                    sstore(ownerOfIdSlot, to)

                    // Store id and amount in the corresponding memory arrays
                    mstore(offsetIds, id)
                    mstore(offsetAmounts, 1)

                    // Increment index offsets by 32 for next iteration
                    offsetIds := add(offsetIds, 0x20)
                    offsetAmounts := add(offsetAmounts, 0x20)
                }
            }

            // Third 16 bits need to be all set to 0 before the new total supply of Lacrean Empire tokens can be stored
            newTotalSupplyBitField = newTotalSupplyBitField & _BITMASK_TOTAL_SUPPLY_LACREAN | newTotalSupplyLacrean << _BITSHIFT_TOTAL_SUPPLY_LACREAN;
        }

        // slither-disable-next-line costly-loop
        _totalSupplyBitField = newTotalSupplyBitField;
        _updateRewardsForMint(to, amountTotal);
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    // ---------- OWNERS ----------

    function owners() external view returns (address[MAX_SUPPLY] memory) {
        return ownerOf;
    }

    // ---------- WITHDRAW ----------

    /// @notice Withdraw all Ether stored in this contract to address of contract owner
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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
pragma solidity 0.8.14;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

/// @title Minimalist and gas efficient ERC1155 implementation optimized for single supply ids
/// @author Solarbots (https://solarbots.io)
/// @notice Based on Solmate implementation (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155B.sol)
abstract contract ERC1155B {
    // ---------- CONSTANTS ----------

    /// @notice Maximum amount of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 18_000;

    /// @notice Maximum token ID
    /// @dev Inline assembly does not support non-number constants like `MAX_SUPPLY - 1`
    uint256 public constant MAX_ID = 17_999;

    string public constant ERROR_ARRAY_LENGTH_MISMATCH = "ARRAY_LENGTH_MISMATCH";
    string public constant ERROR_FROM_NOT_OWNER = "FROM_NOT_OWNER";
    string public constant ERROR_ID_ALREADY_MINTED = "ID_ALREADY_MINTED";
    string public constant ERROR_ID_NOT_MINTED = "ID_NOT_MINTED";
    string public constant ERROR_INVALID_AMOUNT = "INVALID_AMOUNT";
    string public constant ERROR_INVALID_FROM = "INVALID_FROM";
    string public constant ERROR_INVALID_ID = "INVALID_ID";
    string public constant ERROR_INVALID_RECIPIENT = "INVALID_RECIPIENT";
    string public constant ERROR_NOT_AUTHORIZED = "NOT_AUTHORIZED";
    string public constant ERROR_UNSAFE_RECIPIENT = "UNSAFE_RECIPIENT";

    /// @dev bytes32(abi.encodePacked("INVALID_ID"))
    bytes32 internal constant _ERROR_ENCODED_INVALID_ID = 0x494e56414c49445f494400000000000000000000000000000000000000000000;

    /// @dev bytes32(abi.encodePacked("INVALID_AMOUNT"))
    bytes32 internal constant _ERROR_ENCODED_INVALID_AMOUNT = 0x494e56414c49445f414d4f554e54000000000000000000000000000000000000;

    /// @dev bytes32(abi.encodePacked("FROM_NOT_OWNER"))
    bytes32 internal constant _ERROR_ENCODED_FROM_NOT_OWNER = 0x46524f4d5f4e4f545f4f574e4552000000000000000000000000000000000000;

    /// @dev "INVALID_ID" is 14 characters long
    uint256 internal constant _ERROR_LENGTH_INVALID_ID = 10;

    /// @dev "INVALID_AMOUNT" is 14 characters long
    uint256 internal constant _ERROR_LENGTH_INVALID_AMOUNT = 14;

    /// @dev "FROM_NOT_OWNER" is 14 characters long
    uint256 internal constant _ERROR_LENGTH_FROM_NOT_OWNER = 14;

    /// @dev "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
    bytes32 internal constant _ERROR_FUNCTION_SIGNATURE = 0x08c379a000000000000000000000000000000000000000000000000000000000;

    /// @dev Inline assembly does not support non-number constants like `type(uint160).max`
    uint256 internal constant _BITMASK_ADDRESS = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    // ---------- STATE ----------

    address[MAX_SUPPLY] public ownerOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // ---------- EVENTS ----------

    event URI(string value, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

    // ---------- ERC-165 ----------

    // slither-disable-next-line external-function
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    // ---------- METADATA ----------

    // slither-disable-next-line external-function
    function uri(uint256 id) public view virtual returns (string memory);

    // ---------- APPROVAL ----------

    // slither-disable-next-line external-function
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ---------- BALANCE ----------

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 bal) {
        address idOwner = ownerOf[id];

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

    // slither-disable-next-line external-function
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, ERROR_ARRAY_LENGTH_MISMATCH);

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    // ---------- TRANSFER ----------

    // slither-disable-next-line external-function
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);
        require(id < MAX_SUPPLY, ERROR_INVALID_ID);
        require(amount == 1, ERROR_INVALID_AMOUNT);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Load address stored in `ownerOf[id]`
            let ownerOfId := sload(ownerOfIdSlot)
            // Make sure we're only using the first 160 bits of the storage slot
            // as the remaining 96 bits might not be zero
            ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

            // Revert with message "FROM_NOT_OWNER" if `ownerOf[id]` is not `from`
            if xor(ownerOfId, from) {
                // Load free memory position
                let freeMemory := mload(0x40)
                // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                // Store data offset
                mstore(add(freeMemory, 0x04), 0x20)
                // Store length of revert message
                mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_OWNER)
                // Store revert message
                mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_OWNER)
                revert(freeMemory, 0x64)
            }

            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // slither-disable-next-line external-function
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, ERROR_ARRAY_LENGTH_MISMATCH);
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let id := calldataload(add(ids.offset, indexOffset))

                // Revert with message "INVALID_ID" if `id` is higher than `MAX_ID`
                if gt(id, MAX_ID) {
                    // Load free memory position
                    // slither-disable-next-line variable-scope
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_ID)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_ID)
                    revert(freeMemory, 0x64)
                }

                // Revert with message "INVALID_AMOUNT" if amount is not 1
                if xor(calldataload(add(amounts.offset, indexOffset)), 1) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_AMOUNT)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_AMOUNT)
                    revert(freeMemory, 0x64)
                }

                // Calculate storage slot of `ownerOf[id]`
                let ownerOfIdSlot := add(ownerOf.slot, id)
                // Load address stored in `ownerOf[id]`
                let ownerOfId := sload(ownerOfIdSlot)
                // Make sure we're only using the first 160 bits of the storage slot
                // as the remaining 96 bits might not be zero
                ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

                // Revert with message "FROM_NOT_OWNER" if `ownerOf[id]` is not `from`
                if xor(ownerOfId, from) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_OWNER)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_OWNER)
                    revert(freeMemory, 0x64)
                }

                // Store address of `to` in `ownerOf[id]`
                sstore(ownerOfIdSlot, to)
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // ---------- MINT ----------

    // slither-disable-next-line dead-code
    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        // Minting twice would effectively be a force transfer.
        require(ownerOf[id] == address(0), ERROR_ID_ALREADY_MINTED);

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, 1, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // slither-disable-next-line dead-code
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
                require(ownerOf[id] == address(0), ERROR_ID_ALREADY_MINTED);

                ownerOf[id] = to;

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // ---------- BURN ----------

    // slither-disable-next-line dead-code
    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), ERROR_ID_NOT_MINTED);

        ownerOf[id] = address(0);

        emit TransferSingle(msg.sender, owner, address(0), id, 1);
    }

    // slither-disable-next-line dead-code
    function _batchBurn(address from, uint256[] memory ids) internal virtual {
        // Burning unminted tokens makes no sense.
        require(from != address(0), ERROR_INVALID_FROM);

        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                require(from == ownerOf[id], ERROR_FROM_NOT_OWNER);

                ownerOf[id] = address(0);

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Solarbots Lock Manager Interface
/// @author Solarbots (https://solarbots.io)
interface ILockManager {
    function isLocked(address collection, address operator, address from, address to, uint256 id) external returns (bool);
    function isLocked(address collection, address operator, address from, address to, uint256[] calldata ids) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Solarbots Tickets Interface
/// @author Solarbots (https://solarbots.io)
interface ITickets {
    function burn(address from, uint256 id, uint256 amount) external;
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