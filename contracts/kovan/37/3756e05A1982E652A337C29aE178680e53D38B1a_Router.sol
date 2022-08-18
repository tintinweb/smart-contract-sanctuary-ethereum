// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFactory.sol";
import "./interfaces/IPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Router__PairDoesNotExist();
error Router__NoLiquidity();
error Router__MinAmountTooLow();
error Router__LiquidityTooLow();
error Router__FactoryAlreadyInitialized();

contract Router is Ownable{

    event Swap(address indexed firstToken, address indexed secondToken, uint256 firstSold, uint256 secondBought);

    address public s_factory;

    function initializeFactoryAddress(address factory) public onlyOwner{
        s_factory = factory;
        renounceOwnership();
    }

    function addLiquidity(address firstToken, address secondToken, uint256 firstAmount, uint256 secondAmount) external {
        address pairAddress = IFactory(s_factory).getPairAddress(firstToken, secondToken);
        if (pairAddress == address(0)) {
            pairAddress = IFactory(s_factory).createPair(firstToken, secondToken);
        }

        uint256 firstAmountIn;
        uint256 secondAmountIn;
        (address firstTokenInPair, ) = IPair(pairAddress).getTokens();
        if (firstToken == firstTokenInPair) {
             (firstAmountIn, secondAmountIn) = IPair(pairAddress).getTokenAmounts();
        } else {
             (secondAmountIn, firstAmountIn) = IPair(pairAddress).getTokenAmounts();
        }

        uint256 firstAmountToTransfer;
        uint256 secondAmountToTransfer;
        if (firstAmountIn == 0 && secondAmountIn == 0) {
            firstAmountToTransfer = firstAmount;
            secondAmountToTransfer = secondAmount;
        } else {
            uint256 optimalSecondAmount = firstAmount*secondAmountIn/firstAmountIn;
            if (optimalSecondAmount > secondAmount) {
                uint256 optimalFirstAmount = secondAmount*secondAmountIn/firstAmountIn;
                firstAmountToTransfer = optimalFirstAmount;
                secondAmountToTransfer = secondAmount;
            } else {
                firstAmountToTransfer = firstAmount;
                secondAmountToTransfer = optimalSecondAmount;
            }
        }

        IERC20(firstToken).transferFrom(msg.sender, pairAddress, firstAmountToTransfer);
        IERC20(secondToken).transferFrom(msg.sender, pairAddress, secondAmountToTransfer);

        IPair(pairAddress).mintLiquidityTokens(msg.sender, firstAmountIn, secondAmountIn);
    }

    function removeLiquidity (address firstToken, address secondToken, uint256 amount) external {
        address pairAddress = IFactory(s_factory).getPairAddress(firstToken, secondToken);
        if (pairAddress == address(0)) {
            revert Router__PairDoesNotExist();
        }

        IERC20(pairAddress).transferFrom(msg.sender, pairAddress, amount);
        IPair(pairAddress).removeLiquidity(msg.sender, amount);
    }

    function getQuote(address tokenToSell, address tokenToBuy, uint256 tokenToSellAmount) public view returns(uint256) {
        address pairAddress = IFactory(s_factory).getPairAddress(tokenToSell, tokenToBuy);
        if (pairAddress == address(0)) {
            revert Router__PairDoesNotExist();
        }

        (address firstToken, ) = IPair(pairAddress).getTokens();
        uint256 sellTokenAmount;
        uint256 buyTokenAmount;
        if (firstToken == tokenToSell) {
            (sellTokenAmount, buyTokenAmount) = IPair(pairAddress).getTokenAmounts();
        } else {
            (buyTokenAmount, sellTokenAmount) = IPair(pairAddress).getTokenAmounts();
        }

        if (sellTokenAmount == 0 || buyTokenAmount == 0) {
            revert Router__NoLiquidity();
        }

        uint256 quote = tokenToSellAmount*buyTokenAmount/sellTokenAmount;
        if (quote > buyTokenAmount) {
            revert Router__LiquidityTooLow();
        }

        return quote;
    }

    function swapTokens(address tokenToSell, address tokenToBuy, uint256 amountToSell, uint256 minAmountToBuy) external {
        uint256 quote = getQuote(tokenToSell, tokenToBuy, amountToSell);
        if (quote < minAmountToBuy) {
            revert Router__MinAmountTooLow();
        }

        address pairAddress = IFactory(s_factory).getPairAddress(tokenToSell, tokenToBuy);

        IERC20(tokenToSell).transferFrom(msg.sender, pairAddress, amountToSell);
        IPair(pairAddress).transferTo(msg.sender, tokenToBuy, quote);

        emit Swap(tokenToSell, tokenToBuy, amountToSell, quote);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFactory {
    event PairCreated(address indexed firstToken, address indexed secondToken, address pairAddress);

    function createPair(address firstToken, address secondToken) external returns (address pairAddress);

    function getPairAddress(address firstToken, address secondToken) external view returns (address pairAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPair is IERC20 {
    function initializePair(address firstToken, address secondToken) external returns (address pairAddress);

    function getTokenAmounts() external view returns (uint256 firstTokenAmount, uint256 secondTokenAmount);

    function getTokens() external view returns (address firstToken, address secondToken);

    function transferTo(address to, address token, uint256 amount) external;
    
    function mintLiquidityTokens(address to, uint256 firstAmountBefore, uint256 secondAmountBefore) external;

    function removeLiquidity(address to, uint256 liquidityTokenAmount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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