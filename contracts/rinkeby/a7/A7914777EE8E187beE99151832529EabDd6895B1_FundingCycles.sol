// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity ^0.8.4;

import "./abstract/TerminalUtility.sol";
import "./interfaces/IProjects.sol";
import "./interfaces/IFundingCycles.sol";

contract FundingCycles is IFundingCycles, TerminalUtility {
    uint256 private constant SECONDS_IN_DAY = 86400;

    /// @notice The total number of funding cycles created, which is used for issuing funding cycle IDs.
    /// @dev Funding cycles have IDs > 0.
    uint256 public override count = 0;

    // mapping id with funding cycle properties
    mapping(uint256 => FundingCycleProperties) public fundingCycleProperties;

    // mapping projectId with latest funding cycle properties id
    mapping(uint256 => uint256) public override latestIdFundingProject;

    // mapping fundingCycleId with auctionPass
    mapping(uint256 => AuctionedPass[]) public override fundingCycleIdAuctionedPass;

    uint256 public constant override MAX_CYCLE_LIMIT = 32;

    constructor(ITerminalDirectory _terminalDirectory) TerminalUtility(_terminalDirectory) {}

    function getFundingCycle(uint256 _fundingCycleId)
        public
        view
        override
        returns (FundingCycleProperties memory)
    {
        return fundingCycleProperties[_fundingCycleId];
    }

    /**
     * @notice configure funding cycle
        create funding cycle:
        return a new funding cycle by call init if there is no funding cycle exist in the project
        return existing funding cycle if the funding cycle still active in the project
        return new funding cycle if there is no active funding cycle
     * @param _projectId Dao Id
     * @param _duration duration for funding cycle
     * @param _cycleLimit limit for funding cycle 
     * @param _target target fund raising
     * @param _lockRate rate to lock in treasury
     * @param _auctionedPass auction pass information
     */

    function configure(
        uint256 _projectId,
        uint256 _duration,
        uint256 _cycleLimit,
        uint256 _target,
        uint256 _lockRate,
        AuctionedPass[] calldata _auctionedPass
    ) external override onlyTerminal(_projectId) returns (FundingCycleProperties memory) {
        require(_duration <= type(uint256).max, "FundingCycles::configure: BAD_DURATION");

        // Currency must be less than the limit.
        require(_cycleLimit <= MAX_CYCLE_LIMIT, "FundingCycles::configure: BAD_CYCLE_LIMIT");

        uint256 configTime = block.timestamp;

        if (latestIdFundingProject[_projectId] == 0) {
            //create a new one and return it because no fundingcycle active
            uint256 fundingCycleId = _init(
                _projectId,
                _duration,
                _cycleLimit,
                0,
                _target,
                _lockRate
            );
            for (uint256 i = 0; i < _auctionedPass.length; i++) {
                fundingCycleIdAuctionedPass[fundingCycleId].push(_auctionedPass[i]);
            }

            emit Configure(fundingCycleId, _projectId, configTime, msg.sender);

            return getFundingCycle(fundingCycleId);
        } else {
            //check if the latestIdFunding project still running
            uint256 latestId = latestIdFundingProject[_projectId];
            FundingCycleProperties memory latestFundingCycleProperties = fundingCycleProperties[
                latestId
            ];
            if (
                block.timestamp >= latestFundingCycleProperties.start &&
                block.timestamp <=
                latestFundingCycleProperties.start +
                    (latestFundingCycleProperties.duration * SECONDS_IN_DAY)
            ) {
                emit FundingCycleExist(latestId, _projectId, configTime, msg.sender);

                return latestFundingCycleProperties;
            }
            uint256 fundingCycleId = _init(
                _projectId,
                _duration,
                _cycleLimit,
                latestId,
                _target,
                _lockRate
            );
            for (uint256 i = 0; i < _auctionedPass.length; i++) {
                fundingCycleIdAuctionedPass[fundingCycleId].push(_auctionedPass[i]);
            }
            emit Configure(fundingCycleId, _projectId, configTime, msg.sender);
            return getFundingCycle(fundingCycleId);
        }
    }

    /**
        @notice 
        Initializes a funding cycle with the appropriate properties.
        * @param _projectId Dao Id
        * @param _duration duration for funding cycle
        * @param _cycleLimit limit for funding cycle 
        * @param _previousId previous funding cycle id before this funding cycle
        * @param _target target fund raising
        * @param _lockRate rate to lock in treasury
    */
    function _init(
        uint256 _projectId,
        uint256 _duration,
        uint256 _cycleLimit,
        uint256 _previousId,
        uint256 _target,
        uint256 _lockRate
    ) private returns (uint256 newFundingCycleId) {
        count += 1;
        FundingCycleProperties memory newFundingCycle = FundingCycleProperties({
            id: count,
            projectId: _projectId,
            start: block.timestamp,
            duration: _duration,
            cycleLimit: _cycleLimit,
            isPaused: false,
            previousId: _previousId,
            target: _target,
            lockRate: _lockRate,
            deposited: 0,
            tappable: 0,
            locked: 0,
            unLocked: 0,
            reachMaxLock: false
        });
        latestIdFundingProject[_projectId] = newFundingCycle.id;
        fundingCycleProperties[count] = newFundingCycle;

        emit Init(count, _projectId, _previousId, newFundingCycle.start);
        return count;
    }

    /**
    @notice Current active funding cycle of this dao project
    * @param _projectId Dao Id
    */
    function currentOf(uint256 _projectId)
        external
        view
        override
        returns (FundingCycleProperties memory)
    {
        uint256 latestId = latestIdFundingProject[_projectId];
        return getFundingCycle(latestId);
    }

    function setPauseFundingCycle(uint256 _projectId, bool _paused)
        external
        override
        onlyTerminal(_projectId)
        returns (bool)
    {
        uint256 latestId = latestIdFundingProject[_projectId];
        FundingCycleProperties storage latestFundingCycleProperties = fundingCycleProperties[
            latestId
        ];
        latestFundingCycleProperties.isPaused = _paused;
        return true;
    }

    /**
     * @notice
     */
    function updateLocked(uint256 _projectId, uint256 _fundingCycleId, uint256 _amount) external override onlyTerminal(_projectId) {
        FundingCycleProperties storage _fundingCycle = fundingCycleProperties[_fundingCycleId];
        if (_fundingCycle.reachMaxLock) return;
        uint256 _lockToTreasury = (_amount * _fundingCycle.lockRate) / 100;
        uint256 _deposit = _amount - _lockToTreasury;
        _fundingCycle.locked = _fundingCycle.locked + _lockToTreasury;
        _fundingCycle.deposited = _fundingCycle.deposited + _deposit;
        uint256 _maxLocked = (_fundingCycle.target * _fundingCycle.lockRate) / 100;
        uint256 _maxDeposit = _fundingCycle.target - _maxLocked;

        if (_fundingCycle.locked >= _maxLocked) {
            // overflowed
            _fundingCycle.reachMaxLock = true;
            _fundingCycle.locked = _maxLocked;
            uint256 _overflowed = _fundingCycle.deposited - _maxDeposit;
            _fundingCycle.deposited = _maxDeposit;
            _deposit = _deposit - _overflowed;
        }

        _fundingCycle.tappable = _fundingCycle.tappable + _deposit;
    }

    function tap(uint256 _projectId, uint256 _amount) external override onlyTerminal(_projectId) {
        uint256 _total = getTappableAmount(_projectId);
        if (_amount > _total) revert InsufficientBalance();

        uint256 _latestId = latestIdFundingProject[_projectId];
        FundingCycleProperties storage _fundingCycle = fundingCycleProperties[_latestId];
        uint256 _leftAmount = _amount;
        while (_leftAmount > 0) {
            uint256 _tapAmount = _leftAmount > _fundingCycle.tappable
                ? _fundingCycle.tappable
                : _leftAmount;
            _fundingCycle.tappable = _fundingCycle.tappable - _tapAmount;
            _leftAmount = _leftAmount - _tapAmount;
            _fundingCycle = fundingCycleProperties[_fundingCycle.previousId];
        }
    }

    /**
     * @notice ok
     */
    function unlock(uint256 _projectId, uint256 _amount) external override onlyTerminal(_projectId) {
        uint256 _total = getUnLockableAmount(_projectId);
        if (_amount > _total) revert InsufficientBalance();

        uint256 _latestId = latestIdFundingProject[_projectId];
        FundingCycleProperties storage _fundingCycle = fundingCycleProperties[_latestId];
        uint256 _leftAmount = _amount;
        while (_leftAmount > 0) {
            uint256 _unLockable = _fundingCycle.locked - _fundingCycle.unLocked;
            uint256 _unLockAmount = _leftAmount > _unLockable ? _unLockable : _leftAmount;
            _fundingCycle.unLocked = _fundingCycle.unLocked + _unLockAmount;
            _fundingCycle.tappable = _fundingCycle.tappable + _unLockAmount;
            _leftAmount = _leftAmount - _unLockAmount;
            _fundingCycle = fundingCycleProperties[_fundingCycle.previousId];
        }
    }

    /**
     * @notice ok
     */
    function getTappableAmount(uint256 _projectId)
        public
        view
        override
        returns (uint256 _totalTappable)
    {
        uint256 _latestId = latestIdFundingProject[_projectId];
        FundingCycleProperties memory _fundingCycle = fundingCycleProperties[_latestId];

        _totalTappable = _fundingCycle.tappable;
        while (_fundingCycle.previousId != 0) {
            _fundingCycle = fundingCycleProperties[_fundingCycle.previousId];
            _totalTappable = _totalTappable + _fundingCycle.tappable;
        }
    }

    /**
     * @notice
     */
    function getUnLockableAmount(uint256 _projectId)
        public
        view
        override
        returns (uint256 _totalUnLockable)
    {
        uint256 _latestId = latestIdFundingProject[_projectId];
        FundingCycleProperties memory _fundingCycle = fundingCycleProperties[_latestId];

        _totalUnLockable = _fundingCycle.locked - _fundingCycle.unLocked;
        while (_fundingCycle.previousId != 0) {
            _fundingCycle = fundingCycleProperties[_fundingCycle.previousId];
            _totalUnLockable = _totalUnLockable + _fundingCycle.locked - _fundingCycle.unLocked;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ITerminalUtility.sol";

abstract contract TerminalUtility is ITerminalUtility {
    modifier onlyTerminal(uint256 _projectId) {
        require(
            address(terminalDirectory.terminalOf(_projectId)) == msg.sender,
            "TerminalUtility: UNAUTHORIZED"
        );
        _;
    }

    ITerminalDirectory public immutable override terminalDirectory;

    /** 
      @param _terminalDirectory A directory of a project's current terminal to receive payments in.
    */
    constructor(ITerminalDirectory _terminalDirectory) {
        terminalDirectory = _terminalDirectory;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IProjects.sol";

enum ProposalState {
    Pending,
    Active,
    Queued,
    Failed,
    Expired,
    Executed
}

struct Proposal {
    string uri;
    uint256 id;
    bytes32 hash;
    uint256 start;
    uint256 end;
    uint256 minVoters;
    uint256 minVotes;
    ProposalState state;
}

struct Vote {
    uint256 totalVoters;
    uint256 totalVotes;
}

struct NFTStake {
    uint256 tokenId;
    uint256 amount; // ERC721: 1
    uint256 timestamp;
}

interface IDAOGovernorBooster {
    /************************* EVENTS *************************/
    event CreateGovernor(uint256 indexed projectId, address membershipPass, address admin);

    event ProposalCreated(
        uint256 indexed projectId,
        address indexed from,
        uint256 proposalId,
        Proposal proposal
    );

    event ExecuteProposal(
        uint256 indexed projectId,
        address indexed from,
        uint256 proposalId,
        uint8 proposalResult
    );

    event StakeNFT(uint256 indexed projectId, address indexed from, NFTStake[] membershipPass);

    event UnStakeNFT(uint256 indexed projectId, address indexed from);

    /************************* ERRORS *************************/
    error InsufficientBalance();
    error UnknowProposal();
    error BadPeriod();
    error InvalidSignature();
    error TransactionNotMatch();
    error TransactionReverted();
    error NotProjectOwner();
    error UnAuthorized();
    error AlreadyStaked();

    /************************* VIEW FUNCTIONS *************************/
    function createGovernor(
        uint256 _projectId,
        address _membershipPass,
        address _admin
    ) external;

    function propose(
        uint256 _projectId,
        address _proposer,
        Proposal memory _properties,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata
    ) external payable returns (uint256);

    function execute(
        uint256 _projectId,
        uint256 _proposalId,
        uint8 _proposeResult,
        bytes memory _signatureBySigner,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data
    ) external returns (bytes memory);

    function stakeNFT(
        uint256 _projectId,
        address _from,
        NFTStake[] memory _membershipPass
    ) external returns (uint256);

    function unStakeNFT(uint256 _projectId, address _recepient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct AuctionedPass {
    // tier id, indexed from 0
    uint256 id;
    uint256 weight;
    uint256 salePrice;
    // the amount of tickets open for sale in this round
    uint256 saleAmount;
    // the amount of tickets airdroped to community
    uint256 communityAmount;
    // who own the community vouchers can free mint the community ticket
    address communityVoucher;
    // the amount of tickets reserved to next round
    uint256 reservedAmount;
}

// 1st funding cycle:
// gold ticket (erc1155) :  11 salePrice 1 reserveampiunt

// silver ticket: 10 salePrice  2 reserveampiunt

struct FundingCycleProperties {
    uint256 id;
    uint256 projectId;
    uint256 previousId;
    uint256 start;
    uint256 target;
    uint256 lockRate;
    uint256 deposited;
    uint256 tappable;
    uint256 locked;
    uint256 unLocked;
    bool reachMaxLock;
    uint256 duration;
    bool isPaused;
    uint256 cycleLimit;
}

struct FundingCycleParameter {
    uint256 duration;
    uint256 cycleLimit;
    uint256 target;
}

interface IFundingCycles {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        address caller
    );

    event FundingCycleExist(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        address caller
    );

    event Init(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 previous,
        uint256 start
    );

    error InsufficientBalance();

    function latestIdFundingProject(uint256 _projectId) external view returns (uint256);

    function fundingCycleIdAuctionedPass(uint256 _projectId, uint256 _tierId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256
        );

    function count() external view returns (uint256);

    function MAX_CYCLE_LIMIT() external view returns (uint256);

    function getFundingCycle(uint256 _fundingCycleId)
        external
        view
        returns (FundingCycleProperties memory);

    function configure(
        uint256 _projectId,
        uint256 _duration,
        uint256 _cycleLimit,
        uint256 _target,
        uint256 _lockRate,
        AuctionedPass[] memory _auctionedPass
    ) external returns (FundingCycleProperties memory);

    function currentOf(uint256 _projectId) external view returns (FundingCycleProperties memory);

    function setPauseFundingCycle(uint256 _projectId, bool _paused) external returns (bool);

    function updateLocked(uint256 _projectId, uint256 _fundingCycleId, uint256 _amount) external;

    function tap(uint256 _projectId, uint256 _amount) external;

    function unlock(uint256 _projectId, uint256 _amount) external;

    function getTappableAmount(uint256 _projectId) external view returns (uint256);

    function getUnLockableAmount(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IMembershipPass is IERC1155, IERC2981 {
    /************************* EVENTS *************************/

    event MintPass(address indexed account, uint256 indexed tier, uint256 amount);

    event BatchMintPass(address indexed _account, uint256[] _tiers, uint256[] _amounts);

    /************************* VIEW FUNCTIONS *************************/

    function feeCollector() external view returns (address);

    /**
     * @notice
     * Contract-level metadata for OpenSea
     * see https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice
     * Implement ERC2981, but actually the most marketplaces have their own royalty logic
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount);

    /************************* STATE MODIFYING FUNCTIONS *************************/

    function mintPassForMember(
        address _account,
        uint256 _token,
        uint256 _amount
    ) external;

    function batchMintPassForMember(
        address _account,
        uint256[] memory _tokens,
        uint256[] memory _amounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMembershipPass.sol";
import "./IRoyaltyDistributor.sol";

struct PayInfoWithWeight {
    uint256 amount;
    uint256 weight;
}
struct WeightInfo {
    uint256 amount;
    uint256 baseWeight;
    uint256 sqrtWeight;
}

interface IMembershipPassBooth {
    /************************* EVENTS *************************/
    event Issue(
        uint256 indexed projectId,
        string uri,
        address membershipPass,
        uint256[] tierFee,
        uint256[] tierCapacity
    );

    event BatchMintTicket(
        address indexed from,
        uint256 indexed projectId,
        uint256[] tiers,
        uint256[] amounts
    );

    event AirdropBatchMintTicket(
        address indexed from,
        uint256 indexed projectId,
        uint256[] tiers,
        uint256[] amounts
    );

    /************************* VIEW FUNCTIONS *************************/
    function tierSizeOf(uint256 _projectId) external view returns (uint256);

    function membershipPassOf(uint256 _projectId) external view returns (IMembershipPass);

    function royaltyDistributorOf(uint256 _projectId) external view returns (IRoyaltyDistributor);

    function totalSqrtWeightBy(uint256 _fundingCycleId, uint256 _tierId) external returns (uint256);

    function depositedWeightBy(
        address _from,
        uint256 _fundingCycleId,
        uint256 _tierId
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimedOf(address _from, uint256 _fundingCycleId) external returns (bool);

    function airdropClaimedOf(address _from, uint256 _fundingCycleId) external returns (bool);

    function airdropClaimedAmountOf(uint256 _fundingCycleId, uint256 _tierId)
        external
        returns (uint256);

    function issue(
        uint256 _projectId,
        string memory _uri,
        string memory _contractURI,
        uint256[] memory _tierFee,
        uint256[] memory _tierCapacity
    ) external returns (address);

    function stake(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        PayInfoWithWeight[] memory _payInfo
    ) external;

    function batchMintTicket(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        uint256[] memory _amounts
    ) external;

    function airdropBatchMintTicket(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        uint256[] memory _tierIds,
        uint256[] memory _amounts
    ) external;

    function getUserAllocation(
        address _user,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) external view returns (uint256[] memory);

    function getEstimatingUserAllocation(
        uint256 _projectId,
        uint256 _fundingCycleId,
        uint256[] memory _weights
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITerminal.sol";

interface IProjects is IERC721 {
    error EmptyHandle();
    error TakenedHandle();

    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 indexed handle,
        string uri,
        address caller
    );

    event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

    event SetUri(uint256 indexed projectId, string uri, address caller);

    function count() external view returns (uint256);

    function uriOf(uint256 _projectId) external view returns (string memory);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;

    function setUri(uint256 _projectId, string calldata _uri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltyDistributor {
	/**
	 * @notice
	 * Claim according to votes share
	 */
	function claimRoyalties() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IProjects.sol";
import "./IFundingCycles.sol";
import "./ITerminalDirectory.sol";
import "./IDAOGovernorBooster.sol";
import "./IMembershipPassBooth.sol";

struct ImmutablePassTier {
    uint256 id;
    uint256 tierFee;
    uint256 multiplier;
    uint256 tierCapacity;
}

interface ITerminal {
    event Pay(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 amount,
        uint256[] payData,
        string note
    );

    event Airdrop(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256[] tierIds,
        uint256[] amounts,
        string note
    );

    event Claim(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 refundAmount,
        uint256[] offeringAmounts
    );

    event Tap(
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 govFeeAmount,
        uint256 netTransferAmount
    );

    event UnlockTreasury(uint256 indexed projectId, uint256 unlockAmount);

    error MultiplierNotMatch();
    error Voucher721(address _voucher);
    error NoCommunityTicketLeft();
    error AllReservedAmoungZero();
    error FundingCycleNotExist();
    error FundingCyclePaused();
    error InsufficientBalance();
    error AlreadyClaimed();
    error ZeroAddress();
    error BadClaimPeriod();
    error OnlyGovernor();

    function superAdmin() external view returns (address);

    function lockRate() external view returns (uint256);

    function tapFee() external view returns (uint256);

    function contributeFee() external view returns (uint256);

    function devTreasury() external view returns (address);

    function projects() external view returns (IProjects);

    function fundingCycles() external view returns (IFundingCycles);

    function membershipPassBooth() external view returns (IMembershipPassBooth);

    function daoGovernorBooster() external view returns (IDAOGovernorBooster);

    function terminalDirectory() external view returns (ITerminalDirectory);

    function balanceOf(uint256 _projectId) external view returns (uint256);

    function createDao(
        address _owner,
        bytes32 _handle,
        string memory _projectURI,
        string memory _contractURI,
        string memory _membershipPassURI,
        ImmutablePassTier[] memory _tiers,
        FundingCycleParameter memory _params,
        AuctionedPass[] memory _auctionedPass
    ) external;

    function createNewFundingCycle(
        uint256 projectId,
        FundingCycleParameter calldata _params,
        AuctionedPass[] calldata _auctionedPass
    ) external;

    /**
     * @notice
     * Contribute to a project
     */
    function contribute(
        uint256 _projectId,
        address _beneficiary,
        uint256[] memory _payData,
        string memory _memo
    ) external payable;

    /**
     * @notice
     * Community members can mint the  membership pass for free
     */
    function communityContribute(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _beneficiary,
        string memory _memo
    ) external;

    /**
     * @notice
     * Claim menbershippass or refund overlow part
     */
    function claimPassOrRefund(
        address _from,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) external;

    /**
     * @notice
     * Tap into funds that have been contributed to a project's funding cycles
     */
    function tap(uint256 _projectId, uint256 _amount) external;

    /**
     * @notice Unlock the locked balance in dao treasury
     */
    function unLockTreasury(uint256 _projectId, uint256 _unlockAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITerminal.sol";
import "./IProjects.sol";

interface ITerminalDirectory {
    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITerminalDirectory.sol";

interface ITerminalUtility {
    function terminalDirectory() external view returns (ITerminalDirectory);
}