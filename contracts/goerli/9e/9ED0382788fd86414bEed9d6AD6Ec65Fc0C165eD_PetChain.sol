// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./structs.sol";

// @dev This functions are agnostic to which fields are encrypted and which are not
//      Checkout the structs in structs.sol
interface IPetchain {
    function registerOwner(Owner calldata owner) external returns (uint256 ownerId);

    function registerVet(Vet calldata vet) external returns (uint256 vetId);

    function registerAnimal(Animal calldata animal) external returns (uint256 animalId);

    function vaccineAnimal(uint256 animalId, Vaccine calldata vaccine) external;

    /// view functions

    function readOwnerInfo(uint256 vetId) external view returns (Owner memory);

    function readVetInfo(uint256 vetId) external view returns (Vet memory);

    function readAnimalInfo(uint256 animalId) external view returns (Animal memory);

    function readAnimalsFromOwner(uint256 ownerId) external view returns (uint256[] memory);

    function readAnimalVaccines(uint256 animalId) external view returns (Vaccine[] memory);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./IPetchain.sol";

contract PetChain is IPetchain {
    uint256 vetCount;
    uint256 ownerCount;

    mapping(uint256 => Vet) vets;
    mapping(uint256 => Owner) owners;
    mapping(uint256 => Animal) animals;
    mapping(uint256 => uint256[]) ownerToAnimals;

    // animalId => Vaccines
    mapping(uint256 => Vaccine[]) vaccines;

    error NonExistingAnimalId();

    event OwnerRegistered(uint256 ownerId);
    event VetRegistered(uint256 vetId);
    event AnimalRegistered(uint256 microchipId, uint256 ownerId);
    event AnimalVaccinated(uint256 microchipId, string vaccineName);

    // @dev This function is agnostic to which fields are encrypted and which are not
    function registerOwner(Owner calldata owner) external override returns (uint256 ownerId) {
        ownerCount++;
        ownerId = ownerCount;
        owners[ownerId] = owner;
        emit OwnerRegistered(ownerId);
    }

    function registerVet(Vet calldata vet) external override returns (uint256 vetId) {
        vetCount++;
        vetId = vetCount;
        vets[vetId] = vet;
        emit VetRegistered(vetId);
    }

    function registerAnimal(Animal calldata animal) external override returns (uint256 animalId) {
        animalId = animal.microchipNumber;
        animals[animalId] = animal;
        ownerToAnimals[animal.ownerId].push(animalId);
        emit AnimalRegistered(animalId, animal.ownerId);
    }

    function vaccineAnimal(uint256 microchipId, Vaccine calldata vaccine) external override {
        vaccines[microchipId].push(vaccine);
        emit AnimalVaccinated(microchipId, vaccine.name);
    }

    /// view functions

    function readOwnerInfo(uint256 ownerId) external view override returns (Owner memory) {
        return owners[ownerId];
    }

    function readAnimalInfo(uint256 microchipId) external view override returns (Animal memory) {
        return animals[microchipId];
    }

    function readVetInfo(uint256 vetId) external view override returns (Vet memory) {
        return vets[vetId];
    }

    function readAnimalsFromOwner(uint256 ownerId) external override view returns (uint256[] memory) {
        return ownerToAnimals[ownerId];
    }

    function readAnimalVaccines(uint256 microchipId) external override view returns (Vaccine[] memory) {
        return vaccines[microchipId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

struct Owner {
    string firstName; // blockchain, encrypted
    string lastName; // blockchain, encrypted
    string email; // blockchain, encrypted
    string phone; // blockchain, encrypted
    string livingAddress; // blockchain, encrypted
    string country; // blockchain, public
}

struct Vet {
    string firstName; // blockchain, encrypted
    string lastName; // blockchain, encrypted
    string email; // blockchain, encrypted
    string phone; // blockchain, encrypted
    string livingAddress; // blockchain, encrypted
    string country; // blockchain, public
    string institution; // blockchain, public
    uint256 institutionId; // blockchain, public
}

struct Animal {
    uint256 microchipNumber; // blockchain, public
    uint256 microchipDateOfImplant; // blockchain, public
    string microchipImplantLocation; // blockchain, public
    string animalSpecies; // blockchain, public
    string animalBreed; // blockchain, public
    string gender; // blockchain, public
    bool sterilized; // blockchain, public
    uint256 sterilizationDate; // blockchain, public
    uint256 ownerId; // blockchain, public
}

struct Vaccine {
    string name; // blockchain, public
    uint256 date; // blockchain, public
    uint256 lote; // blockchain, public
}