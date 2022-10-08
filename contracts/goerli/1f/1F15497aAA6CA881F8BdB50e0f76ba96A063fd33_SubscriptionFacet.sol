//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 *
 * @author Matias Arazi <[email protected]> , Lucas Martín Grasso Ramos <[email protected]>
 *
 */

import "../interfaces/ERC20/IERC20.sol";
import "../interfaces/ISubscription.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibSubscription } from  "../libraries/LibSubscription.sol";
import { LibSubscriptionStructs } from  "../libraries/LibSubscriptionStructs.sol";

contract SubscriptionFacet is ISubscription{
    address private constant TOKEN_ADDRESS = address(0xFd6CB3CB3cE04c579f35BF5Bd12Ee09141C536EB);
    IERC20 public ZetToken = IERC20(TOKEN_ADDRESS);

    function getPlan(uint256 id) external override view returns (LibSubscriptionStructs.Plan memory) {
        return LibSubscription.getPlan(id);
    }

    function isSubscribed(address account) external override view returns(bool, LibSubscriptionStructs.Plan memory) {
        LibSubscriptionStructs.Subscription memory sub = LibSubscription.getSubcription(account);
        if (sub.endTime > block.timestamp) {
            return (true, LibSubscription.getPlan(sub.planId));
        }
        return (false, LibSubscriptionStructs.Plan(0, "", 0, 0));
    }

    function isSubscribedBatch(address[] calldata accounts) external override view returns(bool[] memory, LibSubscriptionStructs.Plan[] memory) {
        bool[] memory subs = new bool[](accounts.length);
        LibSubscriptionStructs.Plan[] memory plans = new LibSubscriptionStructs.Plan[](accounts.length);
        for (uint256 i = 0; i < accounts.length;){
            LibSubscriptionStructs.Subscription memory sub = LibSubscription.getSubcription(accounts[i]);
            if (sub.endTime > block.timestamp) {
                subs[i] = true;
                plans[i] = LibSubscription.getPlan(sub.planId);
            }
            else {
                subs[i] = false;
                plans[i] = LibSubscriptionStructs.Plan(0, "", 0, 0);
            }
            unchecked {
                ++i;
            }
        }
        return (subs, plans);
    }

    function subscribe (uint256 id) external override {
        require(ZetToken.allowance(msg.sender, address(this)) >= LibSubscription.getPlan(id).cost, "Subscription: Insufficient allowance");
        LibSubscription.subscribe(id);
    }

    function createPlan(string memory name, uint256 cost, uint256 duration) external override {
        LibDiamond.enforceIsContractOwner();
        LibSubscription.createPlan(name, cost, duration);
    }

    function deletePlan(uint256 id) external override {
        LibDiamond.enforceIsContractOwner();
        LibSubscription.deletePlan(id);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


/**
 *
 * @author Matias Arazi <[email protected]> , Lucas Martín Grasso Ramos <[email protected]>
 *
 */

import { LibSubscriptionStructs } from  "../libraries/LibSubscriptionStructs.sol";

interface ISubscription {

    /**
     * @dev Returns the plan with the given id
     * @param id The id of the plan
     * @return The plan with the given id
     */
    function getPlan(uint256 id) external view returns (LibSubscriptionStructs.Plan memory);

    /**
     * @dev Returns if the given account is subscribed and the plan of the subscription
     * @param account The account to check
     * @return If the given account is subscribed and the plan of the subscription
     */
    function isSubscribed(address account) external view returns(bool, LibSubscriptionStructs.Plan memory);

    /**
     * @dev Returns if the given accounts are subscribed and the plan of the subscription
     * @param accounts The accounts to check
     * @return If the given accounts are subscribed and the plan of the subscription
     */
    function isSubscribedBatch(address[] calldata accounts) external view returns(bool[] memory, LibSubscriptionStructs.Plan[] memory);

    /**
     * @dev Subscribes the sender to the plan with the given id
     * @param id The id of the plan to subscribe to
     */
    function subscribe (uint256 id) external;

    /**
     * @dev Creates a new plan
     * @param name The name of the plan
     * @param cost The cost of the plan
     * @param duration The duration of the plan
     */
    function createPlan(string memory name, uint256 cost, uint256 duration) external;

    /**
     * @dev Deletes the plan with the given id
     * @param id The id of the plan to delete
     */
    function deletePlan(uint256 id) external ;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }        
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);                
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }            
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }
            
            
            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }        
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }        
    }
}

//SPDX-License-Identifier: MIT

/**
 * @notice Library for Subcription facets
 * @author Lucas Martín Grasso Ramos <[email protected]>
 *
 */

pragma solidity >=0.8.9;

import { LibSubscriptionStructs } from "./LibSubscriptionStructs.sol";

library LibSubscription {
    bytes32 internal constant SUBSCRIPTION_STORAGE_POSITION =
        keccak256("subscription.facet.storage");

    event PlanUpdated(LibSubscriptionStructs.Plan, uint256 indexed id, bool action);
    event UserSubscription(address indexed account, LibSubscriptionStructs.Subscription);

    struct SubscriptionStorage {
        uint256 nonce;
        mapping(uint256 => LibSubscriptionStructs.Plan) plans;
        mapping(address => LibSubscriptionStructs.Subscription) subscriptions;
    }

    function diamondStorage()
        internal
        pure
        returns (SubscriptionStorage storage ds)
    {
        bytes32 position = SUBSCRIPTION_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getPlan(uint256 id) internal view returns (LibSubscriptionStructs.Plan memory) {
        SubscriptionStorage storage ds = diamondStorage();
        return ds.plans[id];
    }

    function getSubcription(address account)
        internal
        view
        returns (LibSubscriptionStructs.Subscription memory)
    {
        SubscriptionStorage storage ds = diamondStorage();
        return ds.subscriptions[account];
    }

    function createPlan(
        string memory name,
        uint256 cost,
        uint256 duration
    ) internal {
        SubscriptionStorage storage ds = diamondStorage();
        LibSubscriptionStructs.Plan memory newPlan = LibSubscriptionStructs.Plan(ds.nonce, name, cost, duration);
        ds.plans[ds.nonce] = newPlan;
        emit PlanUpdated(newPlan, ds.nonce, true);
        ds.nonce++;
    }

    function deletePlan(uint256 id) internal {
        SubscriptionStorage storage ds = diamondStorage();
        emit PlanUpdated(ds.plans[id], id, false);
        delete ds.plans[id];
    }

    function subscribe (uint256 id) internal {
        SubscriptionStorage storage ds = diamondStorage();
        LibSubscriptionStructs.Plan memory plan = ds.plans[id];
        LibSubscriptionStructs.Subscription memory userSubscription = LibSubscriptionStructs.Subscription(
            plan.id,
            block.timestamp,
            block.timestamp + plan.duration
        );

        ds.subscriptions[msg.sender] = userSubscription;

        emit UserSubscription(msg.sender, userSubscription);
    }

}

//SPDX-License-Identifier: MIT

/**
 * @notice Library for Subcription Structs
 * @author Lucas Martín Grasso Ramos <[email protected]>
 *
 */

pragma solidity >=0.8.9;

library LibSubscriptionStructs { 
    struct Plan {
        uint256 id;
        string name;
        uint256 cost;
        uint256 duration;
    }

    struct Subscription {
        uint256 planId;
        uint256 startTime;
        uint256 endTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;    
}