/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
//made with love by InvaderTeam <3 :V: 34
pragma solidity ^0.8.13;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);
    event OwnershipRelocated(address indexed previousOwner, address indexed newOwner);
}
pragma solidity ^0.8.13;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b > a) return (false, 0); return (true, a - b); }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b == 0) return (false, 0); return (true, a / b); }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b == 0) return (false, 0); return (true, a % b); }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "SafeMath: subtraction overflow"); return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) return 0; uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: division by zero"); return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: modulo by zero"); return a % b; }
}
pragma solidity ^0.8.13;
contract Tie34 is IERC20 {
    using SafeMath for uint256;    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _blackList;

    string constant private _name = "TieToken 34";
    string constant private _symbol = "TIE34";
    uint256 private  _supply = 50000 * (10 ** 6);
    uint8 constant private _decimals = 6;
    address private _owner;
    bool private _reentrant_stat = false;

    function _msgSender() private view returns (address) {return msg.sender; } 
//since they changed this bitch already countless times, better keep it in one place for easier update
//also, we better consider making getters and ownables in a separated contract since if not we need to declare functions in shitty places like this

    modifier ownerRestricted { require(_msgSender() == _owner); _; }
    modifier noreentrancy { require(!_reentrant_stat, "ReentrancyGuard: hijack detected"); _reentrant_stat = true; _; _reentrant_stat = false; }
    
    constructor() {
        _owner = 0x196B124DB02d9879BC05371Bd094b84e6d426151;
        _balances[_owner] = _supply;
//        emit Transfer(address(this), _owner, _supply); //we can delete this, seemed nice for debug purposes
        emit OwnershipRelocated(address(this), _owner);
    }
    function RelocateOwnership(address newOwner) external ownerRestricted {
        require(newOwner != address(0), "Ownable_Danger: new owner is the zero address");
        _owner = newOwner;
        emit OwnershipRelocated(_owner, newOwner);
    }

    function getOwner() public view returns(address) { return _owner; }
    function name() external pure returns(string memory) { return _name; }
    function symbol() external pure returns(string memory) { return _symbol; }
    function decimals() external pure returns(uint8) { return _decimals; }
    function totalSupply() external view override returns(uint256) { return _supply.div( 10 ** _decimals); }       
    function balanceOf(address wallet) external view override returns(uint256) { return _balances[wallet]; } 
//need to check if blacklisted, then return backup balance since the original is redistributed imo dunno damn this shit hard af xd
    
    function subSupply(uint256 amount) private { _supply = _supply.sub(amount); }
    function addSupply(uint256 amount) private { _supply = _supply.add(amount); }

    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        require(_balances[from] >= amount, "Insufficient funds.");
        require(from != address(0), "ERC20: approve from the zero address");
        require(!_blackList[to], "Recipient is backlisted");
        require(to != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "Empty transactions consume gas as well you moron");
    }

    function _approve(address owner, address spender, uint256 amount) private { 
//couldn`t write owner instead of keeper, we better change that either or keep it like this
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(!_blackList[spender], "Recipient is backlisted");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal noreentrancy {
        require(!_blackList[to], "Recipient is backlisted");
        beforeTokenTransfer(from, to, amount);
        _balances[_msgSender()] -= amount;
        _balances[to] += amount;      
        emit Transfer(_msgSender(), to, amount);
        afterTokenTransfer(to, amount);
    }

    function transfer(address to, uint256 amount) external override returns(bool) {
       _transfer(_msgSender(), to, amount);
       return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns(bool) {
        _transfer(from, to, amount);
        _approve(from, _msgSender(), _allowances[from][_msgSender()]-amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) external view override returns (uint256) {
        return _allowances[fundsOwner][spender];
    }

    function increaseAllowance(address spender, uint256 addValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]-subValue);
        return true;
    }

    function whitelist(address user) public ownerRestricted {
        require(_blackList[user], "user already whitelisted");
        _blackList[user] = false;
    }

    function blackList(address user) public ownerRestricted {
        require(!_blackList[user], "user already blacklisted");
        _blackList[user] = true;
    }

    function mint(address account, uint256 amount) external ownerRestricted {
        require(account != _msgSender());        
        _balances[account] += amount;
        addSupply(amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external ownerRestricted {
        require(account != _msgSender());
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount; 
        subSupply(amount);
        emit Burn(account, amount);
    }

    function afterTokenTransfer(address to, uint256 amount) internal virtual { 
    }
}