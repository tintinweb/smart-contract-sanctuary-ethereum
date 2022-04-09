pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vendor is Ownable {
  // address crownAddress = 0x444d6088B0F625f8C20192623B3C43001135E0fa;
  // address usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
  // address usdcAddress = 0x8AdB190AC964D2A0d9f81842175e6b67C7523b18; // polyUSDC GOERLI

  

  uint256 public constant USDCPerCrown = 150000;
  // uint256 public constant CrownPerUSDC = 6666666666666666666;

  // event BuyCrown(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  // event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);
  event WithdrawCrown(address owner, uint256 vendorBalance);
  // event TransferSent(address _from, address _destAddr, uint _amount);

  IERC20 public _crownToken;
  IERC20 public _usdcToken;
  event SendCrown(address receiver, uint256 amount);
  event ReceiveUSDC(address sender, uint256 amount);


  constructor(IERC20 crownAddress, IERC20 usdcAddress) {
    _crownToken = crownAddress;
    _usdcToken = usdcAddress;
  }

    function sendCrown(uint256 amount) external {
      address receiver = msg.sender;
      // _crownToken.transferFrom(address(this), receiver, amount);
      _crownToken.transfer(receiver, amount);
      emit SendCrown(receiver, amount);
    }

    function receiveUSDC(uint256 amount) external {
      address sender = msg.sender;
      _usdcToken.transferFrom(sender, address(this), amount);
      emit ReceiveUSDC(sender, amount);
    }

  // function transferERC20(IERC20 token, address to, uint256 amount) internal {
  //   uint256 erc20balance = token.balanceOf(address(this));
  //   require(amount <= erc20balance, "balance is low");
  //   token.transfer(to, amount);
  //   emit TransferSent(msg.sender, to, amount);
  //   }

  // function crownToUSDC(uint256 usdcToSpend) public pure returns (uint256 amount) {
  //   // uint256 usdc = (crown * USDCPerCrown);
  //   amount = (usdcToSpend * CrownPerUSDC);///10**18;
  //   return amount;
  // }


  // function sendCrown(uint256 amount) public {

  //   // Check that the Vendor's balance is enough to do the swap
  //   uint256 vendorBalance = crownToken.balanceOf(address(this));
  //   require(vendorBalance >= amount, "Vendor contract has not enough Crown");

  //   (bool sent) = crownToken.transferFrom(address(this), msg.sender, amount);
  //   require(sent, "Failed to transfer Crown from  to vendor");
  // }



  /**
  * @notice Allow users to buy crown for USDC
  */
  function buyCrown(uint256 crownTokens) public {
    // Check that the requested amount of tokens to sell is more than 0
    require(crownTokens > 0, "Specify an amount of Crown greater than zero");


    // Check that the Vendor's balance is enough to do the swap
    uint256 vendorBalance = _crownToken.balanceOf(address(this));
    require(vendorBalance >= crownTokens, "Vendor contract has not enough Crown");

    // uint256 crownTokens = (usdcToSpend * CrownPerUSDC);///10**18;
    uint256 usdcToSpend = (crownTokens * USDCPerCrown)/10**18;

    // Check that the user's USDC balance is enough to do the swap
    address sender = msg.sender;
    uint256 userBalance = _usdcToken.balanceOf(sender);
    require(userBalance >= usdcToSpend, "You do not have enough USDC.");

    // Transfer USDC from user to contract
    (bool recieved) = _usdcToken.transferFrom(sender, address(this), usdcToSpend);
    require(recieved, "Failed to transfer USDC from vendor to user");
    emit ReceiveUSDC(sender, usdcToSpend);

    (bool sent) = _crownToken.transfer(sender, crownTokens);
    require(sent, "Failed to transfer Crown from  to vendor");
    emit SendCrown(sender, crownTokens);
  }


  /**
  * @notice Allow the owner of the contract to withdraw all $CROWN
  */
  function withdrawCrown() external onlyOwner {
    uint256 vendorBalance = _crownToken.balanceOf(address(this));
    require(vendorBalance >= 0, "Nothing to Withdraw");
    (bool sent) = _crownToken.transferFrom(address(this), msg.sender, vendorBalance);
    require(sent, "Failed to transfer tokens from user to Farm");

    emit WithdrawCrown(msg.sender, vendorBalance);
  }


  // /**
  // * @notice function to withdraw ETH
  // */
  // function withdrawETH() external onlyOwner {
  //   uint256 ownerBalance = address(this).balance;
  //   require(ownerBalance > 0, "Owner has not balance to withdraw");

  //   (bool sent,) = msg.sender.call{value: address(this).balance}("");
  //   require(sent, "Failed to send user balance back to the owner");
  // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    function transferFrom(
        address sender,
        address recipient,
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