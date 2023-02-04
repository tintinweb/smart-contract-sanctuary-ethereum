/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract OneDAO {
    address payable[] private members;
    mapping(address=>uint256) private votecount;  //address voted
    mapping(address=>address) public voteaddress;  //result vote by address
    mapping(address=>uint256) public addressbalance;  
    uint256 public poolValue = 0;
    uint256 public lastPoolValue = 0;
    uint256 public endTimeStamp = 0;
    uint256 public winnerTakesAllTimeStamp = 0;
    address payable public lastWinner;
    address payable public lastBuyer;
    address payable private _darklord;
    uint256 public priceFactor = 0;
    uint256 private _roundtime;  //second
    uint256 public baseprice;  //eth wei
    uint256 private _winnerTakesAllPercent; 
    uint256 private _poolPercent;  //value to split each round

    constructor (address darklord, uint256 price,  uint256 roundtime, uint256 poolPercent, uint256 winnerTakesAllPercent){
        baseprice = price;
        _darklord = payable(darklord);
        _roundtime = roundtime;
        _poolPercent = poolPercent;
        _winnerTakesAllPercent = winnerTakesAllPercent;
    }

    function buy() public payable {
        require(!isMember(msg.sender), "Can Only Buy One Per Address");
        uint256 price = baseprice * (priceFactor + 1);
        require(msg.value >= price,"Insufficient balance");
        if (members.length == 0)
            initRound();
        else
            checkEndRound();
        members.push(payable(msg.sender));
        poolValue += msg.value;
        priceFactor++;
        lastBuyer = payable(msg.sender);
        uint256 _now = block.timestamp;
        winnerTakesAllTimeStamp = _now + 2 * _roundtime;
    }

    function vote(address votefor) public {
        require(isMember(msg.sender), "Only Member Can Vote");
        require(isMember(votefor), "Must Vote Member");
        checkEndRound();
        if (isMember(msg.sender)){
            if (voteaddress[msg.sender] != address(0))
                votecount[voteaddress[msg.sender]]--;
            voteaddress[msg.sender] = votefor;
            votecount[votefor]++;
        }
    }

    function withdraw() public {
        checkEndRound();
        require(addressbalance[msg.sender] > 0, "No Balance");
        payable(msg.sender).transfer(addressbalance[msg.sender]);
        addressbalance[msg.sender] = 0;
    }

    function getMemberList(uint256 startindex, uint256 endindex) public view returns (address[] memory memberlist, uint256[] memory votes){
        if (members.length < endindex)
            endindex = members.length;
        memberlist = new address[](endindex - startindex);
        votes = new uint256[](endindex - startindex);    
        for (uint256 i = startindex; i < endindex; i++){
            memberlist[i - startindex] = members[i];
            votes[i - startindex] = votecount[members[i]];
        }
    }

    function getMemberCount() public view returns (uint256 result){
        result = members.length;
    }

    function isMember(address user) public view returns (bool result) {
        result = false;
        for (uint256 i = 0; i < members.length; i++){
            if (members[i] == user){
                result = true;
                break;
            }
        }
    }

    function checkEndRound() private{
        if (members.length == 0) 
            return;
        uint256 _now = block.timestamp;
        if (_now > winnerTakesAllTimeStamp && winnerTakesAllTimeStamp > 0 && lastBuyer != address(0)){  
            //last buyer take
            uint256 _value = poolValue * _winnerTakesAllPercent / 100;
            addressbalance[lastBuyer] += _value;
            poolValue -= _value;
            lastPoolValue = poolValue;
            priceFactor = 0;
            winnerTakesAllTimeStamp = _now + 2 * _roundtime;
        }     
        if (_now > endTimeStamp){  //end round
            uint256 currentPool = poolValue * _poolPercent / 100;
            lastWinner = payable(address(0));
            for (uint256 i = 0; i < members.length; i++){  //vote > 50%
                if (votecount[members[i]] >= members.length / 2){
                    lastWinner = members[i];
                    break;
                }
            }       
            //kick member who didn't vote
            for (uint256 i = members.length; i > 0; i--)
                if (voteaddress[members[i-1]] == address(0)){  
                    votecount[members[i-1]] = 0;
                    members[i-1] = members[members.length - 1];
                    members.pop();
                }   
                else{
                    votecount[members[i-1]] = 0;
                    voteaddress[members[i-1]] = address(0);
                }
            //split
            if (currentPool + lastPoolValue < poolValue && members.length > 0){  //pool increased > split value
                if (lastWinner == payable(address(0))){   //all int value
                    uint256 valuePerMember = currentPool * 9 / 10 / members.length;
                    for (uint256 i = 0; i < members.length; i++)
                        addressbalance[members[i]] += valuePerMember;
                    currentPool -= valuePerMember * members.length;
                    _darklord.transfer(currentPool);
                }
                else
                    addressbalance[lastWinner] += currentPool;
                poolValue -= currentPool;
                lastPoolValue = poolValue;            
            }
            initRound();
        }
    }

    function initRound() private{
        uint256 _now = block.timestamp;
        //if (endTimeStamp == 0)
            endTimeStamp = _now + _roundtime;
        //else
        //    endTimeStamp = endTimeStamp + _roundtime;
    }
}