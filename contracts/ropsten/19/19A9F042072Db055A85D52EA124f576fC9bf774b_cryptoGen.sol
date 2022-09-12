/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ERC20 {


    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
	function FreezeAcc(address account, bool target)  external returns(bool);
	function UnfreezeAcc(address account, bool target) external returns(bool);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}



contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner,"you are not owner");
        _;
    }

    modifier onlyManager() {
        require(msg.sender==tokenManagerContractAddress,"you are not manger");
        _;
    }
    address public tokenManagerContractAddress;
    address  public owner;
    // address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        owner = _newOwner;
    }
    
    function changeTokenManager(address payable _manager) public onlyOwner {
        
        tokenManagerContractAddress = _manager;
    }

}


contract cryptoGen is ERC20, Owned {
    using SafeMath for uint;

    string public constant name = 'Pancake LPs';
    string public constant symbol = 'Cake-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply=1000000000e18;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping (address  => bool) public frozen ;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor()  {
        owner=msg.sender;

        balanceOf[owner]=totalSupply;
    }

    
modifier whenNotFrozen(address target) {
    require(!frozen[target],"tokens are freeze already");
      _;
    }

  modifier whenFrozen(address target){
    require(frozen[target],"tokens are not freeze");
    _;
  }



    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        // require(!frozen[from])
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(int(-1))) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    
  function FreezeAcc(address target, bool freeze) whenNotFrozen( target) onlyManager public  returns (bool) {
    frozen[target]=freeze;
    // emit Freeze(target, true);
    return true;
  }

  function UnfreezeAcc(address target, bool freeze) whenFrozen(target) onlyManager public  returns (bool) {

    frozen[target]=freeze;
    // emit Unfreeze(target, false);
    return true;
  }

}