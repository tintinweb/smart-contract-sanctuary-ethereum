// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../market-place/interfaces/IMarketPlace.sol";
import "../interfaces/IAdmin.sol";
import "../interfaces/IOperator.sol";
import "../interfaces/IMintable.sol";
import "./interfaces/ILaboratory.sol";
import "../meta-cell/interfaces/ICellRepository.sol";
import "../interfaces/IEnhancerRepository.sol";
import "../interfaces/IExternalNftRepository.sol";
import "../random/interfaces/IRandom.sol";
import "../meta-cell/interfaces/IMetaCellCreator.sol";
import "../nano-cell/interfaces/INanoCellCreator.sol";
import "../scientist-researcher/interfaces/IScientistResearcher.sol";
import "../creation-history/interfaces/ICreationHistory.sol";
import "../helpers/timelock-access/TimelockAccess.sol";

contract Laboratory is
    ILaboratory,
    TimelockAccess,
    IOperator,
    IEnhancerRepository,
    IExternalNftRepository,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address must not be zero");
        _;
    }

    EnumerableSetUpgradeable.UintSet private scientistsUsed;
    EnumerableSetUpgradeable.AddressSet private nftWhitelist;

    address public random;
    address public metaCell;
    address public nanoCell;
    address public biometaToken;
    address public scientistToken;
    address public scientistResearcher;
    address public creationHistory;
    address public marketPlace;
    address public walletFee;
    address private proxyRegistryAddress;

    uint16 public constant MAX_LEVEL_OF_EVOLUTION = 1000;
    uint256 public boostPerBlockPrice;

    bool public isOpenFeatureSplitNanoCell;

    function setIsOpenFeatureSplitNanoCell(bool value) external onlyTimelock {
        isOpenFeatureSplitNanoCell = value;
    }

    modifier isAllowedToBoost(uint256 _tokenID, address owner) {
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        require(cell.user == msg.sender, "You are not an owner of token");
        require(cell.tokenId >= 0, "Non-existent cell");
        require(
            cell.class != CellData.Class.FINISHED,
            "You are not able to evolve more"
        );
        require(
            cell.nextEvolutionBlock != type(uint256).max,
            "You have the highest level"
        );
        _;
    }

    function initialize(
        address _timelock,
        address _scientist,
        address _scientistResearcher,
        address _creationHistory,
        address _metaCell,
        address _nanoCell,
        address _biometa
    ) external initializer {
        __Ownable_init();
        timelock = _timelock;
        walletFee = msg.sender;
        scientistToken = _scientist;
        scientistResearcher = _scientistResearcher;
        creationHistory = _creationHistory;
        metaCell = _metaCell;
        nanoCell = _nanoCell;
        biometaToken = _biometa;
        boostPerBlockPrice = 1000000000000000000;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    function setScientistResearcher(address _scientistResearcher)
        external
        onlyTimelock
    {
        scientistResearcher = _scientistResearcher;
    }

    function addOperator(address _operator) external override onlyTimelock {
        _addOperator(_operator);
    }

    function removeOperator(address _operator) external override onlyTimelock {
        _removeOperator(_operator);
    }

    function setCreationHistory(address _creationHistory)
        external
        onlyTimelock
        nonZeroAddress(_creationHistory)
    {
        creationHistory = _creationHistory;
    }

    function setRandom(address _random)
        external
        override
        onlyTimelock
        nonZeroAddress(_random)
    {
        random = _random;
    }

    function setNanoCell(address _token)
        external
        override
        onlyTimelock
        nonZeroAddress(_token)
    {
        nanoCell = _token;
    }

    function setScientist(address _token)
        external
        override
        onlyTimelock
        nonZeroAddress(_token)
    {
        scientistToken = _token;
    }

    function setBiometa(address _token)
        external
        override
        onlyTimelock
        nonZeroAddress(_token)
    {
        biometaToken = _token;
    }

    function setWalletFee(address newWalletFee) external override onlyTimelock {
        walletFee = newWalletFee;
    }

    function setMarketPlace(address newMarketPlace)
        external
        override
        onlyTimelock
    {
        marketPlace = newMarketPlace;
    }

    function setSeed(uint256 seed) external override onlyTimelock {
        ISeed(random).setSeed(seed);
    }

    function setBoostPerBlockPrice(uint256 _price)
        external
        override
        onlyTimelock
    {
        boostPerBlockPrice = _price;
        emit BoostPricePerBlockChanged(_price, block.timestamp);
    }

    function evolve(
        uint256 _tokenID,
        uint256 _enhancerID,
        uint256 _scientistID
    ) external override {
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        require(cell.tokenId != 0, "Non-existent cell");
        CellEnhancer.Enhancer memory enhancer;
        if (_enhancerID != 0) {
            enhancer = getEnhancerInfo(_enhancerID);
            require(enhancer.id != type(uint256).max, "Non-existent enhancer");
            require(
                getEnhancersAmount(msg.sender, _enhancerID) > 0,
                "Insufficient amount of enhancers"
            );
            _decreaseEnhancersAmount(msg.sender, _enhancerID, 1);
            emit EnhancerAmountChanged(_enhancerID, 1);
        }
        cell = _evolve(cell, enhancer, _scientistID);
        emit NewEvolutionCompleted("Evolve", cell, block.timestamp);

        if (CellData.isSplittable(cell.class)) {
            _processSplit(cell);
        }
        ICellRepository(metaCell).updateMetaCell(cell, msg.sender);
    }

    function _splitNanoCell(uint256 metaCellId) internal {
        uint256 nanoCellId = INanoCellCreator(nanoCell).create(msg.sender);
        ICreationHistory(creationHistory).registerNanoCellForMetaCell(
            metaCellId,
            nanoCellId
        );
        emit SplitNanoCell(msg.sender, nanoCellId, block.timestamp);
    }

    function _splitBiometa() internal {
        uint256 amount = IRandom(random).randomRateSplitBiometaToken() *
            10**IERC20MetadataUpgradeable(biometaToken).decimals();
        IMintable(biometaToken).mint(msg.sender, amount);
        emit SplitBiometaToken(msg.sender, amount, block.timestamp);
    }

    function _slpitEnhancer() internal {
        uint256 randomEnhancerId = IRandom(random).randomEnhancerId(
            IMarketPlace(marketPlace).numberOfEnhancersType()
        );
        _increaseEnhancersAmount(msg.sender, randomEnhancerId, 1);
        emit SplitEnhancer(msg.sender, randomEnhancerId, block.timestamp);
    }

    function _processSplit(CellData.Cell memory cell) private {
        uint256 replacement;
        if (cell.class == CellData.Class.SPLITTABLE_NANO) {
            if (isOpenFeatureSplitNanoCell) {
                _splitNanoCell(cell.tokenId);
            } else {
                bytes32 randomData = keccak256(
                    abi.encodePacked(
                        blockhash(block.number.sub(1)),
                        msg.sender,
                        block.timestamp
                    )
                );
                replacement = uint256(randomData) % 2;
            }
        }
        if (
            cell.class == CellData.Class.SPLITTABLE_BIOMETA || replacement == 0
        ) {
            _splitBiometa();
        }
        if (
            cell.class == CellData.Class.SPLITTABLE_ENHANCER || replacement == 1
        ) {
            _slpitEnhancer();
        }
        cell.class = CellData.Class.COMMON;
    }

    function _evolve(
        CellData.Cell memory cell,
        CellEnhancer.Enhancer memory _enhancer,
        uint256 _scientistId
    ) private returns (CellData.Cell memory) {
        if (_scientistId != 0) {
            require(
                msg.sender == IERC721Upgradeable(scientistToken).ownerOf(_scientistId),
                "You are not an owner of token"
            );
        }
        require(
            cell.stage < MAX_LEVEL_OF_EVOLUTION,
            "You are not able to evolve more"
        );
        require(
            cell.class != CellData.Class.FINISHED,
            "You are not able to evolve more"
        );
        require(
            cell.nextEvolutionBlock <= block.number,
            "You can't evolve right now"
        );

        if (
            CellEnhancer.convertEnhancer(_enhancer.typeId) ==
            CellEnhancer.EnhancerType.STAGE_ENHANCER
        ) {
            cell.stage = IRandom(random).getRandomStage(
                cell.stage,
                _enhancer.probability
            );
        } else {
            cell.stage = IRandom(random).getRandomStage(cell.stage, 0);
        }

        IScientistResearcher.SpecialEffect
            memory specialEffects = scientistResearcher != address(0)
                ? IScientistResearcher(scientistResearcher).getSpecialEffects(
                    _scientistId
                )
                : IScientistResearcher.SpecialEffect(0, 0, 0);

        if (
            CellEnhancer.convertEnhancer(_enhancer.typeId) ==
            CellEnhancer.EnhancerType.SPLIT_ENHANCER
        ) {
            cell.class = CellData.Class(
                IRandom(random).getSplittableWithIncreaseChance(
                    _enhancer.probability,
                    specialEffects.chanceSplitNanoCell
                )
            );
        } else {
            cell.class = CellData.Class(IRandom(random).getRandomClass());
        }

        cell.nextEvolutionBlock = IRandom(random).getEvolutionTime(
            specialEffects.buffEvolveMetaCellTime
        );
        if (cell.stage > MAX_LEVEL_OF_EVOLUTION) {
            cell.stage = MAX_LEVEL_OF_EVOLUTION;
        }
        if (
            cell.class == CellData.Class.FINISHED ||
            cell.stage == MAX_LEVEL_OF_EVOLUTION
        ) {
            cell.nextEvolutionBlock = type(uint256).max;
        }
        cell.variant = IRandom(random).getRandomVariant();
        return cell;
    }

    function boostCell(uint256 _tokenID, uint256 _amount)
        external
        override
        isAllowedToBoost(_tokenID, msg.sender)
    {
        require(
            IERC20Upgradeable(biometaToken).balanceOf(msg.sender) >= _amount,
            "Not enough funds"
        );
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        require(cell.tokenId >= 0, "Non-existent cell");
        uint256 _blocksAmount = _getBoostedBlocks(_amount);

        if (block.number >= cell.nextEvolutionBlock.sub(_blocksAmount)) {
            cell.nextEvolutionBlock = block.number;
        } else {
            cell.nextEvolutionBlock = cell.nextEvolutionBlock.sub(
                _blocksAmount
            );
        }
        require(
            IERC20Upgradeable(biometaToken).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Should be true"
        );
        ICellRepository(metaCell).updateMetaCell(cell, msg.sender);

        emit EvolutionTimeReduced("BoostCell", cell, block.timestamp);
    }

    function mutate(uint256 _cellId, uint256 _nftId) external override {
        CellData.Cell memory oldCell = ICellRepository(metaCell).getMetaCell(
            _cellId
        );
        NFT memory nft = _getNft(_nftId, msg.sender);

        CellData.Cell memory newCell = _mergeWithNft(oldCell, nft);
        _markNftAsUsed(_nftId, msg.sender);
        ICellRepository(metaCell).updateMetaCell(newCell, msg.sender);

        emit UseNFT(msg.sender, _cellId, _nftId, block.timestamp);
        emit NewEvolutionCompleted("Mutate", newCell, block.timestamp);
    }

    // NFT should be used somehow
    function _mergeWithNft(CellData.Cell memory _cellA, NFT memory)
        private
        returns (CellData.Cell memory)
    {
        CellData.Cell memory newCell = _createNewMetaCellData(
            msg.sender,
            _cellA.tokenId
        );
        return newCell;
    }

    function getSeed() external view override returns (uint256) {
        return ISeed(random).getSeed();
    }

    function _createNewMetaCellData(address tokenOwner, uint256 _numOptions)
        private
        returns (CellData.Cell memory)
    {
        CellData.Class newClass = CellData.Class(
            IRandom(random).getRandomClass()
        );

        if (newClass == CellData.Class.FINISHED) {
            newClass = CellData.Class.COMMON;
        }
        uint256 newStage = 0;
        uint256 newEvoTime = IRandom(random).getEvolutionTime(0);

        uint256 variant = IRandom(random).getRandomVariant();
        CellData.Cell memory newCell = CellData.Cell({
            tokenId: _numOptions,
            user: tokenOwner,
            class: newClass,
            stage: newStage,
            nextEvolutionBlock: newEvoTime,
            variant: variant,
            onSale: false,
            price: 0
        });

        return newCell;
    }

    function getBoostPerBlockPrice() public view override returns (uint256) {
        return boostPerBlockPrice;
    }

    function getBoostedBlocks(uint256 _price)
        external
        view
        override
        returns (uint256)
    {
        return _getBoostedBlocks(_price);
    }

    function _getBoostedBlocks(uint256 _price) private view returns (uint256) {
        return _price.div(boostPerBlockPrice);
    }

    /**
     * @dev Calculates how much money needs to user to be ready to
     * run evolve
     */
    function getAmountForNextEvolution(uint256 _tokenID)
        external
        view
        returns (uint256)
    {
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        if (cell.nextEvolutionBlock <= block.number) {
            return 0;
        }
        return
            cell.nextEvolutionBlock.sub(block.number).mul(
                getBoostPerBlockPrice()
            );
    }

    function addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        external
        override
        isOperator
    {
        super._addAvailableEnhancers(_enhancer);
        emit EnhancerAdded(_enhancer.id);
    }

    function increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external override isOperator {
        super._increaseEnhancersAmount(_owner, _id, _amount);
        emit EnhancerAmountChanged(_id, _amount);
    }

    function decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external override isOperator {
        super._decreaseEnhancersAmount(_owner, _id, _amount);
        emit EnhancerAmountChanged(_id, _amount);
    }

    function addNft(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) external override {
        require(
            EnumerableSetUpgradeable.contains(nftWhitelist, _nftAddress),
            "This NFT address is not whitelist"
        );
        require(
            IERC721Upgradeable(_nftAddress).ownerOf(_tokenId) == _owner,
            "Incorrect owner of NFT"
        );
        string memory _metadataUri = IERC721MetadataUpgradeable(_nftAddress).tokenURI(
            _tokenId
        );
        require(
            bytes(_metadataUri).length != 0 && _owner != address(0),
            "Incorrect URI or owner address."
        );
        super._addNft(_metadataUri, _owner);
        emit AddNFT(
            _owner,
            _metadataUri,
            nftLatestId.current(),
            block.timestamp
        );
    }

    function getNft(uint256 _nftId, address _owner)
        external
        view
        override
        returns (NFT memory)
    {
        return super._getNft(_nftId, _owner);
    }

    function isCanCreateMetaCell(uint256 positionId)
        external
        view
        returns (bool)
    {
        return !EnumerableSetUpgradeable.contains(scientistsUsed, positionId);
    }

    function createMetaCell(uint256 positionId) external override {
        require(
            IERC721Upgradeable(scientistToken).ownerOf(positionId) == msg.sender,
            "Caller is not ower of Scientist"
        );
        require(
            !EnumerableSetUpgradeable.contains(scientistsUsed, positionId),
            "Already used scientist"
        );
        EnumerableSetUpgradeable.add(scientistsUsed, positionId);
        uint256 metaCellId = IMetaCellCreator(metaCell).create(msg.sender);
        ICreationHistory(creationHistory).registerMetaCellForScientist(
            positionId,
            metaCellId
        );
        emit NewMetaCellCreated(msg.sender, metaCellId, block.timestamp);
    }

    function getMetaCellByID(uint256 tokenId)
        external
        view
        override
        returns (CellData.Cell memory)
    {
        return ICellRepository(metaCell).getMetaCell(tokenId);
    }

    function withdrawFee() external onlyTimelock {
        IERC20Upgradeable(biometaToken).transfer(
            walletFee,
            IERC20Upgradeable(biometaToken).balanceOf(address(this))
        );
    }

    function addNFTWhitelist(address nft) external onlyTimelock {
        require(
            !EnumerableSetUpgradeable.contains(nftWhitelist, nft),
            "This address is current whitelist"
        );
        EnumerableSetUpgradeable.add(nftWhitelist, nft);
    }

    function removeNFTWhitelist(address nft) external onlyTimelock {
        require(
            EnumerableSetUpgradeable.contains(nftWhitelist, nft),
            "This address is not current whitelist"
        );
        EnumerableSetUpgradeable.remove(nftWhitelist, nft);
    }

    function getNFTWhitelist() external view returns (address[] memory) {
        return EnumerableSetUpgradeable.values(nftWhitelist);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IScientistResearcher {
    /**
     * @dev Emits when Scientist research each technical
     * @param owner is owner address of Scientist
     * @param tokenId is id of Scientist
     * @param levelTechnical is the level of technical Scientist researched
     * @param technicalSkill is the skill code in the level of technical
     * @param timestamp is the time that event emitted
     */
    event ResearchTech(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed levelTechnical,
        uint256 technicalSkill,
        uint256 timestamp
    );

    /**
     * @dev Structure about level of technical level 1
     * Research these technicals opens access to paths towards level 2 scientific research
     * NOTE Explainations of params in structure:
     * `physics` - the level of technical Physics
     * `chemistry` - the level of technical Chemistry
     * `biology` - the level of technical Biology
     * `sociology` - the level of technical sociology
     * `mathematics` - the level of technical Methematics
     */
    struct TechnicalLevelOne {
        uint8 physics;
        uint8 chemistry;
        uint8 biology;
        uint8 sociology;
        uint8 mathematics;
    }

    /**
     * @dev Structure about level of technical level 2
     * Research these technicals opens access to paths towards level 3 scientific research
     * NOTE Explainations of params in structure:
     * `genetics` - the level of technical Genetics
     * `nutrition` - the level of technical Nutrition
     * `engineering` - the level of technical Engineering
     * `astroPhysics` - the level of technical Astro Physics
     * `economics` - the level of technical Economics
     * `computerScience` - the level of technical Computer Science
     * `quantumMechanics` - the level of technical Quantum Mechanics
     * `cliodynamics` - the level of technical Cliodynamics
     */
    struct TechnicalLevelTwo {
        uint8 genetics;
        uint8 nutrition;
        uint8 engineering;
        uint8 astroPhysics;
        uint8 economics;
        uint8 computerScience;
        uint8 quantumMechanics;
        uint8 cliodynamics;
    }

    /**
     * @dev Structure about level of technical level 3
     * Research these technicals opens access to paths towards level 4 scientific research
     * NOTE Explainations of params in structure:
     * `exometeorology` - the level of technical Exometeorology
     * `nutrigenomics` - the level of technical Nutrigenomics
     * `syntheticBiology` - the level of technical Synthetic Biology
     * `recombinatMemetics` - the level of technical Recombinat Memetics
     * `computationalLexicology` - the level of technical Computational Lexicology
     * `computationalEconomics` - the level of technical Computational Economics
     * `computationalSociology` - the level of technical Computational Sociology
     * `cognitiveEconomics` - the level of technical Cognitive Economics
     */
    struct TechnicalLevelThree {
        uint8 exometeorology;
        uint8 nutrigenomics;
        uint8 syntheticBiology;
        uint8 recombinatMemetics;
        uint8 computationalLexicology;
        uint8 computationalEconomics;
        uint8 computationalSociology;
        uint8 cognitiveEconomics;
    }

    /**
     * @dev Structure about level of technical level 4
     * Research these technicals opens access to paths towards level 5 scientific research
     * NOTE Explainations of params in structure:
     * `culturomics` - the level of technical Culturomics
     * `quantumBiology` - the level of technical QuantumBiology
     */
    struct TechnicalLevelFour {
        uint8 culturomics;
        uint8 quantumBiology;
    }

    /**
     * @dev Structure about level of technical level 4
     * Research these technicals opens access to paths towards level 5 scientific research
     * NOTE Explainations of params in structure:
     * `computationalSocialScience` - the level of technical Computational Social Science
     */
    struct TechnicalLevelFive {
        uint8 computationalSocialScience;
    }

    /**
     * @dev Structure about all the effects that Scientist gained when it had researched
     * NOTE Explainations of params in structure:
     * `chanceSplitNanoCell` - the rate increase for splitting NanoCell when user evolve MetaCell
     * `buffEvolveMetaCellTime` - the rate use for reducing waiting time when user evolve MetaCell
     * `plusAttributeForNanoCell` - the attributes increased for splitted NanoCell when user evolve MetaCell
     */
    struct SpecialEffect {
        uint8 chanceSplitNanoCell;
        uint8 buffEvolveMetaCellTime;
        uint8 plusAttributesForNanoCell;
    }

    enum TechSetLevelOne {
        PHYSICS,
        CHEMISTRY,
        BIOLOGY,
        SCIOLOGY,
        MATHEMATICS
    }

    enum TechSetLevelTwo {
        GENETICS,
        NUTRITION,
        ENGINEERING,
        ASTRO_PHYSICS,
        ECONOMICS,
        COMPUTER_SCIENCE,
        QUANTUM_MECHANICS,
        CLIODYNAMICS
    }

    enum TechSetLevelThree {
        EXOMETEOROLOGY,
        NUTRIGENOMICS,
        SYNTHETIC_BIOLOGY,
        RECOMBINAT_MEMETIC,
        COMPUTATIONAL_LEXICOLOGY,
        COMPUTATIONAL_ECONOMICS,
        COMPUTATIONAL_SOCIOLOGY,
        COGNITIVE_ECONOMICS
    }

    enum TechSetLevelFour {
        CULTUROMICS,
        QUANTUM_BIOLOGY
    }

    enum TechSetLevelFive {
        COMPUTAIONAL_SOCIAL_SCIENCE
    }

    enum SpecialSetEffect {
        CHANCE_SPLIT_NANO_CELL,
        BUFF_EVOLVE_META_CELL_TIME,
        PLUS_ATTRIBUTES_FOR_NANO_CELL
    }

    enum TechLevel {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    function getSpecialEffects(uint256 tokenId)
        external
        view
        returns (SpecialEffect memory);

    function researchTechLevelOne(uint256 tokenId, TechSetLevelOne tech)
        external;

    function researchTechLevelTwo(uint256 tokenId, TechSetLevelTwo tech)
        external;

    function researchTechLevelThree(uint256 tokenId, TechSetLevelThree tech)
        external;

    function researchTechLevelFour(uint256 tokenId, TechSetLevelFour tech)
        external;

    function researchTechLevelFive(uint256 tokenId, TechSetLevelFive tech)
        external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IRandom {
    /**
     * @dev Picks random image depends on the token stage
     */
    function getRandomVariant() external view returns (uint256);

    /**
     * @dev Picks random class for token during evolution from
     * [COMMON, SPLITTABLE_NANO, SPLITTABLE_BIOMETA, FINISHED]
     */
    function getRandomClass() external view returns (uint8);

    /**
     * @dev Check whether token could be splittable
     */
    function getSplittableWithIncreaseChance(uint256 probability, uint256 increasedChanceSplitNanoCell)
        external
        returns (uint8);

    /**
     * @dev Generates next stage for token during evoution
     * in rage of [0;5]
     */
    function getRandomStage(uint256 _stage, uint256 probabilityIncrease)
        external
        view
        returns (uint256);

    /**
     * @dev Generates evolution time
     */
    function getEvolutionTime(uint256 decreasedRate) external returns (uint256);

    function randomEnhancerId(uint256 limit) external view returns (uint256 randomId);

    function randomRateSplitBiometaToken() external view returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface INanoCellCreator {
    function create(address account) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMetaCellCreator {
    function create(address to) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "../../libs/CellData.sol";
/**
 * @title Interface for interaction with particular cell
 */
interface ICellRepository {
    event AddMetaCell(CellData.Cell metaCell, uint256 timestamp);
    event UpdateMetaCell(
        CellData.Cell currentMetaCell,
        CellData.Cell newMetaCell,
        uint256 timestamp
    );
    event RemoveMetaCell(CellData.Cell metaCell, uint256 timestamp);

    function addMetaCell(CellData.Cell memory _cell) external;

    function removeMetaCell(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta cell id's for particular user
     */
    function getUserMetaCellsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external;

    function getMetaCell(uint256 _tokenId)
        external
        view
        returns (CellData.Cell memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceSetter {
    /**
     * @dev function that sets ERC20 token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of ERC20 token
     */
    function setBiometaToken(address _address) external;

    /**
     * @dev function that sets MetaCell token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of MetaCell token
     */
    function setMetaCellToken(address _address) external;

    /**
     * @dev function that sets NanoCell token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of NanoCell token
     */
    function setNanoCellToken(address _address) external;

    /**
     * @dev function that sets laboratory contract address.
     * @dev emits LaboratoryAddressChanged
     * @param _address is address of Laboratory address
     */
    function setLaboratory(address _address) external;

    /**
     * @dev set modules contract address
     * @dev emits ModulesAddressChanged
     */
    function setModulesAddress(address _address) external;

    /**
     * @dev function thats sets price of ERC20 token.
     * @dev emits TokenPriceChanged
     * @param _price is amount per 1 ERC20 token
     */
    function setBiometaTokenPrice(uint256 _price) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceNanoCell {
    /**
     * @dev function that buyer buy NanoCell from seller
     */
    function buyNanoCell(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellNanoCell(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeNanoCellFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellsOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellPrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateNanoCellPrice(uint256 id, uint256 price) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceModule {
    /**
     * @dev transfers module from one user to another
     */
    function buyModule(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellModule(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeModuleFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getModulesOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getModulePrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateModulesPrice(uint256 id, uint256 price) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceMetaCell {
    function buyMetaCell(uint256 _tokenId, address payable _oldOwner)
        external
        payable;

    /**
     * @dev Marks meta cell token as available for selling
     * @param _tokenId id of the cell
     * @param _price selling price
     */
    function sellMetaCell(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Updates token sell price
     * @param _tokenId id of the cell
     * @param _newPrice new price of the token
     */
    function updateMetaCellPrice(uint256 _tokenId, uint256 _newPrice) external;

    /**
     * @dev Marks token as unavailable for selling
     * @param _tokenId id of the cell
     */
    function removeMetaCellFromSale(uint256 _tokenId) external;

    /**
     * @dev Returns all tokens that on sale now as an array of IDs
     */
    function getOnSaleMetaCells()
        external
        view
        returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceMAD {
    /**
     * @dev function that returns price per 1 token.
     */
    function getBiometaTokenPrice() external view returns (uint256);

    /**
     * @dev payable function thata allows to buy ERC20 token for ether
     * @param _amount amount of ERC20 tokens to buy
     */
    function buyBiometaToken(uint256 _amount) external payable;

    /**
     * @dev withdraw MAD rokens to owner
     */
    function withdrawTokens(address token, address to) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceGetter {
    /**
     * @dev Returns Biometa token address
     * @return address of Biometa token
     */
    function getBiometaToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getMetaCellToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getNanoCellToken() external view returns (address);

    /**
     * @dev  returns modules contract address
     */
    function getModuleAddress() external view returns (address module);

    /**
     * @dev function that returns ERC721 token address
     */
    function getLaboratory() external view returns (address laboratory);

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

/**
 * @title IMarketPlaceEvent - interface that contains the define of events 
 */
interface IMarketPlaceEvent {
    /**
     * @dev Emits when token adress is changed
     * @param oldToken is old address token
     * @param newToken is token address that will be changed
     */
    event TokenAdressChanged(address oldToken, address newToken);

    /**
     * @dev Emits when Laboratory adress is changed
     * @param oldLaboratory is old Laboratory address
     * @param newLaboratory is new Laboratory address
     */
    event LaboratoryAddressChanged(address oldLaboratory, address newLaboratory);

    /**
     * @dev Emits when modules token adress is changed
     * @param oldModules is old modules address
     * @param newModules is new modules address
     */
    event ModuleAddressChanged(address oldModules, address newModules);

    /**
     * @dev Emits when wallet adress is changed
     * @param oldWallet is old wallet address
     * @param newWallet is new wallet address
     */
    event WalletAddressChanged(address oldWallet, address newWallet);

    /**
     * @dev Emits when fee amount is changed
     * @param oldFeeAmount is old fee amount
     * @param newFeeAmount is new fee amount
     */
    event FeeQuoteAmountUpdated(uint256 oldFeeAmount, uint256 newFeeAmount);

    /**
     * @dev Emits when token price is changed
     * @param oldPrice is old price of token
     * @param newPrice is new price of token
     */
    event TokenPriceChanged(uint256 oldPrice, uint256 newPrice);

    /**
     * @dev Emits when account successfully added MetaCell to marketplace
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param price is ETH price of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellAddedToMarketplace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 price, 
        uint256 timestamp
    );

    /**
     * @dev Emits when account successfully added NanoCell to marketplace
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param price is MDMA price of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellAddedToMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 price, 
        uint256 timestamp
    );

    /**
     * @dev Emits when account successfully added Module to marketplace
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param price is MDMA price of Module
     * @param timestamp is the time that event emitted
     */
    event ModuleAddedToMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 price, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully removed MetaCell from marketplace
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully removed NanoCell from marketplace
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully removed Module from marketplace
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param timestamp is the time that event emitted
     */
    event ModuleRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 timestamp
    );

    /**
     * @dev Emits when buyer successfully bought MetaCell from seller
     * @param seller is seller address of MetaCell
     * @param tokenId is id of the MetaCell that sold
     * @param buyer is buyer address that buyed the MetaCell
     * @param price is the ETH price at the time MetaCell sold
     * @param fee is the ETH fee charged
     * @param timestamp is the time that event emitted
     */
    event MetaCellSold(
        address indexed seller, 
        uint256 indexed tokenId, 
        address indexed buyer, 
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @dev Emits when buyer successfully bought NanoCell from seller
     * @param seller is seller address of NanoCell
     * @param tokenId is id of the NanoCell that sold
     * @param buyer is buyer address that buyed the NanoCell
     * @param price is the MDMA token price at the time NanoCell sold
     * @param fee is the MDMA token fee charged
     * @param timestamp is the time that event emitted
     */
    event NanoCellSold(
        address indexed seller, 
        uint256 indexed tokenId, 
        address indexed buyer, 
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @dev Emits when buyer successfully bought Module from seller
     * @param seller is seller address of Module
     * @param tokenId is id of the Module that sold
     * @param buyer is buyer address that buyed the Module
     * @param price is the MDMA token price at the time Module sold
     * @param fee is the MDMA token fee charged
     * @param timestamp is the time that event emitted
     */
    event ModuleSold(
        address indexed seller, 
        uint256 indexed tokenId, 
        address indexed buyer, 
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @dev Emits when owner updated MetaCell price
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param newPrice is new ETH price of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellPriceUpdated(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 indexed newPrice, 
        uint256 timestamp
    );

    /**
     * @dev Emits when owner updated NanoCell price
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param newPrice is new ETH price of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellPriceUpdated(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 indexed newPrice, 
        uint256 timestamp
    );

    /**
     * @dev Emits when owner updated Module price
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param newPrice is new ETH price of Module
     * @param timestamp is the time that event emitted
     */
    event ModulePriceUpdated(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 indexed newPrice, 
        uint256 timestamp
    );

    /**
     * @dev Emits when admin created the Enhancer
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param typeId is the type id of Enhancer
     * @param probability is the probability which increases the chance to SPLIT when evolve MetaCell
     * @param basePrice is the price of each Enhancer id
     * @param amount is the amount of Enhancer
     * @param name is the name of Enhancer
     * @param tokenAddress is the token which is used to buy Enhancer, is ETH if `tokenAddress` is equal to address zero
     * @param timestamp is the time that event emitted
     */
    event EnhancerCreated(
        address admin,
        uint256 indexed id, 
        uint256 indexed typeId, 
        uint256 indexed probability, 
        uint256 basePrice,
        uint256 amount, 
        string name,
        address tokenAddress,
        uint256 timestamp
    );
    
    /**
     * @dev Emits when admin increased the amount of Enhancers
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param amount is the current amount after admin increasing the Enhancers
     * @param timestamp is the time that event emitted
     */
    event EnhancersAmountIncreased(
        address indexed admin, 
        uint256 indexed id, 
        uint256 amount, 
        uint256 timestamp
    );

    /**
     * @dev Emits when admin modified the Enhancer
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param typeId is the type id of Enhancer
     * @param probability is the probability which increases the chance to SPLIT when evolve MetaCell
     * @param basePrice is the price of each Enhancer id
     * @param amount is the amount of Enhancer
     * @param name is the name of Enhancer
     * @param tokenAddress is the token which is used to buy Enhancer, is ETH if `tokenAddress` is equal to address zero
     * @param timestamp is the time that event emitted
     */
    event EnhancerModified(
        address admin,
        uint256 indexed id, 
        uint256 indexed typeId, 
        uint256 indexed probability, 
        uint256 basePrice,
        uint256 amount, 
        string name,
        address tokenAddress,
        uint256 timestamp
    );

    /**
     * @dev Emits when admin removed the Enhancer from MarketPlace
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param timestamp is the time that event emitted
     */
    event EnhancerRemoved(
        address indexed admin, 
        uint256 indexed id, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully bought Enhancer
     * @param buyer is buyer address
     * @param id is id of Enhancer
     * @param amount is the amount of Enhancers buyer has buyed
     * @param price is the ETH price that buyer has paid
     * @param timestamp is the time that event emitted
     */
    event EnhancerBought(
        address indexed buyer, 
        uint256 indexed id, 
        uint256 indexed amount, 
        uint256 price,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;
import "../../libs/Enhancer.sol";

interface IMarketPlaceEnhancer {
    /**
     * @notice Buy enhancer for ETH
     * @dev Requirements:
     * - Sufficient quantity of Enhancers in the MarketPlace
     * - Token address to pay must be equal to address zero
     * - Base price multiple `amount` must be less than msg.value
     * @param enhancerId is id of Enhancer
     * @param amount is amount of enhancers that caller want to buy
     */
    function buyEnhancerForETH(
        uint256 enhancerId, 
        uint256 amount
    ) external 
        payable;

    /**
     * @notice Buy enhancer for token address
     * @dev Requirements:
     * - Sufficient quantity of Enhancers in the MarketPlace
     * - Token address to pay must be not equal to address zero
     * - Token address to pay must be equal to `tokenAddress`
     * @param tokenAddress is token address
     * @param enhancerId is id of Enhancer
     * @param amount is amount of enhancers that caller want to buy
     */
    function buyEnhancerForToken(
        address tokenAddress,
        uint256 enhancerId,
        uint256 amount
    ) external;

    /**
     * @dev Returns enhancer info by id
     * @param id is id of Enhancer
     * @return Enhancer info
     */
    function getEnhancer(uint256 id)
        external
        view
        returns (CellEnhancer.Enhancer memory);

    /**
     * @dev returns all available enhancers
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory);

    /**
     * @dev Returns amount of availbale enhancers by given id
     */
    function getEnhancersAmount(uint256 _id) external view returns (uint256);

    function numberOfEnhancersType() external view returns (uint);

    /**
     * @dev Creates enhancer with options
     */
    function createEnhancer(
        uint8 _typeId,
        uint16 _probability,
        uint256 _basePrice,
        uint256 _amount,
        string memory _name,
        address _tokenAddress
    ) external;

    /**
     * @dev Modifies enhancer's info
     * can be changed everything except enhancer's type
     */
    function modifyEnhancer(CellEnhancer.Enhancer memory, uint256) external;

    /**
     * @dev Increases enhancer amount by it's id
     */
    function addEnhancersAmount(uint256 _id, uint256 _amount) external;

    /**
     * @dev Removes enhancer from marketPlace
     */
    function removeEnhancerFromSale(uint256 id) external;

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./IMarketPlaceEvent.sol";
import "./IMarketPlaceGetter.sol";
import "./IMarketPlaceSetter.sol";
import "./IMarketPlaceMetaCell.sol";
import "./IMarketPlaceNanoCell.sol";
import "./IMarketPlaceMAD.sol";
import "./IMarketPlaceModule.sol";
import "./IMarketPlaceEnhancer.sol";


interface IMarketPlace is 
    IMarketPlaceEvent,
    IMarketPlaceGetter,
    IMarketPlaceSetter,
    IMarketPlaceMetaCell,
    IMarketPlaceNanoCell,
    IMarketPlaceMAD,
    IMarketPlaceModule,
    IMarketPlaceEnhancer
{
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Representation of enhancer options
 */
library CellEnhancer {
    /**
     * @dev Enhancer
     * @param id - enhancer id
     * @param typeId - enhancer type id
     * @param probability - chance of successful enhancement
     * @param basePrice - default price
     * @param baseCurrency - default currency
     * @param enhancersAmount - amount of existing enhancers
     */
    struct Enhancer {
        uint256 id;
        uint8 typeId;
        uint16 probability;
        uint256 basePrice;
        string name;
        address tokenAddress;
        //todo uint256 amount; add
    }

    enum EnhancerType {
        UNKNOWN_ENHANCER,
        STAGE_ENHANCER,
        SPLIT_ENHANCER
    }

    function convertEnhancer(uint8 enhancerType)
        internal
        pure
        returns (EnhancerType)
    {
        if (enhancerType == 1) {
            return EnhancerType.STAGE_ENHANCER;
        } else if (enhancerType == 2) {
            return EnhancerType.SPLIT_ENHANCER;
        }

        return EnhancerType.UNKNOWN_ENHANCER;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_BIOMETA,
        SPLITTABLE_ENHANCER,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO ||
            _class == Class.SPLITTABLE_BIOMETA ||
            _class == Class.SPLITTABLE_ENHANCER;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 nextEvolutionBlock;
        uint256 variant;
        bool onSale;
        uint256 price;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface ISeed {
    /**
     * @dev Returns seed
     */
    function getSeed() external view returns (uint256);

    /**
     * @dev Sets seed value
     */
    function setSeed(uint256 seed) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface ILaboratorySetter {
    /**
     * @dev Sets NanoCell address
     * can be used only for owner
     */
    function setNanoCell(address _token) external;

    /**
     * @dev Sets Biometa address
     * can be used only for owner
     */
    function setBiometa(address _token) external;

    /**
     * @dev function that sets ERC721 token address.
     * @param _address is address of ERC721 token
     */
    function setScientist(address _address) external;

    /**
     *  @dev sets address for random contract
     */
    function setRandom(address randomAddress) external;

    /**
     *  @dev specifies price for boost per 1 block
     * could be called by contract owner
     */
    function setBoostPerBlockPrice(uint256 _price) external;

    function setMarketPlace(address newMarketPlace) external;

    function setWalletFee(address newWalletFee) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "../../libs/CellData.sol";

interface ILaboratoryGetter {
    /**
     *  @dev returns price for boost per 1 block
     */
    function getBoostPerBlockPrice() external view returns (uint256);

    /**
     *  @dev calculates how many block can user burn
     *  with passed amount
     */
    function getBoostedBlocks(uint256 _price) external view returns (uint256);

    function getMetaCellByID(uint256 tokenId)
        external
        view
        returns (CellData.Cell memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "../../libs/CellData.sol";

interface ILaboratoryEvent {
    /**
     *  Event to show that meta cell
     *  has changed it's properties
     *  @dev has to be emited in `unpack` and evolve
     */
    event NewEvolutionCompleted(
        string methodName,
        CellData.Cell cell,
        uint256 timestamp
    );

    /**
     * @dev Emits when user evolve MetaCell and split NanoCell
     * @param receiver is receiver address
     * @param tokenId is id of NanoCell
     * @param timestamp is is the time that event emitted
     */
    event SplitNanoCell(
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Emits when user evolve MetaCell and split Biometa token
     * @param receiver is receiver address
     * @param amount is Biometa token amount that split for user
     * @param timestamp is is the time that event emitted
     */
    event SplitBiometaToken(
        address indexed receiver,
        uint256 indexed amount,
        uint256 timestamp
    );

    /**
     * @dev Emits when user evolve MetaCell and split Enhancer
     * @param receiver is receiver address
     * @param enhancerId is id of Enhancer
     * @param timestamp is is the time that event emitted
     */
    event SplitEnhancer(
        address indexed receiver,
        uint256 indexed enhancerId,
        uint256 timestamp
    );

    /**
     *  Event to show the amount
     *  of blocks for next evolution
     *  @dev has to be emited in `boostCell`
     */
    event EvolutionTimeReduced(
        string name,
        CellData.Cell cell,
        uint256 timestamp
    );

    /**
     *  Event to show that price for boost is changed
     *   @dev has to be emited in `setBoostPerBlockPrice`
     */
    event BoostPricePerBlockChanged(uint256 indexed _price, uint256 timestamp);

    /**
     * @dev Emits when user creates MetaCell from ScientistId
     * @param ownerOf is owner of Scientist token id
     * @param tokenId is id of Scientist NFT
     * @param timestamp is the time that event emitted
     */
    event NewMetaCellCreated(
        address indexed ownerOf,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Emits when user adds NFT metadata 
     * @param owner is caller's address
     * @param tokenURI is the URI of NFT
     * @param tokenId is id of NFT
     * @param timestamp is the time that event emitted
     */
    event AddNFT(
        address indexed owner,
        string tokenURI,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Emits when user uses NFT for MetaCell 
     * @param owner is caller's address
     * @param tokenId is the id of MetaCell
     * @param nftId is the id of NFT
     * @param timestamp is the time that event emitted
     */
    event UseNFT(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed nftId,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ILaboratoryEvent.sol";
import "./ILaboratoryGetter.sol";
import "./ILaboratorySetter.sol";
import "./ISeed.sol";

interface ILaboratory is
    ILaboratoryEvent,
    ILaboratoryGetter,
    ILaboratorySetter,
    ISeed
{
    /**
     *  @dev user can evolve his token
     *  to a new stage
     *  can be called by any user
     *  NewEvoutionCompleted has to be emmited with string "Evolve"
     */
    function evolve(uint256 _tokenID, uint256 _enhancerID, uint256 _scientistID) external;

    /**
     *  @dev user can mutate his token
     *  with external nft metadata
     *  can be called by any user
     *  NewEvoutionCompleted has to be emmited with string "Mutate"
     */
    function mutate(uint256 _cellId, uint256 _nftId) external;

    /**
     *  @dev user can boost his
     *  awaiting time
     *  can be called by any user
     *  EvolutionTimeReduced has to be emmited
     */
    function boostCell(uint256 _tokenID, uint256 _amount) external;

    /**
     *  @dev Create additional MetaCells
     *  updateChildChainManager() should be called before for owner
     */
    function createMetaCell(uint256 positionId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title Interface to add alowed operator in additiona to owner
 */
abstract contract IOperator {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private operators;

    modifier isOperator() {
        require(operators.contains(msg.sender), "You do not have rights");
        _;
    }

    event OperatorAdded(address);
    event OperatorRemoved(address);

    function addOperator(address _operator) external virtual;

    function removeOperator(address _operator) external virtual;

    function _addOperator(address _operator) internal {
        require(_operator != address(0), "Address should not be empty");
        require(!operators.contains(_operator), "Already added");
        if (!operators.contains(_operator)) {
            operators.add(_operator);
            emit OperatorAdded(_operator);
        }
    }

    function _removeOperator(address _operator) internal {
        require(operators.contains(_operator), "Not exist");
        if (operators.contains(_operator)) {
            operators.remove(_operator);
            emit OperatorRemoved(_operator);
        }
    }

    function getOperators() external view returns (address[] memory) {
        return operators.values();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

abstract contract IMintable {
    function burn(uint256) external virtual;

    function mint(address, uint256) external virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract IExternalNftRepository {
    struct NFT {
        uint256 tokenId;
        string metadataUri;
        bool isUsed;
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => mapping(uint256 => NFT)) public nftAddressToMap;
    EnumerableSetUpgradeable.UintSet private nftIndexSet;
    CountersUpgradeable.Counter public nftLatestId;

    /**
     * @dev Add NFT metadata uri to storage
     */
    function addNft(address _nftAddress, address _owner, uint256 _tokenId)
        external
        virtual;

    /**
     * @dev Returns token info by it's id for particular user
     */
    function getNft(uint256 _nftId, address _owner)
        external
        view
        virtual
        returns (NFT memory);

    function _addNft(string memory _metadataUri, address _owner) internal {
        nftLatestId.increment();
        uint256 newNftId = nftLatestId.current();

        NFT memory newNft = NFT(newNftId, _metadataUri, false);

        EnumerableSetUpgradeable.add(nftIndexSet, newNftId);

        nftAddressToMap[_owner][newNftId] = newNft;
    }

    function _getNft(uint256 _nftId, address _owner)
        internal
        view
        returns (NFT memory)
    {
        NFT memory nft;

        if (!EnumerableSetUpgradeable.contains(nftIndexSet, _nftId)) {
            nft.tokenId = type(uint256).max;
            return nft;
        }

        nft = nftAddressToMap[_owner][_nftId];
        return nft;
    }

    function _markNftAsUsed(uint256 _nftId, address _owner) internal {
        nftAddressToMap[_owner][_nftId].isUsed = true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libs/Enhancer.sol";

/**
 * @title Interface for interaction with particular cell
 */
abstract contract IEnhancerRepository {
    using SafeMathUpgradeable for uint256;
    /**
     * @dev emits enhancer amount
     */
    event EnhancerAmountChanged(uint256, uint256);
    /**
     * @dev emits when enhancer is added
     */
    event EnhancerAdded(uint256);

    CellEnhancer.Enhancer[] private availableEnhancers;

    struct Enhancer {
        uint256 id;
        uint256 amount;
    }
    mapping(address => Enhancer[]) internal ownedEnhancers;

    /**
     * @dev Adds available enhancers to storage
     */
    function addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        external
        virtual;

    function _addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        internal
    {
        uint256 _index = findEnhancerById(_enhancer.id);
        if (_index == type(uint256).max) {
            availableEnhancers.push(_enhancer);
        } else {
            availableEnhancers[_index] = _enhancer;
        }
    }

    /**
     * @dev Returns enhancer info by it's id
     */
    function getEnhancerInfo(uint256 _id)
        public
        view
        returns (CellEnhancer.Enhancer memory)
    {
        uint256 _index = findEnhancerById(_id);
        if (_index == type(uint256).max) {
            CellEnhancer.Enhancer memory _enhancer;
            _enhancer.id = type(uint256).max;
            return _enhancer;
        }
        return availableEnhancers[_index];
    }

    /**
     * @dev Increases amount of enhancers of particular user
     */
    function increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 i = 0; i < len; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .add(_amount);
                return;
            }
        }

        Enhancer memory _enhancer = Enhancer(_id, _amount);
        ownedEnhancers[_owner].push(_enhancer);
    }

    /**
     * @dev Decreases available user enhancers
     */
    function decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < ownedEnhancers[_owner].length; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .sub(_amount);
                index = i;
                break;
            }
        }

        if (
            index != type(uint256).max &&
            ownedEnhancers[_owner][index].amount == 0
        ) {
            ownedEnhancers[_owner][index] = ownedEnhancers[_owner][
                ownedEnhancers[_owner].length - 1
            ];
            ownedEnhancers[_owner].pop();
        }
    }

    /**
     * @dev Returns ids of all available enhancers for particular user
     */
    function getUserEnhancers(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 len = ownedEnhancers[_owner].length;
        uint256[] memory _ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _ids[i] = ownedEnhancers[_owner][i].id;
        }
        return _ids;
    }

    /**
     * @dev Returns types of all enhancers that are stored
     */
    function getEnhancerTypes() external view returns (uint8[] memory) {
        uint8[] memory _types = new uint8[](availableEnhancers.length);

        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            _types[index] = availableEnhancers[index].typeId;
        }

        return _types;
    }

    /**
     * @dev Returns amount of enhancers by it"s id
     * for particular user
     */
    function getEnhancersAmount(address _owner, uint256 id)
        public
        view
        returns (uint256)
    {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 index = 0; index < len; index++) {
            if (ownedEnhancers[_owner][index].id == id) {
                return ownedEnhancers[_owner][index].amount;
            }
        }
        return 0;
    }

    function findEnhancerById(uint256 _id) private view returns (uint256) {
        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            if (_id == availableEnhancers[index].id) {
                return index;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Returns all stored enhancer
     * that are available
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory)
    {
        return availableEnhancers;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title Interface to add alowed operator in additiona to owner
 */
abstract contract IAdmin {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private admins;

    modifier isAdmin() {
        require(admins.contains(msg.sender), "You do not have rights");
        _;
    }

    event AdminAdded(address);
    event AdminRemoved(address);

    function addAdmin(address _admin) external virtual;

    function removeAdmin(address _admin) external virtual;

    function _addAdmin(address _admin) internal {
        require(_admin != address(0), "Address should not be empty");
        require(!admins.contains(_admin), "Already added");
        if (!admins.contains(_admin)) {
            admins.add(_admin);
            emit AdminAdded(_admin);
        }
    }

    function _removeAdmin(address _admin) internal {
        require(admins.contains(_admin), "Not exist");
        if (admins.contains(_admin)) {
            admins.remove(_admin);
            emit AdminRemoved(_admin);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

abstract contract TimelockAccess {
    address public timelock;

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Must call from Timelock");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface ICreationHistory {

    function GENESIS_BASED_SALARY() external view returns (uint256);

    function registerMetaCellForScientist(
        uint256 scientistId,
        uint256 metaCellId
    ) external;

     function registerNanoCellForMetaCell(uint256 metaCellId, uint256 nanoCellId)
        external;

    function getBasedSalary(uint256 scientistId)
        external
        view
        returns (uint256 basedSalary);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 * Sets have the following properties:
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 */
library EnumerableSetUpgradeable {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}