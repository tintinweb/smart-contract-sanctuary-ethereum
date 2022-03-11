/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.12;

 /// @author The CIS Team
 /// @title Car service center
 contract CarServiceCenter {

    struct Service {
        uint256 service_id;
        uint256 service_start_date;
        uint256 service_end_date;
        address customer_address;
        address service_creator;
        string status;
        uint256 service_cost ;
        bool withdrawStatment  ;
        bool depositFundByCustomer;
    
    }
    mapping(uint =>mapping(address=>bool)) public acknoledgement;
    mapping(uint => uint) public setIndexOfServiceId ;
    mapping(uint => address) public setServiceIdToAddress;
    uint256 private index = 0;
    Service[] private services;
    address public  owner;
     
    ///@dev initializing the deployer_address to the smart contract deployer
    constructor () 
    {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner,"only owner can call this methode");
      _;
   }

    /**@dev updating the index because _service_id mapped with index
    @notice creating the service and storing the service details
    @param _service_id , service_start_date which store service start date, _customer_address
    */
    function createService( uint256 _service_id, uint256 _service_start_date, address _customer_address,uint256 _service_cost)  public {

        require(setServiceIdToAddress[_service_id] == 0x0000000000000000000000000000000000000000," service id already exist");
        Service memory service;
        service.service_id = _service_id;
        service.service_start_date = _service_start_date;
        service.service_end_date = 0;
        service.customer_address = _customer_address;
        service.service_creator = msg.sender;
        service.status ="in progress";
        service.service_cost = _service_cost;
        service.withdrawStatment = false;
        service.depositFundByCustomer= false;
        services.push(service);
        setIndexOfServiceId[_service_id] = index;
        acknoledgement[_service_id][_customer_address]=false;
        acknoledgement[_service_id][msg.sender]=false;
        setServiceIdToAddress[_service_id] = _customer_address;
        index +=1;
    }
  
    /**@dev updating the index because service id mapped with index
    @notice check service creater called this method and then upadte the status
    @param _service_id , updateStatus with this update the service status
    */
    function updateServiceStatus(uint256 _service_id,string memory updateStatus) public {
        
        address customer_address  = setServiceIdToAddress[_service_id];
        require(customer_address != 0x0000000000000000000000000000000000000000," service id does'nt exist");
        require(services[setIndexOfServiceId[_service_id]].service_creator == msg.sender,"only service creator can update the status");
        services[setIndexOfServiceId[_service_id]].status = updateStatus;
    }

    /**@notice check service creater called this method and then upadte the service cost
    @param _service_id , _service_cost with this update the service cost
    */
    function updateServiceCost(uint256 _service_id,uint256 _service_cost) public {
        
        address customer_address  = setServiceIdToAddress[_service_id];
        require(customer_address != 0x0000000000000000000000000000000000000000," service id does'nt exist");
        require(services[setIndexOfServiceId[_service_id]].service_creator == msg.sender,"only service creator can update the status");
        services[setIndexOfServiceId[_service_id]].service_cost = _service_cost;
    }
    
    /**@dev updating the _acknowledgment_status which was intially false through nested mapping
    @param _service_id , address which take address of customer or service creator ,_acknoledgement_status true or false
    */
    function updateAcknowledgmentStatusForServiceCretor(uint256 _service_id,address _address,bool _acknoledgement_status) public {

        require(services[setIndexOfServiceId[_service_id]].service_creator == msg.sender,"only service creator can update the acknowledgement");
        require(services[setIndexOfServiceId[_service_id]].service_creator == _address,"entered wrong address ");
        acknoledgement[_service_id][_address]= _acknoledgement_status;
    }
    /**@dev updating the _acknowledgment_status which was intially false through nested mapping
    @param _service_id , address which take address of customer ,_acknoledgement_status -> true or false.
    */
    function updateAcknowledgmentStatusForCustomer(uint256 _service_id,address _address,bool _acknoledgement_status) public {
       
        address customer_address  = setServiceIdToAddress[_service_id];
        require(customer_address != 0x0000000000000000000000000000000000000000,"service id does'nt exist");
        require(services[setIndexOfServiceId[_service_id]].customer_address == msg.sender,"you cannot call this method through this address");
        require(services[setIndexOfServiceId[_service_id]].customer_address == _address,"entered wrong address");
        acknoledgement[_service_id][_address]= _acknoledgement_status;
    }
  
    /**@dev mapping of setIndexOfServiceId take _service_id and will give index of Services 
    @notice return the service details
    @param _service_id 'every service has a unique service id'
    @return  service_id 'unique id' 
    @return  service_start_date 'service start' 
    @return service_end_date ' end date of service '
    @return  customer_address 'address of customer'
    @return  service_creater 'address of service creator '
    @return   service_cost 'cost of the created service '
    @return  status 'current service status'
    @return  withdrawStatment 'service creator have withdraw the amount of service cost or not'
    */  

    function getServiceDetails (uint256 _service_id) public view 
        returns (
            uint256 service_id,
            uint256 service_start_date,
            uint256 service_end_date,
            address customer_address,
            address service_creater,
            uint256 service_cost,
            string memory status,
            bool withdrawStatment,
            bool depositFundByCustomer
         )
    {
        Service memory myService = services[setIndexOfServiceId[_service_id]];
        return (
            myService.service_id,
            myService.service_start_date,
            myService.service_end_date,
            myService.customer_address,
            myService.service_creator,
            myService.service_cost,
            myService.status,
            myService.withdrawStatment,
            myService.depositFundByCustomer
        );

    }    
   
    /**@dev msg.value should be more than or equal to service cost ,update the struc variable depositeFundByCustomer is true  
    @notice pay service cost through this method it will deposite to smart contract
    */
    function depositFund(uint256 _service_id) payable public {
        
        require(services[setIndexOfServiceId[_service_id]].customer_address == msg.sender,"only this service id customer can call this methode");
        require(msg.value == services[setIndexOfServiceId[_service_id]].service_cost  ,"incorrect amount for service cost");
        services[setIndexOfServiceId[_service_id]].depositFundByCustomer = true;
    }      
    
    /// @notice getting account balance
    function getBalance(address _address) public view returns(uint256 balance) {
      
        return(_address.balance);
    } 

    /**@dev service_creater address is payable withdraw fund after check all require conditions and update service status,withdrawStatment
    @notice service creater withdraw service cost using this methode
    @param _service_id  the unique service id of service
    @param  _service_creater_address   address of the service creater who create the service
    */
    function withdrawFund(uint256 _service_id,address _service_creater_address,uint256 _service_end_date )  public {
       
    
        address customer_address = services[setIndexOfServiceId[_service_id]].customer_address; 
        require(services[setIndexOfServiceId[_service_id]].service_creator == msg.sender,"only service creator of this service id can call this methode");
        require(acknoledgement[_service_id][customer_address] == true,"customer acknoledgement is not true");
        require(acknoledgement[_service_id][_service_creater_address] == true,"service creater acknoledgement is not true");
        require(services[setIndexOfServiceId[_service_id]].withdrawStatment != true ,"service amount already withdraw");
        updateServiceStatus(_service_id,"completed");
        services[setIndexOfServiceId[_service_id]].service_end_date = _service_end_date;
        payable(_service_creater_address).transfer(services[setIndexOfServiceId[_service_id]].service_cost);
        services[setIndexOfServiceId[_service_id]].withdrawStatment = true;
    }    
    

    /**@dev smart contract ether transfer to deploye_address,only deployer can call this methode  
    @notice deployer can transfer blocked or extra amount 
    @param _withdrawAmount amount of ether in term of wei
    */
    function withdraw(uint256 _withdrawAmount) public onlyOwner {

        require(address(this).balance >= _withdrawAmount,"invalid amount");
        payable(owner).transfer(_withdrawAmount);    
        
    }   
    
    /**@dev change smart contract deployer address but only owner can call this methode    
    @notice change smart the contract ownership
    */
    function transferOwnerShip(address _newowner ) public onlyOwner {
  
        owner = _newowner; 
    }   
    
    
 }