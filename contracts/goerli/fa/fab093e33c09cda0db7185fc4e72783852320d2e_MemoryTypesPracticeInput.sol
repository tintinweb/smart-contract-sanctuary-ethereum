/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: UNLICENSED
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

// File: Solidity/course/3.Memory_types/MemoryTypesPracticeInput.sol


pragma solidity 0.8.12;


interface IMemoryTypesPractice {
    function setA(uint256 _a) external;
    function setB(uint256 _b) external;
    function setC(uint256 _c) external;
    function calc1() external view returns(uint256);
    function calc2() external view returns(uint256);
    function claimRewards(address _user) external;
    function addNewMan(
        uint256 _edge, 
        uint8 _dickSize, 
        bytes32 _idOfSecretBluetoothVacinationChip, 
        uint32 _iq
    ) external;
    function getMiddleDickSize() external view returns(uint256);
    function numberOfOldMenWithHighIq() external view returns(uint256);
}

contract MemoryTypesPracticeInput is IMemoryTypesPractice, Ownable {
    
    // Owner part. Cannot be modified.
    IUserInfo public userInfo;
    uint256 public a;
    uint256 public b;
    uint256 public c;

    uint256 public constant MIN_BALANCE = 12000;

    mapping(address => bool) public rewardsClaimed;

    constructor(address _validator, address _userInfo) {
        transferOwnership(_validator);
        userInfo = IUserInfo(_userInfo);

        addNewMan(1, 1, bytes32('0x11'), 1);
    }

    function setA(uint256 _a) external onlyOwner {
        a = _a;
    }

    function setB(uint256 _b) external onlyOwner {
        b = _b;
    }

    function setC(uint256 _c) external onlyOwner {
        c = _c;
    }
// End of the owner part

    // Here starts part for modification. Remember that function signatures cannot be modified. 

    // to optimize 1
    // Now consumes 27835
    // Should consume not more than 27830 as execution cost for non zero values
    function calc1() external view returns(uint256) {
        // uint256 _localA = a;

        return b + c * a;
    }

    // to optimize 2
    // Now consumes 31253
    // Should consume not more than 30000 as execution cost for non zero values
    function calc2() external view returns(uint256) {
        uint256 _a = a;
        uint256 _b = b;
        uint256 _c = c;
        uint256 double_a = 2 * _a;
        uint256 a_plus_b = a + _b;
        return ((_b + _c) * (a_plus_b) + (_c + _a) * _c + _c/_a + _c/_b + double_a - 1 + _a * _b * _c + _a + _b * _a^2)/
                ((a_plus_b) * _c + double_a);
    }  

    // to optimize 3
    // Now consumes 55446
    // Should consume not more than 54500 as execution cost
    function claimRewards(address _user) external {
        require(!rewardsClaimed[_user], 
            "MemoryTypesPracticeInput: Rewards are already claimed");

        IUserInfo.User memory user = userInfo.getUserInfo(_user);
        require(user.unlockTime <= block.timestamp,
            "MemoryTypesPracticeInput: Unlock time has not yet come");
        
        require(user.balance >= MIN_BALANCE, 
            "MemoryTypesPracticeInput: To less balance");
        
        rewardsClaimed[_user] = true;
    }

    // to optimize 4
    struct Man {
        uint256 edge;
        uint8 dickSize;
        uint32 iq;
        bytes32 idOfSecretBluetoothVacinationChip;
    }

    Man[] men;

    // Now consumes 115724
    // Should consume not more than 94000 as execution cost
    function addNewMan(
        uint256 _edge, 
        uint8 _dickSize, 
        bytes32 _idOfSecretBluetoothVacinationChip, 
        uint32 _iq
    ) public {
        men.push(Man(_edge, _dickSize, _iq, _idOfSecretBluetoothVacinationChip));
    }

    // to optimize 5
    // Now consumes 36689
    // Should consume not more than 36100 as execution cost for 6 elements array
    function getMiddleDickSize() external view returns(uint256) {
        uint256 _sum;
        Man[] memory _men = men;

        for (uint256 i = 0; i < _men.length; i++) {
            _sum += _men[i].dickSize;
        }

        return _sum/_men.length;
    }

    // to optimize 6
    // Now consumes 68675
    // Should consume not more than 40000 as execution cost for 6 elements array
    function numberOfOldMenWithHighIq() external view returns(uint256) {
        uint256 _count;
        Man[] memory _men = men;

        for (uint256 i = 0; i < _men.length; i++) {
            if (_men[i].edge > 50 && _men[i].iq > 120) {
                _count++;
            }
        }

        return _count;
    }
}

// Cannot be modified
interface IUserInfo {
    struct User {
        uint256 balance;
        uint256 unlockTime;
    }

    function addUser(address _user, uint256 _balance, uint256 _unlockTime) external;
    function getUserInfo(address _user) external view returns(User memory);
}

// Cannot be modified.
contract UserInfo is IUserInfo, Ownable {
    mapping(address => User) users;

    constructor(address _validator) {
        transferOwnership(_validator);
    }

    function addUser(address _user, uint256 _balance, uint256 _unlockTime) external onlyOwner {
        users[_user] = User(_balance, _unlockTime);
    }

    function getUserInfo(address _user) external view returns(User memory) {
        return users[_user];
    }
}