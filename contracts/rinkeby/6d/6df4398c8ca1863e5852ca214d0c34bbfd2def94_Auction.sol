// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable} from "../lib/utils/Ownable.sol";
import {ReentrancyGuard} from "../lib/utils/ReentrancyGuard.sol";
import {Pausable} from "../lib/utils/Pausable.sol";
import {Cast} from "../lib/utils/Cast.sol";

import {AuctionStorageV1} from "./storage/AuctionStorageV1.sol";
import {Token} from "../token/Token.sol";
import {IAuction} from "./IAuction.sol";
import {IERC20} from "../lib/interfaces/IERC20.sol";
import {IWETH} from "../lib/interfaces/IWETH.sol";

import {IManager} from "../manager/IManager.sol";

/// @title Auction
/// @author Rohan Kulkarni
/// @notice This contract is
contract Auction is IAuction, UUPS, Ownable, ReentrancyGuard, Pausable, AuctionStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The address of WETH
    address private immutable WETH;

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    /// @param _weth The address of WETH
    constructor(address _manager, address _weth) payable initializer {
        manager = IManager(_manager);
        WETH = _weth;
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes a DAO's auction house
    /// @param _token The ERC-721 token address
    /// @param _founder The founder responsible for starting the first auction
    /// @param _treasury The timelock address where ETH will be sent
    /// @param _duration The duration of each auction
    /// @param _reservePrice The reserve price of each auction
    function initialize(
        address _token,
        address _founder,
        address _treasury,
        uint256 _duration,
        uint256 _reservePrice
    ) external initializer {
        // Initialize the reentrancy guard
        __ReentrancyGuard_init();

        // Grant initial ownership to a founder to unpause the auction house when ready
        __Ownable_init(_founder);

        // Pause the contract until the first auction is ready to begin
        __Pausable_init(true);

        // Store the address of the ERC-721 token that will be bid on
        token = Token(_token);

        // Store the auction house settings
        settings.duration = Cast.toUint40(_duration);
        settings.reservePrice = _reservePrice;
        settings.treasury = _treasury;
        settings.timeBuffer = 5 minutes;
        settings.minBidIncrement = 10;
    }

    ///                                                          ///
    ///                          CREATE BID                      ///
    ///                                                          ///

    /// @notice Creates a bid for the current token
    /// @param _tokenId The ERC-721 token id
    function createBid(uint256 _tokenId) external payable nonReentrant {
        // Get the current auction in memory
        Auction memory _auction = auction;

        // Ensure the bid is for the right token id
        if (_auction.tokenId != _tokenId) revert INVALID_TOKEN_ID();

        // Ensure the auction is still active
        if (block.timestamp >= _auction.endTime) revert AUCTION_OVER();

        // Cache the address of the highest bidder
        address highestBidder = _auction.highestBidder;

        // If this is the first bid:
        if (highestBidder == address(0)) {
            // Ensure the bid meets the reserve price
            if (msg.value < settings.reservePrice) revert RESERVE_PRICE_NOT_MET();

            // Else for a subsequent bid:
        } else {
            // Cache the amount of the previous bid
            uint256 prevBid = _auction.highestBid;

            // Used to store the minimum amount required to place the current bid
            uint256 currentBidMin;

            // Compute the minimum amount
            unchecked {
                currentBidMin = prevBid + ((prevBid * settings.minBidIncrement) / 100);
            }

            // Ensure the bid meets the amount
            if (msg.value < currentBidMin) revert MINIMUM_BID_NOT_MET();

            // Refund the previous bidder
            _handleOutgoingTransfer(highestBidder, prevBid);
        }

        // Store the attached amount of ETH as the new highest bid
        auction.highestBid = msg.value;

        // Store the caller as the new highest bidder
        auction.highestBidder = msg.sender;

        // Used to store if the auction will be extended
        bool extend;

        // Cannot underflow as the end time is ensured to be greater than the current time
        unchecked {
            // Compute whether the bid was placed within the time buffer of the auction end
            extend = (_auction.endTime - block.timestamp) < settings.timeBuffer;
        }

        // If the auction is valid to extend:
        if (extend) {
            // Cannot realistically overflow
            unchecked {
                // Add the time buffer to the auction's previous end time
                auction.endTime = _auction.endTime = uint40(block.timestamp + settings.timeBuffer);
            }
        }

        emit AuctionBid(_tokenId, msg.sender, msg.value, extend, _auction.endTime);
    }

    ///                                                          ///
    ///                     SETTLE & CREATE AUCTION              ///
    ///                                                          ///

    /// @notice Settles the current auction and creates the next one
    function settleCurrentAndCreateNewAuction() external nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /// @dev Settles the current auction
    function _settleAuction() private {
        // Get the current auction in memory
        Auction memory _auction = auction;

        // Ensure the auction began
        if (_auction.startTime == 0) revert AUCTION_NOT_STARTED();

        // Ensure the auction ended
        if (block.timestamp < _auction.endTime) revert AUCTION_NOT_OVER();

        // Ensure the auction was not already settled
        if (auction.settled) revert AUCTION_SETTLED();

        // Mark the auction as settled
        auction.settled = true;

        // If a bid was placed:
        if (_auction.highestBidder != address(0)) {
            // Cache the amount of the highest bid
            uint256 highestBid = _auction.highestBid;

            // If the highest bid included ETH:
            if (highestBid > 0) {
                _handleOutgoingTransfer(settings.treasury, highestBid);
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

    /// @dev Creates an auction for the next token
    function _createAuction() private {
        // Get the next token available for bidding
        try token.mint() returns (uint256 tokenId) {
            // Store the token id
            auction.tokenId = tokenId;

            // Cache the current block time
            uint256 startTime = block.timestamp;

            // Used to store the auction end time
            uint256 endTime;

            // Cannot realistically overflow
            unchecked {
                // Compute the auction end time
                endTime = startTime + settings.duration;
            }

            // Store the auction start and end time
            auction.startTime = uint40(startTime);
            auction.endTime = uint40(endTime);

            // Reset previous auction data
            auction.highestBid = 0;
            auction.highestBidder = address(0);
            auction.settled = false;

            emit AuctionCreated(tokenId, startTime, endTime);

            // Pause the contract if token minting failed
        } catch Error(string memory) {
            _pause();
        }
    }

    ///                                                          ///
    ///                             PAUSE                        ///
    ///                                                          ///

    /// @notice Unpauses the auction house
    function unpause() external onlyOwner {
        _unpause();

        // If this is the first auction:
        if (auction.tokenId == 0) {
            // Transfer ownership of the contract to the DAO
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

    /// @notice Pauses the auction house
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Settles the last auction when the contract is paused
    function settleAuction() external nonReentrant whenPaused {
        _settleAuction();
    }

    ///                                                          ///
    ///                       UPDATE SETTINGS                    ///
    ///                                                          ///

    /// @notice Updates the time duration of each auction
    /// @param _duration The duration to set
    function setDuration(uint256 _duration) external onlyOwner {
        settings.duration = Cast.toUint40(_duration);

        emit DurationUpdated(_duration);
    }

    /// @notice Updates the reserve price of each auction
    /// @param _reservePrice The reserve price to set
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        settings.reservePrice = _reservePrice;

        emit ReservePriceUpdated(_reservePrice);
    }

    /// @notice Updates the minimum percentage increment required of each bid
    /// @param _percentage The percentage to set
    function setMinimumBidIncrement(uint256 _percentage) external onlyOwner {
        settings.minBidIncrement = Cast.toUint8(_percentage);

        emit MinBidIncrementPercentageUpdated(_percentage);
    }

    /// @notice Updates the time buffer of each auction
    /// @param _timeBuffer The time buffer to set
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
        settings.timeBuffer = Cast.toUint40(_timeBuffer);

        emit TimeBufferUpdated(_timeBuffer);
    }

    ///                                                          ///
    ///                        TRANSFER UTILS                    ///
    ///                                                          ///

    /// @notice Transfer ETH/WETH from the contract
    /// @param _to The recipient address
    /// @param _amount The amount transferring
    function _handleOutgoingTransfer(address _to, uint256 _amount) private {
        // Ensure the contract has enough balance
        if (address(this).balance < _amount) revert INSOLVENT();

        // Used to store if the transfer succeeded
        bool success;

        assembly {
            // Transfer ETH to the recipient
            // Limit the call to 50,000 gas
            success := call(50000, _to, _amount, 0, 0, 0, 0)
        }

        // If the transfer failed:
        if (!success) {
            // Wrap as WETH
            IWETH(WETH).deposit{value: _amount}();

            // Transfer WETH instead
            IERC20(WETH).transfer(_to, _amount);
        }
    }

    ///                                                          ///
    ///                       CONTRACT UPGRADE                   ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The address of the new implementation
    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        // Ensure the new implementation is registered by the Builder DAO
        if (!manager.isValidUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPS is IERC1822Proxiable {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev keccak256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    address private immutable __self = address(this);

    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event Upgraded(address indexed impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_UPGRADE(address impl);

    error ONLY_DELEGATECALL();

    error NO_DELEGATECALL();

    error ONLY_PROXY();

    error INVALID_UUID();

    error NOT_UUPS();

    error INVALID_TARGET();

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __self) revert NO_DELEGATECALL();
        _;
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function _authorizeUpgrade(address _impl) internal virtual;

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

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract OwnableStorageV1 {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is Initializable, OwnableStorageV1 {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    event OwnerPending(address indexed owner, address indexed pendingOwner);

    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    error ONLY_OWNER();

    error ONLY_PENDING_OWNER();

    error INCORRECT_PENDING_OWNER();

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
        if (_pendingOwner != pendingOwner) revert INCORRECT_PENDING_OWNER();

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
pragma solidity ^0.8.15;

library Cast {
    error UNSAFE_CAST();

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x > (1 << 48)) revert UNSAFE_CAST();

        return uint48(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x > (1 << 40)) revert UNSAFE_CAST();

        return uint40(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x > (1 << 16)) revert UNSAFE_CAST();

        return uint16(x);
    }

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x > (1 << 8)) revert UNSAFE_CAST();

        return uint8(x);
    }

    function toBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function toString(bytes32 _value) internal pure returns (string memory) {
        return string(abi.encodePacked(_value));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Token} from "../../token/Token.sol";
import {AuctionTypesV1} from "../types/AuctionTypesV1.sol";

/// @title AuctionStorageV1
/// @author Rohan Kulkarni
/// @notice The
contract AuctionStorageV1 is AuctionTypesV1 {
    /// @notice The ERC-721 token contract
    Token public token;

    /// @notice The DAO auction house settings
    Settings public settings;

    /// @notice The current auction state
    Auction public auction;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable} from "../lib/utils/Ownable.sol";
import {ReentrancyGuard} from "../lib/utils/ReentrancyGuard.sol";
import {ERC721Votes} from "../lib/token/ERC721Votes.sol";

import {TokenStorageV1} from "./storage/TokenStorageV1.sol";
import {MetadataRenderer} from "./metadata/MetadataRenderer.sol";
import {IManager} from "../manager/IManager.sol";
import {IToken} from "./IToken.sol";

/// @title Token
/// @author Rohan Kulkarni
/// @notice A DAO's ERC-721 token contract
contract Token is IToken, UUPS, ReentrancyGuard, ERC721Votes, TokenStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes an instance of a DAO's ERC-721 token
    /// @param _founders The members of the DAO with scheduled token allocations
    /// @param _initStrings The encoded token and metadata initialization strings
    /// @param _metadataRenderer The token's metadata renderer
    /// @param _auction The token's auction house
    function initialize(
        IManager.FounderParams[] calldata _founders,
        bytes calldata _initStrings,
        address _metadataRenderer,
        address _auction
    ) external initializer {
        // Initialize the reentrancy guard
        __ReentrancyGuard_init();

        // Store the vesting schedules of each founder
        _storeFounders(_founders);

        // Get the token name and symbol from the encoded strings
        (string memory _name, string memory _symbol, , , ) = abi.decode(_initStrings, (string, string, string, string, string));

        // Initialize the ERC-721 token
        __ERC721_init(_name, _symbol);

        // Store the associated auction house
        auction = _auction;

        // Store the associated metadata renderer
        metadataRenderer = MetadataRenderer(_metadataRenderer);
    }

    ///                                                          ///
    ///                              MINT                        ///
    ///                                                          ///

    /// @notice Mints tokens to the auction house for bidding and handles vesting to the founders & Builder DAO
    function mint() public nonReentrant returns (uint256 tokenId) {
        // Ensure the caller is the auction house
        if (msg.sender != auction) revert ONLY_AUCTION();

        // Cannot realistically overflow
        unchecked {
            do {
                // Get the next available token id
                tokenId = totalSupply++;

                // While the current token id is elig
            } while (_isVest(tokenId));
        }

        // Mint the next token to the auction house for bidding
        _mint(auction, tokenId);

        return tokenId;
    }

    /// @dev Overrides _mint to include attribute generation
    /// @param _to The token recipient
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal override {
        // Mint the token
        super._mint(_to, _tokenId);

        // Generate the token attributes
        metadataRenderer.generate(_tokenId);
    }

    ///                                                          ///
    ///                           VESTING                        ///
    ///                                                          ///

    /// @dev Checks if a token is elgible to vest, and mints to the recipient if so
    /// @param _tokenId The ERC-721 token id
    function _isVest(uint256 _tokenId) private returns (bool) {
        // Cache the number of founders
        uint256 numFounders = founders.length;

        // Cannot realistically overflow
        unchecked {
            // For each founder:
            for (uint256 i; i < numFounders; ++i) {
                // Get their vesting details
                Founder memory founder = founders[i];

                // If the token id fits their vesting schedule:
                if (_tokenId % founder.allocationFrequency == 0 && block.timestamp < founder.vestingEnd) {
                    // Mint the token to the founder
                    _mint(founder.wallet, _tokenId);

                    return true;
                }
            }

            return false;
        }
    }

    /// @dev Stores the vesting details of the DAO's founders
    /// @param _founders The list of founders provided upon deploy
    function _storeFounders(IManager.FounderParams[] calldata _founders) internal {
        // Cache the number of founders
        uint256 numFounders = _founders.length;

        // Cannot realistically overflow
        unchecked {
            // For each founder:
            for (uint256 i; i < numFounders; ++i) {
                // Allocate storage space
                founders.push();

                // Get the storage location
                Founder storage founder = founders[i];

                // Store the given details
                founder.allocationFrequency = uint32(_founders[i].allocationFrequency);
                founder.vestingEnd = uint64(_founders[i].vestingEnd);
                founder.wallet = _founders[i].wallet;
            }
        }
    }

    ///                                                          ///
    ///                             BURN                         ///
    ///                                                          ///

    /// @notice Burns a token that did not see any bids
    /// @param _tokenId The ERC-721 token id
    function burn(uint256 _tokenId) public {
        // Ensure the caller is the auction house
        if (msg.sender != auction) revert ONLY_AUCTION();

        // Burn the token
        _burn(_tokenId);
    }

    ///                                                          ///
    ///                              URI                         ///
    ///                                                          ///

    /// @notice The URI for a given token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return metadataRenderer.tokenURI(_tokenId);
    }

    /// @notice The URI for the contract
    function contractURI() public view override returns (string memory) {
        return metadataRenderer.contractURI();
    }

    ///                                                          ///
    ///                             OWNER                        ///
    ///                                                          ///

    /// @notice The shared owner of the token and metadata contracts
    function owner() public view returns (address) {
        return metadataRenderer.owner();
    }

    ///                                                          ///
    ///                        CONTRACT UPGRADE                  ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The address of the new implementation
    function _authorizeUpgrade(address _newImpl) internal view override {
        // Ensure the caller is the shared owner of the token and metadata renderer
        if (msg.sender != owner()) revert ONLY_OWNER();

        // Ensure the implementation is valid
        if (!manager.isValidUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IToken} from "../token/IToken.sol";

interface IAuction {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a bid is placed
    /// @param tokenId The ERC-721 token id
    /// @param bidder The address of the bidder
    /// @param amount The amount of ETH
    /// @param extended If the bid extended the auction
    /// @param endTime The end time of the auction
    event AuctionBid(uint256 tokenId, address bidder, uint256 amount, bool extended, uint256 endTime);

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

    /// @notice Emitted when the auction duration is updated
    /// @param duration The new auction duration
    event DurationUpdated(uint256 duration);

    /// @notice Emitted when the reserve price is updated
    /// @param reservePrice The new reserve price
    event ReservePriceUpdated(uint256 reservePrice);

    /// @notice Emitted when the min bid increment percentage is updated
    /// @param minBidIncrementPercentage The new min bid increment percentage
    event MinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    /// @notice Emitted when the time buffer is updated
    /// @param timeBuffer The new time buffer
    event TimeBufferUpdated(uint256 timeBuffer);

    ///                                                          ///
    ///                           ERRORS                         ///
    ///                                                          ///

    error INVALID_TOKEN_ID();

    error AUCTION_OVER();

    error RESERVE_PRICE_NOT_MET();

    error MINIMUM_BID_NOT_MET();

    error AUCTION_NOT_STARTED();

    error AUCTION_NOT_OVER();

    error AUCTION_SETTLED();

    error INSOLVENT();

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function initialize(
        address token,
        address founder,
        address treasury,
        uint256 duration,
        uint256 reservePrice
    ) external;

    function createBid(uint256 tokenId) external payable;

    function settleCurrentAndCreateNewAuction() external;

    function settleAuction() external;

    function setDuration(uint256 duration) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinimumBidIncrement(uint256 percentage) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function pause() external;

    function unpause() external;
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

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The Manager external interface
interface IManager {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice Emitted when a DAO is deployed
    /// @param token The address of the token
    /// @param metadata The address of the metadata renderer
    /// @param auction The address of the auction
    /// @param timelock The address of the timelock
    /// @param governor The address of the governor
    event DAODeployed(address token, address metadata, address auction, address timelock, address governor);

    /// @notice Emitted when an upgrade is registered
    /// @param baseImpl The address of the previous implementation
    /// @param upgradeImpl The address of the registered upgrade
    event UpgradeRegistered(address baseImpl, address upgradeImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param baseImpl The address of the base contract
    /// @param upgradeImpl The address of the upgrade
    event UpgradeUnregistered(address baseImpl, address upgradeImpl);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error FOUNDER_REQUIRED();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

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

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

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

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol
abstract contract Initializable is InitializableStorageV1 {
    event Initialized(uint256 version);

    error ADDRESS_ZERO();

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
        uint8 minBidIncrement;
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
pragma solidity ^0.8.15;

import {EIP712} from "../utils/EIP712.sol";
import {ERC721} from "../token/ERC721.sol";

contract ERC721VotesTypesV1 {
    struct Checkpoint {
        uint64 timestamp;
        uint192 votes;
    }
}

contract ERC721VotesStorageV1 is ERC721VotesTypesV1 {
    mapping(address => uint256) public numCheckpoints;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => address) internal delegation;
}

abstract contract ERC721Votes is EIP712, ERC721, ERC721VotesStorageV1 {
    ///                                                          ///
    ///                           CONSTANTS                      ///
    ///                                                          ///

    bytes32 internal constant DELEGATION_TYPEHASH = keccak256("Delegation(address from,address to,uint256 nonce,uint256 deadline)");

    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event DelegateChanged(address indexed delegator, address indexed from, address indexed to);

    event DelegateVotesChanged(address indexed delegate, uint256 prevVotes, uint256 newVotes);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_TIMESTAMP();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    function delegates(address _user) external view returns (address) {
        address current = delegation[_user];

        return current == address(0) ? _user : current;
    }

    function delegate(address _to) external {
        _delegate(msg.sender, _to);
    }

    function delegateBySig(
        address _from,
        address _to,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline) revert EXPIRED_SIGNATURE();

        bytes32 digest;

        unchecked {
            digest = keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(DELEGATION_TYPEHASH, _from, _to, nonces[_from]++, _deadline)))
            );
        }

        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        if (recoveredAddress == address(0) || recoveredAddress != _from) revert INVALID_SIGNER();

        _delegate(_from, _to);
    }

    function _delegate(address _from, address _to) internal {
        address prevDelegate = delegation[_from];

        delegation[_from] = _to;

        emit DelegateChanged(_from, prevDelegate, _to);

        _moveDelegateVotes(prevDelegate, _to, balanceOf(_from));
    }

    function _moveDelegateVotes(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        unchecked {
            if (_from != _to && _amount > 0) {
                if (_from != address(0)) {
                    uint256 nCheckpoints = numCheckpoints[_from]++;

                    uint256 prevTotalVotes;

                    if (nCheckpoints != 0) prevTotalVotes = checkpoints[_from][nCheckpoints - 1].votes;

                    _writeCheckpoint(_from, nCheckpoints, prevTotalVotes, prevTotalVotes - _amount);
                }

                if (_to != address(0)) {
                    uint256 nCheckpoints = numCheckpoints[_to]++;

                    uint256 prevTotalVotes;

                    if (nCheckpoints != 0) prevTotalVotes = checkpoints[_to][nCheckpoints - 1].votes;

                    _writeCheckpoint(_to, nCheckpoints, prevTotalVotes, prevTotalVotes + _amount);
                }
            }
        }
    }

    function _writeCheckpoint(
        address _user,
        uint256 _index,
        uint256 _prevTotalVotes,
        uint256 _newTotalVotes
    ) private {
        Checkpoint storage checkpoint = checkpoints[_user][_index];

        checkpoint.votes = uint192(_newTotalVotes);
        checkpoint.timestamp = uint64(block.timestamp);

        emit DelegateVotesChanged(_user, _prevTotalVotes, _newTotalVotes);
    }

    function getVotes(address _user) public view virtual returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[_user];

        unchecked {
            return nCheckpoints != 0 ? checkpoints[_user][nCheckpoints - 1].votes : 0;
        }
    }

    function getPastVotes(address _user, uint256 _timestamp) public view returns (uint256) {
        if (_timestamp >= block.timestamp) revert INVALID_TIMESTAMP();

        uint256 nCheckpoints = numCheckpoints[_user];

        if (nCheckpoints == 0) return 0;

        mapping(uint256 => Checkpoint) storage userCheckpoints = checkpoints[_user];

        unchecked {
            uint256 lastCheckpoint = nCheckpoints - 1;

            if (userCheckpoints[lastCheckpoint].timestamp <= _timestamp) return userCheckpoints[lastCheckpoint].votes;

            if (userCheckpoints[0].timestamp > _timestamp) return 0;

            uint256 high = lastCheckpoint;

            uint256 low;

            uint256 avg;

            Checkpoint memory cp;

            while (high > low) {
                avg = (low & high) + (low ^ high) / 2;

                cp = userCheckpoints[avg];

                if (cp.timestamp == _timestamp) {
                    return cp.votes;
                } else if (cp.timestamp < _timestamp) {
                    low = avg;
                } else {
                    high = avg - 1;
                }
            }

            return userCheckpoints[low].votes;
        }
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        _moveDelegateVotes(_from, _to, 1);

        super._afterTokenTransfer(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRenderer} from "../metadata/MetadataRenderer.sol";
import {TokenTypesV1} from "../types/TokenTypesV1.sol";

contract TokenStorageV1 is TokenTypesV1 {
    /// @notice The total number of tokens minted
    uint256 public totalSupply;

    /// @notice The minter of the token
    address public auction;

    /// @notice The metadata renderer of the token
    MetadataRenderer public metadataRenderer;

    /// @notice The founders of the DAO
    Founder[] public founders;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {LibUintToString} from "sol2string/contracts/LibUintToString.sol";
import {UriEncode} from "sol-uriencode/src/UriEncode.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

import {UUPS} from "../../lib/proxy/UUPS.sol";
import {Ownable} from "../../lib/utils/Ownable.sol";
import {Strings} from "../../lib/utils/Strings.sol";

import {MetadataRendererStorageV1} from "./storage/MetadataRendererStorageV1.sol";
import {IMetadataRenderer} from "./IMetadataRenderer.sol";
import {IManager} from "../../manager/IManager.sol";

/// @title Metadata Renderer
/// @author Iain Nash & Rohan Kulkarni
/// @notice This contract stores, renders, and generates the attributes for an associated token contract
contract MetadataRenderer is IMetadataRenderer, UUPS, Ownable, MetadataRendererStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes an instance of a DAO's metadata renderer
    /// @param _initStrings The encoded token and metadata init strings
    /// @param _token The address of the ERC-721 token
    /// @param _founder The address of the founder responsible for adding
    function initialize(
        bytes calldata _initStrings,
        address _token,
        address _founder,
        address _treasury
    ) external initializer {
        // Decode the token initialization strings
        (string memory _name, , string memory _description, string memory _contractImage, string memory _rendererBase) = abi.decode(
            _initStrings,
            (string, string, string, string, string)
        );

        // Store the renderer settings
        settings.name = _name;
        settings.description = _description;
        settings.contractImage = _contractImage;
        settings.rendererBase = _rendererBase;
        settings.token = _token;
        settings.treasury = _treasury;

        // Initialize ownership to the founder
        __Ownable_init(_founder);
    }

    ///                                                          ///
    ///                     PROPERTIES & ITEMS                   ///
    ///                                                          ///

    /// @notice The number of properties
    function propertiesCount() external view returns (uint256) {
        return properties.length;
    }

    /// @notice The number of items in a property
    /// @param _propertyId The property id
    function itemsCount(uint256 _propertyId) external view returns (uint256) {
        return properties[_propertyId].items.length;
    }

    /// @notice Adds properties and/or items to be pseudo-randomly chosen from for token generation to choose from attribute generations
    /// @param _names The names of the properties to add
    /// @param _items The items to add to each property
    /// @param _ipfsGroup The IPFS base URI and extension
    function addProperties(
        string[] calldata _names,
        ItemParam[] calldata _items,
        IPFSGroup calldata _ipfsGroup
    ) external onlyOwner {
        // Cache the existing amount of IPFS data stored
        uint256 dataLength = ipfsData.length;

        // If this is the first time adding properties and/or items:
        if (dataLength == 0) {
            // Transfer ownership to the DAO treasury
            transferOwnership(settings.treasury);
        }

        // Add the IPFS group information
        ipfsData.push(_ipfsGroup);

        // Cache the number of existing properties
        uint256 numStoredProperties = properties.length;

        // Cache the number of new properties adding
        uint256 numNewProperties = _names.length;

        // Cache the number of new items adding
        uint256 numNewItems = _items.length;

        unchecked {
            // For each new property:
            for (uint256 i = 0; i < numNewProperties; ++i) {
                // Append storage space
                properties.push();

                // Compute the property id
                uint256 propertyId = numStoredProperties + i;

                // Store the property name
                properties[propertyId].name = _names[i];

                emit PropertyAdded(propertyId, _names[i]);
            }

            // For each new item:
            for (uint256 i = 0; i < numNewItems; ++i) {
                // Cache the associated property id
                uint256 _propertyId = _items[i].propertyId;

                // Offset the IDs for new properties
                if (_items[i].isNewProperty) {
                    _propertyId += numStoredProperties;
                }

                // Get the storage location of the other items for the property
                // Property IDs under the hood are offset by 1
                Item[] storage propertyItems = properties[_propertyId].items;

                // Append storage space
                propertyItems.push();

                // Get the index of the
                // Cannot underflow as the array push() ensures the length to be at least 1
                uint256 newItemIndex = propertyItems.length - 1;

                // Store the new item
                Item storage newItem = propertyItems[newItemIndex];

                // Store its associated metadata
                newItem.name = _items[i].name;
                newItem.referenceSlot = uint16(dataLength);

                emit ItemAdded(_propertyId, newItemIndex);
            }
        }
    }

    ///                                                          ///
    ///                     ATTRIBUTE GENERATION                 ///
    ///                                                          ///

    /// @notice Generates attributes for a token
    /// @dev Called by the token upon mint()
    /// @param _tokenId The ERC-721 token id
    function generate(uint256 _tokenId) external {
        // Ensure the caller is the token contract
        if (msg.sender != settings.token) revert ONLY_TOKEN();

        // Compute some randomness for the token id
        uint256 seed = _generateSeed(_tokenId);

        // Get the location to where the attributes should be stored after generation
        uint16[16] storage tokenAttributes = attributes[_tokenId];

        // Cache the number of total properties to choose from
        uint256 numProperties = properties.length;

        // Store the number of properties in the first slot of the token's array for reference
        tokenAttributes[0] = uint16(numProperties);

        // Used to store the number of items in each property
        uint256 numItems;

        unchecked {
            // For each property:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Get the number of items to choose from
                numItems = properties[i].items.length;

                // Use the token's seed to selec an item
                tokenAttributes[i + 1] = uint16(seed % numItems);

                // Adjust the randomness
                seed >>= 16;
            }
        }
    }

    /// @notice The properties and query string for a generated token
    /// @param _tokenId The ERC-721 token id
    function getAttributes(uint256 _tokenId) public view returns (bytes memory aryAttributes, bytes memory queryString) {
        // Compute its query string
        queryString = abi.encodePacked(
            "?contractAddress=",
            Strings.toHexString(uint256(uint160(address(this))), 20),
            "&tokenId=",
            Strings.toString(_tokenId)
        );

        // Get the attributes for the given token
        uint16[16] memory tokenAttributes = attributes[_tokenId];

        // Cache the number of properties stored when the token was minted
        uint256 numProperties = tokenAttributes[0];

        // Ensure the token
        if (numProperties == 0) revert TOKEN_NOT_MINTED(_tokenId);

        unchecked {
            uint256 lastProperty = numProperties - 1;

            // For each of the token's properties:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Check if this is the last iteration
                bool isLast = i == lastProperty;

                // Get the property data
                Property memory property = properties[i];

                // Get the index of its generated attribute for this property
                uint256 attribute = tokenAttributes[i + 1];

                // Get the associated item data
                Item memory item = property.items[attribute];

                aryAttributes = abi.encodePacked(aryAttributes, '"', property.name, '": "', item.name, '"', isLast ? "" : ",");
                queryString = abi.encodePacked(queryString, "&images=", _getItemImage(item, property.name));
            }
        }
    }

    /// @dev Generates a psuedo-random seed for a token id
    function _generateSeed(uint256 _tokenId) private view returns (uint256) {
        return uint256(keccak256(abi.encode(_tokenId, blockhash(block.number), block.coinbase, block.timestamp)));
    }

    /// @dev Encodes the string from an item in a property
    function _getItemImage(Item memory _item, string memory _propertyName) private view returns (string memory) {
        return
            UriEncode.uriEncode(
                string(
                    abi.encodePacked(ipfsData[_item.referenceSlot].baseUri, _propertyName, "/", _item.name, ipfsData[_item.referenceSlot].extension)
                )
            );
    }

    ///                                                          ///
    ///                            URIs                          ///
    ///                                                          ///

    /// @notice The contract URI
    function contractURI() external view returns (string memory) {
        return
            _encodeAsJson(
                abi.encodePacked(
                    '{"name": "',
                    settings.name,
                    '", "description": "',
                    settings.description,
                    '", "image": "',
                    settings.contractImage,
                    '"}'
                )
            );
    }

    /// @notice The token URI
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        (bytes memory aryAttributes, bytes memory queryString) = getAttributes(_tokenId);
        return
            _encodeAsJson(
                abi.encodePacked(
                    '{"name": "',
                    settings.name,
                    " #",
                    LibUintToString.toString(_tokenId),
                    '", "description": "',
                    settings.description,
                    '", "image": "',
                    settings.rendererBase,
                    queryString,
                    '", "properties": {',
                    aryAttributes,
                    "}}"
                )
            );
    }

    /// @notice Encodes s
    function _encodeAsJson(bytes memory _jsonBlob) private pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_jsonBlob)));
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function token() external view returns (address) {
        return settings.token;
    }

    function treasury() external view returns (address) {
        return settings.treasury;
    }

    function contractImage() external view returns (string memory) {
        return settings.contractImage;
    }

    function rendererBase() external view returns (string memory) {
        return settings.rendererBase;
    }

    function description() external view returns (string memory) {
        return settings.description;
    }

    ///                                                          ///
    ///                       UPDATE SETTINGS                    ///
    ///                                                          ///

    /// @notice Updates the contract image
    /// @param _newImage The new contract image
    function updateContractImage(string memory _newImage) external onlyOwner {
        emit ContractImageUpdated(settings.contractImage, _newImage);

        settings.contractImage = _newImage;
    }

    /// @notice Updates the renderer base
    /// @param _newRendererBase The new renderer base
    function updateRendererBase(string memory _newRendererBase) external onlyOwner {
        emit RendererBaseUpdated(settings.rendererBase, _newRendererBase);

        settings.rendererBase = _newRendererBase;
    }

    ///                                                          ///
    ///                        UPGRADE CONTRACT                  ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract to a valid implementation
    /// @dev This function is called in UUPS `upgradeTo` & `upgradeToAndCall`
    /// @param _impl The address of the new implementation
    function _authorizeUpgrade(address _impl) internal view override onlyOwner {
        if (!manager.isValidUpgrade(_getImplementation(), _impl)) revert INVALID_UPGRADE(_impl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IManager} from "../manager/IManager.sol";
import {IMetadataRenderer} from "./metadata/IMetadataRenderer.sol";

interface IToken {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ONLY_OWNER();

    error ONLY_AUCTION();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata tokenInitStrings,
        address metadataRenderer,
        address auction
    ) external;

    // function metadataRenderer() external view returns (IMetadataRenderer);

    // function auction() external view returns (address);

    // function totalSupply() external view returns (uint256);

    // function name() external view returns (string memory);

    // function symbol() external view returns (string memory);

    // function contractURI() external view returns (string memory);

    // function tokenURI(uint256 tokenId) external view returns (string memory);

    // function balanceOf(address owner) external view returns (uint256);

    // function ownerOf(uint256 tokenId) external view returns (address);

    // function isApprovedForAll(address owner, address operator) external view returns (bool);

    // function getApproved(uint256 tokenId) external view returns (address);

    // function getVotes(address account) external view returns (uint256);

    // function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    // function delegates(address account) external view returns (address);

    // function nonces(address owner) external view returns (uint256);

    // function DOMAIN_SEPARATOR() external view returns (bytes32);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function getVotes(address user) external view returns (uint256);

    // function getPastVotes(address user, uint256 timestamp) external view returns (uint256);

    // function delegates(address _user) external view returns (address);

    // function delegate(address to) external;

    // function delegateBySig(
    //     address to,
    //     uint256 nonce,
    //     uint256 expiry,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // function mint() external returns (uint256);

    // function burn(uint256 tokenId) external;

    // function approve(address to, uint256 tokenId) external;

    // function setApprovalForAll(address operator, bool approved) external;

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external;

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract EIP712StorageV1 {
    bytes32 internal _HASHED_NAME;
    bytes32 internal _HASHED_VERSION;

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;
    uint256 internal INITIAL_CHAIN_ID;

    mapping(address => uint256) public nonces;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/draft-EIP712.sol
abstract contract EIP712 is Initializable, EIP712StorageV1 {
    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    error EXPIRED_SIGNATURE();

    error INVALID_SIGNER();

    function __EIP712_init(string memory _name, string memory _version) internal onlyInitializing {
        _HASHED_NAME = keccak256(bytes(_name));
        _HASHED_VERSION = keccak256(bytes(_version));

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";
import {Address} from "../utils/Address.sol";
import {Strings} from "../utils/Strings.sol";
import {ERC721TokenReceiver} from "../utils/TokenReceiver.sol";

contract ERC721StorageV1 {
    string public name;

    string public symbol;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;
}

abstract contract ERC721 is Initializable, ERC721StorageV1 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_ADDRESS();

    error NO_OWNER();

    error NOT_AUTHORIZED();

    error WRONG_OWNER();

    error INVALID_RECIPIENT();

    error ALREADY_MINTED();

    error NOT_MINTED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {}

    function contractURI() public view virtual returns (string memory) {}

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    function __ERC721_init(string memory _name, string memory _symbol) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
            _interfaceId == 0x80ac58cd || // ERC721 Interface ID
            _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
    }

    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert INVALID_ADDRESS();

        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = _ownerOf[_tokenId];

        if (owner == address(0)) revert NO_OWNER();

        return owner;
    }

    function approve(address _to, uint256 _tokenId) public {
        address owner = _ownerOf[_tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NOT_AUTHORIZED();

        getApproved[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        if (_from != _ownerOf[_tokenId]) revert WRONG_OWNER();

        if (_to == address(0)) revert INVALID_RECIPIENT();

        if (msg.sender != _from && !isApprovedForAll[_from][msg.sender] && msg.sender != getApproved[_tokenId]) revert NOT_AUTHORIZED();

        _beforeTokenTransfer(_from, _to, _tokenId);

        unchecked {
            --_balanceOf[_from];

            ++_balanceOf[_to];
        }

        _ownerOf[_tokenId] = _to;

        delete getApproved[_tokenId];

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    function _mint(address _to, uint256 _tokenId) internal virtual {
        if (_to == address(0)) revert INVALID_RECIPIENT();

        if (_ownerOf[_tokenId] != address(0)) revert ALREADY_MINTED();

        _beforeTokenTransfer(address(0), _to, _tokenId);

        unchecked {
            ++_balanceOf[_to];
        }

        _ownerOf[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);

        _afterTokenTransfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual {
        address owner = _ownerOf[_tokenId];

        if (owner == address(0)) revert NOT_MINTED();

        _beforeTokenTransfer(owner, address(0), _tokenId);

        unchecked {
            --_balanceOf[owner];
        }

        delete _ownerOf[_tokenId];

        delete getApproved[_tokenId];

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfer(owner, address(0), _tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract TokenTypesV1 {
    struct Founder {
        uint32 allocationFrequency;
        uint64 vestingEnd;
        address wallet;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibUintToString {
    uint256 private constant MAX_UINT256_STRING_LENGTH = 78;
    uint8 private constant ASCII_DIGIT_OFFSET = 48;

    /// @dev Converts a `uint256` value to a string.
    /// @param n The integer to convert.
    /// @return nstr `n` as a decimal string.
    function toString(uint256 n) 
        internal 
        pure 
        returns (string memory nstr) 
    {
        if (n == 0) {
            return "0";
        }
        // Overallocate memory
        nstr = new string(MAX_UINT256_STRING_LENGTH);
        uint256 k = MAX_UINT256_STRING_LENGTH;
        // Populate string from right to left (lsb to msb).
        while (n != 0) {
            assembly {
                let char := add(
                    ASCII_DIGIT_OFFSET,
                    mod(n, 10)
                )
                mstore(add(nstr, k), char)
                k := sub(k, 1)
                n := div(n, 10)
            }
        }
        assembly {
            // Shift pointer over to actual start of string.
            nstr := add(nstr, k)
            // Store actual string length.
            mstore(nstr, sub(MAX_UINT256_STRING_LENGTH, k))
        }
        return nstr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library UriEncode {
    string internal constant _TABLE = "0123456789abcdef";

    function uriEncode(string memory uri)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesUri = bytes(uri);

        string memory table = _TABLE;

        // Max size is worse case all chars need to be encoded
        bytes memory result = new bytes(3 * bytesUri.length);

        /// @solidity memory-safe-assembly
        assembly {
            // Get the lookup table
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Keep track of the final result size string length
            let resultSize := 0

            for {
                let dataPtr := bytesUri
                let endPtr := add(bytesUri, mload(bytesUri))
            } lt(dataPtr, endPtr) {

            } {
                // advance 1 byte
                dataPtr := add(dataPtr, 1)
                let input := and(mload(dataPtr), 127)

                // Check if is valid URI character
                let isValidUriChar := or(
                    and(gt(input, 96), lt(input, 134)), // a 97 / z 133
                    or(
                        and(gt(input, 64), lt(input, 91)), // A 65 / Z 90
                        or(
                          and(gt(input, 47), lt(input, 58)), // 0 48 / 9 57
                          or(
                            or(
                              eq(input, 46), // . 46
                              eq(input, 95)  // _ 95
                            ),
                            or(
                              eq(input, 45),  // - 45
                              eq(input, 126)  // ~ 126
                            )
                          )
                        )
                    )
                )

                switch isValidUriChar
                // If is valid uri character copy character over and increment the result
                case 1 {
                    mstore8(resultPtr, input)
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 1)
                }
                // If the char is not a valid uri character, uriencode the character
                case 0 {
                    mstore8(resultPtr, 37)
                    resultPtr := add(resultPtr, 1)
                    // table[character >> 4] (take the last 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, shr(4, input))))
                    resultPtr := add(resultPtr, 1)
                    // table & 15 (take the first 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, and(input, 15))))
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 3)
                }
            }

            // Set size of result string in memory
            mstore(result, resultSize)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    error INSUFFICIENT_HEX_LENGTH();

    function toString(uint256 _value) internal pure returns (string memory) {
        unchecked {
            if (_value == 0) {
                return "0";
            }

            uint256 temp = _value;
            uint256 digits;

            while (temp != 0) {
                digits++;

                temp /= 10;
            }

            bytes memory buffer = new bytes(digits);

            while (_value != 0) {
                digits -= 1;

                buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));

                _value /= 10;
            }

            return string(buffer);
        }
    }

    function toHexString(uint256 _value) internal pure returns (string memory) {
        unchecked {
            if (_value == 0) {
                return "0x00";
            }

            uint256 temp = _value;

            uint256 length = 0;

            while (temp != 0) {
                length++;

                temp >>= 8;
            }
            return toHexString(_value, length);
        }
    }

    function toHexString(uint256 _value, uint256 length) internal pure returns (string memory) {
        unchecked {
            uint256 bufferSize = 2 * length + 2;

            bytes memory buffer = new bytes(bufferSize);

            buffer[0] = "0";
            buffer[1] = "x";

            uint256 start = bufferSize - 1;

            for (uint256 i = start; i > 1; --i) {
                buffer[i] = _HEX_SYMBOLS[_value & 0xf];

                _value >>= 4;
            }

            if (_value != 0) revert INSUFFICIENT_HEX_LENGTH();

            return string(buffer);
        }
    }

    function toHexString(address _addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(_addr)), 20);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRendererTypesV1} from "../types/MetadataRendererTypesV1.sol";

contract MetadataRendererStorageV1 is MetadataRendererTypesV1 {
    Settings internal settings;

    IPFSGroup[] internal ipfsData;
    Property[] internal properties;

    mapping(uint256 => uint16[16]) internal attributes;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRendererTypesV1} from "./types/MetadataRendererTypesV1.sol";

interface IMetadataRenderer is MetadataRendererTypesV1 {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    event PropertyAdded(uint256 id, string name);

    event ItemAdded(uint256 propertyId, uint256 index);

    event ContractImageUpdated(string prevImage, string newImage);

    event RendererBaseUpdated(string prevRendererBase, string newRendererBase);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ONLY_TOKEN();

    error TOKEN_NOT_MINTED(uint256 tokenId);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        bytes calldata initStrings,
        address token,
        address founders,
        address treasury
    ) external;

    function addProperties(
        string[] calldata names,
        ItemParam[] calldata items,
        IPFSGroup calldata ipfsGroup
    ) external;

    function updateContractImage(string memory newContractImage) external;

    function updateRendererBase(string memory newRendererBase) external;

    function propertiesCount() external view returns (uint256);

    function itemsCount(uint256 propertyId) external view returns (uint256);

    function generate(uint256 tokenId) external;

    function getAttributes(uint256 tokenId) external view returns (bytes memory aryAttributes, bytes memory queryString);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function token() external view returns (address);

    function treasury() external view returns (address);

    function contractImage() external view returns (string memory);

    function rendererBase() external view returns (string memory);

    function description() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface MetadataRendererTypesV1 {
    struct ItemParam {
        uint256 propertyId;
        string name;
        bool isNewProperty;
    }

    struct IPFSGroup {
        string baseUri;
        string extension;
    }

    struct Item {
        uint16 referenceSlot;
        string name;
    }

    struct Property {
        string name;
        Item[] items;
    }

    struct Settings {
        address token;
        address treasury;
        string name;
        string description;
        string contractImage;
        string rendererBase;
    }
}