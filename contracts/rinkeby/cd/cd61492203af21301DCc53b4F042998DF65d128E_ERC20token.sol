// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;

contract ERC20token {

    string public name;
    string public symbol;
    address public admin;
    uint256 public totalSupply;
    uint8 public decimals; // 10^18 wei

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _from, address indexed _to, uint256 _value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        admin = msg.sender;
    }

    modifier OnlyAdmin() {
        require(msg.sender == admin, "caller is not the admin");
        _;
    }

    function mint(address _to, uint256 _value) external OnlyAdmin {
        require(
            totalSupply + _value >= totalSupply &&
                balances[_to] + _value >= balances[_to]
        );
        balances[msg.sender] +=_value;
        totalSupply += _value;
    }

    function burn(uint256 _value) external OnlyAdmin {
        require(totalSupply >= _value, "Wrong value");
        totalSupply -= _value;
        balances[msg.sender] -= _value;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value, 'Not enough tokens');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public {
        require(
            balances[_from] >= _value && allowed[_from][msg.sender] >= _value,
            "Not enough tokens or amount is more than allowed"
        );
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns(bool){
        require(balances[msg.sender] >= _value, "Not enough tokens for approve");
        allowed[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}