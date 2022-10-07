/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

pragma solidity >=0.7.0 <0.9.0;

contract Piggybank {

    mapping (address => uint256) depositTime;
    mapping (address => uint256) depositAmount;    

    // quando ricevi degli ether, mandali indietro al mittente

    receive() external payable {

        depositTime[msg.sender] = block.timestamp;
        depositAmount[msg.sender] += msg.value;

        // rimandali al mittente
        // payable(msg.sender).send(msg.value);
    }

    function reclaim() public {
        require(block.timestamp >= depositTime[msg.sender] + 100 minutes);
        payable(msg.sender).send(depositAmount[msg.sender]);
        depositAmount[msg.sender] = 0;
    }

}