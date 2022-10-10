/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// File: diamond_tribunal/DS.sol



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

        mapping(uint256 => metadataDeal) deals;

        // deal ID to partTake choose

        mapping(uint256 => agreement) acceptance;

        

        uint256 dealCount;

        // deal ID to history updates

        mapping(uint256 => historyUpdates) updates;

        bool emergencyStop;

        bool contractWorking;

    }



    struct metadataDeal{

        address buyer; 

        address seller; 

        string title;

        uint256 amount; 

        uint256 goods; 

        uint16 status; //0=pending, 1= open, 2= completed, 3= cancelled, 4= OracleForce

        uint256 created;

        uint256 deadline; // timestamp

        string coin;

        uint256 numOfProposals;

        bool goodsCovered;

    }



    // (0 = No answer, 1 = Accepted, 2 = Cancelled, 3 = Paid, 4 = Refund)

    struct agreement{

        uint8 buyerChoose;

        uint8 sellerChoose;

        bool buyerAcceptDraft;

        bool sellerAcceptDraft;

    }



    struct historyUpdates{

        uint256 lastUpdateId;

        uint8 buyerChoose;

        uint8 sellerChoose;

        //

        mapping(uint256 => proposal) proposalsInfo;

    }



    struct proposal{

        uint256 created;

        uint256 proposalType; // 0 = informative, 1 = update deadline, 2=update title, 3=discount, 4=addtokens

        uint16 accepted; //(0 = No answer, 1 = Accepted, 2 = Cancelled, 3 =  No changes, 4 = updated)

        string infOrTitle;

        uint256 timeInDays;

        uint256 subOrAddToken;

        bool proposalStatus;

    }



    function getVar() internal pure returns (Appstorage storage s){

        bytes32 position = NAMESPACE;

        assembly{

            s.slot := position

        }

    }





}


// File: diamond_tribunal/readers.sol



pragma solidity ^0.8.8;




contract readers{



    function initVars() 

    external view returns

    ( address owner,

      address oracle,

      address tribunal,

      uint256 defaultfee,

      uint256 defaultPenalty,

      uint256 defaultLifeTime

      

    ){



      address _owner = DS.getVar().owner;

      address _oracle = DS.getVar().oracle;

      address _tribunal = DS.getVar().tribunal;

      uint256 _defaultFee = DS.getVar().defaultFee; 

      uint256 _defaultPenalty = DS.getVar().defaultPenalty;

      uint256 _defaultLifeTime = DS.getVar().defaultLifeTime;

      

      return ( _owner,_oracle,_tribunal,_defaultFee, _defaultPenalty, _defaultLifeTime);



    }



    function searchTokenERC20(string memory _tokenName) external view returns(address ERC20tokenaddress, uint256 decimals){

      address _tokenAddress = DS.getVar().tokens[_tokenName];

      uint256 _tokenDecimal = DS.getVar().tokenDecimal[_tokenName];

      return(_tokenAddress, _tokenDecimal);

    }



    function readDeal(uint256 _dealId) external view returns(DS.metadataDeal memory) {

      return (DS.getVar().deals[_dealId]);

    }

    function readDealCount() external view returns(uint256) {

      return (DS.getVar().dealCount);

    }



    function readAcceptance(uint256 _dealId) external view returns(DS.agreement memory) {

      return (DS.getVar().acceptance[_dealId]);

    }



    function seeProposalInfo(uint _dealId, uint _proposalId) external  view returns(uint256, uint256, uint16, string memory, uint256, uint256, bool){

        DS.proposal memory _info = DS.getVar().updates[_dealId].proposalsInfo[_proposalId];

        return(_info.created,_info.proposalType,_info.accepted, _info.infOrTitle, _info.timeInDays, _info.subOrAddToken, _info.proposalStatus);

    }



    function seeProposalCount(uint _dealId) external  view returns(uint256){

          return DS.getVar().updates[_dealId].lastUpdateId;

       

    }



    function seeHistoryUpdates(uint _dealId) external  view returns(uint256, uint8, uint8){

        DS.historyUpdates storage _info = DS.getVar().updates[_dealId];

        return(_info.lastUpdateId, _info.buyerChoose, _info.sellerChoose);

    }



    function seeContractStatus()external view returns(bool, bool){

      return(DS.getVar().emergencyStop, DS.getVar().contractWorking);

    }

}