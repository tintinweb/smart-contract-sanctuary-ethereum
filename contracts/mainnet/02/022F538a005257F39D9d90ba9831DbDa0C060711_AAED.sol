/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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




pragma solidity 0.8.8;

abstract contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "NO APPROVAL");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "error : zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

}

abstract contract ERC20Basic is Ownable {
    
    function balanceOf(address who) public virtual view returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual  view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract StandardToken is ERC20 {

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;
    
    function balanceOf(address _account) public override view returns (uint256 balance) {
        return balances[_account];
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract AAED  is StandardToken {
    using SafeMath for uint256;
    string constant public name = "Atherio Dirham";
    string constant public symbol = "AAED";
    uint8 constant public decimals = 2;
    uint256 public totalSupply = 100 * 10**2;
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    

    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the account");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - (amount*10**2);
        }
        totalSupply -= amount*10**2;
        emit Transfer(account, address(0), amount);
    }
    function _mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero account");

        totalSupply = totalSupply.add(amount * 10 ** 2);
        balances[account] = balances[account].add(amount);
        emit Transfer(account, address(0), amount);
    }   
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Transfer to 0 address!");
        require(_value <= balances[_from], "Insufficient amount!");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance!");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Transfer to 0 address!");
        require(_value <= balances[msg.sender], "Insufficient amount!");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}