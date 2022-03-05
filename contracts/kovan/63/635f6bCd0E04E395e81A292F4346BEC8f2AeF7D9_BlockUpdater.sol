/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/access/Ownable.sol



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/M0/block/IBlockUpdater.sol



pragma solidity ^0.8.6;

interface IBlockUpdater {

    event UpdateEpoch(uint256 currentEpoch, uint256 RFactor, uint256 AccRewardSnapShot, uint256 nextEpochStartTime);

    struct Epoch {
        uint256 StartTime;
        uint256 RFactor;            //scaled
        uint256 AccRewardSnapShot;  //scaled
    }

    function getCurrentEpoch() external view returns (uint256);
    function getCurrentAccReward() external view returns (uint256);
    function pendingReward(uint256 balance, uint256 lastModifiedEpoch, uint256 lastModifiedTime, uint256 accAmountTime) external view returns (uint256 epochReward, uint256 pendingAmountTime);
    function estimatedPendingReward(uint256 accAmountTime) external view returns (uint256);
    function estimatedDailyReward(uint256 balance) external view returns (uint256);
}


// File contracts/M0/block/BlockUpdater.sol



pragma solidity ^0.8.6;


contract BlockUpdater is Ownable, IBlockUpdater{

    Epoch[] public epochs;

    uint256 private scale = 10**18;
    string public name;
    uint256 public lastEpochRewardScaled;

    constructor(string memory name_){
        name = name_;
    }

    function getCurrentEpoch() public view override returns(uint256) {
        if(epochs.length > 0){
            return epochs.length - 1;
        }else{
            return 0;
        }
    }

    function getCurrentAccReward() public view override returns(uint256){
        if(epochs.length > 1){
            return epochs[epochs.length - 2].AccRewardSnapShot;
        }else{
            return 0;
        }
    }

    //according to yesterday
    function estimatedPendingReward(uint256 _accAmountTime) public view override returns(uint256){
        require(epochs.length >=2, "Block Updater: NO_HISTORY");
        return epochs[epochs.length - 2].RFactor * _accAmountTime / scale;
    }

    //according to yesterday
    function estimatedDailyReward(uint256 _balance) public view override returns(uint256){
        require(epochs.length >=2, "Block Updater: NO_HISTORY");
        return lastEpochRewardScaled * _balance / scale;
    }

    //the output of 10**12 TH/S over the period
    function startNewEpoch(uint256 _currentEpoch, uint256 _currentEpochRewardScaled) public onlyOwner{
        require(_currentEpoch == getCurrentEpoch(), "Block Updater: WRONG_EPOCH");
        if(epochs.length > 0){  //close current epoch
            uint256 currentEpoch = getCurrentEpoch();
            Epoch storage epoch = epochs[currentEpoch];
            epoch.RFactor = _currentEpochRewardScaled / (block.timestamp - epoch.StartTime);
            epoch.AccRewardSnapShot = getCurrentAccReward() + _currentEpochRewardScaled;
            lastEpochRewardScaled = _currentEpochRewardScaled;
            emit UpdateEpoch(currentEpoch, epoch.RFactor, epoch.AccRewardSnapShot, block.timestamp);
        }else{  //the epoch 0
            emit UpdateEpoch(0, 0, 0, block.timestamp);
        }
        epochs.push(Epoch(block.timestamp, 0, 0));
    }

    function _withinEpoch(
        uint256 _balance,
        uint256 _lastModifiedTime,
        uint256 _accAmountTime) internal view returns (uint256 pendingAmountTime){
        pendingAmountTime = _balance * (block.timestamp - _lastModifiedTime) + _accAmountTime;
    }


    function _crossEpoch(
        uint256 _balance,
        uint256 _lastModifiedEpoch,
        uint256 _lastModifiedTime,
        uint256 _accAmountTime
        ) internal view returns (uint256 reward, uint256 pendingAmountTime){
        Epoch memory lastModifiedEpoch = epochs[_lastModifiedEpoch];
        uint256 fullEpochReward = _balance * (getCurrentAccReward() - lastModifiedEpoch.AccRewardSnapShot);
        uint256 partEpochReward = lastModifiedEpoch.RFactor * 
                                (_accAmountTime + 
                                _balance * (epochs[_lastModifiedEpoch + 1].StartTime - _lastModifiedTime));
        reward = (fullEpochReward + partEpochReward) / scale;    // scale down
        pendingAmountTime = _balance * (block.timestamp - epochs[getCurrentEpoch()].StartTime);
    }

    function pendingReward(
        uint256 _balance,
        uint256 _lastModifiedEpoch,
        uint256 _lastModifiedTime,
        uint256 _accAmountTime
        ) public view override returns(uint256 epochReward, uint256 pendingAmountTime) {
        if(_lastModifiedTime != 0){
            if(_lastModifiedEpoch == getCurrentEpoch()){ // change happens in current epoch
                pendingAmountTime = _withinEpoch(_balance, _lastModifiedTime, _accAmountTime);
            }else{
                (epochReward, pendingAmountTime) = _crossEpoch(_balance, _lastModifiedEpoch, _lastModifiedTime, _accAmountTime);
            }
        }
    }
}