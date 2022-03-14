//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "PiggyBankFundraise.sol";

contract PiggyBankFundraiseFactory {

PiggyBankFundraise[] private piggyBankFundraiseCampaigns; 
mapping(address => uint256) private addressToIndex; 

struct contractTimeFrame {
    uint _startAt;
    uint _recoverFundsAt;
    uint _retainFundsAt; 
}

struct contractState {
    bool _recoverFundsAvailable;
    bool _retainFundsAvailable;
    uint currentTime;
}

struct availableWithdrawMethods {
    bool _recoverFundsAvailable;
    bool _retrainFundsAvailable;
}

function createPiggyBankFundraiseContract(
    uint _fundingGoalWei, 
    string memory _fundingSummary, 
    uint _getBackFundsMin, 
    uint _clearContractMin
) public {
    PiggyBankFundraise piggyBankFundraise = new PiggyBankFundraise(msg.sender,_fundingGoalWei,_fundingSummary, _getBackFundsMin,_clearContractMin);

    piggyBankFundraiseCampaigns.push(piggyBankFundraise);
    uint256 arrayIndex = piggyBankFundraiseCampaigns.length-1; 
    addressToIndex[address(piggyBankFundraise)] = arrayIndex;
}

function getCurrentBlockTimestamp() public view returns (uint256){
    return block.timestamp;
}

function getAddressFromIndex(uint256 _storageIndex)
    public
    view
    returns(address)
    {
        return address(piggyBankFundraiseCampaigns[_storageIndex]);
    }

function getIndexFromAddress(address _address)
    public
    view
    returns(uint256)
    {
        return addressToIndex[_address];
    }

function contractsMade() public view returns (uint256){
    return piggyBankFundraiseCampaigns.length;
}


function callGetBalance(uint256 _storageIndex)
    public
    view
    returns(uint256)    
{
    return address(piggyBankFundraiseCampaigns[_storageIndex]).balance;
}


function amountDonatedInContract(address _client, uint _storageIndex) public view returns (uint256){
return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).addressToDonation(_client);
}

function callGetBackFunds(address _client, uint256 _storageIndex) public {
return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).getBackFunds(_client);
}

function callWithdrawAll(address _client, uint256 _storageIndex) public { 
return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).withdrawAll(_client);
}

function callDisburseFunds(address _client, uint256 _storageIndex) public {
return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).disburseFunds(_client);
}

function getContractOwner(uint256 _storageIndex) public view returns (address) {
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).owner();
}

function getFundingGoal(uint256 _storageIndex) public view returns (uint) {
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).fundingGoal();
}

function getFundingSummary(uint256 _storageIndex) public view returns (string memory){
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).fundingSummary();
}

function getCheckFundsWithdrawn(uint256 _storageIndex) public view returns (bool){
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).fundsWithdrawn();
}

function getCheckGoldenDonerSet(uint256 _storageIndex) public view returns (bool){
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).goldenDonerSet();
}

function getGoldenDoner(uint256 _storageIndex) public view returns (address) {
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).goldenDoner();
}

function getTargetReached(uint256 _storageIndex) public view returns (bool) {
    return PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).goldenDonerSet();
}

function getContractTimeFrames(uint256 _storageIndex) public view returns(contractTimeFrame memory){

    contractTimeFrame memory timeframe = contractTimeFrame(
        PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).startAt(),
        PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).recoverFundsAt(),
        PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).retainFundsAt()
    );
    return timeframe;
}

function getAvailableWithdrawMethods(uint256 _storageIndex) public view returns (availableWithdrawMethods memory){
    availableWithdrawMethods memory withdrawMethods = availableWithdrawMethods(
        PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).isRecoverFundsAvailable(),
        PiggyBankFundraise(piggyBankFundraiseCampaigns[_storageIndex]).isRetrainFundsAvailable()
    );

    return withdrawMethods;
}


}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PiggyBankFundraise {

    event Deposit(uint _amount, address _depositer, uint depositTime);
    event GoldenDonerSet(address goldenDoner, uint time);
    event WithdrawAll(uint amount, uint withdrawTime);


    address payable public owner; 
    uint public fundingGoal; 
    string public fundingSummary;
    address public goldenDoner; 
    
    uint public immutable startAt; 
    uint public immutable recoverFundsAt;
    uint public immutable retainFundsAt; 


    bool public fundsWithdrawn;
    bool public goldenDonerSet; 
 


    mapping(address => uint) public addressToDonation; 

    constructor(address _owner, uint _fundingGoal, string memory _fundingSummary, uint _getBackFundsMinute, uint _clearContractMinute){
        require(_clearContractMinute > _getBackFundsMinute, "clearContractMin time has to be larger than the getBackFundsMin time");
        owner = payable(_owner);
        fundingGoal = _fundingGoal;
        fundingSummary = _fundingSummary;
        startAt = block.timestamp;
        recoverFundsAt = startAt + _getBackFundsMinute*60;
        retainFundsAt = startAt + _clearContractMinute*60;
        fundsWithdrawn = false;
        goldenDonerSet = false;
       
    }

    modifier fundingGoalNotMet(){
        require(checkFundraisingTarget()==false, "funding goal has been reached."); 
        require(!fundsWithdrawn, "contract donation period has ended.");
        _;
    }

    modifier getBackFundsTime(){
        require(block.timestamp >= recoverFundsAt && block.timestamp < retainFundsAt, "not in fund recovery period");
      _;
    }

    modifier clearContractAvailable(address _client){
        require(_client == owner, "function access is only for owner"); 
        require(block.timestamp >= retainFundsAt, "retain funds period has not started");
        _;
    }

    modifier onlyOwner(address _client){
        require(_client ==owner, "function is only for owner");
        _;
    }

    function getTime() public view returns (uint256){
        return block.timestamp;
    }


    receive() external payable {
    require(!fundsWithdrawn,"fundraising campaign has ended, owner withdrew contract funds.");
    require(!goldenDonerSet, "final donation has been recieved");
    addressToDonation[msg.sender] += msg.value;
    if(checkFundraisingTarget()){
        goldenDonerSet = true;
        goldenDoner = msg.sender;
        emit GoldenDonerSet(msg.sender, block.timestamp);
    }
    emit Deposit(msg.value, msg.sender, block.timestamp);
    }

    function getBackFunds(address _client) external getBackFundsTime{
        require(checkFundraisingTarget()==false, "function not available, funding goal has been met.");
        uint donated = addressToDonation[_client];
        addressToDonation[_client] = 0;
        payable(_client).transfer(donated);
    }

    function getContractBalance() public view returns (uint256){
        return address(this).balance; 
    }

    function withdrawAll(address _client) public clearContractAvailable(_client) {
        require(_client== owner, "function available for owner only");
        require(!fundsWithdrawn, "fund withdraw has already been called");

        fundsWithdrawn = true;
        emit WithdrawAll(address(this).balance, block.timestamp);
        owner.transfer(address(this).balance);
    }

    function disburseFunds(address _client) public onlyOwner(_client) {
        require(!fundsWithdrawn, "fund withdraw has already been called");
        require(checkFundraisingTarget()==true, "funding goal not met");
        
        fundsWithdrawn = true;
        emit WithdrawAll(address(this).balance, block.timestamp);
        owner.transfer(address(this).balance);
    }

    function checkFundraisingTarget() internal view returns (bool) {
        if (address(this).balance >= fundingGoal){
            return true;    
            
        }
        return false;     
    } 

    function isRecoverFundsAvailable() public view returns (bool){
        if (block.timestamp >= recoverFundsAt && block.timestamp < retainFundsAt){
            return true;
        }

        return false;
    }

    function isRetrainFundsAvailable() public view returns (bool){
        if(block.timestamp >= retainFundsAt){
            return true;
        }
        return false;
    } 
}