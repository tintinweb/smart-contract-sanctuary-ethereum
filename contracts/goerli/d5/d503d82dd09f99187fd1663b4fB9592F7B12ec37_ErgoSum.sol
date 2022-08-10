// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMercenaries.sol";

/**
 * Nomen habeo ergo sum
 * @author 0xPanku
 */
contract ErgoSum is Ownable {

    // Maximum name size
    uint256 private nc_maxLength;

    // The price to perform the glorify action in gwei
    uint256 private nc_price;

    // ERC20 token payment address
    address private nc_erc20Address;

    // Mapping if certain name has already been reserved
    mapping(bytes32 => bool) private nc_nameReserved;

    address private mercenaries;

    event Nomen_est_omen (uint256 indexed tokenId, string newName, string oldName);

    constructor(address _mercenariesContract, address _erc20Addr, uint256 _price, uint256 _maxLength) {
        mercenaries = _mercenariesContract;
        nc_erc20Address = _erc20Addr;
        nc_price = _price;
        nc_maxLength = _maxLength;
    }

    //--------------------------------------------------------------------------------------------//
    // GETTER & SETTER
    //--------------------------------------------------------------------------------------------//

    /**
     * @dev Get price to change name.
     */
    function getPrice() external view returns (uint256) {
        return nc_price;
    }

    /**
     * @dev Update price to change name.
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        nc_price = _newPrice;
    }

    /**
     * @dev Get the size max of the name sting.
     */
    function getMaxLength() external view returns (uint256) {
        return nc_maxLength;
    }

    /**
     * @dev Set the size max of the name sting.
     */
    function setMaxLength(uint256 _newSize) external onlyOwner {
        nc_maxLength = _newSize;
    }

    /**
     * @dev Get ERC20 token payment address
     */
    function getErc20Addr() external view returns (address) {
        return nc_erc20Address;
    }

    /**
     * @dev Set the ERC20 Token payment
     */
    function setErc20Addr(address _newAddress) external onlyOwner {
        nc_erc20Address = _newAddress;
    }

    //--------------------------------------------------------------------------------------------//
    // UTILS
    //--------------------------------------------------------------------------------------------//

    /**
    * @dev Returns if the name is reserved (true) or if available (false).
    */
    function isNameReserved(string memory _needle) public view returns (bool) {
        return nc_nameReserved[keccak256(abi.encode(_needle))];
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory _str) public view returns (bool){

        bytes memory b = bytes(_str);

        if (b.length < 1) return false;
        if (b.length > nc_maxLength) return false;

        if (b[0] == 0x20) return false;
        // Leading space
        if (b[b.length - 1] == 0x20) return false;
        // Trailing space

        bytes1 lastChar = b[0];

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false;
            // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
            // !(char >= 0x41 && char <= 0x5A) && //A-Z  so no need for a tolower function
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    //--------------------------------------------------------------------------------------------//
    // CHANGE NAME
    //--------------------------------------------------------------------------------------------//

    /**
     * @notice call validate and isNameReserved on the frontend before to call this function.
     * @dev Changes the name for tokenId
     * Emit Nomen_est_omen if successful
     */
    function glorify(uint256 _tokenId, string memory _newName) public {
        require(msg.sender == mercenaries, "403");
        require(validateName(_newName), "Invalid name");
        require(!isNameReserved(_newName), "Reserved name");

        IMercenaries freeCompany = IMercenaries(mercenaries);
        string memory oldName = freeCompany.getName(_tokenId);

        if (bytes(oldName).length > 0) {
            nc_nameReserved[keccak256(abi.encode(oldName))] = false;
        }

        nc_nameReserved[keccak256(abi.encode(_newName))] = true;
        freeCompany.setName(_tokenId, _newName);

        emit Nomen_est_omen(_tokenId, _newName, oldName);
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
pragma solidity ^0.8.4;

interface IMercenaries{
    function getName(uint256 _tokenId) external view returns (string memory);

    function setName(uint256 _tokenId, string memory _value) external;
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