//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IERC1155Burnable.sol";
import "./PokemonStorage.sol";

/**
 * @title Family contract.
 * NOTE: Contract allows users to mint standard ERC 721 tokens of type MAN or WOMAN,
 * after that, the user can create a KID token, when the KID token reaches maturity,
 * they become adults MAN or WOMAN.
 * @dev According to this contract one day equals one year, so each day each
 * contract will be a year older.
 */
contract Pokemons is PokemonStorage {
    uint256 private _mintFee;
    uint256 private _upgradeLevelFee;
    IERC20Burnable private _level;
    IERC1155Burnable private _stones;

    /**
     * @dev Emitted when the owner withdraw ether from the contract.
     * @param owner owner address.
     * @param amount amount of ether.
     */
    event WithdrawalOfOwner(address owner, uint256 indexed amount);

    /**
     * @dev Emitted when new token minted.
     * @param tokenId token Id.
     * @param mintTime block.timestamp of mint.
     * @param owner address of the owner of the tokens.
     */
    event NewPokemon(uint256 tokenId, uint256 mintTime, address owner);

    /**
     * @dev Emitted when checkAgeChanging called.
     * @param tokenId token Id.
     * @param newTokenId GENDER type(MAN, WOMEN, KID_BOY or KID_GIRL).
     * @param stoneId GENDER type(MAN, WOMEN, KID_BOY or KID_GIRL).
     * @param upgradeTime given name of human.
     * @param owner address of the owner of the tokens.
     */
    event UpgradedWithStone(
        uint256 tokenId,
        uint256 newTokenId,
        uint256 stoneId,
        uint256 upgradeTime,
        address indexed owner
    );

    /**
     * @dev Emitted when checkAgeChanging called.
     * @param tokenId token Id.
     * @param newTokenId GENDER type(MAN, WOMEN, KID_BOY or KID_GIRL).
     * @param upgradeTime given name of human.
     * @param owner address of the owner of the tokens.
     */
    event UpgradedWithLevel(uint256 tokenId, uint256 newTokenId, uint256 upgradeTime, address indexed owner);

    constructor(
        uint256 mintFee_,
        uint256 upgradeLevelFee_,
        address level_,
        address stones_
    ) {
        require(mintFee_ > 0, "Mint Fee cannot be 0");
        require(upgradeLevelFee_ > 0, "Upgrade Level Fee cannot be 0");
        require(level_ != address(0), "Wrong erc-20 level address");
        require(stones_ != address(0), "Wrong erc-1155 stones_ address");
        _mintFee = mintFee_;
        _upgradeLevelFee = upgradeLevelFee_;
        _level = IERC20Burnable(level_);
        _stones = IERC1155Burnable(stones_);
    }

    function mintRandomPokemon() public payable {
        require(msg.value >= _mintFee, "Mint fee required");
        uint256 pseudoRandom = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) %
            995) + 1;
        _mint(msg.sender, pseudoRandom, 1, "");
        emit NewPokemon(pseudoRandom, block.timestamp, msg.sender);
    }

    function upgradePokemon(uint256 pokemonNumber) external {
        require(balanceOf(msg.sender, pokemonNumber) > 0, "Caller not the owner");
        (uint256 whichMethodOfUpgrade, uint256 newPokemonId) = checkAvailableUpgrade(pokemonNumber);
        if (whichMethodOfUpgrade < 14) {
            upgradeWithStone(pokemonNumber, newPokemonId, whichMethodOfUpgrade);
        } else if (whichMethodOfUpgrade == 14) {
            upgradeWithLevel(pokemonNumber);
        } else revert("Token cannot be updated");
    }

    function upgradeWithStone(
        uint256 pokemonNumber,
        uint256 newPokemonId,
        uint256 whichStoneToUse
    ) private {
        require(_stones.balanceOf(msg.sender, whichStoneToUse) > 0, "Stone required");
        _stones.burn(msg.sender, whichStoneToUse, 1);
        _mint(msg.sender, newPokemonId, 1, "");
        emit UpgradedWithStone(pokemonNumber, newPokemonId, whichStoneToUse, block.timestamp, msg.sender);
    }

    function upgradeWithLevel(uint256 pokemonNumber) private {
        require(_level.balanceOf(msg.sender) >= _upgradeLevelFee, "Level tokens required");
        _level.burn(_upgradeLevelFee);
        uint256 newPokemonId = pokemonNumber + 1;
        _mint(msg.sender, newPokemonId, 1, "");
        emit UpgradedWithLevel(pokemonNumber, newPokemonId, block.timestamp, msg.sender);
    }

    function checkAvailableUpgrade(uint256 pokemonNumber) private view returns (uint256, uint256) {
        if (true == isUpgradeNotAvailable(pokemonNumber)) {
            return (15, 0);
        } else if (isThunderUpgradeAvailable(pokemonNumber) != 0) {
            return (0, isThunderUpgradeAvailable(pokemonNumber));
        } else if (isMoonUpgradeAvailable(pokemonNumber) != 0) {
            return (1, isMoonUpgradeAvailable(pokemonNumber));
        } else if (isFireUpgradeAvailable(pokemonNumber) != 0) {
            return (2, isFireUpgradeAvailable(pokemonNumber));
        } else if (isLeafUpgradeAvailable(pokemonNumber) != 0) {
            return (3, isLeafUpgradeAvailable(pokemonNumber));
        } else if (isSunUpgradeAvailable(pokemonNumber) != 0) {
            return (4, isSunUpgradeAvailable(pokemonNumber));
        } else if (isWaterUpgradeAvailable(pokemonNumber) != 0) {
            return (5, isWaterUpgradeAvailable(pokemonNumber));
        } else if (isBlackAuguriteUpgradeAvailable(pokemonNumber) != 0) {
            return (6, isBlackAuguriteUpgradeAvailable(pokemonNumber));
        } else if (isShinyUpgradeAvailable(pokemonNumber) != 0) {
            return (7, isShinyUpgradeAvailable(pokemonNumber));
        } else if (isDuskUpgradeAvailable(pokemonNumber) != 0) {
            return (8, isDuskUpgradeAvailable(pokemonNumber));
        } else if (isRazorClawUpgradeAvailable(pokemonNumber) != 0) {
            return (9, isRazorClawUpgradeAvailable(pokemonNumber));
        } else if (isPeatBlockUpgradeAvailable(pokemonNumber) != 0) {
            return (10, isPeatBlockUpgradeAvailable(pokemonNumber));
        } else if (isTartAppleUpgradeAvailable(pokemonNumber) != 0) {
            return (11, isTartAppleUpgradeAvailable(pokemonNumber));
        } else if (isCrackedPotUpgradeAvailable(pokemonNumber) != 0) {
            return (12, isCrackedPotUpgradeAvailable(pokemonNumber));
        } else if (isOvalUpgradeAvailable(pokemonNumber) != 0) {
            return (13, isOvalUpgradeAvailable(pokemonNumber));
        } else return (14, 16);
    }

    /**
     * @dev Owner can withdraw Ether from contract.
     *
     * Emits a {WithdrawalOfOwner} event.
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH");
        payable(owner()).transfer(amount);
        emit WithdrawalOfOwner(msg.sender, amount);
    }

    /**
     * @dev Returns the Pokemon mint fee.
     */
    function getMintFee() external view returns (uint256) {
        return _mintFee;
    }

    /**
     * @dev Returns the upgrade fee in level tokens.
     */
    function getUpgradeLevelFee() external view returns (uint256) {
        return _upgradeLevelFee;
    }

    /**
     * @dev Returns address of the Level contract.
     */
    function getLevelAddress() external view returns (IERC20Burnable) {
        return _level;
    }

    /**
     * @dev Returns address of the Stones contract.
     */
    function getStonesAddress() external view returns (IERC1155Burnable) {
        return _stones;
    }

    receive() external payable {
        mintRandomPokemon();
    }

    fallback() external payable {
        mintRandomPokemon();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Burnable is IERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract PokemonStorage is ERC1155, Ownable {
    mapping(uint256 => bool) private _latestInEvolution;
    mapping(uint256 => uint256) private _thunderUpgrades;
    mapping(uint256 => uint256) private _moonUpgrades;
    mapping(uint256 => uint256) private _fireUpgrades;
    mapping(uint256 => uint256) private _leafUpgrades;
    mapping(uint256 => uint256) private _sunUpgrades;
    mapping(uint256 => uint256) private _waterUpgrades;
    mapping(uint256 => uint256) private _blackAuguriteUpgrades;
    mapping(uint256 => uint256) private _shinyUpgrades;
    mapping(uint256 => uint256) private _duskUpgrades;
    mapping(uint256 => uint256) private _razorClawUpgrades;
    mapping(uint256 => uint256) private _peatBlockUpgrades;
    mapping(uint256 => uint256) private _tartAppleUpgrades;
    mapping(uint256 => uint256) private _crackedPotUpgrades;
    mapping(uint256 => uint256) private _ovalUpgrades;

    function isUpgradeNotAvailable(uint256 pokemonNumber) public view returns (bool) {
        return _latestInEvolution[pokemonNumber];
    }

    function isThunderUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _thunderUpgrades[pokemonNumber];
    }

    function isMoonUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _moonUpgrades[pokemonNumber];
    }

    function isFireUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _fireUpgrades[pokemonNumber];
    }

    function isLeafUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _leafUpgrades[pokemonNumber];
    }

    function isSunUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _sunUpgrades[pokemonNumber];
    }

    function isWaterUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _waterUpgrades[pokemonNumber];
    }

    function isBlackAuguriteUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _blackAuguriteUpgrades[pokemonNumber];
    }

    function isShinyUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _shinyUpgrades[pokemonNumber];
    }

    function isDuskUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _duskUpgrades[pokemonNumber];
    }

    function isRazorClawUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _razorClawUpgrades[pokemonNumber];
    }

    function isPeatBlockUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _peatBlockUpgrades[pokemonNumber];
    }

    function isTartAppleUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _tartAppleUpgrades[pokemonNumber];
    }

    function isCrackedPotUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _crackedPotUpgrades[pokemonNumber];
    }

    function isOvalUpgradeAvailable(uint256 pokemonNumber) public view returns (uint256) {
        return _ovalUpgrades[pokemonNumber];
    }

    constructor() ERC1155("ipfs://bafybeibu47fwlxtdoba4ajk7qboplpiyn2xipln7dguucslxazu7itwvjm/") {
        _latestInEvolution[3] = true;
        _latestInEvolution[6] = true;
        _latestInEvolution[9] = true;
        _latestInEvolution[12] = true;
        _latestInEvolution[15] = true;
        _latestInEvolution[18] = true;
        _latestInEvolution[20] = true;
        _latestInEvolution[22] = true;
        _latestInEvolution[24] = true;
        _latestInEvolution[26] = true;
        _latestInEvolution[28] = true;
        _latestInEvolution[31] = true;
        _latestInEvolution[34] = true;
        _latestInEvolution[36] = true;
        _latestInEvolution[38] = true;
        _latestInEvolution[40] = true;
        _latestInEvolution[42] = true;
        _latestInEvolution[45] = true;
        _latestInEvolution[47] = true;
        _latestInEvolution[49] = true;
        _latestInEvolution[51] = true;
        _latestInEvolution[53] = true;
        _latestInEvolution[55] = true;
        _latestInEvolution[57] = true;
        _latestInEvolution[59] = true;
        _latestInEvolution[62] = true;
        _latestInEvolution[65] = true;
        _latestInEvolution[68] = true;
        _latestInEvolution[71] = true;
        _latestInEvolution[73] = true;
        _latestInEvolution[76] = true;
        _latestInEvolution[78] = true;
        _latestInEvolution[80] = true;
        _latestInEvolution[82] = true;
        _latestInEvolution[83] = true;
        _latestInEvolution[85] = true;
        _latestInEvolution[87] = true;
        _latestInEvolution[89] = true;
        _latestInEvolution[91] = true;
        _latestInEvolution[94] = true;
        _latestInEvolution[95] = true;
        _latestInEvolution[97] = true;
        _latestInEvolution[99] = true;

        _latestInEvolution[101] = true;
        _latestInEvolution[103] = true;
        _latestInEvolution[105] = true;
        _latestInEvolution[106] = true;
        _latestInEvolution[107] = true;
        _latestInEvolution[101] = true;
        _latestInEvolution[103] = true;
        _latestInEvolution[105] = true;
        _latestInEvolution[106] = true;
        _latestInEvolution[107] = true;
        _latestInEvolution[108] = true;
        _latestInEvolution[110] = true;
        _latestInEvolution[112] = true;
        _latestInEvolution[113] = true;
        _latestInEvolution[114] = true;
        _latestInEvolution[117] = true;
        _latestInEvolution[119] = true;
        _latestInEvolution[121] = true;
        _latestInEvolution[122] = true;
        _latestInEvolution[124] = true;
        _latestInEvolution[125] = true;
        _latestInEvolution[126] = true;
        _latestInEvolution[127] = true;
        _latestInEvolution[128] = true;
        _latestInEvolution[130] = true;
        _latestInEvolution[131] = true;
        _latestInEvolution[132] = true;
        _latestInEvolution[134] = true;
        _latestInEvolution[135] = true;
        _latestInEvolution[136] = true;
        _latestInEvolution[137] = true;
        _latestInEvolution[139] = true;
        _latestInEvolution[141] = true;
        _latestInEvolution[142] = true;
        _latestInEvolution[143] = true;
        _latestInEvolution[145] = true;
        _latestInEvolution[146] = true;
        _latestInEvolution[149] = true;
        _latestInEvolution[150] = true;
        _latestInEvolution[151] = true;
        _latestInEvolution[154] = true;
        _latestInEvolution[157] = true;
        _latestInEvolution[160] = true;
        _latestInEvolution[162] = true;
        _latestInEvolution[164] = true;
        _latestInEvolution[166] = true;
        _latestInEvolution[168] = true;
        _latestInEvolution[169] = true;
        _latestInEvolution[171] = true;
        _latestInEvolution[172] = true;
        _latestInEvolution[173] = true;
        _latestInEvolution[174] = true;
        _latestInEvolution[178] = true;
        _latestInEvolution[181] = true;
        _latestInEvolution[182] = true;
        _latestInEvolution[184] = true;
        _latestInEvolution[185] = true;
        _latestInEvolution[186] = true;
        _latestInEvolution[189] = true;
        _latestInEvolution[190] = true;
        _latestInEvolution[192] = true;
        _latestInEvolution[193] = true;
        _latestInEvolution[195] = true;
        _latestInEvolution[196] = true;
        _latestInEvolution[197] = true;
        _latestInEvolution[199] = true;

        _latestInEvolution[201] = true;
        _latestInEvolution[202] = true;
        _latestInEvolution[203] = true;
        _latestInEvolution[205] = true;
        _latestInEvolution[206] = true;
        _latestInEvolution[207] = true;
        _latestInEvolution[208] = true;
        _latestInEvolution[210] = true;
        _latestInEvolution[211] = true;
        _latestInEvolution[212] = true;
        _latestInEvolution[213] = true;
        _latestInEvolution[214] = true;
        _latestInEvolution[219] = true;
        _latestInEvolution[221] = true;
        _latestInEvolution[222] = true;
        _latestInEvolution[224] = true;
        _latestInEvolution[225] = true;
        _latestInEvolution[226] = true;
        _latestInEvolution[227] = true;
        _latestInEvolution[229] = true;
        _latestInEvolution[230] = true;
        _latestInEvolution[232] = true;
        _latestInEvolution[233] = true;
        _latestInEvolution[234] = true;
        _latestInEvolution[235] = true;
        _latestInEvolution[236] = true;
        _latestInEvolution[237] = true;
        _latestInEvolution[238] = true;
        _latestInEvolution[239] = true;
        _latestInEvolution[240] = true;
        _latestInEvolution[241] = true;
        _latestInEvolution[242] = true;
        _latestInEvolution[243] = true;
        _latestInEvolution[244] = true;
        _latestInEvolution[245] = true;
        _latestInEvolution[248] = true;
        _latestInEvolution[249] = true;
        _latestInEvolution[250] = true;
        _latestInEvolution[251] = true;
        _latestInEvolution[254] = true;
        _latestInEvolution[257] = true;
        _latestInEvolution[260] = true;
        _latestInEvolution[262] = true;
        _latestInEvolution[264] = true;
        _latestInEvolution[269] = true;
        _latestInEvolution[272] = true;
        _latestInEvolution[275] = true;
        _latestInEvolution[277] = true;
        _latestInEvolution[279] = true;
        _latestInEvolution[282] = true;
        _latestInEvolution[284] = true;
        _latestInEvolution[286] = true;
        _latestInEvolution[289] = true;
        _latestInEvolution[292] = true;
        _latestInEvolution[295] = true;
        _latestInEvolution[297] = true;
        _latestInEvolution[298] = true;
        _latestInEvolution[299] = true;

        _latestInEvolution[301] = true;
        _latestInEvolution[302] = true;
        _latestInEvolution[303] = true;
        _latestInEvolution[306] = true;
        _latestInEvolution[308] = true;
        _latestInEvolution[310] = true;
        _latestInEvolution[311] = true;
        _latestInEvolution[312] = true;
        _latestInEvolution[313] = true;
        _latestInEvolution[314] = true;
        _latestInEvolution[317] = true;
        _latestInEvolution[319] = true;
        _latestInEvolution[321] = true;
        _latestInEvolution[323] = true;
        _latestInEvolution[324] = true;
        _latestInEvolution[326] = true;
        _latestInEvolution[327] = true;
        _latestInEvolution[330] = true;
        _latestInEvolution[332] = true;
        _latestInEvolution[334] = true;
        _latestInEvolution[335] = true;
        _latestInEvolution[336] = true;
        _latestInEvolution[337] = true;
        _latestInEvolution[338] = true;
        _latestInEvolution[340] = true;
        _latestInEvolution[342] = true;
        _latestInEvolution[344] = true;
        _latestInEvolution[346] = true;
        _latestInEvolution[348] = true;
        _latestInEvolution[350] = true;
        _latestInEvolution[351] = true;
        _latestInEvolution[352] = true;
        _latestInEvolution[354] = true;
        _latestInEvolution[356] = true;
        _latestInEvolution[357] = true;
        _latestInEvolution[358] = true;
        _latestInEvolution[359] = true;
        _latestInEvolution[360] = true;
        _latestInEvolution[362] = true;
        _latestInEvolution[365] = true;
        _latestInEvolution[368] = true;
        _latestInEvolution[369] = true;
        _latestInEvolution[370] = true;
        _latestInEvolution[373] = true;
        _latestInEvolution[376] = true;
        _latestInEvolution[377] = true;
        _latestInEvolution[378] = true;
        _latestInEvolution[379] = true;
        _latestInEvolution[380] = true;
        _latestInEvolution[381] = true;
        _latestInEvolution[382] = true;
        _latestInEvolution[383] = true;
        _latestInEvolution[384] = true;
        _latestInEvolution[385] = true;
        _latestInEvolution[386] = true;
        _latestInEvolution[389] = true;
        _latestInEvolution[392] = true;
        _latestInEvolution[395] = true;
        _latestInEvolution[398] = true;

        _latestInEvolution[400] = true;
        _latestInEvolution[402] = true;
        _latestInEvolution[407] = true;
        _latestInEvolution[405] = true;
        _latestInEvolution[409] = true;
        _latestInEvolution[411] = true;
        _latestInEvolution[414] = true;
        _latestInEvolution[416] = true;
        _latestInEvolution[419] = true;
        _latestInEvolution[421] = true;
        _latestInEvolution[423] = true;
        _latestInEvolution[424] = true;
        _latestInEvolution[426] = true;
        _latestInEvolution[428] = true;
        _latestInEvolution[429] = true;
        _latestInEvolution[430] = true;
        _latestInEvolution[432] = true;
        _latestInEvolution[433] = true;
        _latestInEvolution[435] = true;
        _latestInEvolution[437] = true;
        _latestInEvolution[438] = true;
        _latestInEvolution[439] = true;
        _latestInEvolution[441] = true;
        _latestInEvolution[442] = true;
        _latestInEvolution[445] = true;
        _latestInEvolution[446] = true;
        _latestInEvolution[448] = true;
        _latestInEvolution[450] = true;
        _latestInEvolution[452] = true;
        _latestInEvolution[454] = true;
        _latestInEvolution[455] = true;
        _latestInEvolution[457] = true;
        _latestInEvolution[458] = true;
        _latestInEvolution[460] = true;
        _latestInEvolution[461] = true;
        _latestInEvolution[462] = true;
        _latestInEvolution[463] = true;
        _latestInEvolution[464] = true;
        _latestInEvolution[465] = true;
        _latestInEvolution[466] = true;
        _latestInEvolution[467] = true;
        _latestInEvolution[468] = true;
        _latestInEvolution[469] = true;
        _latestInEvolution[470] = true;
        _latestInEvolution[471] = true;
        _latestInEvolution[472] = true;
        _latestInEvolution[473] = true;
        _latestInEvolution[474] = true;
        _latestInEvolution[475] = true;
        _latestInEvolution[476] = true;
        _latestInEvolution[477] = true;
        _latestInEvolution[478] = true;
        _latestInEvolution[479] = true;
        _latestInEvolution[480] = true;
        _latestInEvolution[481] = true;
        _latestInEvolution[482] = true;
        _latestInEvolution[483] = true;
        _latestInEvolution[484] = true;
        _latestInEvolution[485] = true;
        _latestInEvolution[486] = true;
        _latestInEvolution[487] = true;
        _latestInEvolution[488] = true;
        _latestInEvolution[489] = true;
        _latestInEvolution[490] = true;
        _latestInEvolution[491] = true;
        _latestInEvolution[492] = true;
        _latestInEvolution[493] = true;
        _latestInEvolution[494] = true;
        _latestInEvolution[497] = true;

        _latestInEvolution[500] = true;
        _latestInEvolution[503] = true;
        _latestInEvolution[505] = true;
        _latestInEvolution[508] = true;
        _latestInEvolution[510] = true;
        _latestInEvolution[512] = true;
        _latestInEvolution[514] = true;
        _latestInEvolution[516] = true;
        _latestInEvolution[518] = true;
        _latestInEvolution[521] = true;
        _latestInEvolution[523] = true;
        _latestInEvolution[526] = true;
        _latestInEvolution[528] = true;
        _latestInEvolution[530] = true;
        _latestInEvolution[531] = true;
        _latestInEvolution[534] = true;
        _latestInEvolution[537] = true;
        _latestInEvolution[538] = true;
        _latestInEvolution[539] = true;
        _latestInEvolution[542] = true;
        _latestInEvolution[545] = true;
        _latestInEvolution[547] = true;
        _latestInEvolution[549] = true;
        _latestInEvolution[550] = true;
        _latestInEvolution[553] = true;
        _latestInEvolution[555] = true;
        _latestInEvolution[556] = true;
        _latestInEvolution[558] = true;
        _latestInEvolution[560] = true;
        _latestInEvolution[561] = true;
        _latestInEvolution[563] = true;
        _latestInEvolution[565] = true;
        _latestInEvolution[567] = true;
        _latestInEvolution[569] = true;
        _latestInEvolution[571] = true;
        _latestInEvolution[573] = true;
        _latestInEvolution[576] = true;
        _latestInEvolution[579] = true;
        _latestInEvolution[581] = true;
        _latestInEvolution[584] = true;
        _latestInEvolution[586] = true;
        _latestInEvolution[587] = true;
        _latestInEvolution[589] = true;
        _latestInEvolution[591] = true;
        _latestInEvolution[593] = true;
        _latestInEvolution[594] = true;
        _latestInEvolution[596] = true;
        _latestInEvolution[598] = true;

        _latestInEvolution[601] = true;
        _latestInEvolution[604] = true;
        _latestInEvolution[606] = true;
        _latestInEvolution[609] = true;
        _latestInEvolution[612] = true;
        _latestInEvolution[614] = true;
        _latestInEvolution[615] = true;
        _latestInEvolution[617] = true;
        _latestInEvolution[618] = true;
        _latestInEvolution[620] = true;
        _latestInEvolution[621] = true;
        _latestInEvolution[623] = true;
        _latestInEvolution[625] = true;
        _latestInEvolution[626] = true;
        _latestInEvolution[628] = true;
        _latestInEvolution[630] = true;
        _latestInEvolution[631] = true;
        _latestInEvolution[632] = true;
        _latestInEvolution[635] = true;
        _latestInEvolution[637] = true;
        _latestInEvolution[638] = true;
        _latestInEvolution[639] = true;
        _latestInEvolution[640] = true;
        _latestInEvolution[641] = true;
        _latestInEvolution[642] = true;
        _latestInEvolution[643] = true;
        _latestInEvolution[644] = true;
        _latestInEvolution[645] = true;
        _latestInEvolution[646] = true;
        _latestInEvolution[647] = true;
        _latestInEvolution[648] = true;
        _latestInEvolution[649] = true;
        _latestInEvolution[652] = true;
        _latestInEvolution[655] = true;
        _latestInEvolution[658] = true;
        _latestInEvolution[660] = true;
        _latestInEvolution[663] = true;
        _latestInEvolution[666] = true;
        _latestInEvolution[668] = true;
        _latestInEvolution[671] = true;
        _latestInEvolution[673] = true;
        _latestInEvolution[675] = true;
        _latestInEvolution[676] = true;
        _latestInEvolution[678] = true;
        _latestInEvolution[681] = true;
        _latestInEvolution[683] = true;
        _latestInEvolution[685] = true;
        _latestInEvolution[687] = true;
        _latestInEvolution[689] = true;
        _latestInEvolution[691] = true;
        _latestInEvolution[693] = true;
        _latestInEvolution[695] = true;
        _latestInEvolution[697] = true;
        _latestInEvolution[699] = true;

        _latestInEvolution[700] = true;
        _latestInEvolution[701] = true;
        _latestInEvolution[702] = true;
        _latestInEvolution[703] = true;
        _latestInEvolution[706] = true;
        _latestInEvolution[707] = true;
        _latestInEvolution[709] = true;
        _latestInEvolution[711] = true;
        _latestInEvolution[713] = true;
        _latestInEvolution[715] = true;
        _latestInEvolution[716] = true;
        _latestInEvolution[717] = true;
        _latestInEvolution[718] = true;
        _latestInEvolution[719] = true;
        _latestInEvolution[720] = true;
        _latestInEvolution[721] = true;
        _latestInEvolution[724] = true;
        _latestInEvolution[727] = true;
        _latestInEvolution[730] = true;
        _latestInEvolution[733] = true;
        _latestInEvolution[735] = true;
        _latestInEvolution[738] = true;
        _latestInEvolution[740] = true;
        _latestInEvolution[743] = true;
        _latestInEvolution[745] = true;
        _latestInEvolution[746] = true;
        _latestInEvolution[748] = true;
        _latestInEvolution[750] = true;
        _latestInEvolution[752] = true;
        _latestInEvolution[754] = true;
        _latestInEvolution[756] = true;
        _latestInEvolution[758] = true;
        _latestInEvolution[760] = true;
        _latestInEvolution[763] = true;
        _latestInEvolution[768] = true;
        _latestInEvolution[770] = true;
        _latestInEvolution[771] = true;
        _latestInEvolution[773] = true;
        _latestInEvolution[774] = true;
        _latestInEvolution[775] = true;
        _latestInEvolution[776] = true;
        _latestInEvolution[777] = true;
        _latestInEvolution[778] = true;
        _latestInEvolution[779] = true;
        _latestInEvolution[780] = true;
        _latestInEvolution[781] = true;
        _latestInEvolution[784] = true;
        _latestInEvolution[785] = true;
        _latestInEvolution[786] = true;
        _latestInEvolution[787] = true;
        _latestInEvolution[788] = true;
        _latestInEvolution[791] = true;
        _latestInEvolution[792] = true;
        _latestInEvolution[793] = true;
        _latestInEvolution[794] = true;
        _latestInEvolution[795] = true;
        _latestInEvolution[796] = true;
        _latestInEvolution[797] = true;
        _latestInEvolution[798] = true;
        _latestInEvolution[799] = true;

        _latestInEvolution[800] = true;
        _latestInEvolution[801] = true;
        _latestInEvolution[802] = true;
        _latestInEvolution[804] = true;
        _latestInEvolution[805] = true;
        _latestInEvolution[806] = true;
        _latestInEvolution[807] = true;
        _latestInEvolution[809] = true;
        _latestInEvolution[812] = true;
        _latestInEvolution[815] = true;
        _latestInEvolution[818] = true;
        _latestInEvolution[820] = true;
        _latestInEvolution[823] = true;
        _latestInEvolution[826] = true;
        _latestInEvolution[828] = true;
        _latestInEvolution[830] = true;
        _latestInEvolution[832] = true;
        _latestInEvolution[834] = true;
        _latestInEvolution[836] = true;
        _latestInEvolution[839] = true;
        _latestInEvolution[842] = true;
        _latestInEvolution[844] = true;
        _latestInEvolution[845] = true;
        _latestInEvolution[847] = true;
        _latestInEvolution[849] = true;
        _latestInEvolution[851] = true;
        _latestInEvolution[853] = true;
        _latestInEvolution[855] = true;
        _latestInEvolution[858] = true;
        _latestInEvolution[861] = true;
        _latestInEvolution[862] = true;
        _latestInEvolution[863] = true;
        _latestInEvolution[864] = true;
        _latestInEvolution[865] = true;
        _latestInEvolution[866] = true;
        _latestInEvolution[867] = true;
        _latestInEvolution[868] = true;
        _latestInEvolution[869] = true;
        _latestInEvolution[870] = true;
        _latestInEvolution[871] = true;
        _latestInEvolution[873] = true;
        _latestInEvolution[874] = true;
        _latestInEvolution[875] = true;
        _latestInEvolution[876] = true;
        _latestInEvolution[877] = true;
        _latestInEvolution[879] = true;
        _latestInEvolution[880] = true;
        _latestInEvolution[881] = true;
        _latestInEvolution[882] = true;
        _latestInEvolution[883] = true;
        _latestInEvolution[884] = true;
        _latestInEvolution[887] = true;
        _latestInEvolution[888] = true;
        _latestInEvolution[889] = true;
        _latestInEvolution[890] = true;
        _latestInEvolution[892] = true;
        _latestInEvolution[893] = true;
        _latestInEvolution[894] = true;
        _latestInEvolution[895] = true;
        _latestInEvolution[896] = true;
        _latestInEvolution[897] = true;
        _latestInEvolution[898] = true;
        _latestInEvolution[899] = true;
        _latestInEvolution[900] = true;
        _latestInEvolution[901] = true;
        _latestInEvolution[902] = true;
        _latestInEvolution[903] = true;
        _latestInEvolution[904] = true;
        _latestInEvolution[905] = true;

        _thunderUpgrades[25] = 26;
        _thunderUpgrades[133] = 135;
        _thunderUpgrades[603] = 604;
        _moonUpgrades[30] = 31;
        _moonUpgrades[33] = 34;
        _moonUpgrades[35] = 36;
        _moonUpgrades[39] = 40;
        _moonUpgrades[300] = 301;
        _moonUpgrades[517] = 518;
        _fireUpgrades[37] = 38;
        _fireUpgrades[58] = 59;
        _fireUpgrades[513] = 514;
        _fireUpgrades[133] = 136;
        _leafUpgrades[44] = 45;
        _leafUpgrades[70] = 71;
        _leafUpgrades[102] = 103;
        _leafUpgrades[274] = 275;
        _leafUpgrades[511] = 512;
        _leafUpgrades[133] = 470;
        _sunUpgrades[44] = 182;
        _sunUpgrades[191] = 192;
        _sunUpgrades[546] = 547;
        _sunUpgrades[548] = 549;
        _sunUpgrades[694] = 695;
        _waterUpgrades[61] = 62;
        _waterUpgrades[90] = 91;
        _waterUpgrades[120] = 121;
        _waterUpgrades[271] = 272;
        _waterUpgrades[515] = 516;
        _waterUpgrades[133] = 134;
        _blackAuguriteUpgrades[123] = 900;
        _shinyUpgrades[176] = 468;
        _shinyUpgrades[315] = 407;
        _shinyUpgrades[572] = 573;
        _shinyUpgrades[670] = 671;
        _duskUpgrades[198] = 430;
        _duskUpgrades[200] = 429;
        _duskUpgrades[608] = 609;
        _duskUpgrades[680] = 681;
        _razorClawUpgrades[215] = 461;
        _peatBlockUpgrades[217] = 901;
        _tartAppleUpgrades[840] = 841;
        _crackedPotUpgrades[854] = 855;
        _ovalUpgrades[440] = 113;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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