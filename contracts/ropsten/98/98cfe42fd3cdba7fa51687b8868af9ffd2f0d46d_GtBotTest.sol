/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

contract GtBotTest {
    
    address internal constant TOKEN_WETH  = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

//    fallback() external payable {} //失败了会使用fallback退回原路 这个函数必须使用external payable进行修饰

    function SendEthToWEth(address payable add) external payable
    {
        uint256 u = 1 ether;
        add.transfer(u);
    }

    function MyBalance() external view returns(uint256)
    {
        uint256 selfBalance = address(this).balance;
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