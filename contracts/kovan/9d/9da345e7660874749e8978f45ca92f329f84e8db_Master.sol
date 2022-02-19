/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

pragma solidity ^0.8.0;
pragma abicoder v2;

//import "Text.sol";

abstract contract Text {
    uint public price;
    function mintText(address recipient, string memory tokenURI) public payable virtual returns (uint);
} 

contract Master {
    receive() external payable {}


    address NFT_ADDRESS = 0xc70e8Ee849891372aC6a23F19092925bD8f30821;

    struct Bid {
        bool answered;
        bool withdrawn;
        uint answerId;
        uint timeLimit;
        uint sum;
        address payable beneficiaryAddress; 
        address payable ownerAddress; 
    }
     
    mapping(address => string) privateKeys; 
    mapping(address => string) public publicKeys;
    mapping(address => uint[]) contracts;
    mapping(address => uint[]) beneficiaries;
    mapping(uint => Bid) bids;

    function setKeys(string calldata publicKey, string calldata privateKey) public {
        publicKeys[msg.sender] = publicKey;
        privateKeys[msg.sender] = privateKey;
    }

    function getPrivateKey() public view returns(string memory) {
        return privateKeys[msg.sender];
    }

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
        uint id = TXT.mintText{value: TXT.price()}(solver, question);
        contracts[msg.sender].push(id);
        beneficiaries[solver].push(id);
        bids[id] = Bid({
            answered: false, 
            withdrawn: false,  
            answerId: 0, 
            timeLimit: timeLimit, 
            sum: msg.value - 2*TXT.price(), 
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
   
    function rewardSolvedBid(uint id, string calldata answer) external {
       Bid storage bid = bids[id];
       Text TXT = Text(NFT_ADDRESS);
       uint answerId = TXT.mintText{value: TXT.price()}(bid.ownerAddress, answer);
       require(bid.beneficiaryAddress == msg.sender && bid.answered == false && bid.withdrawn == false && block.timestamp < bids[id].timeLimit );
       bid.answered = true;
       bid.answerId = answerId;
       payable(bid.beneficiaryAddress).transfer(bid.sum);
    }
   
}