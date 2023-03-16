//SPDX-License-Identifier: MIT
pragma solidity ~0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool active);

    function setController(address controller, bool active) public onlyOwner {
        controllers[controller] = active;
        emit ControllerChanged(controller, active);
    }

    modifier onlyController() {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IXAPRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes32 indexed name, uint chainId);

    function setApprovalForAll(address operator) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function approve(bytes32 name, address delegate) external;

    function isApprovedFor(address owner, bytes32 name, address delegate) external view returns (bool);

    function register(bytes32 name, address _owner, uint256 chainId, address _address) external;

    function registerWithData(bytes32 name, address _owner, uint96 accountData, uint256 chainId, address _address, uint96 addressData) external;

    function registerAddress(bytes32 name, uint256 chainId, address _address) external;

    function registerAddressWithData(bytes32 name, uint256 chainId, address _address, uint96 addressData) external;

    function setOwner(bytes32 name, address _address) external;

    function setAccountData(bytes32 name, uint96 accountData) external;

    function resolveAddress(bytes32 name, uint256 chainId) external view returns (address);

    function resolveAddressWithData(bytes32 name, uint256 chainId) external view returns (address, uint96);

    function getOwner(bytes32 name) external view returns (address);

    function getOwnerWithData(bytes32 name) external view returns (address, uint96);

    function available(bytes32 name) external view returns (bool);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Controllable} from "./Controllable.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error Unauthorized(bytes32 name);
error NotAvailable(bytes32 name);
error AccountImmutable(bytes32 name, uint256 chainId, address account);
error CannotSetOwnerToZeroAddress();
error MustHaveNonZeroAddress();
error ImmutableRecord(bytes32 name, uint256 chainId, uint96 addressData);
error CannotDelegateToSelf();

contract XAPRegistry is IXAPRegistry, ERC165, Controllable {

    struct Record {

        uint256 owner;
        // A mapping of chain ids to addresses and data (stored as a single uint256). 
        mapping(uint256 chainId => uint256 addressAndData) addresses;

    }

    /**
     * A mapping of names to records.
     */
    mapping(bytes32 name => Record record) records;

    /**
     * A mapping of operators. An address that is authorized for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     */
    mapping(address owner => address operator) private _operatorApprovals;

    /**
     * A mapping of delegates. The delegate that is set by an owner
     * for a name may make changes to the name's resolver, but may not update
     * the set of token approvals.
     */
    mapping(address owner => mapping(bytes32 name => address delegate)) private _tokenApprovals; 

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator
    );

    // Logged when a delegate is approved or  an approval is revoked.
    event Approved(
        address owner,
        bytes32 indexed name,
        address indexed delegate
    );

    /**
     * @dev Allows for approving a single operator.
     */
    function setApprovalForAll(address operator) external {

        if(msg.sender == operator){
            revert CannotDelegateToSelf();         
        }

        _operatorApprovals[msg.sender] = operator;
        emit ApprovalForAll(msg.sender, operator);
    }

    /**
     * @dev Check to see if the operator is approved for all.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account] == operator;
    }

    /**
     * @dev Approve a delegate to be able to updated records on a name.
     */
    function approve(bytes32 name, address delegate) external {

        if(msg.sender == delegate){
            revert CannotDelegateToSelf();         
        }

        _tokenApprovals[msg.sender][name] = delegate;
        emit Approved(msg.sender, name, delegate);
    }

    /**
     * @dev Check to see if the delegate has been approved by the owner for the name.
     */
    function isApprovedFor(address owner, bytes32 name, address delegate)
        public
        view
        returns (bool)
    {
        return _tokenApprovals[owner][name] == delegate;
    }


    /**
    * @dev The function registers a name with the owner address.
    * @param name The name to be registered.
    * @param _owner The account to be registered as the owner of the name.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The resolved account for a specific chainId.
     */

    function register(
        bytes32 name, 
        address _owner, 
        uint256 chainId, 
        address _address
    ) external onlyController{

        // Check to make sure the name has not already been registered. 
        (address oldOwner, ) = _decodeData(records[name].owner); 
        if (oldOwner != address(0)){
            revert NotAvailable(name);
        }

        records[name].owner = _packData(_owner, 0);
        records[name].addresses[chainId] = _packData(_address, 0);

    }
    /**
    * @dev The function registers a name with the owner address.
    * @param name The name to be registered.
    * @param _owner The account to be registered as the owner of the name.
    * @param accountData The aux data of the owner delegate.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The resolved account for a specific chainId.
    * @param addressData The aux data of the address delegate.
     */

    function registerWithData(
        bytes32 name, 
        address _owner, 
        uint96 accountData, 
        uint256 chainId, 
        address _address,
        uint96 addressData 
    ) external onlyController{

        // Check to make sure the name has not already been registered. 
        (address oldOwner, ) = _decodeData(records[name].owner); 
        if (oldOwner != address(0)){
            revert NotAvailable(name);
        }

        records[name].owner = _packData(_owner, accountData);
        records[name].addresses[chainId] = _packData(_address, addressData);

    }

    /**
    * @dev The function registers an address with a name on the specified chain.
    * @param name The name to be registered.
    * @param chainId The chainId on which the address will be registered.
    * @param _address The account to be registered with the name.
    */ 
    function registerAddress(bytes32 name, uint256 chainId, address _address) external onlyAuthorized(name){

        // Make sure the address is not set. Accounts are immutable. 
        address account = resolveAddress(name, chainId);
        if( account != address(0)){
            revert AccountImmutable(name, chainId, account);
        }
        records[name].addresses[chainId] = _packData(_address, 0);

    }

    /**
    * @dev The function registers an address with a name on the specified chain.
    * @param name The name to be registered.
    * @param chainId The chainId on which the address will be registered.
    * @param _address The account to be registered with the name.
    * @param addressData The auxiliary data of the address.
    */ 
    function registerAddressWithData(
        bytes32 name, 
        uint256 chainId, 
        address _address,
        uint96 addressData
    ) external onlyAuthorized(name){

        // Make sure the address is not set. Account addresses are immutable.

        address account = resolveAddress(name, chainId);
        if( account != address(0)){
            revert AccountImmutable(name, chainId, account);
        }
        records[name].addresses[chainId] = 
            _packData(_address, addressData);

    }

    /**
    * @dev The function sets the owner of a name.
    * @param name The name for which the owner will be set.
    * @param _address The address to be set as the owner of the name.
    */    

    function setOwner(bytes32 name, address _address) external onlyAuthorized(name){

        // Make sure the address is not the zero address.
        if (_address == address(0)){
            revert CannotSetOwnerToZeroAddress();
        }

        // Retrieve the accountData.
        (, uint96 accountData) = _decodeData(records[name].owner);
        records[name].owner = _packData(_address, accountData);

    }

    /**
    * @dev The function sets the account data.
    * @param name The name for which the owner will be set.
    * @param data The auxiliary data of the account.
    */    

    function setAccountData(bytes32 name, uint96 data) external onlyAuthorized(name){

        //Retrive the owner address.
        (address _address, ) = _decodeData(records[name].owner);
        records[name].owner = _packData(_address, data);

    }
    
    /**
    * @dev The function resolves an address associated with a name on a specific chain.
    * @param name The name for which the address will be resolved.
    * @param chainId The chainId on which the address is registered.
    * @return The account associated with the name on the specified chain.
    */

    function resolveAddress(bytes32 name, uint256 chainId) public view returns (address){

        // resolve the address and return the account.
        // Note: if the address is not set the account will be the zero address.
        (address account, ) = _decodeData(records[name].addresses[chainId]);
        return account;

    }

    /**
    * @dev The function resolves an address associated with a name on a specific chain.
    * @param name The name for which the address will be resolved.
    * @param chainId The chainId on which the address is registered.
    * @return The account and auxiliary data associated with the name on the specified chain.
    */

    function resolveAddressWithData(
        bytes32 name, 
        uint256 chainId
    ) public view returns (address, uint96){

        // resolve the address and return the account with auxiliary data.
        // Note: If the address is not set the account and auxiliary data will be the zero address and value zero.
        return _decodeData(records[name].addresses[chainId]);

    }

    /**
    * @dev The function returns the owner of a name.
    * @param name The name for which the owner will be returned.
    * @return The owner of the name.
    */

    function getOwner(bytes32 name) public view returns (address){

        // Note: If the name has not been registered the owner will be the zero address.
        (address _owner, ) = _decodeData(records[name].owner); 
        return _owner;

    }

    /**
    * @dev The function returns the owner of a name with auxiliary data.
    * @param name The name for which the owner will be returned.
    * @return The owner of the name, and auxiliary data.
    */

    function getOwnerWithData(bytes32 name) public view returns (address, uint96){

        return _decodeData(records[name].owner);  

    }

    /**
    * @dev The function checks if a name is available for registration.
    * @param name The name to check availability for.
    * @return Boolean indicating whether the name is available for registration.
    */

    function available(bytes32 name) external view returns (bool){

        (address _owner, ) = _decodeData(records[name].owner); 
        return _owner == address(0);

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IXAPRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //Check whether the sender is authorized to access the function.
    modifier onlyAuthorized(bytes32 name){

        if (isAuthorized(name)){
            revert Unauthorized(name);
        }
        _;

    }

    function isAuthorized(bytes32 name) internal view  returns (bool) {

        address owner = getOwner(name);

        return owner == msg.sender || isApprovedForAll(owner, msg.sender) || 
            isApprovedFor(owner, name, msg.sender);
    }


    // Decode the data that is stored in a token. 
    // The first 160 bits of data is the token owner's address.
    // The last 96 bits of data is the token's auxdata.

    function _decodeData(uint256 data)
        internal
        pure
        returns (
            address account,
            uint96 auxData
        )
    {
        // Get the owner from the token id. 
        account = address(uint160(data));

        // Get the aux data out of the token value.
        auxData = uint96(data >> 160);
    }

    function _packData(
        address account,
        uint96 auxData
    ) internal pure returns (uint256 data) {
        data = uint256(uint160(account)) |
            uint256(auxData) << 160;
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