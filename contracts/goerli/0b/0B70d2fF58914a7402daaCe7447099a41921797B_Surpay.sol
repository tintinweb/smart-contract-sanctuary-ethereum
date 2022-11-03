// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Surpay
 * @author Keegan Anglim and Alan Abed
 * @notice This contract is meant to be a demo and should not be used
 * in production
 * @notice The purpose of this contract is to facilitate an exchange
 * of survey data for funds.
 */

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Surpay__NotEnoughFunds();
error Surpay__MissingRequiredFields();
error Surpay__TransferFailed();
error Surpay__SurveyNotFound();
error Surpay__MaximumRespondantsReached();
error Surpay__NotOwner();
error Surpay__UpkeepNotNeeded();
error Surpay__SurveyAlreadyConcluded();

contract Surpay is AutomationCompatibleInterface{

    /* Type Declarations  */

    /**
     * @dev Survey will hold the survey ID as well as a mapping for each user address and response data for the survey.
     */
    struct Survey{
        
        string companyId;
        address companyAddress;
        uint256 totalPayoutAmount;
        uint256 numOfParticipantsDesired;
        uint256 numOfParticipantsFulfilled;
        string[] surveyResponseData;
        address payable[] surveyTakers;
        uint256 startTimeStamp;
        SurveyState surveyState;
    }
    /**
     * @dev The survey state was needed in an ealier version of the contract
     * @dev We are leaving it in, because a get state function is used in 
     * @dev one of our unit tests.
     */
    enum SurveyState{
        OPEN,
        COMPLETED,
        PAID
    }
    
    /* state variables  */
    /**
     * @dev s_surveys holds all survey data, with the surveyId as the key. 
     * @dev completed surveys stors the surveyIds for all completed surveys
     * @dev The surveyCreationFee is required for all new surveys.
     * @dev The surveyCreationFee is for tx fees and revenue for the service
     */
    address i_owner;
    mapping (string=>Survey) s_surveys;
    string[] private s_completedSurveys;
    uint256 private immutable i_surveyCreationFee;
    uint256 private s_feeHolder;

    /* survey variables  */
    uint256 private immutable i_interval;

    /* modifiers */
    modifier onlyOwner(){
        if (msg.sender != i_owner) revert Surpay__NotOwner();
        _;
    }

    /* constructor */
    constructor(uint256 _surveyCreationFee, uint256 _interval){
        i_owner = msg.sender;
        i_surveyCreationFee = _surveyCreationFee;
        i_interval = _interval;
    }

    /* events */
    event SurveyCreated(string indexed surveyId);
    event UserAddedToSurvey(address indexed surveyTaker);
    event SurveyCompleted(string indexed surveyId);
    event SurveyTakersPaid(string indexed surveyId);
    event FundsWithdrawn(uint256 indexed amount);
    

    /* functions */
    /**
     * @dev chainlink automation. perform upkeep fires if checkUpkeep returns
     * @dev true.
     */
    function performUpkeep(bytes calldata /* performData */) external override{
        (bool upkeepNeeded, ) = checkUpkeep("");
        // logic for what should happen if upkeepNeeded is true
        if (upkeepNeeded) {
            string[] memory completedSurveys = s_completedSurveys;
            for (uint256 i=0;i<completedSurveys.length;i++){
            distributeFundsFromCompletedSurvey(i);
            emit SurveyTakersPaid(completedSurveys[i]);
        } 
        } else {
            revert Surpay__UpkeepNotNeeded();
        }
    }
    /**
     * @dev Returns true only if there are any complete surveys.
     */
    function checkUpkeep(bytes memory /* checkData */) public returns (bool upkeepNeeded, bytes memory /* performData */){
        // conditions for automation to be performed
        if (s_completedSurveys.length > 0){
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
    }
    /**
     * @dev A survey can be created by anyone, but it must be called
     * @dev with both the total payout amount and the survey creation
     * @dev fee. The current fee is 0.01 ETH. 
     */
    function createSurvey(
        string memory _surveyId,
        string memory _companyId, 
        uint256 _totalPayoutAmount, 
        uint256 _numOfParticipantsDesired
        ) public payable {
            if (msg.value < i_surveyCreationFee + _totalPayoutAmount){
                revert Surpay__NotEnoughFunds();
            }

            s_feeHolder += i_surveyCreationFee;
  
            Survey memory newSurvey;
            newSurvey.companyId = _companyId;
            newSurvey.companyAddress = msg.sender;
            newSurvey.totalPayoutAmount = _totalPayoutAmount;
            newSurvey.numOfParticipantsDesired = _numOfParticipantsDesired;
            newSurvey.startTimeStamp = block.timestamp;
            newSurvey.surveyState = SurveyState.OPEN;
            
            s_surveys[_surveyId] = newSurvey;
            emit SurveyCreated(_surveyId);
    }
    /**
     * @notice Function can only be called by the contract owner.
     * @notice This was neccissary to ensure that the user data was
     * @notice a valid response to the survey.
     * 
     * @dev The SurveyCompleted event is the event listener
     */
    function sendUserSurveyData(string memory _surveyId, string memory _surveyData, address userAddress) public onlyOwner {
        
        if (s_surveys[_surveyId].numOfParticipantsDesired > s_surveys[_surveyId].numOfParticipantsFulfilled) {
            // store the user address, store survey data in Survey object
            s_surveys[_surveyId].surveyResponseData.push(_surveyData);
            s_surveys[_surveyId].surveyTakers.push(payable(userAddress));
            s_surveys[_surveyId].numOfParticipantsFulfilled++;
            // if number of participants is equal to the number of participants desired, change the survey state to COMPLETED. Add to completedSurveys array. 
            if (s_surveys[_surveyId].numOfParticipantsDesired == s_surveys[_surveyId].numOfParticipantsFulfilled) {
                s_surveys[_surveyId].surveyState = SurveyState.COMPLETED;
                s_completedSurveys.push(_surveyId);
                // event listener
                emit SurveyCompleted(_surveyId);
            }

            emit UserAddedToSurvey(userAddress);
            

        } else {
            revert Surpay__MaximumRespondantsReached();
        }
    }
    
    /**
     * @dev The index of s_completeSurveys is passed in from performUpkeep().
     */
    function distributeFundsFromCompletedSurvey(uint256 index) public {

        // copy state variable to local varable for payout iteration
        string[] memory completedSurveys = s_completedSurveys;

        // revert if the survey has already been paid out.
        if (s_surveys[completedSurveys[index]].surveyState == SurveyState.PAID){
            revert Surpay__SurveyAlreadyConcluded();
        }

        // total payout amount is divided between the number of participants
        uint256 ethToPay;
        
        ethToPay = s_surveys[completedSurveys[index]].totalPayoutAmount / s_surveys[completedSurveys[index]].numOfParticipantsFulfilled;        
        // loop through all user addresses and in the survey struct, and payout the totalPayoutAmount equally
        for(uint256 i=0;i<s_surveys[completedSurveys[index]].surveyTakers.length;i++){
            if (ethToPay < address(this).balance){
                (bool success, ) = s_surveys[completedSurveys[index]].surveyTakers[i].call{value: ethToPay}("");
                if (!success){
                    revert Surpay__TransferFailed();
                }
            }
        }
        s_surveys[completedSurveys[index]].surveyState = SurveyState.PAID;
        
    }
    /**
     * @dev allows owner to withdraw no more than the survey creation fees.
     */
    function withdrawFromFeeHolder(uint256 amount) public onlyOwner {
        if (amount > s_feeHolder){
            revert Surpay__NotEnoughFunds();
        } else {
            (bool success, ) = i_owner.call{value: amount}("");
            if (success){
                s_feeHolder -= amount;
                emit FundsWithdrawn(amount);
            } else {
                revert Surpay__TransferFailed();
            }
        }
    }
    /**
     * Allows the owner to perform a clean up of any completed surveys
     */
    function removeCompletedSurveys() public onlyOwner {
        string[] memory completedSurveys = s_completedSurveys;
        for(uint256 i=0;i<completedSurveys.length;i++){
            delete(s_surveys[completedSurveys[i]]);
        }
    }

    /* view/pure functions  */

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getSurveyState(string memory _surveyId) public view returns(SurveyState){
        if (s_surveys[_surveyId].numOfParticipantsDesired > 0){
            return s_surveys[_surveyId].surveyState;
        } else {
            revert Surpay__SurveyNotFound();
        }
        
    }

    function getFeeHolderAmount() public view returns(uint256){
        return s_feeHolder;
    }

    function getSurveyCreationFee() public view returns(uint256) {
        return i_surveyCreationFee;
    }

    function getInterval() public view returns(uint256) {
        return i_interval;
    }

    function getCompanyId(string memory surveyId) public view returns(string memory){
        return s_surveys[surveyId].companyId;
    }

    function getSurveyPayoutAmount(string memory _surveyId) public view returns(uint256){
        if (s_surveys[_surveyId].numOfParticipantsDesired > 0){
            return s_surveys[_surveyId].totalPayoutAmount;
        } else {
            revert Surpay__SurveyNotFound();
        }
    }

    function getSurveyTaker(string memory surveyId, uint256 userIndex) public view returns(address){
        // add the address of a survey taker
        if (s_surveys[surveyId].numOfParticipantsDesired > 0){
            return s_surveys[surveyId].surveyTakers[userIndex];
        } else {
            revert Surpay__SurveyNotFound();
        }
        
    }
    
    function getAllSurveyResponseData(string memory surveyId) public view returns(string[] memory){
        if (s_surveys[surveyId].numOfParticipantsDesired > 0){
            return  s_surveys[surveyId].surveyResponseData;
        } else {
            revert Surpay__SurveyNotFound();
        }
    }

    function getSurveyResponseData(string memory surveyId, uint256 responseIndex) public view returns(string memory){
        if (s_surveys[surveyId].numOfParticipantsDesired > 0){
            return s_surveys[surveyId].surveyResponseData[responseIndex];
        } else {
            revert Surpay__SurveyNotFound();
        }
        
    }

    function getLastTimeStamp(string memory surveyId) public view returns(uint256){
        if (s_surveys[surveyId].numOfParticipantsDesired > 0){
            return s_surveys[surveyId].startTimeStamp;
        } else {
            revert Surpay__SurveyNotFound();
        }
    }

    function getPayoutPerPersonBySurveyId(string memory surveyId) public view returns(uint256){
        if (s_surveys[surveyId].numOfParticipantsDesired > 0){
            return s_surveys[surveyId].totalPayoutAmount / s_surveys[surveyId].numOfParticipantsDesired;
        } else {
            revert Surpay__SurveyNotFound();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}