/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//errors
error Transaction__Failed(uint256 value);
error Service__NotExists();
error NotEnough__Fee();
error Service_alreadyTaken();
error Not__Correct__Provider();
error Duplicated_Service_User();

/*
    Things to add/improve
    could add fees thtat deppenig on the state of the order you have to pay x --> could be done by percentage.
    @dev providers only one servicve at time

*/
contract Service {

    // Custom Types, Structs, enum....
    enum State {
        CREATED,
        REQUESTED,
        SHIPPING,
        SHIPPED
    }

    // this struct get stored in storage slot[1]

    struct ServiceStandard {
        State state;
        address provider;
        address user;
        string ServiceName;
        uint256 priceInUSD;
    }

    // events
    event serviceCreated(address provider, ServiceStandard serviceStruct);
    event availabelServices(ServiceStandard[] serviceAvailable);
    event requested(address _user, address provider, string serviceName);
    event ServicePurchased(address buyer, address Provider, ServiceStandard service);
    event ServiceRevocked(address user, ServiceStandard service);
    event ServiceProviderRevocked(address provider, ServiceStandard service);
    event ServiceShipped(address provider, address user, ServiceStandard service);
    event recieved(address);

    // state variables
    // mutex
    bool isLocked = false;
    // State private s_state;
    address public owner;
    // address public provider;
    uint256 public EthPrice;
    // not getting an array maybe do mapping
    ServiceStandard [] public serviceAvailable;


    mapping (address => mapping(address => ServiceStandard)) UserToProviderService;
    mapping (address => mapping(address => bool)) UserToProviderServiceExist;
    mapping (address => bool) WhiteListProvider;
    mapping (address => bool) hasRevokableService;
    mapping (address => uint) Providerfee;
    mapping (uint => ServiceStandard) IndexService;


    constructor(address _owner) {
        owner = _owner;
    }

    modifier OnlyValidatedProviders() {
        require(WhiteListProvider[msg.sender] = true);
        _;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier canRevoke() {
        require(hasRevokableService[msg.sender]);
        _;
    }

    /*

        bullet points:
        what makes a provider legit, a part of the fee, need more incentives or a way to ensure , maybe some in stake

    */

    function NewProvider(uint256 fee) public payable {
        // incentive for the provider to be loyal
        // pagar fianza hasta que el servicio acaba por si acaso (fee)
        require(!WhiteListProvider[msg.sender], "Already a provider");
        if (fee < 10^9) {
            revert NotEnough__Fee();
        }
        Providerfee[msg.sender] += fee;
        // create new provider
        WhiteListProvider[msg.sender] = true;
    }

    /*
        the service is passed as a parameter --> can we generate and pass it to the fuction.
        I do not know if this is possible, the other option will pass the parameters to the funciton needed ot crate the struct
        Create service pass all the arguments passed.
    */

    // the parameter create a copy in memory from storage
    function CreateService(ServiceStandard memory  _serviceStruct) public OnlyValidatedProviders {

        // so when i push the memory service I'm allocating it or not?
        serviceAvailable.push(_serviceStruct);
        emit serviceCreated(msg.sender, _serviceStruct);
        emit availabelServices(serviceAvailable);
    }

    /*
        Think that people can call the function even without interacting with the web page, so every funciton should be protected
        from attacks, so no space security hole.
    */

    function RequestService(uint256 _index, uint256 _EthPriceInWey) public payable {
        uint256 EthToPay;
        // track the service especific only one, but pay the provider
        ServiceStandard memory serviceRequested = serviceAvailable[_index];
        if (serviceRequested.state != State.CREATED) {
            revert Service_alreadyTaken();
        }
        // check no service with the smae provider and user i do not want
        if (UserToProviderServiceExist[serviceRequested.user][serviceRequested.provider]) {
            revert Duplicated_Service_User();
        }
        
        // ! service should lock after requested
        UserToProviderServiceExist[msg.sender][serviceRequested.provider] = true;
        UserToProviderService[msg.sender][serviceRequested.provider] = serviceRequested;

        // set the user
        serviceAvailable[_index].user = msg.sender;
        
        // pay the price for the request Service
        EthToPay = (serviceRequested.priceInUSD / (_EthPriceInWey)); // tranform in wei
        
        serviceRequested.state = State.REQUESTED; // prevent the reentrancy

        bool purchase = payable(serviceRequested.provider).send(msg.value);
        if (!purchase) {
            revert Transaction__Failed(EthToPay);
        }
        hasRevokableService[msg.sender] = true;
        // service Requested
        emit ServicePurchased(msg.sender, serviceRequested.provider, serviceRequested);
    }

    /*
        revoke should alseo change the mapping and varibles linked to them, reovoke not let the user chose the provider we get the provider
        by now only the provider can revoke a service, we could male a user revoke 
    */

    function ProviderRevokeService(uint256 _index) public OnlyValidatedProviders() {
        address _provider = serviceAvailable[_index].provider;
        if (_provider != msg.sender) {
            revert Not__Correct__Provider();
        }
        serviceAvailable[_index] = serviceAvailable[serviceAvailable.length - 1];
        serviceAvailable.pop();

        hasRevokableService[msg.sender] = false;
        emit ServiceProviderRevocked(msg.sender, serviceAvailable[_index]);
    }

    /*

    ? This will be added to let users revoke service Too

    function RevokeService(uint256 _index) public canRevoke() {

        uint index = _index;
        address _provider = serviceAvailable[index].provider;
        if (!UserToProviderServiceExist[msg.sender][_provider]) {
            revert Service__NotExists();
        }
        // equal the service that want't to be delated whit hte last
        serviceAvailable[index] = serviceAvailable[serviceAvailable.length - 1];
        // update the index of the last to the actual
        ServiceIndex[serviceAvailable[index].provider] = index;
        // remove the last value
        serviceAvailable.pop();
        //  you can delate maping using delate key "delete"
        delete UserToProviderService[msg.sender][_provider];
        UserToProviderServiceExist[msg.sender][_provider] = false;
        delete ProviderService[_provider];
        hasRevokableService[msg.sender] = false;
        emit ServiceRevocked(msg.sender, ProviderService[_provider]);
    }

    */

    /*
        Note that this functions coudl manage much more variables to do the changing of state, but for 
        this we are trying to provide a simple solution that could be implemetned in a future

        OnlyValidatedProviders can call this functions --> the serivce
    */

    function ChangeToShipping(uint256 _index) public OnlyValidatedProviders {
        if (serviceAvailable[_index].provider != msg.sender) {
            revert Not__Correct__Provider();
        }
        serviceAvailable[_index].state = State.SHIPPING;
    }

    /*
        with this being a demo we will not send ether at all, we just emit an event of the shipped service where we can see the
        price.
    */

    function ChangeToShipped(uint256 _index) public OnlyValidatedProviders {
         if (serviceAvailable[_index].provider != msg.sender) {
            revert Not__Correct__Provider();
        }
        // ! get the user --> when requested
        uint index = _index;
        require(!isLocked, "Function is locked sorry");
        isLocked = true;
        address user = serviceAvailable[_index].user;
        ServiceStandard memory temp_service = serviceAvailable[index];
        delete UserToProviderService[user][msg.sender];
        UserToProviderServiceExist[user][msg.sender];
        serviceAvailable[index].state  = State.SHIPPED;
        emit ServiceShipped(msg.sender, user, temp_service);
        Providerfee[msg.sender] = 0;
        serviceAvailable[index] = serviceAvailable[serviceAvailable.length - 1];
        serviceAvailable.pop();
        isLocked = false;
    }

    // GETTERS

    function getOwner() public view returns (address) {
        return(owner);
    }

    function isWhitelistProvider(address _provider) public view returns(bool) {
        return(WhiteListProvider[_provider]);
    }

    function GethasRevokableService() public view returns(bool) {
        return(hasRevokableService[msg.sender]);
    }

    function GetSender() public view returns(address) {
        return(msg.sender);
    }

    function getServiceLen() public view returns(uint) {
        return(serviceAvailable.length);
    }
}