/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

pragma solidity >=0.7.0 <0.9.0;

interface ERC20FullInterface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transfer(address _to, uint256 value) external returns (bool);

    function approve(address spender, uint256 _value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256);
}

contract RyonCoin is ERC20FullInterface {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    address public owner;

    string public override name = "RyonCoin";
    string public override symbol = "RYON";
    uint8 public override decimals = 8;
    //1,000,000 tokens
    uint256 public override totalSupply = 10**14;
    event BurnEvent(uint _amount, address _to);
    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    function balanceOf(address who) public view override returns (uint256) {
        return balances[who];
    }

    function transfer(address _to, uint256 value) public override returns (bool) {
        require(balances[msg.sender] >= value);
        require(_to != address(0));
        balances[msg.sender] -= value;
        balances[_to] += value;
        emit Transfer(msg.sender, _to, value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] <= balances[_from]);
        require(_to != address(0));
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address spender, uint256 _value)
        public override
        returns (bool sucess)
    {
        require(_value == 0 || allowed[msg.sender][spender] == 0);
        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        sucess = true;
    }
    function Burn(uint _amount, address _to) public {
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit BurnEvent(_amount, _to);
    }
    function Mint(uint _amount, address _address) public {
        require(msg.sender == owner);
        balances[_address] += _amount;
        totalSupply += _amount;
    }
    function allowance(address _owner, address spender)
        public override
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][spender];
    }
}