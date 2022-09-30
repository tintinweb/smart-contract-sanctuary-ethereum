// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchSendERC20 {    
    constructor() {
        
    }

function batchTransfer(
    address _tokenAddress,
    address[] calldata _recipients,
    uint256[] calldata _amounts
  ) external {
    require(
      _recipients.length == _amounts.length,
      'the input arrays must have the same length'
    );

    // amount is used to get the total amount and fee, and then used as batch fee amount
    uint256 amount = 0;
    for (uint256 i = 0; i < _recipients.length; i++) {
      amount += _amounts[i];
    }
    // Transfer the amount and fee from the payer to the batch contract
    IERC20 requestedToken = IERC20(_tokenAddress);
    require(
      requestedToken.allowance(msg.sender, address(this)) >= amount,
      "Not sufficient allowance for batch to pay"
    );
    require(requestedToken.balanceOf(msg.sender) >= amount, "not enough funds");

    (bool success, ) = address(requestedToken).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
    require(success,"batchERC20Payment() payment transferFrom() failed");

   require(requestedToken.balanceOf(address(this)) >=amount,"batchERC20Payment() Smart contract does not have enough Balance");

    // Batch contract pays the requests using Erc20FeeProxy
    for(uint256 i = 0; i < _recipients.length; i++) {
      // amount is updated to become the sum of amounts, to calculate batch fee amount

      
      (bool okay,) = address(requestedToken).call(abi.encodeWithSignature("transfer(address,uint256)", _recipients[i],  _amounts[i]));
        require(okay , "batchERC20Payment() Unable to transfer fund");
    } 
    
  }
    
}

// SPDX-License-Identifier: MIT

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