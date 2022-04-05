/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity 0.8.12;


contract Rub {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance; // [owner, spender]
    uint8 public constant decimals = 18;
    string public constant symbol = "RUB";
    string public name;
    string public url;
    address bank;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _url) {
        name = _name;
        url = _url;
        bank = msg.sender;
    }

    modifier onlyBank() {
        require(msg.sender == bank, "not a bank");
        _;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "big value");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value, "big value");
        require(allowance[_from][msg.sender] >= _value, "not allowed");
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function deposit(address _to, uint256 _value) external onlyBank {
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
    }

    function withdraw(address _from, uint256 _value) external onlyBank {
        require(balanceOf[_from] >= _value, "big value");
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
    }

    function setBank(address _bank) external onlyBank {
        bank = _bank;
    }

    function setName(string calldata _name) external onlyBank {
        name = _name;
    }

    function setUrl(string calldata _url) external onlyBank {
        url = _url;
    }
}