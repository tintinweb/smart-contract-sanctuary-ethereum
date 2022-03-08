// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./PRBMathUD60x18.sol";

contract VVV {
   address public owner;
   uint256 public balance;
   string public name ="Credits";
   string public symbol="VVV";
   uint256 public decimals=18;
   uint256 public totalSupply;
   uint256 public RegistryCount =0;
   uint256 public EntryFee=10000000000000000;
   
   mapping(address => uint256) public RankID;
   mapping(address => uint256) public CreditbalanceOf;
   mapping(address => uint256) public DebitbalanceOf;
   mapping(address => mapping(address => uint256)) public allowance;

   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
   event TransferReceived(address _from, uint _amount);
   event TransferSent(address _from, address _destAddr, uint _amount);

    constructor() {
        owner = msg.sender;
     }
     receive() payable external {
        Register();
    }   

   function Register() payable public {
        require(msg.value >= EntryFee,"Eth Sent must be greater than or equal to EntryFee.");
        if (RankID[msg.sender] == 0)
        {
            RegistryCount += 1;
            RankID[msg.sender] = RegistryCount;
            totalSupply = (RegistryCount * RegistryCount) * 1000000000000000000;
        }

        balance += msg.value;
   }

function balanceOf(address _to) public view returns (uint256) {
    uint256 TotalArea=1000000000000000000;
    uint256 RankArea=1000000000000000000;

    if (RankID[_to] > 1) 
    {
        RankArea = PRBMathUD60x18.ln(RankID[_to]*1000000000000000000) - PRBMathUD60x18.ln(RankID[_to]*1000000000000000000 - 1000000000000000000);
    }
    if (RankID[_to] == 0) 
    {
        RankArea=0;
    }
    TotalArea = PRBMathUD60x18.ln(RegistryCount*1000000000000000000) + 1000000000000000000;

    return PRBMathUD60x18.mul(PRBMathUD60x18.div(RankArea,TotalArea),totalSupply)+CreditbalanceOf[_to]-DebitbalanceOf[_to];
   }

 function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf(msg.sender) >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
 
        CreditbalanceOf[_to] = CreditbalanceOf[_to] + (_value);
        DebitbalanceOf[_from] = DebitbalanceOf[_from] + (_value);

        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf(_from));
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw funds"); 
        require(amount <= balance, "Insufficient funds");
        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, destAddr, amount);
    }

    function updateFee(uint256 amount) public {
        require(msg.sender == owner, "Only owner can update EntryFee."); 
        EntryFee = amount;
    }
  
}