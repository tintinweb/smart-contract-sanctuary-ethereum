// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract PoolManager {
  enum PoolStatus {
    Launched,
    Unlaunched
  }

  struct Pool {
    uint256 id;
    address owner;
    uint256 ethAmount;
    uint256 ssvAmount;
    PoolStatus status;
  }

  address public owner;
  uint256 public constant ethTarget = 32;
  address public constant ssvAddress = 0x3a9f01091C446bdE031E39ea8354647AFef091E7;
  uint256 public totalPools = 0;
  mapping(uint256 => Pool) pools;

  event CreatePool(uint256 id, address sender, Pool pool);
  event AddEthPool(uint256 id, address sender, uint256 ethAmount);
  event AddSsvToken(uint256 id, address sender, uint256 ssvAmount);

  constructor() {
    owner = msg.sender;
  }

  // Pool ------------------------------------------------

  function createPool() public {
    totalPools += 1;
    Pool memory pool = Pool(totalPools, msg.sender, 0, 0, PoolStatus.Unlaunched);
    pools[totalPools] = pool;
    emit CreatePool(totalPools, msg.sender, pool);
  }

  function readPool(uint256 id) public view returns (Pool memory) {
    return pools[id];
  }

  function readyToLaunch(uint256 id, uint256 ssvTarget) public view returns (bool) {
    return pools[id].ethAmount >= ethTarget && pools[id].ssvAmount >= ssvTarget;
  }

  // function launchPool(uint256 id, uint256 ssvTarget) public {
  //   require(readyToLaunch(id, ssvTarget), 'Pool is not ready to launch');
  //   // pegar interface
  // }

  // ETH ------------------------------------------------

  function ethbalance() public view returns (uint256) {
    return address(this).balance;
  }

  function addEthPool(uint256 poolId) public payable {
    pools[poolId].ethAmount += msg.value;
    emit AddEthPool(poolId, msg.sender, msg.value);
    // generate erc ETH Pool
  }

  // SSV ------------------------------------------------

  function ssvBalance() public view returns (uint256) {
    return IERC20(ssvAddress).balanceOf(address(this));
  }

  function addSsvToken(uint256 poolId, uint256 amount) public {
    require(IERC20(ssvAddress).balanceOf(msg.sender) >= amount, 'Not enough SSV tokens');
    IERC20(ssvAddress).transferFrom(msg.sender, address(this), amount);
    pools[poolId].ssvAmount += amount;
    emit AddSsvToken(poolId, msg.sender, amount);
  }
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