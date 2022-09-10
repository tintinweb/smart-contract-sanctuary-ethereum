// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Seventh{

    address payable owner;
    uint [] languages=[1,2,3];
    uint nOfValidators;
    uint nOfTranslators;
    uint nOfMembers;
    uint nOfRequests;

    mapping(address=> mapping(uint=>bool)) public isFluent;
    mapping(address=>Translator) public findTranslator;
    mapping(address=>Validator) public findValidator;
    mapping(address=>Member) public findMember;
    mapping(uint=>Request) public findRequest;
    mapping(address=>mapping(uint=>bool))hasWorked;

   
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

    struct Role{
        uint nOfAddr;
        address addrId1;
        address addrId2;
        address addrId3;
    }

    struct Request{
        uint requestId;
        address payable client;
        address payable translator;
        uint timeFrame;
        uint amount;
        uint docLang;
        uint langNeeded;
        Role alPendingTranslators;
        Role Approvers;
        Role Deniers;
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
        event ValidatorVoted(uint requestId, uint nOfApprovals, uint nOfDenials);
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
        isFluent[addr][spokenlanguage1]=true;
        isFluent[addr][spokenlanguage2]=true;
        findMember[addr]=newMember;

        emit NewMember(nOfMembers, spokenlanguage1, spokenlanguage2);
    }

    function requestTranslation( uint timeFrame, uint doclang, uint langNeeded) external payable{
        require(msg.value>7000000000000000, "You must deposit at least 0.007ETH");

        nOfRequests+=1;
        address payable client=payable(msg.sender);
        address payable temporaryAddress;

        Request memory newRequest;
        Role memory role;
        newRequest=Request(nOfRequests, client, temporaryAddress, timeFrame, msg.value, doclang, langNeeded, role, role, role, false, 0);
        findRequest[nOfRequests]=newRequest;

        emit NewTranslationRequest(nOfRequests, findRequest[nOfRequests].docLang, findRequest[nOfRequests].langNeeded);
    }

    function proposeTranslation(uint requestId) public onlyTranslator onlyFluent(requestId) {
        require(findRequest[requestId].stage==0, "This function is not available");
     
        findRequest[requestId].stage=1;
        findRequest[requestId].alPendingTranslators.nOfAddr+=1;

        if(findRequest[requestId].alPendingTranslators.nOfAddr==0){
            findRequest[requestId].alPendingTranslators.addrId1=msg.sender;

        }else if(findRequest[requestId].alPendingTranslators.nOfAddr==1){
            findRequest[requestId].alPendingTranslators.addrId2=msg.sender;
        }else{
            findRequest[requestId].alPendingTranslators.addrId3=msg.sender;
        }

        emit NewPendingTranslator(requestId, msg.sender);
    }

    function approveTranslator(uint requestId, uint chosenTranslator) external {
        require(findRequest[requestId].client==payable(msg.sender), "This is not your request");
        require(findRequest[requestId].stage==1, "This function is not available");

        if(chosenTranslator==1){
            findRequest[requestId].translator=payable(findRequest[requestId].alPendingTranslators.addrId1);
        }else if(chosenTranslator==2){
            findRequest[requestId].translator=payable(findRequest[requestId].alPendingTranslators.addrId2);
        }else if(chosenTranslator==3){
            findRequest[requestId].translator=payable(findRequest[requestId].alPendingTranslators.addrId3);
        }
        findRequest[requestId].stage=2;
        findRequest[requestId].timeFrame+=block.timestamp;
        emit TranslatorApproved(requestId, findRequest[requestId].translator, findRequest[requestId].timeFrame);
    }

    function submitTranslation(uint requestId) external {
        //Potentially  Event checker
        require(findRequest[requestId].translator==payable(msg.sender), "This is not your request");
        require(findRequest[requestId].stage==2, "This function is not available");
        findRequest[requestId].stage=3;
        findRequest[requestId].timeFrame+=40;
        hasWorked[msg.sender][requestId]=true;

        if(findRequest[requestId].timeFrame - block.timestamp<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            emit TranslationSubmitted(requestId, findRequest[requestId].docLang, findRequest[requestId].langNeeded);
        }
    }

    function verifyTranslation(uint requestId) external onlyValidator onlyFluent(requestId) onlyNewValidator(requestId) {
        require(findRequest[requestId].stage==3, "This function is not available");
        require(findRequest[requestId].translator!=payable(msg.sender), "The translator cannot validate his own work");
        if(findRequest[requestId].timeFrame - block.timestamp<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            hasWorked[msg.sender][requestId]=true;
            findTranslator[findRequest[requestId].translator].nOfApprovals+=1;
            findRequest[requestId].Approvers.nOfAddr+=1;
            if(findRequest[requestId].Approvers.nOfAddr==0){
                findRequest[requestId].Approvers.addrId1=payable(msg.sender);
            }else if(findRequest[requestId].Approvers.nOfAddr==1){
                findRequest[requestId].Approvers.addrId2=payable(msg.sender);
            }else if(findRequest[requestId].Approvers.nOfAddr==2){
                findRequest[requestId].Approvers.addrId3=payable(msg.sender);
            }
            emit ValidatorVoted(requestId, findRequest[requestId].Approvers.nOfAddr, findRequest[requestId].Deniers.nOfAddr);
        
            if(findRequest[requestId].Approvers.nOfAddr>1){ //Chaneg for test
                findRequest[requestId].stage=4;
                findRequest[requestId].timeFrame+=20; // 5 mins
                emit TranslationValidated(requestId);
                
            }
        }

    }

    function denyTranslation(uint requestId) external onlyValidator onlyFluent(requestId) onlyNewValidator(requestId) {
        require(findRequest[requestId].stage==3, "This function is not available");

        hasWorked[msg.sender][requestId]=true;
        findTranslator[findRequest[requestId].translator].nOfDenials+=1;
        findRequest[requestId].Deniers.nOfAddr+=1;
        emit ValidatorVoted(requestId, findRequest[requestId].Approvers.nOfAddr, findRequest[requestId].Deniers.nOfAddr);

        if(findRequest[requestId].Deniers.nOfAddr==1){
            findRequest[requestId].Deniers.addrId1=payable(msg.sender);
        }else if(findRequest[requestId].Deniers.nOfAddr==2 ||findRequest[requestId].timeFrame - block.timestamp<0){
            findRequest[requestId].Deniers.addrId2=payable(msg.sender);
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }

    }

    function challengeTranslation(uint requestId) external {
        require(findRequest[requestId].client==payable(msg.sender), "You are not the client of this request");
        require(findRequest[requestId].timeFrame-block.timestamp>0, "Sorry, you can no longer challenge the request");
        require(findRequest[requestId].stage ==4, "This function is not available");
        require(findRequest[requestId].challenged=false, "This Request was already challenged");

        findRequest[requestId].challenged=true;
        findRequest[requestId].timeFrame=block.timestamp+40; //10mins
        findRequest[requestId].stage=3;

        if(findRequest[requestId].Approvers.nOfAddr>0){
            uint nOfApprovers=findRequest[requestId].Deniers.nOfAddr;
            for(uint i=0; i<nOfApprovers; i++){
                if(i==0){
                findValidator[findRequest[requestId].Deniers.addrId1].nOfChallenges+=1;
                }else if(i==1){
                    findValidator[findRequest[requestId].Deniers.addrId2].nOfChallenges+=1;
                }else if(i==2){
                    findValidator[findRequest[requestId].Deniers.addrId3].nOfChallenges+=1;
                }
            }
        }
        emit TranslationChallenged(requestId);
    }

    function rejectTranslation(uint requestId) private {
         require(findRequest[requestId].stage==5, "This function is not available");
         
        uint amount=findRequest[requestId].amount;
        (bool sent, ) = findRequest[requestId].client.call{value:amount}("");
        require(sent, "Failed to send back ETH");

        if(findRequest[requestId].Deniers.nOfAddr>0){
            uint nOfDeniers=findRequest[requestId].Deniers.nOfAddr;
            address payable aValidator;
            
            for(uint i=0; i<nOfDeniers; i++){
                if(i==0){
                aValidator=payable(findRequest[requestId].Deniers.addrId1);
                findValidator[aValidator].nOfRequests+=1;
                (bool sent1, ) = aValidator.call{value:2500000000000000}("");
                require(sent1, "Failed to send ETH to Validator1");  
                }else if(i==1){
                    aValidator=payable(findRequest[requestId].Deniers.addrId2);
                    findValidator[aValidator].nOfRequests+=1;
                    (bool sent2, ) = aValidator.call{value:2500000000000000}("");
                    require(sent2, "Failed to send ETH to Validator2"); 
                }else if(i==2){
                    aValidator=payable(findRequest[requestId].Deniers.addrId3);
                    findValidator[aValidator].nOfRequests+=1;
                    (bool sent3, ) = aValidator.call{value:2500000000000000}("");
                    require(sent3, "Failed to send ETH to Validator3"); 
                }
            }
        }
        emit TranslationDenied(requestId);
        emit RequestClosed(requestId);
    }

    function payRequest(uint requestId) external {
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].timeFrame-block.timestamp<0, "The pay is not yet available");

        findRequest[requestId].stage=6;
        address payable validatedTranslator=findRequest[requestId].translator;
        findTranslator[validatedTranslator].nOfTranslations+=1;

        (bool sent1, ) =validatedTranslator.call{value:2500000000000000}("");
        require(sent1, "Failed to pay Translator");
       
        address payable aValidator;
        for(uint i=0; i<findRequest[requestId].Approvers.nOfAddr; i++){
            if(i==0){
                aValidator=payable(findRequest[requestId].Approvers.addrId1);
                findValidator[aValidator].nOfRequests+=1;
                (bool sent4, ) = aValidator.call{value:2500000000000000}("");
                require(sent4, "Failed to send ETH to Validator1");  
                }else if(i==1){
                    aValidator=payable(findRequest[requestId].Approvers.addrId2);
                    findValidator[aValidator].nOfRequests+=1;
                    (bool sent5, ) = aValidator.call{value:2500000000000000}("");
                    require(sent5, "Failed to send ETH to Validator2"); 
                }else if(i==2){
                    aValidator=payable(findRequest[requestId].Approvers.addrId3);
                    findValidator[aValidator].nOfRequests+=1;
                    (bool sent6, ) = aValidator.call{value:2500000000000000}("");
                    require(sent6, "Failed to send ETH to Validator3"); 
                }
        }
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

        (bool success, )= owner.call{value: amount}("");
        require(success, "Failed to withdraw ETH" );
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

    modifier onlyFluent(uint requestId){
        require(isFluent[msg.sender][findRequest[requestId].docLang]==true, "You are not fluent in docLang ");
        require(isFluent[msg.sender][findRequest[requestId].langNeeded]==true, "You are not fluent in langNeeded");
        _;

    }

    modifier onlyNewValidator(uint requestId){
        require(hasWorked[msg.sender][requestId]==false, "You already worked on the Request");
     _;
    }
}