/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: UNLICENSED

// File: erc3156/contracts/interfaces/IERC3156FlashBorrower.sol



pragma solidity >=0.6.0 <0.9.0;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-LICENSE-IDENTIFIER: UNLICENSED

// File: erc3156/contracts/interfaces/IERC3156FlashLender.sol


pragma solidity >=0.6.0 <0.9.0;



interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-LICENSE-IDENTIFIER: UNLICENSED

// File: .deps/github/alcueca/ERC3156-Wrappers/contracts/interfaces/IERC20.sol


pragma solidity ^0.7.0 || ^0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
// SPDX-LICENSE-IDENTIFIER: UNLICENSED

// File: sourcefile.sol


pragma solidity ^0.7.5;


contract FlashBorrower is IERC3156FlashBorrower {
    enum Action {NORMAL, STEAL, REENTER}

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    uint256 public flashBalance;
    address public flashSender;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(address sender, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns(bytes32) {
        require(sender == address(this), "FlashBorrower: External loan initiator");
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashSender = sender;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;
        if (action == Action.NORMAL) {
            flashBalance = IERC20(token).balanceOf(address(this));
        } else if (action == Action.STEAL) {
            // do nothing
        } else if (action == Action.REENTER) {
            flashBorrow(IERC3156FlashLender(msg.sender), token, amount * 2);
        }
        return CALLBACK_SUCCESS;
    }

    function flashBorrow(IERC3156FlashLender lender, address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        approveRepayment(lender, token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function flashBorrowAndSteal(IERC3156FlashLender lender, address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        lender.flashLoan(this, token, amount, data);
    }

    function flashBorrowAndReenter(IERC3156FlashLender lender, address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        approveRepayment(lender, token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function approveRepayment(IERC3156FlashLender lender, address token, uint256 amount) public {
        uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
    }
}