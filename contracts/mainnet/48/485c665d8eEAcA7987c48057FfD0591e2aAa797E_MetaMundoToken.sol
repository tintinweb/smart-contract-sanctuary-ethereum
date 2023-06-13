/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


library SafeMath {
  	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256) {
	    uint256 c = a / b;
		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

abstract contract OwnerHelper {
  	address private _owner;

  	event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);

  	modifier onlyOwner {
		require(msg.sender == _owner, "OwnerHelper: caller is not owner");
		_;
  	}

  	constructor() {
            _owner = msg.sender;
  	}

       function owner() public view virtual returns (address) {
           return _owner;
       }

  	function transferOwnership(address newOwner) onlyOwner public {
            require(newOwner != _owner);
            require(newOwner != address(0x0));
            address preOwner = _owner;
    	    _owner = newOwner;
    	    emit OwnershipTransferred(preOwner, newOwner);
  	}
}

contract MetaMundoToken is IERC20, OwnerHelper {

    using SafeMath for uint256;

    uint256 public constant SECONDS_IN_A_MONTH = 2_628_288;

    address public constant WALLET_TOKEN_SALE = address(0x71677dDADB4be1F2C15ae722B5665475bF7Bed7f);
    address public constant WALLET_ECO_SYSTEM = address(0x5668b3fa2D82505c89213f7aa53CcaCcc8620e15);
    address public constant WALLET_RnD = address(0x4ef5a9FC33B33cDEf3A866aFA1F5aF092bD9B9B5);
    address public constant WALLET_MARKETING = address(0x9De31f65f4e32C1b157925b73ec161b8CAf3947C);
    address public constant WALLET_TEAM_N_ADVISOR = address(0x8ac0fDdca4488Ae52ecCF50a56b67A3fE8e5Ddae);
    address public constant WALLET_IDO = address(0xC4dC6aca12B41a2339DEb3d797834547D5A99Dac);
    address public constant WALLET_DEV = address(0x15A1BFc48e5C90e5820edE03BBBf491930643824);
    address public constant WALLET_STRATEGIC_PARTNERSHIP = address(0xB0AF6F69b1420b0A9a062B09f7e8fEeDd802FA27);

    uint256 public constant SUPPLY_TOKEN_SALE = 200_000_000e18;
    uint256 public constant SUPPLY_ECO_SYSTEM = 600_000_000e18;
    uint256 public constant SUPPLY_RnD = 400_000_000e18;
    uint256 public constant SUPPLY_MARKETING = 200_000_000e18;
    uint256 public constant SUPPLY_TEAM_N_ADVISOR = 200_000_000e18;
    uint256 public constant SUPPLY_IDO = 200_000_000e18;
    uint256 public constant SUPPLY_DEV = 100_000_000e18;
    uint256 public constant SUPPLY_STRATEGIC_PARTNERSHIP = 100_000_000e18;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    uint public _deployTime;
    
    constructor(string memory name_, string memory symbol_) 
    {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 2_000_000_000e18;
        _balances[msg.sender] = _totalSupply;
        _deployTime = block.timestamp;
    }
    
    function name() public view returns (string memory) 
    {
        return _name;
    }
    
    function symbol() public view returns (string memory) 
    {
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) 
    {
        return 18;
    }
    
    function totalSupply() external view virtual override returns (uint256) 
    {
        return _totalSupply;
    }

    function deployTime() external view returns (uint)
    {
        return _deployTime;
    }

    function balanceOf(address account) external view virtual override returns (uint256) 
    {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public virtual override returns (bool) 
    {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) 
    {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) external virtual override returns (bool) 
    {
        uint256 currentAllownace = _allowances[msg.sender][spender];
        require(currentAllownace >= amount, "ERC20: Transfer amount exceeds allowance");
        _approve(msg.sender, spender, currentAllownace, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(isCanTransfer(sender, amount) == true, "TokenLock: invalid token transfer");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
    }
    
    function isCanTransfer(address holder, uint256 amount) public view returns (bool)
    {
        if(holder == WALLET_TOKEN_SALE)
        {
            return true;
        }
        // EcoSystem
        else if(holder == WALLET_ECO_SYSTEM)
        {
            uint releaseTime = _deployTime;
            if(releaseTime <= block.timestamp)
            {
                // 물량의 15퍼센트만 해제된다.
                uint256 releasableBalance = (SUPPLY_ECO_SYSTEM / 100) * 15;
                
                // 지나간 달을 구한다.
                uint pastMonth = ((block.timestamp - releaseTime) / SECONDS_IN_A_MONTH) + 1;
                uint256 releasedBalance = pastMonth * (releasableBalance / 36);
                if(releasedBalance >= amount && _balances[holder] >= amount)
                {
                    return true;
                }

                return false;
            }
            // 여기 들어올일이 없지만 예외처리
            else 
            {
                return false;
            }
        }
        // R&D
        else if(holder == WALLET_RnD)
        {
            // 3개월 락업 이후
            uint releaseTime = _deployTime + SECONDS_IN_A_MONTH * 3;
            if(releaseTime <= block.timestamp)
            {
                // 3개월 락업 이후 계산 하는거니까 3빼줌
                uint pastMonth = ((block.timestamp - releaseTime) / SECONDS_IN_A_MONTH) - 3;
                uint256 releasedBalance = pastMonth * (SUPPLY_RnD / 36);
                if(releasedBalance >= amount && _balances[holder] >= amount)
                {
                    return true;
                }
                return false;
            }
            else 
            {
                return false;
            }            
        }
        // Marketing
        else if(holder == WALLET_MARKETING)
        {
            // 매월 해제
            uint releaseTime = _deployTime;
            if(releaseTime <= block.timestamp)
            {
                // 첫달 부터 해제 되니까
                uint pastMonth = ((block.timestamp - releaseTime) / SECONDS_IN_A_MONTH) + 1;
                uint256 releasedBalance = pastMonth * (SUPPLY_MARKETING / 36);
                if(releasedBalance >= amount && _balances[holder] >= amount)
                {
                    return true;
                }
                return false;
            }
            else
            {
                return false;
            }
        }
        // Team & Advisor
        else if(holder == WALLET_TEAM_N_ADVISOR)
        {
            // 5개월 동안 락
            uint releaseTime = _deployTime + (SECONDS_IN_A_MONTH * 5);
            if(releaseTime <= block.timestamp)
            {
                // 48개월 동안 해제 단 5개월 이후니까 5를 빼줘야 함
                //uint pastMonth = SafeMath.div(block.timestamp - releaseTime, SECONDS_IN_A_MONTH) - 5;
                uint pastMonth = ((block.timestamp - releaseTime) / SECONDS_IN_A_MONTH) - 5;
                    uint256 releasedBalance = pastMonth * (SUPPLY_TEAM_N_ADVISOR / 48);
                    if(releasedBalance >= amount && _balances[holder] >= amount)
                    {
                        return true;
                    }
                return false;
            }
            else 
            {
                return false;
            }
        }
        // IDO
        else if(holder == WALLET_IDO)
        {
            // 발행후 바로 해제
            uint releaseTime = _deployTime;
            if(releaseTime <= block.timestamp)
            {
                // 첫달 부터 해제니까 +1
                uint pastMonth = SafeMath.div(block.timestamp - releaseTime, SECONDS_IN_A_MONTH) + 1;
                    uint256 releasedBalance = pastMonth * (SUPPLY_IDO / 48);
                    if(releasedBalance >= amount && _balances[holder] >= amount)
                    {
                        return true;
                    }

                return false;
            }
            else 
            {
                return false;
            }
        }
        // Dev
        else if(holder == WALLET_DEV)
        {
            // 발행후 바로 해제
            uint releaseTime = _deployTime;
            if(releaseTime <= block.timestamp)
            {
                // 첫달 부터 해제니까 +1
                uint pastMonth = SafeMath.div(block.timestamp - releaseTime, SECONDS_IN_A_MONTH) + 1;
                    uint256 releasedBalance = pastMonth * (SUPPLY_DEV / 36);
                    if(releasedBalance >= amount && _balances[holder] >= amount)
                    {
                        return true;
                    }

                return false;
            }
            else 
            {
                return false;
            }
        }
        // Stategic Partnership
        else if(holder == WALLET_STRATEGIC_PARTNERSHIP)
        {
            // 5개월 후 해제
            uint releaseTime = _deployTime + (SECONDS_IN_A_MONTH * 5);
            if(releaseTime <= block.timestamp)
            {
                // 5개월 이후니까 -5
                uint pastMonth = SafeMath.div(block.timestamp - releaseTime, SECONDS_IN_A_MONTH) - 5;
                    uint256 releasedBalance = pastMonth * (SUPPLY_STRATEGIC_PARTNERSHIP / 36);
                    if(releasedBalance >= amount && _balances[holder] >= amount)
                    {
                        return true;
                    }
                return false;
            }
            else 
            {
                return false;
            }
        }
        
        return true;
    }
}