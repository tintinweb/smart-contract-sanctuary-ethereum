// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./IDODO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoanExecutor.sol";
contract DODOFlashloan {
        uint256 public callbackCount=1;
    //闪电贷入口
    function dodoFlashLoan(
        address flashLoanPool1,//池子1
        address flashLoanPool2,//池子2
        uint256 loanAmount1,//金额1
        uint256 loanAmount2,//金额2
        address loanToken,//借出的代币，借一样的代币，一个池子不够
        address executor   //处理闪电贷逻辑的合约
    ) external  {
        callbackCount=1;
        bytes memory data = abi.encode(executor, flashLoanPool1, flashLoanPool2, loanToken, loanAmount1, loanAmount2);
        address flashLoanBase1 = IDODO(flashLoanPool1)._BASE_TOKEN_();
        address flashLoanBase2 = IDODO(flashLoanPool2)._BASE_TOKEN_();
        if(flashLoanBase1 == loanToken) {
            IDODO(flashLoanPool1).flashLoan(loanAmount1, 0, address(this), data);
        } else {
            IDODO(flashLoanPool1).flashLoan(0, loanAmount1, address(this), data);
        }
        if(flashLoanBase2 == loanToken) {
            IDODO(flashLoanPool2).flashLoan(loanAmount2, 0, address(this), data);
        } else {
            IDODO(flashLoanPool2).flashLoan(0, loanAmount2, address(this), data);
        }
    }


    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount,bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender,baseAmount,data);
    }

    function _flashLoanCallBack(address sender, uint256 loanAmount, bytes calldata data) internal {
        (address executor, address flashLoanPool1, address flashLoanPool2, address loanToken, uint256 loanAmount1, uint256 loanAmount2) = 
        abi.decode(data, (address, address, address, address, uint256, uint256));
        require(sender == address(this) && (msg.sender == flashLoanPool1 || msg.sender == flashLoanPool2), "HANDLE_FLASH_NENIED");
        IERC20(loanToken).approve(executor, loanAmount);
        IERC20(loanToken).transfer(executor, loanAmount);

        callbackCount++;
        if (callbackCount == 2) {
            IFlashLoanExecutor(executor).executeOperation(loanToken);
            IERC20(loanToken).transfer(flashLoanPool1, loanAmount1);
            IERC20(loanToken).transfer(flashLoanPool2, loanAmount2);
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
interface IDODO {
     function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
interface IFlashLoanExecutor{
    function executeOperation(address token) external;
}