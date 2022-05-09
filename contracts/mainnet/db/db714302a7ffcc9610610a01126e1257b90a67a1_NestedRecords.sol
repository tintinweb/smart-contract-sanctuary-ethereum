// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "./abstracts/OwnableFactoryHandler.sol";

/// @title Tracks data for underlying assets of NestedNFTs
contract NestedRecords is OwnableFactoryHandler {
    /* ------------------------------ EVENTS ------------------------------ */

    /// @dev Emitted when maxHoldingsCount is updated
    /// @param maxHoldingsCount The new value
    event MaxHoldingsChanges(uint256 maxHoldingsCount);

    /// @dev Emitted when the lock timestamp of an NFT is increased
    /// @param nftId The NFT ID
    /// @param timestamp The new lock timestamp of the portfolio
    event LockTimestampIncreased(uint256 nftId, uint256 timestamp);

    /// @dev Emitted when the reserve is updated for a specific portfolio
    /// @param nftId The NFT ID
    /// @param newReserve The new reserve address
    event ReserveUpdated(uint256 nftId, address newReserve);

    /* ------------------------------ STRUCTS ------------------------------ */

    /// @dev Store user asset informations
    struct NftRecord {
        mapping(address => uint256) holdings;
        address[] tokens;
        address reserve;
        uint256 lockTimestamp;
    }

    /* ----------------------------- VARIABLES ----------------------------- */

    /// @dev stores for each NFT ID an asset record
    mapping(uint256 => NftRecord) public records;

    /// @dev The maximum number of holdings for an NFT record
    uint256 public maxHoldingsCount;

    /* ---------------------------- CONSTRUCTOR ---------------------------- */

    constructor(uint256 _maxHoldingsCount) {
        maxHoldingsCount = _maxHoldingsCount;
    }

    /* -------------------------- OWNER FUNCTIONS -------------------------- */

    /// @notice Sets the maximum number of holdings for an NFT record
    /// @param _maxHoldingsCount The new maximum number of holdings
    function setMaxHoldingsCount(uint256 _maxHoldingsCount) external onlyOwner {
        require(_maxHoldingsCount != 0, "NRC: INVALID_MAX_HOLDINGS");
        maxHoldingsCount = _maxHoldingsCount;
        emit MaxHoldingsChanges(maxHoldingsCount);
    }

    /* ------------------------- FACTORY FUNCTIONS ------------------------- */

    /// @notice Update the amount for a specific holding and delete
    /// the holding if the amount is zero.
    /// @param _nftId The id of the NFT
    /// @param _token The token/holding address
    /// @param _amount Updated amount for this asset
    function updateHoldingAmount(
        uint256 _nftId,
        address _token,
        uint256 _amount
    ) public onlyFactory {
        if (_amount == 0) {
            uint256 tokenIndex = 0;
            address[] memory tokens = getAssetTokens(_nftId);
            while (tokenIndex < tokens.length) {
                if (tokens[tokenIndex] == _token) {
                    deleteAsset(_nftId, tokenIndex);
                    break;
                }
                tokenIndex++;
            }
        } else {
            records[_nftId].holdings[_token] = _amount;
        }
    }

    /// @notice Fully delete a holding record for an NFT
    /// @param _nftId The id of the NFT
    /// @param _tokenIndex The token index in holdings array
    function deleteAsset(uint256 _nftId, uint256 _tokenIndex) public onlyFactory {
        address[] storage tokens = records[_nftId].tokens;
        address token = tokens[_tokenIndex];

        require(records[_nftId].holdings[token] != 0, "NRC: HOLDING_INACTIVE");

        delete records[_nftId].holdings[token];
        tokens[_tokenIndex] = tokens[tokens.length - 1];
        tokens.pop();
    }

    /// @notice Delete a holding item in holding mapping. Does not remove token in NftRecord.tokens array
    /// @param _nftId NFT's identifier
    /// @param _token Token address for holding to remove
    function freeHolding(uint256 _nftId, address _token) public onlyFactory {
        delete records[_nftId].holdings[_token];
    }

    /// @notice Helper function that creates a record or add the holding if record already exists
    /// @param _nftId The NFT's identifier
    /// @param _token The token/holding address
    /// @param _amount Amount to add for this asset
    /// @param _reserve Reserve address
    function store(
        uint256 _nftId,
        address _token,
        uint256 _amount,
        address _reserve
    ) external onlyFactory {
        NftRecord storage _nftRecord = records[_nftId];

        uint256 amount = records[_nftId].holdings[_token];
        require(_amount != 0, "NRC: INVALID_AMOUNT");
        if (amount != 0) {
            require(_nftRecord.reserve == _reserve, "NRC: RESERVE_MISMATCH");
            updateHoldingAmount(_nftId, _token, amount + _amount);
            return;
        }
        require(_nftRecord.tokens.length < maxHoldingsCount, "NRC: TOO_MANY_TOKENS");
        require(
            _reserve != address(0) && (_reserve == _nftRecord.reserve || _nftRecord.reserve == address(0)),
            "NRC: INVALID_RESERVE"
        );

        _nftRecord.holdings[_token] = _amount;
        _nftRecord.tokens.push(_token);
        _nftRecord.reserve = _reserve;
    }

    /// @notice The factory can update the lock timestamp of a NFT record
    /// The new timestamp must be greater than the records lockTimestamp
    //  if block.timestamp > actual lock timestamp
    /// @param _nftId The NFT id to get the record
    /// @param _timestamp The new timestamp
    function updateLockTimestamp(uint256 _nftId, uint256 _timestamp) external onlyFactory {
        require(_timestamp > records[_nftId].lockTimestamp, "NRC: LOCK_PERIOD_CANT_DECREASE");
        records[_nftId].lockTimestamp = _timestamp;
        emit LockTimestampIncreased(_nftId, _timestamp);
    }

    /// @notice Delete from mapping assetTokens
    /// @param _nftId The id of the NFT
    function removeNFT(uint256 _nftId) external onlyFactory {
        delete records[_nftId];
    }

    /// @notice Set the reserve where assets are stored
    /// @param _nftId The NFT ID to update
    /// @param _nextReserve Address for the new reserve
    function setReserve(uint256 _nftId, address _nextReserve) external onlyFactory {
        records[_nftId].reserve = _nextReserve;
        emit ReserveUpdated(_nftId, _nextReserve);
    }

    /* ------------------------------- VIEWS ------------------------------- */

    /// @notice Get content of assetTokens mapping
    /// @param _nftId The id of the NFT
    /// @return Array of token addresses
    function getAssetTokens(uint256 _nftId) public view returns (address[] memory) {
        return records[_nftId].tokens;
    }

    /// @notice Get reserve the assets are stored in
    /// @param _nftId The NFT ID
    /// @return The reserve address these assets are stored in
    function getAssetReserve(uint256 _nftId) external view returns (address) {
        return records[_nftId].reserve;
    }

    /// @notice Get how many tokens are in a portfolio/NFT
    /// @param _nftId NFT ID to examine
    /// @return The array length
    function getAssetTokensLength(uint256 _nftId) external view returns (uint256) {
        return records[_nftId].tokens.length;
    }

    /// @notice Get holding amount for a given nft id
    /// @param _nftId The id of the NFT
    /// @param _token The address of the token
    /// @return The holding amount
    function getAssetHolding(uint256 _nftId, address _token) public view returns (uint256) {
        return records[_nftId].holdings[_token];
    }

    /// @notice Returns the holdings associated to a NestedAsset
    /// @param _nftId the id of the NestedAsset
    /// @return Two arrays with the same length :
    ///         - The token addresses in the portfolio
    ///         - The respective amounts
    function tokenHoldings(uint256 _nftId) external view returns (address[] memory, uint256[] memory) {
        address[] memory tokens = getAssetTokens(_nftId);
        uint256 tokensCount = tokens.length;
        uint256[] memory amounts = new uint256[](tokensCount);

        for (uint256 i = 0; i < tokensCount; i++) {
            amounts[i] = getAssetHolding(_nftId, tokens[i]);
        }
        return (tokens, amounts);
    }

    /// @notice Get the lock timestamp of a portfolio/NFT
    /// @param _nftId The NFT ID
    /// @return The lock timestamp from the NftRecord
    function getLockTimestamp(uint256 _nftId) external view returns (uint256) {
        return records[_nftId].lockTimestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Asbtract "Ownable" contract managing a whitelist of factories
abstract contract OwnableFactoryHandler is Ownable {
    /// @dev Emitted when a new factory is added
    /// @param newFactory Address of the new factory
    event FactoryAdded(address newFactory);

    /// @dev Emitted when a factory is removed
    /// @param oldFactory Address of the removed factory
    event FactoryRemoved(address oldFactory);

    /// @dev Supported factories to interact with
    mapping(address => bool) public supportedFactories;

    /// @dev Reverts the transaction if the caller is a supported factory
    modifier onlyFactory() {
        require(supportedFactories[msg.sender], "OFH: FORBIDDEN");
        _;
    }

    /// @notice Add a supported factory
    /// @param _factory The address of the new factory
    function addFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "OFH: INVALID_ADDRESS");
        supportedFactories[_factory] = true;
        emit FactoryAdded(_factory);
    }

    /// @notice Remove a supported factory
    /// @param _factory The address of the factory to remove
    function removeFactory(address _factory) external onlyOwner {
        require(supportedFactories[_factory], "OFH: NOT_SUPPORTED");
        supportedFactories[_factory] = false;
        emit FactoryRemoved(_factory);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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