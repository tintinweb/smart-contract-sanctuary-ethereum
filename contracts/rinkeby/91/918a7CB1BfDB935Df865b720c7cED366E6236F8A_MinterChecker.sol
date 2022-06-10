//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IBotMetadata.sol";
import "./Managable.sol";
import "./LibBot.sol";

contract MinterChecker is Managable {
    address public botMetadataAddress;

    uint32[] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];    

    constructor(address _botMetadataAddress) {
        _setBotMetadataAddress(_botMetadataAddress);

        _addManager(msg.sender);
    }

    function setBotMetadataAddress(address _addr) external onlyManager {
        _setBotMetadataAddress(_addr);
    }    

    function canBreed(uint256 _matronId, uint256 _sireId) public view returns(bool) {
        if (_matronId == _sireId) {
            return false;
        }

        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        return _canBreed(matron) && _canBreed(sire) && _notCooldown(matron) && _notCooldown(sire) && _notRelatives(matron, sire);
    }

    function _notCooldown(LibBot.Bot memory _b) private view returns(bool) {
        if (_b.breedCount == 0) {
            return true;
        }

        uint32 _cooldown = cooldowns[_b.breedCount];
        if (_cooldown == 0) {
            return true;
        }

        return _b.lastBreed + _cooldown < block.timestamp;
    }

    function _canBreed(LibBot.Bot memory _b) private pure returns(bool) {
        if (_b.generation == 0 && _b.breedCount <= 12) {
            return true;
        }

        return _b.breedCount <= 7;
    }

    function _notRelatives(LibBot.Bot memory _matron, LibBot.Bot memory _sire) private pure returns(bool) {        
        if (_matron.generation == 0 && _sire.generation == 0) {
            return true;
        }
        
        // If they have same partens it's can't be done
        if (
            (_matron.matronId == _sire.matronId && _matron.sireId == _sire.sireId) || 
            (_matron.sireId == _sire.matronId && _matron.matronId == _sire.sireId)
        ) {
            return false;
        }

        // You can't breed with you kids
        if (_matron.id == _sire.matronId || _matron.id == _sire.sireId) {
            return false;
        }

        if (_sire.id == _matron.matronId || _sire.id == _matron.sireId) {
            return false;
        }

        return true;
    }    

    function relativeChecker(uint256 _matronId, uint256 _sireId) public view returns(bool, bool, bool, bool) {
        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        bool isSameBots;
        bool isGeneZero;
        bool haveSameParents;
        bool isKidAndParent;

        if (matron.generation == 0 && sire.generation == 0) {
            isGeneZero = true;
        }        

        if (_matronId == _sireId) {
            isSameBots = true;
        }        

        if (
            (matron.matronId == sire.matronId && matron.sireId == sire.sireId) || 
            (matron.sireId == sire.matronId && matron.matronId == sire.sireId)
        ) {
            haveSameParents = true;
        }

        if (matron.id == sire.matronId || matron.id == sire.sireId) {
            isKidAndParent = true;
        }

        if (sire.id == matron.matronId || sire.id == matron.sireId) {
            isKidAndParent = true;
        }        

        return (isSameBots, isGeneZero, haveSameParents, isKidAndParent);
    }

    function _botMetadata() private view returns(IBotMetadata) {
        return IBotMetadata(botMetadataAddress);
    }

    function _setBotMetadataAddress(address _addr) internal {
        botMetadataAddress = _addr;
    }          
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibBot.sol";

interface IBotMetadata {
    function setBot(uint256 _tokenId, LibBot.Bot calldata _bot) external;
    function getBot(uint256 _tokenId) external view returns(LibBot.Bot memory);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibBot {
    struct Bot {
        uint256 id;
        uint256 genes;
        uint256 birthTime;
        uint64 matronId;
        uint64 sireId;
        uint8 generation;
        uint8 breedCount;
        uint256 lastBreed;
        uint256 revealCooldown;
    }
}