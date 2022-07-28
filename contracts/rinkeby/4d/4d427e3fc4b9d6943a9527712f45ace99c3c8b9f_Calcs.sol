/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Miner {
    int16 baseHealth;  // 基础血条
    int16 baseArmor;   // 基础装甲
    int16 health;      // 血条
    int16 armor;       // 盔甲
    int16 attack;      // 攻击
    int16 speed;       // 速度
    uint16 gold;       // 黄金
    uint8 genderId;    // 性别编号
    uint8 classId;     // 类别编号
    uint8 skintoneId;  // 皮肤编号
    uint8 hairColorId; // 头发颜色编号
    uint8 hairTypeId;  // 头发类型编号
    uint8 eyeColorId;  // 眼睛颜色编号
    uint8 eyeTypeId;   // 眼睛类型编号
    uint8 mouthId;     // 嘴巴编号
    uint8 headgearId;  // 头饰编号
    uint8 armorId;     // 装甲编号
    uint8 pantsId;     // 裤子编号
    uint8 footwearId;  // 鞋类编号
    uint8 weaponId;    // 武器编号
    uint8 curseTurns;  // 诅咒
    uint8 buffTurns;   // 增益
    uint8 debuffTurns; // 减益
    uint8 revives;     // 复活
    uint8 currentChamber;   // 当前房间
}

struct Monster {
    int16 health; // 血条
    int16 attack; // 攻击
    int16 speed;  // 速度
    uint8 mtype;  // 类型
}

// 打包变量
struct PackedVars {  
    int8 var_int8_1;
    int8 var_int8_2;
    int8 var_int8_3;
    int8 var_int8_4;
    int8 var_int8_5;
    int8 var_int8_6;
    uint8 var_uint8_1;
    uint8 var_uint8_2;
    uint8 var_uint8_3;
    uint8 var_uint8_4;
    uint8 var_uint8_5;
    uint8 var_uint8_6;
    int16 var_int16_1;
    int16 var_int16_2;
    int16 var_int16_3;
    int16 var_int16_4;
    uint16 var_uint16_1;
    uint16 var_uint16_2;
    uint16 var_uint16_3;
    uint16 var_uint16_4;
    uint32 var_uint32_1;
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


library Calcs {
    using Strings for *;

    /**
    * @notice return a headgear stats array  // 返回一个头饰统计数组
    * @param gearId the gear id of the headgear item  // 头饰道具的装备ID
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item  // 返回 int16 值数组，代表项目的 HP buff、AP buff、ATK buff、SPD buff、小资产 id 和大资产 id
    */
    function headgearStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            // common  常见
            [int16(0),0,0,0,    0,3],       // 0  | C | none   无头饰

            // uncommon = 8 total 不常见 = 共 8 个
            // Health & Attack  健康、攻击
            [int16(3),0,5,0,    1,7],       // 1  | U | bandana 头巾
            [int16(6),0,2,0,    2,10],      // 2  | U | leather hat 皮帽
            [int16(2),0,6,0,    3,11],      // 3  | U | rusty helm  生锈的头盔
            [int16(4),0,4,0,    4,8],       // 4  | U | feathered cap 羽毛帽

            // rare = 14 total   稀有 = 共 14 个
            // Health & Armor & Attack 健康、护甲、攻击
            [int16(7),5,2,0,    5,4],       // 5  | R | enchanted crown  魔法皇冠
            [int16(5),5,4,0,    6,12],      // 6  | R | bronze helm  青铜头盔
            [int16(2),4,8,0,    7,0],       // 7  | R | assassin's mask  刺客的面具

            // epic = 24 total  史诗 = 总共 24
            // Health & Armor & Attack 健康、护甲、攻击
            [int16(6),12,6,0,    8,13],     // 8  | E | iron helm   钢铁头盔
            [int16(9),6,9,0,    15,16],     // 9  | E | skull helm  骷髅头盔
            [int16(9),6,9,0,    14,6],      // 10 | E | charmed headband  迷人的头带
            [int16(9),6,9,0,    12,9],      // 11 | E | ranger cap   游侠帽
            [int16(9),6,9,0,    10,1],      // 12 | E | misty hood   迷雾罩
 
            // legendary = 42 total  传奇 = 总共 42
            // Health & Armor & Attack & Speed  健康、护甲、攻击、速度
            [int16(13),10,13,6,    16,17],  // 13 | L | phoenix helm   凤凰头盔
            [int16(13),10,13,6,    13,5],   // 14 | L | ancient mask   古代面具
            [int16(13),10,13,6,    11,15],  // 15 | L | genesis helm   创世头盔
            [int16(13),10,13,6,    9,14]    // 16 | L | soul shroud    灵魂裹尸布
        ];
        return GEAR[gearId];
    }

    /**
    * @notice return an armor stats array   // 返回一个盔甲统计数据数组
    * @param gearId the gear id of the armor item  // 护甲道具的装备ID
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function armorStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            // common  常见
            [int16(0),0,0,0,    0,0],       // 17 | C | cotton shirt  棉衬衫

            // uncommon = 8 total  不常见 = 共 8 个
            // Health & Armor     健康、护甲
            [int16(3),5,0,0,    0,1],       // 18 | U | thick vest  厚背心
            [int16(4),4,0,0,    0,2],       // 19 | U | leather chestplate  皮革胸甲
            [int16(2),6,0,0,    3,3],       // 20 | U | rusty chainmail    生锈的锁子甲
            [int16(6),2,0,0,    0,4],       // 21 | U | longcoat   长大衣

            // rare = 14 total   稀有 = 共 14 个
            // Health & Armor & Attack  健康、护甲、攻击 
            [int16(6),4,4,0,    3,5],       // 22 | R | chainmail          锁子甲
            [int16(5),6,3,0,    0,6],       // 23 | R | bronze chestplate  青铜胸甲
            [int16(6),6,2,0,    0,7],       // 24 | R | blessed armor      被祝福的盔甲

            // epic = 24 total
            // Health & Armor & Attack  健康、护甲、攻击
            [int16(6),7,11,0,    0,8],      // 25 | E | iron chestplate    钢铁胸甲
            [int16(9),9,6,0,    2,9],       // 26 | E | skull armor        骷髅盔甲
            [int16(9),9,6,0,    1,10],      // 27 | E | cape of deception  欺骗斗篷
            [int16(9),9,6,0,    1,11],      // 28 | E | mystic cloak       神秘斗篷
            [int16(9),9,6,0,    4,12],      // 29 | E | shimmering cloak   闪闪发光的斗篷

            // legendary = 42 total   传奇 = 总共 42
            // Health & Armor & Attack & Speed   健康、护甲、攻击、速度
            [int16(13),13,10,6,    0,13],   // 30 | L | phoenix chestplate   凤凰胸甲
            [int16(13),13,10,6,    0,14],   // 31 | L | ancient robe         古代长袍
            [int16(13),13,10,6,    1,15],   // 32 | L | genesis cloak        创世斗篷
            [int16(13),13,10,6,    1,16]    // 33 | L | soul cloak           灵魂斗篷
        ];
        return GEAR[gearId - 17];
    }

    /**
    * @notice return a pants stats array         // 返回一个裤子统计数组
    * @param gearId the gear id of the pants item   // 裤子道具的装备ID
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function pantsStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            // common  常见
            [int16(0),0,0,0,    0,0],       // 34 | C | cotton pants   棉裤

            // uncommon = 8 total   不常见 = 共 8 个
            // Armor & Speed     护甲、速度
            [int16(0),6,0,2,    0,0],       // 35 | U | thick pants   厚裤子
            [int16(0),4,0,4,    0,0],       // 36 | U | leather greaves  皮革护胫
            [int16(0),3,0,5,    3,0],       // 37 | U | rusty chainmail pants  生锈的锁子甲裤
            [int16(0),2,0,6,    0,0],       // 38 | U | reliable leggings  可靠的紧身裤

            // rare = 14 total   稀有 = 共 14 个
            // Health & Armor & Speed   健康、护甲、速度
            [int16(2),4,0,8,    0,0],       // 39 | R | padding leggings  填充打底裤
            [int16(3),5,0,6,    1,0],       // 40 | R | bronze greaves    青铜护胫
            [int16(5),5,0,4,    0,0],       // 41 | R | enchanted pants   魔法裤子

            // epic = 24 total  史诗 = 总共 24
            // Health & Armor & Speed   健康、护甲、速度
            [int16(8),9,0,7,    1,0],       // 42 | E | iron greaves   钢铁护胫
            [int16(6),9,0,9,    0,0],       // 43 | E | skull greaves  骷髅护胫
            [int16(6),9,0,9,    0,0],       // 44 | E | swift leggings  快速打底裤
            [int16(6),9,0,9,    0,0],       // 45 | E | forest greaves  森林护胫
            [int16(6),9,0,9,    0,0],       // 46 | E | silent leggings  无声紧身裤

            // legendary = 42 total   传奇 = 总共 42
            // Health & Armor & Attack & Speed  健康、护甲、攻击、速度
            [int16(10),13,6,13,    0,0],    // 47 | L | phoenix greaves   凤凰护胫
            [int16(10),13,6,13,    2,0],    // 48 | L | ancient greaves   远古护胫
            [int16(10),13,6,13,    0,0],    // 49 | L | genesis greaves   创世护胫
            [int16(10),13,6,13,    0,0]     // 50 | L | soul greaves      灵魂护胫
        ];
        return GEAR[gearId - 34];
    }

    /**
    * @notice return a footwear stats array    // 返回一个鞋类统计数据数组
    * @param gearId the gear id of the footwear item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function footwearStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            // common  常见
            [int16(0),0,0,0,    0,0],       // 51 | C | none   无鞋饰

            // uncommon = 8 total  不常见
            // Health & Speed   健康 速度
            [int16(3),0,0,5,    1,0],       // 52 | U | sturdy cleats  坚固的防滑钉
            [int16(4),0,0,4,    1,0],       // 53 | U | leather boots   皮靴
            [int16(6),0,0,2,    2,0],       // 54 | U | rusty boots     生锈的靴子
            [int16(2),0,0,6,    0,0],       // 55 | U | lightweight shoes  轻便鞋

            // rare = 14 total   // 稀有
            // Health & Attack & Speed   健康 攻击  速度
            [int16(2),0,3,9,    2,0],       // 56 | R | bandit's shoes   强盗的鞋子
            [int16(5),0,4,5,    2,0],       // 57 | R | bronze boots     青铜靴
            [int16(6),0,5,3,    6,0],       // 58 | R | heavy boots      沉重的靴子

            // epic = 24 total  // 史诗
            // Health & Attack & Speed  健康 攻击 速度
            [int16(9),0,10,5,    2,0],      // 59 | E | iron boots      铁靴
            [int16(9),0,6,9,    1,0],       // 60 | E | skull boots     骷髅靴
            [int16(9),0,6,9,    1,0],       // 61 | E | enchanted boots  魔法靴子
            [int16(9),0,6,9,    4,0],       // 62 | E | jaguarpaw boots  美洲豹靴子
            [int16(9),0,6,9,    3,0],       // 63 | E | lightfoot boots  轻足靴

            // legendary = 42 total   // 传奇
            // Health & Armor & Attack & Speed  健康 装甲 攻击 速度
            [int16(13),6,10,13,    5,0],    // 64 | L | phoenix boots   凤凰靴
            [int16(13),6,10,13,    1,0],    // 65 | L | ancient boots   古代靴子
            [int16(13),6,10,13,    1,0],    // 66 | L | genesis boots   创世靴子
            [int16(13),6,10,13,    2,0]     // 67 | L | soul boots      灵魂靴子
        ];
        return GEAR[gearId - 51];
    }

    /**
    * @notice return a weapon stats array   // 返回一个武器统计数组
    * @param gearId the gear id of the weapon item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function weaponStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][29] memory GEAR = [
            // common 常见 
            [int16(0),0,0,0,    0,5],       // 68 | C | fists   拳头

            // uncommon = 8 total  不常见
            // Attack & Speed   攻击 速度
            [int16(0),0,4,4,    1,6],       // 69 | U | rusty sword    生锈的剑
            [int16(0),0,6,2,    8,20],      // 70 | U | wooden club    棒槌
            [int16(0),0,5,3,    7,1],       // 71 | U | pickaxe        镐
            [int16(0),0,2,6,    6,0],       // 72 | U | brass knuckles  指节铜环

            // rare = 14 total  稀有
            // Armor & Attack & Speed  装甲 攻击 速度
            [int16(0),2,6,6,    19,28],     // 73 | R | weathered greataxe  风化的巨斧
            [int16(0),2,6,6,    5,18],      // 74 | R | polished scepter    抛光权杖
            [int16(0),2,6,6,    14,24],     // 75 | R | poisoned spear      毒矛
            [int16(0),2,6,6,    11,3],      // 76 | R | kusarigama          草镰
            [int16(0),4,4,6,    1,7],       // 77 | R | bronze sword        青铜剑
            [int16(0),4,4,6,    4,15],      // 78 | R | bronze staff        青铜法杖
            [int16(0),4,4,6,    13,23],     // 79 | R | bronze shortsword   青铜短剑
            [int16(0),4,4,6,    2,9],       // 80 | R | bronze daggers      青铜匕首
            [int16(0),2,4,8,    18,27],     // 81 | R | dusty scmitar       蒙尘的弯刀
            [int16(0),2,4,8,    15,25],     // 82 | R | silver wand         银魔杖
            [int16(0),2,4,8,    12,22],     // 83 | R | dual handaxes       双手斧
            [int16(0),2,4,8,    10,21],     // 84 | R | dual shortswords    双手短剑

            // epic = 24 total    史诗
            // Armor & Attack & Speed   装甲 攻击  速度
            [int16(0),7,9,8,    1,8],       // 85 | E | holy sword    圣剑
            [int16(0),7,9,8,    4,16],      // 86 | E | holy staff    圣杖
            [int16(0),7,9,8,    3,12],      // 87 | E | holy bow      圣弓
            [int16(0),7,9,8,    2,10],      // 88 | E | holy daggers  神圣匕首
            [int16(0),5,9,10,    17,26],    // 89 | E | soulcutter    灵魂切割者
            [int16(0),5,9,10,    4,17],     // 90 | E | shadow staff  暗影法杖
            [int16(0),5,9,10,    3,13],     // 91 | E | shadow bow    暗影弓
            [int16(0),5,9,10,    9,2],      // 92 | E | shadowblades  暗影刃

            // legendary = 42 total   传奇
            // Health & Armor & Attack & Speed  健康 装甲 攻击 速度
            [int16(6),10,13,13,    16,4],   // 93 | L | phoenix blade   凤凰刀
            [int16(6),10,13,13,    5,19],   // 94 | L | ancient scepter 古代权杖
            [int16(6),10,13,13,    3,14],   // 95 | L | genesis bow     创世弓
            [int16(6),10,13,13,    2,11]    // 96 | L | soul daggers    灵魂匕首
        ];

        return GEAR[gearId - 68];
    }

    /**
    * @notice return a uint16 value from a bytes32 hash, given an offset
    * @param hash the bytes32 hash to retrieve a uint16 from
    * @param offset the offset from 0 to grab the data from
    * @return uint16 value cast to a uint256
    */
    function _hashToUint16(bytes32 hash, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        require(30 >= offset, "oob");
        return uint256((hash << (offset * 8)) >> 240);
    }

    /**
    * @notice calculate a gear type
    * @param typeVal a uint value between 0-255
    * @return uint8 value of gear type for an item
    */
    function gType(uint8 typeVal)
        public
        pure
        returns (uint8)
    {
        /*
        0  | common     | 0-127   | 1/2   | 128 | 50%    | 0%
        1  | uncommon 1 | 128-151 | 3/32  | 24  | 9.375% | 18.75%
        2  | uncommon 2 | 152-175 | 3/32  | 24  | 9.375% | 18.75%
        3  | uncommon 3 | 176-199 | 3/32  | 24  | 9.375% | 18.75%
        4  | uncommon 4 | 200-223 | 3/32  | 24  | 9.375% | 18.75%
        5  | rare 1     | 224-232 | 9/256 | 9   | 3.516% | 7.031%
        6  | rare 2     | 233-241 | 9/256 | 9   | 3.516% | 7.031%
        7  | rare 3     | 242-250 | 9/256 | 9   | 3.516% | 7.031%
        8  | epic 1     | 251-252 | 1/32  | 2   | 0.781% | 1.563%
        9  | epic 2     | 253-254 | 1/32  | 2   | 0.781% | 1.563%
        10 | legendary  | 255     | 1/256 | 1   | 0.391% | 0.781%
        */

        // Sorting from middle-out (reduce gas by probability)
        if(typeVal < 128){
            return 0;
        } else {
            if(typeVal < 224) {
                if(typeVal < 176){
                    return typeVal < 152 ? 1 : 2;
                } else {
                    return typeVal < 200 ? 3 : 4;
                }
            } else {
                if(typeVal < 251){
                    if(typeVal < 233){
                        return 5;
                    } else {
                        return typeVal < 242 ? 6 : 7;
                    }
                } else {
                    if(typeVal < 253){
                        return 8;
                    } else {
                        return typeVal < 255 ? 9 : 10;
                    }
                }
            }
        }
    }

    /**
    * @notice calculate a chamber type
    * @param hash the bytes32 hash value of a chamber
    * @return uint256 value of chamber type
    */
    function _cType(bytes32 hash)
        internal
        pure
        returns (uint256)
    {
        return (uint256(uint8(hash[4])) / 32);
    }

    /**
    * @notice calculate a chamber type and return as a string
    * @param hash the bytes32 hash value of a chamber
    * @return string of chamber type
    */
    function ctString(bytes32 hash)
        external
        pure
        returns (string memory)
    {
        return _cType(hash).toString();
    }

    /**
    * @notice calculate an encounter type  计算遭遇类型
    * @param hash the bytes32 hash value of a chamber
    * @return uint8 value of the encounter type
    */
    function _eType(bytes32 hash)
        internal
        pure
        returns (uint8)
    {
        uint256 typeVal = uint256(_hashToUint16(hash,14));

        /*

        #  | type       | value range | size | probability
        ---+------------+-------------+------+-------------------
        0  | slime      | 0-6143      | 6144 | 9.375%            粘液
        1  | crawler    | 6144-12287  | 6144 | 9.375%            爬行动物
        2  | poison bat | 12288-18431 | 6144 | 9.375%            毒蝙蝠
        3  | skeleton   | 18432-24575 | 6144 | 9.375%            骷髅
        4  | trap       | 24576-28475 | 3900 | 5.950927734375%   陷阱
        5  | curse      | 28476-32375 | 3900 | 5.950927734375%   诅咒
        6  | buff       | 32376-36275 | 3900 | 5.950927734375%   增益
        7  | debuff     | 36276-40175 | 3900 | 5.950927734375%   减益
        8  | gold       | 40176-44075 | 3900 | 5.950927734375%   黄金
        9  | thief      | 44076-47975 | 3900 | 5.950927734375%   贼
        10 | empty      | 47976-51875 | 3900 | 5.950927734375%   空的
        11 | rest       | 51876-55775 | 3900 | 5.950927734375%   休息
        12 | gear       | 55776-58780 | 3005 | 4.58526611328125% 装备
        13 | merchant   | 58781-61785 | 3005 | 4.58526611328125%  商人
        14 | treasure   | 61786-63600 | 1815 | 2.76947021484375%  宝藏
        15 | heal       | 63601-65415 | 1815 | 2.76947021484375%  治愈
        16 | revive     | 65416-65495 | 80   | 0.1220703125%      复活
        17 | armory     | 65496-65535 | 40   | 0.06103515625%     军械库
 
        */

        // Sorting from middle-out (reduce gas by probability)
        if(typeVal < 32376){
            if(typeVal < 18432){
                if(typeVal < 12288){
                    return typeVal < 6144 ? 0 : 1;
                } else {
                    return 2;
                }
            } else {
                if(typeVal < 24576){
                    return 3;
                } else {
                    return typeVal < 28476 ? 4 : 5;
                }
            }
        } else {
            if(typeVal < 47976){
                if(typeVal < 40176){
                    return typeVal < 36276 ? 6 : 7;
                } else {
                    return typeVal < 44076 ? 8 : 9;
                }
            } else {
                if(typeVal < 55776){
                    return typeVal < 51876 ? 10 : 11;
                } else {
                    if(typeVal < 61786){
                        return typeVal < 58781 ? 12 : 13;
                    } else {
                        if(typeVal < 63601){
                            return 14;
                        } else {
                            if(typeVal < 65416){
                                return 15;
                            } else {
                                return typeVal < 65496 ? 16 : 17;
                            }
                        }
                    }
                }
            }
        }

    }

    /**
    * @notice calculate an encounter type and return as a string
    * @param hash the bytes32 hash value of a chamber
    * @return string of the encounter type
    */
    function etString(bytes32 hash)
        external
        pure
        returns (string memory)
    {
        return _eType(hash).toString();
    }

    /**
    * @notice calculate an encounter outcome  计算遭遇结果
    * @param hash chamber hash
    * @param miner the current Miner instance
    * @return array representing the post-encounter miner struct
    */
    function chamberStats(bytes32 hash, Miner memory miner)
        external
        pure
        returns (Miner memory)
    {
        // Define chamberData  定义房间数据
        PackedVars memory chamberData;

        // Define encounter type for this chamber 定义这个房间的遭遇类型
        chamberData.var_uint8_1 = _eType(hash);

        // Pre-encounter calcuations 相遇前计算器

        // Check Miner's class  查看矿工职业
        if(miner.classId == 0){
            // Miner is a warrior! Restore 2 armor    矿工是战士！ 恢复2点护甲
            miner.armor = miner.armor + 2;
            // Check if armor is greater than baseArmor  检查盔甲是否大于baseArmor
            if(miner.armor > miner.baseArmor){
                // Set armor to baseArmor  将盔甲设置为 baseArmor
                miner.armor = miner.baseArmor;
            }
        } else if(miner.classId == 2){
            // Miner is a ranger! Restore 3 health and add 2 to baseHealth  矿工是游侠！ 恢复3点生命值并将2点添加到baseHealth
            // Restore health 恢复健康
            miner.health = miner.health + 3;
            // Check if health is greater than baseHealth  检查 health 是否大于 baseHealth
            if(miner.health > miner.baseHealth){
                // Set health to baseHealth  将健康设置为 baseHealth
                miner.health = miner.baseHealth;
            }
            // Add 2 to baseHealth  添加2个属性点到baseHealth
            miner.baseHealth = miner.baseHealth + 2;
        }

        // Check if Miner is cursed and make sure this isn't a curse chamber to avoid doing double damage  
        // 检查矿工是否被诅咒并确保这不是诅咒室以避免造成双重伤害
        if(miner.curseTurns > 0 && chamberData.var_uint8_1 != 5){
            // Miner is cursed!  矿工被诅咒了！
            // Calculate curse damage taken (10 percent of current health or 5 if Miner has less than 50 health)   
            // 计算受到的诅咒伤害（当前生命值的 10%，如果矿工的生命值低于 50，则为 5）
            chamberData.var_int16_1 = miner.health < 50 ? int16(5) : (miner.health / 10);
            // Set Miner health  设置矿工健康
            miner.health = miner.health - chamberData.var_int16_1;
            // Check if Miner is dead but has a revive   检查矿工是否死了但有复活
            if(miner.health < 1 && miner.revives > 0){
                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                // 如果当前护甲低于当前护甲，则以 1/4 生命值和 1/4 护甲复活
                miner.health = miner.baseHealth / 4;
                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                // Remove revive from inventory  从库存中移除复活
                miner.revives--;
            }
            // Remove curse turn  移除诅咒转身
            miner.curseTurns--;
        }

        // Encounter calculations

        // Check if Miner is still alive after potential curse damage has been calculated
        // 在计算出潜在的诅咒伤害后检查矿工是否还活着
        if(miner.health > 0){
            // Miner is alive! Loop through potential encounter types to calculate results
            // 矿工还活着！ 循环遍历潜在的遭遇类型以计算结果
            if(chamberData.var_uint8_1 < 4){ // MONSTER   怪物
                // Define monster  定义怪物
                Monster memory monster;
                // Check what kind of monster we've encountered and adjust stats
                // 检查我们遇到了什么样的怪物并调整统计数据
                if(chamberData.var_uint8_1 == 0){ // SLIME  粘液
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 70 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 15 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 35;
                    monster.mtype = chamberData.var_uint8_1;
                } else if(chamberData.var_uint8_1 == 1){ // CRAWLER  爬行动物
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 65 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 25 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 50;
                    monster.mtype = chamberData.var_uint8_1;
                } else if(chamberData.var_uint8_1 == 2){ // POISON BAT  毒蝙蝠
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 60 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 15 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 55;
                    monster.mtype = chamberData.var_uint8_1;
                } else { // SKELETON    骷髅
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 80 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 30 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 40;
                    monster.mtype = chamberData.var_uint8_1;
                }

                // Define turn counter  定义转弯计数器
                chamberData.var_uint8_2 = 0;

                // Loop through battle turns until someone dies  循环战斗回合直到有人死亡
                while(miner.health > 0 && monster.health > 0){
                    // Check variable monster turn speed vs. variable Miner turn speed 检查可变怪物转弯速度与可变矿工转弯速度
                    if((monster.speed + int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[7]) % 24))) > (miner.speed + int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[6]) % 24)))){
                        // Monster goes first  怪物先行

                        // Get random offset from monster's base attack for this turn 获得本回合怪物基础攻击的随机偏移
                        chamberData.var_int16_4 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[14]) % 8));
                        // Adjust monster's attack modifier to be a range of -4 to 4, no zero (positive numbers will be a buff, negative will be debuff)
                        // 调整怪物的攻击修正为-4到4的范围，不为零（正数为buff，负数为debuff）
                        chamberData.var_int16_4 = chamberData.var_int16_4 - (chamberData.var_int16_4 < 4 ? int16(4) : int16(3));

                        // Calculate total damage taken  计算受到的总伤害
                        chamberData.var_int16_2 = monster.attack + chamberData.var_int16_4;

                        // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                        // 低于总伤害的 1/3 来自护甲伤害的总伤害（这样做而不是 dmg / 3 * 2，因为整数地板四舍五入 - 有利于健康伤害而不是护甲）
                        // Value is 1/2 instead of 1/3 for Warriors  战士受到的伤害值值是 1/2 而不是 1/3
                        chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                        // Sub armor damage from armor 来自装甲的子装甲伤害
                        miner.armor = miner.armor - chamberData.var_int16_3;
                        // Sub health damage from health  健康造成的亚健康损害
                        miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                        // If armor has been broken, pass excess damage to health and set armor to zero
                        // 如果盔甲被破坏，将多余的伤害传递给健康并将盔甲设置为零
                        if(miner.armor < 0){
                            miner.health = miner.health + miner.armor;
                            miner.armor = 0;
                        }

                        // Check if Miner is dead  检查矿工是否死亡
                        if(miner.health < 1){
                            // Check if Miner has a revive  检查矿工是否有复活
                            if(miner.revives > 0){
                                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                                // 如果当前护甲低于当前护甲，则以 1/4 生命值和 1/4 护甲复活
                                miner.health = miner.baseHealth / 4;
                                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                                // Remove revive from inventory 从库存中移除复活
                                miner.revives--;
                            } else {
                                // He/she dead, bro  他/她死了，兄弟
                                break;
                            }
                        }

                        // Get random offset from Miner's base attack for this turn
                        // 本回合随机偏移矿工的基本攻击
                        chamberData.var_int16_1 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[13]) % 8));
                        // Adjust Miner's attack modifier to be a range of -4 to 4, no zero (negative numbers will be a buff, positive will be debuff)
                        // 调整矿工的攻击修正为-4到4的范围，不为零（负数为buff，正数为debuff）
                        chamberData.var_int16_1 = chamberData.var_int16_1 - (chamberData.var_int16_1 < 4 ? int16(4) : int16(3));

                        // Attack monster 攻击怪物
                        monster.health = monster.health - miner.attack - chamberData.var_int16_1 - (miner.buffTurns > 0 ? int16(4) : int16(0)) + (miner.debuffTurns > 0 ? int16(4) : int16(0));

                    } else {
                        // Miner goes first  矿工先行

                        // Get random offset from Miner's base attack for this turn 本回合随机偏移矿工的基本攻击
                        chamberData.var_int16_1 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[13]) % 8));
                        // Adjust Miner's attack modifier to be a range of -4 to 4, no zero (negative numbers will be a buff, positive will be debuff)
                        // 调整矿工的攻击修正为-4到4的范围，不为零（负数为buff，正数为debuff）
                        chamberData.var_int16_1 = chamberData.var_int16_1 - (chamberData.var_int16_1 < 4 ? int16(4) : int16(3));

                        // Attack monster 攻击怪物
                        monster.health = monster.health - miner.attack - chamberData.var_int16_1 - (miner.buffTurns > 0 ? int16(4) : int16(0)) + (miner.debuffTurns > 0 ? int16(4) : int16(0));

                        // Check if monster is dead  检查怪物是否死亡
                        if(monster.health < 1){
                            // It dead, bro   死了老哥
                            break;
                        } else {

                            // Get random offset from monster's base attack for this turn  获得本回合怪物基础攻击的随机偏移
                            chamberData.var_int16_4 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[14]) % 8));
                            // Adjust monster's attack modifier to be a range of -4 to 4, no zero (positive numbers will be a buff, negative will be debuff)
                            // 调整怪物的攻击修正为-4到4的范围，不为零（正数为buff，负数为debuff）
                            chamberData.var_int16_4 = chamberData.var_int16_4 - (chamberData.var_int16_4 < 4 ? int16(4) : int16(3));

                            // Calculate total damage taken  计算受到的总伤害
                            chamberData.var_int16_2 = monster.attack + chamberData.var_int16_4;

                            // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                            // 低于总伤害的 1/3 来自护甲伤害的总伤害（这样做而不是 dmg / 3 * 2，因为整数地板四舍五入 - 有利于健康伤害而不是护甲）
                            // Value is 1/2 instead of 1/3 for Warriors 战士受到的伤害值值是 1/2 而不是 1/3
                            chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                            // Sub armor damage from armor  减去装甲伤害
                            miner.armor = miner.armor - chamberData.var_int16_3;
                            // Sub health damage from health  减去血条
                            miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                            // If armor has been broken, pass excess damage to health and set armor to zero  如果盔甲被破坏，将多余的伤害传递给健康并将盔甲设置为零
                            if(miner.armor < 0){
                                miner.health = miner.health + miner.armor;
                                miner.armor = 0;
                            }

                            // Check if Miner is dead but has a revive 检查矿工是否死了但有复活
                            if(miner.health < 1 && miner.revives > 0){
                                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                                // 如果当前护甲低于当前护甲，则以 1/4 生命值和 1/4 护甲复活
                                miner.health = miner.baseHealth / 4;
                                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                                // Remove revive from inventory  从库存中移除复活
                                miner.revives--;
                            }
                        }
                    }
                    // Add one to loop/turn count  循环/转数加一
                    chamberData.var_uint8_2++;
                }
            } else if(chamberData.var_uint8_1 == 4){ // TRAP  陷阱
 
                // Calculate trap damage  计算陷阱伤害
                chamberData.var_int16_2 = int16(int8(uint8(hash[2]) % 16) + 32);

                // Check if Miner is an assassin 检查矿工是否是刺客
                if(miner.classId == 3){ 
                    // Miner is an assassin! Cut trap damage in half  矿工是刺客！ 将陷阱伤害减半
                    chamberData.var_int16_2 = (chamberData.var_int16_2 / 2);
                }

                // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                // 低于总伤害的 1/3 来自护甲伤害的总伤害（这样做而不是 dmg / 3 * 2，因为整数地板四舍五入 - 有利于健康伤害而不是护甲）
                // Value is 1/2 instead of 1/3 for Warriors  战士受到的伤害值值是 1/2 而不是 1/3
                chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                // Sub armor damage from armor  减去装甲伤害
                miner.armor = miner.armor - chamberData.var_int16_3;
                // Sub health damage from health  减去血条伤害
                miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                // If armor has been broken, pass excess damage to health and set armor to zero
                // 如果盔甲被破坏，将多余的伤害传递给健康并将盔甲设置为零
                if(miner.armor < 0){
                    miner.health = miner.health + miner.armor;
                    miner.armor = 0;
                }

                // Check if Miner is dead but has a revive  检查矿工是否死了但有复活
                if(miner.health < 1 && miner.revives > 0){
                    // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                    // 如果当前护甲低于当前护甲，则以 1/4 生命值和 1/4 护甲复活
                    miner.health = miner.baseHealth / 4;
                    miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                    // Remove revive from inventory  从库存中移除复活
                    miner.revives--;
                }
            } else if(chamberData.var_uint8_1 == 5){ // CURSE

                // Check if the Miner IS NOT a mage 检查矿工是否不是法师
                if(miner.classId != 1){
                    // Miner is not a mage! Curse this mf  矿工不是法师！ 诅咒这个mf
                    // Calculate curse damage taken (10 percent of current health or 5 if Miner has less than 50 health)
                    // 计算受到的诅咒伤害（当前生命值的 10%，如果矿工的生命值低于 50，则为 5）
                    chamberData.var_int16_1 = miner.health < 50 ? int16(5) : (miner.health / 10);

                    // Sub curse damage from health   减去诅咒伤害
                    miner.health = miner.health - chamberData.var_int16_1;

                    // Check if Miner is dead but has a revive  检查矿工是否死了但有复活
                    if(miner.health < 1 && miner.revives > 0){
                        // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                        // 如果当前护甲低于当前护甲，则以 1/4 生命值和 1/4 护甲复活
                        miner.health = miner.baseHealth / 4;
                        miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                        // Remove revive from inventory 从库存中移除复活
                        miner.revives--;
                    }

                    // Add curse for 4 more chambers  为另外 4 个房间添加诅咒
                    miner.curseTurns = 4;
                }

            } else if(chamberData.var_uint8_1 == 6){ // BUFF 增益
                // Add buff for 3 chambers (adding one extra because it will be removed at the end of loop)
                // 为 3 个房间添加 buff（添加一个额外的，因为它将在循环结束时移除）
                miner.buffTurns = miner.buffTurns + 4;
            } else if(chamberData.var_uint8_1 == 7){ // DEBUFF  减益
                // Add debuff for 3 chambers (adding one extra because it will be removed at the end of loop)
                // 为 3 个房间添加 debuff（添加一个额外的，因为它将在循环结束时移除）
                miner.debuffTurns = miner.debuffTurns + 4;
            } else if(chamberData.var_uint8_1 == 8){ // GOLD  黄金
                // Add gold to inventory  将黄金添加到库存中
                miner.gold = miner.gold + uint16(uint8(hash[8]) % 24) + 2;

            } else if(chamberData.var_uint8_1 == 9){ // THIEF  贼
                // Check if the Miner is an assassin 检查矿工是否是刺客
                if(miner.classId == 3){
                    // Miner is an assassin! Give a low-tier item (uncommon or rare) 矿工是刺客！ 赠送低等级物品（不常见或稀有）

                    // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)  
                    // 装备类型（0 == 头饰，1 == 盔甲，2 == 裤子，3 == 鞋类，4 == 武器）
                    chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                    // Gear rarity  装备稀有度
                    // Add 128 to modulo 123 to get item from uncommon or rare rarity tiers  将 128 添加到模 123 以从不常见或稀有稀有等级中获取物品
                    chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) % 123) + 128);

                    // Gear ID  装备ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? chamberData.var_uint8_3 : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 8) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats  为 gearItem 统计数据定义数组
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately  检查哪种装备类型并适当添加值
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats  获取头饰统计信息
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats  获取装甲数据
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats  获取裤子统计信息
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear 
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats  获取鞋类统计信息
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats   获取武器统计信息
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth  为 baseHealth 添加装备健康增益
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear health buff to health  将装备健康增益添加到健康
                    miner.health = miner.health + gearItem[0];
                    // Add gear armor buff to baseArmor  为 baseArmor 添加装备装甲增益
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear armor buff to armor  将装备盔甲buff添加到盔甲
                    miner.armor = miner.armor + gearItem[1];
                    // Add gear attack buff to attack  将装备攻击buff添加到攻击
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed  将装备速度buff添加到速度
                    miner.speed = miner.speed + gearItem[3];

                } else {
                    // Miner IS NOT an assassin, let's steal some gold  矿工不是刺客，让我们偷点金子吧
                    // uint16 goldStolen
                    chamberData.var_uint16_1 = uint16(uint8(hash[8]) % 16) + 1;

                    // Remove stolen gold from Miner  从矿工的库存中删除被盗的黄金
                    miner.gold = miner.gold > chamberData.var_uint16_1 ? (miner.gold - chamberData.var_uint16_1) : 0;
                }
            // } else if(chamberData.var_uint8_1 == 10){ // EMPTY  空的
                // Nothing happens here   无事发生
            } else if(chamberData.var_uint8_1 == 11){ // REST  休息
                // Restore health  恢复健康
                miner.health = miner.health + int16(int8(uint8(hash[9]) % 24)) + 7;

                // Check if health is greater than baseHealth 检查 health 是否大于 baseHealth
                if(miner.health > miner.baseHealth){
                    // Miner is way too healthy, set health to baseHealth 矿工太健康了，将健康设置为 baseHealth
                    miner.health = miner.baseHealth;
                }
  
            } else if(chamberData.var_uint8_1 == 12){ // GEAR  装备
                // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)  装备类型（0 == 头饰，1 == 盔甲，2 == 裤子，3 == 鞋类，4 == 武器）
                chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                // 装备稀有度
                // If less than 128, add 128 to the hash val (rarity tiers start at uncommon and double chance for each tier)
                // 如果小于 128，则将 128 添加到哈希值（稀有层从不常见开始，每层有双倍机会）
                chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) < 128 ? uint8(hash[16 + chamberData.var_uint8_2]) + 128 : uint8(hash[16 + chamberData.var_uint8_2])));

                // Gear ID  装备ID
                chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                // Define array for gearItem stats  为 gearItem 统计数据定义数组
                int16[6] memory gearItem;

                // Check which gear type and add values appropriately  检查哪种装备类型并适当添加值
                if(chamberData.var_uint8_2 == 0){
                    // Get headgear stats 获取头饰统计信息
                    gearItem = headgearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear  
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.headgearId){
                        miner.headgearId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 1){
                    // Get armor stats 获取装甲数据
                    gearItem = armorStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.armorId){
                        miner.armorId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 2){
                    // Get pants stats  获取裤子统计信息
                    gearItem = pantsStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.pantsId){
                        miner.pantsId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 3){
                    // Get footwear stats  获取鞋类统计信息
                    gearItem = footwearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.footwearId){
                        miner.footwearId = chamberData.var_uint8_4;
                    }
                } else {
                    // Get weapon stats 获取武器数据
                    gearItem = weaponStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.weaponId){
                        miner.weaponId = chamberData.var_uint8_4;
                    }
                }
                // Add gear health buff to baseHealth  为 baseHealth 添加装备健康增益
                miner.baseHealth = miner.baseHealth + gearItem[0];
                // Add gear health buff to health 将装备健康增益添加到健康
                miner.health = miner.health + gearItem[0]; 
                // Add gear armor buff to baseArmor   为 baseArmor 添加装备装甲增益
                miner.baseArmor = miner.baseArmor + gearItem[1];
                // Add gear armor buff to armor  为盔甲添加装备盔甲buff
                miner.armor = miner.armor + gearItem[1];
                // Add gear attack buff to attack  添加装备攻击buff进行攻击
                miner.attack = miner.attack + gearItem[2];
                // Add gear speed buff to speed  将装备速度buff添加到速度
                miner.speed = miner.speed + gearItem[3];

            } else if(chamberData.var_uint8_1 == 13){ // MERCHANT

                // Check if Miner has enough gold for item (min 25) 检查矿工是否有足够的金币购买物品（最少 25 分钟）
                if(miner.gold > 24){
                    // Miner can afford to purchase some gear, assign gear type  矿工有能力购买一些装备，指定装备类型
                    // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon) 装备类型（0 == 头饰，1 == 盔甲，2 == 裤子，3 == 鞋类，4 == 武器）
                    chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                    // Check what the Miner can afford  检查矿工能负担得起的
                    if(miner.gold < 50){ 
                        // Buy uncommon item  购买稀有物品

                        // Gear rarity - assign 1-4 for uncommon   装备稀有度 - 为不常见分配 1-4
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 4) + 1;
                        // Pay the merchant  向商家付款
                        miner.gold = miner.gold - 25;
                    } else if (miner.gold < 75){
                        // Buy rare item  购买稀有物品

                        // Gear rarity - assign 5-7 for rare 装备稀有度 - 为稀有分配 5-7
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 3) + 5;
                        // Pay the merchant  向商家付款
                        miner.gold = miner.gold - 50;
                    }
                    else if (miner.gold < 100){
                        // Buy epic item  购买史诗物品

                        // Gear rarity - assign 8-9 for epic   装备稀有度 - 为史诗分配 8-9
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 2) + 8;
                        // Pay the merchant   向商家付款
                        miner.gold = miner.gold - 75;
                    } else {
                        // Buy legendary item   购买传奇物品

                        // Gear rarity - assign 10 for legendary 装备稀有度 - 为传奇分配 10
                        chamberData.var_uint8_3 = 10;
                        // Pay the merchant   向商家付款
                        miner.gold = miner.gold - 100;
                    }

                    // Determine Gear ID  确定装备ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats  为 gearItem 统计数据定义数组
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately  检查哪种装备类型并适当添加值
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats  获取头饰统计信息
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats  获取装甲数据
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats  获取裤子统计信息
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats  获取鞋类统计信息
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats 获取武器数据
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth 为 baseHealth 添加装备健康增益
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear health buff to health  将装备健康增益添加到健康
                    miner.health = miner.health + gearItem[0];
                    // Add gear armor buff to baseArmor  为 baseArmor 添加装备装甲增益
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear armor buff to armor  为盔甲添加装备盔甲buff
                    miner.armor = miner.armor + gearItem[1];
                    // Add gear attack buff to attack 添加装备攻击buff进行攻击
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed  将装备速度buff添加到速度
                    miner.speed = miner.speed + gearItem[3];
                }

            } else if(chamberData.var_uint8_1 == 14){ // TREASURE  宝藏

                // Add found gold to gold   将发现的黄金添加到黄金中
                miner.gold = miner.gold + uint16(uint8(hash[8]) % 48) + 28;

                // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon) 
                // 装备类型（0 == 头饰，1 == 盔甲，2 == 裤子，3 == 鞋类，4 == 武器）
                chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                // Gear rarity  装备稀有度
                // Modulo of 32, add 224 to the hash val to get a value between 224-255 (rarity tiers start at rare)
                // 以 32 为模，将 224 添加到哈希 val 以获得 224-255 之间的值（稀有层从稀有开始）
                chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) % 32) + 224);

                // Determine Gear ID  确定装备ID
                chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId)) + (17 * chamberData.var_uint8_2);

                // Define array for gearItem stats 为 gearItem 统计数据定义数组
                int16[6] memory gearItem;

                // Check which gear type and add values appropriately  检查哪种装备类型并适当添加值
                if(chamberData.var_uint8_2 == 0){
                    // Get headgear stats 获取头饰统计信息
                    gearItem = headgearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.headgearId){
                        miner.headgearId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 1){
                    // Get armor stats  获取装甲数据
                    gearItem = armorStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.armorId){
                        miner.armorId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 2){
                    // Get pants stats  获取裤子统计信息
                    gearItem = pantsStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.pantsId){
                        miner.pantsId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 3){
                    // Get footwear stats 获取鞋类统计信息
                    gearItem = footwearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.footwearId){
                        miner.footwearId = chamberData.var_uint8_4;
                    }
                } else {
                    // Get weapon stats   获取武器数据
                    gearItem = weaponStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                    if(chamberData.var_uint8_4 > miner.weaponId){
                        miner.weaponId = chamberData.var_uint8_4;
                    }
                }
                // Add gear health buff to baseHealth  为 baseHealth 添加装备健康增益
                miner.baseHealth = miner.baseHealth + gearItem[0];
                // Add gear health buff to health 将装备健康增益添加到健康
                miner.health = miner.health + gearItem[0];
                // Add gear armor buff to baseArmor  为 baseArmor 添加装备装甲增益
                miner.baseArmor = miner.baseArmor + gearItem[1];
                // Add gear armor buff to armor  为盔甲添加装备盔甲buff
                miner.armor = miner.armor + gearItem[1];
                // Add gear attack buff to attack  添加装备攻击buff进行攻击
                miner.attack = miner.attack + gearItem[2];
                // Add gear speed buff to speed   将装备速度buff添加到速度
                miner.speed = miner.speed + gearItem[3];
            } else if(chamberData.var_uint8_1 == 15){ // HEAL  治愈

                // Restore health by 1/2 baseHealth   恢复 1/2 基础生命值
                miner.health = miner.health + (miner.baseHealth / 2);
                // Check if health is greater than baseHealth 检查 health 是否大于 baseHealth
                if(miner.health > miner.baseHealth){
                    // Miner is way too healthy, set health to baseHealth  矿工太健康了，将健康设置为 baseHealth
                    miner.health = miner.baseHealth;
                }

                // Restore armor by 1/2 baseArmor  回复 1/2 baseArmor 护甲
                miner.armor = miner.armor + (miner.baseArmor / 2);

                // Check if armor is greater than baseArmor  检查盔甲是否大于 baseArmor
                if(miner.armor > miner.baseArmor){
                    // Miner is way too tanky, set armor to baseArmor  矿工太坦克了，将装甲设置为 baseArmor
                    miner.armor = miner.baseArmor;
                }
            } else if(chamberData.var_uint8_1 == 16){ // REVIVE  复活
                // Add revive to inventory  将复活添加到库存
                miner.revives++;

            } else if(chamberData.var_uint8_1 == 17){ // ARMORY  军械库
                // Oh baby, this Miner is about to get BROLIC  哦宝贝，这个矿工即将获得 BROLIC

                // Loop through gear types to add all to gear stats   循环遍历装备类型以添加所有装备统计信息
                for(chamberData.var_uint8_2 = 0; chamberData.var_uint8_2 < 5; chamberData.var_uint8_2++){

                    // Gear rarity   装备稀有度
                    // 3/4 chance of epic, 1/4 chance of legendary  3/4几率史诗，1/4几率传奇
                    chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 4) < 3 ? 9 : 10;

                    // Determine Gear ID  确定装备ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats  为 gearItem 统计数据定义数组
                    int16[6] memory gearItem; 

                    // Check which gear type and add values appropriately  检查哪种装备类型并适当添加值
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats  获取头饰统计信息
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear  
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats   获取装甲数据
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats   获取裤子统计信息
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats  获取鞋类统计信息
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats 获取武器数据
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        // 如果 gearId 高于 Miner 当前的 gearId，重新分配可见的 gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth  为 baseHealth 添加装备健康增益
                    miner.baseHealth = miner.baseHealth + gearItem[0]; 
                    // Add gear armor buff to baseArmor  为 baseArmor 添加装备装甲增益
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear attack buff to attack   添加装备攻击buff进行攻击
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed  将装备速度buff添加到速度
                    miner.speed = miner.speed + gearItem[3];
                }
                // Set current Miner health to base health   将当前矿工健康设置为基础健康
                miner.health = miner.baseHealth;
                // Set current Miner armor to base armor     将当前矿工护甲设置为基础护甲
                miner.armor = miner.baseArmor;
            }
        }

        // Post-encounter calculations  事后计算

        // If the Miner has at least one buff turn remaining, remove a buff turn
        // 如果矿工还有至少一个 buff 回合，移除一个 buff 回合
        if(miner.buffTurns > 0){
            miner.buffTurns--;
        }
        // If the Miner has at least one debuff turn remaining, remove a debuff turn
        // 如果矿工至少还有一个 debuff 回合，移除一个 debuff 回合
        if(miner.debuffTurns > 0){
            miner.debuffTurns--;
        }
        // Return the Miner  返回矿工信息
        return miner;
    }
}