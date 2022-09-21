// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract IncubatorMethods is Params {

    constructor(IncubatorConstructor.Struct memory input) Params(input) {}

    function breedHounds(
        uint256 hound1Id, 
        HoundIdentity.Struct memory hound1, 
        uint256 hound2Id, 
        HoundIdentity.Struct memory hound2, 
        uint256 theId
    ) public {
        require(allowed[msg.sender]);
        
        uint256 randomness = IGetRandomNumber(control.randomness).getRandomNumber(
            abi.encode(hound1Id > hound2Id ? hound1.geneticSequence : hound2.geneticSequence)
        );
        uint32[54] memory genetics = IMixGenes(control.genetics).mixGenes(
            hound1.geneticSequence, 
            hound2.geneticSequence,
            randomness
        );

        IInitializeHoundGamingStats(control.gamification).initializeHoundGamingStats(theId, genetics);

        houndsIdentity[theId] = HoundIdentity.Struct(
            hound1Id,
            hound2Id,
            hound1.generation + hound2.generation,
            block.timestamp,
            genetics,
            "",
            uint256(uint160(control.randomness)) % 100 == 99 ? 
                (
                    hound1.specie > hound2.specie ? 
                        hound1.specie
                    : 
                        hound2.specie
                )
            : 
                (
                    hound1.specie > hound2.specie ? 
                        hound2.specie
                    : 
                        hound1.specie
                )
        );
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Constructor.sol';
import '../../genetics/interfaces/IMixGenes.sol';
import '../../randomness/IGetRandomNumber.sol';
import '../interfaces/IBreedHounds.sol';
import '../../gamification/interfaces/IInitializeHoundGamingStats.sol';
import '../../races/interfaces/IGetStatistics.sol';
import '../../gamification/interfaces/IGetStamina.sol';
import '../../gamification/interfaces/IGetBreeding.sol';
import './HoundIdentity.sol';


contract Params is Ownable {

    IncubatorConstructor.Struct public control;
    mapping(address => bool) public allowed;
    mapping(uint256 => HoundIdentity.Struct) public houndsIdentity;

    constructor(IncubatorConstructor.Struct memory input) {
        control = input;
        handleAllowedCallers(input.allowed);
    }
    
    function setGlobalParameters(IncubatorConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
        handleAllowedCallers(globalParameters.allowed);
    }

    function getIdentity(uint256 theId) external view returns(HoundIdentity.Struct memory) {
        return houndsIdentity[theId];
    }

    function setIdentity(uint256 theId, HoundIdentity.Struct memory identity) external {
        require(allowed[msg.sender]);
        houndsIdentity[theId] = identity;
    }

    function handleAllowedCallers(address[] memory allowedCallers) internal {
        for ( uint256 i = 0 ; i < allowedCallers.length ; ++i )
            allowed[allowedCallers[i]] = !allowed[allowedCallers[i]];
    }

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
pragma solidity 0.8.17;


library IncubatorConstructor {
    
    struct Struct {
        address methods;
        address randomness;
        address genetics;
        address gamification;
        address races;
        address[] allowed;
        uint32 secondsToMaturity;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IMixGenes {

    function mixGenes(uint32[54] calldata geneticSequence1, uint32[54] calldata geneticSequence2, uint256 randomness) external view returns(uint32[54] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IGetRandomNumber {

    function getRandomNumber(bytes memory input) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../hounds/params/Hound.sol';


interface IBreedHounds {

    function breedHounds(
        uint256 hound1Id, 
        HoundIdentity.Struct memory hound1, 
        uint256 hound2Id, 
        HoundIdentity.Struct memory hound2,
        uint256 onId
    ) external;

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IInitializeHoundGamingStats {

    function initializeHoundGamingStats(uint256 id, uint32[54] memory genetics) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/HoundStatistics.sol';


interface IGetStatistics {

    function getStatistics(uint256 theId) external view returns(HoundStatistics.Struct memory);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/HoundStamina.sol';


interface IGetStamina {

    function getStamina(uint256 id) external view returns(HoundStamina.Struct memory);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/HoundBreeding.sol';


interface IGetBreeding {

    function getBreeding(uint256 id) external view returns(HoundBreeding.Struct memory);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Specie.sol';

library HoundIdentity {

    struct Struct {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint256 birthDate;
        uint32[54] geneticSequence;
        string extensionTraits;
        Specie.Enum specie;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../incubator/params/HoundIdentity.sol';
import '../../gamification/params/HoundBreeding.sol';
import '../../gamification/params/HoundStamina.sol';
import '../../races/params/HoundStatistics.sol';
import './HoundProfile.sol';


library Hound {
    struct Struct {
        HoundStatistics.Struct statistics;
        HoundStamina.Struct stamina;
        HoundBreeding.Struct breeding;
        HoundIdentity.Struct identity;
        HoundProfile.Struct profile;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundBreeding {

    struct Struct {
        address breedingFeeCurrency;
        address breedingCooldownCurrency;
        uint256 lastBreed;
        uint256 breedingCooldown;
        uint256 breedingFee;
        uint256 breedingCooldownTimeUnit;
        uint256 refillBreedingCooldownCost;
        bool availableToBreed;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundStamina {

    struct Struct {
        address staminaRefillCurrency;
        uint256 staminaLastUpdate;
        uint256 staminaRefill1x;
        uint256 refillStaminaCooldownCost;
        uint32 staminaValue;
        uint32 staminaPerTimeUnit;
        uint32 staminaCap;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundStatistics {

    struct Struct {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library HoundProfile {
    struct Struct {
        string name;
        string token_uri;
        uint256 queueId;
        bool custom;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Specie {
    enum Enum {
        FREE_HOUND,
        NORMAL,
        CHAD,
        RACER,
        COMMUNITY,
        SPEC_OPS,
        PRIME
    }
}