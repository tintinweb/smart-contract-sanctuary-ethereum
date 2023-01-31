pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.5.0;

interface IMonolithRewardTokenHelper {

    function rewardTokenListLength() external view returns (uint256);

    function rewardTokenListItem(uint256 index) external view returns (address);

    function isRewardTokenEnabled(address rewardToken) external view returns (bool);

    function addRewardToken(address rewardToken) external;

    function removeRewardToken(address rewardToken) external;
}

pragma solidity =0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interfaces/IMonolithRewardTokenHelper.sol";

contract MonolithRewardTokenHelper is Ownable, IMonolithRewardTokenHelper {
    address[] rewardTokenList;
    mapping(address => bool) rewardTokenEnabled;

    function rewardTokenListLength() external view returns (uint256) {
        return rewardTokenList.length;
    }

    function rewardTokenListItem(uint256 index) external view returns (address) {
        return rewardTokenList[index];
    }

    function isRewardTokenEnabled(address rewardToken) external view returns (bool) {
        return rewardTokenEnabled[rewardToken];
    }

    function _addRewardToken(address rewardToken) private {
        require(!rewardTokenEnabled[rewardToken], "RewardTokenHelper: REWARD_TOKEN_ENABLED");

        rewardTokenEnabled[rewardToken] = true;
        rewardTokenList.push(rewardToken);
    }

    function addRewardToken(address rewardToken) external onlyOwner {
        _addRewardToken(rewardToken);
    }

    function _indexOfRewardToken(address rewardToken) private view returns (uint256 index) {
        uint256 count = rewardTokenList.length;
        for (uint256 i = 0; i < count; i++) {
            if (rewardTokenList[i] == rewardToken) {
                return i;
            }
        }
        require(false, "RewardTokenHelper: REWARD_TOKEN_NOT_FOUND");
    }

    function removeRewardToken(address rewardToken) external onlyOwner {
        require(rewardTokenEnabled[rewardToken], "RewardTokenHelper: REWARD_TOKEN_NOT_ENABLED");

        uint256 index = _indexOfRewardToken(rewardToken);
        address last = rewardTokenList[rewardTokenList.length - 1];
        rewardTokenList[index] = last;
        rewardTokenList.pop();
        delete rewardTokenEnabled[rewardToken];
    }
}