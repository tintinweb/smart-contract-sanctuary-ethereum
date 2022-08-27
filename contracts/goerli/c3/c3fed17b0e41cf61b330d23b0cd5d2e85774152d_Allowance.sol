/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity >=0.8.0 <0.9.0;

contract Allowance {


    struct claimerInfo {
        address claimerAddress;
        uint256 lastClaimed;
        uint256 nextClaim;
    }
    mapping (address => claimerInfo) public claimers;
    address private owner;

    constructor() public {
    claimers[msg.sender] = claimerInfo(msg.sender,block.number,block.number+20);
    owner = msg.sender;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Caller is not owner");
        owner = newOwner;
    }

    function getUser(address lookedUser) public view returns(address,uint256,uint256) {
        return(claimers[lookedUser].claimerAddress,claimers[lookedUser].lastClaimed,claimers[lookedUser].nextClaim);
    }

    function claimAllowance() public {

        require(claimers[msg.sender].claimerAddress != 0x0000000000000000000000000000000000000000, "Claimer doesn't exist!");
        require(claimers[msg.sender].nextClaim < block.number, "Allowance not ready yet.");
        address payable userToPay = payable(claimers[msg.sender].claimerAddress);
        userToPay.transfer(1000000000000000);
        // Set next vars
        claimers[msg.sender].lastClaimed = block.number;
        claimers[msg.sender].nextClaim = block.number + 20;
}

function sendETHtoContract(uint256 j) public payable {
    //msg.value is the amount of wei that the msg.sender sent with this transaction. 
    //If the transaction doesn't fail, then the contract now has this ETH.
}
}