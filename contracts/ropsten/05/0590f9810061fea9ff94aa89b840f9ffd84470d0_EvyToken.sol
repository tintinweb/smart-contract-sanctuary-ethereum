/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

pragma solidity >=0.4.22 <0.7.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract EvyToken is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    address public master;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(string => address) ownership;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "EvyCoin";
        name = "Evy Token";
        master = 0x9375888232e4E00ef5a4266407dFA70BAbE07550;
        decimals = 3;
        _totalSupply = 200000000 * 10**uint(decimals);
        balances[master] = _totalSupply;
        ownership["fish"] = master;
        ownership["apple"] = master;
        ownership["gold"] = master;
        ownership["computer"] = master;
        ownership["flower"] = master;
        emit Transfer(address(0), master, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function changeOwner(string memory productName, address winner) public {
        ownership[productName] = winner;
    }

    function getOwnership(string memory productName) public view returns (address owner) {
        return ownership[productName];
    }
}