/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract _CrowdFunding {

    address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

    //mapping contributors address with their donated amount
    mapping (address => uint) public contributors;
    //target amount the owner has requested to raise
    uint public target;
    //total funds raised 
    uint public raisedAmount;
    //time when the funding will end
    uint public deadline;
    uint public noOfContributors;
    //minimum amount a contributor can donate
    uint public minimumContribution;
    uint public noOfRequests;

    struct Request{
        string description;
        address payable recipient;
        bool isFunded;
        //checking the voter has already casted vote for a request or not
        //votter can't cast vote twice for same request 
        mapping(address=>bool) voters;
        uint noOfVoters;
        uint amountNeeded;
    }

    mapping(uint=>Request) public requests;

    constructor(uint _target,uint _deadline) {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        target = _target;
        //the current block time when the contract was deployed + next specified time both in secs
        deadline= block.timestamp+_deadline; 
        minimumContribution = 100 wei;
    }

      function checkBalance() public view returns(uint){
        return address(this).balance;
    } 

    //contributors can donate funds 
    function donateFunds() payable public {
        require(block.timestamp<=deadline,"Deadline is meet,you can't donate");
        require(msg.value>=minimumContribution,"Minimum donation rquired is 100 wei");
        require(msg.sender!= address(0));
        //managing record of contributors amount
        if(contributors[msg.sender]==0){   
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    //if deadline or target is not achieved means raised amount is less than required target contributor can refund his amount
    function refund() payable public{
        require(block.timestamp > deadline ,"deadline not exceeded yet");
        require(raisedAmount<target,"target achieved donation can't be refund");
        require(contributors[msg.sender]!=0,"you havn't contributed");
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
        raisedAmount-=msg.value;
    }

    //manager can make request for a particular project after specifying the details of the 
    //donation project , the receipent id for whom the donation is being gathered
    //contributors can then vote for proposal of their choice to 
    //then the project winning by the public majority will reccive the funds

    function makeRequestProposal(string memory _description, address _recipient,uint _amountNeeded) 
        public onlyOwner{
            Request storage _newRequest = requests[noOfRequests];
            _newRequest.description = _description;
            _newRequest.recipient= payable(_recipient);
            _newRequest.amountNeeded= _amountNeeded;
            //incrementin the total no of request proposal received
            noOfRequests++;
    }

    function castVote(uint _requestId) public {
        require(contributors[msg.sender]>0,"You haven't contributed");
        Request storage _newRequest = requests[_requestId];
        require(_newRequest.voters[msg.sender]==false,"you can't cast vote twice");
        _newRequest.voters[msg.sender]=true;
        _newRequest.noOfVoters++;
    }

    function withdrawAmount(uint _requestId) public onlyOwner{
        require(block.timestamp>deadline,"can't withdraw amount, deadline not exceeded");
        Request storage _newRequest = requests[_requestId];
        require(raisedAmount >= _newRequest.amountNeeded,"raised amount is lesser than amount needed");
        //redonation not possible
        require(_newRequest.isFunded==false,"donation has already made for this request");
        // require(_newRequest.amountNeeded<=raisedAmount,"raised amount is lesser than needed");
        uint noOfSupporters = _newRequest.noOfVoters;
        require(noOfSupporters>noOfContributors/2,"this request proposal is not supported by majority,try making another request");
        require(_newRequest.recipient!=address(0),"can't transfer to address zero");
        _newRequest.recipient.transfer(_newRequest.amountNeeded);
        _newRequest.isFunded=true;
        raisedAmount-=_newRequest.amountNeeded;
    }


    //owner can extend the duration and target when deploying new proposals
    function resetDurations(uint _target, uint _deadline) public onlyOwner{
        target = _target;
        //the current block time when the contract was deployed + next specified time both in secs
        deadline= block.timestamp+_deadline; 
    }

    function castedVote(uint _requestId,address _votterAddress) public view returns(bool){
        Request storage _newRequest = requests[_requestId];
        if(_newRequest.voters[_votterAddress]==false)
        return false;
        else
        return true;
    }
}