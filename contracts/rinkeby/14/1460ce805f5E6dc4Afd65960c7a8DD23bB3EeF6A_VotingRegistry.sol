//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IVoteContract} from "../voteContract/IVoteContract.sol";
import {IVotingRegistry} from "./IVotingRegistry.sol";

error AlreadyRegistered(address contractSeekingRegistration);
error notInterfaceImplementer(address contractSeekingRegistration);
error InvalidVoteContractSelector(IVoteContract voteContractSelector);
error NotRegistered(address notRegisteredContract);

abstract contract Categories {

    bytes4[] internal registeredCategories;
    mapping(bytes4=>uint256[]) internal registrationsInCategory;
    mapping(address=>bytes4[]) internal categoriesOfRegistration;

    function getRegisteredCategory(uint256 index) 
    external 
    view 
    returns(bytes4)
    {
        return registeredCategories[index];
    }

    function getNumberOfRegisteredCategories() 
    external 
    view 
    returns(uint256)
    {
        return registeredCategories.length;
    }


    function getNumberOfRegistrationsInCategory(bytes4 _category) 
    external 
    view 
    returns(uint256)
    {
        return registrationsInCategory[_category].length;
    }

    function getCategoriesOfRegistration(address registeredContract) 
    external 
    view 
    returns(bytes4[] memory)
    {
        return categoriesOfRegistration[registeredContract];
    }

    function _addCategory(uint256 index, bytes4 _category)
    internal
    {
        if(registrationsInCategory[_category].length==0){
            registeredCategories.push(_category);
        }
        categoriesOfRegistration[msg.sender].push(_category);
        registrationsInCategory[_category].push(index);
    }

    function _setCategories(uint256 index, bytes4[] memory _categories)
    internal
    {
        for (uint256 j; j<_categories.length; j++){
            _addCategory(index, _categories[j]);
        }
    }

    function _addCategories(uint256 index, bytes4[] memory _categories)
    internal
    {
        for (uint256 j; j<_categories.length; j++){
            bool exists = false;
            for (uint256 i; i<categoriesOfRegistration[msg.sender].length; i++){
                if (categoriesOfRegistration[msg.sender][i]==_categories[j]) {
                    exists = true;
                    break;
                }
            }
            if (!exists){
                _addCategory(index, _categories[j]);
            }
        }
    }
    
}

abstract contract Registration is Categories {

    // mapping(address=>bool) internal _alreadyRegistered;
    mapping(uint256=>IVoteContract) public voteContract;
    mapping(address=>uint256) public reverseRegistry;
    uint256 public numberOfRegisteredVoteContracts;

    function _register() 
    internal 
    returns (uint256)
    {
        numberOfRegisteredVoteContracts += 1;
        voteContract[numberOfRegisteredVoteContracts] = IVoteContract(msg.sender);
        reverseRegistry[msg.sender] = numberOfRegisteredVoteContracts;
        return numberOfRegisteredVoteContracts;
    }

    function _registerWithCategories(bytes4[] memory _categories) 
    internal 
    returns (uint256 index)
    {        
        index = _register();
        _setCategories(index, _categories);


    }

    function _implementsInterface()
    internal 
    view 
    returns(bool) {
        //TODO: add ERC176 or whatever it is.
        return IERC165(msg.sender).supportsInterface(type(IVoteContract).interfaceId);
    }

    modifier isRegistered {
        if (reverseRegistry[msg.sender]!=0){
            revert NotRegistered(msg.sender);
        }
        _;
    }

    modifier registrationReentrancyGuard {
        if (reverseRegistry[msg.sender]==0){
            revert AlreadyRegistered(msg.sender);
        }
        _;
    }

    modifier isInterfaceImplementer {
        if (!_implementsInterface()){
            revert notInterfaceImplementer(msg.sender);
        }
        _;
    }

   
}

contract VotingRegistry is Registration {
    
    function register()
    external 
    isInterfaceImplementer
    registrationReentrancyGuard
    returns (uint256)
    {
        return _register();
    }

    function register(bytes4[] memory categories) 
    external 
    isInterfaceImplementer
    registrationReentrancyGuard
    returns (uint256)
    {
        return _registerWithCategories(categories);
    }

    function addCategories(bytes4[] memory categories) 
    external 
    isRegistered
    isInterfaceImplementer
    {
        _addCategories(reverseRegistry[msg.sender], categories);
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;



interface IVoteContract {
    function start(bytes memory votingParams) external; 

    function stop() external;

    // function parseParameters(bytes memory votingParams) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IVoteContract} from "../voteContract/IVoteContract.sol";


// TODO should be deployed always to the same address!
// TODO: Use the same trick as ERC1860 or whatever the global registry is called.
address constant VotingRegistryAddress = 0x0000000000000000000000000000000000000000;


interface IVotingRegistry {

    function register() external;

    function getVoteContract(bytes4 selector) external returns(IVoteContract voteContract);
}