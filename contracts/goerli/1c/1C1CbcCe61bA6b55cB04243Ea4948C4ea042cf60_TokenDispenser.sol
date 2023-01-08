// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../contracts/Interfaces/IMyERC20.sol";

// Smart contract to dispense ERC20 tokens
contract TokenDispenser {
  // Address of the deployer of this contract, who is the admin
  address public admin;

  // Mapping to keep track of the token balances of users
  mapping (address => uint256) public balances;

  // Token contract that this contract is initialized to
  IMyERC20 public token;

  // Maximum balance that a user can have
  uint256 public withDrawalLimit;

  // Constructor to initialize the contract with an ERC20 token and set the deployer as the admin
  constructor(IMyERC20 _token) {
    admin = msg.sender;
    token = IMyERC20(_token);
    withDrawalLimit = 10000000 * 10**18;
  }

  // Function to dispense tokens from the owner's wallet to the caller's wallet
  function dispenseTokens(uint256 _amount) public {
    require(balances[msg.sender] + _amount <= withDrawalLimit, "Exceeded maximum balance limit");
    require(token.transferFrom(admin, msg.sender, _amount), "Transfer failed");
    balances[msg.sender] += _amount;
  }

  // Function for the admin to reset the balance of any user
  function resetBalance(address _user) public {
    require(msg.sender == admin, "Only the admin can reset a user's balance");
    balances[_user] = 0;
  }

    // Function for the admin to change the maximum balance limit
  function changeWithDrawalLimit(uint256 _withDrawalLimit) public {
    require(msg.sender == admin, "Only the admin can change the maximum balance limit");
    withDrawalLimit = _withDrawalLimit;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMyERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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