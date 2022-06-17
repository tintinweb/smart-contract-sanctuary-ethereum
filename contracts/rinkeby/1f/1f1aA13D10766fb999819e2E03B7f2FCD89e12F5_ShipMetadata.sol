//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibShip.sol";
import "../Managable.sol";

contract ShipMetadata is Managable {
    mapping(uint256 => LibShip.Ship) public ships;

    constructor() {
        _addManager(msg.sender);
    }

    function setShip(uint256 _tokenId, LibShip.Ship calldata _ship) external onlyManager {
        ships[_tokenId] = _ship;
    }

    function getShip(uint256 _tokenId) external view returns(LibShip.Ship memory) {
        return ships[_tokenId];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibShip {
    struct Ship {
        uint256 genes;
        uint48 id;
        uint48 birthTime;
        uint8 a;
        uint8 b;
        uint8 c;
        uint48 x;
        uint48 y;
        uint32 z;
    }
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