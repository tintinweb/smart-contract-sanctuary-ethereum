pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {FoundanceLibrary} from "../helpers/FoundanceLibrary.sol";
import "./DaoFactory.sol";
import "./DaoRegistry.sol";
import '../extensions/IExtension.sol';
import "../extensions/bank/BankFactory.sol";
import "../extensions/executor/ExecutorFactory.sol";
import "../extensions/nft/NFTCollectionFactory.sol";
import "../extensions/erc1155/ERC1155TokenExtensionFactory.sol";
import "../extensions/erc1271/ERC1271Factory.sol";
import "../extensions/token/erc20/ERC20TokenExtensionFactory.sol";
import "../extensions/token/erc20/InternalTokenVestingExtensionFactory.sol";
//import "../extensions/foundance/DynamicEquityExtensionFactory.sol";
import "../helpers/DaoHelper.sol";        

        //TODO: FoundanceFactory.sol
          //TODO: create governance roles
          //TODO: configure adapters
          //TODO: configure extension
          //TODO: Register all member
          //TODO: ERC20Extension address
          //TODO: distribute all initial Tokens for each member
          //TODO: setup foundance_vesting for all member
          //TODO: setup foundance_dynamicEquity for all member

        //TODO: DynamicEquityExtension.sol
          //TODO: DataStructure
        //TODO: DynamicEquityAdapter.sol
          //TODO: Voting Report

        //TODO: foundancefactory.test.js
        //TODO: dynamicEquity.test.js
        //TODO: dynamicEquityFactory.test.js
        //TODO: dynamicEquityAdapter.test.js

        //TODO: foundanceDeployment.js

        //TODO: (hardhat)
        //TODO: (polygon)
        //TODO: (avalanche)
        //TODO: (provide ACL id map for deployment)
        //TODO: (make foundanceFactory proxy)
        //TODO: (voting settings, quadratic, 1by1, linear)
        //TODO: (configure offchain voting)
        

contract FoundanceFactory{
    address daoFactoryAddress = 0x18EA160f95510af49473F60b99a95509688a13A9;
    address bankFactoryAddress = 0xAA9c440357B0fb441b498c1C5028Cc428abD3cC7;
    address erc20TokenExtensionFactoryAddress = 0x252778dCE92C5E2Cd085dCB067aaDEdAd5f95954;
    address erc1155TokenCollectionFactoryAddress = 0xa9A41180488FB4E9C95A8E239283643fF4E7A033;
    address erc1271ExtensionFactoryAddress = 0x4e6B44EaA0B0B5157b2D94F3aeaba2da21333e6e;
    address nftCollectionFactoryAddress = 0x11519997d9452f510DE67c3A97e76F787df53f52;
    address executorExtensionFactoryAddress = 0x73917D1bfB83671AE2EE8832D0a938BD5Ac0DC6a;
    address internalTokenVestingExtensionFactoryAddress = 0x14d09251d470501F1584d00BeD6984646f0fE7c0;
    //address dynamicEquityExtensionAddress = ;
    DaoFactory daoFactory; 
    BankFactory bankFactory;
    ERC20TokenExtensionFactory erc20TokenExtensionFactory;
    ERC1155TokenCollectionFactory erc1155TokenCollectionFactory;
    ERC1271ExtensionFactory erc1271ExtensionFactory;
    NFTCollectionFactory nftCollectionFactory;
    ExecutorExtensionFactory executorExtensionFactory;
    InternalTokenVestingExtensionFactory internalTokenVestingExtensionFactory;
    //DynamicEquityExtensionFactory dynamicEquityExtensionFactory;
    constructor() {
        daoFactory = DaoFactory(daoFactoryAddress);
        bankFactory = BankFactory(bankFactoryAddress);
        erc20TokenExtensionFactory = ERC20TokenExtensionFactory(erc20TokenExtensionFactory);
        erc1155TokenCollectionFactory = ERC1155TokenCollectionFactory(erc1155TokenCollectionFactoryAddress);
        erc1271ExtensionFactory = ERC1271ExtensionFactory(erc1271ExtensionFactoryAddress);
        nftCollectionFactory = NFTCollectionFactory(nftCollectionFactoryAddress);
        executorExtensionFactory = ExecutorExtensionFactory(executorExtensionFactoryAddress);
        internalTokenVestingExtensionFactory = InternalTokenVestingExtensionFactory(internalTokenVestingExtensionFactoryAddress);
        //dynamicEquityExtensionFactory = DynamicEquityExtensionFactory(dynamicEquityExtensionAddress);
    }
    /**
     * @notice Event emitted when a new Foundance-Agreement has been registered/approved
     * @param  _address address of interacting member
     * @param  _name name of Foundance-Agreement
     */
		event FoundanceRegistered(address _address, string _name);
    event FoundanceApproved(address _address, string _name);
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
     * @param  _daoAdress address of DaoRegistry
     * @param  _bankAdress address of BankExtension
     * @param  _erc1155TokenExtensionAddress address of ERC1155 Extension
     * @param  _erc1271ExtensionAddress address of ERC1271 Extension
     * @param  _executorExtensionAddress address of Executor Extension
     * @param  _nftExtensionAddress address of NFT Extension
     * @param  _erc20ExtensionAddress address of ERC20 Extension
     * @param  _internalTokenVestingExtensionAddress address of internalTokenVesting Extension
     * @param  _dynamicEquityExtensionAddress address of dynamicEquity Extension
     * @param  _name name of Foundance
     */
    event FoundanceLive(
      address _daoAdress,
      address _bankAdress,
      address _erc1155TokenExtensionAddress, 
      address _erc1271ExtensionAddress, 
      address _executorExtensionAddress,
      address _nftExtensionAddress,
      address _erc20ExtensionAddress ,
      address _internalTokenVestingExtensionAddress ,
      address _dynamicEquityExtensionAddress ,
      string _name
    );    

    mapping(string => FoundanceLibrary.Foundance) private registeredFoundance;

    modifier onlyCreator(string calldata foundanceName) {
        require(registeredFoundance[foundanceName].creatorAddress == msg.sender, "Only creatorAddress can access");
        _;
    }
    /**
     * @notice Register a Foundance Dao   
     * @dev The foundanceName must be unique and not previously registered.
     * @param foundanceName Name of the Dao
     * @param memberArray Member Array including all relevant data
     * @param dynamicEquityConfiguration Dynamic Equity Risk Multiplier
     * @param tokenConfiguration Dynamic Equity Time Multiplier
     **/ 
    function registerFoundance( 
      string calldata foundanceName,
      FoundanceLibrary.Member[] memory memberArray,
      FoundanceLibrary.DynamicEquityConfiguration calldata dynamicEquityConfiguration, 
      FoundanceLibrary.TokenConfiguration calldata tokenConfiguration
    ) external{
        require(daoFactory.getDaoAddress(foundanceName)==address(0x0),"Foundance-DAO with this name already created.");
        require(registeredFoundance[foundanceName].creatorAddress==address(0x0),"Foundance-Agreement with this name already registered.");
        FoundanceLibrary.Foundance storage foundance = registeredFoundance[foundanceName];
        foundance.creatorAddress = msg.sender;
        //foundance.memberArray = memberArray;
        for(uint256 i=0;i<memberArray.length;i++){
          foundance.memberIndex[memberArray[i].memberAddress]=i+1;
          foundance.memberArray[i] = memberArray[i];
        }
        foundance.dynamicEquityConfiguration = dynamicEquityConfiguration; 	
        foundance.tokenConfiguration = tokenConfiguration; 	
        foundance.foundanceStatus = FoundanceLibrary.FoundanceStatus.REGISTERED;
        emit FoundanceRegistered(msg.sender,foundanceName);
     }
    /**
    * @notice Member approves a registered Foundance-Agreement  
    * @param foundanceName Name of Foundance-DAO
    **/ 
    function approveFoundance(
      string calldata foundanceName
    ) external{
        FoundanceLibrary.Foundance storage foundance = registeredFoundance[foundanceName];
        require(foundanceMemberExists(foundance, msg.sender), "Member doesnt exists in this Foundance-Agreement.");
        foundance.memberArray[foundance.memberIndex[msg.sender]-1].foundanceApproved = true;
        emit FoundanceApproved(msg.sender,foundanceName);
    }
    /**
    * @notice Checks if the Foundance-Agreement is approved by all registered members.  
    * @param foundance Foundance
    **/ 
    function isFoundanceApproved(
      FoundanceLibrary.Foundance storage foundance
    ) internal returns(bool){
        for(uint256 i=0;i<foundance.memberArray.length;i++){
          if(!foundance.memberArray[i].foundanceApproved) return false;
        }
        return true;
    }
    /**
    * @notice Revokes approval for all members within a Foundance-Agreement
    * @param foundance Foundance
    **/ 
    function revokeApproval(FoundanceLibrary.Foundance storage foundance) internal returns(FoundanceLibrary.Foundance storage){
      for(uint256 i=0;i<foundance.memberArray.length;i++){
      	foundance.memberArray[i].foundanceApproved=false;
      }
      return foundance;
    }
    /**
    * @notice Create a Foundance-DAO based upon an already approved Foundance-Agreement 
    * @dev The Foundance-Agreement must be approved by all members
    * @dev This function must be accessed by the Foundance-Agreement creator
    * @param foundanceName Name of the Foundance-DAO
    * @param creatorAddress Address of the Foundance-DAO creator
    **/ 
    function createFoundance(
      string calldata foundanceName, 
      address creatorAddress
    ) external onlyCreator(foundanceName){
				FoundanceLibrary.Foundance storage foundance = registeredFoundance[foundanceName];    
    		require(isFoundanceApproved(foundance), "Foundance-Agreement is not approved by all members");
				foundance.foundanceStatus=FoundanceLibrary.FoundanceStatus.APPROVED;
        //create dao
        daoFactory.createDao(foundanceName, creatorAddress);    
        address daoAddress = daoFactory.getDaoAddress(foundanceName);
        DaoRegistry daoRegistry = DaoRegistry(daoAddress);
        //create extensions
        bankFactory.create(DaoRegistry(daoAddress),foundance.tokenConfiguration.maxExternalTokens);//(DaoRegistry dao, uint8 maxExternalTokens)
        erc1155TokenCollectionFactory.create(DaoRegistry(daoAddress));//(DaoRegistry dao)
        erc1271ExtensionFactory.create(DaoRegistry(daoAddress));//(DaoRegistry dao)
        executorExtensionFactory.create(DaoRegistry(daoAddress));//(DaoRegistry dao)
        nftCollectionFactory.create(DaoRegistry(daoAddress));//(DaoRegistry dao)
        erc20TokenExtensionFactory.create(DaoRegistry(daoAddress),foundanceName,foundance.tokenConfiguration.tokenAddress,foundance.tokenConfiguration.tokenSymbol,foundance.tokenConfiguration.decimals);//(DaoRegistry dao,string calldata tokenName,address tokenAddress,string calldata tokenSymbol,uint8 decimals)
        internalTokenVestingExtensionFactory.create(DaoRegistry(daoAddress));//(DaoRegistry dao)
        //dynamicEquityExtensionFactory.create(DaoRegistry(daoAddress));//(DaoRegistry dao)
        //get adresses
        address bankExtensionAddress = bankFactory.getExtensionAddress(daoAddress);
        address erc1155TokenExtensionAddress = erc1155TokenCollectionFactory.getExtensionAddress(daoAddress);
        address erc1271ExtensionAddress = erc1271ExtensionFactory.getExtensionAddress(daoAddress);
        address executorExtensionAddress = executorExtensionFactory.getExtensionAddress(daoAddress);
        address nftExtensionAddress = nftCollectionFactory.getExtensionAddress(daoAddress);
        address erc20TokenExtensionAddress = erc20TokenExtensionFactory.getExtensionAddress(daoAddress);
        address internalTokenVestingExtensionAddress = internalTokenVestingExtensionFactory.getExtensionAddress(daoAddress);
        //address dynamicEquityExtensionAddress = dynamicEquityExtensionFactory.getExtensionAddress(daoAddress);
        //enable extensions
        daoRegistry.addExtension(DaoHelper.BANK, IExtension(bankExtensionAddress));
        daoRegistry.addExtension(DaoHelper.ERC1155_EXT,IExtension(erc1155TokenExtensionAddress));
        daoRegistry.addExtension(DaoHelper.ERC1271,IExtension(erc1271ExtensionAddress));
        daoRegistry.addExtension(DaoHelper.EXECUTOR_EXT,IExtension(executorExtensionAddress));
        daoRegistry.addExtension(DaoHelper.NFT,IExtension(nftExtensionAddress));
        daoRegistry.addExtension(DaoHelper.ERC20_EXT,IExtension(erc20TokenExtensionAddress));
        daoRegistry.addExtension(DaoHelper.INTERNAL_TOKEN_VESTING_EXT,IExtension(internalTokenVestingExtensionAddress));
        //daoRegistry.addExtension(DaoHelper.DYNAMIC_EQUITY_EXT,IExtension(dynamicEquityExtensionAddress));

				//foundance.status=FoundanceStatus.LIVE;
        //emit FoundanceLive(daoAddress,bankExtensionAddress,erc1155TokenExtensionAddress,erc1271ExtensionAddress,executorExtensionAddress,nftExtensionAddress,erc20TokenExtensionAddress,internalTokenVestingExtensionAddress, foundanceName);
    }

    /**
    * @notice Checks if the member exists within the Foundance
    * @dev The Foundance must exist
    * @param foundance Foundance
    * @param _member Address of member
    **/ 
    function foundanceMemberExists(
      FoundanceLibrary.Foundance storage foundance, 
      address _member
    ) internal view returns(bool){
        require(foundance.creatorAddress!=address(0x0),"There is no foundance with this name");
        uint memberIndex = foundance.memberIndex[_member];
        if(memberIndex==0){
      	  return false;
        }
        return true;
    }
 
    //Member management for registered Foundance-Agreement

		function addMember(string calldata foundanceName, FoundanceLibrary.Member calldata _member) external onlyCreator(foundanceName){ 
    	FoundanceLibrary.Foundance storage foundance = registeredFoundance[foundanceName];      
      require(!foundanceMemberExists(foundance, _member.memberAddress), "Member already exists in this foundance"); 
      
      foundance.memberArray.push(_member);
      foundance.memberIndex[_member.memberAddress]=foundance.memberArray.length;
      revokeApproval(foundance);
    }
 
    function deleteMember(string calldata foundanceName, address _member) external onlyCreator(foundanceName){
    	FoundanceLibrary.Foundance storage foundance = registeredFoundance[foundanceName];   
      require(foundanceMemberExists(foundance, _member), "Member doesnt exists in this foundance");
      
      foundance.memberArray[foundance.memberIndex[_member]-1] = foundance.memberArray[foundance.memberArray.length-1];
      foundance.memberIndex[foundance.memberArray[foundance.memberArray.length-1].memberAddress] = foundance.memberIndex[_member];      
      foundance.memberIndex[_member]=0;
      foundance.memberArray.pop();
			revokeApproval(foundance);
    }
    
    function changeMember(string calldata foundanceName, FoundanceLibrary.Member calldata _member) external onlyCreator(foundanceName){
    	FoundanceLibrary.Foundance storage foundance = registeredFoundance[foundanceName];   
      require(foundanceMemberExists(foundance, _member.memberAddress), "Member doesnt exists in this foundance");
      
      foundance.memberArray[foundance.memberIndex[_member.memberAddress]-1] = _member;
      revokeApproval(foundance);
    }

    //view Functions

    function getFoundanceMembers(string calldata foundanceName) public view returns(FoundanceLibrary.Member[] memory _memberArray){
       return registeredFoundance[foundanceName].memberArray;       
    }


}

pragma solidity ^0.8.0;

library FoundanceLibrary {
    enum FoundanceStatus {
      REGISTERED,
      APPROVED,
      LIVE
    }
    
    struct Member {
        address memberAddress;
        uint initialTokenAmount;
        bool foundanceApproved;
        DynamicEquityMemberConfig dynamicEquityMemberConfig;
        VestingMemberConfig vestingMemberConfig;
    }
    struct DynamicEquityMemberConfig {
        bool active;
        uint availability;
        uint salary;
        uint marketSalary;
        uint expenses;
    }
    struct VestingMemberConfig {
        bool active;
        uint vestedTokenAmount;
        uint duration;
        uint cliff;
    }
    struct Foundance {
        address creatorAddress;
        Member[] memberArray;
        mapping(address => uint) memberIndex;
        DynamicEquityConfiguration dynamicEquityConfiguration;
        TokenConfiguration tokenConfiguration;
        FoundanceStatus foundanceStatus;
    }
    struct DynamicEquityConfiguration {
        uint riskMultiplier;
        uint timeMultiplier;
        uint multiplierPrecision;
        uint256 epochDuration;
        uint256 epochStart;
    }
    struct TokenConfiguration {
        address tokenAddress;
        string tokenName;
        string tokenSymbol;
        uint8 maxExternalTokens;
        uint8 decimals;
    }

    uint8 internal constant FOUNDANCE_TOKENS_GUILD_BANK = 100;
    uint8 internal constant FOUNDANCE_TOKEN_DECIMALS = 8;
    uint internal constant FOUNDANCE_WORKDAYS_WEEK= 5;
    uint internal constant FOUNDANCE_MONTHS_YEAR = 12;
    uint internal constant FOUNDANCE_WEEKS_MONTH = 434524;
    uint internal constant FOUNDANCE_WEEKS_MONTH_PRECISION = 5;
    uint internal constant FOUNDANCE_PRECISION = 5;
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
    // Adapters
    bytes32 internal constant VOTING = keccak256("voting");
    bytes32 internal constant ONBOARDING = keccak256("onboarding");
    bytes32 internal constant NONVOTING_ONBOARDING =
        keccak256("nonvoting-onboarding");
    bytes32 internal constant TRIBUTE = keccak256("tribute");
    bytes32 internal constant FINANCING = keccak256("financing");
    bytes32 internal constant MANAGING = keccak256("managing");
    bytes32 internal constant RAGEQUIT = keccak256("ragequit");
    bytes32 internal constant GUILDKICK = keccak256("guildkick");
    bytes32 internal constant CONFIGURATION = keccak256("configuration");
    bytes32 internal constant DISTRIBUTE = keccak256("distribute");
    bytes32 internal constant DYNAMIC_EQUITY_ADAPT = keccak256("dynamic-equity-adpt");
    bytes32 internal constant TRIBUTE_NFT = keccak256("tribute-nft");
    bytes32 internal constant REIMBURSEMENT = keccak256("reimbursement");
    bytes32 internal constant TRANSFER_STRATEGY =
        keccak256("erc20-transfer-strategy");
    bytes32 internal constant DAO_REGISTRY_ADAPT = keccak256("daoRegistry");
    bytes32 internal constant BANK_ADAPT = keccak256("bank");
    bytes32 internal constant ERC721_ADAPT = keccak256("nft");
    bytes32 internal constant ERC1155_ADAPT = keccak256("erc1155-adpt");
    bytes32 internal constant ERC1271_ADAPT = keccak256("signatures");
    bytes32 internal constant SNAPSHOT_PROPOSAL_ADPT =
        keccak256("snapshot-proposal-adpt");
    bytes32 internal constant VOTING_HASH_ADPT = keccak256("voting-hash-adpt");
    bytes32 internal constant KICK_BAD_REPORTER_ADPT =
        keccak256("kick-bad-reporter-adpt");
    bytes32 internal constant COUPON_ONBOARDING_ADPT =
        keccak256("coupon-onboarding");
    bytes32 internal constant LEND_NFT_ADPT = keccak256("lend-nft");
    bytes32 internal constant ERC20_TRANSFER_STRATEGY_ADPT =
        keccak256("erc20-transfer-strategy");

    // Extensions
    bytes32 internal constant BANK = keccak256("bank");
    bytes32 internal constant ERC1271 = keccak256("erc1271");
    bytes32 internal constant NFT = keccak256("nft");
    bytes32 internal constant EXECUTOR_EXT = keccak256("executor-ext");
    bytes32 internal constant INTERNAL_TOKEN_VESTING_EXT = keccak256("internal-token-vesting-ext");
    bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext");
    bytes32 internal constant ERC1155_EXT = keccak256("erc1155-ext");
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");

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
import "../../../core/DaoRegistry.sol";
import "../../../core/CloneFactory.sol";
import "../../IFactory.sol";
import "./InternalTokenVestingExtension.sol";

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

contract InternalTokenVestingExtensionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event InternalTokenVestingExtensionCreated(
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
     */
    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "invalid dao addr");
        address payable extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;

        InternalTokenVestingExtension extension = InternalTokenVestingExtension(
            extensionAddr
        );
        extension.initialize(dao, address(0));
        // slither-disable-next-line reentrancy-events
        emit InternalTokenVestingExtensionCreated(
            daoAddress,
            address(extension)
        );
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
import "../../../extensions/IExtension.sol";
import "../../../helpers/DaoHelper.sol";

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
contract InternalTokenVestingExtension is IExtension {
    enum AclFlag {
        NEW_VESTING,
        REMOVE_VESTING
    }

    bool public initialized;

    DaoRegistry private _dao;

    struct VestingSchedule {
        uint64 startDate;
        uint64 endDate;
        uint88 blockedAmount;
    }

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
            "vestingExt::accessDenied"
        );

        _;
    }

    mapping(address => mapping(address => VestingSchedule)) public vesting;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO that it belongs to.
     * @param dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        _dao = dao;
    }

    /**
     * @notice Creates a new vesting schedule for a member based on the internal token, amount and end date.
     * @param member The member address to update the balance.
     * @param internalToken The internal DAO token in which the member will receive the funds.
     * @param amount The amount staked.
     * @param endDate The unix timestamp in which the vesting schedule ends.
     */
    function createNewVesting(
        DaoRegistry dao,
        address member,
        address internalToken,
        uint88 amount,
        uint64 endDate
    ) external hasExtensionAccess(dao, AclFlag.NEW_VESTING) {
        //slither-disable-next-line timestamp
        require(endDate > block.timestamp, "vestingExt::end date in the past");
        VestingSchedule storage schedule = vesting[member][internalToken];
        uint88 minBalance = getMinimumBalanceInternal(
            schedule.startDate,
            schedule.endDate,
            schedule.blockedAmount
        );

        schedule.startDate = uint64(block.timestamp);
        //get max value between endDate and previous one
        if (endDate > schedule.endDate) {
            schedule.endDate = endDate;
        }

        schedule.blockedAmount = minBalance + amount;
    }

    /**
     * @notice Updates a vesting schedule of a member based on the internal token, and amount.
     * @param member The member address to update the balance.
     * @param internalToken The internal DAO token in which the member will receive the funds.
     * @param amountToRemove The amount to be removed.
     */
    function removeVesting(
        DaoRegistry dao,
        address member,
        address internalToken,
        uint88 amountToRemove
    ) external hasExtensionAccess(dao, AclFlag.REMOVE_VESTING) {
        VestingSchedule storage schedule = vesting[member][internalToken];
        uint88 blockedAmount = getMinimumBalanceInternal(
            schedule.startDate,
            schedule.endDate,
            schedule.blockedAmount
        );

        schedule.startDate = uint64(block.timestamp);
        schedule.blockedAmount = blockedAmount - amountToRemove;
    }

    /**
     * @notice Returns the minimum balance of the vesting for a given member and internal token.
     * @param member The member address to update the balance.
     * @param internalToken The internal DAO token in which the member will receive the funds.
     */
    function getMinimumBalance(address member, address internalToken)
        external
        view
        returns (uint88)
    {
        VestingSchedule storage schedule = vesting[member][internalToken];
        return
            getMinimumBalanceInternal(
                schedule.startDate,
                schedule.endDate,
                schedule.blockedAmount
            );
    }

    /**
     * @notice Returns the minimum balance of the vesting for a given start date, end date, and amount.
     * @param startDate The start date of the vesting to calculate the elapsed time.
     * @param endDate The end date of the vesting to calculate the vesting period.
     * @param amount The amount staked.
     */
    function getMinimumBalanceInternal(
        uint64 startDate,
        uint64 endDate,
        uint88 amount
    ) public view returns (uint88) {
        //slither-disable-next-line timestamp
        if (block.timestamp > endDate) {
            return 0;
        }

        uint88 period = endDate - startDate;
        //slither-disable-next-line timestamp
        uint88 elapsedTime = uint88(block.timestamp) - startDate;

        uint88 vestedAmount = (amount * elapsedTime) / period;

        return amount - vestedAmount;
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

import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./NFT.sol";
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

contract NFTCollectionFactory is IFactory, CloneFactory, ReentrancyGuard {
    address public identityAddress;

    event NFTCollectionCreated(address daoAddress, address extensionAddress);

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
        NFTExtension extension = NFTExtension(extensionAddr);
        extension.initialize(dao, address(0));
        // slither-disable-next-line reentrancy-events
        emit NFTCollectionCreated(daoAddress, address(extension));
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
import "../IExtension.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

contract NFTExtension is IExtension, IERC721Receiver {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        WITHDRAW_NFT,
        COLLECT_NFT,
        INTERNAL_TRANSFER
    }

    event CollectedNFT(address nftAddr, uint256 nftTokenId);
    event TransferredNFT(
        address nftAddr,
        uint256 nftTokenId,
        address oldOwner,
        address newOwner
    );
    event WithdrawnNFT(address nftAddr, uint256 nftTokenId, address toAddress);

    // All the Token IDs that belong to an NFT address stored in the GUILD collection
    mapping(address => EnumerableSet.UintSet) private _nfts;

    // The internal owner of record of an NFT that has been transferred to the extension
    mapping(bytes32 => address) private _ownership;

    // All the NFTs addresses collected and stored in the GUILD collection
    EnumerableSet.AddressSet private _nftAddresses;

    modifier hasExtensionAccess(DaoRegistry _dao, AclFlag flag) {
        require(
            dao == _dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "erc721::accessDenied"
        );
        _;
    }

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO address that it belongs to.
     * @param _dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        dao = _dao;
    }

    /**
     * @notice Collects the NFT from the owner and moves it to the NFT extension.
     * @notice It must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * @dev Reverts if the NFT is not in ERC721 standard.
     * @param nftAddr The NFT contract address.
     * @param nftTokenId The NFT token id.
     */
    // slither-disable-next-line reentrancy-benign
    function collect(
        DaoRegistry _dao,
        address nftAddr,
        uint256 nftTokenId
    ) external hasExtensionAccess(_dao, AclFlag.COLLECT_NFT) {
        IERC721 erc721 = IERC721(nftAddr);
        address currentOwner = erc721.ownerOf(nftTokenId);
        //If the NFT is already in the NFTExtension, update the ownership if not set already
        if (currentOwner == address(this)) {
            if (_ownership[getNFTId(nftAddr, nftTokenId)] == address(0x0)) {
                _saveNft(nftAddr, nftTokenId, DaoHelper.GUILD);
                // slither-disable-next-line reentrancy-events
                emit CollectedNFT(nftAddr, nftTokenId);
            }
        } else {
            //If the NFT is not in the NFTExtension, we try to transfer from the current owner of the NFT to the extension
            _saveNft(nftAddr, nftTokenId, DaoHelper.GUILD);
            erc721.safeTransferFrom(currentOwner, address(this), nftTokenId);
            // slither-disable-next-line reentrancy-events
            emit CollectedNFT(nftAddr, nftTokenId);
        }
    }

    /**
     * @notice Transfers the NFT token from the extension address to the new owner.
     * @notice It also updates the internal state to keep track of the all the NFTs collected by the extension.
     * @notice The caller must have the ACL Flag: WITHDRAW_NFT
     * @notice TODO This function needs to be called from a new adapter (RagequitNFT) that will manage the Bank balances, and will return the NFT to the owner.
     * @dev Reverts if the NFT is not in ERC721 standard.
     * @param newOwner The address of the new owner.
     * @param nftAddr The NFT address that must be in ERC721 standard.
     * @param nftTokenId The NFT token id.
     */
    // slither-disable-next-line reentrancy-benign
    function withdrawNFT(
        DaoRegistry _dao,
        address newOwner,
        address nftAddr,
        uint256 nftTokenId
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW_NFT) {
        // Remove the NFT from the contract address to the actual owner
        require(
            _nfts[nftAddr].remove(nftTokenId),
            "erc721::can not remove token id"
        );
        IERC721(nftAddr).safeTransferFrom(address(this), newOwner, nftTokenId);
        // Remove the asset from the extension
        delete _ownership[getNFTId(nftAddr, nftTokenId)];

        // If we dont hold asset from this address anymore, we can remove it
        if (_nfts[nftAddr].length() == 0) {
            require(
                _nftAddresses.remove(nftAddr),
                "erc721::can not remove nft"
            );
        }
        //slither-disable-next-line reentrancy-events
        emit WithdrawnNFT(nftAddr, nftTokenId, newOwner);
    }

    /**
     * @notice Updates internally the ownership of the NFT.
     * @notice The caller must have the ACL Flag: INTERNAL_TRANSFER
     * @dev Reverts if the NFT is not already internally owned in the extension.
     * @param nftAddr The NFT address.
     * @param nftTokenId The NFT token id.
     * @param newOwner The address of the new owner.
     */
    function internalTransfer(
        DaoRegistry _dao,
        address nftAddr,
        uint256 nftTokenId,
        address newOwner
    ) external hasExtensionAccess(_dao, AclFlag.INTERNAL_TRANSFER) {
        require(newOwner != address(0x0), "erc721::new owner is 0");
        address currentOwner = _ownership[getNFTId(nftAddr, nftTokenId)];
        require(_dao.notJailed(currentOwner), "member is jailed");
        require(currentOwner != address(0x0), "erc721::nft not found");

        _ownership[getNFTId(nftAddr, nftTokenId)] = newOwner;

        emit TransferredNFT(nftAddr, nftTokenId, currentOwner, newOwner);
    }

    /**
     * @notice Gets ID generated from an NFT address and token id (used internally to map ownership).
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTId(address nftAddress, uint256 tokenId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftAddress, tokenId));
    }

    /**
     * @notice Returns the total amount of token ids collected for an NFT address.
     * @param tokenAddr The NFT address.
     */
    function nbNFTs(address tokenAddr) external view returns (uint256) {
        return _nfts[tokenAddr].length();
    }

    /**
     * @notice Returns token id associated with an NFT address stored in the GUILD collection at the specified index.
     * @param tokenAddr The NFT address.
     * @param index The index to get the token id if it exists.
     */
    function getNFT(address tokenAddr, uint256 index)
        external
        view
        returns (uint256)
    {
        return _nfts[tokenAddr].at(index);
    }

    /**
     * @notice Returns the total amount of NFT addresses collected.
     */
    function nbNFTAddresses() external view returns (uint256) {
        return _nftAddresses.length();
    }

    /**
     * @notice Returns NFT address stored in the GUILD collection at the specified index.
     * @param index The index to get the NFT address if it exists.
     */
    function getNFTAddress(uint256 index) external view returns (address) {
        return _nftAddresses.at(index);
    }

    /**
     * @notice Returns owner of NFT that has been transferred to the extension.
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTOwner(address nftAddress, uint256 tokenId)
        external
        view
        returns (address)
    {
        return _ownership[getNFTId(nftAddress, tokenId)];
    }

    /**
     * @notice Required function from IERC721 standard to be able to receive assets to this contract address.
     */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes calldata
    ) external override returns (bytes4) {
        _saveNft(msg.sender, id, DaoHelper.GUILD);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Must be manually called if the NFT was received via transferFrom function.
     * @notice If this function is not called, the NFT metadata won't be stored in the extension,
     * because the transferFrom call does not trigger the onERC721Received callback.
     * @notice If the NFT is not owner by the Extension, the update call is not allowed, this is done to
     * ensure that the NFT was actually sent to the Extension address.
     */
    function updateCollection(address token, uint256 tokenId) external {
        require(
            IERC721(token).ownerOf(tokenId) == address(this),
            "update not allowed"
        );
        _saveNft(token, tokenId, DaoHelper.GUILD);
    }

    /**
     * @notice Helper function to update the extension states for an NFT collected by the extension.
     * @param nftAddr The NFT address.
     * @param nftTokenId The token id.
     * @param owner The address of the owner.
     */
    function _saveNft(
        address nftAddr,
        uint256 nftTokenId,
        address owner
    ) private {
        // Save the asset, returns false if already saved.
        bool saved = _nfts[nftAddr].add(nftTokenId);
        if (saved) {
            // set ownership to the GUILD.
            _ownership[getNFTId(nftAddr, nftTokenId)] = owner;
            // Keep track of the collected assets.
            if (!_nftAddresses.contains(nftAddr)) {
                //slither-disable-next-line unused-return
                _nftAddresses.add(nftAddr);
            }
        }
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

import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./ERC1271.sol";
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

contract ERC1271ExtensionFactory is IFactory, CloneFactory, ReentrancyGuard {
    address public identityAddress;

    event ERC1271Created(address daoAddress, address extensionAddress);

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
        address extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        ERC1271Extension extension = ERC1271Extension(extensionAddr);
        extension.initialize(dao, address(0));
        // slither-disable-next-line reentrancy-events
        emit ERC1271Created(daoAddress, address(extension));
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
import "../IExtension.sol";
import "../../helpers/DaoHelper.sol";
import "../../guards/AdapterGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

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
 * @dev Signs arbitrary messages and exposes ERC1271 interface
 */
contract ERC1271Extension is IExtension, IERC1271 {
    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        SIGN
    }

    struct DAOSignature {
        bytes32 signatureHash;
        bytes4 magicValue;
    }

    mapping(bytes32 => DAOSignature) public signatures; // msgHash => Signature

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

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
            "erc1271::accessDenied"
        );
        _;
    }

    /**
     * @notice Initialises the ERC1271 extension to be associated with a DAO
     * @dev Can only be called once
     * @param _dao The dao address that will be associated with the new extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        dao = _dao;
    }

    /**
     * @notice Verifies if exists a signature based on the permissionHash, and checks if the provided signature matches the expected signatureHash.
     * @param permissionHash The digest of the data to be signed.
     * @param signature The signature in bytes to be encoded, hashed and verified.
     * @return The magic number in bytes4 in case the signature is valid, otherwise it reverts.
     */
    function isValidSignature(bytes32 permissionHash, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        DAOSignature memory daoSignature = signatures[permissionHash];
        require(daoSignature.magicValue != 0, "erc1271::invalid signature");
        require(
            daoSignature.signatureHash ==
                keccak256(abi.encodePacked(signature)),
            "erc1271::invalid signature hash"
        );
        return daoSignature.magicValue;
    }

    /**
     * @notice Registers a valid signature in the extension.
     * @dev Only adapters/extensions with `SIGN` ACL can call this function.
     * @param permissionHash The digest of the data to be signed.
     * @param signatureHash The hash of the signature.
     * @param magicValue The value to be returned by the ERC1271 interface upon success.
     */
    function sign(
        DaoRegistry _dao,
        bytes32 permissionHash,
        bytes32 signatureHash,
        bytes4 magicValue
    ) external hasExtensionAccess(_dao, AclFlag.SIGN) {
        signatures[permissionHash] = DAOSignature({
            signatureHash: signatureHash,
            magicValue: magicValue
        });
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../../core/DaoRegistry.sol";
import "../../core/CloneFactory.sol";
import "../IFactory.sol";
import "./ERC1155TokenExtension.sol";
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

contract ERC1155TokenCollectionFactory is
    IFactory,
    CloneFactory,
    ReentrancyGuard
{
    address public identityAddress;

    event ERC1155CollectionCreated(
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
     */
    function create(DaoRegistry dao) external nonReentrant {
        address daoAddress = address(dao);
        require(daoAddress != address(0x0), "invalid dao addr");
        address extensionAddr = _createClone(identityAddress);
        _extensions[daoAddress] = extensionAddr;
        ERC1155TokenExtension extension = ERC1155TokenExtension(extensionAddr);
        extension.initialize(dao, address(0));
        // slither-disable-next-line reentrancy-events
        emit ERC1155CollectionCreated(daoAddress, address(extension));
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
import "../../guards/MemberGuard.sol";
import "../../helpers/DaoHelper.sol";
import "../IExtension.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

contract ERC1155TokenExtension is IExtension, IERC1155Receiver {
    using Address for address payable;
    //LIBRARIES
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized = false; //internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        WITHDRAW_NFT,
        COLLECT_NFT,
        INTERNAL_TRANSFER
    }

    //EVENTS
    event TransferredNFT(
        address oldOwner,
        address newOwner,
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount
    );
    event WithdrawnNFT(
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount,
        address toAddress
    );

    //MAPPINGS

    // All the Token IDs that belong to an NFT address stored in the GUILD.
    mapping(address => EnumerableSet.UintSet) private _nfts;

    // The internal mapping to track the owners, nfts, tokenIds, and amounts records of the owners that sent ther NFT to the extension
    // owner => (tokenAddress => (tokenId => tokenAmount)).
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _nftTracker;

    // The (NFT Addr + Token Id) key reverse mapping to track all the tokens collected and actual owners.
    mapping(bytes32 => EnumerableSet.AddressSet) private _ownership;

    // All the NFT addresses stored in the Extension collection
    EnumerableSet.AddressSet private _nftAddresses;

    //MODIFIERS
    modifier hasExtensionAccess(DaoRegistry _dao, AclFlag flag) {
        require(
            _dao == dao &&
                (DaoHelper.isInCreationModeAndHasAccess(dao) ||
                    !initialized ||
                    dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "erc1155Ext::accessDenied"
        );
        _;
    }

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initializes the extension with the DAO address that it belongs to.
     * @param _dao The address of the DAO that owns the extension.
     */
    function initialize(DaoRegistry _dao, address) external override {
        require(!initialized, "already initialized");
        initialized = true;
        dao = _dao;
    }

    /**
     * @notice Transfers the NFT token from the extension address to the new owner.
     * @notice It also updates the internal state to keep track of the all the NFTs collected by the extension.
     * @notice The caller must have the ACL Flag: WITHDRAW_NFT
     * @notice This function needs to be called from a new adapter (RagequitNFT) that will manage the Bank balances, and will return the NFT to the owner.
     * @dev Reverts if the NFT is not in ERC1155 standard.
     * @param newOwner The address of the new owner that will receive the NFT.
     * @param nftAddr The NFT address that must be in ERC1155 standard.
     * @param nftTokenId The NFT token id.
     * @param amount The NFT token id amount to withdraw.
     */
    function withdrawNFT(
        DaoRegistry _dao,
        address from,
        address newOwner,
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.WITHDRAW_NFT) {
        IERC1155 erc1155 = IERC1155(nftAddr);
        uint256 balance = erc1155.balanceOf(address(this), nftTokenId);
        require(
            balance > 0 && amount > 0,
            "erc1155Ext::not enough balance or amount"
        );

        uint256 currentAmount = _getTokenAmount(from, nftAddr, nftTokenId);
        require(currentAmount >= amount, "erc1155Ext::insufficient funds");
        uint256 remainingAmount = currentAmount - amount;

        // Updates the tokenID amount to keep the records consistent
        _updateTokenAmount(from, nftAddr, nftTokenId, remainingAmount);

        uint256 ownerTokenIdBalance = erc1155.balanceOf(
            address(this),
            nftTokenId
        ) - amount;

        // Updates the mappings if the amount of tokenId in the Extension is 0
        // It means the GUILD/Extension does not hold that token id anymore.
        if (ownerTokenIdBalance == 0) {
            delete _nftTracker[from][nftAddr][nftTokenId];
            //slither-disable-next-line unused-return
            _ownership[getNFTId(nftAddr, nftTokenId)].remove(from);
            //slither-disable-next-line unused-return
            _nfts[nftAddr].remove(nftTokenId);
            // If there are 0 tokenIds for the NFT address, remove the NFT from the collection
            if (_nfts[nftAddr].length() == 0) {
                //slither-disable-next-line unused-return
                _nftAddresses.remove(nftAddr);
                delete _nfts[nftAddr];
            }
        }

        // Transfer the NFT, TokenId and amount from the contract address to the new owner
        erc1155.safeTransferFrom(
            address(this),
            newOwner,
            nftTokenId,
            amount,
            ""
        );
        //slither-disable-next-line reentrancy-events
        emit WithdrawnNFT(nftAddr, nftTokenId, amount, newOwner);
    }

    /**
     * @notice Updates internally the ownership of the NFT.
     * @notice The caller must have the ACL Flag: INTERNAL_TRANSFER
     * @dev Reverts if the NFT is not already internally owned in the extension.
     * @param fromOwner The address of the current owner.
     * @param toOwner The address of the new owner.
     * @param nftAddr The NFT address.
     * @param nftTokenId The NFT token id.
     * @param amount the number of a particular NFT token id.
     */
    function internalTransfer(
        DaoRegistry _dao,
        address fromOwner,
        address toOwner,
        address nftAddr,
        uint256 nftTokenId,
        uint256 amount
    ) external hasExtensionAccess(_dao, AclFlag.INTERNAL_TRANSFER) {
        require(_dao.notJailed(fromOwner), "member is jailed!");
        // Checks if there token amount is valid and has enough funds
        uint256 tokenAmount = _getTokenAmount(fromOwner, nftAddr, nftTokenId);
        require(
            amount > 0 && tokenAmount >= amount,
            "erc1155Ext::invalid amount"
        );

        // Checks if the extension holds the NFT
        require(
            _nfts[nftAddr].contains(nftTokenId),
            "erc1155Ext::nft not found"
        );
        if (fromOwner != toOwner) {
            // Updates the internal records for toOwner with the current balance + the transferred amount
            uint256 toOwnerNewAmount = _getTokenAmount(
                toOwner,
                nftAddr,
                nftTokenId
            ) + amount;
            _updateTokenAmount(toOwner, nftAddr, nftTokenId, toOwnerNewAmount);
            // Updates the internal records for fromOwner with the remaning amount
            _updateTokenAmount(
                fromOwner,
                nftAddr,
                nftTokenId,
                tokenAmount - amount
            );
            //slither-disable-next-line reentrancy-events
            emit TransferredNFT(
                fromOwner,
                toOwner,
                nftAddr,
                nftTokenId,
                amount
            );
        }
    }

    /**
     * @notice Gets ID generated from an NFT address and token id (used internally to map ownership).
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTId(address nftAddress, uint256 tokenId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftAddress, tokenId));
    }

    /**
     * @notice gets owner's amount of a TokenId for an NFT address.
     * @param owner eth address
     * @param tokenAddr the NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTIdAmount(
        address owner,
        address tokenAddr,
        uint256 tokenId
    ) external view returns (uint256) {
        return _nftTracker[owner][tokenAddr][tokenId];
    }

    /**
     * @notice Returns the total amount of token ids collected for an NFT address.
     * @param tokenAddr The NFT address.
     */
    function nbNFTs(address tokenAddr) external view returns (uint256) {
        return _nfts[tokenAddr].length();
    }

    /**
     * @notice Returns token id associated with an NFT address stored in the GUILD collection at the specified index.
     * @param tokenAddr The NFT address.
     * @param index The index to get the token id if it exists.
     */
    function getNFT(address tokenAddr, uint256 index)
        external
        view
        returns (uint256)
    {
        return _nfts[tokenAddr].at(index);
    }

    /**
     * @notice Returns the total amount of NFT addresses collected.
     */
    function nbNFTAddresses() external view returns (uint256) {
        return _nftAddresses.length();
    }

    /**
     * @notice Returns NFT address stored in the GUILD collection at the specified index.
     * @param index The index to get the NFT address if it exists.
     */
    function getNFTAddress(uint256 index) external view returns (address) {
        return _nftAddresses.at(index);
    }

    /**
     * @notice Returns owner of NFT that has been transferred to the extension.
     * @param nftAddress The NFT address.
     * @param tokenId The NFT token id.
     */
    function getNFTOwner(
        address nftAddress,
        uint256 tokenId,
        uint256 index
    ) external view returns (address) {
        return _ownership[getNFTId(nftAddress, tokenId)].at(index);
    }

    /**
     * @notice Returns the total number of owners of an NFT addresses and token id collected.
     */
    function nbNFTOwners(address nftAddress, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _ownership[getNFTId(nftAddress, tokenId)].length();
    }

    /**
     * @notice Helper function to update the extension states for an NFT collected by the extension.
     * @param nftAddr The NFT address.
     * @param nftTokenId The token id.
     * @param owner The address of the owner.
     * @param amount of the tokenID
     */
    function _saveNft(
        address nftAddr,
        uint256 nftTokenId,
        address owner,
        uint256 amount
    ) private {
        // Save the asset address and tokenId
        //slither-disable-next-line unused-return
        _nfts[nftAddr].add(nftTokenId);
        // Track the owner by nftAddr+tokenId
        //slither-disable-next-line unused-return
        _ownership[getNFTId(nftAddr, nftTokenId)].add(owner);
        // Keep track of the collected assets addresses
        //slither-disable-next-line unused-return
        _nftAddresses.add(nftAddr);
        // Track the actual owner per Token Id and amount
        uint256 currentAmount = _nftTracker[owner][nftAddr][nftTokenId];
        _nftTracker[owner][nftAddr][nftTokenId] = currentAmount + amount;
    }

    /**
     *  @notice required function from IERC1155 standard to be able to to receive tokens
     */
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        _saveNft(msg.sender, id, DaoHelper.GUILD, value);
        return this.onERC1155Received.selector;
    }

    /**
     *  @notice required function from IERC1155 standard to be able to to batch receive tokens
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        require(
            ids.length == values.length,
            "erc1155Ext::ids values length mismatch"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            _saveNft(msg.sender, ids[i], DaoHelper.GUILD, values[i]);
        }

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Supports ERC-165 & ERC-1155 interfaces only.
     * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
     */
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    /**
     *  @notice internal function to update the amount of a tokenID for an NFT an owner has
     */
    function _updateTokenAmount(
        address owner,
        address nft,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _nftTracker[owner][nft][tokenId] = amount;
    }

    /**
     *  @notice internal function to get the amount of a tokenID for an NFT an owner has
     */
    function _getTokenAmount(
        address owner,
        address nft,
        uint256 tokenId
    ) internal view returns (uint256) {
        return _nftTracker[owner][nft][tokenId];
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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