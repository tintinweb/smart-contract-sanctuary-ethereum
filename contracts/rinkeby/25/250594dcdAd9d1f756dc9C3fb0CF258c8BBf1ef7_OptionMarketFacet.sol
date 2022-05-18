// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IOptionMarket } from "../interfaces/facets/IOptionMarket.sol";
import { ICryptoPunksMarket } from "../interfaces/ICryptoPunksMarket.sol";
import { IVault } from "../interfaces/IVault.sol";
import { LibStorage, OptionMarketStorage, VaultStorage, TokenAddressStorage } from "../libraries/LibStorage.sol";
import { LibVaultUtils } from "../libraries/LibVaultUtils.sol";
import { OptionDuration, OptionInputParams, OptionInfo } from "../FukuTypes.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract OptionMarketFacet is IOptionMarket, IERC721Receiver {
    /**
     * @notice Places an option bid for the NFT
     *
     * @param optionParams The option params
     */
    function placeOptionBid(OptionInputParams calldata optionParams) external override {
        OptionMarketStorage storage oms = LibStorage.optionMarketStorage();
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        // ensure strike and premium are not 0
        require(
            optionParams.bidInput.amount > 0 && optionParams.premium > 0,
            "Insufficient strike and premium amounts"
        );

        if (optionParams.bidInput.nft == tas.punkToken) {
            // check punk exists
            require(optionParams.bidInput.nftIndex < 10000, "Punk not found");

            // check is not already owned by fuku marketplace
            require(
                ICryptoPunksMarket(tas.punkToken).punkIndexToAddress(optionParams.bidInput.nftIndex) != address(this),
                "Already in option"
            );
        } else {
            // check erc721 owner exists and is not already owned by fuku marketplace
            address nftOwner = IERC721(optionParams.bidInput.nft).ownerOf(optionParams.bidInput.nftIndex);
            require(nftOwner != address(0), "NFT unowned");
            require(nftOwner != address(this), "Already in option");
        }

        // verify user has enough in vault to pay premium
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(msg.sender, optionParams.bidInput.vault);
        require(optionParams.premium <= userEthVaultBalance, "Insufficient funds");

        // create the option id
        uint256 optionId = oms.nextOptionId++;
        oms.options[optionId] = OptionInfo(optionParams, false, msg.sender);

        emit OptionBidEntered(
            optionId,
            optionParams.bidInput.amount,
            optionParams.premium,
            optionParams.duration,
            optionParams.bidInput.vault,
            optionParams.bidInput.nft,
            optionParams.bidInput.nftIndex,
            msg.sender
        );
    }

    /**
     * @notice Allows a bidder to modify one of their existing bids
     *
     * @param optionId The option id
     * @param strike The strike amount
     * @param premium The premium amount
     * @param duration The option duration
     */
    function modifyOptionBid(
        uint256 optionId,
        uint256 strike,
        uint256 premium,
        OptionDuration duration
    ) external override {
        OptionMarketStorage storage oms = LibStorage.optionMarketStorage();

        // only bidder can modify bid
        require(oms.options[optionId].bidder == msg.sender, "Not your bid");

        // can't modify if it has already been accepted
        require(!oms.options[optionId].exercisable, "Option already accepted");

        // strike and premium cannot be 0
        require(strike > 0 && premium > 0, "Insufficient strike and premium amounts");

        // verify user has enough in vault to pay premium
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(
            msg.sender,
            oms.options[optionId].optionInput.bidInput.vault
        );
        require(premium <= userEthVaultBalance, "Insufficient funds");

        // modify option
        oms.options[optionId].optionInput.bidInput.amount = strike;
        oms.options[optionId].optionInput.premium = premium;
        oms.options[optionId].optionInput.duration = duration;

        emit OptionBidModified(optionId, strike, premium, duration);
    }

    /**
     * @notice Cancels an open option bid
     *
     * @param optionId The option id of the bid to cancel
     */
    function withdrawOptionBid(uint256 optionId) external override {
        OptionMarketStorage storage oms = LibStorage.optionMarketStorage();

        // only bidder can cancel their option bid
        require(oms.options[optionId].bidder == msg.sender, "Not your bid");

        // can only cancel if it has not yet been accepted
        require(!oms.options[optionId].exercisable, "Option already accepted");

        // cancel bid
        delete oms.options[optionId];

        emit OptionBidWithdrawn(optionId, msg.sender);
    }

    /**
     * @notice Accepts and option bid
     */
    function acceptOptionBid(uint256 optionId) external override {
        OptionMarketStorage storage oms = LibStorage.optionMarketStorage();
        VaultStorage storage vs = LibStorage.vaultStorage();
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        OptionInfo memory option = oms.options[optionId];
        IVault vault = IVault(vs.vaultAddresses[option.optionInput.bidInput.vault]);

        // make sure option exists
        require(option.bidder != address(0), "Option does not exist");

        // make sure option was not already accepted
        require(!option.exercisable, "Option already accepted");

        // make sure bidder can still cover the premium
        uint256 premiumLPTokenAmount = vault.getAmountLpTokens(option.optionInput.premium);
        uint256 userLPTokenBalance = LibVaultUtils.getUserLpTokenBalance(
            option.bidder,
            option.optionInput.bidInput.vault
        );
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(option.bidder, option.optionInput.bidInput.vault);
        // check both LP and ETH in case of slight conversion rounding errors
        require(
            premiumLPTokenAmount <= userLPTokenBalance && option.optionInput.premium <= userEthVaultBalance,
            "Option no longer valid"
        );

        // update user balance
        vs.userVaultBalances[option.bidder][option.optionInput.bidInput.vault] -= premiumLPTokenAmount;
        // withdraw the premium from bidder's vault
        uint256 ethReturned = vault.withdraw(premiumLPTokenAmount, payable(this));
        // another safety check to make sure enough ETH was withdrawn
        require(option.optionInput.premium <= ethReturned, "Didn't burn enough LP tokens");

        // check if punk option bid
        if (option.optionInput.bidInput.nft == tas.punkToken) {
            require(
                ICryptoPunksMarket(tas.punkToken).punkIndexToAddress(option.optionInput.bidInput.nftIndex) ==
                    msg.sender,
                "Not your punk"
            );

            // buy the punk for the premium (punk now held in escrow)
            ICryptoPunksMarket(tas.punkToken).buyPunk{ value: option.optionInput.premium }(
                option.optionInput.bidInput.nftIndex
            );
        } else {
            require(
                IERC721(option.optionInput.bidInput.nft).ownerOf(option.optionInput.bidInput.nftIndex) == msg.sender,
                "Not your NFT"
            );

            payable(msg.sender).transfer(option.optionInput.premium);
            IERC721(option.optionInput.bidInput.nft).safeTransferFrom(
                msg.sender,
                address(this),
                option.optionInput.bidInput.nftIndex
            );
        }

        // update option info
        option.exercisable = true;
        oms.options[optionId] = option;

        // calculate the expiry
        uint256 expiry = option.optionInput.duration == OptionDuration.ThirtyDays
            ? block.timestamp + 30 days
            : block.timestamp + 90 days;

        // update the accepted option info
        oms.acceptedOptions[optionId].expiry = expiry;
        oms.acceptedOptions[optionId].seller = msg.sender;

        emit OptionBidAccepted(
            optionId,
            option.bidder,
            msg.sender,
            option.optionInput.bidInput.amount,
            option.optionInput.premium,
            expiry
        );
    }

    /**
     * @notice Exercises the accepted option by the bidder
     *
     * @param optionId The option id
     */
    function exerciseOption(uint256 optionId) external override {
        OptionMarketStorage storage oms = LibStorage.optionMarketStorage();
        VaultStorage storage vs = LibStorage.vaultStorage();

        OptionInfo memory option = oms.options[optionId];
        IVault vault = IVault(vs.vaultAddresses[option.optionInput.bidInput.vault]);

        // check to see if option is exercisable
        require(option.exercisable, "Option is not exercisable");
        // check to make sure is owner of option
        require(option.bidder == msg.sender, "Not your option");
        // check to make sure option is not expired
        require(block.timestamp < oms.acceptedOptions[optionId].expiry);

        // verify bidder has enough funds to exercise the option
        uint256 strikeLPTokenAmount = vault.getAmountLpTokens(option.optionInput.bidInput.amount);
        uint256 userLPTokenBalance = LibVaultUtils.getUserLpTokenBalance(
            option.bidder,
            option.optionInput.bidInput.vault
        );
        uint256 userEthVaultBalance = LibVaultUtils.getUserEthBalance(option.bidder, option.optionInput.bidInput.vault);
        // check both LP and ETH in case of slight conversion rounding errors
        require(
            strikeLPTokenAmount <= userLPTokenBalance && option.optionInput.bidInput.amount <= userEthVaultBalance,
            "Bid no longer valid"
        );

        // update user balance
        vs.userVaultBalances[option.bidder][option.optionInput.bidInput.vault] -= strikeLPTokenAmount;
        // withdraw the strike amount from bidder's vault
        uint256 ethReturned = vault.withdraw(strikeLPTokenAmount, payable(oms.acceptedOptions[optionId].seller));
        // another safety check to make sure enough ETH was withdrawn
        require(option.optionInput.bidInput.amount <= ethReturned, "Didn't burn enough LP tokens");

        // transfer to NFT to bidder
        _transferNFT(
            option.optionInput.bidInput.nft,
            option.optionInput.bidInput.nftIndex,
            address(this),
            option.bidder
        );

        delete oms.options[optionId];
        delete oms.acceptedOptions[optionId];

        emit OptionExercised(
            optionId,
            option.bidder,
            option.optionInput.bidInput.amount,
            option.optionInput.bidInput.nft,
            option.optionInput.bidInput.nftIndex
        );
    }

    /**
     * @notice Allows the seller to retrieve NFT in case option expired
     *
     * @param optionId The option id
     */
    function closeOption(uint256 optionId) external override {
        OptionMarketStorage storage oms = LibStorage.optionMarketStorage();

        // check to make sure is option seller
        require(oms.acceptedOptions[optionId].seller == msg.sender, "Not your option");
        // check to make sure option has expired
        require(block.timestamp >= oms.acceptedOptions[optionId].expiry, "Option not expired");

        // send nft back to seller
        _transferNFT(
            oms.options[optionId].optionInput.bidInput.nft,
            oms.options[optionId].optionInput.bidInput.nftIndex,
            address(this),
            msg.sender
        );

        delete oms.options[optionId];
        delete oms.acceptedOptions[optionId];

        emit OptionClosed(optionId);
    }

    /**
     * @notice Callback for ERC-721 compatibility
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _transferNFT(
        address nft,
        uint256 nftIndex,
        address from,
        address to
    ) internal {
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        // check if sending punk
        if (nft == tas.punkToken) {
            ICryptoPunksMarket(tas.punkToken).transferPunk(to, nftIndex);
        } else {
            IERC721(nft).safeTransferFrom(from, to, nftIndex);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { OptionDuration, OptionInputParams } from "../../FukuTypes.sol";

interface IOptionMarket {
    event OptionBidEntered(
        uint256 optionId,
        uint256 strike,
        uint256 premium,
        OptionDuration duration,
        bytes12 vaultName,
        address indexed collection,
        uint256 indexed nftIndex,
        address indexed bidder
    );

    event OptionBidWithdrawn(uint256 optionId, address indexed bidder);

    event OptionBidModified(uint256 optionId, uint256 strike, uint256 premium, OptionDuration duration);

    event OptionBidAccepted(
        uint256 optionId,
        address indexed bidder,
        address indexed nftOwner,
        uint256 strike,
        uint256 premium,
        uint256 optionEnd
    );

    event OptionExercised(
        uint256 optionId,
        address indexed bidder,
        uint256 strike,
        address indexed nft,
        uint256 indexed nftIndex
    );

    event OptionClosed(uint256 optionId);

    function placeOptionBid(OptionInputParams calldata optionParams) external;

    function modifyOptionBid(
        uint256 optionId,
        uint256 strike,
        uint256 premium,
        OptionDuration duration
    ) external;

    function withdrawOptionBid(uint256 optionId) external;

    function acceptOptionBid(uint256 optionId) external;

    function exerciseOption(uint256 optionId) external;

    function closeOption(uint256 optionId) external;
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