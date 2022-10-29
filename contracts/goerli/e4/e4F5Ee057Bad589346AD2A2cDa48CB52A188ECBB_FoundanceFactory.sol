pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import "./DaoFactory.sol";
import "./DaoRegistry.sol";
import "../extensions/IExtension.sol";
import "../extensions/bank/BankFactory.sol";
import "../extensions/executor/ExecutorFactory.sol";
import "../extensions/token/erc20/ERC20TokenExtensionFactory.sol";
import "../extensions/foundance/MemberExtensionFactory.sol";
import "../extensions/foundance/DynamicEquityExtensionFactory.sol";
import "../extensions/foundance/VestedEquityExtensionFactory.sol";
import "../extensions/foundance/CommunityIncentiveExtensionFactory.sol";
  //import "../extensions/nft/NFTCollectionFactory.sol";
  //import "../extensions/erc1155/ERC1155TokenExtensionFactory.sol";
  //import "../extensions/erc1271/ERC1271Factory.sol";
import "../adapters/Manager.sol";
import "../adapters/foundance/VotingAdapter.sol"; 
import "../adapters/foundance/MemberAdapter.sol";
import "../adapters/foundance/DynamicEquityAdapter.sol";
import "../adapters/foundance/VestedEquityAdapter.sol";
import "../adapters/foundance/CommunityIncentiveAdapter.sol";
  //import "../adapters/Onboarding.sol";
import "../helpers/DaoHelper.sol";

contract FoundanceFactory{
    //EVENT
    /**
     * @notice Event emitted when a new Foundance-Agreement has been registered/approved
     * @param  _address address of interacting member
     * @param _projectId The Foundance project Id
     * @param  _name name of Foundance-Agreement
     */
		event FoundanceRegistered(address _address, uint32 _projectId, string _name);
    event FoundanceApproved(address _address, uint32 _projectId,  string _name);
    event FoundanceUpdated(address _address, uint32 _projectId, string _name);

    /**
     * @notice Event emitted when a member has been added/deleted/changed in already registered Foundance-Agreement
     * @param  _address address of Foundance creator
     * @param  _name name of Foundance
     */
    event FoundanceMemberAdded(address _address, string _name);
    event FoundanceMemberDeleted(address _address, string _name);
    event FoundanceMemberChanged(address _address, string _name);
     /**
     * @notice Event emitted when a new Dao has been created based upon a registered Foundance
     * @dev The event is too big, people will have to call `function getExtensionAddress(bytes32 extensionId)` to get the addresses
     * @param  _creatorAddress add of the member summoning the DAO
     * @param _projectId The Foundance project Id
     * @param  _daoAdress address of DaoRegistry
     * @param  _bankAdress address of BankExtension
     * @param  _dynamicEquityExtensionAddress address of dynamicEquity Extension
     */
    event FoundanceLive(
      address _creatorAddress,
      uint32 _projectId,
      address _daoAdress,
      address _bankAdress,
      address _memberExtensionAddress,
      address _dynamicEquityExtensionAddress,
      address _vestedEquityExtensionAddress,
      address _communityIncentiveExtensionAddress
    ); 

    //CORE
    address daoFactoryAddress = 0x2887cb61034A7D75E94B53FcaD9b67E687e090D6;
    //EXTENSION
    address bankFactoryAddress = 0xd1E2beFfDb74DE220d7A5F67f87eF021A8d8ef10;
    address erc20TokenExtensionFactoryAddress = 0x6Fc8dDCB65738FD402756d0d6FA0330de38C6c29;
    address memberExtensionFactoryAddress = 0x9bd452E606714Bd10726eD0Dd968A0df7Cd12a00;
    address dynamicEquityExtensionFactoryAddress = 0x9bd452E606714Bd10726eD0Dd968A0df7Cd12a00;
    address vestedEquityExtensionFactoryAddress = 0xe637BE9d6e04fc44C8EE18d9CC4668B5476e5e14;
    address communityIncentiveExtensionFactoryAddress = 0xe1730cFF138a5Cd1D793F037CAb9197f274C6732;
      //address erc1155TokenCollectionFactoryAddress = 0xa9A41180488FB4E9C95A8E239283643fF4E7A033;
      //address erc1271ExtensionFactoryAddress = 0x4e6B44EaA0B0B5157b2D94F3aeaba2da21333e6e;
      //address nftCollectionFactoryAddress = 0x11519997d9452f510DE67c3A97e76F787df53f52;
      //address executorExtensionFactoryAddress = 0x73917D1bfB83671AE2EE8832D0a938BD5Ac0DC6a;
    //ADAPTER
    address daoRegistryAdapterContractAddress = 0xc299b245729928eAC1476E0256C58E082CAF37e1;
    address bankAdapterContractAddress = 0x08cD229F0eAA028d04e26170566Bd04fb2EBA755;
    address configurationContractAddress = 0xEbA9383543B3a21D0E8B10e68b7e7A11BE65aeff;
    address managingContractAddress = 0x713a652171555E14a4d62d4d4d1029175f0Ddbfd;
    address managerAddress = 0x3cDF7A0B4B78ed744c18Aa99Ac8FE46af5503693;
    address dynamicEquityAdapterAddress = 0x2631bf4eCcb03eAe3B513D61979A23aBdDd50845;
    address vestedEquityAdapterAddress = 0xA388f9e353cB3b36f4820a46F1b0165FF7C78296;
    address communityIncentiveAdapterAddress = 0xd81426B4506B7b9b531D1296E153462bAC5FfbF8;
    address memberAdapterAddress = 0x639065400627260Dc8c60Bf5948B910B745C6720;
    address votingAdapterAddress = 0x36EE28C95E6aFA2e291ABdC46579Eb212E3E2fbB;
    address ERC20TransferStrategyAddress = 0x300761B934c60716A5ffD41cc50e88F6F53b3408;
    address multicallAddress = 0xf56ccB937dB963674a7935bda315132A299b747D;
      //address signaturesContractAddress = 0xA4eA0F9c93d5Aca3117999bc5EBb1743fDe55692;
      //address onboardingContractAddress = 0x9C4443e13F3ff47Aa1Be8a108d2E529755e91d1F;
      //address ERC1155AdapterContractAddress = 0xEe7DD41D6Ed50aCD0B2fB84b5bd3A653944F2b9f;

    //CORE
    DaoFactory daoFactory; 
    //EXTENSION
    BankFactory bankFactory;
    ERC20TokenExtensionFactory erc20TokenExtensionFactory;
    MemberExtensionFactory memberExtensionFactory;
    DynamicEquityExtensionFactory dynamicEquityExtensionFactory;
    VestedEquityExtensionFactory vestedEquityExtensionFactory;
    CommunityIncentiveExtensionFactory communityIncentiveExtensionFactory;
      //ERC1155TokenCollectionFactory erc1155TokenCollectionFactory;
      //ERC1271ExtensionFactory erc1271ExtensionFactory;
      //NFTCollectionFactory nftCollectionFactory;
      //ExecutorExtensionFactory executorExtensionFactory;
    //ADAPTER
    Manager manager;
    VotingAdapter votingAdapter;
    MemberAdapter memberAdapter;
    DynamicEquityAdapter dynamicEquityAdapter;
    VestedEquityAdapter vestedEquityAdapter;
    CommunityIncentiveAdapter communityIncentiveAdapter;
      //OnboardingContract onboardingContract;

    constructor() {        
        isAdmin[msg.sender]=true;
        
        daoFactory = DaoFactory(daoFactoryAddress);
        bankFactory = BankFactory(bankFactoryAddress);
        memberExtensionFactory = MemberExtensionFactory(memberExtensionFactoryAddress);
        erc20TokenExtensionFactory = ERC20TokenExtensionFactory(erc20TokenExtensionFactoryAddress);
        dynamicEquityExtensionFactory = DynamicEquityExtensionFactory(dynamicEquityExtensionFactoryAddress);
        vestedEquityExtensionFactory = VestedEquityExtensionFactory(vestedEquityExtensionFactoryAddress);
        communityIncentiveExtensionFactory = CommunityIncentiveExtensionFactory(communityIncentiveExtensionFactoryAddress);
          //erc1155TokenCollectionFactory = ERC1155TokenCollectionFactory(erc1155TokenCollectionFactoryAddress);
          //erc1271ExtensionFactory = ERC1271ExtensionFactory(erc1271ExtensionFactoryAddress);
          //nftCollectionFactory = NFTCollectionFactory(nftCollectionFactoryAddress);
          //executorExtensionFactory = ExecutorExtensionFactory(executorExtensionFactoryAddress);
        manager = Manager(managerAddress);
        votingAdapter = VotingAdapter(votingAdapterAddress);
        memberAdapter = MemberAdapter(memberAdapterAddress);
        dynamicEquityAdapter = DynamicEquityAdapter(dynamicEquityAdapterAddress);
        vestedEquityAdapter = VestedEquityAdapter(vestedEquityAdapterAddress);
        communityIncentiveAdapter = CommunityIncentiveAdapter(communityIncentiveAdapterAddress);
          //onboardingContract = OnboardingContract(onboardingContractAddress);
    }

    mapping(string => Foundance.FoundanceConfig) private registeredFoundance;
    mapping(uint32 => string) private registeredFoundanceWithId;
    mapping(address => bool) public isAdmin;

    modifier onlyCreator(string calldata foundanceName) {
        require(registeredFoundance[foundanceName].creatorAddress == msg.sender, "Only creatorAddress can access");
        _;
    }
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can access");
        _;
    }

    /**
     * @notice Register a Foundance Dao   
     * @dev The foundanceName must be unique and not previously registered.
     * @param foundanceName Name of the Dao
     * @param projectId THe internal project identifier for correlating projects and DAOs
     * @param factoryMemberConfigArray FactoryMemberConfig Array including all relevant data
     * @param tokenConfig *
     * @param votingConfig *
     * @param epochConfig *
     * @param dynamicEquityConfig *
     * @param communityIncentiveConfig *
     **/ 
    function registerFoundance( 
      string calldata foundanceName,
      uint32 projectId,
      Foundance.FactoryMemberConfig[] memory factoryMemberConfigArray,
      Foundance.TokenConfig calldata tokenConfig,
      Foundance.VotingConfig calldata  votingConfig,
      Foundance.EpochConfig calldata epochConfig,
      Foundance.DynamicEquityConfig calldata dynamicEquityConfig, 
      Foundance.CommunityIncentiveConfig calldata communityIncentiveConfig 
    ) external{
        require(isNameUnique(foundanceName),"Foundance-DAO or Foundance-Agreement with this name already created.");
        require(isIdUnique(projectId),"Foundance-Agreement with this projectId has already been created");        
        registeredFoundanceWithId[projectId] = foundanceName;
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        foundance.creatorAddress = msg.sender;
        //FOUNDANCE
        foundance.projectId = projectId;
        foundance.tokenConfig = tokenConfig; 	
        foundance.votingConfig = votingConfig; 	
        foundance.epochConfig = epochConfig; 	
        foundance.dynamicEquityConfig = dynamicEquityConfig; 	
        foundance.communityIncentiveConfig = communityIncentiveConfig; 	
        //MEMBER
        for(uint256 i=0;i<factoryMemberConfigArray.length;i++){
          factoryMemberConfigArray[i].foundanceApproved = false;
          foundance.factoryMemberConfigArray.push(factoryMemberConfigArray[i]);
          foundance.factoryMemberConfigIndex[factoryMemberConfigArray[i].memberAddress]=i+1;
        }
        foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[msg.sender]-1].foundanceApproved = true;
        foundance.foundanceStatus = Foundance.FoundanceStatus.REGISTERED;
        emit FoundanceRegistered(msg.sender, projectId, foundanceName);
     }

     /**
     * @notice Edit a Foundance Dao   
     * @dev The foundanceName must be previously registered.
     * @param foundanceName Name of the Dao
     * @param projectId THe internal project identifier for correlating projects and DAOs
     * @param factoryMemberConfigArray FactoryMemberConfig Array including all relevant data
     * @param tokenConfig *
     * @param votingConfig *
     * @param epochConfig *
     * @param dynamicEquityConfig *
     * @param communityIncentiveConfig *
     **/ 
    function updateFoundance( 
      string calldata foundanceName,
      uint32 projectId,
      Foundance.FactoryMemberConfig[] memory factoryMemberConfigArray,
      Foundance.TokenConfig calldata tokenConfig,
      Foundance.VotingConfig calldata  votingConfig,
      Foundance.EpochConfig calldata epochConfig,
      Foundance.DynamicEquityConfig calldata dynamicEquityConfig, 
      Foundance.CommunityIncentiveConfig calldata communityIncentiveConfig 
    ) external onlyCreator(foundanceName){
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        //FOUNDANCE
        foundance.tokenConfig = tokenConfig; 	
        foundance.votingConfig = votingConfig; 	
        foundance.epochConfig = epochConfig; 	
        foundance.dynamicEquityConfig = dynamicEquityConfig; 	
        foundance.communityIncentiveConfig = communityIncentiveConfig; 	
        //MEMBER
        Foundance.FactoryMemberConfig[] memory tempfactoryMemberConfigArray = foundance.factoryMemberConfigArray;
        for(uint256 i=0;i<tempfactoryMemberConfigArray.length;i++){
          foundance.factoryMemberConfigIndex[tempfactoryMemberConfigArray[i].memberAddress]=0;
          foundance.factoryMemberConfigArray.pop();          
        }
        for(uint256 i=0;i<factoryMemberConfigArray.length;i++){
          factoryMemberConfigArray[i].foundanceApproved = false;
          foundance.factoryMemberConfigArray.push(factoryMemberConfigArray[i]);
          foundance.factoryMemberConfigIndex[factoryMemberConfigArray[i].memberAddress]=i+1;
        }
        foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[msg.sender]-1].foundanceApproved = true;
        foundance.foundanceStatus = Foundance.FoundanceStatus.REGISTERED;
        emit FoundanceUpdated(msg.sender, projectId, foundanceName);
     }

    /**
    * @notice FactoryMemberConfig approves a registered Foundance-Agreement  
    * @param foundanceName Name of Foundance-DAO
    **/ 
    function approveFoundance(
      string calldata foundanceName
    ) external{
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        require(foundanceMemberExists(foundance, msg.sender), "FactoryMemberConfig doesnt exists in this Foundance-Agreement.");
        foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[msg.sender]-1].foundanceApproved = true;
        emit FoundanceApproved(msg.sender,foundance.projectId,foundanceName);
        if(_isFoundanceApproved(foundance)){
          foundance.foundanceStatus=Foundance.FoundanceStatus.APPROVED;
        }
    }

    /**
    * @notice Checks if the Foundance-Agreement is approved by all registered members.  
    * @param foundanceName Name of the Foundance DAO
    **/ 
    function isFoundanceApproved(string calldata foundanceName) external view returns(bool){
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];    
        return _isFoundanceApproved(foundance);
    }

    /**
    * @notice Checks if the Foundance-Agreement is approved by all registered members.  
    * @param foundance Foundance
    **/ 
    function _isFoundanceApproved(
      Foundance.FoundanceConfig storage foundance
    ) internal view returns(bool){
        for(uint256 i=0;i<foundance.factoryMemberConfigArray.length;i++){
          if(!foundance.factoryMemberConfigArray[i].foundanceApproved) return false;
        }
        return true;
    }

    /**
    * @notice Revokes approval for all members within a Foundance-Agreement
    * @param foundance Foundance
    **/ 
    function revokeApproval(Foundance.FoundanceConfig storage foundance) internal returns(Foundance.FoundanceConfig storage){
      for(uint256 i=0;i<foundance.factoryMemberConfigArray.length;i++){
      	foundance.factoryMemberConfigArray[i].foundanceApproved=false;
      }
      return foundance;
    }

    /**
    * @notice Create a Foundance-DAO based upon an already approved Foundance-Agreement 
    * @dev The Foundance-Agreement must be approved by all members
    * @dev This function must be accessed by the Foundance-Agreement creator
    * @param foundanceName Name of the Foundance-DAO
    **/ 
    function createFoundance(
      string calldata foundanceName
    ) external onlyCreator(foundanceName){
				Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
    	  require(_isFoundanceApproved(foundance), "Foundance-Agreement is not approved by all members");				
        //CREATE_CORE
        daoFactory.createDao(foundanceName, msg.sender);
        address daoAddress = daoFactory.getDaoAddress(foundanceName);
        DaoRegistry daoRegistry = DaoRegistry(daoAddress);
        //CREATE_EXTENSION
        bankFactory.create(daoRegistry,foundance.tokenConfig.maxExternalTokens);
        erc20TokenExtensionFactory.create(daoRegistry,foundance.tokenConfig.tokenName,DaoHelper.UNITS,foundance.tokenConfig.tokenSymbol,foundance.tokenConfig.decimals);
        memberExtensionFactory.create(daoRegistry);
        dynamicEquityExtensionFactory.create(daoRegistry);
        vestedEquityExtensionFactory.create(daoRegistry);
        communityIncentiveExtensionFactory.create(daoRegistry);
          //erc1155TokenCollectionFactory.create(daoRegistry);//(DaoRegistry dao)
          //erc1271ExtensionFactory.create(daoRegistry);//(DaoRegistry dao)
          //executorExtensionFactory.create(daoRegistry);//(DaoRegistry dao)
          //nftCollectionFactory.create(daoRegistry);//(DaoRegistry dao)
        //GET_ADDRESSES
        address bankExtensionAddress = bankFactory.getExtensionAddress(daoAddress);
        address erc20TokenExtensionAddress = erc20TokenExtensionFactory.getExtensionAddress(daoAddress);
        address memberExtensionAddress = memberExtensionFactory.getExtensionAddress(daoAddress);
        address dynamicEquityExtensionAddress = dynamicEquityExtensionFactory.getExtensionAddress(daoAddress);
        address vestedEquityExtensionAddress = vestedEquityExtensionFactory.getExtensionAddress(daoAddress);
        address communityIncentiveExtensionAddress = communityIncentiveExtensionFactory.getExtensionAddress(daoAddress);
          //address erc1155TokenExtensionAddress = erc1155TokenCollectionFactory.getExtensionAddress(daoAddress);
          //address erc1271ExtensionAddress = erc1271ExtensionFactory.getExtensionAddress(daoAddress);
          //address executorExtensionAddress = executorExtensionFactory.getExtensionAddress(daoAddress);
          //address nftExtensionAddress = nftCollectionFactory.getExtensionAddress(daoAddress);
        //ENABLE_EXTENSION
        daoRegistry.addExtension(DaoHelper.BANK, IExtension(bankExtensionAddress));
        daoRegistry.addExtension(DaoHelper.ERC20_EXT,IExtension(erc20TokenExtensionAddress));
        daoRegistry.addExtension(DaoHelper.MEMBER_EXT,IExtension(memberExtensionAddress));
        daoRegistry.addExtension(DaoHelper.DYNAMIC_EQUITY_EXT,IExtension(dynamicEquityExtensionAddress));
        daoRegistry.addExtension(DaoHelper.VESTED_EQUITY_EXT,IExtension(vestedEquityExtensionAddress));
        daoRegistry.addExtension(DaoHelper.COMMUNITY_INCENTIVE_EXT,IExtension(communityIncentiveExtensionAddress));
          //daoRegistry.addExtension(DaoHelper.ERC1155_EXT,IExtension(erc1155TokenExtensionAddress));
          //daoRegistry.addExtension(DaoHelper.ERC1271,IExtension(erc1271ExtensionAddress));
          //daoRegistry.addExtension(DaoHelper.EXECUTOR_EXT,IExtension(executorExtensionAddress));
          //daoRegistry.addExtension(DaoHelper.NFT,IExtension(nftExtensionAddress));
        //CONFIGURATION  
        daoRegistry.setConfiguration(keccak256("erc20.transfer.type"), 2);//no transfers
        //ADDRESS_CONFIGURATION  
        daoRegistry.setAddressConfiguration(keccak256(abi.encodePacked("governance.role.", configurationContractAddress)), DaoHelper.UNITS); // Here we should put maintainerTokenAddress
        daoRegistry.setAddressConfiguration(keccak256(abi.encodePacked("governance.role.", managingContractAddress)), DaoHelper.UNITS); // Here we should put maintainerTokenAddress
        //CORE_ADAPTER_ACL
        {
        DaoFactory.Adapter[] memory adapterList = new DaoFactory.Adapter[](13);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.DAO_REGISTRY_ADAPT,daoRegistryAdapterContractAddress,uint128(4));
          adapterList[1] = DaoFactory.Adapter(DaoHelper.BANK_ADAPT,bankAdapterContractAddress,uint128(0));
          adapterList[2] = DaoFactory.Adapter(DaoHelper.CONFIGURATION,configurationContractAddress,uint128(10));        
          adapterList[3] = DaoFactory.Adapter(DaoHelper.MANAGING,managingContractAddress,uint128(59));
          adapterList[4] = DaoFactory.Adapter(keccak256("manager"),managerAddress,uint128(59));        
          adapterList[5] = DaoFactory.Adapter(DaoHelper.VOTING_ADAPT,votingAdapterAddress,uint128(0));
          adapterList[6] = DaoFactory.Adapter(DaoHelper.MEMBER_ADAPT,memberAdapterAddress,uint128(66));
          adapterList[7] = DaoFactory.Adapter(DaoHelper.ERC20_TRANSFER_STRATEGY_ADPT,ERC20TransferStrategyAddress,uint128(0));
          adapterList[8] = DaoFactory.Adapter(keccak256("foundanceFactory"),address(this),uint128(127));
          adapterList[9] = DaoFactory.Adapter(DaoHelper.ERC20_EXT,erc20TokenExtensionAddress,uint128(64));
          adapterList[10] = DaoFactory.Adapter(DaoHelper.DYNAMIC_EQUITY_ADAPT,dynamicEquityAdapterAddress,uint128(127));
          adapterList[11] = DaoFactory.Adapter(DaoHelper.VESTED_EQUITY_ADAPT,vestedEquityAdapterAddress,uint128(127));
          adapterList[12] = DaoFactory.Adapter(DaoHelper.COMMUNITY_INCENTIVE_ADAPT,communityIncentiveAdapterAddress,uint128(127));
            //adapterList[] = DaoFactory.Adapter(DaoHelper.ERC1155_ADAPT,ERC1155AdapterContractAddress,uint128(0));
            //adapterList[] = DaoFactory.Adapter(DaoHelper.ERC1271_ADAPT,signaturesContractAddress,uint128(2));
            //adapterList[] = DaoFactory.Adapter(DaoHelper.ONBOARDING,onboardingContractAddress,uint128(70));
        daoFactory.addAdapters(daoRegistry, adapterList);
        }
        {
        //CONFIGURATION  
        manager.configureDao(daoRegistry, msg.sender);
        votingAdapter.configureDao(daoRegistry, foundance.votingConfig);
          //noTributeAdapter.configureDao(daoRegistry, DaoHelper.UNITS);
          //noTributeAdapter.configureDao(daoRegistry, DaoHelper.LOOT);
          //onboardingContract.configureDao(daoRegistry, DaoHelper.UNITS, 100000000000000000, 100000, 11,address(0x0));//This transaction is made twice with different unitsToMint parameter???
          //onboardingContract.configureDao(daoRegistry, DaoHelper.LOOT, 100000000000000000, 100000, 11,address(0x0));//This transaction is made twice with different unitsToMint parameter??
        }
        //EXTENSION_ADAPTER_ACL
        {
        DaoFactory.Adapter[] memory adapterList = new DaoFactory.Adapter[](8);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.BANK_ADAPT,bankAdapterContractAddress,uint128(75));        
          adapterList[1] = DaoFactory.Adapter(DaoHelper.MEMBER_ADAPT,memberAdapterAddress,uint128(17));
          adapterList[2] = DaoFactory.Adapter(DaoHelper.ERC20_TRANSFER_STRATEGY_ADPT,ERC20TransferStrategyAddress,uint128(4));
          adapterList[3] = DaoFactory.Adapter(keccak256("foundanceFactory"),address(this),uint128(127));
          adapterList[4] = DaoFactory.Adapter(DaoHelper.DYNAMIC_EQUITY_ADAPT,dynamicEquityAdapterAddress,uint128(7));
          adapterList[5] = DaoFactory.Adapter(DaoHelper.VESTED_EQUITY_ADAPT,dynamicEquityAdapterAddress,uint128(7));
          adapterList[6] = DaoFactory.Adapter(DaoHelper.COMMUNITY_INCENTIVE_ADAPT,communityIncentiveAdapterAddress,uint128(15));
          adapterList[7] = DaoFactory.Adapter(DaoHelper.VOTING_ADAPT,votingAdapterAddress,uint128(4));
          //adapterList[] = DaoFactory.Adapter(DaoHelper.ONBOARDING,onboardingContractAddress,uint128(5));
        daoFactory.configureExtension(daoRegistry, bankExtensionAddress, adapterList);

        adapterList = new DaoFactory.Adapter[](2);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.MEMBER_ADAPT,memberAdapterAddress,uint128(7));
          adapterList[1] = DaoFactory.Adapter(keccak256("foundanceFactory"),address(this),uint128(7));
        daoFactory.configureExtension(daoRegistry, memberExtensionAddress, adapterList);

        adapterList = new DaoFactory.Adapter[](2);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.DYNAMIC_EQUITY_ADAPT,dynamicEquityAdapterAddress,uint128(7));
          adapterList[1] = DaoFactory.Adapter(keccak256("foundanceFactory"),address(this),uint128(7));
        daoFactory.configureExtension(daoRegistry, dynamicEquityExtensionAddress, adapterList);

        adapterList = new DaoFactory.Adapter[](2);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.VESTED_EQUITY_ADAPT,vestedEquityAdapterAddress,uint128(7));
          adapterList[1] = DaoFactory.Adapter(keccak256("foundanceFactory"),address(this),uint128(7));
        daoFactory.configureExtension(daoRegistry, vestedEquityExtensionAddress, adapterList);

        adapterList = new DaoFactory.Adapter[](2);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.COMMUNITY_INCENTIVE_ADAPT,communityIncentiveAdapterAddress,uint128(7));
          adapterList[1] = DaoFactory.Adapter(keccak256("foundanceFactory"),address(this),uint128(7));
        daoFactory.configureExtension(daoRegistry, communityIncentiveExtensionAddress, adapterList);

        adapterList = new DaoFactory.Adapter[](1);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.ERC20_EXT,erc20TokenExtensionAddress,uint128(4));
        daoFactory.configureExtension(daoRegistry, bankExtensionAddress, adapterList);
        }
        /*
          DaoFactory.Adapter[] memory adapterList = new DaoFactory.Adapter[](1);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.ERC1155_ADAPT,ERC1155AdapterContractAddress,uint128(7));
          daoFactory.configureExtension(daoRegistry, nftExtensionAddress, adapterList);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.ERC1271_ADAPT,signaturesContractAddress,uint128(1));
          daoFactory.configureExtension(daoRegistry, erc1271ExtensionAddress, adapterList);
          adapterList[0] = DaoFactory.Adapter(DaoHelper.ERC1155_ADAPT,ERC1155AdapterContractAddress,uint128(7));
          daoFactory.configureExtension(daoRegistry, erc1155TokenExtensionAddress, adapterList);
        */
        _createFoundanceInternal(
          daoRegistry,
          bankExtensionAddress,
          memberExtensionAddress,
          dynamicEquityExtensionAddress,
          vestedEquityExtensionAddress,
          communityIncentiveExtensionAddress,
          foundance
        );
        //FINALIZE_DAO
        daoRegistry.finalizeDao();
				foundance.foundanceStatus=Foundance.FoundanceStatus.LIVE;
        emit FoundanceLive(msg.sender,foundance.projectId,daoAddress,bankExtensionAddress, memberExtensionAddress, dynamicEquityExtensionAddress, vestedEquityExtensionAddress, communityIncentiveExtensionAddress);
    }
    function _createFoundanceInternal(
      DaoRegistry daoRegistry,
      address bankExtensionAddress, 
      address memberExtensionAddress,
      address dynamicEquityExtensionAddress,
      address vestedEquityExtensionAddress,
      address communityIncentiveExtensionAddress,
      Foundance.FoundanceConfig storage foundance
    ) internal {
        //CREATE_EXTENSION_INSTANCE
        BankExtension bank = BankExtension(bankExtensionAddress);
        MemberExtension member = MemberExtension(memberExtensionAddress);
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dynamicEquityExtensionAddress);
        VestedEquityExtension vestedEquity = VestedEquityExtension(vestedEquityExtensionAddress);
        CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(communityIncentiveExtensionAddress);
        //CONFIGURE_EXTENSION
        bank.registerPotentialNewInternalToken(daoRegistry, DaoHelper.UNITS);
        dynamicEquity.setDynamicEquity(daoRegistry,foundance.dynamicEquityConfig,foundance.epochConfig);
        //communityIncentive.setCommunityIncentive(daoRegistry,foundance.communityIncentiveConfig,foundance.epochConfig);
        //CONFIGURE_EXTENSION_PER_MEMBER
        for(uint256 i=0;i<foundance.factoryMemberConfigArray.length;i++){
          Foundance.FactoryMemberConfig memory factoryMemberConfig = foundance.factoryMemberConfigArray[i];
          member.setMember(daoRegistry, factoryMemberConfig.memberConfig);
          if(factoryMemberConfig.dynamicEquityMemberConfig.memberAddress==factoryMemberConfig.memberAddress){
            dynamicEquity.setDynamicEquityMember(daoRegistry,factoryMemberConfig.dynamicEquityMemberConfig);
          }
          if(factoryMemberConfig.vestedEquityMemberConfig.memberAddress==factoryMemberConfig.memberAddress){
            vestedEquity.setVestedEquityMember(daoRegistry,factoryMemberConfig.vestedEquityMemberConfig);
          }
          if(factoryMemberConfig.communityIncentiveMemberConfig.memberAddress==factoryMemberConfig.memberAddress){
            //communityIncentive.setCommunityIncentiveMember(daoRegistry,factoryMemberConfig.communityIncentiveMemberConfig);
          }
        }
    }
    /**
    * @notice Checks if the member exists within the Foundance
    * @dev The Foundance must exist
    * @param foundance Foundance
    * @param _member Address of member
    **/ 
    function foundanceMemberExists(
      Foundance.FoundanceConfig storage foundance, 
      address _member
    ) internal view returns(bool){
        require(foundance.creatorAddress!=address(0x0),"There is no foundance with this name");
        uint memberIndex = foundance.factoryMemberConfigIndex[_member];
        if(memberIndex==0){
      	  return false;
        }
        return true;
    }
 
    //FactoryMemberConfig management for registered Foundance-Agreement
    /*
		function addMember(string calldata foundanceName, Foundance.FactoryMemberConfig calldata _member) external onlyCreator(foundanceName){ 
    	Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];      
      require(!foundanceMemberExists(foundance, _member.memberAddress), "FactoryMemberConfig already exists in this foundance"); 
      
      foundance.factoryMemberConfigArray.push(_member);
      foundance.factoryMemberConfigIndex[_member.memberAddress]=foundance.factoryMemberConfigArray.length;
      revokeApproval(foundance);
    }
 
    function deleteMember(string calldata foundanceName, address _member) external onlyCreator(foundanceName){
    	Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];   
      require(foundanceMemberExists(foundance, _member), "FactoryMemberConfig doesnt exists in this foundance");
      
      foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[_member]-1] = foundance.factoryMemberConfigArray[foundance.factoryMemberConfigArray.length-1];
      foundance.factoryMemberConfigIndex[foundance.factoryMemberConfigArray[foundance.factoryMemberConfigArray.length-1].memberAddress] = foundance.factoryMemberConfigIndex[_member];      
      foundance.factoryMemberConfigIndex[_member]=0;
      foundance.factoryMemberConfigArray.pop();
			revokeApproval(foundance);
    }
    
    function changeMember(string calldata foundanceName, Foundance.FactoryMemberConfig calldata _member) external onlyCreator(foundanceName){
    	Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];   
      require(foundanceMemberExists(foundance, _member.memberAddress), "FactoryMemberConfig doesnt exists in this foundance");
      
      foundance.factoryMemberConfigArray[foundance.factoryMemberConfigIndex[_member.memberAddress]-1] = _member;
      revokeApproval(foundance);
    }
    */
    // Admin Functions
    function addAdmins(address[] calldata admins) public onlyAdmin{
      for(uint256 i=0;i<admins.length;i++){
        isAdmin[admins[i]] = true;
      }
    }
    function removeAdmins(address[] calldata admins) public onlyAdmin{
      for(uint256 i=0;i<admins.length;i++){
        isAdmin[admins[i]] = false;
      }
    }
    function setIdtoDaoName(uint32 projectId, string calldata name) public onlyAdmin{
      registeredFoundanceWithId[projectId] = name;
    }
    function setFoundanceConfig(
      string calldata foundanceName,
      uint32 projectId,
      Foundance.FactoryMemberConfig[] memory factoryMemberConfigArray,
      Foundance.TokenConfig calldata tokenConfig,
      Foundance.VotingConfig calldata  votingConfig,
      Foundance.EpochConfig calldata epochConfig,
      Foundance.DynamicEquityConfig calldata dynamicEquityConfig, 
      Foundance.CommunityIncentiveConfig calldata communityIncentiveConfig,
      address creatorAddress,
      uint8 foundanceStatus
      ) public onlyAdmin{
        registeredFoundanceWithId[projectId] = foundanceName;
        Foundance.FoundanceConfig storage foundance = registeredFoundance[foundanceName];
        foundance.creatorAddress = creatorAddress;
        //FOUNDANCE
        foundance.projectId = projectId;
        foundance.tokenConfig = tokenConfig; 	
        foundance.votingConfig = votingConfig; 	
        foundance.epochConfig = epochConfig; 	
        foundance.dynamicEquityConfig = dynamicEquityConfig; 	
        foundance.communityIncentiveConfig = communityIncentiveConfig;          
        //MEMBER
        for(uint256 i=0;i<factoryMemberConfigArray.length;i++){
          foundance.factoryMemberConfigIndex[factoryMemberConfigArray[i].memberAddress]=i+1;
          factoryMemberConfigArray[i].foundanceApproved = false;
          foundance.factoryMemberConfigArray.push(factoryMemberConfigArray[i]);
        }
        foundance.foundanceStatus = Foundance.FoundanceStatus(foundanceStatus);
    }

    //view Functions

    function isNameUnique(string calldata foundanceName) public view returns(bool){       
       return daoFactory.getDaoAddress(foundanceName)==address(0x0) && registeredFoundance[foundanceName].creatorAddress==address(0x0);   
    }
    function isIdUnique(uint32 projectId) public view returns(bool){       
      return bytes(registeredFoundanceWithId[projectId]).length==0;     
    }

    function getFoundanceMembers(string calldata foundanceName) public view returns(Foundance.FactoryMemberConfig[] memory _factoryMemberConfigArray){
       return registeredFoundance[foundanceName].factoryMemberConfigArray;       
    }
    function getFoundanceTokenConfig(string calldata foundanceName) public view returns(Foundance.TokenConfig memory _factoryMemberConfigArray){
       return registeredFoundance[foundanceName].tokenConfig;       
    }
    function getFoundanceDynamicEquityConfig(string calldata foundanceName) public view returns(Foundance.DynamicEquityConfig memory _factoryMemberConfigArray){
       return registeredFoundance[foundanceName].dynamicEquityConfig;       
    }
    function getFoundanceVotingConfig(string calldata foundanceName) public view returns(Foundance.VotingConfig memory){
       return registeredFoundance[foundanceName].votingConfig;       
    }
    function getFoundanceEpochConfig(string calldata foundanceName) public view returns(Foundance.EpochConfig memory){
       return registeredFoundance[foundanceName].epochConfig;       
    }
    function getFoundanceCommunityIncentiveConfig(string calldata foundanceName) public view returns(Foundance.CommunityIncentiveConfig memory){
       return registeredFoundance[foundanceName].communityIncentiveConfig;       
    }
    function getFoundanceCreatorAddress(string calldata foundanceName) public view returns(address){
       return registeredFoundance[foundanceName].creatorAddress;       
    }
    function getFoundanceStatus(string calldata foundanceName) public view returns(Foundance.FoundanceStatus){
       return registeredFoundance[foundanceName].foundanceStatus;       
    }
    function getFoundancewithId(uint32 projectId) public view returns(string memory){
       return registeredFoundanceWithId[projectId];       
    }
    function getFoundanceConfigWithId(uint32 projectId) public view returns(Foundance.FoundanceConfigView memory){
      string memory foundanceName  = registeredFoundanceWithId[projectId];
      Foundance.FoundanceConfig storage config = registeredFoundance[foundanceName];
      Foundance.FoundanceConfigView memory configView = Foundance.FoundanceConfigView(config.creatorAddress, foundanceName, config.foundanceStatus, config.factoryMemberConfigArray, config.tokenConfig, config.votingConfig, config.epochConfig, config.dynamicEquityConfig, config.communityIncentiveConfig);
      return configView;       
    }
    
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
library Foundance {
  //CONFIG
  struct FoundanceConfig {
    address creatorAddress;
    uint32 projectId;
    FoundanceStatus foundanceStatus;
    FactoryMemberConfig[] factoryMemberConfigArray;
    mapping(address => uint256) factoryMemberConfigIndex;
    TokenConfig tokenConfig;
    VotingConfig votingConfig;
    EpochConfig epochConfig;
    DynamicEquityConfig dynamicEquityConfig;
    CommunityIncentiveConfig communityIncentiveConfig;
  }
  struct FoundanceConfigView {
    address creatorAddress;
    string foundanceName;
    FoundanceStatus foundanceStatus;
    FactoryMemberConfig[] factoryMemberConfigArray;
    TokenConfig tokenConfig;
    VotingConfig votingConfig;
    EpochConfig epochConfig;
    DynamicEquityConfig dynamicEquityConfig;
    CommunityIncentiveConfig communityIncentiveConfig;
  }

  struct TokenConfig {
    string tokenName;
    string tokenSymbol;
    uint8 maxExternalTokens;
    uint8 decimals;
  }

  struct VotingConfig {
    VotingType votingType;
    uint256 votingPeriod;
    uint256 gracePeriod;
    uint256 disputePeriod;
    uint256 passRateMember;
    uint256 passRateToken;
    uint256 supportRequired;
  }

  struct EpochConfig {
    uint256 epochDuration;
    uint256 epochReview;
    uint256 epochStart;
    uint256 epochLast;
  }
  struct DynamicEquityConfig {
    uint256 riskMultiplier;
    uint256 timeMultiplier;
  }

  struct CommunityIncentiveConfig {
    AllocationType allocationType;
    uint256 allocationTokenAmount;
    uint256 tokenAmount;
  }

  //MEMBER_CONFIG
  struct FactoryMemberConfig {
    address memberAddress;
    bool foundanceApproved;
    MemberConfig memberConfig;
    DynamicEquityMemberConfig dynamicEquityMemberConfig;
    VestedEquityMemberConfig vestedEquityMemberConfig;
    CommunityIncentiveMemberConfig communityIncentiveMemberConfig;
  }

  struct MemberConfig {
    address memberAddress;
    uint256 initialAmount;
    uint256 initialPeriod;
    bool appreciationRight;
  }

  struct DynamicEquityMemberConfig {
    address memberAddress;
    uint256 suspendedUntil;
    uint256 availability;
    uint256 availabilityThreshold;
    uint256 salary;
    uint256 salaryMarket;
    uint256 salaryThreshold;
    uint256 expense;
    uint256 expenseThreshold;
    uint256 expenseAdhoc;
  }

  struct VestedEquityMemberConfig {
    address memberAddress;
    uint256 tokenAmount;
    uint256 duration;
    uint256 start;
    uint256 cliff;
  }

  struct CommunityIncentiveMemberConfig {
    address memberAddress;
    uint256 singlePaymentAmountThreshold;
    uint256 totalPaymentAmountThreshold;
    uint256 totalPaymentAmount;
  }

  //ENUM
  enum FoundanceStatus {
    REGISTERED,
    APPROVED,
    LIVE
  }

  enum VotingType {
    LINEAR,
    WEIGHTED,
    QUADRATIC,
    OPTIMISTIC,
    COOPERATIVE
  }

  enum AllocationType {
    POOL,
    EPOCH
  }

  enum ProposalStatus {
    NOT_STARTED,
    IN_PROGRESS,
    DONE,
    FAILED
  }

  //CONSTANTS
  uint256 internal constant FOUNDANCE_WORKDAYS_WEEK = 5;

  uint256 internal constant FOUNDANCE_MONTHS_YEAR = 12;

  uint256 internal constant FOUNDANCE_WEEKS_MONTH = 434524;

  uint256 internal constant FOUNDANCE_WEEKS_MONTH_PRECISION = 5;

  uint256 internal constant FOUNDANCE_PRECISION = 5;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "./DaoRegistry.sol";
import "./CloneFactory.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract DaoFactory is CloneFactory {
    struct Adapter {
        bytes32 id;
        address addr;
        uint128 flags;
    }

    // daoAddr => hashedName
    mapping(address => bytes32) public daos;
    // hashedName => daoAddr
    mapping(bytes32 => address) public addresses;

    address public identityAddress;

    /**
     * @notice Event emitted when a new DAO has been created.
     * @param _address The DAO address.
     * @param _name The DAO name.
     */
    event DAOCreated(address _address, string _name);

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "invalid addr");
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates and initializes a new DaoRegistry with the DAO creator and the transaction sender.
     * @notice Enters the new DaoRegistry in the DaoFactory state.
     * @dev The daoName must not already have been taken.
     * @param daoName The name of the DAO which, after being hashed, is used to access the address.
     * @param creator The DAO's creator, who will be an initial member.
     */
    function createDao(string calldata daoName, address creator) external {
        bytes32 hashedName = keccak256(abi.encode(daoName));
        require(
            addresses[hashedName] == address(0x0),
            string(abi.encodePacked("name ", daoName, " already taken"))
        );
        DaoRegistry dao = DaoRegistry(_createClone(identityAddress));

        address daoAddr = address(dao);
        addresses[hashedName] = daoAddr;
        daos[daoAddr] = hashedName;

        dao.initialize(creator, msg.sender);
        //slither-disable-next-line reentrancy-events
        emit DAOCreated(daoAddr, daoName);
    }

    /**
     * @notice Returns the DAO address based on its name.
     * @return The address of a DAO, given its name.
     * @param daoName Name of the DAO to be searched.
     */
    function getDaoAddress(string calldata daoName)
        external
        view
        returns (address)
    {
        return addresses[keccak256(abi.encode(daoName))];
    }

    /**
     * @notice Adds adapters and sets their ACL for DaoRegistry functions.
     * @dev A new DAO is instantiated with only the Core Modules enabled, to reduce the call cost. This call must be made to add adapters.
     * @dev The message sender must be an active member of the DAO.
     * @dev The DAO must be in `CREATION` state.
     * @param dao DaoRegistry to have adapters added to.
     * @param adapters Adapter structs to be added to the DAO.
     */
    function addAdapters(DaoRegistry dao, Adapter[] calldata adapters)
        external
    {
        require(dao.isMember(msg.sender), "not member");
        //Registring Adapters
        require(
            dao.state() == DaoRegistry.DaoState.CREATION,
            "this DAO has already been setup"
        );

        for (uint256 i = 0; i < adapters.length; i++) {
            //slither-disable-next-line calls-loop
            dao.replaceAdapter(
                adapters[i].id,
                adapters[i].addr,
                adapters[i].flags,
                new bytes32[](0),
                new uint256[](0)
            );
        }
    }

    /**
     * @notice Configures extension to set the ACL for each adapter that needs to access the extension.
     * @dev The message sender must be an active member of the DAO.
     * @dev The DAO must be in `CREATION` state.
     * @param dao DaoRegistry for which the extension is being configured.
     * @param extension The address of the extension to be configured.
     * @param adapters Adapter structs for which the ACL is being set for the extension.
     */
    function configureExtension(
        DaoRegistry dao,
        address extension,
        Adapter[] calldata adapters
    ) external {
        require(dao.isMember(msg.sender), "not member");
        //Registring Adapters
        require(
            dao.state() == DaoRegistry.DaoState.CREATION,
            "this DAO has already been setup"
        );

        for (uint256 i = 0; i < adapters.length; i++) {
            //slither-disable-next-line calls-loop
            dao.setAclToExtensionForAdapter(
                extension,
                adapters[i].addr,
                adapters[i].flags
            );
        }
    }

    /**
     * @notice Removes an adapter with a given ID from a DAO, and adds a new one of the same ID.
     * @dev The message sender must be an active member of the DAO.
     * @dev The DAO must be in `CREATION` state.
     * @param dao DAO to be updated.
     * @param adapter Adapter that will be replacing the currently-existing adapter of the same ID.
     */
    function updateAdapter(DaoRegistry dao, Adapter calldata adapter) external {
        require(dao.isMember(msg.sender), "not member");
        require(
            dao.state() == DaoRegistry.DaoState.CREATION,
            "this DAO has already been setup"
        );

        dao.replaceAdapter(
            adapter.id,
            adapter.addr,
            adapter.flags,
            new bytes32[](0),
            new uint256[](0)
        );
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import '../guards/AdapterGuard.sol';
import '../guards/MemberGuard.sol';
import '../extensions/IExtension.sol';
import '../helpers/DaoHelper.sol';

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract DaoRegistry is MemberGuard, AdapterGuard {
    /**
     * EVENTS
     */
    event SubmittedProposal(bytes32 proposalId, uint256 flags);
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    event ProcessedProposal(bytes32 proposalId, uint256 flags);
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    event AdapterRemoved(bytes32 adapterId);
    event ExtensionAdded(bytes32 extensionId, address extensionAddress);
    event ExtensionRemoved(bytes32 extensionId);
    event UpdateDelegateKey(address memberAddress, address newDelegateKey);
    event ConfigurationUpdated(bytes32 key, uint256 value);
    event AddressConfigurationUpdated(bytes32 key, address value);

    /**
     * ENUM
     */
    enum DaoState {
        CREATION,
        READY
    }

    enum MemberFlag {
        EXISTS,
        JAILED
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        JAIL_MEMBER
    }

    /**
     * STRUCTURES
     */
    struct Proposal {
        /// the structure to track all the proposals in the DAO
        address adapterAddress; /// the adapter address that called the functions to change the DAO state
        uint256 flags; /// flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
    }
 
    struct Member {
        /// the structure to track all the members in the DAO
        uint256 flags; /// flags to track the state of the member: exists, etc
    }

    struct Checkpoint {
        /// A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    struct DelegateCheckpoint {
        /// A checkpoint for marking the delegate key for a member from a given block
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
        bool deleted;
    }

    /**
     * PUBLIC VARIABLES
     */

    /// @notice internally tracks deployment under eip-1167 proxy pattern
    bool public initialized = false;

    /// @notice The dao state starts as CREATION and is changed to READY after the finalizeDao call
    DaoState public state;

    /// @notice The map to track all members of the DAO with their existing flags
    mapping(address => Member) public members;
    /// @notice The list of members
    address[] private _members;

    /// @notice delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;
    /// @notice The map that tracks the voting adapter address per proposalId: proposalId => adapterAddress
    mapping(bytes32 => address) public votingAdapter;
    /// @notice The map that keeps track of all adapters registered in the DAO: sha3(adapterId) => adapterAddress
    mapping(bytes32 => address) public adapters;
    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;
    /// @notice The map that keeps track of all extensions registered in the DAO: sha3(extId) => extAddress
    mapping(bytes32 => address) public extensions;
    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;
    /// @notice The map that keeps track of configuration parameters for the DAO and adapters: sha3(configId) => numericValue
    mapping(bytes32 => uint256) public mainConfiguration;
    /// @notice The map to track all the configuration of type Address: sha3(configId) => addressValue
    mapping(bytes32 => address) public addressConfiguration;

    /// @notice controls the lock mechanism using the block.number
    uint256 public lockedAt;

    /**
     * INTERNAL VARIABLES
     */

    /// @notice memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) _checkpoints;
    /// @notice memberAddress => numDelegateCheckpoints
    mapping(address => uint32) _numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    //slither-disable-next-line reentrancy-no-eth
    function initialize(address creator, address payer) external {
        require(!initialized, 'dao already initialized');
        initialized = true;
        potentialNewMember(msg.sender);
        potentialNewMember(creator);
        potentialNewMember(payer);
    }

    /**
     * ACCESS CONTROL
     */

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() external {
        require(
            isActiveMember(this, msg.sender) || isAdapter(msg.sender),
            'not allowed to finalize'
        );
        state = DaoState.READY;
    }

    /**
     * @notice Contract lock strategy to lock only the caller is an adapter or extension.
     */
    function lockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    /**
     * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
     */
    function unlockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    /**
     * CONFIGURATIONS
     */

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(bytes32 key, uint256 value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(key, value);
    }

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(bytes32 key, address value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(key, value);
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(bytes32 key) external view returns (uint256) {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(bytes32 key)
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    /**
     * ADAPTERS
     */

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) external hasAccess(this, AclFlag.REPLACE_ADAPTER) {
        require(adapterId != bytes32(0), 'adapterId must not be empty');

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];
            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;
            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            require(
                inverseAdapters[adapterAddress].id == bytes32(0),
                'adapterAddress already in use'
            );
            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            emit AdapterAdded(adapterId, adapterAddress, acl);
        }
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(address adapterAddress) public view returns (bool) {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(address adapterAddress, AclFlag flag)
        external
        view
        returns (bool)
    {
        return
            DaoHelper.getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(bytes32 adapterId)
        external
        view
        returns (address)
    {
        require(adapters[adapterId] != address(0), 'adapter not found');
        return adapters[adapterId];
    }

    /**
     * EXTENSIONS
     */

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     */
    // slither-disable-next-line reentrancy-events
    function addExtension(bytes32 extensionId, IExtension extension)
        external
        hasAccess(this, AclFlag.ADD_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extension id must not be empty');
        require(
            extensions[extensionId] == address(0x0),
            'extensionId already in use'
        );
        require(
            !inverseExtensions[address(extension)].deleted,
            'extension can not be re-added'
        );
        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;
        emit ExtensionAdded(extensionId, address(extension));
    }

    // v1.0.6 signature
    function addExtension(
        bytes32,
        IExtension,
        address
    ) external {
        revert('not implemented');
    }

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(bytes32 extensionId)
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extensionId must not be empty');
        address extensionAddress = extensions[extensionId];
        require(extensionAddress != address(0x0), 'extensionId not registered');
        ExtensionEntry storage extEntry = inverseExtensions[extensionAddress];
        extEntry.deleted = true;
        //slither-disable-next-line mapping-deletion
        delete extensions[extensionId];
        emit ExtensionRemoved(extensionId);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(address extensionAddr) public view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
     */
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    ) external hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(isAdapter(adapterAddress), 'not an adapter');
        require(isExtension(extensionAddress), 'not an extension');
        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) external view returns (bool) {
        return
            isAdapter(adapterAddress) &&
            DaoHelper.getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(bytes32 extensionId)
        external
        view
        returns (address)
    {
        require(extensions[extensionId] != address(0), 'extension not found');
        return extensions[extensionId];
    }

    /**
     * PROPOSALS
     */

    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(bytes32 proposalId)
        external
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        require(proposalId != bytes32(0), 'invalid proposalId');
        require(
            !getProposalFlag(proposalId, ProposalFlag.EXISTS),
            'proposalId must be unique'
        );
        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS
        emit SubmittedProposal(proposalId, 1);
    }

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) external onlyMember2(this, sponsoringMember) {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can sponsor it'
        );

        require(
            !DaoHelper.getFlag(flags, uint8(ProposalFlag.PROCESSED)),
            'proposal already processed'
        );
        votingAdapter[proposalId] = votingAdapterAddr;
        emit SponsoredProposal(proposalId, flags, votingAdapterAddr);
    }

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(bytes32 proposalId) external {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        require(proposal.adapterAddress == msg.sender, 'err::adapter mismatch');
        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(bytes32 proposalId, ProposalFlag flag)
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        require(
            DaoHelper.getFlag(flags, uint8(ProposalFlag.EXISTS)),
            'proposal does not exist for this dao'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'invalid adapter try to set flag'
        );

        require(!DaoHelper.getFlag(flags, uint8(flag)), 'flag already set');

        flags = DaoHelper.setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return DaoHelper.getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * MEMBERS
     */

    /**
     * @notice Sets true for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function jailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        require(
            DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        member.flags = DaoHelper.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            true
        );
    }

    /**
     * @notice Sets false for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function unjailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        require(
            DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        member.flags = DaoHelper.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            false
        );
    }

    /**
     * @notice Checks if a given member address is not jailed.
     * @param memberAddress The address of the member to check the flag.
     */
    function notJailed(address memberAddress) external view returns (bool) {
        return
            !DaoHelper.getFlag(
                members[memberAddress].flags,
                uint8(MemberFlag.JAILED)
            );
    }

    /**
     * @notice Registers a member address in the DAO if it is not registered or invalid.
     * @notice A potential new member is a member that holds no shares, and its registration still needs to be voted on.
     */
    function potentialNewMember(address memberAddress)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        if (!DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            require(
                memberAddressesByDelegatedKey[memberAddress] == address(0x0),
                'member address already taken as delegated key'
            );
            member.flags = DaoHelper.setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[DaoHelper.BANK];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, DaoHelper.MEMBER_COUNT) == 0) {
                bank.addToBalance(
                    this,
                    memberAddress,
                    DaoHelper.MEMBER_COUNT,
                    1
                );
            }
        }
    }
    
    function potentialNewMemberBatch(address[] calldata memberAddressArray)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        for(uint256 i = 0;i<memberAddressArray.length;i++){
            require(memberAddressArray[i] != address(0x0), 'invalid member address');

            Member storage member = members[memberAddressArray[i]];
            if (!DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                require(
                    memberAddressesByDelegatedKey[memberAddressArray[i]] == address(0x0),
                    'member address already taken as delegated key'
                );
                member.flags = DaoHelper.setFlag(
                    member.flags,
                    uint8(MemberFlag.EXISTS),
                    true
                );
                memberAddressesByDelegatedKey[memberAddressArray[i]] = memberAddressArray[i];
                _members.push(memberAddressArray[i]);
            }
            address bankAddress = extensions[DaoHelper.BANK];
            if  (bankAddress != address(0x0)) {
                BankExtension bank = BankExtension(bankAddress);
                if (bank.balanceOf(memberAddressArray[i], DaoHelper.MEMBER_COUNT) == 0) {
                    bank.addToBalance(
                        this,
                        memberAddressArray[i],
                        DaoHelper.MEMBER_COUNT,
                        1
                    );
                }
            }
        }
    }
    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(address addr) external view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(address memberAddress, MemberFlag flag)
        public
        view
        returns (bool)
    {
        return DaoHelper.getFlag(members[memberAddress].flags, uint8(flag));
    }

    /**
     * @notice Returns the number of members in the registry.
     */
    function getNbMembers() external view returns (uint256) {
        return _members.length;
    }

    /**
     * @notice Returns the member address for the given index.
     */
    function getMemberAddress(uint256 index) external view returns (address) {
        return _members[index];
    }

    /**
     * DELEGATE
     */

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(address memberAddr, address newDelegateKey)
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        require(newDelegateKey != address(0x0), 'newDelegateKey cannot be 0');

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            require(
                // newDelegate must not be delegated to
                memberAddressesByDelegatedKey[newDelegateKey] == address(0x0),
                'cannot overwrite existing delegated keys'
            );
        } else {
            require(
                memberAddressesByDelegatedKey[memberAddr] == address(0x0),
                'address already taken as delegated key'
            );
        }

        Member storage member = members[memberAddr];
        require(
            DaoHelper.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }

    /**
     * @param checkAddr The address to check for a delegate
     * @return the delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(address checkAddr)
        external
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? _checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(address memberAddr)
        external
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? _checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The delegate key of the member
     */
    function getPriorDelegateKey(address memberAddr, uint256 blockNumber)
        external
        view
        returns (address)
    {
        require(blockNumber < block.number, 'getPriorDelegateKey: NYD');

        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            _checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return _checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (_checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = _checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) internal {
        uint32 nCheckpoints = _numCheckpoints[member];
        // The only condition that we should allow the deletegaKey upgrade
        // is when the block.number exactly matches the fromBlock value.
        // Anything different from that should generate a new checkpoint.
        if (
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            _checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        ) {
            _checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } else {
            _checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            _numCheckpoints[member] = nCheckpoints + 1;
        }
    }
}

pragma solidity ^0.8.0;
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IExtension {
    function initialize(DaoRegistry dao, address creator) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./Bank.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract BankFactory is IFactory, CloneFactory, ReentrancyGuard {
    address public identityAddress;

    event BankCreated(address daoAddress, address extensionAddress);

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "invalid addr");
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates a new extension using clone factory.
     * @notice It can set additional arguments to the extension.
     * @notice It initializes the extension and sets the DAO owner as the extension creator.
     * @notice The DAO owner is stored at index 1 in the members storage.
     * @notice The safest way to read the new extension address is to read it from the event.
     * @param dao The dao address that will be associated with the new extension.
     * @param maxExternalTokens The maximum number of external tokens stored in the Bank
     */
    // slither-disable-next-line reentrancy-events
    function create(DaoRegistry dao, uint8 maxExternalTokens)
        external
        nonReentrant
    {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "invalid dao addr");
        address extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        BankExtension extension = BankExtension(extensionAddr);
        extension.setMaxExternalTokens(maxExternalTokens);
        // Member at index 1 is the DAO owner, but also the payer of the DAO deployment
        extension.initialize(dao, dao.getMemberAddress(1));
        // slither-disable-next-line reentrancy-events
        emit BankCreated(daoAddress, address(extension));
    }

    /**
     * @notice Returns the extension address created for that DAO, or 0x0... if it does not exist.
     * @notice Do not rely on the result returned by this right after the new extension is cloned,
     * because it is prone to front-running attacks. During the extension creation it is safer to
     * read the new extension address from the event generated in the create call transaction.
     */
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./Executor.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract ExecutorExtensionFactory is IFactory, CloneFactory, ReentrancyGuard {
    address public identityAddress;

    event ExecutorCreated(address daoAddress, address extensionAddress);

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "invalid addr");
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates a new extension using clone factory.
     * @notice It can set additional arguments to the extension.
     * @notice It initializes the extension and sets the DAO owner as the extension creator.
     * @notice The safest way to read the new extension address is to read it from the event.
     * @param dao The dao address that will be associated with the new extension.
     */
    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        ExecutorExtension extension = ExecutorExtension(extensionAddr);
        extension.initialize(dao, address(0));
        // slither-disable-next-line reentrancy-events
        emit ExecutorCreated(daoAddress, address(extension));
    }

    /**
     * @notice Returns the extension address created for that DAO, or 0x0... if it does not exist.
     * @notice Do not rely on the result returned by this right after the new extension is cloned,
     * because it is prone to front-running attacks. During the extension creation it is safer to
     * read the new extension address from the event generated in the create call transaction.
     */
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../../core/DaoRegistry.sol";
import "../../../core/CloneFactory.sol";
import "../../IFactory.sol";
import "./ERC20TokenExtension.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract ERC20TokenExtensionFactory is IFactory, CloneFactory, ReentrancyGuard {
    address public identityAddress;

    event ERC20TokenExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "invalid addr");
        identityAddress = _identityAddress;
    }

    /**
     * @notice Creates a new extension using clone factory.
     * @notice It can set additional arguments to the extension.
     * @notice It initializes the extension and sets the DAO owner as the extension creator.
     * @notice The safest way to read the new extension address is to read it from the event.
     * @param dao The dao address that will be associated with the new extension.
     * @param tokenName The name of the token.
     * @param tokenAddress The address of the ERC20 token.
     * @param tokenSymbol The symbol of the ERC20 token.
     * @param decimals The number of decimal places of the ERC20 token.
     */
    // slither-disable-next-line reentrancy-events
    function create(
        DaoRegistry dao,
        string calldata tokenName,
        address tokenAddress,
        string calldata tokenSymbol,
        uint8 decimals
    ) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        ERC20Extension extension = ERC20Extension(extensionAddr);
        extension.setName(tokenName);
        extension.setToken(tokenAddress);
        extension.setSymbol(tokenSymbol);
        extension.setDecimals(decimals);
        extension.initialize(dao, address(0));
        // slither-disable-next-line reentrancy-events
        emit ERC20TokenExtensionCreated(daoAddress, address(extension));
    }

    /**
     * @notice Returns the extension address created for that DAO, or 0x0... if it does not exist.
     * @notice Do not rely on the result returned by this right after the new extension is cloned,
     * because it is prone to front-running attacks. During the extension creation it is safer to
     * read the new extension address from the event generated in the create call transaction.
     */
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./MemberExtension.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract MemberExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event MemberExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "memberExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "memberExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        MemberExtension extension = MemberExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));
        emit MemberExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./DynamicEquityExtension.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DynamicEquityExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event DynamicEquityExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "dynamicEquityExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "dynamicEquityExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        DynamicEquityExtension extension = DynamicEquityExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));
        emit DynamicEquityExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./VestedEquityExtension.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract VestedEquityExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event VestedEquityExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "vestedEquityExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "vestedEquityExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        VestedEquityExtension extension = VestedEquityExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));
        emit VestedEquityExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./CommunityIncentiveExtension.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract CommunityIncentiveExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event CommunityIncentiveExtensionCreated(
        address daoAddress,
        address extensionAddress
    );

    mapping(address => address) private _extensions;

    constructor(address _identityAddress) {
        require(_identityAddress != address(0x0), "communityIncentiveExtFactory::invalid addr");
        identityAddress = _identityAddress;
    }

    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "communityIncentiveExtFactory::invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        CommunityIncentiveExtension extension = CommunityIncentiveExtension(
            extensionAddr
        );

        extension.initialize(dao, address(0));
        emit CommunityIncentiveExtensionCreated(
            daoAddress,
            address(extension)
        );
    }
    
    function getExtensionAddress(address dao)
        external
        view
        override
        returns (address)
    {
        return _extensions[dao];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import '../core/DaoRegistry.sol';
import '../extensions/bank/Bank.sol';
import '../guards/AdapterGuard.sol';
import './modifiers/Reimbursable.sol';
import '../utils/Signatures.sol';
import '../helpers/DaoHelper.sol';

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract Manager is Reimbursable, AdapterGuard, Signatures {
    enum UpdateType {
        UNKNOWN,
        ADAPTER,
        EXTENSION,
        CONFIGS
    }

    enum ConfigType {
        NUMERIC,
        ADDRESS
    }

    struct Configuration {
        bytes32 key;
        uint256 numericValue;
        address addressValue;
        ConfigType configType;
    }

    struct ProposalDetails {
        bytes32 adapterOrExtensionId;
        address adapterOrExtensionAddr;
        UpdateType updateType;
        uint128 flags;
        bytes32[] keys;
        uint256[] values;
        address[] extensionAddresses;
        uint128[] extensionAclFlags;
    }

    struct ManagingCoupon {
        address daoAddress;
        ProposalDetails proposal;
        Configuration[] configs;
        uint256 nonce;
    }

    mapping(address => uint256) public nonces;

    string public constant MANAGING_COUPON_MESSAGE_TYPE =
        'Message(address daoAddress,ProposalDetails proposal,Configuration[] configs,uint256 nonce)Configuration(bytes32 key,uint256 numericValue,address addressValue,uint8 configType)ProposalDetails(bytes32 adapterOrExtensionId,address adapterOrExtensionAddr,uint8 updateType,uint128 flags,bytes32[] keys,uint256[] values,address[] extensionAddresses,uint128[] extensionAclFlags)';
    bytes32 public constant MANAGING_COUPON_MESSAGE_TYPEHASH =
        keccak256(abi.encodePacked(MANAGING_COUPON_MESSAGE_TYPE));

    string public constant PROPOSAL_DETAILS_TYPE =
        'ProposalDetails(bytes32 adapterOrExtensionId,address adapterOrExtensionAddr,uint8 updateType,uint128 flags,bytes32[] keys,uint256[] values,address[] extensionAddresses,uint128[] extensionAclFlags)';
    bytes32 public constant PROPOSAL_DETAILS_TYPEHASH =
        keccak256(abi.encodePacked(PROPOSAL_DETAILS_TYPE));

    string public constant CONFIGURATION_DETAILS_TYPE =
        'Configuration(bytes32 key,uint256 numericValue,address addressValue,uint8 configType)';
    bytes32 public constant CONFIGURATION_DETAILS_TYPEHASH =
        keccak256(abi.encodePacked(CONFIGURATION_DETAILS_TYPE));

    bytes32 public constant SignerAddressConfig =
        keccak256('Manager.signerAddress');

    /**
     * @notice Configures the Adapter with the managing signer address.
     * @param signerAddress the address of the managing signer
     */
    function configureDao(DaoRegistry dao, address signerAddress)
        external
        onlyAdapter(dao)
    {
        dao.setAddressConfiguration(SignerAddressConfig, signerAddress);
    }

    function processSignedProposal(
        DaoRegistry dao,
        ProposalDetails calldata proposal,
        Configuration[] memory configs,
        uint256 nonce,
        bytes memory signature
    ) external {
        require(
            proposal.keys.length == proposal.values.length,
            'must be an equal number of config keys and values'
        );
        require(
            DaoHelper.isNotReservedAddress(proposal.adapterOrExtensionAddr),
            'address is reserved'
        );
        require(nonce > nonces[address(dao)], 'coupon already redeemed');
        nonces[address(dao)] = nonce;

        ManagingCoupon memory managingCoupon = ManagingCoupon(
            address(dao),
            proposal,
            configs,
            nonce
        );
        bytes32 hash = hashCouponMessage(dao, managingCoupon);

        require(
            SignatureChecker.isValidSignatureNow(
                dao.getAddressConfiguration(SignerAddressConfig),
                hash,
                signature
            ),
            'invalid sig'
        );

        _submitAndProcessProposal(dao, proposal, configs);
    }

    /**
     * @notice Submits and processes a proposal that was signed by the managing address.
     * @dev Reverts when the adapter address is already in use and it is an adapter addition.
     * @dev Reverts when the extension address is already in use and it is an extension addition.
     * @param dao The dao address.
     * @param proposal The proposal data.
     * @param configs The configurations to be updated.
     */
    // slither-disable-next-line reentrancy-benign
    function _submitAndProcessProposal(
        DaoRegistry dao,
        ProposalDetails calldata proposal,
        Configuration[] memory configs
    ) internal reimbursable(dao) {
        if (proposal.updateType == UpdateType.ADAPTER) {
            dao.replaceAdapter(
                proposal.adapterOrExtensionId,
                proposal.adapterOrExtensionAddr,
                proposal.flags,
                proposal.keys,
                proposal.values
            );

            // Grant new adapter access to extensions.
            for (uint256 i = 0; i < proposal.extensionAclFlags.length; i++) {
                _grantExtensionAccess(
                    dao,
                    proposal.extensionAddresses[i],
                    proposal.adapterOrExtensionAddr,
                    proposal.extensionAclFlags[i]
                );
            }
        } else if (proposal.updateType == UpdateType.EXTENSION) {
            _replaceExtension(dao, proposal);

            // Grant adapters access to new extension.
            for (uint256 i = 0; i < proposal.extensionAclFlags.length; i++) {
                _grantExtensionAccess(
                    dao,
                    proposal.adapterOrExtensionAddr,
                    proposal.extensionAddresses[i], // Adapters.
                    proposal.extensionAclFlags[i]
                );
            }
        } else if (proposal.updateType == UpdateType.CONFIGS) {
            for (uint256 i = 0; i < proposal.extensionAclFlags.length; i++) {
                _grantExtensionAccess(
                    dao,
                    proposal.extensionAddresses[i],
                    proposal.adapterOrExtensionAddr,
                    proposal.extensionAclFlags[i]
                );
            }
        } else {
            revert('unknown update type');
        }
        _saveDaoConfigurations(dao, configs);
    }

    /**
     * @notice If the extension is already registered, it removes the extension from the DAO Registry.
     * @notice If the adapterOrExtensionAddr is provided, the new address is added as a new extension to the DAO Registry.
     */
    function _replaceExtension(DaoRegistry dao, ProposalDetails memory proposal)
        internal
    {
        if (dao.extensions(proposal.adapterOrExtensionId) != address(0x0)) {
            dao.removeExtension(proposal.adapterOrExtensionId);
        }

        if (proposal.adapterOrExtensionAddr != address(0x0)) {
            try
                dao.addExtension(
                    proposal.adapterOrExtensionId,
                    IExtension(proposal.adapterOrExtensionAddr)
                )
            {} catch {
                // v1.0.6 signature
                dao.addExtension(
                    proposal.adapterOrExtensionId,
                    IExtension(proposal.adapterOrExtensionAddr),
                    // The creator of the extension must be set as the DAO owner,
                    // which is stored at index 0 in the members storage.
                    dao.getMemberAddress(0)
                );
            }
        }
    }

    /**
     * @notice Saves to the DAO Registry the ACL Flag that grants the access to the given `extensionAddresses`
     */
    function _grantExtensionAccess(
        DaoRegistry dao,
        address extensionAddr,
        address adapterAddr,
        uint128 acl
    ) internal {
        // It is fine to execute the external call inside the loop
        // because it is calling the correct function in the dao contract
        // it won't be calling a fallback that always revert.
        // slither-disable-next-line calls-loop
        dao.setAclToExtensionForAdapter(
            // It needs to be registered as extension
            extensionAddr,
            // It needs to be registered as adapter
            adapterAddr,
            // Indicate which access level will be granted
            acl
        );
    }

    /**
     * @notice Saves the numeric/address configurations to the DAO registry
     */
    function _saveDaoConfigurations(
        DaoRegistry dao,
        Configuration[] memory configs
    ) internal {
        for (uint256 i = 0; i < configs.length; i++) {
            Configuration memory config = configs[i];
            if (ConfigType.NUMERIC == config.configType) {
                // It is fine to execute the external call inside the loop
                // because it is calling the correct function in the dao contract
                // it won't be calling a fallback that always revert.
                // slither-disable-next-line calls-loop
                dao.setConfiguration(config.key, config.numericValue);
            } else if (ConfigType.ADDRESS == config.configType) {
                // It is fine to execute the external call inside the loop
                // because it is calling the correct function in the dao contract
                // it won't be calling a fallback that always revert.
                // slither-disable-next-line calls-loop
                dao.setAddressConfiguration(config.key, config.addressValue);
            }
        }
    }

    /**
     * @notice Hashes the provided coupon as an ERC712 hash.
     * @param dao is the DAO instance to be configured
     * @param coupon is the coupon to hash
     */
    function hashCouponMessage(DaoRegistry dao, ManagingCoupon memory coupon)
        public
        view
        returns (bytes32)
    {
        bytes32 message = keccak256(
            abi.encode(
                MANAGING_COUPON_MESSAGE_TYPEHASH,
                coupon.daoAddress,
                hashProposal(coupon.proposal),
                hashConfigurations(coupon.configs),
                coupon.nonce
            )
        );

        return hashMessage(dao, address(this), message);
    }

    function hashProposal(ProposalDetails memory proposal)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    PROPOSAL_DETAILS_TYPEHASH,
                    proposal.adapterOrExtensionId,
                    proposal.adapterOrExtensionAddr,
                    proposal.updateType,
                    proposal.flags,
                    keccak256(abi.encodePacked(proposal.keys)),
                    keccak256(abi.encodePacked(proposal.values)),
                    keccak256(abi.encodePacked(proposal.extensionAddresses)),
                    keccak256(abi.encodePacked(proposal.extensionAclFlags))
                )
            );
    }

    function hashConfigurations(Configuration[] memory configs)
        public
        pure
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](configs.length);
        for (uint256 i = 0; i < configs.length; i++) {
            result[i] = keccak256(
                abi.encode(
                    CONFIGURATION_DETAILS_TYPEHASH,
                    configs[i].key,
                    configs[i].numericValue,
                    configs[i].addressValue,
                    configs[i].configType
                )
            );
        }

        return keccak256(abi.encodePacked(result));
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/bank/Bank.sol";
import "../../guards/MemberGuard.sol";
import "../../guards/AdapterGuard.sol";
import "./interfaces/IVotingAdapter.sol";
import "../modifiers/Reimbursable.sol";
import "../../helpers/DaoHelper.sol";
import "../../helpers/GovernanceHelper.sol";

contract VotingAdapter is IVotingAdapter, MemberGuard, AdapterGuard, Reimbursable {

    bytes32 constant VotingType = keccak256("voting.votingType");
    bytes32 constant VotingPeriod = keccak256("voting.votingPeriod");
    bytes32 constant GracePeriod = keccak256("voting.gracePeriod");
    bytes32 constant DisputePeriod = keccak256("voting.disputePeriod");
    bytes32 constant PassRateMember = keccak256("voting.passRateMember");
    bytes32 constant PassRateToken = keccak256("voting.passRateToken");
    bytes32 constant SupportRequired = keccak256("voting.supportRequired");
    string public constant ADAPTER_NAME = "VotingAdapter";

    struct Voting {
        uint256 nbYes;
        uint256 nbNo;
        uint256 nbMembers;
        uint256 nbTokens;
        uint256 startingTime;
        uint256 graceStartingTime;
        uint256 disputeStartingTime;
        uint256 blockNumber;
        Foundance.VotingType votingType;
        mapping(address => uint256) votes;
    }
    mapping(address => Foundance.VotingConfig) public config;

    mapping(address => mapping(bytes32 => Voting)) public votes;

    //EVENT
    event SubmitVoteEvent(address _address);//TODO
    event StartNewVotingForProposalEvent(address _address);//TODO
  
    function getAdapterName() external pure override returns (string memory) {
        return ADAPTER_NAME;
    }

    function configureDao(
        DaoRegistry dao,
        Foundance.VotingConfig memory _votingConfig
    ) external onlyAdapter(dao) {
        config[address(dao)] = _votingConfig;
        if(_votingConfig.passRateToken>100){
            _votingConfig.passRateToken=100;
        }
        if(_votingConfig.supportRequired>100){
            _votingConfig.supportRequired=100;
        }
        dao.setConfiguration(VotingPeriod, _votingConfig.votingPeriod);
        dao.setConfiguration(GracePeriod, _votingConfig.gracePeriod);
        dao.setConfiguration(DisputePeriod, _votingConfig.disputePeriod);
        dao.setConfiguration(PassRateMember, _votingConfig.passRateMember);
        dao.setConfiguration(PassRateToken, _votingConfig.passRateToken);
        dao.setConfiguration(SupportRequired, _votingConfig.supportRequired);
    }

    function getSenderAddress(
        DaoRegistry,
        address,
        bytes memory,
        address sender
    ) external pure override returns (address) {
        return sender;
    }

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata
    ) external override onlyAdapter(dao) {
        Voting storage vote = votes[address(dao)][proposalId];
        vote.startingTime = block.timestamp;
        vote.blockNumber = block.number;
        vote.votingType = config[address(dao)].votingType;
        emit StartNewVotingForProposalEvent(msg.sender);
    }

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata,
        Foundance.VotingType _votingType
    ) external onlyAdapter(dao) {
        Voting storage vote = votes[address(dao)][proposalId];
        vote.startingTime = block.timestamp;
        vote.blockNumber = block.number;
        vote.votingType = _votingType;
        emit StartNewVotingForProposalEvent(msg.sender);
    }

    function submitVote(
        DaoRegistry dao,
        bytes32 proposalId,
        uint256 voteValue,
        uint256 weightedVoteValue
    ) external onlyMember(dao) reimbursable(dao) {
        require(
            dao.getProposalFlag(proposalId, DaoRegistry.ProposalFlag.SPONSORED),
            "the proposal has not been sponsored yet"
        );
        require(
            !dao.getProposalFlag(
                proposalId,
                DaoRegistry.ProposalFlag.PROCESSED
            ),
            "the proposal has already been processed"
        );
        require(
            voteValue < 3 && voteValue > 0,
            "only yes (1) and no (2) are possible values"
        );
        Voting storage vote = votes[address(dao)][proposalId];
        require(
            vote.startingTime > 0,
            "this proposalId has no vote going on at the moment"
        );
        require(
            block.timestamp <
                vote.startingTime + dao.getConfiguration(VotingPeriod),
            "vote has already ended"
        );
        address memberAddr = DaoHelper.msgSender(dao, msg.sender);
        require(vote.votes[memberAddr] == 0, "member has already voted");
        uint256 tokenAmount = GovernanceHelper.getVotingWeight(
            dao,
            memberAddr,
            proposalId,
            vote.blockNumber
        );
        uint256 votingWeight = 0;
        if (tokenAmount == 0) revert("vote not allowed");
        vote.nbMembers += 1;
        vote.nbTokens += tokenAmount;
        vote.votes[memberAddr] = voteValue;
        if(vote.votingType == Foundance.VotingType.LINEAR){
            votingWeight = tokenAmount; 
        }else if(vote.votingType == Foundance.VotingType.QUADRATIC){
            votingWeight = DaoHelper.sqrt(tokenAmount);
        }else if(vote.votingType == Foundance.VotingType.OPTIMISTIC){
            votingWeight = tokenAmount; 
        }else if(vote.votingType == Foundance.VotingType.COOPERATIVE){
            votingWeight = 1;
        }
        if(vote.votingType == Foundance.VotingType.WEIGHTED){
            votingWeight = tokenAmount; 
            weightedVoteValue = weightedVoteValue>100?100:weightedVoteValue;
            uint256 weightedVotingWeight = (votingWeight*weightedVoteValue)/100;
            uint256 weightedVotingMinorityWeight = votingWeight-weightedVotingWeight;
            if(voteValue == 1){
                vote.nbYes = vote.nbYes + weightedVotingWeight;
                vote.nbNo = vote.nbNo + weightedVotingMinorityWeight;
            }else{
                vote.nbYes = vote.nbYes + weightedVotingMinorityWeight;
                vote.nbNo = vote.nbNo + weightedVotingWeight;
            }
        } else if (voteValue == 1) {
            vote.nbYes = vote.nbYes + votingWeight;
        } else if (voteValue == 2) {
            vote.nbNo = vote.nbNo + votingWeight;
        }
        emit SubmitVoteEvent(msg.sender);
    }

    function voteResult(DaoRegistry dao, bytes32 proposalId)
        external
        view
        override
        returns (VotingState state)
    {
        Voting storage vote = votes[address(dao)][proposalId];
        Foundance.VotingConfig memory votingConfig = config[address(dao)];
        if (vote.startingTime == 0) {
            return VotingState.NOT_STARTED;
        }
        if (
            block.timestamp <
            vote.startingTime + dao.getConfiguration(VotingPeriod)
        ) {
            return VotingState.IN_PROGRESS;
        }
        if (
            block.timestamp <
            vote.startingTime +
                dao.getConfiguration(VotingPeriod) +
                dao.getConfiguration(GracePeriod)
        ) {
            return VotingState.GRACE_PERIOD;
        }
        if(vote.votingType == Foundance.VotingType.OPTIMISTIC){
            if (vote.nbYes >= vote.nbNo) {
                return VotingState.PASS;
            } else if (vote.nbYes < vote.nbNo) {
                return VotingState.NOT_PASS;
            }
            return VotingState.PASS;
        }else{
            BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
            uint256 totalUnitTokens = DaoHelper.totalUnitTokens(bank);
            if( 
                votingConfig.passRateMember < vote.nbMembers || 
                (votingConfig.passRateToken*totalUnitTokens)/100  < vote.nbTokens || 
                (votingConfig.supportRequired*totalUnitTokens)/100 < vote.nbTokens   
            ) {
                return VotingState.NOT_PASS;
            }
            if (vote.nbYes > vote.nbNo) {
                return VotingState.PASS;
            } else if (vote.nbYes < vote.nbNo) {
                return VotingState.NOT_PASS;
            } else {
                return VotingState.TIE;
            }
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/bank/Bank.sol";
import "../../extensions/foundance/MemberExtension.sol";
import "../../extensions/foundance/DynamicEquityExtension.sol";
import "../../extensions/foundance/VestedEquityExtension.sol";
import "../../extensions/foundance/CommunityIncentiveExtension.sol";
import {LVoting} from "./libraries/LVoting.sol";
import "../../helpers/DaoHelper.sol";
import "./../modifiers/Reimbursable.sol";
import "./interfaces/IMemberAdapter.sol";
import "./interfaces/IVotingAdapter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MemberAdapter is IMemberAdapter, Reimbursable, AdapterGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    struct MemberProposal {
        Foundance.ProposalStatus status;
        Foundance.MemberConfig memberConfig;
    }

    struct MemberRemoveProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }

    struct MemberSetupProposal {
        Foundance.ProposalStatus status;
        Foundance.MemberConfig memberConfig;
        Foundance.DynamicEquityMemberConfig dynamicEquityMemberConfig;
        Foundance.VestedEquityMemberConfig vestedEquityMemberConfig;
        Foundance.CommunityIncentiveMemberConfig communityIncentiveMemberConfig;
    }


    mapping(address => mapping(bytes32 => MemberProposal)) public setMemberProposal;

    mapping(address => mapping(bytes32 => MemberSetupProposal)) public setMemberSetupProposal;

    mapping(address => mapping(bytes32 => MemberRemoveProposal)) public removeMemberProposal;

    mapping(address => mapping(bytes32 => MemberRemoveProposal)) public removeMemberBadLeaverProposal;

    mapping(address => mapping(bytes32 => MemberRemoveProposal)) public removeMemberResigneeProposal;

    //EVENT
    event SubmitSetMemberProposalEvent(
        address _daoAddress, address _addressSender, bytes _data, bytes32 proposalId, Foundance.MemberConfig _memberConfig);
        
    event SubmitSetMemberSetupProposalEvent(
        address _daoAddress, address _addressSender, bytes _data, bytes32 proposalId, Foundance.MemberConfig _memberConfig,
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig, 
        Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig, 
        Foundance.CommunityIncentiveMemberConfig _communityIncentiveMemberConfig);
        
    event SubmitRemoveMemberProposalEvent(
        address _daoAddress, address _addressSender, bytes _data, bytes32 proposalId, address _addressMember);
        
    event SubmitRemoveMemberBadLeaverProposalEvent(
        address _daoAddress, address _addressSender, bytes _data, bytes32 proposalId, address _addressMember);
        
    event SubmitRemoveMemberResigneeProposalEvent(
        address _daoAddress, address _addressSender, bytes _data, bytes32 proposalId, address _addressMember);

    event ProcessSetMemberProposalEvent(
        address _daoAddress, address _addressSender, bytes32 proposalId, Foundance.MemberConfig _memberConfig);

    event ProcessSetMemberSetupProposalEvent(
        address _daoAddress, address _addressSender, bytes32 proposalId, Foundance.MemberConfig _memberConfig,
        Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig, 
        Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig, 
        Foundance.CommunityIncentiveMemberConfig _communityIncentiveMemberConfig);

    event ProcessRemoveMemberProposalEvent(
        address _daoAddress, address _addressSender, bytes32 proposalId, address _addressMember, bytes _data, bytes32 _newProposalId);

    event ProcessRemoveMemberBadLeaverProposalEvent(
        address _daoAddress, address _addressSender, bytes32 proposalId, address _addressMember, bool goodLeaver);

    event ProcessRemoveMemberResigneeProposalEvent(
        address _daoAddress, address _addressSender, bytes32 proposalId, address _addressMember, bool goodLeaver);

    event ActMemberResignEvent(
        address _daoAddress, address _addressSender, bytes _data, address _addressMember);

    event SetMemberEvent(
        address _daoAddress, Foundance.MemberConfig _memberConfig);

    event RemoveMemberEvent(
        address _daoAddress, address _addressSender);

    //SUBMIT_INTERNAL
    function _submitRemoveMemberBadLeaverProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) internal {
        removeMemberBadLeaverProposal[address(dao)][proposalId] = MemberRemoveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data, Foundance.VotingType.OPTIMISTIC);
        emit SubmitRemoveMemberBadLeaverProposalEvent(address(dao),msg.sender, data, proposalId, _memberAddress);
    }

    function _submitRemoveMemberResigneeProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) internal {
        removeMemberResigneeProposal[address(dao)][proposalId] = MemberRemoveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data, Foundance.VotingType.OPTIMISTIC);
        emit SubmitRemoveMemberResigneeProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //SUBMIT
    function submitSetMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        Foundance.MemberConfig memory _memberConfig
    ) external override reimbursable(dao) {
        require(
            DaoHelper.isNotReservedAddress(_memberConfig.memberAddress),
            "MemberAdpt::applicant is reserved address"
        );
        setMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberConfig
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberConfig);
    }

    function submitSetMemberSetupProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        Foundance.MemberConfig memory _memberConfig,
        Foundance.DynamicEquityMemberConfig memory _dynamicEquityMemberConfig,
        Foundance.VestedEquityMemberConfig memory _vestedEquityMemberConfig,
        Foundance.CommunityIncentiveMemberConfig memory _communityIncentiveMemberConfig
    ) external override reimbursable(dao) {
        require(
            DaoHelper.isNotReservedAddress(_memberConfig.memberAddress),
            "MemberAdpt::applicant is reserved address"
        );
        setMemberSetupProposal[address(dao)][proposalId] = MemberSetupProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberConfig,
            _dynamicEquityMemberConfig,
            _vestedEquityMemberConfig,
            _communityIncentiveMemberConfig
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetMemberSetupProposalEvent(
            address(dao), msg.sender, data, proposalId, _memberConfig, _dynamicEquityMemberConfig, _vestedEquityMemberConfig, _communityIncentiveMemberConfig);
    }

    function submitRemoveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) external override reimbursable(dao) {
        require(dao.isMember(_memberAddress), "_memberAddress not a member");
        removeMemberProposal[address(dao)][proposalId] = MemberRemoveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitRemoveMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //PROCESS_INTERNAL
    function _processSetMember(
        DaoRegistry dao,
        Foundance.MemberConfig memory _memberConfig
    ) internal {
        MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoHelper.MEMBER_EXT));
        member.setMember(
            dao,
            _memberConfig
        );
        emit SetMemberEvent(address(dao), _memberConfig);    
    }

    function _processSetMemberSetup(
        DaoRegistry dao,
        MemberSetupProposal memory _proposal
    ) internal {
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoHelper.VESTED_EQUITY_EXT));
        vestedEquity.setVestedEquityMember(
            dao,
            _proposal.vestedEquityMemberConfig
        );
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT));
        dynamicEquity.setDynamicEquityMember(
            dao,
            _proposal.dynamicEquityMemberConfig
        );
        CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT));
        communityIncentive.setCommunityIncentiveMember(
            dao,
            _proposal.communityIncentiveMemberConfig
        );
    }

    function _processRemoveMember(
        DaoRegistry dao,
        address _memberAddress
    ) internal {
        dao.jailMember(_memberAddress);
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT));
        dynamicEquity.removeDynamicEquityMember(
            dao,
            _memberAddress
        );
        CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT));
        communityIncentive.removeCommunityIncentiveMember(
            dao,
            _memberAddress
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoHelper.VESTED_EQUITY_EXT));
        vestedEquity.removeVestedEquityMember(
            dao,
            _memberAddress
        );
        emit RemoveMemberEvent(address(dao), _memberAddress);  
    }

    function _processRemoveMemberAppreciationRight(
        DaoRegistry dao,
        address _memberAddress
    ) internal view {
        MemberExtension member = MemberExtension(dao.getExtensionAddress(DaoHelper.MEMBER_EXT));
        member.removeMember(
            dao,
            _memberAddress
        );
    }

    function _processRemoveMemberToken(
        DaoRegistry dao,
        address _memberAddress
    ) internal {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        uint256 unitsToBurn = bank.balanceOf(_memberAddress, DaoHelper.UNITS);
        bank.subtractFromBalance(dao, _memberAddress, DaoHelper.UNITS, unitsToBurn);
    }

    //PROCESS
    function processSetMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = setMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = LVoting._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            _processSetMember(dao, proposal.memberConfig);
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberConfig);
        }
    }

    function processSetMemberSetupProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberSetupProposal storage proposal = setMemberSetupProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = LVoting._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            _processSetMember(dao, proposal.memberConfig);
            _processSetMemberSetup(dao, proposal);
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetMemberSetupProposalEvent(
                address(dao), msg.sender, proposalId, proposal.memberConfig, proposal.dynamicEquityMemberConfig, proposal.vestedEquityMemberConfig, proposal.communityIncentiveMemberConfig);
        }
    }

    function processRemoveMemberProposal(DaoRegistry dao, bytes32 proposalId, bytes calldata data, bytes32 newProposalId)
        external
        override
        reimbursable(dao)
    {
        MemberRemoveProposal storage proposal = removeMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = LVoting._processProposal(dao, proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            _processRemoveMember(dao,proposal.memberAddress);
            _submitRemoveMemberBadLeaverProposal(dao, newProposalId, data, proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessRemoveMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress, data, newProposalId);
    }

    function processRemoveMemberBadLeaverProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberRemoveProposal storage proposal = removeMemberBadLeaverProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = LVoting._processProposal(dao, proposalId);
        bool goodLeaver = false;
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            goodLeaver = true;
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        } else if (proposal.status == Foundance.ProposalStatus.FAILED){
            _processRemoveMemberToken(dao,proposal.memberAddress);
            _processRemoveMemberAppreciationRight(dao,proposal.memberAddress);
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessRemoveMemberBadLeaverProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress, goodLeaver);
    }

     function processRemoveMemberResigneeProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberRemoveProposal storage proposal = removeMemberResigneeProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "memberAdpt::proposal already completed or in progress"
        );  
        proposal.status = LVoting._processProposal(dao, proposalId);
        bool goodLeaver = false;
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            goodLeaver = true;
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        } else if (proposal.status == Foundance.ProposalStatus.FAILED){
            _processRemoveMemberAppreciationRight(dao,proposal.memberAddress);
            dao.unjailMember(proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
        emit ProcessRemoveMemberResigneeProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress, goodLeaver);
    }

    //ACT
    function actMemberResign(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        address _memberAddress
    ) external override reimbursable(dao) {
        require(
            _memberAddress == msg.sender,
            "memberAdpt::_memberAddress==msg.sender required"
        );
        require(
            dao.isMember(_memberAddress),
            "memberAdpt::_memberAddress not a member"
        );
        _processRemoveMember(dao, _memberAddress);
        MemberExtension member = MemberExtension(
            dao.getExtensionAddress(DaoHelper.MEMBER_EXT)
        );
        Foundance.MemberConfig memory memberConfig = member.getMemberConfig(_memberAddress);
        if(memberConfig.initialPeriod<block.timestamp){
            _submitRemoveMemberResigneeProposal(dao,proposalId, data, _memberAddress);
        }else{
            _submitRemoveMemberBadLeaverProposal(dao,proposalId, data, _memberAddress);
        }
        emit ActMemberResignEvent(address(dao), msg.sender, data, _memberAddress);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/bank/Bank.sol";
import "../../extensions/foundance/DynamicEquityExtension.sol";
import "../../guards/AdapterGuard.sol";
import "./../modifiers/Reimbursable.sol";
import "./interfaces/IVotingAdapter.sol";
import "./interfaces/IDynamicEquity.sol";
import "./libraries/LVoting.sol";
import "../../helpers/FairShareHelper.sol";
import "../../helpers/DaoHelper.sol";



contract DynamicEquityAdapter is IDynamicEquity, AdapterGuard, Reimbursable {

    struct DynamicEquityProposal {
        Foundance.ProposalStatus status;
        Foundance.DynamicEquityConfig dynamicEquityConfig;
        Foundance.EpochConfig epochConfig;
    }

    struct DynamicEquityMemberProposal {
        Foundance.ProposalStatus status;
        Foundance.DynamicEquityMemberConfig dynamicEquityMemberConfig;
    }

    struct DynamicEquityEpochProposal {
        Foundance.ProposalStatus status;
        uint256 lastEpoch; 
    }

    struct MemberProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }
    
     struct MemberValueProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
        uint256 value; 
    }

    mapping(address => mapping(bytes32 => DynamicEquityProposal)) public setDynamicEquityProposal;

    mapping(address => mapping(bytes32 => DynamicEquityEpochProposal)) public setDynamicEquityEpochProposal;

    mapping(address => mapping(bytes32 => DynamicEquityMemberProposal)) public setDynamicEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberValueProposal)) public setDynamicEquityMemberSuspendProposal;

    mapping(address => mapping(bytes32 => DynamicEquityMemberProposal)) public setDynamicEquityMemberEpochProposal;

    mapping(address => mapping(bytes32 => MemberValueProposal)) public setDynamicEquityMemberEpochExpenseProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeDynamicEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeDynamicEquityMemberEpochProposal;

    //EVENT
    event SubmitSetDynamicEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, Foundance.DynamicEquityConfig _dynamicEquityConfig, Foundance.EpochConfig _epochConfig);

    event SubmitSetDynamicEquityEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, uint _unixTimestampInS);

    event SubmitSetDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig);

    event SubmitSetDynamicEquityMemberSuspendProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, address _memberAddress, uint256 _suspendUntil);

    event SubmitSetDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig);

    event SubmitSetDynamicEquityMemberEpochExpenseProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, address _memberAddress, uint256 _expenseAmount);

    event SubmitRemoveDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, address _memberAddress);

    event SubmitRemoveDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, address _memberAddress);
  
    event ProcessSetDynamicEquityProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, Foundance.DynamicEquityConfig _dynamicEquityConfig, Foundance.EpochConfig _epochConfig);

    event ProcessSetDynamicEquityEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, uint _unixTimestampInS);

    event ProcessSetDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig);

    event ProcessSetDynamicEquityMemberSuspendProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, address _memberAddress, uint256 _suspendUntil);

    event ProcessSetDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, Foundance.DynamicEquityMemberConfig _dynamicEquityMemberConfig);

    event ProcessSetDynamicEquityMemberEpochExpenseProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, address _memberAddress, uint256 _expenseAmount);

    event ProcessRemoveDynamicEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, address _memberAddress);

    event ProcessRemoveDynamicEquityMemberEpochProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, address _memberAddress);

    event ActDynamicEquityMemberEpochDistributedEvent(
        address _daoAddress, address _senderAddress, address _memberAddress, address _tokenAddress, uint256 _tokenAmount);

    event ActDynamicEquityEpochDistributedEvent(
        address _daoAddress, address _senderAddress, uint256 _distributionEpoch);

    //SUBMIT
    function submitSetDynamicEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityConfig calldata _dynamicEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external override reimbursable(dao) {
        setDynamicEquityProposal[address(dao)][proposalId] = DynamicEquityProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _dynamicEquityConfig,
            _epochConfig
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetDynamicEquityProposalEvent(address(dao), msg.sender, data, proposalId, _dynamicEquityConfig, _epochConfig);
    }

    function submitSetDynamicEquityEpochProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        uint256 _unixTimestampInS
    ) external override reimbursable(dao) {
        setDynamicEquityEpochProposal[address(dao)][proposalId] = DynamicEquityEpochProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _unixTimestampInS
        );
        LVoting._submitProposal(dao, proposalId, data, Foundance.VotingType.OPTIMISTIC);
        emit SubmitSetDynamicEquityEpochProposalEvent(address(dao), msg.sender, data, proposalId, _unixTimestampInS);
    }

    function submitSetDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external override reimbursable(dao) {
        setDynamicEquityMemberProposal[address(dao)][proposalId] = DynamicEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _dynamicEquityMemberConfig
        );
       LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetDynamicEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _dynamicEquityMemberConfig);
    }

    function submitSetDynamicEquityMemberSuspendProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress,
        uint256 _suspendUntil
    ) external override reimbursable(dao) {
        setDynamicEquityMemberSuspendProposal[address(dao)][proposalId] = MemberValueProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAdress,
            _suspendUntil
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetDynamicEquityMemberSuspendProposalEvent(address(dao), msg.sender, data, proposalId, _memberAdress, _suspendUntil);
    }

    function submitSetDynamicEquityMemberEpochProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external override reimbursable(dao) {
        setDynamicEquityMemberEpochProposal[address(dao)][proposalId] = DynamicEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _dynamicEquityMemberConfig
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, data, proposalId, _dynamicEquityMemberConfig);
    }

    function submitSetDynamicEquityMemberEpochExpenseProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress,
        uint256 _expenseAmount
    ) external override reimbursable(dao) {
        setDynamicEquityMemberEpochExpenseProposal[address(dao)][proposalId] = MemberValueProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress,
            _expenseAmount
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetDynamicEquityMemberEpochExpenseProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress, _expenseAmount);
    }

    function submitRemoveDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        removeDynamicEquityMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitRemoveDynamicEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    function submitRemoveDynamicEquityMemberEpochProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        removeDynamicEquityMemberEpochProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitRemoveDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //PROCESS
    function processSetDynamicEquityProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityProposal storage proposal = setDynamicEquityProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquity(
                dao,
                proposal.dynamicEquityConfig,
                proposal.epochConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityProposalEvent(address(dao), msg.sender, proposalId, proposal.dynamicEquityConfig, proposal.epochConfig);
        }
    }

    function processSetDynamicEquityEpochProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityEpochProposal storage proposal = setDynamicEquityEpochProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityEpoch(
                dao,
                proposal.lastEpoch
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityEpochProposalEvent(address(dao), msg.sender, proposalId, proposal.lastEpoch);
        }
    }

    function processSetDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityMemberProposal storage proposal = setDynamicEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMember(
                dao,
                proposal.dynamicEquityMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.dynamicEquityMemberConfig);
        }
    }
    
    function processSetDynamicEquityMemberSuspendProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberValueProposal storage proposal = setDynamicEquityMemberSuspendProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMemberSuspend(
                dao,
                proposal.memberAddress,
                proposal.value
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberSuspendProposalEvent(address(dao), msg.sender, proposalId,  proposal.memberAddress, proposal.value);
        } 
    }

    function processSetDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        DynamicEquityMemberProposal storage proposal = setDynamicEquityMemberEpochProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMemberEpoch(
                dao,
                proposal.dynamicEquityMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, proposalId,  proposal.dynamicEquityMemberConfig);
        }
    }

    function processSetDynamicEquityMemberEpochExpenseProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberValueProposal storage proposal = setDynamicEquityMemberEpochExpenseProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.setDynamicEquityMemberEpochExpense(
                dao,
                proposal.memberAddress,
                proposal.value
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetDynamicEquityMemberEpochExpenseProposalEvent(address(dao), msg.sender, proposalId,  proposal.memberAddress, proposal.value);
        }
    }
 
    function processRemoveDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = removeDynamicEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.removeDynamicEquityMember(
                dao,
                proposal.memberAddress
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveDynamicEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
        }
    }
   
    function processRemoveDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = removeDynamicEquityMemberEpochProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
                dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
            );
            dynamicEquity.removeDynamicEquityMemberEpoch(
                dao,
                proposal.memberAddress
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveDynamicEquityMemberEpochProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
        }
    }

    //ACT
    function actDynamicEquityEpochDistributed(DaoRegistry dao)
        external
        override
        reimbursable(dao)
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(
            dao.getExtensionAddress(DaoHelper.DYNAMIC_EQUITY_EXT)
        );
        uint256 blockTimestamp = block.timestamp;
        uint256 nbMembers = dao.getNbMembers();
        Foundance.EpochConfig memory epochConfig = dynamicEquity.getEpochConfig();
        uint256 distributionEpoch = epochConfig.epochLast+epochConfig.epochDuration;
        while(distributionEpoch<blockTimestamp){
            for (uint256 i = 0; i < nbMembers; i++) {
                address memberAddress = dao.getMemberAddress(i);
                uint amount = dynamicEquity.getDynamicEquityMemberEpochAmount(memberAddress);
                require(bank.isTokenAllowed(DaoHelper.UNITS), "token not allowed");
                if(amount>0){
                bank.addToBalance(
                    dao,
                    memberAddress,
                    DaoHelper.UNITS,
                    amount
                );
                }
                emit ActDynamicEquityMemberEpochDistributedEvent(address(dao), msg.sender, memberAddress, DaoHelper.UNITS, amount);
            }
            dynamicEquity.setDynamicEquityEpoch(dao, epochConfig.epochDuration+epochConfig.epochLast);
            distributionEpoch+=epochConfig.epochDuration;
        }
        emit ActDynamicEquityEpochDistributedEvent(address(dao), msg.sender, distributionEpoch);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/bank/Bank.sol";
import "../../extensions/foundance/VestedEquityExtension.sol";
import "../../guards/AdapterGuard.sol";
import "./../modifiers/Reimbursable.sol";
import "./interfaces/IVotingAdapter.sol";
import "./interfaces/IVestedEquity.sol";
import "./libraries/LVoting.sol";
import "../../helpers/FairShareHelper.sol";
import "../../helpers/DaoHelper.sol";



contract VestedEquityAdapter is IVestedEquity, AdapterGuard, Reimbursable {

    struct VestedEquityMemberProposal {
        Foundance.ProposalStatus status;
        Foundance.VestedEquityMemberConfig vestedEquityMemberConfig;
    }
    struct MemberProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }

    mapping(address => mapping(bytes32 => VestedEquityMemberProposal)) public setVestedEquityMemberProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeVestedEquityMemberProposal;

    //EVENT
    event SubmitSetVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig);

    event SubmitRemoveVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 proposalId, address _memberAddress);

    event ProcessSetVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress,bytes32 proposalId, Foundance.VestedEquityMemberConfig _vestedEquityMemberConfig);

    event ProcessRemoveVestedEquityMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 proposalId, address _memberAddress);

    event ActVestedEquityMemberDistributedEvent(
        address _daoAddress, address _senderAddress, address _memberAddress, address _tokenAddress, uint256 _tokenAmount);

    //SUBMIT
    function submitSetVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) external override reimbursable(dao) {
        setVestedEquityMemberProposal[address(dao)][proposalId] = VestedEquityMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _vestedEquityMemberConfig
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetVestedEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _vestedEquityMemberConfig);
    }

    function submitRemoveVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        removeVestedEquityMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitRemoveVestedEquityMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    }

    //PROCESS
    function processSetVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        VestedEquityMemberProposal storage proposal = setVestedEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            VestedEquityExtension vestedEquity = VestedEquityExtension(
                dao.getExtensionAddress(DaoHelper.VESTED_EQUITY_EXT)
            );
            vestedEquity.setVestedEquityMember(
                dao,
                proposal.vestedEquityMemberConfig
            );
            emit ProcessSetVestedEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.vestedEquityMemberConfig);
            proposal.status == Foundance.ProposalStatus.DONE;
        } 
    }

    function processRemoveVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId)
        external
        override
        reimbursable(dao)
    {
        MemberProposal storage proposal = removeVestedEquityMemberProposal[address(dao)][
            proposalId
        ];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "dynamicEquityAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            VestedEquityExtension vestedEquity = VestedEquityExtension(
                dao.getExtensionAddress(DaoHelper.VESTED_EQUITY_EXT)
            );
            vestedEquity.removeVestedEquityMember(
                dao,
                proposal.memberAddress
            );
            emit ProcessRemoveVestedEquityMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
            proposal.status == Foundance.ProposalStatus.DONE;
        }
    }

    //ACT_INTERNAL
    function _actVestedEquityMemberDistributed(DaoRegistry dao, address senderAddress)
        public
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(
            dao.getExtensionAddress(DaoHelper.VESTED_EQUITY_EXT)
        );
        uint256 nbMembers = dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            address _memberAddress = dao.getMemberAddress(i);
            Foundance.VestedEquityMemberConfig memory vestedEquityMemberConfig = vestedEquity.getVestedEquityMemberConfig(_memberAddress); 
            address token = DaoHelper.UNITS;
            require(
                bank.isTokenAllowed(token),
                "dynamicEquityAdpt::token not allowed"
            );
            uint tokenAmount = vestedEquityMemberConfig.tokenAmount;
            vestedEquity.removeVestedEquityMemberAmount(dao, _memberAddress);       
            uint newAmount = vestedEquity.getVestedEquityMemberAmount(_memberAddress);
            uint tokenAmountToDistributed = newAmount-tokenAmount;
            if(tokenAmountToDistributed>0){
                bank.addToBalance(
                    dao,
                    _memberAddress,
                    token,
                    tokenAmountToDistributed
                );
            }
            emit ActVestedEquityMemberDistributedEvent(address(dao), senderAddress, _memberAddress, token, tokenAmountToDistributed);
        }
    }

    //ACT
    function actVestedEquityMemberDistributed(DaoRegistry dao, address memberAddress)
        external
        override
        reimbursable(dao)
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(
            dao.getExtensionAddress(DaoHelper.VESTED_EQUITY_EXT)
        );
        if (memberAddress != address(0x0)) {
                Foundance.VestedEquityMemberConfig memory vestedEquityMemberConfig = vestedEquity.getVestedEquityMemberConfig(memberAddress);
                address token = DaoHelper.UNITS;
                require(
                    bank.isTokenAllowed(token),
                    "token not allowed"
                );
                uint tokenAmount = vestedEquityMemberConfig.tokenAmount;
                vestedEquity.removeVestedEquityMemberAmount(dao, memberAddress);       
                uint newAmount = vestedEquity.getVestedEquityMemberAmount(memberAddress);
                uint tokenAmountToDistributed = newAmount - tokenAmount;
                if(tokenAmountToDistributed>0){
                    bank.addToBalance(
                        dao,
                        memberAddress,
                        token,
                        tokenAmountToDistributed
                    );
                }
                emit ActVestedEquityMemberDistributedEvent(address(dao), msg.sender, memberAddress, token, tokenAmountToDistributed);
        }else{
                _actVestedEquityMemberDistributed(dao, msg.sender);          
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/foundance/CommunityIncentiveExtension.sol";
import "../../extensions/foundance/MemberExtension.sol";
import "../../guards/AdapterGuard.sol";
import "./../modifiers/Reimbursable.sol";
import "./interfaces/IVotingAdapter.sol";
import "./interfaces/ICommunityIncentive.sol";
import "./libraries/LVoting.sol";
import "../../helpers/FairShareHelper.sol";
import "../../helpers/DaoHelper.sol";
import "../../extensions/bank/Bank.sol";


contract CommunityIncentiveAdapter is ICommunityIncentive, AdapterGuard, Reimbursable {
    
    struct CommunityIncentiveProposal {
        Foundance.ProposalStatus status;
        Foundance.CommunityIncentiveConfig communityIncentiveConfig;
        Foundance.EpochConfig epochConfig;
    }

    struct CommunityIncentiveMemberProposal {
        Foundance.ProposalStatus status;
        Foundance.CommunityIncentiveMemberConfig communityIncentiveMemberConfig;
    }

    struct MemberProposal {
        Foundance.ProposalStatus status;
        address memberAddress;
    }

    mapping(address => mapping(bytes32 => CommunityIncentiveProposal)) public setCommunityIncentiveProposal;

    mapping(address => mapping(bytes32 => CommunityIncentiveMemberProposal)) public setCommunityIncentiveMemberProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeCommunityIncentiveProposal;

    mapping(address => mapping(bytes32 => MemberProposal)) public removeCommunityIncentiveMemberProposal;

    mapping(address => bytes32) public ongoingCommunityIncentiveDistribution;

    //EVENT
    event SubmitSetCommunityIncentiveProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, Foundance.CommunityIncentiveConfig _communityIncentiveConfig, Foundance.EpochConfig _epochConfig);
        
    event SubmitSetCommunityIncentiveMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, Foundance.CommunityIncentiveMemberConfig _communityIncentiveMemberConfig);
        
    event SubmitRemoveCommunityIncentiveProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId);

    event SubmitRemoveCommunityIncentiveMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes _data, bytes32 _proposalId, address _memberAddress);

    event ProcessSetCommunityIncentiveProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, Foundance.CommunityIncentiveConfig _communityIncentiveConfig, Foundance.EpochConfig _epochConfig);
    
    event ProcessSetCommunityIncentiveMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, Foundance.CommunityIncentiveMemberConfig _communityIncentiveMemberConfig);

    event ProcessRemoveCommunityIncentiveProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId);

    event ProcessRemoveCommunityIncentiveMemberProposalEvent(
        address _daoAddress, address _senderAddress, bytes32 _proposalId, address _memberAddress);
    
    event ActCommunityIncentiveMemberDistributedEvent(
        address _daoAddress, address _senderAddress, address _memberAddress, uint256 amountToBeSent);

    event ActCommunityIncentiveEpochDistributedEvent(
        address _daoAddress, address _senderAddress);
    
    //SUBMIT
    function submitSetCommunityIncentiveProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityIncentiveConfig calldata _communityIncentiveConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external override reimbursable(dao) {
        setCommunityIncentiveProposal[address(dao)][proposalId] = CommunityIncentiveProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _communityIncentiveConfig,
            _epochConfig
        );
       LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetCommunityIncentiveProposalEvent(address(dao), msg.sender, data, proposalId,_communityIncentiveConfig, _epochConfig);
    }

    function submitSetCommunityIncentiveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityIncentiveMemberConfig calldata _communityIncentiveMemberConfig
    ) external override reimbursable(dao) {
        setCommunityIncentiveMemberProposal[address(dao)][proposalId] = CommunityIncentiveMemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _communityIncentiveMemberConfig
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitSetCommunityIncentiveMemberProposalEvent(address(dao), msg.sender, data, proposalId, _communityIncentiveMemberConfig);
    }
 
    function submitRemoveCommunityIncentiveProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) external override reimbursable(dao) {
        removeCommunityIncentiveProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            msg.sender
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitRemoveCommunityIncentiveProposalEvent(address(dao), msg.sender, data, proposalId);
    }

    function submitRemoveCommunityIncentiveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external override reimbursable(dao) {
        removeCommunityIncentiveMemberProposal[address(dao)][proposalId] = MemberProposal(
            Foundance.ProposalStatus.NOT_STARTED,
            _memberAddress
        );
        LVoting._submitProposal(dao, proposalId, data);
        emit SubmitRemoveCommunityIncentiveMemberProposalEvent(address(dao), msg.sender, data, proposalId, _memberAddress);
    } 

    //PROCESS_INTERNAL
    function _processRemoveCommunityIncentive(
        DaoRegistry dao,
        CommunityIncentiveExtension communityIncentive,
        BankExtension bank
    ) internal {
        Foundance.CommunityIncentiveConfig memory communityIncentiveConfig = communityIncentive.getCommunityIncentiveConfig(); 
        uint256 tokenAmountToBeRemoved = communityIncentiveConfig.tokenAmount;
        uint guildTokenAmount = bank.balanceOf(DaoHelper.GUILD,DaoHelper.UNITS);
        if(
            tokenAmountToBeRemoved>0 &&
            guildTokenAmount>=tokenAmountToBeRemoved
        ){
            bank.subtractFromBalance(
                dao,
                DaoHelper.GUILD,
                DaoHelper.UNITS,
                tokenAmountToBeRemoved
            );
        }
        communityIncentive.removeCommunityIncentive(
            dao
        );
    }

    //PROCESS
    function processSetCommunityIncentiveProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        CommunityIncentiveProposal storage proposal = setCommunityIncentiveProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityIncentiveAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(
                dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT)
            );
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoHelper.BANK)
            );
            _processRemoveCommunityIncentive(dao, communityIncentive, bank);
            communityIncentive.setCommunityIncentive(
                dao,
                proposal.communityIncentiveConfig,
                proposal.epochConfig
            );
            bank.addToBalance(
                dao,
                DaoHelper.GUILD,
                DaoHelper.UNITS,
                proposal.communityIncentiveConfig.tokenAmount
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetCommunityIncentiveProposalEvent(address(dao), msg.sender, proposalId,proposal.communityIncentiveConfig, proposal.epochConfig);
        }
    }

    function processSetCommunityIncentiveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        CommunityIncentiveMemberProposal storage proposal = setCommunityIncentiveMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityIncentiveAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(
                dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT)
            );
            communityIncentive.setCommunityIncentiveMember(
                dao,
                proposal.communityIncentiveMemberConfig
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessSetCommunityIncentiveMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.communityIncentiveMemberConfig);
        }
    }
  
    function processRemoveCommunityIncentiveProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        MemberProposal storage proposal = removeCommunityIncentiveProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityIncentiveAdpt::proposal already completed or in progress"
        );
        proposal.status = LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(
                dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT)
            );
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoHelper.BANK)
            );
            _processRemoveCommunityIncentive(dao, communityIncentive, bank);
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveCommunityIncentiveProposalEvent(address(dao), msg.sender, proposalId);
        }
    }

    function processRemoveCommunityIncentiveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) external override reimbursable(dao) {
        MemberProposal storage proposal = removeCommunityIncentiveMemberProposal[address(dao)][proposalId];
        require(
            proposal.status == Foundance.ProposalStatus.NOT_STARTED,
            "communityIncentiveAdpt::proposal already completed or in progress"
        );
        proposal.status =LVoting._processProposal(dao,proposalId);
        if (proposal.status == Foundance.ProposalStatus.IN_PROGRESS) {
            CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(
                dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT)
            );
            communityIncentive.removeCommunityIncentiveMember(
                dao,
                proposal.memberAddress
            );
            proposal.status == Foundance.ProposalStatus.DONE;
            emit ProcessRemoveCommunityIncentiveMemberProposalEvent(address(dao), msg.sender, proposalId, proposal.memberAddress);
        }
    }

    //ACT_INTERNAL
    function _actCommunityIncentiveMemberDistributed(
        DaoRegistry dao,
        bytes32 distributionId
    ) internal {
        ongoingCommunityIncentiveDistribution[address(dao)] = distributionId;
    }

    //ACT
    function actCommunityIncentiveMemberDistributed(
        DaoRegistry dao, 
        address memberAddress,
        uint256 amountToBeSent,
        bytes32 distributionId 
    ) external override reimbursable(dao) {        
        CommunityIncentiveExtension communityIncentive = CommunityIncentiveExtension(
            dao.getExtensionAddress(DaoHelper.COMMUNITY_INCENTIVE_EXT)
        );
        Foundance.CommunityIncentiveMemberConfig memory communityIncentiveMemberConfig = communityIncentive.getCommunityIncentiveMemberConfig(memberAddress);
        require(
            communityIncentive.getIsCommunityIncentiveMember(msg.sender),
            "communityIncentiveAdpt::msg.sender not allowed to distribute community incentives"
        );
        require(
            amountToBeSent < communityIncentiveMemberConfig.singlePaymentAmountThreshold,
            "communityIncentiveAdpt::amount to be sent has to be less than singlePaymentAmountThreshold"
        );
        require(
            communityIncentiveMemberConfig.totalPaymentAmount+amountToBeSent<communityIncentiveMemberConfig.totalPaymentAmountThreshold,
            "communityIncentiveAdpt::total amount to be sent has to be less than totalPaymentAmountThreshold"
        );
        BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoHelper.BANK)
        );
        require(
            bank.balanceOf(DaoHelper.GUILD,DaoHelper.UNITS)>=amountToBeSent,
            "communityIncentiveAdpt::amountToBeSent has to be less than available Tokens in the GUILD"
        );
        Foundance.CommunityIncentiveConfig memory communityIncentiveConfig = communityIncentive.getCommunityIncentiveConfig();
        require(
            communityIncentiveConfig.tokenAmount>=amountToBeSent,
            "communityIncentiveAdpt::amountToBeSent has to be less than available Tokens in the Community Incentive Allocation"
        );
        _actCommunityIncentiveMemberDistributed(dao, distributionId);
        require(
            ongoingCommunityIncentiveDistribution[address(dao)]==0,
            "communityIncentiveAdpt::has to wait until ongoingDistribution is done"
        );
        communityIncentiveConfig.tokenAmount -= amountToBeSent;
        communityIncentive.setCommunityIncentive(dao, communityIncentiveConfig);
        MemberExtension member = MemberExtension(
            dao.getExtensionAddress(DaoHelper.MEMBER_EXT)
        );
        if(member.getIsMember(memberAddress)){            
            bank.addToBalance(
                dao,
                memberAddress,
                DaoHelper.UNITS,
                amountToBeSent
            );
        }
        else{
            member.setMember(
                dao,
                Foundance.MemberConfig(
                    memberAddress,
                    amountToBeSent,
                    block.timestamp,
                    false
                )
            );
        }
        bank.subtractFromBalance(
            dao,
            DaoHelper.GUILD,
            DaoHelper.UNITS,
            amountToBeSent
        );
        communityIncentiveMemberConfig.totalPaymentAmount += amountToBeSent;
        communityIncentive.setCommunityIncentiveMember(dao,communityIncentiveMemberConfig);
        _actCommunityIncentiveMemberDistributed(dao, 0);
        emit ActCommunityIncentiveMemberDistributedEvent(address(dao), msg.sender, memberAddress, amountToBeSent);
    }
    
    function actCommunityIncentiveEpochDistributed(
        DaoRegistry dao
    ) external override reimbursable(dao) { 
        //TODO
        emit ActCommunityIncentiveEpochDistributedEvent(address(dao), msg.sender);
    }
}

pragma solidity ^0.8.0;
import "../extensions/bank/Bank.sol";
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
library DaoHelper {
    
    bytes32 internal constant DYNAMIC_EQUITY_ADAPT = keccak256("dynamic-equity-adpt"); //FOUNDANCE
    bytes32 internal constant VESTED_EQUITY_ADAPT = keccak256("vested-equity-adpt"); //FOUNDANCE
    bytes32 internal constant COMMUNITY_INCENTIVE_ADAPT = keccak256("community-incentive-adpt"); //FOUNDANCE
    bytes32 internal constant MEMBER_ADAPT = keccak256("member-adpt"); //FOUNDANCE
    bytes32 internal constant VOTING_ADAPT = keccak256("voting-adpt"); //FOUNDANCE
    // Adapters
    bytes32 internal constant VOTING = keccak256("voting");
    bytes32 internal constant ONBOARDING = keccak256("onboarding");
    bytes32 internal constant NONVOTING_ONBOARDING = keccak256("nonvoting-onboarding");
    bytes32 internal constant TRIBUTE = keccak256("tribute");
    bytes32 internal constant FINANCING = keccak256("financing");
    bytes32 internal constant MANAGING = keccak256("managing");
    bytes32 internal constant RAGEQUIT = keccak256("ragequit");
    bytes32 internal constant GUILDKICK = keccak256("guildkick");
    bytes32 internal constant CONFIGURATION = keccak256("configuration");
    bytes32 internal constant DISTRIBUTE = keccak256("distribute");
    bytes32 internal constant TRIBUTE_NFT = keccak256("tribute-nft");
    bytes32 internal constant REIMBURSEMENT = keccak256("reimbursement");
    bytes32 internal constant TRANSFER_STRATEGY = keccak256("erc20-transfer-strategy");
    bytes32 internal constant DAO_REGISTRY_ADAPT = keccak256("daoRegistry");
    bytes32 internal constant BANK_ADAPT = keccak256("bank");
    bytes32 internal constant ERC721_ADAPT = keccak256("nft");
    bytes32 internal constant ERC1155_ADAPT = keccak256("erc1155-adpt");
    bytes32 internal constant ERC1271_ADAPT = keccak256("signatures");
    bytes32 internal constant SNAPSHOT_PROPOSAL_ADPT = keccak256("snapshot-proposal-adpt");
    bytes32 internal constant VOTING_HASH_ADPT = keccak256("voting-hash-adpt");
    bytes32 internal constant KICK_BAD_REPORTER_ADPT = keccak256("kick-bad-reporter-adpt");
    bytes32 internal constant COUPON_ONBOARDING_ADPT = keccak256("coupon-onboarding");
    bytes32 internal constant LEND_NFT_ADPT = keccak256("lend-nft");
    bytes32 internal constant ERC20_TRANSFER_STRATEGY_ADPT = keccak256("erc20-transfer-strategy");
    // Extensions
    bytes32 internal constant BANK = keccak256("bank");
    bytes32 internal constant EXECUTOR_EXT = keccak256("executor-ext");
    bytes32 internal constant ERC1271 = keccak256("erc1271");
    bytes32 internal constant ERC1155_EXT = keccak256("erc1155-ext");
    bytes32 internal constant NFT = keccak256("nft");
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");
    bytes32 internal constant INTERNAL_TOKEN_VESTING_EXT = keccak256("internal-token-vesting-ext");
    bytes32 internal constant MEMBER_EXT = keccak256("member-ext"); //FOUNDANCE
    bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext"); //FOUNDANCE
    bytes32 internal constant COMMUNITY_INCENTIVE_EXT = keccak256("community-incentive-ext"); //FOUNDANCE
    bytes32 internal constant VESTED_EQUITY_EXT = keccak256("vested-equity-ext"); //FOUNDANCE
    // Reserved Addresses
    address internal constant GUILD = address(0xdead);
    address internal constant ESCROW = address(0x4bec);
    address internal constant TOTAL = address(0xbabe);
    address internal constant UNITS = address(0xFF1CE);
    address internal constant LOOT = address(0xB105F00D);
    address internal constant ETH_TOKEN = address(0x0);
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    uint8 internal constant MAX_TOKENS_GUILD_BANK = 200;


    function totalTokens(BankExtension bank) internal view returns (uint256) {
        return memberTokens(bank, TOTAL) - memberTokens(bank, GUILD); //GUILD is accounted for twice otherwise
    }

    function totalUnitTokens(BankExtension bank) internal view returns (uint256) {
        return  bank.balanceOf(TOTAL, UNITS) - bank.balanceOf(GUILD, UNITS); //GUILD is accounted for twice otherwise
    }
    /**
     * @notice calculates the total number of units.
     */
    function priorTotalTokens(BankExtension bank, uint256 at)
        internal
        view
        returns (uint256)
    {
        return
            priorMemberTokens(bank, TOTAL, at) -
            priorMemberTokens(bank, GUILD, at);
    }

    function memberTokens(BankExtension bank, address member)
        internal
        view
        returns (uint256)
    {
        return bank.balanceOf(member, UNITS) + bank.balanceOf(member, LOOT);
    }

    function msgSender(DaoRegistry dao, address addr)
        internal
        view
        returns (address)
    {
        address memberAddress = dao.getAddressIfDelegated(addr);
        address delegatedAddress = dao.getCurrentDelegateKey(addr);

        require(
            memberAddress == delegatedAddress || delegatedAddress == addr,
            "call with your delegate key"
        );

        return memberAddress;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorMemberTokens(
        BankExtension bank,
        address member,
        uint256 at
    ) internal view returns (uint256) {
        return
            bank.getPriorAmount(member, UNITS, at) +
            bank.getPriorAmount(member, LOOT, at);
    }

    //helper
    function getFlag(uint256 flags, uint256 flag) internal pure returns (bool) {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) internal pure returns (uint256) {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(address addr) internal pure returns (bool) {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(address addr) internal pure returns (bool) {
        return addr != address(0x0);
    }

    function potentialNewMember(
        address memberAddress,
        DaoRegistry dao,
        BankExtension bank
    ) internal {
        dao.potentialNewMember(memberAddress);
        require(memberAddress != address(0x0), "invalid member address");
        if (address(bank) != address(0x0)) {
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(dao, memberAddress, MEMBER_COUNT, 1);
            }
        }
    }

    /**
     * A DAO is in creation mode is the state of the DAO is equals to CREATION and
     * 1. The number of members in the DAO is ZERO or,
     * 2. The sender of the tx is a DAO member (usually the DAO owner) or,
     * 3. The sender is an adapter.
     */
    // slither-disable-next-line calls-loop
    function isInCreationModeAndHasAccess(DaoRegistry dao)
        internal
        view
        returns (bool)
    {
        return
            dao.state() == DaoRegistry.DaoState.CREATION &&
            (dao.getNbMembers() == 0 ||
                dao.isMember(msg.sender) ||
                dao.isAdapter(msg.sender));
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    function _createClone(address target)
        internal
        returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
        require(result != address(0), "create failed");
    }

    function _isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../helpers/DaoHelper.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(DaoRegistry dao) {
        require(
            dao.isAdapter(msg.sender) ||
                DaoHelper.isInCreationModeAndHasAccess(dao),
            "onlyAdapter"
        );
        _;
    }

    modifier reentrancyGuard(DaoRegistry dao) {
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        _;
        dao.unlockSession();
    }

    modifier executorFunc(DaoRegistry dao) {
        address executorAddr = dao.getExtensionAddress(
            keccak256("executor-ext")
        );
        require(address(this) == executorAddr, "only callable by the executor");
        _;
    }

    modifier hasAccess(DaoRegistry dao, DaoRegistry.AclFlag flag) {
        require(
            DaoHelper.isInCreationModeAndHasAccess(dao) ||
                dao.hasAdapterAccess(msg.sender, flag),
            "accessDenied"
        );
        _;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../extensions/bank/Bank.sol";
import "../helpers/DaoHelper.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract MemberGuard {
    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(DaoRegistry dao) {
        _onlyMember(dao, msg.sender);
        _;
    }

    modifier onlyMember2(DaoRegistry dao, address _addr) {
        _onlyMember(dao, _addr);
        _;
    }

    function _onlyMember(DaoRegistry dao, address _addr) internal view {
        require(isActiveMember(dao, _addr), "onlyMember");
    }

    function isActiveMember(DaoRegistry dao, address _addr)
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(DaoHelper.BANK);
        if (bankAddress != address(0x0)) {
            address memberAddr = DaoHelper.msgSender(dao, _addr);
            return
                dao.isMember(_addr) &&
                BankExtension(bankAddress).balanceOf(
                    memberAddr,
                    DaoHelper.UNITS
                ) >
                0;
        }

        return dao.isMember(_addr);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import '../../core/DaoRegistry.sol';
import '../IExtension.sol';
import '../../guards/AdapterGuard.sol';
import '../../helpers/DaoHelper.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract BankExtension is IExtension, ERC165 {
    using Address for address payable;
    using SafeERC20 for IERC20;

    uint8 public maxExternalTokens; // the maximum number of external tokens that can be stored in the bank

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }

    modifier noProposal() {
        require(dao.lockedAt() < block.number, 'proposal lock');
        _;
    }

    /// @dev - Events for Bank
    event NewBalance(address member, address tokenAddr, uint160 amount);

    event Withdraw(address account, address tokenAddr, uint160 amount);

    event WithdrawTo(
        address accountFrom,
        address accountTo,
        address tokenAddr,
        uint160 amount
    );

    /*
     * STRUCTURES
     */

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    address[] public tokens;
    address[] public internalTokens;
    // tokenAddress => availability
    mapping(address => bool) public availableTokens;
    mapping(address => bool) public availableInternalTokens;
    // tokenAddress => memberAddress => checkpointNum => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
        public checkpoints;
    // tokenAddress => memberAddress => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    // slither-disable-next-line calls-loop
    modifier hasExtensionAccess(DaoRegistry _dao, AclFlag flag) {
        require(
            dao == _dao &&
                (address(this) == msg.sender ||
                    address(dao) == msg.sender ||
                    !initialized ||
                    DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            'bank::accessDenied'
        );
        _;
    }

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     */
    function initialize(DaoRegistry _dao, address creator) external override {
        require(!initialized, 'already initialized');
        require(_dao.isMember(creator), 'not a member');
        dao = _dao;

        availableInternalTokens[DaoHelper.UNITS] = true;
        internalTokens.push(DaoHelper.UNITS);

        availableInternalTokens[DaoHelper.MEMBER_COUNT] = true;
        internalTokens.push(DaoHelper.MEMBER_COUNT);
        uint256 nbMembers = _dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            //slither-disable-next-line calls-loop
            addToBalance(
                _dao,
                _dao.getMemberAddress(i),
                DaoHelper.MEMBER_COUNT,
                1
            );
        }

        _createNewAmountCheckpoint(creator, DaoHelper.UNITS, 1);
        _createNewAmountCheckpoint(DaoHelper.TOTAL, DaoHelper.UNITS, 1);
        initialized = true;
    }

    function withdraw(
        DaoRegistry _dao,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(member, tokenAddr) >= amount,
            'bank::withdraw::not enough funds'
        );
        subtractFromBalance(_dao, member, tokenAddr, amount);
        if (tokenAddr == DaoHelper.ETH_TOKEN) {
            member.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(member, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit Withdraw(member, tokenAddr, uint160(amount));
    }

    function withdrawTo(
        DaoRegistry _dao,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(memberFrom, tokenAddr) >= amount,
            'bank::withdraw::not enough funds'
        );
        subtractFromBalance(_dao, memberFrom, tokenAddr, amount);
        if (tokenAddr == DaoHelper.ETH_TOKEN) {
            memberTo.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(memberTo, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit WithdrawTo(memberFrom, memberTo, tokenAddr, uint160(amount));
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(address token) external view returns (bool) {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(address token) public view returns (bool) {
        return availableTokens[token];
    }

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(uint8 maxTokens) external {
        require(!initialized, 'already initialized');
        require(
            maxTokens > 0 && maxTokens <= DaoHelper.MAX_TOKENS_GUILD_BANK,
            'maxTokens should be (0,200]'
        );
        maxExternalTokens = maxTokens;
    }

    /*
     * BANK
     */

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(DaoRegistry _dao, address token)
        external
        hasExtensionAccess(_dao, AclFlag.REGISTER_NEW_TOKEN)
    {
        require(DaoHelper.isNotReservedAddress(token), 'reservedToken');
        require(!availableInternalTokens[token], 'internalToken');
        require(
            tokens.length <= maxExternalTokens,
            'exceeds the maximum tokens allowed'
        );

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(DaoRegistry _dao, address token)
        external
        hasExtensionAccess(_dao, AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        require(DaoHelper.isNotReservedAddress(token), 'reservedToken');
        require(!availableTokens[token], 'availableToken');

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    function updateToken(DaoRegistry _dao, address tokenAddr)
        external
        hasExtensionAccess(_dao, AclFlag.UPDATE_TOKEN)
    {
        require(isTokenAllowed(tokenAddr), 'token not allowed');
        uint256 totalBalance = balanceOf(DaoHelper.TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == DaoHelper.ETH_TOKEN) {
            realBalance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(
                _dao,
                DaoHelper.GUILD,
                tokenAddr,
                realBalance - totalBalance
            );
        } else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(DaoHelper.GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(
                    _dao,
                    DaoHelper.GUILD,
                    tokenAddr,
                    tokensToRemove
                );
            } else {
                subtractFromBalance(
                    _dao,
                    DaoHelper.GUILD,
                    tokenAddr,
                    guildBalance
                );
            }
        }
    }

    /**
     * Public read-only functions
     */

    /**
     * Internal bookkeeping
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank's tokens
     */
    function getToken(uint256 index) external view returns (address) {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank's array of internal tokens
     */
    function getInternalToken(uint256 index) external view returns (address) {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() external view returns (uint256) {
        return internalTokens.length;
    }

    function addToBalance(
        address,
        address,
        uint256
    ) external payable {
        revert('not implemented');
    }

    /**
     * @notice Adds to a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        DaoRegistry _dao,
        address member,
        address token,
        uint256 amount
    ) public payable hasExtensionAccess(_dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            'unknown token address'
        );
        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(DaoHelper.TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoHelper.TOTAL, token, newTotalAmount);
    }

    function addToBalanceBatch(
        DaoRegistry _dao,
        address[] memory member ,
        address token,
        uint256[] memory amount
    ) public payable hasExtensionAccess(_dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            'unknown token address'
        );
        for(uint256 i;i<member.length;i++){
            uint256 newAmount = balanceOf(member[i], token) + amount[i];
            uint256 newTotalAmount = balanceOf(DaoHelper.TOTAL, token) + amount[i];
            _createNewAmountCheckpoint(member[i], token, newAmount);
            _createNewAmountCheckpoint(DaoHelper.TOTAL, token, newTotalAmount);
        }

    }
    /**
     * @notice Remove from a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        DaoRegistry _dao,
        address member,
        address token,
        uint256 amount
    ) public hasExtensionAccess(_dao, AclFlag.SUB_FROM_BALANCE) {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(DaoHelper.TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoHelper.TOTAL, token, newTotalAmount);
    }

    function subtractFromBalance(
        address,
        address,
        uint256
    ) external pure {
        revert('not implemented');
    }

    function internalTransfer(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('not implemented');
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        DaoRegistry _dao,
        address from,
        address to,
        address token,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.INTERNAL_TRANSFER) {
        require(dao.notJailed(from), 'no transfer from jail');
        require(dao.notJailed(to), 'no transfer from jail');
        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(from, token, newAmount);
        _createNewAmountCheckpoint(to, token, newAmount2);
    }

    /**
     * @notice Returns an member's balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member's balance of which will be returned
     * @return The amount in account's tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) external view returns (uint256) {
        require(
            blockNumber < block.number,
            'bank::getPriorAmount: not yet determined'
        );

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            this.withdrawTo.selector == interfaceId;
    }

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) internal {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            require(
                amount < type(uint88).max,
                'token amount exceeds the maximum limit for internal tokens'
            );
            isValidToken = true;
        } else if (availableTokens[token]) {
            require(
                amount < type(uint160).max,
                'token amount exceeds the maximum limit for external tokens'
            );
            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        require(isValidToken, 'token not registered');

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            // The only condition that we should allow the amount update
            // is when the block.number exactly matches the fromBlock value.
            // Anything different from that should generate a new checkpoint.
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } else {
            checkpoints[token][member][nCheckpoints] = Checkpoint(
                uint96(block.number),
                newAmount
            );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        //slither-disable-next-line reentrancy-events
        emit NewBalance(member, token, newAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IFactory {
    /**
     * @notice Do not rely on the result returned by this right after the new extension is cloned,
     * because it is prone to front-running attacks. During the extension creation it is safer to
     * read the new extension address from the event generated in the create call transaction.
     */
    function getExtensionAddress(address dao) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";
import "../IExtension.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

/**
 * @dev Proxy contract which executes delegated calls to another contract using the EVM
 * instruction `delegatecall`, the call is triggered via fallback function.
 * The call is executed in the target contract identified by its address via `implementation` argument.
 * The success and return data of the delegated call are be returned back to the caller of the proxy.
 * Only contracts with the ACL Flag: EXECUTOR are allowed to use the proxy delegated call function.
 * This contract was based on the OpenZeppelin Proxy contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
 */
contract ExecutorExtension is IExtension {
    using Address for address payable;

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        EXECUTE
    }

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    modifier hasExtensionAccess(AclFlag flag) {
        require(
            (address(this) == msg.sender ||
                address(dao) == msg.sender ||
                !initialized ||
                DaoHelper.isInCreationModeAndHasAccess(dao) ||
                dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )),
            "executorExt::accessDenied"
        );
        _;
    }

    /**
     * @notice Initialises the Executor extension to be associated with a DAO
     * @dev Can only be called once
     * @param _dao The dao address that will be associated with the new extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        dao = _dao;
        initialized = true;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation)
        internal
        virtual
        hasExtensionAccess(AclFlag.EXECUTE)
    {
        require(
            DaoHelper.isNotZeroAddress(implementation),
            "executorExt: impl address can not be zero"
        );
        require(
            DaoHelper.isNotReservedAddress(implementation),
            "executorExt: impl address can not be reserved"
        );

        address daoAddr;
        bytes memory data = msg.data;
        assembly {
            daoAddr := mload(add(data, 36))
        }

        require(daoAddr == address(dao), "wrong dao!");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Delegates the current call to the sender address.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(msg.sender);
    }

    /**
     * @dev Fallback function that delegates calls to the sender address. Will run if no other
     * function in the contract matches the call data.
     */
    // Only senders with the EXECUTE ACL Flag enabled is allowed to send eth.
    //slither-disable-next-line locked-ether
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    // Only senders with the EXECUTE ACL Flag enabled is allowed to send eth.
    //slither-disable-next-line locked-ether
    receive() external payable {
        _fallback();
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../../core/DaoRegistry.sol";
import "../../../helpers/DaoHelper.sol";
import "../../../guards/AdapterGuard.sol";
import "../../IExtension.sol";
import "../../bank/Bank.sol";
import "./IERC20TransferStrategy.sol";
import "../../../guards/AdapterGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

/**
 *
 * The ERC20Extension is a contract to give erc20 functionality
 * to the internal token units held by DAO members inside the DAO itself.
 */
contract ERC20Extension is AdapterGuard, IExtension, IERC20 {
    // The DAO address that this extension belongs to
    DaoRegistry public dao;

    // Internally tracks deployment under eip-1167 proxy pattern
    bool public initialized = false;

    // The token address managed by the DAO that tracks the internal transfers
    address public tokenAddress;

    // The name of the token managed by the DAO
    string public tokenName;

    // The symbol of the token managed by the DAO
    string public tokenSymbol;

    // The number of decimals of the token managed by the DAO
    uint8 public tokenDecimals;

    // Tracks all the token allowances: owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO that it belongs to,
     * and checks if the parameters were set.
     * @param _dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        require(tokenAddress != address(0x0), "missing token address");
        require(bytes(tokenName).length != 0, "missing token name");
        require(bytes(tokenSymbol).length != 0, "missing token symbol");
        initialized = true;
        dao = _dao;
    }

    /**
     * @dev Returns the token address managed by the DAO that tracks the
     * internal transfers.
     */
    function token() external view virtual returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Sets the token address if the extension is not initialized,
     * not reserved and not zero.
     */
    function setToken(address _tokenAddress) external {
        require(!initialized, "already initialized");
        require(_tokenAddress != address(0x0), "invalid token address");
        require(
            DaoHelper.isNotReservedAddress(_tokenAddress),
            "token address already in use"
        );

        tokenAddress = _tokenAddress;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return tokenName;
    }

    /**
     * @dev Sets the name of the token if the extension is not initialized.
     */
    function setName(string memory _name) external {
        require(!initialized, "already initialized");
        tokenName = _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev Sets the token symbol if the extension is not initialized.
     */
    function setSymbol(string memory _symbol) external {
        require(!initialized, "already initialized");
        tokenSymbol = _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() external view virtual returns (uint8) {
        return tokenDecimals;
    }

    /**
     * @dev Sets the token decimals if the extension is not initialized.
     */
    function setDecimals(uint8 _decimals) external {
        require(!initialized, "already initialized");
        tokenDecimals = _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        return bank.balanceOf(DaoHelper.TOTAL, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        return bank.balanceOf(account, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account` considering the snapshot.
     */
    function getPriorAmount(address account, uint256 snapshot)
        external
        view
        returns (uint256)
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        return bank.getPriorAmount(account, tokenAddress, snapshot);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param spender The address account that will have the units decremented.
     * @param amount The amount to decrement from the spender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    // slither-disable-next-line reentrancy-benign
    function approve(address spender, uint256 amount)
        public
        override
        reentrancyGuard(dao)
        returns (bool)
    {
        address senderAddr = dao.getAddressIfDelegated(msg.sender);
        require(
            DaoHelper.isNotZeroAddress(senderAddr),
            "ERC20: approve from the zero address"
        );
        require(
            DaoHelper.isNotZeroAddress(spender),
            "ERC20: approve to the zero address"
        );
        require(dao.isMember(senderAddr), "sender is not a member");
        require(
            DaoHelper.isNotReservedAddress(spender),
            "spender can not be a reserved address"
        );

        _allowances[senderAddr][spender] = amount;
        // slither-disable-next-line reentrancy-events
        emit Approval(senderAddr, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to increment in the recipient account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return
            transferFrom(
                dao.getAddressIfDelegated(msg.sender),
                recipient,
                amount
            );
    }

    function _transferInternal(
        address senderAddr,
        address recipient,
        uint256 amount,
        BankExtension bank
    ) internal {
        DaoHelper.potentialNewMember(recipient, dao, bank);
        bank.internalTransfer(dao, senderAddr, recipient, tokenAddress, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param sender The address account that will have the units decremented.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to decrement from the sender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            DaoHelper.isNotZeroAddress(recipient),
            "ERC20: transfer to the zero address"
        );

        IERC20TransferStrategy strategy = IERC20TransferStrategy(
            dao.getAdapterAddress(DaoHelper.TRANSFER_STRATEGY)
        );
        (
            IERC20TransferStrategy.ApprovalType approvalType,
            uint256 allowedAmount
        ) = strategy.evaluateTransfer(
                dao,
                tokenAddress,
                sender,
                recipient,
                amount,
                msg.sender
            );

        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );

        if (approvalType == IERC20TransferStrategy.ApprovalType.NONE) {
            revert("transfer not allowed");
        }

        if (approvalType == IERC20TransferStrategy.ApprovalType.SPECIAL) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(sender, recipient, amount);
            return true;
        }

        if (sender != msg.sender) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            //check if sender has approved msg.sender to spend amount
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );

            if (allowedAmount >= amount) {
                _allowances[sender][msg.sender] = currentAllowance - amount;
            }
        }

        if (allowedAmount >= amount) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(sender, recipient, amount);
            return true;
        }

        return false;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import "../../../core/DaoRegistry.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

/**
 *
 * The ERC20Extension is a contract to give erc20 functionality
 * to the internal token units held by DAO members inside the DAO itself.
 */
interface IERC20TransferStrategy {
    enum AclFlag {
        REGISTER_TRANSFER
    }
    enum ApprovalType {
        NONE,
        STANDARD,
        SPECIAL
    }

    function evaluateTransfer(
        DaoRegistry dao,
        address tokenAddr,
        address from,
        address to,
        uint256 amount,
        address caller
    ) external view returns (ApprovalType, uint256);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/IExtension.sol";
import "../../helpers/DaoHelper.sol";

contract MemberExtension is IExtension {

    enum AclFlag {
        SET_MEMBER,
        REMOVE_MEMBER,
        ACT_MEMBER
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "memberExt::accessDenied"
        );
        _;
    }

    Foundance.MemberConfig[] public memberConfig;
    mapping(address => uint) public memberIndex;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "memberExt::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET
    function setMember(
        DaoRegistry dao,
        Foundance.MemberConfig calldata _memberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_MEMBER) {
        require(_memberConfig.memberAddress!=address(0), "memberExt::member not set");
        uint length = memberConfig.length;
        if(memberIndex[_memberConfig.memberAddress]==0){
            memberIndex[_memberConfig.memberAddress]=length+1;
            memberConfig.push(_memberConfig);
            BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoHelper.BANK)
            );
            DaoHelper.potentialNewMember(
                _memberConfig.memberAddress,
                dao,
                bank
            );
            bank.addToBalance(
                dao,
                _memberConfig.memberAddress,
                DaoHelper.UNITS,
                _memberConfig.initialAmount
            );
        }else{
            memberConfig[memberIndex[_memberConfig.memberAddress]-1] = _memberConfig;
        } 
    }

    function setMemberAppreciationRight(
        DaoRegistry dao,
        address _memberAddress,
        bool appreciationRight
    ) external hasExtensionAccess(dao, AclFlag.SET_MEMBER) {
        require(memberIndex[_memberAddress]>0, "memberExt::member not set");
        Foundance.MemberConfig storage member = memberConfig[memberIndex[_memberAddress]-1];
        member.appreciationRight = appreciationRight;
    }

    //REMOVE
    function removeMember(
        DaoRegistry dao,
        address _memberAddress
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_MEMBER) {
        require(memberIndex[_memberAddress]>0, "memberExt::member not set");
        memberIndex[_memberAddress]==0;
    }

    //GET
    function getIsMember(
        address _memberAddress
    ) external view returns (bool) {
        return memberConfig[memberIndex[_memberAddress]-1].memberAddress==address(0) ? true : false;
    }

    function getMemberConfig(
        address _memberAddress
    ) external view returns (Foundance.MemberConfig memory) {
        return memberConfig[memberIndex[_memberAddress]-1];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/IExtension.sol";
import "../../helpers/DaoHelper.sol";

contract DynamicEquityExtension is IExtension {

    enum AclFlag {
        SET_DYNAMIC_EQUITY,
        REMOVE_DYNAMIC_EQUITY,
        ACT_DYNAMIC_EQUITY
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "dynamicEquityExt::accessDenied"
        );
        _;
    }

    Foundance.EpochConfig public epochConfig;
    Foundance.DynamicEquityConfig public dynamicEquityConfig;
    mapping(uint256 => mapping(address => Foundance.DynamicEquityMemberConfig)) public dynamicEquityEpochs;
    Foundance.DynamicEquityMemberConfig[] public dynamicEquityMemberConfig;
    mapping(address => uint) public dynamicEquityMemberIndex;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "dynamicEquityExt::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET 
    function setDynamicEquity(
        DaoRegistry dao,
        Foundance.DynamicEquityConfig calldata config,
        Foundance.EpochConfig calldata _epochConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        dynamicEquityConfig = config;
        epochConfig = _epochConfig;
        epochConfig.epochLast = epochConfig.epochStart;
    }

    function setDynamicEquityEpoch(
        DaoRegistry dao,
        uint256 newEpochLast
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(epochConfig.epochLast<block.timestamp,"dynamicEquityExt::epoch not in past");
        require(epochConfig.epochLast>newEpochLast,"dynamicEquityExt::epoch not incremental to previous one");
        epochConfig.epochLast = newEpochLast;
    }



    function setDynamicEquityMember(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig calldata config
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(config.memberAddress!=address(0), "memberAddress not set");
        uint length = dynamicEquityMemberConfig.length;
        if(dynamicEquityMemberIndex[config.memberAddress]==0){
            dynamicEquityMemberIndex[config.memberAddress]=length+1;
            dynamicEquityMemberConfig.push(config);
        }else{
            dynamicEquityMemberConfig[dynamicEquityMemberIndex[config.memberAddress]-1] = config;
        } 
    }

    function setDynamicEquityMemberBatch(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig[] calldata config
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        uint length = dynamicEquityMemberConfig.length;
        for(uint256 i=0;i<config.length;i++){
            if(config[i].memberAddress==address(0)){
                continue;
            }
            if(dynamicEquityMemberIndex[config[i].memberAddress]==0){
                dynamicEquityMemberIndex[config[i].memberAddress]=length+1;
                dynamicEquityMemberConfig.push(config[i]);
            }else{
                dynamicEquityMemberConfig[dynamicEquityMemberIndex[config[i].memberAddress]-1] = config[i];
            } 
        }
    }

    function setDynamicEquityMemberSuspend(
        DaoRegistry dao,
        address _member,
        uint256 suspendedUntil
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(dynamicEquityMemberIndex[_member]>0, "dynamicEquityExt::member not set");
        dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1].suspendedUntil = suspendedUntil;
    }

    function setDynamicEquityMemberEpoch(
        DaoRegistry dao,
        Foundance.DynamicEquityMemberConfig calldata config
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(dynamicEquityMemberIndex[config.memberAddress]>0,"dynamicEquityExt::member not set");
        require(config.expense<dynamicEquityMemberConfig[dynamicEquityMemberIndex[config.memberAddress]-1].expenseThreshold,"dynamicEquityExt::expense surpassed expenseThreshold");
        require(config.availability<dynamicEquityMemberConfig[dynamicEquityMemberIndex[config.memberAddress]-1].availabilityThreshold,"dynamicEquityExt::availability surpassed availabilityThreshold");
        require(config.salaryMarket<dynamicEquityMemberConfig[dynamicEquityMemberIndex[config.memberAddress]-1].salaryThreshold,"dynamicEquityExt::salaryMarket surpassed salaryThreshold");
        dynamicEquityEpochs[epochConfig.epochLast+epochConfig.epochDuration][config.memberAddress] = config;
    }

    function setDynamicEquityMemberEpochExpense(
        DaoRegistry dao,
        address memberAddress,
        uint256 value
    ) external hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) {
        require(dynamicEquityMemberIndex[memberAddress]>0,"dynamicEquityExt::member not set");
        dynamicEquityEpochs[epochConfig.epochLast+epochConfig.epochDuration][memberAddress].expenseAdhoc = value;
        dynamicEquityEpochs[epochConfig.epochLast+epochConfig.epochDuration][memberAddress].memberAddress = memberAddress;
    }

    //REMOVE
    function removeDynamicEquityMemberEpoch(
        DaoRegistry dao,
        address _member
    ) external hasExtensionAccess(dao, AclFlag.REMOVE_DYNAMIC_EQUITY) {
        require(dynamicEquityMemberIndex[_member]>0,"dynamicEquityExt::member not set");
        Foundance.DynamicEquityMemberConfig storage _config = dynamicEquityEpochs[epochConfig.epochLast+epochConfig.epochDuration][_member];
        _config.memberAddress = address(0);
    }
    function removeDynamicEquityMember(
        DaoRegistry dao,
        address _member
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_DYNAMIC_EQUITY) {
        require(dynamicEquityMemberIndex[_member]>0, "dynamicEquityExt::member not set");
        dynamicEquityMemberIndex[_member]==0;
    }

    //GET_INTERNAL
    function getDynamicEquityMemberEpochAmountInternal(
        Foundance.DynamicEquityMemberConfig memory dynamicEquityMemberEpochConfig
    ) internal view returns (uint) {
        uint precisionFactor = 10**Foundance.FOUNDANCE_PRECISION;
        uint availabilityFactor = (dynamicEquityMemberEpochConfig.availability*precisionFactor/Foundance.FOUNDANCE_WORKDAYS_WEEK/Foundance.FOUNDANCE_MONTHS_YEAR);
        availabilityFactor *= 10**Foundance.FOUNDANCE_WEEKS_MONTH_PRECISION/Foundance.FOUNDANCE_WEEKS_MONTH;
        uint salaryEpoch = (dynamicEquityMemberEpochConfig.salary*availabilityFactor)/precisionFactor;
        uint salaryMarketEpoch = (dynamicEquityMemberEpochConfig.salaryMarket*availabilityFactor)/precisionFactor;
        uint timeEquity = 0;
        if(dynamicEquityMemberEpochConfig.salaryMarket>dynamicEquityMemberEpochConfig.salary){
            timeEquity = (( salaryMarketEpoch - salaryEpoch) * dynamicEquityConfig.timeMultiplier / 10**Foundance.FOUNDANCE_PRECISION );
        }
        uint riskEquity = ( (dynamicEquityMemberEpochConfig.expense+dynamicEquityMemberEpochConfig.expenseAdhoc) * dynamicEquityConfig.riskMultiplier / 10**Foundance.FOUNDANCE_PRECISION);
        return timeEquity + riskEquity;
    }

    //GET
    function getDynamicEquityMemberEpochAmount(
        address _member
    ) external view returns (uint) {
        Foundance.DynamicEquityMemberConfig memory _epochMemberConfig = dynamicEquityEpochs[epochConfig.epochLast][_member];
        if(_epochMemberConfig.memberAddress != address(0)){
            return getDynamicEquityMemberEpochAmountInternal(
                _epochMemberConfig
            );
        }else{
            return getDynamicEquityMemberEpochAmountInternal(
                dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1]
            );
        }
    }

    function getDynamicEquityMemberEpoch(
        address _member
    ) external view returns (Foundance.DynamicEquityMemberConfig memory) {
        return dynamicEquityEpochs[epochConfig.epochLast][_member];
    }

    function getDynamicEquityMemberEpoch(
        address _member,
        uint256 timestamp
    ) external view returns (Foundance.DynamicEquityMemberConfig memory) {
        return dynamicEquityEpochs[timestamp][_member];
    }

    function getEpochConfig(
    ) public view returns (Foundance.EpochConfig memory) {
        return epochConfig;
    }

    function getDynamicEquityConfig(
    ) public view returns (Foundance.DynamicEquityConfig memory) {
        return dynamicEquityConfig;
    }

    function getDynamicEquityMemberConfig(
    ) external view returns (Foundance.DynamicEquityMemberConfig[] memory) {
        return dynamicEquityMemberConfig;
    }

    function getDynamicEquityMemberConfig(
        address _member
    ) external view returns (Foundance.DynamicEquityMemberConfig memory) {
        return dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1];
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/IExtension.sol";
import "../../helpers/DaoHelper.sol";

contract VestedEquityExtension is IExtension {

    enum AclFlag {
        SET_VESTED_EQUITY,
        REMOVE_VESTED_EQUITY,
        ACT_VESTED_EQUITY
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "vestedEquityExt::accessDenied"
        );
        _;
    }

    Foundance.VestedEquityMemberConfig[] public vestedEquityMemberConfig;
    mapping(address => uint) public vestedEquityMemberIndex;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "vestedEquityExt::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET
    function setVestedEquityMember(
        DaoRegistry dao,
        Foundance.VestedEquityMemberConfig calldata config
    ) external hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) {
        require(config.memberAddress!=address(0), "memberAddress not set");
        uint length = vestedEquityMemberConfig.length;
        if(vestedEquityMemberIndex[config.memberAddress]==0){
            vestedEquityMemberIndex[config.memberAddress]=length+1;
            vestedEquityMemberConfig.push(config);
        }else{
            vestedEquityMemberConfig[vestedEquityMemberIndex[config.memberAddress]-1] = config;
        } 
    }

    function setVestedEquityMemberBatch(
        DaoRegistry dao,
        Foundance.VestedEquityMemberConfig[] calldata config
    ) external hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) {
        for(uint256 i=0;i<config.length;i++){
            if(config[i].memberAddress==address(0)){
                continue;
            }
            uint length = vestedEquityMemberConfig.length;
            if(vestedEquityMemberIndex[config[i].memberAddress]==0){
                vestedEquityMemberIndex[config[i].memberAddress]=length+1;
                vestedEquityMemberConfig.push(config[i]);
            }else{
                vestedEquityMemberConfig[vestedEquityMemberIndex[config[i].memberAddress]-1] = config[i];
            } 
        }
    }

    //REMOVE
    function removeVestedEquityMember(
        DaoRegistry dao,
        address _member
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_VESTED_EQUITY) {
        require(vestedEquityMemberIndex[_member]>0, "vestedEquityExt::member not set");
        vestedEquityMemberIndex[_member]==0;
    }

    function removeVestedEquityMemberAmount(
        DaoRegistry dao,
        address _member
    ) external hasExtensionAccess(dao, AclFlag.REMOVE_VESTED_EQUITY) {
        uint blockTimestamp = block.timestamp;
        Foundance.VestedEquityMemberConfig storage _vestedEquityMemberConfig = vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
        require(blockTimestamp > _vestedEquityMemberConfig.start + _vestedEquityMemberConfig.cliff ,"vestedEquityExt::cliff not yet exceeded");
        _vestedEquityMemberConfig.tokenAmount -= getVestedEquityMemberDistributionAmountInternal(_member);
        _vestedEquityMemberConfig.start = blockTimestamp;
        _vestedEquityMemberConfig.cliff = blockTimestamp;
        uint prolongedDuration = blockTimestamp - _vestedEquityMemberConfig.start;
        _vestedEquityMemberConfig.duration -= prolongedDuration;
    }

    //GET_INTERNAL
    function getVestedEquityMemberDistributionAmountInternal(
        address _member
    ) internal view returns (uint) {
        Foundance.VestedEquityMemberConfig storage _vestedEquityMemberConfig = vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
        uint amount = 0;
        uint256 blockTimestamp = block.timestamp;
        if(blockTimestamp > _vestedEquityMemberConfig.start + _vestedEquityMemberConfig.cliff){
            if(_vestedEquityMemberConfig.start + _vestedEquityMemberConfig.duration < blockTimestamp){
                uint prolongedDuration = blockTimestamp-_vestedEquityMemberConfig.start;
                uint toBeDistributed = (prolongedDuration / _vestedEquityMemberConfig.duration) * _vestedEquityMemberConfig.tokenAmount;
                return toBeDistributed;
            }else{
                return _vestedEquityMemberConfig.tokenAmount;
            }
        }
        return amount;
    }

    //GET
    function getVestedEquityMemberConfig(
    ) external view returns (Foundance.VestedEquityMemberConfig[] memory) {
        return vestedEquityMemberConfig;
    }

    function getVestedEquityMemberConfig(
        address _member
    ) external view returns (Foundance.VestedEquityMemberConfig memory) {
        return vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
    }

    function getVestedEquityMemberAmount(
        address _member
    ) external view returns (uint) {
        return vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1].tokenAmount;
    }

    function getVestedEquityMemberDistributionAmount(
        address _member
    ) external view returns (uint) {
        return getVestedEquityMemberDistributionAmountInternal(_member);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";
import "../../extensions/IExtension.sol";
import "../../helpers/DaoHelper.sol";

contract CommunityIncentiveExtension is IExtension {

    enum AclFlag {
        SET_COMMUNITY_INCENTIVE,
        REMOVE_COMMUNITY_INCENTIVE,
        ACT_COMMUNITY_INCENTIVE
    }

    bool public initialized;

    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "communityIncentive::accessDenied"
        );
        _;
    }

    Foundance.EpochConfig public epochConfig;
    Foundance.CommunityIncentiveConfig public communityIncentiveConfig;
    Foundance.CommunityIncentiveMemberConfig[] public communityIncentiveMemberConfig;
    mapping(address => uint) public communityIncentiveMemberIndex;

    constructor() {}
    
    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "communityIncentive::already initialized");
        initialized = true;
        _dao = dao;
    }

    //SET
    function setCommunityIncentive(
        DaoRegistry dao,
        Foundance.CommunityIncentiveConfig calldata _communityIncentiveConfig 
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_INCENTIVE) {
        communityIncentiveConfig = _communityIncentiveConfig;
    }

    function setCommunityIncentive(
        DaoRegistry dao,
        Foundance.CommunityIncentiveConfig calldata _communityIncentiveConfig, 
        Foundance.EpochConfig calldata _epochConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_INCENTIVE) {
        communityIncentiveConfig = _communityIncentiveConfig;
        epochConfig = _epochConfig;
        epochConfig.epochLast = epochConfig.epochStart;
    }

    function setCommunityIncentiveEpoch(
        DaoRegistry dao
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_INCENTIVE) {
        require(
            communityIncentiveConfig.allocationType==Foundance.AllocationType.EPOCH,
            "communityIncentiveExt::AllocationType has to be EPOCH"
        );
        //TODO replenish tokenAmount
        //TODO update epoch
    }

    function setCommunityIncentiveMember(
        DaoRegistry dao,
        Foundance.CommunityIncentiveMemberConfig calldata _communityIncentiveMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_INCENTIVE) {
        require(
            _communityIncentiveMemberConfig.memberAddress!=address(0),
            "communityIncentiveExt::memberAddress not set"
        );
        uint length = communityIncentiveMemberConfig.length;
        if(communityIncentiveMemberIndex[_communityIncentiveMemberConfig.memberAddress]==0){
            communityIncentiveMemberIndex[_communityIncentiveMemberConfig.memberAddress]=length+1;
            communityIncentiveMemberConfig.push(_communityIncentiveMemberConfig);
        }else{
            communityIncentiveMemberConfig[communityIncentiveMemberIndex[_communityIncentiveMemberConfig.memberAddress]-1] = _communityIncentiveMemberConfig;
        } 
    }

    function setCommunityIncentiveMemberBatch(
        DaoRegistry dao,
        Foundance.CommunityIncentiveMemberConfig[] calldata _communityIncentiveMemberConfig
    ) external hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_INCENTIVE) {
        for(uint256 i=0;i<_communityIncentiveMemberConfig.length;i++){
            if(_communityIncentiveMemberConfig[i].memberAddress==address(0)){
                continue;
            }
            uint length = communityIncentiveMemberConfig.length;
            if(communityIncentiveMemberIndex[_communityIncentiveMemberConfig[i].memberAddress]==0){
                communityIncentiveMemberIndex[_communityIncentiveMemberConfig[i].memberAddress]=length+1;
                communityIncentiveMemberConfig.push(_communityIncentiveMemberConfig[i]);
            }else{
                communityIncentiveMemberConfig[communityIncentiveMemberIndex[_communityIncentiveMemberConfig[i].memberAddress]-1] = _communityIncentiveMemberConfig[i];
            } 
        }
    }

    //REMOVE
    function removeCommunityIncentive(
        DaoRegistry dao
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_COMMUNITY_INCENTIVE) {
        //TODO remove config
        //TODO remove epoch
        //TODO remove configMemberIndex//allmember
    }

    function removeCommunityIncentiveMember(
        DaoRegistry dao,
        address _member
    ) external view hasExtensionAccess(dao, AclFlag.REMOVE_COMMUNITY_INCENTIVE) {
        require(communityIncentiveMemberIndex[_member]>0, "communityIncentive::member not set");
        communityIncentiveMemberIndex[_member]==0;
    }
    
    //GET
    function getCommunityIncentiveEpochConfig(
    ) public view returns (Foundance.EpochConfig memory) {
        return epochConfig;
    }

    function getCommunityIncentiveConfig(
    ) public view returns (Foundance.CommunityIncentiveConfig memory) {
        return communityIncentiveConfig;
    }

    function getCommunityIncentiveMemberConfig(
    ) external view returns (Foundance.CommunityIncentiveMemberConfig[] memory) {
        return communityIncentiveMemberConfig;
    }

    function getIsCommunityIncentiveMember(
        address _memberAddress
    ) external view returns (bool) {
        return communityIncentiveMemberConfig[communityIncentiveMemberIndex[_memberAddress]-1].memberAddress==address(0) ? true : false;
    }

    function getCommunityIncentiveMemberConfig(
        address _member
    ) external view returns (Foundance.CommunityIncentiveMemberConfig memory) {
        return communityIncentiveMemberConfig[communityIncentiveMemberIndex[_member]-1];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";
import "../../companion/interfaces/IReimbursement.sol";
import "./ReimbursableLib.sol";

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract Reimbursable {
    struct ReimbursementData {
        uint256 gasStart; // how much gas is left before executing anything
        bool shouldReimburse; // should the transaction be reimbursed or not ?
        uint256 spendLimitPeriod; // how long (in seconds) is the spend limit period
        IReimbursement reimbursement; // which adapter address is used for reimbursement
    }

    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier reimbursable(DaoRegistry dao) {
        ReimbursementData memory data = ReimbursableLib.beforeExecution(dao);
        _;
        ReimbursableLib.afterExecution(dao, data);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

abstract contract Signatures {
    string public constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,address actionId)";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712_DOMAIN));

    function hashMessage(
        DaoRegistry dao,
        address actionId,
        bytes32 message
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator(dao, actionId),
                    message
                )
            );
    }

    function domainSeparator(DaoRegistry dao, address actionId)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("Snapshot Message"), // string name
                    keccak256("4"), // string version
                    block.chainid, // uint256 chainId
                    address(dao), // address verifyingContract,
                    actionId
                )
            );
    }

    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes memory sig
    ) external view returns (bool) {
        return SignatureChecker.isValidSignatureNow(signer, hash, sig);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoRegistry.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IReimbursement {
    function reimburseTransaction(
        DaoRegistry dao,
        address payable caller,
        uint256 gasUsage,
        uint256 spendLimitPeriod
    ) external;

    function shouldReimburse(DaoRegistry dao, uint256 gasLeft)
        external
        view
        returns (bool, uint256);
}

pragma solidity ^0.8.0;

import "../../core/DaoRegistry.sol";
import "../../companion/interfaces/IReimbursement.sol";
import "./Reimbursable.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2021 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
library ReimbursableLib {
    function beforeExecution(DaoRegistry dao)
        internal
        returns (Reimbursable.ReimbursementData memory data)
    {
        data.gasStart = gasleft();
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        address reimbursementAdapter = dao.adapters(DaoHelper.REIMBURSEMENT);
        if (reimbursementAdapter == address(0x0)) {
            data.shouldReimburse = false;
        } else {
            data.reimbursement = IReimbursement(reimbursementAdapter);

            (bool shouldReimburse, uint256 spendLimitPeriod) = data
                .reimbursement
                .shouldReimburse(dao, data.gasStart);

            data.shouldReimburse = shouldReimburse;
            data.spendLimitPeriod = spendLimitPeriod;
        }
    }

    function afterExecution(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data
    ) internal {
        afterExecution2(dao, data, payable(msg.sender));
    }

    function afterExecution2(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data,
        address payable caller
    ) internal {
        if (data.shouldReimburse) {
            data.reimbursement.reimburseTransaction(
                dao,
                caller,
                data.gasStart - gasleft(),
                data.spendLimitPeriod
            );
        }
        dao.unlockSession();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../../libraries/Foundance.sol";
import "../../../core/DaoRegistry.sol";

interface IVotingAdapter {
    enum VotingState {
        NOT_STARTED,
        TIE,
        PASS,
        NOT_PASS,
        IN_PROGRESS,
        GRACE_PERIOD,
        DISPUTE_PERIOD
    }

    function getAdapterName() external pure returns (string memory);

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) external;

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.VotingType
    ) external;
    
    function getSenderAddress(
        DaoRegistry dao,
        address actionId,
        bytes memory data,
        address sender
    ) external returns (address);

    function voteResult(
        DaoRegistry dao, 
        bytes32 proposalId
    ) external returns (VotingState state);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../helpers/DaoHelper.sol";
import "../core/DaoRegistry.sol";
import "../extensions/bank/Bank.sol";
import "../extensions/token/erc20/ERC20TokenExtension.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
library GovernanceHelper {
    string public constant ROLE_PREFIX = "governance.role.";
    bytes32 public constant DEFAULT_GOV_TOKEN_CFG =
        keccak256(abi.encodePacked(ROLE_PREFIX, "default"));

    /*
     * @dev Checks if the member address holds enough funds to be considered a governor.
     * @param dao The DAO Address.
     * @param memberAddr The message sender to be verified as governor.
     * @param proposalId The proposal id to retrieve the governance token address if configured.
     * @param snapshot The snapshot id to check the balance of the governance token for that member configured.
     */
    function getVotingWeight(
        DaoRegistry dao,
        address voterAddr,
        bytes32 proposalId,
        uint256 snapshot
    ) internal view returns (uint256) {
        (address adapterAddress, ) = dao.proposals(proposalId);

        // 1st - if there is any governance token configuration
        // for the adapter address, then read the voting weight based on that token.
        address governanceToken = dao.getAddressConfiguration(
            keccak256(abi.encodePacked(ROLE_PREFIX, adapterAddress))
        );
        if (DaoHelper.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 2nd - if there is no governance token configured for the adapter,
        // then check if exists a default governance token.
        // If so, then read the voting weight based on that token.
        governanceToken = dao.getAddressConfiguration(DEFAULT_GOV_TOKEN_CFG);
        if (DaoHelper.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 3rd - if none of the previous options are available, assume the
        // governance token is UNITS, then read the voting weight based on that token.
        return
            BankExtension(dao.getExtensionAddress(DaoHelper.BANK))
                .getPriorAmount(voterAddr, DaoHelper.UNITS, snapshot);
    }

    function getVotingWeight(
        DaoRegistry dao,
        address governanceToken,
        address voterAddr,
        uint256 snapshot
    ) internal view returns (uint256) {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoHelper.BANK)
        );
        if (bank.isInternalToken(governanceToken)) {
            return bank.getPriorAmount(voterAddr, governanceToken, snapshot);
        }

        // The external token must implement the getPriorAmount function,
        // otherwise this call will fail and revert the voting process.
        // The actual revert does not show a clear reason, so we catch the error
        // and revert with a better error message.
        // slither-disable-next-line unused-return
        try
            ERC20Extension(governanceToken).getPriorAmount(voterAddr, snapshot)
        returns (
            // slither-disable-next-line uninitialized-local,variable-scope
            uint256 votingWeight
        ) {
            return votingWeight;
        } catch {
            revert("getPriorAmount not implemented");
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../../libraries/Foundance.sol";
import "../../../core/DaoRegistry.sol";
import "../../../helpers/DaoHelper.sol";
import "../interfaces/IVotingAdapter.sol";


library LVoting {
    
    //SUBMIT
    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data
    ) internal {
        dao.submitProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(
            dao.getAdapterAddress(DaoHelper.VOTING_ADAPT)
        );
        address submittedBy = votingAdapter.getSenderAddress(
            dao,
            address(this),
            data,
            msg.sender
        );
        dao.sponsorProposal(proposalId, submittedBy, address(votingAdapter));
        votingAdapter.startNewVotingForProposal(dao, proposalId, data);
    }

    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        Foundance.VotingType votingType
    ) internal {
        dao.submitProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(
            dao.getAdapterAddress(DaoHelper.VOTING_ADAPT)
        );
        address submittedBy = votingAdapter.getSenderAddress(
            dao,
            address(this),
            data,
            msg.sender
        );
        dao.sponsorProposal(proposalId, submittedBy, address(votingAdapter));
        votingAdapter.startNewVotingForProposal(dao, proposalId, data, votingType);
    }

    //PROCESS
    function _processProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) internal returns (Foundance.ProposalStatus){
        dao.processProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(dao.votingAdapter(proposalId));
        require(address(votingAdapter) != address(0), "votingAdpt::adapter not found");
        IVotingAdapter.VotingState voteResult = votingAdapter.voteResult(
            dao,
            proposalId
        );
        if (voteResult == IVotingAdapter.VotingState.PASS) {
            return Foundance.ProposalStatus.IN_PROGRESS;
        } else if (voteResult == IVotingAdapter.VotingState.NOT_PASS || voteResult == IVotingAdapter.VotingState.TIE) {
            return Foundance.ProposalStatus.FAILED;
        }else{
            return Foundance.ProposalStatus.NOT_STARTED;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../../libraries/Foundance.sol";
import "../../../core/DaoRegistry.sol";

interface IMemberAdapter {

    //SUBMIT
    function submitSetMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.MemberConfig memory _memberConfig
    ) external;

    function submitSetMemberSetupProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.MemberConfig memory _memberConfig,
        Foundance.DynamicEquityMemberConfig memory _dynamicEquityMemberConfig,
        Foundance.VestedEquityMemberConfig memory _vestedEquityMemberConfig,
        Foundance.CommunityIncentiveMemberConfig memory _communityIncentiveMemberConfig
    ) external;

    function submitRemoveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external;
    
    //PROCESS
    function processSetMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetMemberSetupProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveMemberProposal(DaoRegistry dao, bytes32 proposalId, bytes calldata data, bytes32 newProposalId) external;

    function processRemoveMemberBadLeaverProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveMemberResigneeProposal(DaoRegistry dao, bytes32 proposalId) external;

    //ACT
    function actMemberResign(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../../libraries/Foundance.sol";
import "../../../core/DaoRegistry.sol";

interface IDynamicEquity {

    //SUBMIT
    function submitSetDynamicEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityConfig calldata _dynamicEquityConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external;

    function submitSetDynamicEquityEpochProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        uint256 _lastEpoch
    ) external;

    function submitSetDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external;

    function submitSetDynamicEquityMemberSuspendProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress,
        uint256 _suspendUntil
    ) external;

    function submitSetDynamicEquityMemberEpochProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig
    ) external;

    function submitSetDynamicEquityMemberEpochExpenseProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress,
        uint256 _expenseAmount
    ) external;

    function submitRemoveDynamicEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress
    ) external;

    function submitRemoveDynamicEquityMemberEpochProposal( 
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress
    ) external;

    //PROCESS
    function processSetDynamicEquityProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityEpochProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityMemberSuspendProposal(DaoRegistry dao, bytes32 proposalId) external;
    
    function processSetDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetDynamicEquityMemberEpochExpenseProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveDynamicEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveDynamicEquityMemberEpochProposal(DaoRegistry dao, bytes32 proposalId) external;

    //ACT
    function actDynamicEquityEpochDistributed(
        DaoRegistry dao
    ) external; 
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
library FairShareHelper {
    /**
     * @notice calculates the fair unit amount based the total units and current balance.
     */
    function calc(
        uint256 balance,
        uint256 units,
        uint256 totalUnits
    ) internal pure returns (uint256) {
        require(totalUnits > 0, "totalUnits must be greater than 0");
        require(
            units <= totalUnits,
            "units must be less than or equal to totalUnits"
        );
        if (balance == 0) {
            return 0;
        }
        // The balance for Internal and External tokens are limited to 2^64-1 (see Bank.sol:L411-L421)
        // The maximum number of units is limited to 2^64-1 (see ...)
        // Worst case cenario is: balance=2^64-1 * units=2^64-1, no overflows.
        uint256 prod = balance * units;
        return prod / totalUnits;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../../libraries/Foundance.sol";
import "../../../core/DaoRegistry.sol";

interface IVestedEquity {

    //SUBMIT
    function submitSetVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) external;
    
    function submitRemoveVestedEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAdress
    ) external;

    //PROCESS
    function processSetVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveVestedEquityMemberProposal(DaoRegistry dao, bytes32 proposalId) external;
    
    //ACT
    function actVestedEquityMemberDistributed(
        DaoRegistry dao,
        address _memberAddress
    ) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../../libraries/Foundance.sol";
import "../../../core/DaoRegistry.sol";

interface ICommunityIncentive {

    //SUBMIT
    function submitSetCommunityIncentiveProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityIncentiveConfig calldata _communityIncentiveConfig,
        Foundance.EpochConfig calldata _epochConfig
    ) external;

    function submitSetCommunityIncentiveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        Foundance.CommunityIncentiveMemberConfig calldata _communityIncentiveMemberConfig
    ) external;

    function submitRemoveCommunityIncentiveProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) external;

    function submitRemoveCommunityIncentiveMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        address _memberAddress
    ) external;
        
    //PROCESS
    function processSetCommunityIncentiveProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processSetCommunityIncentiveMemberProposal(DaoRegistry dao, bytes32 proposalId) external;

    function processRemoveCommunityIncentiveProposal(DaoRegistry dao, bytes32 proposalId) external; 

    function processRemoveCommunityIncentiveMemberProposal(DaoRegistry dao, bytes32 proposalId) external;  

    //ACT
    function actCommunityIncentiveMemberDistributed(
        DaoRegistry dao,
        address _memberAddress,
        uint256 _amountToBeSent,
        bytes32 _distributionId 
    ) external;

    function actCommunityIncentiveEpochDistributed(
        DaoRegistry dao
    ) external;  
}