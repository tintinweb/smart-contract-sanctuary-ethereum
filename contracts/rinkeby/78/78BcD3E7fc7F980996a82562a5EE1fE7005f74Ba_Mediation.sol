//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*
*This will be removed and the contract will inherit the mediator.sol
*We can still use the interface method if we want to deploy more than one contract
*/
interface IMediator {
    function getAllMediators() external view returns(address[] memory);
    function minusCaseCount(uint _id) external returns(bool);
    function addCaseCount(uint _id) external returns(bool);
}

contract Mediation is VRFConsumerBaseV2, Ownable {
    IMediator immutable i_Mediator;
    VRFCoordinatorV2Interface immutable i_COORDINATOR;
    //Rinkeby coordinator, These test values are coming from https://docs.chain.link/docs/vrf-contracts/#configurations
    address constant c_vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    //subscription id, gotten from when you subscribe for LINK
    uint64 immutable i_subscriptionId;  //Subscription ID 4857
    bytes32 constant c_keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 constant c_callbackGasLimit = 100000;    
    uint16 constant c_requestConfirmations = 3;
    uint32 constant c_numWords =  1;
    uint256 public requestCounter;


    struct Case {
        uint256 caseId;
        address payable firstParty;
        address payable secondParty;
        address payable mediator;
        string tokenURI;
        bool caseClosed;
        uint256 caseCreatedAt;
        uint256 numberOfSession;
        bool sessionStarted;
    }
    uint256 public nextCaseId;

    /*
    *  Number of default sessions that users have to pay upfront when creating a case,
    *  If they don't use the number of sessions, they will be refunded part of the funds
    */
    
    uint256 constant defaultNumberOfSessions = 3; 

    struct BookedSession {
        uint256 caseId;
        address firstParty;
        address secondParty;
        address payable mediator;
        address[] firstPartyMembers;
        address[] secondPartyMembers;
        bool bookedSessionClosed;
        bool bookedSessionStarted;
        uint256 bookedSessionCreatedAt;
    }


    /*
    * WE MAY NEED CHAINLINK DATA FEED TO GET THE CURRENT PRICE OF ETH AND KNOW WHAT TO PRICE USERS
    */
    uint256 mediatorPrice = 0.001 ether;

    mapping(uint256 => uint256) private ethBalances;//This container keep tracks of the amount eth for each case
    mapping(uint256 => Case) public cases; //Holds all the information for a particular case id
    mapping(uint256 => BookedSession) public bookedSessions; //Holds all the information for a particular case id
    mapping(uint256 => bool) public sessionStarted; //Checks if a case id session has been started
    mapping(uint256 => bool) public paymentAccepted; //Checks if payment has been accepted for a case id

    mapping(uint256 => address[]) public firstPartyMembers; //Array of addresses of all the party one members
    mapping(uint256 => address[]) public secondPartyMembers; //Array of addresses of all the party two members

    mapping(uint256 => uint256) private acceptedByFirstParty; //The number of party one members who accepted to pay for a particular case session
    mapping(uint256 => uint256) private acceptedBySecondparty; //The number of party two members who accepted to pay for a particular case session
    mapping(uint256 => bool) private doesCaseExist;


    mapping(uint256 => uint256) s_requestIdToRequestIndex; //used for 
    mapping(uint256 => uint256) public s_requestIndexToRandomWords; //mapping of caseID to associated random number that was generated

    
    //Events
    event case_Created(
        uint256 _caseId, 
        address firstParty,
        address secondParty,
        address mediator,
        string tokenUri,
        bool caseClosed,
        uint256 caseCreatedAt,
        uint256 numberOfSession,
        bool sessionStarted);

    event case_SecondPartyJoint(uint256 _caseId);
    event case_Completed(uint256 _caseId, address[] _winner);
    event case_JoinedCase(uint256 _caseId, uint256 _party, address _address);
    event BookedSessionCreated(uint256 _caseId);
    event JoinedBookedSession(uint256 _caseId);
    event AssignMediator(uint256 _caseId, address _mediator);


    //Custom errors
    error Mediation__PartyDoesNotExist();
    error Mediation__CaseDoesNotExistOrCaseIsClosed();
    error Mediation__OnlyMediatorCanDoThis();
    error Mediation__SessionAlredyStarted();
    error Mediation__ExceededDefaultNumberOfSessions();
    error Mediation__CannotReceivePaymentPartiesNeedToApprove();
    error Mediation__FailedToSendPayment();
    error Mediation__FailedToWithdrawFunds();
    error Mediation__NotEnoughFundsInContract();
    error Mediation__YouAreNotPartOfThisSession();
    error Mediation__BookedSessionAlreadyStarted();
    error Mediation__BookedSessionIsStillclosed();
    error Mediation__FailedToRefundFundsToParty1();
    error Mediation__FailedToRefundFundsToParty2();


    constructor(uint64 subscriptionId, address _mediator) VRFConsumerBaseV2(c_vrfCoordinator) {
        i_COORDINATOR = VRFCoordinatorV2Interface(c_vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_Mediator = IMediator(_mediator);
    }

    //discuss, if two users are calling this function at the same time, what will happened with the Id
    
    /*
    * One of the parties involved will create a case specifying the category of the case
    * From the category, we will be able to get a mediator 
    * User will pay eth with respect to the fee of the mediator for the numberOfSessions
    */
    function createCase() external payable payHalfFeeForDefaultNumSession(defaultNumberOfSessions){
        ethBalances[nextCaseId] += msg.value;
        nextCaseId++;
        _requestRandomWords();
        
        cases[nextCaseId] = Case({
            caseId: nextCaseId,
            firstParty: payable(msg.sender),
            secondParty: payable(address(0)),
            mediator: payable(address(0)),
            tokenURI: "tokenuri",
            caseClosed: true,
            caseCreatedAt: block.timestamp,
            numberOfSession: 0,
            sessionStarted: false
        });

        doesCaseExist[nextCaseId] = true;

        emit case_Created(nextCaseId,
        cases[nextCaseId].firstParty,
        cases[nextCaseId].secondParty,
        cases[nextCaseId].mediator,
        cases[nextCaseId].tokenURI,
        cases[nextCaseId].caseClosed,
        cases[nextCaseId].caseCreatedAt,
        cases[nextCaseId].numberOfSession,
        cases[nextCaseId].sessionStarted);
    }

    /*
    * Company starts a case and pay for the two parties, 
    * They then assign a mediator and he starts the sessions
    */
    function companyCreateCase(address payable _firstParty, address payable _secondParty) 
        external payable payFullFeeForDefaultNumSession(defaultNumberOfSessions){
            nextCaseId++;
            ethBalances[nextCaseId] += msg.value;
            
            cases[nextCaseId] = Case({
                caseId: nextCaseId,
                firstParty: _firstParty,
                secondParty: _secondParty,
                mediator: payable(address(0)),
                tokenURI: "tokenuri",
                caseClosed: false,
                caseCreatedAt: block.timestamp,
                numberOfSession: 0,
                sessionStarted: false
            });

            doesCaseExist[nextCaseId] = true;
             _requestRandomWords(); //random number


            emit case_Created(
            nextCaseId,
            cases[nextCaseId].firstParty,
            cases[nextCaseId].secondParty,
            cases[nextCaseId].mediator,
            cases[nextCaseId].tokenURI,
            cases[nextCaseId].caseClosed,
            cases[nextCaseId].caseCreatedAt,
            cases[nextCaseId].numberOfSession,
            cases[nextCaseId].sessionStarted);
    }

    /*
    * This calls the mediator contracts and get a random winner
    * The selected mediator is then added to the case
    */
    function assignMediator(uint256 _caseId) external {
        address[] memory mediators = i_Mediator.getAllMediators();
        uint256 selectedMediatorIndex = s_requestIndexToRandomWords[_caseId];
        require(
            i_Mediator.addCaseCount(selectedMediatorIndex),
            "error updating caseCount"
        );
        address selectedMediator = mediators[selectedMediatorIndex];
        cases[_caseId].mediator = payable(selectedMediator);
        emit AssignMediator(_caseId, selectedMediator);
    }

    /*
    * The other party has to join the case before mediator will be able to start a session
    * When joining, he has to specify the case that he is joining and pay the fee accordingly
    */
    function joinCaseAsSecondParty(uint256 _caseId) external payable payHalfFeeForDefaultNumSession(defaultNumberOfSessions){
        if(!doesCaseExist[_caseId]) {
            revert Mediation__CaseDoesNotExistOrCaseIsClosed();
        }
        ethBalances[_caseId] += msg.value;
        cases[_caseId].secondParty = payable(msg.sender);
        cases[_caseId].caseClosed = false;

        emit case_SecondPartyJoint(_caseId);
    }

    /*
    * This method, other party members can join the case. 
    * When joining the case, they specify the case id and the party that they are joining
    */
    function joinCase(uint256 _caseId, uint256 _party) external {
        if(_party != 1 && _party != 2) {
            revert Mediation__PartyDoesNotExist();
        }
        if(cases[_caseId].caseClosed){
            revert Mediation__CaseDoesNotExistOrCaseIsClosed();
        }

        if(_party == 1) {
            firstPartyMembers[_caseId].push(msg.sender);
        }
        else {
            secondPartyMembers[_caseId].push(msg.sender);
        }

        emit case_JoinedCase(_caseId, _party, msg.sender);
    }

    function getFirstPartyMembers(uint256 _caseId) external view returns(address[] memory) {
        return firstPartyMembers[_caseId];
    } 

    function getSecondPartyMembers(uint256 _caseId) external view returns(address[] memory) {
        return secondPartyMembers[_caseId];
    } 

    //we should have a message feedback on the front end for parties to rate and comment on mediator, providing their addresses.
    // we should be able to remove a mediator from the mediator contract

    /*
    * Only the mediator should be able to start a session by providing the case id.
    * If the session of that case has already been started then the mediator should not be able to start it again
    * If the case is closed, then the mediator can not start the session
    * IF the number of sessions is more that the number they have paid for, then the mediator won't be able to start a session
    */
    function startSession(uint256 _caseId) external onlyMediator(_caseId) {
        if(cases[_caseId].sessionStarted) {
            revert Mediation__SessionAlredyStarted();
        }
        if(cases[_caseId].caseClosed) {
            revert Mediation__CaseDoesNotExistOrCaseIsClosed();
        }
        if(cases[_caseId].numberOfSession > defaultNumberOfSessions) {
            revert Mediation__ExceededDefaultNumberOfSessions();
        }

        cases[_caseId].sessionStarted = true;
        cases[_caseId].numberOfSession += 1;
    }


    //LETS DISCUSS MORE ON THIS FEATURE

    /*
    * Both parties involved, have to accept to pay the mediator before the mediator can get paid when he ends the session
    */
    function acceptPayment(uint256 _caseId) external {
        if(cases[_caseId].firstParty == msg.sender) {
            acceptedByFirstParty[_caseId] = 1;
        }

        if(cases[_caseId].secondParty == msg.sender){
            acceptedBySecondparty[_caseId] = 1;
        }

        if((acceptedByFirstParty[_caseId] + acceptedBySecondparty[_caseId]) == 2){
            paymentAccepted[_caseId] = true;
        }else{
            paymentAccepted[_caseId] = false;
        }
    }

    /*
    * ON THE UI, WE WILL LET THE MEDIATORS KNOW THAT THEY ARE GETTING 90% OF THE PAY
    */

    /*
    * Only the Mediator can end a session, 
    * Payment must be accepted by the parties, after ending the sessions the mediator receive his/her payment
    */
    function endSession(uint256 _caseId) external onlyMediator(_caseId) receivePayment(_caseId) {
        if(!paymentAccepted[_caseId]){
            revert Mediation__CannotReceivePaymentPartiesNeedToApprove();
        }
        paymentAccepted[_caseId] = false;
        cases[_caseId].sessionStarted = false;
    }

    /*
    * Mediator can end a session without receiving payment, 
    */
    function endSessionWithoutPay(uint256 _caseId) external onlyMediator(_caseId) {
        cases[_caseId].sessionStarted = false;
        cases[_caseId].numberOfSession -= 1;
    }

    /*
    * Once the number of default sessions has been reached but the parties still need more session,
    * They will book for a session and the first party creates the booking and pay for it according
    */
    function createBookedSession(uint256 _caseId) external payable payHalfFeeForDefaultNumSession(1){
        if(cases[_caseId].firstParty != msg.sender) {
            revert Mediation__YouAreNotPartOfThisSession();
        }
        ethBalances[_caseId] = 0;
        ethBalances[_caseId] += msg.value;

        bookedSessions[_caseId] = BookedSession(
            _caseId,
            cases[_caseId].firstParty,
            cases[_caseId].secondParty,
            cases[_caseId].mediator,
            firstPartyMembers[_caseId],
            secondPartyMembers[_caseId],
            true, //bookedSessionClosed : true because all the two parties must be available for mediator can start a session
            false,
            block.timestamp
        );

        paymentAccepted[_caseId] = false;
        acceptedByFirstParty[_caseId] = 0;
        acceptedBySecondparty[_caseId] = 0;

        emit BookedSessionCreated(_caseId);
    }

    /*
    * The second party joins the booked sessions and pay for it. 
    * When he joins, the booked session is now opened that the mediator can start it
    */
    function joinBookedSessionAsSecondParty(uint256 _caseId) external payable payHalfFeeForDefaultNumSession(1) {
        if(cases[_caseId].secondParty != msg.sender) {
            revert Mediation__YouAreNotPartOfThisSession();
        }

        ethBalances[_caseId] += msg.value;
        bookedSessions[_caseId].bookedSessionClosed = false;

        emit JoinedBookedSession(_caseId);
    }

    function companyCreateBookedSession(uint256 _caseId) 
        external payable payFullFeeForDefaultNumSession(1){
            ethBalances[_caseId] = 0;
            ethBalances[_caseId] += msg.value;
            
            bookedSessions[_caseId] = BookedSession(
                _caseId,
                cases[_caseId].firstParty,
                cases[_caseId].secondParty,
                cases[_caseId].mediator,
                firstPartyMembers[_caseId],
                secondPartyMembers[_caseId],
                false, //bookedSessionClosed : False because all the two parties are already available for mediator to start a session
                false,
                block.timestamp
                );

            paymentAccepted[_caseId] = false;
            acceptedByFirstParty[_caseId] = 0;
            acceptedBySecondparty[_caseId] = 0;

            emit BookedSessionCreated(_caseId);
    }

    /*
    * Mediator can start a booked session
    */
    function startBookedSession(uint256 _caseId) external onlyMediator(_caseId) {
        if(bookedSessions[_caseId].bookedSessionClosed) {
            revert Mediation__BookedSessionIsStillclosed();
        }
        if(bookedSessions[_caseId].bookedSessionStarted) {
            revert Mediation__BookedSessionAlreadyStarted();
        }

        bookedSessions[_caseId].bookedSessionStarted = true;
    }

    /*
    * When a mediator ends a booked session, the funds for the booked sessions are send to him
    */
    function endBookedSession(uint256 _caseId) external onlyMediator(_caseId) {
        if(!paymentAccepted[_caseId]){
            revert Mediation__CannotReceivePaymentPartiesNeedToApprove();
        }
        paymentAccepted[_caseId] = false;
        bookedSessions[_caseId].bookedSessionStarted = false;
        bookedSessions[_caseId].bookedSessionClosed = true;

        uint256 mediatorPay = (ethBalances[_caseId] * 90)/100;
        (bool success, ) = bookedSessions[_caseId].mediator.call{value: mediatorPay}("");
        if(!success) {
            revert Mediation__FailedToSendPayment();
        }
    }

    /*
    * Only the mediator or Owner can close a session
    * Closing a session when the max number of sessions has not reached, the parties receives the excess fund they provided
    */
    function closeCase(uint256 _caseId) external onlyMediatorOrOwner(_caseId) {
        if(cases[_caseId].numberOfSession == 0){
            //mediator should be compensated, I THINK and Parties receive their money after compensation 
            (bool success1, ) = cases[_caseId].firstParty.call{value: (mediatorPrice*defaultNumberOfSessions)/2}("");
            (bool success2, ) = cases[_caseId].secondParty.call{value: (mediatorPrice*defaultNumberOfSessions)/2}("");
            if(!success1) {
                revert Mediation__FailedToRefundFundsToParty1();
            }
            if(!success2) {
                revert Mediation__FailedToRefundFundsToParty2();
            }
        }

        uint256 numbSessions = defaultNumberOfSessions - cases[_caseId].numberOfSession;
        if(numbSessions > 0) {
            uint256 _pricePerParty = mediatorPrice/2;

            (bool success1, ) = cases[_caseId].firstParty.call{value: _pricePerParty*numbSessions}("");
            (bool success2, ) = cases[_caseId].secondParty.call{value: _pricePerParty*numbSessions}("");
            if(!success1) {
                revert Mediation__FailedToRefundFundsToParty1();
            }
            if(!success2) {
                revert Mediation__FailedToRefundFundsToParty2();
            }
        }

        cases[_caseId].caseClosed = true;
        doesCaseExist[_caseId] = false;
    }

    /*
    * Only the owner can withdraw all the funds in the contract
    */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if(!success) {
            revert Mediation__FailedToWithdrawFunds();
        }
    }

    /*
    * Owner can send fund to a paticular address
    */
    function withdrawToAddress(address payable _address, uint256 _amount) external onlyOwner {
        if(_amount > address(this).balance){
            revert Mediation__NotEnoughFundsInContract();
        }

        (bool success, ) = _address.call{value: _amount}("");
        if(!success) {
            revert Mediation__FailedToWithdrawFunds();
        }
    }


    //Get random word.
    function _requestRandomWords() internal  {
    uint256 requestId = i_COORDINATOR.requestRandomWords(
        c_keyHash,
        i_subscriptionId,
        c_requestConfirmations,
        c_callbackGasLimit,
        c_numWords
    );
    requestCounter += 1;
    s_requestIdToRequestIndex[requestId] = requestCounter;

    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address[] memory mediators = i_Mediator.getAllMediators();
    uint256 requestNumber = s_requestIdToRequestIndex[requestId];
    s_requestIndexToRandomWords[requestNumber] = (randomWords[0] % mediators.length);
    }


    /*
    * A modifier to receive payment, 
    * Mediators use this to receive their payments when they end a session
    */
    modifier receivePayment(uint256 _caseId) {
        _;
        uint256 balance = ethBalances[_caseId] / defaultNumberOfSessions;
        uint256 ethToSendToMediator = (balance*90)/100; //90%
        (bool success, ) = cases[_caseId].mediator.call{value: ethToSendToMediator}("");
        if(!success) {
            revert Mediation__FailedToSendPayment();
        }
    }


    /*
    * Parties involved use this to pay for a case with respect to the category
    */
    modifier payHalfFeeForDefaultNumSession(uint256 _numberOfSessions) {
        require(msg.value == (mediatorPrice/2)*_numberOfSessions, "Not enough or too much eth to create a case");
        _;
    }

    modifier payFullFeeForDefaultNumSession( uint256 _numberOfSessions) {
        require(msg.value == mediatorPrice*_numberOfSessions, "Not enough or too much eth to create a case");
        _;
    }

    modifier onlyMediator(uint256 _caseId) {
        if(msg.sender != cases[_caseId].mediator) {
            revert Mediation__OnlyMediatorCanDoThis();
        }
        _;
    }

    modifier onlyMediatorOrOwner(uint256 _caseId) {
        require(msg.sender == cases[_caseId].mediator || msg.sender == owner(), "Only Mediator or Owner can do this");
        _;
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}