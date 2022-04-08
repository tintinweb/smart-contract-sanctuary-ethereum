/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity >= 0.8.4 <0.9.0;

contract GtTest {

    function SendEthDemo(address payable add) external payable
    {
        uint256 selfBalance = address (this).balance;
        if(selfBalance > 1) add.transfer(selfBalance - 1);
        
    }

    function MyBalance() external view returns(uint256)
    {
        uint256 selfBalance = address (this).balance;
        return selfBalance;
    }

    address public _owner;
    
    constructor() public {
        _owner = msg.sender;
    }
    
    function getInvoker()  public view returns (address){
        return msg.sender;  // sender 获取部署合约或调用合约的用户地址
    }
    
    function getOwnerBalance()  public view returns (uint256){
        return msg.sender.balance;
    }

}

interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}