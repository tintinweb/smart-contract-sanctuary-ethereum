/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity 0.8.13;

contract AdContract {
    mapping(address => uint) public adLABEL;
    mapping(address => uint) public adLINK;
    mapping(address => uint) public adVALUE;
    mapping(address => uint) public adSTAMP;

    function addAD(address toADD, uint adLABELv, uint adLINKv) external payable {
        require(msg.value >= block.gaslimit);
        uint ctr;
        //2678400 seconds = 31 days, 86400 seconds = 1 day
        if (block.timestamp < (adSTAMP[toADD] + 2678400)) {
        	ctr = adVALUE[toADD] * ((30 - ((block.timestamp - adSTAMP[toADD]) / 86400)) + 1);
        	} else {
        	ctr = adVALUE[toADD] / (((block.timestamp / 86400) - 30) - (adSTAMP[toADD] / 86400));
        }
        require(msg.value > ctr);
        require(block.timestamp > (adSTAMP[toADD] + 86400)); //lock, 86400 seconds = 1 day
        adVALUE[toADD] = msg.value;
        adLINK[toADD] = adLINKv;
        adLABEL[toADD] = adLABELv;
        adSTAMP[toADD] = block.timestamp;
        (bool sent, ) = toADD.call{value: (msg.value - (msg.value / 100))}("");
        require(sent, "Failed to send Ether");
    }

    function calCTR(address toADD) public view returns (uint) {
        uint ctr;
        //2678400 seconds = 31 days, 86400 seconds = 1 day
        if (block.timestamp < (adSTAMP[toADD] + 2678400)) {
        	ctr = adVALUE[toADD] * ((30 - ((block.timestamp - adSTAMP[toADD]) / 86400)) + 1);
        	} else {
        	ctr = adVALUE[toADD] / (((block.timestamp / 86400) - 30) - (adSTAMP[toADD] / 86400));
        }
        if (ctr < block.gaslimit) {ctr = block.gaslimit;}
        if (block.timestamp <= (adSTAMP[toADD] + 86400)) {ctr = 0;} //0 = locked
        return (ctr);
    }

    function operTAKE(uint operTAKEv) public {
        require(msg.sender == 0x0661eE3542CfffBBEFCA7F83cfaD2E9D006d61a2);
        (bool sent, ) = msg.sender.call{value: operTAKEv}("");
        require(sent, "Failed to send Ether");
    }

}