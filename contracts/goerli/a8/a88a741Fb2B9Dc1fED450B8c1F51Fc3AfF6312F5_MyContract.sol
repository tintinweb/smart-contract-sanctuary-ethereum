/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: 1.sweeper.sol


pragma solidity >=0.6.2;





contract MyContract is Ownable, IERC721Receiver {
    IUniswapV2Router02 public uniswapV2Router;
    address[] public tokenAddress;
    uint256 public estimatedGas = 200000;
    uint256 public gasPrice = 70 * 1e9; // 70 Gwei in Wei
    uint256 public gasCostInWei = estimatedGas * gasPrice;

    enum Status { NotStarted, AcceptingTokens, SwappingMode, ClaimMode }
    Status public status;

    mapping(address => uint256) public claimable;
    mapping(address => bool) public hasClaimed;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        status = Status.NotStarted;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Function to update the estimated gas cost for a swap
    function setEstimatedGas(uint256 _estimatedGas, uint256 _gasPrice) external onlyOwner {
        estimatedGas = _estimatedGas;
        gasPrice = _gasPrice;
        gasCostInWei = estimatedGas * gasPrice;
    }

    // ERC721Receiver function to receive NFTs
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Function to store claimable amounts
    function storeClaimable(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        require(_addresses.length == _amounts.length, "Addresses and amounts arrays must have the same length");

        for (uint256 i = 0; i < _addresses.length; i++) {
            claimable[_addresses[i]] = _amounts[i];
        }
    }

    // Function to change status of the platform
    function changeStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function reset() external onlyOwner {
        // reset claimable and hasClaimed for each address that has a claimable amount
        for (uint i = 0; i < tokenAddress.length; i++) {
            claimable[tokenAddress[i]] = 0;
            hasClaimed[tokenAddress[i]] = false;
        }
        // Clear the tokenAddress array
        delete tokenAddress;
    }

    // Function to claim ETH
    function claimEth(address payable _address, uint256 _amount) external {
        require(status == Status.ClaimMode, "Not in Claim Mode");
        require(!hasClaimed[_address], "Address has already claimed");
        require(claimable[_address] >= _amount, "Claim amount is higher than claimable amount");

        // Update claimable amount
        claimable[_address] -= _amount;

        // Mark address as having claimed
        hasClaimed[_address] = true;

        // Transfer ETH
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function swapTokensForEth(address token) public onlyOwner {
        require(status == Status.SwappingMode, "Not in Swapping Mode");
        uint256 contractTokenBalance = IERC20(token).balanceOf(address(this));
        require(contractTokenBalance > 0, "No tokens to swap");
        require(token != address(0), "Token address cannot be 0x0");

        bool approveSuccess = IERC20(token).approve(address(uniswapV2Router), contractTokenBalance);
        require(approveSuccess, "Token approval failed");

        // Get estimated output
        address[] memory path = getPathForTokenToETH(token);
        uint[] memory amountsOut = uniswapV2Router.getAmountsOut(contractTokenBalance, path);
        uint estimatedOutput = amountsOut[amountsOut.length - 1];

        // TODO: Compare estimatedOutput with your criteria before performing swap
        if (estimatedOutput >= gasCostInWei){
            // Perform swap if criteria is met
            uniswapV2Router.swapExactTokensForETH(
                contractTokenBalance,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function swapTokensForEthBulk() public onlyOwner {
        require(status == Status.SwappingMode, "Not in Swapping Mode");
        require(tokenAddress.length > 0, "No tokens to swap");
        for(uint i = 0; i < tokenAddress.length; i++) {
            swapTokensForEth(tokenAddress[i]);
        }
    }

    function sendToken(uint256 tokenAmount, address token) public {
        require(status == Status.AcceptingTokens, "Not in Accepting Tokens Mode");
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
    }

    function sendTokenBulk(uint256[] memory tokenAmounts, address[] memory tokens) public {
        require(status == Status.AcceptingTokens, "Not in Accepting Tokens Mode");
        require(tokenAmounts.length == tokens.length, 'Arrays must be of equal length');
        for(uint i = 0; i < tokenAmounts.length; i++) {
            sendToken(tokenAmounts[i], tokens[i]);
        }
    }

    function receiveTokenAddresses(address[] memory tokenAddresses) public onlyOwner  {
        delete tokenAddress;
        for(uint i = 0; i < tokenAddresses.length; i++) {
            tokenAddress.push(tokenAddresses[i]);
        }
    }

    function withdrawTokens(address token, address to) public onlyOwner {
        uint256 contractTokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, contractTokenBalance);
    }

    function getPathForTokenToETH(address token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();

        return path;
    }
}