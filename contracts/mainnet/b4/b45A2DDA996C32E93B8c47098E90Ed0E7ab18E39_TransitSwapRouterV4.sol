// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ReentrancyGuard.sol";
import "./libraries/RevertReasonParser.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/TransitStructs.sol";
import "./libraries/Ownable.sol";
import "./libraries/Pausable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITransitSwapFees.sol";

contract TransitSwapRouterV4 is Ownable, ReentrancyGuard, Pausable {

    using SafeMath for uint256;

    address private _transit_swap;
    address private _transit_cross;
    address private _transit_fees;
    //default: Pre-trade fee model
    mapping(uint8 => bool) private _swap_type_mode;
    //whitelist wrapped
    mapping(address => bool) private _wrapped_allowed;

    event Receipt(address from, uint256 amount);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    event ChangeTransitSwap(address indexed previousTransit, address indexed newTransit);
    event ChangeTransitCross(address indexed previousTransit, address indexed newTransit);
    event ChangeTransitFees(address indexed previousTransitFees, address indexed newTransitFees);
    event ChangeSwapTypeMode(uint8[] types, bool[] newModes);
    event ChangeWrappedAllowed(address[] wrappeds, bool[] newAllowed);
    event TransitSwapped(address indexed srcToken, address indexed dstToken, address indexed dstReceiver, address trader, bool feeMode, uint256 amount, uint256 returnAmount, uint256 minReturnAmount, uint256 fee, uint256 toChainID, string channel, uint256 time);


    constructor(address transitSwap_, address transitCross_, address transitFees_, address executor) Ownable (executor) {
        _transit_swap = transitSwap_;
        _transit_cross = transitCross_;
        _transit_fees = transitFees_;
    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function transitSwap() external view returns (address) {
        return _transit_swap;
    }

    function transitCross() external view returns (address) {
        return _transit_cross;
    }

    function transitFees() external view returns (address) {
        return _transit_fees;
    }

    function swapTypeMode(uint8 swapType) external view returns (bool) {
        return _swap_type_mode[swapType];
    }

    function wrappedAllowed(address wrapped) external view returns (bool) {
        return _wrapped_allowed[wrapped];
    }

    function changeTransitSwap(address newTransit) external onlyExecutor {
        address oldTransit = _transit_swap;
        _transit_swap = newTransit;
        emit ChangeTransitSwap(oldTransit, newTransit);
    }

    function changeTransitCross(address newTransit) external onlyExecutor {
        address oldTransit = _transit_cross;
        _transit_cross = newTransit;
        emit ChangeTransitCross(oldTransit, newTransit);
    }

    function changeTransitFees(address newTransitFees) external onlyExecutor {
        address oldTransitFees = _transit_fees;
        _transit_fees = newTransitFees;
        emit ChangeTransitFees(oldTransitFees, newTransitFees);
    }

    function changeSwapTypeMode(uint8[] memory swapTypes) external onlyExecutor {
        bool[] memory newModes = new bool[](swapTypes.length);
        for (uint index; index < swapTypes.length; index++) {
            _swap_type_mode[swapTypes[index]] = !_swap_type_mode[swapTypes[index]];
            newModes[index] = _swap_type_mode[swapTypes[index]];
        }
        emit ChangeSwapTypeMode(swapTypes, newModes);
    }

    function changeWrappedAllowed(address[] calldata wrappeds) external onlyExecutor {
        bool[] memory newAllowed = new bool[](wrappeds.length);
        for (uint index; index < wrappeds.length; index++) {
            _wrapped_allowed[wrappeds[index]] = !_wrapped_allowed[wrappeds[index]];
            newAllowed[index] = _wrapped_allowed[wrappeds[index]];
        }
        emit ChangeWrappedAllowed(wrappeds, newAllowed);
    }

    function changePause(bool paused) external onlyExecutor {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function _beforeSwap(bool preTradeModel, TransitStructs.TransitSwapDescription calldata desc) private returns (uint256 swapAmount, uint256 fee, uint256 beforeBalance) {
        if (preTradeModel) {
            fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, desc.amount, desc.swapType, desc.channel);
        }
        if (TransferHelper.isETH(desc.srcToken)) {
            require(msg.value == desc.amount, "TransitSwap: invalid msg.value");
            swapAmount = desc.amount.sub(fee);
        } else {
            if (preTradeModel) {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);
                TransferHelper.safeTransfer(desc.srcToken, desc.srcReceiver, desc.amount.sub(fee));
            } else {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, desc.srcReceiver, desc.amount);
            }
        }
        if (TransferHelper.isETH(desc.dstToken)) {
            if (preTradeModel) {
                beforeBalance = desc.dstReceiver.balance;
            } else {
                if (desc.swapType == uint8(TransitStructs.SwapTypes.swap)) {
                    require(_wrapped_allowed[desc.wrappedNative], "TransitSwap: invalid wrapped address");
                    beforeBalance = IERC20(desc.wrappedNative).balanceOf(address(this));
                } else {
                    beforeBalance = address(this).balance;
                }
            }
        } else {
            if (preTradeModel) {
                beforeBalance = IERC20(desc.dstToken).balanceOf(desc.dstReceiver);
            } else {
                beforeBalance = IERC20(desc.dstToken).balanceOf(address(this));
            }
        }
    }

    function _afterSwap(bool preTradeModel, TransitStructs.TransitSwapDescription calldata desc, uint256 beforeBalance) private returns (uint256 returnAmount, uint256 fee) {
        if (TransferHelper.isETH(desc.dstToken)) {
            if (preTradeModel) {
                returnAmount = desc.dstReceiver.balance.sub(beforeBalance);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
            } else {
                if (desc.swapType == uint8(TransitStructs.SwapTypes.swap)) {
                    returnAmount = IERC20(desc.wrappedNative).balanceOf(address(this)).sub(beforeBalance);
                    require(_wrapped_allowed[desc.wrappedNative], "TransitSwap: invalid wrapped address");
                    TransferHelper.safeWithdraw(desc.wrappedNative, returnAmount);
                } else {
                    returnAmount = address(this).balance.sub(beforeBalance);
                }
                fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, returnAmount, desc.swapType, desc.channel);
                returnAmount = returnAmount.sub(fee);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
                TransferHelper.safeTransferETH(desc.dstReceiver, returnAmount);
            }
        } else {
            if (preTradeModel) {
                returnAmount = IERC20(desc.dstToken).balanceOf(desc.dstReceiver).sub(beforeBalance);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
            } else {
                returnAmount = IERC20(desc.dstToken).balanceOf(address(this)).sub(beforeBalance);
                fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, returnAmount, desc.swapType, desc.channel);
                returnAmount = returnAmount.sub(fee);
                uint256 receiverBeforeBalance = IERC20(desc.dstToken).balanceOf(desc.dstReceiver);
                TransferHelper.safeTransfer(desc.dstToken, desc.dstReceiver, returnAmount);
                returnAmount = IERC20(desc.dstToken).balanceOf(desc.dstReceiver).sub(receiverBeforeBalance);
                require(returnAmount >= desc.minReturnAmount, "TransitSwap: insufficient return amount");
            }
        }        
    }

    function swap(TransitStructs.TransitSwapDescription calldata desc, TransitStructs.CallbytesDescription calldata callbytesDesc) external payable nonReentrant whenNotPaused {
        require(callbytesDesc.calldatas.length > 0, "TransitSwap: data should be not zero");
        require(desc.amount > 0, "TransitSwap: amount should be greater than 0");
        require(desc.dstReceiver != address(0), "TransitSwap: receiver should be not address(0)");
        require(desc.minReturnAmount > 0, "TransitSwap: minReturnAmount should be greater than 0");
        if (callbytesDesc.flag == uint8(TransitStructs.Flag.aggregate)) {
            require(desc.srcToken == callbytesDesc.srcToken, "TransitSwap: invalid callbytesDesc");
        }
        bool preTradeModel = !_swap_type_mode[desc.swapType];
        (uint256 swapAmount, uint256 fee, uint256 beforeBalance) = _beforeSwap(preTradeModel, desc);

        {
            //bytes4(keccak256(bytes('callbytes(TransitStructs.CallbytesDescription)')));
            (bool success, bytes memory result) = _transit_swap.call{value:swapAmount}(abi.encodeWithSelector(0xccbe4007, callbytesDesc));
            if (!success) {
                revert(RevertReasonParser.parse(result,"TransitSwap:"));
            }
        }

        (uint256 returnAmount, uint256 postFee) = _afterSwap(preTradeModel, desc, beforeBalance);
        if (postFee > fee) {
            fee = postFee;
        }
        _emitTransit(desc, preTradeModel, fee, returnAmount);
    }

    function _beforeCross(TransitStructs.TransitSwapDescription calldata desc) private returns (uint256 swapAmount, uint256 fee, uint256 beforeBalance) {
        fee = ITransitSwapFees(_transit_fees).getFeeRate(msg.sender, desc.amount, desc.swapType, desc.channel);
        if (TransferHelper.isETH(desc.srcToken)) {
            require(msg.value == desc.amount, "TransitSwap: invalid msg.value");
            swapAmount = desc.amount.sub(fee);
        } else {
            beforeBalance = IERC20(desc.srcToken).balanceOf(_transit_cross);
            if (fee == 0) {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, _transit_cross, desc.amount);
            } else {
                TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);
                TransferHelper.safeTransfer(desc.srcToken, _transit_cross, desc.amount.sub(fee));
            }
        }
    }

    function cross(TransitStructs.TransitSwapDescription calldata desc, TransitStructs.CallbytesDescription calldata callbytesDesc) external payable nonReentrant whenNotPaused {
        require(callbytesDesc.calldatas.length > 0, "TransitSwap: data should be not zero");
        require(desc.amount > 0, "TransitSwap: amount should be greater than 0");
        require(desc.srcToken == callbytesDesc.srcToken, "TransitSwap: invalid callbytesDesc");
        (uint256 swapAmount, uint256 fee, uint256 beforeBalance) = _beforeCross(desc);
        
        {
            //bytes4(keccak256(bytes('callbytes(TransitStructs.CallbytesDescription)')));
            (bool success, bytes memory result) = _transit_cross.call{value:swapAmount}(abi.encodeWithSelector(0xccbe4007, callbytesDesc));
            if (!success) {
                revert(RevertReasonParser.parse(result,"TransitSwap:"));
            }
        }
        
        if (!TransferHelper.isETH(desc.srcToken)) {
            require(IERC20(desc.srcToken).balanceOf(_transit_cross) >= beforeBalance, "TransitSwap: invalid cross");
        }

        _emitTransit(desc, true, fee, 0);
    }

    function _emitTransit(TransitStructs.TransitSwapDescription calldata desc, bool preTradeModel, uint256 fee, uint256 returnAmount) private {
        emit TransitSwapped(
            desc.srcToken, 
            desc.dstToken, 
            desc.dstReceiver, 
            msg.sender, 
            preTradeModel, 
            desc.amount, 
            returnAmount, 
            desc.minReturnAmount, 
            fee, 
            desc.toChainID, 
            desc.channel,
            block.timestamp
        );
    }

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for(uint index; index < tokens.length; index++) {
            uint amount;
            if(TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

interface ITransitSwapFees {
    
    function getFeeRate(address trader, uint256 tradeAmount, uint8 swapType, string memory channel) external  view returns (uint payFees);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint x, uint y) internal pure returns (uint z) {
        require(y != 0 , 'ds-math-div-zero');
        z = x / y;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// Add executor extension

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;
    address private _executor;
    address private _pendingExecutor;
    bool internal _initialized;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ExecutorshipTransferStarted(address indexed previousExecutor, address indexed newExecutor);
    event ExecutorshipTransferred(address indexed previousExecutor, address indexed newExecutor);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address newExecutor) {
        require(!_initialized, "Ownable: initialized");
        _transferOwnership(msg.sender);
        _transferExecutorship(newExecutor);
        _initialized = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        _checkExecutor();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current executor.
     */
    function executor() public view virtual returns (address) {
        return _executor;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Returns the address of the pending executor.
     */
    function pendingExecutor() public view virtual returns (address) {
        return _pendingExecutor;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Throws if the sender is not the executor.
     */
    function _checkExecutor() internal view virtual {
        require(executor() == msg.sender, "Ownable: caller is not the executor");
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
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers executorship of the contract to a new account (`newExecutor`).
     * Can only be called by the current executor.
     */
    function transferExecutorship(address newExecutor) public virtual onlyExecutor {
        _pendingExecutor = newExecutor;
        emit ExecutorshipTransferStarted(executor(), newExecutor);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        delete _pendingOwner;
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferExecutorship(address newExecutor) internal virtual {
        delete _pendingExecutor;
        address oldExecutor = _executor;
        _executor = newExecutor;
        emit ExecutorshipTransferred(oldExecutor, newExecutor);
    }

    function acceptOwnership() external {
        address sender = msg.sender;
        require(pendingOwner() == sender, "Ownable: caller is not the new owner");
        _transferOwnership(sender);
    }

    function acceptExecutorship() external {
        address sender = msg.sender;
        require(pendingExecutor() == sender, "Ownable: caller is not the new executor");
        _transferExecutorship(sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TransitStructs {

    enum SwapTypes {aggregatePreMode, aggregatePostMode, swap, cross}
    enum Flag {aggregate, swap, cross}

    struct TransitSwapDescription {
        uint8 swapType;
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        string channel;
        uint256 toChainID;
        address wrappedNative;
    }

    struct CallbytesDescription {
        uint8 flag;
        address srcToken;
        bytes calldatas;
    }

    struct AggregateDescription {
        address dstToken;
        address receiver;
        uint[] amounts;
        uint[] needTransfer;
        address[] callers;
        address[] approveProxy;
        bytes[] calls;
    }

    struct SwapDescription {
        address[][] paths;
        address[][] pairs;
        uint[] fees;
        address receiver;
        uint deadline;
    }

    struct CrossDescription {
        address caller;
        uint256 amount;
        bool needWrapped;
        bytes calls;
    }

    function decodeAggregateDesc(bytes calldata calldatas) internal pure returns (AggregateDescription memory desc) {
        desc = abi.decode(calldatas, (AggregateDescription));
    }

    function decodeSwapDesc(bytes calldata calldatas) internal pure returns (SwapDescription memory desc) {
        desc = abi.decode(calldatas, (SwapDescription));
    }

    function decodeCrossDesc(bytes calldata calldatas) internal pure returns (CrossDescription memory desc) {
        desc = abi.decode(calldatas, (CrossDescription));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library TransferHelper {
    
    address private constant _ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant _ZERO_ADDRESS = address(0);
    
    function isETH(address token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }
    
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_TOKEN_FAILED');
    }
    
    function safeTransferWithoutRequire(address token, address to, uint256 value) internal returns (bool) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        // solium-disable-next-line
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }

    function safeDeposit(address wrapped, uint value) internal {
        // bytes4(keccak256(bytes('deposit()')));
        (bool success, bytes memory data) = wrapped.call{value:value}(abi.encodeWithSelector(0xd0e30db0));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: DEPOSIT_FAILED');
    }

    function safeWithdraw(address wrapped, uint value) internal {
        // bytes4(keccak256(bytes('withdraw(uint256 wad)')));
        (bool success, bytes memory data) = wrapped.call{value:0}(abi.encodeWithSelector(0x2e1a7d4d, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: WITHDRAW_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library RevertReasonParser {
        function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
        // We assume that revert reason is abi-encoded as Error(string)

        // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
        if (data.length >= 68 && data[0] == "\x08" && data[1] == "\xc3" && data[2] == "\x79" && data[3] == "\xa0") {
            string memory reason;
            // solhint-disable no-inline-assembly
            assembly {
                // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
                reason := add(data, 68)
            }
            /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
            require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
            return string(abi.encodePacked(prefix, "Error(", reason, ")"));
        }
        // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
        else if (data.length == 36 && data[0] == "\x4e" && data[1] == "\x48" && data[2] == "\x7b" && data[3] == "\x71") {
            uint256 code;
            // solhint-disable no-inline-assembly
            assembly {
                // 36 = 32 bytes data length + 4-byte selector
                code := mload(add(data, 36))
            }
            return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
        }

        return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
    }
    
    function _toHex(uint256 value) private pure returns(string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes16 alphabet = 0x30313233343536373839616263646566;
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}