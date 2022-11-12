// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./real_estate/RealEstate.sol";
import "./user/User.sol";

contract BaseContract {
    /**
     * @dev an administrator of these contracts
     */
    address public immutable i_contractCreator;
    /**
     * @dev Map(ownerAddress=>List<RealEstateAddress>)
     */
    mapping(address => address[]) public realEstate;
    /**
     * @dev contains the list of real estate address
     */
    address[] public realEstateList;

    address public userContract;

    modifier onlyOwner() {
        bool isAuthorized = User(userContract).usersRoles(msg.sender) == 2 ||
            msg.sender == i_contractCreator;
        require(isAuthorized, "YOU ARE NOT AUTHORIZED USER!");
        _;
    }

    modifier onlyBroker() {
        bool isAuthorized = User(userContract).usersRoles(msg.sender) == 3 ||
            msg.sender == i_contractCreator;
        require(isAuthorized, "YOU ARE NOT AUTHORIZED USER!");
        _;
    }

    modifier onlyAdmin() {
        bool isAuthorized = msg.sender == i_contractCreator;
        require(isAuthorized, "YOU ARE NOT AUTHORIZED ADMIN!");
        _;
    }

    constructor(address _userContract) {
        userContract = _userContract;
        i_contractCreator = msg.sender;
    }

    function addRealEstate(address _owner) public onlyOwner {
        address _realEstate = address(
            new RealEstate(msg.sender, address(this))
        );
        realEstateList.push(_realEstate);
        realEstate[msg.sender].push(_realEstate);
        User(userContract).addRealEstate(_owner, _realEstate);
    }

    function getRealEstateList()
        public
        view
        onlyBroker
        returns (address[] memory)
    {
        return realEstateList;
    }

    function setBrokerPropertyToRealEstate(
        address _realEstateAddress,
        address _brokerAddress
    ) public onlyAdmin {
        /**
         * @dev keep in mind that don't forget to add a feature to authorize the brokeraddress
         */
        RealEstate(_realEstateAddress).setBrokerAddressInPreparation(
            _brokerAddress
        );
        User(userContract).addBrokerJob(_brokerAddress, _realEstateAddress);

        // RealEstate(_realEstateAddress).setDueDiligenceContract(_brokerAddress);
        // PropertyBroker()
    }

    /**
     * @dev insert a new real estate contract into the real estate map according to the owner address
     */
    // function addRealEstate(address _owner, address _realEstate) public {
    //     realEstate[_owner].push(_realEstate);
    //     realEstateList.push(_realEstate);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PropertyOwner.sol";
import "./PropertyBroker.sol";
import "./ExternalAdvisor.sol";
import "./ProspectiveBuyer.sol";
import "./IUser.sol";

contract User {
    /**
     * @dev contains all users address
     */
    address[] public users;

    /**
     * @dev mapping the roles based on the address
     * @dev map[key<address>, value<uint>] => [userAddress, role]
     * @dev role:
     *      1 => ADMIN
     *      2 => OWNER
     *      3 => BROKER
     *      4 => EXTERNAL ADVISOR
     *      5 => PROSPECTIVE BUYER
     */
    mapping(address => uint) public usersRoles;

    /**
     * @dev is used for mapping the deployed contract address based on the given role key
     * @dev map[key<uint>, value<address>] => [role, userContractAddress]
     * @dev mapping:
     *      [2, propertyOwnerContract]
     *      [3, propertyBrokerContract]
     *      [4, externalAdvisorContract]
     *      [5, prospectiveBuyerContract]
     */
    mapping(uint => address) public usersContracts;

    /**
     * contains the admin address
     */
    address public admin;

    modifier onlyUser(address userAddress) {
        bool userOnly = usersRoles[userAddress] == 1 ||
            usersRoles[userAddress] == 2 ||
            usersRoles[userAddress] == 3 ||
            usersRoles[userAddress] == 4 ||
            usersRoles[userAddress] == 5;

        require(userOnly, "only user");
        _;
    }

    constructor(
        address _propertyOwner,
        address _propertyBroker,
        address _externalAdvisor,
        address _prospectiveBuyer
    ) {
        usersContracts[2] = _propertyOwner;
        usersContracts[3] = _propertyBroker;
        usersContracts[4] = _externalAdvisor;
        usersContracts[5] = _prospectiveBuyer;

        PropertyOwner(usersContracts[2]).setUserContract(address(this));
        PropertyOwner(usersContracts[3]).setUserContract(address(this));
        PropertyOwner(usersContracts[4]).setUserContract(address(this));
        PropertyOwner(usersContracts[5]).setUserContract(address(this));

        admin = msg.sender;

        initAccounts();
        registerAccount(msg.sender, 1);
    }

    /**
     * @dev is used to register the user account based on its role
     */
    function registerAccount(address userAddress, uint role) public {
        users.push(userAddress);
        usersRoles[userAddress] = role;

        if (role == 0 || role == 1) return;
        PropertyOwner(usersContracts[role]).registerUser(userAddress);
    }

    /**
     * @dev is used for testing purposes only
     */
    function initAccounts() private {
        // admin
        registerAccount(msg.sender, 1);

        // owner
        registerAccount(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 2);

        // broker
        registerAccount(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 3);

        // external advisor
        registerAccount(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 4);

        // buyer
        registerAccount(0x976EA74026E726554dB657fA54763abd0C3a0aa9, 5);
    }

    function addBrokerJob(address _brokerAddress, address _realEstateAddress)
        public
    {
        PropertyBroker(usersContracts[3]).addJob(
            _brokerAddress,
            _realEstateAddress
        );
    }

    function addRealEstate(address _owner, address _realEstate) public {
        PropertyOwner(usersContracts[2]).addOwnerRealEstates(
            _owner,
            _realEstate
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Preparation.sol";
import "./DueDiligence.sol";
import "./Completion.sol";
import "../user/PropertyOwner.sol";
import "../user/User.sol";

contract RealEstate {
    // /**
    //  * @dev preparation contract address
    //  */
    // Preparation public preparation;
    // /**
    //  * @dev due diligence contract address
    //  */
    // DueDiligence public dueDiligence;
    // /**
    //  * @dev completion contract address
    //  */
    // Completion public completion;

    /**
     * @dev preparation contract address
     */
    address public preparation;
    /**
     * @dev due diligence contract address
     */
    address public dueDiligence;
    /**
     * @dev completion contract address
     */
    address public completion;
    address public baseContract;

    constructor(address _owner, address _baseContractAddress) {
        preparation = address(
            new Preparation(_owner, address(this), _baseContractAddress)
        );
        baseContract = _baseContractAddress;
        // PropertyOwner(msg.sender).addOwnerRealEstates(
        //     msg.sender,
        //     address(preparation)
        // );
    }

    function setBrokerAddressInPreparation(address _broker) public {
        require(
            msg.sender == baseContract,
            "only base contract who execute this action!"
        );
        Preparation(preparation).setBrokerAddress(_broker);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";
import "./User.sol";

contract PropertyBroker is IUser {
    event brokerCreation(address indexed broker);

    struct Broker {
        string name;
    }

    struct Data {
        bool isFilled;
        Broker broker;
    }

    mapping(address => Data) public propertyBrokers;
    address[] public propertyBrokerList;
    /**
     * @dev contains the list of the broker property working on
     * mapping(broker => realEstate[])
     */
    mapping(address => address[]) public realEstateContractAddress;

    address public admin;
    address public userContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(address _userAddress)
        external
        override
    // onlyUserContract
    {
        propertyBrokers[_userAddress].isFilled = true;
        propertyBrokerList.push(_userAddress);
        emit brokerCreation(_userAddress);
    }

    function insertData(string memory name) public {
        propertyBrokers[msg.sender].isFilled = true;
        propertyBrokers[msg.sender].broker = Broker(name);
    }

    function setUserContract(address _userContract) external override {
        require(
            userContract == address(0),
            "You are prohibited to change the existing data!"
        );
        userContract = _userContract;
    }

    function addJob(address _brokerAddress, address _realEstateAddress)
        public
        onlyUserContract
    {
        realEstateContractAddress[_brokerAddress].push(_realEstateAddress);
    }

    function getPropertyBrokerList() public view returns (address[] memory) {
        return propertyBrokerList;
    }

    function getRealEstateContractAddressList(address _broker)
        public
        view
        returns (address[] memory)
    {
        return realEstateContractAddress[_broker];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";
import "../real_estate/RealEstate.sol";

contract PropertyOwner is IUser {
    event ownerCreation(address indexed owner);

    /**
     * @dev describes the properties that owners should have
     */
    struct Owner {
        address ownerAddress;
        string name;
    }

    /**
     * @dev contains isFilled field that indicates the existance of the owner data
     */
    struct Data {
        bool isFilled;
        Owner owner;
    }

    // address[] public propertyOwners;
    mapping(address => Data) public propertyOwners;

    /**
     * @dev contains the admin address
     */
    address public admin;
    address public userContract;

    /**
     * @dev contains a list of real estate contracts address
     */
    mapping(address => address[]) public ownerRealEstates;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /**
     * @dev the function that is called from the user contract
     */
    function registerUser(address _userAddress)
        external
        override
        onlyUserContract
    {
        propertyOwners[_userAddress].isFilled = true;
        emit ownerCreation(_userAddress);
    }

    /**
     * @dev the function that is called from the DApp
     */
    function insertData(string memory name) public {
        propertyOwners[msg.sender].isFilled = true;
        propertyOwners[msg.sender].owner = Owner(msg.sender, name);
    }

    function setUserContract(address _userContract) external override {
        require(
            userContract == address(0),
            "You are prohibited to change the existing data!"
        );
        userContract = _userContract;
    }

    function addOwnerRealEstates(address _owner, address _realEstate) public {
        ownerRealEstates[_owner].push(_realEstate);
    }

    function getOwnerRealEstates(address _owner)
        public
        view
        returns (address[] memory)
    {
        return ownerRealEstates[_owner];
    }

    // function createRealEstate() public {
    //     RealEstate realEstate = new RealEstate();
    //     addOwnerRealEstates(msg.sender, address(realEstate));
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUser {
    function registerUser(address _userAddress) external;

    function setUserContract(address _userContract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract ExternalAdvisor is IUser {
    event externalAdvisorCreation(address indexed externalAdvisor);

    struct ExternalAdvisorUser {
        address brokerAddress;
        string name;
    }

    struct Data {
        bool isFilled;
        ExternalAdvisorUser owner;
    }

    mapping(address => Data) externalAdvisors;

    address public admin;
    address public userContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(address _userAddress)
        external
        override
    // onlyUserContract
    {
        externalAdvisors[_userAddress].isFilled = true;
        emit externalAdvisorCreation(_userAddress);
    }

    function insertData(string memory name) public {
        externalAdvisors[msg.sender].isFilled = true;
        externalAdvisors[msg.sender].owner = ExternalAdvisorUser(
            msg.sender,
            name
        );
    }

    function setUserContract(address _userContract) external override {
        require(
            userContract == address(0),
            "You are prohibited to change the existing data!"
        );
        userContract = _userContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IUser.sol";

contract ProspectiveBuyer is IUser {
    event prospectiveBuyerCreation(address indexed buyer);

    struct Buyer {
        address brokerAddress;
        string name;
    }

    struct Data {
        bool isFilled;
        Buyer owner;
    }

    mapping(address => Data) prospectiveBuyers;

    address public admin;
    address public userContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlyUserContract() {
        require(msg.sender == userContract, "not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(address _userAddress)
        external
        override
    // onlyUserContract
    {
        prospectiveBuyers[_userAddress].isFilled = true;
        emit prospectiveBuyerCreation(_userAddress);
    }

    function insertData(string memory name) public {
        prospectiveBuyers[msg.sender].isFilled = true;
        prospectiveBuyers[msg.sender].owner = Buyer(msg.sender, name);
    }

    function setUserContract(address _userContract) external override {
        require(
            userContract == address(0),
            "You are prohibited to change the existing data!"
        );
        userContract = _userContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RealEstate.sol";

contract DueDiligence {
    /**
     * @dev real estate contract
     */
    RealEstate public realEstate;
    address public broker;
    address public externalAdvisor;

    constructor(address _broker, address _realEstate) {
        broker = _broker;
        realEstate = RealEstate(_realEstate);
    }

    function setExternalAdvisor(address _externalAdvisor) public {
        require(
            externalAdvisor == address(0),
            "broker address has already registered!"
        );

        externalAdvisor = _externalAdvisor;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RealEstate.sol";

/**
 * @notice
 * this contract is used for the preparation phase
 * of the property transaction
 */
contract Preparation {
    /**
     * @notice
     * is fired by property owners when submitting the form
     */
    event SubmitForm(bool status);
    /**
     * @notice
     * is fired by property brokers
     * @notice
     * is used to notify property owners whether the submitted form
     * is approved or rejected by a propery broker
     */
    event UpdateFormStatus(address owner, bool status);
    /**
     * @notice is used to notify that the preparation phase is done
     */
    event FinishPreparationPhase(address owner, address broker);

    /**
     * @notice address of a property owner
     */
    address public owner;
    /**
     * @notice address of a property broker
     */
    address public broker;
    /**
     * @dev RealEstate contract
     */
    RealEstate public realEstate;
    /**
     * @notice is used to indicate whether the submitted form is approved or not
     *         depending on the boolean value
     */
    bool public formApproved = false;
    /**
     * @notice is used to indicate whether or not the multi-signature is executed
     */
    mapping(address => bool) public multiSigApproved;
    struct FormData {
        string data1;
        string data2;
        string data3;
    }
    /**
     * @notice this is where property owners store their formData
     */
    FormData public formData;
    address public baseContractAddress;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyBroker() {
        require(msg.sender == broker, "not broker");
        _;
    }

    modifier onlyRealEstate() {
        require(msg.sender == address(realEstate), "not Real Estate");
        _;
    }

    /**
     * @notice since this contract is created by property owner.
     *         the address of broker property will be automatically assigned by the system
     */
    constructor(
        address _owner,
        address _realEstate,
        address _baseContract
    ) {
        realEstate = RealEstate(_realEstate);
        owner = _owner;
        multiSigApproved[owner] = false;
        baseContractAddress = _baseContract;
    }

    function setBrokerAddress(address _broker) public onlyRealEstate {
        require(broker == address(0), "broker can only be setted once");

        broker = _broker;
        multiSigApproved[broker] = false;
    }

    /**
     * @notice is used to store the formData property to be checked by the broker
     * @notice only owner can execute this function
     * @notice once the broker has notified, they can execute the setApproved function
     *         to give a sign whether the proposed form is approved or not
     * @dev the data will be NFT in the future
     */
    function submitFormData(
        string memory data1,
        string memory data2,
        string memory data3
    ) public onlyOwner {
        require(
            formApproved == false,
            "the form is already submitted, please wait for the property broker to check your submitted form"
        );

        formData = FormData(data1, data2, data3);
        signContract(true);
        emit SubmitForm(true);
    }

    function signContract(bool _approved) public {
        require(
            msg.sender == owner || msg.sender == broker,
            "unauthenticated user"
        );
        multiSigApproved[msg.sender] = _approved;
        if (multiSigApproved[owner] && multiSigApproved[broker]) {
            _finishPreparationPhase();
        }
    }

    // /**
    //  * @notice is used to update the approved property
    //  * @notice only broker can execute this function
    //  */
    // function setFormApproval(bool _approved) public onlyBroker {
    //     formApproved = _approved;

    //     if (formApproved) {
    //         emit UpdateFormStatus(owner, true);
    //         signTransaction();
    //     } else {
    //         emit UpdateFormStatus(owner, false);
    //     }
    // }

    // function signTransaction() public {
    //     require(
    //         msg.sender == owner || msg.sender == broker,
    //         "unauthenticated user"
    //     );
    //     require(formApproved, "the form is not approved yet");

    //     multiSigApproved[msg.sender] = true;

    //     if (multiSigApproved[owner] && multiSigApproved[broker]) {
    //         _finishPreparationPhase();
    //     }
    // }

    function _finishPreparationPhase() private {
        // realEstate.setDueDiligenceContract(broker);
        emit FinishPreparationPhase(owner, broker);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Completion {}