//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import "../venders/chainlink/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IEvaFlowController, KeepNetWork} from "../interfaces/IEvaFlowController.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";
import "../lib/MathConv.sol";

contract EvaFlowStatusUpkeep is KeeperCompatibleInterface, Ownable {
    event PerformFailed(uint256 flowId, string err);

    uint64 public lastPerformTime;
    uint64 public perfromInterval;
    IEvaFlowController public controller;
    uint256[] private _flowIdTemp; //just for off-chain.

    constructor(IEvaFlowController controller_, uint64 interval_) {
        controller = controller_;
        perfromInterval = interval_;
    }

    function setInterval(uint64 interval) external onlyOwner {
        perfromInterval = interval;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        require(tx.origin == address(0), "only for off-chain"); // solhint-disable

        upkeepNeeded = lastPerformTime + perfromInterval < block.timestamp;
        if (!upkeepNeeded) {
            return (false, bytes(""));
        }
        (KeepNetWork network, uint32 maxChecks) = abi.decode(checkData, (KeepNetWork, uint32));

        IEvaFlowController _controller = controller;
        uint256 flowCount = _controller.getAllVaildFlowSize(network);
        if (flowCount == 0) {
            return (false, bytes(""));
        }

        uint256 begin;
        if (flowCount > maxChecks) {
            // select a random number as first flow index.
            begin = uint256(keccak256(abi.encode(block.timestamp))) % flowCount; // solhint-disable
        }
        for (uint256 i = begin; i < maxChecks && i < flowCount; i++) {
            uint256 flowId = _controller.getIndexVaildFlow(i, network);

            (address flow, bytes memory flowCheckData) = _controller.getFlowCheckInfo(flowId);

            // can be check next flow when flow has reveted.
            // solhint-disable
            (bool success, bytes memory returnBytes) = flow.call(
                abi.encodeWithSelector(IEvaFlow.needClose.selector, flowCheckData)
            );
            if (success) {
                bool can = abi.decode(returnBytes, (bool));
                if (can) {
                    // push functon only for storage array.
                    _flowIdTemp.push(flowId);
                }
            }
        }

        upkeepNeeded = _flowIdTemp.length > 0;
        performData = abi.encode(_flowIdTemp);
    }

    /**
     * @notice destory flow when flow can never be executed.
     * @dev note: can be called by anyone
     */
    function performUpkeep(bytes calldata performData) external override {
        require(lastPerformTime + perfromInterval < block.timestamp, "in dormancy");

        uint256[] memory flowIds = abi.decode(performData, (uint256[]));
        IEvaFlowController _controller = controller;
        uint256 succCount;
        for (uint256 i = 0; i < flowIds.length; i++) {
            uint256 before = gasleft();
            uint256 flowId = flowIds[i];
            (address flow, bytes memory flowCheckData) = _controller.getFlowCheckInfo(flowId);

            try IEvaFlow(flow).close(flowCheckData) {
                _controller.closeFlowWithGas(flowId, before);
                succCount++;
            } catch Error(string memory err) {
                emit PerformFailed(flowId, err);
            }
        }
        // Eusure that invalid tx are not always minted.
        require(succCount > 0, "all failed");
        lastPerformTime = MathConv.toU64(block.timestamp);
    
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
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

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {FlowStatus, KeepNetWork} from "../lib/EvabaseHelper.sol";

//struct
struct EvaFlowMeta {
    FlowStatus flowStatus;
    KeepNetWork keepNetWork;
    address admin;
    address lastKeeper;
    address lastVersionflow;
    uint256 lastExecNumber;
    uint256 maxVaildBlockNumber;
    string flowName;
    bytes checkData;
}

struct EvaUserMeta {
    uint120 ethBal;
    uint120 gasTokenBal; //keep
    uint8 vaildFlowsNum;
}

struct MinConfig {
    address feeRecived;
    address feeToken;
    uint64 minGasFundForUser;
    uint64 minGasFundOneFlow;
    uint16 ppb;
    uint16 blockCountPerTurn;
}

interface IEvaFlowController {
    event FlowOperatorChanged(address op, bool removed);
    event FlowCreated(address indexed user, uint256 indexed flowId, address flowAdd, bytes checkData, uint256 fee);
    event FlowUpdated(address indexed user, uint256 flowId, address flowAdd);
    event FlowClosed(address indexed user, uint256 flowId);
    event FlowExecuteSuccess(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed
    );
    event FlowExecuteFailed(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed,
        string reason
    );

    event SetMinConfig(
        address indexed user,
        address feeRecived,
        address feeToken,
        uint64 minGasFundForUser,
        uint64 minGasFundOneFlow,
        uint16 ppb,
        uint16 blockCountPerTurn
    );

    function registerFlow(
        string memory name,
        KeepNetWork keepNetWork,
        address flow,
        bytes memory checkdata
    ) external payable returns (uint256 flowId);

    function closeFlow(uint256 flowId) external;

    function closeFlowWithGas(uint256 flowId, uint256 before) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function depositFund(address flowAdmin) external payable;

    function withdrawFund(address recipient, uint256 amount) external;

    function withdrawPayment(uint256 amount) external;

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(address keeper, bytes memory data) external;

    function getFlowCheckInfo(uint256 flowId) external view returns (address flow, bytes memory checkData);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function check(bytes memory checkData) external view returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external returns (bool canDestoryFlow);

    function needClose(bytes memory checkData) external returns (bool yes);

    function close(bytes memory checkData) external;
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
/* solhint-disable */

pragma solidity ^0.8.0;

library MathConv {
    function toU120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "to120-overflow");
        return uint120(value);
    }

    function toU96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "to96-overflow");
        return uint96(value);
    }

    function toU64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "to64-overflow");
        return uint64(value);
    }

    function toU8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "to8-overflow");
        return uint8(value);
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