// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../scientist/interfaces/IScientistRepository.sol";
import "./interfaces/IScientistResearcher.sol";

contract ScientistResearcher is IScientistResearcher {
    modifier isPassedTheLockedBlock(uint256 tokenId) {
        require(
            block.number >= currentLockBlock[tokenId],
            "Scientist id must be passed locked block"
        );
        _;
    }

    modifier isOwnerOf(uint256 tokenId) {
        address scientistToken = address(scientistInstance);
        address ownerOf = IERC721(scientistToken).ownerOf(tokenId);
        require(
            ownerOf == msg.sender,
            "You are not owner of this scientist"
        );
        _;
    }

    // Instance of Scientist address
    IScientistRepository public scientistInstance;

    // Limitation of times can research of technicals
    uint256 public constant LIMIT_OF_TECH_LV_TWO = 3;
    uint256 public constant LIMIT_OF_TECH_LV_THREE = 4;
    uint256 public constant LIMIT_OF_TECH_LV_FOUR = 1;
    uint256 public constant LIMIT_OF_TECH_LV_FIVE = 1;

    // Block number when scientist researach technicals
    uint256 public constant BLOCK_LOCK_TECH_LV_ONE = 10;
    uint256 public constant BLOCK_LOCK_TECH_LV_TWO = 20;
    uint256 public constant BLOCK_LOCK_TECH_LV_THREE = 30;
    uint256 public constant BLOCK_LOCK_TECH_LV_FOUR = 40;
    uint256 public constant BLOCK_LOCK_TECH_LV_FIVE = 50;

    // Messages constant
    string private constant ERR_NOT_RESEARCH_ENOUGH =
        "Must research enough technicals";

    string private constant ERR_NOT_RESEARCH_MORE =
        "Scientist can not research this tech any more";

    // Technicals level of Scientists
    mapping(uint256 => TechnicalLevelOne) public technicalLevelOne;
    mapping(uint256 => TechnicalLevelTwo) public technicalLevelTwo;
    mapping(uint256 => TechnicalLevelThree) public technicalLevelThree;
    mapping(uint256 => TechnicalLevelFour) public technicalLevelFour;
    mapping(uint256 => TechnicalLevelFive) public technicalLevelFive;

    // Special effects of Scientists
    mapping(uint256 => SpecialEffect) private specialEffects;

    // Block lock of Scientists
    mapping(uint256 => uint256) public currentLockBlock;

    constructor(IScientistRepository _scientistInstance) {
        scientistInstance = _scientistInstance;
    }

    function getSpecialEffects(uint256 tokenId)
        external
        view
        override
        returns (SpecialEffect memory)
    {
        return specialEffects[tokenId];
    }

    /**
     * @dev Research technical level 1 - Physics
     * NOTE Explainations about function:
     * - Scientist will gain 1 point physics for each researching
     * @param _scientist is scientist data
     */
    function _researchSkillPhysics(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        technicalLevelOne[_tokenId].physics += 1;

        _scientist.point.physics += 1;
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    /**
     * @dev Research technical level 1 - Chemistry
     * NOTE Explainations about function:
     * - Scientist will gain 1 point chemistry for each researching
     * @param _scientist is scientist data
     */
    function _researchSkillChemistry(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        technicalLevelOne[_tokenId].chemistry += 1;

        _scientist.point.chemistry += 1;
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    /**
     * @dev Research technical level 1 - Biology
     * NOTE Explainations about function:
     * - Scientist will gain 1 point biology for each researching
     * @param _scientist is scientist data
     */
    function _researchSkillBiology(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        technicalLevelOne[_tokenId].biology += 1;

        _scientist.point.biology += 1;
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    /**
     * @dev Research technical level 1 - Sociology
     * NOTE Explainations about function:
     * - Scientist will gain 1 point sociology for each researching
     * @param _scientist is scientist data
     */
    function _researchSkillSociology(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        technicalLevelOne[_tokenId].sociology += 1;

        _scientist.point.sociology += 1;
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    /**
     * @dev Research technical level 1 - Mathematics
     * NOTE Explainations about function:
     * - Scientist will gain 1 point mathematics for each researching
     * @param _scientist is scientist data
     */
    function _researchSkillMathematics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        technicalLevelOne[_tokenId].mathematics += 1;

        _scientist.point.mathematics += 1;
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    /**
     * @dev Research technical level 2 - Genetics
     * NOTE Explainations about function:
     * - Scientist will gain 1 point chemistry and 1 point biology for each researching
     * - Increase 1% higher chance to split into Nanocells at the first time researching
     * @param _scientist is scientist data
     */
    function _researchSkillGenetics(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].genetics < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(
            _techLvOne.biology >= 1 && _techLvOne.chemistry >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelTwo[_tokenId].genetics += 1;

        _scientist.point.chemistry += 1;
        _scientist.point.biology += 1;
        if (technicalLevelTwo[_tokenId].genetics == 1) {
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
                1
            );
        }
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    /**
     * @dev Research technical level 2 - Nutrition
     * NOTE Explainations about function:
     * - Scientist will 2 points biology at the first researching
     *   and 1 point biology for next researching
     * - Allows MAD Metacells to permanently evolve 1% faster at the first time researching
     * @param _scientist is scientist data
     */
    function _researchSkillNutrition(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].nutrition < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(_techLvOne.biology >= 1, ERR_NOT_RESEARCH_ENOUGH);
        technicalLevelTwo[_tokenId].nutrition += 1;

        if (technicalLevelTwo[_tokenId].nutrition == 1) {
            _scientist.point.biology += 2;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME,
                1
            );
        } else {
            _scientist.point.biology += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillEngineering(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].engineering < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(
            _techLvOne.physics >= 1 && _techLvOne.mathematics >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelTwo[_tokenId].engineering += 1;

        _scientist.point.physics += 1;
        _scientist.point.mathematics += 1;
        if (technicalLevelTwo[_tokenId].engineering == 1) {
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                1
            );
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillAstroPhysics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].astroPhysics < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(
            _techLvOne.physics >= 1 && _techLvOne.mathematics >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelTwo[_tokenId].astroPhysics += 1;

        _scientist.point.physics += 1;
        _scientist.point.mathematics += 1;
        if (technicalLevelTwo[_tokenId].astroPhysics == 1) {
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                1
            );
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillEconomics(ScientistData.Scientist memory _scientist)
        internal
    {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].economics < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(_techLvOne.mathematics >= 1, ERR_NOT_RESEARCH_ENOUGH);
        technicalLevelTwo[_tokenId].economics += 1;

        if (technicalLevelTwo[_tokenId].economics == 1) {
            _scientist.point.mathematics += 2;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
                1
            );
        } else {
            _scientist.point.mathematics += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillComputerScience(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].computerScience < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(_techLvOne.mathematics >= 1, ERR_NOT_RESEARCH_ENOUGH);
        technicalLevelTwo[_tokenId].computerScience += 1;

        if (technicalLevelTwo[_tokenId].computerScience == 1) {
            _scientist.point.mathematics += 2;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
                1
            );
        } else {
            _scientist.point.mathematics += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillQuantumMechanics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].quantumMechanics < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(_techLvOne.physics >= 1, ERR_NOT_RESEARCH_ENOUGH);
        technicalLevelTwo[_tokenId].quantumMechanics += 1;

        if (technicalLevelTwo[_tokenId].quantumMechanics == 1) {
            _scientist.point.physics += 2;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME,
                1
            );
        } else {
            _scientist.point.physics += 1;
        }
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillCliodynamics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelTwo[_tokenId].cliodynamics < LIMIT_OF_TECH_LV_TWO,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        require(
            _techLvOne.mathematics >= 1 && _techLvOne.sociology >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelTwo[_tokenId].cliodynamics += 1;

        _scientist.point.sociology += 1;
        _scientist.point.mathematics += 1;
        if (technicalLevelTwo[_tokenId].cliodynamics == 1) {
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
                1
            );
        }
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillExometeorology(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].exometeorology <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(_techLvTwo.astroPhysics >= 1, ERR_NOT_RESEARCH_ENOUGH);
        technicalLevelThree[_tokenId].exometeorology += 1;

        if (technicalLevelThree[_tokenId].exometeorology == 1) {
            _scientist.point.physics += 2;
            _scientist.point.mathematics += 1;

            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
                1
            );
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME,
                1
            );
        } else {
            _scientist.point.physics += 1;
            _scientist.point.mathematics += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillNutrigenomics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].nutrigenomics <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvTwo.genetics >= 1 && _techLvTwo.nutrition >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelThree[_tokenId].nutrigenomics += 1;

        if (technicalLevelThree[_tokenId].nutrigenomics == 1) {
            _scientist.point.chemistry += 2;
            _scientist.point.biology += 1;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME,
                2
            );
        } else {
            _scientist.point.chemistry += 1;
            _scientist.point.biology += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillSyntheticBiology(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].syntheticBiology <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvOne.biology >= 1 && _techLvTwo.engineering >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelThree[_tokenId].syntheticBiology += 1;

        if (technicalLevelThree[_tokenId].syntheticBiology == 1) {
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                2
            );
        }
        _scientist.point.physics += 1;
        _scientist.point.biology += 1;
        _scientist.point.mathematics += 1;
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillRecombinatMemetics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].recombinatMemetics <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvOne.sociology >= 1 && _techLvTwo.genetics >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelThree[_tokenId].recombinatMemetics += 1;

        if (technicalLevelThree[_tokenId].recombinatMemetics == 1) {
            _scientist.point.chemistry += 2;
            _scientist.point.sociology += 1;

            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME,
                1
            );
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                1
            );
        } else {
            _scientist.point.chemistry += 1;
            _scientist.point.sociology += 1;
        }
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillComputationalLexicology(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].computationalLexicology <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvOne.sociology >= 1 && _techLvTwo.computerScience >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelThree[_tokenId].computationalLexicology += 1;

        if (technicalLevelThree[_tokenId].computationalLexicology == 1) {
            _scientist.point.mathematics += 2;
            _scientist.point.sociology += 1;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                2
            );
        } else {
            _scientist.point.mathematics += 1;
            _scientist.point.sociology += 1;
        }
        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillComputationalEconomics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].computationalEconomics <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvTwo.economics >= 1 && _techLvTwo.computerScience >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelThree[_tokenId].computationalEconomics += 1;

        if (technicalLevelThree[_tokenId].computationalEconomics == 1) {
            _scientist.point.mathematics += 2;
            _scientist.point.sociology += 1;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                2
            );
        } else {
            _scientist.point.mathematics += 1;
            _scientist.point.sociology += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillComputationalSociology(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].computationalSociology <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvOne.sociology >= 1 && _techLvTwo.computerScience >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );

        technicalLevelThree[_tokenId].computationalSociology += 1;

        if (technicalLevelThree[_tokenId].computationalSociology == 1) {
            _scientist.point.mathematics += 2;
            _scientist.point.sociology += 1;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
                2
            );
        } else {
            _scientist.point.mathematics += 1;
            _scientist.point.sociology += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillCognitiveEconomics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelThree[_tokenId].cognitiveEconomics <
                LIMIT_OF_TECH_LV_THREE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        require(
            _techLvOne.sociology >= 1 && _techLvTwo.economics >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );

        technicalLevelThree[_tokenId].cognitiveEconomics += 1;

        if (technicalLevelThree[_tokenId].cognitiveEconomics == 1) {
            _scientist.point.mathematics += 2;
            _scientist.point.sociology += 1;
            _activeSpecialEffect(
                _tokenId,
                SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
                2
            );
        } else {
            _scientist.point.mathematics += 1;
            _scientist.point.sociology += 1;
        }

        scientistInstance.updateScientist(_scientist, msg.sender);
    }

    function _researchSkillCulturomics(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelFour[_tokenId].culturomics < LIMIT_OF_TECH_LV_FOUR,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelThree memory _techLvThree = technicalLevelThree[_tokenId];
        require(
            _techLvThree.computationalLexicology >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelFour[_tokenId].culturomics += 1;
        _activeSpecialEffect(
            _tokenId,
            SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
            4
        );
    }

    function _researchSkillQuantumBiology(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelFour[_tokenId].quantumBiology < LIMIT_OF_TECH_LV_FOUR,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelOne memory _techLvOne = technicalLevelOne[_tokenId];
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        TechnicalLevelThree memory _techLvThree = technicalLevelThree[_tokenId];
        require(
            _techLvOne.biology >= 1 &&
                _techLvOne.chemistry >= 1 &&
                _techLvTwo.quantumMechanics >= 1 &&
                _techLvThree.cognitiveEconomics >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelFour[_tokenId].quantumBiology += 1;
        _activeSpecialEffect(
            _tokenId,
            SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
            4
        );
    }

    function _researchSkillComputationalSocialScience(
        ScientistData.Scientist memory _scientist
    ) internal {
        uint256 _tokenId = _scientist.tokenId;
        require(
            technicalLevelFive[_tokenId].computationalSocialScience <
                LIMIT_OF_TECH_LV_FIVE,
            ERR_NOT_RESEARCH_MORE
        );
        TechnicalLevelTwo memory _techLvTwo = technicalLevelTwo[_tokenId];
        TechnicalLevelThree memory _techLvThree = technicalLevelThree[_tokenId];
        TechnicalLevelFour memory _techLvFour = technicalLevelFour[_tokenId];

        require(
            _techLvTwo.cliodynamics >= 1 &&
                _techLvThree.computationalEconomics >= 1 &&
                _techLvThree.computationalSociology >= 1 &&
                _techLvFour.culturomics >= 1,
            ERR_NOT_RESEARCH_ENOUGH
        );
        technicalLevelFive[_tokenId].computationalSocialScience += 1;
        _activeSpecialEffect(
            _tokenId,
            SpecialSetEffect.CHANCE_SPLIT_NANO_CELL,
            2
        );
        _activeSpecialEffect(
            _tokenId,
            SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME,
            2
        );
        _activeSpecialEffect(
            _tokenId,
            SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL,
            2
        );
    }

    function _activeSpecialEffect(
        uint256 _tokenId,
        SpecialSetEffect _effect,
        uint8 _addedValue
    ) internal {
        if (_effect == SpecialSetEffect.CHANCE_SPLIT_NANO_CELL) {
            specialEffects[_tokenId].chanceSplitNanoCell += _addedValue;
        } else if (_effect == SpecialSetEffect.BUFF_EVOLVE_META_CELL_TIME) {
            specialEffects[_tokenId].buffEvolveMetaCellTime += _addedValue;
        } else if (_effect == SpecialSetEffect.PLUS_ATTRIBUTES_FOR_NANO_CELL) {
            specialEffects[_tokenId].plusAttributesForNanoCell += _addedValue;
        }
    }

    function _lockBlockForNextResearching(
        uint256 _tokenId,
        uint256 _blockNumber
    ) internal {
        currentLockBlock[_tokenId] = block.number + _blockNumber;
    }

    function researchTechLevelOne(uint256 tokenId, TechSetLevelOne tech)
        external
        override
        isPassedTheLockedBlock(tokenId)
    {
        ScientistData.Scientist memory scientist = scientistInstance
            .getScientist(tokenId);

        if (tech == TechSetLevelOne.PHYSICS) {
            _researchSkillPhysics(scientist);
        } else if (tech == TechSetLevelOne.CHEMISTRY) {
            _researchSkillChemistry(scientist);
        } else if (tech == TechSetLevelOne.BIOLOGY) {
            _researchSkillBiology(scientist);
        } else if (tech == TechSetLevelOne.SCIOLOGY) {
            _researchSkillSociology(scientist);
        } else if (tech == TechSetLevelOne.MATHEMATICS) {
            _researchSkillMathematics(scientist);
        }
        _lockBlockForNextResearching(tokenId, BLOCK_LOCK_TECH_LV_ONE);

        emit ResearchTech({
            owner: msg.sender,
            tokenId: tokenId,
            levelTechnical: uint256(TechLevel.ONE),
            technicalSkill: uint256(tech),
            timestamp: block.timestamp
        });
    }

    function researchTechLevelTwo(uint256 tokenId, TechSetLevelTwo tech)
        external
        override
        isOwnerOf(tokenId)
        isPassedTheLockedBlock(tokenId)
    {
        
        ScientistData.Scientist memory scientist = scientistInstance
            .getScientist(tokenId);
        if (tech == TechSetLevelTwo.GENETICS) {
            _researchSkillGenetics(scientist);
        } else if (tech == TechSetLevelTwo.NUTRITION) {
            _researchSkillNutrition(scientist);
        } else if (tech == TechSetLevelTwo.ENGINEERING) {
            _researchSkillEngineering(scientist);
            // Need description about skill
        } else if (tech == TechSetLevelTwo.ASTRO_PHYSICS) {
            _researchSkillAstroPhysics(scientist);
        } else if (tech == TechSetLevelTwo.ECONOMICS) {
            _researchSkillEconomics(scientist);
            // Need description about skill
        } else if (tech == TechSetLevelTwo.COMPUTER_SCIENCE) {
            _researchSkillComputerScience(scientist);
        } else if (tech == TechSetLevelTwo.QUANTUM_MECHANICS) {
            _researchSkillQuantumMechanics(scientist);
        } else if (tech == TechSetLevelTwo.CLIODYNAMICS) {
            _researchSkillCliodynamics(scientist);
        }
        _lockBlockForNextResearching(tokenId, BLOCK_LOCK_TECH_LV_TWO);

        emit ResearchTech({
            owner: msg.sender,
            tokenId: tokenId,
            levelTechnical: uint256(TechLevel.TWO),
            technicalSkill: uint256(tech),
            timestamp: block.timestamp
        });
    }

    function researchTechLevelThree(uint256 tokenId, TechSetLevelThree tech)
        external
        override
        isOwnerOf(tokenId)
        isPassedTheLockedBlock(tokenId)
    {
        
        ScientistData.Scientist memory scientist = scientistInstance
            .getScientist(tokenId);
        if (tech == TechSetLevelThree.EXOMETEOROLOGY) {
            _researchSkillExometeorology(scientist);
        } else if (tech == TechSetLevelThree.NUTRIGENOMICS) {
            _researchSkillNutrigenomics(scientist);
        } else if (tech == TechSetLevelThree.SYNTHETIC_BIOLOGY) {
            _researchSkillSyntheticBiology(scientist);
        } else if (tech == TechSetLevelThree.RECOMBINAT_MEMETIC) {
            _researchSkillRecombinatMemetics(scientist);
        } else if (tech == TechSetLevelThree.COMPUTATIONAL_LEXICOLOGY) {
            _researchSkillComputationalLexicology(scientist);
        } else if (tech == TechSetLevelThree.COMPUTATIONAL_ECONOMICS) {
            _researchSkillComputationalEconomics(scientist);
            // Need description about skill
        } else if (tech == TechSetLevelThree.COMPUTATIONAL_SOCIOLOGY) {
            _researchSkillComputationalSociology(scientist);
            // Need description about skill
        } else if (tech == TechSetLevelThree.COGNITIVE_ECONOMICS) {
            _researchSkillCognitiveEconomics(scientist);
        }
        _lockBlockForNextResearching(tokenId, BLOCK_LOCK_TECH_LV_THREE);
        emit ResearchTech({
            owner: msg.sender,
            tokenId: tokenId,
            levelTechnical: uint256(TechLevel.THREE),
            technicalSkill: uint256(tech),
            timestamp: block.timestamp
        });
    }

    function researchTechLevelFour(uint256 tokenId, TechSetLevelFour tech)
        external
        override
        isOwnerOf(tokenId)
        isPassedTheLockedBlock(tokenId)
    {
        
        ScientistData.Scientist memory scientist = scientistInstance
            .getScientist(tokenId);
        if (tech == TechSetLevelFour.CULTUROMICS) {
            _researchSkillCulturomics(scientist);
        } else if (tech == TechSetLevelFour.QUANTUM_BIOLOGY) {
            _researchSkillQuantumBiology(scientist);
        }
        _lockBlockForNextResearching(tokenId, BLOCK_LOCK_TECH_LV_FOUR);
        emit ResearchTech({
            owner: msg.sender,
            tokenId: tokenId,
            levelTechnical: uint256(TechLevel.FOUR),
            technicalSkill: uint256(tech),
            timestamp: block.timestamp
        });
    }

    function researchTechLevelFive(uint256 tokenId, TechSetLevelFive tech)
        external
        override
        isOwnerOf(tokenId)
        isPassedTheLockedBlock(tokenId)
    {
        
        ScientistData.Scientist memory scientist = scientistInstance
            .getScientist(tokenId);
        if (tech == TechSetLevelFive.COMPUTAIONAL_SOCIAL_SCIENCE) {
            _researchSkillComputationalSocialScience(scientist);
        }
        _lockBlockForNextResearching(tokenId, BLOCK_LOCK_TECH_LV_FIVE);
        emit ResearchTech({
            owner: msg.sender,
            tokenId: tokenId,
            levelTechnical: uint256(TechLevel.FIVE),
            technicalSkill: uint256(tech),
            timestamp: block.timestamp
        });
    }

    function remainingLockedBlockNumber(uint256 tokenId)
        external
        view
        returns (uint256 remainingLockedBlock)
    {
        remainingLockedBlock = currentLockBlock[tokenId] > block.number
            ? currentLockBlock[tokenId] - block.number
            : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "../../libs/ScientistData.sol";

/**
 * @title Interface for interaction with particular scientist
 */
interface IScientistRepository {
    function addScientist(ScientistData.Scientist memory _scientist) external;

    function removeScientist(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta scientist id's for particular user
     */
    function getUserMetascientistsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateScientist(
        ScientistData.Scientist memory _scientist,
        address _owner
    ) external;

    function getScientist(uint256 _tokenId)
        external
        view
        returns (ScientistData.Scientist memory);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Representation of scientitst with it fields
 */
library ScientistData {
    /**
     *  Represents the basic parameters that describes scientist
     */
    struct Scientist {
        uint256 tokenId;
        address user;
        uint256 level;
        string tokenUri;
        bool onSale;
        uint256 price;
        Point point;
    }

    struct Point {
        uint256 physics;
        uint256 chemistry;
        uint256 biology;
        uint256 sociology;
        uint256 mathematics;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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