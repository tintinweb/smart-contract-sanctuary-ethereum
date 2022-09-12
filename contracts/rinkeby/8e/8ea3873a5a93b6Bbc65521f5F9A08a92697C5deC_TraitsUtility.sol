// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../lib_constants/TraitDefs.sol";
import "../extensions/Owner.sol";
import "../lib_env/Rinkeby.sol";

interface IOptionsContract {
  function getOption(uint256) external pure returns (uint8);
}

contract TraitsUtility is Owner {
  mapping(uint8 => address) optionsContracts;

  constructor() {
    _owner = msg.sender;

    // once optionContracts are live, initialize automatically here
    optionsContracts[TraitDefs.SPECIES] = Rinkeby.OptionSpecies;
    optionsContracts[TraitDefs.LOCALE] = Rinkeby.OptionLocale;
    optionsContracts[TraitDefs.BELLY] = Rinkeby.OptionBelly;
    optionsContracts[TraitDefs.EYES] = Rinkeby.OptionEyes;
    optionsContracts[TraitDefs.MOUTH] = Rinkeby.OptionMouth;
    optionsContracts[TraitDefs.NOSE] = Rinkeby.OptionNose;
    optionsContracts[TraitDefs.CLOTHING] = Rinkeby.OptionClothing;
    optionsContracts[TraitDefs.HAT] = Rinkeby.OptionHat;
    optionsContracts[TraitDefs.JEWELRY] = Rinkeby.OptionJewelry;
    optionsContracts[TraitDefs.FOOTWEAR] = Rinkeby.OptionFootwear;
    optionsContracts[TraitDefs.ACCESSORIES] = Rinkeby.OptionAccessories;
    optionsContracts[TraitDefs.FACE_ACCESSORY] = Rinkeby.OptionFaceAccessory;
    optionsContracts[TraitDefs.BACKGROUND] = Rinkeby.OptionBackground;
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

library Rinkeby {
  address constant ACCESSORIES = 0x4acDa10ff43430Ae90eF328555927e9FcFd4904A;
  address constant ARMS = 0xfAD91b20182Ad3907074E0043c1212EaE1F7dfaE;
  address constant BELLY = 0x435B753316d4bfeF7BB755c3f4fAC202aACaA209;
  address constant CLOTHINGA = 0x220d2C51332aafd76261E984e4DA1a43C361A62f;
  address constant CLOTHINGB = 0x8f69858BD253AcedFFd99479C05Aa37305919ec1;
  address constant EYES = 0x13c0B8289bEb260145e981c3201CC2A046F1b83D;
  address constant FACE = 0xcb03ebEabc285616CF4aEa7de1333D53f0789141;
  address constant FEET = 0x03774BA2E684D0872dA02a7da98AfcbebF9E61b2;
  address constant FOOTWEAR = 0x9FAe2ceBDbfDA7EAeEC3647c16FAE2a4e715e5CA;
  address constant HAT = 0x5438ae4D244C4a8eAc6Cf9e64D211c19B5835a91;
  address constant HEAD = 0x31b2E83d6fb1d7b9d5C4cdb5ec295167d3525eFF;
  address constant JEWELRY = 0x1097750D85A2132CAf2DE3be2B97fE56C7DB0bCA;
  address constant MOUTH = 0xF0B8294279a35bE459cfc257776521A5E46Da0d1;
  address constant NOSE = 0xa0F6DdB7B3F114F18073867aE4B740D0AF786721;
  address constant SPECIAL_CLOTHING =
    0xf7C17dB875d8C4ccE301E2c6AF07ab7621204223;
  address constant SPECIAL_FACE = 0x07E0b24A4070bC0e8198154e430dC9B2FB9B4721;

  // Deployed Trait Options Contracts
  address constant OptionAccessories =
    0xBC2D1FF30cF861081521C14f63acBEcB292C6f7A;
  address constant OptionBackground =
    0x8E1ca38c557f12dA069D2cc8dBAD810aa6438b7F;
  address constant OptionBelly = 0x4BE43551f349147f5fF1641Ba59BDB451E016956;
  address constant OptionClothing = 0xA8e7384eF936B9Bd01d165E55919513A7D2A9e22;
  address constant OptionEyes = 0x3a4CF675d3DdfA65aBBE0C5c1bfafA0F7cc69CE8;
  address constant OptionFaceAccessory =
    0xdf038D99d41D3F38803fEC558C5E6401E61dCA91;
  address constant OptionFootwear = 0xA18EFD67AC4383D94B6FD68b627ACF89AdA412fB;
  address constant OptionHat = 0x3dCFAa025847A02b385940284aD803bca5deCD23;
  address constant OptionJewelry = 0x02FEF28743b63E80DEf13f70618a6F2ad2bD65aE;
  address constant OptionLocale = 0x7582801c4e57fd0eA21B9A474E5144C436998C71;
  address constant OptionMouth = 0xc278A76EDB76E0F26e3365354061D12Dadd5950C;
  address constant OptionNose = 0x1A494C15474987A9633B0E21735A5130ff6939C8;
  address constant OptionSpecies = 0x72581cEA263688bE9278507b9361E18dca19c65c;

  // Utility Contracts
  address constant TraitsUtility = 0xD6E6d9A4065a3f4A20e049753d4fcdc5844b644e;
  address constant Animation = 0x1b9aDeACe896a3ab7876D921da59c28FaF5ea6C4;
}