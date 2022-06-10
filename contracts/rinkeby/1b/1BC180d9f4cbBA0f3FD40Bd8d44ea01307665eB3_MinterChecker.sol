//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IBotMetadata.sol";
import "./Managable.sol";
import "./LibBot.sol";

contract MinterChecker is Managable {
    address public botMetadataAddress;

    constructor(address _botMetadataAddress) {
        _setBotMetadataAddress(_botMetadataAddress);

        _addManager(msg.sender);
    }

    function setBotMetadataAddress(address _addr) external onlyManager {
        _setBotMetadataAddress(_addr);
    }    

    function canBreed(uint256 _matronId, uint256 _sireId) public view returns(bool, bool, bool, bool) {


        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        bool isSameBots;
        bool isGeneZero;
        bool haveSameParents;
        bool isKidAndParent;

        if (matron.generation == 0 && matron.generation == 0) {
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