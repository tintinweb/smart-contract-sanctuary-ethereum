// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable} from "../lib/utils/Ownable.sol";
import {ReentrancyGuard} from "../lib/utils/ReentrancyGuard.sol";
import {Pausable} from "../lib/utils/Pausable.sol";

import {AuctionStorageV1} from "./storage/AuctionStorageV1.sol";
import {IAuction} from "./IAuction.sol";
import {IERC20} from "../lib/interfaces/IERC20.sol";
import {IWETH} from "../lib/interfaces/IWETH.sol";
import {IToken} from "../token/IToken.sol";
import {IManager} from "../manager/IManager.sol";

/// @title Auction House
/// @author Rohan Kulkarni
/// @notice Modified version of NounsAuctionHouse.sol (commit 2cbe6c7) that Nouns licensed under the GPL-3.0 license
contract Auction is UUPS, Ownable, ReentrancyGuard, Pausable, AuctionStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The address of the Nouns DAO Treasury
    address public immutable nounsDAO;

    /// @notice The address of the Builder DAO Treasury
    address public immutable builderDAO;

    /// @notice The address of the Zora DAO Treasury
    address public immutable zoraDAO;

    /// @notice The address of WETH
    address private immutable WETH;

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    /// @param _weth The address of WETH
    /// @param _nounsDAO The address of the Nouns DAO Treasury
    /// @param _builderDAO The address of the Builder DAO Treasury
    /// @param _zoraDAO The address of the Zora DAO Treausury
    constructor(
        address _manager,
        address _weth,
        address _nounsDAO,
        address _builderDAO,
        address _zoraDAO
    ) payable initializer {
        manager = IManager(_manager);
        WETH = _weth;

        nounsDAO = _nounsDAO;
        builderDAO = _builderDAO;
        zoraDAO = _zoraDAO;
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Called by the deployer to initialize an instance of a DAO's auction house
    /// @param _token The DAO ERC-721 token
    /// @param _foundersDAO The DAO founders
    /// @param _timelock The DAO treasury
    /// @param _duration The duration to set for each auction
    /// @param _reservePrice The reserve price to set for each auction
    function initialize(
        address _token,
        address _foundersDAO,
        address _timelock,
        uint256 _duration,
        uint256 _reservePrice
    ) external initializer {
        // Initialize the reentrancy guard
        __ReentrancyGuard_init();

        // Initialize ownership of the contract to the founders
        __Ownable_init(_foundersDAO);

        // Pause the contract until the founders are ready to start the first auction
        __Pausable_init(true);

        // Store the address of the associated token
        token = IToken(_token);

        // Store the auction house settings
        settings.treasury = _timelock;
        settings.duration = uint40(_duration);
        settings.reservePrice = _reservePrice;
        settings.timeBuffer = 5 minutes;
        settings.minBidIncrementPercentage = 10;
    }

    ///                                                          ///
    ///                          CREATE BID                      ///
    ///                                                          ///

    /// @notice Emitted when a bid is placed
    /// @param tokenId The ERC-721 token id
    /// @param bidder The address of the bidder
    /// @param amount The amount of ETH
    /// @param extended If the bid extended the auction
    /// @param endTime The end time of the auction
    event AuctionBid(uint256 tokenId, address bidder, uint256 amount, bool extended, uint256 endTime);

    error INVALID_TOKEN_ID();

    error AUCTION_OVER();

    error RESERVE_PRICE_NOT_MET();

    error MINIMUM_BID_NOT_MET();

    /// @notice Creates a bid for the current token
    /// @param _tokenId The ERC-721 token id
    function createBid(uint256 _tokenId) external payable nonReentrant {
        // Get the auction in memory
        Auction memory _auction = auction;

        // Ensure the bid is for the current token id
        if (_auction.tokenId != _tokenId) revert INVALID_TOKEN_ID();

        // Ensure the auction is active
        if (block.timestamp >= _auction.endTime) revert AUCTION_OVER();

        // Cache the highest bidder
        address lastBidder = _auction.highestBidder;

        // If this is the first bid:
        if (lastBidder == address(0)) {
            // Ensure the bid meets the reserve price
            if (msg.value < settings.reservePrice) revert RESERVE_PRICE_NOT_MET();

            // Else for a subsequent bid:
        } else {
            // Cache the previous bid
            uint256 prevBid = _auction.highestBid;

            // Used to store the next bid minimum
            uint256 nextBidMin;

            // Calculate the amount of ETH required to place the next bid
            unchecked {
                nextBidMin = prevBid + ((prevBid * settings.minBidIncrementPercentage) / 100);
            }

            // Ensure the bid meets the minimum
            if (msg.value < nextBidMin) revert MINIMUM_BID_NOT_MET();

            // Refund the previous bidder
            _handleOutgoingTransfer(lastBidder, prevBid);
        }

        // Store the attached ETH as the highest bid
        auction.highestBid = msg.value;

        // Store the caller as the highest bidder
        auction.highestBidder = msg.sender;

        // Used to store if the auction will be extended
        bool extend;

        // Cannot underflow as `block.timestamp` is ensured to be less than `_auction.endTime`
        unchecked {
            // Get if the bid was placed within the time buffer of the auction end
            extend = (_auction.endTime - block.timestamp) < settings.timeBuffer;
        }

        // If the auction will be extended:
        if (extend) {
            // Cannot overflow on human timescales
            unchecked {
                // Add to the current time so that the time buffer remains
                auction.endTime = _auction.endTime = uint40(block.timestamp + settings.timeBuffer);
            }
        }

        emit AuctionBid(_tokenId, msg.sender, msg.value, extend, _auction.endTime);
    }

    ///                                                          ///
    ///                     SETTLE & CREATE AUCTION              ///
    ///                                                          ///

    /// @notice Emitted when an auction is settled
    /// @param tokenId The ERC-721 token id of the settled auction
    /// @param winner The address of the winning bidder
    /// @param amount The amount of ETH raised from the winning bid
    event AuctionSettled(uint256 tokenId, address winner, uint256 amount);

    /// @notice Emitted when an auction is created
    /// @param tokenId The ERC-721 token id of the created auction
    /// @param startTime The start time of the created auction
    /// @param endTime The end time of the created auction
    event AuctionCreated(uint256 tokenId, uint256 startTime, uint256 endTime);

    error AUCTION_NOT_STARTED();

    error AUCTION_NOT_OVER();

    error AUCTION_SETTLED();

    /// @notice Settles the current auction and creates the next one
    function settleCurrentAndCreateNewAuction() external nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /// @dev Settles the current auction
    function _settleAuction() internal {
        // Get the current auction in memory
        Auction memory _auction = auction;

        // Ensure the auction started
        if (_auction.startTime == 0) revert AUCTION_NOT_STARTED();

        // Ensure the auction ended
        if (block.timestamp < _auction.endTime) revert AUCTION_NOT_OVER();

        // Ensure the auction was not already settled
        if (auction.settled) revert AUCTION_SETTLED();

        // Mark the auction as settled
        auction.settled = true;

        // If a bid was placed:
        if (_auction.highestBidder != address(0)) {
            // Cache the highest bid amount
            uint256 highestBid = _auction.highestBid;

            // If the highest bid included ETH:
            if (highestBid > 0) {
                // Calculate the profit after fees
                uint256 remainingProfit = _handleFees(highestBid);

                // Transfer the profit to the DAO treasury
                _handleOutgoingTransfer(settings.treasury, remainingProfit);
            }

            // Transfer the token to the highest bidder
            token.transferFrom(address(this), _auction.highestBidder, _auction.tokenId);

            // Else no bid was placed:
        } else {
            // Burn the token
            token.burn(_auction.tokenId);
        }

        emit AuctionSettled(_auction.tokenId, _auction.highestBidder, _auction.highestBid);
    }

    /// @notice Creates an auction for the next token
    function _createAuction() internal {
        // Get the next token available for bidding
        try token.mint() returns (uint256 tokenId) {
            // Store the token id returned
            auction.tokenId = tokenId;

            // Used to calculate the auction end time
            uint256 startTime = block.timestamp;
            uint256 endTime;

            // Cannot realistically overflow
            unchecked {
                // Compute the auction end time
                endTime = startTime + settings.duration;
            }

            // Store the start and end time of the next auction
            auction.startTime = uint40(startTime);
            auction.endTime = uint40(endTime);

            // Reset lingering data from the previous auction
            auction.highestBid = 0;
            auction.highestBidder = address(0);
            auction.settled = false;

            emit AuctionCreated(tokenId, startTime, endTime);

            // Pause the contract if minting failed to investigate
        } catch Error(string memory) {
            _pause();
        }
    }

    ///                                                          ///
    ///                       PAUSE AUCTION HOUSE                ///
    ///                                                          ///

    /// @notice Pauses the auction house
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the auction house
    function unpause() external onlyOwner {
        _unpause();

        // If this is the first auction:
        if (auction.tokenId == 0) {
            // Transfer ownership from the founder to the treasury
            transferOwnership(settings.treasury);

            // Start the first auction
            _createAuction();
        }
        // Else if the contract was paused and the previous auction was settled:
        else if (auction.settled) {
            // Start the next auction
            _createAuction();
        }
    }

    /// @notice Settles the last auction when the contract is paused
    function settleAuction() external nonReentrant whenPaused {
        _settleAuction();
    }

    ///                                                          ///
    ///                       UPDATE SETTINGS                    ///
    ///                                                          ///

    /// @notice Emitted when the auction duration is updated
    /// @param duration The new auction duration
    event DurationUpdated(uint256 duration);

    /// @notice Updates the auction duration
    /// @param _duration The duration to set
    function setDuration(uint256 _duration) external onlyOwner {
        settings.duration = uint40(_duration);

        emit DurationUpdated(_duration);
    }

    /// @notice Emitted when the reserve price is updated
    /// @param reservePrice The new reserve price
    event ReservePriceUpdated(uint256 reservePrice);

    /// @notice Updates the reserve price
    /// @param _reservePrice The new reserve price to set
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        settings.reservePrice = _reservePrice;

        emit ReservePriceUpdated(_reservePrice);
    }

    /// @notice Emitted when the min bid increment percentage is updated
    /// @param minBidIncrementPercentage The new min bid increment percentage
    event MinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    /// @notice Updates the minimum bid increment percentage
    /// @param _minBidIncrementPercentage The new min bid increment percentage to set
    function setMinBidIncrementPercentage(uint256 _minBidIncrementPercentage) external onlyOwner {
        settings.minBidIncrementPercentage = uint16(_minBidIncrementPercentage);

        emit MinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /// @notice Emitted when the time buffer is updated
    /// @param timeBuffer The new time buffer
    event TimeBufferUpdated(uint256 timeBuffer);

    /// @notice Updates the time buffer
    /// @param _timeBuffer The new time buffer to set
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
        settings.timeBuffer = uint40(_timeBuffer);

        emit TimeBufferUpdated(_timeBuffer);
    }

    ///                                                          ///
    ///                        TRANSFER UTILS                    ///
    ///                                                          ///

    error INSOLVENT();

    /// @notice Transfer ETH/WETH outbound from this contract
    /// @param _dest The address of the destination
    /// @param _amount The amount of ETH to transfer
    function _handleOutgoingTransfer(address _dest, uint256 _amount) internal {
        // Ensure the contract has enough ETH
        if (address(this).balance < _amount) revert INSOLVENT();

        // Transfer the given amount of ETH to the given destination
        (bool success, ) = _dest.call{value: _amount, gas: 50_000}("");

        // If the transfer fails:
        if (!success) {
            // Wrap the ETH as WETH
            IWETH(WETH).deposit{value: _amount}();

            // Transfer as WETH instead
            IERC20(WETH).transfer(_dest, _amount);
        }
    }

    /// @dev Handles payouts to Nouns DAO, Builder DAO, and Zora DAO
    /// @param _bid The amount of ETH raised from the winning bid
    function _handleFees(uint256 _bid) private returns (uint256 remainingProfit) {
        // Compute 2% of the winning bid
        uint256 totalFee = _computeFee(_bid, 200);

        unchecked {
            // Get the remaining profit
            remainingProfit = _bid - totalFee;
        }

        // Compute the Builder DAO fee from the total fee
        uint256 builderDAOFee = _computeFee(totalFee, 3400);

        // Compute the Nouns DAO fee from the total fee
        uint256 nounsDAOFee = _computeFee(totalFee, 3300);

        // Compute the Zora DAO fee from the total fee
        uint256 zoraDAOFee = _computeFee(totalFee, 3300);

        // Transfer the Nouns DAO fee
        _handleOutgoingTransfer(nounsDAO, nounsDAOFee);

        // Transfer the Builder DAO fee
        _handleOutgoingTransfer(builderDAO, builderDAOFee);

        // Transfer the Zora DAO fee
        _handleOutgoingTransfer(zoraDAO, zoraDAOFee);
    }

    /// @dev Computes the payout from a winning bid
    /// @param _amount The amount of ETH
    /// @param _bps The basis points fee
    function _computeFee(uint256 _amount, uint256 _bps) private pure returns (uint256 fee) {
        assembly {
            fee := div(mul(_amount, _bps), 10000)
        }
    }

    ///                                                          ///
    ///                       CONTRACT UPGRADE                   ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The address of the new implementation
    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        // Ensure the new implementation is a registered upgrade
        if (!manager.isValidUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Minimal UUPS proxy modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPS {
    /// @dev keccak256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address private immutable __self = address(this);

    event Upgraded(address impl);

    error INVALID_UPGRADE(address impl);

    error ONLY_DELEGATECALL();

    error NO_DELEGATECALL();

    error ONLY_PROXY();

    error INVALID_UUID();

    error NOT_UUPS();

    error INVALID_TARGET();

    function _authorizeUpgrade(address _impl) internal virtual;

    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __self) revert NO_DELEGATECALL();
        _;
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address _impl) external onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, "", false);
    }

    function upgradeToAndCall(address _impl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, _data, true);
    }

    function _upgradeToAndCallUUPS(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_impl);
        } else {
            try IERC1822Proxiable(_impl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert INVALID_UUID();
            } catch {
                revert NOT_UUPS();
            }

            _upgradeToAndCall(_impl, _data, _forceCall);
        }
    }

    function _upgradeToAndCall(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_impl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_impl, _data);
        }
    }

    function _upgradeTo(address _impl) internal {
        _setImplementation(_impl);

        emit Upgraded(_impl);
    }

    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_TARGET();

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract OwnableStorageV1 {
    address public owner;
    address public pendingOwner;
}

/// @notice Modern, efficient, and (optionally) safe Ownable
abstract contract Ownable is Initializable, OwnableStorageV1 {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    event OwnerPending(address indexed owner, address indexed pendingOwner);

    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    error ONLY_OWNER();

    error ONLY_PENDING_OWNER();

    error WRONG_PENDING_OWNER();

    modifier onlyOwner() {
        if (msg.sender != owner) revert ONLY_OWNER();
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    function __Ownable_init(address _owner) internal onlyInitializing {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(owner, _newOwner);

        owner = _newOwner;
    }

    function safeTransferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;

        emit OwnerPending(owner, _newOwner);
    }

    function cancelOwnershipTransfer(address _pendingOwner) public onlyOwner {
        if (_pendingOwner != pendingOwner) revert WRONG_PENDING_OWNER();

        emit OwnerCanceled(owner, _pendingOwner);

        delete pendingOwner;
    }

    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(owner, msg.sender);

        owner = pendingOwner;

        delete pendingOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract ReentrancyGuardStorageV1 {
    uint256 internal _status;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
abstract contract ReentrancyGuard is Initializable, ReentrancyGuardStorageV1 {
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    error REENTRANCY();

    function __ReentrancyGuard_init() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert REENTRANCY();

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract PausableStorageV1 {
    bool public paused;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
abstract contract Pausable is Initializable, PausableStorageV1 {
    event Paused(address user);

    event Unpaused(address user);

    error PAUSED();

    error UNPAUSED();

    function __Pausable_init(bool _paused) internal onlyInitializing {
        paused = _paused;
    }

    modifier whenPaused() {
        if (!paused) revert UNPAUSED();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert PAUSED();
        _;
    }

    function _pause() internal virtual whenNotPaused {
        paused = true;

        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        paused = false;

        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IToken} from "../../token/IToken.sol";
import {AuctionTypesV1} from "../types/AuctionTypesV1.sol";

contract AuctionStorageV1 is AuctionTypesV1 {
    /// @notice The ERC-721 token contract
    IToken public token;

    /// @notice The DAO auction house settings
    Settings public settings;

    /// @notice The latest auction metadata
    Auction public auction;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IToken} from "../token/IToken.sol";

interface IAuction {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    struct House {
        address treasury;
        uint40 duration;
        uint40 timeBuffer;
        uint16 minBidIncrementPercentage;
        uint256 reservePrice;
    }

    struct Auction {
        uint256 tokenId;
        uint256 highestBid;
        address highestBidder;
        uint40 startTime;
        uint40 endTime;
        bool settled;
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        address token,
        address foundersDAO,
        address treasury,
        uint256 duration,
        uint256 reservePrice
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function token() external view returns (IToken);

    function auction() external view returns (Auction calldata);

    function house() external view returns (House calldata);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function createBid(uint256 tokenId) external payable;

    function settleCurrentAndCreateNewAuction() external;

    function settleAuction() external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function paused() external view returns (bool);

    function unpause() external;

    function pause() external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint256 minBidIncrementPercentage) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function renounceOwnership() external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function upgradeTo(address implementation) external;

    function upgradeToAndCall(address implementation, bytes memory data) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC20} from "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IManager} from "../manager/IManager.sol";
import {IMetadataRenderer} from "./metadata/IMetadataRenderer.sol";

interface IToken {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata tokenInitStrings,
        address metadataRenderer,
        address auction
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function metadataRenderer() external view returns (IMetadataRenderer);

    function auction() external view returns (address);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function getVotes(address account) external view returns (uint256);

    function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    function delegates(address account) external view returns (address);

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The external interface for the Manager contract
interface IManager {
    /// @notice The ownership config for each founder
    /// @param wallet A wallet or multisig address
    /// @param allocationFrequency The frequency of tokens minted to them (eg. Every 10 tokens to Nounders)
    /// @param vestingEnd The timestamp that their vesting will end
    struct FounderParams {
        address wallet;
        uint256 allocationFrequency;
        uint256 vestingEnd;
    }

    /// @notice The DAO's ERC-721 token and metadata config
    /// @param initStrings The encoded
    struct TokenParams {
        bytes initStrings; // name, symbol, description, contract image, renderer base
    }

    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    struct GovParams {
        uint256 timelockDelay; // The time between a proposal and its execution
        uint256 votingDelay; // The number of blocks after a proposal that voting is delayed
        uint256 votingPeriod; // The number of blocks that voting for a proposal will take place
        uint256 proposalThresholdBPS; // The number of votes required for a voter to become a proposer
        uint256 quorumVotesBPS; // The number of votes required to support a proposal
    }

    error FOUNDER_REQUIRED();

    function deploy(
        FounderParams[] calldata _founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function isValidUpgrade(address _baseImpl, address _upgradeImpl) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    error INVALID_TARGET();

    error DELEGATE_CALL_FAILED();

    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)));
    }

    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol
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

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Address} from "../utils/Address.sol";

contract InitializableStorageV1 {
    uint8 internal _initialized;
    bool internal _initializing;
}

/// @notice Modern Initializable modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol
abstract contract Initializable is InitializableStorageV1 {
    event Initialized(uint256 version);

    error INVALID_INIT();

    error NOT_INITIALIZING();

    error ALREADY_INITIALIZED();

    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

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

    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

// TODO IToken where treasury is and move treasury before reserve price
contract AuctionTypesV1 {
    struct Settings {
        address treasury;
        uint40 duration;
        uint40 timeBuffer;
        uint16 minBidIncrementPercentage;
        uint256 reservePrice;
    }

    struct Auction {
        uint256 tokenId;
        uint256 highestBid;
        address highestBidder;
        uint40 startTime;
        uint40 endTime;
        bool settled;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IMetadataRenderer {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        bytes calldata initStrings,
        address token,
        address founders,
        address treasury
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    struct ItemParam {
        uint256 propertyId;
        string name;
        bool isNewProperty;
    }

    struct IPFSGroup {
        string baseUri;
        string extension;
    }

    function addProperties(
        string[] calldata names,
        ItemParam[] calldata items,
        IPFSGroup calldata ipfsGroup
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function propertiesCount() external view returns (uint256);

    function itemsCount(uint256 propertyId) external view returns (uint256);

    function getProperties(uint256 tokenId) external view returns (bytes memory aryAttributes, bytes memory queryString);
}