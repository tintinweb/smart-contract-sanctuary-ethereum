/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Bold Predictions
 * @author sonke.eth
 * @dev Everyone can put a bold prediction here, and optionally bet some value on it. Everyone can bet on existing predictions (if still open for new bets)
 */
contract BoldPredictions {

    enum PredictionStatus { open, succeeded, failed, inconclusive }
    enum SubmissionSummary { none, succeeded, failed, inconclusive, disputed }

    address private admin; // special rights - changing preferences and resolving disputes
    string deploymentNote; // A short text about this deployment  
    uint16 objectionPeriodDays; // how many days need to be waited from last outcomeSubmission until the reward can be claimed
    uint8 facilitationFeePercentage; // how much in percentage is kept by this contract
    bool newPredictionsAllowed; // Wheter it is possible to create new predictions
    uint accruedFeesToHarvest; // Sum of earned fees that can be harvested by admin

    struct Bet { // either initial bet of the creator of the prediction or additional bet from any one
        address sender; // sender address - msg.sender
        uint timestamp;   // timestamp of submission of bet - block.timestamp
        uint amount; // The amount he has put in - msg.value
        bool predictedOutcome; // true: he agrees with predition, false: disagrees        
    }
    struct BetSummary { // A summarized info of all bets of one address on one prediction
        bool betCount; // The number of bets from this address
        bool betOutcome; // true: he agrees with predition, false: disagrees  
        uint betAmount; // The total amount set on that bet from this address
    }
    struct OutcomeSubmission { // A statement on the actual outcome of the bet (trur or false)
        address sender; // sender address - msg.sender
        uint timestamp;   // timestamp of submission of outcome - block.timestamp
        PredictionStatus submittedOutcome; // may NOT be "open"       
    }
    struct Prediction {
        address creator; // sender address - msg.sender
        uint timestamp;   // timestamp of submission of outcome - block.timestamp
        uint noBetsAfter;   // timestamp of cut-off for new bets. Set to 0 if it should not be possible to place bets anymore
        uint16 predictionId; // Id of the prediction
        bool hadDisputeResolution; // whether this was resolved by admin
        string predictionText; // a textual description of the prediction      
        PredictionStatus predictionOutcome; // the status of the prediction
        Bet[] bets; // array of all bets for this prediction
        OutcomeSubmission[] outcomeSubmissions; // array of all submitted outcomes
        address[] payoutLog; // Array of addresses that got a payout
        uint accruedFees; // Sum of fees accrued (calculated as the payouts are done)
    }

    Prediction[] predictions; // array of all created predictions



    // event for EVM logging
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event PredictionCreated(uint16 indexed predictionId);
    event OutcomeSubmitted(uint16 indexed predictionId, PredictionStatus submittedOutcome, bool isDisputed);
    event PredictionResultDetermined(uint16 indexed predictionId, PredictionStatus result, bool hadDisputeResolution);

    // modifier to check if caller is admin of this contract
    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not admin of this contract");
        _;
    }

    // modifier to check if caller is creator of this prediction
    modifier isCreator(uint16 _predictionId) {
        require(predictions[_predictionId].creator == admin, "Caller is not creator of this prediction");
        _;
    }

    // modifier to check if prediction exists
    modifier validPredictionId(uint16 _predictionId) {
        require(_predictionId < predictions.length, "No prediction with this predictionId");
        _;
    }

    /**
     * @dev Set contract deployer as admin and set default values
     */
    constructor(uint16 _objectionPeriodDays, uint8 _facilitationFeePercentage, string memory _deploymentNote) {
        admin = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit AdminSet(address(0), admin);
        objectionPeriodDays = _objectionPeriodDays; 
        require(_facilitationFeePercentage <= 100, "facilitationFeePercentage must be equal or lower 100");
        facilitationFeePercentage = _facilitationFeePercentage;
        deploymentNote = _deploymentNote;
        newPredictionsAllowed = true;
        accruedFeesToHarvest = 0;
    }
    /**
     * @dev Set admin to another address
     */
    function changeAdmin(address _newAdmin) public isAdmin() {
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminSet(oldAdmin, admin);
    }
    /**
     * @dev Change objection period - in days
     */
    function changeobjectionPeriodDays(uint16 _objectionPeriodDays) public isAdmin() {
        objectionPeriodDays = _objectionPeriodDays; 
    }

    /**
     * @dev Change facilitation fee percentage
     */
    function changeFacilitationFeePercentage(uint8 _facilitationFeePercentage) public isAdmin() {
        facilitationFeePercentage = _facilitationFeePercentage; 
    }

    /**
     * @dev Set whether creation of new predictions is allowed
     */
    function setNewPredictionsAllowed(bool _newPredictionsAllowed) public isAdmin() {
        newPredictionsAllowed = _newPredictionsAllowed; 
    }

    /**
     * @dev Transfers all accrued fees of completed transactions to the _destination address up to _maxAmount
     */
    function harvestFees(address _destination, uint _maxAmount) public isAdmin() {
        require(accruedFeesToHarvest > 0, "No fees left to be harvested");
        if(accruedFeesToHarvest <= _maxAmount){
            payable(_destination).transfer(accruedFeesToHarvest);
            accruedFeesToHarvest = 0;
        }
        else{
            payable(_destination).transfer(_maxAmount);
            accruedFeesToHarvest -= _maxAmount;
        }
    }

    /**
     * @dev Creates a new prediction and gives creator special rights
     * @param _predictionText - The prediction as human-readable text. Please be as concise as possible
     * @param _noBetsAfter - The unix timestamp of the deadline for submitting bets on this prediction
     * @return predictionId - id of newly created prediction
     */
    function createPrediction(string calldata _predictionText, uint _noBetsAfter) public payable returns (uint16 predictionId) {
        require(bytes(_predictionText).length > 20, "Please enter more elaborat preditionText (>20 chars)");
        require(predictions.length < 65535, "Wow, we got way too many predictions, man!");
        predictions.push();
        uint16 pId = uint16(predictions.length - 1);
        predictions[pId].creator = msg.sender;
        predictions[pId].timestamp = block.timestamp;
        predictions[pId].noBetsAfter = _noBetsAfter;
        predictions[pId].predictionId = pId;
        predictions[pId].hadDisputeResolution = false;
        predictions[pId].predictionText = _predictionText;
        predictions[pId].predictionOutcome = PredictionStatus.open;
        predictions[pId].accruedFees = 0;
        predictions[pId].bets.push();
        predictions[pId].bets[0] = Bet({
                sender: msg.sender,
                timestamp: block.timestamp,
                amount: msg.value,
                predictedOutcome: true
            });

        emit PredictionCreated(pId);
        return pId;
    }

    /**
     * @dev Sets the timestamp of the cut-off time for new bets - set to 0 to disable bets
     */
    function setNoBetsAfter(uint16 _predictionId, uint _noBetsAfter) public isCreator(_predictionId) validPredictionId(_predictionId) {
        predictions[_predictionId].noBetsAfter = _noBetsAfter;
    }


    /**
     * @dev Enables anyone to put a bet on the prediction
     */
    function putBet(uint16 _predictionId, bool _outcome) validPredictionId(_predictionId) public payable {
        // Check if still allowed to put bet
        require(block.timestamp < predictions[_predictionId].noBetsAfter, "Sorry, not possible to put new bets on this prediction anymore");
        
        // Make sure no outcome has already been submitted
        require(predictions[_predictionId].outcomeSubmissions.length == 0, "Sorry, not possible to put new bets: One or more outcomes already submitted");

        // Make sure the minimum bet value requirements are met
        uint forAmount;
        uint againstAmount;
        (forAmount, againstAmount) = getTotalBetAmounts(_predictionId);
        if(_outcome && againstAmount > forAmount){
            require(msg.value > againstAmount - forAmount, "Your bet amount needs to at least equal out the difference between for and against amounts");
        }
        if(!_outcome && againstAmount < forAmount){
            require(msg.value > forAmount - againstAmount, "Your bet amount needs to at least equal out the difference between for and against amounts");
        }

        // Check if this better has been betting on another side before (not allowed)
        uint16 betCount = 0;
        bool prevOutcome = false;
        uint prevAmount = 0;
        (betCount, prevOutcome, prevAmount) = getBetOfAddress(_predictionId, msg.sender);
        if(betCount > 0){
            require(prevOutcome == _outcome, "You need to bet on the same outcome as before");
        }

        // Accept and register bet
        predictions[_predictionId].bets.push(Bet({
                sender: msg.sender,
                timestamp: block.timestamp,
                amount: msg.value,
                predictedOutcome: _outcome
            }));
    }



    /**
     * @dev Calculates the amount of eth bet for and against the prediction
     */
    function getTotalBetAmounts(uint16 _predictionId) public view  validPredictionId(_predictionId) returns (uint forAmount, uint againstAmount){
        forAmount = 0;
        againstAmount = 0;
        for(uint i = 0; i < predictions[_predictionId].bets.length; i++){
            if(predictions[_predictionId].bets[i].predictedOutcome)
                forAmount += predictions[_predictionId].bets[i].amount;
            else
                againstAmount += predictions[_predictionId].bets[i].amount;
        }
        return (forAmount, againstAmount);
    }    

    /**
     * @dev Returns what outcome the given address has bet on and calculates the amount of eth bet on this outcome 
     */
    function getBetOfAddress(uint16 _predictionId, address _better) public view  validPredictionId(_predictionId) returns (uint16 betCount, bool outcome, uint amount){
        betCount = 0;
        outcome = false;
        amount = 0;
        for(uint i = 0; i < predictions[_predictionId].bets.length; i++){
            if(predictions[_predictionId].bets[i].sender == _better){
                betCount++;
                outcome = predictions[_predictionId].bets[i].predictedOutcome;
                amount += predictions[_predictionId].bets[i].amount;
            }
        }
        return (betCount, outcome, amount);
    }    

    /**
     * @dev Submit the actual outcome of a prediction 
     */
    function submitOutcome(uint16 _predictionId, PredictionStatus _outcome) public  validPredictionId(_predictionId) {
            require(_outcome != PredictionStatus.open, "Outcome can only be succeeded, failed or inconclusive");
            require(predictions[_predictionId].predictionOutcome == PredictionStatus.open, "Cannot accept new submission as predictionStatus is no longer open");

            // Register outcome
            predictions[_predictionId].outcomeSubmissions.push(OutcomeSubmission({
                    sender: msg.sender,
                    timestamp: block.timestamp,
                    submittedOutcome: _outcome
            }));

            // Emit event if this is the first submission 
            if(predictions[_predictionId].outcomeSubmissions.length == 1)
                emit OutcomeSubmitted(_predictionId, _outcome, false);
            else{
                // Check if this is disputed, if yes, emit event
                if(getSubmittedOutcomeSummary(_predictionId) == SubmissionSummary.disputed)
                    emit OutcomeSubmitted(_predictionId, _outcome, true);
            }
            
    }    

    /**
     * @dev Summarizes the submitted outcomes
     */
    function getSubmittedOutcomeSummary(uint16 _predictionId) public view  validPredictionId(_predictionId) returns (SubmissionSummary summary){
        bool submittedStatusSucceeded = false;
        bool submittedStatusFailed = false;
        bool submittedStatusInconclusive = false;
        for(uint i = 0; i < predictions[_predictionId].outcomeSubmissions.length; i++){
            if(predictions[_predictionId].outcomeSubmissions[i].submittedOutcome == PredictionStatus.succeeded)
                submittedStatusSucceeded = true;
            else if(predictions[_predictionId].outcomeSubmissions[i].submittedOutcome == PredictionStatus.failed)
                submittedStatusFailed = true;
            else if(predictions[_predictionId].outcomeSubmissions[i].submittedOutcome == PredictionStatus.inconclusive)
                submittedStatusInconclusive = true;
        }
        if(!submittedStatusSucceeded && !submittedStatusFailed && !submittedStatusInconclusive)
            return SubmissionSummary.none;
        if(submittedStatusSucceeded && !submittedStatusFailed && !submittedStatusInconclusive)
            return SubmissionSummary.succeeded;
        if(!submittedStatusSucceeded && submittedStatusFailed && !submittedStatusInconclusive)
            return SubmissionSummary.failed;
        if(!submittedStatusSucceeded && !submittedStatusFailed && submittedStatusInconclusive)
            return SubmissionSummary.inconclusive;

        return SubmissionSummary.disputed;
    }    


    /**
     * @dev Resolve a dispute
     */
    function resolveDispute(uint16 _predictionId, PredictionStatus _outcome) public isAdmin() validPredictionId(_predictionId) {
        require(getSubmittedOutcomeSummary(_predictionId) == SubmissionSummary.disputed, "No dispute found");

        // Update status
        predictions[_predictionId].predictionOutcome = _outcome;
        predictions[_predictionId].hadDisputeResolution = true;

        emit PredictionResultDetermined(_predictionId, _outcome, true);
    }    

    /**
     * @dev Claiming a reward - only possible if the calling address has participated and either won, or the outcome was inconclusive
     */
    function claimReward(uint16 _predictionId, address _destination) public validPredictionId(_predictionId) {
        // Check if outcome is still open - if yes, we need to check if we can set the outcome now
        if(predictions[_predictionId].predictionOutcome == PredictionStatus.open){

            SubmissionSummary summary = getSubmittedOutcomeSummary(_predictionId);
            // Check, if submitted outcomes would make pay out possible
            require(summary != SubmissionSummary.disputed, "Cannot pay out as outcome is disputed. Please ask admin to resolve dispute.");
            require(summary != SubmissionSummary.none, "Cannot pay out as no outcome was submitted yet. Please first submit the outcome and wait fot the objection period to pass");

            // Check if the objection period has already passed
            require(block.timestamp > predictions[_predictionId].outcomeSubmissions[0].timestamp + (uint(objectionPeriodDays) * 24 * 3600) , "Cannot pay out as objection period has not passed yet");

            PredictionStatus outcome = PredictionStatus.inconclusive;
            if(summary == SubmissionSummary.succeeded)
                outcome = PredictionStatus.succeeded;
            if(summary == SubmissionSummary.failed)
                outcome = PredictionStatus.failed;

            predictions[_predictionId].predictionOutcome = outcome;

        }
        
        // Start pay out process
        uint payout;
        uint fee;
        (payout, fee) = calculateReturn(_predictionId, msg.sender);
        require(payout > 0, "Nothing to pay out");

        // Check if this address already has got its pay out
        for(uint i = 0; i < predictions[_predictionId].payoutLog.length; i++){
            require(predictions[_predictionId].payoutLog[i] != msg.sender, "Your payout has already been done");
        }
        // Add fee to accruedFees
        predictions[_predictionId].accruedFees += fee;
        accruedFeesToHarvest += fee;

        // Mark sender as paid out
        predictions[_predictionId].payoutLog.push(msg.sender);

        // Pay out!
        payable(_destination).transfer(payout);

    }    


    /**
     * @dev Calculates the amount that a betting party has won
     */
    function calculateReturn(uint16 _predictionId, address party) public view  validPredictionId(_predictionId) returns (uint payout, uint fee){
        // Check if this address has bet on the right outcome
        BetSummary memory bSum;
        {
            uint16 betCount;
            bool betOutcome;
            uint betAmount;
            (betCount, betOutcome, betAmount) = getBetOfAddress(_predictionId, party);
            require(betCount > 0, "No bet found for this address");
            bSum.betOutcome = betOutcome;
            bSum.betAmount = betAmount;
        }

        // Check if this person has won
        if(predictions[_predictionId].predictionOutcome == PredictionStatus.succeeded && bSum.betOutcome == true){
            uint forAmount;
            uint againstAmount;
            (forAmount, againstAmount) = getTotalBetAmounts(_predictionId);

            uint shareOfOtherBets;
            // Special case: If no one winning has put money on the table
            if(forAmount == 0){
                // Pay out everything to the creator of the prediction
                if(msg.sender == predictions[_predictionId].creator)
                    shareOfOtherBets = againstAmount;
                else
                    shareOfOtherBets = 0;
            }
            else 
                shareOfOtherBets = againstAmount * bSum.betAmount / forAmount;
            uint rBeforeFee = bSum.betAmount + shareOfOtherBets;
            payout = (rBeforeFee * 100 - rBeforeFee * facilitationFeePercentage) / 100;
            fee = rBeforeFee - payout;
            return (payout, fee);
        }
        if(predictions[_predictionId].predictionOutcome == PredictionStatus.failed && bSum.betOutcome == false){
            uint forAmount;
            uint againstAmount;
            (forAmount, againstAmount) = getTotalBetAmounts(_predictionId);
            uint shareOfOtherBets;
            // Special case: If no one winning has put money on the table
            if(againstAmount == 0){
                // Share equally between all addresses that bet against

                // Count addresses that bet against
                uint addrCount = 0;
                address[] memory addrList = new address[](predictions[_predictionId].bets.length);
                for(uint i = 0; i < predictions[_predictionId].bets.length; i++){
                    if(!predictions[_predictionId].bets[i].predictedOutcome && !arrayContains(addrList, predictions[_predictionId].bets[i].sender)){ // new address
                            addrList[addrCount] = predictions[_predictionId].bets[i].sender;
                            addrCount++;
                    }
                }
                shareOfOtherBets = forAmount * 1 / addrCount;
            }
            else 
                shareOfOtherBets = forAmount * bSum.betAmount / againstAmount;
            uint rBeforeFee = bSum.betAmount + shareOfOtherBets;
            payout = (rBeforeFee * 100 - rBeforeFee * facilitationFeePercentage) / 100;
            fee = rBeforeFee - payout;
            return (payout, fee);
        }
        if(predictions[_predictionId].predictionOutcome == PredictionStatus.inconclusive){
            // Everybody just gets back his share minus the facilitation fee
            uint rBeforeFee = bSum.betAmount;
            payout = (rBeforeFee * 100 - rBeforeFee * facilitationFeePercentage) / 100;
            fee = rBeforeFee - payout;
            return (payout, fee);
        }


    }    
    function arrayContains(address[] memory _array, address _search) private pure returns (bool) {
        for(uint i = 0; i < _array.length; i++){
            if(_array[i] == _search)
                return true;
        }
        return false;
    }

}