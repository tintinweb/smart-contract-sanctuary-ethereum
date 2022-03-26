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

    mapping (address => Developer) public developers;
    mapping (address => Client) public clients;
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

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event RegisterDeveloper(address _addr, string name, Language lang, uint256 rate);
    event RegisterClient(address _addr, string company);
    
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

}