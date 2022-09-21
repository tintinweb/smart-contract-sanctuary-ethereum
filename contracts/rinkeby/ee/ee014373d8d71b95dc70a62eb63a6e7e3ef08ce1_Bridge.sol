/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

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

  function mint(address receiver, uint256 amount) external;

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
    using SafeMath for uint256;
    address public admin;
    IERC20 public  token;
    uint256 public nonce;
    mapping(uint256 => bool) public processedTransactionNonces; // for storing the nonce process status using boolean and mapping

    bytes32 internal keyHash = 0xd609d5ea12b50fe8d48cea0df5be6ee2dc250d644f336775a08a56e0751845b7;

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
    }

    // burn some amount of tokens
    function burn(uint256 _amount, address _token) public {
        token = IERC20(_token); 
        token.transferFrom(msg.sender, address(this), _amount);

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

    function getNonce() public view returns (uint256) {
        require(msg.sender == admin, "Only admin can mint tokens");
        return nonce;
    }

    function mint(
        address reciever,
        uint256 amount,
        uint256 otherChainNonce,
        address _token,
        uint256 _safeamount
    ) external {
        require(msg.sender == admin, "Only admin can mint tokens");

        require(
            processedTransactionNonces[otherChainNonce] == false,
            "transfer already processed"
        );
        token = IERC20(_token);
        uint256 safeamountvalue = uint256(sha256(abi.encode(keyHash, (otherChainNonce.mul(amount)))));
        require(_safeamount == safeamountvalue, "The hash value is not exact");

        processedTransactionNonces[otherChainNonce] = true;

        token.mint(reciever, amount);
        emit Transfer(
            msg.sender,
            reciever,
            amount,
            block.timestamp,
            otherChainNonce,
            Step.Mint
        );
    }

    function getHash(uint _amount,uint _nonce) public view returns (uint256){
        require(msg.sender == admin, "Only admin can mint tokens");
        return uint256(sha256(abi.encode(keyHash, (_nonce.mul(_amount)))));
    }
}