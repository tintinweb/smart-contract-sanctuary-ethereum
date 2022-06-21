pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IModuleRegistry.sol";
import "./interfaces/IModuleFactory.sol";
import "./interfaces/ISecurityTokenRegistry.sol";
import "./interfaces/IPolymathRegistry.sol";
import "./interfaces/IFeatureRegistry.sol";
import "./libraries/VersionUtils.sol";
import "./storage/EternalStorage.sol";
import "./libraries/Encoder.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/ISecurityToken.sol";

/**
* @title Registry contract to store registered modules
* @notice Only Polymath can register and verify module factories to make them available for issuers to attach.
*/
contract ModuleRegistry is IModuleRegistry, EternalStorage {
    /*
        // Mapping used to hold the type of module factory corresponds to the address of the Module factory contract
        mapping (address => uint8) public registry;

        // Mapping used to hold the reputation of the factory
        mapping (address => address[]) public reputation;

        // Mapping containing the list of addresses of Module Factories of a particular type
        mapping (uint8 => address[]) public moduleList;

        // Mapping to store the index of the Module Factory in the moduleList
        mapping(address => uint8) private moduleListIndex;

        // contains the list of verified modules
        mapping (address => bool) public verified;

    */

    bytes32 constant INITIALIZE = 0x9ef7257c3339b099aacf96e55122ee78fb65a36bd2a6c19249882be9c98633bf; //keccak256("initialised")
    bytes32 constant LOCKED = 0xab99c6d7581cbb37d2e578d3097bfdd3323e05447f1fd7670b6c3a3fb9d9ff79; //keccak256("locked")
    bytes32 constant POLYTOKEN = 0xacf8fbd51bb4b83ba426cdb12f63be74db97c412515797993d2a385542e311d7; //keccak256("polyToken")
    bytes32 constant PAUSED = 0xee35723ac350a69d2a92d3703f17439cbaadf2f093a21ba5bf5f1a53eb2a14d9; //keccak256("paused")
    bytes32 constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; //keccak256("owner")
    bytes32 constant POLYMATHREGISTRY = 0x90eeab7c36075577c7cc5ff366e389fefa8a18289b949bab3529ab4471139d4d; //keccak256("polymathRegistry")
    bytes32 constant FEATURE_REGISTRY = 0xed9ca06607835ad25ecacbcb97f2bc414d4a51ecf391b5ae42f15991227ab146; //keccak256("featureRegistry")
    bytes32 constant SECURITY_TOKEN_REGISTRY = 0x12ada4f7ee6c2b7b933330be61fefa007a1f497dc8df1b349b48071a958d7a81; //keccak256("securityTokenRegistry")

    ///////////////
    //// Modifiers
    ///////////////

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner(), "sender must be owner");
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPausedOrOwner() {
        _whenNotPausedOrOwner();
        _;
    }

    function _whenNotPausedOrOwner() internal view {
        if (msg.sender != owner()) {
            require(!isPaused(), "Paused");
        }
    }

    /**
     * @notice Modifier to prevent reentrancy
     */
    modifier nonReentrant() {
        set(LOCKED, getUintValue(LOCKED) + 1);
        uint256 localCounter = getUintValue(LOCKED);
        _;
        require(localCounter == getUintValue(LOCKED));
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused and ignore is msg.sender is owner.
     */
    modifier whenNotPaused() {
        require(!isPaused(), "Already paused");
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(isPaused(), "Should not be paused");
        _;
    }

    /////////////////////////////
    // Initialization
    /////////////////////////////

    // Constructor
    constructor() public {

    }

    function initialize(address _polymathRegistry, address _owner) external payable {
        require(!getBoolValue(INITIALIZE), "already initialized");
        require(_owner != address(0) && _polymathRegistry != address(0), "0x address is invalid");
        set(POLYMATHREGISTRY, _polymathRegistry);
        set(OWNER, _owner);
        set(PAUSED, false);
        set(INITIALIZE, true);
    }

    function _customModules() internal view returns (bool) {
        return IFeatureRegistry(getAddressValue(FEATURE_REGISTRY)).getFeatureStatus("customModulesAllowed");
    }


    /**
     * @notice Called by a SecurityToken (2.x) to check if the ModuleFactory is verified or appropriate custom module
     * @dev ModuleFactory reputation increases by one every time it is deployed(used) by a ST.
     * @dev Any module can be added during token creation without being registered if it is defined in the token proxy deployment contract
     * @dev The feature switch for custom modules is labelled "customModulesAllowed"
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external {
        useModule(_moduleFactory, false);
    }

    /**
     * @notice Called by a SecurityToken to check if the ModuleFactory is verified or appropriate custom module
     * @dev ModuleFactory reputation increases by one every time it is deployed(used) by a ST.
     * @dev Any module can be added during token creation without being registered if it is defined in the token proxy deployment contract
     * @dev The feature switch for custom modules is labelled "customModulesAllowed"
     * @param _moduleFactory is the address of the relevant module factory
     * @param _isUpgrade whether or not the function is being called as a result of an upgrade
     */
    function useModule(address _moduleFactory, bool _isUpgrade) public nonReentrant {
        if (_customModules()) {
            require(
                getBoolValue(Encoder.getKey("verified", _moduleFactory)) || getAddressValue(Encoder.getKey("factoryOwner", _moduleFactory))
                    == IOwnable(msg.sender).owner(),
                "ModuleFactory must be verified or SecurityToken owner must be ModuleFactory owner"
            );
        } else {
            require(getBoolValue(Encoder.getKey("verified", _moduleFactory)), "ModuleFactory must be verified");
        }
        // This if statement is required to be able to add modules from the STFactory contract during deployment
        // before the token has been registered to the STR.
        if (ISecurityTokenRegistry(getAddressValue(SECURITY_TOKEN_REGISTRY)).isSecurityToken(msg.sender)) {
            require(isCompatibleModule(_moduleFactory, msg.sender), "Incompatible versions");
            if (!_isUpgrade) {
                pushArray(Encoder.getKey("reputation", _moduleFactory), msg.sender);
                emit ModuleUsed(_moduleFactory, msg.sender);
            }
        }
    }

    /**
     * @notice Check that a module and its factory are compatible
     * @param _moduleFactory is the address of the relevant module factory
     * @param _securityToken is the address of the relevant security token
     * @return bool whether module and token are compatible
     */
    function isCompatibleModule(address _moduleFactory, address _securityToken) public view returns(bool) {
        uint8[] memory _latestVersion = ISecurityToken(_securityToken).getVersion();
        uint8[] memory _lowerBound = IModuleFactory(_moduleFactory).getLowerSTVersionBounds();
        uint8[] memory _upperBound = IModuleFactory(_moduleFactory).getUpperSTVersionBounds();
        bool _isLowerAllowed = VersionUtils.lessThanOrEqual(_lowerBound, _latestVersion);
        bool _isUpperAllowed = VersionUtils.greaterThanOrEqual(_upperBound, _latestVersion);
        return (_isLowerAllowed && _isUpperAllowed);
    }

    /**
     * @notice Called by the ModuleFactory owner to register new modules for SecurityTokens to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external whenNotPausedOrOwner nonReentrant {
        address factoryOwner = IOwnable(_moduleFactory).owner();
        // This is set statically to avoid having to call back out to unverified factories to determine owner
        set(Encoder.getKey("factoryOwner", _moduleFactory), factoryOwner);
        if (_customModules()) {
            require(
                msg.sender == factoryOwner || msg.sender == owner(),
                "msg.sender must be the Module Factory owner or registry curator"
            );
        } else {
            require(msg.sender == owner(), "Only owner allowed to register modules");
        }
        require(getUintValue(Encoder.getKey("registry", _moduleFactory)) == 0, "Module factory should not be pre-registered");
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        //Enforce type uniqueness
        uint256 i;
        uint256 j;
        uint8[] memory moduleTypes = moduleFactory.getTypes();
        for (i = 1; i < moduleTypes.length; i++) {
            for (j = 0; j < i; j++) {
                require(moduleTypes[i] != moduleTypes[j], "Type mismatch");
            }
        }
        require(moduleTypes.length != 0, "Factory must have type");
        // NB - here we index by the first type of the module.
        uint8 moduleType = moduleTypes[0];
        require(uint256(moduleType) != 0, "Invalid type");
        set(Encoder.getKey("registry", _moduleFactory), uint256(moduleType));
        set(
            Encoder.getKey("moduleListIndex", _moduleFactory),
            uint256(getArrayAddress(Encoder.getKey("moduleList", uint256(moduleType))).length)
        );
        pushArray(Encoder.getKey("moduleList", uint256(moduleType)), _moduleFactory);
        emit ModuleRegistered(_moduleFactory, factoryOwner);
    }

    /**
     * @notice Called by the ModuleFactory owner or registry curator to delete a ModuleFactory from the registry
     * @param _moduleFactory is the address of the module factory to be deleted from the registry
     */
    function removeModule(address _moduleFactory) external whenNotPausedOrOwner {
        uint256 moduleType = getUintValue(Encoder.getKey("registry", _moduleFactory));

        require(moduleType != 0, "Module factory should be registered");
        require(
            msg.sender == owner() || msg.sender == getAddressValue(Encoder.getKey("factoryOwner", _moduleFactory)),
            "msg.sender must be the Module Factory owner or registry curator"
        );
        uint256 index = getUintValue(Encoder.getKey("moduleListIndex", _moduleFactory));
        uint256 last = getArrayAddress(Encoder.getKey("moduleList", moduleType)).length - 1;
        address temp = getArrayAddress(Encoder.getKey("moduleList", moduleType))[last];

        // pop from array and re-order
        if (index != last) {
            // moduleList[moduleType][index] = temp;
            setArrayIndexValue(Encoder.getKey("moduleList", moduleType), index, temp);
            set(Encoder.getKey("moduleListIndex", temp), index);
        }
        deleteArrayAddress(Encoder.getKey("moduleList", moduleType), last);

        // delete registry[_moduleFactory];
        set(Encoder.getKey("registry", _moduleFactory), uint256(0));
        // delete reputation[_moduleFactory];
        setArray(Encoder.getKey("reputation", _moduleFactory), new address[](0));
        // delete verified[_moduleFactory];
        set(Encoder.getKey("verified", _moduleFactory), false);
        // delete moduleListIndex[_moduleFactory];
        set(Encoder.getKey("moduleListIndex", _moduleFactory), uint256(0));
        // delete module owner
        set(Encoder.getKey("factoryOwner", _moduleFactory), address(0));
        emit ModuleRemoved(_moduleFactory, msg.sender);
    }

    /**
    * @notice Called by Polymath to verify Module Factories for SecurityTokens to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST)
    * @notice -> Only if Polymath enabled the feature.
    * @param _moduleFactory is the address of the module factory to be verified
    */
    function verifyModule(address _moduleFactory) external onlyOwner {
        require(getUintValue(Encoder.getKey("registry", _moduleFactory)) != uint256(0), "Module factory must be registered");
        set(Encoder.getKey("verified", _moduleFactory), true);
        emit ModuleVerified(_moduleFactory);
    }

    /**
    * @notice Called by Polymath to verify Module Factories for SecurityTokens to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST)
    * @notice -> Only if Polymath enabled the feature.
    * @param _moduleFactory is the address of the module factory to be verified
    */
    function unverifyModule(address _moduleFactory) external nonReentrant {
        // Can be called by the registry owner, the module factory, or the module factory owner
        bool isOwner = msg.sender == owner();
        bool isFactory = msg.sender == _moduleFactory;
        bool isFactoryOwner = msg.sender == getAddressValue(Encoder.getKey("factoryOwner", _moduleFactory));
        require(isOwner || isFactory || isFactoryOwner, "Not authorised");
        require(getUintValue(Encoder.getKey("registry", _moduleFactory)) != uint256(0), "Module factory must be registered");
        set(Encoder.getKey("verified", _moduleFactory), false);
        emit ModuleUnverified(_moduleFactory);
    }

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @param _securityToken is the token
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[] memory, address[] memory) {
        address[] memory modules = getModulesByTypeAndToken(_moduleType, _securityToken);
        return _tagsByModules(modules);
    }

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[] memory, address[] memory) {
        address[] memory modules = getModulesByType(_moduleType);
        return _tagsByModules(modules);
    }

    /**
     * @notice Returns all the tags related to the modules provided
     * @param _modules modules to return tags for
     * @return list of tags
     * @return corresponding list of module factories
     */
    function _tagsByModules(address[] memory _modules) internal view returns(bytes32[] memory, address[] memory) {
        uint256 counter = 0;
        uint256 i;
        uint256 j;
        for (i = 0; i < _modules.length; i++) {
            counter = counter + IModuleFactory(_modules[i]).getTags().length;
        }
        bytes32[] memory tags = new bytes32[](counter);
        address[] memory modules = new address[](counter);
        bytes32[] memory tempTags;
        counter = 0;
        for (i = 0; i < _modules.length; i++) {
            tempTags = IModuleFactory(_modules[i]).getTags();
            for (j = 0; j < tempTags.length; j++) {
                tags[counter] = tempTags[j];
                modules[counter] = _modules[i];
                counter++;
            }
        }
        return (tags, modules);
    }

    /**
     * @notice Returns the verified status, and reputation of the entered Module Factory
     * @param _factoryAddress is the address of the module factory
     * @return bool indicating whether module factory is verified
     * @return address of the factory owner
     * @return address array which contains the list of securityTokens that use that module factory
     */
    function getFactoryDetails(address _factoryAddress) external view returns(bool, address, address[] memory) {
        return (getBoolValue(Encoder.getKey("verified", _factoryAddress)), getAddressValue(Encoder.getKey("factoryOwner", _factoryAddress)), getArrayAddress(Encoder.getKey("reputation", _factoryAddress)));
    }

    /**
     * @notice Returns the list of addresses of verified Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getModulesByType(uint8 _moduleType) public view returns(address[] memory) {
        address[] memory _addressList = getArrayAddress(Encoder.getKey("moduleList", uint256(_moduleType)));
        uint256 _len = _addressList.length;
        uint256 counter = 0;
        for (uint256 i = 0; i < _len; i++) {
            if (getBoolValue(Encoder.getKey("verified", _addressList[i]))) {
                counter++;
            }
        }
        address[] memory _tempArray = new address[](counter);
        counter = 0;
        for (uint256 j = 0; j < _len; j++) {
            if (getBoolValue(Encoder.getKey("verified", _addressList[j]))) {
                _tempArray[counter] = _addressList[j];
                counter++;
            }
        }
        return _tempArray;
    }


    /**
     * @notice Returns the list of addresses of all Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getAllModulesByType(uint8 _moduleType) external view returns(address[] memory) {
        return getArrayAddress(Encoder.getKey("moduleList", uint256(_moduleType)));
    }

    /**
     * @notice Returns the list of available Module factory addresses of a particular type for a given token.
     * @param _moduleType is the module type to look for
     * @param _securityToken is the address of SecurityToken
     * @return address array that contains the list of available addresses of module factory contracts.
     */
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) public view returns(address[] memory) {
        address[] memory _addressList = getArrayAddress(Encoder.getKey("moduleList", uint256(_moduleType)));
        uint256 _len = _addressList.length;
        bool _isCustomModuleAllowed = _customModules();
        uint256 counter = 0;
        for (uint256 i = 0; i < _len; i++) {
            if (_isCustomModuleAllowed) {
                if (getBoolValue(
                    Encoder.getKey("verified", _addressList[i])) || getAddressValue(Encoder.getKey("factoryOwner", _addressList[i])) == IOwnable(_securityToken).owner()
                ) if (isCompatibleModule(_addressList[i], _securityToken)) counter++;
            } else if (getBoolValue(Encoder.getKey("verified", _addressList[i]))) {
                if (isCompatibleModule(_addressList[i], _securityToken)) counter++;
            }
        }
        address[] memory _tempArray = new address[](counter);
        counter = 0;
        for (uint256 j = 0; j < _len; j++) {
            if (_isCustomModuleAllowed) {
                if (getAddressValue(Encoder.getKey("factoryOwner", _addressList[j])) == IOwnable(_securityToken).owner() || getBoolValue(
                    Encoder.getKey("verified", _addressList[j])
                )) {
                    if (isCompatibleModule(_addressList[j], _securityToken)) {
                        _tempArray[counter] = _addressList[j];
                        counter++;
                    }
                }
            } else if (getBoolValue(Encoder.getKey("verified", _addressList[j]))) {
                if (isCompatibleModule(_addressList[j], _securityToken)) {
                    _tempArray[counter] = _addressList[j];
                    counter++;
                }
            }
        }
        return _tempArray;
    }

    /**
    * @notice Reclaims all ERC20Basic compatible tokens
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "0x address is invalid");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "token transfer failed");
    }

    /**
     * @notice Called by the owner to pause, triggers stopped state
     */
    function pause() external whenNotPaused onlyOwner {
        set(PAUSED, true);
        /*solium-disable-next-line security/no-block-members*/
        emit Pause(msg.sender);
    }

    /**
     * @notice Called by the owner to unpause, returns to normal state
     */
    function unpause() external whenPaused onlyOwner {
        set(PAUSED, false);
        /*solium-disable-next-line security/no-block-members*/
        emit Unpause(msg.sender);
    }

    /**
     * @notice Stores the contract addresses of other key contracts from the PolymathRegistry
     */
    function updateFromRegistry() external onlyOwner {
        address _polymathRegistry = getAddressValue(POLYMATHREGISTRY);
        set(SECURITY_TOKEN_REGISTRY, IPolymathRegistry(_polymathRegistry).getAddress("SecurityTokenRegistry"));
        set(FEATURE_REGISTRY, IPolymathRegistry(_polymathRegistry).getAddress("FeatureRegistry"));
        set(POLYTOKEN, IPolymathRegistry(_polymathRegistry).getAddress("PolyToken"));
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner(), _newOwner);
        set(OWNER, _newOwner);
    }

    /**
     * @notice Gets the owner of the contract
     * @return address owner
     */
    function owner() public view returns(address) {
        return getAddressValue(OWNER);
    }

    /**
     * @notice Checks whether the contract operations is paused or not
     * @return bool
     */
    function isPaused() public view returns(bool) {
        return getBoolValue(PAUSED);
    }
}

pragma solidity 0.5.8;

contract EternalStorage {
    /// @notice Internal mappings used to store all kinds on data into the contract
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;

    /// @notice Internal mappings used to store arrays of different data types
    mapping(bytes32 => bytes32[]) internal bytes32ArrayStorage;
    mapping(bytes32 => uint256[]) internal uintArrayStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => string[]) internal stringArrayStorage;

    //////////////////
    //// set functions
    //////////////////
    /// @notice Set the key values using the Overloaded `set` functions
    /// Ex- string version = "0.0.1"; replace to
    /// set(keccak256(abi.encodePacked("version"), "0.0.1");
    /// same for the other variables as well some more example listed below
    /// ex1 - address securityTokenAddress = 0x123; replace to
    /// set(keccak256(abi.encodePacked("securityTokenAddress"), 0x123);
    /// ex2 - bytes32 tokenDetails = "I am ST20"; replace to
    /// set(keccak256(abi.encodePacked("tokenDetails"), "I am ST20");
    /// ex3 - mapping(string => address) ownedToken;
    /// set(keccak256(abi.encodePacked("ownedToken", "Chris")), 0x123);
    /// ex4 - mapping(string => uint) tokenIndex;
    /// tokenIndex["TOKEN"] = 1; replace to set(keccak256(abi.encodePacked("tokenIndex", "TOKEN"), 1);
    /// ex5 - mapping(string => SymbolDetails) registeredSymbols; where SymbolDetails is the structure having different type of values as
    /// {uint256 date, string name, address owner} etc.
    /// registeredSymbols["TOKEN"].name = "MyFristToken"; replace to set(keccak256(abi.encodePacked("registeredSymbols_name", "TOKEN"), "MyFirstToken");
    /// More generalized- set(keccak256(abi.encodePacked("registeredSymbols_<struct variable>", "keyname"), "value");

    function set(bytes32 _key, uint256 _value) internal {
        uintStorage[_key] = _value;
    }

    function set(bytes32 _key, address _value) internal {
        addressStorage[_key] = _value;
    }

    function set(bytes32 _key, bool _value) internal {
        boolStorage[_key] = _value;
    }

    function set(bytes32 _key, bytes32 _value) internal {
        bytes32Storage[_key] = _value;
    }

    function set(bytes32 _key, string memory _value) internal {
        stringStorage[_key] = _value;
    }

    function set(bytes32 _key, bytes memory _value) internal {
        bytesStorage[_key] = _value;
    }

    ////////////////////////////
    // deleteArray functions
    ////////////////////////////
    /// @notice Function used to delete the array element.
    /// Ex1- mapping(address => bytes32[]) tokensOwnedByOwner;
    /// For deleting the item from array developers needs to create a funtion for that similarly
    /// in this case we have the helper function deleteArrayBytes32() which will do it for us
    /// deleteArrayBytes32(keccak256(abi.encodePacked("tokensOwnedByOwner", 0x1), 3); -- it will delete the index 3

    //Deletes from mapping (bytes32 => array[]) at index _index
    function deleteArrayAddress(bytes32 _key, uint256 _index) internal {
        address[] storage array = addressArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    //Deletes from mapping (bytes32 => bytes32[]) at index _index
    function deleteArrayBytes32(bytes32 _key, uint256 _index) internal {
        bytes32[] storage array = bytes32ArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    //Deletes from mapping (bytes32 => uint[]) at index _index
    function deleteArrayUint(bytes32 _key, uint256 _index) internal {
        uint256[] storage array = uintArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    //Deletes from mapping (bytes32 => string[]) at index _index
    function deleteArrayString(bytes32 _key, uint256 _index) internal {
        string[] storage array = stringArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    ////////////////////////////
    //// pushArray functions
    ///////////////////////////
    /// @notice Below are the helper functions to facilitate storing arrays of different data types.
    /// Ex1- mapping(address => bytes32[]) tokensOwnedByTicker;
    /// tokensOwnedByTicker[owner] = tokensOwnedByTicker[owner].push("xyz"); replace with
    /// pushArray(keccak256(abi.encodePacked("tokensOwnedByTicker", owner), "xyz");

    /// @notice use to store the values for the array
    /// @param _key bytes32 type
    /// @param _value [uint256, string, bytes32, address] any of the data type in array
    function pushArray(bytes32 _key, address _value) internal {
        addressArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, bytes32 _value) internal {
        bytes32ArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, string memory _value) internal {
        stringArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, uint256 _value) internal {
        uintArrayStorage[_key].push(_value);
    }

    /////////////////////////
    //// Set Array functions
    ////////////////////////
    /// @notice used to intialize the array
    /// Ex1- mapping (address => address[]) public reputation;
    /// reputation[0x1] = new address[](0); It can be replaced as
    /// setArray(hash('reputation', 0x1), new address[](0));

    function setArray(bytes32 _key, address[] memory _value) internal {
        addressArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, uint256[] memory _value) internal {
        uintArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, bytes32[] memory _value) internal {
        bytes32ArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, string[] memory _value) internal {
        stringArrayStorage[_key] = _value;
    }

    /////////////////////////
    /// getArray functions
    /////////////////////////
    /// @notice Get functions to get the array of the required data type
    /// Ex1- mapping(address => bytes32[]) tokensOwnedByOwner;
    /// getArrayBytes32(keccak256(abi.encodePacked("tokensOwnedByOwner", 0x1)); It return the bytes32 array
    /// Ex2- uint256 _len =  tokensOwnedByOwner[0x1].length; replace with
    /// getArrayBytes32(keccak256(abi.encodePacked("tokensOwnedByOwner", 0x1)).length;

    function getArrayAddress(bytes32 _key) public view returns(address[] memory) {
        return addressArrayStorage[_key];
    }

    function getArrayBytes32(bytes32 _key) public view returns(bytes32[] memory) {
        return bytes32ArrayStorage[_key];
    }

    function getArrayUint(bytes32 _key) public view returns(uint[] memory) {
        return uintArrayStorage[_key];
    }

    ///////////////////////////////////
    /// setArrayIndexValue() functions
    ///////////////////////////////////
    /// @notice set the value of particular index of the address array
    /// Ex1- mapping(bytes32 => address[]) moduleList;
    /// general way is -- moduleList[moduleType][index] = temp;
    /// It can be re-write as -- setArrayIndexValue(keccak256(abi.encodePacked('moduleList', moduleType)), index, temp);

    function setArrayIndexValue(bytes32 _key, uint256 _index, address _value) internal {
        addressArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, uint256 _value) internal {
        uintArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, bytes32 _value) internal {
        bytes32ArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, string memory _value) internal {
        stringArrayStorage[_key][_index] = _value;
    }

    /// Public getters functions
    /////////////////////// @notice Get function use to get the value of the singleton state variables
    /// Ex1- string public version = "0.0.1";
    /// string _version = getString(keccak256(abi.encodePacked("version"));
    /// Ex2 - assert(temp1 == temp2); replace to
    /// assert(getUint(keccak256(abi.encodePacked(temp1)) == getUint(keccak256(abi.encodePacked(temp2));
    /// Ex3 - mapping(string => SymbolDetails) registeredSymbols; where SymbolDetails is the structure having different type of values as
    /// {uint256 date, string name, address owner} etc.
    /// string _name = getString(keccak256(abi.encodePacked("registeredSymbols_name", "TOKEN"));

    function getUintValue(bytes32 _variable) public view returns(uint256) {
        return uintStorage[_variable];
    }

    function getBoolValue(bytes32 _variable) public view returns(bool) {
        return boolStorage[_variable];
    }

    function getStringValue(bytes32 _variable) public view returns(string memory) {
        return stringStorage[_variable];
    }

    function getAddressValue(bytes32 _variable) public view returns(address) {
        return addressStorage[_variable];
    }

    function getBytes32Value(bytes32 _variable) public view returns(bytes32) {
        return bytes32Storage[_variable];
    }

    function getBytesValue(bytes32 _variable) public view returns(bytes memory) {
        return bytesStorage[_variable];
    }

}

pragma solidity 0.5.8;

/**
 * @title Helper library use to compare or validate the semantic versions
 */

library VersionUtils {

    function lessThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] < _new[i]) return true;
            if (_current[i] > _new[i]) return false;
        }
        return true;
    }

    function greaterThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] > _new[i]) return true;
            if (_current[i] < _new[i]) return false;
        }
        return true;
    }

    /**
     * @notice Used to pack the uint8[] array data into uint24 value
     * @param _major Major version
     * @param _minor Minor version
     * @param _patch Patch version
     */
    function pack(uint8 _major, uint8 _minor, uint8 _patch) internal pure returns(uint24) {
        return (uint24(_major) << 16) | (uint24(_minor) << 8) | uint24(_patch);
    }

    /**
     * @notice Used to convert packed data into uint8 array
     * @param _packedVersion Packed data
     */
    function unpack(uint24 _packedVersion) internal pure returns(uint8[] memory) {
        uint8[] memory _unpackVersion = new uint8[](3);
        _unpackVersion[0] = uint8(_packedVersion >> 16);
        _unpackVersion[1] = uint8(_packedVersion >> 8);
        _unpackVersion[2] = uint8(_packedVersion);
        return _unpackVersion;
    }


    /**
     * @notice Used to packed the KYC data
     */
    function packKYC(uint64 _a, uint64 _b, uint64 _c, uint8 _d) internal pure returns(uint256) {
        // this function packs 3 uint64 and a uint8 together in a uint256 to save storage cost
        // a is rotated left by 136 bits, b is rotated left by 72 bits and c is rotated left by 8 bits.
        // rotation pads empty bits with zeroes so now we can safely do a bitwise OR operation to pack
        // all the variables together.
        return (uint256(_a) << 136) | (uint256(_b) << 72) | (uint256(_c) << 8) | uint256(_d);
    }

    /**
     * @notice Used to convert packed data into KYC data
     * @param _packedVersion Packed data
     */
    function unpackKYC(uint256 _packedVersion) internal pure returns(uint64 canSendAfter, uint64 canReceiveAfter, uint64 expiryTime, uint8 added) {
        canSendAfter = uint64(_packedVersion >> 136);
        canReceiveAfter = uint64(_packedVersion >> 72);
        expiryTime = uint64(_packedVersion >> 8);
        added = uint8(_packedVersion);
    }
}

pragma solidity 0.5.8;

library Encoder {
    function getKey(string memory _key) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key)));
    }

    function getKey(string memory _key1, address _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, string memory _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, uint256 _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, bytes32 _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, bool _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

}

pragma solidity 0.5.8;

/**
 * @title Interface for the Polymath Security Token Registry contract
 */
interface ISecurityTokenRegistry {

    // Emit when network becomes paused
    event Pause(address account);
    // Emit when network becomes unpaused
    event Unpause(address account);
    // Emit when the ticker is removed from the registry
    event TickerRemoved(string _ticker, address _removedBy);
    // Emit when the token ticker expiry is changed
    event ChangeExpiryLimit(uint256 _oldExpiry, uint256 _newExpiry);
    // Emit when changeSecurityLaunchFee is called
    event ChangeSecurityLaunchFee(uint256 _oldFee, uint256 _newFee);
    // Emit when changeTickerRegistrationFee is called
    event ChangeTickerRegistrationFee(uint256 _oldFee, uint256 _newFee);
    // Emit when Fee currency is changed
    event ChangeFeeCurrency(bool _isFeeInPoly);
    // Emit when ownership gets transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // Emit when ownership of the ticker gets changed
    event ChangeTickerOwnership(string _ticker, address indexed _oldOwner, address indexed _newOwner);
    // Emit at the time of launching a new security token of version 3.0+
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _usdFee,
        uint256 _polyFee,
        uint256 _protocolVersion
    );
    // Emit at the time of launching a new security token v2.0.
    // _registrationFee is in poly
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _registrationFee
    );
    // Emit when new ticker get registers
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFeePoly,
        uint256 _registrationFeeUsd
    );
    // Emit after ticker registration
    // _registrationFee is in poly
    // fee in usd is not being emitted to maintain backwards compatibility
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        string _name,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFee
    );
    // Emit at when issuer refreshes exisiting token
    event SecurityTokenRefreshed(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        uint256 _protocolVersion
    );
    event ProtocolFactorySet(address indexed _STFactory, uint8 _major, uint8 _minor, uint8 _patch);
    event LatestVersionSet(uint8 _major, uint8 _minor, uint8 _patch);
    event ProtocolFactoryRemoved(address indexed _STFactory, uint8 _major, uint8 _minor, uint8 _patch);

    /**
     * @notice Deploys an instance of a new Security Token of version 2.0 and records it to the registry
     * @dev this function is for backwards compatibilty with 2.0 dApp.
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     */
    function generateSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible
    )
        external;

    /**
     * @notice Deploys an instance of a new Security Token and records it to the registry
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     * @param _treasuryWallet Ethereum address which will holds the STs.
     * @param _protocolVersion Version of securityToken contract
     * - `_protocolVersion` is the packed value of uin8[3] array (it will be calculated offchain)
     * - if _protocolVersion == 0 then latest version of securityToken will be generated
     */
    function generateNewSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible,
        address _treasuryWallet,
        uint256 _protocolVersion
    )
        external;

    /**
     * @notice Deploys an instance of a new Security Token and replaces the old one in the registry
     * This can be used to upgrade from version 2.0 of ST to 3.0 or in case something goes wrong with earlier ST
     * @dev This function needs to be in STR 3.0. Defined public to avoid stack overflow
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     */
    function refreshSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible,
        address _treasuryWallet
    )
        external returns (address securityToken);

    /**
     * @notice Adds a new custom Security Token and saves it to the registry. (Token should follow the ISecurityToken interface)
     * @param _name Name of the token
     * @param _ticker Ticker of the security token
     * @param _owner Owner of the token
     * @param _securityToken Address of the securityToken
     * @param _tokenDetails Off-chain details of the token
     * @param _deployedAt Timestamp at which security token comes deployed on the ethereum blockchain
     */
    function modifySecurityToken(
        string calldata _name,
        string calldata _ticker,
        address _owner,
        address _securityToken,
        string calldata _tokenDetails,
        uint256 _deployedAt
    )
    external;

    /**
     * @notice Adds a new custom Security Token and saves it to the registry. (Token should follow the ISecurityToken interface)
     * @param _ticker is the ticker symbol of the security token
     * @param _owner is the owner of the token
     * @param _securityToken is the address of the securityToken
     * @param _tokenDetails is the off-chain details of the token
     * @param _deployedAt is the timestamp at which the security token is deployed
     */
    function modifyExistingSecurityToken(
        string calldata _ticker,
        address _owner,
        address _securityToken,
        string calldata _tokenDetails,
        uint256 _deployedAt
    )
        external;

    /**
     * @notice Modifies the ticker details. Only Polymath has the ability to do so.
     * @notice Only allowed to modify the tickers which are not yet deployed.
     * @param _owner is the owner of the token
     * @param _ticker is the token ticker
     * @param _registrationDate is the date at which ticker is registered
     * @param _expiryDate is the expiry date for the ticker
     * @param _status is the token deployment status
     */
    function modifyExistingTicker(
        address _owner,
        string calldata _ticker,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
        external;

    /**
     * @notice Registers the token ticker for its particular owner
     * @notice once the token ticker is registered to its owner then no other issuer can claim
     * @notice its ownership. If the ticker expires and its issuer hasn't used it, then someone else can take it.
     * @param _owner Address of the owner of the token
     * @param _ticker Token ticker
     * @param _tokenName Name of the token
     */
    function registerTicker(address _owner, string calldata _ticker, string calldata _tokenName) external;

    /**
     * @notice Registers the token ticker to the selected owner
     * @notice Once the token ticker is registered to its owner then no other issuer can claim
     * @notice its ownership. If the ticker expires and its issuer hasn't used it, then someone else can take it.
     * @param _owner is address of the owner of the token
     * @param _ticker is unique token ticker
     */
    function registerNewTicker(address _owner, string calldata _ticker) external;

    /**
    * @notice Check that Security Token is registered
    * @param _securityToken Address of the Scurity token
    * @return bool
    */
    function isSecurityToken(address _securityToken) external view returns(bool isValid);

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

    /**
     * @notice Get security token address by ticker name
     * @param _ticker Symbol of the Scurity token
     * @return address
     */
    function getSecurityTokenAddress(string calldata _ticker) external view returns(address tokenAddress);

    /**
    * @notice Returns the security token data by address
    * @param _securityToken is the address of the security token.
    * @return string is the ticker of the security Token.
    * @return address is the issuer of the security Token.
    * @return string is the details of the security token.
    * @return uint256 is the timestamp at which security Token was deployed.
    */
    function getSecurityTokenData(address _securityToken) external view returns (
        string memory tokenSymbol,
        address tokenAddress,
        string memory tokenDetails,
        uint256 tokenTime
    );

    /**
     * @notice Get the current STFactory Address
     */
    function getSTFactoryAddress() external view returns(address stFactoryAddress);

    /**
     * @notice Returns the STFactory Address of a particular version
     * @param _protocolVersion Packed protocol version
     */
    function getSTFactoryAddressOfVersion(uint256 _protocolVersion) external view returns(address stFactory);

    /**
     * @notice Get Protocol version
     */
    function getLatestProtocolVersion() external view returns(uint8[] memory protocolVersion);

    /**
     * @notice Used to get the ticker list as per the owner
     * @param _owner Address which owns the list of tickers
     */
    function getTickersByOwner(address _owner) external view returns(bytes32[] memory tickers);

    /**
     * @notice Returns the list of tokens owned by the selected address
     * @param _owner is the address which owns the list of tickers
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokensByOwner(address _owner) external view returns(address[] memory tokens);

    /**
     * @notice Returns the list of all tokens
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokens() external view returns(address[] memory tokens);

    /**
     * @notice Returns the owner and timestamp for a given ticker
     * @param _ticker ticker
     * @return address
     * @return uint256
     * @return uint256
     * @return string
     * @return bool
     */
    function getTickerDetails(string calldata _ticker) external view returns(address tickerOwner, uint256 tickerRegistration, uint256 tickerExpiry, string memory tokenName, bool tickerStatus);

    /**
     * @notice Modifies the ticker details. Only polymath account has the ability
     * to do so. Only allowed to modify the tickers which are not yet deployed
     * @param _owner Owner of the token
     * @param _ticker Token ticker
     * @param _tokenName Name of the token
     * @param _registrationDate Date on which ticker get registered
     * @param _expiryDate Expiry date of the ticker
     * @param _status Token deployed status
     */
    function modifyTicker(
        address _owner,
        string calldata _ticker,
        string calldata _tokenName,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
    external;

    /**
     * @notice Removes the ticker details and associated ownership & security token mapping
     * @param _ticker Token ticker
     */
    function removeTicker(string calldata _ticker) external;

    /**
     * @notice Transfers the ownership of the ticker
     * @dev _newOwner Address whom ownership to transfer
     * @dev _ticker Ticker
     */
    function transferTickerOwnership(address _newOwner, string calldata _ticker) external;

    /**
     * @notice Changes the expiry time for the token ticker
     * @param _newExpiry New time period for token ticker expiry
     */
    function changeExpiryLimit(uint256 _newExpiry) external;

   /**
    * @notice Sets the ticker registration fee in USD tokens. Only Polymath.
    * @param _tickerRegFee is the registration fee in USD tokens (base 18 decimals)
    */
    function changeTickerRegistrationFee(uint256 _tickerRegFee) external;

    /**
    * @notice Sets the ticker registration fee in USD tokens. Only Polymath.
    * @param _stLaunchFee is the registration fee in USD tokens (base 18 decimals)
    */
    function changeSecurityLaunchFee(uint256 _stLaunchFee) external;

    /**
    * @notice Sets the ticker registration and ST launch fee amount and currency
    * @param _tickerRegFee is the ticker registration fee (base 18 decimals)
    * @param _stLaunchFee is the st generation fee (base 18 decimals)
    * @param _isFeeInPoly defines if the fee is in poly or usd
    */
    function changeFeesAmountAndCurrency(uint256 _tickerRegFee, uint256 _stLaunchFee, bool _isFeeInPoly) external;

    /**
    * @notice Changes the SecurityToken contract for a particular factory version
    * @notice Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * @notice Changing versions does not affect existing tokens.
    * @param _STFactoryAddress is the address of the proxy.
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function setProtocolFactory(address _STFactoryAddress, uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
    * @notice Removes a STFactory
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function removeProtocolFactory(uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
    * @notice Changes the default protocol version
    * @notice Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * @notice Changing versions does not affect existing tokens.
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function setLatestVersion(uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
     * @notice Changes the PolyToken address. Only Polymath.
     * @param _newAddress is the address of the polytoken.
     */
    function updatePolyTokenAddress(address _newAddress) external;

    /**
     * @notice Used to update the polyToken contract address
     */
    function updateFromRegistry() external;

    /**
     * @notice Gets the security token launch fee
     * @return Fee amount
     */
    function getSecurityTokenLaunchFee() external returns(uint256 fee);

    /**
     * @notice Gets the ticker registration fee
     * @return Fee amount
     */
    function getTickerRegistrationFee() external returns(uint256 fee);

    /**
     * @notice Set the getter contract address
     * @param _getterContract Address of the contract
     */
    function setGetterRegistry(address _getterContract) external;

    /**
     * @notice Returns the usd & poly fee for a particular feetype
     * @param _feeType Key corresponding to fee type
     */
    function getFees(bytes32 _feeType) external returns (uint256 usdFee, uint256 polyFee);

    /**
     * @notice Returns the list of tokens to which the delegate has some access
     * @param _delegate is the address for the delegate
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokensByDelegate(address _delegate) external view returns(address[] memory tokens);

    /**
     * @notice Gets the expiry limit
     * @return Expiry limit
     */
    function getExpiryLimit() external view returns(uint256 expiry);

    /**
     * @notice Gets the status of the ticker
     * @param _ticker Ticker whose status need to determine
     * @return bool
     */
    function getTickerStatus(string calldata _ticker) external view returns(bool status);

    /**
     * @notice Gets the fee currency
     * @return true = poly, false = usd
     */
    function getIsFeeInPoly() external view returns(bool isInPoly);

    /**
     * @notice Gets the owner of the ticker
     * @param _ticker Ticker whose owner need to determine
     * @return address Address of the owner
     */
    function getTickerOwner(string calldata _ticker) external view returns(address owner);

    /**
     * @notice Checks whether the registry is paused or not
     * @return bool
     */
    function isPaused() external view returns(bool paused);

    /**
    * @notice Called by the owner to pause, triggers stopped state
    */
    function pause() external;

    /**
     * @notice Called by the owner to unpause, returns to normal state
     */
    function unpause() external;

    /**
     * @notice Reclaims all ERC20Basic compatible tokens
     * @param _tokenContract is the address of the token contract
     */
    function reclaimERC20(address _tokenContract) external;

    /**
     * @notice Gets the owner of the contract
     * @return address owner
     */
    function owner() external view returns(address ownerAddress);

    /**
     * @notice Checks if the entered ticker is registered and has not expired
     * @param _ticker is the token ticker
     * @return bool
     */
    function tickerAvailable(string calldata _ticker) external view returns(bool);

}

pragma solidity 0.5.8;

/**
 * @title Interface for all security tokens
 */
interface ISecurityToken {
    // Standard ERC20 interface
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    // Emit at the time when module get added
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );

    // Emit when the token details get updated
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the token name get updated
    event UpdateTokenName(string _oldName, string _newName);
    // Emit when the granularity get changed
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when is permanently frozen by the issuer
    event FreezeIssuance();
    // Emit when transfers are frozen or unfrozen
    event FreezeTransfers(bool _status);
    // Emit when new checkpoint created
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    // Events to log controller actions
    event SetController(address indexed _oldController, address indexed _newController);
    //Event emit when the global treasury wallet address get changed
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

    // Emit when Module get archived from the securityToken
    event ModuleArchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get unarchived from the securityToken
    event ModuleUnarchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get removed from the securityToken
    event ModuleRemoved(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when the budget allocated to a module is changed
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget); //Event emitted by the tokenLib.

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    // Issuance / Redemption Events
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    /**
     * @notice Initialization function
     * @dev Expected to be called atomically with the proxy being created, by the owner of the token
     * @dev Can only be called once
     */
    function initialize(address _getterDelegate) external;

    /**
     * @notice The standard provides an on-chain function to determine whether a transfer will succeed,
     * and return details indicating the reason if the transfer is not valid.
     * @param _from The address from whom the tokens get transferred.
     * @param _to The address to which to transfer tokens to.
     * @param _partition The partition from which to transfer tokens
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return ESC (Ethereum Status Code) following the EIP-1066 standard
     * @return Application specific reason codes with additional details
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte statusCode, bytes32 reasonCode, bytes32 partition);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external;

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * @return string The URI associated with the document.
     * @return bytes32 The hash (of the contents) of the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory documentUri, bytes32 documentHash, uint256 documentTime);

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory documentNames);

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view returns (bool controlled);

    /**
     * @notice Checks if an address is a module of certain type
     * @param _module Address to check
     * @param _type type to check against
     */
    function isModule(address _module, uint8 _type) external view returns(bool isValid);

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice issue new tokens and assigns them to the target _tokenHolder.
     * @dev Can only be called by the issuer or STO attached to the token.
     * @param _tokenHolders A list of addresses to whom the minted tokens will be dilivered
     * @param _values A list of number of tokens get minted and transfer to corresponding address of the investor from _tokenHolders[] list
     * @return success
     */
    function issueMulti(address[] calldata _tokenHolders, uint256[] calldata _values) external;

    /**
     * @notice Increases totalSupply and the corresponding amount of the specified owners partition
     * @param _partition The partition to allocate the increase in balance
     * @param _tokenHolder The token holder whose balance should be increased
     * @param _value The amount by which to increase the balance
     * @param _data Additional data attached to the minting of tokens
     */
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of msg.sender
     * @param _partition The partition to allocate the decrease in balance
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     */
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of tokenHolder
     * @dev This function can only be called by the authorised operator.
     * @param _partition The partition to allocate the decrease in balance.
     * @param _tokenHolder The token holder whose balance should be decreased
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     */
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPermission);

    /**
     * @notice Returns module list for a module type
     * @param _module Address of the module
     * @return bytes32 Name
     * @return address Module address
     * @return address Module factory address
     * @return bool Module archived
     * @return uint8 Array of module types
     * @return bytes32 Module label
     */
    function getModule(address _module) external view returns (bytes32 moduleName, address moduleAddress, address factoryAddress, bool isArchived, uint8[] memory moduleTypes, bytes32 moduleLabel);

    /**
     * @notice Returns module list for a module name
     * @param _name Name of the module
     * @return address[] List of modules with this name
     */
    function getModulesByName(bytes32 _name) external view returns(address[] memory modules);

    /**
     * @notice Returns module list for a module type
     * @param _type Type of the module
     * @return address[] List of modules with this type
     */
    function getModulesByType(uint8 _type) external view returns(address[] memory modules);

    /**
     * @notice use to return the global treasury wallet
     */
    function getTreasuryWallet() external view returns(address treasuryWallet);

    /**
     * @notice Queries totalSupply at a specified checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256 supply);

    /**
     * @notice Queries balance at a specified checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns(uint256 balance);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() external returns(uint256 checkpointId);

    /**
     * @notice Gets list of times that checkpoints were created
     * @return List of checkpoint times
     */
    function getCheckpointTimes() external view returns(uint256[] memory checkpointTimes);

    /**
     * @notice returns an array of investors
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @return list of addresses
     */
    function getInvestors() external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors at a given checkpoint
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @return list of investors
     */
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors with non zero balance at a given checkpoint
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice generates subset of investors
     * NB - can be used in batches if investor list is large
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice Gets current checkpoint ID
     * @return Id
     */
    function currentCheckpointId() external view returns(uint256 checkpointId);

    /**
     * @notice Determines whether `_operator` is an operator for all partitions of `_tokenHolder`
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for all partitions of `_tokenHolder`
     */
    function isOperator(address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Determines whether `_operator` is an operator for a specified partition of `_tokenHolder`
     * @param _partition The partition to check
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for a specified partition of `_tokenHolder`
     */
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Return all partitions
     * @param _tokenHolder Whom balance need to queried
     * @return List of partitions
     */
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory partitions);

    /**
     * @notice Gets data store address
     * @return data store address
     */
    function dataStore() external view returns (address dataStoreAddress);

    /**
    * @notice Allows owner to change data store
    * @param _dataStore Address of the token data store
    */
    function changeDataStore(address _dataStore) external;


    /**
     * @notice Allows to change the treasury wallet address
     * @param _wallet Ethereum address of the treasury wallet
     */
    function changeTreasuryWallet(address _wallet) external;

    /**
     * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
     * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
     * @param _tokenContract Address of the ERC20Basic compliance token
     * @param _value Amount of POLY to withdraw
     */
    function withdrawERC20(address _tokenContract, uint256 _value) external;

    /**
    * @notice Allows owner to increase/decrease POLY approval of one of the modules
    * @param _module Module address
    * @param _change Change in allowance
    * @param _increase True if budget has to be increased, false if decrease
    */
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external;

    /**
     * @notice Changes the tokenDetails
     * @param _newTokenDetails New token details
     */
    function updateTokenDetails(string calldata _newTokenDetails) external;

    /**
    * @notice Allows owner to change token name
    * @param _name new name of the token
    */
    function changeName(string calldata _name) external;

    /**
    * @notice Allows the owner to change token granularity
    * @param _granularity Granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external;

    /**
     * @notice Freezes all the transfers
     */
    function freezeTransfers() external;

    /**
     * @notice Un-freezes all the transfers
     */
    function unfreezeTransfers() external;

    /**
     * @notice Permanently freeze issuance of this security token.
     * @dev It MUST NOT be possible to increase `totalSuppy` after this function is called.
     */
    function freezeIssuance(bytes calldata _signature) external;

    /**
      * @notice Attachs a module to the SecurityToken
      * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
      * @dev to control restrictions on transfers.
      * @param _moduleFactory is the address of the module factory to be added
      * @param _data is data packed into bytes used to further configure the module (See STO usage)
      * @param _maxCost max amount of POLY willing to pay to the module.
      * @param _budget max amount of ongoing POLY willing to assign to the module.
      * @param _label custom module label.
      * @param _archived whether to add the module as an archived module
      */
    function addModuleWithLabel(
        address _moduleFactory,
        bytes calldata _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) external;

    /**
     * @notice Function used to attach a module to the security token
     * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     * @dev to control restrictions on transfers.
     * @dev You are allowed to add a new moduleType if:
     * @dev - there is no existing module of that type yet added
     * @dev - the last member of the module list is replacable
     * @param _moduleFactory is the address of the module factory to be added
     * @param _data is data packed into bytes used to further configure the module (See STO usage)
     * @param _maxCost max amount of POLY willing to pay to module. (WIP)
     * @param _budget max amount of ongoing POLY willing to assign to the module.
     * @param _archived whether to add the module as an archived module
     */
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external;

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function archiveModule(address _module) external;

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function unarchiveModule(address _module) external;

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function removeModule(address _module) external;

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external;

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
    function disableController(bytes calldata _signature) external;

    /**
     * @notice Used to get the version of the securityToken
     */
    function getVersion() external view returns(uint8[] memory version);

    /**
     * @notice Gets the investor count
     */
    function getInvestorCount() external view returns(uint256 investorCount);

    /**
     * @notice Gets the holder count (investors with non zero balance)
     */
    function holderCount() external view returns(uint256 count);

    /**
      * @notice Overloaded version of the transfer function
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;

    /**
      * @notice Overloaded version of the transferFrom function
      * @param _from sender of transfer
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32 partition);

    /**
     * @notice Get the balance according to the provided partitions
     * @param _partition Partition which differentiate the tokens.
     * @param _tokenHolder Whom balance need to queried
     * @return Amount of tokens as per the given partitions
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns(uint256 balance);

    /**
      * @notice Provides the granularity of the token
      * @return uint256
      */
    function granularity() external view returns(uint256 granularityAmount);

    /**
      * @notice Provides the address of the polymathRegistry
      * @return address
      */
    function polymathRegistry() external view returns(address registryAddress);

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function upgradeModule(address _module) external;

    /**
    * @notice Upgrades security token
    */
    function upgradeToken() external;

    /**
     * @notice A security token issuer can specify that issuance has finished for the token
     * (i.e. no new tokens can be minted or issued).
     * @dev If a token returns FALSE for `isIssuable()` then it MUST always return FALSE in the future.
     * If a token returns FALSE for `isIssuable()` then it MUST never allow additional tokens to be issued.
     * @return bool `true` signifies the minting is allowed. While `false` denotes the end of minting
     */
    function isIssuable() external view returns (bool issuable);

    /**
     * @notice Authorises an operator for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being authorised.
     */
    function authorizeOperator(address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being de-authorised
     */
    function revokeOperator(address _operator) external;

    /**
     * @notice Authorises an operator for a given partition of `msg.sender`
     * @param _partition The partition to which the operator is authorised
     * @param _operator An address which is being authorised
     */
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for a specified partition of `msg.sender`
     * @param _partition The partition to which the operator is de-authorised
     * @param _operator An address which is being de-authorised
     */
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens.
     * @param _from The address from which to transfer tokens from
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32 partition);

    /*
    * @notice Returns if transfers are currently frozen or not
    */
    function transfersFrozen() external view returns (bool isFrozen);

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() external view returns (bool);

    /**
     * @return the address of the owner.
     */
    function owner() external view returns (address ownerAddress);

    function controller() external view returns(address controllerAddress);

    function moduleRegistry() external view returns(address moduleRegistryAddress);

    function securityTokenRegistry() external view returns(address securityTokenRegistryAddress);

    function polyToken() external view returns(address polyTokenAddress);

    function tokenFactory() external view returns(address tokenFactoryAddress);

    function getterDelegate() external view returns(address delegate);

    function controllerDisabled() external view returns(bool isDisabled);

    function initialized() external view returns(bool isInitialized);

    function tokenDetails() external view returns(string memory details);

    function updateFromRegistry() external;

}

pragma solidity 0.5.8;

interface IPolymathRegistry {

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);
    
    /**
     * @notice Returns the contract address
     * @param _nameKey is the key for the contract address mapping
     * @return address
     */
    function getAddress(string calldata _nameKey) external view returns(address registryAddress);

    /**
     * @notice Changes the contract address
     * @param _nameKey is the key for the contract address mapping
     * @param _newAddress is the new contract address
     */
    function changeAddress(string calldata _nameKey, address _newAddress) external;

}

pragma solidity 0.5.8;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
interface IOwnable {
    /**
    * @dev Returns owner
    */
    function owner() external view returns(address ownerAddress);

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface for the Polymath Module Registry contract
 */
interface IModuleRegistry {

    ///////////
    // Events
    //////////

    // Emit when network becomes paused
    event Pause(address account);
    // Emit when network becomes unpaused
    event Unpause(address account);
    // Emit when Module is used by the SecurityToken
    event ModuleUsed(address indexed _moduleFactory, address indexed _securityToken);
    // Emit when the Module Factory gets registered on the ModuleRegistry contract
    event ModuleRegistered(address indexed _moduleFactory, address indexed _owner);
    // Emit when the module gets verified by Polymath
    event ModuleVerified(address indexed _moduleFactory);
    // Emit when the module gets unverified by Polymath or the factory owner
    event ModuleUnverified(address indexed _moduleFactory);
    // Emit when a ModuleFactory is removed by Polymath
    event ModuleRemoved(address indexed _moduleFactory, address indexed _decisionMaker);
    // Emit when ownership gets transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @notice Called by a security token (2.x) to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external;

    /**
     * @notice Called by a security token to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     * @param _isUpgrade whether the use is part of an existing module upgrade
     */
    function useModule(address _moduleFactory, bool _isUpgrade) external;

    /**
     * @notice Called by the ModuleFactory owner to register new modules for SecurityToken to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external;

    /**
     * @notice Called by the ModuleFactory owner or registry curator to delete a ModuleFactory
     * @param _moduleFactory is the address of the module factory to be deleted
     */
    function removeModule(address _moduleFactory) external;

    /**
     * @notice Check that a module and its factory are compatible
     * @param _moduleFactory is the address of the relevant module factory
     * @param _securityToken is the address of the relevant security token
     * @return bool whether module and token are compatible
     */
    function isCompatibleModule(address _moduleFactory, address _securityToken) external view returns(bool isCompatible);

    /**
    * @notice Called by Polymath to verify modules for SecurityToken to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST - Only if enabled by the FeatureRegistry)
    * @param _moduleFactory is the address of the module factory to be registered
    */
    function verifyModule(address _moduleFactory) external;

    /**
    * @notice Called by Polymath to unverify modules for SecurityToken to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST - Only if enabled by the FeatureRegistry)
    * @param _moduleFactory is the address of the module factory to be registered
    */
    function unverifyModule(address _moduleFactory) external;

    /**
     * @notice Returns the verified status, and reputation of the entered Module Factory
     * @param _factoryAddress is the address of the module factory
     * @return bool indicating whether module factory is verified
     * @return address of the factory owner
     * @return address array which contains the list of securityTokens that use that module factory
     */
    function getFactoryDetails(address _factoryAddress) external view returns(bool isVerified, address factoryOwner, address[] memory usingTokens);

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @param _securityToken is the token
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[] memory tags, address[] memory factories);

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[] memory tags, address[] memory factories);

    /**
     * @notice Returns the list of addresses of all Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getAllModulesByType(uint8 _moduleType) external view returns(address[] memory factories);
    /**
     * @notice Returns the list of addresses of Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getModulesByType(uint8 _moduleType) external view returns(address[] memory factories);

    /**
     * @notice Returns the list of available Module factory addresses of a particular type for a given token.
     * @param _moduleType is the module type to look for
     * @param _securityToken is the address of SecurityToken
     * @return address array that contains the list of available addresses of module factory contracts.
     */
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(address[] memory factories);

    /**
     * @notice Use to get the latest contract address of the regstries
     */
    function updateFromRegistry() external;

    /**
     * @notice Get the owner of the contract
     * @return address owner
     */
    function owner() external view returns(address ownerAddress);

    /**
     * @notice Check whether the contract operations is paused or not
     * @return bool
     */
    function isPaused() external view returns(bool paused);

    /**
     * @notice Reclaims all ERC20Basic compatible tokens
     * @param _tokenContract The address of the token contract
     */
    function reclaimERC20(address _tokenContract) external;

    /**
     * @notice Called by the owner to pause, triggers stopped state
     */
    function pause() external;

    /**
     * @notice Called by the owner to unpause, returns to normal state
     */
    function unpause() external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module factory contract should implement
 */
interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes calldata _data) external returns(address moduleAddress);

    /**
     * @notice Get the tags related to the module factory
     */
    function version() external view returns(string memory moduleVersion);

    /**
     * @notice Get the tags related to the module factory
     */
    function name() external view returns(bytes32 moduleName);

    /**
     * @notice Returns the title associated with the module
     */
    function title() external view returns(string memory moduleTitle);

    /**
     * @notice Returns the description associated with the module
     */
    function description() external view returns(string memory moduleDescription);

    /**
     * @notice Get the setup cost of the module in USD
     */
    function setupCost() external returns(uint256 usdSetupCost);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory moduleTypes);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory moduleTags);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeSetupCost(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the currency and amount setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() external returns (uint256 polySetupCost);

    /**
     * @notice Used to get the lower bound
     * @return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

    /**
     * @notice Used to get the upper bound
     * @return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] calldata _tagsData) external;

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) external;

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string calldata _description) external;

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string calldata _title) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface for managing polymath feature switches
 */
interface IFeatureRegistry {

    event ChangeFeatureStatus(string _nameKey, bool _newStatus);

    /**
     * @notice change a feature status
     * @dev feature status is set to false by default
     * @param _nameKey is the key for the feature status mapping
     * @param _newStatus is the new feature status
     */
    function setFeatureStatus(string calldata _nameKey, bool _newStatus) external;

    /**
     * @notice Get the status of a feature
     * @param _nameKey is the key for the feature status mapping
     * @return bool
     */
    function getFeatureStatus(string calldata _nameKey) external view returns(bool hasFeature);

}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}