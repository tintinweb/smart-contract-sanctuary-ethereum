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


// File: diamond_tribunal/initDiamond.sol



pragma solidity ^0.8.8;




contract initDiamond{



    function init(address _tokenAddress, string memory _tokenName,  uint256 _tokenDecimal, uint256 _defaultPenalty) external{

        DS.getVar().owner = payable(0xd20fD73BFD6B0fCC3222E5b881AB03A24449E608);

        DS.getVar().tokens[_tokenName] = _tokenAddress;

        DS.getVar().tokenDecimal[_tokenName] = _tokenDecimal;

        DS.getVar().defaultFee = 150; // Point Bassis 100 = 1%

        DS.getVar().defaultPenalty = _defaultPenalty;

        DS.getVar().defaultLifeTime =  604800; // 7 days

    }

}