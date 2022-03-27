// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title OutsourcingContract
 * @dev Implements create job process along with transfer 25% of budget to project manager
 */
contract Outsourcing {
    address private projectManager;
    uint256 public rateJava;
    uint256 public ratePython;

    enum Language { JAVA, PYTHON }
    enum JobStatus { 
        SUBMITTED,
        BUILD_AND_TEST,
        PENDING_COMPLETE_BUILD_AND_TEST,
        COMPLETE_BUILD_AND_TEST,
        CLIENT_ACCEPT_BUILD_AND_TEST,
        PENDING_CLIENT_CONFIRM_UAT,
        CLIENT_ACCEPT_UAT_COMPLETE,
        PENDING_IT_CONFIRM_DEPLOYMENT, 
        PENDING_CLIENT_CONFIRM_COMPLETED, 
        CLIENT_ACCEPT_DELIVERY_COMPLETE,
        COMPLETE, 
        CANCEL
    }

    mapping (address => Developer) public developers;
    mapping (address => Client) public clients;
    mapping(string => Project) public ticket;
    //Developer[] public developerList;
    
    // Struct develop => enum, lang, rate, name -> condition rate < manday rate && not dupplicate
    struct Developer {
        address addr;
        string name;
        Language lang;
        uint256 rate;
        bool available;
    }

    // Struct client => company name, name, role -> condition rate < manday rate && not dupplicate
    struct Client {
        address addr;
        string company;
    }

    struct Project {
        string ticketId;
        JobStatus status;
        address client;
        address[] listDevelopers;
        mapping (address => bool) developers;
        string checksum;
        uint256 budget;
    }

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event RegisterDeveloper(address _addr, string name, Language lang, uint256 rate);
    event RegisterClient(address _addr, string company);
    event SignAgreement(string ticketId, uint budget, address client, address manager, address[] _developers);
    event ChangeStatus(string ticketId, address _addr, JobStatus old_status, JobStatus new_status);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == projectManager, "Caller is not owner");
        _;
    }

    modifier isCientExisting(address _addr) {
        Client memory temp = clients[_addr];
        bytes memory tempEmptyStringTest = bytes(temp.company); // Uses memory
        
        require(tempEmptyStringTest.length == 0, "Your address already registered.");
        _;
    }

    modifier isDeveloperExisting(address _addr) {
        Developer memory temp = developers[_addr];
        bytes memory tempEmptyStringTest = bytes(temp.name); // Uses memory
        
        require(tempEmptyStringTest.length == 0, "Your address already registered.");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        projectManager = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), projectManager);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(projectManager, newOwner);
        projectManager = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return projectManager;
    }

    function setRateJava(uint256 _rate) public isOwner {
        rateJava = _rate;
    }

    function setRatePython(uint256 _rate) public isOwner {
        ratePython = _rate;
    }

    function registerDeveloper(string memory _name, Language _lang, uint256 _rate) public isDeveloperExisting(msg.sender) {
        require(bytes(_name).length > 0, "Name at least 1 charactor.");
        require(_rate > 0, "Rate must great than 0");

        Developer storage developer = developers[msg.sender];
        developer.addr = msg.sender;
        developer.name = _name;
        developer.lang = _lang;
        developer.rate = _rate;
        developer.available = true;

        emit RegisterDeveloper(msg.sender, _name, _lang, _rate);
    }

    function registerClient(string memory _company) public isCientExisting(msg.sender) {
        require(bytes(_company).length > 0, "Company name at least 1 charactor.");

        Client storage client = clients[msg.sender];
        client.company = _company;

        emit RegisterClient(msg.sender, _company);
    }

    // 0x19bFB4C85746bCaafC64d80c509409fDE7657b2f
    // 0.01 ETH = 10000000000000000
    function signAgreement(address[] memory _developers, address client, string memory ticketId, uint256 budget, string memory _checksum) public isOwner {
        // Validate
        require(budget > 0);
        require(_developers.length > 0);
        require(ticket[ticketId].budget == 0, "The ticket is already in use.");
        require(bytes(clients[client].company).length > 0, "The client has not yet been registered.");

        Project storage data = ticket[ticketId];
        data.ticketId = ticketId;
        data.status = JobStatus.SUBMITTED;
        data.client = client;
        data.listDevelopers = _developers;
        // initial developers
        for (uint i = 0; i < _developers.length; i++) {
            require(bytes(developers[_developers[i]].name).length > 0, "The developers aren't registered.");
            data.developers[_developers[i]] = true;
        }

        data.checksum = _checksum;
        data.budget = budget;

        emit SignAgreement(ticketId, budget, client, msg.sender, _developers);
    }

    function changeStatus(string memory ticketId, JobStatus _status) public {
        // require existing project
        require(ticket[ticketId].budget > 0, "The ticket does not exist.");

        Project storage data = ticket[ticketId];
        JobStatus currentStatus = data.status;
        
        if (_status == JobStatus.BUILD_AND_TEST) {
            // action role : Client
            require(currentStatus == JobStatus.SUBMITTED, "Invalid job status!");
            require(data.client == msg.sender, "Client only!!!");

            // transfer 25% of budget to ProjectManager (1/4) ---> 2
        }

        if (_status == JobStatus.PENDING_COMPLETE_BUILD_AND_TEST) {
            require(currentStatus == JobStatus.BUILD_AND_TEST, "Invalid job status!");
            require(data.developers[msg.sender] || msg.sender == projectManager , "PM or Dev only!!!");
        }

        if (_status == JobStatus.COMPLETE_BUILD_AND_TEST) {
            // action role : Project Manager
            require(currentStatus == JobStatus.PENDING_COMPLETE_BUILD_AND_TEST, "Invalid job status!");
        }

        if (_status == JobStatus.CLIENT_ACCEPT_BUILD_AND_TEST) {
            // action role : Client
            require(currentStatus == JobStatus.COMPLETE_BUILD_AND_TEST, "Invalid job status!");
            require(data.client == msg.sender, "Client only!!!");

            // transfer 25% of budget to ProjectManager (2/4) ---> 4
        }

        if (_status == JobStatus.PENDING_CLIENT_CONFIRM_UAT) {
            // action role : DEV
            require(currentStatus == JobStatus.CLIENT_ACCEPT_BUILD_AND_TEST, "Invalid job status!");
            require(data.developers[msg.sender] || msg.sender == projectManager , "PM or Dev only!!!");
        }

        if (_status == JobStatus.CLIENT_ACCEPT_UAT_COMPLETE) {
            // action role : Client
            require(currentStatus == JobStatus.PENDING_CLIENT_CONFIRM_UAT, "Invalid job status!");
            require(data.client == msg.sender, "Client only!!!");

            // transfer 25% of budget to ProjectManager (3/4) ---> 6
        }

        if (_status == JobStatus.PENDING_IT_CONFIRM_DEPLOYMENT) {
            // action role : DEV
            require(currentStatus == JobStatus.CLIENT_ACCEPT_UAT_COMPLETE, "Invalid job status!");
            require(data.developers[msg.sender] || msg.sender == projectManager , "PM or Dev only!!!");
        }

        if (_status == JobStatus.PENDING_CLIENT_CONFIRM_COMPLETED) {
            // action role : CLIENT
            require(currentStatus == JobStatus.PENDING_IT_CONFIRM_DEPLOYMENT, "Invalid job status!");
            require(data.developers[msg.sender] || msg.sender == projectManager , "PM or Dev only!!!");
        }

        if (_status == JobStatus.PENDING_IT_CONFIRM_DEPLOYMENT) {
            // action role : DEV
            require(currentStatus == JobStatus.CLIENT_ACCEPT_UAT_COMPLETE, "Invalid job status!");
            require(data.developers[msg.sender] || msg.sender == projectManager , "PM or Dev only!!!");
        }

        if (_status == JobStatus.PENDING_CLIENT_CONFIRM_COMPLETED) {
            // action role : DEV
            require(currentStatus == JobStatus.PENDING_IT_CONFIRM_DEPLOYMENT, "Invalid job status!");
            require(data.developers[msg.sender] || msg.sender == projectManager , "PM or Dev only!!!");
        }

        if (_status == JobStatus.CLIENT_ACCEPT_DELIVERY_COMPLETE) {
            // action role : Client
            require(currentStatus == JobStatus.PENDING_CLIENT_CONFIRM_COMPLETED, "Invalid job status!");
            require(data.client == msg.sender, "Client only!!!");

            // transfer 25% of budget to ProjectManager (4/4) ---> 9
        }

        if (_status == JobStatus.COMPLETE) {
            // action role : Project Manager
            require(currentStatus == JobStatus.CLIENT_ACCEPT_DELIVERY_COMPLETE, "Invalid job status!");
            require(msg.sender == projectManager, "Project manager only!!!");
        }

        if (_status == JobStatus.CANCEL) {
            // action role : Client
            require(currentStatus < JobStatus.COMPLETE, "Invalid job status!");
            require(data.client == msg.sender, "Client only!!!");
            // return currentBudget - fee from weth to client
        }
        
        // Set status project
        setStatusProject(ticketId, _status);

        emit ChangeStatus(ticketId, msg.sender, currentStatus, _status);
    }

    function setStatusProject(string memory ticketId, JobStatus _status) internal {
        Project storage project = ticket[ticketId];
        project.status = _status;
    }
}