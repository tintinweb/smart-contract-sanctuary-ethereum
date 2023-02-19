// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BCoC {
// smart contract structure
    struct Evidence {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations; 
    }
// mapping to be able to access it in the following line
    mapping(uint256 => Evidence) public evidences;
//public variable
    uint256 public numberOfEvidence = 0; 



// create functions for smartcontract 
    //specifing the parameters that Create function going to take 
    //Public - used in the front end , Private stored on in the backend 
    // returns (uint256) because we want it to return the ID of this object 
    function createEvidence(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Evidence storage evidence = evidences[numberOfEvidence];

        // require --> test to see if everything is okay (it is a condition to move forword)
        // timestamp will show us the time block was submitted 
        require(evidence.deadline < block.timestamp, "The deadlin should be in the future.");
        evidence.owner = _owner; 
        evidence.title = _title;
        evidence.description = _description;
        evidence.target = _target;
        evidence.deadline = _deadline;
        evidence.amountCollected = 0; 
        evidence.image = _image;

        numberOfEvidence++; // incrementing the number of evidences it is alternative to numberOfEvidence = numberOfEvidence + 1

        return numberOfEvidence - 1; // index of the most recently created evidence 
    }



 // payable --> signifies that we are going to send some crypto currency through this function
    function addHandlers(uint256 _id) public payable {
        // The amount of wei sent with a message to a contract (wei is a denomination of ETH)
        uint256 amount = msg.value;
        Evidence storage evidence = evidences[_id];
        // push the address of person who submitted the handling form
        evidence.donators.push(msg.sender);
        evidence.donations.push(amount);
        // transaction , sent is a variable to be called later, payable(evidence.owner) --> sending eth to the owner of the evidence
        (bool sent, ) = payable(evidence.owner).call{value: amount}("");
        if(sent) {
            evidence.amountCollected = evidence.amountCollected + amount;
        }
    }




    // it will take no parameters we want to return all the evidence 
    function getEvidence() public view returns (Evidence[] memory) {
    // we are creating a new variable called "allEvidences" which is of the type array of multible evidence structure. We are creating an empty array with as many empty elements as there are actual evidence objects (just like containers to handle the evidence). {},{},{},{},{}
    Evidence[] memory allEvidences = new Evidence[](numberOfEvidence);
    // loop through all the evidence and popoulate/view them. for i = 0, while i < numberOfEvidence, i++
    // uint vs uint256 ????
    for (uint i = 0; i < numberOfEvidence; i++) {
        // get evidence from the storage and call it item then populate it to 
        Evidence storage item = evidences[i];
        //matching arrays with the evidence item
        allEvidences[i] = item;
    }
    return allEvidences;
}



// to get handlers we need to know from which evidence they came from thus we need to pass the evidence id
// view -- return some data from the blockchain
// memory -- get me this variable that has been stored before 
    function getHandlers(uint256 _id) view public returns (address[] memory, uint256[] memory ){
        // here in the function we want to view the handlers based on each evidence separtely that is why we use an array and define _id inside it (id is for the evidence id)
        return (evidences[_id].donators, evidences[_id].donations);
    }
     
}