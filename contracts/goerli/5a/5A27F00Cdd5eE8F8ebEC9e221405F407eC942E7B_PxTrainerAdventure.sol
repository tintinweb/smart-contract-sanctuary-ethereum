// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WinnerSelectionManager.sol";
import "./IPxTrainerAdventureSignature.sol";
import "./Utils.sol";

/// @notice Thrown when all prizes are already claimed
error AlreadyClaimed();
/// @notice Thrown when address is not a winner
error NotAWinner();
/// @notice Thrown when input is not as expected condition
error InvalidInput();
/// @notice Thrown when inputting non-exist treasure index
error InvalidTreasureIndex();
/// @notice Thrown when no available prizes to be transferred to the winner
error InsufficientToken();
/// @notice Thrown when not enough winner to be selected to get Sponsored Trips
error NotEnoughWinnersForSponsoredTrip();
/// @notice Thrown when the input signature is invalid.
error InvalidSignature();

contract PxTrainerAdventure is WinnerSelectionManager, Utils, ReentrancyGuard {
    /// @notice code number for ERC1155 token
    uint256 public constant ERC_1155_TYPE = 1;
    /// @notice code number for ERC721 token
    uint256 public constant ERC_721_TYPE = 2;

    /// @dev Signature Contract Address
    IPxTrainerAdventureSignature public SIGNATURE_CONTRACT;

    /// @notice Wallet address that keeps all prizes
    address public vaultWalletAddress;

    /// @notice Claim ID
    /// @dev This can be used to track the claimed prize
    uint256 public claimIndexCount;
    /// @notice Total prize options
    uint256 public totalTreasures;
    /// @notice Variable to store Sponsored Trips prize information such
    ///         as the collection address, token ID, amount, and token type
    Treasure public sponsoredTrip;
    /// @notice Variable to store prize information such as the collection
    ///         address, token ID, amount, and token type
    /// @custom:key prize ID
    /// @custom:value Prize information
    mapping(uint256 => Treasure) public treasures;
    /// @notice List of address who owns Sponsored Trips
    /// @custom:key wallet address
    /// @custom:value 'true' means already own Sponsored Trips
    mapping(address => bool) public sponsoredTripWinners;

    /// @notice Emit when a prize is claimed
    /// @dev The requestId input can use the value of claimIndexCount
    /// @param weekNumber Week number when the prize is claimed
    /// @param requestId Claim ID
    /// @param userWallet Wallet address who claims the prize
    /// @param collectionAddress The origin address of the prize
    /// @param tokenId The prize token ID in its origin address
    /// @param tokenType The token type in its origin address
    /// @param randomNumber The random number generated when claiming the prize
    event TreasureTransferred(
        uint256 weekNumber,
        uint256 requestId,
        address userWallet,
        address collectionAddress,
        uint256 tokenId,
        uint256 tokenType,
        uint256 randomNumber
    );

    /// @notice The contract constructor
    /// @dev The constructor parameters only used as input
    ///      from WinnerSelectionManager contract
    /// @param _vrfCoordinator The address of the Chainlink VRF Coordinator contract
    /// @param _chainLinkSubscriptionId The Chainlink Subscription ID that is funded to use VRF
    /// @param _keyHash The gas lane to use, which specifies the maximum gas price to bump to.
    ///        More https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    /// @param _pxSignatureAddress Signature contract address
    constructor(
        address _vrfCoordinator,
        uint64 _chainLinkSubscriptionId,
        bytes32 _keyHash,
        address _pxSignatureAddress
    ) WinnerSelectionManager(_vrfCoordinator, _chainLinkSubscriptionId, _keyHash) {
        SIGNATURE_CONTRACT = IPxTrainerAdventureSignature(_pxSignatureAddress);
    }

    function setSignatureContractAddress(address _pxSignatureAddress) external onlyOwner {
        SIGNATURE_CONTRACT = IPxTrainerAdventureSignature(_pxSignatureAddress);
    }

    /// @notice Set address to become vault
    /// @param _walletAddress Wallet address that will be the vault
    function setVaultWalletAddress(address _walletAddress) external onlyOwner {
        vaultWalletAddress = _walletAddress;
    }

    /// @notice Add prize to the smart contract
    /// @dev Only admin can call this method
    /// @param _treasure Prize information according to Treasure struct
    function addTreasures(Treasure memory _treasure) external onlyAdmin(msg.sender) {
        totalTreasures++;
        if (_treasure.claimedToken != 0 || (_treasure.contractType != ERC_1155_TYPE && _treasure.contractType != ERC_721_TYPE)) {
            revert InvalidInput();
        }
        if ((_treasure.contractType == ERC_1155_TYPE && _treasure.tokenIds.length > 0) || (_treasure.contractType == ERC_721_TYPE && _treasure.tokenIds.length == 0)) {
            revert InvalidInput();
        }
        treasures[totalTreasures] = _treasure;
    }

    /// @notice Add Sponsored Trips prize to the smart contract
    /// @dev Can only be called by administrators
    /// @param _treasure Sponsored Trips information according to Treasure struct
    function addSponsoredTripTreasure(Treasure memory _treasure) external onlyAdmin(msg.sender) {
        if (_treasure.claimedToken != 0 || _treasure.contractType != ERC_1155_TYPE || _treasure.tokenIds.length > 0) {
            revert InvalidInput();
        }
        sponsoredTrip = _treasure;
    }

    /// @notice Claim prize for winner
    /// @dev Only winner of the week can call this method
    /// @param _weekNumber The week number to claim prize
    /// @param _signature Signature from signer wallet
    function claimTreasure(uint256 _weekNumber, bytes calldata _signature) external nonReentrant noContracts {
        if (!(block.timestamp >= weekInfos[_weekNumber].claimStartTimeStamp && block.timestamp <= weekInfos[_weekNumber].endTimeStamp)) {
            revert InvalidClaimingPeriod();
        }
        Week storage week = weekInfos[_weekNumber];
        
        bool isValidSigner = SIGNATURE_CONTRACT.recoverSignerFromSignature(_weekNumber, week.winners[msg.sender].claimed, msg.sender, _signature);
        
        if(!isValidSigner) {
            revert InvalidSignature();
        }

        if (week.winners[msg.sender].claimLimit == 0) {
            revert NotAWinner();
        }
        if (week.winners[msg.sender].claimed == weekInfos[_weekNumber].winners[msg.sender].claimLimit) {
            revert AlreadyClaimed();
        }
        if (week.winners[msg.sender].claimed == 0) {
            primaryClaim(_weekNumber);
        } else {
            secondaryClaim(_weekNumber);
        }
    }

    /// @notice Method to claim the first prize
    /// @dev This method is also used to claim Sponsor Trips if
    ///      the winner selected to get one
    /// @param _weekNumber The week number to claim prize
    function primaryClaim(uint256 _weekNumber) internal {
        Week storage week = weekInfos[_weekNumber];
        if (week.tripWinnersMap[msg.sender]) {
            sponsoredTripWinners[msg.sender] = true;
            week.tripWinnersMap[msg.sender] = false;
            week.winners[msg.sender].claimed++;
            week.availabletripsCount--;
            sponsoredTrip.claimedToken++;
            claimIndexCount++;
            transferToken(sponsoredTrip);
            claimIndexCount++;
            emit TreasureTransferred(
                _weekNumber,
                claimIndexCount,
                msg.sender,
                sponsoredTrip.collectionAddress,
                sponsoredTrip.tokenId,
                sponsoredTrip.contractType,
                0
            );
        } else {
            uint256 randomNumber = getRandomNumber();
            uint256 random = randomNumber - ((randomNumber / week.remainingSupply) * week.remainingSupply) + 1;

            uint256 selectedIndex;
            uint256 sumOfTotalSupply;

            for (uint256 index = 1; index <= week.treasureCount; index++) {
                if (week.distributions[index].totalSupply == 0) {
                    continue;
                }
                sumOfTotalSupply += week.distributions[index].totalSupply;
                if (random <= sumOfTotalSupply) {
                    selectedIndex = index;
                    break;
                }
            }
            uint256 selectedTreasureIndex = week.distributions[selectedIndex].treasureIndex;
            week.distributions[selectedIndex].totalSupply--;
            week.winners[msg.sender].treasureTypeClaimed[treasures[selectedTreasureIndex].treasureType] = true;
            week.winners[msg.sender].claimed++;
            week.remainingSupply--;
            claimIndexCount++;
            treasures[selectedTreasureIndex].claimedToken++;

            transferToken(treasures[selectedTreasureIndex]);

            emit TreasureTransferred(
                _weekNumber,
                claimIndexCount,
                msg.sender,
                treasures[selectedTreasureIndex].collectionAddress,
                treasures[selectedTreasureIndex].tokenId,
                treasures[selectedTreasureIndex].contractType,
                randomNumber
            );
        }
    }

    /// @notice Method to claim the next prize
    /// @dev This method will give different prizes than the first
    ///      one if there still other prize option available
    /// @param _weekNumber The week number to claim prize
    function secondaryClaim(uint256 _weekNumber) internal {
        Week storage week = weekInfos[_weekNumber];
        uint256 remaining;
        uint256 altRemaining;

        for (uint256 index = 1; index <= week.treasureCount; index++) {
            uint256 treasureType = treasures[week.distributions[index].treasureIndex].treasureType;
            if (week.winners[msg.sender].treasureTypeClaimed[treasureType]) {
                altRemaining += week.distributions[index].totalSupply;
            } else {
                remaining += week.distributions[index].totalSupply;
            }
        }
        uint256 randomNumber = getRandomNumber();

        uint256 selectedIndex;
        uint256 sumOfTotalSupply;
        if (altRemaining == week.remainingSupply) {
            uint256 random = randomNumber - ((randomNumber / altRemaining) * altRemaining) + 1;
            for (uint256 index = 1; index <= week.treasureCount; index++) {
                uint256 treasureType = treasures[week.distributions[index].treasureIndex].treasureType;
                if (week.distributions[index].totalSupply == 0 || !week.winners[msg.sender].treasureTypeClaimed[treasureType]) {
                    continue;
                }
                sumOfTotalSupply += week.distributions[index].totalSupply;
                if (random <= sumOfTotalSupply) {
                    selectedIndex = index;
                    break;
                }
            }
        } else {
            uint256 random = randomNumber - ((randomNumber / remaining) * remaining) + 1;

            for (uint256 index = 1; index <= week.treasureCount; index++) {
                uint256 treasureType = treasures[week.distributions[index].treasureIndex].treasureType;
                if (week.distributions[index].totalSupply == 0 || week.winners[msg.sender].treasureTypeClaimed[treasureType]) {
                    continue;
                }
                sumOfTotalSupply += week.distributions[index].totalSupply;
                if (random <= sumOfTotalSupply) {
                    selectedIndex = index;
                    break;
                }
            }
        }

        uint256 selectedTreasureIndex = week.distributions[selectedIndex].treasureIndex;
        week.distributions[selectedIndex].totalSupply--;
        week.winners[msg.sender].treasureTypeClaimed[treasures[selectedTreasureIndex].treasureType] = true;
        week.winners[msg.sender].claimed++;
        week.remainingSupply--;
        treasures[selectedTreasureIndex].claimedToken++;
        transferToken(treasures[selectedTreasureIndex]);
        emit TreasureTransferred(
            _weekNumber,
            claimIndexCount,
            msg.sender,
            treasures[selectedTreasureIndex].collectionAddress,
            treasures[selectedTreasureIndex].tokenId,
            treasures[selectedTreasureIndex].contractType,
            randomNumber
        );
    }

    /// @notice Transfer token from vault to the method caller's wallet address
    /// @dev This method will be used in a public method and user who call the
    ///      method will get a token from vault
    /// @param _treasure Prize to transfer
    function transferToken(Treasure memory _treasure) internal {
        if (_treasure.contractType == ERC_1155_TYPE) {
            IERC1155 erc1155Contract = IERC1155(_treasure.collectionAddress);
            erc1155Contract.safeTransferFrom(vaultWalletAddress, msg.sender, _treasure.tokenId, 1, "");
        }
        if (_treasure.contractType == ERC_721_TYPE) {
            IERC721 erc721Contract = IERC721(_treasure.collectionAddress);
            if (_treasure.tokenIds.length == _treasure.claimedToken) {
                revert InsufficientToken();
            }
            erc721Contract.transferFrom(vaultWalletAddress, msg.sender, _treasure.tokenIds[_treasure.claimedToken - 1]);
        }
    }

    /// @notice Set prize that will be awarded to the winner of the week
    /// @dev Only admin can call this method
    /// @param _weekNumber The week number
    /// @param _treasureindexes The index of the treasure in 'treasures' mapping variable
    /// @param _counts Amount of treasure that will be available to claim during the week
    function setWeeklyTreasureDistribution(
        uint256 _weekNumber,
        uint256[] memory _treasureindexes,
        uint256[] memory _counts
    ) external onlyAdmin(msg.sender) validTreaureDistributionPeriod(_weekNumber) validArrayLength(_treasureindexes.length, _counts.length) {
        Week storage week = weekInfos[_weekNumber];

        for (uint256 index = 0; index < _treasureindexes.length; index++) {
            if (_treasureindexes[index] == 0 || _treasureindexes[index] > totalTreasures) {
                revert InvalidTreasureIndex();
            }
            week.treasureCount++;
            week.distributions[week.treasureCount].treasureIndex = _treasureindexes[index];
            week.distributions[week.treasureCount].totalSupply = _counts[index];
            week.remainingSupply += _counts[index];
        }
    }

    /// @notice Set amount of Sponsored Trips prize that will be awarded to the winner of the week
    /// @param _weekNumber The week number
    /// @param _count Amount of Sponsored Trips that will be distributed during the week
    function setWeeklySponsoredTripDistribution(
        uint256 _weekNumber,
        uint256 _count
    ) external onlyAdmin(msg.sender) validTreaureDistributionPeriod(_weekNumber) {
        weekInfos[_weekNumber].sponsoredTripsCount = _count;
        weekInfos[_weekNumber].availabletripsCount = _count;
    }

    /// @notice Set a list of winner of the week
    /// @param _weekNumber The week number
    /// @param _winners List of wallet addresses that become the winner
    /// @param _counts Amount of prize that awarded to the winner
    function updateWeeklyWinners(
        uint256 _weekNumber,
        address[] memory _winners,
        uint8[] memory _counts
    )
        external
        onlyModerator(msg.sender)
        validWeekNumber(_weekNumber)
        validArrayLength(_winners.length, _counts.length)
        validWinnerUpdationPeriod(_weekNumber)
    {
        uint256 randomNumber = getRandomNumber();
        uint256 index = randomNumber - ((randomNumber / _counts.length) * _counts.length);
        uint256 counter = 0;
        uint256 tripCount = 0;
        address[] memory tmp = new address[](weekInfos[_weekNumber].sponsoredTripsCount);
        while (counter < _counts.length) {
            if (index == _counts.length) {
                index = 0;
            }
            if (sponsoredTripWinners[_winners[index]] == false && tripCount < weekInfos[_weekNumber].sponsoredTripsCount) {
                weekInfos[_weekNumber].tripWinnersMap[_winners[index]] = true;
                tmp[tripCount] = _winners[index];
                tripCount++;
            }
            weekInfos[_weekNumber].winners[_winners[index]].claimLimit = _counts[index];

            index++;
            counter++;
        }
        if (tripCount < weekInfos[_weekNumber].sponsoredTripsCount) {
            revert NotEnoughWinnersForSponsoredTrip();
        }
        weekInfos[_weekNumber].tripWinners = tmp;

        emit WeeklyWinnersSet(_weekNumber, tmp);
    }

    /// @notice Add a list of wallet addresses that already owns Sponsored Trips
    /// @param _previousWinners List of addresses that already owns Sponsored Trips
    /// @param _flags 'true' means already own Sponsored Trips
    function setSponsoredTripWinnerMap(
        address[] memory _previousWinners,
        bool[] memory _flags
    ) external onlyAdmin(msg.sender) validArrayLength(_previousWinners.length, _flags.length) {
        for (uint256 index = 0; index < _flags.length; index++) {
            sponsoredTripWinners[_previousWinners[index]] = _flags[index];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

/// @title Pixelmon Trainer Adventure Smart Contract
/// @author LiquidX
/// @notice This smart contract provides configuration for the Trainer Adventure event on Pixelmon

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Thrown when end timestamp is less than equal to start timestamp
error InvalidTimeStamp();
/// @notice Thrown when inputting week number less than equal to the current week number
///         and when the start week number is greater than end week number
error InvalidWeekNumber();
/// @notice Thrown when week duration is less than total period for updating prize and set the winners
error InvalidDuration();
/// @notice Thrown when block.timestamp is less than end timestamp of the current week
///         or more than the start timestamp in the next week
error InvalidUpdationPeriod();
/// @notice Thrown when claiming treasure beyond the schedule
error InvalidClaimingPeriod();
/// @notice Thrown when address has no "Admin" role
error NotAdmin();
/// @notice Thrown when address has no "Moderator" role
error NotModerator();
/// @notice Thrown when length of both arrays are not equal
error InvalidLength();

contract WinnerSelectionManager is Ownable, VRFConsumerBaseV2 {
    /// @notice Amount of random number requested to Chainlink
    uint32 public constant Random_Number_Count = 3;

    /// @notice Struct object to send request to Chainlink
    /// @param fulfilled Whether the random words has been set or not
    /// @param exists Whether the request has been sent or not
    /// @param weekNumber Draw week number
    /// @param randomWords Random words from Chainlink
    struct Request {
        bool fulfilled;
        bool exists;
        uint256 weekNumber;
        uint256[] randomWords;
    }

    /// @notice Struct object for winner information
    /// @param claimLimit Maximum prize that can be claimed by winner
    /// @param claimed Number of prize that has been claimed by winner
    /// @param treasureTypeClaimed Type of prize that is rewarded to the winner.
    ///        'true' means the prize has been claimed by the winner. Otherwise false
    struct Winner {
        uint8 claimLimit;
        uint8 claimed;
        mapping(uint256 => bool) treasureTypeClaimed;
    }

    /// @notice Struct object to store prize information
    /// @dev If the prize is ERC721, leave tokenIds value as empty array
    ///      if the prize is ERC1155, leave tokenId value as dummy
    /// @param collectionAddress Contract address which is the origin of the prize
    /// @param tokenId ERC721 Prize token ID in its Smart Contract
    /// @param tokenIds ERC1155 Prize token ID in its Smart Contract
    /// @param claimedToken Amount of token that has been claimed
    /// @param contractType 1 for ERC1155, 2 for ERC721
    /// @param treasureType Similar like ID for the prize. Prize ID is different
    ///        than token ID, 2 token IDs can have same prize ID. Prize ID is used
    ///        to identify the prize that claimed by winner and it's used to make
    ///        sure the winner will get different set of prizes.
    struct Treasure {
        address collectionAddress;
        uint256 tokenId;
        uint256[] tokenIds;
        uint256 claimedToken;
        uint256 contractType;
        uint256 treasureType;
    }

    /// @notice Struct object to store information about prize that distributed within a week
    /// @param treasureIndex Index of the prize in the smart contract
    /// @param totalSupply Total supply of the prize within a week
    struct TreasureDistribution {
        uint256 treasureIndex;
        uint256 totalSupply;
    }

    /// @notice Struct object to store week information
    /// @param startTimeStamp Start time of the event in a week
    /// @param ticketDrawTimeStamp Time of the ticket is distributed within a week
    /// @param claimStartTimeStamp Time where the winner can claim the prize
    /// @param endTimeStamp End time of the event in a week
    /// @param remainingSupply The remaining prize supply that hasn't been claimed during
    ///        the week. This supply is the sum of every prize supply excluding Sponsored Trips
    /// @param treasureCount How many prize option available
    /// @param sponsoredTripsCount How many Sponsored Trips available in a week
    /// @param availabletripsCount How many Sponsored Trips prize that has not been claimed
    /// @param randomNumbers Chainlink random seed
    /// @param tripWinners Winner of Sponsored Trips
    /// @param tripWinnersMap Map that contains address of the Sponsored Trips winner.
    ///        Map is used to easily validate whether the address is a winner rather than
    ///        iterating every index in a list/array to find a winner
    /// @param distributions Map of prize that is distributed during the week
    /// @param winners List of winner of the week
    struct Week {
        uint256 startTimeStamp;
        uint256 ticketDrawTimeStamp;
        uint256 claimStartTimeStamp;
        uint256 endTimeStamp;
        uint256 remainingSupply;
        uint256 treasureCount;
        uint256 sponsoredTripsCount;
        uint256 availabletripsCount;
        uint256[] randomNumbers;
        address[] tripWinners;
        mapping(address => bool) tripWinnersMap;
        mapping(uint256 => TreasureDistribution) distributions;
        mapping(address => Winner) winners;
    }

    /// @notice Struct object for week information
    /// @dev This struct is only used as return type for getWeekInfo method
    /// @param startTimeStamp Start time of the event in a week
    /// @param ticketDrawTimeStamp Time of the ticket is distributed within a week
    /// @param claimStartTimeStamp Time where the winner can claim the prize
    /// @param endTimeStamp End time of the event in a week
    /// @param remainingSupply The remaining prize supply that hasn't been claimed during
    ///        the week. This supply is the sum of every prize supply excluding Sponsored Trips
    /// @param treasureCount How many prize option available
    /// @param sponsoredTripsCount How many Sponsored Trips available in a week
    /// @param randomNumbers Chainlink random seed
    /// @param tripWinners Winner of Sponsored Trips
    /// @param availabletripsCount How many Sponsored Trips prize that has not been claimed
    struct WeekData {
        uint256 startTimeStamp;
        uint256 ticketDrawTimeStamp;
        uint256 claimStartTimeStamp;
        uint256 endTimeStamp;
        uint256 remainingSupply;
        uint256 treasureCount;
        uint256 sponsoredTripsCount;
        uint256[] randomNumbers;
        address[] tripWinners;
        uint256 availabletripsCount;
    }

    /// @notice Total week to claim treasure
    uint256 public totalWeek;
    /// @notice Collection of information for each week
    mapping(uint256 => Week) public weekInfos;

    /// @notice List of address that has "Admin" role, 'true' means it has the privilege
    mapping(address => bool) public adminWallets;
    /// @notice List of address that has "Moderator" role, 'true' means it has the privilege
    mapping(address => bool) public moderatorWallets;

    /// @notice The maximum gas price to pay for a request to Chainlink in wei.
    bytes32 public keyHash;
    /// @notice How many confirmations the Chainlink node should wait before responding
    uint16 requestConfirmations = 3;
    /// @notice Chainlink subscription ID that used for sending request
    uint64 public chainLinkSubscriptionId;
    /// @notice Gas limit used to call Chainlink
    uint32 public callbackGasLimit = 400000;
    /// @notice Address that is able to call Chainlink
    VRFCoordinatorV2Interface internal COORDINATOR;
    /// @notice Last request ID to Chainlink
    uint256 public lastRequestId;
    /// @notice Collection of chainink request ID
    uint256[] public requestIds;
    /// @notice Map of request to Chainlink
    mapping(uint256 => Request) public requests;

    /// @notice Check whether address has "Admin" role
    /// @param _walletAddress Valid ethereum address
    modifier onlyAdmin(address _walletAddress) {
        if (!adminWallets[_walletAddress]) {
            revert NotAdmin();
        }
        _;
    }

    /// @notice Check whether address has "Moderator" role
    /// @param _walletAddress Valid ethereum address
    modifier onlyModerator(address _walletAddress) {
        if (!moderatorWallets[_walletAddress]) {
            revert NotModerator();
        }
        _;
    }

    /// @notice Check whether block.timestamp is within the schedule
    ///         to set prize distribution
    /// @param _weekNumber Number of the week
    modifier validTreaureDistributionPeriod(uint256 _weekNumber) {
        if (!(block.timestamp >= weekInfos[_weekNumber].startTimeStamp && block.timestamp < weekInfos[_weekNumber].ticketDrawTimeStamp)) {
            revert InvalidUpdationPeriod();
        }
        _;
    }

    /// @notice Check whether block.timestamp is beyond the schedule
    ///         to update winner merkle root and chainlink
    /// @param _weekNumber Number of the week
    modifier validWinnerUpdationPeriod(uint256 _weekNumber) {
        if (!(block.timestamp >= weekInfos[_weekNumber].ticketDrawTimeStamp && block.timestamp < weekInfos[_weekNumber].claimStartTimeStamp)) {
            revert InvalidUpdationPeriod();
        }
        _;
    }

    /// @notice Check whether the input week number is valid
    /// @param _weekNumber Number of the week
    modifier validWeekNumber(uint256 _weekNumber) {
        if (_weekNumber == 0 || _weekNumber > totalWeek) {
            revert InvalidWeekNumber();
        }
        _;
    }

    /// @notice Check whether both array input has the same length
    /// @param length1 First length of the array input
    /// @param length2 Second length of the array input
    modifier validArrayLength(uint256 length1, uint256 length2) {
        if (length1 != length2) {
            revert InvalidLength();
        }
        _;
    }

    /// @notice Emit when calling fulfillRandomWords function
    /// @param weekNumber The week number when the request is sent to Chainlink
    /// @param RandomWords The input random words
    event ChainlinkRandomNumberSet(uint256 weekNumber, uint256[] RandomWords);

    /// @notice Emit when winners of the week has been selected
    /// @param weekNumber The week number
    /// @param tripWinners The winner for Sponsored Trips prize
    event WeeklyWinnersSet(uint256 weekNumber, address[] tripWinners);

    /// @notice Constructor function
    /// @param _vrfCoordinator The address of the Chainlink VRF Coordinator contract
    /// @param _chainLinkSubscriptionId The Chainlink Subscription ID that is funded to use VRF
    /// @param _keyHash The gas lane to use, which specifies the maximum gas price to bump to.
    ///        More https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    constructor(address _vrfCoordinator, uint64 _chainLinkSubscriptionId, bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        chainLinkSubscriptionId = _chainLinkSubscriptionId;
    }

    /// @notice Set "Admin" role for specific address, 'true' means it has privilege
    /// @dev Only owner can call this method
    /// @param _walletAddress The address that will be set as admin
    /// @param _flag 'true' means the address is an admin
    function setAdminWallet(address _walletAddress, bool _flag) external onlyOwner {
        adminWallets[_walletAddress] = _flag;
    }

    /// @notice Set "Moderator" role for specific address, 'true' means it has privilege
    /// @dev Only owner can call this method
    /// @param _walletAddress The address that will be set as moderator
    /// @param _flag 'true' means the address is a moderator
    function setModeratorWallet(address _walletAddress, bool _flag) external onlyOwner {
        moderatorWallets[_walletAddress] = _flag;
    }

    /// @notice Set callback gas limit parameter when sending request to Chainlink
    /// @param _callbackGasLimit Amount of expected gas limit
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyAdmin(msg.sender) {
        callbackGasLimit = _callbackGasLimit;
    }

    /// @notice Set keyHash parameter when sending request to Chainlink
    /// @param _keyHash key Hash for chain link
    function setChainLinkKeyHash(bytes32 _keyHash) external onlyAdmin(msg.sender) {
        keyHash = _keyHash;
    }

    /// @notice Set chainLinkSubscriptionId parameter when sending request to Chainlink
    /// @param _chainLinkSubscriptionId Chainlink subscription Id
    function setChainlinkSubscriptionId(uint64 _chainLinkSubscriptionId) external onlyAdmin(msg.sender) {
        chainLinkSubscriptionId = _chainLinkSubscriptionId;
    }

    /// @notice Generate random number from Chainlink
    /// @param _weekNumber Number of the week
    /// @return requestId Chainlink requestId
    function generateChainLinkRandomNumbers(
        uint256 _weekNumber
    ) external onlyModerator(msg.sender) validWinnerUpdationPeriod(_weekNumber) validWeekNumber(_weekNumber) returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(keyHash, chainLinkSubscriptionId, requestConfirmations, callbackGasLimit, Random_Number_Count);
        requests[requestId] = Request({randomWords: new uint256[](0), exists: true, fulfilled: false, weekNumber: _weekNumber});
        requestIds.push(requestId);
        lastRequestId = requestId;
        return requestId;
    }

    /// @notice Store random words in a contract
    /// @param _requestId Chainlink request ID
    /// @param _randomWords A collection of random word
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(requests[_requestId].exists, "request not found");
        requests[_requestId].fulfilled = true;
        requests[_requestId].randomWords = _randomWords;
        weekInfos[requests[_requestId].weekNumber].randomNumbers = _randomWords;
        emit ChainlinkRandomNumberSet(requests[_requestId].weekNumber, _randomWords);
    }

    /// @notice Update the week information related with timestamp
    /// @param _weekNumber Number of the week
    /// @param _startTimeStamp The start time of the event
    /// @param _prizeUpdationDuration Duration to update the prize in pool
    /// @param _winnerUpdationDuration Duration to update winner in merkle root
    /// @param _weeklyDuration How long the event will be held within a week
    function updateWeeklyTimeStamp(
        uint256 _weekNumber,
        uint256 _startTimeStamp,
        uint256 _prizeUpdationDuration,
        uint256 _winnerUpdationDuration,
        uint256 _weeklyDuration
    ) external onlyAdmin(msg.sender) validWeekNumber(_weekNumber) {
        if (_weeklyDuration <= (_prizeUpdationDuration + _winnerUpdationDuration)) {
            revert InvalidDuration();
        }
        if (_weekNumber != 1 && _startTimeStamp <= weekInfos[_weekNumber - 1].endTimeStamp) {
            revert InvalidTimeStamp();
        }
        if (_weekNumber != totalWeek && _startTimeStamp + _weeklyDuration - 1 >= weekInfos[_weekNumber + 1].startTimeStamp) {
            revert InvalidTimeStamp();
        }

        weekInfos[_weekNumber].startTimeStamp = _startTimeStamp;
        weekInfos[_weekNumber].ticketDrawTimeStamp = _startTimeStamp + _prizeUpdationDuration;
        weekInfos[_weekNumber].claimStartTimeStamp = _startTimeStamp + _prizeUpdationDuration + _winnerUpdationDuration;
        weekInfos[_weekNumber].endTimeStamp = _startTimeStamp + _weeklyDuration - 1;
    }

    /// @notice Set the week information related with timestamp
    /// @param _numberOfWeeks How many weeks the event will be held
    /// @param _startTimeStamp The start time of the event
    /// @param _prizeUpdationDuration Duration to update the prize in pool
    /// @param _winnerUpdationDuration Duration to update winner in merkle root
    /// @param _weeklyDuration How long the event will be held within a week
    function setWeeklyTimeStamp(
        uint256 _numberOfWeeks,
        uint256 _startTimeStamp,
        uint256 _prizeUpdationDuration,
        uint256 _winnerUpdationDuration,
        uint256 _weeklyDuration
    ) external onlyAdmin(msg.sender) {
        if (_weeklyDuration <= (_prizeUpdationDuration + _winnerUpdationDuration)) {
            revert InvalidDuration();
        }
        for (uint256 index = 0; index < _numberOfWeeks; index++) {
            totalWeek++;
            weekInfos[totalWeek].startTimeStamp = _startTimeStamp;
            weekInfos[totalWeek].ticketDrawTimeStamp = _startTimeStamp + _prizeUpdationDuration;
            weekInfos[totalWeek].claimStartTimeStamp = _startTimeStamp + _prizeUpdationDuration + _winnerUpdationDuration;
            weekInfos[totalWeek].endTimeStamp = _startTimeStamp + _weeklyDuration - 1;
            _startTimeStamp += _weeklyDuration;
        }
    }

    /// @notice Get week informations for specific week
    /// @param _weekNumber The number of the week
    /// @return week Information for specific week
    function getWeekInfo(uint256 _weekNumber) external view returns (WeekData memory week) {
        week.startTimeStamp = weekInfos[_weekNumber].startTimeStamp;
        week.ticketDrawTimeStamp = weekInfos[_weekNumber].ticketDrawTimeStamp;
        week.claimStartTimeStamp = weekInfos[_weekNumber].claimStartTimeStamp;
        week.endTimeStamp = weekInfos[_weekNumber].endTimeStamp;
        week.remainingSupply = weekInfos[_weekNumber].remainingSupply;
        week.treasureCount = weekInfos[_weekNumber].treasureCount;
        week.sponsoredTripsCount = weekInfos[_weekNumber].sponsoredTripsCount;
        week.randomNumbers = weekInfos[_weekNumber].randomNumbers;
        week.tripWinners = weekInfos[_weekNumber].tripWinners;
        week.availabletripsCount = weekInfos[_weekNumber].availabletripsCount;
    }

    function getWeeklyClaimedCount(uint256 _weekNumber, address _walletAddress ) external view returns (uint8 count) {
        return weekInfos[_weekNumber].winners[_walletAddress].claimed;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPxTrainerAdventureSignature {

    /// @notice Recovers signer wallet from signature
    /// @dev View function for signature recovering
    /// @param weekNumber Week number for claim
    /// @param claimIndex Claim index for a perticular user for a week
    /// @param walletAddress Token owner wallet address
    /// @param signature Signature from signer wallet
    function recoverSignerFromSignature(
        uint256 weekNumber,
        uint256 claimIndex,
        address walletAddress,
        bytes calldata signature
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

contract Utils {
    modifier noContracts() {
        uint256 size;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }
        require(msg.sender == tx.origin, "tx.origin != msg.sender");
        require(size == 0, "Contract calls are not allowed");
        _;
    }

    function _uncheckedInc(uint256 value) internal pure returns (uint256) {
        unchecked {
            return value + 1;
        }
    }

    function getRandomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number
                )
            )
        );

        return randomNumber;
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}