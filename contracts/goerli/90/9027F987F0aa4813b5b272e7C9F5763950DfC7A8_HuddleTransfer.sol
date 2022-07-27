// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "HuddleCore.sol";


contract HuddleTransfer is HuddleCore {


    constructor(address payable feeWallet, address WETH, address _uniswapRouter) HuddleCore(feeWallet, WETH, _uniswapRouter) {}


    /* ========================================== */
    /*                                            */
    /*              Token Transfers               */
    /*                                            */
    /* ========================================== */

    /*
      This function allow for multiple user to transfer token to another wallet in the same block transaction
      Input
        _from - Array of wallets from where the token will be sent
        _token - Address of the token that will be sent
        _to -Array of addresses of the recipients
        _amountIn -Array of amounts that will be sent from each wallet
    */
    function ManyToManyTransfer(Order[] calldata _orders, address _token, address[] calldata _from, address[] calldata _to, bool _isSafeToken) public onlyOwner {
        uint256 _totalFee;

        for (uint16 i = 0; i < _from.length; i++) {

            if (transferTokenFrom(_token, _from[i], address(this), totalOrderValue(_orders[i]))) {
                _totalFee += sumOfGasAndFee(_orders[i]);
                transfer(_token, _to[i], _orders[i].amount);
            }
        }

        feePayment(_token, _totalFee, _isSafeToken);
    }


    /*
      This function executes a Token to Coin transfer of WETH, as such it will receive WETH and unwrap to ETH to send
      Input
        _from - Wallets from where the token will be sent
        _token - Address of the token that will be sent
        _to -Array of addresses of the recipients
        _amountIn -Array of amounts that will be sent from each wallet
    */
    function OneToManyTransfer(Order[] calldata _orders, address _token, address _from, address[] calldata _to, bool _isSafeToken) public onlyOwner {
        uint256 _totalFee;
        uint256 _totalAmount;
        uint16 i;

        for (i = 0; i < _to.length; i++) {
            _totalAmount += _orders[i].amount;
            _totalFee += _orders[i].fee + _orders[i].gasCost;
        }
        require(transferTokenFrom(_token, _from, address(this), _totalAmount + _totalFee),
            "Unsuccessful transfer of funds to the contract. Please check if you have enough balance approved.");

        for (i = 0; i < _to.length; i++) {
            transfer(_token, _to[i], _orders[i].amount);
        }

        feePayment(_token, _totalFee, _isSafeToken);
    }


    /*
      This functions takes tokens from various wallets and sends them all to one address
      Input
        _token - Address of the token that will be sent
        _amountIn -Array of amounts that will be sent from each wallet
        _to - Address of the recipient
        _from - Array of wallets from where the token will be sent
    */
    function ManyToOneTransfer(Order[] calldata _orders, address _token, address[] calldata _from, address _to, bool _isSafeToken) public onlyOwner {
        uint256 _totalAmount;
        uint256 _totalFee;

        for (uint16 i = 0; i < _from.length; i++) {
            if (transferTokenFrom(_token, _from[i], address(this), totalOrderValue(_orders[i]))) {
                _totalAmount += _orders[i].amount;
                _totalFee += sumOfGasAndFee(_orders[i]);
            }
        }

        transfer(_token, _to, _totalAmount);

        feePayment(_token, _totalFee, _isSafeToken);
    }


    /* ========================================== */
    /*                                            */
    /*              ETH Transfers                 */
    /*                                            */
    /* ========================================== */


    /*
      This function allow for multiple user to transfer token to another wallet in the same block transaction
      Input
        _from - Array of wallets from where the token will be sent
        _token - Address of the token that will be sent
        _to -Array of addresses of the recipients
        _amountIn -Array of amounts that will be sent from each wallet
    */
    function ManyToManyETHTransfer(Order[] calldata _orders, address[] calldata _from, address[] calldata _to) public onlyOwner {
        uint256 _totalFee;
        uint256 _totalAmount;
        bool[] memory isTransferAccepted = new bool[](_from.length);

        for (uint16 i = 0; i < _from.length; i++) {
            if (transferTokenFrom(WETH, _from[i], address(this), totalOrderValue(_orders[i]))) {
                _totalFee += sumOfGasAndFee(_orders[i]);
                _totalAmount += _orders[i].amount;
                isTransferAccepted[i] = true;
            } else {
                isTransferAccepted[i] = false;
            }
        }

        withdrawWETH(_totalAmount);

        for (uint16 i = 0; i < _from.length; i++) {
            if (isTransferAccepted[i]) payable(_to[i]).transfer(_orders[i].amount);
        }

        feePayment(WETH, _totalFee, true);
    }


    /*
      This function executes a Token to Coin transfer of WETH, as such it will receive WETH and unwrap to ETH to send
      Input
        _from - Wallets from where the token will be sent
        _to -Array of addresses of the recipients
        _amountIn -Array of amounts that will be sent from each wallet

      NOTE: To use a Approval for WETH needs to be done
    */
    function OneToManyETHTransfer(Order[] calldata _orders, address _from, address[] calldata _to) public onlyOwner {
        uint256 _totalFee;
        uint256 _totalAmount;
        uint16 i;

        for (i = 0; i < _to.length; i++) {
            _totalAmount += _orders[i].amount;
            _totalFee += sumOfGasAndFee(_orders[i]);
        }
        require(transferTokenFrom(WETH, _from, address(this), _totalAmount + _totalFee),
            "Unsuccessful transfer of funds to the contract. Please check if you have enough balance approved.");

        withdrawWETH(_totalAmount);

        for (i = 0; i < _to.length; i++) {
            payable(_to[i]).transfer(_orders[i].amount);
        }

        feePayment(WETH, _totalFee, true);
    }


    /*
      This functions takes tokens from various wallets and sends them all to one address
      Input
        _from - Array of wallets from where the token will be sent
        _to - Address of the recipient
        _orders -Array of orders from each wallet
    */
    function ManyToOneETHTransfer(Order[] calldata _orders, address[] calldata _from, address _to) public onlyOwner {
        uint256 _totalAmount;
        uint256 _totalFee;

        for (uint16 i = 0; i < _from.length; i++) {
            if (transferTokenFrom(WETH, _from[i], address(this), totalOrderValue(_orders[i]))) {
                _totalAmount += _orders[i].amount;
                _totalFee += sumOfGasAndFee(_orders[i]);
            }
        }
        withdrawWETH(_totalAmount);
        payable(_to).transfer(_totalAmount);

        feePayment(WETH, _totalFee, true);
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