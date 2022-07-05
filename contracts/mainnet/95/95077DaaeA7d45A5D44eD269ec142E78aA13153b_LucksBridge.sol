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
pragma solidity ^0.8.0;
pragma abicoder v2;

// imports
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "layerzero-contracts/contracts/lzApp/NonblockingLzApp.sol";

// interfaces
import "./interfaces/ILucksExecutor.sol";
import "./interfaces/ILucksBridge.sol";

contract LucksBridge is NonblockingLzApp, ILucksBridge {
    using SafeMath for uint256;
    //---------------------------------------------------------------------------
    // CONSTANTS
    uint8 internal constant TYPE_CREATE_TASK = 1;
    uint8 internal constant TYPE_WITHDRAW_NFT = 2;

    //---------------------------------------------------------------------------
    // VARIABLES
    mapping(uint16 => mapping(uint8 => uint256)) public gasLookup;
    ILucksExecutor public EXECUTOR;
    bool public useLayerZeroToken;

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyExecutor() {
        require(msg.sender == address(EXECUTOR), "Lucks: caller must be LucksExecutor");
        _;
    }

    constructor(address _lzEndpoint, address _executor) NonblockingLzApp(_lzEndpoint) {
        require(_executor != address(0x0), "Lucks: _executor cannot be 0x0");
        EXECUTOR = ILucksExecutor(_executor);
    }

    // main method
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        uint8 functionType;
        assembly {
            functionType := mload(add(_payload, 32))
        }
        // try-catch all errors/exceptions
        try EXECUTOR.onLzReceive(functionType, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    // ============ EXTERNAL functions ============
    // estimateSendFee

    function quoteLayerZeroFee(uint16 _dstChainId, uint8 _functionType, string memory _note, lzTxObj memory _lzTxParams) 
        external view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = "";
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10000;
        amounts[1] = 10000;

        if (_functionType == TYPE_CREATE_TASK) {
            TaskItem memory item = TaskItem(
                address(0),
                0,
                address(0),
                amounts,
                amounts,
                address(0),
                TaskStatus.Open,
                block.timestamp,
                block.timestamp,
                1000e18,
                1e18,
                1,
                ExclusiveToken(address(0), 1e18),
                0,
                10000
            );
            TaskExt memory ext = TaskExt(1, "nft collection item title", _note);

            payload = abi.encode(TYPE_CREATE_TASK, item, ext);

        } else if (_functionType == TYPE_WITHDRAW_NFT) {

            payload = abi.encode(TYPE_WITHDRAW_NFT, address(0), 10000);

        } else {
            revert("Lucks: unsupported function type");
        }

        bytes memory lzTxParamBuilt = _txParamBuilder( _dstChainId, _functionType, _lzTxParams);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, useLayerZeroToken, lzTxParamBuilt);
    }

    function estimateCreateTaskFee(uint16 _dstChainId, TaskItem memory item, TaskExt memory ext, lzTxObj memory _lzTxParams) 
        external view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(TYPE_CREATE_TASK, item, ext);
        bytes memory lzTxParamBuilt = _txParamBuilder(_dstChainId, TYPE_CREATE_TASK, _lzTxParams);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, useLayerZeroToken, lzTxParamBuilt);
    }

    function estimateWithdrawNFTsFee(uint16 _dstChainId, address payable _user, address nftContract, uint256 depositId, lzTxObj memory _lzTxParams) 
        external view override returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(TYPE_WITHDRAW_NFT, _user, nftContract, depositId);
        bytes memory lzTxParamBuilt = _txParamBuilder(_dstChainId, TYPE_WITHDRAW_NFT, _lzTxParams);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, useLayerZeroToken,lzTxParamBuilt);
    }

    function renounceOwnership() public override onlyOwner {}

    // ============  LOCAL CHAIN (send out message to destination chain)============

    function sendCreateTask(
        uint16 _dstChainId,
        address payable _refundAddress,
        TaskItem memory item,
        TaskExt memory ext,
        lzTxObj memory _lzTxParams
    ) external payable override onlyExecutor {
        bytes memory payload = abi.encode(TYPE_CREATE_TASK, item, ext);
        _call(_dstChainId, TYPE_CREATE_TASK, _refundAddress, _lzTxParams, payload);
    }

    function sendWithdrawNFTs(
        uint16 _dstChainId,        
        address payable _refundAddress,
        address payable _user,
        address nftContract,
        uint256 depositId,
        lzTxObj memory _lzTxParams
    ) external payable override onlyExecutor {
        bytes memory payload = abi.encode(TYPE_WITHDRAW_NFT, _user, nftContract, depositId);
        _call(_dstChainId, TYPE_WITHDRAW_NFT, _refundAddress, _lzTxParams, payload);
    }

    // ============ onlyOwner functions ============

    function setGasAmount(uint16 _dstChainId, uint8 _functionType, uint256 _gasAmount) external onlyOwner {
        require(
            _functionType >= 1 && _functionType <= 4,
            "Lucks: invalid _functionType"
        );
        gasLookup[_dstChainId][_functionType] = _gasAmount;
    }

    // ============ INTERNAL functions ============

    function txParamBuilderType1(uint256 _gasAmount) internal pure returns (bytes memory) {
        uint16 txType = 1;
        return abi.encodePacked(txType, _gasAmount);
    }

    function txParamBuilderType2(uint256 _gasAmount, uint256 _dstNativeAmount, bytes memory _dstNativeAddr) internal pure returns (bytes memory) {
        uint16 txType = 2;
        return abi.encodePacked(txType, _gasAmount, _dstNativeAmount,_dstNativeAddr);
    }

    function _txParamBuilder(
        uint16 _dstChainId,
        uint8 _type,
        lzTxObj memory _lzTxParams
    ) internal view returns (bytes memory) {
        bytes memory lzTxParam;
        address dstNativeAddr;
        {
            bytes memory dstNativeAddrBytes = _lzTxParams.dstNativeAddr;
            assembly {
                dstNativeAddr := mload(add(dstNativeAddrBytes, 20))
            }
        }

        uint256 totalGas = gasLookup[_dstChainId][_type].add(_lzTxParams.dstGasForCall);
        if (_lzTxParams.dstNativeAmount > 0 && dstNativeAddr != address(0x0)) {
            lzTxParam = txParamBuilderType2(totalGas, _lzTxParams.dstNativeAmount, _lzTxParams.dstNativeAddr);
        } else {
            lzTxParam = txParamBuilderType1(totalGas);
        }

        return lzTxParam;
    }

    function _call(
        uint16 _dstChainId, // dst chainId
        uint8 _type, // function type
        address payable _refundAddress, // _user refundAddress
        lzTxObj memory _lzTxParams,
        bytes memory _payload
    ) internal {
        bytes memory _adapterParams = _txParamBuilder(_dstChainId, _type, _lzTxParams);
        address zroPaymentAddr;
        {
            bytes memory zroPaymentAddrBytes = _lzTxParams.zroPaymentAddr;
            assembly {
                zroPaymentAddr := mload(add(zroPaymentAddrBytes, 20))
            }
        }
        _lzSend(_dstChainId, _payload, _refundAddress, zroPaymentAddr, _adapterParams);

        uint64 nextNonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendMsg(_type, nextNonce);
    }

    function setExecutor(ILucksExecutor _executor) external onlyOwner {
        EXECUTOR = _executor;
    }

    function setUseLayerZeroToken(bool enable) external onlyOwner {
        useLayerZeroToken = enable;
    }

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

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint16 => bytes) public trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}