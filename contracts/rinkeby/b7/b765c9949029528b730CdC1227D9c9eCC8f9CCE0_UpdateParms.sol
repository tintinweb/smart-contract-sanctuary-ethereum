// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";
import "./Modifiers.sol";

contract UpdateParms is Modifiers{

    // Change Defaults parms
    function _changeDefaultFee(uint256 _newDefaultFee) onlyOwner external{
        // use Points Basis 1% = 100
        require(DS.getVar().owner == msg.sender, "Only Owner");
        require((_newDefaultFee >= 10),"Fee in PB MIN 0.1% = 10" );
        require((_newDefaultFee <= 1000),"Fee in PB MAX 10% = 1000");
        DS.getVar().defaultFee = _newDefaultFee;
    }

    function _changeDefaultPenalty(uint256 _newDefaultPenalty) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().defaultPenalty = _newDefaultPenalty; // 1 USD = 1 unit
    }

    function _changeDefaultLifeTime(uint256 _newDefaultLifeTime) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().defaultLifeTime = _newDefaultLifeTime; // in secs
    }

    function _changeTribunalAdress(address _newAddress) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().tribunal = _newAddress;
    }

    function _changeOracleAddress(address _newAddress) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().oracle = _newAddress;
    }

    function _addNewToken(string memory _tokenName, address _tokenAddress, uint256 _tokenDecimal) onlyOwner external {
        require(DS.getVar().owner == msg.sender, "Only Owner");
        require(DS.getVar().tokens[_tokenName] == address(0), "token already exists");    
        DS.getVar().tokens[_tokenName] = _tokenAddress;
        DS.getVar().tokenDecimal[_tokenName] = _tokenDecimal;
    }

    function enableContract(bool _status) onlyOwner external{
        DS.getVar().contractWorking = _status;
    }

    function emegergencyStopContract(bool _status) onlyOwner external{
        DS.getVar().emergencyStop = _status;
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
    // Validate Only the buyer or seller can edit
    modifier isPartTaker(uint256 _dealID){
        require(((msg.sender == DS.getVar().deals[_dealID].buyer)||(msg.sender == DS.getVar().deals[_dealID].seller)),
        "You are not part of the deal");
        _;
    }
    // Validate the Deal status still OPEN
    modifier openDeal(uint256 _dealID){
        require(DS.getVar().deals[_dealID].status == 1," DEAL are not OPEN");
        _;
    }

    // Validate the Deal status is a DRAFT
    modifier openDraft(uint256 _dealID){
        require(DS.getVar().deals[_dealID].status == 0," DRAFT are not PENDING");
        _;
    }
    
    modifier goodsInDeal(uint256 _dealID){
        require(!DS.getVar().deals[_dealID].goodsCovered);
        _;
    }

    modifier isWorking(){
        require(DS.getVar().contractWorking == true, "Contract turned OFF");
        _;
    }

    modifier wasStopped(){
        require(DS.getVar().emergencyStop == false, "Contract stopped for emergency ");
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