/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != 0x0);
        owner = newOwner;
    }
}

contract BasicToken is owned {
    using SafeMath for uint256;

    mapping (address => uint256) internal balance_of;
    mapping (address => mapping (address => uint256)) internal allowances;

    mapping (address => bool) private address_exist;
    address[] private address_list;

 

    event Transfer(address indexed from, address indexed to, uint256 value);

    function BasicToken() public {
    }

    function balanceOf(address token_owner) public constant returns (uint balance) {
        return balance_of[token_owner];
    }

    function allowance(
        address _hoarder,
        address _spender
    ) public constant returns (uint256) {
        return allowances[_hoarder][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(msg.sender != address(0));
        require(_spender != address(0));
        require(_value >= 0);
        allowances[msg.sender][_spender] = _value;
        return true;
    }

    function getAddressLength() onlyOwner public constant returns (uint) {
        return address_list.length;
    }

    function getAddressIndex(uint _address_index) onlyOwner public constant returns (address _address) {
        _address = address_list[_address_index];
    }

    function getAllAddress() onlyOwner public constant returns (address[]) {
        return address_list;
    }

    function getAddressExist(address _target) public constant returns (bool) {
        if (_target == address(0)) {
            return false;
        } else {
            return address_exist[_target];
        }
    }

    function addAddress(address _target) internal returns(bool) {
        if (_target == address(0)) {
            return false;
        } else if (address_exist[_target] == true) {
            return false;
        } else {
            address_exist[_target] = true;
            address_list[address_list.length++] = _target;
        }
    }

    function transfer(address to, uint256 value) public;
    function transferFrom(address _from, address _to, uint256 _amount) public;


}

contract FreezeToken is owned {
    mapping (address => uint256) public freezeDateOf;

    event Freeze(address indexed _who, uint256 _date);
    event Melt(address indexed _who);

    function checkFreeze(address _sender) public constant returns (bool) {
        if (now >= freezeDateOf[_sender]) {
            return false;
        } else {
            return true;
        }
    }

    function freezeTo(address _who, uint256 _date) internal {
        freezeDateOf[_who] = _date;
        Freeze(_who, _date);
    }

    function meltNow(address _who) internal onlyOwner {
        freezeDateOf[_who] = now;
        Melt(_who);
    }
}

contract TokenInfo is owned {
    using SafeMath for uint256;

    address public token_wallet_address;

    string public name = "DOTORI";
    string public symbol = "DTR";
    uint256 public decimals = 18;
    uint256 public total_supply = 10000000000 * (10 ** uint256(decimals));



    event ChangeTokenName(address indexed who);
    event ChangeTokenSymbol(address indexed who);
    event ChangeTokenWalletAddress(address indexed from, address indexed to);
    event ChangeFreezeTime(uint256 indexed from, uint256 indexed to);

    function totalSupply() public constant returns (uint) {
        return total_supply;
    }

    function changeTokenName(string newName) onlyOwner public {
        name = newName;
        ChangeTokenName(msg.sender);
    }

    function changeTokenSymbol(string newSymbol) onlyOwner public {
        symbol = newSymbol;
        ChangeTokenSymbol(msg.sender);
    }

    function changeTokenWallet(address newTokenWallet) onlyOwner internal {
        require(newTokenWallet != address(0));
        address pre_address = token_wallet_address;
        token_wallet_address = newTokenWallet;
        ChangeTokenWalletAddress(pre_address, token_wallet_address);
    }



}

contract Token is owned,  FreezeToken, TokenInfo, BasicToken {
    using SafeMath for uint256;

    

    event Payable(address indexed who, uint256 eth_amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);


    function Token (address _owner_address, address _token_wallet_address) public {
        require(_token_wallet_address != address(0));

        if (_owner_address != address(0)) {
            owner = _owner_address;
            balance_of[owner] = 0;
        } else {
            owner = msg.sender;
            balance_of[owner] = 0;
        }

        token_wallet_address = _token_wallet_address;
        balance_of[token_wallet_address] = total_supply;
    }


    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(msg.sender != address(0));
        require(_from != address(0));
        require(_amount <= allowances[_from][msg.sender]);
        _transfer(_from, _to, _amount);
        allowances[_from][msg.sender] -= _amount;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        require(_from != address(0));
        require(_to != address(0));
        require(balance_of[_from] >= _amount);
        require(balance_of[_to].add(_amount) >= balance_of[_to]);

        require(checkFreeze(_from) == false);

        uint256 prevBalance = balance_of[_from] + balance_of[_to];
        balance_of[_from] -= _amount;
        balance_of[_to] += _amount;
        assert(balance_of[_from] + balance_of[_to] == prevBalance);
        addAddress(_to);
        Transfer(_from, _to, _amount);
    }

    function burn(address _who, uint256 _amount) onlyOwner public returns(bool) {
        require(_amount > 0);
        require(balanceOf(_who) >= _amount);
        balance_of[_who] -= _amount;
        total_supply -= _amount;
        Burn(_who, _amount);
        return true;
    }

    function tokenWalletChange(address newTokenWallet) onlyOwner public returns(bool) {
        require(newTokenWallet != address(0));
        uint256 token_wallet_amount = balance_of[token_wallet_address];
        balance_of[newTokenWallet] = token_wallet_amount;
        balance_of[token_wallet_address] = 0;
        changeTokenWallet(newTokenWallet);
    }

    function () payable public {
        uint256 eth_amount = msg.value;
        msg.sender.transfer(eth_amount);
        Payable(msg.sender, eth_amount);
    }

    function freezeAddress(
        address _who,
        uint256 _addTimestamp
    ) onlyOwner public returns(bool) {
        freezeTo(_who, _addTimestamp);
        return true;
    }

    function meltAddress(
        address _who
    ) onlyOwner public returns(bool) {
        meltNow(_who);
        return true;
    }

}