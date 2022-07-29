pragma solidity ^0.5.16;
import "./Campaign.sol";


//Campaign factory: This contract is used to deploy and keep track of deployed Campaigns
contract CampaignFactory{
    
    //list of all the deployed Campaigns
    address[] public deployedCampaigns;
    
    //deploys a new Campaign
    function createCampaign(
        address _manager, 
        string memory _title, 
        string memory _description, 
        uint _initialAmountGoal, 
        uint _createdAt,
        uint _closedAt) public {
        Campaign newCampaign = new Campaign( _manager, _title,  _description, _initialAmountGoal, _createdAt, _closedAt);
        deployedCampaigns.push(address(newCampaign));
    }
    
    function getCampaignsCount() public view returns(uint) {
        return deployedCampaigns.length;
    }
    
    function getDeployedCampaigns() public view returns(address[] memory){
        return deployedCampaigns;
    }
    
    function getLastDeployedContract() public view returns(address){
        return deployedCampaigns[deployedCampaigns.length-1];
    }
}

pragma solidity ^0.5.16;

//https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity

//A campaign is a single project used to collect funds from donors and spend them for any number of tasks related to a project,
//through fund request which is totally controlled by donors voting, if donors approve a request, it will be completed 
//and funds can be withdrawn otherwise funds are locked inside the contract.
contract Campaign{
    
    //Perosn model to hold a person's address & the delegated amount
    struct Person{
        address personAddress;
        uint amount;
    }
    
    //Fund request, required to take out  funds from this Campaign through requests for different tasks,
    //it takes three days for a request to complete, and requires alteast 51% donors approval to proceed,
    //otherwise won't complete, after completion of the request, donation can be transfered to the recipients,
    //whom were registered when the request was created.
    //The request, by default is considered to be approved by the donors, but if donors want to disapprove a request,
    //they have three days to explicitly disapprove it. After that, request would be considered approved by any donor,
    //who didn't disapproved it.
    struct FundRequest{
        
        //Breif description about the task
        string description;
        
        //The amount required for the task
        uint amount;
        
        //List of recipients, who will recieve the donation
        mapping(uint=>Person) recipients;
        
        //recipients count
        uint recipientsCount;
        
        //list of people who disapproves this request(by default request is considered to be approved by all donors,
        //that's why we just need the disapprovers lists & count)
        mapping(address=>bool) disapprovers;
        
        //disapprovers count
        uint disapproversCount;
        
        //represents a timestamp at which this request was created
        uint createdAt;
        
        //Indicates if the request is completed
        bool isCompleted;
        
        bool isClosed;
    }
    
    //=============================Public Properties=======================================//
    
    //Manager: Owner of the contract, can request funds for different tasks
    address public manager;
    
    //Campaign title
    string public title;
    
    //Breif description of the Campaign
    string public description;
    
    //Minimum amount of donation this contract must recieve to process the donations
    uint public amountInitialGoal;
    
     //the total amount of donations collected
    uint public amountCollected;
    
    //the amount delegated to fund requests
    uint public amountDelegated;
    
    //the total amount spended by this Campaign
    uint public amountSpended;
    
    //NOTE: donorsList starts at index 1 NOT at zero because we are tracking donors addresses for faster exists checks,
    //in another mapping(see below "donors") of address and index of that address in this array pointing to its amount.
    //
    //Donations made by donors
    Person[] public donorsList;
    
    //actual count of donors(NOTE: donorslist lenght won't represent the actual count because donors can be removed from middle of the array and will have empty dononrs then)
    uint public dononrsCount;
    
    //Donors address with and integer array pointing to donations array where donation amount is stored
    mapping(address=>uint) public donors;
    
    //Fund request by manager for certain task, donors can disapprove this, if 51% donors disapprove the request it will be considered cancled
    FundRequest[] fundRequests;
    
    //time required for a request to process if 51% of the donors approve it
    uint public fundRequestProcessTime; 
    
    //the timestamp at which the Campaign was created
    uint public createdAt;
    
    //the timestamp the Campaign will be closed (after Campaign is closed donations will be locked in the contract)
    uint public closedAt;
    
    //True till campaign is closed
    bool public isActive;
    
     //=============================Modifiers=======================================//
     
    modifier onlyManager(){ require(manager == msg.sender,'Only Manager can call this function'); _; }
    modifier onlyDonor(){ require( donors[msg.sender] > 0 ,'Only Donor can call this functions'); _; }
    modifier ifActive(){ require( isActive == true , 'Contract is closed'); _; }
    modifier hasReachedGoal(){ require( closedAt < now && amountCollected >=  amountInitialGoal , "Campaign hasn't reached its goal yet."); _; }
     
    //=============================Constructor=======================================//

    constructor(address _manager, string memory _title, string memory _description, uint _initialAmountGoal, uint _createdAt, uint _closedAt) public{
        require(_closedAt > _createdAt, 'Campaign start time must be less than end time.');
        require(_initialAmountGoal > uint(0) , 'Initial amount goal  must be greater than zero');
        
        manager = _manager;
        title = _title;
        description = _description;
        amountInitialGoal = _initialAmountGoal;
        createdAt = _createdAt;
        closedAt = _closedAt;
        fundRequestProcessTime = 259200;//equal to three days
        isActive = true;
        dononrsCount = 0;
        donorsList.push(Person({personAddress: address(0x0), amount: 0}));
    }

    //=============================Public Methods=======================================//
    
    //To donate funds for this Campaign, users can donate as many times as they want
    function donate() ifActive public payable {
        require(msg.value != uint(0),'Amount must be greater than zero');
        
        uint index = donors[msg.sender];

        //if donor hasn't donated any amount yet this would be true
        if(index == 0){
            index = 1;
            

            //add donor
            donorsList.push(
                Person({personAddress: msg.sender, amount: msg.value})
                );
                
            //add donor to mapping 
            donors[msg.sender] = donorsList.length - 1;
            dononrsCount++;
        }
        //if donor has donated before just add the new donation amount to the previous one
        else{
            
            uint prevAmount = donorsList[index].amount;
            donorsList[index].amount = prevAmount + msg.value;
        }
        
        //increase amount collected count
        amountCollected += msg.value;
    }
    
    //To withdraw the donations for certain time if user wants before Campaign is closed and Campaign donation goal is not achieved,
    //after thqt users will be able to donate but they won't be able to withdraw their donations
    function withdrawDonation() ifActive public returns(uint) {
        //donation can only be withdrawn in two cases
        //1. if donation goal couldn't be reached
        //2. if donation hasn't closed yet
        require(amountCollected < amountInitialGoal || closedAt > now,'Donation cannot be withdrawn');
        
        uint index = donors[msg.sender];
        
        //if donor doesn't exist return
        require(index > 0, "You have to be a donor in order to withdraw your donation");
        
        uint amount = donorsList[index].amount;
        if(amount > 0)
        {
            // delete donor from mapping;
            donors[msg.sender] = 0;
            
            //delete donor from list
            delete donorsList[index];
            
            //detect the amount collected
            amountCollected -= amount;
            
            dononrsCount--;
            
            //transfer funds
            msg.sender.transfer(amount);
        }
    }
    
    function createFundRequest(string memory _description, uint _amount, address[] memory _recipientsAddress, uint[] memory _recipientsAmount) hasReachedGoal ifActive onlyManager public{
        require(_amount > 0,'Amount cannot be zero.');
        require(_recipientsAddress.length > 0 && _recipientsAmount.length > 0, 'Request must contain atleast one recipient');
        require(_recipientsAddress.length == _recipientsAmount.length,'There should be equal no. of recipients addresses and amounts');
        require(amountCollected - amountSpended - amountDelegated >= _amount, "Campaign don't have enough funds for your request.");
        
        uint totalAmount = 0;
        for(uint i; i < _recipientsAmount.length; i++){
            totalAmount += _recipientsAmount[i];   
        }
        
        require(totalAmount == _amount, "Total amount delegated to recipients must be equal to the total amount in the request");
        
        fundRequests.push(
            FundRequest({description: _description, amount: _amount, recipientsCount: 0, createdAt: now, disapproversCount: 0, isCompleted: false, isClosed: false})
        );
        //get the added request
        FundRequest storage request = fundRequests[fundRequests.length - 1];
        
        mapping(uint=>Person) storage recipients = request.recipients;
        //add the recipients
        for(uint i = 0; i < _recipientsAddress.length; i++){
            recipients[i] = Person({personAddress: _recipientsAddress[i], amount: _recipientsAmount[i]});
            request.recipientsCount++;
        }
        
        amountDelegated += _amount;
    }
    
    function closeFundRequest(uint index) ifActive onlyDonor public{
        require(index < fundRequests.length, "Fund Request don't exist.");
        require(fundRequests[index].isCompleted == false,'Request has already been completed.');
        
        amountDelegated -= fundRequests[index].amount;
        fundRequests[index].isClosed = true;
    }
    
    function disapproveFundRequest(uint index) hasReachedGoal ifActive onlyDonor public{
        require(index < fundRequests.length, "Fund Request don't exist.");
        require(fundRequests[index].isCompleted == false,'Request has already been completed.');
        require(fundRequests[index].isClosed == false,'This Request has already been closed.');
        
        if(!fundRequests[index].disapprovers[msg.sender]){
            fundRequests[index].disapprovers[msg.sender] = true;
            fundRequests[index].disapproversCount++;
        }
    }
    
    function approveFundRequest(uint index) ifActive onlyDonor public{
        require(index < fundRequests.length, "Fund Request don't exist.");
        require(fundRequests[index].isCompleted == false,'Request has already been completed.');
        require(fundRequests[index].isClosed == false,'This Request has already been closed.');
        
        mapping(address=>bool) storage disapprovers = fundRequests[index].disapprovers;
        
        //only approve if donor disapproved the request before
        if(disapprovers[msg.sender]){
            //make aprover again
            disapprovers[msg.sender] = false;
            //decrease the disapprovers count
            fundRequests[index].disapproversCount--;
        }
    }
    
    function processFundRequest(uint index) ifActive onlyManager public{
        require(fundRequests[index].isClosed == false,'This Request has already been closed.');
        
        FundRequest storage request = fundRequests[index];
        require(
            request.createdAt + fundRequestProcessTime < now && 
            request.disapproversCount < donorsList.length &&
            !request.isCompleted  
          , "Fund Request cannot be processed, either the required time is not reached yet or most donors has disapproved it.");
          
            request.isCompleted = true;
            amountDelegated -= request.amount;
            amountSpended += request.amount;
            for(uint i = 0; i < request.recipientsCount; i++){
                Person storage recipient = request.recipients[i];
                //convert address to address payable (NOTE: this conversion differs around different versions of solidity)
                address(uint160(recipient.personAddress)).transfer(recipient.amount);
            }
        
    }
    
    function getFundRequest(uint index) public view returns(string memory,uint, uint, uint, uint, bool, bool, address[]memory, uint[]memory,bool){
        require(fundRequests.length + 1 > index,"Index is out of range.");
        
        //get the recipients
        FundRequest storage req = fundRequests[index];
        address[] memory addresses = new address[](req.recipientsCount);
        uint[] memory amounts = new uint[](req.recipientsCount);
        
        for(uint i = 0; i < req.recipientsCount; i++){
            addresses[i] = req.recipients[i].personAddress;
            amounts[i] = req.recipients[i].amount;
        }
        
        return(
            req.description,
            req.amount,
            req.recipientsCount,
            req.disapproversCount,
            req.createdAt,
            req.isCompleted,
            req.disapprovers[msg.sender],
            addresses,
            amounts,
            req.isClosed
            );
    }

    function getSummary()public view returns(
        address, string memory, string memory, uint, uint, uint, uint, uint, uint, uint, uint,uint, bool
        ){
        return (
            manager,
            title,
            description,
            amountInitialGoal,
            amountCollected,
            amountDelegated,
            amountSpended,
            fundRequestProcessTime,
            createdAt,
            closedAt,
            donorsList.length,
            fundRequests.length,
            isActive
            );
    }
    
    function setFundRequestProcessTime(uint processTime) ifActive  onlyManager  public {
        fundRequestProcessTime = processTime;
    }
 
    
    function deactivate() onlyManager public {
        require(amountCollected == amountSpended,"Campaign cannot be closed, because it still has some unspended funds");
        isActive = false;
    }
    
}