/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

pragma solidity ^0.4.24;
contract DistributeTokens {
    address public owner;
    mapping(address => address) public recordMember;
    mapping(address => uint) public investors;
    mapping(uint => address) public profits;
    uint public count;

    constructor() public {
        owner = msg.sender;
    }

    function invest() public payable {    
        require(msg.value > 0, "Investment capital must be greater than 0 wei.");
        if(recordMember[msg.sender] != msg.sender) {
            recordMember[msg.sender] = msg.sender;
            profits[count] = msg.sender;
            count++;
        }
        investors[msg.sender] += msg.value;
    }

    // 不是正確的分紅模式，單純測試
    function distribute() public payable {
        require(msg.sender == owner, "Only administer could distribute."); // only owner

        for (uint i=0;i<count;i++){
            profits[i].transfer(investors[profits[i]]/5);
            investors[profits[i]] -= investors[profits[i]] / 5; // 就是這裡不正確，但單純給測試用以避免獎金池缺錢發不出錢
        }
    }

    function numberOfInvesters() public view returns(uint) {
        return count;
    }

    function over() public {
        require(msg.sender == owner, "Only administer could over this game."); // only owner
        for (uint i=0;i<count;i++){
            profits[i].transfer(investors[profits[i]]);
            investors[profits[i]] = 0;
        }
    }
}