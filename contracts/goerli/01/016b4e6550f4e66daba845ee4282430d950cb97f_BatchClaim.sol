/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// If you'd like to support me, send ETH here. Thank you for your support! ETH address: 0x88e76a35f42ee076B06356fEB1e9586123166fe6
// 如果你想支持我，请发送一些ETH给我。谢谢你的支持！以太坊地址: 0x88e76a35f42ee076B06356fEB1e9586123166fe6

// Telegram: https://t.me/SophonGo
// 电    报：https://t.me/SophonGo

interface ERC20 { 

    function claim() external;

    function transfer(address recipient, uint256 amount) external;
}

contract BatchClaim {

    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    /* Batch claim (Note: before calling, please make sure that the manual claim can be received normally. 
       When the total number of claims exceeds 101010, please do not use the claim of this contract)*/
    /* 0x00 批量Claim(注: 调用前，请务必确保手动Claim能正常领取, 当总的领取次数超过: 101010次, 请不要在使用本合约Claim) */

    function batchClaim(uint amount) external {
        for(uint i = 0; i < amount; i++){
            new Claim(msg.sender);
        }
    }

    function kill() external onlyOwner {
        selfdestruct(payable(owner));
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'You are not owner');
        _;
    }
}

contract Claim {
    
    constructor(address _owner) payable {

        /* 0x01 Build token instance */
        /* 0x01 构建Token实例 */

        // Goerli Testnet Network Token: 0x27be511e558fe24458da97e1a087c0e6a6e1029b
        // Goerli 测试网 代币: 0x27be511e558fe24458da97e1a087c0e6a6e1029b

        // Eth Main Network Token: 0x1c7E83f8C581a967940DBfa7984744646AE46b29
        // Eth 主网 代币: 0x1c7E83f8C581a967940DBfa7984744646AE46b29

        ERC20 randromToken = ERC20(0x27be511e558Fe24458dA97e1a087C0E6a6E1029B);

        /* 0x02 Execute claim to receive airdrop */
        /* 0x02 执行Claim领取空投 */

        randromToken.claim();

        /* 0x03 Transfer tokens to the caller's account number
           (Note: to save gas fees, cancel the query of token balance, and the number of tokens transferred directly is 151200000) */
        /* 0x03 转移代币到调用者账号(注: 为节省Gas费, 取消查询代币余额, 直接转移代币数量为: 151,200,000) */

        randromToken.transfer(_owner, 151200000000000000000000000);

        /* 0x04 Destroy contract */
        /* 0x04 销毁合约 */

        selfdestruct(payable(_owner));
    }
}