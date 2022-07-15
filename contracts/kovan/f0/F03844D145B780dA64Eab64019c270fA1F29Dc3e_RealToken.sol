pragma solidity ^0.5.0;

import '../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 *
 * Real Token Smart Contract Features.
 *
 * - Contract owner can transfer ownership to a different ethereun address.
 * - Contract owner can mint and burn tokens to and from an address.
 * - Contract owner can set addresses in the whitelist and remove from the whitelist.
 * - 3rd Party access to set allowances for transfer by token owner only if whitelisted and timelock cleared.
 * - Whitelisted investors who can transact with other investors who are whitelisted.
 * - Token Vesting. Investor purchase date must meet one year timestamp for token owner to allow transfer token(s).
 * - If an investor is cleared from (whitelist, timelock), investor can send tokens to whitelisted investor who is not vested.
 *
 * @author [email protected]
 */
contract RealToken is IERC20 {

  using SafeMath for uint256;

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint8 public constant DECIMALS = 18;
  uint256 private _totalSupply;
  address private _owner;

  /**
   * @dev Investor Struct
   * - investor must be whitelisted to allow transfers
   * - investor timestamp must exceed one year from transfer date
   */
  struct Investor {
    // eth wallet address
    address wallet; 
    // whitelisted property
    bool whitelisted; 
    // flag indicating vesting period completed
    bool vested;  
    // timestamp for token release
    uint256 releaseTime;
    // unreleased tokens 
    uint256 unreleasedTokens;
    // vested tokens
    uint256 vestedTokens; 
  }
  /**
   * @dev Investors mapping contains all token holders info object.
   */
  mapping (address => Investor) private _investors;

  /**
   * @dev Balances for the token holders stored by wallet address.
   */
  mapping (address => uint256) private _balances;

  /**
   * @dev Allowances for 3rd Party transfers.
   */
  mapping (address => mapping (address => uint256)) private _allowances;

  /**
   * @dev Whitelist
   */
  mapping (address => bool) private _whitelist;

  /**
   * @dev Emitted when an investor is created.
   */
  event InvestorCreated(address investor, uint256 unreleasedTokens);

  /**
   * @dev Emitted when investor data is requested.
   */
  event InvestorRequested(address wallet, bool whitelisted, bool vested, uint256 releaseTime, uint256 unreleasedTokens, uint256 vestedTokens);

  /**
   * @dev Emitted when the investor has vested.
   */
  event InvestorVested(address investor, bool vested, uint256 vestedTokens);

  /**
   * @dev Emitted when the investor vestment releaseTime has been updated.
   */
  event InvestorVestmentUpdated(address investor, uint256 releaseTime);

  /**
   * @dev Emitted when the investor has had tokens revoked.
   */
  event InvestorRevoked(address investor, uint256 refundedTokens);

  /**
   * @dev Emitted when the investor has had a failed token release.
   */
  event InvestorFailedRelease(address investor, uint256 amount);

  /**
   * @dev Emitted when the investor has had tokens revoked.
   */
  event InvestorInsufficientBalance(address investor, uint256 balance, uint256 refund);

  /**
   * @dev Emitted when the investor is added to the whitelist.
   */
  event WhitelistStatus(address investor, bool whitelisted);

  /**
   * @dev Emitted when the investor is added to the whitelist.
   */
  event WhitelistAdded(address investor, bool whitelisted);

  /**
   * @dev Emitted when the investor is removed from the whitelist.
   */
  event WhitelistRemoved(address investor, bool whitelisted);

  /**
   * @dev Ownership transfer.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
   * these values are immutable: they can only be set once during
   * construction.
   */
  constructor (string memory name, string memory symbol, uint256 initialSupply) public {
    // set the smart contract properties
    _name = name;
    _symbol = symbol;
    _decimals = DECIMALS;
    // set the smart contract owner
    _owner = msg.sender;
    // mint the asset backed tokens
    uint256 calculatedSupply = initialSupply * (10 ** uint256(DECIMALS));
    _mint(_owner, calculatedSupply);
    // transfer ownership to contract owner
    emit OwnershipTransferred(address(0), _owner);
  }


  /**
   * @dev `RealToken`.
   */

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei.
   *
   * > Note that this information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * `IERC20.balanceOf` and `IERC20.transfer`.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See `IERC20.totalSupply`.
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See `IERC20.balanceOf`.
   */
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See `IERC20.transfer`.
   *
   * Requirements:
   *
   * - `recipient` must be whitelisted to allow transfer.
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public returns (bool) {
    if(isWhitelisted(recipient) != true) {
      return false;
    }
    if(isVested(recipient) != true) {
      return false;
    }
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See `IERC20.allowance`.
   */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See `IERC20.approve`.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev See `IERC20.transferFrom`.
   *
   * Emits an `Approval` event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of `ERC20`;
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `value`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    // sender check
    if(isWhitelisted(sender) != true) {
      return false;
    }
    if(isVested(sender) != true) {
      return false;
    }
    // recipient check
    if(isWhitelisted(recipient) != true) {
      return false;
    }
    if(isVested(recipient) != true) {
      return false;
    }
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to `approve` that can be used as a mitigation for
   * problems described in `IERC20.approve`.
   *
   * Emits an `Approval` event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to `approve` that can be used as a mitigation for
   * problems described in `IERC20.approve`.
   *
   * Emits an `Approval` event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to `transfer`, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a `Transfer` event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    bool senderWhitelisted = isWhitelisted(recipient);
    bool senderVested = isVested(recipient);

    // sender check
    require(senderWhitelisted == true, "RealToken: sender not whitelisted");
    require(senderVested == true, "RealToken: sender not vested");

    // recipient check
    bool recipientWhitelisted = isWhitelisted(recipient);
    bool recipientVested = isVested(recipient);

    require(recipientWhitelisted == true, "RealToken: recipient not whitelisted");
    require(recipientVested == true, "RealToken: recipient not vested");

    // apply transfer
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** 
   * @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
   *
   * Emits a `Transfer` event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
  function mint(address account, uint256 amount) public onlyOwner returns (bool) {
    require(account != address(0), "ERC20: mint from the zero address");

    _mint(account, amount);
    return true;
  }

  /**
   * @dev Destoys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a `Transfer` event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
  /**
   * @dev Public `burn` method. 
   */
  function burn(address account, uint256 value) public onlyOwner returns (bool) {
    require(account != address(0), "ERC20: burn from the zero address");
    _burn(account, value);
    return true;
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an `Approval` event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }


  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See `_burn` and `_approve`.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
  }
  /**
   * @dev Public `burnFrom` method. 
   */
  function burnFrom(address account, uint256 value) public onlyOwner returns (bool) {
    require(account != address(0), "ERC20: burnFrom from the zero address");
    _burnFrom(account, value);
    return true;
  }

  /**
   * Ownership
   */

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
   * Whitelist
   */

  function isWhitelisted(address investor) public returns (bool) {
    require(investor != address(0), "RealToken: isWhitelisted from the zero address");

    // return whitelist status
    Investor memory inv = _investors[investor];
    bool status = inv.whitelisted;
    emit WhitelistStatus(investor, status);
    return status;
  }

  function addWhitelist(address investor) public onlyOwner returns (bool) {
    require(investor != address(0), "RealToken: addWhitelist from the zero address");

    Investor memory inv = _investors[investor];

    // set investor as whitelisted
    inv.whitelisted = true;

    // update investor
    _investors[investor] = inv;

    emit WhitelistAdded(investor, inv.whitelisted);
    return true;
  }

  function removeWhitelist(address investor) public onlyOwner returns (bool) {
    require(investor != address(0), "RealToken: removeWhitelist from the zero address");

    Investor memory inv = _investors[investor];

    // set investor to false in whitelist to remove
    inv.whitelisted = false;

    // update investor
    _investors[investor] = inv;

    emit WhitelistRemoved(investor, inv.whitelisted);
    return true;
  }

  /**
   * Investor
   */

  function createInvestor(address investor, bool _isWhitelisted, bool _vested, uint256 tokens) public onlyOwner returns (bool) {
    require(investor != address(0), "RealToken: createInvestor from the zero address");

    // calculate period based on vested flag
    uint256 vestingPeriod = block.timestamp; 
    uint256 unreleasedTokens = 0;
    uint256 vestedTokens = 0;
    if(_vested == false) {
      vestingPeriod = calculateVestingPeriod(); // calculate one year if not vested
      unreleasedTokens = tokens;
      vestedTokens = 0;
    } else {
      // incoming vested account all tokens released
      unreleasedTokens = 0;
      vestedTokens = tokens;
    }

    // create investor
    Investor memory inv = Investor({wallet:investor, whitelisted: _isWhitelisted, vested: _vested, releaseTime: vestingPeriod, unreleasedTokens: unreleasedTokens, vestedTokens: vestedTokens});
    // add to investors
    _investors[investor] = inv;
    // emit investor created 
    emit InvestorCreated(investor, tokens);
    // emit whitelist added
    emit WhitelistAdded(investor, _isWhitelisted);
    
    return true;
  }

  function getInvestor(address investor) public onlyOwner returns (bool) { 
    require(investor != address(0), "RealToken: getInvestor from the zero address");

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));

    // emit requested investor data
    emit InvestorRequested(inv.wallet, inv.whitelisted, inv.vested, inv.releaseTime, inv.unreleasedTokens, inv.vestedTokens);
    return true;
  }

  function vestedTokenBalanceOf(address investor) public view returns(uint256) {
    require(investor != address(0), "RealToken: vestedTokenBalanceOf from the zero address");

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));
    
    return inv.vestedTokens;
  }
  
  function unreleasedTokenBalanceOf(address investor) public view returns(uint256) {
    require(investor != address(0), "RealToken: unreleasedTokenBalanceOf from the zero address");

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));

    return inv.unreleasedTokens;
  }
  

  /**
   * Bulk Investor Whitelist / Whitelist-Transfer
   * Bulk ERC20 token transfer to multiple addresses
   * Bulk Address Whitelisting
   */
  function whitelistTransfer(address investor, uint256 vestedTokens, uint256 tokens) public onlyOwner {
    require(createInvestor(investor, true, true, vestedTokens));
    require(transfer(investor, tokens));
  }

  /**
   * @dev Bulk whitelist a collection of investors
   */
  function bulkWhitelist(address[] memory investors, uint256[] memory tokens) public onlyOwner {
    for (uint256 i = 0; i < investors.length; i++)
      require(createInvestor(investors[i], true, true, tokens[i]));
  }

  /**
   * @dev Bulk whitelist transfer to a collection of recipients
   */
  function bulkWhitelistTransfer(address[] memory investors, uint256[] memory vestedTokens, uint256[] memory tokens) public onlyOwner {
    for (uint256 i = 0; i < investors.length; i++) {
      require(createInvestor(investors[i], true, true, vestedTokens[i]));// vested tokens
      require(transfer(investors[i], tokens[i]));  // paid tokens
    }
  }

  /**
   * Investor Vestments
   */

  /**
   * @dev Timelock
   * 
   * Time Units
   * Suffixes like seconds, minutes, hours, days and weeks after literal numbers can be used to specify units of time where seconds are the base unit and units are considered naively in the following way:
   * 1 == 1 seconds
   * 1 minutes == 60 seconds
   * 1 hours == 60 minutes
   * 1 days == 24 hours
   * 1 weeks == 7 days
   *
   * Take care if you perform calendar calculations using these units, 
   * because not every year equals 365 days and not even every day has 24 hours because of leap seconds. 
   * Due to the fact that leap seconds cannot be predicted, an exact calendar library has to be updated by an external oracle.
   */
  function calculateVestingPeriod() public view onlyOwner returns (uint256) {
    return (now + 365 days); // does not account for leap year or leap seconds, we may need to have oracle set time
  }

  /**
   * @dev Returns the timelock vested flag an investor address.
   */
  function isVested(address investor) public view returns (bool) {
    require(investor != address(0), "RealToken: isVested from the zero address");

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));

    return inv.vested;
  }

  /**
   * @dev onlyOwner
   * @notice Set the investor timelock vested flag to true and timelock to now.
   */
  function setVested(address investor) public onlyOwner returns (bool) {
    require(investor != address(0), "RealToken: setVested from the zero address");

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));

    // solhint-disable-next-line not-rely-on-time
    inv.releaseTime = now;  // now
    inv.vested = true;

    _investors[investor] = inv;

    emit InvestorVestmentUpdated(inv.wallet, inv.releaseTime);
    
    return inv.vested;
  }

  /**
   * @dev onlyOwner
   * @notice Transfers tokens held by timelock from unreleasedTokens to vestedTokens.
   * @param investor Address to release tokens from vestment.
   */
  function release(address investor, uint256 amount) public onlyOwner returns (bool) {
    require(investor != address(0), "RealToken: release from the zero address");
    assert(amount > 0);

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));

    uint256 _releaseTime = inv.releaseTime;

    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp >= _releaseTime, "RealToken: current time is before release time");

    // update vestment check
    if(isVested(investor) && isWhitelisted(investor)) {

      if(inv.unreleasedTokens >= amount) {
        inv.unreleasedTokens = inv.unreleasedTokens.sub(amount);
      }
      inv.vestedTokens = inv.vestedTokens.add(amount);
        
      // update 
      _investors[investor] = inv;

      emit InvestorVested(investor, inv.vested, inv.vestedTokens);
      return true;

    } else {
      // failed to release dispatch InvestorFailedRelease
      emit InvestorFailedRelease(investor, amount);
      return false;
    }

  }


  /**
   * @dev onlyOwner
   * @notice Allows the owner to revoke tokens from an investor account.
   * @param investor Ethereum address.
   * @param refund Amount of tokens to revoke from investor.
   */
  function revoke(address investor, uint256 refund) public onlyOwner returns (bool) {
    require(investor != address(0), "RealToken: revoke from the zero address");
    require(refund > 0, "RealToken: revoke with a zero refund");

    Investor memory inv = _investors[investor];

    require(inv.wallet != address(0));
    
    uint256 balance = balanceOf(investor);

    // check funds available for refund 
    assert(balance >= refund);
    
    // For revoke check unreleasedTokens, vestedTokens, current balance
    // (a) when we call revoke and not vested, take from unreleased tokens
    // (b) when we call revoke and is vested, take from vested tokens    
    // get refund and subtract from vested or unreleased tokens

    // check refunded availability 
    if(inv.vested == true) {

      // do we have enough vested tokens to provide a refund?
      // update internally 
      if(inv.vestedTokens >= refund) {
        // update vested token balances
        inv.vestedTokens = inv.vestedTokens.sub(refund);
      } else {
        // insufficient balance 
        emit InvestorInsufficientBalance(investor, balance, refund);
        return false;
      }

    } else {
            // do we have enough unreleased tokens to provide a refund?
      if(inv.unreleasedTokens >= refund) {
        // update unreleased token balances
        inv.unreleasedTokens = inv.unreleasedTokens.sub(refund);
      } else {
        // insufficient balance 
        emit InvestorInsufficientBalance(investor, balance, refund);
        return false;
      }

    }

    _investors[investor] = inv;

    // did we have enough tokens available to provide a refund
    // burn tokens from investor 
    _burn(investor, refund);
    // mint new token for the _owner
    _mint(_owner, refund); 
    // emit investor revoked
    emit InvestorRevoked(investor, refund);
    return true;

  }


}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}