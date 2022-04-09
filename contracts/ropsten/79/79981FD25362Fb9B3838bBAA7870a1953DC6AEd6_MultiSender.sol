/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

pragma solidity ^0.4.23;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {

        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {

        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {

    using SafeMath for uint;

    mapping(address => uint) balances;

    function transfer(address _to, uint _value) public {

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

    }

    function balanceOf(address _owner) public constant returns (uint balance) {

        return balances[_owner];

    }
}

contract IERC20 is BasicToken, ERC20 {
    mapping (address => mapping (address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) public {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public{
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}


contract Ownable {
    address public owner = msg.sender;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract MultiSender is Ownable{
    using SafeMath for uint;

    address public receiverAddress;
    address public feeAddress;
    uint public txFee;

    constructor(uint _fee, address _address) public {
        txFee =  _fee;
        feeAddress = _address;
    }

    function withdrawAll(address _tokenAddress) onlyOwner public {
        address _receiverAddress = owner;
        if(_tokenAddress == address(0)){
            require(_receiverAddress.send(address(this).balance));
        }

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(this);
        token.transfer(_receiverAddress, balance);
    }

    function setFee (uint _fee) onlyOwner external {
        txFee =  _fee;
    }

    function setFeeAddress (address _address) onlyOwner external {
        feeAddress = _address;
    }

    function etherSendSameValue(address[] memory _to, uint _value) public payable {
        uint sendAmount = _to.length.mul(_value);
        uint remainingValue = msg.value;
        if (msg.sender == owner) 
            require(remainingValue >= sendAmount, "Not enough amount.");

        else
            require(remainingValue >= sendAmount.add(txFee),"Not enough amount.");

        feeAddress.transfer(txFee);
        remainingValue.sub(txFee);

        for (uint8 i = 0 ; i < _to.length ; i++) {
            remainingValue = remainingValue.sub(_value);
            _to[i].transfer(_value);
        }
        
    }

    function etherSendDifferentValue(address[] memory _to, uint[]  memory _value) public payable {
        require(_to.length == _value.length, "Not correct input.");

        uint sendAmount;
        for (uint8 i = 0 ; i < _to.length ; i ++) {
            sendAmount.add(_value[i]) ;
        }
        uint remainingValue = msg.value;

        if (msg.sender == owner)
            require(remainingValue >= sendAmount);
        
        else
            require(remainingValue >= sendAmount.add(txFee)) ;

        for (uint8 j = 0 ; j < _to.length ; j++) {
            remainingValue = remainingValue.sub(_value[j]);
            _to[j].transfer(_value[j]);
        }

    }

    function tokenSendSameValue(address _tokenAddress, uint _value, address[] memory _to )  public payable {
        uint fee = msg.value;
        if (msg.sender != owner){
            require(fee >= txFee, "Need to pay for fee!");
            feeAddress.transfer(txFee);
        }

        address from = msg.sender;
        IERC20 token = IERC20(_tokenAddress);		

        for (uint8 i = 0 ; i < _to.length ; i++) {
            token.transferFrom(from, _to[i], _value);
        }
    }

	function tokenSendDifferentValue(address _tokenAddress, uint[] memory _value, address[] memory _to)  public payable  {
		require(_to.length == _value.length,"Not correct input.");

        uint fee = msg.value;
        if (msg.sender != owner) {
            require(fee >= txFee, "Need to pay for fee!");
            feeAddress.transfer(txFee);
        }
        
        IERC20 token = IERC20(_tokenAddress);
        for (uint8 i = 0 ; i < _to.length ; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
        }
	}
}