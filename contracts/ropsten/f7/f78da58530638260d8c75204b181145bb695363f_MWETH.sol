/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity >=0.4.22 <0.7.0;

contract MWETH {
    event Approval(address indexed src,address indexed guy, uint value);
    event Transfer(address indexed src,address indexed dst,uint value);
    event Deposit(address indexed dst,uint value);
    event Withdrawal(address indexed src,uint value);
    
    string public name     = "My Wrapped Ether";
    string public symbol   = "MWETH";
    uint8  public decimals = 18;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    function receive() external payable {
        deposit();
    }
    
    //质押eth
    function deposit() public payable{
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    //获取eth 
    function withdrawal(uint value) public{
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        msg.sender.transfer(value);
        emit Withdrawal(msg.sender, value);
    }
    
    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }
    
    function approval(address guy,uint value) public returns (bool) {
        allowance[msg.sender][guy] = value;
        emit Approval(msg.sender, guy, value);
        return true;
    }
    
    function transfer(address dst,uint value) public returns (bool){
        return transferFrom(msg.sender, dst, value);
    }
    
    function transferFrom(address src, address dst, uint value) public returns (bool){
        require(balanceOf[msg.sender] >= value);
        //授权交易   
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= value);
            allowance[src][msg.sender] -= value;
        }
        
        balanceOf[msg.sender] -= value;
        balanceOf[dst] += value;
        
        emit Transfer(src, dst, value);
        return true;
    }
    
}