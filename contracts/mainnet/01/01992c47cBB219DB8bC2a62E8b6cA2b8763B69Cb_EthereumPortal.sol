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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../external/IRootChainManager.sol";
import "../external/IFxStateSender.sol";

/// @title Constants for use on the Ethereum network
contract EthereumConstants {
    /// @dev see https://static.matic.network/network/mainnet/v1/index.json
    /// @return polygon ERC20 predicate for transferring ERC20 tokens to polygon
    address public constant ERC20_PREDICATE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    /// @dev see https://static.matic.network/network/mainnet/v1
    /// @return WETH token on polygon
    address public constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    /// @dev see https://static.matic.network/network/mainnet/v1
    /// @return fxRoot contract which can send arbitrary state messages
    IFxStateSender public constant FX_ROOT =
        IFxStateSender(0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2);

    /// @dev see https://static.matic.network/network/mainnet/v1
    /// @return polygon main pos-bridge contract
    IRootChainManager public constant CHAIN_MANAGER =
        IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EthereumConstants.sol";
import "./IEthereumPortal.sol";

/// @title Main entry point on ethereum network. Sends messages to its counterpart on polygon
/// @dev the main mechanism is polygon's state sync, see https://docs.polygon.technology/docs/contribute/state-sync/state-sync
contract EthereumPortal is EthereumConstants, IEthereumPortal, Ownable {
    address public polygonContract;

    constructor() Ownable() {}

    /** @param _polygonContract address of the polygon contract */
    function initialize(address _polygonContract) external onlyOwner {
        polygonContract = _polygonContract;
    }

    /**
     *  @param tokenIn The ERC20 token to deposit
     *  @param amountIn The amount of tokens to deposit
     *  @param routerAddress The address of the router contract on L2
     *  @param routerArguments Calldata to execute the desired swap on L2
     *  @param calls Calldata to purchase NFT on L2
     *  @dev The L1 function to execute a cross chain purchase with an ERC20 on L2
     */
    function depositERC20(
        IERC20 tokenIn,
        uint256 amountIn,
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external {
        require(
            CHAIN_MANAGER.rootToChildToken(address(tokenIn)) != address(0x0),
            "EthereumPortal: TOKEN MUST BE MAPPED"
        );

        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenIn.approve(ERC20_PREDICATE, amountIn);

        CHAIN_MANAGER.depositFor(polygonContract, address(tokenIn), abi.encode(amountIn));

        FX_ROOT.sendMessageToChild(
            polygonContract,
            abi.encode(
                CHAIN_MANAGER.rootToChildToken(address(tokenIn)),
                amountIn,
                msg.sender,
                routerAddress,
                routerArguments,
                calls
            )
        );
    }

    /**
     *  @param routerAddress The address of the router contract on L2
     *  @param routerArguments Calldata to execute the desired swap on L2
     *  @param calls Calldata to purchase NFT on L2
     *  @dev The L1 function to execute a cross chain purchase with ETH on L2
     */
    function depositEther(
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external payable {
        CHAIN_MANAGER.depositEtherFor{value: msg.value}(polygonContract);

        FX_ROOT.sendMessageToChild(
            polygonContract,
            abi.encode(WETH, msg.value, msg.sender, routerAddress, routerArguments, calls)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Main contract which serves as the entry point on Ethereum
interface IEthereumPortal {
    function initialize(address _polygonContract) external;

    function depositERC20(
        IERC20 tokenIn,
        uint256 amountIn,
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external;

    function depositEther(
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev see https://github.com/fx-portal/contracts/blob/main/contracts/tunnel/FxBaseRootTunnel.sol
interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @dev see https://github.com/maticnetwork/pos-portal/blob/v1.1.0/contracts/root/RootChainManager/RootChainManager.sol
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function rootToChildToken(address rootToken) external returns (address);
}