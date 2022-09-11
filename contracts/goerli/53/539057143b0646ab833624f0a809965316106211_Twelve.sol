/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

contract Twelve{

    address payable owner;
    address nullAddress;
    uint nOfValidators;
    uint nOfTranslators;
    uint nOfMembers;
    uint nOfRequests;

    mapping(address=>Translator) public findTranslator;
    mapping(address=>Validator) public findValidator;
    mapping(address=>Member) public findMember;
    mapping(uint=>Request) public findRequest;
    mapping(address=>mapping(uint=>bool)) hasWorked;
    mapping(address=>mapping(uint=>bool)) hasApproved;
    mapping(address=>mapping(uint=>bool)) hasDenied;
    mapping(address=>mapping(uint=>bool)) hasCollected;

    struct Validator{
        address validator;
        uint validatorId;
        bool english;
        bool french;
        bool lingala;
    }

    struct Translator{
        address translator;
        uint translatorId;
        bool english;
        bool french;
        bool lingala;
    }

    struct Member{
        address member;
        uint memberId;
       bool english;
        bool french;
        bool lingala;
    }

    struct Request{
        uint requestId;
        uint amount;
        uint nOfWords;
        address client;
        address translator;
        bool english;
        bool french;
        bool lingala;
        bool accepted;
        uint approvals;
        uint denials;
        uint stage;
    }

        event NewTranslationRequest(bool english, bool french, bool lingala);
        event TranslatorAcceptedRequest(uint requestId, address indexed translator);
        event TranslationSubmitted(uint requestId);
        event TranslationApproved(uint requestId, address indexed Validator);
        event TranslationDenied(uint requestId, address indexed Validator);
        event RequestClosed(uint requestId);

    constructor() payable{
        owner=payable(msg.sender);
    }

    function addValidator(address addr, bool english, bool french, bool lingala) external onlyOwner{
        require(findValidator[addr].validatorId==0, "Role already granted");
        nOfValidators+=1;
        Validator memory newValidator;
        newValidator= Validator(addr, nOfValidators, english, french, lingala);
        findValidator[addr]=newValidator;
    }

    function addTranslator(address addr, bool english, bool french, bool lingala) external onlyValidator{
        require(findTranslator[addr].translatorId==0, "Role already granted");
        nOfTranslators+=1;
        Translator memory newTranslator;
        newTranslator= Translator(addr, nOfTranslators, english, french, lingala);
        findTranslator[addr]=newTranslator;
    }

    function becomeMember(address addr, bool english, bool french, bool lingala) external payable{
        require(findMember[addr].memberId==0, "Role already granted");
        require(msg.value==7000000000000000, "You must deposit 0.007ETH");
        nOfMembers+=1;
        Member memory newMember;
        newMember=Member(addr, nOfMembers, english, french, lingala);
        findMember[addr]=newMember;
    }

    function requestTranslation(uint nOfWords, bool english, bool french, bool lingala) external payable{
        require(msg.value>7000000000000000, "You must deposit at least 0.007ETH");

        nOfRequests+=1;
        Request memory newRequest;

        newRequest=Request(nOfRequests, msg.value, nOfWords, msg.sender,nullAddress, english, french, lingala, false, 0, 0, 1);
        findRequest[nOfRequests]=newRequest;

        emit NewTranslationRequest(english, french, lingala);
    }

    function acceptTranslation(uint requestId) external onlyTranslator{
        findRequest[requestId].accepted=true;
        findRequest[requestId].translator=msg.sender;
        findRequest[requestId].stage=2;
         emit TranslatorAcceptedRequest(requestId, msg.sender);
    }

    function submitTranslation(uint requestId) external {
        require(findRequest[requestId].translator==msg.sender, "This is not your request");
        require(findRequest[requestId].stage==2, "This function is not available");
 
            findRequest[requestId].stage=3;
            emit TranslationSubmitted(requestId);
        
    }

    function ApproveTranslation(uint requestId) external onlyValidator {
        require(findRequest[requestId].stage==3, "This function is not available");
        
            hasApproved[msg.sender][requestId]=true;
            findRequest[requestId].approvals+=1;
            emit TranslationApproved(requestId, msg.sender);
        
            if(findRequest[requestId].approvals>1){ //Chaneg for test
                findRequest[requestId].stage=4;
                emit RequestClosed(requestId);
            }
    }

    function denyTranslation(uint requestId) external onlyValidator {
        require(findRequest[requestId].stage==3, "This function is not available");

        hasDenied[msg.sender][requestId]=true;
        findRequest[requestId].denials+=1;
       emit TranslationDenied(requestId, msg.sender);
    
        if(findRequest[requestId].denials>1){ //Chaneg for test
            findRequest[requestId].stage=5;
            emit RequestClosed(requestId);
        }
    }

    function recollectFunds(uint requestId) external {
        require(findRequest[requestId].stage==5, "This function is not available");
        require(findRequest[requestId].client==msg.sender,"This is not your Request");
        require(hasCollected[msg.sender][requestId]==false, "You have already used this function");

        hasCollected[msg.sender][requestId]=true ;
        uint amount=findRequest[requestId].amount;
        (bool sent, ) = payable(msg.sender).call{value:amount}("");
        require(sent, "Failed to send back ETH");
        
        emit RequestClosed(requestId);
    }

    function getPaidAfterApproval (uint requestId) external {
        require(findRequest[requestId].stage==4, "This function is not available");
        require(hasApproved[msg.sender][requestId]==true, "You have not validated this request" );
        findRequest[requestId].stage=6;
        
        address payable validator=payable(msg.sender);

        (bool sent1, ) =validator.call{value:2500000000000000}("");
        require(sent1, "Failed to pay validating Validator");
    }

    function getPaidAfterDenial (uint requestId)external{
        require(findRequest[requestId].stage==5, "This function is not available");
        require(hasDenied[msg.sender][requestId]==true, "You have not denied this request" );

        findRequest[requestId].stage=6;
        address payable validator=payable(msg.sender);
        (bool sent1, ) =validator.call{value:2500000000000000}("");
        require(sent1, "Failed to pay validating Validator");
    }

    function getPaidTranslator(uint requestId) external{
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].translator==msg.sender, "You have not worked on this request");

        (bool sent3, )=payable(msg.sender).call{value:2500000000000000}("");
        require(sent3, "Failed to pat translator");
    }

    function deposit() external payable onlyOwner{}

    function withdraw(uint amount) external onlyOwner{
        require(amount<address(this).balance, "Not enough ETH");

        (bool success2, )= owner.call{value: amount}("");
        require(success2, "Failed to withdraw ETH" );
    }
  
    function changeRequest(
        uint requestId,
        uint denials,
        uint approvals,
        uint _stage) external{
        findRequest[requestId].requestId=requestId;
        findRequest[requestId].stage=_stage;
        findRequest[requestId].client=msg.sender;
        findRequest[requestId].translator=msg.sender;
        findRequest[requestId].amount=3000000;
        findRequest[requestId].english=true;
        findRequest[requestId].french=true;
        findRequest[requestId].lingala=true;
        findRequest[requestId].approvals=approvals;
        findRequest[requestId].denials=denials;

    }

    modifier onlyOwner() {
        require (msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier onlyValidator() {
        require(findValidator[msg.sender].validatorId>0, "You are not a Validator");
        _;
    }

    modifier onlyTranslator() {
        require(findTranslator[msg.sender].translatorId>0, "You are not a Translator");
        _;
    }

    modifier onlyNewValidator(uint requestId){
        require(hasWorked[msg.sender][requestId]==false, "You already worked on the Request");
     _;
    }

}