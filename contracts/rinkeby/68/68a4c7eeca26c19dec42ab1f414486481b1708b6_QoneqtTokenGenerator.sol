/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

//SPDX-License-Identifier: MIT 
 

pragma solidity ^ 0.8.0;

 
library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



contract QoneqtTokenGenerator {

    using SafeMath for uint256;
    
    address private _owner;

    mapping(address => uint256) balances;
   
  uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _tFeeTotal;

    string private _name ;
    string private _symbol;
    uint8 public constant decimals = 18;

    bool public LiqFee = false;
    bool public burnFee = false;
    bool public Ownable = false;

    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

   constructor (string memory tokenName, string memory tokenSymbol,uint256 initialSupply,bool _liqFee, bool _burnFee,bool _Ownable,uint256 liquidityFee_,uint256 burnRate_, address _uniswapv2router){
        address msgSender = msg.sender;
        require(address(msgSender) != address(0) , "ERC20: transfer to the zero address");
        _owner = msgSender;
        _name = tokenName;
        _symbol = tokenSymbol;
        _tTotal = initialSupply * 10 ** 18;
          LiqFee = _liqFee;
          burnFee = _burnFee;
          Ownable = _Ownable;

     
       balances[msgSender] = _tTotal;
        
        //exclude owner and this contract from fee

     emit Transfer(address(0), msgSender, _tTotal);

        if(Ownable == true) {
            renounceOwnershipToBurnAddress();
        }
        
    }
 

     function renounceOwnershipToBurnAddress() public virtual onlyOwner {
        require(Ownable == true , "Your token doesn't have Admin key burn option , It is decided at the time of token creation time");
          _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
         
        _owner = newOwner;
 
    }

     function Admin() public view returns (address) {
        return _owner;
    }
      function name() public view virtual  returns (string memory) {
        return _name;
    }
      function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    
   modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }



   function balanceOf(address owner_) public view returns (uint256) {
        return balances[owner_];
    }
    function totalSupply() public view virtual  returns (uint256) {
        return _tTotal;
    }

    /// ERC20 transfer().
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// ERC20 transferFrom().
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// ERC20 approve(). Comes with the standard caveat that an approval
    /// meant to limit spending may actually allow more to be spent due to
    /// unfortunate ordering of transactions. For safety, this method
    /// should only be called if the current allowance is 0. Alternatively,
    /// non-ERC20 increaseApproval() and decreaseApproval() can be used.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// ERC20 allowance().
    function allowance(address owner_, address _spender) public view returns (uint256) {
        return allowed[owner_][_spender];
    }

    /// Not officially ERC20. Allows an allowance to be increased safely.
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /// Not officially ERC20. Allows an allowance to be decreased safely.
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

    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}


}