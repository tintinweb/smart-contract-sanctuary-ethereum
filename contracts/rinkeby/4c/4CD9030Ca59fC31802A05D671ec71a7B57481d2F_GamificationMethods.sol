//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract GamificationMethods is Params {

    constructor(Constructor.Struct memory input) Params(input) {}

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? b : a;
    }

    function initializeHoundGamingStats(uint256 onId, uint32[54] memory genetics) external {
        require(allowed[msg.sender]);
        houndsStamina[onId] = HoundStamina.Struct(
            control.defaultStamina.staminaRefillCurrency, // staminaRefillCurrency
            0, // staminaLastUpdate
            genetics[53] > 3 ? 
                control.defaultStamina.staminaRefill1x - ( control.defaultStamina.staminaRefill1x / 100 * genetics[53] ) 
            : 
                control.defaultStamina.staminaRefill1x + ( control.defaultStamina.staminaRefill1x / 100 * genetics[53] ), // staminaRefill1x
            genetics[50] >= 1 && genetics[50] <= 4 ? 
                    control.defaultStamina.refillStaminaCooldownCost - ( ( control.defaultStamina.refillStaminaCooldownCost / 100 ) * genetics[50] ) 
                :
                    control.defaultStamina.refillStaminaCooldownCost + ( ( control.defaultStamina.refillStaminaCooldownCost / 150 ) * genetics[50] ), // refillStaminaCooldownCost
            genetics[52] > 6 ? 
                control.defaultStamina.staminaValue + genetics[52] - 6 
            : 
                control.defaultStamina.staminaValue - genetics[52], // staminaValue
            genetics[51] == 9 ? control.defaultStamina.staminaPerTimeUnit / 2 : control.defaultStamina.staminaPerTimeUnit, // staminaPerHour
            genetics[50] > 6 ? 
                control.defaultStamina.staminaCap + ( ( genetics[50] - 6 ) * 5 ) 
            : 
                control.defaultStamina.staminaCap - genetics[50] // staminaCap
        );

        houndsBreeding[onId] = HoundBreeding.Struct(
            control.defaultBreeding.breedingFeeCurrency,
            control.defaultBreeding.breedingCooldownCurrency,
            0, // lastBreed
            genetics[1] == 1 ? 
                control.defaultBreeding.breedingCooldown - (
                    genetics[50] < 3 ? 
                        ( control.defaultBreeding.breedingCooldown / 100 ) * ( ( genetics[50] + 1 ) * 8 )
                    : 
                        0
                )
            : 
                control.defaultBreeding.breedingCooldown + (
                    genetics[50] < 3 ? 
                        ( control.defaultBreeding.breedingCooldown / 100 ) * ( ( genetics[50] + 1 ) * 8 )
                    : 
                        0
                ), // breedingCooldown
            0, // breedingFee,
            genetics[51] == 1 ? control.defaultBreeding.breedingCooldownTimeUnit / 2 : control.defaultBreeding.breedingCooldownTimeUnit, // breedingCooldownTimeUnit
            genetics[52] > 7 && genetics[52] <= 9 ? 
                control.defaultBreeding.refillBreedingCooldownCost - ( ( control.defaultBreeding.refillBreedingCooldownCost / 100 ) * genetics[52] )
            : 
                control.defaultBreeding.refillBreedingCooldownCost + ( ( control.defaultBreeding.refillBreedingCooldownCost / 150 ) * genetics[52] ), // refillBreedingCooldownCost
            false // availableToBreed
        );
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Constructor.sol';
import './HoundBreeding.sol';
import './HoundStamina.sol';


contract Params is Ownable {

    Constructor.Struct public control;
    mapping (address => bool) public allowed;
    mapping(uint256 => HoundStamina.Struct) public houndsStamina;
    mapping(uint256 => HoundBreeding.Struct) public houndsBreeding;

    constructor(Constructor.Struct memory input) {
        control = input;
        handleAllowedCallers(input.allowed);
    }

    function setGlobalParameters(Constructor.Struct memory globalParameters) external onlyOwner {
        handleAllowedCallers(globalParameters.allowed);
        control = globalParameters;
    }

    function handleAllowedCallers(address[] memory allowedCallers) internal {
        for ( uint256 i = 0 ; i < allowedCallers.length ; ++i )
            allowed[allowedCallers[i]] = !allowed[allowedCallers[i]];
    }

    function getStamina(uint256 id) external view returns(HoundStamina.Struct memory){
        return houndsStamina[id];
    }

    function getBreeding(uint256 id) external view returns(HoundBreeding.Struct memory){
        return houndsBreeding[id];
    }

    function getStaminaBreeding(uint256 id) external view returns(HoundStamina.Struct memory, HoundBreeding.Struct memory) {
        return (houndsStamina[id],houndsBreeding[id]);
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
import './HoundBreeding.sol';
import './HoundStamina.sol';

library Constructor {
    struct Struct {
        HoundBreeding.Struct defaultBreeding;
        HoundStamina.Struct defaultStamina;
        address[] allowed;
        address restricted;
        address methods;
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