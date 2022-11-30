// Copyright (c) 2022 Fellowship
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LightYears.sol";
import "./Pausable.sol";

contract TimedSelectionMinter is Pausable {
    uint256 private constant PRESELECTIONS = 2;
    uint256 private constant SELECTION_TICKETS = 98;

    /// @notice ERC-721 contract that is used as passes
    /// @dev should start numbering its tokens from ID 1
    IERC721 public passes;

    /// @notice ERC-721 contract that mints tokens by ID in response to selections
    /// @dev must implement mint(address, uint256)
    LightYears public lightYears;

    /// @notice Address where used passes are sent
    address public passDestination;

    /// @notice Whether or not a given pass has already been claimed
    /// @dev Provides a check against passes recirculating after going to the `passDestination`
    mapping(uint256 => bool) public passClaimed;

    /// @notice The start time for the mint, i.e. when the owner of Pass 1 can make their selection
    uint256 public selectionMintStartTime;

    /// @notice The end of the selection period, after which the contract owner can mint on behalf of pass holders
    uint256 public selectionMintDeadline;

    /// @notice The number of selections that unlock per day
    uint256 public selectionUnlocksPerDay;

    /// @notice The time between passes unlocking, in seconds
    uint256 public selectionUnlockOffset = 15 minutes;

    uint256 private pauseStart;
    uint256 private pastPauseUnlocks;
    uint256 private preselectCount;

    bool private selectionStarted;

    /// @notice An event to be emitted upon selection for the benefit of the UI
    event Selection(address recipient, uint256 passId, uint256 selectedTokenId);

    /// @notice An error returned when the selection has already started.
    error AlreadyStarted();

    constructor(
        IERC721 passes_,
        LightYears lightYears_,
        address destination,
        uint256 startTime,
        uint256 selectionDeadline,
        uint256 unlocksPerDay,
        uint256 unlockOffsetInSeconds
    ) {
        // CHECKS inputs
        require(passes_.supportsInterface(0x80ac58cd), "Pass contract must implement ERC-721");
        require(
            lightYears_.supportsInterface(0x40c10f19),
            "Light Years contract must implement mint(address, uint256)"
        );
        require(destination != address(0), "Final pass destination must not be the zero address");
        require(startTime > block.timestamp, "The start time cannot be in the past");
        require(
            unlocksPerDay > 0 && unlocksPerDay <= SELECTION_TICKETS,
            "Unlocks per day must be between 1 and the number of selection passes"
        );
        require(
            unlockOffsetInSeconds >= 5 minutes && unlockOffsetInSeconds <= 12 hours,
            "Unlock offset must be between 5 minutes and 12 hours"
        );
        require(
            unlocksPerDay * unlockOffsetInSeconds <= 1 days,
            "Unlock offset must allow unlocks per day to complete within 24 hours"
        );
        uint256 selectionDays = (SELECTION_TICKETS + unlocksPerDay - 1) / unlocksPerDay;
        require(
            selectionDeadline >= startTime + 1 days * selectionDays,
            "Selection deadline must be a full day after selection has ended"
        );
        // EFFECTS
        passes = passes_;
        lightYears = lightYears_;
        passDestination = destination;
        selectionMintStartTime = startTime;
        selectionMintDeadline = selectionDeadline;
        selectionUnlocksPerDay = unlocksPerDay;
        selectionUnlockOffset = unlockOffsetInSeconds;
    }

    modifier beforeSelection() {
        if (selectionStarted) revert AlreadyStarted();
        _;
    }

    // TICKET HOLDER FUNCTIONS

    /// @notice Allows the owner of the specified `passes` token to select a token to mint
    /// @dev Can only be called after the pass is unlocked
    /// @param passId The pass being redeemed. The caller must be the owner of the pass or an approved operator.
    /// @param selectedTokenId The unminted token that the sender has chosen to mint
    function select(uint256 passId, uint256 selectedTokenId) external whenNotPaused {
        // CHECKS inputs
        require(passId <= unlockedUpTo(), "Wait for your selection slot");
        require(!passClaimed[passId], "Pass has already been claimed");

        // CHECKS permissions
        // With safe INTERACTIONS: use view function of known contract
        address passHolder = passes.ownerOf(passId);
        address operator = msg.sender;
        require(
            operator == passHolder ||
                passes.isApprovedForAll(passHolder, operator) ||
                passes.getApproved(passId) == operator ||
                // Allow selections by the contract owner after the deadline
                (block.timestamp >= selectionMintDeadline && operator == owner()),
            "Caller is not pass owner or approved"
        );

        // EFFECTS
        selectionStarted = true;
        passClaimed[passId] = true;

        emit Selection(passHolder, passId, selectedTokenId);

        // INTERACTIONS: reverts if selectedTokenId has already been minted
        lightYears.mint(passHolder, selectedTokenId);
        passes.transferFrom(passHolder, passDestination, passId);
    }

    // OWNER FUNCTIONS

    /// @notice Allows the contract owner to preselect a token to mint without a pass
    /// @dev The number of tokens mintable with this method is limited by `PRESELECTIONS`
    /// @param selectedTokenId The unminted token that will be minted
    function preselect(uint256 selectedTokenId) external onlyOwner {
        // CHECKS inputs
        require(preselectCount < PRESELECTIONS, "Preselections have all been minted");

        // EFFECTS
        preselectCount++;
        emit Selection(owner(), SELECTION_TICKETS + preselectCount, selectedTokenId);

        // INTERACTIONS: reverts if selectedTokenId has already been minted
        lightYears.mint(owner(), selectedTokenId);
    }

    /// @notice Update the passes contract address
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setPasses(IERC721 passes_) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(passes_.supportsInterface(0x80ac58cd), "Pass contract must implement ERC-721");
        // EFFECTS
        passes = passes_;
    }

    /// @notice Update the Light Years contract address
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setLightYears(LightYears lightYears_) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(
            lightYears_.supportsInterface(0x40c10f19),
            "Light Years contract must implement mint(address, uint256)"
        );
        // EFFECTS
        lightYears = lightYears_;
    }

    /// @notice Update the pass destination address
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setPassDestination(address passDestination_) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(passDestination_ != address(0), "Final pass destination must not be the zero address");
        // EFFECTS
        passDestination = passDestination_;
    }

    /// @notice Pause this contract
    /// @dev Can only be called by the contract `owner`
    function pause() public override {
        // CHECKS + EFFECTS: `Pausable` handles checking permissions and setting pause state
        super.pause();

        // More EFFECTS
        pauseStart = block.timestamp;
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`. Any selection slots that were during the pause will be pushed
    ///  back, which may require adding more selection blocks to complete the selection process.
    function unpause() public override {
        // CHECKS + EFFECTS: `Pausable` handles checking permissions and setting pause state
        super.unpause();

        // More EFFECTS
        if (block.timestamp > selectionMintStartTime) {
            unchecked {
                // Unchecked arithmetic: pauseStart is a timestamp, selectionUnlockOffset guaranteed to be smaller
                uint256 lastCompletePass = unadjustedMintUpTo(pauseStart - selectionUnlockOffset);
                uint256 unpausePass = unadjustedMintUpTo(block.timestamp);
                // Unchecked arithmetic: RHS never negative. `pastPauseUnlocks` cannot overflow as each pause unlock
                // represents either a unique call to unpause() or a passing of `selectionUnlockOffset` seconds.
                pastPauseUnlocks += unpausePass - lastCompletePass;
            }
        }
    }

    /// @notice Update the start time for the mint
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setSelectionMintStartTime(uint256 startTime) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(startTime > block.timestamp, "The start time cannot be in the past");
        // EFFECTS
        selectionMintStartTime = startTime;
    }

    function setSelectionMintDeadline(uint256 deadline) external onlyOwner beforeSelection {
        // CHECKS inputs
        uint256 selectionDays = (SELECTION_TICKETS + selectionUnlocksPerDay - 1) / selectionUnlocksPerDay;
        require(
            deadline >= selectionMintStartTime + 1 days * selectionDays,
            "Selection deadline must be a full day after selection has ended"
        );
        // EFFECTS
        selectionMintDeadline = deadline;
    }

    /// @notice Update number of selections that unlock per day
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setSelectionUnlocksPerDay(uint256 unlocksPerDay) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(
            unlocksPerDay > 0 && unlocksPerDay <= SELECTION_TICKETS,
            "Unlocks per day must be between 1 and the number of selection passes"
        );
        require(
            unlocksPerDay * selectionUnlockOffset <= 1 days,
            "Unlock offset must allow unlocks per day to complete within 24 hours"
        );
        // EFFECTS
        selectionUnlocksPerDay = unlocksPerDay;
    }

    /// @notice Update the time between passes unlocking
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setSelectionUnlockOffset(uint256 offsetInSeconds) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(
            offsetInSeconds >= 5 minutes && offsetInSeconds <= 12 hours,
            "Unlock offset must be between 5 minutes and 12 hours"
        );
        require(
            selectionUnlocksPerDay * offsetInSeconds <= 1 days,
            "Unlock offset must allow unlocks per day to complete within 24 hours"
        );
        // EFFECTS
        selectionUnlockOffset = offsetInSeconds;
    }

    // VIEW FUNCTIONS

    /// @notice Query the highest pass id that can currently mint
    function unlockedUpTo() public view returns (uint256 passId) {
        passId = unadjustedMintUpTo(block.timestamp);

        // Handle repeated early pauses edge case
        if (pastPauseUnlocks > passId) return 0;

        unchecked {
            // Unchecked arithmetic: already compared values to prevent underflow
            passId -= pastPauseUnlocks;
        }

        if (passId > SELECTION_TICKETS) {
            return SELECTION_TICKETS;
        }
    }

    /// @notice Query the time that the given `passId` will be able to mint
    /// @dev Times in the past may be inaccurate if the contract has previously been paused
    function unlockTime(uint256 passId) external view returns (uint256 unlockTimestamp) {
        // CHECKS input
        require(passId > 0 && passId <= SELECTION_TICKETS, "Invalid pass ID");

        // Compute output
        unchecked {
            // Unchecked arithmetic: switching to zero-indexed. Cannot underflow due to previous checks.
            passId--;
        }
        passId += pastPauseUnlocks;

        unlockTimestamp =
            selectionMintStartTime +
            // Divide before multiply: divide computes completed days
            ((passId / selectionUnlocksPerDay) * 1 days) +
            (selectionUnlockOffset * (passId % selectionUnlocksPerDay));
    }

    /// @notice Query for all times that `passId` holders will be able to mint
    /// @dev Array index === passId - 1
    function unlockTimes() external view returns (uint256[SELECTION_TICKETS] memory unlockTimestamps) {
        uint256 _selectionMintStartTime = selectionMintStartTime;
        uint256 _selectionUnlocksPerDay = selectionUnlocksPerDay;
        uint256 _selectionUnlockOffset = selectionUnlockOffset;
        uint256 _pastPauseUnlocks = pastPauseUnlocks;
        for (uint256 passSlot = _pastPauseUnlocks; passSlot < SELECTION_TICKETS + _pastPauseUnlocks; passSlot++) {
            unlockTimestamps[passSlot - _pastPauseUnlocks] =
                _selectionMintStartTime +
                ((passSlot / _selectionUnlocksPerDay) * 1 days) +
                (_selectionUnlockOffset * (passSlot % _selectionUnlocksPerDay));
        }
        return unlockTimestamps;
    }

    // PRIVATE FUNCTIONS

    function unadjustedMintUpTo(uint256 timestamp) private view returns (uint256 passId) {
        if (timestamp < selectionMintStartTime) return 0;

        unchecked {
            // Unchecked arithmetic: already compared values to prevent underflow
            uint256 elapsedTime = timestamp - selectionMintStartTime;
            uint256 elapsedDays = elapsedTime / (1 days);
            uint256 lastDayUnlocks = Math.min(
                selectionUnlocksPerDay,
                // Unchecked arithmetic: sum guaranteed to be less than (1 days)
                1 + ((elapsedTime % (1 days)) / selectionUnlockOffset)
            );
            // Unchecked arithmetic: passId will be less than timestamp
            passId = elapsedDays * selectionUnlocksPerDay + lastDayUnlocks;
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "./TokenBase.sol";

contract LightYears is TokenBase {
    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        string memory baseURI_
    ) TokenBase(name, symbol, 1, 100, royaltyReceiver) {
        baseURI = baseURI_;
    }

    // MINTER FUNCTIONS

    /// @notice Mint an unclaimed token to the given address
    /// @dev Can only be called by the `minter` address
    /// @param to The new token owner that will receive the minted token
    /// @param tokenId The token being claimed. Reverts if invalid or already claimed.
    function mint(address to, uint256 tokenId) external onlyMinter {
        // CHECKS inputs
        require(tokenId != 0 && tokenId <= 100, "Invalid token ID");
        // CHECKS + EFFECTS (not _safeMint, so no interactions)
        _mint(to, tokenId);
        // More EFFECTS
        unchecked {
            totalSupply++;
        }
    }

    /// @notice Query if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            interfaceId == 0x40c10f19 || // Selector for: mint(address, uint256)
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Pausable is Ownable {
    /// @notice Whether or not this contract is paused
    /// @dev The exact meaning of "paused" will vary by contract, but in general paused contracts should prevent most
    ///  interactions from non-owners
    bool public isPaused = false;

    event Paused();
    event Unpaused();

    error ContractIsPaused();
    error ContractNotPaused();

    modifier whenPaused() {
        if (!isPaused) revert ContractNotPaused();
        _;
    }

    modifier whenNotPaused() {
        if (isPaused) revert ContractIsPaused();
        _;
    }

    // OWNER FUNCTIONS

    /// @notice Pause this contract
    /// @dev Can only be called by the contract `owner`
    function pause() public virtual whenNotPaused onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        isPaused = true;
        emit Paused();
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`
    function unpause() public virtual whenPaused onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        isPaused = false;
        emit Unpaused();
    }

    // VIEW FUNCTIONS

    /// @notice Query if this contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if `interfaceID` is implemented and is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x7f5828d0 || // ERC-173 Contract Ownership Standard
            interfaceId == 0x01ffc9a7; // ERC-165 Standard Interface Detection
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address contract_, address operator) external view returns (bool);

    function registerAndSubscribe(address contract_, address subscription) external;
}

contract TimeLimitedOperatorFilter {
    /// @notice The OpenSea OperatorFilterRegistry deployment
    IOperatorFilterRegistry private constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    uint256 private constant FILTER_END_DATE = 1675227600; // 2023-02-01 00:00:00 EST

    error OperatorNotAllowed(address operator);

    constructor() {
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Subscribe to the "OpenSea Curated Subscription Address"
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
        }
    }

    function operatorAllowed(address operator) internal view returns (bool) {
        return
            block.timestamp >= FILTER_END_DATE ||
            address(OPERATOR_FILTER_REGISTRY).code.length == 0 ||
            OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TimeLimitedOperatorFilter.sol";

/// @title Token Base
/// @notice Shared logic for token contracts
abstract contract TokenBase is ERC721, Ownable, TimeLimitedOperatorFilter {
    using Strings for uint256;

    uint256 private immutable MIN_ID;
    uint256 private immutable MAX_ID;

    address public royaltyReceiver;
    address public minter;
    address public metadataContract;

    uint256 public royaltyFraction = 7;
    uint256 public royaltyDenominator = 100;

    /// @notice Count of valid NFTs tracked by this contract
    /// @dev Contracts that extend TokenBase must manually manage this number
    uint256 public totalSupply;

    /// @notice Return the baseURI used for computing `tokenURI` values
    string public baseURI;

    error OnlyMinter();

    /// @dev This event emits when the metadata of a token is changed. Anyone aware of ERC-4906 can update cached
    ///  attributes related to a given `tokenId`.
    event MetadataUpdate(uint256 tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed. mAnyone aware of ERC-4906 can update
    ///  cached attributes for tokens in the designated range.
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    constructor(
        string memory name,
        string memory symbol,
        uint256 minId,
        uint256 maxId,
        address royaltyReceiver_
    ) ERC721(name, symbol) {
        // CHECKS inputs
        require(minId <= maxId, "Invalid token ID range");
        require(royaltyReceiver_ != address(0), "Royalty receiver must not be the zero address");
        // EFFECTS
        MIN_ID = minId;
        MAX_ID = maxId;
        royaltyReceiver = royaltyReceiver_;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) revert OnlyMinter();
        _;
    }

    // HOLDER FUNCTIONS

    /// @notice Enable or disable approval for an `operator` to manage all assets belonging to the sender
    /// @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True to grant approval, false to revoke approval
    function setApprovalForAll(address operator, bool approved) public virtual override {
        // CHECKS inputs
        if (approved && !operatorAllowed(operator)) revert OperatorNotAllowed(operator);
        // CHECKS + EFFECTS
        super.setApprovalForAll(operator, approved);
    }

    // OWNER FUNCTIONS

    /// @notice Set the `minter` address
    /// @dev Can only be called by the contract `owner`
    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
    }

    /// @notice Set the `royaltyReceiver` address
    /// @dev Can only be called by the contract `owner`
    function setRoyaltyReceiver(address royaltyReceiver_) external onlyOwner {
        // CHECKS inputs
        require(royaltyReceiver_ != address(0), "Royalty receiver must not be the zero address");
        // EFFECTS
        royaltyReceiver = royaltyReceiver_;
    }

    /// @notice Update the royalty fraction
    /// @dev Can only be called by the contract `owner`
    function setRoyaltyFraction(uint256 royaltyFraction_, uint256 royaltyDenominator_) external onlyOwner {
        // CHECKS inputs
        require(royaltyDenominator_ != 0, "Royalty denominator must not be zero");
        require(royaltyFraction_ <= royaltyDenominator_, "Royalty fraction must not be greater than 100%");
        // EFFECTS
        royaltyFraction = royaltyFraction_;
        royaltyDenominator = royaltyDenominator_;
    }

    /// @notice Update the baseURI for all metadata
    /// @dev Can only be called by the contract `owner`. Emits an ERC-4906 event.
    /// @param baseURI_ The new URI base. When specified, token URIs are created by concatenating the baseURI,
    ///  token ID, and ".json".
    function updateBaseURI(string calldata baseURI_) external onlyOwner {
        // CHECKS inputs
        require(bytes(baseURI_).length > 0, "New base URI must be provided");

        // EFFECTS
        baseURI = baseURI_;
        metadataContract = address(0);

        emit BatchMetadataUpdate(MIN_ID, MAX_ID);
    }

    /// @notice Delegate all `tokenURI` calls to another contract
    /// @dev Can only be called by the contract `owner`. Emits an ERC-4906 event.
    /// @param delegate The contract that will handle `tokenURI` responses
    function delegateTokenURIs(address delegate) external onlyOwner {
        // CHECKS inputs
        require(delegate != address(0), "New metadata delegate must not be the zero address");
        require(delegate.code.length > 0, "New metadata delegate must be a contract");

        // EFFECTS
        baseURI = "";
        metadataContract = delegate;

        emit BatchMetadataUpdate(MIN_ID, MAX_ID);
    }

    // VIEW FUNCTIONS

    /// @notice The URI for the given token
    /// @dev Throws if `tokenId` is not valid or has not been minted
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        if (address(metadataContract) != address(0)) {
            return IERC721Metadata(metadataContract).tokenURI(tokenId);
        }

        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }

        revert("tokenURI not configured");
    }

    /// @notice Return whether the given tokenId has been minted yet
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Calculate how much royalty is owed and to whom
    /// @param salePrice - the sale price of the NFT asset
    /// @return receiver - address of where the royalty payment should be sent
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyReceiver;
        // Use OpenZeppelin math utils for full precision multiply and divide without overflow.
        royaltyAmount = Math.mulDiv(salePrice, royaltyFraction, royaltyDenominator, Math.Rounding.Up);
    }

    /// @notice Query if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC-721 Non-Fungible Token Standard
            interfaceId == 0x5b5e139f || // ERC-721 Non-Fungible Token Standard - metadata extension
            interfaceId == 0x2a55205a || // ERC-2981 NFT Royalty Standard
            interfaceId == 0x49064906 || // ERC-4906 Metadata Update Extension
            interfaceId == 0x7f5828d0 || // ERC-173 Contract Ownership Standard
            interfaceId == 0x01ffc9a7; // ERC-165 Standard Interface Detection
    }

    // PRIVATE FUNCTIONS

    /// @dev OpenZeppelin hook that is called before any token transfer, including minting and burning
    function _beforeTokenTransfer(address from, address, uint256) internal virtual override {
        if (from != address(0) && from != msg.sender && !operatorAllowed(msg.sender)) {
            revert OperatorNotAllowed(msg.sender);
        }
    }
}

// OpenZeppelin Contracts
//
// Copyright (c) 2016-2022 zOS Global Limited and contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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