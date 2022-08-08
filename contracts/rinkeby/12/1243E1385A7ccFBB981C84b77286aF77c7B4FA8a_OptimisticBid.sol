// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IOptimisticBid, BidInfo, State} from "./interfaces/IOptimisticBid.sol";
import {ITransfer} from "../interfaces/ITransfer.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";
import {INounletRegistry} from "./interfaces/INounletRegistry.sol";
import {INounletSupply} from "./interfaces/INounletSupply.sol";
import {INounletAuction} from "./interfaces/INounletAuction.sol";
import {NounletToken} from "./NounletToken.sol";
import {Multicall} from "../utils/Multicall.sol";
import {NFTReceiver} from "../utils/NFTReceiver.sol";
import {SafeSend} from "../utils/SafeSend.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

/// @title OptimisticBid
/// @author Fractional Art
contract OptimisticBid is
    IOptimisticBid,
    Multicall,
    NFTReceiver,
    ReentrancyGuard,
    SafeSend
{
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of Supply target contract
    address public immutable supply;
    /// @notice Address of Transfer target contract
    address public immutable transfer;
    /// @notice Address of the minter contract
    address public immutable auction;
    /// @notice Time length of the rejection period
    uint256 public constant REJECTION_PERIOD = 7 days;
    /// @notice Percentage increase in fraction price to outbid a live pool
    uint256 private constant MIN_INCREASE = 5;
    /// @notice Mapping of vault address to auction struct
    mapping(address => BidInfo) public bidInfo;

    /// @notice Initializes registry, supply, and transfer contracts
    constructor(
        address _registry,
        address _supply,
        address _transfer,
        address _auction
    ) {
        registry = _registry;
        supply = _supply;
        transfer = _transfer;
        auction = _auction;
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    /// @notice Starts the auction for a buyout pool
    /// @param _vault Address of the vault
    /// @param ids Deposit amount of fractions
    function start(
        address _vault,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable nonReentrant {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        uint256 idsLength = ids.length;
        uint256 amountsLength = amounts.length;
        require(idsLength == amountsLength, "length mismatch");

        (, uint96 currentId, uint32 endTime) = INounletAuction(auction)
            .auctionInfo(_vault, 100);
        /// 100 and after the last auction endTime
        if (currentId != uint96(100) && block.timestamp < uint256(endTime))
            revert("still minting");

        (, , State current, , , ) = this.bidInfo(_vault);
        State required = State.INACTIVE;
        if (current != required) revert InvalidState(required, current);

        uint256 totalSupply = NounletToken(token).totalSupply();
        uint256 nounletPrice = msg.value / (totalSupply - ids.length);
        uint256 buyoutPrice = idsLength * nounletPrice + msg.value;

        bidInfo[_vault] = BidInfo(
            block.timestamp,
            msg.sender,
            State.LIVE,
            nounletPrice,
            msg.value,
            totalSupply
        );
        emit Start(
            _vault,
            msg.sender,
            block.timestamp,
            buyoutPrice,
            nounletPrice
        );

        NounletToken(token).safeBatchTransferFrom(
            msg.sender,
            address(this),
            ids,
            amounts,
            ""
        );
    }

    /// @notice Buys fractional tokens in exchange for ether from a pool
    /// @param _vault Address of the vault
    /// @param ids Deposit amount of fractions
    function buyFractions(
        address _vault,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable nonReentrant {
        uint256 idsLength = ids.length;
        uint256 amountsLength = amounts.length;
        require(idsLength == amountsLength, "length mismatch");

        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (
            uint256 startTime,
            address proposer,
            State current,
            uint256 fractionPrice,
            ,

        ) = this.bidInfo(_vault);

        State required = State.LIVE;
        if (current != required) revert InvalidState(required, current);

        {
            uint256 endTime = startTime + REJECTION_PERIOD;
            uint256 timestamp = block.timestamp;
            if (timestamp > endTime) revert TimeExpired(timestamp, endTime);
        }
        if (msg.value != fractionPrice * idsLength) revert InvalidPayment();

        bidInfo[_vault].ethBalance += msg.value;
        emit BuyFractions(msg.sender, idsLength);

        /// we should be storing the amount of tokens vs doing  balanceOf amount
        if (NounletToken(token)._ballots(address(this)) == idsLength)
            _end(_vault, proposer, bidInfo[_vault].ethBalance);
        NounletToken(token).safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            amounts,
            ""
        );
    }

    /// @notice Ends the auction for a live buyout pool
    /// @param _vault Address of the vault
    /// @param ids Deposit amount of fractions
    /// @param _burnProof Merkle proof for burning fractional tokens
    function end(
        address _vault,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32[] calldata _burnProof
    ) external {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (
            uint256 startTime,
            address proposer,
            State current,
            ,
            uint256 ethBalance,

        ) = this.bidInfo(_vault);

        State required = State.LIVE;
        if (current != required) revert InvalidState(required, current);

        /// if we store the balance we could also use it here vs doing balanceOf
        /// to make sure we are buring all the tokens
        uint256 amount = ids.length;
        if (block.timestamp > startTime + 4 days) {
            require(
                amount == NounletToken(token)._ballots(address(this)),
                "missing ids"
            );
            if (amount > 0) {
                bidInfo[_vault].state = State.SUCCESS;
                // Initializes vault transaction
                bytes memory data = abi.encodeCall(
                    INounletSupply.batchBurn,
                    (address(this), ids)
                );
                // Executes burn of fractional tokens from pool
                IVault(payable(_vault)).execute(supply, data, _burnProof);
            } else {
                delete bidInfo[_vault];
                NounletToken(token).safeBatchTransferFrom(
                    address(this),
                    proposer,
                    ids,
                    amounts,
                    ""
                );
                _sendEthOrWeth(proposer, ethBalance);
            }
        } else {
            revert("not endable");
        }
    }

    /// @notice Cashes out proceeds from a successful buyout
    /// @param _vault Address of the vault
    /// @param ids Deposit amount of fractions
    /// @param _burnProof Merkle proof for burning fractional tokens
    function cash(
        address _vault,
        uint256[] memory ids,
        bytes32[] calldata _burnProof
    ) external {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (, , State current, , uint256 ethBalance, ) = this.bidInfo(_vault);
        State required = State.SUCCESS;
        if (current != required) revert InvalidState(required, current);

        uint256 amount = ids.length;
        uint256 totalSupply = NounletToken(token).totalSupply();
        uint256 share = (amount * ethBalance) / totalSupply;
        bidInfo[_vault].ethBalance -= share;

        bytes memory data = abi.encodeCall(
            INounletSupply.batchBurn,
            (msg.sender, ids)
        );
        IVault(payable(_vault)).execute(supply, data, _burnProof);

        _sendEthOrWeth(msg.sender, share);
    }

    /// @notice Withdraws an ERC-721 token from a vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _to Address of the receiver
    /// @param _tokenId ID of the token
    /// @param _erc721TransferProof Merkle proof for transferring an ERC-721 token
    function withdrawERC721(
        address _vault,
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (, address proposer, State current, , , ) = this.bidInfo(_vault);
        State required = State.SUCCESS;
        if (current != required) revert InvalidState(required, current);
        require(msg.sender == proposer, "not winner");

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            ITransfer.ERC721TransferFrom,
            (_token, _vault, _to, _tokenId)
        );
        // Executes transfer of ERC721 token to caller
        IVault(payable(_vault)).execute(transfer, data, _erc721TransferProof);
    }

    /// @notice Gets the list of leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return nodes Hashes of leaf nodes
    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        // Gets list of permissions from this module
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        nodes = new bytes32[](length);
        for (uint256 i; i < length; ) {
            // Hashes permission into leaf node
            nodes[i] = keccak256(abi.encode(permissions[i]));
            // Can't overflow since loop is a fixed size
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](2);
        // Burn function selector from supply contract
        permissions[0] = Permission(
            address(this),
            supply,
            INounletSupply(supply).batchBurn.selector
        );
        // ERC721TransferFrom function selector from transfer contract
        permissions[1] = Permission(
            address(this),
            transfer,
            ITransfer(transfer).ERC721TransferFrom.selector
        );
    }

    function _end(
        address _vault,
        address _proposer,
        uint256 _amount
    ) internal {
        delete bidInfo[_vault];
        _sendEthOrWeth(_proposer, _amount);
    }

    function _calculatePrice(
        uint256 ethAmount,
        uint256 fractionAmount,
        uint256 fractionSupply
    ) internal returns (uint256 fractionPrice, uint256 buyoutPrice) {
        fractionPrice = ethAmount / (fractionSupply - fractionAmount);
        buyoutPrice = fractionAmount * fractionPrice + ethAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "../../interfaces/IModule.sol";
import {Permission} from "../../interfaces/IVaultRegistry.sol";

/// @dev Possible states that a buyout auction may have
enum State {
    INACTIVE,
    LIVE,
    SUCCESS
}

/// @dev Bid information
struct BidInfo {
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
interface IOptimisticBid is IModule {
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

    function REJECTION_PERIOD() external view returns (uint256);

    function bidInfo(address _vault)
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

    function cash(
        address _vault,
        uint256[] memory ids,
        bytes32[] calldata _burnProof
    ) external;

    function end(
        address _vault,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32[] calldata _burnProof
    ) external;

    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);

    function registry() external view returns (address);

    function start(
        address _vault,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable;

    function buyFractions(
        address _vault,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable;

    function supply() external view returns (address);

    function transfer() external view returns (address);

    function withdrawERC721(
        address _vault,
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32[] memory _erc721TransferProof
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Transfer target contract
interface ITransfer {
    /// @dev Emitted when an ERC-20 token transfer returns a falsey value
    /// @param _token The token for which the ERC20 transfer was attempted
    /// @param _from The source of the attempted ERC20 transfer
    /// @param _to The recipient of the attempted ERC20 transfer
    /// @param _amount The amount for the attempted ERC20 transfer
    error BadReturnValueFromERC20OnTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    );
    /// @dev Emitted when a batch ERC-1155 token transfer reverts
    /// @param _token The token for which the transfer was attempted
    /// @param _from The source of the attempted transfer
    /// @param _to The recipient of the attempted transfer
    /// @param _identifiers The identifiers for the attempted transfer
    /// @param _amounts The amounts for the attempted transfer
    error ERC1155BatchTransferGenericFailure(
        address _token,
        address _from,
        address _to,
        uint256[] _identifiers,
        uint256[] _amounts
    );
    /// @dev Emitted when an ERC-721 transfer with amount other than one is attempted
    error InvalidERC721TransferAmount();
    /// @dev Emitted when attempting to fulfill an order where an item has an amount of zero
    error MissingItemAmount();
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    /// @param _account The account that should contain code
    error NoContract(address _account);
    /// @dev Emitted when an ERC-20, ERC-721, or ERC-1155 token transfer fails
    /// @param _token The token for which the transfer was attempted
    /// @param _from The source of the attempted transfer
    /// @param _to The recipient of the attempted transfer
    /// @param _identifier The identifier for the attempted transfer
    /// @param _amount The amount for the attempted transfer
    error TokenTransferGenericFailure(
        address _token,
        address _from,
        address _to,
        uint256 _identifier,
        uint256 _amount
    );

    function ERC20Transfer(
        address _token,
        address _to,
        uint256 _value
    ) external;

    function ERC721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ERC1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function ERC1155BatchTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;
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

import {Permission} from "../../interfaces/IVaultRegistry.sol";

/// @dev Interface for VaultRegistry contract
interface INounletRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    event VaultDeployed(address indexed _vault, address indexed _token);

    function mint(address _to, uint256 _id) external;

    function batchBurn(address _from, uint256[] memory _ids) external;

    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors,
        address _descriptor,
        uint256 _nounId
    ) external returns (address vault);

    function factory() external view returns (address);

    function fNFTImplementation() external view returns (address);

    function uri(address _vault, uint256 _id)
        external
        view
        returns (string memory);

    function vaultToToken(address) external view returns (address token);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Supply target contract
interface INounletSupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _id) external;

    function batchBurn(address _from, uint256[] memory _ids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "../../interfaces/IModule.sol";
import {Permission} from "../../interfaces/IVaultRegistry.sol";

/// @dev Auction information
struct Auction {
    address bidder;
    uint64 amount;
    uint32 endTime;
}

struct Vault {
    address curator;
    uint96 currentId;
}

/// @dev Interface for BaseVault protoform contract
interface INounletAuction is IModule {
    error AuctionAlreadyCreated();
    error AuctionNotCompleted();
    error AuctionExpired();
    error InvalidBidIncrease();
    error NotWinner();

    /// @dev Event log for creation of auction
    /// @param _vault The vault associated with the auction
    /// @param _token The token associated with the vault
    /// @param _id The ID of the token at auction
    /// @param _endTime The end time of the auction
    event Created(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id,
        uint256 _endTime
    );

    /// @dev Event log for bidding on an auction
    /// @param _vault The vault associated with the auction
    /// @param _token The token associated with the vault
    /// @param _id The ID of the token at auction
    /// @param _bidder The address of the bidder
    /// @param _value The ether value of the bid
    event Bid(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id,
        address _bidder,
        uint256 _value
    );

    /// @dev Event log for settling of an auction
    /// @param _vault The vault associated with the auction
    /// @param _token The token associated with the vault
    /// @param _id The ID of the token at auction
    /// @param _winner The address of the highest bidder
    /// @param _amount The ether value of the highest bid
    event Settled(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id,
        address _winner,
        uint256 _amount
    );

    function bid(address _vault) external payable;

    function registry() external view returns (address);

    function createAuction(
        address _vault,
        address _curator,
        bytes32[] calldata _mintProof
    ) external;

    function settleAuction(address _vault, bytes32[] calldata _mintProof)
        external;

    function withdrawNounlet(address _vault, uint256 _id) external;

    function auctionInfo(address, uint256)
        external
        view
        returns (
            address bidder,
            uint64 bid,
            uint32 endTime
        );

    function vaultInfo(address)
        external
        view
        returns (address curator, uint96 currentId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Clone} from "clones-with-immutable-args/src/Clone.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC1155B} from "../utils/ERC1155B.sol";
import {ERC1155BCheckpointable} from "../utils/ERC1155BCheckpointable.sol";
import {ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {INounletToken, Checkpoint} from "./interfaces/INounletToken.sol";
import {INFTReceiver} from "../interfaces/INFTReceiver.sol";
import {SafeCastLib} from "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import {INounsDescriptor, INounsToken, INounsSeeder} from "./NounsMetadata.sol";
import "../constants/Permit.sol";

/// @title Vault
/// @author Fractional Art
/// @notice An ERC-1155 implementation for Fractions
contract NounletToken is Clone, ERC1155BCheckpointable, INounletToken {
    using Strings for uint256;

    uint256 public constant ROYALTY_PERCENT = 3;
    address public constant ROYALTY_RECEIVER = address(0xBEEF);

    /// @notice metadata contract
    address public metadata;

    /// @notice mapping of token ID to nounlet seed
    mapping(uint256 => INounsSeeder.Seed) nounSeed;

    /// @notice Name of the token contract
    string public constant NAME = "NounletToken";
    /// @notice Version number of the token contract
    string public constant VERSION = "1";
    /// @notice URI of contract metadata
    string public constant CONTRACT_URI = "";
    /// @notice Mapping of token type approvals owner => operator => tokenId => approved
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public isApproved;
    /// @notice Mapping to track account nonces for metadata txs owner => nonces
    mapping(address => uint256) public nonces;

    /// @notice Modifier for restricting function calls to the VaultRegistry
    modifier onlyRegistry() {
        address vaultRegistry = VAULT_REGISTRY();
        if (msg.sender != vaultRegistry)
            revert InvalidSender(vaultRegistry, msg.sender);
        _;
    }

    /// @notice Mints new fractions for an ID
    /// @param _to Address to mint fraction tokens to
    /// @param _id Token ID to mint
    /// @param _data Extra calldata to include in the mint
    function mint(
        address _to,
        uint256 _id,
        bytes memory _data
    ) external onlyRegistry {
        _mint(_to, _id, _data);
        //nounSeed[_id] = generateSeed(_id);
    }

    /// @notice Burns fractions for multiple IDs
    /// @param _from Address to burn fraction tokens from
    /// @param _ids Token IDs to burn
    function batchBurn(address _from, uint256[] memory _ids)
        external
        onlyRegistry
    {
        _batchBurn(_from, _ids);
    }

    /// @notice Getter for URI of a token type
    /// @param _id ID of the token type
    function uri(uint256 _id)
        public
        view
        override(ERC1155B, INounletToken)
        returns (string memory)
    {
        INounsSeeder.Seed memory seed = nounSeed[_id];
        uint256 nounId = NOUN_ID();
        address descriptor = DESCRIPTOR();
        string memory noun = nounId.toString();
        string memory token = _id.toString();
        string memory name = string(
            abi.encodePacked("Noun ", noun, " Collective #", token)
        );
        string memory description = string(
            abi.encodePacked(
                "Noun ",
                noun,
                " is collectively owned by a 100 member DAO"
            )
        );

        return
            INounsDescriptor(descriptor).genericDataURI(
                name,
                description,
                seed
            );
    }

    function generateSeed(uint256 tokenId)
        public
        view
        returns (INounsSeeder.Seed memory)
    {
        address descriptor = DESCRIPTOR();
        uint256 nounId = NOUN_ID();
        INounsSeeder.Seed memory nounSeed = INounsToken(
            0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03
        ).seeds(nounId);
        uint48 head = nounSeed.head;

        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        uint256 backgroundCount = INounsDescriptor(descriptor)
            .backgroundCount();
        uint256 bodyCount = INounsDescriptor(descriptor).bodyCount();
        uint256 accessoryCount = INounsDescriptor(descriptor).accessoryCount();
        uint256 glassesCount = INounsDescriptor(descriptor).glassesCount();

        return
            INounsSeeder.Seed({
                background: uint48(uint48(pseudorandomness) % backgroundCount),
                body: uint48(uint48(pseudorandomness >> 48) % bodyCount),
                accessory: uint48(
                    uint48(pseudorandomness >> 96) % accessoryCount
                ),
                head: uint48(head),
                glasses: uint48(uint48(pseudorandomness >> 192) % glassesCount)
            });
    }

    /// @notice Sets the token royalties
    /// @param _id Token ID royalties are being updated for
    /// @param _salePrice Sale price to calculate the royalty for
    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = ROYALTY_RECEIVER;
        royaltyAmount = (_salePrice * ROYALTY_PERCENT) / 100;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return (interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x2a55205a); // ERC165 Interface ID for ERC2981
    }

    /// @notice Permit function that approves an operator for token type with a valid sigature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    /// @param _v The recovery ID (129th byte and chain ID) of the signature used to recover the signer
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline)
            revert SignatureExpired(block.timestamp, _deadline);

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 structHash = _computePermitStructHash(
                _owner,
                _operator,
                _id,
                _approved,
                _deadline
            );

            bytes32 digest = _computeDigest(
                _computeDomainSeparator(),
                structHash
            );

            address signer = ecrecover(digest, _v, _r, _s);

            if (signer == address(0) || signer != _owner)
                revert InvalidSignature(signer, _owner);
        }

        isApproved[_owner][_operator][_id] = _approved;

        emit SingleApproval(_owner, _operator, _id, _approved);
    }

    /// @notice Permit function that approves an operator for all token types with a valid sigature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    /// @param _v The recovery ID (129th byte and chain ID) of the signature used to recover the signer
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline)
            revert SignatureExpired(block.timestamp, _deadline);

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 structHash = _computePermitAllStructHash(
                _owner,
                _operator,
                _approved,
                _deadline
            );

            bytes32 digest = _computeDigest(
                _computeDomainSeparator(),
                structHash
            );

            address signer = ecrecover(digest, _v, _r, _s);

            if (signer == address(0) || signer != _owner)
                revert InvalidSignature(signer, _owner);
        }

        isApprovedForAll[_owner][_operator] = _approved;

        emit ApprovalForAll(_owner, _operator, _approved);
    }

    /// @notice Scoped approvals allow us to eliminate some of the risks associated with setting the approval for an entire collection
    /// @param _operator Address of spender account
    /// @param _id ID of the token type
    /// @param _approved Approval status for operator(spender) account
    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external {
        isApproved[msg.sender][_operator][_id] = _approved;

        emit SingleApproval(msg.sender, _operator, _id, _approved);
    }

    /// @notice Transfer an amount of a token type between two accounts
    /// @param _from Source address for an amount of tokens
    /// @param _to Destination address for an amount of tokens
    /// @param _ids ID of the token type
    /// @param _amounts The amount of tokens being transferred
    /// @param _data Additional calldata
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) public override(ERC1155BCheckpointable, INounletToken) {
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    /// @notice Transfer an amount of a token type between two accounts
    /// @param _from Source address for an amount of tokens
    /// @param _to Destination address for an amount of tokens
    /// @param _id ID of the token type
    /// @param _amount The amount of tokens being transferred
    /// @param _data Additional calldata
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override(ERC1155BCheckpointable, INounletToken) {
        require(
            msg.sender == _from ||
                isApprovedForAll[_from][msg.sender] ||
                isApproved[_from][msg.sender][_id],
            "NOT_AUTHORIZED"
        );

        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    /// @notice VaultRegistry address that is allowed to call mint() and burn()
    function VAULT_REGISTRY() public pure returns (address) {
        return _getArgAddress(0);
    }

    /// @notice
    function DESCRIPTOR() public pure returns (address) {
        return _getArgAddress(20);
    }

    /// @notice
    function NOUN_ID() public pure returns (uint256) {
        return _getArgUint256(40);
    }

    /// @dev Computes hash of permit struct
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    function _computePermitStructHash(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _owner,
                    _operator,
                    _id,
                    _approved,
                    nonces[_owner]++,
                    _deadline
                )
            );
    }

    /// @dev Computes hash of permit all struct
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    function _computePermitAllStructHash(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_ALL_TYPEHASH,
                    _owner,
                    _operator,
                    _approved,
                    nonces[_owner]++,
                    _deadline
                )
            );
    }

    /// @dev Computes domain separator to prevent signature collisions
    /// @return Hash of the contract-specific fields
    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(NAME)),
                    keccak256(bytes(VERSION)),
                    block.chainid,
                    address(this)
                )
            );
    }

    /// @dev Computes digest of domain separator and struct hash
    /// @param _domainSeparator Hash of contract-specific fields
    /// @param _structHash Hash of signature fields struct
    /// @return Hash of the signature digest
    function _computeDigest(bytes32 _domainSeparator, bytes32 _structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainSeparator, _structHash)
            );
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {WETH} from "@rari-capital/solmate/src/tokens/WETH.sol";

/// @title SafeSend
/// @author Fractional Art
/// @notice Utility contract for sending Ether or WETH value to an address
abstract contract SafeSend {
    /// @notice Address for WETH contract on mainnet
    address payable public constant WETH_ADDRESS =
        payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice Attempts to send ether to an address
    /// @param _to Address attemping to send to
    /// @param _value Amount to send
    /// @return success Status of transfer
    function _attemptETHTransfer(address _to, uint256 _value)
        internal
        returns (bool success)
    {
        assembly {
            success := call(gas(), _to, _value, 0, 0, 0, 0)
        }
    }

    /// @notice Sends eth or weth to an address
    /// @param _to Address to send to
    /// @param _value Amount to send
    function _sendEthOrWeth(address _to, uint256 _value) internal {
        if (!_attemptETHTransfer(_to, _value)) {
            WETH(WETH_ADDRESS).deposit{value: _value}();
            WETH(WETH_ADDRESS).transfer(_to, _value);
        }
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

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type bytes32
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgBytes32(uint256 argOffset)
        internal
        pure
        returns (bytes32 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (uint256[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        uint256 el;
        arr = new uint256[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            assembly {
                // solhint-disable-next-line no-inline-assembly
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgBytes32Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (bytes32[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        bytes32 el;
        arr = new bytes32[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            assembly {
                // solhint-disable-next-line no-inline-assembly
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

/// @notice Minimalist and gas efficient ERC1155 implementation optimized for single supply ids.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155B.sol)
abstract contract ERC1155B {
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

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                            ERC1155B STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public ownerOf;

    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 bal)
    {
        address idOwner = ownerOf[id];

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

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
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        require(from == ownerOf[id], "WRONG_FROM"); // Can only transfer from the owner.

        // Can only transfer 1 with ERC1155B.
        require(amount == 1, "INVALID_AMOUNT");

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];
                amount = amounts[i];

                // Can only transfer from the owner.
                require(from == ownerOf[id], "WRONG_FROM");

                // Can only transfer 1 with ERC1155B.
                require(amount == 1, "INVALID_AMOUNT");

                ownerOf[id] = to;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
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
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        // Minting twice would effectively be a force transfer.
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    1,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                // Minting twice would effectively be a force transfer.
                require(ownerOf[id] == address(0), "ALREADY_MINTED");

                ownerOf[id] = to;

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(address from, uint256[] memory ids) internal virtual {
        // Burning unminted tokens makes no sense.
        require(from != address(0), "INVALID_FROM");

        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                require(ownerOf[id] == from, "WRONG_FROM");

                ownerOf[id] = address(0);

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        ownerOf[id] = address(0);

        emit TransferSingle(msg.sender, owner, address(0), id, 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC1155B.sol";
import "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

///  TODO: try out libraries to see how syntax changes:
/// https://docs.soliditylang.org/en/v0.8.15/solidity-by-example.html?highlight=modular#modular-contracts
abstract contract ERC1155BCheckpointable is ERC1155B {
    using SafeCastLib for uint256;
    /// @notice Defines decimals as per ERC-20 convention to make integrations with 3rd party governance platforms easier
    uint8 public constant decimals = 0;
    uint96 public totalSupply;
    uint96 public constant maxSupply = type(uint96).max;

    /// delegator -> delegatee
    mapping(address => address) private _delegates;
    /// delegator -> #votes
    mapping(address => uint96) public _ballots;
    /// delegatee -> #checkpoints
    mapping(address => uint32) public numCheckpoints;
    /// delegatee -> checkpoint# -> checkpoint(fromBlock,#votes)
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 pos = numCheckpoints[account];
        return pos != 0 ? checkpoints[account][pos - 1].votes : 0;
    }

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(block.number > blockNumber, "UNDETERMINED");

        uint32 pos = numCheckpoints[account];
        if (pos == 0) return 0;

        if (checkpoints[account][pos - 1].fromBlock <= blockNumber)
            return checkpoints[account][pos - 1].votes;

        if (checkpoints[account][0].fromBlock > blockNumber) return 0;

        uint32 lower;
        uint32 upper = pos - 1;

        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) return cp.votes;
            cp.fromBlock < blockNumber ? lower = center : upper = center - 1;
        }

        return checkpoints[account][lower].votes;
    }

    /// from nouns
    function votesToDelegate(address delegator) public view returns (uint96) {
        return _ballots[delegator];
    }

    /// from nouns
    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    function safeTransferFrom(
        address src,
        address dst,
        uint256 id,
        uint256,
        bytes calldata data
    ) public virtual override {
        _ballots[src]--;
        _ballots[dst]++;
        _moveDelegates(delegates(src), delegates(dst), 1);
        super.safeTransferFrom(src, dst, id, 1, data);
    }

    function safeBatchTransferFrom(
        address src,
        address dst,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        uint96 amount = ids.length.safeCastTo96();
        _ballots[src] -= amount;
        _ballots[dst] += amount;
        _moveDelegates(delegates(src), delegates(dst), amount);
        super.safeBatchTransferFrom(src, dst, ids, amounts, data);
    }

    function _mint(
        address dst,
        uint256 id,
        bytes memory data
    ) internal virtual override {
        totalSupply++;
        _ballots[dst]++;
        _moveDelegates(address(0), delegates(dst), 1);
        super._mint(dst, id, data);
    }

    function _batchMint(
        address dst,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual override {
        uint96 amount = ids.length.safeCastTo96();
        totalSupply += amount;
        _ballots[dst] += amount;
        _moveDelegates(address(0), delegates(dst), amount);
        super._batchMint(dst, ids, data);
    }

    function _burn(uint256 id) internal virtual override {
        totalSupply--;
        _ballots[msg.sender]--;
        _moveDelegates(delegates(msg.sender), address(0), 1);
        super._burn(id);
    }

    function _batchBurn(address src, uint256[] memory ids)
        internal
        virtual
        override
    {
        uint96 amount = ids.length.safeCastTo96();
        totalSupply -= amount;
        _ballots[src] -= amount;
        _moveDelegates(delegates(src), address(0), amount);
        super._batchBurn(src, ids);
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);
        _delegates[delegator] = delegatee;
        uint96 amount = votesToDelegate(delegator);
        _moveDelegates(currentDelegate, delegatee, amount);
    }

    function _moveDelegates(
        address src,
        address dst,
        uint96 amount
    ) internal {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                uint96 srcOld;
                uint32 srcPos = numCheckpoints[src];

                srcOld = srcPos != 0 ? checkpoints[src][srcPos - 1].votes : 0;

                uint96 srcNew = srcOld - amount;

                _writeCheckpoint(src, srcPos, srcNew);
            }

            if (dst != address(0)) {
                uint32 dstPos = numCheckpoints[dst];
                uint96 dstOld;

                dstOld = dstPos != 0 ? checkpoints[dst][dstPos - 1].votes : 0;

                uint96 dstNew = dstOld + amount;

                _writeCheckpoint(dst, dstPos, dstNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 pos,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = block.number.safeCastTo32();
        if (
            pos > 0 && checkpoints[delegatee][pos - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][pos - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][pos] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = pos + 1;
        }
    }
}

contract MockERC1155BCheckpointable is ERC1155BCheckpointable {
    function uri(uint256) public pure override returns (string memory) {}

    function batchMint(address to, uint256[] memory ids) public {
        _batchMint(to, ids, "");
    }

    function batchBurn(address from, uint256[] memory ids) public {
        _batchBurn(from, ids);
    }

    function mint(address to, uint256 id) public {
        _mint(to, id, "");
    }

    function burn(uint256 id) public {
        _burn(id);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {INounsSeeder} from "../NounsMetadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

struct Checkpoint {
    uint64 fromTimestamp;
    uint192 votes;
}

/// @dev Interface of ERC-1155 token contract for fractions
interface INounletToken is IERC165 {
    /// @dev Emitted when caller is not required address
    error InvalidSender(address required, address provided);
    /// @dev Emitted when owner signature is invalid
    error InvalidSignature(address signer, address owner);
    /// @dev Emitted when deadline for signature has passed
    error SignatureExpired(uint256 timestamp, uint256 deadline);
    /// @dev Emitted when new controller is zero address
    error ZeroAddress();

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
    /// @dev Event log for changing of delegate
    /// @param _delegator Address of delegator
    /// @param _id Token ID
    /// @param _fromDelegate Address of previous delegate
    /// @param _toDelegate Address of new delegate
    event DelegateChanged(
        address indexed _delegator,
        uint256 _id,
        address indexed _fromDelegate,
        address indexed _toDelegate
    );
    /// @dev Event log for change in votes to delegate
    /// @param _delegate Address of delegate
    /// @param _id Token ID
    /// @param _previousBalance Previous balance of votes
    /// @param _newBalance New balance of votes
    event DelegateVotesChanged(
        address indexed _delegate,
        uint256 _id,
        uint256 _previousBalance,
        uint256 _newBalance
    );

    function NAME() external view returns (string memory);

    function VAULT_REGISTRY() external pure returns (address);

    function DESCRIPTOR() external pure returns (address);

    function NOUN_ID() external pure returns (uint256);

    function VERSION() external view returns (string memory);

    function CONTRACT_URI() external view returns (string memory);

    function isApproved(
        address,
        address,
        uint256
    ) external view returns (bool);

    function mint(
        address _to,
        uint256 _id,
        bytes memory _data
    ) external;

    function batchBurn(address _from, uint256[] memory _ids) external;

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

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external;

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NFT Receiver contract
interface INFTReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }
}

interface INounsDescriptor {
    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);
}

interface INounsToken {
    function seeds(uint256) external view returns (INounsSeeder.Seed memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Name of the FERC1155 token contract
string constant NAME = "FERC1155";

/// @dev Version number of the FERC1155 token contract
string constant VERSION = "1";

/// @dev The EIP-712 typehash for the contract's domain
bytes32 constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

/// @dev The EIP-712 typehash for the permit struct used by the contract
bytes32 constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address operator,uint256 tokenId,bool approved,uint256 nonce,uint256 deadline)"
);

/// @dev The EIP-712 typehash for the permit all struct used by the contract
bytes32 constant PERMIT_ALL_TYPEHASH = keccak256(
    "PermitAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)"
);

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}