/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.5.0;
contract loan{


    struct customer{

        string name;
        address payable wallet;
        uint balance;

    }
    struct timer{

        uint end;
    }
    customer public owner;
    mapping (string => customer) members;
    mapping (address => timer) public memberTimer;
    mapping (address => uint) public memberLoan;

    address payable [] public memberCount;
    
    constructor()public payable{
        owner.wallet = msg.sender;
        owner.balance = msg.value;
    }
    modifier onlyOwner(){
        if(msg.sender == owner.wallet){
            _;
        }
    }
    modifier onlyTimerReached(){
        if(block.timestamp >= memberTimer[msg.sender].end){
            _;
        }
        _;
    }

    function setMember
    (string memory _name,address payable _wallet,uint _balance)
    public onlyOwner{
        members[_name] = customer(_name,_wallet,_balance);
        memberCount.push(_wallet);
    }
    function setTimer(address payable _wallet,uint _end)public onlyOwner{
        memberTimer[_wallet] = timer(_end);
        memberCount.push(_wallet);
    }
    function getTimer()public view returns(uint){
        return block.timestamp;
    }
    function setLoan(address payable _wallet,uint _amount)public{
        memberLoan[_wallet] = _amount;
    }
    function transfer()public onlyOwner onlyTimerReached {
        for(uint i=0;i<memberCount.length;i++){
            memberCount[i].transfer(memberLoan[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]);
        }
    }
    // function memberPay(address payable _wallet, uint _amount)public{
    //     owner.transfer()

    // }
}