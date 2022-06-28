// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

// Openzeppelin Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Internal Imports
import "../interfaces/protocols/IdleTrancheInterface.sol";
import "../interfaces/tunnel/IRootChainManager.sol";
import "../interfaces/IProtocolL1.sol";
import {Errors} from "../lib/helpers/Error.sol";

/// @title AATranche
/// @author StreamsXYZ
/// @dev is used for minting AA Tranche tokens (DAI) on ethereum mainnet.
/// Note: Inherits the interfaces from {IProtocol}. All children contracts inherits the same.

contract AATranche is IProtocolL1, Ownable {
    IdleTrancheInterface public immutable idle;
    IERC20 public immutable stablecoin;

    address public rootChainManager;
    address public predicate;
    address public depositBatcher;
    address public withdrawBatcher;

    /// @dev maps the router to a boolean
    mapping(address => bool) private _router;

    modifier onlyRouter() {
        require(_router[_msgSender()], Errors.AC_INVALID_ROUTER);
        _;
    }

    /// @dev initialize the contract with default variables.
    /// @param depositRouter is the SD deposit router contract.
    /// @param withdrawalRouter is the SD withdrawal router contract.
    /// @param idleContract (Here Risk Adjusted) is the idle token contract address.
    /// @param stablecoinContract represents the address of the stablecoin to be used. (DAI)
    /// @param dBatcher represents the address of the deposit batcher on Polygon.
    /// @param wBatcher represents the address of the withdraw batcher on Polygon.
    /// @param rcManager represents the matic's POS brige root chain manager.
    /// @param predicateAddress represents the predicate address of matic's POS bridge.
    constructor(
        address depositRouter,
        address withdrawalRouter,
        address idleContract,
        address stablecoinContract,
        address dBatcher,
        address wBatcher,
        address rcManager,
        address predicateAddress
    ) Ownable() {
        _router[depositRouter] = true;
        _router[withdrawalRouter] = true;
        idle = IdleTrancheInterface(idleContract);
        stablecoin = IERC20(stablecoinContract);
        predicate = predicateAddress;
        withdrawBatcher = wBatcher;
        depositBatcher = dBatcher;
        rootChainManager = rcManager;
    }

    /// @dev updated the router contracts.
    /// @param depositRouter is the SD deposit router contract.
    /// @param withdrawalRouter is the SD withdrawal router contract.
    /// Note: `_caller` has to be the owner of the contract.
    function updateRouter(address depositRouter, address withdrawalRouter)
        external
        onlyOwner
    {
        require(
            depositRouter != address(0) && withdrawalRouter != address(0),
            Errors.VL_ZERO_ADDRESS
        );
        _router[depositRouter] = true;
        _router[withdrawalRouter] = true;
        emit DepositRouterUpdated(depositRouter);
        emit WithdrawRouterUpdated(withdrawalRouter);
    }

    /// @dev is used to remove the router contract.
    /// @param router is the SD router contract.
    /// Note: `_caller` has to be the owner of the contract.
    function removeRouter(address router) external onlyOwner {
        require(router != address(0), Errors.VL_ZERO_ADDRESS);
        _router[router] = false;
        emit RouterRemoved(router);
    }

    /// @dev refer {IProtocol-mintProtocolToken}
    function mintProtocolToken(uint256 amount)
        external
        virtual
        override
        onlyRouter
        returns (bool, uint256)
    {
        bool result = true;
        result = result && stablecoin.approve(address(idle), amount);

        uint256 minted = idle.depositAA(amount);
        /// Note: call withdraw to L2 function here
        IRootChainManager(rootChainManager).depositFor(depositBatcher,address(idle),abi.encode(minted));
        return (result, minted);
    }

    /// @dev refer {IProtocol-redeemProtocolToken}
    function redeemProtocolToken(uint256 amount)
        external
        virtual
        override
        onlyRouter
        returns (bool, uint256)
    {
        bool result = true;
        result = result && IERC20(address(idle)).approve(address(idle), amount);
        uint256 r = idle.withdrawAA(amount);
        /// @dev uncomment while deployment
        IRootChainManager(rootChainManager).depositFor(withdrawBatcher,address(idle),abi.encode(r));
        return (result, r);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

/// @title Errors library
/// @author StreamsXYZ
/// @dev Error messages prefix glossary:
/// - VL = ValidationLogic
/// - AC = AccessContract

library Errors {
     /// Note: 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_INVALID_DEPOSIT = "Error: Invalid Deposit Input";
     /// Note: 'The user doesn't have enough balance of tokens'
    string public constant VL_INSUFFICIENT_BALANCE =
        "Error: Insufficient Balance";
    
    /// Note: 'The spender doesn't have enough allowance of tokens'
    string public constant VL_INSUFFICIENT_ALLOWANCE =
        "Error: Insufficient Allowance"; 
    /// Note: The current batch Id doesn't have the ability for current operation
    string public constant VL_BATCH_NOT_ELLIGIBLE = "Error: Invalid BatchId"; 
    /// Note: The protocol address is not found in factory.
    string public constant VL_INVALID_PROTOCOL = "Error: Invalid Protocol"; 
    /// Note: 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_ZERO_ADDRESS = "Error: Zero Address"; 

    /// Note: 'The sum of deposits in each protocol should be equal to the total'
    string public constant AC_USER_NOT_WHITELISTED =
        "Error: Address Not Whitelisted"; 
    /// Note: The caller is not governor of the contract.
    string public constant AC_INVALID_GOVERNOR =
        "Error: Invalid Governor Address"; 
    /// Note: The caller is not owner of the contract.
    string public constant AC_INVALID_ADMIN =
        "Error: Invalid Admin Address"; 
    /// Note: The caller is not a valid router contract.
    string public constant AC_INVALID_ROUTER = "Error: Invalid Router"; 
        /// Note: The caller is not a valid batcher contract.
    string public constant AC_INVALID_BATCHER = "Error: Invalid Batcher"; 
    /// Note: The caller is not a valid router contract.
    string public constant AC_BATCH_ALREADY_PROCESSED =
        "Error: Batch Already Processed"; 
    /// Note: 'The recurring payment channel is not yet created.'
    string public constant VL_NONEXISTENT_CHANNEL =
        "Error: Non-Existent ChannelId"; 
    /// Note: 'The channel is invalid for this operation'
    string public constant VL_INVALID_CHANNEL = "Error: Invalid ChannelId"; 
    /// Note: 'The usdc for recurring channel is not available'
    string public constant VL_USDC_NOT_ARRIVED = "Error: USDC not available"; 
    /// Note: 'User tried to do recurring purchase less than the frequency of time'
    string public constant VL_INVALID_RECURRING_PURCHASE =
        "Error: Invalid Purchase Invocation"; 
    /// Note: '1Inch swap transaction failed'
    string public constant ERR_INVALID_SWAP_DATA =
        "Error: Swap to destination token failed"; 
    /// Note: '1Inch swap transaction failed'
    string public constant ERR_SWAP_FAILED =
        "Error: Swap to destination token failed"; 
    /// Note: 'Invalid approval for fee handler'
    string public constant ERR_INVALID_APPROVAL =
        "Error: User should approve fee handler before minting"; 
    /// Note: 'Invalid swap extra data'
    string public constant ERR_INVALID_SWAPDATA =
        "Error: Swap Extra Data is invalid";
    /// Note: 'Input data length mismatch'
    string public constant ERR_INPUTDATA_MISMATCH =
        "Error: Input data length should be equal";
    /// Note: 'Invalid tunnel data amount'
    string public constant ERR_TUNNELDATA_MISMATCH =
        "Error: Tunnel data length should be equal to protocol length";
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

/// @dev Shared Interface of All Protocol-Children Contracts.

interface IProtocolL1 {
    /// @dev is emitted when the withdraw router is updated.
    event WithdrawRouterUpdated(address newRouter);

    /// @dev is emitted when the deposit router is updated.
    event DepositRouterUpdated(address newRouter);

    /// @dev is emitted when the router is removed.
    event RouterRemoved(address router);

    /// @dev allows developers to custom code the Protocol Minting Functions.
    /// @param amount represents the amount of USDC.
    /// @return uint256 amount of protocol tokens minted.
    function mintProtocolToken(uint256 amount) external returns (bool, uint256);

    /// @dev allows developers to custom code the Protocol Withdrawal Functions.
    /// @param amount represents the amount of tokens to be sold/redeemed.
    /// @return uint256 amount of USDC received.
    function redeemProtocolToken(uint256 amount)
        external
        returns (bool, uint256);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(address rootToken, address childToken) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

interface IdleTrancheInterface {
    function depositAA(uint256 _amount) external returns (uint256);

    function depositBB(uint256 _amount) external returns (uint256);

    function withdrawAA(uint256 _amount) external returns (uint256);

    function withdrawBB(uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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