// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract N2BridgeETH {

  uint chainId;
  address public admin;
  IERC20 public token;
  
  mapping(address => mapping(uint => bool)) public processedNonces;
  mapping(address => uint) public nonces;

  enum Step { Deposit, Withdraw }
  event Transfer(
    address from,
    address to,
    uint destChainId,
    uint amount,
    uint date,
    uint nonce,
    bytes32 signature,
    Step indexed step
  );

  constructor() {
    admin = msg.sender;
    uint _chainId;
    assembly {
        _chainId := chainid()
    }
    chainId = _chainId;
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "Only Admin can perform this operation.");
    _;
  }

  function setToken(address _token) external onlyAdmin {
    token = IERC20(_token);
    token.approve(_token, type(uint).max);
  }

  function deposit(uint amount) external onlyAdmin {
    require(token.balanceOf(admin) >= amount, "not sufficient fund");
    token.transferFrom(admin, address(this), amount);
  }

  // function withdraw(uint amount) external onlyAdmin {
  //   token.transfer(admin, amount);
  // }

  function deposit(address to, uint destChainId, uint amount, uint nonce) external {
    require(nonces[msg.sender] == nonce, 'transfer already processed');
    nonces[msg.sender] += 1;
    token.transferFrom(msg.sender, address(this), amount);
    bytes32 signature = keccak256(abi.encodePacked(msg.sender, to, chainId, destChainId, amount, nonce));
    
    emit Transfer(
      msg.sender,
      to,
      destChainId,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Deposit
    );
  }

  function withdraw(
    address from, 
    address to, 
    uint srcChainId,
    uint amount, 
    uint nonce,
    bytes32 signature
  ) external {
    bytes32 _signature = keccak256(abi.encodePacked(
      from, 
      to, 
      srcChainId,
      chainId,
      amount,
      nonce
    ));
    require(_signature == signature , 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    require(token.balanceOf(address(this)) >= amount, 'insufficient pool');
    token.transfer(to, amount);
    emit Transfer(
      from,
      to,
      chainId,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Withdraw
    );
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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