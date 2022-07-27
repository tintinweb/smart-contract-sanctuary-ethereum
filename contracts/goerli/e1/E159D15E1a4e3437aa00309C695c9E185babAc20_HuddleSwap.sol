// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "HuddleCore.sol";
import "HuddleCalculation.sol";


contract HuddleSwap is HuddleCore, HuddleCalculation {


    constructor(address payable feeWallet, address WETH, address _uniswapRouter) HuddleCore(feeWallet, WETH, _uniswapRouter) {}


    /*
      Huddle Swap that returns the value in ETH, used for transaction Token -> Eth
        Input 
            _path - Array of addresses with the input and output token for the swap (address[2])
            _amountIn - Array of Amounts to Swap (address[])
            _amountOutMin - Total Minimum Amount allowed to permit the Swap (uint256)
            _from - Array of wallets that are executing the swap (address[])
        
        NOTE:
        THE ETH COIN CANNOT BE USED AS A INPUT PARAMETER
        WETH NEEDS TO BE THE OUTPUT TOKEN
    */
    function swapTokensToETH(address[2] calldata _path, Order[] calldata _orders, uint256 _amountOutMin, address[] calldata _from, bool _isSafeToken) public onlyOwner {

        //Initialize the variables needed for the transfer of the tokens from the users
        uint256 _totalFee;
        uint256 _totalAmount;
        address [] memory _fromUpdated = new address[](_from.length);

        //Obtains the tokens and applies the fees at the same time
        (_totalFee, _totalAmount, _fromUpdated) = importTokenAndFees(_orders, _from, _path[0]);


        //Calculate the necessary percentages of the inputted amount
        uint256[] memory _percentageAmount = getPercentageArray(_orders, _fromUpdated.length, _totalAmount, _path[0]);

        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        approval(_path[0], _totalAmount, address(uniswapRouter));

        setSwapETHTransfer(_totalAmount, _amountOutMin, _path, _percentageAmount, _from);

        feePayment(_path[0], _totalFee, _isSafeToken);

    }


    /*
      Huddle Swap for ERC20 token Tokens <-> Tokens
        Input 
          _path - Array of addresses with the input and output token for the swap (address[2])
          _amountIn - Array of Amounts to Swap (address[])
          _amountOutMin - Total Minimum Amount allowed to permit the Swap (uint256)
          _from - Array of wallets that are executing the swap (address[])
      
        NOTE:
        THE ETH COIN CANNOT BE USED AS A INPUT PARAMETER
    */
    function swapTokensToTokens(address[2] calldata _path, Order[] calldata _orders, uint256 _amountOutMin, address[] calldata _from, bool _isSafeToken) public onlyOwner {

        //Initialize the variables needed for the transfer of the tokens from the users
        uint256 _totalFee;
        uint256 _totalAmount;
        address [] memory _fromUpdated = new address[](_from.length);

        //Obtains the tokens and applies the fees at the same time
        (_totalFee, _totalAmount, _fromUpdated) = importTokenAndFees(_orders, _from, _path[0]);

        //Calculate each user's percentage of the total input amount
        uint256[] memory _percentageAmount = getPercentageArray(_orders, _fromUpdated.length, _totalAmount, _path[0]);

        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        approval(_path[0], _totalAmount, address(uniswapRouter));


        setSwapTransfer(_totalAmount, _amountOutMin, _path, _percentageAmount, _from);

        feePayment(_path[0], _totalFee, _isSafeToken);
    }


    /*
      Transfers the Tokens from the Users Wallets and returns the total value to Swap as well as the Fees
        Input
            _from - Array of wallets that are executing the swap (address[])
            _tokenIn - Total Minimmum Amount allowed to permit the Swap (uint256)
            _amountIn - Array of Amounts to Swap (address[])
        Outputs
            [_totalFee,_totalAmount] - Array of the following values :
                                        The total amount of fees
                                        The total amount that will swap after the extraction of the fees (uint256[]).
            _fromUpdated - Array of the wallets from where the tokens where sucessfully transfered
    */
    function importTokenAndFees(Order[] calldata _orders, address[] calldata _from, address _tokenIn) private returns (uint256, uint256, address[] memory) {
        uint256 _totalAmount;
        uint256 _totalFee;
        address [] memory _fromUpdated = new address[](_from.length);

        for (uint16 i = 0; i < _from.length; i++) {
            if (orderBasedTransfer(_orders[i], _from[i], _tokenIn)) {
                _totalFee += sumOfGasAndFee(_orders[i]);
                _totalAmount += _orders[i].amount;
                _fromUpdated[i] = _from[i];
            }
        }
        require(_totalAmount != 0, "HuddleSwap revert: No amount was transferred into the HuddleSwap contract.");
        return (_totalFee, _totalAmount, _fromUpdated);
    }


    /*
      Calculates the percentage of each user over the whole order
      Input
          _from - Array of wallets that are executing the swap (address[])
          _tokenIn - Total Minimmum Amount allowed to permit the Swap (uint256)
          _amountIn - Array of Amounts to Swap (address[])
    */
    function getPercentageArray(Order[] calldata _orders, uint256 _fromLength ,uint256 _totalAmount, address _tokenIn) private view returns (uint256 [] memory){
        uint8 _decimals = IERC20Metadata(_tokenIn).decimals();

        uint256[] memory _percentageAmount = new uint[](_orders.length);
        for (uint16 m = 0; m < _orders.length; m++) {
            _percentageAmount[m] = getPercentage(_orders[m].amount, _totalAmount, _decimals);
        }
        return _percentageAmount;
    }


    /*
      Calculates the value that is equivalent with the initial amount sent for the transaction
        Example:
          User A - 0.02 WETH -> Total Amount 0.03 -> Percentage A 66%   -> Swap for 3 TOKENS -> User A 2 Token
          User B - 0.01 WETH ->                      Percentage B 33%                           User B 1 Token

        Input
          _amount - Total amount that was returned from the swap (uint265)
          _percentageAmount - Percentage calculated based on the initial amount sent (uint256)
          _tokenOut - Address of the token that the swap was made for (address)
    */
    function getPercentageReturn(uint256 _amount, uint256 _percentageAmount, address _tokenOut) public view returns (uint256){
        uint32 _decimals = IERC20Metadata(_tokenOut).decimals();
        return (_percentageAmount * _amount) / (10 ** _decimals);
    }


    /*
      This function works the transfer Token based on the order system, necessary to overcome the stack to deep issue
      Input
        _order
        _from
        _tokenIn
    */
    function orderBasedTransfer(Order calldata _order, address _from, address _tokenIn) private returns (bool) {
        return transferTokenFrom(_tokenIn, _from, address(this), totalOrderValue(_order));
    }


    /*
      Swaps Tokens for Tokens
        Input
          _amount - amount that will be swapped (uint256)
          _amountOutMin - minimum amount that will allow the transaction to be executed (uint256)
          _path  - Array with the entry token and output token (address[2])
    */
    function uniswapSwapTokensToTokens(uint256 _amount, uint256 _amountOutMin, address[] memory path) internal returns (uint256){
        uint256[] memory _returnAmounts = uniswapRouter.swapExactTokensForTokens(_amount, _amountOutMin, path, address(this), block.timestamp);
        return _returnAmounts[_returnAmounts.length - 1];
    }


    /*
      Swaps Tokens for ETH
        Input
          _amount - amount that will be swapped (uint256)
          _amountOutMin - minimum amount that will allow the transaction to be executed (uint256)
          _path  - Array with the entry token and output token (address[2])

      NOTE:
      THE ETH COIN CANNOT BE USED AS A INPUT PARAMETER
      WETH NEEDS TO BE THE OUTPUT TOKEN
    */
    function uniswapSwapTokensToETH(uint256 _amount, uint256 _amountOutMin, address[] memory path) internal returns (uint256){
        uint256[] memory _returnAmounts = uniswapRouter.swapExactTokensForETH(_amount, _amountOutMin, path, address(this), block.timestamp);
        return _returnAmounts[_returnAmounts.length - 1];
    }


    /*
      This function creates a path, Swaps token for tokens and sends the swapped amount to the user
      Input
        _amountToSwap - Total amount from the pile of users (uint265)
        _amountOutMin - Minimum amount acceptable to execute the swap (uint256)
        _path - Array of tokens that will be swapped (address[2])
        _percentageAmount - Array of percentages calculate to track the diferent amount swapped (uint256[])
        _to - Array of wallets where the swapped ETH will be sent (address[])

      NOTE:
        THE ETH COIN CANNOT BE USED AS A INPUT PARAMETER
        WETH NEEDS TO BE THE OUTPUT TOKEN
    */
    function setSwapTransfer(uint256 _amountToSwap, uint256 _amountOutMin, address[2] calldata _path, uint256[] memory _percentageAmount, address[] memory _to) private {
        uint256 _returnAmount = uniswapSwapTokensToTokens(_amountToSwap, _amountOutMin, createSwapPath(_path));

        for (uint16 l = 0; l < _percentageAmount.length; l++) {
            if (_to[l] != address(0)) transfer(_path[1], _to[l], getPercentageReturn(_returnAmount, _percentageAmount[l], _path[0]));
        }
    }


    /*
      This function creates a path, Swaps the tokens for ETH and sends the swapped amount to the user
      Input
        _amountToSwap - Total amount from the pile of users (uint265)
        _amountOutMin - Minimum amount acceptable to execute the swap (uint256)
        _path - Array of tokens that will be swapped (address[2])
        _percentageAmount - Array of percentages calculate to track the diferent amount swapped (uint256[])
        _to - Array of wallets where the swapped ETH will be sent (address[])

      NOTE:
        THE ETH COIN CANNOT BE USED AS A INPUT PARAMETER
        WETH NEEDS TO BE THE OUTPUT TOKEN
    */
    function setSwapETHTransfer(uint256 _amountToSwap, uint256 _amountOutMin, address[2] calldata _path, uint256[] memory _percentageAmount, address[] memory _to) private {
        //Swap token for ETH
        uint256 _returnAmount = uniswapSwapTokensToETH(_amountToSwap, _amountOutMin, createSwapPath(_path));

        //Return Swaped ETH back to the Users
        for (uint16 l = 0; l < _percentageAmount.length; l++) {
            if (_to[l] != address(0)) payable(_to[l]).transfer(getPercentageReturn(_returnAmount, _percentageAmount[l], _path[0]));
        }
    }

    /*
      Creates a Path that will have WETH as a middle token in case none of the token being swapped is WETH
        Input
          _path - Array of token address with two memory slot (address[2])

      NOTE:
        This methodology is being used due to UNISWAP V2 constraints
    */
    function createSwapPath(address[2] calldata _path) internal returns (address[] memory){
        address[] memory path;
        if (_path[0] == WETH || _path[1] == WETH) {
            path = new address[](2);
            path[0] = _path[0];
            path[1] = _path[1];
        } else {
            path = new address[](3);
            path[0] = _path[0];
            path[1] = WETH;
            path[2] = _path[1];
        }

        return path;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "HuddleLib.sol";
import "IUniswapV2Router02.sol";


contract HuddleCore is HuddleLib {

    address internal  feeWallet;
    IUniswapV2Router02 internal uniswapRouter;

    struct Order {
        uint256 amount;
        uint256 fee;
        uint256 gasCost;
    }


    constructor (address feeWalletAddress, address WETH, address UNISWAP_ROUTER) HuddleLib(WETH) {
        feeWallet = feeWalletAddress;
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER);
    }


    /*
        Send fee or exchange based on the input token
    */
    function feePayment(address _tokenIn, uint256 _totalFee, bool _isSafeToken) internal {
         if (_totalFee > 0){
            if (_tokenIn == WETH) {
                sendWETHFee();
            } else {
                if(_isSafeToken) transfer(_tokenIn, feeWallet, _totalFee);
                else sendUnsafeFee(_tokenIn, _totalFee);
            }
        }
    }


    /*
        Send WETH Fee to input wallet
    */
    function sendWETHFee() internal {
        withdrawWETH(IWETH.balanceOf(address(this)));
        payable(feeWallet).transfer(address(this).balance);
    }


    /*
        Swap Unsafe Token to Eth and Send to Wallet
    */
    function sendUnsafeFee(address _tokenIn, uint256 _totalFee) internal{
        approval(_tokenIn, _totalFee, address(uniswapRouter));
        address[] memory path = new address[](2);

        path[0] = _tokenIn;
        path[1] = WETH;

        try uniswapRouter.swapExactTokensForETH(
            _totalFee,
            0,
            path,
            feeWallet,
            block.timestamp
        )returns (uint256[] memory _returnAmounts)
        {
           emit SuccessfulTransfer(address(0), address(this), feeWallet, _returnAmounts[1]);
        } catch Error(string memory reason){
            emit FailedTransfer(address(0), address(this), feeWallet, 0);
        } catch{
            emit FailedTransfer(address(0), address(this), feeWallet, 0);
        }
    }


    /*
      Updates the address of the fee pay wallet
        Input
          newPayWallet - Address of the new wallet for
    */
    function updateFeeWallet(address newFeeWallet) public onlyOwner {
        feeWallet = newFeeWallet;
    }


    /*
      Returns the sum of all of the elements of an order
      Input
      _order - Order Structure
    */
    function totalOrderValue(Order calldata _order) internal pure returns (uint256){
        return _order.amount + _order.fee + _order.gasCost;
    }


    /*
      Returns the sum of all of the GasCost and Fee elements of an Order
      Input
      _order - Order Structure
    */
    function sumOfGasAndFee(Order calldata _order) internal pure returns (uint256){
        return _order.fee + _order.gasCost;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


//import the ERC20 interface

import "IERC20Metadata.sol";
import "IWETH9.sol";
import "Ownable.sol";


contract HuddleLib is Ownable {

    event LogString(string);

    // Transfer Event
    event SuccessfulTransfer(address token, address from, address to, uint256 amount);
    event FailedTransfer(address token, address from, address to, uint256 amount);

    // Approval Event
    event SuccessfulApproval(address token, address from, address spender, uint256 amount);
    event FailedApproval(address token, address from, address spender, uint256 amount);

    // Withdraw Event
    event SuccessfulWETHWithdraw(uint256 amount);
    event FailedWETHWithdraw(uint256 amount);

    // Swap Event
    event SuccessfulSwap(address path0, address path1, uint256 amount);
    event FailedSwap(address path0, address path1, uint256 amount);

    // Donation Event
    event ReceivedDonation(address from, uint256 amount);

    address internal WETH;
    IWETH9 internal IWETH;

    constructor (address _WETH) {
        WETH = _WETH;
        IWETH = IWETH9(_WETH);
    }


    /*
    Create a approval so that the destination is able to use the token.
    Input
        _tokenIn - Address of token to be sent (address)
        _amount - Amount to Transfer (uint256)   
        _approveTo - Address where the token will be sent (address)
    */
    function approval(address _tokenIn, uint256 _amount, address _approveTo) internal returns (bool) {
        try IERC20(_tokenIn).approve(_approveTo, _amount) {
            emit SuccessfulApproval(_tokenIn, address(this), _approveTo, _amount);
            return true;
        } catch {
            emit FailedApproval(_tokenIn, address(this), _approveTo, _amount);
        }
        return false;
    }


    /*
    Allow for the transfer of Tokens the current address to another
    Input
        _recipient - Address where the token will be sent (address)
        _amount - Amount to Transfer (uint256)   
        _tokenAddress - Address of token to be sent (address)
    */
    function transfer(address _tokenAddress, address _to, uint256 _amount) internal returns (bool) {
        try IERC20(_tokenAddress).transfer(_to, _amount){
            emit SuccessfulTransfer(_tokenAddress, address(this), _to, _amount);
            return true;
        } catch {
            emit FailedTransfer(_tokenAddress, address(this), _to, _amount);
        }
        return false;
    }


    /*
    Allow for the transfer of Tokens from one location to another
    Input
        _tokenAddress - Address of token to be sent (address)
        _from - Address from where the transfer originates (address)
        _to - Address where the token will be sent (address)
        _amount - Amount to Transfer (uint256)   
    */
    function transferTokenFrom(address _tokenAddress, address _from, address _to, uint256 _amount) internal returns (bool){// todo discuss low level call (lower gas) or instantiating the IERC20 interface only once

        try IERC20(_tokenAddress).transferFrom(_from, _to, _amount){
            emit SuccessfulTransfer(_tokenAddress, _from, _to, _amount);
            return true;
        }
        catch {
            emit FailedTransfer(_tokenAddress, _from, _to, _amount);
        }
        return false;
    }


    /*
    This function withdraws WETH and converts it to ETH to adequatly use in the in the payable Mint Function
    The reason for this is that multiples transfer cannot be requested from a waller without using a ERC20 Token
    Input
     -NULL
    */
    function withdrawWETH(uint256 amount) internal {
        if (amount > 0) {
            try IWETH.withdraw(amount) {
                emit SuccessfulWETHWithdraw(amount);
            } catch {
                emit FailedWETHWithdraw(amount);
            }
        }
    }

    function withdrawLockedFunds(address token, uint256 amount, address to) public onlyOwner {
        if (token == address(0)) { // Assuming address 0 for ETH balance
            if (amount == 0) { // Assuming amount 0 for all balance
                payable(to).transfer(address(this).balance);
            } else {
                payable(to).transfer(amount);
            }
        } else {
            if (amount == 0) {
                IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
            } else {
                IERC20(token).transfer(to, amount);
            }
        }
    }

    receive() external payable {
        emit ReceivedDonation(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "IERC20.sol";

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity ^0.8.15;


interface IWETH9 {

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity ^0.8.15;


interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);


    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline) external view returns (uint[] memory amounts);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;



library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}



contract HuddleCalculation {

    function getPercentage(uint256 _amount, uint256 _totalAmount, uint8 _decimals) internal pure returns(uint256){
        return  FullMath.mulDiv(_amount,10**_decimals,_totalAmount);
    }

}