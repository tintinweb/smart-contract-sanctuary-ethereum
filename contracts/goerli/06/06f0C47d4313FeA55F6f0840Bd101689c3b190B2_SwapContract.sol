/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: SwapContract.sol



/*

Hello sir happy holidays, this is the swap contract, I'm aware you have experience deploying contracts but still wanted
to leave some instructions and notes in case you need some help, first I'll describe the steps to take to deploy, then the 
things to do to after deploying and some final notes.

I added comments to every function to make it easier to know what each one does and also to some important variables, you can delete all the comments when you deploy.

STEPS TO TAKE: 

DEPLOYING: 
- Go to remix.ethereum.org/
- Create a new file and call it "SwapContract.sol" or something like that and paste this code.
- Compile with version 0.8.0.
- Deploy the contract called "SwapContract", the deploy button will be red, this means that you can send eth to the contract in the same
transaction, ignore that, you can later send eth to it after deployment.

VERIFYING:
This contract imports from openzeppelin, the official ethereum recommended standard library for basic smart contract security, so the way
you need to verify is a bit different.

- Go to https://etherscan.io/verifyContract
- Paste the newly deployed smart contract address.
- Compiler type is Single File
- Compiler version is 0.8.0 
- Open Source License Type is MIT.
- Click continue.
- Now go back to remix ethereum and click the Plugin Manager button on top of the settings button at the button left of the screen.
- There search for a plugin called "FLATTENER" and activate it.
- Then you'll see a symbol which looks like a scroll under the bugs icon, click it and click "Flatten (name of the contract).sol", that will copy
a *flattened* version of the contract to your clipboard. 
- Go to the verify contract page and paste the flattened contract where it asks for the source code. 
- Click verify.

WHAT TO DO AFTER VERIFICATION: 

- Dm me the contract address so I set up the dapp with it.

With that the contract should be good to go, I recommend reading the whole contract commentary so you know what each function does and
when you could use it.

If you have any doubts you can just dm.

*/


pragma solidity ^0.8.0;



interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

contract SwapContract is ReentrancyGuard {

    //Basic Variables
    address public owner;
    address public UniSwapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // Make sure this is the correct feeAddress, I added a function to change it below too.
    address public feeAddress = 0x58A1817a36787d20FC5Ef11E3e9e68684BfC9127;
    // Make sure this is the correct wrapped ether address.
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Change To Mainnet.
    uint public feePercent = 4;

    IUniswapV2Router02 router = IUniswapV2Router02(UniSwapRouter);

    //Modifiers
    modifier onlyOwner {
     require (owner == msg.sender, "Only owner may call this function");
     _;
    }

    constructor() payable {
        owner = msg.sender;
    }

    // Helper Functions
    receive () external payable {

    }

    // Function that converts eth to tokens.
    function ethToToken (address tokenFrom, address tokenOut, uint slippage, address receiver) external payable nonReentrant {
        address[] memory path;
        path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenOut;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: (msg.value - (msg.value / 100 * feePercent ))}(slippage, path, receiver, 1955751025);

        (bool os,) = payable(feeAddress).call{value:address(this).balance}("");
        require(os);
    }

    // Function that converts tokens to eth.
    function tokenToEth (address tokenFrom, address tokenOut, uint amountToSell, uint slippage, address receiver) external nonReentrant {
        address[] memory path;
        path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenOut;

        IERC20(tokenFrom).transferFrom(msg.sender, address(this), amountToSell);

        uint balance = IERC20(tokenFrom).balanceOf(address(this));
        uint feeAmount = (IERC20(tokenFrom).balanceOf(address(this)) / 100 * feePercent);

        uint amountToApe = balance - feeAmount;

        IERC20(tokenFrom).approve(UniSwapRouter, amountToApe * 50);

        // Do The Swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToApe, slippage, path, receiver, 1955751025);

        // Convert Fee To ETH
        address[] memory feePath;
        feePath = new address[](2);
        feePath[0] = tokenFrom;
        feePath[1] = weth;

        uint balance2 = IERC20(tokenFrom).balanceOf(address(this));

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance2, slippage, feePath, feeAddress, 1955751025);
    }

    // Function that converts tokens to tokens.
    function tokenToToken (address tokenFrom, address tokenOut, uint amountToSell, uint slippage, address receiver) external nonReentrant {
        address[] memory path;
        path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenOut;

        IERC20(tokenFrom).transferFrom(msg.sender, address(this), amountToSell);

        uint balance = IERC20(tokenFrom).balanceOf(address(this));
        uint feeAmount = (IERC20(tokenFrom).balanceOf(address(this)) / 100 * feePercent);

        uint amountToApe = balance - feeAmount;

        IERC20(tokenFrom).approve(UniSwapRouter, amountToApe * 50);

        // Do The Swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountToApe, slippage, path, receiver, 1955751025);

        // Convert Fee To ETH
        address[] memory feePath;
        feePath = new address[](2);
        feePath[0] = tokenFrom;
        feePath[1] = weth;

        uint balance2 = IERC20(tokenFrom).balanceOf(address(this));

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance2, slippage, feePath, feeAddress, 1955751025);
    }

    // This function will transfer all the eth from the contract to the fee address.
    function withdrawEth() external onlyOwner {
          (bool os,) = payable(feeAddress).call{value:address(this).balance}("");
          require(os);
    }

    // This function will change the contract owner.
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // This function will change the fee address.
    function changeFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    // This function will change the fee percentage.
    function changeFeePercent(uint newFeePercent) external onlyOwner {
        feePercent = newFeePercent;
    }

}