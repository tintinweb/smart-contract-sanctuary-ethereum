/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.4.11;

/**
* @title Contract that will work with ERC223 tokens.
*/
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data);
}		
		
 

contract CarbonCapture {

    string public name = "CCToken";      //  token name
    string public symbol = "CC";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    bool public stopped = false;

    uint256 constant valueFounder = 100000000000000000;
    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }
    
    
    function mint(address _to,uint256 _value, bytes _data) {
         uint codeLength;
         //檢查_to是否為合約，如果是的話就呼叫tokenFallback函式
         assembly { codeLength  := extcodesize(_to) }
         if(codeLength > 0) {
            ERC223ReceivingContract trc = ERC223ReceivingContract(_to);
            //注意，請不要用.call()等方式來呼叫tokenFallback，否則會導致tokenFallback丟出例外但transfer只會收到一個零當回傳值的情況 
            trc.tokenFallback(msg.sender, _value, _data);
         }
          totalSupply+=_value;
          balanceOf[_to]+=_value;
          Transfer(0x0, _to, _value , _data);
          
    }


    function transfer(address _to, uint256 _value) isRunning validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        bytes memory empty;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value ,empty);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning validAddress returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        bytes memory empty;
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value ,empty);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() isOwner {
        stopped = true;
    }

    function start() isOwner {
        stopped = false;
    }

    function setName(string _name) isOwner {
        name = _name;
    }

    function burn(uint256 _value , uint date) {
        require(balanceOf[msg.sender] >= _value);
        require(now >= date);
        bytes memory empty;
        totalSupply-=_value;
        balanceOf[msg.sender] -= _value;
        balanceOf[0x0] += _value;
        Transfer(msg.sender, 0x0, _value ,empty);
        
    }
     

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes data);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}