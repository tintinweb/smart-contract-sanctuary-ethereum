// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AccessControl.sol";

//

interface Egg {
  function mintEggs(address to, uint256 amount) external;

  function setBaseURI(string memory baseURI_) external;

  function purchasedAmount(address user) external view returns (uint8);
}

//solhint-disable avoid-low-level-calls
contract RoosterEggSale is AccessControl {
  //EggSale struct
  EggSale public eggsale;

  //RoosterEgg address
  Egg public immutable egg;

  //USDC address
  IERC20 public immutable usdc;

  //Vault address
  address public immutable vault;

  //Whitelist verification signer address
  address public immutable signer;

  //Total minted
  uint256 public minted;

  //Max supply of eggs
  uint256 public constant maxSupply = 150_000;

  //User egg purchased amount (user => amount)
  mapping(address => uint256) public purchasedAmount;
  //Check if nonce is used (nonce => boolean)
  mapping(bytes32 => bool) private _nonceUsed;

  event Purchase(address indexed purchaser, uint256 amount, uint256 value);
  event EggSaleSet(
    uint256 supply,
    uint256 cap,
    uint256 openingTime,
    uint256 closingTime,
    bool whitelist,
    uint256 price,
    uint256 cashback
  );
  event MaticCashback(address user, uint256 amount);
  event MaticCashbackFailed(address indexed user, uint256 balance);

  struct EggSale {
    uint32 supply;
    uint32 cap;
    uint32 sold;
    uint32 openingTime;
    uint32 closingTime;
    bool whitelist;
    uint256 price;
    uint256 cashback;
  }

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  constructor(
    address usdc_,
    address egg_,
    address vault_,
    address signer_,
    uint256 minted_
  ) {
    usdc = IERC20(usdc_);
    egg = Egg(egg_);
    vault = vault_;
    signer = signer_;
    minted = minted_;
  }

  receive() external payable {}

  function isOpen() public view returns (bool) {
    return block.timestamp >= eggsale.openingTime && block.timestamp < eggsale.closingTime;
  }

  function buyEggs(
    uint8 amount,
    bytes32 nonce,
    Sig calldata sig
  ) external whenNotPaused {
    address purchaser = msg.sender;
    uint256 value = eggsale.price * amount;
    uint256 cashbackAmount = eggsale.cashback * amount;

    //Basic chekcs
    require(isOpen(), "Not open");
    require(minted + amount <= maxSupply, "Exceeds max supply");
    require(eggsale.sold + amount <= eggsale.supply, "Exceeds supply");
    require(
      purchasedAmount[purchaser] + egg.purchasedAmount(purchaser) + amount <= eggsale.cap,
      "Exceeds cap"
    );

    //Whitelist check
    if (eggsale.whitelist) {
      require(!_nonceUsed[nonce], "Nonce used");
      require(_isWhitelisted(purchaser, nonce, sig), "Not whitelisted");
      _nonceUsed[nonce] = true;
    }

    //Effects
    unchecked {
      minted += amount;
      eggsale.sold += amount;
      purchasedAmount[purchaser] += amount;
    }

    //Interactions
    usdc.transferFrom(purchaser, vault, value);

    egg.mintEggs(purchaser, amount);

    if (cashbackAmount > 0) {
      (bool success, ) = payable(purchaser).call{value: cashbackAmount}("");
      if (success) {
        emit MaticCashback(purchaser, cashbackAmount);
      } else {
        emit MaticCashbackFailed(purchaser, address(this).balance);
      }
    }

    emit Purchase(purchaser, amount, value);
  }

  function _isWhitelisted(
    address user,
    bytes32 nonce,
    Sig calldata sig
  ) private view returns (bool) {
    bytes32 messageHash = keccak256(abi.encodePacked(user, nonce));
    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s) == signer;
  }

  /* Only owner functions */

  function setEggSale(
    uint32 openingTime,
    uint32 closingTime,
    uint32 supply,
    uint32 cap,
    bool whitelist,
    uint256 price,
    uint256 cashback
  ) external onlyOwner {
    require(closingTime >= openingTime, "Closing time < Opening time");

    if (!isOpen()) {
      require(openingTime > block.timestamp, "Invalid opening time");
      eggsale.openingTime = openingTime;
      eggsale.sold = 0;
    }

    eggsale.closingTime = closingTime;
    eggsale.supply = supply;
    eggsale.cap = cap;
    eggsale.whitelist = whitelist;
    eggsale.price = price;
    eggsale.cashback = cashback;

    emit EggSaleSet(supply, cap, openingTime, closingTime, whitelist, price, cashback);
  }

  function mintEggs(address to, uint256 amount) external onlyMinter {
    require(minted + amount <= maxSupply, "Exceeds max supply");
    unchecked {
      minted += amount;
    }
    egg.mintEggs(to, amount);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    egg.setBaseURI(baseURI_);
  }

  function withdrawMatic(uint256 amount) external onlyOwner {
    (bool success, ) = payable(vault).call{value: amount}("");
    require(success, "Withdraw failed");
  }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract AccessControl is Pausable {
  //Address of current owner
  address public owner;
  //Address of new owner (Note: new owner must pull to be an owner)
  address public newOwner;
  //Maps if user has minter role
  mapping(address => bool) public isMinter;

  //Fires when new owner is pushed
  event OwnerPushed(address indexed pushedOwner);
  //Fires when new owner pulled
  event OwnerPulled(address indexed previousOwner, address indexed newOwner);
  //Fires when minter role is granted
  event MinterRoleGranted(address indexed account);
  //Fires when minter role is revoked
  event MinterRoleRevoked(address indexed account);

  constructor() {
    owner = msg.sender;
    emit OwnerPulled(msg.sender, address(0));
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner");
    _;
  }

  modifier onlyMinter() {
    require(isMinter[msg.sender], "Only minter");
    _;
  }

  function pushOwner(address account) public onlyOwner {
    require(account != address(0), "No address(0)");
    newOwner = account;
    emit OwnerPushed(account);
  }

  function pullOwner() external {
    require(msg.sender == newOwner, "Only new owner");
    address oldOwner = owner;
    owner = msg.sender;
    emit OwnerPulled(oldOwner, msg.sender);
  }

  function grantMinterRole(address account) external onlyOwner {
    require(account != address(0), "No address(0)");
    require(!isMinter[account], "Already granted");
    isMinter[account] = true;
    emit MinterRoleGranted(account);
  }

  function revokeMinterRole(address account) external onlyOwner {
    require(isMinter[account], "Not granted");
    isMinter[account] = false;
    emit MinterRoleRevoked(account);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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