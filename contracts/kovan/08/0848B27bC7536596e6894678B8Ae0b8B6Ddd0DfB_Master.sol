/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

pragma solidity ^0.8.0;
pragma abicoder v2;

//import "Text.sol";

abstract contract Text {
    function mintText(address recipient, string memory tokenURI) public virtual returns (uint);
} 

contract Master {
    receive() external payable {}


    address NFT_ADDRESS = 0xd8aF13Fb0B1f716591c7A31bab321756b867f4D0;

    struct Bid {
        bool answered;
        bool withdrawn;
        uint answerId;
        uint timeLimit;
        uint sum;
        address payable beneficiaryAddress; 
        address payable ownerAddress; 
    }

    mapping(address => uint[]) contracts;
    mapping(address => uint[]) beneficiaries;
    mapping(uint => Bid) bids;

    function getBidsContract() public view returns(uint[] memory) {
        return contracts[msg.sender];
    }

    function getBidsBeneficiary() public view returns(uint[] memory) {
        return beneficiaries[msg.sender];
    }

    function getBid(uint id) public view returns(bool, bool, uint, uint, uint, address payable, address payable) {
        Bid storage bid = bids[id];
        require(bid.ownerAddress == msg.sender || bid.beneficiaryAddress == msg.sender);
        return (bid.answered, bid.withdrawn, bid.answerId, bid.timeLimit, bid.sum, bid.ownerAddress, bid.beneficiaryAddress); 
    }


    function makeNew(address payable solver, string calldata question, uint timeLimit) payable public {
        payable(this).transfer(msg.value);
        Text TXT = Text(NFT_ADDRESS);
        uint id = TXT.mintText(solver, question);
        contracts[msg.sender].push(id);
        beneficiaries[solver].push(id);
        bids[id] = Bid({
            answered: false, 
            withdrawn: false,  
            answerId: 0, 
            timeLimit: timeLimit, 
            sum: msg.value, 
            beneficiaryAddress: solver, 
            ownerAddress: payable(msg.sender)});
    }
   
    function withdrawExpiredBid(uint id) external {
      Bid storage bid = bids[id];  
      require(bid.ownerAddress == msg.sender && bid.answered == false && bid.withdrawn == false && block.timestamp  > bids[id].timeLimit); 
      // send back the eth here    
      bid.withdrawn = true;
      payable(msg.sender).transfer(bid.sum); 
    }
   
    function rewardSolvedBid(uint id, string calldata answer) external  {
       Bid storage bid = bids[id];
       Text TXT = Text(NFT_ADDRESS);
       uint answerId = TXT.mintText(bid.ownerAddress, answer);
       require(bid.beneficiaryAddress == msg.sender && bid.answered == false && bid.withdrawn == false && block.timestamp < bids[id].timeLimit );
       bid.answered = true;
       bid.answerId = answerId;
       payable(bid.beneficiaryAddress).transfer(bid.sum);
    }
   
}