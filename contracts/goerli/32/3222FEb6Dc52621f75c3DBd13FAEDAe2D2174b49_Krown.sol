/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

/***************************************************************************************************** 

 _   ________ _____  _    _ _   _       ____________ _____ _____ _____ _____ _____ _     
| | / /| ___ \  _  || |  | | \ | |      | ___ \ ___ \  _  |_   _|  _  /  __ \  _  | |    
| |/ / | |_/ / | | || |  | |  \| |      | |_/ / |_/ / | | | | | | | | | /  \/ | | | |    
|    \ |    /| | | || |/\| | . ` |      |  __/|    /| | | | | | | | | | |   | | | | |    
| |\  \| |\ \\ \_/ /\  /\  / |\  |      | |   | |\ \\ \_/ / | | \ \_/ / \__/\ \_/ / |____
\_| \_/\_| \_|\___/  \/  \/\_| \_/      \_|   \_| \_|\___/  \_/  \___/ \____/\___/\_____/
                                                                                         
https://t.me/krown_protocol                                                                                    
******************************************************************************************************/                                                                                                                                 
pragma solidity ^0.8.7;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
        return c;
    }

}

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.7;

contract Krown is IERC20 {
    using SafeMath for uint256;

    string public constant symbol = "KRN";
    string public constant name = "KROWN PROTOCOL";
    uint256 public constant decimals = 18;

    uint256 public immutable totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    address payable owner;

    constructor() public {
        // remember which address deployed the KROWN contract
        owner = payable(msg.sender);

        totalSupply = 50_000_000_000 * (10 ** decimals);

        // move all 5M tokens to deployer account so it
        // can be split between LBP, Uniswap, &c
        balances[owner] = totalSupply;

        emit Transfer(address(0), owner, totalSupply);
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    // use the same event signature as openzeppelin-contracts/contracts/access/Ownable.sol 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function transferOwnership(address payable newOwner) public {
        // change contract owner
        require(msg.sender == owner, "Must be owner");
        address prevOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(prevOwner, newOwner);
    }
    
    function rescueETH() public {
        // withdraw ETH which may be accidentally sent to this contract
        require(msg.sender == owner, "Must be owner");
        owner.transfer(address(this).balance);
    }

    function rescueTokens() public {
        // move tokens from this contract to the owner
        require(msg.sender == owner, "Must be owner");
        uint256 trappedTokens = balances[address(this)];
        if (trappedTokens > 0) {
             _transfer(address(this), owner, trappedTokens);    
        }
    }

}