/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

contract ReceiveETH {
    // 收到eth事件，记录amount和gas
    event Log(uint amount, uint gas);
    
    // receive方法，接收eth时被触发
    receive() external payable{
        emit Log(msg.value, gasleft());
    }
    
    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    function sendeth(address payable _to,uint256 amount) public payable{
        _to.transfer(amount);
    }


}