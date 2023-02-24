/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library SafeMath {
   
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

contract Ownable {
    address public owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function waiveOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }

    function unlock() public {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked Time is not up");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

interface ERC20 {
    
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;
    uint256 public totalSupply;   
    uint256 public txFee;
    uint256 public burnFee;
    address public FeeAddress;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) tokenBlacklist;
    mapping(address => bool) tokenGreylist;
    
    event Blacklist(address indexed blackListed, bool value);
    event Gerylist(address indexed geryListed, bool value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) balances;


    function _transfer(address _to, uint256 _value) public returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(tokenBlacklist[_to] == false);

        require(tokenGreylist[msg.sender] == false);
        // require(tokenGreylist[_to] == false);

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 tempValue = _value;
        if(txFee > 0 && msg.sender != FeeAddress){
            uint256 DenverDeflaionaryDecay = tempValue.div(uint256(100 / txFee));
            balances[FeeAddress] = balances[FeeAddress].add(DenverDeflaionaryDecay);
            emit Transfer(msg.sender, FeeAddress, DenverDeflaionaryDecay);
            _value =  _value.sub(DenverDeflaionaryDecay);
        }

        if(burnFee > 0 && msg.sender != FeeAddress){
            uint256 Burnvalue = tempValue.div(uint256(100 / burnFee));
            totalSupply = totalSupply.sub(Burnvalue);
            emit Transfer(msg.sender, address(0), Burnvalue);
            _value =  _value.sub(Burnvalue);
        }

        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function _transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(tokenBlacklist[_from] == false);
        require(tokenBlacklist[_to] == false);

        require(tokenGreylist[_from] == false);

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        uint256 tempValue = _value;
        if(txFee > 0 && _from != FeeAddress){
            uint256 DenverDeflaionaryDecay = tempValue.div(uint256(100 / txFee));
            balances[FeeAddress] = balances[FeeAddress].add(DenverDeflaionaryDecay);
            emit Transfer(_from, FeeAddress, DenverDeflaionaryDecay);
            _value =  _value.sub(DenverDeflaionaryDecay);
        }

        if(burnFee > 0 && _from != FeeAddress){
            uint256 Burnvalue = tempValue.div(uint256(100 / burnFee));
            totalSupply = totalSupply.sub(Burnvalue);
            emit Transfer(_from, address(0), Burnvalue);
            _value =  _value.sub(Burnvalue);
        }

        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function _increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }

    function _geryList(address _address, bool _isGeryListed) internal returns (bool) {
        require(tokenGreylist[_address] != _isGeryListed);
        tokenGreylist[_address] = _isGeryListed;
        emit Gerylist(_address, _isGeryListed);
        return true;
    }

    function _blackAddressList(address[] memory _addressList, bool _isBlackListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            tokenBlacklist[_addressList[i]] = _isBlackListed;
            emit Blacklist(_addressList[i], _isBlackListed);
        }
        return true;
    }

    function _geryAddressList(address[] memory _addressList, bool _isGeryListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            tokenGreylist[_addressList[i]] = _isGeryListed;
            emit Gerylist(_addressList[i], _isGeryListed);
        }
        return true;
    }
}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super._transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super._transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super._approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super._increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super._decreaseApproval(_spender, _subtractedValue);
    }

    function blackListAddress(address listAddress,  bool isBlackListed) public whenNotPaused onlyOwner  returns (bool success) {
        return super._blackList(listAddress, isBlackListed);
    }

    function geryListAddress(address listAddress,  bool _isGeryListed) public whenNotPaused onlyOwner  returns (bool success) {
        return super._geryList(listAddress, _isGeryListed);
    }

    function blackAddressList(address[] memory listAddress,  bool isBlackListed) public whenNotPaused onlyOwner  returns (bool success) {
        return super._blackAddressList(listAddress, isBlackListed);
    }

    function geryAddressList(address[] memory listAddress,  bool _isGeryListed) public whenNotPaused onlyOwner  returns (bool success) {
        return super._geryAddressList(listAddress, _isGeryListed);
    }
}

contract CoinToken is PausableToken {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    bool internal _INITIALIZED_;


    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }
    function initToken(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, uint256 _txFee,uint256 _burnFee,address _FeeAddress,address tokenOwner) public notInitialized returns (bool){
        _INITIALIZED_=true;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        txFee = _txFee;
        burnFee = _burnFee;
        FeeAddress = _FeeAddress;
        // // service.transfer(msg.value);
        // (bool success) = service.call.value(msg.value)();
        // require(success, "Transfer failed.");
        emit Transfer(address(0), tokenOwner, totalSupply);
        return true;     
    }

    function burn(uint256 _value) public{
        _burn(msg.sender, _value);
    }

    function updateFee(uint256 _txFee,uint256 _burnFee,address _FeeAddress) onlyOwner public{
        txFee = _txFee;
        burnFee = _burnFee;
        FeeAddress = _FeeAddress;
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function mint(address account, uint256 amount) onlyOwner public {

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }
}

contract CoinFactory{

    function createToken(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, uint256 _txFee,uint256 _burnFee,address _FeeAddress,address tokenOwner)public returns (address){
        CoinToken token=new CoinToken();
        token.initToken(_name,_symbol,_decimals,_supply,_txFee,_burnFee,_FeeAddress,tokenOwner);
        return address(token);
    }
}