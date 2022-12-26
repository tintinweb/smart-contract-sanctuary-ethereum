/**
 *Submitted for verification at Etherscan.io on 2022-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
}
/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract BOOCOIN is ERC20, Ownable, ERC20Burnable {
    
    constructor() ERC20("BOOCOIN", "BOC") {}

    uint public maxTotalSupply = 300000000 ether;
    uint public thirtyDaysConstant = 2592000;

    uint public launchTime;
    bool public launchinitialized = false;

    function intitialize_launch() public onlyOwner {
        require(!launchinitialized, "Launch time already initialized.");
        launchinitialized = true;
        launchTime = block.timestamp;
    }

    function currenttime() public view returns(uint) {
        return block.timestamp;
    }

///////////////////////////// COMMUNITY /////////////////////////////////

    uint public community_initialSupply = 4166667 ether;
    uint public community_circulatingSupply = 0 ether;

    function mint_community(address to, uint256 amount) public onlyOwner {
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");
        require(community_circulatingSupply + amount <= community_availableSupply(), "Reached Community Available SUPPLY!!");
        community_circulatingSupply += amount;
        _mint(to, amount);
    }

    function community_availableSupply() public view returns(uint){

        uint total = community_initialSupply;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 3))
            total += 8333333 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 6))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 9))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 12))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 15))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 18))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 21))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 24))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 27))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 30))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 33))
            total += 12500000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 36))
            total += 12500000 ether;

        return total;
    }

    address public stakingAddress;

    function setStakingAddress(address a) public onlyOwner {
        stakingAddress = a;
    }

    function stakeReward(address to, uint256 amount) public {
        require(msg.sender == stakingAddress, "Invalid Request!!");
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");
        require(community_circulatingSupply + amount <= community_availableSupply(), "Reached Community Available SUPPLY!!");
        community_circulatingSupply += amount;
        _mint(to, amount);
    }

///////////////////////////// ADVISORS /////////////////////////////////

    address public ADVISORS1 = 0x475e107401B0458090bC60f513981CF5f61D1aeE;
    address public ADVISORS2 = 0x45a960ad31E0b9e429017fb0cF90A6417aaA9A74;
    address public ADVISORS3 = 0xA37d0260c6ad89CbDf35a64D96923D1004119d15;

    uint public advisors_initialSupply = 0 ether;

    uint public advisors_minted_1 = 0 ether;
    uint public advisors_minted_2 = 0 ether;
    uint public advisors_minted_3 = 0 ether;

    function mint_advisors(address to, uint256 amount) public {
        require(msg.sender == ADVISORS1 || msg.sender == ADVISORS2 || msg.sender == ADVISORS3, "User not Advisor!!");
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");

        if(msg.sender == ADVISORS1) {
            require(advisors_minted_1 + amount <= advisors_availableSupply()/3, "Reached ADVISORS Available SUPPLY!!");
            advisors_minted_1 += amount;

        } else if(msg.sender == ADVISORS2) {
            require(advisors_minted_2 + amount <= advisors_availableSupply()/3, "Reached ADVISORS Available SUPPLY!!");
            advisors_minted_2 += amount;

        } else if(msg.sender == ADVISORS3) {
            require(advisors_minted_3 + amount <= advisors_availableSupply()/3, "Reached ADVISORS Available SUPPLY!!");
            advisors_minted_3 += amount;
        }
        
        _mint(to, amount);
    }

    function advisors_availableSupply() public view returns(uint){

        uint total = advisors_initialSupply;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 9))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 12))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 15))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 18))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 21))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 24))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 27))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 30))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 33))
            total += 1050000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 36))
            total += 1050000 ether;

        return total;
    }

    function set_ADVISORS_Address_1(address a) public onlyOwner {
        ADVISORS1 = a;
    }

    function set_ADVISORS_Address_2(address a) public onlyOwner {
        ADVISORS2 = a;
    }

    function set_ADVISORS_Address_3(address a) public onlyOwner {
        ADVISORS3 = a;
    }

///////////////////////////// TEAM /////////////////////////////////

    address public TEAM = 0x997F503b63EEE4661db04580ecA29670f537c977;
    uint public team_initialSupply = 0 ether;
    uint public team_circulatingSupply = 0 ether;

    function mint_team(address to, uint256 amount) public {
        require(msg.sender == TEAM, "User not TEAM!!");
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");
        require(team_circulatingSupply + amount <= team_availableSupply(), "Reached TEAM Available SUPPLY!!");
        team_circulatingSupply += amount;
        _mint(to, amount);
    }

    function team_availableSupply() public view returns(uint){

        uint total = team_initialSupply;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 36))
            total += 9000000 ether;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 48))
            total += 9000000 ether;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 60))
            total += 9000000 ether;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 72))
            total += 9000000 ether;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 84))
            total += 9000000 ether;

        return total;
    }

    function set_TEAM_Address(address a) public onlyOwner {
        TEAM = a;
    }

///////////////////////////// WEB3 /////////////////////////////////
    
    address public WEB3 = 0x0Df57B50e0bcEb93Fb6a6da753D3E83cFBc54a7A;
    uint public web3_app_dev_initialSupply = 0 ether;
    uint public web3_app_dev_circulatingSupply = 0 ether;

    function mint_web3(address to, uint256 amount) public {
        require(msg.sender == WEB3, "User not WEB3 DEV!!");
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");
        require(web3_app_dev_circulatingSupply + amount <= web3_availableSupply(), "Reached WEB3 DEV Available SUPPLY!!");
        web3_app_dev_circulatingSupply += amount;
        _mint(to, amount);
    }

    function web3_availableSupply() public view returns(uint){

        uint total = web3_app_dev_initialSupply;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 9))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 12))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 15))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 18))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 21))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 24))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 27))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 30))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 33))
            total += 3750000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 36))
            total += 3750000 ether;

        return total;
    }

    function set_WEB3_Address(address a) public onlyOwner {
        WEB3 = a;
    }
    
///////////////////////////// ECOSYSTEM /////////////////////////////////

    address public ECOSYSTEM = 0x6Bbef72ca754684316AbfC7656ea98d2e430D85A;
    uint public eco_system_growth_fund_initialSupply = 333333 ether;
    uint public eco_system_growth_fund_circulatingSupply = 0 ether;

    function mint_eco_system_growth_fund(address to, uint256 amount) public onlyOwner {
        require(msg.sender == ECOSYSTEM, "User not ECOSYSTEM!!");
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");
        require(eco_system_growth_fund_circulatingSupply + amount <= eco_system_growth_fund_availableSupply(), "Reached ECOSYSTEM Available SUPPLY!!");
        eco_system_growth_fund_circulatingSupply += amount;
        _mint(to, amount);
    }

    function eco_system_growth_fund_availableSupply() public view returns(uint){

        uint total = eco_system_growth_fund_initialSupply;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 3))
            total += 666667 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 6))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 9))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 12))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 15))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 18))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 21))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 24))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 27))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 30))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 33))
            total += 1000000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 36))
            total += 1000000 ether;

        return total;
    }

    function set_ECOSYSTEM_Address(address a) public onlyOwner {
        ECOSYSTEM = a;
    }
    
///////////////////////////// PRIVATE_PUBLIC_SALE /////////////////////////////////

    address public PRIVATE_PUBLIC_SALE = 0xdd1F6b6c9b0f3d575f2De14a3cE89c0D5a8c9De6;
    uint public initial_private_public_sale_initialSupply = 0 ether;
    uint public initial_private_public_sale_circulatingSupply = 0 ether;

    function mint_initial_private_public_sale(address to, uint256 amount) public onlyOwner {
        require(msg.sender == PRIVATE_PUBLIC_SALE, "User not PRIVATE_PUBLIC_SALE!!");
        require(launchinitialized, "Launch time not initialized!!");
        require(totalSupply()+amount <= maxTotalSupply, "Reached Max SUPPLY!!");
        require(initial_private_public_sale_circulatingSupply + amount <= initial_private_public_sale_availableSupply(), "Reached PRIVATE_PUBLIC_SALE Available SUPPLY!!");
        initial_private_public_sale_circulatingSupply += amount;
        _mint(to, amount);
    }

    function initial_private_public_sale_availableSupply() public view returns(uint){

        uint total = initial_private_public_sale_initialSupply;

        if(block.timestamp >= launchTime + (thirtyDaysConstant * 3))
            total += 11250000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 6))
            total += 11250000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 9))
            total += 11250000 ether;
        if(block.timestamp >= launchTime + (thirtyDaysConstant * 12))
            total += 11250000 ether;

        return total;
    }

    function set_PRIVATE_PUBLIC_SALE_Address(address a) public onlyOwner {
        PRIVATE_PUBLIC_SALE = a;
    }

///
}