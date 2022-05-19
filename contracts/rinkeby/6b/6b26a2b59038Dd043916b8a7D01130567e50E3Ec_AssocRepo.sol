//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IAssocRepo.sol";

/**
 * @title Open Association Retention
 * @dev Association Repository -- Retains Association Data for Other Contracts
 */
contract AssocRepo is IAssocRepo, Context, ERC165 {

    //--- Storage
    
    //Arbitrary Contract Name & Symbol 
    string public constant symbol = "ASSOC";
    string public constant name = "Open Association Repository";
    
    //Associations by Contract Address
    mapping(address => mapping(string => address)) internal _assoc;
    
    //--- Functions

    // constructor() { }

    /** 
     * Set Association
     * @dev Set association to another contract
     */
    function setAssoc(string memory key, address destinationContract) external override {
        _assoc[_msgSender()][key] = destinationContract;
        //Association Changed Event
        emit Assoc(_msgSender(), key, destinationContract);
    }

    /** 
     * Get Association
     * @dev Get association to another contract
     */
    function getAssoc(string memory key) external view override returns(address) {
        address originContract = _msgSender();
        //Validate
        // require(_assoc[originContract][key] != address(0) , string(abi.encodePacked("Assoc:Faild to Get Assoc: ", key)));
        return _assoc[originContract][key];
    }

    /** 
     * Set Contract Association 
     * @dev Set association of a specified contract to another contract
     */
    function getAssocOf(address originContract, string memory key) external view override returns(address) {
        //Validate
        require(_assoc[originContract][key] != address(0) , string(abi.encodePacked("Faild to Find Assoc: ", key)));
        return _assoc[originContract][key];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IAssocRepo {
    
    //--- Functions

    /// Set  Association
    function setAssoc(string memory key, address destinationContract) external;

    /// Get Association
    function getAssoc(string memory key) external view returns(address);

    /// Get Contract Association
    function getAssocOf(address originContract, string memory key) external view returns(address);

    //--- Events

    /// Association Set
    event Assoc(address originContract, string key, address destinationContract);

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