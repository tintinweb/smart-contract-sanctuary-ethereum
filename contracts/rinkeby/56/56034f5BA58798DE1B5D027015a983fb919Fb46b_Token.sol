/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

/**
 *Submitted for verification at Etherscan.io on 2019-02-11
*/

pragma solidity >=0.4.22 <0.6.0;

contract owned {
    address public owner;
    address public manager;
    address public operation;
    address public miner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
    
    modifier onlyOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }
    
    modifier onlyMiner {
        require(msg.sender == miner);
        _;
    }
    
    modifier onlyOwnerAndManager {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }
    
    modifier onlyManagerAndOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function setManager(address newManager) onlyOwnerAndManager public {
        manager = newManager;
    }
    
    function setOperation(address newOperation) onlyOwnerAndManager public {
        operation = newOperation;
    }
    
    function setMiner(address newMiner) onlyOwnerAndManager public {
        miner = newMiner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenERC20 {

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public supplyLimit;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Mint(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    constructor() public {
        totalSupply = 0;
        supplyLimit = 0;
        name = 'Bitkub Token';
        symbol = 'KUB';
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}


contract Token is owned, TokenERC20 {
    string public detail;
    string public website;
    address public dapp;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event SetSupply(uint256 value, string note);
    event BurnDirect(address indexed from, uint256 value, string note);

    constructor() TokenERC20() public {}

    function setDetail(string memory newDetail, string memory newWebsite) onlyOwnerAndManager public {
        detail = newDetail;
        website = newWebsite;
    }
    
    function setSupply(uint _value,string memory _note) onlyOwnerAndManager public {
        require (totalSupply <= _value);
        supplyLimit = _value;
        emit SetSupply(_value, _note);
    }
    
    function setDapp(address _address) onlyOwnerAndManager public {
        dapp = _address;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function freezeAccount(address _target, bool _freeze) onlyManagerAndOperation public {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function mintToken(address _target, uint _value) onlyMiner public {
        require (_target != address(0x0));
        require (totalSupply <= supplyLimit);
        balanceOf[_target] += _value;
        totalSupply += _value;
        emit Transfer(address(0), address(this), _value);
        emit Transfer(address(this), _target, _value);
    }

    function directBurn(address _from, uint _value,string memory _note) onlyMiner public{
        require (_from != address(0x0));
        require(balanceOf[_from] >= _value );
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit BurnDirect(_from, _value, _note);
    }

}