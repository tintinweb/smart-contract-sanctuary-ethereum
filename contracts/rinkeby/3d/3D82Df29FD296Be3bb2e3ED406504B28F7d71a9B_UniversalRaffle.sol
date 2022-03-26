// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Forked from Universe Auction House by Stan
// Product by universe.xyz

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRaffleTickets.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/IUniversalRaffle.sol";
import "./interfaces/IRoyaltiesProvider.sol";
import "./lib/LibPart.sol";
import "./UniversalRaffleCore.sol";

/* TODO: 
 * Consumer is not decentralized and can halt raffle contracts
 */

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
        for (uint256 i; i < _supportedERC20Tokens.length;) {
            ds.supportedERC20Tokens[_supportedERC20Tokens[i]] = true;
            unchecked { i++; }
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
        UniversalRaffleCore.depositNFTsToRaffle(raffleId, slotIndices, tokens);
    }

    function withdrawDepositedERC721(
        uint256 raffleId,
        UniversalRaffleCore.SlotIndexAndNFTIndex[] calldata slotNftIndexes
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

        UniversalRaffleCore.buyRaffleTicketsChecks(raffleId, amount);

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
            SafeERC20.safeTransferFrom(IERC20(raffleInfo.ERC20PurchaseToken), msg.sender, address(this), amount.mul(raffleInfo.ticketPrice));
        }

        raffle.ticketCounter += amount;
        IRaffleTickets(ds.raffleTicketAddress).mint(msg.sender, amount, raffleId);
    }

    function finalizeRaffle(uint256 raffleId, bytes32 keyHash, uint64 subscriptionId, uint16 minConf, uint32 callbackGas) external override nonReentrant {
        (
            UniversalRaffleCore.Storage storage ds,
            UniversalRaffleCore.RaffleConfig storage raffleInfo,
            UniversalRaffleCore.Raffle storage raffle
        ) = getRaffleData(raffleId);

        require(raffleId > 0 && raffleId <= ds.totalRaffles &&
                !raffle.isCanceled &&
                block.timestamp > raffleInfo.endTime && !raffle.isFinalized, "E01");

        if (raffle.ticketCounter < raffleInfo.minTicketCount) ds.raffles[raffleId].isCanceled = true;
        else {
            // if (ds.unsafeRandomNumber) IRandomNumberGenerator(ds.vrfAddress).getWinnersMock(raffleId); // Testing purposes only
            // else IRandomNumberGenerator(ds.vrfAddress).getWinners(raffleId, keyHash, subscriptionId, minConf, callbackGas);
            IRandomNumberGenerator(ds.vrfAddress).getWinners(raffleId, keyHash, subscriptionId, minConf, callbackGas);
            UniversalRaffleCore.calculatePaymentSplits(raffleId);
        }
    }

    function setWinners(uint256 raffleId, uint256[] memory winnerIds, address[] memory winners) external {
        UniversalRaffleCore.Storage storage ds = UniversalRaffleCore.raffleStorage();
        require(msg.sender == ds.vrfAddress, "No permission");
        for (uint256 i = 1; i <= winners.length;) {
            ds.raffles[raffleId].slots[i].winnerId = winnerIds[i - 1];
            ds.raffles[raffleId].slots[i].winner = winners[i - 1];
            unchecked { i++; }
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
        for (uint256 i; i < tokenIds.length;) {
            require(IERC721(ds.raffleTicketAddress).ownerOf(tokenIds[i]) == msg.sender && !raffle.refunds[tokenIds[i]], "Refund already issued");
            raffle.refunds[tokenIds[i]] = true;
            unchecked { i++; }
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

        uint256 raffleRevenue = ds.raffleRevenue[raffleId];
        require(raffleId > 0 && raffleId <= ds.totalRaffles && raffle.isFinalized && raffleRevenue > 0, "E30");

        ds.raffleRevenue[raffleId] = 0;

        uint256 remainder = (raffleInfo.ticketPrice * raffle.ticketCounter).sub(ds.rafflesRoyaltyPool[raffleId]).sub(ds.rafflesDAOPool[raffleId]);
        uint256 value = remainder;
        uint256 paymentSplitsPaid;

        emit UniversalRaffleCore.LogRaffleRevenueWithdrawal(raffleInfo.raffler, raffleId, remainder);

        // Distribute the payment splits to the respective recipients
        for (uint256 i; i < raffleInfo.paymentSplits.length && i < 5;) {
            uint256 fee = (remainder * raffleInfo.paymentSplits[i].value) / 10000;
            value -= fee;
            paymentSplitsPaid += fee;
            sendPayments(raffleInfo.ERC20PurchaseToken, fee, raffleInfo.paymentSplits[i].recipient);
            unchecked { i++; }
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

        nft.feesPaid = true;

        for (uint256 i; i < nft.feesAddress.length && i < 5;) {
            uint256 value = (averageERC721SalePrice * nft.feesValue[i]) / 10000;
            if (ds.rafflesRoyaltyPool[raffleId] >= value) {
                ds.rafflesRoyaltyPool[raffleId] = ds.rafflesRoyaltyPool[raffleId].sub(value);
                sendPayments(raffleInfo.ERC20PurchaseToken, value, nft.feesAddress[i]);
            }
            unchecked { i++; }
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
            SafeERC20.safeTransfer(IERC20(tokenAddress), address(to), value);
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

    function getRaffleState(uint256 raffleId) external view override returns (UniversalRaffleCore.RaffleConfig memory, UniversalRaffleCore.RaffleState memory) {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
    function getWinners(uint256 raffleId, bytes32 _keyHash, uint64 _subscriptionId, uint16 _minConf, uint32 _callbackGas) external;
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
      UniversalRaffleCore.SlotIndexAndNFTIndex[] calldata slotNftIndexes
  ) external;

  /// @notice Purchases raffle tickets
  /// @param raffleId The raffle id
  /// @param amount The amount of raffle tickets
  function buyRaffleTickets(uint256 raffleId, uint256 amount) external payable;

  /// @notice Select winners of raffle
  /// @param raffleId The raffle id
  function finalizeRaffle(uint256 raffleId, bytes32 keyHash, uint64 subscriptionId, uint16 minConf, uint32 callbackGas) external;

  /// @notice Select winners of raffle
  /// @param raffleId The raffle id
  /// @param winners Array of winner addresses
  function setWinners(uint256 raffleId, uint256[] memory winnerIds, address[] memory winners) external;

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

  /// @notice Gets raffle state
  /// @param raffleId The raffle id
  function getRaffleState(uint256 raffleId)
      external
      view
      returns (UniversalRaffleCore.RaffleConfig memory, UniversalRaffleCore.RaffleState memory);

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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