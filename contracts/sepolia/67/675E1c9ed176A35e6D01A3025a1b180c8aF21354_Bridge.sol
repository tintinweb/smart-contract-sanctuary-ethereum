// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBridge.sol";

contract Bridge is IBridge, Ownable {
    error InsufficientBalance();
    error InvalidTokenAddress();

    uint256 private reserveA; // reserve of tokenA
    uint256 private reserveB; // reserve of tokenB

    address public tokenA_addr;
    address public tokenB_addr;

    constructor(address _tokenA, address _tokenB) {
        tokenA_addr = _tokenA;
        tokenB_addr = _tokenB;
    }

    /**
     * @dev stake token into contract
     * @param tokenIn the address of ERC20 token to stake
     * @param amount the amount of ERC20 token to stake
     * @return success the result of tx
     */
    function stake(
        address tokenIn,
        uint256 amount
    ) external override returns (bool success) {
        if(tokenIn != tokenA_addr && tokenIn != tokenB_addr) {
            revert InvalidTokenAddress();
        }
        uint256 outputAmount = getAmountOut(amount, tokenIn);
        address tokenOut;
        if (tokenIn == tokenA_addr) {
            IERC20(tokenA_addr).transferFrom(_msgSender(), address(this), amount);
            reserveA += amount;
            reserveB -= outputAmount;
            tokenOut = tokenB_addr;
        } else {
            IERC20(tokenB_addr).transferFrom(_msgSender(), address(this), amount);
            reserveB += amount;
            reserveA -= outputAmount;
            tokenOut = tokenA_addr;
        }
        success = true;

        emit Stake(_msgSender(), tokenOut, outputAmount);
    }

    /**
     * @dev transfer token from contract to account address
     * @param token_addr the address of ERC20 token
     * @param outputAmount the amount of ERC20 to transfer
     * @return success the result of tx
     */
    function mint(
        address account,
        address token_addr,
        uint256 outputAmount
    ) external override onlyOwner returns (bool success) {
        if(token_addr != tokenA_addr && token_addr != tokenB_addr) {
            revert InvalidTokenAddress();
        }

        IERC20(token_addr).transfer(account, outputAmount);

        address tokenIn;
        uint256 amountIn = getAmountIn(outputAmount, token_addr);
        if (token_addr == tokenA_addr) {
            reserveA -= outputAmount;
            reserveB += amountIn;
            tokenIn = tokenB_addr;
        } else {
            reserveB -= outputAmount;
            reserveA += amountIn;
            tokenIn = tokenA_addr;
        }

        success = true;

        emit Mint(account, tokenIn, amountIn);
    }

    /**
     * @dev show the contract balance of the specified token
     * @param token_addr the address of ERC20 token
     * @return balance the balance of token_addr
     */
    function balanceOfToken(
        address token_addr
    ) public view override returns (uint256 balance) {
        return IERC20(token_addr).balanceOf(address(this));
    }

    /**
     * @dev get AmountOut by inputAmount
     * @param inputAmount the amount of input token
     * @param inputToken the address of input token
     * @return outputAmount the amount user will get
     */
    function getAmountOut(
        uint256 inputAmount,
        address inputToken
    ) public view override returns (uint256 outputAmount) {
        if (inputToken == tokenA_addr) {
            outputAmount = (inputAmount * reserveB) / (reserveA + inputAmount);
        } else if (inputToken == tokenB_addr) {
            outputAmount = (inputAmount * reserveA) / (reserveB + inputAmount);
        } else {
            revert InvalidTokenAddress();
        }

        if(outputAmount == 0) revert InsufficientBalance();
    }

    /**
     * @dev get inputAmount by outputAmount
     * @param outputAmount the amount of output token
     * @param outputToken the address of output token
     * @return inputAmount the amount user should input
     */
    function getAmountIn(
        uint256 outputAmount,
        address outputToken
    ) public view override returns (uint256 inputAmount) {
        if(outputToken != tokenA_addr && outputToken != tokenB_addr) {
            revert InvalidTokenAddress();
        }
        (uint256 _reserveA, uint256 _reserveB) = getReserve();
        if (outputToken == tokenA_addr) {
            inputAmount = (_reserveB * outputAmount) / (_reserveA - outputAmount);
        } else {
            inputAmount = (_reserveA * outputAmount) / (_reserveB - outputAmount);
        }

        if(inputAmount == 0) revert InsufficientBalance();
    }

    /**
     * @dev get reserve of tokenA and tokenB
     * @return _reserveA the reserve of tokenA
     * @return _reserveB the reserve of tokenB
     */
    function getReserve() public view override returns (uint256 _reserveA, uint256 _reserveB) {
        (_reserveA, _reserveB) = (reserveA, reserveB);
    }

    /**
     * @dev add liquidity
     * @param amountA the amount of tokenA
     * @param amountB the amount of tokenB
     * @return success the result of tx
     */
    function addReserve(uint256 amountA, uint256 amountB) public override returns (bool success) {
        IERC20(tokenA_addr).transferFrom(_msgSender(), address(this), amountA);
        IERC20(tokenB_addr).transferFrom(_msgSender(), address(this), amountB);
        success = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
pragma solidity ^0.8.16;

interface IBridge {
    // =============================== Event ===============================
    event Stake(address indexed account, address tokenOut, uint256 amount);
    event Mint(address indexed account, address tokenIn, uint256 amount);

    // =============================== Read Functions ===============================
    function balanceOfToken(address token_addr) view external returns (uint256 balance);
    function getReserve() external view returns (uint256 _reserveA, uint256 _reserveB);

    function getAmountIn(uint256 outputAmount, address outputToken) external view returns (uint256 inputAmount);
    function getAmountOut(uint256 inputAmount, address inputToken) external view returns (uint256 outputAmount);

    // =============================== Write Functions ===============================
    function stake(address token_addr, uint256 _amount) external returns (bool success);
    function mint(address account, address token_addr, uint256 amount) external returns (bool success);
    function addReserve(uint256 amountA, uint256 amountB) external returns (bool success);
}