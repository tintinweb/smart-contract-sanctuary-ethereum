// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {IBuyout, Auction, State} from "../interfaces/IBuyout.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {IFERC1155} from "../interfaces/IFERC1155.sol";
import {IMigration, Proposal} from "../interfaces/IMigration.sol";
import {IModule} from "../interfaces/IModule.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IVaultRegistry, Permission} from "../interfaces/IVaultRegistry.sol";
import {MerkleBase} from "../utils/MerkleBase.sol";
import {Minter} from "./Minter.sol";
import {Multicall} from "../utils/Multicall.sol";
import {NFTReceiver} from "../utils/NFTReceiver.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

/// @title Migration
/// @author Fractional Art
/// @notice Module contract for vaults to migrate to a new set of permissions
/// - A fractional holder creates a proposal with a target price and list of modules
/// - For 7 days, users can contribute their fractions / ether to signal support
/// - If the target price is reached then a buyout can be triggered and trading
///   against the proposed buyout price can take place to resolve the outcome
/// - If a proposal holds more than 51% of the total supply, the buyout succeeds, a new vault can
///   be created and the underlying assets (ERC-20, ERC-721 and ERC-1155 tokens) can be migrated
contract Migration is
    IMigration,
    MerkleBase,
    Minter,
    Multicall,
    NFTReceiver,
    ReentrancyGuard
{
    /// @notice Address of Buyout module contract
    address payable public buyout;
    /// @notice Address of VaultRegistry contract
    address public registry;
    /// @notice Counter used to assign IDs to new proposals
    uint256 public nextId;
    /// @notice The length for the migration proposal period
    uint256 public constant PROPOSAL_PERIOD = 7 days;
    /// @notice Mapping of a vault to it's proposal migration information
    mapping(address => mapping(uint256 => Proposal)) public migrationInfo;
    /// @notice Mapping of a proposal ID to a user's ether contribution
    mapping(uint256 => mapping(address => uint256)) private userProposalEth;
    /// @notice Mapping of a proposal ID to a user's fractions contribution
    mapping(uint256 => mapping(address => uint256))
        private userProposalFractions;

    /// @notice Initializes buyout, registry, and supply contracts
    constructor(
        address _buyout,
        address _registry,
        address _supply
    ) Minter(_supply) {
        buyout = payable(_buyout);
        registry = _registry;
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    /// @notice Proposes a set of modules and plugins to migrate a vault to
    /// @param _vault Address of the vault
    /// @param _modules Addresses of module contracts
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of plugin function selectors
    /// @param _newFractionSupply New supply of fractional tokens
    /// @param _targetPrice Target price of the buyout
    function propose(
        address _vault,
        address[] calldata _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        uint256 _newFractionSupply,
        uint256 _targetPrice
    ) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);
        // Reverts if buyout state is not inactive
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        State required = State.INACTIVE;
        if (current != required) revert IBuyout.InvalidState(required, current);

        // Initializes migration proposal info
        Proposal storage proposal = migrationInfo[_vault][++nextId];
        proposal.startTime = block.timestamp;
        proposal.targetPrice = _targetPrice;
        proposal.modules = _modules;
        proposal.plugins = _plugins;
        proposal.selectors = _selectors;
        proposal.oldFractionSupply = IVaultRegistry(registry).totalSupply(
            _vault
        );
        proposal.newFractionSupply = _newFractionSupply;
    }

    /// @notice Joins a migration proposal by contributing ether and fractional tokens
    /// @param _vault The address of the vault
    /// @param _proposalId ID of the proposal being contributed to
    /// @param _amount Number of fractions being contributed
    function join(
        address _vault,
        uint256 _proposalId,
        uint256 _amount
    ) external payable nonReentrant {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = IVaultRegistry(registry).vaultToToken(
            _vault
        );
        if (id == 0) revert NotVault(_vault);
        // Reverts if buyout state is not inactive
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        State required = State.INACTIVE;
        if (current != required) revert IBuyout.InvalidState(required, current);

        // Gets the migration proposal for the given ID
        Proposal storage proposal = migrationInfo[_vault][_proposalId];
        // Updates ether balances of the proposal and caller
        proposal.totalEth += msg.value;
        userProposalEth[_proposalId][msg.sender] += msg.value;
        // Deposits fractional tokens into contract
        IFERC1155(token).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            _amount,
            ""
        );
        // Updates fraction balances of the proposal and caller
        proposal.totalFractions += _amount;
        userProposalFractions[_proposalId][msg.sender] += _amount;
    }

    /// @notice Leaves a proposed migration with contribution amount
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal being left
    function leave(address _vault, uint256 _proposalId) external {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = IVaultRegistry(registry).vaultToToken(
            _vault
        );
        if (id == 0) revert NotVault(_vault);
        // Reverts if buyout state is not inactive
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        State required = State.INACTIVE;
        if (current != required) revert IBuyout.InvalidState(required, current);

        // Gets the migration proposal for the given ID
        Proposal storage proposal = migrationInfo[_vault][_proposalId];
        // Updates fraction balances of the proposal and caller
        uint256 amount = userProposalFractions[_proposalId][msg.sender];
        proposal.totalFractions -= amount;
        userProposalFractions[_proposalId][msg.sender] = 0;
        // Updates ether balances of the proposal and caller
        uint256 ethAmount = userProposalEth[_proposalId][msg.sender];
        proposal.totalEth -= ethAmount;
        userProposalEth[_proposalId][msg.sender] = 0;

        // Withdraws fractions from contract back to caller
        IFERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
        // Withdraws ether from contract back to caller
        payable(msg.sender).transfer(ethAmount);
    }

    /// @notice Kicks off the buyout process for a migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal being committed to
    /// @return started Bool status of starting the buyout process
    function commit(address _vault, uint256 _proposalId)
        external
        returns (bool started)
    {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = IVaultRegistry(registry).vaultToToken(
            _vault
        );
        if (id == 0) revert NotVault(_vault);
        // Reverts if buyout state is not inactive
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        State required = State.INACTIVE;
        if (current != required) revert IBuyout.InvalidState(required, current);
        // Reverts if migration is passed proposal period
        Proposal storage proposal = migrationInfo[_vault][_proposalId];
        if (block.timestamp > proposal.startTime + PROPOSAL_PERIOD)
            revert ProposalOver();

        // Calculates current price of the proposal based on total supply
        uint256 currentPrice = _calculateTotal(
            100,
            IVaultRegistry(registry).totalSupply(_vault),
            proposal.totalEth,
            proposal.totalFractions
        );

        // Checks if the current price is greater than target price of the proposal
        if (currentPrice > proposal.targetPrice) {
            // Sets token approval to the buyout contract
            IFERC1155(token).setApprovalFor(address(buyout), id, true);
            // Starts the buyout process
            IBuyout(buyout).start{value: proposal.totalEth}(_vault);
            proposal.isCommited = true;
            started = true;
        }
    }

    /// @notice Settles a migration by ending the buyout
    /// @dev Succeeds if buyout goes through, fails otherwise
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal being settled
    function settleVault(address _vault, uint256 _proposalId) external {
        // Reverts if the migration was not proposed
        Proposal storage proposal = migrationInfo[_vault][_proposalId];
        if (!(proposal.isCommited)) revert NotProposed();
        // Reverts if the migration was unsuccessful
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        if (current != State.SUCCESS) revert UnsuccessfulMigration();
        // Reverts if the new vault has already been deployed
        if (proposal.newVault != address(0))
            revert NewVaultAlreadyDeployed(proposal.newVault);

        // Gets the merkle root for the vault and given proposal ID
        bytes32[] memory merkleTree = generateMerkleTree(proposal.modules);
        bytes32 merkleRoot = getRoot(merkleTree);
        // Deploys a new vault with set permissions and plugins
        address newVault = IVaultRegistry(registry).create(
            merkleRoot,
            proposal.plugins,
            proposal.selectors
        );
        // Sets address of the newly deployed vault
        proposal.newVault = newVault;
        // Emits event for settling the new vault
        emit VaultMigrated(
            _vault,
            newVault,
            _proposalId,
            proposal.modules,
            proposal.plugins,
            proposal.selectors
        );
    }

    /// @notice Mints the fractional tokens for a new vault
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _mintProof Merkle proof for minting fractional tokens
    function settleFractions(
        address _vault,
        uint256 _proposalId,
        bytes32[] calldata _mintProof
    ) external {
        // Reverts if the migration was unsuccessful
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        if (current != State.SUCCESS) revert UnsuccessfulMigration();
        // Reverts if there is no new vault to migrate to
        Proposal storage proposal = migrationInfo[_vault][_proposalId];
        if (proposal.newVault == address(0)) revert NoVaultToMigrateTo();
        // Reverts if fractions of the new vault have already been minted
        if (proposal.fractionsMigrated) revert NewFractionsAlreadyMinted();

        // Mints initial supply of fractions for the new vault
        _mintFractions(
            proposal.newVault,
            address(this),
            proposal.newFractionSupply,
            _mintProof
        );

        migrationInfo[_vault][_proposalId].fractionsMigrated = true;
        // Emits event for minting fractional tokens for the new vault
        emit FractionsMigrated(
            _vault,
            proposal.newVault,
            _proposalId,
            proposal.newFractionSupply
        );
    }

    /// @notice Retrieves ether and fractions deposited from an unsuccessful migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the failed proposal
    function withdrawContribution(address _vault, uint256 _proposalId)
        external
    {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = IVaultRegistry(registry).vaultToToken(
            _vault
        );
        if (id == 0) revert NotVault(_vault);
        // Reverts if caller has no fractional balance to withdraw
        (, , State current, , , ) = IBuyout(buyout).buyoutInfo(_vault);
        if (
            current != State.INACTIVE ||
            migrationInfo[_vault][_proposalId].newVault != address(0)
        ) revert NoContributionToWithdraw();

        // Temporarily store user's fractions for the transfer
        uint256 userFractions = userProposalFractions[_proposalId][msg.sender];
        // Updates fractional balance of caller
        userProposalFractions[_proposalId][msg.sender] = 0;
        // Withdraws fractional tokens from contract back to caller
        IFERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            id,
            userFractions,
            ""
        );

        // Temporarily store user's eth for the transfer
        uint256 userEth = userProposalEth[_proposalId][msg.sender];
        // Udpates ether balance of caller
        userProposalEth[_proposalId][msg.sender] = 0;
        // Withdraws ether from contract back to caller
        payable(msg.sender).transfer(userEth);
    }

    /// @notice Migrates an ERC-20 token to the new vault after a successful migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _token Address of the ERC-20 token
    /// @param _amount Transfer amount
    /// @param _erc20TransferProof Merkle proof for transferring an ERC-20 token
    function migrateVaultERC20(
        address _vault,
        uint256 _proposalId,
        address _token,
        uint256 _amount,
        bytes32[] calldata _erc20TransferProof
    ) external {
        address newVault = migrationInfo[_vault][_proposalId].newVault;
        // Withdraws an ERC-20 token from the old vault and transfers to the new vault
        IBuyout(buyout).withdrawERC20(
            _vault,
            _token,
            newVault,
            _amount,
            _erc20TransferProof
        );
    }

    /// @notice Migrates an ERC-721 token to the new vault after a successful migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _token Address of the ERC-721 token
    /// @param _tokenId ID of the token
    /// @param _erc721TransferProof Merkle proof for transferring an ERC-721 token
    function migrateVaultERC721(
        address _vault,
        uint256 _proposalId,
        address _token,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external {
        address newVault = migrationInfo[_vault][_proposalId].newVault;
        // Withdraws an ERC-721 token from the old vault and transfers to the new vault
        IBuyout(buyout).withdrawERC721(
            _vault,
            _token,
            newVault,
            _tokenId,
            _erc721TransferProof
        );
    }

    /// @notice Migrates an ERC-1155 token to the new vault after a successful migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _token Address of the ERC-1155 token
    /// @param _id ID of the token
    /// @param _amount amount to be transferred
    /// @param _erc1155TransferProof Merkle proof for transferring an ERC-1155 token
    function migrateVaultERC1155(
        address _vault,
        uint256 _proposalId,
        address _token,
        uint256 _id,
        uint256 _amount,
        bytes32[] calldata _erc1155TransferProof
    ) external {
        address newVault = migrationInfo[_vault][_proposalId].newVault;
        // Withdraws an ERC-1155 token from the old vault and transfers to the new vault
        IBuyout(buyout).withdrawERC1155(
            _vault,
            _token,
            newVault,
            _id,
            _amount,
            _erc1155TransferProof
        );
    }

    /// @notice Batch migrates multiple ERC-1155 tokens to the new vault after a successful migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _token Address of the ERC-1155 token
    /// @param _ids IDs of each token type
    /// @param _amounts Transfer amounts per token type
    /// @param _erc1155BatchTransferProof Merkle proof for batch transferring multiple ERC-1155 tokens
    function batchMigrateVaultERC1155(
        address _vault,
        uint256 _proposalId,
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes32[] calldata _erc1155BatchTransferProof
    ) external {
        address newVault = migrationInfo[_vault][_proposalId].newVault;
        // Batch withdraws multiple ERC-1155 tokens from the old vault and transfers to the new vault
        IBuyout(buyout).batchWithdrawERC1155(
            _vault,
            _token,
            newVault,
            _ids,
            _amounts,
            _erc1155BatchTransferProof
        );
    }

    /// @notice Migrates the caller's fractions from an old vault to a new one after a successful migration
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    function migrateFractions(address _vault, uint256 _proposalId) external {
        // Reverts if address is not a registered vault
        (, uint256 id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);
        // Reverts if buyout state is not successful
        (, address proposer, State current, , , ) = IBuyout(buyout).buyoutInfo(
            _vault
        );
        State required = State.SUCCESS;
        if (current != required) revert IBuyout.InvalidState(required, current);
        // Reverts if proposer of buyout is not this contract
        if (proposer != address(this)) revert NotProposalBuyout();

        // Gets the last total supply of fractions for the vault
        (, , , , , uint256 lastTotalSupply) = IBuyout(buyout).buyoutInfo(
            _vault
        );
        // Calculates the total ether amount of a successful proposal
        uint256 totalInEth = _calculateTotal(
            1 ether,
            lastTotalSupply,
            migrationInfo[_vault][_proposalId].totalEth,
            migrationInfo[_vault][_proposalId].totalFractions
        );
        // Calculates balance of caller based on ether contribution
        uint256 balanceContributedInEth = _calculateContribution(
            totalInEth,
            lastTotalSupply,
            userProposalEth[_proposalId][msg.sender],
            userProposalFractions[_proposalId][msg.sender]
        );

        // Gets the token and fraction ID of the new vault
        address newVault = migrationInfo[_vault][_proposalId].newVault;
        (address token, uint256 newFractionId) = IVaultRegistry(registry)
            .vaultToToken(newVault);
        // Calculates share amount of fractions for the new vault based on the new total supply
        uint256 newTotalSupply = IVaultRegistry(registry).totalSupply(newVault);
        uint256 shareAmount = (balanceContributedInEth * newTotalSupply) /
            totalInEth;

        // Transfers fractional tokens to caller based on share amount
        IFERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            newFractionId,
            shareAmount,
            ""
        );
    }

    /// @notice Generates the merkle tree of a given proposal
    /// @param _modules List of module contracts
    /// @return hashes Combined list of leaf nodes
    function generateMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes32[] memory hashes)
    {
        uint256 treeLength;
        uint256 modulesLength = _modules.length;

        unchecked {
            for (uint256 i; i < modulesLength; ++i) {
                treeLength += IModule(_modules[i]).getLeafNodes().length;
            }
        }

        uint256 counter;
        hashes = new bytes32[](treeLength);
        unchecked {
            for (uint256 i; i < modulesLength; ++i) {
                bytes32[] memory leaves = IModule(_modules[i]).getLeafNodes();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    hashes[counter++] = leaves[j];
                }
            }
        }
    }

    /// @notice Calculates the total amount of ether
    /// @param _scalar Scalar used for multiplication
    /// @param _lastTotalSupply Previous total fractional supply of the vault
    /// @param _totalEth Total ether balance of the proposal
    /// @param _totalFractions Total fractional balance of the proposal
    /// @return Total amount of ether
    function _calculateTotal(
        uint256 _scalar,
        uint256 _lastTotalSupply,
        uint256 _totalEth,
        uint256 _totalFractions
    ) private pure returns (uint256) {
        return
            (_totalEth * _scalar) /
            (_scalar - ((_totalFractions * _scalar) / _lastTotalSupply));
    }

    /// @notice Calculates the amount of ether contributed by the user
    /// @param _totalInEth Total amount of ether
    /// @param _lastTotalSupply Previous total fractional supply of the vault
    /// @param _userProposalEth User balance of ether for the proposal
    /// @param _userProposalFractions User balance of fractions for the proposal
    /// @return Total contribution amount
    function _calculateContribution(
        uint256 _totalInEth,
        uint256 _lastTotalSupply,
        uint256 _userProposalEth,
        uint256 _userProposalFractions
    ) private pure returns (uint256) {
        return
            _userProposalEth +
            (_userProposalFractions * _totalInEth) /
            _lastTotalSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "./IModule.sol";
import {Permission} from "./IVaultRegistry.sol";

/// @dev Possible states that a buyout auction may have
enum State {
    INACTIVE,
    LIVE,
    SUCCESS
}

/// @dev Auction information
struct Auction {
    // Time of when buyout begins
    uint256 startTime;
    // Address of proposer creating buyout
    address proposer;
    // Enum state of the buyout auction
    State state;
    // Price of fractional tokens
    uint256 fractionPrice;
    // Balance of ether in buyout pool
    uint256 ethBalance;
    // Total supply recorded before a buyout started
    uint256 lastTotalSupply;
}

/// @dev Interface for Buyout module contract
interface IBuyout is IModule {
    /// @dev Emitted when the payment amount does not equal the fractional price
    error InvalidPayment();
    /// @dev Emitted when the buyout state is invalid
    error InvalidState(State _required, State _current);
    /// @dev Emitted when the caller has no balance of fractional tokens
    error NoFractions();
    /// @dev Emitted when the caller is not the winner of an auction
    error NotWinner();
    /// @dev Emitted when the address is not a registered vault
    error NotVault(address _vault);
    /// @dev Emitted when the time has expired for selling and buying fractions
    error TimeExpired(uint256 _current, uint256 _deadline);
    /// @dev Emitted when the buyout auction is still active
    error TimeNotElapsed(uint256 _current, uint256 _deadline);
    /// @dev Emitted when ether deposit amount for starting a buyout is zero
    error ZeroDeposit();

    /// @dev Event log for starting a buyout
    /// @param _vault Address of the vault
    /// @param _proposer Address that created the buyout
    /// @param _startTime Timestamp of when buyout was created
    /// @param _buyoutPrice Price of buyout pool in ether
    /// @param _fractionPrice Price of fractional tokens
    event Start(
        address indexed _vault,
        address indexed _proposer,
        uint256 _startTime,
        uint256 _buyoutPrice,
        uint256 _fractionPrice
    );
    /// @dev Event log for selling fractional tokens into the buyout pool
    /// @param _seller Address selling fractions
    /// @param _amount Transfer amount being sold
    event SellFractions(address indexed _seller, uint256 _amount);
    /// @dev Event log for buying fractional tokens from the buyout pool
    /// @param _buyer Address buying fractions
    /// @param _amount Transfer amount being bought
    event BuyFractions(address indexed _buyer, uint256 _amount);
    /// @dev Event log for ending an active buyout
    /// @param _vault Address of the vault
    /// @param _state Enum state of auction
    /// @param _proposer Address that created the buyout
    event End(address _vault, State _state, address indexed _proposer);
    /// @dev Event log for cashing out ether for fractions from a successful buyout
    /// @param _vault Address of the vault
    /// @param _casher Address cashing out of buyout
    /// @param _amount Transfer amount of ether
    event Cash(address _vault, address indexed _casher, uint256 _amount);
    /// @dev Event log for redeeming the underlying vault assets from an inactive buyout
    /// @param _vault Address of the vault
    /// @param _redeemer Address redeeming underlying assets
    event Redeem(address _vault, address indexed _redeemer);

    function PROPOSAL_PERIOD() external view returns (uint256);

    function REJECTION_PERIOD() external view returns (uint256);

    function batchWithdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes32[] memory _erc1155BatchTransferProof
    ) external;

    function buyFractions(address _vault, uint256 _amount) external payable;

    function buyoutInfo(address)
        external
        view
        returns (
            uint256 startTime,
            address proposer,
            State state,
            uint256 fractionPrice,
            uint256 ethBalance,
            uint256 lastTotalSupply
        );

    function cash(address _vault, bytes32[] memory _burnProof) external;

    function end(address _vault, bytes32[] memory _burnProof) external;

    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);

    function redeem(address _vault, bytes32[] memory _burnProof) external;

    function registry() external view returns (address);

    function sellFractions(address _vault, uint256 _amount) external;

    function start(address _vault) external payable;

    function supply() external view returns (address);

    function transfer() external view returns (address);

    function withdrawERC20(
        address _vault,
        address _token,
        address _to,
        uint256 _value,
        bytes32[] memory _erc20TransferProof
    ) external;

    function withdrawERC721(
        address _vault,
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32[] memory _erc721TransferProof
    ) external;

    function withdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes32[] memory _erc1155TransferProof
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-20 token contract
interface IERC20 {
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
    event Transfer(address indexed _from, address indexed _to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-721 token contract
interface IERC721 {
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 indexed _id
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _id
    );

    function approve(address _spender, uint256 _id) external;

    function balanceOf(address _owner) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function name() external view returns (string memory);

    function ownerOf(uint256 _id) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _id) external view returns (string memory);

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-1155 token contract
interface IERC1155 {
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event URI(string _value, uint256 indexed _id);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory _owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function isApprovedForAll(address, address) external view returns (bool);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface of ERC-1155 token contract for fractions
interface IFERC1155 {
    /// @dev Emitted when caller is not required address
    error InvalidSender(address _required, address _provided);
    /// @dev Emitted when owner signature is invalid
    error InvalidSignature(address _signer, address _owner);
    /// @dev Emitted when deadline for signature has passed
    error SignatureExpired(uint256 _timestamp, uint256 _deadline);
    /// @dev Emitted when new controller is zero address
    error ZeroAddress();

    /// @dev Event log for updating the Controller of the token contract
    /// @param _newController Address of the controller
    event ControllerTransferred(address indexed _newController);
    /// @dev Event log for updating the metadata contract for a token type
    /// @param _metadata Address of the metadata contract that URI data is stored on
    /// @param _id ID of the token type
    event SetMetadata(address indexed _metadata, uint256 _id);
    /// @dev Event log for updating the royalty of a token type
    /// @param _receiver Address of the receiver of secondary sale royalties
    /// @param _id ID of the token type
    /// @param _percentage Royalty percent on secondary sales
    event SetRoyalty(
        address indexed _receiver,
        uint256 _id,
        uint256 _percentage
    );
    /// @dev Event log for approving a spender of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    event SingleApproval(
        address indexed _owner,
        address indexed _operator,
        uint256 _id,
        bool _approved
    );

    function INITIAL_CONTROLLER() external pure returns (address);

    function NAME() external view returns (string memory);

    function VAULT_REGISTRY() external pure returns (address);

    function VERSION() external view returns (string memory);

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;

    function contractURI() external view returns (string memory);

    function controller() external view returns (address controllerAddress);

    function emitSetURI(uint256 _id, string memory _uri) external;

    function isApproved(
        address,
        address,
        uint256
    ) external view returns (bool);

    function metadata(uint256) external view returns (address);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function nonces(address) external view returns (uint256);

    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external;

    function setContractURI(string memory _uri) external;

    function setMetadata(address _metadata, uint256 _id) external;

    function setRoyalties(
        uint256 _id,
        address _receiver,
        uint256 _percentage
    ) external;

    function totalSupply(uint256) external view returns (uint256);

    function transferController(address _newController) external;

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";
import {State} from "./IBuyout.sol";

/// @dev Struct of migration proposal info for a vault
struct Proposal {
    // Start time of the migration proposal
    uint256 startTime;
    // Target buyout price for the migration
    uint256 targetPrice;
    // Total ether contributed to the migration
    uint256 totalEth;
    // Total fractions contributed to the migration
    uint256 totalFractions;
    // Module contract addresses proposed for the migration
    address[] modules;
    // Plugin contract addresses proposed for the migration
    address[] plugins;
    // Function selectors for the proposed plugins
    bytes4[] selectors;
    // Address for the new vault to migrate to (if buyout is succesful)
    address newVault;
    // Boolean status to check if the propoal is active
    bool isCommited;
    // Old fraction supply for a given vault
    uint256 oldFractionSupply;
    // New fraction supply for a given vault that has succesfully migrated
    uint256 newFractionSupply;
    // Boolean status to check that the fractions have already been migrated
    bool fractionsMigrated;
}

/// @dev Interface for Migration module contract
interface IMigration {
    /// @dev Emitted when someone attempts to mint more new fractions into existence
    error NewFractionsAlreadyMinted();
    /// @dev Emitted when someone attempts to deploy a vault after a migration has already redeployed one
    error NewVaultAlreadyDeployed(address _newVault);
    /// @dev Emitted when a user attempts to withdraw non existing contributions
    error NoContributionToWithdraw();
    /// @dev Emitted when the buyout was not initiated by a migration
    error NotProposalBuyout();
    /// @dev Emitted when an action is taken on a proposal id that does not exist
    error NotProposed();
    /// @dev Emitted when the address is not a registered vault
    error NotVault(address _vault);
    /// @dev Emitted when a user attempts to settle an action before a new vault has been deployed
    error NoVaultToMigrateTo();
    /// @dev Emitted when an action is taken on a migration with a proposal period that has ended
    error ProposalOver();
    /// @dev Emitted when a migration is attempted after an unsuccessful buyout
    error UnsuccessfulMigration();

    /// @dev Event log for minting the new fractional supply for a vault
    /// @param _oldVault Address of the old vault
    /// @param _newVault Address of the new vault
    /// @param _proposalId id of the proposal
    /// @param _amount Amount of fractions settled
    event FractionsMigrated(
        address indexed _oldVault,
        address indexed _newVault,
        uint256 _proposalId,
        uint256 _amount
    );
    /// @dev Event log for settling a vault
    /// @param _oldVault Address of the old vault
    /// @param _newVault Address of the vault
    /// @param _proposalId id of the proposal for the Migration
    /// @param _modules Addresses of module contracts
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of plugin function selectors
    event VaultMigrated(
        address indexed _oldVault,
        address indexed _newVault,
        uint256 _proposalId,
        address[] _modules,
        address[] _plugins,
        bytes4[] _selectors
    );

    function PROPOSAL_PERIOD() external view returns (uint256);

    function batchMigrateVaultERC1155(
        address _vault,
        uint256 _proposalId,
        address _nft,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes32[] memory _erc1155BatchTransferProof
    ) external;

    function buyout() external view returns (address payable);

    function commit(address _vault, uint256 _proposalId)
        external
        returns (bool started);

    function generateMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes32[] memory hashes);

    function join(
        address _vault,
        uint256 _proposalId,
        uint256 _amount
    ) external payable;

    function leave(address _vault, uint256 _proposalId) external;

    function migrateFractions(address _vault, uint256 _proposalId) external;

    function migrateVaultERC20(
        address _vault,
        uint256 _proposalId,
        address _token,
        uint256 _amount,
        bytes32[] memory _erc20TransferProof
    ) external;

    function migrateVaultERC721(
        address _vault,
        uint256 _proposalId,
        address _nft,
        uint256 _tokenId,
        bytes32[] memory _erc721TransferProof
    ) external;

    function migrationInfo(address, uint256)
        external
        view
        returns (
            uint256 startTime,
            uint256 targetPrice,
            uint256 totalEth,
            uint256 totalFractions,
            address newVault,
            bool isCommited,
            uint256 oldFractionSupply,
            uint256 newFractionSupply,
            bool fractionsMigrated
        );

    function nextId() external view returns (uint256);

    function propose(
        address _vault,
        address[] memory _modules,
        address[] memory _plugins,
        bytes4[] memory _selectors,
        uint256 _newFractionSupply,
        uint256 _targetPrice
    ) external;

    function registry() external view returns (address);

    function settleFractions(
        address _vault,
        uint256 _proposalId,
        bytes32[] memory _mintProof
    ) external;

    function settleVault(address _vault, uint256 _proposalId) external;

    function withdrawContribution(address _vault, uint256 _proposalId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Vault proxy contract
interface IVault {
    /// @dev Emitted when execution reverted with no reason
    error ExecutionReverted();
    /// @dev Emitted when ownership of the proxy has been renounced
    error Initialized(address _owner, address _newOwner, uint256 _nonce);
    /// @dev Emitted when there is no implementation stored in methods for a function signature
    error MethodNotFound();
    /// @dev Emitted when the caller is not the owner
    error NotAuthorized(address _caller, address _target, bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotOwner(address _owner, address _caller);
    /// @dev Emitted when the owner is changed during the DELEGATECALL
    error OwnerChanged(address _originalOwner, address _newOwner);
    /// @dev Emitted when passing an EOA or an undeployed contract as the target
    error TargetInvalid(address _target);

    /// @dev Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);
    /// @dev Event log for installing plugins
    /// @param _selectors List of function selectors
    /// @param _plugins List of plugin contracts
    event InstallPlugin(bytes4[] _selectors, address[] _plugins);
    /// @dev Event log for transferring ownership
    /// @param _oldOwner Address of old owner
    /// @param _newOwner Address of new owner
    event TransferOwnership(
        address indexed _oldOwner,
        address indexed _newOwner
    );
    /// @dev Event log for uninstalling plugins
    /// @param _selectors List of function selectors
    event UninstallPlugin(bytes4[] _selectors);

    function execute(
        address _target,
        bytes memory _data,
        bytes32[] memory _proof
    ) external payable returns (bool success, bytes memory response);

    function init() external;

    function install(bytes4[] memory _selectors, address[] memory _plugins)
        external;

    function merkleRoot() external view returns (bytes32);

    function methods(bytes4) external view returns (address);

    function nonce() external view returns (uint256);

    function owner() external view returns (address);

    function setMerkleRoot(bytes32 _rootHash) external;

    function transferOwnership(address _newOwner) external;

    function uninstall(bytes4[] memory _selectors) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Vault permissions
struct Permission {
    // Address of module contract
    address module;
    // Address of target contract
    address target;
    // Function selector from target contract
    bytes4 selector;
}

/// @dev Vault information
struct VaultInfo {
    // Address of FERC1155 token contract
    address token;
    // ID of the token type
    uint256 id;
}

/// @dev Interface for VaultRegistry contract
interface IVaultRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(
        address indexed _vault,
        address indexed _token,
        uint256 _id
    );

    function burn(address _from, uint256 _value) external;

    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function createCollection(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault, address token);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault, address token);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function factory() external view returns (address);

    function fNFT() external view returns (address);

    function fNFTImplementation() external view returns (address);

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address)
        external
        view
        returns (address token, uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Merkle Base
/// @author Modified from Murky (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    constructor() {}

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32 data)
    {
        // Return opposite node if checked node is of bytes zero value
        if (_left == bytes32(0)) return _right;
        if (_right == bytes32(0)) return _left;

        assembly {
            // TODO: This can be aesthetically simplified with a switch. Not sure it will
            // save much gas but there are other optimizations to be had in here.
            if or(lt(_left, _right), eq(_left, _right)) {
                mstore(0x0, _left)
                mstore(0x20, _right)
            }
            if gt(_left, _right) {
                mstore(0x0, _right)
                mstore(0x20, _left)
            }
            data := keccak256(0x0, 0x40)
        }
    }

    /// @notice Verifies the merkle proof of a given value
    /// @param _root Hash of merkle root
    /// @param _proof Merkle proof
    /// @param _valueToProve Leaf node being proven
    /// @return Status of proof verification
    function verifyProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _valueToProve
    ) public pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = _valueToProve;
        unchecked {
            for (uint256 i = 0; i < _proof.length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, _proof[i]);
            }
        }
        return _root == rollingHash;
    }

    /// @notice Generates the merkle root of a tree
    /// @param _data Leaf nodes of the merkle tree
    /// @return Hash of merkle root
    function getRoot(bytes32[] memory _data) public pure returns (bytes32) {
        require(_data.length > 1, "wont generate root for single leaf");
        while (_data.length > 1) {
            _data = hashLevel(_data);
        }
        return _data[0];
    }

    /// @notice Generates the merkle proof for a leaf node in a given tree
    /// @param _data Leaf nodes of the merkle tree
    /// @param _node Index of the node in the tree
    /// @return Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory)
    {
        require(_data.length > 1, "wont generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        uint256 size = log2ceil_naive(_data.length);
        bytes32[] memory result = new bytes32[](size);
        uint256 pos;
        uint256 counter;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (_data.length > 1) {
            unchecked {
                if (_node % 2 == 1) {
                    result[pos] = _data[_node - 1];
                } else if (_node + 1 == _data.length) {
                    result[pos] = bytes32(0);
                    ++counter;
                } else {
                    result[pos] = _data[_node + 1];
                }
                ++pos;
                _node = _node / 2;
            }
            _data = hashLevel(_data);
        }

        // Dynamic array to filter out address(0) since proof size is rounded up
        // This is done to return the actual proof size of the indexed node
        bytes32[] memory arr = new bytes32[](size - counter);
        unchecked {
            uint256 offset;
            for (uint256 i; i < result.length; ++i) {
                if (result[i] != bytes32(0)) {
                    arr[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }

        return arr;
    }

    /// @dev Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data)
        private
        pure
        returns (bytes32[] memory result)
    {
        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always.
        unchecked {
            uint256 length = _data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[](length / 2 + 1);
                result[result.length - 1] = hashLeafPairs(
                    _data[length - 1],
                    bytes32(0)
                );
            } else {
                result = new bytes32[](length / 2);
            }

            // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos;
            for (uint256 i; i < length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so.
        assembly {
            // we check by seeing if x == (~x + 1) & x. This applies a mask
            // to find the lowest set bit of x and then checks it for equality
            // with x. If they are equal, then x is a power of 2.

            /* Example
                x has single bit set
                x := 0000_1000
                (~x + 1) = (1111_0111) + 1 = 1111_1000
                (1111_1000 & 0000_1000) = 0000_1000 == x
                x has multiple bits set
                x := 1001_0010
                (~x + 1) = (0110_1101 + 1) = 0110_1110
                (0110_1110 & x) = 0000_0010 != x
            */

            // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            ceil -= pOf2; // see above
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IMinter} from "../interfaces/IMinter.sol";
import {ISupply} from "../interfaces/ISupply.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";

/// @title Minter
/// @author Fractional Art
/// @notice Module contract for minting a fixed supply of fractions
contract Minter is IMinter {
    /// @notice Address of Supply target contract
    address public supply;

    /// @notice Initializes supply target contract
    constructor(address _supply) {
        supply = _supply;
    }

    /// @notice Gets the list of leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return nodes A list of leaf nodes
    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        nodes = new bytes32[](1);
        nodes[0] = keccak256(abi.encode(getPermissions()[0]));
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](1);
        permissions[0] = Permission(
            address(this),
            supply,
            ISupply.mint.selector
        );
    }

    /// @notice Mints a fraction supply
    /// @param _vault Address of the Vault
    /// @param _to Address of the receiver of fractions
    /// @param _fractionSupply Number of NFT Fractions minted to control the vault
    /// @param _mintProof List of proofs to execute a mint function
    function _mintFractions(
        address _vault,
        address _to,
        uint256 _fractionSupply,
        bytes32[] calldata _mintProof
    ) internal {
        bytes memory data = abi.encodeCall(
            ISupply.mint,
            (_to, _fractionSupply)
        );
        IVault(payable(_vault)).execute(supply, data, _mintProof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Multicall
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// @notice Utility contract that enables calling multiple local methods in a single call
abstract contract Multicall {
    /// @notice Allows multiple function calls within a contract that inherits from it
    /// @param _data List of encoded function calls to make in this contract
    /// @return results List of return responses for each encoded call passed
    function multicall(bytes[] calldata _data)
        external
        returns (bytes[] memory results)
    {
        uint256 length = _data.length;
        results = new bytes[](length);

        bool success;
        for (uint256 i; i < length; ) {
            bytes memory result;
            (success, result) = address(this).delegatecall(_data[i]);
            if (!success) {
                if (result.length == 0) revert();
                // If there is return data and the call wasn't successful, the call reverted with a reason or a custom error.
                _revertedWithReason(result);
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Handles function for revert responses
    /// @param _response Reverted return response from a delegate call
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

/// @title NFT Receiver
/// @author Fractional Art
/// @notice Plugin contract for handling receipts of non-fungible tokens
contract NFTReceiver is ERC721TokenReceiver, ERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC721 token
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "./IModule.sol";
import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for Minter module contract
interface IMinter is IModule {
    function supply() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Supply target contract
interface ISupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}