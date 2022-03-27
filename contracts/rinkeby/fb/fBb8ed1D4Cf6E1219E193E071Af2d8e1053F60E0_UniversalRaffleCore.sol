// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Adapted from Universe Auction House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRoyaltiesProvider.sol";
import "./lib/LibPart.sol";
import "./UniversalRaffleSchema.sol";

library UniversalRaffleCore {
    using SafeMath for uint256;

    bytes32 constant STORAGE_POSITION = keccak256("com.universe.raffle.storage");

    function raffleStorage() internal pure returns (UniversalRaffleSchema.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
        ds.slot := position
        }
    }

    modifier onlyRaffleSetup(uint256 raffleId) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        require(raffleId > 0 &&
                raffleId <= ds.totalRaffles &&
                ds.raffleConfigs[raffleId].startTime > block.timestamp &&
                !ds.raffles[raffleId].isCanceled, "E01");
        _;
    }

    modifier onlyDAO() {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        require(msg.sender == ds.daoAddress, "E07");
        _;
    }

    function transferDAOownership(address payable _daoAddress) external onlyDAO {
        UniversalRaffleSchema.Storage storage ds = UniversalRaffleCore.raffleStorage();
        ds.daoAddress = _daoAddress;
        ds.daoInitialized = true;
    }

    function configureRaffle(UniversalRaffleSchema.RaffleConfig calldata config, uint256 existingRaffleId) external returns (uint256) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        uint256 currentTime = block.timestamp;

        require(currentTime < config.startTime && config.startTime < config.endTime, 'Out of time configuration');
        require(config.totalSlots > 0 && config.totalSlots <= ds.maxNumberOfSlotsPerRaffle, 'Incorrect slots');
        require(config.ERC20PurchaseToken == address(0) || ds.supportedERC20Tokens[config.ERC20PurchaseToken], 'Token not allowed');
        require(config.minTicketCount > 1 && config.maxTicketCount >= config.minTicketCount,"Wrong ticket count");

        uint256 raffleId;
        if (existingRaffleId > 0) {
            raffleId = existingRaffleId;
            require(ds.raffleConfigs[raffleId].raffler == msg.sender && ds.raffleConfigs[raffleId].startTime > currentTime, "No permission");
            emit UniversalRaffleSchema.LogRaffleEdited(raffleId, msg.sender, config.raffleName);
        } else {
            ds.totalRaffles = ds.totalRaffles + 1;
            raffleId = ds.totalRaffles;

            ds.raffleConfigs[raffleId].raffler = msg.sender;
            ds.raffleConfigs[raffleId].totalSlots = config.totalSlots;

            emit UniversalRaffleSchema.LogRaffleCreated(raffleId, msg.sender, config.raffleName);
        }

        ds.raffleConfigs[raffleId].ERC20PurchaseToken = config.ERC20PurchaseToken;
        ds.raffleConfigs[raffleId].startTime = config.startTime;
        ds.raffleConfigs[raffleId].endTime = config.endTime;
        ds.raffleConfigs[raffleId].maxTicketCount = config.maxTicketCount;
        ds.raffleConfigs[raffleId].minTicketCount = config.minTicketCount;
        ds.raffleConfigs[raffleId].ticketPrice = config.ticketPrice;
        ds.raffleConfigs[raffleId].raffleName = config.raffleName;
        ds.raffleConfigs[raffleId].ticketColorOne = config.ticketColorOne;
        ds.raffleConfigs[raffleId].ticketColorTwo = config.ticketColorTwo;

        uint256 checkSum = 0;
        delete ds.raffleConfigs[raffleId].paymentSplits;
        for (uint256 k; k < config.paymentSplits.length;) {
            require(config.paymentSplits[k].recipient != address(0) && config.paymentSplits[k].value != 0, "Bad splits data");
            checkSum += config.paymentSplits[k].value;
            ds.raffleConfigs[raffleId].paymentSplits.push(config.paymentSplits[k]);
            unchecked { k++; }
        }
        require(checkSum < 10000, "Splits should be less than 100%");

        return raffleId;
    }

    function depositNFTsToRaffle(
        uint256 raffleId,
        uint256[] calldata slotIndices,
        UniversalRaffleSchema.NFT[][] calldata tokens
    ) external onlyRaffleSetup(raffleId) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        UniversalRaffleSchema.RaffleConfig storage raffle = ds.raffleConfigs[raffleId];

        require(
            slotIndices.length <= raffle.totalSlots &&
                slotIndices.length <= 10 &&
                slotIndices.length == tokens.length,
            "Incorrect slots"
        );

        for (uint256 i; i < slotIndices.length;) {
            require(tokens[i].length <= 5, "E17");
            depositERC721(raffleId, slotIndices[i], tokens[i]);
            unchecked { i++; }
        }
    }

    function depositERC721(
        uint256 raffleId,
        uint256 slotIndex,
        UniversalRaffleSchema.NFT[] calldata tokens
    ) internal returns (uint256[] memory) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        UniversalRaffleSchema.Raffle storage raffle = ds.raffles[raffleId];
        UniversalRaffleSchema.RaffleConfig storage raffleConfig = ds.raffleConfigs[raffleId];

        require(msg.sender == raffleConfig.raffler || raffle.depositors[msg.sender], 'No permission');
        require(raffleConfig.totalSlots >= slotIndex && slotIndex > 0, 'Incorrect slots');
        require(tokens.length <= 40 && raffle.slots[slotIndex].depositedNFTCounter + tokens.length <= ds.nftSlotLimit, "Too many NFTs");

        // Ensure previous slot has depoited NFTs, so there is no case where there is an empty slot between non-empty slots
        if (slotIndex > 1) require(raffle.slots[slotIndex - 1].depositedNFTCounter > 0, "Previous slot empty");

        uint256 nftSlotIndex = raffle.slots[slotIndex].depositedNFTCounter;
        raffle.slots[slotIndex].depositedNFTCounter += uint16(tokens.length);
        raffle.depositedNFTCounter += uint16(tokens.length);
        uint256[] memory nftSlotIndexes = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length;) {
            nftSlotIndex++;
            nftSlotIndexes[i] = nftSlotIndex;
            _depositERC721(
                raffleId,
                slotIndex,
                nftSlotIndex,
                tokens[i].tokenId,
                tokens[i].tokenAddress
            );
            unchecked { i++; }
        }

        return nftSlotIndexes;
    }

    function _depositERC721(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex,
        uint256 tokenId,
        address tokenAddress
    ) internal returns (uint256) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();

        (LibPart.Part[] memory nftRoyalties,) = ds.royaltiesRegistry.getRoyalties(tokenAddress, tokenId);

        address[] memory feesAddress = new address[](nftRoyalties.length);
        uint96[] memory feesValue = new uint96[](nftRoyalties.length);
        for (uint256 i; i < nftRoyalties.length && i < 5;) {
            feesAddress[i] = nftRoyalties[i].account;
            feesValue[i] = nftRoyalties[i].value;
            unchecked { i++; }
        }

        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        ds.raffles[raffleId].slots[slotIndex].depositedNFTs[nftSlotIndex] = UniversalRaffleSchema.DepositedNFT({
            tokenId: tokenId,
            tokenAddress: tokenAddress,
            depositor: msg.sender,
            hasSecondarySaleFees: nftRoyalties.length > 0,
            feesPaid: false,
            feesAddress: feesAddress,
            feesValue: feesValue
        });

        emit UniversalRaffleSchema.LogERC721Deposit(
            msg.sender,
            tokenAddress,
            tokenId,
            raffleId,
            slotIndex,
            nftSlotIndex
        );

        return nftSlotIndex;
    }

    function withdrawDepositedERC721(
        uint256 raffleId,
        UniversalRaffleSchema.SlotIndexAndNFTIndex[] calldata slotNftIndexes
    ) external {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        UniversalRaffleSchema.Raffle storage raffle = ds.raffles[raffleId];

        require(raffleId > 0 && raffleId <= ds.totalRaffles, 'Does not exist');
        require(ds.raffles[raffleId].isCanceled, "Raffle must be canceled");

        raffle.withdrawnNFTCounter += uint16(slotNftIndexes.length);
        raffle.depositedNFTCounter -= uint16(slotNftIndexes.length);
        for (uint256 i; i < slotNftIndexes.length;) {
            ds.raffles[raffleId].slots[slotNftIndexes[i].slotIndex].withdrawnNFTCounter += 1;
            _withdrawDepositedERC721(
                raffleId,
                slotNftIndexes[i].slotIndex,
                slotNftIndexes[i].NFTIndex
            );
            unchecked { i++; }
        }
    }

    function _withdrawDepositedERC721(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) internal {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        UniversalRaffleSchema.DepositedNFT memory nftForWithdrawal = ds.raffles[raffleId].slots[slotIndex].depositedNFTs[
            nftSlotIndex
        ];

        require(msg.sender == nftForWithdrawal.depositor, "No permission");
        delete ds.raffles[raffleId].slots[slotIndex].depositedNFTs[nftSlotIndex];

        emit UniversalRaffleSchema.LogERC721Withdrawal(
            msg.sender,
            nftForWithdrawal.tokenAddress,
            nftForWithdrawal.tokenId,
            raffleId,
            slotIndex,
            nftSlotIndex
        );

        IERC721(nftForWithdrawal.tokenAddress).safeTransferFrom(
            address(this),
            nftForWithdrawal.depositor,
            nftForWithdrawal.tokenId
        );
    }

    function claimERC721Rewards(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 amount
    ) external {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();

        UniversalRaffleSchema.Raffle storage raffle = ds.raffles[raffleId];
        UniversalRaffleSchema.Slot storage winningSlot = raffle.slots[slotIndex];

        uint256 totalWithdrawn = winningSlot.withdrawnNFTCounter;

        require(raffle.isFinalized, 'Must finalize raffle');
        require(winningSlot.winner == msg.sender, 'No permission');
        require(amount <= 40 && amount <= winningSlot.depositedNFTCounter - totalWithdrawn, "Too many NFTs");

        emit UniversalRaffleSchema.LogERC721RewardsClaim(msg.sender, raffleId, slotIndex, amount);

        raffle.withdrawnNFTCounter += uint16(amount);
        raffle.slots[slotIndex].withdrawnNFTCounter += uint16(amount);
        for (uint256 i = totalWithdrawn; i < amount + totalWithdrawn;) {
            UniversalRaffleSchema.DepositedNFT memory nftForWithdrawal = winningSlot.depositedNFTs[i + 1];

            IERC721(nftForWithdrawal.tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                nftForWithdrawal.tokenId
            );

            unchecked { i++; }
        }
    }

    function setRaffleConfigValue(uint256 configType, uint256 _value) external onlyDAO returns (uint256) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();

        if (configType == 0) ds.maxNumberOfSlotsPerRaffle = uint32(_value);
        else if (configType == 1) ds.maxBulkPurchaseCount = uint32(_value);
        else if (configType == 2) ds.nftSlotLimit = uint32(_value);
        else if (configType == 3) ds.royaltyFeeBps = uint32(_value);

        return _value;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider _royaltiesRegistry) external onlyDAO returns (IRoyaltiesProvider) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        ds.royaltiesRegistry = _royaltiesRegistry;
        return ds.royaltiesRegistry;
    }

    function setSupportedERC20Tokens(address erc20token, bool value) external onlyDAO returns (address, bool) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        ds.supportedERC20Tokens[erc20token] = value;
        return (erc20token, value);
    }

    function getRaffleState(uint256 raffleId) external view returns (UniversalRaffleSchema.RaffleConfig memory, UniversalRaffleSchema.RaffleState memory)
    {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        return (ds.raffleConfigs[raffleId], UniversalRaffleSchema.RaffleState(
            ds.raffles[raffleId].ticketCounter,
            ds.raffles[raffleId].depositedNFTCounter,
            ds.raffles[raffleId].withdrawnNFTCounter,
            ds.raffles[raffleId].useAllowList,
            ds.raffles[raffleId].isSetup,
            ds.raffles[raffleId].isCanceled,
            ds.raffles[raffleId].isFinalized,
            ds.raffles[raffleId].revenuePaid
        ));
    }

    function getRaffleFinalize(uint256 raffleId) external view returns (bool, uint256, uint256) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        return (ds.raffles[raffleId].isFinalized, ds.raffleConfigs[raffleId].totalSlots, ds.raffles[raffleId].ticketCounter);
    }

    function getDepositorList(uint256 raffleId, address participant) external view returns (bool) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        return ds.raffles[raffleId].depositors[participant];
    }

    function getAllowList(uint256 raffleId, address participant) external view returns (uint256) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        return ds.raffles[raffleId].allowList[participant];
    }

    function getDepositedNftsInSlot(uint256 raffleId, uint256 slotIndex) external view returns (UniversalRaffleSchema.DepositedNFT[] memory) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        uint256 nftsInSlot = ds.raffles[raffleId].slots[slotIndex].depositedNFTCounter;

        UniversalRaffleSchema.DepositedNFT[] memory nfts = new UniversalRaffleSchema.DepositedNFT[](nftsInSlot);

        for (uint256 i; i < nftsInSlot;) {
            nfts[i] = ds.raffles[raffleId].slots[slotIndex].depositedNFTs[i + 1];
            unchecked { i++; }
        }
        return nfts;
    }

    function getSlotInfo(uint256 raffleId, uint256 slotIndex) external view returns (UniversalRaffleSchema.SlotInfo memory) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();
        UniversalRaffleSchema.Slot storage slot = ds.raffles[raffleId].slots[slotIndex];
        UniversalRaffleSchema.SlotInfo memory slotInfo = UniversalRaffleSchema.SlotInfo(
            slot.depositedNFTCounter,
            slot.withdrawnNFTCounter,
            slot.winner,
            slot.winnerId
        );
        return slotInfo;
    }

    function getContractConfig() external view returns (UniversalRaffleSchema.ContractConfigByDAO memory) {
        UniversalRaffleSchema.Storage storage ds = raffleStorage();

        return UniversalRaffleSchema.ContractConfigByDAO(
            ds.daoAddress,
            ds.raffleTicketAddress,
            ds.vrfAddress,
            ds.totalRaffles,
            ds.maxNumberOfSlotsPerRaffle,
            ds.maxBulkPurchaseCount,
            ds.nftSlotLimit,
            ds.royaltyFeeBps,
            ds.daoInitialized
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../lib/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory, LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Adapted from Universe Auction House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

import "./interfaces/IRoyaltiesProvider.sol";

library UniversalRaffleSchema {
    struct RaffleConfig {
        address raffler;
        address ERC20PurchaseToken;
        uint64 startTime;
        uint64 endTime;
        uint32 maxTicketCount;
        uint32 minTicketCount;
        uint32 totalSlots;
        uint256 ticketPrice;
        string raffleName;
        string ticketColorOne;
        string ticketColorTwo;
        PaymentSplit[] paymentSplits;
    }

    struct Raffle {
        uint32 ticketCounter;
        uint16 depositedNFTCounter;
        uint16 withdrawnNFTCounter;
        uint16 depositorCount;
        mapping(uint256 => Slot) slots;
        mapping(uint256 => bool) refunds;
        mapping(address => uint256) allowList;
        mapping(address => bool) depositors;
        bool useAllowList;
        bool isSetup;
        bool isCanceled;
        bool isFinalized;
        bool revenuePaid;
    }

    struct RaffleState {
        uint32 ticketCounter;
        uint16 depositedNFTCounter;
        uint16 withdrawnNFTCounter;
        bool useAllowList;
        bool isSetup;
        bool isCanceled;
        bool isFinalized;
        bool revenuePaid;
    }

    struct Slot {
        uint16 depositedNFTCounter;
        uint16 withdrawnNFTCounter;
        address winner;
        uint256 winnerId;
        mapping(uint256 => DepositedNFT) depositedNFTs;
    }

    struct SlotInfo {
        uint16 depositedNFTCounter;
        uint16 withdrawnNFTCounter;
        address winner;
        uint256 winnerId;
    }

    struct SlotIndexAndNFTIndex {
        uint16 slotIndex;
        uint16 NFTIndex;
    }

    struct NFT {
        uint256 tokenId;
        address tokenAddress;
    }

    struct DepositedNFT {
        address tokenAddress;
        uint256 tokenId;
        address depositor;
        bool hasSecondarySaleFees;
        bool feesPaid;
        address[] feesAddress;
        uint96[] feesValue;
    }

    struct PaymentSplit {
        address payable recipient;
        uint96 value;
    }

    struct AllowList {
        address participant;
        uint32 allocation;
    }

    struct ContractConfigByDAO {
        address daoAddress;
        address raffleTicketAddress;
        address vrfAddress;
        uint32 totalRaffles;
        uint32 maxNumberOfSlotsPerRaffle;
        uint32 maxBulkPurchaseCount;
        uint32 nftSlotLimit;
        uint32 royaltyFeeBps;
        bool daoInitialized;
    }

    struct Storage {
        bool unsafeVRFtesting;
        address vrfAddress;
        address raffleTicketAddress;

        address payable daoAddress;
        bool daoInitialized;

        // DAO Configurable Settings
        uint32 maxNumberOfSlotsPerRaffle;
        uint32 maxBulkPurchaseCount;
        uint32 royaltyFeeBps;
        uint32 nftSlotLimit;
        IRoyaltiesProvider royaltiesRegistry;
        mapping(address => bool) supportedERC20Tokens;

        // Raffle state and data storage
        uint32 totalRaffles;
        mapping(uint256 => RaffleConfig) raffleConfigs;
        mapping(uint256 => Raffle) raffles;
        mapping(uint256 => uint256) raffleRevenue;
        mapping(uint256 => uint256) rafflesDAOPool;
        mapping(uint256 => uint256) rafflesRoyaltyPool;
        mapping(address => uint256) royaltiesReserve;
    }


    event LogERC721Deposit(
        address indexed depositor,
        address tokenAddress,
        uint256 tokenId,
        uint256 indexed raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    );

    event LogERC721Withdrawal(
        address indexed depositor,
        address tokenAddress,
        uint256 tokenId,
        uint256 indexed raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    );

    event LogRaffleCreated(
        uint256 indexed raffleId,
        address indexed raffleOwner,
        string raffleName
    );

    event LogRaffleEdited(
        uint256 indexed raffleId,
        address indexed raffleOwner,
        string raffleName
    );

    event LogRaffleTicketsPurchased(
        address indexed purchaser,
        uint256 amount,
        uint256 indexed raffleId
    );

    event LogRaffleTicketsRefunded(
        address indexed purchaser,
        uint256 indexed raffleId
    );

    event LogERC721RewardsClaim(address indexed claimer, uint256 indexed raffleId, uint256 slotIndex, uint256 amount);

    event LogRaffleCanceled(uint256 indexed raffleId);

    event LogRaffleRevenueWithdrawal(address indexed recipient, uint256 indexed raffleId, uint256 amount);

    event LogRaffleSecondaryFeesPayout(uint256 indexed raffleId, uint256 slotIndex, uint256 nftSlotIndex);

    event LogRoyaltiesWithdrawal(address indexed token, uint256 amount, address to);

    event LogRaffleFinalized(uint256 indexed raffleId);

    event LogWinnersFinalized(uint256 indexed raffleId);
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