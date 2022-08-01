/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity^0.6.0;

contract Bet {
    address public owner;//管理员
    bool isFinished;//是否结束
    struct Player {
        address payable addr;
        uint amount;
    }

    Player[] inBig;
    Player[] inSmall;

    uint totalBig;
    uint totalSmall;
    uint nowtime;

    constructor() public {
        owner = msg.sender;
        totalSmall = 0;
        totalBig = 0;
        isFinished = false;
        nowtime = now;
    }

    function stake(bool flag) public payable returns (bool) {
        require(msg.value > 0,"value must > 0");
        Player memory p = Player(msg.sender,msg.value);
        if(flag){
            inBig.push(p);
            totalBig += msg.value;
        }else{
            inSmall.push(p);
            totalSmall += msg.value;
        }
        return true;
    }

    function open() public payable returns(bool) {
        require(now > nowtime + 20,"开奖时间必须超过开始时间20秒");
        require(!isFinished,"活动已结束");
        uint points = uint(keccak256(abi.encode(msg.sender,now,block.number)))%18;
        uint i = 0;
        Player memory p;
        if(points >= 9){
            for(i ==0;i <inBig.length; i++){
                p = inBig[i];
                p.addr.transfer(p.amount + p.amount*totalSmall/totalBig);
            }
        }else{
            for(i ==0;i <inSmall.length; i++){
                p = inSmall[i];
                p.addr.transfer(p.amount + p.amount*totalBig/totalSmall);
            }
        }
        isFinished = true;
        return true;
    }
}