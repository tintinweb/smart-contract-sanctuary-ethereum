/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
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

    function stakedTokens(uint256 tokenid) external returns (StakedToken memory _stakedToken);
}

interface AcrocalypseTokenContract {
    function ownerOf(uint256 tokenid) external returns (address);
}

contract PaperDAONameResolver is Ownable {
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

    AcrocalypseStakingContract public stakingContract;
    AcrocalypseTokenContract public tokenContract;

    constructor(address tokenContractAddress, address stakingContractAddress) {
        stakingContract = AcrocalypseStakingContract(address(stakingContractAddress));
        tokenContract = AcrocalypseTokenContract(address(tokenContractAddress));
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function convert(bytes32 node) public pure returns (uint256) {
        //string memory tempString = bytes32ToString(node);
        return uint256(stringToUint(bytes32ToString(node)));
    }

    function addr(bytes32 node) external returns (address) {
        uint256 convertedNode = uint256(stringToUint(bytes32ToString(node)));
        address stakingOwner = stakingContract.stakedTokens(convertedNode).owner;

        if (address(stakingOwner) != address(0)) {
            return stakingOwner;
        }
        return tokenContract.ownerOf(convertedNode);
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

    function stringToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de;
    }
}