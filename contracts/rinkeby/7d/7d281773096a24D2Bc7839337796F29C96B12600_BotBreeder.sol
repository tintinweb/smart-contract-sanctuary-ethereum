//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IBotBreeder.sol";
import "./Managable.sol";

/*
Genes is uint256
  0  ..   7   ( 8) version
  8  ..  19   (12) ears
 20  ..  31   (12) mask
 32  ..  43   (12) eyes
 44  ..  55   (12) body
 56  ..  67   (12) legs
 68  ..  79   (12) arms
 80  ..  91   (12) aerial
 92  ..  103  ( 8) generation
104  ..  115  ( 8) purity

Every attribute consist of 3 values:
  0 ..  3 (4) Domninant gene
  4 ..  7 (4) Recessive gene
  8 .. 11 (4) Minor gene
*/

contract BotBreeder is IBotBreeder, Managable {
    // номер версии
    uint8 private constant VERSION = 0;

    // attributes offset
    uint8 private constant ATTRIBUTE_OFFSET = (4 + 6) * 3;
    uint8 private constant EARS_OFFSET      = 4;  
    uint8 private constant MASK_OFFSET      = EARS_OFFSET + ATTRIBUTE_OFFSET;
    uint8 private constant EYES_OFFSET      = MASK_OFFSET + ATTRIBUTE_OFFSET;
    uint8 private constant BODY_OFFSET      = EYES_OFFSET + ATTRIBUTE_OFFSET;
    uint8 private constant LEGS_OFFSET      = BODY_OFFSET + ATTRIBUTE_OFFSET;
    uint8 private constant ARMS_OFFSET      = LEGS_OFFSET + ATTRIBUTE_OFFSET;
    uint8 private constant AERIAL_OFFSET    = ARMS_OFFSET + ATTRIBUTE_OFFSET;

    uint8[] private OFFSETS = [
        EARS_OFFSET,
        MASK_OFFSET,
        EYES_OFFSET,
        BODY_OFFSET,
        LEGS_OFFSET,
        ARMS_OFFSET,
        AERIAL_OFFSET
    ];

    uint8[] private producers = [1, 2, 3];
    uint8[] private tiers     = [1, 2, 3];

    // Bitmasks
    // 3 is for 000 - 111 from 0 to 7
    // 4 is for 0000 - 1111 from 0 to 15
    // 6 is for 0000 00 - 1111 11 from 0 to 63
    // 8 is for 0000 0000 - 1111 1111 from 0 to 255
    // 9 is for 0000 0000 0 - 1111 1111 1 from 0 to 511
    // 10 is for 0000 0000 00 - 1111 1111 11 from 0 to 1023
    uint256 private constant MASK2 = 3;
    uint256 private constant MASK3 = 7;
    uint256 private constant MASK4 = 15;
    uint256 private constant MASK6 = 63;
    uint256 private constant MASK8 = 255;
    uint256 private constant MASK9 = 511;
    uint256 private constant MASK10 = 1023;

    event ChangedProducers(uint8[] _producers);
    event ChangesTiers(uint8[] _tiers);

    constructor() {
        _addManager(msg.sender);
    }

    function setProducers(uint8[] calldata _producers) external onlyManager {
        producers = _producers;
        emit ChangedProducers(_producers);
    }

    function setTiers(uint8[] calldata _tiers) external onlyManager {
        tiers = _tiers;
        emit ChangesTiers(_tiers);
    }

    function mixGenes(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _seed
    ) external view override returns (
        uint256 _newgenes
    ) {
        // Version of genes consists in the begging
        _newgenes = VERSION;

        uint256 seed = _seed;
        uint256 mask;

        for (uint8 i = 0; i < OFFSETS.length; i++) {
            (mask, seed) = mixAttribute(
                _genes1,
                _genes2,
                OFFSETS[i],
                seed
            );
            _newgenes |= mask;
        }
    }      

    // возвращает генотип, в котором установлено значение атрибута заданого смещения у потомка
    function mixAttribute(
        uint256 _genes1,
        uint256 _genes2,
        uint8   _o,         // оффсет, по которому находится значение атрибута
        uint256 _seed
    ) internal view returns (
        uint256 _newgenes,
        uint256 _newseed
    ) {
        uint16 _s = 10;
        uint _mask = MASK10;
        uint256 rand;

        // Generating new dummy seed
        (, _newseed) = blumBlumShub(0, _seed);

        // Percentage ranges modulo 100000
        // 37.5     - 37500
        // 9.375    - 9375
        // 3.125    - 3125

        // Generating dominant gene
        // 37.5     - dominant gene of first parent     -- 0        .. 37499
        // 9.375    - recessive gene of first parent    -- 37500    .. 46874
        // 3.125    - minor gene of first parent        -- 46875    .. 49999
        // 37.5     - dominant gene of second parent    -- 50000    .. 87499
        // 9.375    - recessive gene of second parent   -- 87500    .. 96874
        // 3.125    - recessive gene of second parent   -- 96875    .. 99999
        (rand, _newseed) = blumBlumShub(100000, _newseed);
        if (rand <= 37499) {
            _newgenes |= (_genes1 & (_mask << _o));
        } else if (rand <= 46874) {
            _newgenes |= (_genes1 & (_mask << (_o + _s  ))) >> _s;
        } else if (rand <= 49999) {
            _newgenes |= (_genes1 & (_mask << (_o + _s*2))) >> _s*2;
        } else if (rand <= 87499) {
            _newgenes |= (_genes2 & (_mask <<  _o));
        } else if (rand <= 96874) {
            _newgenes |= (_genes2 & (_mask << (_o + _s  ))) >> _s;
        } else {
            _newgenes |= (_genes2 & (_mask << (_o + _s*2))) >> _s*2;
        }

        // Generating recessive genes
        // 50.0     - recessive 
        (rand, _newseed) = blumBlumShub(100, _newseed);
        bool isRecessiveEmpty;

        if (rand <= 50) {
            _newgenes |= (_genes1 & (_mask << (_o + _s  )));
        } else {
            _newgenes |= (_genes2 & (_mask << (_o + _s  )));
        }

        uint recessiveProducer = uint8((_newgenes >> _o + _s) & MASK4);
        if (recessiveProducer == 0) {
            isRecessiveEmpty = true;
        }

        // We have a 10 percent chance to mutate
        if (!isRecessiveEmpty) {
            (rand, _newseed) = blumBlumShub(100, _newseed);

            if (rand <= 10) {
                (rand, _newseed) = blumBlumShub(producers.length, _newseed);
                // We must put new producer
                _newgenes |= rand << (_o + _s);

                // We must calculate new receiver
                uint gene1Tier = uint8((_genes1 >> (_o + _s)) & MASK6);
                uint gene2Tier = uint8((_genes2 >> (_o + _s)) & MASK6);

                (rand, _newseed) = blumBlumShub(100, _newseed);
                if (rand <= 49) {
                    _newgenes |= gene1Tier << (_o + _s + 4);
                } else {
                    _newgenes |= gene2Tier << (_o + _s + 4);
                }
            }
        }


        // Generating minor genes
        // 50.0     - minor 
        (rand, _newseed) = blumBlumShub(100, _newseed);
        bool isMinorEmpty;

        if (rand <= 50) {
            _newgenes |= (_genes1 & (_mask << (_o + _s*2  )));
        } else {
            _newgenes |= (_genes2 & (_mask << (_o + _s*2  )));
        }

        uint minorProducer = uint8((_newgenes >> _o + _s*2) & MASK4);
        if (minorProducer == 0) {
            isMinorEmpty = true;
        }        

        // We have a 10 percent chance to mutate
        if (!isMinorEmpty) {
            (rand, _newseed) = blumBlumShub(100, _newseed);

            if (rand <= 10) {
                (rand, _newseed) = blumBlumShub(producers.length, _newseed);
                // We must put new producer
                _newgenes |= rand << (_o + _s*2);

                // We must calculate new receiver
                uint gene1Tier = uint8((_genes1 >> (_o + _s*2)) & MASK6);
                uint gene2Tier = uint8((_genes2 >> (_o + _s*2)) & MASK6);

                (rand, _newseed) = blumBlumShub(100, _newseed);
                if (rand <= 49) {
                    _newgenes |= gene1Tier << (_o + _s*2 + 4);
                } else {
                    _newgenes |= gene2Tier << (_o + _s*2 + 4);
                }
            }
        }   
    }

    function getPhenotype(uint _genes) public pure returns (uint8[15] memory _pheno) {
        return [
            uint8(0),
            uint8((_genes >> EARS_OFFSET) & MASK4),
            uint8((_genes >> (EARS_OFFSET + 4)) & MASK6),
            uint8((_genes >> MASK_OFFSET) & MASK4),
            uint8((_genes >> (MASK_OFFSET + 4)) & MASK6),
            uint8((_genes >> EYES_OFFSET) & MASK4),
            uint8((_genes >> (EYES_OFFSET + 4)) & MASK6),
            uint8((_genes >> BODY_OFFSET) & MASK4),
            uint8((_genes >> (BODY_OFFSET + 4)) & MASK6),
            uint8((_genes >> LEGS_OFFSET) & MASK4),
            uint8((_genes >> (LEGS_OFFSET + 4)) & MASK6),
            uint8((_genes >> ARMS_OFFSET) & MASK4),
            uint8((_genes >> (ARMS_OFFSET + 4)) & MASK6),
            uint8((_genes >> AERIAL_OFFSET) & MASK4),
            uint8((_genes >> (AERIAL_OFFSET + 4)) & MASK6)
        ];
    }

    function max(uint8 a, uint8 b) internal pure returns (uint8) {
        return a >= b ? a : b;
    }

    // https://en.wikipedia.org/wiki/Blum_Blum_Shub
    function blumBlumShub(uint _modulo, uint _seed) internal pure returns (uint _rand, uint _newseed) {
        // 127 * 257
        _newseed = mulmod(_seed, _seed, 32639);
        if (_modulo > 0) {
            _rand = _newseed % _modulo;
        } else {
            _rand = _newseed;
        }
    }    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBotBreeder {
    function mixGenes(uint256 _genes1, uint256 _genes2, uint256 _seed) external view returns(uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}