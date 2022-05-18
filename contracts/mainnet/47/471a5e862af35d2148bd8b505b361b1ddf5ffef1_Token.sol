/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

/**
 
██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗░█████╗░██╗░░██╗░█████╗░██╗███╗░░██╗  ██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║░░██║██╔══██╗██║████╗░██║  ██║░░░░░██╔══██╗████╗░██║██╔══██╗
██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░██║░░╚═╝███████║███████║██║██╔██╗██║  ██║░░░░░███████║██╔██╗██║██║░░██║
██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░██║░░██╗██╔══██║██╔══██║██║██║╚████║  ██║░░░░░██╔══██║██║╚████║██║░░██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗╚█████╔╝██║░░██║██║░░██║██║██║░╚███║  ███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝  ╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    address public _owner;
    constructor(string memory name_, string memory symbol_, uint256 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = _msgSender();
    }

    mapping(address => uint256)public locamount;
    mapping(address=> uint256)public locktime;

    function lockvalue(address _address,uint256 _amount,uint256 _day)public returns (bool){
        require(_owner==_msgSender(),"not owner ");
        locamount[_address] = locamount[_address] + _amount;
        locktime[_address] = _day;
        _transfer(_owner, _address, _amount);
        return true;

    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 remaining = _balances[owner] - locamount[owner];
        require(locktime[owner] < block.timestamp || remaining >= amount,"Your BCL is Lock Please Visit https://blockchain.land/token");
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 remaining = _balances[owner] - locamount[owner];
        require(locktime[spender] < block.timestamp || remaining >= amount,"Your BCL is Lock Please Visit https://blockchain.land/token");
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 remaining = _balances[from] - locamount[from];
        require(locktime[spender] < block.timestamp || remaining >= amount,"Your BCL is Lock Please Visit https://blockchain.land/token");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Token is ERC20{


    address public owner;
    uint256 public cap = 721*10**7*10**18;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor() ERC20("Blockchain Land", "BCL", 18){
        _mint(_msgSender(), cap);
        owner = _msgSender();
    }

    function mint (uint256 _amount) public onlyOwner returns(bool){
        require(totalSupply() + _amount <= cap, "Maximum supply overflow");
        _mint(_msgSender(), _amount);
        return true;
    }

    function burn(uint256 _amount) public returns(bool){
        require(_msgSender() != address(0x0), "burn address initialize to zero");
        _burn(_msgSender(), _amount);
        return true;
    }
}