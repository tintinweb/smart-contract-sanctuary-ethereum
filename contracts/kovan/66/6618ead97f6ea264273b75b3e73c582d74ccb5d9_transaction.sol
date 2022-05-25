/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// File: mainframe.sol

pragma solidity 0.6.12; 

contract mainframe{ 
  uint public nodecount = 0; 
  bytes32 authorHash;
  event newPaper(uint paperOwnerId, string paperTitle, bytes32 paperHash);
  
  struct User{ 
    uint userId; 
    string userName; 
    address userAddress;
    bool author;   //true = user is author, vice versa
  }

   struct Paper{ 
    uint paperOwnerId;
    uint paperCost;
    string paperTitle; 
    bytes32 paperHash;
  }
  
  mapping (uint => address) public userToAddress;

  mapping (uint => address[]) paperToAddress;
  mapping (address => uint[]) public ownerToPapers;
  

  //mapping (uint => uint) public ownerIdToPaper; 

  User[] public users; //dynamic array of users
  Paper[] public papers; //dynamic array of papers

  modifier isAuthor(uint _userId){   //check whether user is author 
    require(users[_userId].author == true); 
    _; 
  }
  
  modifier isOwner(uint _userId){   //check whether user is owner
  require(msg.sender == users[_userId].userAddress);
    _;
  }
  

  function uploadPaper(uint _paperOwnerId, uint _paperCost, string memory _paperTitle) external{ 
    bytes32 hashDummy = keccak256(abi.encodePacked("dummy"));
    papers.push(Paper(_paperOwnerId, _paperCost, _paperTitle,hashDummy));
    uint paperInd = papers.length - 1;
    bytes32 realHash = callPaperHash(paperInd);
    papers[paperInd].paperHash = realHash;
    paperToAddress[paperInd].push(msg.sender);
    ownerToPapers[msg.sender].push(paperInd);
    emit newPaper(_paperOwnerId, _paperTitle, realHash);
  }
  
  
 function callPaperHash(uint id) internal pure returns (bytes32){
   return keccak256(abi.encodePacked("dummy", id));
 }

function queryPaper(uint _index) external view returns(bytes32) {
    address[] memory addressList = paperToAddress[_index];
    for (uint i = 0; i < addressList.length; i++){
        if (addressList[i] == msg.sender){
            return papers[_index].paperHash;
            break;
        }
    }

    revert("Doesn't own paper");

}
  
}



  /*
  function uploadPaper(address _owner, uint _paperOwnerId, string memory _paperTitle, bytes32 _paperHash) internal isAuthor(_paperOwnerId){ 
    uint paperInd = papers.push(Paper(_paperOwnerId, _paperTitle, _paperHash)) - 1;
    paperToAddress[paperInd] = msg.sender;
    ownerToPapers[_owner].push(paperInd);
    emit newPaper(paperInd, _paperOwnerId, _paperTitle, _paperHash);
  }

 // function callPaperHash() internal return (bytes32){
    

  //function addUser(){} //concept: add user to user array

    
  } //concept: gets paper hash
 


  //ownerToPapers[owner];

*/


   

// File: transaction.sol

pragma solidity 0.6.12; 


contract transaction is mainframe{ 

  event transaction(address sender, address receiver, uint amount);

  
  modifier checkBalance(uint amountTransferred, uint userBalance){ 
    require(amountTransferred <= userBalance); 
    _; 
  } //check whether the user have enough balance for the transaction

  
  function transferETH(address payable _receiverAddress, uint _amount)public payable { 
    address senderAddress = msg.sender; 
    _receiverAddress.transfer(_amount); 
  }           

  
   //Checks if the money sent and then gives the user address the owner of the paper from ownerToPapers, as well as have paperToAddress give the paperId to the user address. | Needs more implementation on how the hash is going to return a copy of the paper.
  function buyPaper(uint _paperInd, address payable _receiver) external payable{
    Paper memory targetPaper = papers[_paperInd];
    require(msg.value == targetPaper.paperCost);
    ownerToPapers[msg.sender].push(_paperInd);
    paperToAddress[_paperInd].push(msg.sender);
    
  } 


  
}
//  mapping (address => uint[]) public ownerToPapers;
//     ownerToPapers[_owner].push(paperInd);

contract ETHReceiver{ 
  event Log(uint amount, uint gas); 

  receive() external payable { 
    emit Log(msg.value, gasleft()); 
  }
}