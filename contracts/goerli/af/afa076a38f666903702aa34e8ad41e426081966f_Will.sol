/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract Will is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


 // event PayeeAdded(address payable _addrs, uint256 _share, uint _age );
address owner;
bool deceased;
 uint256 fortune;
 uint256 _totalShares ;
    address  []  recipients;
      mapping(address => uint256) public _shares;
      mapping(address => uint256) public age;
      uint  contractTime = block.timestamp;


    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
       
        name = "TafveezToken";
        symbol = "TFZ";
        decimals = 8;

        _totalSupply = 100000000000000;
        owner = msg.sender;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

       
    
    
     //event TransferReceived(address _from, uint _amount);

 


    }
    struct payee{
        address Address;
        uint256 Shares;
        uint256 Age;
        bool deceased ;
        
    

    }
    mapping(uint=>payee) public payeeList;
    uint256 payeeCount;
    

function addPayee(address  [] memory _addrs, uint256[] memory _share, uint[] memory _age ) public {
        require(_addrs.length == _share.length, "PaymentSplitter: payees and shares length mismatch");
        require(_addrs.length > 0, "PaymentSplitter: no payees");
        require(_addrs.length == _age.length, "length mismatch");
        payeeCount = _addrs.length;
        for (uint256 i = 0; i < _addrs.length; i++) {
            payeeList[i].Address = (_addrs[i]);
            payeeList[i].Shares = _share[i];
            require(_age[i] > contractTime,"age is not reached to claim");
        payeeList[i].Age = _age[i];
        
//emit PayeeAdded(address payable payeeList[i].Address, uint256 payeeList[i].Shares, uint256 payeeList[i].Age );
        }



      //  


}


function getPayee (uint n) public view returns ( address  ,uint , uint){
          return (payeeList[n].Address, payeeList[n].Shares, payeeList[n].Age);
}
    //    receive() payable external{
           
    //     uint256 share = fortune; 
        

    //     for(uint i=0; i < recipients.length; i++){
    //         uint amount = share *_shares[recipients[i]]/100;
    //          recipients[i].transfer(amount);
        
    //     }    
    //     emit TransferReceived(msg.sender, msg.value);
    // }     
    function payout(uint n) public  {
         require(payeeList[n].deceased == true);
         for(uint i=0; i < payeeCount; i++){
             uint amount = _totalSupply * payeeList[i].Shares/100;
             address temp = payeeList[i].Address;
             approve(temp, amount);
             transfer(temp,amount);
         }
         totalSupply();

    }
        function hasDeceased(uint n) public  onlyOwner {
        payeeList[n].deceased = true;
       payout(n);
    }
    function getTimeStamp() public view returns(uint256){
        return block.timestamp +100;
    }


function checkShares( address payable account) public view returns (uint256){
    return _shares[account];
}
function checkAge( address payable account) public view returns (uint256){
    return age[account];
}
  modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    //  modifier mustBeDeceased{
    //    //
    //     _;
    // }

    

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }



}