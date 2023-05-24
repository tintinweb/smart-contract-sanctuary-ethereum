//SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;

import {ICharityStreamV2} from "./interfaces/ICharityStreamV2.sol";

/**
 * @title CharityStreamV2 is a contract that allows to create campaigns.
 * @author devorsmth.eth
 */
contract CharityStreamV2 is ICharityStreamV2 {
    // 100% == 1000;
    uint256 public fee;
    address public owner;
    address private pendingOwner;
    // collected fee
    uint256 feeAmount;
    // starts from 1
    uint256 public idCampaign = 1;
    uint256 public streamedAmount;

    Campaign[] campaigns;
    Stream[] streams;
    LatestProposition latestProposition;

    // Campaign's backers
    mapping (uint256 => address[]) idToBackers;
    // backer => idCampaign => amount
    mapping (address => mapping(uint256 => uint256)) donations;
    mapping (address => uint256) refunds;
    // backer => all supported campaigns
    mapping (address => uint256[]) backedCampaigns;
    // idCampaign => propositions
    mapping (uint256 => Proposition[]) idToProposition;
    // backer => idCampaign => idProposition => vote
    mapping (address => mapping(uint256 => mapping(uint256 => bool))) hasVoted;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyCampaignOwner(uint256 _idCampaign) {
        if (msg.sender != campaigns[_idCampaign-1].creator) revert NotOwner();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * Create Campaign
     * @param _name Name of the campaign
     * @param _amount Goal amount
     * @param _duration Duration of you campaign in seconds
     */
    function createCampaign(
        string memory _name, 
        uint128 _amount, 
        uint256 _duration
    ) external {
        if (0 == _duration) revert DurationIsZero();
        if (0 == _amount) revert AmountIsZero();

        uint32 endTime = uint32(block.timestamp + _duration);
        campaigns.push(Campaign({
            status: Status.Active,
            endTime: endTime,
            quorum: 0,
            creator: msg.sender,
            amountGoal: _amount,
            amountReceived: 0,
            amountLeft: 0,
            idProposition: 1,
            name: _name
        }));

        emit campaignCreatedEvent(
            msg.sender, 
            idCampaign, 
            endTime, 
            _amount, 
            _name
        );
        ++idCampaign;           
    }

    /**
     * Donate to a campaign
     */
    function donate(uint256 _idCampaign) external payable {
        Campaign storage campaign = campaigns[_idCampaign-1];
        if (campaign.status != Status.Active) revert CampaignIsNotActive();
        if (campaign.endTime < block.timestamp) revert CampaignEnded();

        campaign.amountReceived = campaign.amountReceived + uint128(msg.value);
        // if it's the first donation
        if (0 == donations[msg.sender][_idCampaign]) {
            backedCampaigns[msg.sender].push(_idCampaign);
            idToBackers[_idCampaign].push(msg.sender);
        }
        donations[msg.sender][_idCampaign] += msg.value;        

        emit donationEvent(msg.sender, _idCampaign, msg.value); 
    }

    /**
     * Stop a campaign and add eth to backers' refunds
     */
    function stopAndRefundCampaign(uint256 _idCampaign) external {
        Campaign storage campaign = campaigns[_idCampaign-1];
        if (msg.sender != campaign.creator && msg.sender != owner) revert NotOwner();
        if (Status.Active != campaign.status) revert CampaignIsNotActive();
        campaign.status = Status.Refunded;

        address[] memory backers = idToBackers[_idCampaign];
        uint256 length = backers.length;
        address backer;
        for (uint256 i; i < length; ) {
            backer = backers[i];
            refunds[backer] += donations[backer][_idCampaign];
            delete donations[backer][_idCampaign];
            unchecked {++i;}
        }
        delete idToBackers[_idCampaign];

        emit stopAndRefundCampaignEvent(msg.sender, _idCampaign);
    }

    function withdrawRefunds() external {
        uint256 refund = refunds[msg.sender];
        if(0 == refund) revert NoRefund();
        delete refunds[msg.sender];
        (bool sent,) = msg.sender.call{value: refund}("");
        if(!sent) revert NoRefund();
        emit refundEvent(msg.sender, refund);
    }

    /**
     * Finish a campaign and allow to create propositions
     */
    function finishCampaign(uint256 _idCampaign) external onlyCampaignOwner(_idCampaign) {
        Campaign storage campaign = campaigns[_idCampaign-1];
        if (Status.Active != campaign.status) revert CampaignIsNotActive();
        if (block.timestamp <= campaign.endTime) revert CampaignIsActive();
        campaign.status = Status.Finished;

        uint256 amount = campaign.amountReceived;
        uint256 fee_ = fee;
        if (0 != fee_) {
            fee_ = amount*fee_/1000;
            feeAmount = feeAmount + fee_;
            amount -= fee_;
        }
        campaign.amountLeft = uint128(amount);

        // quorum is 30% of backers + 1
        campaign.quorum = uint64(idToBackers[_idCampaign].length*300/1000 + 1);
        emit finishCampaignEvent(_idCampaign, amount);
    }

    /**
     * Create a proposition for a campaign
     * @notice Creating a proposition locks _amount of eth
     * @param _idCampaign Campaign id
     * @param _description Description of the proposition
     * @param _amount Amount of eth required for the proposition
     * @param _paymentDuration How long _amount will be paid in seconds
     * @param _voteDuration Time to vote in seconds
     */
    function newProposition(
        uint256 _idCampaign,
        string memory _description,
        uint128 _amount,
        uint32 _paymentDuration,
        uint32 _voteDuration
    ) external onlyCampaignOwner(_idCampaign) {
        Campaign storage campaign = campaigns[_idCampaign-1];
        if (Status.Finished != campaign.status) revert CampaignIsNotFinished();
        if (_amount > campaign.amountLeft) revert NotEnoughFunds();
        if (0 == _paymentDuration) revert DurationIsZero();
        if (0 == _voteDuration) revert DurationIsZero();

        uint256 idProposition_ = campaign.idProposition;
        uint32 voteEndTime = uint32(block.timestamp) + _voteDuration;

        idToProposition[_idCampaign].push(Proposition({
            status: Status.Active,
            paymentDuration: _paymentDuration,
            voteEndTime: voteEndTime,
            numberOfVoters: 0,
            amount: _amount,
            ayes: 0,
            nays: 0,
            description: _description
        }));
        // already checked for underflow
        unchecked {campaign.amountLeft = campaign.amountLeft - _amount;}
        latestProposition = LatestProposition(
            uint128(_idCampaign),
            uint128(idProposition_)
        );
        ++campaign.idProposition;

        emit newPropositionEvent(
            msg.sender, 
            _idCampaign, 
            idProposition_, 
            _description, 
            _amount, 
            _paymentDuration, 
            voteEndTime
        );
    }

    /**
     * Vote yes or no for a proposition
     * @notice only backers can vote,
     * Vote power = sqrt(donation in wei)
     */
    function vote(
        uint256 _idCampaign, 
        uint256 _idProposition, 
        bool _decision
    ) external {
        uint256 donation = donations[msg.sender][_idCampaign];
        if (0 == donation) revert NotBacker();

        Proposition storage proposition = idToProposition[_idCampaign][_idProposition-1];
        if (block.timestamp > proposition.voteEndTime) revert VotingEnded();
        if (true == hasVoted[msg.sender][_idCampaign][_idProposition]) revert AlreadyVoted();
        hasVoted[msg.sender][_idCampaign][_idProposition] = true;
        ++proposition.numberOfVoters;

        uint128 votePower = uint128(sqrt(donation));
        if (_decision) proposition.ayes = proposition.ayes + votePower;
        else proposition.nays = proposition.nays + votePower;

        emit voteEvent(msg.sender, _idCampaign, _idProposition, _decision, votePower);
    }

    /**
     * End a proposition
     * @notice Numbers of voters must be >= quorum,
     * if ayes > nays, the proposition is approved
     * and a stream is created.
     * If quorum is not met or nays > ayes, the locked funds are unlocked
     */
    function endProposition(uint256 _idCampaign, uint256 _idProposition) external onlyCampaignOwner(_idCampaign) {
        Proposition storage proposition = idToProposition[_idCampaign][_idProposition-1];
        if (Status.Active != proposition.status) revert PropositionIsNotActive();
        if (block.timestamp < proposition.voteEndTime) revert VotingIsActive();
        proposition.status = Status.Finished;

        Campaign storage campaign = campaigns[_idCampaign-1];
        if (proposition.numberOfVoters < campaign.quorum) { 
            unchecked{
                campaign.amountLeft = campaign.amountLeft + proposition.amount;
            }
            emit quorumIsNotMetEvent(msg.sender, _idCampaign, _idProposition);
        } else {
            if (proposition.ayes > proposition.nays) {                               
                createStream(
                    proposition.amount, 
                    proposition.paymentDuration
                );
                emit propositionIsApprovedEvent(msg.sender, _idCampaign, _idProposition);
            } else {
                unchecked {
                    campaign.amountLeft = campaign.amountLeft + proposition.amount;    
                }                
                emit propositionIsNotApprovedEvent(msg.sender, _idCampaign, _idProposition);
            }
        }
    }

    function createStream(uint128 _amount, uint32 _paymentDuration) internal {
        uint128 flow = _amount/_paymentDuration;
        streams.push(Stream({
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + _paymentDuration,
            lastWithdrawTime: uint32(block.timestamp),
            receiver: msg.sender,
            flow: flow,
            leftAmount: _amount
        }));
        emit createStreamEvent(msg.sender, streams.length, flow, _amount);
    }

    /**
     * Withdraw available funds from a stream
     */
    function withdrawFunds(uint256 idStream) external {
        Stream storage stream = streams[idStream - 1];
        address receiver = stream.receiver;
        if (msg.sender != receiver) revert NotReceiver();
        uint128 payment = getPayment(stream);
        if (0 != payment) {
            unchecked{stream.leftAmount -= payment;}
            (bool sent,) = receiver.call{value: payment}("");
            if (!sent) revert NoWithdraw();
            streamedAmount = streamedAmount + payment;
            emit fundsWithrawnEvent(msg.sender, idStream, payment);
        } else {
            revert NotEnoughFunds();
        }
    }

    /**
     * Calculates the payment for a stream
     */
    function getPayment(Stream storage _stream) internal returns (uint128){
        uint256 delta;
        uint32 endTime = _stream.endTime;
        if (block.timestamp < endTime) {
            delta = block.timestamp - _stream.lastWithdrawTime;
            _stream.lastWithdrawTime = uint32(block.timestamp);
        } else {
            delta = endTime - _stream.lastWithdrawTime;
            _stream.lastWithdrawTime = endTime;
        }
        return uint128(delta*_stream.flow);
    }

    /**
     * Set new fee
     * @param _newFee New fee is in %, where 100%==1000
     */
    function setFee(uint256 _newFee) external payable onlyOwner() {
        if (1000 < _newFee) revert FeeTooHigh();
        emit newFeeEvent(fee, _newFee);
        fee = _newFee;
    }

    /**
     * Withdraw collected fee
     */
    function withdrawFee() external payable onlyOwner() {
        uint256 feeAmount_ = feeAmount;
        if (0 == feeAmount_) revert NoWithdraw();
        delete feeAmount;
        (bool sent,) = msg.sender.call{value: feeAmount_}("");
        if (!sent) revert NoWithdraw();
        emit withdrawEvent(msg.sender, feeAmount_);
    }

    /**
     * The first step of a transfer
     */
    function transferOwnership(address _newOwner) external payable onlyOwner() {
        pendingOwner = _newOwner;
        emit transferOwnershipEvent(msg.sender, _newOwner);
    }

    /**
     * The second step of a transfer
     */
    function acceptOwnership() external payable {
        if (msg.sender != pendingOwner) revert NotOwner();
        owner = msg.sender;
        delete pendingOwner;
        emit acceptOwnershipEvent(msg.sender);
    }

    //// View functions ////
    function getRefunds(address _addr) external view returns (uint256) {
        return refunds[_addr];
    }

    function getCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    function getBackedCampaigns(address _backer) external view returns (uint256[] memory) {
        return backedCampaigns[_backer];
    }

    function getProposition(
        uint256 _idCampaign, 
        uint256 _idProposition
    ) external view returns (Proposition memory) {
        return idToProposition[_idCampaign][_idProposition-1];
    }

    function getLatestProposition() external view returns (LatestProposition memory) {
        return latestProposition;
    }

    function getStreams() external view returns (Stream[] memory) {
        return streams;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1)>>1;
        y = x;
        while (z < y) {
            y = z;
            z = (x/z + z)>>1;
        }
    }
}

//SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;

import "./IErrors.sol";
import "./IEvents.sol";

interface ICharityStreamV2 is IErrors, IEvents {
  function createCampaign(
    string memory _name, 
    uint128 _amount, 
    uint256 _duration
  ) external;
  function donate(uint256 _idCampaign) external payable;
  function stopAndRefundCampaign(uint256 _idCampaign) external;
  function withdrawRefunds() external;
  function finishCampaign(uint256 _idCampaign) external;
  function newProposition(
    uint256 _idCampaign,
    string memory _description,
    uint128 _amount,
    uint32 _paymentDuration,
    uint32 _voteDuration
  ) external;
  function vote(
    uint256 _idCampaign, 
    uint256 _idProposition, 
    bool _decision
  ) external;
  function endProposition(uint256 _idCampaign, uint256 _idProposition) external;
  function withdrawFunds(uint256 idStream) external;
  function setFee(uint256 _newFee) external payable;
  function withdrawFee() external payable;
  function transferOwnership(address _newOwner) external payable;
  function acceptOwnership() external payable;
  function getRefunds(address _addr) external view returns (uint256);
  function getCampaigns() external view returns (Campaign[] memory);
  function getBackedCampaigns(address _backer) external view returns (uint256[] memory);
  function getProposition(
    uint256 _idCampaign, 
    uint256 _idProposition
  ) external view returns (Proposition memory);
  function getStreams() external view returns (Stream[] memory);

  enum Status {NotActive, Active, Finished, Refunded}

  struct Campaign {
    Status status;
    uint32 endTime; 
    uint64 quorum;
    address creator;
    uint128 amountGoal;
    uint128 amountReceived;
    uint128 amountLeft;
    uint128 idProposition;
    string name;
  }

  struct Proposition {
    Status status;
    uint32 paymentDuration;
    uint32 voteEndTime;
    uint32 numberOfVoters;
    uint128 amount;
    uint128 ayes;
    uint128 nays;
    string description;
  }

  struct LatestProposition {
    uint128 idCampaign;
    uint128 idProposition;    
  }

  struct Stream {
    uint32 startTime;
    uint32 endTime;
    uint32 lastWithdrawTime;
    address receiver;
    uint128 flow;
    uint128 leftAmount;
  }
}

//SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;

interface IErrors {
  error CampaignEnded();
  error CampaignIsActive();
  error CampaignIsNotActive();
  error CampaignIsNotFinished();
  error AmountIsZero();
  error NotOwner();
  error NoRefund();
  error NoWithdraw();
  error NotEnoughFunds();
  error NotBacker();
  error AlreadyVoted();
  error VotingEnded();
  error VotingIsActive();
  error PropositionIsNotActive();
  error NotReceiver();
  error DurationIsZero();
  error FeeTooHigh();
}

//SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;

interface IEvents {
  event campaignCreatedEvent(
    address indexed creator, 
    uint256 indexed idCampaign, 
    uint32 endTime, 
    uint128 amount, 
    string name
  );
  event donationEvent(address indexed backer, uint256 indexed idCampaign, uint256 amount);
  event stopAndRefundCampaignEvent(address indexed creator, uint256 indexed idCampaign);
  event refundEvent(address indexed backer, uint256 amount);
  event finishCampaignEvent(uint256 indexed idCampaign, uint256 amount);
  event newPropositionEvent(
    address indexed owner, 
    uint256 indexed idCampaign, 
    uint256 indexed idProposition, 
    string description, 
    uint256 amount, 
    uint32 paymentDuration, 
    uint32 voteEndTime
  );
  event voteEvent(address indexed voter, uint256 indexed idCampaign, uint256 indexed idProposition, bool decision, uint128 votePower);
  event quorumIsNotMetEvent(address indexed creator, uint256 indexed idCampaign, uint256 indexed idProposition);
  event propositionIsApprovedEvent(address indexed creator, uint256 indexed idCampaign, uint256 indexed idProposition);
  event propositionIsNotApprovedEvent(address indexed creator, uint256 indexed idCampaign, uint256 indexed idProposition);
  event createStreamEvent(address indexed receiver, uint256 indexed idStream, uint128 flow, uint128 funds);
  event fundsWithrawnEvent(address receiver, uint256 idStream, uint128 payment);
  event newFeeEvent(uint256 oldFee, uint256 newFee);
  event withdrawEvent(address indexed owner, uint256 amount);
  event transferOwnershipEvent(address indexed oldOwner, address indexed newOwner);
  event acceptOwnershipEvent(address indexed newOwner);
}