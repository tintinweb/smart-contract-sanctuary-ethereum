// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Forked from Universe Auction House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRoyaltiesProvider.sol";
import "./lib/LibPart.sol";

library UniversalRaffleCore {
    using SafeMath for uint256;

    bytes32 constant STORAGE_POSITION = keccak256("com.universe.raffle.storage");

    struct RaffleConfig {
        address raffler;
        address ERC20PurchaseToken;
        uint256 startTime;
        uint256 endTime;
        uint256 maxTicketCount;
        uint256 minTicketCount;
        uint256 ticketPrice;
        uint32 totalSlots;
        string raffleName;
        string raffleImageURL;
        PaymentSplit[] paymentSplits;
    }

    struct Raffle {
        uint256 ticketCounter;
        uint256 depositedNFTCounter;
        uint256 withdrawnNFTCounter;
        uint256 depositorCount;
        mapping(uint256 => Slot) slots;
        mapping(uint256 => bool) refunds;
        mapping(address => uint256) allowList;
        mapping(address => bool) depositors;
        bool useAllowList;
        bool isCanceled;
        bool isFinalized;
        bool revenuePaid;
    }

    struct RaffleState {
        uint256 ticketCounter;
        uint256 depositedNFTCounter;
        uint256 withdrawnNFTCounter;
        bool useAllowList;
        bool isCanceled;
        bool isFinalized;
        bool revenuePaid;
    }

    struct Slot {
        uint256 depositedNFTCounter;
        uint256 withdrawnNFTCounter;
        uint256 winnerId;
        address winner;
        mapping(uint256 => DepositedNFT) depositedNFTs;
    }

    struct SlotInfo {
        uint256 depositedNFTCounter;
        uint256 withdrawnNFTCounter;
        uint256 winnerId;
        address winner;
    }

    struct SlotIndexAndNFTIndex {
        uint256 slotIndex;
        uint256 NFTIndex;
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
        uint256 value;
    }

    struct AllowList {
        address participant;
        uint32 allocation;
    }

    struct ContractConfigByDAO {
        address daoAddress;
        address raffleTicketAddress;
        address vrfAddress;
        uint256 totalRaffles;
        uint256 maxNumberOfSlotsPerRaffle;
        uint256 maxBulkPurchaseCount;
        uint256 nftSlotLimit;
        uint256 royaltyFeeBps;
        bool daoInitialized;
        bool unsafeRandomNumber;
    }

    struct Storage {
        address vrfAddress;
        address raffleTicketAddress;

        address payable daoAddress;
        bool daoInitialized;
        bool unsafeRandomNumber; // Toggle used mainly for mocking VRF, cannot modify once deployed

        // DAO Configurable Settings
        uint256 maxNumberOfSlotsPerRaffle;
        uint256 maxBulkPurchaseCount;
        uint256 royaltyFeeBps;
        uint256 nftSlotLimit;
        IRoyaltiesProvider royaltiesRegistry;
        mapping(address => bool) supportedERC20Tokens;

        // Raffle state and data storage
        uint256 totalRaffles;
        mapping(uint256 => RaffleConfig) raffleConfigs;
        mapping(uint256 => Raffle) raffles;
        mapping(uint256 => uint256) raffleRevenue;
        mapping(uint256 => uint256) rafflesDAOPool;
        mapping(uint256 => uint256) rafflesRoyaltyPool;
        mapping(address => uint256) royaltiesReserve;
    }

    function raffleStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
        ds.slot := position
        }
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
        uint256 numberOfSlots,
        uint256 startTime,
        uint256 endTime,
        uint256 resetTimer
    );

    event LogBidMatched(
        uint256 indexed raffleId,
        uint256 slotIndex,
        uint256 slotReservePrice,
        uint256 winningBidAmount,
        address winner
    );

    event LogSlotRevenueCaptured(
        uint256 indexed raffleId,
        uint256 slotIndex,
        uint256 amount,
        address ERC20PurchaseToken
    );

    event LogBidSubmitted(address indexed sender, uint256 indexed raffleId, uint256 currentBid, uint256 totalBid);

    event LogBidWithdrawal(address indexed recipient, uint256 indexed raffleId, uint256 amount);

    event LogRaffleExtended(uint256 indexed raffleId, uint256 endTime);

    event LogRaffleCanceled(uint256 indexed raffleId);

    event LogRaffleRevenueWithdrawal(address indexed recipient, uint256 indexed raffleId, uint256 amount);

    event LogERC721RewardsClaim(address indexed claimer, uint256 indexed raffleId, uint256 slotIndex);

    event LogRoyaltiesWithdrawal(uint256 amount, address to, address token);

    event LogRaffleFinalized(uint256 indexed raffleId);

    modifier onlyRaffleSetupOwner(uint256 raffleId) {
        Storage storage ds = raffleStorage();
        require(raffleId > 0 &&
                raffleId <= ds.totalRaffles &&
                ds.raffleConfigs[raffleId].startTime > block.timestamp &&
                !ds.raffles[raffleId].isCanceled &&
                ds.raffleConfigs[raffleId].raffler == msg.sender, "E01");
        _;
    }

    modifier onlyRaffleSetup(uint256 raffleId) {
        Storage storage ds = raffleStorage();
        require(raffleId > 0 &&
                raffleId <= ds.totalRaffles &&
                ds.raffleConfigs[raffleId].startTime > block.timestamp &&
                !ds.raffles[raffleId].isCanceled, "E01");
        _;
    }

    modifier onlyDAO() {
        Storage storage ds = raffleStorage();
        require(msg.sender == ds.daoAddress, "E07");
        _;
    }

    function configureRaffle(RaffleConfig calldata config, uint256 existingRaffleId) external returns (uint256) {
        Storage storage ds = raffleStorage();
        uint256 currentTime = block.timestamp;

        require(
            currentTime < config.startTime &&
            config.startTime < config.endTime &&
            config.totalSlots > 0 && config.totalSlots <= ds.maxNumberOfSlotsPerRaffle &&
            config.ERC20PurchaseToken == address(0) || ds.supportedERC20Tokens[config.ERC20PurchaseToken] &&
            config.minTicketCount > 1 && config.maxTicketCount >= config.minTicketCount,
            "Wrong configuration"
        );

        uint256 raffleId;
        if (existingRaffleId > 0) {
            raffleId = existingRaffleId;
            require(ds.raffleConfigs[raffleId].raffler == msg.sender && ds.raffleConfigs[raffleId].startTime > currentTime, "No permission");
        } else {
            ds.totalRaffles = ds.totalRaffles + 1;
            raffleId = ds.totalRaffles;

            ds.raffleConfigs[raffleId].raffler = msg.sender;
            ds.raffleConfigs[raffleId].totalSlots = config.totalSlots;
        }

        ds.raffleConfigs[raffleId].ERC20PurchaseToken = config.ERC20PurchaseToken;
        ds.raffleConfigs[raffleId].startTime = config.startTime;
        ds.raffleConfigs[raffleId].endTime = config.endTime;
        ds.raffleConfigs[raffleId].maxTicketCount = config.maxTicketCount;
        ds.raffleConfigs[raffleId].minTicketCount = config.minTicketCount;
        ds.raffleConfigs[raffleId].ticketPrice = config.ticketPrice;
        ds.raffleConfigs[raffleId].raffleName = config.raffleName;
        ds.raffleConfigs[raffleId].raffleImageURL = config.raffleImageURL;

        uint256 checkSum = 0;
        delete ds.raffleConfigs[raffleId].paymentSplits;
        for (uint256 k; k < config.paymentSplits.length;) {
            require(config.paymentSplits[k].recipient != address(0) && config.paymentSplits[k].value != 0, "Bad data");
            checkSum += config.paymentSplits[k].value;
            ds.raffleConfigs[raffleId].paymentSplits.push(config.paymentSplits[k]);
            unchecked { k++; }
        }
        require(checkSum < 10000, "E15");

        return raffleId;
    }

    function setDepositors(uint256 raffleId, AllowList[] calldata allowList) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];

        for (uint256 i; i < allowList.length;) {
            raffle.depositors[allowList[i].participant] = allowList[i].allocation == 1 ? true : false;
            unchecked { i++; }
        }
    }

    function setAllowList(uint256 raffleId, AllowList[] calldata allowList) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];

        require(allowList.length <= 1000, 'Max 1000 per');
        for (uint256 i; i < allowList.length;) {
            raffle.allowList[allowList[i].participant] = allowList[i].allocation;
            unchecked { i++; }
        }
    }

    function toggleAllowList(uint256 raffleId) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];
        raffle.useAllowList = !raffle.useAllowList;
    }

    function depositNFTsToRaffle(
        uint256 raffleId,
        uint256[] calldata slotIndices,
        NFT[][] calldata tokens
    ) external onlyRaffleSetup(raffleId) {
        Storage storage ds = raffleStorage();
        RaffleConfig storage raffle = ds.raffleConfigs[raffleId];

        require(
            slotIndices.length <= raffle.totalSlots &&
                slotIndices.length <= 10 &&
                slotIndices.length == tokens.length,
            "E16"
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
        NFT[] calldata tokens
    ) internal returns (uint256[] memory) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];
        RaffleConfig storage raffleConfig = ds.raffleConfigs[raffleId];

        require(
            (msg.sender == raffleConfig.raffler || raffle.depositors[msg.sender]) &&
            raffleConfig.totalSlots >= slotIndex && slotIndex > 0 && (tokens.length <= 40) &&
            (raffle.slots[slotIndex].depositedNFTCounter + tokens.length <= ds.nftSlotLimit)
        , "E36");

        // Ensure previous slot has depoited NFTs, so there is no case where there is an empty slot between non-empty slots
        if (slotIndex > 1) require(raffle.slots[slotIndex - 1].depositedNFTCounter > 0, "E39");

        uint256 nftSlotIndex = raffle.slots[slotIndex].depositedNFTCounter;
        raffle.slots[slotIndex].depositedNFTCounter += tokens.length;
        raffle.depositedNFTCounter += tokens.length;
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
        Storage storage ds = raffleStorage();

        (LibPart.Part[] memory nftRoyalties,) = ds.royaltiesRegistry.getRoyalties(tokenAddress, tokenId);

        address[] memory feesAddress = new address[](nftRoyalties.length);
        uint96[] memory feesValue = new uint96[](nftRoyalties.length);
        for (uint256 i; i < nftRoyalties.length && i < 5;) {
            feesAddress[i] = nftRoyalties[i].account;
            feesValue[i] = nftRoyalties[i].value;
            unchecked { i++; }
        }

        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        ds.raffles[raffleId].slots[slotIndex].depositedNFTs[nftSlotIndex] = DepositedNFT({
            tokenId: tokenId,
            tokenAddress: tokenAddress,
            depositor: msg.sender,
            hasSecondarySaleFees: nftRoyalties.length > 0,
            feesPaid: false,
            feesAddress: feesAddress,
            feesValue: feesValue
        });

        emit LogERC721Deposit(
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
        SlotIndexAndNFTIndex[] calldata slotNftIndexes
    ) external {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];

        require(raffleId > 0 && raffleId <= ds.totalRaffles && ds.raffles[raffleId].isCanceled, "E01");

        raffle.withdrawnNFTCounter += slotNftIndexes.length;
        raffle.depositedNFTCounter -= slotNftIndexes.length;
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
        Storage storage ds = raffleStorage();
        DepositedNFT memory nftForWithdrawal = ds.raffles[raffleId].slots[slotIndex].depositedNFTs[
            nftSlotIndex
        ];

        require(msg.sender == nftForWithdrawal.depositor, "E41");
        delete ds.raffles[raffleId].slots[slotIndex].depositedNFTs[nftSlotIndex];

        emit LogERC721Withdrawal(
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

    function buyRaffleTicketsChecks(uint256 raffleId, uint256 amount) external {
        Storage storage ds = raffleStorage();
        RaffleConfig storage raffleInfo = ds.raffleConfigs[raffleId];
        Raffle storage raffle = ds.raffles[raffleId];

        require(
            raffleId > 0 && raffleId <= ds.totalRaffles &&
            !raffle.isCanceled &&
            raffleInfo.startTime < block.timestamp && 
            block.timestamp < raffleInfo.endTime &&
            raffle.depositedNFTCounter > 0 &&
            amount > 0 && amount <= ds.maxBulkPurchaseCount, "Unavailable");
    }

    function claimERC721Rewards(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 amount
    ) external {
        Storage storage ds = raffleStorage();

        Raffle storage raffle = ds.raffles[raffleId];
        Slot storage winningSlot = raffle.slots[slotIndex];

        uint256 totalDeposited = winningSlot.depositedNFTCounter;
        uint256 totalWithdrawn = winningSlot.withdrawnNFTCounter;

        require(raffle.isFinalized &&
                winningSlot.winner == msg.sender &&
                amount <= 40 &&
                amount <= totalDeposited - totalWithdrawn, "E24");

        emit LogERC721RewardsClaim(msg.sender, raffleId, slotIndex);

        raffle.withdrawnNFTCounter += amount;
        raffle.slots[slotIndex].withdrawnNFTCounter = winningSlot.withdrawnNFTCounter += amount;
        for (uint256 i = totalWithdrawn; i < amount + totalWithdrawn;) {
            DepositedNFT memory nftForWithdrawal = winningSlot.depositedNFTs[i + 1];

            IERC721(nftForWithdrawal.tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                nftForWithdrawal.tokenId
            );

            unchecked { i++; }
        }
    }

    function cancelRaffle(uint256 raffleId) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();

        require(raffleId > 0 && raffleId <= ds.totalRaffles &&
                ds.raffleConfigs[raffleId].startTime > block.timestamp &&
                !ds.raffles[raffleId].isCanceled, "E01");

        ds.raffles[raffleId].isCanceled = true;

        emit LogRaffleCanceled(raffleId);
    }

    function calculatePaymentSplits(uint256 raffleId) external {
        Storage storage ds = UniversalRaffleCore.raffleStorage();
        RaffleConfig storage raffleInfo = ds.raffleConfigs[raffleId];
        Raffle storage raffle = ds.raffles[raffleId];

        uint256 raffleTotalRevenue = raffleInfo.ticketPrice * raffle.ticketCounter;
        uint256 averageERC721SalePrice = raffleTotalRevenue / raffle.depositedNFTCounter;
        uint256 totalRoyaltyFees = 0;

        for (uint256 i = 1; i <= raffleInfo.totalSlots;) {
            for (uint256 j = 1; j <= raffle.slots[i].depositedNFTCounter;) {
                UniversalRaffleCore.DepositedNFT storage nft = raffle.slots[i].depositedNFTs[j];

                if (nft.hasSecondarySaleFees) {
                    uint256 value = averageERC721SalePrice;

                    for (uint256 k; k < nft.feesAddress.length && k < 5;) {
                        uint256 fee = (averageERC721SalePrice * nft.feesValue[k]) / 10000;

                        if (value > fee) {
                            value = value.sub(fee);
                            totalRoyaltyFees = totalRoyaltyFees.add(fee);
                        }
                        unchecked { k++; }
                    }
                }
                unchecked { j++; }
            }
            unchecked { i++; }
        }

        // NFT Royalties Split
        ds.rafflesRoyaltyPool[raffleId] = totalRoyaltyFees;

        // DAO Royalties Split
        uint256 daoRoyalty = raffleTotalRevenue.sub(totalRoyaltyFees).mul(ds.royaltyFeeBps).div(10000);
        ds.rafflesDAOPool[raffleId] = daoRoyalty;
        ds.royaltiesReserve[raffleInfo.ERC20PurchaseToken] = ds.royaltiesReserve[raffleInfo.ERC20PurchaseToken].add(daoRoyalty);

        uint256 splitValue = 0;
        uint256 rafflerRevenue = raffleTotalRevenue.sub(totalRoyaltyFees).sub(daoRoyalty);

        for (uint256 i; i < raffleInfo.paymentSplits.length && i < 5;) {
            uint256 fee = (rafflerRevenue * raffleInfo.paymentSplits[i].value) / 10000;
            splitValue = splitValue.add(fee);
            unchecked { i++; }
        }

        // Revenue Split
        ds.raffleRevenue[raffleId] = raffleTotalRevenue.sub(totalRoyaltyFees).sub(splitValue).sub(daoRoyalty);
    }

    function setRaffleConfigValue(uint256 configType, uint256 _value) external onlyDAO returns (uint256) {
        Storage storage ds = raffleStorage();

        if (configType == 0) ds.maxNumberOfSlotsPerRaffle = _value;
        else if (configType == 1) ds.maxBulkPurchaseCount = _value;
        else if (configType == 2) ds.nftSlotLimit = _value;
        else if (configType == 3) ds.royaltyFeeBps = _value;

        return _value;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider _royaltiesRegistry) external onlyDAO returns (IRoyaltiesProvider) {
        Storage storage ds = raffleStorage();
        ds.royaltiesRegistry = _royaltiesRegistry;
        return ds.royaltiesRegistry;
    }

    function setSupportedERC20Tokens(address erc20token, bool value) external onlyDAO returns (address, bool) {
        Storage storage ds = raffleStorage();
        ds.supportedERC20Tokens[erc20token] = value;
        return (erc20token, value);
    }

    function getRaffleState(uint256 raffleId) external view returns (RaffleConfig memory, RaffleState memory)
    {
        Storage storage ds = raffleStorage();
        return (ds.raffleConfigs[raffleId], RaffleState(
            ds.raffles[raffleId].ticketCounter,
            ds.raffles[raffleId].depositedNFTCounter,
            ds.raffles[raffleId].withdrawnNFTCounter,
            ds.raffles[raffleId].useAllowList,
            ds.raffles[raffleId].isCanceled,
            ds.raffles[raffleId].isFinalized,
            ds.raffles[raffleId].revenuePaid
        ));
    }

    function getAllowList(uint256 raffleId, address participant) external view returns (uint256) {
        Storage storage ds = raffleStorage();
        return ds.raffles[raffleId].allowList[participant];
    }

    function getDepositedNftsInSlot(uint256 raffleId, uint256 slotIndex) external view returns (DepositedNFT[] memory) {
        Storage storage ds = raffleStorage();
        uint256 nftsInSlot = ds.raffles[raffleId].slots[slotIndex].depositedNFTCounter;

        DepositedNFT[] memory nfts = new DepositedNFT[](nftsInSlot);

        for (uint256 i; i < nftsInSlot;) {
            nfts[i] = ds.raffles[raffleId].slots[slotIndex].depositedNFTs[i + 1];
            unchecked { i++; }
        }
        return nfts;
    }

    function getSlotInfo(uint256 raffleId, uint256 slotIndex) external view returns (SlotInfo memory) {
        Storage storage ds = raffleStorage();
        Slot storage slot = ds.raffles[raffleId].slots[slotIndex];
        SlotInfo memory slotInfo = SlotInfo(
            slot.depositedNFTCounter,
            slot.withdrawnNFTCounter,
            slot.winnerId,
            slot.winner
        );
        return slotInfo;
    }

    function getContractConfig() external view returns (ContractConfigByDAO memory) {
        Storage storage ds = raffleStorage();

        return ContractConfigByDAO(
            ds.daoAddress,
            ds.raffleTicketAddress,
            ds.vrfAddress,
            ds.totalRaffles,
            ds.maxNumberOfSlotsPerRaffle,
            ds.maxBulkPurchaseCount,
            ds.nftSlotLimit,
            ds.royaltyFeeBps,
            ds.daoInitialized,
            ds.unsafeRandomNumber
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