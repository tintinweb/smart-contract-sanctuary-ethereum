//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./interfaces/IEvabaseConfig.sol";

import {KeepNetWork} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EvabaseConfig is IEvabaseConfig, Ownable {
    event ItemChanged(bytes32 indexed key, bytes32 newValue);

    mapping(address => KeepInfo) private _keepBotExists;
    mapping(KeepNetWork => uint32) public override keepBotSizes;

    address public override control;
    uint32 public override batchFlowNum = 60;

    mapping(bytes32 => bytes32) private _bytes32items;

    function setBatchFlowNum(uint32 num) external onlyOwner {
        batchFlowNum = num;
        emit SetBatchFlowNum(msg.sender, num);
    }

    function addKeeper(address _keeper, KeepNetWork keepNetWork) external {
        require(msg.sender == owner(), "only owner can add keeper");
        require(!_keepBotExists[_keeper].isActive, "keeper exist");

        _keepBotExists[_keeper] = KeepInfo(true, keepNetWork);

        // require(keepBots.contains(_keeper), "keeper exist");
        // keepBots.add(_keeper);
        keepBotSizes[keepNetWork] = keepBotSizes[keepNetWork] + 1;
        emit AddKeeper(msg.sender, _keeper, keepNetWork);
    }

    function removeBatchKeeper(address[] memory arr) external onlyOwner {
        for (uint256 i = 0; i < arr.length; i++) {
            if (_keepBotExists[arr[i]].isActive) {
                keepBotSizes[_keepBotExists[arr[i]].keepNetWork] = keepBotSizes[_keepBotExists[arr[i]].keepNetWork] - 1;
                delete _keepBotExists[arr[i]];
            }
        }

        emit RemoveBatchKeeper(msg.sender, arr);
    }

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWorks) external onlyOwner {
        require(arr.length == keepNetWorks.length, "invalid length");
        for (uint256 i = 0; i < arr.length; i++) {
            if (!_keepBotExists[arr[i]].isActive) {
                _keepBotExists[arr[i]] = KeepInfo(true, keepNetWorks[i]);
                keepBotSizes[keepNetWorks[i]] = keepBotSizes[keepNetWorks[i]] + 1;
            }
        }

        emit AddBatchKeeper(msg.sender, arr, keepNetWorks);
    }

    function removeKeeper(address _keeper) external onlyOwner {
        require(_keepBotExists[_keeper].isActive, "keeper not exist");

        KeepNetWork _keepNetWork = _keepBotExists[_keeper].keepNetWork;
        keepBotSizes[_keepNetWork] = keepBotSizes[_keepNetWork] - 1;
        delete _keepBotExists[_keeper];
        emit RemoveKeeper(msg.sender, _keeper);
    }

    function isKeeper(address _query) external view override returns (bool) {
        return _keepBotExists[_query].isActive;
    }

    function getKeepBot(address _query) external view override returns (KeepInfo memory) {
        return _keepBotExists[_query];
    }

    function setControl(address _control) external onlyOwner {
        control = _control;
        emit SetControl(msg.sender, _control);
    }

    function isActiveControler(address add) external view override returns (bool) {
        return control == add;
    }

    function setBytes32Item(bytes32 key, bytes32 value) external onlyOwner {
        _bytes32items[key] = value;

        emit ItemChanged(key, value);
    }

    function getBytes32Item(bytes32 key) external view override returns (bytes32) {
        return _bytes32items[key];
    }

    function getAddressItem(bytes32 key) external view override returns (address) {
        return address(uint160(uint256(_bytes32items[key])));
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

struct KeepInfo {
    bool isActive;
    KeepNetWork keepNetWork;
}

interface IEvabaseConfig {
    event AddKeeper(address indexed user, address keeper, KeepNetWork keepNetWork);
    event RemoveKeeper(address indexed user, address keeper);
    event AddBatchKeeper(address indexed user, address[] keeper, KeepNetWork[] keepNetWork);
    event RemoveBatchKeeper(address indexed user, address[] keeper);

    event SetControl(address indexed user, address control);
    event SetBatchFlowNum(address indexed user, uint32 num);

    function getBytes32Item(bytes32 key) external view returns (bytes32);

    function getAddressItem(bytes32 key) external view returns (address);

    function control() external view returns (address);

    function isKeeper(address query) external view returns (bool);

    function batchFlowNum() external view returns (uint32);

    function keepBotSizes(KeepNetWork keepNetWork) external view returns (uint32);

    function getKeepBot(address add) external view returns (KeepInfo memory);

    function isActiveControler(address add) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum CompareOperator {
    Eq,
    Ne,
    Ge,
    Gt,
    Le,
    Lt
}

enum FlowStatus {
    Active, //可执行
    Closed,
    Expired,
    Completed,
    Unknown
}

enum KeepNetWork {
    ChainLink,
    Evabase,
    Gelato,
    Others
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaSafesFactory {
    event ConfigChanged(address indexed newConfig);

    event WalletCreated(address indexed user, address wallet);

    function get(address user) external view returns (address wallet);

    function create(address user) external returns (address wallet);

    function calcSafes(address user) external view returns (address wallet);

    function changeConfig(address _config) external;
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