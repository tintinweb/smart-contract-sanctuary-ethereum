// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "../model/IDelegationFactory.sol";
import "./EthereansFactory.sol";
import "../../../base/model/IProposalsManager.sol";
import { ReflectionUtilities, BehaviorUtilities, Uint256Utilities, AddressUtilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";
import { Grimoire as BaseGrimoire, Getters } from "../../../base/lib/KnowledgeBase.sol";
import { Getters as ExternalGetters } from "../../../ext/lib/KnowledgeBase.sol";
import "../../../ext/subDAO/model/ISubDAO.sol";
import "../../../base/model/IProposalsManager.sol";
import "../../../core/model/IOrganization.sol";
import "../../../base/model/IStateManager.sol";
import { State } from "../../../base/lib/KnowledgeBase.sol";
import "@ethereansos/items-v2/contracts/projection/IItemProjection.sol";
import "@ethereansos/items-v2/contracts/projection/factory/model/IItemProjectionFactory.sol";
import "../model/IProposalModelsFactory.sol";

contract DelegationFactory is EthereansFactory, IDelegationFactory {
    using ReflectionUtilities for address;
    using Getters for IOrganization;
    using ExternalGetters for IOrganization;
    using State for IStateManager;
    using Uint256Utilities for uint256;
    using AddressUtilities for address;

    uint256 public constant MANDATORY_COMPONENTS = 3;
    //ProposalsManager true
    //TreasuryManager false
    //DelegationTokensManager true

    uint256 public constant PROPOSALS_MANAGER_POSITION = 0;

    address[] private _utilityModels;
    bytes32[] private _utilityModelKeys;
    bool[] private _utilityModelsActive;

    uint256 public presetArrayMaxSize;

    address public itemProjectionFactoryAddress;
    address public mainInterface;
    address public projectionAddress;
    bytes32 public collectionId;
    ISubDAO.SubDAOProposalModel[] private _proposalModels;

    address public proposalModelsFactory;

    uint256 private constant BY_SPECIFIC_ADDRESS_POSITION = 0;
    uint256 private constant BLOCK_LENGTH_POSITION = 2;
    uint256 private constant HARD_CAP_POSITION = 3;
    uint256 private constant VALIDATION_BOMB_POSITION = 4;
    uint256 private constant QUORUM_POSITION = 5;

    constructor(bytes memory lazyInitData) EthereansFactory(lazyInitData) {
    }

    function _ethosFactoryLazyInit(bytes memory lazyInitData) internal override returns(bytes memory lazyInitResponse) {
        (proposalModelsFactory, _utilityModels, _utilityModelKeys, _utilityModelsActive, lazyInitResponse) = abi.decode(lazyInitData, (address, address[], bytes32[], bool[], bytes));
        ISubDAO.SubDAOProposalModel[] memory proposalModels;
        Header memory collectionHeader;
        (itemProjectionFactoryAddress, collectionHeader, presetArrayMaxSize, proposalModels) = abi.decode(lazyInitResponse, (address, Header, uint256, ISubDAO.SubDAOProposalModel[]));
        for(uint256 i = 0; i < proposalModels.length; i++) {
            _proposalModels.push(proposalModels[i]);
        }
        _deployCollection(collectionHeader);
        lazyInitResponse = "";
    }

    function mintItems(CreateItem[] memory items) external returns(uint256[] memory itemIds) {
        require(deployer[msg.sender] != address(0), "unauthorized");
        for(uint256 i = 0; i < items.length; i++) {
            items[i].collectionId = collectionId;
        }
        return IItemProjection(projectionAddress).mintItems(items);
    }

    function data() external override view returns(address[] memory utilityModels, bytes32[] memory utilitiyModelKeys, bool[] memory utilitiyModelActive, string memory proposalUri) {
        return (_utilityModels, _utilityModelKeys, _utilityModelsActive, "");
    }

    function deploy(bytes calldata deployData) external payable override(Factory, IFactory) virtual returns(address productAddress, bytes memory productInitResponse) {
        (OrganizationDeployData memory organizationDeployData) = abi.decode(deployData, (OrganizationDeployData));

        deployer[productAddress = modelAddress.clone()] = msg.sender;

        uint256 componentsLength = MANDATORY_COMPONENTS;
        IOrganization.Component[] memory components = new IOrganization.Component[](componentsLength);

        for(uint256 i = 0; i < MANDATORY_COMPONENTS; i++) {
            components[i] = _createOrganizationComponent(i, productAddress, i == PROPOSALS_MANAGER_POSITION ? abi.encode(true, organizationDeployData.mandatoryComponentsDeployData[i]) : organizationDeployData.mandatoryComponentsDeployData[i]);
        }

        productInitResponse = _emitDeploy(productAddress, organizationDeployData.uri, components);

        require(ILazyInitCapableElement(productAddress).initializer() == address(this));
    }

    address[] private _validationAddresses;
    address[] private _canTerminateAddresses;

    function createNewRules(
        address delegationAddress,
        uint256 quorumPercentage,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCapPercentage
    ) public override returns (address[] memory validationAddresses, address[] memory canTerminateAddresses) {
        require(deployer[delegationAddress] != address(0), "unknown delegation");

        _addTo(QUORUM_POSITION, quorumPercentage, true, true);
        if(validationBomb > 0) {
            _addTo(VALIDATION_BOMB_POSITION, validationBomb, false, true);
        }

        if(blockLength > 0) {
            _addTo(BLOCK_LENGTH_POSITION, blockLength, false, false);
        }

        if(hardCapPercentage > 0) {
            _addTo(HARD_CAP_POSITION, hardCapPercentage, true, false);
        }

        validationAddresses = _validationAddresses;
        canTerminateAddresses = _canTerminateAddresses;

        require(validationAddresses.length > 0, "No validators");
        require(canTerminateAddresses.length > 0, "No canTerminates");

        delete _validationAddresses;
        delete _canTerminateAddresses;
    }

    function initializeProposalModels(
        address delegationAddress,
        address host,
        uint256 quorumPercentage,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCapPercentage
        ) external override {

        require(deployer[delegationAddress] == msg.sender, "unauthorized");
        (address creationRules,) = IProposalModelsFactory(proposalModelsFactory).deploy(abi.encode(BY_SPECIFIC_ADDRESS_POSITION, abi.encode(host, true)));

        (address[] memory validationAddresses, address[] memory canTerminateAddresses) = createNewRules(
            delegationAddress,
            quorumPercentage,
            validationBomb,
            blockLength,
            hardCapPercentage
        );

        ISubDAO.SubDAOProposalModel[] memory proposalModels = _proposalModels;
        proposalModels[0].creationRules = creationRules;//Attach-Detach

        proposalModels[1].creationRules = creationRules;//Change URI

        proposalModels[2].creationRules = creationRules;//Change Rules

        proposalModels[3].creationRules = creationRules;//Transfer
        proposalModels[3].validatorsAddresses[0] = validationAddresses;
        proposalModels[3].canTerminateAddresses[0] = canTerminateAddresses;

        proposalModels[4].creationRules = creationRules;//Vote
        proposalModels[4].validatorsAddresses[0] = validationAddresses;
        proposalModels[4].canTerminateAddresses[0] = canTerminateAddresses;

        ISubDAO(delegationAddress).setInitialProposalModels(proposalModels);
    }

    function _addTo(uint256 position, uint256 value, bool valueIsPercentage, bool validators) private {
        bytes memory init = valueIsPercentage ? abi.encode(value, true) : abi.encode(value);
        (address model,) = IProposalModelsFactory(proposalModelsFactory).deploy(abi.encode(position, init));
        if(validators) {
            _validationAddresses.push(model);
        } else {
            _canTerminateAddresses.push(model);
        }
    }

    function _emitDeploy(address productAddress, string memory uri, IOrganization.Component[] memory components) private returns(bytes memory productInitResponse) {
        emit Deployed(modelAddress, productAddress, msg.sender, productInitResponse = ILazyInitCapableElement(productAddress).lazyInit(abi.encode(address(0), abi.encode(uri, dynamicUriResolver, abi.encode(false, presetArrayMaxSize, abi.encode(new ISubDAO.SubDAOProposalModel[](0), abi.encode(components)))))));
    }

    function proposeToAttachOrDetach(address delegationAddress, address delegationsManagerAddress, bool attach) public returns(bytes32 proposalId) {
        require(deployer[delegationAddress] != address(0), "Unrecognized");

        IProposalsManager.ProposalCode[] memory proposalCodes = new IProposalsManager.ProposalCode[](1);
        proposalCodes[0] = IProposalsManager.ProposalCode(address(0), abi.encode(delegationsManagerAddress, attach));

        IProposalsManager.ProposalCodes[] memory proposalCodesArray = new IProposalsManager.ProposalCodes[](1);
        proposalCodesArray[0] = IProposalsManager.ProposalCodes(proposalCodes, true);

        return IOrganization(delegationAddress).proposalsManager().batchCreate(proposalCodesArray)[0];
    }

    function _createOrganizationComponent(uint256 index, address productAddress, bytes memory lazyInitData) private returns(IOrganization.Component memory organizationComponent) {
        ILazyInitCapableElement((organizationComponent = IOrganization.Component(_utilityModelKeys[index], _utilityModels[index].clone(), _utilityModelsActive[index], true)).location).lazyInit(abi.encode(productAddress, lazyInitData));
        deployer[organizationComponent.location] = msg.sender;
    }

    function _deployCollection(Header memory collectionHeader) private {
        mainInterface = IItemProjectionFactory(itemProjectionFactoryAddress).mainInterface();

        collectionHeader.host = address(0);

        bytes memory deployData = abi.encode((uint256(1)).asSingletonArray(), address(this).asSingletonArray());
        deployData = abi.encode(bytes32(0), collectionHeader, new CreateItem[](0), deployData);
        deployData = abi.encode(address(0), deployData);
        deployData = abi.encode(0, deployData);
        (projectionAddress,) = IItemProjectionFactory(itemProjectionFactoryAddress).deploy(deployData);
        collectionId = IItemProjection(projectionAddress).collectionId();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "@ethereansos/swissknife/contracts/factory/impl/Factory.sol";

interface IProposalModelsFactory is IFactory {

    event Singleton(address indexed productAddress);

    function deploySingleton(bytes calldata code, bytes calldata deployData) external returns(address deployedAddress, bytes memory deployLazyInitResponse);

    function addModel(bytes calldata code, string calldata uri) external returns(address modelAddress, uint256 positionIndex);

    function models() external view returns(address[] memory addresses, string[] memory uris);

    function singletons() external view returns(address[] memory addresses);

    function setModelUris(uint256[] memory indices, string[] memory uris) external;

    function model(uint256 i) external view returns(address modelAddress, string memory modelUri);

    function singleton(uint256 i) external view returns(address singletonAddress);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "@ethereansos/swissknife/contracts/factory/impl/Factory.sol";

interface IItemProjectionFactory is IFactory {

    function mainInterface() external view returns(address);

    function deploySingleton(bytes calldata code, bytes calldata deployData) external returns(address deployedAddress, bytes memory deployLazyInitResponse);

    function addModel(bytes calldata code) external returns(address modelAddress, uint256 positionIndex);

    function models() external view returns(address[] memory);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "../model/Item.sol";
import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IItemProjection is Item, ILazyInitCapableElement {

    function mainInterface() external view returns(address);

    function collectionId() external view returns(bytes32);
    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);
    function itemPlainUri(uint256 itemId) external view returns(string memory);
    function setHeader(Header calldata value) external returns(Header memory oldValue);

    function toInteroperableInterfaceAmount(uint256 amount, uint256 itemId, address account) external view returns(uint256);
    function toMainInterfaceAmount(uint256 amount, uint256 itemId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../core/model/IOrganization.sol";
import "../model/IMicroservicesManager.sol";
import "../model/IStateManager.sol";
import "../model/IProposalsManager.sol";
import "../model/ITreasuryManager.sol";
import { ReflectionUtilities, BytesUtilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";

library Grimoire {
    bytes32 constant public COMPONENT_KEY_TREASURY_MANAGER = 0xcfe1633df53a0649d88d788961f26058c5e7a0b5644675f19f67bb2975827ba2;
    bytes32 constant public COMPONENT_KEY_STATE_MANAGER = 0xd1d09e8f5708558865b8acd5f13c69781ae600e42dbc7f52b8ef1b9e33dbcd36;
    bytes32 constant public COMPONENT_KEY_MICROSERVICES_MANAGER = 0x0aef4c8f864010d3e1817691f51ade95a646fffafd7f3df9cb8200def342cfd7;
    bytes32 constant public COMPONENT_KEY_PROPOSALS_MANAGER = 0xa504406933af7ca120d20b97dfc79ea9788beb3c4d3ac1ff9a2c292b2c28e0cc;
}

library Getters {

    function treasuryManager(IOrganization organization) internal view returns(ITreasuryManager) {
        return ITreasuryManager(organization.get(Grimoire.COMPONENT_KEY_TREASURY_MANAGER));
    }

    function stateManager(IOrganization organization) internal view returns(IStateManager) {
        return IStateManager(organization.get(Grimoire.COMPONENT_KEY_STATE_MANAGER));
    }

    function microservicesManager(IOrganization organization) internal view returns(IMicroservicesManager) {
        return IMicroservicesManager(organization.get(Grimoire.COMPONENT_KEY_MICROSERVICES_MANAGER));
    }

    function proposalsManager(IOrganization organization) internal view returns(IProposalsManager) {
        return IProposalsManager(organization.get(Grimoire.COMPONENT_KEY_PROPOSALS_MANAGER));
    }
}

library Setters {

    function replaceTreasuryManager(IOrganization organization, address newComponentAddress) internal returns(ITreasuryManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = ITreasuryManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_TREASURY_MANAGER, newComponentAddress, false, true)));
    }

    function replaceStateManager(IOrganization organization, address newComponentAddress) internal returns(IStateManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IStateManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_STATE_MANAGER, newComponentAddress, false ,true)));
    }

    function replaceMicroservicesManager(IOrganization organization, address newComponentAddress) internal returns(IMicroservicesManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IMicroservicesManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_MICROSERVICES_MANAGER, newComponentAddress, true, true)));
    }

    function replaceProposalsManager(IOrganization organization, address newComponentAddress) internal returns(IProposalsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IProposalsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_PROPOSALS_MANAGER, newComponentAddress, true, true)));
    }
}

library Treasury {
    using ReflectionUtilities for address;

    function storeETH(IOrganization organization, uint256 value) internal {
        if(value != 0) {
            organization.get(Grimoire.COMPONENT_KEY_TREASURY_MANAGER).submit(value, "");
        }
    }

    function callTemporaryFunction(ITreasuryManager treasuryManager, bytes4 selector, address subject, uint256 value, bytes memory data) internal returns(bytes memory response) {
        address oldServer = treasuryManager.setAdditionalFunction(selector, subject, false);
        response = address(treasuryManager).submit(value, abi.encodePacked(selector, data));
        treasuryManager.setAdditionalFunction(selector, oldServer, false);
    }
}

library State {
    using BytesUtilities for bytes;

    bytes32 constant public ENTRY_TYPE_ADDRESS = 0x421683f821a0574472445355be6d2b769119e8515f8376a1d7878523dfdecf7b;
    bytes32 constant public ENTRY_TYPE_ADDRESS_ARRAY = 0x23d8ff3dc5aed4a634bcf123581c95e70c60ac0e5246916790aef6d4451ff4c1;
    bytes32 constant public ENTRY_TYPE_BOOL = 0xc1053bdab4a5cf55238b667c39826bbb11a58be126010e7db397c1b67c24271b;
    bytes32 constant public ENTRY_TYPE_BOOL_ARRAY = 0x8761250c4d2c463ce51f91f5d2c2508fa9142f8a42aa9f30b965213bf3e6c2ac;
    bytes32 constant public ENTRY_TYPE_BYTES = 0xb963e9b45d014edd60cff22ec9ad383335bbc3f827be2aee8e291972b0fadcf2;
    bytes32 constant public ENTRY_TYPE_BYTES_ARRAY = 0x084b42f8a8730b98eb0305d92103d9107363192bb66162064a34dc5716ebe1a0;
    bytes32 constant public ENTRY_TYPE_STRING = 0x97fc46276c172633607a331542609db1e3da793fca183d594ed5a61803a10792;
    bytes32 constant public ENTRY_TYPE_STRING_ARRAY = 0xa227fd7a847724343a7dda3598ee0fb2d551b151b73e4a741067596daa6f5658;
    bytes32 constant public ENTRY_TYPE_UINT256 = 0xec13d6d12b88433319b64e1065a96ea19cd330ef6603f5f6fb685dde3959a320;
    bytes32 constant public ENTRY_TYPE_UINT256_ARRAY = 0xc1b76e99a35aa41ed28bbbd9e6c7228760c87b410ebac94fa6431da9b592411f;

    function getAddress(IStateManager stateManager, string memory name) internal view returns(address) {
        return stateManager.get(name).value.asAddress();
    }

    function setAddress(IStateManager stateManager, string memory name, address val) internal returns(address oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_ADDRESS, abi.encodePacked(val))).asAddress();
    }

    function getAddressArray(IStateManager stateManager, string memory name) internal view returns(address[] memory) {
        return stateManager.get(name).value.asAddressArray();
    }

    function setAddressArray(IStateManager stateManager, string memory name, address[] memory val) internal returns(address[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_ADDRESS_ARRAY, abi.encode(val))).asAddressArray();
    }

    function getBool(IStateManager stateManager, string memory name) internal view returns(bool) {
        return stateManager.get(name).value.asBool();
    }

    function setBool(IStateManager stateManager, string memory name, bool val) internal returns(bool oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BOOL, abi.encode(val ? 1 : 0))).asBool();
    }

    function getBoolArray(IStateManager stateManager, string memory name) internal view returns(bool[] memory) {
        return stateManager.get(name).value.asBoolArray();
    }

    function setBoolArray(IStateManager stateManager, string memory name, bool[] memory val) internal returns(bool[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BOOL_ARRAY, abi.encode(val))).asBoolArray();
    }

    function getBytes(IStateManager stateManager, string memory name) internal view returns(bytes memory) {
        return stateManager.get(name).value;
    }

    function setBytes(IStateManager stateManager, string memory name, bytes memory val) internal returns(bytes memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BYTES, val));
    }

    function getBytesArray(IStateManager stateManager, string memory name) internal view returns(bytes[] memory) {
        return stateManager.get(name).value.asBytesArray();
    }

    function setBytesArray(IStateManager stateManager, string memory name, bytes[] memory val) internal returns(bytes[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BYTES_ARRAY, abi.encode(val))).asBytesArray();
    }

    function getString(IStateManager stateManager, string memory name) internal view returns(string memory) {
        return string(stateManager.get(name).value);
    }

    function setString(IStateManager stateManager, string memory name, string memory val) internal returns(string memory oldValue) {
        return string(stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_STRING, bytes(val))));
    }

    function getStringArray(IStateManager stateManager, string memory name) internal view returns(string[] memory) {
        return stateManager.get(name).value.asStringArray();
    }

    function setStringArray(IStateManager stateManager, string memory name, string[] memory val) internal returns(string[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_STRING_ARRAY, abi.encode(val))).asStringArray();
    }

    function getUint256(IStateManager stateManager, string memory name) internal view returns(uint256) {
        return stateManager.get(name).value.asUint256();
    }

    function setUint256(IStateManager stateManager, string memory name, uint256 val) internal returns(uint256 oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_UINT256, abi.encode(val))).asUint256();
    }

    function getUint256Array(IStateManager stateManager, string memory name) internal view returns(uint256[] memory) {
        return stateManager.get(name).value.asUint256Array();
    }

    function setUint256Array(IStateManager stateManager, string memory name, uint256[] memory val) internal returns(uint256[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_UINT256_ARRAY, abi.encode(val))).asUint256Array();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IStateManager is ILazyInitCapableElement {

    struct StateEntry {
        string key;
        bytes32 entryType;
        bytes value;
    }

    function size() external view returns (uint256);
    function all() external view returns (StateEntry[] memory);
    function partialList(uint256 start, uint256 offset) external view returns (StateEntry[] memory);
    function list(string[] calldata keys) external view returns (StateEntry[] memory);
    function listByIndices(uint256[] calldata indices) external view returns (StateEntry[] memory);

    function exists(string calldata key) external view returns(bool result, uint256 index);

    function get(string calldata key) external view returns(StateEntry memory);
    function getByIndex(uint256 index) external view returns(StateEntry memory);

    function set(StateEntry calldata newValue) external returns(bytes memory replacedValue);
    function batchSet(StateEntry[] calldata newValues) external returns(bytes[] memory replacedValues);

    function remove(string calldata key) external returns(bytes32 removedType, bytes memory removedValue);
    function batchRemove(string[] calldata keys) external returns(bytes32[] memory removedTypes, bytes[] memory removedValues);
    function removeByIndices(uint256[] calldata indices) external returns(bytes32[] memory removedTypes, bytes[] memory removedValues);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/dynamicMetadata/model/IDynamicMetadataCapableElement.sol";

interface IOrganization is IDynamicMetadataCapableElement {

    struct Component {
        bytes32 key;
        address location;
        bool active;
        bool log;
    }

    function keyOf(address componentAddress) external view returns(bytes32);
    function history(bytes32 key) external view returns(address[] memory componentsAddresses);
    function batchHistory(bytes32[] calldata keys) external view returns(address[][] memory componentsAddresses);

    function get(bytes32 key) external view returns(address componentAddress);
    function list(bytes32[] calldata keys) external view returns(address[] memory componentsAddresses);
    function isActive(address subject) external view returns(bool);
    function keyIsActive(bytes32 key) external view returns(bool);

    function set(Component calldata) external returns(address replacedComponentAddress);
    function batchSet(Component[] calldata) external returns (address[] memory replacedComponentAddresses);

    event ComponentSet(bytes32 indexed key, address indexed from, address indexed to, bool active);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IProposalsManager is IERC1155Receiver, ILazyInitCapableElement {

    struct ProposalCode {
        address location;
        bytes bytecode;
    }

    struct ProposalCodes {
        ProposalCode[] codes;
        bool alsoTerminate;
    }

    struct Proposal {
        address proposer;
        address[] codeSequence;
        uint256 creationBlock;
        uint256 accept;
        uint256 refuse;
        address triggeringRules;
        address[] canTerminateAddresses;
        address[] validatorsAddresses;
        bool validationPassed;
        uint256 terminationBlock;
        bytes votingTokens;
    }

    struct ProposalConfiguration {
        address[] collections;
        uint256[] objectIds;
        uint256[] weights;
        address creationRules;
        address triggeringRules;
        address[] canTerminateAddresses;
        address[] validatorsAddresses;
    }

    function batchCreate(ProposalCodes[] calldata codeSequences) external returns(bytes32[] memory createdProposalIds);

    function list(bytes32[] calldata proposalIds) external view returns(Proposal[] memory);

    function votes(bytes32[] calldata proposalIds, address[] calldata voters, bytes32[][] calldata items) external view returns(uint256[][] memory accepts, uint256[][] memory refuses, uint256[][] memory toWithdraw);
    function weight(bytes32 code) external view returns(uint256);

    function vote(address erc20TokenAddress, bytes memory permitSignature, bytes32 proposalId, uint256 accept, uint256 refuse, address voter, bool alsoTerminate) external payable;
    function batchVote(bytes[] calldata data) external payable;

    function withdrawAll(bytes32[] memory proposalIds, address voterOrReceiver, bool afterTermination) external;

    function terminate(bytes32[] calldata proposalIds) external;

    function configuration() external view returns(ProposalConfiguration memory);
    function setConfiguration(ProposalConfiguration calldata newValue) external returns(ProposalConfiguration memory oldValue);

    function lastProposalId() external view returns(bytes32);

    function lastVoteBlock(address voter) external view returns (uint256);

    event ProposalCreated(address indexed proposer, address indexed code, bytes32 indexed proposalId);
    event ProposalWeight(bytes32 indexed proposalId, address indexed collection, uint256 indexed id, bytes32 key, uint256 weight);
    event ProposalTerminated(bytes32 indexed proposalId, bool result, bytes errorData);

    event Accept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event MoveToAccept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event RetireAccept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);

    event Refuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event MoveToRefuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event RetireRefuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
}

interface IProposalChecker {
    function check(address proposalsManagerAddress, bytes32 id, bytes calldata data, address from, address voter) external view returns(bool);
}

interface IExternalProposalsManagerCommands {
    function createProposalCodeSequence(bytes32 proposalId, IProposalsManager.ProposalCode[] memory codeSequenceInput, address sender) external returns (address[] memory codeSequence, IProposalsManager.ProposalConfiguration memory localConfiguration);
    function proposalCanBeFinalized(bytes32 proposalId, IProposalsManager.Proposal memory proposal, bool validationPassed, bool result) external view returns (bool);
    function isVotable(bytes32 proposalId, IProposalsManager.Proposal memory proposal, address from, address voter, bool voteOrWithtraw) external view returns (bytes memory response);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../../core/model/IOrganization.sol";
import "../../../base/model/IProposalsManager.sol";

interface ISubDAO is IOrganization, IExternalProposalsManagerCommands {

    event Proposed(uint256 indexed modelIndex, uint256 indexed presetIndex, bytes32 indexed proposalId);

    struct SubDAOProposalModel {
        address source;
        string uri;
        bool isPreset;
        bytes[] presetValues;
        bytes32[] presetProposals;
        address creationRules;
        address triggeringRules;
        uint256 votingRulesIndex;
        address[][] canTerminateAddresses;
        address[][] validatorsAddresses;
    }

    function presetArrayMaxSize() external view returns(uint256);

    function proposalModels() external view returns(SubDAOProposalModel[] memory);
    function setProposalModels(SubDAOProposalModel[] calldata newValue) external returns(SubDAOProposalModel[] memory oldValue);

    function setInitialProposalModels(SubDAOProposalModel[] calldata newValue) external;

    function setVotingRules(uint256 modelIndex, uint256 votingRulesIndex) external returns(address[] memory oldCanTerminateAddresses, address[] memory oldValidatorsAddresses);
    function setCreationAndTriggeringRules(uint256 modelIndex, address newCreationRules, address newTriggeringRules) external returns(address oldCreationRules, address oldTriggeringRules);
    function setPresetValues(uint256 modelIndex, bytes[] calldata newPresetValues) external returns(bytes[] memory oldPresetValues, bytes32[] memory deprecatedProposalIds);

    function finalizeInit(address firstHost) external;

    function isPersistent(bytes32 proposalId) external view returns(bool result, bool isDeprecated);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../core/model/IOrganization.sol";
import "../subDAOsManager/model/ISubDAOsManager.sol";
import "../delegationsManager/model/IDelegationsManager.sol";
import "../treasurySplitterManager/model/ITreasurySplitterManager.sol";
import "../investmentsManager/model/IInvestmentsManager.sol";
import "../delegation/model/IDelegationTokensManager.sol";

library Grimoire {
    bytes32 constant public COMPONENT_KEY_TREASURY_SPLITTER_MANAGER = 0x87a92f6bd20613c184485be8eadb46851dd4294a8359f902606085b8be6e7ae6;
    bytes32 constant public COMPONENT_KEY_SUBDAOS_MANAGER = 0x5b87d6e94145c2e242653a71b7d439a3638a93c3f0d32e1ea876f9fb1feb53e2;
    bytes32 constant public COMPONENT_KEY_DELEGATIONS_MANAGER = 0x49b87f4ee20613c184485be8eadb46851dd4294a8359f902606085b8be6e7ae6;
    bytes32 constant public COMPONENT_KEY_INVESTMENTS_MANAGER = 0x4f3ad97a91794a00945c0ead3983f793d34044c6300048d8b4ef95636edd234b;
}

library DelegationGrimoire {
    bytes32 constant public COMPONENT_KEY_TOKENS_MANAGER = 0x62b56c3ab20613c184485be8eadb46851dd4294a8359f902606085b8be9f7dc5;
}

library Getters {
    function treasurySplitterManager(IOrganization organization) internal view returns(ITreasurySplitterManager) {
        return ITreasurySplitterManager(organization.get(Grimoire.COMPONENT_KEY_TREASURY_SPLITTER_MANAGER));
    }

    function subDAOsManager(IOrganization organization) internal view returns(ISubDAOsManager) {
        return ISubDAOsManager(organization.get(Grimoire.COMPONENT_KEY_SUBDAOS_MANAGER));
    }

    function delegationsManager(IOrganization organization) internal view returns(IDelegationsManager) {
        return IDelegationsManager(organization.get(Grimoire.COMPONENT_KEY_DELEGATIONS_MANAGER));
    }

    function investmentsManager(IOrganization organization) internal view returns(IInvestmentsManager) {
        return IInvestmentsManager(organization.get(Grimoire.COMPONENT_KEY_INVESTMENTS_MANAGER));
    }
}

library Setters {
    function replaceTreasurySplitterManager(IOrganization organization, address newComponentAddress) internal returns(ITreasurySplitterManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = ITreasurySplitterManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_TREASURY_SPLITTER_MANAGER, newComponentAddress, false, true)));
    }

    function replaceSubDAOsManager(IOrganization organization, address newComponentAddress) internal returns(ISubDAOsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = ISubDAOsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_SUBDAOS_MANAGER, newComponentAddress, true, true)));
    }

    function replaceDelegationsManager(IOrganization organization, address newComponentAddress) internal returns(IDelegationsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IDelegationsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_DELEGATIONS_MANAGER, newComponentAddress, false, true)));
    }

    function replaceInvestmentsManager(IOrganization organization, address newComponentAddress) internal returns(IInvestmentsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IInvestmentsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_INVESTMENTS_MANAGER, newComponentAddress, false, true)));
    }
}

library DelegationGetters {
    function tokensManager(IOrganization organization) internal view returns(IDelegationTokensManager) {
        return IDelegationTokensManager(organization.get(DelegationGrimoire.COMPONENT_KEY_TOKENS_MANAGER));
    }
}

library DelegationUtilities {
    using DelegationGetters for IOrganization;

    function extractVotingTokens(address delegationsManagerAddress, address delegationAddress) internal view returns (bytes memory) {
        IDelegationsManager delegationsManager = IDelegationsManager(delegationsManagerAddress);
        (bool exists,,) = delegationsManager.exists(delegationAddress);
        require(exists, "wrong address");
        (address collection, uint256 tokenId) = delegationsManager.supportedToken();
        (collection, tokenId) = IOrganization(delegationAddress).tokensManager().wrapped(collection, tokenId, delegationsManagerAddress);
        require(tokenId != 0, "Wrap tokens first");
        address[] memory collections = new address[](1);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory weights = new uint256[](1);
        collections[0] = collection;
        tokenIds[0] = tokenId;
        weights[0] = 1;
        return abi.encode(collections, tokenIds, weights);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library BehaviorUtilities {

    function randomKey(uint256 i) internal view returns (bytes32) {
        return keccak256(abi.encode(i, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function calculateProjectedArraySizeAndLoopUpperBound(uint256 arraySize, uint256 start, uint256 offset) internal pure returns(uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) {
        if(arraySize != 0 && start < arraySize && offset != 0) {
            uint256 length = start + offset;
            if(start < (length = length > arraySize ? arraySize : length)) {
                projectedArraySize = (projectedArrayLoopUpperBound = length) - start;
            }
        }
    }
}

library ReflectionUtilities {

    function read(address subject, bytes memory inputData) internal view returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.staticcall(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function submit(address subject, uint256 value, bytes memory inputData) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.call{value : value}(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function isContract(address subject) internal view returns (bool) {
        if(subject == address(0)) {
            return false;
        }
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(subject)
        }
        return codeLength > 0;
    }

    function clone(address originalContract) internal returns(address copyContract) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(originalContract, 0x1000000000000000000)
                )
            )
            copyContract := create(0, 0, 32)
            switch extcodesize(copyContract)
                case 0 {
                    invalid()
                }
        }
    }
}

library BytesUtilities {

    bytes private constant ALPHABET = "0123456789abcdef";
    string internal constant BASE64_ENCODER_DATA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function asAddress(bytes memory b) internal pure returns(address) {
        if(b.length == 0) {
            return address(0);
        }
        if(b.length == 20) {
            address addr;
            assembly {
                addr := mload(add(b, 20))
            }
            return addr;
        }
        return abi.decode(b, (address));
    }

    function asAddressArray(bytes memory b) internal pure returns(address[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (address[]));
        }
    }

    function asBool(bytes memory bs) internal pure returns(bool) {
        return asUint256(bs) != 0;
    }

    function asBoolArray(bytes memory b) internal pure returns(bool[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bool[]));
        }
    }

    function asBytesArray(bytes memory b) internal pure returns(bytes[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bytes[]));
        }
    }

    function asString(bytes memory b) internal pure returns(string memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string));
        }
    }

    function asStringArray(bytes memory b) internal pure returns(string[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string[]));
        }
    }

    function asUint256(bytes memory bs) internal pure returns(uint256 x) {
        if (bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }

    function asUint256Array(bytes memory b) internal pure returns(uint256[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (uint256[]));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2+i*2] = ALPHABET[uint256(uint8(data[i] >> 4))];
            str[3+i*2] = ALPHABET[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function asSingletonArray(bytes memory a) internal pure returns(bytes[] memory array) {
        array = new bytes[](1);
        array[0] = a;
    }

    function toBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        string memory table = BASE64_ENCODER_DATA;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

library StringUtilities {

    bytes1 private constant CHAR_0 = bytes1('0');
    bytes1 private constant CHAR_A = bytes1('A');
    bytes1 private constant CHAR_a = bytes1('a');
    bytes1 private constant CHAR_f = bytes1('f');

    bytes  internal constant BASE64_DECODER_DATA = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                                   hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                                   hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                                   hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function isEmpty(string memory test) internal pure returns (bool) {
        return equals(test, "");
    }

    function equals(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint256 i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function asBytes(string memory str) internal pure returns(bytes memory toDecode) {
        bytes memory data = abi.encodePacked(str);
        if(data.length == 0 || data[0] != "0" || (data[1] != "x" && data[1] != "X")) {
            return "";
        }
        uint256 start = 2;
        toDecode = new bytes((data.length - 2) / 2);

        for(uint256 i = 0; i < toDecode.length; i++) {
            toDecode[i] = bytes1(_fromHexChar(uint8(data[start++])) + _fromHexChar(uint8(data[start++])) * 16);
        }
    }

    function toBase64(string memory input) internal pure returns(string memory) {
        return BytesUtilities.toBase64(abi.encodePacked(input));
    }

    function fromBase64(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        bytes memory table = BASE64_DECODER_DATA;

        uint256 decodedLen = (data.length / 4) * 3;

        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            mstore(result, decodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        bytes1 charc = bytes1(c);
        return charc < CHAR_0 || charc > CHAR_f ? 0 : (charc < CHAR_A ? 0 : 10) + c - uint8(charc < CHAR_A ? CHAR_0 : charc < CHAR_a ? CHAR_A : CHAR_a);
    }
}

library Uint256Utilities {
    function asSingletonArray(uint256 n) internal pure returns(uint256[] memory array) {
        array = new uint256[](1);
        array[0] = n;
    }

    function toHex(uint256 _i) internal pure returns (string memory) {
        return BytesUtilities.toString(abi.encodePacked(_i));
    }

    function toString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function sum(uint256[] memory arr) internal pure returns (uint256 result) {
        for(uint256 i = 0; i < arr.length; i++) {
            result += arr[i];
        }
    }
}

library AddressUtilities {
    function asSingletonArray(address a) internal pure returns(address[] memory array) {
        array = new address[](1);
        array[0] = a;
    }

    function toString(address _addr) internal pure returns (string memory) {
        return _addr == address(0) ? "0x0000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(_addr));
    }
}

library Bytes32Utilities {

    function asSingletonArray(bytes32 a) internal pure returns(bytes32[] memory array) {
        array = new bytes32[](1);
        array[0] = a;
    }

    function toString(bytes32 bt) internal pure returns (string memory) {
        return bt == bytes32(0) ?  "0x0000000000000000000000000000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(bt));
    }
}

library TransferUtilities {
    using ReflectionUtilities for address;

    function balanceOf(address erc20TokenAddress, address account) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return account.balance;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).balanceOf.selector, account)), (uint256));
    }

    function allowance(address erc20TokenAddress, address account, address spender) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return 0;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).allowance.selector, account, spender)), (uint256));
    }

    function safeApprove(address erc20TokenAddress, address spender, uint256 value) internal {
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, spender, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function safeTransfer(address erc20TokenAddress, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IEthereansFactory.sol";
import "@ethereansos/swissknife/contracts/factory/impl/Factory.sol";
import "../../factoryOfFactories/model/IFactoryOfFactories.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { TransferUtilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

abstract contract EthereansFactory is Factory, IEthereansFactory {
    using TransferUtilities for address;

    uint256 internal _feePercentageForTransacted;
    address internal _feeReceiver;
    address internal _tokenToTransferOrBurnAddressInCreation;
    uint256 internal _transferOrBurnAmountInCreation;
    address internal _transferOrBurnReceiverInCreation;
    address internal _tokenToTransferOrBurnAddressInApplication;
    uint256 internal _transferOrBurnAmountInApplication;
    address internal _transferOrBurnReceiverInApplication;

    constructor(bytes memory lazyInitData) Factory(lazyInitData) {
    }

    receive() external payable {
    }

    function _factoryLazyInit(bytes memory initData) internal override virtual returns (bytes memory factoryLazyInitResponse) {
        EthereansFactoryInitializer memory ethereansFactoryInitializer;
        (ethereansFactoryInitializer) = abi.decode(initData, (EthereansFactoryInitializer));
        _feePercentageForTransacted = ethereansFactoryInitializer.feePercentageForTransacted;
        _feeReceiver = ethereansFactoryInitializer.feeReceiver;
        _tokenToTransferOrBurnAddressInCreation = ethereansFactoryInitializer.tokenToTransferOrBurnAddressInCreation;
        _transferOrBurnAmountInCreation = ethereansFactoryInitializer.transferOrBurnAmountInCreation;
        _transferOrBurnReceiverInCreation = ethereansFactoryInitializer.transferOrBurnReceiverInCreation;
        _tokenToTransferOrBurnAddressInApplication = ethereansFactoryInitializer.tokenToTransferOrBurnAddressInApplication;
        _transferOrBurnAmountInApplication = ethereansFactoryInitializer.transferOrBurnAmountInApplication;
        _transferOrBurnReceiverInApplication = ethereansFactoryInitializer.transferOrBurnReceiverInApplication;
        factoryLazyInitResponse = _ethosFactoryLazyInit(ethereansFactoryInitializer.factoryLazyInitData);
    }

    function feeInfo() public override view returns(address operator, uint256 feePercentageForTransacted, address feeReceiver, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) {
        operator = initializer;
        (feePercentageForTransacted, feeReceiver, tokenToTransferOrBurnAddressInCreation, transferOrBurnAmountInCreation, transferOrBurnReceiverInCreation, tokenToTransferOrBurnAddressInApplication, transferOrBurnAmountInApplication, transferOrBurnReceiverInApplication) = _realFeeInfo();
    }

    function payFee(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature) external override payable returns (uint256 feePaid) {
        (uint256 feePercentageForTransacted, address feeReceiver, , , , , uint256 transferOrBurnAmountInApplication, ) = _realFeeInfo();
        if(feePercentageForTransacted != 0) {
            (uint256 feeSentOrBurnt, uint256 fofFeePaid) = IFactoryOfFactories(initializer).payFee{value : tokenAddress == address(0) ? value : 0}(sender, tokenAddress, value, permitSignature, feePercentageForTransacted, feeReceiver);
            feePaid = feeSentOrBurnt + fofFeePaid;
            _feePaid(sender, tokenAddress, value, feeSentOrBurnt, fofFeePaid, feePercentageForTransacted, feeReceiver);
        } else {
            require(transferOrBurnAmountInApplication == 0, "zero fees");
        }
    }

    function _feePaid(address sender, address tokenAddress, uint256 value, uint256 feeSentOrBurnt, uint256 feePaid, uint256 feePercentageForTransacted, address feeReceiver) internal virtual {
    }

    function burnOrTransferToken(address sender, bytes calldata permitSignature) external payable override returns(uint256 amountTransferedOrBurnt) {
        (uint256 feePercentageForTransacted, , , , , address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) = _realFeeInfo();
        if(transferOrBurnAmountInApplication != 0) {
            (uint256 feeSentOrBurnt, uint256 fofAmountTransferedOrBurnt) = IFactoryOfFactories(initializer).burnOrTransferTokenAmount{value : tokenToTransferOrBurnAddressInApplication == address(0) ? transferOrBurnAmountInApplication : 0}(sender, tokenToTransferOrBurnAddressInApplication, transferOrBurnAmountInApplication, permitSignature, transferOrBurnReceiverInApplication);
            amountTransferedOrBurnt = feeSentOrBurnt + fofAmountTransferedOrBurnt;
            _amountTransferedOrBurnt(sender, feeSentOrBurnt, fofAmountTransferedOrBurnt, tokenToTransferOrBurnAddressInApplication, transferOrBurnAmountInApplication, transferOrBurnReceiverInApplication);
        } else {
            require(feePercentageForTransacted == 0, "zero amount");
        }
    }

    function _amountTransferedOrBurnt(address sender, uint256 feeSentOrBurnt, uint256 amountTransferedOrBurnt, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) internal virtual {
    }

    function _burnOrTransferTokenAtCreation(address sender, bytes memory permitSignature) internal returns(uint256 amountTransferedOrBurnt) {
        (, , address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, , , ) = _realFeeInfo();
        if(transferOrBurnAmountInCreation != 0) {
            (uint256 feeSentOrBurnt, uint256 fofAmountTransferedOrBurnt) = IFactoryOfFactories(initializer).burnOrTransferTokenAmount{value : tokenToTransferOrBurnAddressInCreation == address(0) ? transferOrBurnAmountInCreation : 0}(sender, tokenToTransferOrBurnAddressInCreation, transferOrBurnAmountInCreation, permitSignature, transferOrBurnReceiverInCreation);
            amountTransferedOrBurnt = feeSentOrBurnt + fofAmountTransferedOrBurnt;
            _amountTransferedOrBurntAtCreation(sender, feeSentOrBurnt, fofAmountTransferedOrBurnt, tokenToTransferOrBurnAddressInCreation, transferOrBurnAmountInCreation, transferOrBurnReceiverInCreation);
        }
    }

    function _amountTransferedOrBurntAtCreation(address sender, uint256 feeSentOrBurnt, uint256 amountTransferedOrBurnt, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation) internal virtual {
    }

    function _subjectIsAuthorizedFor(address, address, bytes4 selector, bytes calldata, uint256) internal override pure returns (bool, bool) {
        if(selector == this.setModelAddress.selector || selector == this.setDynamicUriResolver.selector) {
            return (true, false);
        }
        return (false, false);
    }

    function _realFeeInfo() internal virtual view returns(uint256 feePercentageForTransacted, address feeReceiver, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) {
        return (_feePercentageForTransacted, _feeReceiver, _tokenToTransferOrBurnAddressInCreation, _transferOrBurnAmountInCreation, _transferOrBurnReceiverInCreation, _tokenToTransferOrBurnAddressInApplication, _transferOrBurnAmountInApplication, _transferOrBurnReceiverInApplication);
    }

    function _ethosFactoryLazyInit(bytes memory lazyInitData) internal virtual returns(bytes memory lazyInitResponse);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganizationFactory.sol";
import { IDelegationRulesChanger } from "../../../ext/delegation/impl/DelegationProposals.sol";

interface IDelegationFactory is IOrganizationFactory, IDelegationRulesChanger {

    function initializeProposalModels(
        address delegationAddress,
        address host,
        uint256 quorum,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCap) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IDelegationTokensManager is ILazyInitCapableElement, IERC1155Receiver {

    event Wrapped(address sourceAddress, uint256 sourceObjectId, address indexed sourceDelegationsManagerAddress, uint256 indexed wrappedObjectId);

    function itemMainInterfaceAddress() external view returns(address);
    function projectionAddress() external view returns(address);
    function collectionId() external view returns(bytes32);
    function ticker() external view returns(string memory);

    function wrap(address sourceDelegationsManagerAddress, bytes memory permitSignature, uint256 amount, address receiver) payable external returns(uint256 wrappedObjectId);

    function wrapped(address sourceCollection, uint256 sourceObjectId, address sourceDelegationsManagerAddress) external view returns(address wrappedCollection, uint256 wrappedObjectId);
    function source(uint256 wrappedObjectId) external view returns(address sourceCollectionAddress, uint256 sourceObjectId, address sourceDelegationsManagerAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "@ethereansos/covenants/contracts/presto/IPrestoUniV3.sol";

interface IInvestmentsManager is ILazyInitCapableElement {

    function ONE_HUNDRED() external pure returns(uint256);

    function refundETHReceiver() external view returns(bytes32 key, address receiverAddress);

    function executorRewardPercentage() external view returns(uint256);

    function prestoAddress() external view returns(address prestoAddress);

    function tokenFromETHToBurn() external view returns(address addr);

    function tokensFromETH() external view returns(address[] memory addresses);
    function setTokensFromETH(address[] calldata addresses) external returns(address[] memory oldAddresses);

    function swapFromETH(PrestoOperation[] calldata tokensFromETHData, PrestoOperation calldata tokenFromETHToBurnData, address executorRewardReceiver) external returns (uint256[] memory tokenAmounts, uint256 tokenFromETHToBurnAmount, uint256 executorReward);

    function lastSwapToETHBlock() external view returns (uint256);

    function swapToETHInterval() external view returns (uint256);

    function nextSwapToETHBlock() external view returns (uint256);

    function tokensToETH() external view returns(address[] memory addresses, uint256[] memory percentages);
    function setTokensToETH(address[] calldata addresses, uint256[] calldata percentages) external returns(address[] memory oldAddresses, uint256[] memory oldPercentages);

    function swapToETH(PrestoOperation[] calldata tokensToETHData, address executorRewardReceiver) external returns (uint256[] memory executorRewards, uint256[] memory ethAmounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface ITreasurySplitterManager is ILazyInitCapableElement {

    event Splitted(bytes32 indexed subDAO, address indexed receiver, uint256 amount);

    function ONE_HUNDRED() external pure returns(uint256);

    function lastSplitBlock() external view returns (uint256);

    function splitInterval() external view returns (uint256);

    function nextSplitBlock() external view returns (uint256);

    function executorRewardPercentage() external view returns(uint256);

    function flushExecutorRewardPercentage() external view returns(uint256);

    function receiversAndPercentages() external view returns (bytes32[] memory keys, address[] memory addresses, uint256[] memory percentages);

    function flushReceiver() external view returns(bytes32 key, address addr);

    function flushERC20Tokens(address[] calldata tokenAddresses, address executorRewardReceiver) external;

    function splitTreasury(address executorRewardReceiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IDelegationsManager is ILazyInitCapableElement {

    event DelegationSet(address indexed delegationAddress, address indexed treasuryAddress);
    event SupportedToken(address indexed collectionAddress, uint256 indexed objectId);
    event Factory(address indexed factory, bool indexed allowed);

    struct DelegationData {
        address location;
        address treasury;
    }

    function split(address executorRewardReceiver) external;

    function supportedToken() external view returns(address collection, uint256 objectId);
    function setSupportedToken(address collection, uint256 tokenId) external;

    function maxSize() external view returns(uint256);
    function setMaxSize(uint256 newValue) external returns (uint256 oldValue);

    function size() external view returns (uint256);
    function list() external view returns (DelegationData[] memory);
    function partialList(uint256 start, uint256 offset) external view returns (DelegationData[] memory);
    function listByAddresses(address[] calldata delegationAddresses) external view returns (DelegationData[] memory);
    function listByIndices(uint256[] calldata indices) external view returns (DelegationData[] memory);

    function exists(address delegationAddress) external view returns(bool result, uint256 index, address treasuryOf);
    function treasuryOf(address delegationAddress) external view returns(address treasuryAddress);

    function get(address delegationAddress) external view returns(DelegationData memory);
    function getByIndex(uint256 index) external view returns(DelegationData memory);

    function set() external;

    function remove(address[] calldata delegationAddresses) external returns(DelegationData[] memory removedDelegations);
    function removeAll() external;

    function executorRewardPercentage() external view returns(uint256);

    function getSplit(address executorRewardReceiver) external view returns (address[] memory receivers, uint256[] memory values);
    function getSituation() external view returns(address[] memory treasuries, uint256[] memory treasuryPercentages);

    function factoryIsAllowed(address factoryAddress) external view returns(bool);
    function setFactoriesAllowed(address[] memory factoryAddresses, bool[] memory allowed) external;

    function isBanned(address productAddress) external view returns(bool);
    function ban(address[] memory productAddresses) external;

    function isValid(address delegationAddress) external view returns(bool);

    event PaidFor(address indexed delegationAddress, address indexed from, address indexed retriever, uint256 amount);

    function paidFor(address delegationAddress, address retriever) external view returns(uint256 totalPaid, uint256 retrieverPaid);
    function payFor(address delegationAddress, uint256 amount, bytes memory permitSignature, address retriever) external payable;
    function retirePayment(address delegationAddress, address receiver, bytes memory data) external;
    function attachInsurance() external view returns (uint256);
    function setAttachInsurance(uint256 value) external returns (uint256 oldValue);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface ISubDAOsManager is ILazyInitCapableElement {

    struct SubDAOEntry {
        bytes32 key;
        address location;
        address newHost;
    }

    function keyOf(address subdaoAddress) external view returns(bytes32);
    function history(bytes32 key) external view returns(address[] memory subdaosAddresses);
    function batchHistory(bytes32[] calldata keys) external view returns(address[][] memory subdaosAddresses);

    function get(bytes32 key) external view returns(address subdaoAddress);
    function list(bytes32[] calldata keys) external view returns(address[] memory subdaosAddresses);
    function exists(address subject) external view returns(bool);
    function keyExists(bytes32 key) external view returns(bool);

    function set(bytes32 key, address location, address newHost) external returns(address replacedSubdaoAddress);
    function batchSet(SubDAOEntry[] calldata) external returns (address[] memory replacedSubdaoAddresses);

    function submit(bytes32 key, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);

    event SubDAOSet(bytes32 indexed key, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IFactory.sol";
import "../../dynamicMetadata/impl/DynamicMetadataCapableElement.sol";
import { ReflectionUtilities } from "../../lib/GeneralUtilities.sol";

contract Factory is IFactory, DynamicMetadataCapableElement {
    using ReflectionUtilities for address;

    address public override modelAddress;
    mapping(address => address) public override deployer;

    constructor(bytes memory lazyInitData) DynamicMetadataCapableElement(lazyInitData) {
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal override returns (bytes memory lazyInitResponse) {
        require(modelAddress == address(0), "init");
        (modelAddress, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        lazyInitResponse = _factoryLazyInit(lazyInitResponse);
    }

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) override internal view returns(bool) {
        return
            interfaceId == type(IFactory).interfaceId ||
            interfaceId == this.modelAddress.selector ||
            interfaceId == this.setModelAddress.selector ||
            interfaceId == this.deployer.selector ||
            interfaceId == this.deploy.selector ||
            _factorySupportsInterface(interfaceId);
    }

    function setModelAddress(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = modelAddress;
        modelAddress = newValue;
    }

    function deploy(bytes calldata deployData) external payable override virtual returns(address deployedAddress, bytes memory deployedLazyInitResponse) {
        deployer[deployedAddress = modelAddress.clone()] = msg.sender;
        emit Deployed(modelAddress, deployedAddress, msg.sender, deployedLazyInitResponse = ILazyInitCapableElement(deployedAddress).lazyInit(deployData));
        require(ILazyInitCapableElement(deployedAddress).initializer() == address(this));
    }

    function _factoryLazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _factorySupportsInterface(bytes4 interfaceId) internal virtual view returns(bool) {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../delegationsManager/model/IDelegationsManager.sol";
import "@ethereansos/swissknife/contracts/factory/model/IFactory.sol";
import "../../../base/model/IProposalsManager.sol";
import "../../../base/model/ITreasuryManager.sol";
import "../../../core/model/IOrganization.sol";
import { Getters } from "../../../base/lib/KnowledgeBase.sol";
import { Uint256Utilities, AddressUtilities, TransferUtilities, Bytes32Utilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";
import "../../../ext/subDAO/model/ISubDAO.sol";
import { Getters as ExternalGetters, DelegationUtilities } from "../../../ext/lib/KnowledgeBase.sol";
import "../../../ethereans/factories/model/IDelegationFactory.sol";

contract DelegationsManagerAttacherProposal {
    using AddressUtilities for address;

    string public uri;
    address public delegationsManagerAddress;

    string public additionalUri;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (additionalUri, delegationsManagerAddress) = abi.decode(lazyInitResponseData, (string, address));

        lazyInitResponseData = "";
    }

    function execute(bytes32) external {
        IOrganization organization = IOrganization(ILazyInitCapableElement(msg.sender).host());
        organization.submit(delegationsManagerAddress, abi.encodeWithSignature("set()"), address(0));
    }
}

contract DelegationTransferManagerProposal {
    string public uri;
    address public treasuryManagerAddress;
    ITreasuryManager.TransferEntry[] public entries;

    string public additionalUri;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        ITreasuryManager.TransferEntry[] memory _entries;
        (additionalUri, treasuryManagerAddress, _entries) = abi.decode(lazyInitResponseData, (string, address, ITreasuryManager.TransferEntry[]));
        for(uint256 i = 0; i < _entries.length; i++) {
            entries.push(_entries[i]);
        }

        require(ILazyInitCapableElement(treasuryManagerAddress).host() == msg.sender, "Wrong Treasury Manager");

        lazyInitResponseData = DelegationUtilities.extractVotingTokens(ILazyInitCapableElement(treasuryManagerAddress).initializer(), msg.sender);
    }

    function execute(bytes32) external {
        ITreasuryManager(treasuryManagerAddress).batchTransfer(entries);
    }

    function allEntries() external view returns(ITreasuryManager.TransferEntry[] memory) {
        return entries;
    }
}

contract VoteProposal {
    using Getters for IOrganization;
    using ExternalGetters for IOrganization;
    using Uint256Utilities for uint256;
    using TransferUtilities for address;
    using Bytes32Utilities for bytes32;

    string public uri;
    address public proposalsManagerAddress;
    bytes32 public organizationProposalID;
    address public collectionAddress;
    uint256 public objectId;
    uint256 public accept;
    uint256 public refuse;
    bool public vote;
    bool public afterTermination;

    bool public _voting;

    string public additionalUri;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        _lazyInit1(lazyInitResponseData);

        lazyInitResponseData = DelegationUtilities.extractVotingTokens(address(IOrganization(ILazyInitCapableElement(proposalsManagerAddress).host()).delegationsManager()), msg.sender);
    }

    function _lazyInit1(bytes memory lazyInitResponseData) private {
        (proposalsManagerAddress, organizationProposalID, collectionAddress, lazyInitResponseData) = abi.decode(lazyInitResponseData, (address, bytes32, address, bytes));
        _lazyInit2(lazyInitResponseData);
    }

    function _lazyInit2(bytes memory lazyInitResponseData) private {
        (objectId, accept, refuse, vote, afterTermination, additionalUri) = abi.decode(lazyInitResponseData, (uint256, uint256, uint256, bool, bool, string));
    }

    receive() external payable {
        require(_voting, "not voting");
    }

    function execute(bytes32) external {
        ITreasuryManager treasuryManager = IOrganization(ILazyInitCapableElement(msg.sender).host()).treasuryManager();
        return vote ? _vote(treasuryManager) : _withdraw(treasuryManager);
    }

    function _vote(ITreasuryManager treasuryManager) private {
        bool hasERC20 = collectionAddress == address(0);
        ITreasuryManager.TransferEntry[] memory transferEntries = new ITreasuryManager.TransferEntry[](1);
        transferEntries[0] = ITreasuryManager.TransferEntry({
            token : hasERC20 ? address(uint160(objectId)) : collectionAddress,
            objectIds : hasERC20 ? new uint256[](0) : objectId.asSingletonArray(),
            values : (accept + refuse).asSingletonArray(),
            receiver : hasERC20 ? address(this) : proposalsManagerAddress,
            safe : false,
            batch : false,
            withData : false,
            data : hasERC20 ? bytes("") : abi.encode(organizationProposalID, accept, refuse, address(treasuryManager), false)
        });
        _voting = hasERC20;
        treasuryManager.batchTransfer(transferEntries);
        _voting = false;
        IProposalsManager proposalsManager = IProposalsManager(proposalsManagerAddress);
        if(hasERC20) {
            address erc20TokenAddress = address(uint160(objectId));
            if(erc20TokenAddress != address(0)) {
                erc20TokenAddress.safeApprove(proposalsManagerAddress, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            }
            proposalsManager.vote{value : erc20TokenAddress != address(0) ? 0 : (accept + refuse)}(erc20TokenAddress, "", organizationProposalID, accept, refuse, address(treasuryManager), false);
        }
    }

    function _withdraw(ITreasuryManager treasuryManager) private {
        treasuryManager.submit(proposalsManagerAddress, abi.encodeWithSelector(IProposalsManager(proposalsManagerAddress).withdrawAll.selector, organizationProposalID.asSingletonArray(), address(treasuryManager), afterTermination), address(treasuryManager));
    }
}

interface IDelegationRulesChanger {

    function createNewRules(
        address delegationAddress,
        uint256 quorum,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCap) external returns (address[] memory validationAddresses, address[] memory canTerminateAddresses);
}

contract DelegationChangeRulesProposal {
    string public uri;

    uint256 public quorum;

    uint256 public validationBomb;

    uint256 public blockLength;

    uint256 public hardCap;

    string public additionalUri;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (additionalUri, quorum, validationBomb, blockLength, hardCap) = abi.decode(lazyInitResponseData, (string, uint256, uint256, uint256, uint256));

        require(blockLength > 0 || hardCap > 0, "No termination rules");

        lazyInitResponseData = "";
    }

    function execute(bytes32) external {
        ISubDAO subDAO = ISubDAO(ILazyInitCapableElement(msg.sender).host());

        (address[] memory validators, address[] memory canTerminates) = IDelegationRulesChanger(subDAO.initializer()).createNewRules(address(subDAO), quorum, validationBomb, blockLength, hardCap);

        ISubDAO.SubDAOProposalModel[] memory proposalModels = subDAO.proposalModels();

        ISubDAO.SubDAOProposalModel memory prop = proposalModels[proposalModels.length - 2];
        prop.validatorsAddresses[0] = validators;
        prop.canTerminateAddresses[0] = canTerminates;
        proposalModels[proposalModels.length - 2] = prop;

        prop = proposalModels[proposalModels.length - 1];
        prop.validatorsAddresses[0] = validators;
        prop.canTerminateAddresses[0] = canTerminates;
        proposalModels[proposalModels.length - 1] = prop;

        subDAO.setProposalModels(proposalModels);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IEthereansFactory.sol";

interface IOrganizationFactory is IEthereansFactory {

    struct OrganizationDeployData {
        string uri;
        bytes[] mandatoryComponentsDeployData;
        uint256[] additionalComponents;
        bytes[] additionalComponentsDeployData;
        bytes[] specialComponentsData;
        bytes specificOrganizationData;
    }

    function data() external view returns(address[] memory utilityModels, bytes32[] memory utilitiyModelKeys, bool[] memory utilitiyModelActive, string memory proposalUri);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
pragma solidity >=0.7.0;

interface IFactoryOfFactories {

    function size() external view returns (uint256);
    function all() external view returns (address[] memory hosts, address[][] memory factoryLists);
    function partialList(uint256 start, uint256 offset) external view returns (address[] memory hosts, address[][] memory factoryLists);

    function get(uint256 index) external view returns(address host, address[] memory factoryList);

    function create(address[] calldata hosts, bytes[][] calldata factoryBytecodes) external returns (address[][] memory factoryLists, uint256[] memory listPositions);
    function setFactoryListsMetadata(uint256[] calldata listPositions, address[] calldata newHosts) external returns (address[] memory replacedHosts);
    event FactoryList(uint256 indexed listPosition, address indexed fromHost, address indexed toHost);

    function add(uint256[] calldata listPositions, bytes[][] calldata factoryBytecodes) external returns(address[][] memory factoryLists, uint256[][] memory factoryPositions);
    event FactoryAdded(uint256 indexed listPosition, address indexed host, address indexed factoryAddress, uint256 factoryPosition);

    function payFee(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature, uint256 feePercentage, address feeReceiver) external payable returns (uint256 feeSentOrBurnt, uint256 feePaid);
    function burnOrTransferTokenAmount(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature, address receiver) external payable returns(uint256 feeSentOrBurnt, uint256 amountTransferedOrBurnt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/factory/model/IFactory.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IEthereansFactory is IFactory {

    struct EthereansFactoryInitializer {
        uint256 feePercentageForTransacted;
        address feeReceiver;
        address tokenToTransferOrBurnAddressInCreation;
        uint256 transferOrBurnAmountInCreation;
        address transferOrBurnReceiverInCreation;
        address tokenToTransferOrBurnAddressInApplication;
        uint256 transferOrBurnAmountInApplication;
        address transferOrBurnReceiverInApplication;
        bytes factoryLazyInitData;
    }

    function feeInfo() external view returns(address operator, uint256 feePercentageForTransacted, address feeReceiver, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication);

    function payFee(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature) external payable returns (uint256 feePaid);
    function burnOrTransferToken(address sender, bytes calldata permitSignature) external payable returns(uint256 amountTransferedOrBurnt);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../generic/model/ILazyInitCapableElement.sol";

interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
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
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface ITreasuryManager is ILazyInitCapableElement {

    struct TransferEntry {
        address token;
        uint256[] objectIds;
        uint256[] values;
        address receiver;
        bool safe;
        bool batch;
        bool withData;
        bytes data;
    }

    function transfer(address token, uint256 value, address receiver, uint256 tokenType, uint256 objectId, bool safe, bool withData, bytes calldata data) external returns(bool result, bytes memory returnData);
    function batchTransfer(TransferEntry[] calldata transferEntries) external returns(bool[] memory results, bytes[] memory returnDatas);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);

    function setAdditionalFunction(bytes4 selector, address newServer, bool log) external returns (address oldServer);
    event AdditionalFunction(address caller, bytes4 indexed selector, address indexed oldServer, address indexed newServer);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IMicroservicesManager is ILazyInitCapableElement {

    struct Microservice {
        string key;
        address location;
        string methodSignature;
        bool submittable;
        string returnAbiParametersArray;
        bool isInternal;
        bool needsSender;
    }

    function size() external view returns (uint256);
    function all() external view returns (Microservice[] memory);
    function partialList(uint256 start, uint256 offset) external view returns (Microservice[] memory);
    function list(string[] calldata keys) external view returns (Microservice[] memory);
    function listByIndices(uint256[] calldata indices) external view returns (Microservice[] memory);

    function exists(string calldata key) external view returns(bool result, uint256 index);

    function get(string calldata key) external view returns(Microservice memory);
    function getByIndex(uint256 index) external view returns(Microservice memory);

    function set(Microservice calldata newValue) external returns(Microservice memory replacedValue);
    function batchSet(Microservice[] calldata newValues) external returns(Microservice[] memory replacedValues);

    event MicroserviceAdded(address indexed sender, bytes32 indexed keyHash, string key, address indexed location, string methodSignature, bool submittable, string returnAbiParametersArray, bool isInternal, bool needsSender);

    function remove(string calldata key) external returns(Microservice memory removedValue);
    function batchRemove(string[] calldata keys) external returns(Microservice[] memory removedValues);
    function removeByIndices(uint256[] calldata indices) external returns(Microservice[] memory removedValues);

    event MicroserviceRemoved(address indexed sender, bytes32 indexed keyHash, string key, address indexed location, string methodSignature, bool submittable, string returnAbiParametersArray, bool isInternal, bool needsSender);

    function read(string calldata key, bytes calldata data) external view returns(bytes memory returnData);
    function submit(string calldata key, bytes calldata data) external payable returns(bytes memory returnData);
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

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC1155Views.sol";

struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata newValues) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "./PrestoDataUniV3.sol";

interface IPrestoUniV3 {

    function ONE_HUNDRED() external view returns (uint256);
    function doubleProxy() external view returns (address);
    function feePercentage() external view returns (uint256);

    function feePercentageInfo() external view returns (uint256, address);

    function setDoubleProxy(address _doubleProxy) external;

    function setFeePercentage(uint256 _feePercentage) external;

    function execute(PrestoOperation[] memory operations) external payable returns(uint256[] memory outputAmounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../dynamicMetadata/model/IDynamicMetadataCapableElement.sol";

interface IFactory is IDynamicMetadataCapableElement {

    event Deployed(address indexed modelAddress, address indexed deployedAddress, address indexed deployer, bytes deployedLazyInitResponse);

    function modelAddress() external view returns(address);
    function setModelAddress(address newValue) external returns(address oldValue);

    function deployer(address deployedAddress) external view returns(address);

    function deploy(bytes calldata deployData) external payable returns(address deployedAddress, bytes memory deployedLazyInitResponse);
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IDynamicMetadataCapableElement.sol";
import "../model/IDynamicUriResolver.sol";
import "../../generic/impl/LazyInitCapableElement.sol";

abstract contract DynamicMetadataCapableElement is IDynamicMetadataCapableElement, LazyInitCapableElement {

    string public override plainUri;
    address public override dynamicUriResolver;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory lazyInitResponse) {
        (plainUri, dynamicUriResolver, lazyInitResponse) = abi.decode(lazyInitData, (string, address, bytes));
        lazyInitResponse = _dynamicMetadataElementLazyInit(lazyInitResponse);
    }

    function _supportsInterface(bytes4 interfaceId) internal override view returns(bool) {
        return
            interfaceId == type(IDynamicMetadataCapableElement).interfaceId ||
            interfaceId == this.plainUri.selector ||
            interfaceId == this.uri.selector ||
            interfaceId == this.dynamicUriResolver.selector ||
            interfaceId == this.setUri.selector ||
            interfaceId == this.setDynamicUriResolver.selector ||
            _dynamicMetadataElementSupportsInterface(interfaceId);
    }

    function uri() external override view returns(string memory) {
        return _uri(plainUri, "");
    }

    function setUri(string calldata newValue) external override authorizedOnly returns (string memory oldValue) {
        oldValue = plainUri;
        plainUri = newValue;
    }

    function setDynamicUriResolver(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = dynamicUriResolver;
        dynamicUriResolver = newValue;
    }

    function _uri(string memory _plainUri, bytes memory additionalData) internal view returns(string memory) {
        if(dynamicUriResolver == address(0)) {
            return _plainUri;
        }
        return IDynamicUriResolver(dynamicUriResolver).resolve(address(this), _plainUri, additionalData, msg.sender);
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal virtual returns(bytes memory);

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal virtual view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/ILazyInitCapableElement.sol";
import { ReflectionUtilities } from "../../lib/GeneralUtilities.sol";

abstract contract LazyInitCapableElement is ILazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override initializer;
    address public override host;

    constructor(bytes memory lazyInitData) {
        if(lazyInitData.length > 0) {
            _privateLazyInit(lazyInitData);
        }
    }

    function lazyInit(bytes calldata lazyInitData) override external returns (bytes memory lazyInitResponse) {
        return _privateLazyInit(lazyInitData);
    }

    function supportsInterface(bytes4 interfaceId) override external view returns(bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ILazyInitCapableElement).interfaceId ||
            interfaceId == this.lazyInit.selector ||
            interfaceId == this.initializer.selector ||
            interfaceId == this.subjectIsAuthorizedFor.selector ||
            interfaceId == this.host.selector ||
            interfaceId == this.setHost.selector ||
            _supportsInterface(interfaceId);
    }

    function setHost(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = host;
        host = newValue;
        emit Host(oldValue, newValue);
    }

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) public override virtual view returns(bool) {
        (bool chidlElementValidationIsConsistent, bool chidlElementValidationResult) = _subjectIsAuthorizedFor(subject, location, selector, payload, value);
        if(chidlElementValidationIsConsistent) {
            return chidlElementValidationResult;
        }
        if(subject == host) {
            return true;
        }
        if(!host.isContract()) {
            return false;
        }
        (bool result, bytes memory resultData) = host.staticcall(abi.encodeWithSelector(ILazyInitCapableElement(host).subjectIsAuthorizedFor.selector, subject, location, selector, payload, value));
        return result && abi.decode(resultData, (bool));
    }

    function _privateLazyInit(bytes memory lazyInitData) private returns (bytes memory lazyInitResponse) {
        require(initializer == address(0), "init");
        initializer = msg.sender;
        (host, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        emit Host(address(0), host);
        lazyInitResponse = _lazyInit(lazyInitResponse);
    }

    function _lazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _supportsInterface(bytes4 selector) internal virtual view returns (bool);

    function _subjectIsAuthorizedFor(address, address, bytes4, bytes calldata, uint256) internal virtual view returns(bool, bool) {
    }

    modifier authorizedOnly {
        require(_authorizedOnly(), "unauthorized");
        _;
    }

    function _authorizedOnly() internal returns(bool) {
        return subjectIsAuthorizedFor(msg.sender, address(this), msg.sig, msg.data, msg.value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IDynamicUriResolver {
    function resolve(address subject, string calldata plainUri, bytes calldata inputData, address caller) external view returns(string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

struct PrestoOperation {

    address inputTokenAddress;
    uint256 inputTokenAmount;

    address ammPlugin;
    address[] liquidityPoolAddresses;
    address[] swapPath;
    bool enterInETH;
    bool exitInETH;

    uint256[] tokenMins;

    address[] receivers;
    uint256[] receiversPercentages;
}