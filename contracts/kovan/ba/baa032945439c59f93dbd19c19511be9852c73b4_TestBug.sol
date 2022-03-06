/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

pragma solidity ^0.6.12;

contract TestBug{

    uint64 seend =0;
    uint64 private constant RA = 1103515245;
    uint64 private constant RC = 12345;

    uint64 public constant MAX_HERO_COUNT_LOW_GRADE = 8; // 1 ~ 3 grade
    uint64 public constant MAX_HERO_COUNT_HIGH_GRADE = 24; // 4 ~ 5 grade

    uint32 public constant GRADE4_CODE_MINT_LIMIT = 2000;
    uint32 public constant GRADE5_CODE_MINT_LIMIT = 200;

    function getBUG(uint64 _seed) public returns (
            uint64 seend
        ){
     seend = _seed -2;
    }

    
    function getSeend() public returns (uint) {
        return seend;
    }

    function getHeroProp(uint64 _seed)
        external
        returns (
            uint32 code,
            uint32 grade,
            uint32 power,
            uint64 seed
        )
    {
        seed = (RA * _seed + RC) % 0x7fffffff;
        uint32 val1 = uint32((seed * 1000) >> 31); // 0 ~ 999
        grade = _computeRandGrade(val1 + 1); // 1 ~ 5

        seed = (RA * seed + RC) % 0x7fffffff;
        code = getCode(grade, seed);

        seed = (RA * seed + RC) % 0x7fffffff;
        uint32 val3 = uint32((seed * 100) >> 31);
 
    }

    function _computeRandGrade(uint32 randval) internal pure returns (uint32) {
        uint32 grade;
        if (randval <= 5) {
            grade = 5;
        } else if (randval <= 30) {
            grade = 4;
        } else if (randval <= 110) {
            grade = 3;
        } else if (randval <= 360) {
            grade = 2;
        } else if (randval <= 1000) {
            grade = 1;
        }
        return grade;
    }


    function getBaseCode(uint32 grade) public pure returns (uint32) {
        uint32 baseCode = grade * 100;
        if (grade == 5) {
            baseCode += 100;
        } else if (grade == 6) {
            baseCode += 200;
        }
        return baseCode;
    }

    function getCode(uint32 grade, uint64 seed) private view returns (uint32) {
        uint32 baseCode = getBaseCode(grade);
        if (grade < 4) {
            uint32 val2 = uint32((seed * MAX_HERO_COUNT_LOW_GRADE) >> 31); // 0 ~ maxCount - 1
            uint32 code = baseCode + val2 + 1;
            return code;
        }

        uint32 leng = 0;
        uint32[] memory numbers = new uint32[](MAX_HERO_COUNT_HIGH_GRADE);
        for (uint32 i = 0; i < MAX_HERO_COUNT_HIGH_GRADE; i++) {
            uint32 code = i + 1 + baseCode;
            uint64 num = 0;
            // uint64 num = TinyNFT.itemCodeNumMap(uint16(code));
            if (
                (grade == 4 && num < GRADE4_CODE_MINT_LIMIT) ||
                (grade == 5 && num < GRADE5_CODE_MINT_LIMIT)
            ) {
                numbers[leng] = code;
                leng++;
            }
        }
        require(leng > 0, "Gene: The code has been used up");
        uint32 index = uint32((seed * leng) >> 31); // 0 ~ leng - 1
        uint32 code = numbers[index];
        return code;
    }
}