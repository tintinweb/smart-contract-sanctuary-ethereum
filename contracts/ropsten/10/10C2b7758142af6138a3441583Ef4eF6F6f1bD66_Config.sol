// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Global Configuration Contract
 */
contract Config is Ownable {

    // Arbitrary contract designation signature
    string public constant role = "SuperTrueConfig";

    //-- Storage --//
    //Treasury
    uint256 private _treasuryFee;
    address private _treasury;
    //Admin
    mapping(address => bool) private _admins;   //Admins of this contract
    //URI
    string private _baseURI;
    //Signers addresses
    address private _signer1;
    address private _signer2;

    //-- Events --//
    event TreasurySet(address treasury);
    event TreasuryFeeSet(uint256 treasuryFee);
    event AdminAdded(address admin);
    event AdminRemoved(address admin);
    event SignersSet(address signer1, address signer2);

    //-- Modifiers --//

    /**
     * @dev Throws if called by any account other than the owner or admins.
     */
    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || isAdmin(_msgSender()), "Only admin or owner");
        _;
    }

    //-- Methods --//


    constructor() {
        //Default Base URI
        _baseURI = "https://us-central1-supertrue-5bc93.cloudfunctions.net/api/artist/";
        //Default Treasury Fee
        _treasuryFee = 2000;  //20%
        //Init Signers
        _signer1 = 0x8eC13C4982a5Fb8b914F0927C358E14f8d657133;
        _signer2 = 0xb9fAfb1De9083eAa09Fd7D058784a0316a2960B1;
    }

    /**
     * @dev Get Signers Storage Contract Address
     */
    function signer1() public view returns (address) {
        return _signer1;
    }

    /**
     * @dev Get Signers Storage Contract Address
     */
    function signer2() public view returns (address) {
        return _signer2;
    }

    /**
     * @dev Set Signers Storage Contract Address
     */
    function setSigners(address signer1_, address signer2_) public onlyOwner {
        _signer1 = signer1_;
        _signer2 = signer2_;
        emit SignersSet(signer1_, signer2_);
    }

    //-- Treasury
    /**
     * @dev Fetch Treasury Data
     */
    function getTreasuryData() public view returns (address, uint256) {
        return (_treasury, _treasuryFee);
    }

    /**
     * @dev Set Treasury Address
     */
    function setTreasury(address newTreasury) public onlyOwner {
        // if (newTreasury == address(0)) revert Errors.InitParamsInvalid();
        // address prevTreasury = _treasury;
        _treasury = newTreasury;
        emit TreasurySet(newTreasury);
    }

    /**
     * @dev Set Treasury Fee
     */
    function setTreasuryFee(uint256 newTreasuryFee) public onlyOwner {
        // if (newTreasuryFee >= BPS_MAX / 2) revert Errors.InitParamsInvalid();
        // uint256 prevTreasuryFee = _treasuryFee;
        _treasuryFee = newTreasuryFee;
        emit TreasuryFeeSet(newTreasuryFee);
    }

    //-- Admin Management

    /**
    * @dev enables an address for only admin functions
    * @param admin the address to enable
    */
    function addAdmin(address admin) external onlyOwner {
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    /**
    * @dev disables an address for only admin functions
    * @param admin the address to disbale
    */
    function removeAdmin(address admin) external onlyOwner {
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    /**
     * @dev Function to check if address is admin
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    /**
     * @dev Set Protocol's Base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwnerOrAdmin {
        _baseURI = baseURI_;
    }

    /**
     * @dev Fetch Base URI
     */
    function getBaseURI() external view returns (string memory) {
        return _baseURI;
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