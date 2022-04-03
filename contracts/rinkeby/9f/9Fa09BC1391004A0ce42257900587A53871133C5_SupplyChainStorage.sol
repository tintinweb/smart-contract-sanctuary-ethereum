pragma solidity ^0.4.23;
import "./SupplyChainStorage.sol";
import "./Ownable.sol";

contract CoffeeSupplyChain is Ownable
{
  
    event PerformCultivation(address indexed user, address indexed batchNo);
    event DoneInspection(address indexed user, address indexed batchNo);
    event DoneHarvesting(address indexed user, address indexed batchNo);
    event DoneExporting(address indexed user, address indexed batchNo);
    event DoneImporting(address indexed user, address indexed batchNo);
    event DoneProcessing(address indexed user, address indexed batchNo);

    
    /*Modifier*/
    modifier isValidPerformer(address batchNo, string role) {
    
        require(keccak256(supplyChainStorage.getUserRole(msg.sender)) == keccak256(role));
        require(keccak256(supplyChainStorage.getNextAction(batchNo)) == keccak256(role));
        _;
    }
    
    /* Storage Variables */    
    SupplyChainStorage supplyChainStorage;
    
    constructor(address _supplyChainAddress) public {
        supplyChainStorage = SupplyChainStorage(_supplyChainAddress);
    }
    
    
    /* Get Next Action  */    

    function getNextAction(address _batchNo) public view returns(string action)
    {
       (action) = supplyChainStorage.getNextAction(_batchNo);
       return (action);
    }
    

    /* get Basic Details */
    
    function getBasicDetails(address _batchNo) public view returns (string registrationNo,
                                                                     string farmerName,
                                                                     string farmAddress,
                                                                     string exporterName,
                                                                     string importerName) {
        /* Call Storage Contract */
        (registrationNo, farmerName, farmAddress, exporterName, importerName) = supplyChainStorage.getBasicDetails(_batchNo);  
        return (registrationNo, farmerName, farmAddress, exporterName, importerName);
    }

    /* perform Basic Cultivation */
    
    function addBasicDetails(string _registrationNo,
                             string _farmerName,
                             string _farmAddress,
                             string _exporterName,
                             string _importerName
                            ) public onlyOwner returns(address) {
    
        address batchNo = supplyChainStorage.setBasicDetails(_registrationNo,
                                                            _farmerName,
                                                            _farmAddress,
                                                            _exporterName,
                                                            _importerName);
        
        emit PerformCultivation(msg.sender, batchNo); 
        
        return (batchNo);
    }                            
    
    /* get Farm Inspection */
    
    function getFarmInspectorData(address _batchNo) public view returns (string coffeeFamily,string typeOfSeed,string fertilizerUsed) {
        /* Call Storage Contract */
        (coffeeFamily, typeOfSeed, fertilizerUsed) = supplyChainStorage.getFarmInspectorData(_batchNo);  
        return (coffeeFamily, typeOfSeed, fertilizerUsed);
    }
    
    /* perform Farm Inspection */
    
    function updateFarmInspectorData(address _batchNo,
                                    string _coffeeFamily,
                                    string _typeOfSeed,
                                    string _fertilizerUsed) 
                                public isValidPerformer(_batchNo,'FARM_INSPECTION') returns(bool) {
        /* Call Storage Contract */
        bool status = supplyChainStorage.setFarmInspectorData(_batchNo, _coffeeFamily, _typeOfSeed, _fertilizerUsed);  
        
        emit DoneInspection(msg.sender, _batchNo);
        return (status);
    }

    
    /* get Harvest */
    
    function getHarvesterData(address _batchNo) public view returns (string cropVariety, string temperatureUsed, string humidity) {
        /* Call Storage Contract */
        (cropVariety, temperatureUsed, humidity) =  supplyChainStorage.getHarvesterData(_batchNo);  
        return (cropVariety, temperatureUsed, humidity);
    }
    
    /* perform Harvest */
    
    function updateHarvesterData(address _batchNo,
                                string _cropVariety,
                                string _temperatureUsed,
                                string _humidity) 
                                public isValidPerformer(_batchNo,'HARVESTER') returns(bool) {
                                    
        /* Call Storage Contract */
        bool status = supplyChainStorage.setHarvesterData(_batchNo, _cropVariety, _temperatureUsed, _humidity);  
        
        emit DoneHarvesting(msg.sender, _batchNo);
        return (status);
    }
    
    /* get Export */
    
    function getExporterData(address _batchNo) public view returns (uint256 quantity,
                                                                    string destinationAddress,
                                                                    string shipName,
                                                                    string shipNo,
                                                                    uint256 departureDateTime,
                                                                    uint256 estimateDateTime,
                                                                    uint256 exporterId) {
        /* Call Storage Contract */
       (quantity,
        destinationAddress,
        shipName,
        shipNo,
        departureDateTime,
        estimateDateTime,
        exporterId) =  supplyChainStorage.getExporterData(_batchNo);  
        
        return (quantity,
                destinationAddress,
                shipName,
                shipNo,
                departureDateTime,
                estimateDateTime,
                exporterId);
    }
    
    /* perform Export */
    
    function updateExporterData(address _batchNo,
                                uint256 _quantity,    
                                string _destinationAddress,
                                string _shipName,
                                string _shipNo,
                                uint256 _estimateDateTime,
                                uint256 _exporterId) 
                                public isValidPerformer(_batchNo,'EXPORTER') returns(bool) {
                                    
        /* Call Storage Contract */
        bool status = supplyChainStorage.setExporterData(_batchNo, _quantity, _destinationAddress, _shipName,_shipNo, _estimateDateTime,_exporterId);  
        
        emit DoneExporting(msg.sender, _batchNo);
        return (status);
    }
    
    /* get Import */
    
    function getImporterData(address _batchNo) public view returns (uint256 quantity,
                                                                    string shipName,
                                                                    string shipNo,
                                                                    uint256 arrivalDateTime,
                                                                    string transportInfo,
                                                                    string warehouseName,
                                                                    string warehouseAddress,
                                                                    uint256 importerId) {
        /* Call Storage Contract */
        (quantity,
         shipName,
         shipNo,
         arrivalDateTime,
         transportInfo,
         warehouseName,
         warehouseAddress,
         importerId) =  supplyChainStorage.getImporterData(_batchNo);  
         
         return (quantity,
                 shipName,
                 shipNo,
                 arrivalDateTime,
                 transportInfo,
                 warehouseName,
                 warehouseAddress,
                 importerId);
        
    }
    
    /* perform Import */
    
    function updateImporterData(address _batchNo,
                                uint256 _quantity, 
                                string _shipName,
                                string _shipNo,
                                string _transportInfo,
                                string _warehouseName,
                                string _warehouseAddress,
                                uint256 _importerId) 
                                public isValidPerformer(_batchNo,'IMPORTER') returns(bool) {
                                    
        /* Call Storage Contract */
        bool status = supplyChainStorage.setImporterData(_batchNo, _quantity, _shipName, _shipNo, _transportInfo,_warehouseName,_warehouseAddress,_importerId);  
        
        emit DoneImporting(msg.sender, _batchNo);
        return (status);
    }
    
    
    /* get Processor */
    
    function getProcessorData(address _batchNo) public view returns (uint256 quantity,
                                                                    string temperature,
                                                                    uint256 rostingDuration,
                                                                    string internalBatchNo,
                                                                    uint256 packageDateTime,
                                                                    string processorName,
                                                                    string processorAddress) {
        /* Call Storage Contract */
        (quantity,
         temperature,
         rostingDuration,
         internalBatchNo,
         packageDateTime,
         processorName,
         processorAddress) =  supplyChainStorage.getProcessorData(_batchNo);  
         
         return (quantity,
                 temperature,
                 rostingDuration,
                 internalBatchNo,
                 packageDateTime,
                 processorName,
                 processorAddress);
 
    }
    
    /* perform Processing */
    
    function updateProcessorData(address _batchNo,
                              uint256 _quantity, 
                              string _temperature,
                              uint256 _rostingDuration,
                              string _internalBatchNo,
                              uint256 _packageDateTime,
                              string _processorName,
                              string _processorAddress) public isValidPerformer(_batchNo,'PROCESSOR') returns(bool) {
                                    
        /* Call Storage Contract */
        bool status = supplyChainStorage.setProcessorData(_batchNo, 
                                                        _quantity, 
                                                        _temperature, 
                                                        _rostingDuration, 
                                                        _internalBatchNo,
                                                        _packageDateTime,
                                                        _processorName,
                                                        _processorAddress);  
        
        emit DoneProcessing(msg.sender, _batchNo);
        return (status);
    }
}

pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

pragma solidity ^0.4.23;

import "./SupplyChainStorageOwnable.sol";

contract SupplyChainStorage is SupplyChainStorageOwnable {
    
    address public lastAccess;
    constructor() public {
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);
    }
    
    /* Events */
    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);
    
    /* Modifiers */
    
    modifier onlyAuthCaller(){
        lastAccess = msg.sender;
        require(authorizedCaller[msg.sender] == 1);
        _;
    }
    
    /* User Related */
    struct user {
        string name;
        string contactNo;
        bool isActive;
        string profileHash;
    } 
    
    mapping(address => user) userDetails;
    mapping(address => string) userRole;
    
    /* Caller Mapping */
    mapping(address => uint8) authorizedCaller;
    
    /* authorize caller */
    function authorizeCaller(address _caller) public onlyOwner returns(bool) 
    {
        authorizedCaller[_caller] = 1;
        emit AuthorizedCaller(_caller);
        return true;
    }
    
    /* deauthorize caller */
    function deAuthorizeCaller(address _caller) public onlyOwner returns(bool) 
    {
        authorizedCaller[_caller] = 0;
        emit DeAuthorizedCaller(_caller);
        return true;
    }
    
    /*User Roles
        SUPER_ADMIN,
        FARM_INSPECTION,
        HARVESTER,
        EXPORTER,
        IMPORTER,
        PROCESSOR
    */
    
    /* Process Related */
     struct basicDetails {
        string registrationNo;
        string farmerName;
        string farmAddress;
        string exporterName;
        string importerName;
        
    }
    
    struct farmInspector {
        string coffeeFamily;
        string typeOfSeed;
        string fertilizerUsed;
    }
    
    struct harvester {
        string cropVariety;
        string temperatureUsed;
        string humidity;
    }    
    
    struct exporter {
        string destinationAddress;
        string shipName;
        string shipNo;
        uint256 quantity;
        uint256 departureDateTime;
        uint256 estimateDateTime;
        uint256 plantNo;
        uint256 exporterId;
    }
    
    struct importer {
        uint256 quantity;
        uint256 arrivalDateTime;
        uint256 importerId;
        string shipName;
        string shipNo;
        string transportInfo;
        string warehouseName;
        string warehouseAddress;
    }
    
    struct processor {
        uint256 quantity;
        uint256 rostingDuration;
        uint256 packageDateTime;
        string temperature;
        string internalBatchNo;
        string processorName;
        string processorAddress;
    }
    
    mapping (address => basicDetails) batchBasicDetails;
    mapping (address => farmInspector) batchFarmInspector;
    mapping (address => harvester) batchHarvester;
    mapping (address => exporter) batchExporter;
    mapping (address => importer) batchImporter;
    mapping (address => processor) batchProcessor;
    mapping (address => string) nextAction;
    
    /*Initialize struct pointer*/
    user userDetail;
    basicDetails basicDetailsData;
    farmInspector farmInspectorData;
    harvester harvesterData;
    exporter exporterData;
    importer importerData;
    processor processorData; 
    
    
    
    /* Get User Role */
    function getUserRole(address _userAddress) public onlyAuthCaller view returns(string)
    {
        return userRole[_userAddress];
    }
    
    /* Get Next Action  */    
    function getNextAction(address _batchNo) public onlyAuthCaller view returns(string)
    {
        return nextAction[_batchNo];
    }
        
    /*set user details*/
    function setUser(address _userAddress,
                     string _name, 
                     string _contactNo, 
                     string _role, 
                     bool _isActive,
                     string _profileHash) public onlyAuthCaller returns(bool){
        
        /*store data into struct*/
        userDetail.name = _name;
        userDetail.contactNo = _contactNo;
        userDetail.isActive = _isActive;
        userDetail.profileHash = _profileHash;
        
        /*store data into mapping*/
        userDetails[_userAddress] = userDetail;
        userRole[_userAddress] = _role;
        
        return true;
    }  
    
    /*get user details*/
    function getUser(address _userAddress) public onlyAuthCaller view returns(string name, 
                                                                    string contactNo, 
                                                                    string role,
                                                                    bool isActive, 
                                                                    string profileHash
                                                                ){

        /*Getting value from struct*/
        user memory tmpData = userDetails[_userAddress];
        
        return (tmpData.name, tmpData.contactNo, userRole[_userAddress], tmpData.isActive, tmpData.profileHash);
    }
    
    /*get batch basicDetails*/
    function getBasicDetails(address _batchNo) public onlyAuthCaller view returns(string registrationNo,
                             string farmerName,
                             string farmAddress,
                             string exporterName,
                             string importerName) {
        
        basicDetails memory tmpData = batchBasicDetails[_batchNo];
        
        return (tmpData.registrationNo,tmpData.farmerName,tmpData.farmAddress,tmpData.exporterName,tmpData.importerName);
    }
    
    /*set batch basicDetails*/
    function setBasicDetails(string _registrationNo,
                             string _farmerName,
                             string _farmAddress,
                             string _exporterName,
                             string _importerName
                             
                            ) public onlyAuthCaller returns(address) {
        
        uint tmpData = uint(keccak256(msg.sender, now));
        address batchNo = address(tmpData);
        
        basicDetailsData.registrationNo = _registrationNo;
        basicDetailsData.farmerName = _farmerName;
        basicDetailsData.farmAddress = _farmAddress;
        basicDetailsData.exporterName = _exporterName;
        basicDetailsData.importerName = _importerName;
        
        batchBasicDetails[batchNo] = basicDetailsData;
        
        nextAction[batchNo] = 'FARM_INSPECTION';   
        
        
        return batchNo;
    }
    
    /*set farm Inspector data*/
    function setFarmInspectorData(address batchNo,
                                    string _coffeeFamily,
                                    string _typeOfSeed,
                                    string _fertilizerUsed) public onlyAuthCaller returns(bool){
        farmInspectorData.coffeeFamily = _coffeeFamily;
        farmInspectorData.typeOfSeed = _typeOfSeed;
        farmInspectorData.fertilizerUsed = _fertilizerUsed;
        
        batchFarmInspector[batchNo] = farmInspectorData;
        
        nextAction[batchNo] = 'HARVESTER'; 
        
        return true;
    }
    
    
    /*get farm inspactor data*/
    function getFarmInspectorData(address batchNo) public onlyAuthCaller view returns (string coffeeFamily,string typeOfSeed,string fertilizerUsed){
        
        farmInspector memory tmpData = batchFarmInspector[batchNo];
        return (tmpData.coffeeFamily, tmpData.typeOfSeed, tmpData.fertilizerUsed);
    }
    

    /*set Harvester data*/
    function setHarvesterData(address batchNo,
                              string _cropVariety,
                              string _temperatureUsed,
                              string _humidity) public onlyAuthCaller returns(bool){
        harvesterData.cropVariety = _cropVariety;
        harvesterData.temperatureUsed = _temperatureUsed;
        harvesterData.humidity = _humidity;
        
        batchHarvester[batchNo] = harvesterData;
        
        nextAction[batchNo] = 'EXPORTER'; 
        
        return true;
    }
    
    /*get farm Harvester data*/
    function getHarvesterData(address batchNo) public onlyAuthCaller view returns(string cropVariety,
                                                                                           string temperatureUsed,
                                                                                           string humidity){
        
        harvester memory tmpData = batchHarvester[batchNo];
        return (tmpData.cropVariety, tmpData.temperatureUsed, tmpData.humidity);
    }
    
    /*set Exporter data*/
    function setExporterData(address batchNo,
                              uint256 _quantity,    
                              string _destinationAddress,
                              string _shipName,
                              string _shipNo,
                              uint256 _estimateDateTime,
                              uint256 _exporterId) public onlyAuthCaller returns(bool){
        
        exporterData.quantity = _quantity;
        exporterData.destinationAddress = _destinationAddress;
        exporterData.shipName = _shipName;
        exporterData.shipNo = _shipNo;
        exporterData.departureDateTime = now;
        exporterData.estimateDateTime = _estimateDateTime;
        exporterData.exporterId = _exporterId;
        
        batchExporter[batchNo] = exporterData;
        
        nextAction[batchNo] = 'IMPORTER'; 
        
        return true;
    }
    
    /*get Exporter data*/
    function getExporterData(address batchNo) public onlyAuthCaller view returns(uint256 quantity,
                                                                string destinationAddress,
                                                                string shipName,
                                                                string shipNo,
                                                                uint256 departureDateTime,
                                                                uint256 estimateDateTime,
                                                                uint256 exporterId){
        
        
        exporter memory tmpData = batchExporter[batchNo];
        
        
        return (tmpData.quantity, 
                tmpData.destinationAddress, 
                tmpData.shipName, 
                tmpData.shipNo, 
                tmpData.departureDateTime, 
                tmpData.estimateDateTime, 
                tmpData.exporterId);
                
        
    }

    
    /*set Importer data*/
    function setImporterData(address batchNo,
                              uint256 _quantity, 
                              string _shipName,
                              string _shipNo,
                              string _transportInfo,
                              string _warehouseName,
                              string _warehouseAddress,
                              uint256 _importerId) public onlyAuthCaller returns(bool){
        
        importerData.quantity = _quantity;
        importerData.shipName = _shipName;
        importerData.shipNo = _shipNo;
        importerData.arrivalDateTime = now;
        importerData.transportInfo = _transportInfo;
        importerData.warehouseName = _warehouseName;
        importerData.warehouseAddress = _warehouseAddress;
        importerData.importerId = _importerId;
        
        batchImporter[batchNo] = importerData;
        
        nextAction[batchNo] = 'PROCESSOR'; 
        
        return true;
    }
    
    /*get Importer data*/
    function getImporterData(address batchNo) public onlyAuthCaller view returns(uint256 quantity,
                                                                                        string shipName,
                                                                                        string shipNo,
                                                                                        uint256 arrivalDateTime,
                                                                                        string transportInfo,
                                                                                        string warehouseName,
                                                                                        string warehouseAddress,
                                                                                        uint256 importerId){
        
        importer memory tmpData = batchImporter[batchNo];
        
        
        return (tmpData.quantity, 
                tmpData.shipName, 
                tmpData.shipNo, 
                tmpData.arrivalDateTime, 
                tmpData.transportInfo,
                tmpData.warehouseName,
                tmpData.warehouseAddress,
                tmpData.importerId);
                
        
    }

    /*set Proccessor data*/
    function setProcessorData(address batchNo,
                              uint256 _quantity, 
                              string _temperature,
                              uint256 _rostingDuration,
                              string _internalBatchNo,
                              uint256 _packageDateTime,
                              string _processorName,
                              string _processorAddress) public onlyAuthCaller returns(bool){
        
        
        processorData.quantity = _quantity;
        processorData.temperature = _temperature;
        processorData.rostingDuration = _rostingDuration;
        processorData.internalBatchNo = _internalBatchNo;
        processorData.packageDateTime = _packageDateTime;
        processorData.processorName = _processorName;
        processorData.processorAddress = _processorAddress;
        
        batchProcessor[batchNo] = processorData;
        
        nextAction[batchNo] = 'DONE'; 
        
        return true;
    }
    
    
    /*get Processor data*/
    function getProcessorData( address batchNo) public onlyAuthCaller view returns(
                                                                                        uint256 quantity,
                                                                                        string temperature,
                                                                                        uint256 rostingDuration,
                                                                                        string internalBatchNo,
                                                                                        uint256 packageDateTime,
                                                                                        string processorName,
                                                                                        string processorAddress){

        processor memory tmpData = batchProcessor[batchNo];
        
        
        return (
                tmpData.quantity, 
                tmpData.temperature, 
                tmpData.rostingDuration, 
                tmpData.internalBatchNo,
                tmpData.packageDateTime,
                tmpData.processorName,
                tmpData.processorAddress);
                
        
    }
  
}

pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract SupplyChainStorageOwnable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}