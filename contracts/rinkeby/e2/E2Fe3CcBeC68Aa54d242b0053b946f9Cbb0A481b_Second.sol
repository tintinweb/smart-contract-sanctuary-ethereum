// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Second{

    address payable owner;
    string matic="MATIC";
    string usdt="USDT";
    string [] currencies=[matic, usdt ];
    uint [] languages=[1,2,3];
    uint nOfValidators;
    uint nOfTranslators;
    uint nOfMembers;
    uint nOfRequests;
    uint rewardFee=2500000000000000;
    uint timeToValidate=40; //10 MIN
    
    mapping(address=>bool) public isValidator;
    mapping(address=>bool) public isTranslator;
    mapping(address=>bool) public isMember;
    mapping(uint=>Request) public findRequest;
    mapping(uint=>bool) public isClient;
    mapping(address=> mapping(uint=>bool)) public isFluent;
    mapping(address=> mapping(uint=>bool)) public hasValidated;
    mapping(address=> mapping(uint=>bool)) public hasDenied;
    mapping(address=>Translator) public findTranslator;
    mapping(address=>Validator) public findValidator;


    struct Validator{
        address payable validator;
        uint validatorId;
        uint [] language;
        uint nOfValidations;
    }

    struct Translator{
        address payable translator;
        uint translatorId;
        uint [] language;
        uint nOfTranslations;
    }

    struct Member{
        address member;
        uint [] language;
    }

    struct Request{
        uint requestId;
        address payable client;
        address payable translator;
        uint timeFrame;
        uint amount;
        string currency;
        uint docLang;
        uint langNeeded;
        address [] pendingTranslators;
        address payable [] validatorApprovals;
        address payable [] validatorDenials;
        bool challenged;
        uint stage;

    }

        event NewLanguage(uint idLanguage, string language);
        event NewValidator(uint validatorId, address indexed validator, uint[] lang);
        event NewTranslator(uint translatorId, address indexed validator, uint[] lang);
        event NewMember(uint memberId, address indexed validator, uint[] lang);
        event NewTranslation(uint requestId, uint docLang, uint langNeeded);
        event NewPendingTranslator(uint requestId, address indexed pendTrans);
        event TranslatorApproved(uint requestId, address indexed translator);
        event TranslationSubmitted(uint requestId, uint docLang, uint langNeeded);
        event ValidatorVoted(uint requestId, uint nOfApprovals, uint nOfDenials);
        event TranslationValidated(uint requestId);
        event TranslationDenied(uint requestId);
        event TranslationChallenged(uint requestId);
        event RequestClosed(uint requestId);

    constructor() payable{
        owner=payable(msg.sender);
    }
 
    //function addCurency() public{}

    function addLanguage(string memory language) external onlyOwner{
        languages.push(languages.length);
        emit NewLanguage(languages.length, language) ;
    }

    function addValidator(address payable addr, uint[] calldata lang) external onlyOwner{
        require(isValidator[addr]==false);
        nOfValidators+=1;
        Validator memory newValidator;
        newValidator= Validator(addr, nOfValidators, lang, 0);
        isValidator[addr]=true;
        findValidator[addr]=newValidator;

        for (uint i; i<lang.length; i++){
            isFluent[addr][lang[i]]=true;
        }
        emit NewValidator(nOfValidators, addr, lang);
    }

    function addTranslator(address payable addr, uint[] calldata lang) external onlyValidator{
        require(isTranslator[addr]==false);
        nOfTranslators+=1;
        Translator memory newTranslator;
        newTranslator= Translator(addr, nOfTranslators, lang, 0);
        isTranslator[addr]=true;
        findTranslator[addr]=newTranslator;

        for (uint i; i<lang.length; i++){
            isFluent[addr][lang[i]]=true;
        }
        emit NewTranslator(nOfTranslators, addr, lang);
    }

    function becomeMember(address payable addr, uint[] calldata lang) external payable{
        require(isMember[addr]==false);
        require(msg.value==7000000000000000, "You must deposit 0.007ETH");

        nOfMembers+=1;
        Member memory newMember;
        newMember=Member(addr,lang);
        isMember[addr]=true;
        emit NewMember(nOfMembers, addr, lang);
    }

    function requestTranslation( uint timeFrame, uint currencyPlace, uint doclang, uint langNeeded) public payable{
        require(msg.value>7000000000000000, "You must deposit at least 0.007ETH");

        uint amount=msg.value;
        string memory currency=currencies[currencyPlace];
        nOfRequests+=1;
        address payable client=payable(msg.sender);
        address payable temporaryAddress;
        address [] memory pendingTrans;
        address payable [] memory nullAddress;
        //IERC20 TRANSFER

        Request memory newRequest;
        newRequest=Request(nOfRequests, client, temporaryAddress, timeFrame, amount, currency, doclang, langNeeded, pendingTrans, nullAddress, nullAddress,false, 0);
        findRequest[nOfRequests]=newRequest;
        isClient[nOfRequests]=true;
        emit NewTranslation(nOfRequests, findRequest[nOfRequests].docLang, findRequest[nOfRequests].langNeeded);
    }

    function proposeTranslation(uint requestId) public onlyTranslator onlyFluent(requestId) {
        require(findRequest[requestId].stage==0, "This function is not available");
        findRequest[requestId].pendingTranslators.push(msg.sender);
        findRequest[requestId].stage=1;
        emit NewPendingTranslator(requestId, msg.sender);
    }

    function approveTranslator(uint requestId, uint chosenTranslator) public {
        require(isClient[requestId]==true, "This is not your request");
        require(findRequest[requestId].stage==1, "This function is not available");
        findRequest[requestId].translator= payable(findRequest[requestId].pendingTranslators[chosenTranslator]);
        findRequest[requestId].stage=2;
        findRequest[requestId].timeFrame+=block.timestamp;
        emit TranslatorApproved(requestId, findRequest[requestId].translator);
    }

    function submitTranslation(uint requestId) public payable onlyTranslator {
        //Potentially  Event checker
        require(findRequest[requestId].translator==msg.sender, "This is not your request");
        require(findRequest[requestId].stage==2, "This function is not available");
        findRequest[requestId].stage=3;
        findRequest[requestId].timeFrame+=timeToValidate;

        if(findRequest[requestId].timeFrame - block.timestamp<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            emit TranslationSubmitted(requestId, findRequest[requestId].docLang, findRequest[requestId].langNeeded);
        }
    }

    function verifyTranslation(uint requestId) public onlyValidator onlyFluent(requestId) onlyNewValidator(requestId) {
        require(findRequest[requestId].stage==3, "This function is not available");
        require(findRequest[requestId].translator!=msg.sender);
        if(findRequest[requestId].timeFrame - block.timestamp<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }
        hasValidated[msg.sender][requestId]=true;
        findRequest[requestId].validatorApprovals.push(payable(msg.sender));
        emit ValidatorVoted(requestId, findRequest[requestId].validatorApprovals.length, findRequest[requestId].validatorDenials.length);

        if(findRequest[requestId].validatorApprovals.length>1){
            findRequest[requestId].stage=4;
            findRequest[requestId].timeFrame+=20; // 5 mins
            emit TranslationValidated(requestId);
        }

    }

    function denyTranslation(uint requestId) public onlyValidator onlyFluent(requestId) onlyNewValidator(requestId) {
        require(findRequest[requestId].stage==3, "This function is not available");
        hasDenied[msg.sender][requestId]=true;
        findRequest[requestId].validatorDenials.push(payable(msg.sender));

        if(findRequest[requestId].validatorDenials.length>0 ||findRequest[requestId].timeFrame - block.timestamp<0){
            findRequest[requestId].stage=5;
            rejectTranslation(requestId);
        }else{
            emit ValidatorVoted(requestId, findRequest[requestId].validatorApprovals.length, findRequest[requestId].validatorDenials.length);
        }

    }

    function challengeTranslation(uint requestId) public {
        require(isClient[requestId]=true, "You are not the client of this request");
        require(findRequest[requestId].timeFrame-block.timestamp>0, "Sorry, you can no longer challenge the request");
        require(findRequest[requestId].stage ==4);
        require(findRequest[requestId].challenged=false, "This Request was already challenged");

        findRequest[requestId].challenged=true;
        findRequest[requestId].timeFrame=block.timestamp+timeToValidate;
        findRequest[requestId].stage=3;
        emit TranslationChallenged(requestId);
    }

    function rejectTranslation(uint requestId) public payable {
         require(findRequest[requestId].stage==5);
         
        uint amount=findRequest[requestId].amount;
        (bool sent, ) = findRequest[requestId].client.call{value:amount}("");
        require(sent, "Failed to send back ETH");

        if(findRequest[requestId].validatorDenials.length>0){
            for(uint i=0; i<findRequest[requestId].validatorDenials.length; i++){
            address payable aValidator;
            aValidator=findRequest[requestId].validatorDenials[i];
            (bool sent1, ) = aValidator.call{value:rewardFee}("");
            require(sent1, "Failed to send ETH to Validator");  
            }
        }
        emit TranslationDenied(requestId);
        emit RequestClosed(requestId);
    }

    function payRequest(uint requestId) public payable {
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].timeFrame-block.timestamp<0, "The pay is not yet available");

        findRequest[requestId].stage=6;
        //IERC20 TRANSFER

        address payable validatedTranslator=findRequest[requestId].translator;
        findTranslator[validatedTranslator].nOfTranslations+=1;

        for (uint i=0; i<findRequest[requestId].validatorApprovals.length; i++){
            address payable approvedValidator=findRequest[requestId].validatorApprovals[i];

            findValidator[approvedValidator].nOfValidations+=1;
            (bool sent, ) =approvedValidator.call{value:rewardFee}("");
            require(sent, "Failed to send back ETH");
        }
        emit RequestClosed(requestId);
    }

    // function getReward() internal{

    // }

    // function checkRole() public view returns(bool){

    // }

    // function checkNotation() public view returns(bool){

    // }

    // function addFluency(uint id, uint lang) public{

    // }

    function deposit() external payable onlyOwner{}

    function withdraw(uint amount) public onlyOwner{
        require(amount<address(this).balance, "Not enough ETH");

        (bool success, )= owner.call{value: amount}("");
        require(success, "Failed to withdraw ETH" );
    }

    modifier onlyOwner() {
        require (msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier onlyValidator() {
        require(isValidator[msg.sender]==true, "You are not a Validator");
        _;
    }

    modifier onlyTranslator() {
        require(isValidator[msg.sender]==true, "You are not a Translator");
        _;
    }

    modifier onlyMember(){
        require(isMember[msg.sender]==true, "You are not a Member");
        _;
    }

    modifier onlyFluent(uint requestId){
        require(isFluent[msg.sender][findRequest[requestId].docLang]==true);
        require(isFluent[msg.sender][findRequest[requestId].langNeeded]==true);
        _;

    }

    modifier onlyNewValidator(uint requestId){
        require(hasValidated[msg.sender][requestId]==false );
        require(hasDenied[msg.sender][requestId]==false );
        _;
    }

 









}