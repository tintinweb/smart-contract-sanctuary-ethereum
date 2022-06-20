// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

/**
 * @title SHEDSwap
 * @dev Swap SHED for Metis/BNB
 */
contract SHEDSwap is Ownable {
  // IERC20Decimals private shed =
  //   IERC20Decimals(0x8420Cb59B1718Da87c0DCD7bB2E64525B0AD61A1);
  // IERC20Decimals private metis =
  //   IERC20Decimals(0xe552Fb52a4F19e44ef5A967632DBc320B0820639);
  IERC20Decimals private shed =
    IERC20Decimals(0xedB762B35400974CB0C0d2EF5ca9417054cf6FA8);
  IERC20Decimals private metis =
    IERC20Decimals(0x46771F7dB9Fd583EC87580d2f7163Aec4c43d849);

  uint256 public shedPerBnb = 2100763666;
  uint256 public shedPerMetis = 1076973778;

  mapping(address => bool) public swapped;

  function swap() external {
    require(!swapped[msg.sender], 'already swapped');
    swapped[msg.sender] = true;

    uint256 _shedBalance = shed.balanceOf(msg.sender);
    require(_shedBalance > 0, 'you do not have any SHED to swap');
    shed.transferFrom(msg.sender, address(this), _shedBalance);

    // handle BNB reimbursement
    uint256 _bnbToReimburse = getBnbToReimburse(_shedBalance);
    require(
      address(this).balance >= _bnbToReimburse,
      'not enough BNB to reimburse'
    );
    (bool success, ) = payable(msg.sender).call{ value: _bnbToReimburse }('');
    require(success, 'did not successfully reimburse BNB');

    // handle Metis reimbursement
    uint256 _metisToReimburse = getMetisToReimburse(_shedBalance);
    require(
      metis.balanceOf(address(this)) >= _metisToReimburse,
      'not enough Metis to reimburse'
    );
    metis.transfer(msg.sender, _metisToReimburse);
  }

  function getBnbToReimburse(uint256 _shedBalance)
    public
    view
    returns (uint256)
  {
    return (_shedBalance * 10**18) / (shedPerBnb * 10**shed.decimals());
  }

  function getMetisToReimburse(uint256 _shedBalance)
    public
    view
    returns (uint256)
  {
    return
      (_shedBalance * 10**metis.decimals()) /
      (shedPerMetis * 10**shed.decimals());
  }

  function getShed() external view returns (address) {
    return address(shed);
  }

  function getMetis() external view returns (address) {
    return address(metis);
  }

  function setShedPerBnb(uint256 _ratio) external onlyOwner {
    shedPerBnb = _ratio;
  }

  function setShedPerMetis(uint256 _ratio) external onlyOwner {
    shedPerMetis = _ratio;
  }

  function setSwapped(address _wallet, bool _swapped) external onlyOwner {
    swapped[_wallet] = _swapped;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amountWei) external onlyOwner {
    _amountWei = _amountWei == 0 ? address(this).balance : _amountWei;
    payable(owner()).call{ value: _amountWei }('');
  }

  receive() external payable {}
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

/*
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