// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// interfaces
import {IProxyNFTStation, DepositNFT} from "./interfaces/IProxyNFTStation.sol";
import {ILucksHelper} from "./interfaces/ILucksHelper.sol";
import "./interfaces/IPunks.sol";

contract ProxyCryptoPunks is IProxyNFTStation, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _depositIds;

    // ============ Public  ============    

    ILucksHelper public HELPER;

    // OpenLuck executors
    mapping(address => bool) public executors;

    // store user deposited nfts, support multiple executors (executor-address => depositId => NFT)    
    mapping(address => mapping(uint256 => DepositNFT)) public deposits;


    modifier onlyExecutor() {
        require(executors[msg.sender] == true, "Lucks: onlyExecutor");
        _;
    }

    // ======== Constructor =========

    /**
     * @notice Constructor
     * @param _executor address
     */
    constructor(address _executor, ILucksHelper _helper) {       
       executors[_executor]= true;
       HELPER = _helper;
    }

    // ============ Public functions ============

    function getNFT(address executor, uint256 depositId) public view override returns(DepositNFT memory){
        return deposits[executor][depositId];
    }

    function deposit(address user, address nft, uint256[] memory tokenIds, uint256[] memory amounts, uint256 endTime) override external payable onlyExecutor 
        returns(uint256 depositId) { 

        require(HELPER.isPunks(nft), "Punks: not Punks");

        // transfer punks to this contract
        // user need to offerPunkForSaleToAddress before createTask
        IPunks punks = HELPER.getPunks();
        
        for (uint256 i = 0; i < tokenIds.length; i++) {

            address holder = punks.punkIndexToAddress(tokenIds[i]);
            require(holder == user, "Punks: not owner of punkIndex");

            punks.buyPunk(tokenIds[i]);    
        }     

        // store deposit record
        _depositIds.increment();
        depositId = _depositIds.current();

        deposits[msg.sender][depositId] = DepositNFT(user, nft, tokenIds, amounts, endTime);
        
        emit Deposit(msg.sender, depositId, user, nft, tokenIds, amounts, endTime);   
    }

    function withdraw(uint256 depositId, address to) override external onlyExecutor {

        require(deposits[msg.sender][depositId].tokenIds.length > 0, "Invalid depositId");

        address nft = deposits[msg.sender][depositId].nftContract;
        uint256[] memory tokenIds = deposits[msg.sender][depositId].tokenIds;
        uint256[] memory amounts = deposits[msg.sender][depositId].amounts;

        // update storage
        delete deposits[msg.sender][depositId];

        // transfer out nft
        IPunks punks = HELPER.getPunks();
      
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address holder = punks.punkIndexToAddress(tokenIds[i]);
            require(holder == address(this), "Punks: proxy is not owner");

            punks.transferPunk(to, tokenIds[i]);
        }

        emit Withdraw(msg.sender, depositId, to, nft, tokenIds, amounts);   
    }

    
    // ============ only Owner ============

    /**
     * @notice for enmergency case
     * for user to redeem
     * in case of cross chain withdraw suck nft, enable to redeem back to seller nft after endTime
    */
    function redeem(address executor, uint256 depositId, address to) override external onlyOwner {
        
        require(deposits[executor][depositId].tokenIds.length > 0, "Invalid depositId");
        require(block.timestamp > deposits[executor][depositId].endTime, "Not time to redeem");
        require(deposits[executor][depositId].user == to , "Invalid redeem to");

        address nft = deposits[executor][depositId].nftContract;
        uint256[] memory tokenIds = deposits[executor][depositId].tokenIds;
        uint256[] memory amounts = deposits[executor][depositId].amounts;

        // update storage
        delete deposits[executor][depositId];

        // transfer back nft to user
        IPunks punks = HELPER.getPunks();
      
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address holder = punks.punkIndexToAddress(tokenIds[i]);
            require(holder == address(this), "Punks: proxy is not owner");

            punks.transferPunk(to, tokenIds[i]);
        }

        emit Redeem(msg.sender, depositId, to, nft, tokenIds, amounts);   
    }


    //  ============ onlyOwner  functions  ============

    function setExecutor(address executor) external onlyOwner {
        executors[executor] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Task {
    uint256 endTime;
    uint256 lastTimestamp;
}

interface ILucksAuto {

    event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);
    event FundsWithdrawn(uint256 amountWithdrawn, address payee);

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);    
    
    event RevertInvoke(uint256 taskId, string reason);

    function addTask(uint256 taskId, uint endTime) external;
    function removeTask(uint256 taskId) external;
    function getQueueTasks() external view returns (uint256[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenLuck
import {TaskItem, TaskExt} from "./ILucksExecutor.sol";

struct lzTxObj {
    uint256 dstGasForCall;
    uint256 dstNativeAmount;
    bytes dstNativeAddr;
    bytes zroPaymentAddr; //  the address of the ZRO token holder who would pay for the transaction
}

interface ILucksBridge {
    // ============= events ====================
    event SendMsg(uint8 msgType, uint64 nonce);

    // ============= Task functions ====================

    function sendCreateTask(
        uint16 _dstChainId,
        address payable _refundAddress,
        TaskItem memory item,
        TaskExt memory ext,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendWithdrawNFTs(
        uint16 _dstChainId,
        address payable _refundAddress,
        address payable _user,
        address nftContract,
        uint256 depositId,
        lzTxObj memory _lzTxParams
    ) external payable;

    // ============= Assets functions ====================

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        string memory _note,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function estimateCreateTaskFee(
        uint16 _dstChainId,
        TaskItem memory item,
        TaskExt memory ext,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function estimateWithdrawNFTsFee(
        uint16 _dstChainId,
        address payable _user,
        address nftContract,
        uint256 depositId,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { lzTxObj } from "./ILucksBridge.sol";

/** 
    TaskStatus
    0) Pending: task created but not reach starttime
    1) Open: task opening
    2) Close: task close, waiting for draw
    3) Success: task reach target, drawed winner
    4) Fail: task Fail and expired
    5) Cancel: task user cancel
 */
enum TaskStatus {
    Pending,
    Open,
    Close,
    Success,
    Fail,
    Cancel
}

struct ExclusiveToken {
    address token; // exclusive token contract address    
    uint256 amount; // exclusive token holding amount required
}

struct TaskItem {

    address seller; // Owner of the NFTs
    uint16 nftChainId; // NFT source ChainId    
    address nftContract; // NFT registry address    
    uint256[] tokenIds; // Allow mulit nfts for sell    
    uint256[] tokenAmounts; // support ERC1155
    
    address acceptToken; // acceptToken    
    TaskStatus status; // Task status    

    uint256 startTime; // Task start time    
    uint256 endTime; // Task end time
    
    uint256 targetAmount; // Task target crowd amount (in wei) for the published item    
    uint256 price; // Per ticket price  (in wei)    
    
    uint16 paymentStrategy; // payment strategy;
    ExclusiveToken exclusiveToken; // exclusive token contract address    
    
    // editable fields
    uint256 amountCollected; // The amount (in wei) collected of this task
    uint256 depositId; // NFTs depositId (system set)
}

struct TaskExt {
    uint16 chainId; // Task Running ChainId   
    string title; // title (for searching keywords)  
    string note;   // memo
}

struct Ticket {
    uint256 number;  // the ticket's id, equal to the end number (last ticket id)
    uint32 count;   // how many QTY the ticket joins, (number-count+1) equal to the start number of this ticket.
    address owner;  // ticket owner
}

struct TaskInfo {
    uint256 lastTID;
    uint256 closeTime;
    uint256 finalNo;
}
 
struct UserState {
    uint256 num; // user buyed tickets count
    bool claimed;  // user claimed
}
interface ILucksExecutor {

    // ============= events ====================

    event CreateTask(uint256 taskId, TaskItem item, TaskExt ext);
    event CancelTask(uint256 taskId, address seller);
    event CloseTask(uint256 taskId, address caller, TaskStatus status);
    event JoinTask(uint256 taskId, address buyer, uint256 amount, uint256 count, uint256 number,string note);
    event PickWinner(uint256 taskId, address winner, uint256 number);
    event ClaimToken(uint256 taskId, address caller, uint256 amount, address acceptToken);
    event ClaimNFT(uint256 taskId, address seller, address nftContract, uint256[] tokenIds);    
    event CreateTickets(uint256 taskId, address buyer, uint256 num, uint256 start, uint256 end);
    event UpdateTaskNote(uint256 taskId, string note);

    event TransferFee(uint256 taskId, address to, address token, uint256 amount); // for protocol
    event TransferShareAmount(uint256 taskId, address to, address token, uint256 amount); // for winners
    event TransferPayment(uint256 taskId, address to, address token, uint256 amount); // for seller

    // ============= functions ====================

    function count() external view returns (uint256);
    function exists(uint256 taskId) external view returns (bool);
    function getTask(uint256 taskId) external view returns (TaskItem memory);
    function getInfo(uint256 taskId) external view returns (TaskInfo memory);
    function isFail(uint256 taskId) external view returns(bool);
    function getChainId() external view returns (uint16);

    function createTask(TaskItem memory item, TaskExt memory ext, lzTxObj memory _param) external payable;
    function updateTaskNote(uint256, string memory note) external;
    function joinTask(uint256 taskId, uint32 num, string memory note) external payable;
    function cancelTask(uint256 taskId, lzTxObj memory _param) external payable;
    function closeTask(uint256 taskId, lzTxObj memory _param) external payable;
    function pickWinner(uint256 taskId, lzTxObj memory _param) external payable;

    function claimTokens(uint256[] memory taskIds) external;
    function claimNFTs(uint256[] memory taskIds, lzTxObj memory _param) external payable;

    function onLzReceive(uint8 functionType, bytes memory _payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openluck interfaces
import {ILucksExecutor, TaskItem, TaskStatus, Ticket} from "./ILucksExecutor.sol";
import {ILucksHelper} from "./ILucksHelper.sol";

interface ILucksGroup {    

    event JoinGroup(address user, uint256 taskId, uint256 groupId);
    event CreateGroup(address user, uint256 taskId, uint256 groupId, uint16 seat);     

    function getGroupUsers(uint256 taskId, address winner) view external returns (address[] memory);
   
    function joinGroup(uint256 taskId, uint256 groupId, uint16 seat) external;
    function createGroup(uint256 taskId, uint16 seat) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import "@openzeppelin/contracts/access/Ownable.sol";

// Openluck interfaces
import {TaskItem, TaskExt} from "./ILucksExecutor.sol";
import {ILucksVRF} from "./ILucksVRF.sol";
import {ILucksGroup} from "./ILucksGroup.sol";
import {ILucksPaymentStrategy} from "./ILucksPaymentStrategy.sol";
import {ILucksAuto} from "./ILucksAuto.sol";
import {IPunks} from "./IPunks.sol";
import {IProxyNFTStation} from "./IProxyNFTStation.sol";

interface ILucksHelper {

    function checkPerJoinLimit(uint32 num) external view returns (bool);
    function checkAcceptToken(address acceptToken) external view returns (bool);
    function checkNFTContract(address addr) external view returns (bool);
    function checkNewTask(address user, TaskItem memory item) external view returns (bool);
    function checkNewTaskExt(TaskExt memory ext) external pure returns (bool);
    function checkNewTaskRemote(TaskItem memory item) external view returns (bool);
    function checkJoinTask(address user, uint256 taskId, uint32 num, string memory note) external view returns (bool);
    function checkTokenListing(address addr, address seller, uint256[] memory tokenIds, uint256[] memory amounts) external view returns (bool,string memory);    
    function checkExclusive(address account, address token, uint256 amount) external view returns (bool);
    function isPunks(address nftContract) external view returns(bool);

    function getProtocolFeeRecipient() external view returns (address);
    function getProtocolFee() external view returns (uint256);
    function getMinTargetLimit(address token) external view returns (uint256);
    function getDrawDelay() external view returns (uint32);

    function getVRF() external view returns (ILucksVRF);
    function getGROUPS() external view returns (ILucksGroup);
    function getSTRATEGY() external view returns (ILucksPaymentStrategy);
    function getAutoClose() external view returns (ILucksAuto);
    function getAutoDraw() external view returns (ILucksAuto);

    function getPunks() external view returns (IPunks);
    function getProxyPunks() external view returns (IProxyNFTStation);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILucksPaymentStrategy {
    
    function getShareRate(uint16 strategyId) external pure returns (uint32);
    function viewPaymentShares(uint16 strategyId, address winner,uint256 taskId) external view returns (uint256, uint256[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILucksVRF {

    event ReqRandomNumber(uint256 taskId, uint256 max, uint256 requestId);
    event RspRandomNumber(uint256 taskId, uint256 requestId, uint256 randomness, uint32 number);    

    /**
     * Requests randomness from a user-provided max
     */
    function reqRandomNumber(uint256 taskId, uint256 max) external;

    /**
     * Views random result
     */
    function viewRandomResult(uint256 taskId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DepositNFT {
    address user; // deposit user
    address nftContract; // NFT registry address    
    uint256[] tokenIds; // Allow mulit nfts for sell    
    uint256[] amounts; // support ERC1155
    uint256 endTime; // Task end time
}

interface IProxyNFTStation {

    event Deposit(address indexed executor, uint256 depositId, address indexed user, address nft, uint256[] tokenIds, uint256[] amounts, uint256 endTime);
    event Withdraw(address indexed executor, uint256 depositId, address indexed to, address nft, uint256[] tokenIds, uint256[] amounts);
    event Redeem(address indexed executor, uint256 depositId, address indexed to, address nft, uint256[] tokenIds, uint256[] amounts);

    function getNFT(address executor, uint256 depositId) external view returns(DepositNFT memory);
    function deposit(address user, address nft, uint256[] memory tokenIds, uint256[] memory amounts, uint256 endTime) external payable returns (uint256 depositId);    
    function withdraw(uint256 depositId, address to) external;    
    function redeem(address executor, uint256 depositId, address to) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
  
  function balanceOf(address account) external view returns (uint256);

  function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

  function buyPunk(uint256 punkIndex) external;

  function transferPunk(address to, uint256 punkIndex) external;
}