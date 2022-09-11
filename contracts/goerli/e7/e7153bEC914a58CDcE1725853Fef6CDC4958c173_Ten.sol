// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Ten{

    address payable owner;
    uint [] languages=[1,2,3];
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
    mapping(address=>mapping(uint=>bool)) isFluent;
   
    struct Validator{
        address payable validator;
        uint validatorId;
        uint nOfSpokenlanguages;
        uint nOfRequests;
        uint nOfChallenges;
    }

    struct Translator{
        address payable translator;
        uint translatorId;
        uint nOfSpokenlanguages;
        uint nOfTranslations;
        uint nOfApprovals;
        uint nOfDenials;
    }

    struct Member{
        address payable member;
        uint memberId;
        uint nOfSpokenlanguages;
    }

    struct PendingTrans{
        uint nOfTranslators;
        address payable translator1;
        address payable translator2;
        address payable translator3;
    }


    struct Request{
        uint requestId;
        address payable client;
        address payable translator;
        PendingTrans alPendingTranslators;
        uint timeFrame;
        uint amount;
        uint docLang;
        uint langNeeded;
        uint approvals;
        uint denials;
        bool challenged;
        uint stage;
    }

        event NewLanguage(uint idLanguage, string language);
        event NewValidator(uint validatorId, uint spokenlanguage1, uint spokenlanguage2);
        event NewTranslator(uint translatorId, uint spokenlanguage1, uint spokenlanguage2);
        event NewMember(uint memberId, uint spokenlanguage1, uint spokenlanguage2);
        event NewTranslationRequest(uint requestId, uint docLang, uint langNeeded);
        event NewPendingTranslator(uint requestId, address indexed pendTrans);
        event TranslatorApproved(uint requestId, address indexed translator, uint timeFrame);
        event TranslationSubmitted(uint requestId, uint docLang, uint langNeeded);
        event ValidatorVoted(uint requestId, address indexed Validator, uint nOfVotes);
        event TranslationValidated(uint requestId);
        event TranslationDenied(uint requestId);
        event TranslationChallenged(uint requestId);
        event RequestClosed(uint requestId);

    constructor() payable{
        owner=payable(msg.sender);
    }

    function addLanguage(string memory language) external onlyOwner{
        languages.push(languages.length);
        emit NewLanguage(languages.length, language) ;
    }

    function addValidator(address payable addr, uint spokenlanguage1, uint spokenlanguage2) external onlyOwner{
        require(findValidator[addr].validatorId==0, "Role already granted");
        nOfValidators+=1;
        Validator memory newValidator;
        newValidator= Validator(addr, nOfValidators, 2, 0, 0);
        findValidator[addr]=newValidator;
        isFluent[addr][spokenlanguage1]=true;
        isFluent[addr][spokenlanguage2]=true;
        emit NewValidator(nOfValidators, spokenlanguage1, spokenlanguage2);
    }

    function addTranslator(address payable addr, uint spokenlanguage1, uint spokenlanguage2) external onlyValidator{
        require(findTranslator[addr].translatorId==0, "Role already granted");
        nOfTranslators+=1;
        Translator memory newTranslator;
        newTranslator= Translator(addr, nOfTranslators, 2, 0, 0, 0);
        findTranslator[addr]=newTranslator;
        isFluent[addr][spokenlanguage1]=true;
        isFluent[addr][spokenlanguage2]=true;
        emit NewTranslator(nOfTranslators, spokenlanguage1, spokenlanguage2);
    }

    function becomeMember(address payable addr, uint spokenlanguage1, uint spokenlanguage2) external payable{
        require(findMember[addr].memberId==0, "Role already granted");
        require(msg.value==7000000000000000, "You must deposit 0.007ETH");

        nOfMembers+=1;
        Member memory newMember;
        newMember=Member(addr, nOfMembers, 2);
        findMember[addr]=newMember;
        isFluent[addr][spokenlanguage1]=true;
        isFluent[addr][spokenlanguage2]=true;

        emit NewMember(nOfMembers, spokenlanguage1, spokenlanguage2);
    }

    function requestTranslation( uint timeFrame, uint docLang, uint langNeeded) external payable{
        require(msg.value>7000000000000000, "You must deposit at least 0.007ETH");

        nOfRequests+=1;
        address payable client=payable(msg.sender);
        address payable nullAddress;
        Request memory newRequest;
        PendingTrans memory pendingTrans;

        newRequest=Request(nOfRequests, client,nullAddress,pendingTrans, timeFrame, docLang, langNeeded, msg.value, 0, 0, false, 0);
        findRequest[nOfRequests]=newRequest;

        emit NewTranslationRequest(nOfRequests, findRequest[nOfRequests].docLang, findRequest[nOfRequests].langNeeded);
    }

    function proposeTranslation(uint requestId) public onlyFluent(requestId){
        require(findRequest[requestId].stage<2, "This function is not available");
     
        findRequest[requestId].stage=1;
        findRequest[requestId].alPendingTranslators.nOfTranslators+=1;

        if(findRequest[requestId].alPendingTranslators.nOfTranslators==1){
            findRequest[requestId].alPendingTranslators.translator1=payable(msg.sender);

        }else if(findRequest[requestId].alPendingTranslators.nOfTranslators==2){
            findRequest[requestId].alPendingTranslators.translator2=payable(msg.sender);
        }else{
            findRequest[requestId].alPendingTranslators.translator3=payable(msg.sender);
        }

        emit NewPendingTranslator(requestId, msg.sender);
    }

    function approveTranslator(uint requestId, uint chosenTranslator) external {
        require(findRequest[requestId].client==payable(msg.sender), "This is not your request");
        require(findRequest[requestId].stage==1, "This function is not available");

        if(chosenTranslator==1){
            findRequest[requestId].translator=payable(findRequest[requestId].alPendingTranslators.translator1);
        }else if(chosenTranslator==2){
            findRequest[requestId].translator=payable(findRequest[requestId].alPendingTranslators.translator2);
        }else if(chosenTranslator==3){
            findRequest[requestId].translator=payable(findRequest[requestId].alPendingTranslators.translator3);
        }
        hasWorked[msg.sender][requestId]=true;
        findRequest[requestId].stage=2;
        findRequest[requestId].timeFrame+=block.number;
        emit TranslatorApproved(requestId, findRequest[requestId].translator, findRequest[requestId].timeFrame);
    }

    function submitTranslation(uint requestId) external {
        require(findRequest[requestId].translator==payable(msg.sender), "This is not your request");
        require(findRequest[requestId].stage==2, "This function is not available");
        uint timeLeft=findRequest[requestId].timeFrame - block.number;
        if(timeLeft<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            findRequest[requestId].stage=3;
            findRequest[requestId].timeFrame+=40;
            emit TranslationSubmitted(requestId, findRequest[requestId].docLang, findRequest[requestId].langNeeded);
        }
    }

    function verifyTranslation(uint requestId) external onlyNewValidator(requestId) onlyFluent(requestId){
        require(findRequest[requestId].stage==3, "This function is not available");
        uint timeLeft=findRequest[requestId].timeFrame - block.number;
        if(timeLeft - block.number<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            hasApproved[msg.sender][requestId]=true;
            hasWorked[msg.sender][requestId]=true;
            findTranslator[findRequest[requestId].translator].nOfApprovals+=1;
            findRequest[requestId].approvals+=1;
            emit ValidatorVoted(requestId, msg.sender, findRequest[requestId].approvals);
        
            if(findRequest[requestId].approvals>1){ //Chaneg for test
                findRequest[requestId].stage=4;
                findRequest[requestId].timeFrame+=20; // 5 mins
                emit TranslationValidated(requestId);
            }
        }

    }

    function denyTranslation(uint requestId) external onlyNewValidator(requestId) onlyFluent(requestId) {
        require(findRequest[requestId].stage==3, "This function is not available");
        uint timeLeft=findRequest[requestId].timeFrame - block.number;
        if(timeLeft - block.number<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            hasDenied[msg.sender][requestId]=true;
            hasWorked[msg.sender][requestId]=true;
            findTranslator[findRequest[requestId].translator].nOfDenials+=1;
            findRequest[requestId].denials+=1;
            emit ValidatorVoted(requestId, msg.sender, findRequest[requestId].denials);
        }
    }

    function challengeTranslation(uint requestId) external {
        require(findRequest[requestId].client==payable(msg.sender), "You are not the client of this request");
        require(findRequest[requestId].timeFrame-block.number>0, "Sorry, you can no longer challenge the request");
        require(findRequest[requestId].stage ==4, "This function is not available");
        require(findRequest[requestId].challenged=false, "This Request was already challenged");

        findRequest[requestId].challenged=true;
        findRequest[requestId].timeFrame=block.number+40; //10mins
        findRequest[requestId].stage=3;
        findRequest[requestId].approvals=0;
        findRequest[requestId].denials=0;

        emit TranslationChallenged(requestId);
    }

    function rejectTranslation(uint requestId) private {
        require(findRequest[requestId].stage==5, "This function is not available");
         
        uint amount=findRequest[requestId].amount;
        (bool sent, ) = findRequest[requestId].client.call{value:amount}("");
        require(sent, "Failed to send back ETH");
        
        emit TranslationDenied(requestId);
        emit RequestClosed(requestId);
    }

    function getPaidAfterValidation (uint requestId) external {
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].timeFrame-block.number<0, "The pay is not yet available");
        require(hasApproved[msg.sender][requestId]=true||findRequest[requestId].translator==payable(msg.sender), "You have not worked on this request" );
        findRequest[requestId].stage=6;
        address payable worker=payable(msg.sender);
        findTranslator[worker].nOfTranslations+=1;

        (bool sent1, ) =worker.call{value:2500000000000000}("");
        require(sent1, "Failed to pay Worker");
        emit RequestClosed(requestId);
    }

    function getPaidAfterDenial (uint requestId)external{
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].timeFrame-block.number<0, "The pay is not yet available");
        require(hasDenied[msg.sender][requestId]=true, "You have not worked on this request" );
        findRequest[requestId].stage=6;
        address payable worker=payable(msg.sender);
        findTranslator[worker].nOfTranslations+=1;

        (bool sent5, ) =worker.call{value:2500000000000000}("");
        require(sent5, "Failed to pay Validator");
        emit RequestClosed(requestId);
    }

    function addFluency(address addr, uint languageId) external onlyOwner{
        require(isFluent[addr][languageId]==false, "Already fluent");
        isFluent[addr][languageId]=true;
        if(findValidator[addr].validatorId>0){
            findValidator[addr].nOfSpokenlanguages+=1;
        }else if(findTranslator[addr].translatorId>0){
            findTranslator[addr].nOfSpokenlanguages+=1;
        }else if(findMember[addr].memberId>0){
            findMember[addr].nOfSpokenlanguages+=1;
        }
    }

    function deposit() external payable onlyOwner{}

    function withdraw(uint amount) external onlyOwner{
        require(amount<address(this).balance, "Not enough ETH");

        (bool success2, )= owner.call{value: amount}("");
        require(success2, "Failed to withdraw ETH" );
    }

    function changeRequest(
        uint requestId,
        uint _timeFrame,
        bool _challenged,
        uint _stage) external{
        findRequest[requestId].stage=_stage;
        findRequest[requestId].client=payable(msg.sender);
        findRequest[requestId].translator=payable(msg.sender);
        findRequest[requestId].timeFrame=_timeFrame;
        findRequest[requestId].amount=3000000;
        findRequest[requestId].docLang=1;
        findRequest[requestId].langNeeded=2;
        findRequest[requestId].challenged=_challenged;
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

    modifier onlyFluent(uint requestId){
        require(isFluent[msg.sender][findRequest[requestId].docLang]==true, "You are not Fluent in the docLang" );
        require(isFluent[msg.sender][findRequest[requestId].docLang]==true, "You are not Fluent in the Lang needed");
        _;
    }
}