// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

contract LaserRegistry {
    address private constant POINTER = address(0x1);

    address public laser;

    uint256 moduleCount;

    mapping(address => address) private approvedModules;

    mapping(address => address) private approvedSingletons;

    modifier onlyLaser() {
        require(msg.sender == laser, "Only Laser");

        _;
    }

    constructor(
        address _laser,
        address firstSingleton,
        address[] memory modules
    ) {
        laser = _laser;

        approvedSingletons[firstSingleton] = approvedSingletons[POINTER];
        approvedSingletons[firstSingleton] = firstSingleton;

        address currentModule = POINTER;
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            address module = modules[i];

            approvedModules[currentModule] = module;
            currentModule = module;
        }
        approvedModules[currentModule] = POINTER;
        moduleCount = modulesLength;
    }

    function approveSingleton(address singleton) external onlyLaser {
        approvedSingletons[singleton] = approvedSingletons[POINTER];
        approvedSingletons[singleton] = singleton;
    }

    function approveModule(address module) external onlyLaser {
        approvedModules[module] = approvedModules[POINTER];
        approvedModules[POINTER] = module;

        unchecked {
            ++moduleCount;
        }
    }

    function removeModule(address prevModule, address module) external onlyLaser {
        require(approvedModules[module] != address(0), "Module not found");
        require(module != POINTER, "incorrect");

        require(approvedModules[prevModule] == module, "incorrect prev module");

        approvedModules[prevModule] = approvedModules[module];
        approvedModules[module] = address(0);

        unchecked {
            --moduleCount;
        }
    }

    function isSingleton(address singleton) external view returns (bool) {
        return approvedSingletons[singleton] != address(0) && singleton != POINTER;
    }

    function isModule(address module) external view returns (bool) {
        return approvedModules[module] != address(0) && module != POINTER;
    }

    function getModules() public view returns (address[] memory) {
        address[] memory modulesArray = new address[](moduleCount);
        address currentModule = approvedModules[POINTER];

        uint256 index;
        while (currentModule != POINTER) {
            modulesArray[index] = currentModule;
            currentModule = approvedModules[currentModule];
            unchecked {
                ++index;
            }
        }
        return modulesArray;
    }
}