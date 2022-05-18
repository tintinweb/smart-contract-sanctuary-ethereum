// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IBidMarket } from "../interfaces/facets/IBidMarket.sol";
import { ICryptoPunksMarket } from "../interfaces/ICryptoPunksMarket.sol";
import { IVault } from "../interfaces/IVault.sol";
import { LibStorage, BidMarketStorage, VaultStorage, TokenAddressStorage } from "../libraries/LibStorage.sol";
import { LibVaultUtils } from "../libraries/LibVaultUtils.sol";
import { BidInputParams, BidInfo } from "../FukuTypes.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BidMarketFacet is IBidMarket {
    /**
     * @notice Places a bid for the NFT
     *
     * @param bidInputParams The input parameters used to place bid
     */
    function placeBid(BidInputParams calldata bidInputParams) public override {
        BidMarketStorage storage bms = LibStorage.bidMarketStorage();
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        require(bidInputParams.amount > 0, "Insufficient bid amount");

        if (bidInputParams.nft == tas.punkToken) {
            // check punk exists
            require(bidInputParams.nftIndex < 10000, "Punk not found");
        } else {
            // check erc721 owner exists
            require(IERC721(bidInputParams.nft).ownerOf(bidInputParams.nftIndex) != address(0), "NFT unowned");
        }

        // verify user has enough in vault to make bid
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(msg.sender, bidInputParams.vault);
        require(bidInputParams.amount <= userEthVaultBalance, "Insufficient funds");

        // create the bid
        uint256 bidId = bms.nextBidId++;
        bms.bids[bidId] = BidInfo(bidInputParams, msg.sender);

        emit BidEntered(
            bidId,
            bidInputParams.amount,
            bidInputParams.vault,
            bidInputParams.nft,
            bidInputParams.nftIndex,
            msg.sender
        );
    }

    /**
     * @notice Places multiple bids within one transaction
     *
     * @param bidInputParams Array of bid input parameters
     */
    function placeMultipleBids(BidInputParams[] calldata bidInputParams) external override {
        for (uint256 i; i < bidInputParams.length; ++i) {
            placeBid(bidInputParams[i]);
        }
    }

    /**
     * @notice Allows a user to modify one of their existing bids
     *
     * @param bidId The bid id
     * @param newAmount The new bid amount
     */
    function modifyBid(uint256 bidId, uint256 newAmount) public override {
        BidMarketStorage storage bms = LibStorage.bidMarketStorage();

        // only bidder can modify bid
        require(bms.bids[bidId].bidder == msg.sender, "Not bid owner");
        // bids with 0 amount are invalid
        require(newAmount > 0, "Insufficient bid amount");

        // verify bidder has enough in vault to make bid
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(msg.sender, bms.bids[bidId].bidInput.vault);
        require(newAmount <= userEthVaultBalance, "Insufficient funds");

        bms.bids[bidId].bidInput.amount = newAmount;

        emit BidModified(bidId, newAmount);
    }

    /**
     * @notice Modify multiple existing bids within one transaction
     *
     * @param bidIds Array of bid Ids
     * @param amounts Array of amounts
     */
    function modifyMultipleBids(uint256[] calldata bidIds, uint256[] calldata amounts) external override {
        require(bidIds.length == amounts.length, "Array length mismatch");
        for (uint256 i; i < bidIds.length; ++i) {
            modifyBid(bidIds[i], amounts[i]);
        }
    }

    /**
     * @notice Cancels an open bid by passing in the bidId
     *
     * @param bidId The bid id
     */
    function withdrawBid(uint256 bidId) public override {
        BidMarketStorage storage bms = LibStorage.bidMarketStorage();

        // only bidder can withdraw his bid
        require(bms.bids[bidId].bidder == msg.sender, "Not your bid");

        // set bid values back to default
        delete bms.bids[bidId];

        emit BidWithdrawn(bidId, msg.sender);
    }

    /**
     * @notice Cancels multiple bids in one transaction
     *
     * @param bidIds Array of bid Ids
     */
    function withdrawMultipleBids(uint256[] calldata bidIds) external override {
        for (uint256 i; i < bidIds.length; ++i) {
            withdrawBid(bidIds[i]);
        }
    }

    /**
     * @notice NFT owner accepts an open bid on his NFT after approving the bid
     *
     * @param bidId The bid id
     */
    function acceptBid(uint256 bidId) external override {
        BidMarketStorage storage bms = LibStorage.bidMarketStorage();
        VaultStorage storage vs = LibStorage.vaultStorage();
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        BidInfo memory bidInfo = bms.bids[bidId];
        IVault vault = IVault(vs.vaultAddresses[bidInfo.bidInput.vault]);

        // verify bid exists
        require(bidInfo.bidder != address(0), "Bid does not exist");

        // verify bidder still has enough in vault for bid to go through
        uint256 bidLPTokenAmount = vault.getAmountLpTokens(bidInfo.bidInput.amount);
        uint256 userLPTokenBalance = LibVaultUtils.getUserLpTokenBalance(bidInfo.bidder, bidInfo.bidInput.vault);
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(bidInfo.bidder, bidInfo.bidInput.vault);
        // check both LP and ETH in case of slight conversion rounding errors
        require(
            bidLPTokenAmount <= userLPTokenBalance && bidInfo.bidInput.amount <= userEthVaultBalance,
            "Bid no longer valid"
        );

        // update user balance
        vs.userVaultBalances[bidInfo.bidder][bidInfo.bidInput.vault] -= bidLPTokenAmount;
        // withdraw funds from vault
        uint256 ethReturned = vault.withdraw(bidLPTokenAmount, payable(this));
        // another safety check to make sure enough ETH was withdrawn
        require(bidInfo.bidInput.amount <= ethReturned, "Didn't burn enough LP tokens");

        // check if punk bid
        if (bidInfo.bidInput.nft == tas.punkToken) {
            require(
                ICryptoPunksMarket(tas.punkToken).punkIndexToAddress(bidInfo.bidInput.nftIndex) == msg.sender,
                "Not your punk"
            );

            ICryptoPunksMarket(tas.punkToken).buyPunk{ value: bidInfo.bidInput.amount }(bidInfo.bidInput.nftIndex);
            ICryptoPunksMarket(tas.punkToken).transferPunk(bidInfo.bidder, bidInfo.bidInput.nftIndex);
        } else {
            require(IERC721(bidInfo.bidInput.nft).ownerOf(bidInfo.bidInput.nftIndex) == msg.sender, "Not your NFT");

            payable(msg.sender).transfer(bidInfo.bidInput.amount);

            IERC721(bidInfo.bidInput.nft).safeTransferFrom(msg.sender, bidInfo.bidder, bidInfo.bidInput.nftIndex);
        }

        delete bms.bids[bidId];
        emit BidAccepted(bidId, bidInfo.bidder, msg.sender, bidInfo.bidInput.amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BidInputParams } from "../../FukuTypes.sol";

interface IBidMarket {
    event BidEntered(
        uint256 bidId,
        uint256 amount,
        bytes12 vaultName,
        address indexed nft,
        uint256 indexed nftIndex,
        address indexed bidder
    );

    event BidAccepted(uint256 bidId, address indexed bidder, address indexed seller, uint256 bidAmount);

    event BidWithdrawn(uint256 bidId, address indexed bidder);

    event BidModified(uint256 bidId, uint256 amount);

    function placeBid(BidInputParams calldata bidInputParams) external;

    function placeMultipleBids(BidInputParams[] calldata bidInputParams) external;

    function modifyBid(uint256 bidId, uint256 amount) external;

    function modifyMultipleBids(uint256[] calldata bidIds, uint256[] calldata amounts) external;

    function withdrawBid(uint256 bidId) external;

    function withdrawMultipleBids(uint256[] calldata bidIds) external;

    function acceptBid(uint256 bidId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICryptoPunksMarket {
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
    event PunkBidEntered(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
    event PunkBidWithdrawn(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
    event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    function setInitialOwner(address to, uint256 punkIndex) external;

    function setInitialOwners(address[] calldata addresses, uint256[] calldata indices) external;

    function allInitialOwnersAssigned() external;

    function getPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;

    function punkNoLongerForSale(uint256 punkIndex) external;

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei) external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function withdraw() external;

    function enterBidForPunk(uint256 punkIndex) external payable;

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

    function withdrawBidForPunk(uint256 punkIndex) external;

    function punkIndexToAddress(uint256 punkIndex) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVault {
    /**
     * @dev Deposits ETH and converts to vault's LP token
     *
     * @return The amount of LP tokens received from ETH deposit
     */
    function deposit() external payable returns (uint256);

    /**
     * @dev Deposits LP token directly into vault
     *
     * @param amount The amount of LP tokens to deposit
     * @param user The user depositing
     */
    function depositLpToken(uint256 amount, address user) external;

    /**
     * @dev Converts LP token and withdraws as ETH
     *
     * @param lpTokenAmount The amount of LP tokens to withdraw before converting
     * @param recipient The recipient of the converted ETH
     * @return The amount of ETH withdrawn
     */
    function withdraw(uint256 lpTokenAmount, address payable recipient) external returns (uint256);

    /**
     * @dev Withdraws LP token directly from vault
     *
     * @param lpTokenAmount The amount of LP tokens to withdraw
     * @param recipient The recipient of the LP tokens
     */
    function withdrawLpToken(uint256 lpTokenAmount, address recipient) external;

    /**
     * @dev Transfers LP tokens to new vault
     *
     * @param newVaultAddress The new vault which will receive the LP tokens
     */
    function transferFunds(address payable newVaultAddress) external;

    /**
     * @dev Gets the conversion from LP token to ETH
     *
     * @param lpTokenAmount The LP token amount
     */
    function getAmountETH(uint256 lpTokenAmount) external view returns (uint256);

    /**
     * @dev Gets the conversion from ETH to LP token
     *
     * @param ethAmount The ETH amount
     */
    function getAmountLpTokens(uint256 ethAmount) external view returns (uint256);

    /**
     * @dev Get the LP token address of the vault
     */
    function getLpToken() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BidInfo, OptionInfo, AcceptedOption } from "../FukuTypes.sol";

struct BidMarketStorage {
    uint256 nextBidId;
    mapping(uint256 => BidInfo) bids;
}

struct OptionMarketStorage {
    uint256 nextOptionId;
    mapping(uint256 => OptionInfo) options;
    mapping(uint256 => AcceptedOption) acceptedOptions;
}

struct VaultStorage {
    mapping(bytes12 => address) vaultAddresses;
    mapping(address => mapping(bytes12 => uint256)) userVaultBalances;
}

struct TokenAddressStorage {
    address punkToken;
    address fukuToken;
}

struct AirdropClaimStorage {
    bytes32 merkleRoot;
    uint256 totalAmount; // todo: unused
    uint256 initialUnlockBps; // todo: unused
    mapping(address => uint256) claimed;
}

struct RewardsManagementStorage {
    uint256 nextEpochId;
    uint256 epochDuration;
    mapping(uint256 => uint256) epochEndings;
    mapping(uint256 => bytes32) epochRewardsMekleRoots;
    mapping(uint256 => uint256) epochTotalRewards;
    mapping(uint256 => mapping(address => bool)) rewardsClaimed;
}

struct DepositsRewardsStorage {
    mapping(bytes12 => uint256) periodFinish;
    mapping(bytes12 => uint256) rewardRate;
    mapping(bytes12 => uint256) rewardsDuration;
    mapping(bytes12 => uint256) lastUpdateTime;
    mapping(bytes12 => uint256) rewardPerTokenStored;
    mapping(bytes12 => uint256) totalSupply;
    mapping(bytes12 => mapping(address => uint256)) userRewardPerTokenPaid;
    mapping(bytes12 => mapping(address => uint256)) rewards;
}

library LibStorage {
    bytes32 constant BID_MARKET_STORAGE_POSITION = keccak256("fuku.storage.market.bid");
    bytes32 constant OPTION_MARKET_STORAGE_POSTION = keccak256("fuku.storage.market.option");
    bytes32 constant VAULT_STORAGE_POSITION = keccak256("fuku.storage.vault");
    bytes32 constant TOKEN_ADDRESS_STORAGE_POSITION = keccak256("fuku.storage.token.address");
    bytes32 constant AIRDROP_CLAIM_STORAGE_POSITION = keccak256("fuku.storage.airdrop.claim");
    bytes32 constant REWARDS_MANAGEMENT_STORAGE_POSITION = keccak256("fuku.storage.rewards.management");
    bytes32 constant DEPOSITS_REWARDS_STORAGE_POSITION = keccak256("fuku.storage.deposits.rewards");

    function bidMarketStorage() internal pure returns (BidMarketStorage storage bms) {
        bytes32 position = BID_MARKET_STORAGE_POSITION;
        assembly {
            bms.slot := position
        }
    }

    function optionMarketStorage() internal pure returns (OptionMarketStorage storage oms) {
        bytes32 position = OPTION_MARKET_STORAGE_POSTION;
        assembly {
            oms.slot := position
        }
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    function tokenAddressStorage() internal pure returns (TokenAddressStorage storage tas) {
        bytes32 position = TOKEN_ADDRESS_STORAGE_POSITION;
        assembly {
            tas.slot := position
        }
    }

    function airdropClaimStorage() internal pure returns (AirdropClaimStorage storage acs) {
        bytes32 position = AIRDROP_CLAIM_STORAGE_POSITION;
        assembly {
            acs.slot := position
        }
    }

    function rewardsManagementStorage() internal pure returns (RewardsManagementStorage storage rms) {
        bytes32 position = REWARDS_MANAGEMENT_STORAGE_POSITION;
        assembly {
            rms.slot := position
        }
    }

    function depositsRewardsStorage() internal pure returns (DepositsRewardsStorage storage drs) {
        bytes32 position = DEPOSITS_REWARDS_STORAGE_POSITION;
        assembly {
            drs.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { LibStorage, VaultStorage } from "./LibStorage.sol";
import { IVault } from "../interfaces/IVault.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibVaultUtils {
    function getUserLpTokenBalance(address user, bytes12 vaultName) internal view returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        return vs.userVaultBalances[user][vaultName];
    }

    function getUserEthBalance(address user, bytes12 vaultName) internal view returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        return IVault(vs.vaultAddresses[vaultName]).getAmountETH(vs.userVaultBalances[user][vaultName]);
    }

    function getTotalVaultHoldings(bytes12 vaultName) internal view returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        address vault = vs.vaultAddresses[vaultName];
        address vaultLpToken = IVault(vault).getLpToken();
        if (vaultLpToken == address(0)) {
            return vault.balance;
        } else {
            return IERC20(vaultLpToken).balanceOf(vault);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum OptionDuration {
    ThirtyDays,
    NinetyDays
}

struct BidInputParams {
    bytes12 vault; // the vault from where the funds for the bid originate
    address nft; // the address of the nft collection
    uint256 nftIndex; // the index of the nft in the collection
    uint256 amount; // the bid amount
}

struct BidInfo {
    BidInputParams bidInput; // the input params used to create bid
    address bidder; // the address of the bidder
}

struct OptionInputParams {
    BidInputParams bidInput;
    uint256 premium;
    OptionDuration duration;
}

struct OptionInfo {
    OptionInputParams optionInput; // the input params used to create base part of bid
    bool exercisable; // true if option can be exercised, false otherwise
    address bidder; // the bidder (buyer)
}

struct AcceptedOption {
    uint256 expiry;
    address seller;
}

struct AirdropInit {
    bytes32 merkleRoot;
    address token;
    uint256 totalAmount;
    uint256 initialUnlockBps;
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