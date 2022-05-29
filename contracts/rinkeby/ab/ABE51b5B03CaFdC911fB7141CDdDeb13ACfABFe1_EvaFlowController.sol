//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {FlowStatus, KeepNetWork, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {Utils} from "./lib/Utils.sol";
import {TransferHelper} from "./lib/TransferHelper.sol";
import {IEvaSafes} from "./interfaces/IEvaSafes.sol";
import "./interfaces/IEvabaseConfig.sol";
import "./interfaces/IEvaFlowExecutor.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract EvaFlowController is IEvaFlowController, OwnableUpgradeable {
    EvaFlowMeta[] private _flowMetas;
    MinConfig public minConfig;
    mapping(address => EvaUserMeta) public userMetaMap;

    //need exec flows
    using EvabaseHelper for EvabaseHelper.UintSet;
    mapping(KeepNetWork => EvabaseHelper.UintSet) private _vaildFlows;

    uint256 private constant _REGISTRY_GAS_OVERHEAD = 80_000;
    uint256 private constant _MAX_INT = type(uint256).max;
    bytes32 private constant _FLOW_EXECUTOR = keccak256("FLOW_EXECUTOR");

    //Withdrawable fees
    uint256 public paymentEthAmount;
    uint256 public paymentGasAmount;

    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    mapping(address => bool) public flowOperators;

    event FlowOperatorChanged(address op, bool removed);

    function initialize(address _config, address _evaSafesFactory) external initializer {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        __Ownable_init();
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        config = IEvabaseConfig(_config);

        EvaFlowMeta memory f;
        _flowMetas.push(f); //storage a solt, flow id starts with 1.

        flowOperators[msg.sender] = true;
    }

    function setMinConfig(MinConfig memory _minConfig) external onlyOwner {
        require(_minConfig.ppb >= 10000 && _minConfig.ppb <= 15000, "invalid ppb");
        minConfig = _minConfig;
        emit SetMinConfig(
            msg.sender,
            _minConfig.feeRecived,
            _minConfig.feeToken,
            _minConfig.minGasFundForUser,
            _minConfig.minGasFundOneFlow,
            _minConfig.ppb,
            _minConfig.blockCountPerTurn
        );
    }

    function setFlowOperators(address op, bool isAdd) external onlyOwner {
        if (isAdd) {
            flowOperators[op] = true;
        } else {
            delete flowOperators[op];
        }
        emit FlowOperatorChanged(op, isAdd);
    }

    function _checkEnoughGas() internal view {
        bool isEnoughGas = true;
        if (minConfig.feeToken == address(0)) {
            isEnoughGas =
                (userMetaMap[msg.sender].ethBal >= minConfig.minGasFundForUser) &&
                (userMetaMap[msg.sender].ethBal >= userMetaMap[msg.sender].vaildFlowsNum * minConfig.minGasFundOneFlow);
        } else {
            isEnoughGas =
                (userMetaMap[msg.sender].gasTokenBal >= minConfig.minGasFundForUser) &&
                (userMetaMap[msg.sender].gasTokenBal >=
                    userMetaMap[msg.sender].vaildFlowsNum * minConfig.minGasFundOneFlow);
        }

        require(isEnoughGas, "gas balance is not enough");
    }

    function _beforeCreateFlow(KeepNetWork _keepNetWork) internal view {
        require(uint256(_keepNetWork) <= uint256(KeepNetWork.Others), "invalid netWork");
        require(IEvaSafes(msg.sender).isEvaSafes(), "should be safes");
    }

    function isValidFlow(address flow) public view returns (bool) {
        require(flow != address(0), "flow is 0x");
        require(flow != address(this), "invalid flow");
        return true; //TODO: Valid Flows
    }

    function _appendFee(address acct, uint256 amount) private {
        userMetaMap[acct].ethBal += Utils.toUint120(amount);
    }

    function registerFlow(
        string memory name,
        KeepNetWork network,
        address flow,
        bytes memory checkdata
    ) external payable override returns (uint256 flowId) {
        require(isValidFlow(flow), "invalid flow");
        _beforeCreateFlow(network);
        _appendFee(msg.sender, msg.value);
        userMetaMap[msg.sender].vaildFlowsNum += uint8(1); // Error if overflow
        //Check if the Gas fee balance is sufficient
        _checkEnoughGas();
        _flowMetas.push(
            EvaFlowMeta({
                flowStatus: FlowStatus.Active,
                keepNetWork: network,
                maxVaildBlockNumber: _MAX_INT,
                admin: msg.sender,
                lastKeeper: address(0),
                lastExecNumber: 0,
                lastVersionflow: flow,
                flowName: name,
                checkData: checkdata
            })
        );
        flowId = _flowMetas.length - 1;
        _vaildFlows[network].add(flowId);
        emit FlowCreated(msg.sender, flowId, flow, checkdata, msg.value);
    }

    function updateFlow(
        uint256 _flowId,
        string memory _flowName,
        bytes memory _flowCode
    ) external override {
        require(_flowId < _flowMetas.length, "over bound");
        require(msg.sender == _flowMetas[_flowId].admin, "flow's owner is not y");
        require(FlowStatus.Active == _flowMetas[_flowId].flowStatus, "flow's status is error");

        KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;

        _beforeCreateFlow(keepNetWork);
        //create
        address addr;
        uint256 size;
        // solhint-disable no-inline-assembly
        assembly {
            addr := create(0, add(_flowCode, 0x20), mload(_flowCode))
            size := extcodesize(addr)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        // _vaildFlows.remove(_flowId);
        _vaildFlows[keepNetWork].remove(_flowId);
        _flowMetas[_flowId].flowName = _flowName;
        _flowMetas[_flowId].lastKeeper = address(0);
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].lastVersionflow = addr;
        // _vaildFlows.add(_flowId);
        _vaildFlows[keepNetWork].add(_flowId);

        emit FlowUpdated(msg.sender, _flowId, addr);
    }

    function closeFlow(uint256 flowId) external override {
        EvaFlowMeta memory meta = _flowMetas[flowId];
        _requireFlowOperator(meta.admin);
        require(meta.flowStatus != FlowStatus.Closed, "have closeed");
        _closeFlow(flowId, meta);
    }

    function _closeFlow(uint256 flowId, EvaFlowMeta memory meta) internal {
        // remove from valid when flow is active.
        if (meta.flowStatus == FlowStatus.Active) {
            userMetaMap[meta.admin].vaildFlowsNum -= 1;
            _vaildFlows[meta.keepNetWork].remove(flowId);
        }
        _flowMetas[flowId].flowStatus = FlowStatus.Closed;
        emit FlowClosed(meta.admin, flowId);
    }

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address flowAdmin
    ) public payable override {
        if (tokenAdress == address(0)) {
            require(msg.value == amount, "value is not equal");

            userMetaMap[flowAdmin].ethBal = userMetaMap[flowAdmin].ethBal + Utils.toUint120(msg.value);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");

            userMetaMap[flowAdmin].gasTokenBal = userMetaMap[flowAdmin].gasTokenBal + Utils.toUint120(amount);

            TransferHelper.safeTransferFrom(tokenAdress, msg.sender, address(this), amount);
        }
    }

    function withdrawFundByUser(
        address recipient,
        address tokenAdress,
        uint256 amount
    ) external override {
        require(recipient != address(0), "Invalid address");
        address safeWallet = msg.sender;

        uint256 minTotalFlow = userMetaMap[safeWallet].vaildFlowsNum * minConfig.minGasFundOneFlow;
        uint256 minTotalGas = minTotalFlow > minConfig.minGasFundForUser ? minTotalFlow : minConfig.minGasFundForUser;

        if (tokenAdress == address(0)) {
            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas, "withdraw too big");
            userMetaMap[safeWallet].ethBal -= Utils.toUint120(amount);
            TransferHelper.safeTransferETH(recipient, amount);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");
            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas, "withdraw too big");

            userMetaMap[safeWallet].gasTokenBal -= Utils.toUint120(amount);

            TransferHelper.safeTransfer(tokenAdress, recipient, amount);
        }
    }

    function withdrawPayment(address tokenAdress, uint256 amount) external override onlyOwner {
        if (tokenAdress == address(0)) {
            require(paymentEthAmount >= amount, "");
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");
            require(paymentGasAmount >= amount, "");
            TransferHelper.safeTransfer(tokenAdress, msg.sender, amount);
        }
    }

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view override returns (uint256 value) {
        return _vaildFlows[keepNetWork].get(index);
    }

    function getVaildFlowRange(
        uint256 fromIndex,
        uint256 endIndex,
        KeepNetWork keepNetWork
    ) external view override returns (uint256[] memory arr) {
        return _vaildFlows[keepNetWork].getRange(fromIndex, endIndex);
    }

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view override returns (uint256 size) {
        return _vaildFlows[keepNetWork].getSize();
    }

    function getFlowMetas(uint256 index) external view override returns (EvaFlowMeta memory) {
        return _flowMetas[index];
    }

    function getFlowMetaSize() external view override returns (uint256) {
        return _flowMetas.length;
    }

    function batchExecFlow(
        address keeper,
        bytes memory data,
        uint256
    ) external override {
        (uint256[] memory arr, bytes[] memory executeDataArray) = Utils._decodeTwoArr(data);
        require(arr.length == executeDataArray.length, "invalid array len");
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > 0) {
                execFlow(keeper, arr[i], executeDataArray[i]);
            }
        }
    }

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory execData
    ) public override {
        EvaFlowMeta memory flow = _flowMetas[flowId];
        KeepStruct memory ks = config.getKeepBot(msg.sender);

        bool isOffChain = tx.origin == address(0);
        // Let pre-execution pass
        // solhint-disable avoid-tx-origin
        if (!isOffChain) {
            // Check if the flow's network matches the keeper
            require(flow.keepNetWork == ks.keepNetWork, "invalid keepNetWork");
            require(ks.isActive, "exect keeper is not whitelist");
        }

        uint256 before = gasleft();

        if (flow.keepNetWork != KeepNetWork.Evabase) {
            require((keeper != flow.lastKeeper), "expect next keeper");
        }

        // update first.
        _flowMetas[flowId].lastExecNumber = block.number;
        _flowMetas[flowId].lastKeeper = keeper;

        bool success;
        bool needClose;
        string memory failedReason;
        {
            address executor = config.getAddressItem(_FLOW_EXECUTOR);
            try IEvaFlowExecutor(executor).execute(flow, execData) returns (bool needCloseFlow) {
                needClose = needCloseFlow;
                success = true;
            } catch Error(string memory reason) {
                failedReason = reason; // revert or require
            } catch {
                failedReason = "Reverted"; //assert
            }
        }

        uint256 usedGas = before - gasleft();

        uint120 payAmountByETH = 0;
        uint120 payAmountByFeeToken = 0;

        if (minConfig.feeToken == address(0)) {
            payAmountByETH = _calculatePaymentAmount(usedGas);
            uint120 bal = userMetaMap[flow.admin].ethBal;

            if (isOffChain) {
                uint256 minPay = payAmountByETH > minConfig.minGasFundOneFlow
                    ? payAmountByETH
                    : minConfig.minGasFundOneFlow;
                require(bal >= minPay, "insufficient fund");
            }

            userMetaMap[flow.admin].ethBal = bal < payAmountByETH ? 0 : bal - payAmountByETH;
        } else {
            revert("TODO");
        }

        if (success) {
            emit FlowExecuteSuccess(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas);
        } else {
            if (isOffChain) {
                revert(failedReason);
            }
            emit FlowExecuteFailed(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas, failedReason);
        }

        if (needClose && !isOffChain) {
            // don't close flow when try execute on off-chain
            _closeFlow(flowId, flow);
        }
    }

    function _calculatePaymentAmount(uint256 gasLimit) private view returns (uint120 payment) {
        uint256 price = tx.gasprice == 0 ? 1 gwei : tx.gasprice;
        uint256 weiForGas = price * (gasLimit + _REGISTRY_GAS_OVERHEAD);
        uint256 total = (weiForGas * minConfig.ppb) / 10000;
        return uint120(total);
    }

    function getSafes(address user) external view override returns (address) {
        return evaSafesFactory.get(user);
    }

    function getFlowCheckInfo(uint256 flowId) external view override returns (address flow, bytes memory checkData) {
        flow = _flowMetas[flowId].lastVersionflow;
        checkData = _flowMetas[flowId].checkData;
    }

    function _requireFlowOperator(address flowAdmin) private view {
        require(flowAdmin == msg.sender || flowOperators[msg.sender], "only for op/admin");
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
    uint120 gasTokenBal;
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

    function updateFlow(
        uint256 flowId,
        string memory flowName,
        bytes memory flowCode
    ) external;

    function closeFlow(uint256 flowId) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address user
    ) external payable;

    function withdrawFundByUser(
        address recipient,
        address tokenAdress,
        uint256 amount
    ) external;

    function withdrawPayment(address tokenAdress, uint256 amount) external;

    function getVaildFlowRange(
        uint256 fromIndex,
        uint256 endIndex,
        KeepNetWork keepNetWork
    ) external view returns (uint256[] memory arr);

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(
        address keeper,
        bytes memory data,
        uint256 gasLimit
    ) external;

    function getSafes(address user) external view returns (address);

    function getFlowCheckInfo(uint256 flowId) external view returns (address flow, bytes memory checkData);
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
/* solhint-disable */

pragma solidity ^0.8.0;

library Utils {
    function _decodeUints(bytes memory data) internal pure returns (uint256[] memory _arr) {
        _arr = abi.decode(data, (uint256[]));
    }

    function _decodeTwoArr(bytes memory data) internal pure returns (uint256[] memory _arr, bytes[] memory _bytes) {
        (_arr, _bytes) = abi.decode(data, (uint256[], bytes[]));
    }

    function _decodeUintAndBytes(bytes memory data) internal pure returns (bytes memory _byte, uint256 _arr) {
        (_byte, _arr) = abi.decode(data, (bytes, uint256));
    }

    function _encodeTwoArr(uint256[] memory _uint, bytes[] memory _bytes) internal pure returns (bytes memory) {
        return (abi.encode(_uint, _bytes));
    }

    function hashCompareInternal(bytes memory a, bytes memory b) internal pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 224 bits");
        return uint120(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /* solhint-disable */
    address internal constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    /**
     * @notice Get the account's balance of token or ETH
     * @param token - Address of the token
     * @param addr - Address of the account
     * @return uint256 - Account's balance of token or ETH
     */
    function balanceOf(address token, address addr) internal view returns (uint256) {
        if (ETH_ADDRESS == address(token)) {
            return addr.balance;
        }
        return IERC20(token).balanceOf(addr);
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransferTokenOrETH(
        address token,
        address to,
        uint256 value
    ) internal {
        if (ETH_ADDRESS == token) {
            safeTransferETH(to, value);
            return;
        }
        safeTransfer(token, to, value);
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum HowToCall {
    Call,
    DelegateCall
}

interface IEvaSafes {
    function initialize(address admin, address agent) external;

    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) external payable returns (bytes memory);

    function isEvaSafes() external pure returns (bool);
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

    function getBytes32Item(bytes32 key) external view returns (bytes32);

    function getAddressItem(bytes32 key) external view returns (address);

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
//author: Evabase core team

pragma solidity ^0.8.0;

import {EvaFlowMeta} from "./IEvaFlowController.sol";

interface IEvaFlowExecutor {
    function execute(EvaFlowMeta memory flow, bytes memory executeData) external returns (bool needCloseFlow);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}