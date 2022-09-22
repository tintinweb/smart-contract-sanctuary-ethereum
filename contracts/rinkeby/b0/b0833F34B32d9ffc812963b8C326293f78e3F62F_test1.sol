// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";
import "./Modifiers.sol";

contract test1 is Modifiers{

    function showDealCount()external view returns(uint256){
        return DS.getVar().dealCount;
    }
    function resetCounter() onlyOwner external{
        DS.getVar().dealCount = 0;
    }



    function addToCounter() external returns(bool){
        uint256 _count = DS.getVar().dealCount + 1;
        if(DS.getVar().deals_test[_count].amount == 0){
            return false;
        }else{
            DS.getVar().dealCount += 1;
            return true;
        }
    }

    function addDeal(address _seller, string memory _title, uint256 _amount) external  {
        uint256 _count = DS.getVar().dealCount + 1;
        require(DS.getVar().deals_test[_count].amount == 0, "This key already exists");
        DS.getVar().dealCount =  _count; //updating deal counter
        //buyer
        DS.getVar().acceptance[_count] = DS.getVar().acceptance[_count] = DS.agreement(0,0,true,false);

        DS.getVar().deals_test[_count] = DS.metadataDeal(
        msg.sender, 
        _seller, 
        _title, 
        _amount,
        0, 
        0, 
        block.timestamp, 
        0, //_newDeadline, 
        "BUSD",//_coin, 
        0
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";

contract Modifiers{

    modifier onlyOwner(){
        require(DS.getVar().owner == msg.sender, "Only OWNER");
        _;
    }
    modifier onlyOracle(){
        require(DS.getVar().oracle == msg.sender, "Only ORACLE");
        _;
    }
    modifier onlyTribunal(){
        require(DS.getVar().tribunal == msg.sender, "Only TRIBUNAL");
        _;
    }
    modifier tokenValid(string memory _tokenName){
        require(DS.getVar().tokens[_tokenName] != address(0),"token NOT supported");
        _;
    }
    function fill()external{

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library DS{

    //bytes32 internal constant NAMESPACE = keccak256("deploy.1.var.diamondstorage");
    bytes32 internal constant NAMESPACE = keccak256("test.1.var.diamondstorage");

    struct Appstorage{
        uint256 defaultLifeTime;
        uint256 defaultFee;
        uint256 defaultPenalty;
        address payable owner;
        address oracle;
        address tribunal;

        // map tokens contract
        mapping(string => address)  tokens;     
        // map tokens contract > decimals
        mapping(string => uint)  tokenDecimal;
        // deal ID to metadata Deal 
        mapping(uint256 => metadataDeal) deals_test;
        // deal ID to partTake choose
        mapping(uint256 => agreement) acceptance;
        
        uint256 dealCount;
    }

    struct metadataDeal{
        address buyer; 
        address seller; 
        string title;
        uint256 amount; 
        uint256 goods; 
        uint16 status; //0=pending, 1= open, 2= completed, 3= cancelled, 4= tribunal
        uint256 created;
        uint256 deadline; // timestamp
        string coin;
        uint256 numOfProposals;
    }

    // (0 = No answer, 1 = Accepted, 2 = Cancelled, 3 = Paid, 4 = Refund)
    struct agreement{
        uint8 buyerChoose;
        uint8 sellerChoose;
        bool buyerAcceptDraft;
        bool sellerAcceptDraft;
    }





    function getVar() internal pure returns (Appstorage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }


}