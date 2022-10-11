/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

library Strings {
    function toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }
}

library MTMLib {
    // Static String Returns
    function getNameOfItem(uint8 item_) public pure returns (string memory) {
        if      (item_ == 1) { return "WEAPONS";   }
        else if (item_ == 2) { return "CHEST";     }
        else if (item_ == 3) { return "HEAD";      }
        else if (item_ == 4) { return "LEGS";      }
        else if (item_ == 5) { return "VEHICLE";   }
        else if (item_ == 6) { return "ARMS";      }
        else if (item_ == 7) { return "ARTIFACTS"; }
        else if (item_ == 8) { return "RINGS";     }
        else                 { revert("Invalid Equipment Upgrades Query!"); }
    }

    // Static Rarity Stuff
    function getItemRarity(uint16 spaceCapsuleId_, string memory keyPrefix_) public pure returns (uint8) {
        uint256 _rarity = uint256(keccak256(abi.encodePacked(keyPrefix_, Strings.toString(spaceCapsuleId_)))) % 21;
        return uint8(_rarity);
    }
    function queryEquipmentUpgradability(uint8 rarity_) public pure returns (uint8) {
        return rarity_ >= 19 ? rarity_ == 19 ? 4 : 4 : 4; 
    }
    function queryBaseEquipmentTier(uint8 rarity_) public pure returns (uint8) {
        return rarity_ >= 19 ? rarity_ == 19 ? 1 : 2 : 0;
    }

    // Character Modification Costs
    function queryAugmentCost(uint8 currentLevel_) public pure returns (uint256) {
        if      (currentLevel_ == 0) { return 0;         }
        else if (currentLevel_ == 1) { return 1 ether;   }
        else if (currentLevel_ == 2) { return 2 ether;   }
        else if (currentLevel_ == 3) { return 5 ether;   }
        else if (currentLevel_ == 4) { return 10 ether;  }
        else if (currentLevel_ == 5) { return 15 ether;  }
        else if (currentLevel_ == 6) { return 25 ether;  }
        else if (currentLevel_ == 7) { return 50 ether;  }
        else if (currentLevel_ == 8) { return 100 ether; }
        else if (currentLevel_ == 9) { return 250 ether; }
        else                         { revert("Invalid level!"); }
    }
    function queryBasePointsUpgradeCost(uint16 currentLevel_) public pure returns (uint256) {
        uint8 _tier = uint8(currentLevel_ / 5);
        if      (_tier == 0) { return 1 ether;   }
        else if (_tier == 1) { return 2 ether;   }
        else if (_tier == 2) { return 5 ether;   }
        else if (_tier == 3) { return 10 ether;  }
        else if (_tier == 4) { return 20 ether;  }
        else if (_tier == 5) { return 30 ether;  }
        else if (_tier == 6) { return 50 ether;  }
        else if (_tier == 7) { return 70 ether;  }
        else if (_tier == 8) { return 100 ether; }
        else if (_tier == 9) { return 150 ether; }
        else                 { revert("Invalid Level!"); }
    }
    function queryEquipmentUpgradeCost(uint8 currentLevel_) public pure returns (uint256) {
        if      (currentLevel_ == 0) { return 50 ether;   }
        else if (currentLevel_ == 1) { return 250 ether;  }
        else if (currentLevel_ == 2) { return 750 ether;  }
        else if (currentLevel_ == 3) { return 1500 ether; }
        else                         { revert("Invalid Level!"); }
    }

    // Yield Rate Constants
    function getBaseYieldRate(uint8 augments_) public pure returns (uint256) {
        if      (augments_ == 0 ) { return 0.1 ether; }
        else if (augments_ == 1 ) { return 1 ether;   }
        else if (augments_ == 2 ) { return 2 ether;   }
        else if (augments_ == 3 ) { return 3 ether;   }
        else if (augments_ == 4 ) { return 4 ether;   }
        else if (augments_ == 5 ) { return 5 ether;   }
        else if (augments_ == 6 ) { return 6 ether;   }
        else if (augments_ == 7 ) { return 7 ether;   }
        else if (augments_ == 8 ) { return 8 ether;   }
        else if (augments_ == 9 ) { return 9 ether;   }
        else if (augments_ == 10) { return 10 ether;  }
        else                      { return 0;         }
    }
    function queryEquipmentModulus(uint8 rarity_, uint8 upgrades_) public pure returns (uint8) {
        uint8 _baseTier = queryBaseEquipmentTier(rarity_);
        uint8 _currentTier = _baseTier + upgrades_;
        if      (_currentTier == 0) { return 0;  }
        else if (_currentTier == 1) { return 2;  }
        else if (_currentTier == 2) { return 5;  }
        else if (_currentTier == 3) { return 10; }
        else if (_currentTier == 4) { return 20; }
        else if (_currentTier == 5) { return 35; }
        else if (_currentTier == 6) { return 50; }
        else                        { revert("Invalid Level!"); }
    }
    function getStatMultiplier(uint16 basePoints_) public pure returns (uint256) {
        return uint256( (basePoints_ * 2) + 100 );
    }
    function getEquipmentMultiplier(uint16 totalEquipmentBonus_) public pure returns (uint256) {
        return uint256( totalEquipmentBonus_ + 100 );
    }

    // Base Yield Rate Caclulations
    function getItemBaseBonus(uint16 spaceCapsuleId_, string memory keyPrefix_) public pure returns (uint8) {
        return queryEquipmentModulus( getItemRarity(spaceCapsuleId_, keyPrefix_), 0 );
    }
    function getEquipmentBaseBonus(uint16 spaceCapsuleId_) public pure returns (uint16) {
        return uint16(
        getItemBaseBonus(spaceCapsuleId_, "WEAPONS") + 
        getItemBaseBonus(spaceCapsuleId_, "CHEST") +
        getItemBaseBonus(spaceCapsuleId_, "HEAD") +
        getItemBaseBonus(spaceCapsuleId_, "LEGS") +
        getItemBaseBonus(spaceCapsuleId_, "VEHICLE") +
        getItemBaseBonus(spaceCapsuleId_, "ARMS") + 
        getItemBaseBonus(spaceCapsuleId_, "ARTIFACTS") +
        getItemBaseBonus(spaceCapsuleId_, "RINGS")
        );
    }

    // Yield Rate Calculation
    function getCharacterYieldRate(uint8 augments_, uint16 basePoints_, uint16 totalEquipmentBonus_) public pure returns (uint256) {
        uint256 _baseYield = getBaseYieldRate(augments_);
        uint256 _statMultiplier = getStatMultiplier(basePoints_);
        uint256 _eqMultiplier = getEquipmentMultiplier(totalEquipmentBonus_);
        return _baseYield * (_statMultiplier * _eqMultiplier) / 10000;
    }
}