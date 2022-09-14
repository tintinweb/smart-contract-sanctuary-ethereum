// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../lib_constants/TraitDefs.sol";
import "../extensions/Owner.sol";
import "../lib_env/Mainnet.sol";

interface IOptionsContract {
  function getOption(uint256) external pure returns (uint8);
}

contract TraitsUtility is Owner {
  mapping(uint8 => address) optionsContracts;

  constructor() {
    _owner = msg.sender;

    // once optionContracts are live, initialize automatically here
    optionsContracts[TraitDefs.SPECIES] = Mainnet.OptionSpecies;
    optionsContracts[TraitDefs.LOCALE] = Mainnet.OptionLocale;
    optionsContracts[TraitDefs.BELLY] = Mainnet.OptionBelly;
    optionsContracts[TraitDefs.EYES] = Mainnet.OptionEyes;
    optionsContracts[TraitDefs.MOUTH] = Mainnet.OptionMouth;
    optionsContracts[TraitDefs.NOSE] = Mainnet.OptionNose;
    optionsContracts[TraitDefs.CLOTHING] = Mainnet.OptionClothing;
    optionsContracts[TraitDefs.HAT] = Mainnet.OptionHat;
    optionsContracts[TraitDefs.JEWELRY] = Mainnet.OptionJewelry;
    optionsContracts[TraitDefs.FOOTWEAR] = Mainnet.OptionFootwear;
    optionsContracts[TraitDefs.ACCESSORIES] = Mainnet.OptionAccessories;
    optionsContracts[TraitDefs.FACE_ACCESSORY] = Mainnet.OptionFaceAccessory;
    optionsContracts[TraitDefs.BACKGROUND] = Mainnet.OptionBackground;
  }

  function setOptionContract(uint8 traitDef, address optionContract)
    external
    onlyOwner
  {
    optionsContracts[traitDef] = optionContract;
  }

  function getOption(uint8 traitDef, uint256 dna)
    external
    view
    returns (uint8)
  {
    return IOptionsContract(optionsContracts[traitDef]).getOption(dna);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitDefs {
  uint8 constant SPECIES = 0;
  uint8 constant LOCALE = 1;
  uint8 constant BELLY = 2;
  uint8 constant ARMS = 3;
  uint8 constant EYES = 4;
  uint8 constant MOUTH = 5;
  uint8 constant NOSE = 6;
  uint8 constant CLOTHING = 7;
  uint8 constant HAT = 8;
  uint8 constant JEWELRY = 9;
  uint8 constant FOOTWEAR = 10;
  uint8 constant ACCESSORIES = 11;
  uint8 constant FACE_ACCESSORY = 12;
  uint8 constant BACKGROUND = 13;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Owner {
  address _owner;

  constructor() {
    _owner = msg.sender;
  }

  modifier setOwner(address owner_) {
    require(msg.sender == _owner);
    _owner = _owner;
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Mainnet {
  address constant ACCESSORIES = 0x72b7596E59CfB97661D68024b3c5C587fBc3F0D3;
  address constant ARMS = 0x7e10747a91E45F0fD0C97b763BCcB61030806a69;
  address constant BELLY = 0xf398b7504F01c198942D278EAB8715f0A03D55cb;
  address constant CLOTHINGA = 0x324E15FbDaC47DaF13EaB1fD06C4467D4C7008f9;
  address constant CLOTHINGB = 0x927858Ed8FF2F3E9a09CE9Ca5E9B13523e574fa2;
  address constant EYES = 0x12b538733eFc80BD5D25769AF34B2dA63911BEf8;
  address constant FACE = 0xa8cA38F3BBE56001bE7E3F9768C6e4A0fC2D79cF;
  address constant FEET = 0xE6d17Ff2D51c02f49005B5046f499715aE7E6FF3;
  address constant FOOTWEAR = 0x4384ccFf9bf4e1448976310045144e3B7d17e851;
  address constant HAT = 0xB1A63A1a745E49417BB6E3B226C47af7319664cB;
  address constant HEAD = 0x76Bcf1b35632f59693f8E7D348FcC293aE90f888;
  address constant JEWELRY = 0x151E97911b357fF8EF690107Afbcf6ecBd52D982;
  address constant MOUTH = 0x16Ba2C192391A400b6B6Ee5E46901C737d83Df9D;
  address constant NOSE = 0x6f3cdF8dc2D1915aaAE804325d2c550b959E6B47;
  address constant SPECIAL_CLOTHING =
    0x228dc46360537d24139Ee81AFb9235FA2C0CdA07;
  address constant SPECIAL_FACE = 0x7713D096937d98CDA86Fc80EF10dcAb77367068c;

  // Trait Option Labels
  address constant TraitOptionLabelsAccessories =
    0x7db2Ae5Da12b6891ED08944690B3f4468F68AA71;
  address constant TraitOptionLabelsBackground =
    0x1Dea31e5497f80dE9F4802508D98288ffF834cd9;
  address constant TraitOptionLabelsBelly =
    0xDa97bDb87956fE1D370ab279eF5327c7751D0Bd4;
  address constant TraitOptionLabelsClothing =
    0x42C328934037521E1E08ee3c3E0142aB7E9e8534;
  address constant TraitOptionLabelsEyes =
    0x4acDa10ff43430Ae90eF328555927e9FcFd4904A;
  address constant TraitOptionLabelsFaceAccessory =
    0xfAD91b20182Ad3907074E0043c1212EaE1F7dfaE;
  address constant TraitOptionLabelsFootwear =
    0x435B753316d4bfeF7BB755c3f4fAC202aACaA209;
  address constant TraitOptionLabelsHat =
    0x220d2C51332aafd76261E984e4DA1a43C361A62f;
  address constant TraitOptionLabelsJewelry =
    0x8f69858BD253AcedFFd99479C05Aa37305919ec1;
  address constant TraitOptionLabelsLocale =
    0x13c0B8289bEb260145e981c3201CC2A046F1b83D;
  address constant TraitOptionLabelsMouth =
    0xcb03ebEabc285616CF4aEa7de1333D53f0789141;
  address constant TraitOptionLabelsNose =
    0x03774BA2E684D0872dA02a7da98AfcbebF9E61b2;
  address constant TraitOptionLabelsSpecies =
    0x9FAe2ceBDbfDA7EAeEC3647c16FAE2a4e715e5CA;

  address constant OptionSpecies = 0x5438ae4D244C4a8eAc6Cf9e64D211c19B5835a91;
  address constant OptionAccessories =
    0x1097750D85A2132CAf2DE3be2B97fE56C7DB0bCA;
  address constant OptionClothing = 0xF0B8294279a35bE459cfc257776521A5E46Da0d1;
  address constant OptionLocale = 0xa0F6DdB7B3F114F18073867aE4B740D0AF786721;
  address constant OptionHat = 0xf7C17dB875d8C4ccE301E2c6AF07ab7621204223;
  address constant OptionFaceAccessory =
    0x07E0b24A4070bC0e8198154e430dC9B2FB9B4721;
  address constant OptionFootwear = 0x31b2E83d6fb1d7b9d5C4cdb5ec295167d3525eFF;
  address constant OptionJewelry = 0x9ba79b1fa5A19d31E6cCeEA7De6712992080644B;

  address constant OptionBackground =
    0xC3c5a361d09C54C59340a8aB069b0796C962D2AE;
  address constant OptionBelly = 0xEDf3bAdbb0371bb95dedF567E1a947a0841C5Cc5;
  address constant OptionEyes = 0x4aBeBaBb4F4Fb7A9440E05cBebc55E5Cd160A3aA;
  address constant OptionMouth = 0x9801A9da73fBe2D889c4847BCE25C751Ce334332;
  address constant OptionNose = 0x22116E7ff81752f7b61b4c1d3E0966033939b50f;

  // Utility Contracts
  address constant TraitsUtility = 0xc81Ee07619c8ff65f0E19A214e43b1fd55051FE2;
  // address constant Animation = 0x2F3264D81B4A2761aF4961Db43abbe3c0CACcb8b;

  // address constant Metadata = 0x46690c52FD37545e5EF82a7AAfEf11716bff0109;
}