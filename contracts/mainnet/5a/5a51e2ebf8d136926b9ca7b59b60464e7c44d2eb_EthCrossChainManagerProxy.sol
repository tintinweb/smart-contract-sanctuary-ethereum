/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// File: eth-contracts/contracts/core/cross_chain_manager/interface/IEthCrossChainManagerProxy.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the EthCrossChainManagerProxy for business contract like LockProxy to obtain the reliable EthCrossChainManager contract hash.
 */
interface IEthCrossChainManagerProxy {
    function getEthCrossChainManager() external view returns (address);
}

// File: eth-contracts/contracts/core/cross_chain_manager/interface/IUpgradableECCM.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of upgradableECCM to make ECCM be upgradable, the implementation is in UpgradableECCM.sol
 */
interface IUpgradableECCM {
    function pause() external returns (bool);
    function unpause() external returns (bool);
    function paused() external view returns (bool);
    function upgradeToNew(address) external returns (bool);
    function isOwner() external view returns (bool);
    function setChainId(uint64 _newChainId) external returns (bool);
}

// File: eth-contracts/contracts/libs/GSN/Context.sol

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
 * Refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
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

// File: eth-contracts/contracts/libs/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called to pause, triggers stopped state.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called to unpause, returns to normal state.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: eth-contracts/contracts/libs/ownership/Ownable.sol

pragma solidity ^0.5.0;

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
    function transferOwnership(address newOwner) public  onlyOwner {
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

// File: eth-contracts/contracts/core/cross_chain_manager/upgrade/EthCrossChainManagerProxy.sol

pragma solidity ^0.5.0;





contract EthCrossChainManagerProxy is IEthCrossChainManagerProxy, Ownable, Pausable {
    address private EthCrossChainManagerAddr_;
    
    constructor(address _ethCrossChainManagerAddr) public {
        EthCrossChainManagerAddr_ = _ethCrossChainManagerAddr;
    }
    
    function pause() onlyOwner public returns (bool) {
        if (paused()) {
            return true;
        }
        _pause();
        return true;
    }
    function unpause() onlyOwner public returns (bool) {
        if (!paused()) {
            return true;
        }
        _unpause();
        return true;
    }
    function pauseEthCrossChainManager() onlyOwner whenNotPaused public returns (bool) {
        IUpgradableECCM eccm = IUpgradableECCM(EthCrossChainManagerAddr_);
        require(pause(), "pause EthCrossChainManagerProxy contract failed!");
        require(eccm.pause(), "pause EthCrossChainManager contract failed!");
    }
    function upgradeEthCrossChainManager(address _newEthCrossChainManagerAddr) onlyOwner whenPaused public returns (bool) {
        IUpgradableECCM eccm = IUpgradableECCM(EthCrossChainManagerAddr_);
        if (!eccm.paused()) {
            require(eccm.pause(), "Pause old EthCrossChainManager contract failed!");
        }
        require(eccm.upgradeToNew(_newEthCrossChainManagerAddr), "EthCrossChainManager upgradeToNew failed!");
        IUpgradableECCM neweccm = IUpgradableECCM(_newEthCrossChainManagerAddr);
        require(neweccm.isOwner(), "EthCrossChainManagerProxy is not owner of new EthCrossChainManager contract");
        EthCrossChainManagerAddr_ = _newEthCrossChainManagerAddr;
    }
    function unpauseEthCrossChainManager() onlyOwner whenPaused public returns (bool) {
        IUpgradableECCM eccm = IUpgradableECCM(EthCrossChainManagerAddr_);
        require(eccm.unpause(), "unpause EthCrossChainManager contract failed!");
        require(unpause(), "unpause EthCrossChainManagerProxy contract failed!");
    }
    function getEthCrossChainManager() whenNotPaused public view returns (address) {
        return EthCrossChainManagerAddr_;
    }
}