//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol"; 
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol"; 
import "./SafeMath.sol";
import "./Ownable.sol";

/// @title DFreelance
/// @author Cao Huang
contract DFreelance is Ownable, ReentrancyGuard { 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public stopped=false;
    address private treasury = address(0);
    
    enum ProjectState{Initiated, Accepted, Finished, Refund}
    enum MilestoneState{Initiated, Pending, RequestPayement, DepositPending, Deposited, Released, Refund, AcceptedRelease, Disputed, ResolvedDispute}
    enum DelayType{None, Release, Dispute}
    enum ActiveState{inactive, Active}

    // project structure
    struct Project{
      uint    id;
      address client;
      address freelancer;     
      string freelancerHash;
      ProjectState  state;
      bool isvalid;       
    }

    // milestone structure
    struct Milestone{
        uint id;
        uint price;
        address token;
        MilestoneState state;        
        bool isvalid;
        uint updated;
    }

    // for milestone dispute
    struct Dispute {
      uint id;
      uint milestoneId;
      address litigator;
      uint litigatorAmount;
      uint defendantAmount;
      MilestoneState milestoneState;
      uint litigatorUpdatedAt;
      uint defendantUpdatedAt;      
      uint createdAt;
      uint clientAccepted;
      uint freelancerAccepted;
    }

    struct DisputePaymentInfo {
      address client;
      address freelancer;
      uint freelancerFee;
      uint clientAmount;
      uint freelancerAmount;
      uint freelancerFeeAmt;        
    }

    // memership
    struct Membership{
       address token;
       uint level;
       uint price;              
       uint updated; 
       uint expired;
    }

    uint gClientFee;
    mapping(uint=>uint) private gFreelancerFee;
    mapping(DelayType=>uint) public delayTimes;

    mapping(address=>ActiveState) private tokenFactory;
    mapping(address=>ActiveState) private observers;

    mapping(uint=>Project) private projects;
    mapping(uint=>mapping(uint=>Milestone)) private milestones;
    mapping(uint=>mapping(uint=>Dispute)) private disputes;
    mapping(string=>Membership) private memberships; 

    uint[] private projectidList;
    mapping(uint=>uint[]) private milestoneIdList;
    
    // project events
    event AcceptProject(uint projectId);
    event FinishProject(uint projectId,address client,address freelancer);
	
    // mileston events
    event DepositMilestone(uint _proejctId, uint _milestoneId);
    event ReleaseMilestone(uint _proejctId, uint _milestoneId);
    event AcceptReleaseMilestone(uint _proejctId, uint _milestoneId, uint valueReleased);
    event RefundMilestone(address employer,uint price);
    event SetMilestoneState(uint _projectId, uint _milestoneId, MilestoneState _status);

    // dispute events
    event DisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId, uint _amount);
    event UpdateDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId, uint _amount);
    event AcceptDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId);
    event ResolveDispute(uint _projectId, uint _milestoneId, uint _disputeId, uint _disputeAmt);
    event CancelDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId);
    event SetDisputeStatus(uint _projectId, uint _milestoneId, uint _disputeId, MilestoneState _status);

    // membership events
    event MembershipPayment(string _userId, uint _level, uint _price, uint _type);

    // require that the caller must be an EOA account to avoid flash loans
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    // modifiers for project 
    modifier verifyCaller (address _address) { 
      require (msg.sender == _address); 
      _;
    }
    
    modifier accepted(uint _id){ 
      require(projects[_id].state==ProjectState.Accepted);
      _;
    }

    // circuit breaker pattern modifiers
    modifier stopInEmergency { 
      require(!stopped); 
      _; 
    }
    modifier onlyInEmergency { 
      require(stopped); 
      _;
    }
   
    modifier onlyObservers {
      require(msg.sender == getOwner() || observers[msg.sender] == ActiveState.Active, "It's not observer's account");
      _;
    }

    // modifier for milestone
    modifier condition(bool _condition) {
      require(_condition);
      _;
    }

    modifier onlyDeveloper(address _freelancerAddress) {
      require(msg.sender == _freelancerAddress, "It's not freelancer wallet account");
      _;
    }

    modifier onlyClient(address _clientAddress) {
      require(msg.sender == _clientAddress, "It's not client wallet account");
      _;
    }
    
    modifier inProjectState(uint _projectId, ProjectState _state) {
      require(projects[_projectId].state == _state, "It is in inappropriate Status.");
      _;
    }

    modifier inProjectProgress(uint _projectId) {
      require(projects[_projectId].state == ProjectState.Accepted, "It's not active job.");
      _;
    }

    modifier inProjectProgressOrCompleted(uint _projectId) {
      require(projects[_projectId].state == ProjectState.Accepted || projects[_projectId].state == ProjectState.Finished, "It's a pending job.");
      _;
    }

    modifier inMilestoneState(uint _projectId, uint _milestonId,  MilestoneState _state){
      require(milestones[_projectId][_milestonId].state == _state, "It is in inappropriate Status.");
      _;
    }
    
    function getObserver(address _observer) public view returns(ActiveState) {
      requireOwner();
      return observers[_observer];
    }

    function setObserver(address _observer, ActiveState _state) external {
      requireOwner();
      observers[_observer] = _state; 
    }

    function getTreasuryInfo() public view returns (address) {
      return treasury;
    }

    function setTreasuryInfo(address _treasury) external {
      requireOwner();
      treasury = _treasury;
    }

    /// @notice Stop contract functionality in case of a bug is detected
    /// @dev Using the Circuit braker design pattern
    /// @param _stopped boolian state variable for stopping the contract
    function breakCircuit(bool _stopped)public{
        requireOwner();
        stopped=_stopped;
    } 
	
    /// @notice Get delay time
    /// @dev Solidity doesnt support the struct return type in public function calls
    function getDelayTime() public view returns(uint releaseDelay, uint disputeDelay){
        releaseDelay = delayTimes[DelayType.Release];
        disputeDelay = delayTimes[DelayType.Dispute];
    } 

    function setDelayTime(uint _releaseDelay, uint _disputeDelay ) external{ 
        requireOwner();
        require(_releaseDelay > 0 && _disputeDelay > 0, "Invalid delay time");
        delayTimes[DelayType.Release] = _releaseDelay;
        delayTimes[DelayType.Dispute] = _disputeDelay;
    }

    /// @notice Get the client fee
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @return clientFee: client fee (%)
    function getValidToken(address token) public view returns(ActiveState){
        return tokenFactory[token];
    } 

    function setValidToken(address _token, ActiveState _state) external{ 
        requireOwner();
        tokenFactory[_token] = _state; // 1: active, 0: inactive
    }


    /// @notice Get the client fee
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @return clientFee: client fee (%)
    function getClientFee() public view returns(uint){
        return gClientFee;
    } 

    function setClientFee(uint _fee) external{ 
        requireOwner();
        require(_fee < 1000, "Invalid client fee");        
        gClientFee = _fee;
    }

    /// @notice Get the freelancer fee
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @return freelancerFee: freelancer fee (%)
    ///         ex: 10%,  8.5%, 7%    
    function getFreelancerFee(string memory _userHash) public view returns(uint){
        return gFreelancerFee[memberships[_userHash].level];
    }

    function setFreelancerFee(uint _level, uint _fee) external{   
        requireOwner();
        require(_fee < 1000, "Invalid Freelancer fee");
        
        gFreelancerFee[_level] = _fee;
    }

    /// @notice Start an open project as a freelancer
    /// @param _projectId The project id
    /// @param _hash: freelancer's hash
    function acceptProject(uint _projectId, string memory _hash, uint _level) onlyEOA nonReentrant external stopInEmergency{
      require(projects[_projectId].isvalid == false, "Project id is already registered");
      
      projects[_projectId] = Project({
          id:_projectId,
          state:ProjectState.Accepted,          
          client:address(0),
          freelancer:msg.sender,
          freelancerHash:_hash,
          isvalid:true
          }); 

      projectidList.push(_projectId);

      Membership memory membership;     
      membership.level = _level;
      memberships[_hash] = membership;

      emit AcceptProject(_projectId);
    }

    /// @notice Close the commited project as an client, Ethers will be sent to the freelancer 
    /// @dev Sending Ethers with call function and check the result
    /// @param _projectId The project id
    function finishProject(uint _projectId) external onlyEOA nonReentrant accepted(_projectId) verifyCaller(projects[_projectId].client){

      uint milestoneSize = getMilestonesSize(_projectId);  

      for (uint i = 0; i < milestoneSize ; i++) {  //for loop example
         uint milestoneId = getMilestoneId(_projectId, i);
         require(milestones[_projectId][milestoneId].state == MilestoneState.Released 
         || milestones[_projectId][milestoneId].state == MilestoneState.AcceptedRelease
         || milestones[_projectId][milestoneId].state == MilestoneState.ResolvedDispute 
         || milestones[_projectId][milestoneId].state == MilestoneState.Refund , "Yon can't finish your job.");
      }

      projects[_projectId].state=ProjectState.Finished;      

      emit FinishProject(_projectId,projects[_projectId].client,projects[_projectId].freelancer);
    }

    /// @notice Get the project id list
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @return ids: Array of project ids
    function getProjectsSize() external view returns (uint){
        return projectidList.length;
    }

    function getProjectId(uint idx) external view returns(uint) {
        return projectidList[idx];
    }

    /// @notice Get the project specifications
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @param _id : The project id
    /// @return id : The project id
    /// @return state : The project state
    /// @return client : The client address
    /// @return freelancer : The freelancer address
    function getProject(uint _id)external view onlyObservers returns(uint id,uint state, address client,address freelancer){ 

      id=projects[_id].id;
      state=uint(projects[_id].state);
      client=projects[_id].client;
      freelancer=projects[_id].freelancer;
    }

    /// @notice Get milestone ids by project id
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @param _projectId project id
    /// @return ids: mileston id list
    function getMilestoneId(uint _projectId, uint _idx) public view returns(uint) {
        return milestoneIdList[_projectId][_idx];
    }

    function getMilestonesSize(uint _projectId) public view returns(uint) {
        return milestoneIdList[_projectId].length;
    }

    /// @notice Get the milestone specifications
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @param _projectId : The project id
    /// @param _milestoneId : The milestone id
    /// @return id : The project id
    /// @return price : The project price
    /// @return state : The project state
    /// @return token : The token address
    /// @return updated : The update uinx time
    function getMilestone(uint _projectId, uint _milestoneId) external view onlyObservers returns(uint id,uint price,uint state, address token, uint updated){ 

      id=milestones[_projectId][_milestoneId].id;
      price=milestones[_projectId][_milestoneId].price;
      state=uint(milestones[_projectId][_milestoneId].state);
      token = milestones[_projectId][_milestoneId].token;
      updated = milestones[_projectId][_milestoneId].updated;
    }

    /// @notice Set the status of milestone. This function can be called by only owner.
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @param _projectId : The project id
    /// @param _milestoneId : The milestone id
    /// @param _state : The milestone state
    function setMilestoneState(uint _projectId, uint _milestoneId, MilestoneState _state) external onlyObservers{
      milestones[_projectId][_milestoneId].state = _state;    
      emit SetMilestoneState(_projectId, _milestoneId, _state);
    }

    function balance() public view returns(uint256){
        return address(this).balance;
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    // Milestone
    ///////////////////////////////////////////////////////////////////////////////////////

    /// @notice Add a milestone as an client and milestone's state is set with "Deposited".
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    /// @param _clientAddr The client's address
    /// @param _amount The milestone price
    function depositMilestone(uint _projectId, uint _milestoneId, address _clientAddr, uint _amount, address _token)
        external 
        payable 
        nonReentrant 
        onlyEOA
        inProjectProgress(_projectId)
    {
        require(msg.sender == _clientAddr, "Invalid Address");
        require(milestones[_projectId][_milestoneId].isvalid == false, "This milestone is already registered");
        require(_amount > 0, "Invalid milestone price");

        if(_token == address(0)) {
          require(msg.value == _amount, "Invalid Amount");
        } else {
           require(tokenFactory[_token] == ActiveState.Active, "Invalid token address");
        }

        if(projects[_projectId].client != address(0)) {
          require(msg.sender == projects[_projectId].client, "Invalid address");
        } else {
          projects[_projectId].client = msg.sender;
        }

        uint clientFee = getClientFee();
        uint oriAmount = _amount.mul(1000).div(1000 + clientFee); 
        uint clientFeeAmt = oriAmount.mul(clientFee).div(1000);        
        
        if(_token == address(0)) {
          // Send the client service fee to our wallet.
          payable(treasury).transfer(clientFeeAmt);
        } else {
          // receive token into here
          IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount); 
          // send the fee to our wallet
          IERC20(_token).safeTransfer(treasury,  clientFeeAmt);
        }

        Milestone memory milestone;
        milestone.id = _milestoneId;
        milestone.state = MilestoneState.Deposited;
        milestone.token = _token;
        milestone.price = oriAmount;
        milestone.isvalid = true;
        milestone.updated=block.timestamp;

        milestones[_projectId][_milestoneId]=milestone;        
        milestoneIdList[_projectId].push(_milestoneId);

        emit DepositMilestone(_projectId, _milestoneId);
    }

    /// @notice Withdraw funds to the client in an emergency
    /// @dev Set the price to zero and the status of the project to Closed 
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    function refundMilestone(uint _projectId, uint _milestoneId)
      external 
      nonReentrant 
      onlyEOA
      inProjectProgress(_projectId)
      inMilestoneState(_projectId, _milestoneId, MilestoneState.Deposited)
      onlyDeveloper((projects[_projectId].freelancer))
    {
      address tokenAddr = milestones[_projectId][_milestoneId].token;
      uint price=milestones[_projectId][_milestoneId].price;
      
      milestones[_projectId][_milestoneId].price=0;
      milestones[_projectId][_milestoneId].state=MilestoneState.Refund;
      milestones[_projectId][_milestoneId].updated=block.timestamp;

      //payable(msg.sender).transfer(price);
      if(tokenAddr == address(0)) {
        payable(projects[_projectId].client).transfer(price);
      } else {
        IERC20(tokenAddr).safeTransfer(projects[_projectId].client, price);
      }      

      emit RefundMilestone(projects[_projectId].client, price);
    }

    /// @notice Close the commited milestone as an client, Ethers will be sent to the freelancer.
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id 
    function releaseMilestone(uint _projectId, uint _milestoneId)
        external
        inProjectProgress(_projectId)
        inMilestoneState(_projectId, _milestoneId, MilestoneState.Deposited)
        onlyClient((projects[_projectId].client))
    {
        milestones[_projectId][_milestoneId].state = MilestoneState.Released;
        milestones[_projectId][_milestoneId].updated=block.timestamp + delayTimes[DelayType.Release];

        emit ReleaseMilestone(_projectId, _milestoneId);
    }

    /// @notice Close the commited milestone as an client, Ethers will be sent to the freelancer.
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id 
    function acceptReleaseMilestone(uint _projectId, uint _milestoneId)
        external
        payable
        nonReentrant 
        onlyEOA
        inProjectProgressOrCompleted(_projectId)
        inMilestoneState(_projectId, _milestoneId, MilestoneState.Released)
        onlyDeveloper((projects[_projectId].freelancer))
    {
        require(block.timestamp > milestones[_projectId][_milestoneId].updated, "You can receive it delay times after the client releases.");

        address tokenAddr = milestones[_projectId][_milestoneId].token;
        uint freelancerFeeAmt = milestones[_projectId][_milestoneId].price.mul(getFreelancerFee(projects[_projectId].freelancerHash)).div(1000);
        uint price = milestones[_projectId][_milestoneId].price.sub(freelancerFeeAmt);
        
        // Send the freelancer fee to our wallet.
        milestones[_projectId][_milestoneId].state = MilestoneState.AcceptedRelease;
        milestones[_projectId][_milestoneId].updated=block.timestamp;

        if(tokenAddr == address(0)) {
          payable(projects[_projectId].freelancer).transfer(price);
          payable(treasury).transfer(freelancerFeeAmt);
        } else {
          IERC20(tokenAddr).safeTransfer(projects[_projectId].freelancer, price);
          IERC20(tokenAddr).safeTransfer(treasury, freelancerFeeAmt);
        }

        emit AcceptReleaseMilestone(_projectId, _milestoneId, price);
    }

    /////////////////////////////////////////////////////////////////////////////////////
    //                               dispute  
    /////////////////////////////////////////////////////////////////////////////////////

    /// @notice Get the dispute information 
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId : The project id
    /// @param _disputeId : The dispute id
    /// @return id :  dispute id
    /// @return milestoneId :  milestone id
    /// @return litigator :  litigator's account address
    /// @return litigatorAmount :  litigator's dispute amount.
    /// @return defendantAmount :  defendant's dispute amount.
    /// @return litigatorUpdatedAt :  litigator's update date.
    /// @return defendantUpdatedAt :  defendant's update date.
    /// @return milestoneState : milestone's state
    function getDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId)external view onlyObservers returns(uint id, uint milestoneId, address litigator, uint litigatorAmount, uint defendantAmount, uint litigatorUpdatedAt, uint defendantUpdatedAt, uint milestoneState){ 

      id = _disputeId;
      milestoneId = disputes[_projectId][_disputeId].milestoneId;
      litigator = disputes[_projectId][_disputeId].litigator;
      litigatorAmount = disputes[_projectId][_disputeId].litigatorAmount;
      defendantAmount = disputes[_projectId][_disputeId].defendantAmount;
      litigatorUpdatedAt = disputes[_projectId][_disputeId].litigatorUpdatedAt;
      defendantUpdatedAt = disputes[_projectId][_disputeId].defendantUpdatedAt;
      milestoneState = uint(milestones[_projectId][_milestoneId].state);
    }

    /// @notice Set the status of milestone. This function can be called by only owner.
    /// @dev Solidity doesnt support the struct return type in public function calls
    /// @param _projectId : The project id
    /// @param _milestoneId : The milestone id
    /// @param _disputeId : The dispute id
    /// @param _status : The milestone state
    function setDisputeStatus(uint _projectId, uint _milestoneId, uint _disputeId, MilestoneState _status) external{
      
      requireOwner();
      milestones[_projectId][_milestoneId].state = _status;
      emit SetDisputeStatus(_projectId, _milestoneId, _disputeId, _status);
    }

    /// @notice Create new dispute.
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    /// @param _disputeId The milestone id
    /// @param _amount The milestone price
    function disputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId, uint _amount)
        external
        nonReentrant 
        onlyEOA
        inProjectProgress(_projectId)
    {
        require(msg.sender == projects[_projectId].client || msg.sender == projects[_projectId].freelancer, "Invalid access");
        require(milestones[_projectId][_milestoneId].state == MilestoneState.Deposited || 
                milestones[_projectId][_milestoneId].state == MilestoneState.Released, "You can't dispute the milestone.");

        if(msg.sender == projects[_projectId].client) {
          require(_amount >= 0 && _amount < milestones[_projectId][_milestoneId].price, "Invalid dispute amount"); 
        } else {
          require(_amount > 0 && _amount <= milestones[_projectId][_milestoneId].price, "Invalid dispute amount"); 
        }        

        Dispute memory dispute;

        dispute.id = _disputeId;
        dispute.milestoneId = _milestoneId;
        dispute.litigator = msg.sender; // set the disputer's wallet address.
        dispute.litigatorAmount = _amount;
        dispute.milestoneState = milestones[_projectId][_milestoneId].state;
        dispute.litigatorUpdatedAt = block.timestamp;
        dispute.createdAt = block.timestamp;

        disputes[_projectId][_disputeId] = dispute;
        milestones[_projectId][_milestoneId].state = MilestoneState.Disputed;

        emit DisputeMilestone(_projectId, _milestoneId, _disputeId, _amount);
    }

    /// @notice Cancel the dispute request.
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    /// @param _disputeId The milestone id
    function cancelDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId)
        external
        nonReentrant 
        onlyEOA
        inProjectProgress(_projectId)
        inMilestoneState(_projectId, _milestoneId, MilestoneState.Disputed)
    {
        require(msg.sender == disputes[_projectId][_disputeId].litigator, "Only litigator can cancel the dispute request.");

        milestones[_projectId][_milestoneId].state = disputes[_projectId][_disputeId].milestoneState;
        delete disputes[_projectId][_disputeId];

        emit CancelDisputeMilestone(_projectId, _milestoneId, _disputeId);
    }

    /// @notice Update the dispute information.
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    /// @param _disputeId The milestone id
    /// @param _amount The milestone price
    function updateDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId, uint _amount)
        external
        nonReentrant 
        onlyEOA
        inProjectProgress(_projectId)
        inMilestoneState(_projectId, _milestoneId, MilestoneState.Disputed)
    {
        require(msg.sender == projects[_projectId].client || msg.sender == projects[_projectId].freelancer, "Invalid access");        
        
        if(msg.sender == projects[_projectId].client) {
          require(_amount >= 0 && _amount < milestones[_projectId][_milestoneId].price, "Invalid dispute amount"); 
        } else {
          require(_amount > 0 && _amount <= milestones[_projectId][_milestoneId].price, "Invalid dispute amount"); 
        }

        if(disputes[_projectId][_disputeId].defendantUpdatedAt == 0) {
          require((block.timestamp - disputes[_projectId][_disputeId].createdAt) < delayTimes[DelayType.Dispute], "This is a dispute that has already been resolved and cannot be changed.");
        }

        // set the disputer's wallet address.
        if(msg.sender == disputes[_projectId][_disputeId].litigator) {
          disputes[_projectId][_disputeId].litigatorAmount = _amount;
          disputes[_projectId][_disputeId].litigatorUpdatedAt = block.timestamp;
        } else {
          disputes[_projectId][_disputeId].defendantAmount = _amount;
          disputes[_projectId][_disputeId].defendantUpdatedAt = block.timestamp;
        }

        if(disputes[_projectId][_disputeId].defendantUpdatedAt > 0 && disputes[_projectId][_disputeId].litigatorUpdatedAt > 0) {
          if(disputes[_projectId][_disputeId].litigatorAmount == disputes[_projectId][_disputeId].defendantAmount) {
            settleDisputeMilestone(_projectId, _milestoneId, _disputeId);
          }
        } 
        emit UpdateDisputeMilestone(_projectId, _milestoneId, _disputeId, _amount);
    }

    /// @notice Settle the dispute information and resolve the dispute.
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    /// @param _disputeId The milestone id
    function settleDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId) private
    {
        // Send the freelancer fee to our wallet.
        DisputePaymentInfo memory paymentInfo;

        paymentInfo.freelancerFee = getFreelancerFee(projects[_projectId].freelancerHash); 
        paymentInfo.freelancer = projects[_projectId].freelancer;
        paymentInfo.client = projects[_projectId].client;

        address tokenAddr = milestones[_projectId][_milestoneId].token;

        paymentInfo.freelancerAmount = disputes[_projectId][_disputeId].litigatorAmount;
        paymentInfo.clientAmount = milestones[_projectId][_milestoneId].price - paymentInfo.freelancerAmount;
        
        paymentInfo.freelancerFeeAmt = paymentInfo.freelancerAmount.mul(paymentInfo.freelancerFee).div(1000);
        paymentInfo.freelancerAmount -= paymentInfo.freelancerFeeAmt;
        
        milestones[_projectId][_milestoneId].state = MilestoneState.ResolvedDispute;

        if(tokenAddr == address(0)) {
          if(paymentInfo.freelancerAmount > 0) {
            payable(paymentInfo.freelancer).transfer(paymentInfo.freelancerAmount);    
            payable(treasury).transfer(paymentInfo.freelancerFeeAmt);         
          }

          if(paymentInfo.clientAmount > 0) {
            payable(paymentInfo.client).transfer(paymentInfo.clientAmount);          
          }     
        } else {
          if(paymentInfo.freelancerAmount > 0) {
            IERC20(tokenAddr).safeTransfer(paymentInfo.freelancer, paymentInfo.freelancerAmount); 
            IERC20(tokenAddr).safeTransfer(treasury, paymentInfo.freelancerFeeAmt);
          }
          
          if(paymentInfo.clientAmount > 0) {
            IERC20(tokenAddr).safeTransfer(paymentInfo.client, paymentInfo.clientAmount); 
          }
        }
    }

    /// @notice Accept the dispute information and resolve the dispute.
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId The project id
    /// @param _milestoneId The milestone id
    /// @param _disputeId The milestone id
    function acceptDisputeMilestone(uint _projectId, uint _milestoneId, uint _disputeId) 
      external
      nonReentrant 
      onlyEOA
      inProjectProgress(_projectId)
      inMilestoneState(_projectId, _milestoneId, MilestoneState.Disputed)
    {
        require(msg.sender == projects[_projectId].client || msg.sender == projects[_projectId].freelancer, "Invalid access");     
        require( disputes[_projectId][_disputeId].defendantUpdatedAt == 0 && block.timestamp > (delayTimes[DelayType.Dispute] +  disputes[_projectId][_disputeId].createdAt), 
                "You can accept the dispute payment after 48 hours.");

        // Send the freelancer fee to our wallet.
        DisputePaymentInfo memory paymentInfo;

        paymentInfo.freelancerFee = getFreelancerFee(projects[_projectId].freelancerHash); 
        paymentInfo.freelancer = projects[_projectId].freelancer;
        paymentInfo.client = projects[_projectId].client;
        
        address tokenAddr = milestones[_projectId][_milestoneId].token;

        paymentInfo.freelancerAmount = disputes[_projectId][_disputeId].litigatorAmount;
        paymentInfo.clientAmount = milestones[_projectId][_milestoneId].price - paymentInfo.freelancerAmount;
        
        paymentInfo.freelancerFeeAmt = paymentInfo.freelancerAmount.mul(paymentInfo.freelancerFee).div(1000);
        paymentInfo.freelancerAmount -= paymentInfo.freelancerFeeAmt;     

        if(tokenAddr == address(0)) {
          if(msg.sender == projects[_projectId].client) {
             require(disputes[_projectId][_disputeId].clientAccepted == 0, "Client was accepted the dispute funt already."); 
                
            disputes[_projectId][_disputeId].clientAccepted = 1;
            if(paymentInfo.clientAmount > 0) {
              payable(paymentInfo.client).transfer(paymentInfo.clientAmount);
            } 
          } else {
            require(disputes[_projectId][_disputeId].freelancerAccepted == 0, "Client was accepted the dispute funt already.");

            disputes[_projectId][_disputeId].freelancerAccepted = 1;
            if(paymentInfo.freelancerAmount > 0) {
              payable(paymentInfo.freelancer).transfer(paymentInfo.freelancerAmount);     
              payable(treasury).transfer(paymentInfo.freelancerFeeAmt);
            }
          }
        } else {
          if(msg.sender == projects[_projectId].client) {
            require(disputes[_projectId][_disputeId].clientAccepted == 0, "Client was accepted the dispute funt already.");

            disputes[_projectId][_disputeId].clientAccepted = 1;
            if(paymentInfo.clientAmount > 0) {
                IERC20(tokenAddr).safeTransfer(paymentInfo.client, paymentInfo.clientAmount); 
            }               
          } else {
            require(disputes[_projectId][_disputeId].freelancerAccepted == 0, "Client was accepted the dispute funt already.");
            
            disputes[_projectId][_disputeId].freelancerAccepted = 1;
            if(paymentInfo.freelancerAmount > 0) {
              IERC20(tokenAddr).safeTransfer(paymentInfo.freelancer, paymentInfo.freelancerAmount); 
              IERC20(tokenAddr).safeTransfer(treasury, paymentInfo.freelancerFeeAmt);
            }            
          }
        }
        
        if(paymentInfo.clientAmount == milestones[_projectId][_milestoneId].price || 
            disputes[_projectId][_disputeId].litigatorAmount == milestones[_projectId][_milestoneId].price) {
            milestones[_projectId][_milestoneId].state = MilestoneState.ResolvedDispute;
        } else {
          if(disputes[_projectId][_disputeId].freelancerAccepted == 1 && disputes[_projectId][_disputeId].clientAccepted == 1) {
            milestones[_projectId][_milestoneId].state = MilestoneState.ResolvedDispute;
          }
        }

        emit AcceptDisputeMilestone(_projectId, _milestoneId, _disputeId);
    }

    /// @notice Resolve the dispute request by manager.
    /// @dev  Solidity doesnt support the struct return type in public function calls
    /// @param _projectId : The project id
    /// @param _milestoneId : The milestone id
    /// @param _disputeId  : The milestone id
    /// @param _disputeAmt : litigateor's dispute amount
    function resolveDispute(uint _projectId, uint _milestoneId, uint _disputeId, uint _disputeAmt)
        external
        inProjectProgress(_projectId)
        inMilestoneState(_projectId, _milestoneId, MilestoneState.Disputed)
    {
        requireOwner();
        require(_disputeAmt >= 0 && _disputeAmt < milestones[_projectId][_milestoneId].price, "Invalid dispute amount");

        address tokenAddr = milestones[_projectId][_milestoneId].token;
        DisputePaymentInfo memory paymentInfo;

        paymentInfo.freelancerFee = getFreelancerFee(projects[_projectId].freelancerHash); 
        paymentInfo.freelancer = projects[_projectId].freelancer;
        paymentInfo.client = projects[_projectId].client;

        disputes[_projectId][_disputeId].litigatorAmount = _disputeAmt;
        disputes[_projectId][_disputeId].litigatorUpdatedAt = block.timestamp;
        disputes[_projectId][_disputeId].defendantAmount = _disputeAmt;
        disputes[_projectId][_disputeId].defendantUpdatedAt = block.timestamp;

        paymentInfo.freelancerAmount = _disputeAmt;
        paymentInfo.clientAmount = milestones[_projectId][_milestoneId].price - _disputeAmt;

        paymentInfo.freelancerFeeAmt = paymentInfo.freelancerAmount.mul(paymentInfo.freelancerFee).div(1000);
        paymentInfo.freelancerAmount -= paymentInfo.freelancerFeeAmt;
        
        //disputes[_projectId][_disputeId].updated = block.timestamp;
        milestones[_projectId][_milestoneId].state = MilestoneState.ResolvedDispute;

        if(tokenAddr == address(0)) {
          if(paymentInfo.freelancerAmount > 0) {
            payable(paymentInfo.freelancer).transfer(paymentInfo.freelancerAmount);     
            payable(treasury).transfer(paymentInfo.freelancerFeeAmt);       
          }

          if(paymentInfo.clientAmount > 0) {
            payable(paymentInfo.client).transfer(paymentInfo.clientAmount);           
          }
          
        } else {

          if(paymentInfo.freelancerAmount > 0) {
            IERC20(tokenAddr).safeTransfer(paymentInfo.freelancer, paymentInfo.freelancerAmount); 
            IERC20(tokenAddr).safeTransfer(treasury, paymentInfo.freelancerFeeAmt);
          }
          
          if(paymentInfo.clientAmount > 0) {
            IERC20(tokenAddr).safeTransfer(paymentInfo.client, paymentInfo.clientAmount); 
          }
        }

        emit ResolveDispute(_projectId, _milestoneId, _disputeId, _disputeAmt);        
    }

    // For membership payment
    function membershipPayment(string memory _userHash, uint _level, uint _amount, uint _type, address _token) 
      external 
      payable
      nonReentrant 
      onlyEOA
    {
      if(_token == address(0)) {
        require(msg.value == _amount, "Invalid amount");
        payable(treasury).transfer(msg.value);
      } else {
        require(tokenFactory[_token] == ActiveState.Active, "Invalid token address");
        require(_amount > 0, "Invalid membership price");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount); 
        IERC20(_token).safeTransfer(treasury,  _amount);
      }
      
      emit MembershipPayment(_userHash, _level, _amount, _type);
    }
    

}