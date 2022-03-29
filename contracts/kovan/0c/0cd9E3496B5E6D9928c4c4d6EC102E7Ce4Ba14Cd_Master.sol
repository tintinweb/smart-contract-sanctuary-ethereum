/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// https://ethereum.stackexchange.com/questions/3609/returning-a-struct-and-reading-via-web3
pragma solidity ^0.8.13;
//pragma abicoder v2;
pragma experimental ABIEncoderV2;


library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

}

contract Master {
    receive() external payable {}

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    uint public fee = 100;

    //address NFT_ADDRESS = 0x4b3054bb6b265B5A5032185Ca37dDF3261625E29;
    address collectorAddress = 0x60e2CB9C426500058b936981c547C3640C8A4752;

    struct Bid {
        bool answered;
        bool withdrawn;
        uint value;
        uint sum;
        uint timestamp;
        uint deadline;
        address payable beneficiaryAddress; 
        address payable ownerAddress; 
        string[4] messages; // questionEncodedForOwner, questionEncodedForBeneficiary, answerEncodedForOwner, answerEncodedForBeneficiary
    }
     
    mapping(address => string) privateKeys; 
    mapping(address => string) public publicKeys;
    mapping(address => uint[]) contracts;
    mapping(address => uint[]) beneficiaries;
    mapping(uint => Bid) bids;
    mapping(address => uint) public bidLimits;

    function setKeys(string calldata publicKey, string calldata privateKey) external {
        publicKeys[msg.sender] = publicKey;
        privateKeys[msg.sender] = privateKey;
    }  

    function setBidLimit(uint bidLimit) external {
       bidLimits[msg.sender] = bidLimit;
    }

    function setKeysWithBidLimit(string calldata publicKey, string calldata privateKey, uint bidLimit) external {
        publicKeys[msg.sender] = publicKey;
        privateKeys[msg.sender] = privateKey;
        bidLimits[msg.sender] = bidLimit;
    }

    function getPrivateKey() external view returns(string memory) {
        return privateKeys[msg.sender];
    }

    function getBidsContract() external view returns(uint[] memory) {
        return contracts[msg.sender];
    }

    function getBidsBeneficiary() external view returns(uint[] memory) {
        return beneficiaries[msg.sender];
    }


    function getBids(uint[] calldata ids) external view returns (Bid[] memory) {

        Bid[] memory result = new Bid[](ids.length);
        Bid storage bid;

        for (uint i; i < ids.length; i++) {
            bid = bids[ids[i]]; 
            require(bid.ownerAddress == msg.sender || bid.beneficiaryAddress == msg.sender);
            result[i] = bid;
        }
        return result;
    }


    function getBid(uint id) internal view returns(bool, bool, uint, uint, uint, uint, address payable, address payable, string[4] memory) {
        Bid storage bid = bids[id];
        require(bid.ownerAddress == msg.sender || bid.beneficiaryAddress == msg.sender);
        return(bid.answered, bid.withdrawn, bid.timestamp, bid.deadline, bid.value, bid.sum, bid.ownerAddress, bid.beneficiaryAddress, bid.messages);
    }


    function makeNewWithSetKey(uint reward, address payable solver, string[2] calldata questionEncoded, uint blockLimit, string calldata publicKey, string calldata privateKey, uint bidLimit) payable external {
        publicKeys[msg.sender] = publicKey;
        privateKeys[msg.sender] = privateKey;
        bidLimits[msg.sender] = bidLimit;
        _makeNew(reward, solver, questionEncoded, blockLimit, msg.sender);   
    }

    /*function rewardSolvedBidWithSetKey(uint id, string calldata answer, string calldata publicKey, string calldata privateKey, uint bidLimit) external {
        this.setKeys(publicKey, privateKey, bidLimit);
        this.rewardSolvedBid(id, answer);   
    }*/

    function makeNew(uint reward, address payable solver, string[2] calldata questionEncoded, uint blockLimit) payable external {
        _makeNew(reward,  solver, questionEncoded, blockLimit, msg.sender);
    }


    function _makeNew(uint reward, address payable solver, string[2] calldata questionEncoded, uint blockLimit, address sender) internal { 
        
        require(msg.value >= reward && msg.value >= ((reward * 101)/100), "Value is less than reward + fee.");
        require(reward >= bidLimits[solver], "Reward is less than the bid limit of solver.");

        tokenIds.increment();
        uint id = tokenIds.current();
        
        contracts[sender].push(id);
        beneficiaries[solver].push(id);
        bids[id] = Bid({
            answered: false, 
            withdrawn: false,   
            value: msg.value,
            sum: reward, 
            timestamp: block.timestamp,
            deadline: block.number + blockLimit, // as blocknumber
            beneficiaryAddress: solver, 
            ownerAddress: payable(sender),
            messages: [questionEncoded[0], questionEncoded[1],"",""]});

        payable(this).transfer(msg.value);
    }
   
    function withdrawExpiredBid(uint id) external {
        Bid storage bid = bids[id];  
        require(bid.ownerAddress == msg.sender && !bid.answered  && !bid.withdrawn && block.number > bid.deadline); 
        // send back the eth here    
        bid.withdrawn = true;
        payable(msg.sender).transfer(bid.sum);
        payable(collectorAddress).transfer(bid.value-bid.sum); 
    }
   
    function rewardSolvedBid(uint id, string calldata answerEncodedForOwner, string calldata answerEncodedForBeneficiary) external {
        Bid storage bid = bids[id];
    
        require(bid.beneficiaryAddress == msg.sender && !bid.answered && !bid.withdrawn);
        if (bid.deadline > 0) {
            require(block.number <= bid.deadline);
        }
        bid.answered = true;
        bid.messages[2] = answerEncodedForOwner;
        bid.messages[3] = answerEncodedForBeneficiary;
        payable(bid.beneficiaryAddress).transfer(bid.sum);
        payable(collectorAddress).transfer(bid.value-bid.sum);
    }
   
}