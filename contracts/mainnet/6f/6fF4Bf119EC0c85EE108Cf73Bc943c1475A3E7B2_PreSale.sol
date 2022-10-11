// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreSale is Ownable {
  event SwapEvent(address addr, uint256 amount);

  address public DSTAddress; // DST ERC20 token address
  address public foundationWallet; // Foundation wallet address

  uint256 public preSale1Height; // First presale block number
  uint256 public preSale2Height; // Second presale block number
  uint256 public publicSaleHeight; // Public sale block number
  uint256 public price; // Sale price

  // Presale Account
  struct PreSaleAccount {
    uint256 totalClaimBalance; // Total able claim balance
    uint256 claimedBalance; // Claimed balance
    bool isExist;
  }

  mapping(address => PreSaleAccount) public preSaleAccounts;

  // [Owner] Enter presale information
  function setPreSaleInfo(uint256 _price, uint256 _preSale1Height, uint256 _preSale2Height, uint256 _publicSaleHeight) public onlyOwner {
    require(_price > 0, "price must be greater than zero");
    require(_preSale2Height > _preSale1Height, "Presale 2 cannot be faster than Presale 1");
    require(_publicSaleHeight > _preSale2Height, "Public sale cannot be faster than Presale 1");

    price = _price;
    preSale1Height = _preSale1Height;
    preSale2Height = _preSale2Height;
    publicSaleHeight = _publicSaleHeight;
  }

  // [Owner] Enter foundation wallet address
  function setFoundationWalletAddress(address _addr) public onlyOwner {
    foundationWallet = _addr;
  }

  // [Owner] Enter DST(ERC-20) contract address
  function setDSTAddress(address _addr) public onlyOwner {
    IERC20(_addr).balanceOf(_addr);
    DSTAddress = _addr;
  }

  // [Owner] Add presale accounts
  // Params: addressList:["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"], balanceList:[123]
  function addPreSaleAccounts(address[] memory _addressList, uint256[] memory _balanceList) public onlyOwner {
    require(_addressList.length == _balanceList.length, "need same length");
    for (uint i = 0; i < _addressList.length; i++) {
      if(!preSaleAccounts[_addressList[i]].isExist) {
        preSaleAccounts[_addressList[i]] = PreSaleAccount({
          totalClaimBalance: _balanceList[i],
          claimedBalance : 0,
          isExist: true
        });
      }
    }
  }

  // [Owner] Set presale account
  function setPreSaleAccount(address _address, uint256 _balance, bool _isExist) public onlyOwner {
    PreSaleAccount storage account = preSaleAccounts[_address];
    require(account.isExist, "not registered");
    account.totalClaimBalance = _balance;
    account.isExist = _isExist;
  }

  // [Onwer] Check the ETH balance
  function getEthBalance() public view returns(uint256){
    return address(this).balance;
  }

  // [Owner] Check the DST balance
  function getDSTBalance() public view returns(uint256){
    return IERC20(DSTAddress).balanceOf(address(this));
  }

  // [Owner] Withdraw ETH
  function withdrawETH() public onlyOwner {
    require(foundationWallet != address(0), "no foundation address");
    payable(foundationWallet).transfer(address(this).balance);
  }

  // [Owner] Withdraw DST
  function withdrawDST() public onlyOwner {
    require(foundationWallet != address(0), "no foundation address");
    IERC20(DSTAddress).transfer(foundationWallet, IERC20(DSTAddress).balanceOf(address(this)));
  }

  // [User] Swap ETH to DST
  function swap() public payable {
    require(price > 0, "price must be greater than zero");
    require(msg.value > 0, "value must be greater than zero");
    require(msg.value % price == 0, "price error");

    uint blockNumber = block.number;
    uint256 amount = msg.value / price;
    require(IERC20(DSTAddress).balanceOf(address(this)) >= amount, "Insufficient quantity");
    uint256 transferAmount = amount * 10 ** 18;

    if(blockNumber >= preSale1Height && blockNumber < preSale2Height) { // Presale 1
      PreSaleAccount storage account = preSaleAccounts[msg.sender];
      require(account.isExist, "Not whitelisted");
      require(account.totalClaimBalance - account.claimedBalance >= amount, "Over claimabled");

      account.claimedBalance += amount;
      IERC20(DSTAddress).transfer(msg.sender, transferAmount);
      emit SwapEvent(msg.sender, amount);
    } else if(blockNumber >= preSale2Height && blockNumber < publicSaleHeight) { // Presale 2
      PreSaleAccount storage account = preSaleAccounts[msg.sender];
      require(account.isExist, "Not whitelisted");

      account.claimedBalance += amount;
      IERC20(DSTAddress).transfer(msg.sender, transferAmount);
      emit SwapEvent(msg.sender, amount);
    } else if(blockNumber >= publicSaleHeight) { // Public Sale
      IERC20(DSTAddress).transfer(msg.sender, transferAmount);
      emit SwapEvent(msg.sender, amount);
    } else {
      revert("can't swap");
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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