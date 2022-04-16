pragma solidity ^0.7.0;

import "./Token.sol";

interface proxy {
    function transferFrom(address owner, address buyer, uint256 numTokens) external returns (bool);
    function allowance(address owner, address delegate) external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
}

contract SmartContract {
    proxy token;
    mapping(address => uint256) public balances;

    function setTokenAddress(address _address) public {
        token = proxy(_address);
    }

    function simp(uint256 tribute) public {
        address user = msg.sender;
        token.transferFrom(user, address(this), tribute);
        balances[msg.sender] += tribute;
    }

    function proxyAllowance(address owner, address delegate) public returns (uint256) {
        return token.allowance(owner, delegate);
    }

    function proxyBalance(address tokenOwner) public view returns (uint256)  {
        return token.balanceOf(tokenOwner);
    }
}

pragma solidity ^0.7.0;

contract Tokens {
    string public constant name = "ERC20Basic";
    string public constant symbol = "TOKENS";
    uint8 public constant decimals = 18;

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][buyer]);

        balances[owner] = balances[owner].sub(numTokens);
        // allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}