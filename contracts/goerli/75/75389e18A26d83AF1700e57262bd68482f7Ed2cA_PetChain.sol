// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./structs.sol";

// @dev This functions are agnostic to which fields are encrypted and which are not
//      Checkout the structs in structs.sol
interface IPetchain {
    function registerAnimal(Animal calldata animal) external returns (uint256 animalId);

    function vaccineAnimal(uint256 animalId, Vaccine calldata vaccine) external;

    /// view functions

    function readAnimalInfo(uint256 animalId) external view returns (Animal memory);

    function readAnimalVaccines(uint256 animalId) external view returns (Vaccine[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./IPetchain.sol";

contract PetChain is IPetchain {
    uint256 vetCount;
    uint256 ownerCount;

    mapping(uint256 => Animal) animals;

    // animalId => Vaccines
    mapping(uint256 => Vaccine[]) vaccines;

    error NonExistingAnimalId();

    event AnimalRegistered(uint256 microchipId);
    event AnimalVaccinated(uint256 microchipId, string vaccineName);

    function registerAnimal(Animal calldata animal) external override returns (uint256 animalId) {
        animalId = animal.microchipNumber;
        animals[animalId] = animal;
        emit AnimalRegistered(animalId);
    }

    function vaccineAnimal(uint256 microchipId, Vaccine calldata vaccine) external override {
        vaccines[microchipId].push(vaccine);
        emit AnimalVaccinated(microchipId, vaccine.vaccineName);
    }

    /// view functions

    function readAnimalInfo(uint256 microchipId) external view override returns (Animal memory) {
        return animals[microchipId];
    }

    function readAnimalVaccines(uint256 microchipId) external view override returns (Vaccine[] memory) {
        return vaccines[microchipId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

struct Animal {
    uint256 microchipNumber; // blockchain, public
    uint256 microchipDateOfImplant; // blockchain, public
    string microchipImplantLocation; // blockchain, public
    string animalSpecies; // blockchain, public
    string animalBreed; // blockchain, public
    string ownerName; // blockchain, encrypted
    string ownerContactInfo; // blockchain, encrypted
}

struct Vaccine {
    string vaccineName; // blockchain, public
    uint256 date; // blockchain, public
    uint256 lote; // blockchain, public
}