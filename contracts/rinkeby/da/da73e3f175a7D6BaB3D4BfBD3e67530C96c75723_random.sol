// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IRNG.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface requestor {
    function process(uint256 rand, bytes32 requestId) external;
}

contract random is IRNG , Ownable{
    
    uint public next = 0;

    mapping(bytes32 => uint256) responses;
    mapping(bytes32 => bool) responded;
    mapping(uint256=>address)   public callbacks;
    


    event Request(uint number);
    event RandomReceived(uint requestId,uint rand);

    function requestRandomNumber() external override returns (bytes32 requestId) {
        emit Request(next);
        return bytes32(next++);
    }

    function requestRandomNumberWithCallback( ) external override returns (bytes32) {
        emit Request(next);
        callbacks[next] = msg.sender;
        return bytes32(next++);        
    }


    function isRequestComplete(bytes32 requestId) external override view returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(bytes32 requestId) external view override returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return responses[requestId];
    }

    // back end

    function setRand(uint requestId, uint256 rand) external onlyOwner {
        require (requestId < next, "bad ID");
        responses[bytes32(requestId)] = rand;
        responded[bytes32(requestId)] = true;
        emit RandomReceived(requestId,rand);
        address z = callbacks[requestId];
        if (z != address(0)) {
            requestor(z).process(rand,bytes32(requestId));
        }
    }

    function setCallback(uint pos, address dest) external onlyOwner {
        callbacks[pos] = dest;
    }

}

pragma solidity ^0.8.0;

interface IRNG {
    function requestRandomNumber( ) external returns (bytes32);
    function requestRandomNumberWithCallback( ) external returns (bytes32);
    function isRequestComplete(bytes32 requestId) external view returns (bool isCompleted);
    function randomNumber(bytes32 requestId) external view returns (uint256 randomNum);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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