/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.4.24;
contract class24{
    function get_time_now()public view returns(uint256,uint256){
        return (now,block.timestamp);
    }
    function get_block_info()public view returns(uint blockNumber,bytes32 blockHash,uint256  blockDifficulty){
        //只能拿到256個區塊內的hash
        return (block.number,
                blockhash(block.number-1),
                block.difficulty);
    }
    function get_tx_info()public view returns(address msgSender,address origin,uint value){
        return  (msg.sender,
                tx.origin,
                msg.value );
    }

    //實作記錄送過來的ether

uint public value;
address public who;
uint public blockheight;
uint public when;
uint public hard;
uint public limit;
uint public left;
bytes public data;

function buy (uint)public payable{
        value =msg.value;
        who=msg.sender;
        blockheight=block.number;
        when=now;
hard=block.difficulty;
    limit=block.gaslimit;
    left=msg.gas;
    data=msg.data;
}





//block.difficulty (uint): 當前區塊難度
//block.gaslimit (uint): 當前區塊 gas 限額
//block.number (uint): 當前區塊號
//block.timestamp (uint): 目前區塊時間戳（block.timestamp）
//gasleft() returns (uint256)：剩餘的 gas
//msg.data (bytes): 完整的 calldata
//msg.gas (uint): 剩餘的 gas - 自 0.4.21 版本開始已經不使用，由 gesleft() 代替
//msg.sender (address): 消息發送者
//msg.sig (bytes4): calldata 的前 4 字節（也就是函數標識符）
//msg.value (uint): 隨著交易發送的 wei 的數量

}