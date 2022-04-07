// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import '../params/Index.sol';


contract IncubatorMethods is Params {

    constructor(IncubatorConstructor.Struct memory input) Params(input) {}

    function breedHounds(uint256 hound1Id, Hound.Struct memory hound1, uint256 hound2Id, Hound.Struct memory hound2) public view returns(Hound.Struct memory) {
        
        uint32[54] memory genetics = IGeneticsZerocost(control.genetics).mixGenes(
            hound1.identity.geneticSequence, 
            hound2.identity.geneticSequence,
            IRandomnessZerocost(control.randomness).getRandomNumber(
                abi.encode(hound1Id > hound2Id ? hound1.identity.geneticSequence : hound2.identity.geneticSequence)
            )
        );

        Statistics.Struct memory houndStatistics = Statistics.Struct(
            0,
            0,
            0,
            0    
        );

        Stamina.Struct memory stamina = Stamina.Struct(
            0,
            .1 ether,
            100,
            1,
            100
        );

        Breeding.Struct memory breeding = Breeding.Struct(
            control.secondsToMaturity, 
            .3 ether,
            0,
            false
        );

        Identity.Struct memory identity = Identity.Struct(
            hound1Id,
            hound2Id,
            hound1.identity.generation + hound2.identity.generation,
            block.timestamp,
            genetics // preferences will be extracted from this 
        );

        return Hound.Struct(
            houndStatistics,
            stamina,
            breeding,
            identity,
            "",
            "",
            false,
            false
        );
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../hounds/hound/Index.sol';
import './Constructor.sol';
import '../methods/IIndex.sol';
import '../../genetics/zerocost/IIndex.sol';
import '../../randomness/zerocost/IIndex.sol';


contract Params is Ownable {
    IncubatorConstructor.Struct public control;

    constructor(IncubatorConstructor.Struct memory input) {
        control = input;
    }
    
    function setGlobalParameters(IncubatorConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;
import './Statistics.sol';
import './Stamina.sol';
import './Breeding.sol';
import './Identity.sol';

library Hound {
    struct Struct {
        Statistics.Struct statistics;
        Stamina.Struct stamina;
        Breeding.Struct breeding;
        Identity.Struct identity;
        string title;
        string token_uri;
        bool custom;
        bool running;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


library IncubatorConstructor {
    
    struct Struct {
        address methods;
        address randomness;
        address genetics;
        uint256 secondsToMaturity;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import '../../hounds/hound/Index.sol';


interface IIncubatorMethods {

    function breedHounds(uint256 hound1Id, Hound.Struct memory hound1, uint256 hound2Id, Hound.Struct memory hound2) external view returns(Hound.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IGeneticsZerocost {

    function wholeArithmeticRecombination(uint32[54] memory geneticSequence1, uint32[54] memory geneticSequence2) external view returns(uint32[54] memory geneticSequence);

    function swapMutation(uint32[54] memory geneticSequence, uint256 randomness) external view returns(uint32[54] memory);

    function inversionMutation(uint32[54] memory geneticSequence, uint256 randomness) external view returns(uint32[54] memory);

    function scrambleMutation(uint32[54] memory geneticSequence, uint256 randomness) external view returns(uint32[54] memory);
    
    function arithmeticMutation(uint32[54] memory geneticSequence, uint256 randomness) external view returns(uint32[54] memory);

    function uniformCrossover(uint32[54] calldata geneticSequence1, uint32[54] calldata geneticSequence2, uint256 randomness) external view returns(uint32[54] memory geneticSequence);

    function mixGenes(uint32[54] calldata geneticSequence1, uint32[54] calldata geneticSequence2, uint256 randomness) external view returns(uint32[54] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IRandomnessZerocost {

    function getRandomNumber(bytes memory input) external view returns(uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;

library Statistics {
    struct Struct {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;

library Stamina {
    struct Struct {
        uint256 staminaLastUpdate;
        uint256 staminaRefill1x;
        uint32 staminaValue;
        uint32 staminaPerHour;
        uint32 staminaCap;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;

library Breeding {
    struct Struct {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 breedLastUpdate;
        bool availableToBreed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;

library Identity {
    struct Struct {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint256 birthDate;
        uint32[54] geneticSequence;
    }
}