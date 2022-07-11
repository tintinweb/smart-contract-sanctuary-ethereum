/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
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

// the base implementation contract for the bridge-contract


contract Bridge {
    address public admin;
    IERC20 public  token;
    uint256 public nonce;
    mapping(uint256 => bool) public processedTransactionNonces; // for storing the nonce process status using boolean and mapping

    enum Step {
        Burn,
        Mint
    }

    /*
     A custom event for bridge which will be emitted when a transaction is processed(burn/mint)
     */

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 date,
        uint256 nonce,
        Step indexed step
    );

    // initializing the bridge with the token contract and the admin address
    constructor() {
        admin = msg.sender;
        // token = IERC20(_token); // getting the token from the IERC interface
    }

    // burn some amount of tokens
    function burn(uint256 _amount, address _token) public {
        token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount); // locking the tokens from the sender address in the contract
        emit Transfer(
            msg.sender,
            address(this),
            _amount,
            block.timestamp,
            nonce,
            Step.Burn
        );
        nonce++;
    }

    // function for minting some toknes the reciver

    function mint(
        address reciever,
        uint256 amount,
        uint256 otherChainNonce,
        address _token
    ) external {
        require(msg.sender == admin, "Only admin can mint tokens");

        require(
            processedTransactionNonces[otherChainNonce] == false,
            "transfer already processed"
        ); // checking if the nonce is already processed
        token = IERC20(_token);

        processedTransactionNonces[otherChainNonce] = true;
        token.approve(address(this), amount); // approving the amount of tokens to be minted
        token.transferFrom(address(this), reciever, amount); // minting some tokens for the reciever
        emit Transfer(
            msg.sender,
            reciever,
            amount,
            block.timestamp,
            otherChainNonce,
            Step.Mint
        );
    }
}