//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// @author yvesbou

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Fund {
    mapping(address => uint256) public addressToFunds;
    mapping(address => bool) public addressToFundingStatus;
    address[] public funders;

    // USDC token parameters
    address public usdcAddress;
    IERC20 public usdcContract;

    event Deposit(uint256 amount, address indexed sender);
    event Withdraw(uint256 amount, address indexed receiver);
    event NewFunder(address indexed funder);

     /// @notice Initialise the contract
     /// @param _usdcAddress address of the USDC Token Contract   
    constructor(address _usdcAddress) {
        if(_usdcAddress == address(0)) {
            revert ZeroAddressSpecified();
        }
        usdcAddress = _usdcAddress;
        usdcContract = IERC20(usdcAddress);
    }

    /// @notice Deposit USDC to the Fund Contract.
    /// @param _amount The Amount of USDC token send to the Fund.
    function deposit(uint256 _amount) external {

        // checks
        if (_amount <= 0) {
            revert InsufficientAmount({depositAmount: _amount});
        }
        uint256 userBalance = usdcContract.balanceOf(msg.sender);
        if (userBalance < _amount) {
            revert InsufficientBalance({available: userBalance, required: _amount});
        }

        // state updates and events
        addressToFunds[msg.sender] += _amount;
        emit Deposit(_amount, msg.sender);

        if (! addressToFundingStatus[msg.sender]) {
            funders.push(msg.sender);
            addressToFundingStatus[msg.sender] = true;
            emit NewFunder(msg.sender);
        }
        
        // external calls
        if (!usdcContract.transferFrom(msg.sender, address(this), _amount)){
            revert TransactionDeclined();
        }
    }

    /// @notice Withdraw USDC from the Fund Contract.
    /// @param _amount The Amount of USDC tokens to withdraw from the Fund.
    function withdraw(uint256 _amount) external {
        
        // checks

        if (_amount <= 0) {
            revert InsufficientAmount({depositAmount: _amount});
        }

        if (!addressToFundingStatus[address(msg.sender)]) {
            // this address has not funded the contract
            revert UserNotAFunder();
        }

        if (addressToFunds[address(msg.sender)] < _amount) {
            // the user wanted to withdraw more than deposited
            revert InsufficientBalance({available: addressToFunds[address(msg.sender)], required: _amount});
        }

        // state updates and events

        addressToFunds[msg.sender] -= _amount;
        emit Withdraw(_amount, msg.sender);
        // mark address as non-funder if balance fully withdraw
        if (addressToFunds[address(msg.sender)] == _amount) {
            addressToFundingStatus[address(msg.sender)] = false;
        }

        // call external contract
        if (!usdcContract.transfer(msg.sender, _amount)) {
            revert TransactionDeclined();
        }
    }

    /***********************************************************************************************
                                            Custom errors
    ***********************************************************************************************/

    /// Insufficient balance for transfer. Needed `required` but only
    /// `available` available.
    /// @param available balance available.
    /// @param required requested amount to transfer.
    error InsufficientBalance(uint256 available, uint256 required);

    /// User wanted to deposit insufficient amount
    /// @param depositAmount amount tried to deposit
    error InsufficientAmount(uint256 depositAmount);

    /// User declined transaction
    error TransactionDeclined();

    /// User is not a funder of this contract
    error UserNotAFunder();

    /// User didn't specify an address
    error ZeroAddressSpecified();
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