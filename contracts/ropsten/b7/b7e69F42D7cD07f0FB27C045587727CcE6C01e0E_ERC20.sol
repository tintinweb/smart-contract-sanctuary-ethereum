// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount ) external returns (bool);

    function mint(uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPausable {

    event Pause();

    event Unpause();

    event NotPausable();
}

interface IOwnable {

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract Ownable is IOwnable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) private onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() private onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract Pausable is IPausable, Ownable {

    bool private paused = false;
    bool private canPause = true;

    modifier whenNotPaused() {
        // require(!paused || msg.sender == owner);
        require(!paused); // For test
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        require(paused == true);
        paused = false;
        emit Unpause();
    }

    function notPausable() onlyOwner public{
        paused = false;
        canPause = false;
        emit NotPausable();
    }
}

contract ERC20 is IERC20, Pausable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    address private _admin;

    constructor() {
        _symbol = "TKJ";
        _name = "Token Kelvin Jess 1234";
        _decimals = 18;
        _totalSupply = 1000000000 * 1e18;
        _balances[msg.sender] = _totalSupply;
        _admin = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
  
    function name() public view override  returns (string memory) {
        return _name;
    }

    function symbol() public view override  returns (string memory) {
        return _symbol;
    }

    function decimals() public view override  returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function mint(uint256 amount) public whenNotPaused override returns (bool) {
        address account = msg.sender;
        // require(account == _admin , "should are not admin so you can't min token");
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public whenNotPaused override returns (bool) {
        address account = msg.sender;
        _burn(account, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public whenNotPaused override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount ) public whenNotPaused  returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) private whenNotPaused returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + amount);
        return true;
    }

    function decreaseAllowance(address spender, uint amount) private whenNotPaused returns (bool success) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "ERC20: allowance is less than 0");

         _approve(owner, spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount ) internal  {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[from] = fromBalance.sub(amount);
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance.sub(amount);
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount ) internal  {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _decreaseApproval(address spender, uint amount) internal returns (bool) {
        address owner = msg.sender;

        uint oldValue = _allowances[owner][spender];
        
        if (amount > oldValue) {
        _allowances[owner][spender] = 0;
        } else {
        _allowances[owner][spender] = oldValue.sub(amount);
        }
        
        emit Approval(owner, spender, _allowances[owner][spender]);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  {}

    function _afterTokenTransfer(address from, address to, uint256 amount ) internal  {}
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
	
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}