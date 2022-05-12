//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./interfaces/IEvabaseConfig.sol";
import {EvabaseHelper, KeepNetWork} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EvabaseConfig is IEvabaseConfig, Ownable {
    mapping(address => KeepStruct) private _keepBotExists;
    mapping(KeepNetWork => uint32) public override keepBotSizes;
    // uint32 public override keepBotSize;
    // using EvabaseHelper for EvabaseHelper.AddressSet;
    // EvabaseHelper.AddressSet keepBots;

    address public override control;

    uint32 public override batchFlowNum = 60;

    function setBatchFlowNum(uint32 num) external override onlyOwner {
        batchFlowNum = num;
        emit SetBatchFlowNum(msg.sender, num);
    }

    function addKeeper(address _keeper, KeepNetWork keepNetWork) external override {
        require(msg.sender == owner(), "only owner can add keeper");
        require(!_keepBotExists[_keeper].isActive, "keeper exist");

        _keepBotExists[_keeper] = KeepStruct(true, keepNetWork);

        // require(keepBots.contains(_keeper), "keeper exist");
        // keepBots.add(_keeper);
        keepBotSizes[keepNetWork] = keepBotSizes[keepNetWork] + 1;
        emit AddKeeper(msg.sender, _keeper, keepNetWork);
    }

    function removeBatchKeeper(address[] memory arr) external override {
        require(msg.sender == owner(), "only owner can add keeper");
        // require(
        //     arr.length == keepNetWorks.length,
        //     "arr length not equal keepNetWorks length"
        // );
        for (uint256 i = 0; i < arr.length; i++) {
            // if (keepBots.contains(arr[i])) {
            //     keepBots.remove(arr[i]);
            // }

            if (_keepBotExists[arr[i]].isActive) {
                // _keepBotExists[arr[i]].isActive = false;

                keepBotSizes[_keepBotExists[arr[i]].keepNetWork] = keepBotSizes[_keepBotExists[arr[i]].keepNetWork] - 1;
                delete _keepBotExists[arr[i]];
            }
        }

        emit RemoveBatchKeeper(msg.sender, arr);
    }

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWorks) external override {
        require(arr.length == keepNetWorks.length, "invalid length");
        require(msg.sender == owner(), "only owner");
        for (uint256 i = 0; i < arr.length; i++) {
            // if (!keepBots.contains(arr[i])) {
            //     keepBots.add(arr[i]);
            // }
            if (!_keepBotExists[arr[i]].isActive) {
                // _keepBotExists[arr[i]] = true;
                // keepBotSize++;

                // require(keepBots.contains(_keeper), "keeper exist");
                // keepBots.add(_keeper);
                _keepBotExists[arr[i]] = KeepStruct(true, keepNetWorks[i]);

                // stuct.isActive == true;
                // _keepBotExists[arr[i]].keepNetWork == keepNetWorks[i];
                keepBotSizes[keepNetWorks[i]] = keepBotSizes[keepNetWorks[i]] + 1;
            }
        }

        emit AddBatchKeeper(msg.sender, arr, keepNetWorks);
    }

    function removeKeeper(address _keeper) external override {
        require(msg.sender == owner(), "only owner can add keeper");
        require(_keepBotExists[_keeper].isActive, "keeper not exist");

        KeepNetWork _keepNetWork = _keepBotExists[_keeper].keepNetWork;
        keepBotSizes[_keepNetWork] = keepBotSizes[_keepNetWork] - 1;
        delete _keepBotExists[_keeper];
        // require(!keepBots.contains(_keeper), "keeper not exist");
        // keepBots.remove(_keeper);
        emit RemoveKeeper(msg.sender, _keeper);
    }

    function isKeeper(address _query) external view override returns (bool) {
        return _keepBotExists[_query].isActive;
        // return keepBots.contains(_query);
    }

    function getKeepBot(address _query) external view override returns (KeepStruct memory) {
        return _keepBotExists[_query];
        // return keepBots.contains(_query);
    }

    function setControl(address _control) external override onlyOwner {
        control = _control;
        emit SetControl(msg.sender, _control);
    }

    function isActiveControler(address add) external view override returns (bool) {
        return control == add;
    }

    // function keepBotSizes(KeepNetWork keepNetWork)
    //     external
    //     view
    //     override
    //     returns (uint32)
    // {
    //     return keepBotSizes[keepNetWork];
    // }

    // function getAllKeepBots()
    //     external
    //     view
    //     override
    //     returns (address[] memory)
    // {
    //     return keepBots.getAll();
    // }

    // function getKeepBotSize() external view override returns (uint32) {
    //     return uint32(keepBots.getSize());
    // }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

struct KeepStruct {
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

    function control() external view returns (address);

    function setControl(address control_) external;

    function isKeeper(address query) external view returns (bool);

    function addKeeper(address keeper, KeepNetWork keepNetWork) external;

    function removeKeeper(address keeper) external;

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWork) external;

    function removeBatchKeeper(address[] memory arr) external;

    function setBatchFlowNum(uint32 num) external;

    function batchFlowNum() external view returns (uint32);

    function keepBotSizes(KeepNetWork keepNetWork) external view returns (uint32);

    function getKeepBot(address add) external view returns (KeepStruct memory);

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
    Paused,
    Destroyed,
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

library EvabaseHelper {
    struct UintSet {
        // value ->index value !=0
        mapping(uint256 => uint256) indexMapping;
        uint256[] values;
    }

    function add(UintSet storage self, uint256 value) internal {
        require(value != uint256(0), "value=0");
        require(!contains(self, value), "value exists");
        self.values.push(value);
        self.indexMapping[value] = self.values.length;
    }

    function contains(UintSet storage self, uint256 value) internal view returns (bool) {
        return self.indexMapping[value] != 0;
    }

    function remove(UintSet storage self, uint256 value) internal {
        require(contains(self, value), "value doesn't exist");
        uint256 toDeleteindexMapping = self.indexMapping[value] - 1;
        uint256 lastindexMapping = self.values.length - 1;
        uint256 lastValue = self.values[lastindexMapping];
        self.values[toDeleteindexMapping] = lastValue;
        self.indexMapping[lastValue] = toDeleteindexMapping + 1;
        delete self.indexMapping[value];
        // self.values.length--;
        self.values.pop();
    }

    function getSize(UintSet storage self) internal view returns (uint256) {
        return self.values.length;
    }

    function get(UintSet storage self, uint256 index) internal view returns (uint256) {
        return self.values[index];
    }

    function getAll(UintSet storage self) internal view returns (uint256[] memory) {
        // uint256[] memory output = new uint256[](self.values.length);
        // for (uint256 i; i < self.values.length; i++) {
        //     output[i] = self.values[i];
        // }
        return self.values;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        // solhint-disable no-inline-assembly
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function getRange(
        UintSet storage self,
        uint256 fromIndex,
        uint256 endIndex
    ) internal view returns (uint256[] memory) {
        require(fromIndex <= endIndex, "fromIndex gt endIndex");
        require(endIndex <= self.values.length, "endIndex exceed bound");
        uint256[] memory output = new uint256[](endIndex - fromIndex);
        uint256 j = 0;
        for (uint256 i = fromIndex; i < endIndex; i++) {
            output[j++] = self.values[i];
        }
        return output;
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaSafesFactory {
    event ConfigChanged(address indexed newConfig);

    event WalletCreated(address indexed user, address wallet, uint256);

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