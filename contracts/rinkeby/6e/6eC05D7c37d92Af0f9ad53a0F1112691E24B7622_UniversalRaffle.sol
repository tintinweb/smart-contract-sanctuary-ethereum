// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Forked from Universe Auction House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRaffleTickets.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/IUniversalRaffle.sol";
import "./interfaces/IRoyaltiesProvider.sol";
import "./lib/LibPart.sol";
import "./UniversalRaffleCore.sol";

contract UniversalRaffle is 
    IUniversalRaffle,
    ERC721Holder,
    ReentrancyGuard
{
    using SafeMath for uint256;

    constructor(
        bool _unsafeRandomNumber,
        uint256 _maxNumberOfSlotsPerRaffle,
        uint256 _maxBulkPurchaseCount,
        uint256 _nftSlotLimit,
        uint256 _royaltyFeeBps,
        address payable _daoAddress,
        address _raffleTicketAddress,
        address _vrfAddress,
        address[] memory _supportedERC20Tokens,
        IRoyaltiesProvider _royaltiesRegistry
    ) {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();

        ds.unsafeRandomNumber = _unsafeRandomNumber;
        ds.maxNumberOfSlotsPerRaffle = _maxNumberOfSlotsPerRaffle;
        ds.maxBulkPurchaseCount = _maxBulkPurchaseCount;
        ds.nftSlotLimit = _nftSlotLimit;
        ds.royaltyFeeBps = _royaltyFeeBps;
        ds.royaltiesRegistry = _royaltiesRegistry;
        ds.daoAddress = payable(msg.sender);
        ds.daoInitialized = false;
        for (uint256 i = 0; i < _supportedERC20Tokens.length; i++) {
            ds.supportedERC20Tokens[_supportedERC20Tokens[i]] = true;
        }

        ds.raffleTicketAddress = _raffleTicketAddress;
        ds.vrfAddress = _vrfAddress;
    }

    modifier onlyDAO() {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();
        require(msg.sender == ds.daoAddress, "E07");
        _;
    }

    function transferDAOownership(address payable _daoAddress) external onlyDAO {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();
        ds.daoAddress = _daoAddress;
        ds.daoInitialized = true;
    }

    function getRaffleData(uint256 raffleId) private returns (
        UniversalRaffleCore.Storage storage,
        UniversalRaffleCore.RaffleConfig storage,
        UniversalRaffleCore.Raffle storage
    ) {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();
        return (
            ds,
            ds.raffleConfigs[raffleId],
            ds.raffles[raffleId]
        );
    }

    function createRaffle(UniversalRaffleCore.RaffleConfig calldata config) external override returns (uint256) {
        return UniversalRaffleCore.configureRaffle(config, 0);
    }

    function reconfigureRaffle(UniversalRaffleCore.RaffleConfig calldata config, uint256 existingRaffleId) external override returns (uint256) {
        return UniversalRaffleCore.configureRaffle(config, existingRaffleId);
    }

    function setDepositors(uint256 raffleId, UniversalRaffleCore.AllowList[] calldata allowList) external override {
        return UniversalRaffleCore.setDepositors(raffleId, allowList);
    }

    function setAllowList(uint256 raffleId, UniversalRaffleCore.AllowList[] calldata allowList) external override {
        return UniversalRaffleCore.setAllowList(raffleId, allowList);
    }

    function toggleAllowList(uint256 raffleId) external override {
        return UniversalRaffleCore.toggleAllowList(raffleId);
    }

    function depositNFTsToRaffle(
        uint256 raffleId,
        uint256[] calldata slotIndices,
        UniversalRaffleCore.NFT[][] calldata tokens
    ) external override {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffle,
        ) = getRaffleData(raffleId);

        require(
            slotIndices.length <= raffle.totalSlots &&
                slotIndices.length <= 10 &&
                slotIndices.length == tokens.length,
            "E16"
        );

        for (uint256 i = 0; i < slotIndices.length; i += 1) {
            require(tokens[i].length <= 5, "E17");
            UniversalRaffleCore.depositERC721(raffleId, slotIndices[i], tokens[i]);
        }
    }

    function withdrawDepositedERC721(
        uint256 raffleId,
        uint256[][] calldata slotNftIndexes
    ) external override nonReentrant {
        UniversalRaffleCore.withdrawDepositedERC721(raffleId, slotNftIndexes);
    }

    function buyRaffleTickets(
        uint256 raffleId,
        uint256 amount
    ) external payable override nonReentrant {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffleInfo,
            UniversalRaffleCore.Raffle storage raffle
        ) = getRaffleData(raffleId);

        require(raffleId > 0 && raffleId <= ds.totalRaffles, "E01");
        require(
            !raffle.isCanceled &&
            raffleInfo.startTime < block.timestamp && 
            block.timestamp < raffleInfo.endTime &&
            raffle.depositedNFTCounter > 0, "Unavailable");
        require(amount > 0 && amount <= ds.maxBulkPurchaseCount, "Wrong amount");

        if (raffle.useAllowList) {
            require(raffle.allowList[msg.sender] >= amount);
            raffle.allowList[msg.sender] -= amount;
        }

        if (raffleInfo.ERC20PurchaseToken == address(0)) {
            require(msg.value >= amount.mul(raffleInfo.ticketPrice), "Insufficient value");
            uint256 excessAmount = msg.value.sub(amount.mul(raffleInfo.ticketPrice));
            if (excessAmount > 0) {
                (bool returnExcessStatus, ) = (msg.sender).call{value: excessAmount}("");
                require(returnExcessStatus, "Failed to return excess");
            }
        } else {
            IERC20 paymentToken = IERC20(raffleInfo.ERC20PurchaseToken);
            require(paymentToken.transferFrom(msg.sender, address(this), amount.mul(raffleInfo.ticketPrice)), "TX FAILED");
        }

        raffle.ticketCounter += amount;
        IRaffleTickets(ds.raffleTicketAddress).mint(msg.sender, amount, raffleId);
    }

    function finalizeRaffle(uint256 raffleId) external override nonReentrant {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffleInfo,
            UniversalRaffleCore.Raffle storage raffle
        ) = getRaffleData(raffleId);

        require(raffleId > 0 && raffleId <= ds.totalRaffles &&
                !raffle.isCanceled &&
                block.timestamp > raffleInfo.endTime && !raffle.isFinalized, "E01");

        if (raffle.ticketCounter < raffleInfo.minTicketCount) {
            UniversalRaffleCore.refundRaffle(raffleId);
        } else {
            if (ds.unsafeRandomNumber) IRandomNumberGenerator(ds.vrfAddress).getWinnersMock(raffleId); // Testing purposes only
            else IRandomNumberGenerator(ds.vrfAddress).getWinners(raffleId);
            UniversalRaffleCore.calculatePaymentSplits(raffleId);
        }
    }

    function setWinners(uint256 raffleId, address[] memory winners) external {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();
        require(msg.sender == ds.vrfAddress, "No permission");
        for (uint32 i = 1; i <= winners.length; i++) {
            ds.raffles[raffleId].winners[i] = winners[i - 1];
            ds.raffles[raffleId].slots[i].winner = winners[i - 1];
        }

        ds.raffles[raffleId].isFinalized = true;
    }

    function claimERC721Rewards(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 amount
    ) external override nonReentrant {
        UniversalRaffleCore.claimERC721Rewards(raffleId, slotIndex, amount);
    }

    function refundRaffleTickets(uint256 raffleId, uint256[] memory tokenIds)
        external
        override
        nonReentrant
    {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffleInfo,
            UniversalRaffleCore.Raffle storage raffle
        ) = getRaffleData(raffleId);

        require(raffle.isCanceled, "E04");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC721(ds.raffleTicketAddress).ownerOf(tokenIds[i]) == msg.sender);
            require(!raffle.refunds[tokenIds[i]], "Refund already issued");
            raffle.refunds[tokenIds[i]] = true;
        }

        uint256 amount = raffleInfo.ticketPrice.mul(tokenIds.length);
        sendPayments(raffleInfo.ERC20PurchaseToken, amount, payable(msg.sender));
    }

    function cancelRaffle(uint256 raffleId) external override {
        return UniversalRaffleCore.cancelRaffle(raffleId);
    }

    function distributeCapturedRaffleRevenue(uint256 raffleId)
        external
        override
        nonReentrant
    {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffleInfo,
            UniversalRaffleCore.Raffle storage raffle
        ) = getRaffleData(raffleId);

        require(raffleId > 0 && raffleId <= ds.totalRaffles && raffle.isFinalized, "E01");

        uint256 raffleRevenue = ds.raffleRevenue[raffleId];
        uint256 raffleTotalRevenue = raffleInfo.ticketPrice * raffle.ticketCounter;
        uint256 daoRoyalty = raffleTotalRevenue.sub(ds.rafflesRoyaltyPool[raffleId]).mul(ds.royaltyFeeBps).div(10000);
        uint256 remainder = raffleTotalRevenue.sub(ds.rafflesRoyaltyPool[raffleId]).sub(daoRoyalty);
        require(raffleRevenue > 0, "E30");

        ds.raffleRevenue[raffleId] = 0;

        uint256 value = remainder;
        uint256 paymentSplitsPaid;

        emit UniversalRaffleCore.LogRaffleRevenueWithdrawal(raffleInfo.raffler, raffleId, remainder);

        // Distribute the payment splits to the respective recipients
        for (uint256 i = 0; i < raffleInfo.paymentSplits.length && i < 5; i += 1) {
            uint256 fee = (remainder * raffleInfo.paymentSplits[i].value) / 10000;
            value -= fee;
            paymentSplitsPaid += fee;
            sendPayments(raffleInfo.ERC20PurchaseToken, fee, raffleInfo.paymentSplits[i].recipient);
        }

        // Distribute the remaining revenue to the raffler
        sendPayments(raffleInfo.ERC20PurchaseToken, raffleRevenue, raffleInfo.raffler);

        raffle.revenuePaid = true;
    }

    function distributeSecondarySaleFees(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) external override nonReentrant {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffleInfo,
            UniversalRaffleCore.Raffle storage raffle
        ) = getRaffleData(raffleId);

        UniversalRaffleCore.DepositedNFT storage nft = raffle.slots[slotIndex].depositedNFTs[nftSlotIndex];

        require(raffle.revenuePaid && nft.hasSecondarySaleFees && !nft.feesPaid, "E34");

        uint256 averageERC721SalePrice = raffleInfo.ticketPrice * raffle.ticketCounter / raffle.depositedNFTCounter;

        LibPart.Part[] memory fees = ds.royaltiesRegistry.getRoyalties(nft.tokenAddress, nft.tokenId);
        nft.feesPaid = true;

        for (uint256 i = 0; i < fees.length && i < 5; i += 1) {
            uint256 value = (averageERC721SalePrice * fees[i].value) / 10000;
            if (ds.rafflesRoyaltyPool[raffleId] >= value) {
                ds.rafflesRoyaltyPool[raffleId] = ds.rafflesRoyaltyPool[raffleId].sub(value);
                sendPayments(raffleInfo.ERC20PurchaseToken, value, fees[i].account);
            }
        }
    }

    function distributeRoyalties(address token) external nonReentrant returns (uint256) {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();

        uint256 amountToWithdraw = ds.royaltiesReserve[token];
        require(amountToWithdraw > 0, "E30");

        ds.royaltiesReserve[token] = 0;

        sendPayments(token, amountToWithdraw, ds.daoAddress);
        return amountToWithdraw;
    }

    function sendPayments(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0) && value > 0) {
            (bool success, ) = (to).call{value: value}("");
            require(success, "TX FAILED");
        }

        if (tokenAddress != address(0) && value > 0) {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(address(to), value), "TX FAILED");
        }
    }

    function setRaffleConfigValue(uint256 configType, uint256 _value) external override returns (uint256) {
        return UniversalRaffleCore.setRaffleConfigValue(configType, _value);
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider _royaltiesRegistry) external override returns (IRoyaltiesProvider) {
        return UniversalRaffleCore.setRoyaltiesRegistry(_royaltiesRegistry);
    }

    function setSupportedERC20Tokens(address erc20token, bool value) external override returns (address, bool) {
        return UniversalRaffleCore.setSupportedERC20Tokens(erc20token, value);
    }

    function getRaffleConfig(uint256 raffleId) external view override returns (UniversalRaffleCore.RaffleConfig memory) {
        return UniversalRaffleCore.getRaffleConfig(raffleId);
    }

    function getRaffleState(uint256 raffleId) external view override returns (UniversalRaffleCore.RaffleState memory) {
        return UniversalRaffleCore.getRaffleState(raffleId);
    }

    function getAllowList(uint256 raffleId, address participant) external view override returns (uint256) {
        return UniversalRaffleCore.getAllowList(raffleId, participant);
    }

    function getDepositedNftsInSlot(uint256 raffleId, uint256 slotIndex) external view override 
        returns (UniversalRaffleCore.DepositedNFT[] memory) {
        return UniversalRaffleCore.getDepositedNftsInSlot(raffleId, slotIndex);
    }

    function getSlotInfo(uint256 raffleId, uint256 slotIndex) external view override returns (UniversalRaffleCore.SlotInfo memory) {
        return UniversalRaffleCore.getSlotInfo(raffleId, slotIndex);
    }

    function getSlotWinner(uint256 raffleId, uint256 slotIndex) external view override returns (address) {
        return UniversalRaffleCore.getSlotWinner(raffleId, slotIndex);
    }

    function getContractConfig() external view override returns (UniversalRaffleCore.ContractConfigByDAO memory) {
        return UniversalRaffleCore.getContractConfig();
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// Written by Tim Kang <> illestrater
// Product by universe.xyz

pragma solidity 0.8.11;


interface IRaffleTickets {
  function initRaffleTickets(address _contractAddress) external;
  function mint(address to, uint256 amount, uint256 raffleId) external;
  function totalSupply() external view returns (uint256);
  function raffleTicketCounter(uint256 raffleId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Forked from Universe Auction House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

interface IRandomNumberGenerator {
    function initVRF(address _contractAddress) external;
    function getWinners(uint256 raffleId) external;
    function getWinnersMock(uint256 raffleId) external;
}

// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Forked from Universe Raffle House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

import "./IRoyaltiesProvider.sol";
import "../UniversalRaffleCore.sol";

/// @title Users buy raffle tickets in order to win deposited ERC721 tokens.
/// @notice This interface should be implemented by the NFTRaffle contract
/// @dev This interface should be implemented by the NFTRaffle contract
interface IUniversalRaffle {
  /// @notice Create a raffle with initial parameters
  /// @param config Raffle configuration
  /// @dev config.raffler Raffler creator (msg.sender)
  /// @dev config.ERC20PurchaseToken ERC20 token used to purchase raffle tickets
  /// @dev config.startTime The start of the raffle
  /// @dev config.endTime End of the raffle
  /// @dev config.maxTicketCount Maximum tickets allowed to be sold
  /// @dev config.minTicketCount Minimum tickets that must be sold for raffle to proceed
  /// @dev config.ticketPrice Price per raffle ticket
  /// @dev config.totalSlots The number of winner slots which the raffle will have
  /// @dev config.paymentSplits Array of payment splits which will be distributed after raffle ends
  function createRaffle(UniversalRaffleCore.RaffleConfig calldata config) external returns (uint256);

  /// @notice Change raffle configuration
  /// @param config Raffle configuration above
  /// @param existingRaffleId The raffle id
  function reconfigureRaffle(UniversalRaffleCore.RaffleConfig calldata config, uint256 existingRaffleId) external returns (uint256);

  /// @notice Sets addresses able to deposit NFTs to raffle
  /// @param raffleId The raffle id
  /// @param allowList Array of [address, 1 for true, 0 for false]
  function setDepositors(uint256 raffleId, UniversalRaffleCore.AllowList[] calldata allowList) external;

  /// @notice Sets allow list addresses and allowances
  /// @param raffleId The raffle id
  /// @param allowList Array of [address, allowance]
  function setAllowList(uint256 raffleId, UniversalRaffleCore.AllowList[] calldata allowList) external;

  /// @notice Turns allow list on and off
  /// @param raffleId The raffle id
  function toggleAllowList(uint256 raffleId) external;

  /// @notice Deposit ERC721 assets to the specified Raffle
  /// @param raffleId The raffle id
  /// @param slotIndices Array of slot indexes
  /// @param tokens Array of ERC721 arrays
  function depositNFTsToRaffle(
      uint256 raffleId,
      uint256[] calldata slotIndices,
      UniversalRaffleCore.NFT[][] calldata tokens
  ) external;

  /// @notice Withdraws the deposited ERC721 before an auction has started
  /// @param raffleId The raffle id
  /// @param slotNftIndexes The slot index and nft index in array [[slot index, nft index]]
  function withdrawDepositedERC721(
      uint256 raffleId,
      uint256[][] calldata slotNftIndexes
  ) external;

  /// @notice Purchases raffle tickets
  /// @param raffleId The raffle id
  /// @param amount The amount of raffle tickets
  function buyRaffleTickets(uint256 raffleId, uint256 amount) external payable;

  /// @notice Select winners of raffle
  /// @param raffleId The raffle id
  function finalizeRaffle(uint256 raffleId) external;

  /// @notice Select winners of raffle
  /// @param raffleId The raffle id
  /// @param winners Array of winner addresses
  function setWinners(uint256 raffleId, address[] memory winners) external;

  /// @notice Claims and distributes the NFTs from a winning slot
  /// @param raffleId The auction id
  /// @param slotIndex The slot index
  /// @param amount The amount which should be withdrawn
  function claimERC721Rewards(
      uint256 raffleId,
      uint256 slotIndex,
      uint256 amount
  ) external;

  /// @notice Refunds purchase amount for raffle tickets
  /// @param raffleId The raffle id
  /// @param tokenIds The ids of ticket NFTs bought from raffle
  function refundRaffleTickets(uint256 raffleId, uint256[] memory tokenIds) external;

  /// @notice Cancels an auction which has not started yet
  /// @param raffleId The raffle id
  function cancelRaffle(uint256 raffleId) external;

  /// @notice Withdraws the captured revenue from the auction to the auction owner. Can be called multiple times after captureSlotRevenue has been called.
  /// @param raffleId The auction id
  function distributeCapturedRaffleRevenue(uint256 raffleId) external;


  /// @notice Gets the minimum reserve price for auciton slot
  /// @param raffleId The raffle id
  /// @param slotIndex The slot index
  /// @param nftSlotIndex The nft slot index
  function distributeSecondarySaleFees(
      uint256 raffleId,
      uint256 slotIndex,
      uint256 nftSlotIndex
  ) external;

  /// @notice Withdraws the aggregated royalites amount of specific token to a specified address
  /// @param token The address of the token to withdraw
  function distributeRoyalties(address token) external returns(uint256);

  /// @notice Sets a raffle config value
  /// @param value The value of the configuration
  /// configType value 0: maxBulkPurchaseCount - Sets maximum number of tickets someone can buy in one bulk purchase
  /// configType value 1: Sets the NFT slot limit for raffle
  /// configType value 2: Sets the percentage of the royalty which wil be kept from each sale in basis points (1000 - 10%)
  function setRaffleConfigValue(uint256 configType, uint256 value) external returns(uint256);

  /// @notice Sets the RoyaltiesRegistry
  /// @param royaltiesRegistry The royalties registry address
  function setRoyaltiesRegistry(IRoyaltiesProvider royaltiesRegistry) external returns (IRoyaltiesProvider);

  /// @notice Modifies whether a token is supported for bidding
  /// @param erc20token The erc20 token
  /// @param value True or false
  function setSupportedERC20Tokens(address erc20token, bool value) external returns (address, bool);

  /// @notice Gets raffle information
  /// @param raffleId The raffle id
  function getRaffleConfig(uint256 raffleId)
      external
      view
      returns (UniversalRaffleCore.RaffleConfig memory);

  /// @notice Gets raffle state
  /// @param raffleId The raffle id
  function getRaffleState(uint256 raffleId)
      external
      view
      returns (UniversalRaffleCore.RaffleState memory);

  /// @notice Gets allow list
  /// @param raffleId The raffle id
  function getAllowList(uint256 raffleId, address participant)
      external
      view
      returns (uint256);


  /// @notice Gets deposited erc721s for slot
  /// @param raffleId The raffle id
  /// @param slotIndex The slot index
  function getDepositedNftsInSlot(uint256 raffleId, uint256 slotIndex)
      external
      view
      returns (UniversalRaffleCore.DepositedNFT[] memory);

  /// @notice Gets slot winner for particular auction
  /// @param raffleId The raffle id
  /// @param slotIndex The slot index
  function getSlotWinner(uint256 raffleId, uint256 slotIndex) external view returns (address);

  /// @notice Gets slot info for particular auction
  /// @param raffleId The raffle id
  /// @param slotIndex The slot index
  function getSlotInfo(uint256 raffleId, uint256 slotIndex) external view returns (UniversalRaffleCore.SlotInfo memory);

  /// @notice Gets contract configuration controlled by DAO
  function getContractConfig() external view returns (UniversalRaffleCore.ContractConfigByDAO memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../lib/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory);
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
        PaymentSplit[] paymentSplits;
    }

    struct Raffle {
        uint256 ticketCounter;
        uint256 depositedNFTCounter;
        uint256 withdrawnNFTCounter;
        uint256 depositorCount;
        mapping(uint256 => Slot) slots;
        mapping(uint256 => address) winners;
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
        address winner;
        mapping(uint256 => DepositedNFT) depositedNFTs;
    }

    struct SlotInfo {
        uint256 depositedNFTCounter;
        uint256 withdrawnNFTCounter;
        address winner;
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
        address depositor,
        address tokenAddress,
        uint256 tokenId,
        uint256 raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    );

    event LogERC721Withdrawal(
        address depositor,
        address tokenAddress,
        uint256 tokenId,
        uint256 raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    );

    event LogRaffleCreated(
        uint256 raffleId,
        address raffleOwner,
        uint256 numberOfSlots,
        uint256 startTime,
        uint256 endTime,
        uint256 resetTimer
    );

    event LogBidMatched(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 slotReservePrice,
        uint256 winningBidAmount,
        address winner
    );

    event LogSlotRevenueCaptured(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 amount,
        address ERC20PurchaseToken
    );

    event LogBidSubmitted(address sender, uint256 raffleId, uint256 currentBid, uint256 totalBid);

    event LogBidWithdrawal(address recipient, uint256 raffleId, uint256 amount);

    event LogRaffleExtended(uint256 raffleId, uint256 endTime);

    event LogRaffleCanceled(uint256 raffleId);

    event LogRaffleRevenueWithdrawal(address recipient, uint256 raffleId, uint256 amount);

    event LogERC721RewardsClaim(address claimer, uint256 raffleId, uint256 slotIndex);

    event LogRoyaltiesWithdrawal(uint256 amount, address to, address token);

    event LogRaffleFinalized(uint256 raffleId);

    modifier onlyRaffleSetupOwner(uint256 raffleId) {
        Storage storage ds = raffleStorage();
        require(raffleId > 0 && raffleId <= ds.totalRaffles, "E01");
        require(ds.raffleConfigs[raffleId].startTime > block.timestamp, "E03");
        require(!ds.raffles[raffleId].isCanceled, "E04");
        require(ds.raffleConfigs[raffleId].raffler == msg.sender, "E06");
        _;
    }

    modifier onlyRaffleSetup(uint256 raffleId) {
        Storage storage ds = raffleStorage();
        require(raffleId > 0 && raffleId <= ds.totalRaffles, "E01");
        require(ds.raffleConfigs[raffleId].startTime > block.timestamp, "E03");
        require(!ds.raffles[raffleId].isCanceled, "E04");
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
            config.startTime < config.endTime,
            "Wrong time configuration"
        );

        require(
            config.totalSlots > 0 && config.totalSlots <= ds.maxNumberOfSlotsPerRaffle,
            "Slots are out of bounds"
        );

        require(config.ERC20PurchaseToken == address(0) || ds.supportedERC20Tokens[config.ERC20PurchaseToken], "The ERC20 token is not supported");
        require(config.minTicketCount > 1 && config.maxTicketCount >= config.minTicketCount, "Ticket count err");

        uint256 raffleId;
        if (existingRaffleId > 0) {
            raffleId = existingRaffleId;
            require(ds.raffleConfigs[raffleId].raffler == msg.sender, "No permission");
            require(ds.raffleConfigs[raffleId].startTime > currentTime, "Raffle already started");
        } else {
            ds.totalRaffles = ds.totalRaffles + 1;
            raffleId = ds.totalRaffles;

            // Can only be initialized and not reconfigurable
            ds.raffles[raffleId].ticketCounter = 0;
            ds.raffles[raffleId].depositedNFTCounter = 0;
            ds.raffles[raffleId].withdrawnNFTCounter = 0;
            ds.raffles[raffleId].useAllowList = false;
            ds.raffles[raffleId].isCanceled = false;
            ds.raffles[raffleId].isFinalized = false;

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

        uint256 checkSum = 0;
        delete ds.raffleConfigs[raffleId].paymentSplits;
        for (uint256 k = 0; k < config.paymentSplits.length; k += 1) {
            require(config.paymentSplits[k].recipient != address(0), "Recipient should be present");
            require(config.paymentSplits[k].value != 0, "Fee value should be positive");
            checkSum += config.paymentSplits[k].value;
            ds.raffleConfigs[raffleId].paymentSplits.push(config.paymentSplits[k]);
        }
        require(checkSum < 10000, "E15");

        return raffleId;
    }

    function setDepositors(uint256 raffleId, AllowList[] calldata allowList) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];

        for (uint32 i = 0; i < allowList.length; i++) {
            raffle.depositors[allowList[i].participant] = allowList[i].allocation == 1 ? true : false;
        }
    }

    function setAllowList(uint256 raffleId, AllowList[] calldata allowList) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];

        require(allowList.length <= 1000, 'Max 1000 per');
        for (uint32 i = 0; i < allowList.length; i++) {
            raffle.allowList[allowList[i].participant] = allowList[i].allocation;
        }
    }

    function toggleAllowList(uint256 raffleId) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];
        raffle.useAllowList = !raffle.useAllowList;
    }

    function depositERC721(
        uint256 raffleId,
        uint256 slotIndex,
        NFT[] calldata tokens
    ) external onlyRaffleSetup(raffleId) returns (uint256[] memory) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];
        RaffleConfig storage raffleConfig = ds.raffleConfigs[raffleId];

        require(
            (msg.sender == raffleConfig.raffler || raffle.depositors[msg.sender]) &&
            raffleConfig.totalSlots >= slotIndex && slotIndex >= 0 && (tokens.length <= 40) &&
            (raffle.slots[slotIndex].depositedNFTCounter + tokens.length <= ds.nftSlotLimit)
        , "E36");

        // Ensure previous slot has depoited NFTs, so there is no case where there is an empty slot between non-empty slots
        if (slotIndex > 1) require(raffle.slots[slotIndex - 1].depositedNFTCounter > 0, "E39");

        uint256[] memory nftSlotIndexes = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            nftSlotIndexes[i] = _depositERC721(
                raffleId,
                slotIndex,
                tokens[i].tokenId,
                tokens[i].tokenAddress
            );
        }

        return nftSlotIndexes;
    }

    function _depositERC721(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 tokenId,
        address tokenAddress
    ) internal returns (uint256) {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];
        Slot storage slot = raffle.slots[slotIndex];

        DepositedNFT memory item = DepositedNFT({
            tokenId: tokenId,
            tokenAddress: tokenAddress,
            depositor: msg.sender,
            hasSecondarySaleFees: ds.royaltiesRegistry.getRoyalties(tokenAddress, tokenId).length > 0,
            feesPaid: false
        });

        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 nftSlotIndex = slot.depositedNFTCounter + 1;

        slot.depositedNFTs[nftSlotIndex] = item;
        slot.depositedNFTCounter = nftSlotIndex;
        raffle.depositedNFTCounter = raffle.depositedNFTCounter + 1;

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
        uint256[][] calldata slotNftIndexes
    ) external {
        Storage storage ds = raffleStorage();

        require(raffleId > 0 && raffleId <= ds.totalRaffles, "E01");
        require(ds.raffles[raffleId].isCanceled, "E05");

        for (uint256 i = 0; i < slotNftIndexes.length; i++) {
            _withdrawDepositedERC721(
                raffleId,
                slotNftIndexes[i][0],
                slotNftIndexes[i][1]
            );
        }
    }

    function _withdrawDepositedERC721(
        uint256 raffleId,
        uint256 slotIndex,
        uint256 nftSlotIndex
    ) internal {
        Storage storage ds = raffleStorage();
        Raffle storage raffle = ds.raffles[raffleId];
        Slot storage slot = raffle.slots[slotIndex];

        DepositedNFT memory nftForWithdrawal = slot.depositedNFTs[
            nftSlotIndex
        ];

        require(msg.sender == nftForWithdrawal.depositor, "E41");

        delete slot.depositedNFTs[nftSlotIndex];

        raffle.withdrawnNFTCounter = raffle.withdrawnNFTCounter + 1;
        raffle.depositedNFTCounter = raffle.depositedNFTCounter - 1;
        slot.withdrawnNFTCounter = slot.withdrawnNFTCounter + 1;

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

        require(raffle.isFinalized, "E24");
        require(raffle.winners[slotIndex] == msg.sender, "E31");

        require(amount <= 40, "E25");
        require(amount <= totalDeposited - totalWithdrawn, "E33");

        emit LogERC721RewardsClaim(msg.sender, raffleId, slotIndex);

        for (uint256 i = totalWithdrawn; i < amount + totalWithdrawn; i += 1) {
            DepositedNFT memory nftForWithdrawal = winningSlot.depositedNFTs[i + 1];

            raffle.withdrawnNFTCounter = raffle.withdrawnNFTCounter + 1;
            raffle.slots[slotIndex].withdrawnNFTCounter =
                winningSlot.withdrawnNFTCounter +
                1;

            if (nftForWithdrawal.tokenId != 0) {
                IERC721(nftForWithdrawal.tokenAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftForWithdrawal.tokenId
                );
            }
        }
    }

    function cancelRaffle(uint256 raffleId) external onlyRaffleSetupOwner(raffleId) {
        Storage storage ds = raffleStorage();
        ds.raffles[raffleId].isCanceled = true;

        emit LogRaffleCanceled(raffleId);
    }

    function refundRaffle(uint256 raffleId) external {
        Storage storage ds = raffleStorage();

        require(raffleId > 0 && raffleId <= ds.totalRaffles, "E01");
        require(ds.raffleConfigs[raffleId].startTime < block.timestamp, "E03");
        require(!ds.raffles[raffleId].isCanceled, "E04");

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

        for (uint256 i = 1; i <= raffleInfo.totalSlots; i++) {
            for (uint256 j = 1; j <= raffle.slots[i].depositedNFTCounter; j++) {
                UniversalRaffleCore.DepositedNFT memory nft = raffle.slots[i].depositedNFTs[j];

                if (nft.hasSecondarySaleFees) {
                    LibPart.Part[] memory fees = ds.royaltiesRegistry.getRoyalties(
                        nft.tokenAddress,
                        nft.tokenId
                    );
                    uint256 value = averageERC721SalePrice;

                    for (uint256 k = 0; k < fees.length && k < 5; k++) {
                        uint256 fee = (averageERC721SalePrice * fees[k].value) / 10000;

                        if (value > fee) {
                            value = value.sub(fee);
                            totalRoyaltyFees = totalRoyaltyFees.add(fee);
                        }
                    }
                }
            }
        }

        // NFT Royalties Split
        ds.rafflesRoyaltyPool[raffleId] = totalRoyaltyFees;

        // DAO Royalties Split
        uint256 daoRoyalty = raffleTotalRevenue.sub(totalRoyaltyFees).mul(ds.royaltyFeeBps).div(10000);
        ds.royaltiesReserve[raffleInfo.ERC20PurchaseToken] = ds.royaltiesReserve[raffleInfo.ERC20PurchaseToken].add(daoRoyalty);

        uint256 splitValue = 0;
        uint256 rafflerRevenue = raffleTotalRevenue.sub(totalRoyaltyFees).sub(daoRoyalty);

        for (uint256 i = 0; i < raffleInfo.paymentSplits.length && i < 5; i += 1) {
            uint256 fee = (rafflerRevenue * raffleInfo.paymentSplits[i].value) / 10000;
            splitValue = splitValue.add(fee);
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

    function getRaffleConfig(uint256 raffleId) external view returns (RaffleConfig memory) {
        Storage storage ds = raffleStorage();
        return ds.raffleConfigs[raffleId];
    }

    function getRaffleState(uint256 raffleId) external view returns (RaffleState memory)
    {
        Storage storage ds = raffleStorage();
        return RaffleState(
            ds.raffles[raffleId].ticketCounter,
            ds.raffles[raffleId].depositedNFTCounter,
            ds.raffles[raffleId].withdrawnNFTCounter,
            ds.raffles[raffleId].useAllowList,
            ds.raffles[raffleId].isCanceled,
            ds.raffles[raffleId].isFinalized,
            ds.raffles[raffleId].revenuePaid
        );
    }

    function getAllowList(uint256 raffleId, address participant) external view returns (uint256) {
        Storage storage ds = raffleStorage();
        return ds.raffles[raffleId].allowList[participant];
    }

    function getDepositedNftsInSlot(uint256 raffleId, uint256 slotIndex) external view returns (DepositedNFT[] memory) {
        Storage storage ds = raffleStorage();
        uint256 nftsInSlot = ds.raffles[raffleId].slots[slotIndex].depositedNFTCounter;

        DepositedNFT[] memory nfts = new DepositedNFT[](nftsInSlot);

        for (uint256 i = 0; i < nftsInSlot; i += 1) {
            nfts[i] = ds.raffles[raffleId].slots[slotIndex].depositedNFTs[i + 1];
        }
        return nfts;
    }

    function getSlotInfo(uint256 raffleId, uint256 slotIndex) external view returns (SlotInfo memory) {
        Storage storage ds = raffleStorage();
        Slot storage slot = ds.raffles[raffleId].slots[slotIndex];
        SlotInfo memory slotInfo = SlotInfo(
            slot.depositedNFTCounter,
            slot.withdrawnNFTCounter,
            slot.winner
        );
        return slotInfo;
    }

    function getSlotWinner(uint256 raffleId, uint256 slotIndex) external view returns (address) {
        Storage storage ds = raffleStorage();
        return ds.raffles[raffleId].winners[slotIndex];
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}