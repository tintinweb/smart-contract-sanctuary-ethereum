//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;
pragma abicoder v2;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {WithdrawsLib} from "../../libraries/Withdraws/WithdrawsLib.sol";
import {TimerLib} from "../../libraries/Timer/TimerLib.sol";
import {IERC721CreatorMintPermissions} from "@manifoldxyz/creator-core-solidity/contracts/permissions/ERC721/IERC721CreatorMintPermissions.sol";
import {IERC721CreatorCore} from "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import {IERC1155CreatorMintPermissions} from "@manifoldxyz/creator-core-solidity/contracts/permissions/ERC1155/IERC1155CreatorMintPermissions.sol";
import {IERC1155CreatorCore} from "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Represents the setings for an auction
struct NftAuctionSettings {
    // the time at which the auction would close (will be updating)
    uint256 initialAuctionSeconds;
    // the time at which the auction would close (will be updating)
    uint256 floor;
    // The minimum amount of time left in an auction after a new bid is created
    uint256 timeBufferSeconds;
    // the token id for this auction
    uint256 tokenId;
    // The minimum percentage difference between the last bid amount and the current bid. (1-100)
    uint256 minBidIncrementPercentage;
}

/// @notice Represents an auction project
struct NftAuction {
    NftAuctionSettings settings;
    // the token id for this auction
    uint256 startTime;
    // the time at which the auction would close (will be updating)
    uint256 closeTime;
    // the highest bid, used specifically for auctions
    uint256 highBid;
    // the highest bidder, used specifically for auctions
    address highBidder;
    // the user id of the high bidder
    bytes32 highBidderUserId;
}

/// @notice Represents a ranged project
struct NftRangedProjectState {
    // used for ranged release to specify the start of the range
    uint256 rangeStart;
    // used for ranged release to specify the end of the range
    uint256 rangeEnd;
    // used specifically for ranged release
    uint256 pointer;
}

/// @notice Represents an input to create/update a project
struct NftProjectInput {
    // we have support for 2 token standards - erc721 or erc1155
    bool isErc721;
    // the id of the project (should use product id from storyblok)
    bytes32 projectId;
    // the identifier of the product
    string productId;
    // the wallet of the project
    address wallet;
    // the nft contract of the project
    address nftContract;
    // the time at which the contract would be closed
    uint256 closeTime;
    // allows us to pause the project if needed
    bool paused;
    // the custodial for the tokens in this project, if applicable
    address custodial;
    // we can limit items to be claimed from a release by specifying a limit.
    uint256 countLimit;
}

/// @notice Represents an NFT project
struct NftProject {
    // the curator who created the project
    address curator;
    // the time the project was created
    uint256 timestamp;
    // we have support for 2 token standards - erc721 or erc1155
    bool isErc721;
    // the type of the project
    uint8 projectType;
    // the id of the project (should use product id from storyblok)
    bytes32 projectId;
    // the identifier of the product
    string productId;
    // the wallet of the project
    address wallet;
    // the nft contract of the project
    address nftContract;
    // the time at which the contract would be closed
    uint256 closeTime;
    // allows us to pause the project if needed
    bool paused;
    // the custodial for the tokens in this project, if applicable
    address custodial;
    // counts the items claimed from this release.
    uint256 count;
    // we can limit items to be claimed from a release by specifying a limit.
    uint256 countLimit;
}

/// @notice Represents a voucher with definitions that allows the holder to claim an NFT
struct NFTVoucher {
    /// @notice the id of the project, allows us to scope projects.
    bytes32 projectId;
    /// @notice the id of the intended user, for mailing.
    bytes32 userId;
    /// @notice (optional) used to lock voucher usage to specific wallet address.
    address walletAddress;
    /// @notice the identifier of the voucher, used to prevent double usage.
    string voucherId;
    /// @notice (optional) The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 price;
    /// @notice (optional) allows us to restrict voucher usage.
    uint256 validUntil;
    /// @notice (optional) allows us to restrict voucher usage.
    uint256 tokenId;
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the SIGNER_ROLE.
    bytes signature;
}

/// @notice Represents the state of a project
struct ProjectStateOutput {
    uint256 time;
    NftProject project;
    NftAuction auction;
    NftRangedProjectState ranged;
}

/// @title a multi release contract supporting multiple release formats
/// @author Liron Navon
/// @notice this contract has a complicated access system, please contact owner for support
/// @dev This contract heavily relies on vouchers with valid signatures.
contract MultiRelease is
    Ownable,
    ReentrancyGuard,
    EIP712,
    AccessControl,
    IERC721CreatorMintPermissions,
    IERC1155CreatorMintPermissions
{
    /// @dev roles for access control
    bytes32 private constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /// @dev release types for project types
    uint8 private constant AUCTION_PROJECT = 1;
    uint8 private constant SPECIFIED_PROJECT = 2;
    uint8 private constant RANGED_PROJECT = 3;
    uint8 private constant LAZY_MINT_PROJECT = 4;

    /// @dev for domain separation (EIP712)
    string private constant SIGNING_DOMAIN = "AvantArte NFT Voucher";
    string private constant SIGNATURE_VERSION = "1";

    /// @notice vouchers which are already used
    mapping(string => address) public usedVouchers;
    /// @notice mapping of projectId => project
    mapping(bytes32 => NftProject) private projects;
    /// @notice mapping of projectId => auction info - used only for auctions
    mapping(bytes32 => NftAuction) private auctions;
    /// @notice mapping of projectId => auction project - used only for auctions
    mapping(bytes32 => NftRangedProjectState) private rangedProjects;
    /// @notice mapping of address => address - used to verify minting using manifold
    mapping(address => address) private pendingMints;

    /// @notice an event that represents when funds have been withdrawn from the contract
    event OnWithdraw(address indexed addr, uint256 balance);

    /// @notice an event that represents when a token is claimed
    event OnTokenClaim(
        bytes32 userId,
        bytes32 indexed projectId,
        string indexed productId,
        address indexed account,
        uint256 tokenId,
        uint256 value,
        bool minted
    );

    /// @notice an event that represents when a bid happens
    event OnAuctionBid(
        bytes32 userId,
        bytes32 indexed projectId,
        string indexed productId,
        address indexed account,
        uint256 tokenId,
        uint256 value
    );

    /// @notice an event that represents when an auction start
    event OnAuctionStart(
        bytes32 userId,
        bytes32 indexed projectId,
        string indexed productId,
        address indexed account,
        uint256 tokenId
    );

    /// @notice an event to call when the auction is closed manually
    event OnAuctionClose(
        bytes32 indexed projectId,
        string indexed productId,
        address indexed account,
        uint256 tokenId
    );

    /// @notice an event to call when a user dropped from the auction
    event OnAuctionOutBid(
        bytes32 userId,
        bytes32 indexed projectId,
        string indexed productId,
        address indexed account,
        uint256 tokenId,
        uint256 value
    );

    /// @notice an event that happens when a project is created
    event OnProjectCreated(
        bytes32 indexed projectId,
        uint8 indexed projectType,
        address indexed curator,
        string productId
    );

    /// @notice an event that happens when a voucher is used
    event OnVoucherUsed(
        bytes32 indexed projectId,
        address indexed account,
        string indexed voucherId
    );

    // solhint-disable-next-line no-empty-blocks
    constructor() ReentrancyGuard() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    /// @notice creates a project in which we give a range of tokens
    /// @param project the input to create this project
    /// @param rangeStart the first token in the range
    /// @param rangeEnd the last token in the range
    /// @param pointer where we start counting from, in a new project it should be same as rangeStart
    function setRangedProject(
        NftProjectInput calldata project,
        uint256 rangeStart,
        uint256 rangeEnd,
        uint256 pointer
    ) external onlyRole(ADMIN_ROLE) {
        _setProject(project, RANGED_PROJECT);
        rangedProjects[project.projectId].rangeStart = rangeStart;
        rangedProjects[project.projectId].rangeEnd = rangeEnd;
        rangedProjects[project.projectId].pointer = pointer;
    }

    /// @notice creates a project in which we expect to be given a contract of type manifold creator
    /// @param project the input to create this project
    function setLazyMintProject(NftProjectInput calldata project)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setProject(project, LAZY_MINT_PROJECT);
    }

    /// @notice creates a project in which we expect to be given a tokenId from the voucher
    /// @param project the input to create this project
    function setSpecifiedProject(NftProjectInput calldata project)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setProject(project, SPECIFIED_PROJECT);
    }

    /// @notice creates a project which is an auction
    /// @param project the input to create this project
    /// @param auctionSettings extra settings, releated to the auction
    function setAuctionProject(
        NftProjectInput calldata project,
        NftAuctionSettings memory auctionSettings
    ) external onlyRole(ADMIN_ROLE) {
        _setProject(project, AUCTION_PROJECT);
        // settings specific to auction project
        auctions[project.projectId].settings = auctionSettings;
    }

    /// @notice allows an admin to withdraw funds from the contract, be careful as this can break functionality
    /// @dev extra care was taken to make sure the contract has only the funds reqired to function
    /// @param to the address to get the funds
    /// @param value the amount of funds to withdraw
    function withdraw(address to, uint256 value)
        external
        onlyRole(WITHDRAWER_ROLE)
    {
        WithdrawsLib._withdraw(payable(to), value);
    }

    /// @dev makes sure the project exists
    /// @param projectId the id of the project
    modifier onlyExistingProject(bytes32 projectId) {
        require(projects[projectId].timestamp != 0, "Nonexisting project");
        _;
    }

    /// @dev makes sure the project is of the right type
    /// @param projectId the id of the project
    /// @param projectType type id of the project
    modifier onlyProjectOfType(bytes32 projectId, uint8 projectType) {
        require(projects[projectId].timestamp != 0, "Nonexisting project");
        require(
            projects[projectId].projectType == projectType,
            "Wrong project type"
        );
        _;
    }

    /// @dev makes sure the project is active
    /// @param projectId the id of the project
    modifier onlyActiveProjects(bytes32 projectId) {
        // check if the project is paused
        require(!projects[projectId].paused, "Project is paused");
        // check if the project has a closeTime, and if so check if it passed
        if (projects[projectId].closeTime > 0) {
            require(
                projects[projectId].closeTime >= TimerLib._now(),
                "Project is over"
            );
        }
        // check if the project has a countLimit, and if it's reached
        if (projects[projectId].countLimit > 0) {
            require(
                projects[projectId].countLimit > projects[projectId].count,
                "Project at count limit"
            );
        }
        _;
    }

    /// @dev makes sure voucher was never used
    /// @param voucherId the id of the voucher
    modifier onlyUnusedVouchers(string calldata voucherId) {
        require(usedVouchers[voucherId] == address(0), "Used voucher");
        _;
    }

    /// @dev makes sure the voucher is verified
    /// @param voucher the voucher to validates
    modifier onlyVerifiedVouchers(NFTVoucher calldata voucher) {
        // check authorized signer
        require(
            hasRole(SIGNER_ROLE, _recoverVoucherSigner(voucher)),
            "Unauthorized signer"
        );

        // check payment
        if (voucher.price > 0) {
            require(msg.value >= voucher.price, "Insufficient funds");
        }

        if (voucher.validUntil > 0) {
            require(voucher.validUntil >= TimerLib._now(), "Voucher expired");
        }

        // check wallet restriction
        if (voucher.walletAddress != address(0)) {
            require(voucher.walletAddress == msg.sender, "Unauthorized wallet");
        }
        _;
    }

    /// @notice sets the project as paused
    /// @param projectId the id of the project
    /// @param paused is the project paused
    function setPaused(bytes32 projectId, bool paused)
        external
        onlyExistingProject(projectId)
        onlyRole(ADMIN_ROLE)
    {
        projects[projectId].paused = paused;
    }

    /// @dev starts the auction
    /// @param projectId the id of the project
    /// @param userId the user who starts the auction
    function _startAuction(bytes32 projectId, bytes32 userId) private {
        // set start time
        auctions[projectId].startTime = TimerLib._now();
        // set end time
        auctions[projectId].closeTime =
            TimerLib._now() +
            auctions[projectId].settings.initialAuctionSeconds;

        emit OnAuctionStart(
            userId,
            projectId,
            projects[projectId].productId,
            msg.sender,
            auctions[projectId].settings.tokenId
        );
    }

    /// @notice starts the auction manualy
    /// @param projectId the id of the project
    function startAuction(bytes32 projectId)
        external
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyRole(ADMIN_ROLE)
    {
        _startAuction(projectId, bytes32(0));
    }

    /// @notice close the auction manually
    /// @param projectId the id of the project
    function closeAuction(bytes32 projectId)
        external
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyRole(ADMIN_ROLE)
    {
        auctions[projectId].closeTime = TimerLib._now();
        emit OnAuctionClose({
            projectId: projectId,
            productId: projects[projectId].productId,
            account: msg.sender,
            tokenId: auctions[projectId].settings.tokenId
        });
    }

    /// @notice start the project with a given time
    /// @param projectId the id of the project
    /// @param timeSeconds the time, in seconds
    function startWithTime(bytes32 projectId, uint256 timeSeconds)
        external
        onlyExistingProject(projectId)
        onlyRole(ADMIN_ROLE)
    {
        projects[projectId].paused = false;
        projects[projectId].closeTime = TimerLib._now() + timeSeconds;
    }

    function getProjectState(bytes32 projectId)
        external
        view
        returns (ProjectStateOutput memory state)
    {
        return
            ProjectStateOutput({
                time: TimerLib._now(),
                project: projects[projectId],
                auction: auctions[projectId],
                ranged: rangedProjects[projectId]
            });
    }

    /// @dev in order to make a bid in an auction, a user must pass a certain threshhold, this function calculates it
    /// @param projectId the id of the auction project
    function _getAuctionThreshHold(bytes32 projectId)
        private
        view
        returns (uint256)
    {
        return
            auctions[projectId].highBid +
            (auctions[projectId].highBid *
                auctions[projectId].settings.minBidIncrementPercentage) /
            100;
    }

    /// @notice validates and marks voucher as used
    /// @param voucher the voucher to use
    function _useVoucher(NFTVoucher calldata voucher)
        private
        onlyUnusedVouchers(voucher.voucherId)
        onlyVerifiedVouchers(voucher)
    {
        usedVouchers[voucher.voucherId] = msg.sender;
        emit OnVoucherUsed(voucher.projectId, msg.sender, voucher.voucherId);
    }

    /// @dev take the funds if required, validate required payments before calling this
    /// @param recipient the wallet to get the funds
    /// @param value the amount of funds to withdraw
    function _withdrawIfNeeded(address recipient, uint256 value) private {
        if (value > 0) {
            WithdrawsLib._withdraw(payable(recipient), value);
        }
    }

    /// @notice claim a token from a ranged project
    /// @param voucher the voucher to use
    function claimRanged(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, RANGED_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        require(
            rangedProjects[voucher.projectId].pointer <=
                rangedProjects[voucher.projectId].rangeEnd,
            "Project out of tokens"
        );
        _useVoucher(voucher);

        // get token id and increase pointer
        uint256 tokenId = rangedProjects[voucher.projectId].pointer;
        rangedProjects[voucher.projectId].pointer += 1;

        // transfer the NFT
        _transferToken(voucher.projectId, voucher.userId, tokenId, msg.sender);
        _withdrawIfNeeded(projects[voucher.projectId].wallet, msg.value);
    }

    /// @notice claim a token from a lazy mint project
    /// @param voucher the voucher to use
    function claimLazyMint(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, LAZY_MINT_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        _useVoucher(voucher);
        _mintToken(
            voucher.projectId,
            voucher.tokenId,
            voucher.userId,
            msg.sender
        );
        _withdrawIfNeeded(projects[voucher.projectId].wallet, msg.value);
    }

    /// @notice claim a token from a specified project
    /// @param voucher the voucher to use
    function claimSpecified(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, SPECIFIED_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        _useVoucher(voucher);
        _transferToken(
            voucher.projectId,
            voucher.userId,
            voucher.tokenId,
            msg.sender
        );
        _withdrawIfNeeded(projects[voucher.projectId].wallet, msg.value);
    }

    /// @notice claim a token from an auction project
    /// @param projectId the id of the auction
    /// @param userId the id of the user who makes the claim
    function claimAuction(bytes32 projectId, bytes32 userId)
        external
        payable
        nonReentrant
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyActiveProjects(projectId)
    {
        require(
            TimerLib._now() >= auctions[projectId].closeTime,
            "Auction is still running"
        );
        require(
            msg.sender == auctions[projectId].highBidder,
            "Not highest bidder"
        );
        _transferToken(
            projectId,
            userId,
            auctions[projectId].settings.tokenId,
            msg.sender
        );
        WithdrawsLib._withdraw(
            payable(projects[projectId].wallet),
            auctions[projectId].highBid
        );
    }

    /// @notice make a bid for an auction
    /// @param projectId the id of the auction
    /// @param userId the id of the user who makes the bid
    function bidAuction(bytes32 projectId, bytes32 userId)
        external
        payable
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyActiveProjects(projectId)
    {
        // setup the auction if it's not started yet
        if (auctions[projectId].startTime == 0) {
            _startAuction(projectId, userId);
        } else {
            // auction needs to be running
            require(
                TimerLib._now() < auctions[projectId].closeTime,
                "Auction is over"
            );
        }

        // check the bid value
        if (auctions[projectId].highBid == 0) {
            // needs to be above floor price
            require(
                msg.value >= auctions[projectId].settings.floor,
                "Lower than floor"
            );
        } else {
            require(
                msg.value >= _getAuctionThreshHold(projectId),
                "Lower than threshold"
            );
            // emit the event for outbid
            emit OnAuctionOutBid(
                auctions[projectId].highBidderUserId,
                projectId,
                projects[projectId].productId,
                auctions[projectId].highBidder,
                auctions[projectId].settings.tokenId,
                auctions[projectId].highBid
            );
        }

        // emit the event for the bid
        emit OnAuctionBid(
            userId,
            projectId,
            projects[projectId].productId,
            msg.sender,
            auctions[projectId].settings.tokenId,
            msg.value
        );

        // increase the time if needed
        uint256 timeLeft = auctions[projectId].closeTime - TimerLib._now();
        if (timeLeft < auctions[projectId].settings.timeBufferSeconds) {
            auctions[projectId].closeTime +=
                auctions[projectId].settings.timeBufferSeconds -
                timeLeft;
        }

        // info to refund the last high bidder
        uint256 refundBid = auctions[projectId].highBid;
        address refundBidder = auctions[projectId].highBidder;

        // set the new high bidder
        auctions[projectId].highBid = msg.value;
        auctions[projectId].highBidder = msg.sender;
        auctions[projectId].highBidderUserId = userId;

        // refund the last bidder
        if (refundBid > 0 && refundBidder != address(0)) {
            WithdrawsLib._withdraw(payable(refundBidder), refundBid);
        }
    }

    /// @dev setup a project
    /// @param project the input for the project
    /// @param projectType the type of the project to create/update
    function _setProject(NftProjectInput calldata project, uint8 projectType)
        private
    {
        // check if exists, if so check if the same product type
        if (projects[project.projectId].timestamp != 0) {
            require(
                projects[project.projectId].projectType == projectType,
                "Wrong project type"
            );
        } else {
            // setup for new project, these cannot be edited after creation
            projects[project.projectId].projectId = project.projectId;
            projects[project.projectId].timestamp = TimerLib._now();
            projects[project.projectId].curator = msg.sender;
            projects[project.projectId].count = 0;
            projects[project.projectId].projectType = projectType;
            emit OnProjectCreated({
                projectId: project.projectId,
                projectType: projectType,
                productId: project.productId,
                curator: msg.sender
            });
        }

        // general project settings
        projects[project.projectId].isErc721 = project.isErc721;
        projects[project.projectId].custodial = project.custodial;
        projects[project.projectId].productId = project.productId;
        projects[project.projectId].wallet = project.wallet;
        projects[project.projectId].nftContract = project.nftContract;
        projects[project.projectId].paused = project.paused;
        projects[project.projectId].closeTime = project.closeTime;
        projects[project.projectId].countLimit = project.countLimit;
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hashVoucher(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(bytes32 projectId,address walletAddress,string voucherId,uint256 price,uint256 validUntil,uint256 tokenId)"
                        ),
                        voucher.projectId,
                        voucher.walletAddress,
                        keccak256(bytes(voucher.voucherId)),
                        voucher.price,
                        voucher.validUntil,
                        voucher.tokenId
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _recoverVoucherSigner(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        // take data, hash it
        bytes32 digest = _hashVoucher(voucher);
        // take hash + signature, and get public key
        return ECDSA.recover(digest, voucher.signature);
    }

    /// @notice Transfers a token from a custodial wallet to a user wallet
    /// @param projectId the id of the related project
    /// @param userId the id of the user
    /// @param tokenId the id of the token to transfer
    /// @param to the wallet who would recieve the token
    function _transferToken(
        bytes32 projectId,
        bytes32 userId,
        uint256 tokenId,
        address to
    ) private {
        projects[projectId].count += 1;
        emit OnTokenClaim(
            userId,
            projectId,
            projects[projectId].productId,
            msg.sender,
            tokenId,
            msg.value,
            false
        );
        if (projects[projectId].isErc721) {
            IERC721 nft = IERC721(projects[projectId].nftContract);
            nft.transferFrom(projects[projectId].custodial, to, tokenId);
        } else {
            IERC1155 nft2 = IERC1155(projects[projectId].nftContract);
            nft2.safeTransferFrom(
                projects[projectId].custodial,
                to,
                tokenId,
                1,
                ""
            );
        }
    }

    /// @notice Mints a new token
    /// @dev this only works with manifold.xyz contracts
    /// @param projectId the id of the related project
    /// @param userId the id of the user
    /// @param tokenId the id of the token to mint (only for ERC1155)
    /// @param to the wallet who would recieve the token
    function _mintToken(
        bytes32 projectId,
        uint256 tokenId,
        bytes32 userId,
        address to
    ) private {
        pendingMints[to] = projects[projectId].nftContract;
        projects[projectId].count += 1;

        if (projects[projectId].isErc721) {
            IERC721CreatorCore erc721 = IERC721CreatorCore(
                projects[projectId].nftContract
            );
            uint256 createdToken = erc721.mintExtension(msg.sender);
            emit OnTokenClaim(
                userId,
                projectId,
                projects[projectId].productId,
                to,
                createdToken,
                msg.value,
                true
            );
            return;
        }

        IERC1155CreatorCore erc1155 = IERC1155CreatorCore(
            projects[projectId].nftContract
        );
        address[] memory addresses = new address[](1);
        addresses[0] = to;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // extra setup for ERC1155, need to call "mintExtensionNew" for the first token
        // https://docs.manifold.xyz/v/manifold-for-developers/smart-contracts/manifold-creator/contracts/extensions/extensions-deployment-guide/lazy-mint-extension-erc1155
        if (projects[projectId].count == 1) {
            uint256[] memory ids = erc1155.mintExtensionNew(
                addresses,
                amounts,
                new string[](1)
            );
            emit OnTokenClaim(
                userId,
                projectId,
                projects[projectId].productId,
                to,
                ids[0],
                msg.value,
                true
            );
        } else {
            erc1155.mintExtensionExisting(addresses, tokenIds, amounts);
            emit OnTokenClaim(
                userId,
                projectId,
                projects[projectId].productId,
                to,
                tokenId,
                msg.value,
                true
            );
        }
    }

    /// @notice approve minting for manifold contract (ERC721)
    /// @dev it is verified by setting pendingMints for a wallet address and approving only the specified wallet
    /// @param to the wallet which is expected to recieve the token
    function approveMint(
        address, /* extension */
        address to,
        uint256 /* tokenId */
    ) external virtual override {
        require(msg.sender == pendingMints[to], "Not manifold creator");
        delete pendingMints[to];
    }

    /// @notice approve minting for manifold contract (ERC1155)
    /// @dev it is verified by setting pendingMints for a wallet address and approving only the specified wallet
    /// @param to the wallet(s) which is expected to recieve the token
    function approveMint(
        address, /* extension */
        address[] calldata to,
        uint256[] calldata, /* tokenIds */
        uint256[] calldata /* tokenAmounts */
    ) external virtual override {
        require(msg.sender == pendingMints[to[0]], "Not manifold creator");
        delete pendingMints[to[0]];
    }

    /// @notice derived from ERC165, checks support for interfaces
    /// @param interfaceId the interface id to check
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC165)
        returns (bool)
    {
        return
            // supports open zepplin's access control
            AccessControl.supportsInterface(interfaceId) ||
            // supports maniford mint permissions (erc721)
            interfaceId == type(IERC721CreatorMintPermissions).interfaceId ||
            // supports maniford mint permissions (erc1155)
            interfaceId == type(IERC1155CreatorMintPermissions).interfaceId;
    }

    /// @notice overriding check role (from AccessControl) to treat the owner as a super user
    /// @param role the id of the role
    function _checkRole(bytes32 role) internal view virtual override {
        if (msg.sender != owner()) {
            _checkRole(role, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

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
pragma solidity 0.8.15;

/// @title provides functionality to use time
library WithdrawsLib {
    /// @notice an event to call when funds are withdrawn
    event OnWithdraw(address indexed addr, uint256 balance);

    /// @notice allows to withdraw funds from the contract
    function _withdraw(address payable _to, uint256 amount) internal {
        require(_to != address(0), "address 0");
        uint256 balance = address(this).balance;
        require(balance >= amount, "no funds");

        emit OnWithdraw(_to, amount);
        /// solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _to.call{value: amount}("");
        require(success, "failed withdraw");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct TimerData {
    /// @notice the time the contract started (seconds)
    uint256 startTime;
    /// @notice the time the contract is running from startTime (seconds)
    uint256 runningTime;
}

/// @title provides functionality to use time
library TimerLib {
    using TimerLib for Timer;
    struct Timer {
        /// @notice the time the contract started
        uint256 startTime;
        /// @notice the time the contract is running from startTime
        uint256 runningTime;
        /// @notice is the timer paused
        bool paused;
    }

    /// @notice is the timer running - marked as running and has time remaining
    function _deadline(Timer storage self) internal view returns (uint256) {
        return self.startTime + self.runningTime;
    }

    function _now() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /// @notice is the timer running - marked as running and has time remaining
    function _isRunning(Timer storage self) internal view returns (bool) {
        return !self.paused && (self._deadline() > _now());
    }

    /// @notice starts the timer, call again to restart
    function _start(Timer storage self, uint256 runningTime) internal {
        self.paused = false;
        self.startTime = _now();
        self.runningTime = runningTime;
    }

    /// @notice updates the running time
    function _updateRunningTime(Timer storage self, uint256 runningTime)
        internal
    {
        self.runningTime = runningTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IERC721CreatorMintPermissions is IERC165 {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155Creator compliant extension contracts.
 */
interface IERC1155CreatorMintPermissions is IERC165 {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator interface
 */
interface IERC1155CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     *
     * @param to       - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param amounts  - Can be a single element array (all recipients get the same amount) or a multi-element array
     * @param uris     - If no elements, all tokens use the default uri.
     *                   If any element is an empty string, the corresponding token uses the default uri.
     *
     *
     * Requirements: If to is a multi-element array, then uris must be empty or single element array
     *               If to is a multi-element array, then amounts must be a single element array or a multi-element array of the same size
     *               If to is a single element array, uris must be empty or the same length as amounts
     *
     * Examples:
     *    mintBaseNew(['0x....1', '0x....2'], [1], [])
     *        Mints a single new token, and gives 1 each to '0x....1' and '0x....2'.  Token uses default uri.
     *    
     *    mintBaseNew(['0x....1', '0x....2'], [1, 2], [])
     *        Mints a single new token, and gives 1 to '0x....1' and 2 to '0x....2'.  Token uses default uri.
     *    
     *    mintBaseNew(['0x....1'], [1, 2], ["", "http://token2.com"])
     *        Mints two new tokens to '0x....1'. 1 of the first token, 2 of the second.  1st token uses default uri, second uses "http://token2.com".
     *    
     * @return Returns list of tokenIds minted
     */
    function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint existing token with no extension. Can only be called by an admin.
     *
     * @param to        - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param tokenIds  - Can be a single element array (all recipients get the same token) or a multi-element array
     * @param amounts   - Can be a single element array (all recipients get the same amount) or a multi-element array
     *
     * Requirements: If any of the parameters are multi-element arrays, they need to be the same length as other multi-element arrays
     *
     * Examples:
     *    mintBaseExisting(['0x....1', '0x....2'], [1], [10])
     *        Mints 10 of tokenId 1 to each of '0x....1' and '0x....2'.
     *    
     *    mintBaseExisting(['0x....1', '0x....2'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 2 to '0x....2'.
     *    
     *    mintBaseExisting(['0x....1'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 and 20 of tokenId 2 to '0x....1'.
     *    
     *    mintBaseExisting(['0x....1', '0x....2'], [1], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 1 to '0x....2'.
     *    
     */
    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev mint a token from an extension. Can only be called by a registered extension.
     *
     * @param to       - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param amounts  - Can be a single element array (all recipients get the same amount) or a multi-element array
     * @param uris     - If no elements, all tokens use the default uri.
     *                   If any element is an empty string, the corresponding token uses the default uri.
     *
     *
     * Requirements: If to is a multi-element array, then uris must be empty or single element array
     *               If to is a multi-element array, then amounts must be a single element array or a multi-element array of the same size
     *               If to is a single element array, uris must be empty or the same length as amounts
     *
     * Examples:
     *    mintExtensionNew(['0x....1', '0x....2'], [1], [])
     *        Mints a single new token, and gives 1 each to '0x....1' and '0x....2'.  Token uses default uri.
     *    
     *    mintExtensionNew(['0x....1', '0x....2'], [1, 2], [])
     *        Mints a single new token, and gives 1 to '0x....1' and 2 to '0x....2'.  Token uses default uri.
     *    
     *    mintExtensionNew(['0x....1'], [1, 2], ["", "http://token2.com"])
     *        Mints two new tokens to '0x....1'. 1 of the first token, 2 of the second.  1st token uses default uri, second uses "http://token2.com".
     *    
     * @return Returns list of tokenIds minted
     */
    function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint existing token from extension. Can only be called by a registered extension.
     *
     * @param to        - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param tokenIds  - Can be a single element array (all recipients get the same token) or a multi-element array
     * @param amounts   - Can be a single element array (all recipients get the same amount) or a multi-element array
     *
     * Requirements: If any of the parameters are multi-element arrays, they need to be the same length as other multi-element arrays
     *
     * Examples:
     *    mintExtensionExisting(['0x....1', '0x....2'], [1], [10])
     *        Mints 10 of tokenId 1 to each of '0x....1' and '0x....2'.
     *    
     *    mintExtensionExisting(['0x....1', '0x....2'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 2 to '0x....2'.
     *    
     *    mintExtensionExisting(['0x....1'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 and 20 of tokenId 2 to '0x....1'.
     *    
     *    mintExtensionExisting(['0x....1', '0x....2'], [1], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 1 to '0x....2'.
     *    
     */
    function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev burn tokens. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(address account, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev Total amount of tokens in with a given tokenId.
     */
    function totalSupply(uint256 tokenId) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../extensions/ICreatorExtensionTokenURI.sol";

import "./ICreatorCore.sol";

/**
 * @dev Core creator implementation
 */
abstract contract CreatorCore is ReentrancyGuard, ICreatorCore, ERC165 {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressUpgradeable for address;

    uint256 _tokenCount = 0;

    // Track registered extensions data
    EnumerableSet.AddressSet internal _extensions;
    EnumerableSet.AddressSet internal _blacklistedExtensions;
    mapping (address => address) internal _extensionPermissions;
    mapping (address => bool) internal _extensionApproveTransfers;
    
    // For tracking which extension a token was minted by
    mapping (uint256 => address) internal _tokensExtension;

    // The baseURI for a given extension
    mapping (address => string) private _extensionBaseURI;
    mapping (address => bool) private _extensionBaseURIIdentical;

    // The prefix for any tokens with a uri configured
    mapping (address => string) private _extensionURIPrefix;

    // Mapping for individual token URIs
    mapping (uint256 => string) internal _tokenURIs;

    
    // Royalty configurations
    mapping (address => address payable[]) internal _extensionRoyaltyReceivers;
    mapping (address => uint256[]) internal _extensionRoyaltyBPS;
    mapping (uint256 => address payable[]) internal _tokenRoyaltyReceivers;
    mapping (uint256 => uint256[]) internal _tokenRoyaltyBPS;

    /**
     * External interface identifiers for royalties
     */

    /**
     *  @dev CreatorCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorCore).interfaceId || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    modifier extensionRequired() {
        require(_extensions.contains(msg.sender), "Must be registered extension");
        _;
    }

    /**
     * @dev Only allows non-blacklisted extensions
     */
    modifier nonBlacklistRequired(address extension) {
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
        _;
    }   

    /**
     * @dev See {ICreatorCore-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory extensions) {
        extensions = new address[](_extensions.length());
        for (uint i = 0; i < _extensions.length(); i++) {
            extensions[i] = _extensions.at(i);
        }
        return extensions;
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal {
        require(extension != address(this), "Creator: Invalid");
        require(extension.isContract(), "Creator: Extension must be a contract");
        if (!_extensions.contains(extension)) {
            _extensionBaseURI[extension] = baseURI;
            _extensionBaseURIIdentical[extension] = baseURIIdentical;
            emit ExtensionRegistered(extension, msg.sender);
            _extensions.add(extension);
        }
    }

    /**
     * @dev Unregister an extension
     */
    function _unregisterExtension(address extension) internal {
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
    }

    /**
     * @dev Blacklist an extension
     */
    function _blacklistExtension(address extension) internal {
       require(extension != address(this), "Cannot blacklist yourself");
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
       if (!_blacklistedExtensions.contains(extension)) {
           emit ExtensionBlacklisted(extension, msg.sender);
           _blacklistedExtensions.add(extension);
       }
    }

    /**
     * @dev Set base token uri for an extension
     */
    function _setBaseTokenURIExtension(string calldata uri, bool identical) internal {
        _extensionBaseURI[msg.sender] = uri;
        _extensionBaseURIIdentical[msg.sender] = identical;
    }

    /**
     * @dev Set token uri prefix for an extension
     */
    function _setTokenURIPrefixExtension(string calldata prefix) internal {
        _extensionURIPrefix[msg.sender] = prefix;
    }

    /**
     * @dev Set token uri for a token of an extension
     */
    function _setTokenURIExtension(uint256 tokenId, string calldata uri) internal {
        require(_tokensExtension[tokenId] == msg.sender, "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Set base token uri for tokens with no extension
     */
    function _setBaseTokenURI(string memory uri) internal {
        _extensionBaseURI[address(this)] = uri;
    }

    /**
     * @dev Set token uri prefix for tokens with no extension
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _extensionURIPrefix[address(this)] = prefix;
    }


    /**
     * @dev Set token uri for a token with no extension
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        require(_tokensExtension[tokenId] == address(this), "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Retrieve a token's URI
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        address extension = _tokensExtension[tokenId];
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            if (bytes(_extensionURIPrefix[extension]).length != 0) {
                return string(abi.encodePacked(_extensionURIPrefix[extension],_tokenURIs[tokenId]));
            }
            return _tokenURIs[tokenId];
        }

        if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionTokenURI).interfaceId)) {
            return ICreatorExtensionTokenURI(extension).tokenURI(address(this), tokenId);
        }

        if (!_extensionBaseURIIdentical[extension]) {
            return string(abi.encodePacked(_extensionBaseURI[extension], tokenId.toString()));
        } else {
            return _extensionBaseURI[extension];
        }
    }

    /**
     * Get token extension
     */
    function _tokenExtension(uint256 tokenId) internal view returns (address extension) {
        extension = _tokensExtension[tokenId];

        require(extension != address(this), "No extension for token");
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");

        return extension;
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] storage, uint256[] storage) {
        return (_getRoyaltyReceivers(tokenId), _getRoyaltyBPS(tokenId));
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] storage) {
        if (_tokenRoyaltyReceivers[tokenId].length > 0) {
            return _tokenRoyaltyReceivers[tokenId];
        } else if (_extensionRoyaltyReceivers[_tokensExtension[tokenId]].length > 0) {
            return _extensionRoyaltyReceivers[_tokensExtension[tokenId]];
        }
        return _extensionRoyaltyReceivers[address(this)];        
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] storage) {
        if (_tokenRoyaltyBPS[tokenId].length > 0) {
            return _tokenRoyaltyBPS[tokenId];
        } else if (_extensionRoyaltyBPS[_tokensExtension[tokenId]].length > 0) {
            return _extensionRoyaltyBPS[_tokensExtension[tokenId]];
        }
        return _extensionRoyaltyBPS[address(this)];        
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount){
        address payable[] storage receivers = _getRoyaltyReceivers(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");
        
        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], _getRoyaltyBPS(tokenId)[0]*value/10000);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _tokenRoyaltyReceivers[tokenId] = receivers;
        _tokenRoyaltyBPS[tokenId] = basisPoints;
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _extensionRoyaltyReceivers[extension] = receivers;
        _extensionRoyaltyBPS[extension] = basisPoints;
        if (extension == address(this)) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit ExtensionRoyaltiesUpdated(extension, receivers, basisPoints);
        }
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (uint256)) > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}