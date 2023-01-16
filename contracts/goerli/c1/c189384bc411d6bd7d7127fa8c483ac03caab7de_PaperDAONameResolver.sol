/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PaperDAONameResolver.sol


pragma solidity ^0.8.17;



interface AcrocalypseStakingContract {
    struct StakedToken {
        address owner;
        uint256 tokenId;
        uint256 stakePool;
        uint256 rewardsPerDay;
        uint256 pool1RewardsPerDay;
        uint256 creationTime;
        uint256 lockedUntilTime;
        uint256 lastClaimTime;
    }

    function stakedTokens(uint256 tokenid) external view returns (StakedToken memory);
}

interface AcrocalypseTokenContract {
    function ownerOf(uint256 tokenid) external view returns (address);
}

contract PaperDAONameResolver is ERC165, Ownable {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;
    bytes contentHash;

    AcrocalypseStakingContract public stakingContract;
    AcrocalypseTokenContract public tokenContract;

    constructor(address tokenContractAddress, address stakingContractAddress) {
        stakingContract = AcrocalypseStakingContract(address(stakingContractAddress));
        tokenContract = AcrocalypseTokenContract(address(tokenContractAddress));
    }

    function _addr(bytes32 node) internal view returns (address) {
        uint256 convertedNode = uint256(stringToUint(bytes32ToString(node)));
        address stakingOwner = stakingContract.stakedTokens(convertedNode).owner;

        if (address(stakingOwner) != address(0)) {
            return stakingOwner;
        }
        return tokenContract.ownerOf(convertedNode);
    }

    function addressToBytes(address _address) internal pure returns (bytes memory _bytes) {
        _bytes = new bytes(20);
        assembly {
            mstore(add(_bytes, 32), mul(_address, exp(256, 12)))
        }
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function addr(bytes32 node) external view returns (address) {
        return _addr(node);
    }

    function addr(bytes32 node, uint256 coinType) public view returns (bytes memory) {
        return addressToBytes(_addr(node));
    }

    function contenthash(bytes32 node) external view returns (bytes memory) {
        return contentHash;
    }

    function setContentHash(bytes calldata hash) external onlyOwner {
        contentHash = hash;
    }

    function setStakingContractAddress(address newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            stakingContract = AcrocalypseStakingContract(newAddress);
        }
    }

    function setTokenContractAddress(address newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            tokenContract = AcrocalypseTokenContract(newAddress);
        }
    }

    function stringToUint(string memory _string) internal pure returns (uint) {
        bytes memory _bytes = bytes(_string);
        uint result = 0;
        for (uint256 i = 0; i < _bytes.length; i++) {
            uint256 c = uint256(uint8(_bytes[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID || interfaceID == CONTENT_HASH_INTERFACE_ID;
    }
}