//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {FlowStatus, KeepNetWork, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {Utils} from "./lib/Utils.sol";
import {TransferHelper} from "./lib/TransferHelper.sol";
import {IEvaSafes} from "./interfaces/IEvaSafes.sol";
import "./interfaces/IEvabaseConfig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EvaFlowController is IEvaFlowController, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    EvaFlowMeta[] private _flowMetas;
    MinConfig public minConfig;
    mapping(address => EvaUserMeta) public userMetaMap;
    // bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("execute(bytes)"));

    ////need exec flows
    using EvabaseHelper for EvabaseHelper.UintSet;
    mapping(KeepNetWork => EvabaseHelper.UintSet) private _vaildFlows;
    // EvabaseHelper.UintSet _vaildFlows;
    uint256 private constant _REGISTRY_GAS_OVERHEAD = 80_000;
    // using LibSingleList for LibSingleList.List;
    // using LibSingleList for LibSingleList.Iterate;
    // LibSingleList.List _vaildFlows;

    uint256 public constant MAX_INT = 2 ^ (256 - 1);

    //可提取的手续费
    uint256 public paymentEthAmount;
    uint256 public paymentGasAmount;

    IEvaSafesFactory public evaSafesFactory;

    IEvabaseConfig public config;

    constructor(address _config, address _evaSafesFactory) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        config = IEvabaseConfig(_config);
        _flowMetas.push(
            EvaFlowMeta({
                flowStatus: FlowStatus.Unknown,
                keepNetWork: KeepNetWork.ChainLink,
                maxVaildBlockNumber: MAX_INT,
                admin: msg.sender,
                lastKeeper: address(0),
                lastExecNumber: block.number,
                lastVersionflow: address(0),
                flowName: "init",
                checkData: ""
            })
        );
    }

    function setMinConfig(MinConfig memory _minConfig) external onlyOwner {
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

    function _checkEnoughGas() internal view {
        // 需要修正
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
        IEvaSafes safes = IEvaSafes(msg.sender);
        require(safes.isEvaSafes(), "should be safes");
    }

    function isValidFlow(address flow) public pure returns (bool) {
        require(flow != address(0), "flow is 0x");
        return true; //TODO: 需要维护合法Flow清单
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
        userMetaMap[msg.sender].vaildFlowsNum += uint8(1); // 如果溢出则报错
        //检查Gas费余额是否足够
        _checkEnoughGas();
        _flowMetas.push(
            EvaFlowMeta({
                flowStatus: FlowStatus.Active,
                keepNetWork: network,
                maxVaildBlockNumber: MAX_INT,
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
    ) external override nonReentrant {
        require(_flowId < _flowMetas.length, "over bound");
        // address safeWallet = evaSafesFactory.get(msg.sender);
        // require(safeWallet != address(0), "safe wallet is 0x");
        require(msg.sender == _flowMetas[_flowId].admin, "flow's owner is not y");
        require(
            FlowStatus.Active == _flowMetas[_flowId].flowStatus || FlowStatus.Paused == _flowMetas[_flowId].flowStatus,
            "flow's status is error"
        );

        KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;

        _beforeCreateFlow(keepNetWork);
        //create
        address addr;
        uint256 size;
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

    function pauseFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");
        require(userMetaMap[msg.sender].vaildFlowsNum > 0, "vaildFlowsNum should gt 0");
        require(FlowStatus.Active == _flowMetas[_flowId].flowStatus, "flow's status is error");
        require(msg.sender == _flowMetas[_flowId].admin || msg.sender == owner(), "flow's owner is not y");
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Paused;

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum - 1;

        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.remove(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].remove(_flowId);
        }
        //pause flow IEvaFlow
        // IEvaFlow(_flowMetas[_flowId].lastVersionflow).pause(_flowId, _flowCode);

        emit FlowPaused(msg.sender, _flowId);
    }

    function startFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");

        require(msg.sender == _flowMetas[_flowId].admin || msg.sender == owner(), "flow's owner is not y");
        require(FlowStatus.Paused == _flowMetas[_flowId].flowStatus, "flow's status is error");
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Active;

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum + 1;

        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.add(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].add(_flowId);
        }

        emit FlowStart(msg.sender, _flowId);
    }

    function destroyFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");
        require(msg.sender == _flowMetas[_flowId].admin || msg.sender == owner(), "flow's owner is not y");
        require(userMetaMap[msg.sender].vaildFlowsNum > 0, "vaildFlowsNum should gt 0");
        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.remove(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].remove(_flowId);
        }

        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Destroyed;
        // _flowMetas[_flowId].lastVersionflow = address(0);

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum - 1;

        emit FlowDestroyed(msg.sender, _flowId);
    }

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        // address user
        address flowAdmin
    ) public payable override nonReentrant {
        // address safeWallet = evaSafesFactory.get(user);
        // require(safeWallet != address(0), "safe wallet is 0x");
        // require(msg.sender == flowAdmin, "flow's owner is not y");
        // require(evaSafesFactory.get(user) != address(0), "safe wallet is 0x");

        if (tokenAdress == address(0)) {
            require(msg.value == amount, "value is not equal");

            userMetaMap[flowAdmin].ethBal = userMetaMap[flowAdmin].ethBal + Utils.toUint120(msg.value);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");

            userMetaMap[flowAdmin].gasTokenBal = userMetaMap[flowAdmin].gasTokenBal + Utils.toUint120(amount);

            IERC20(tokenAdress).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function withdrawFundByUser(address tokenAdress, uint256 amount) external override nonReentrant {
        address safeWallet = msg.sender;
        // require(safeWallet != address(0), "safe wallet is 0x");
        // require(msg.sender == flowAdmin, "flow's owner is not y");

        uint256 minTotalFlow = userMetaMap[safeWallet].vaildFlowsNum * minConfig.minGasFundOneFlow;
        uint256 minTotalGas = minTotalFlow > minConfig.minGasFundForUser ? minTotalFlow : minConfig.minGasFundForUser;

        if (tokenAdress == address(0)) {
            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas);
            userMetaMap[safeWallet].ethBal = userMetaMap[safeWallet].ethBal - Utils.toUint120(amount);
            (bool sent, ) = safeWallet.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");

            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas);

            userMetaMap[safeWallet].gasTokenBal = userMetaMap[safeWallet].gasTokenBal - Utils.toUint120(amount);

            IERC20(tokenAdress).transfer(safeWallet, amount);
        }
    }

    function withdrawPayment(address tokenAdress, uint256 amount) external override onlyOwner {
        if (tokenAdress == address(0)) {
            require(paymentEthAmount >= amount, "");
            TransferHelper.safeTransferETH(msg.sender, amount);
            // (bool sent, ) = msg.sender.call{value: amount}("");
            // require(sent, "Failed to send Ether");
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");
            require(paymentGasAmount >= amount, "");
            IERC20(tokenAdress).transfer(msg.sender, amount);
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
        uint256 gasLimit
    ) external override {
        uint256 gasTotal = 0;
        // uint256[] memory arr = Utils.decodeUints(data);
        (uint256[] memory arr, bytes[] memory executeDataArray) = Utils._decodeTwoArr(data);

        require(arr.length == executeDataArray.length, "arr is empty");

        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > 0) {
                uint256 before = gasleft();
                execFlow(keeper, arr[i], executeDataArray[i]);
                if (gasTotal + before - gasleft() > gasLimit) {
                    return;
                }
            }
        }
    }

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory execData
    ) public override nonReentrant {
        KeepStruct memory ks = config.getKeepBot(msg.sender);

        require(ks.isActive, "exect keeper is not whitelist");

        uint256 before = gasleft();

        EvaFlowMeta memory flow = _flowMetas[flowId];

        require(flow.admin != address(0), "task not found");
        require(flow.flowStatus == FlowStatus.Active, "task is not active");
        require((keeper != flow.lastKeeper ||  flow.keepNetWork != KeepNetWork.ChainLink), "expect next keeper");
        require(flow.maxVaildBlockNumber >= block.number, "invalid task");
        // 检查是否 flow 的网络是否和 keeper 匹配
        require(flow.keepNetWork == ks.keepNetWork, "invalid keepNetWork");

        //  flow 必须被 Safes 创建，否则无法执行execFlow
        IEvaSafes safes = IEvaSafes(flow.admin);
        bool success;
        string memory failedReason;
        try safes.execFlow(flow.lastVersionflow, execData) {
            success = true;
        } catch Error(string memory reason) {
            failedReason = reason; // revert or require
        } catch {
            failedReason = "F"; //assert
        }

        // update
        _flowMetas[flowId].lastExecNumber = block.number;
        _flowMetas[flowId].lastKeeper = keeper;

        uint256 usedGas = before - gasleft();

        uint120 payAmountByETH = 0;
        uint120 payAmountByFeeToken = 0;

        if (minConfig.feeToken == address(0)) {
            payAmountByETH = Utils.toUint120(_calculatePaymentAmount(usedGas));
            uint120 bal = userMetaMap[flow.admin].ethBal;

            if (tx.origin == address(0)) {
                //是默认交易，在check完成后将模拟调用
                require(bal >= payAmountByETH, "insufficient fund");
            }

            userMetaMap[flow.admin].ethBal = bal < payAmountByETH ? 0 : bal - payAmountByETH;
        } else {
            revert("TODO");
        }

        if (success) {
            emit FlowExecuteSuccess(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas);
        } else {
            emit FlowExecuteFailed(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas, failedReason);
        }
    }

    function _calculatePaymentAmount(uint256 gasLimit) private view returns (uint96 payment) {
        uint256 total;

        uint256 weiForGas = tx.gasprice * (gasLimit + _REGISTRY_GAS_OVERHEAD);
        // uint256 premium = minConfig.add(config.paymentPremiumPPB);
        total = weiForGas * (minConfig.ppb);

        //require(total <= LINK_TOTAL_SUPPLY, "payment greater than all LINK");
        return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
    }

    function getSafes(address user) external view override returns (address) {
        return evaSafesFactory.get(user);
    }

    function getFlowCheckInfo(uint256 flowId) external view override returns (address flow, bytes memory checkData) {
        flow = _flowMetas[flowId].lastVersionflow;
        checkData = _flowMetas[flowId].checkData;
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
    event FlowPaused(address indexed user, uint256 flowId);
    event FlowStart(address indexed user, uint256 flowId);
    event FlowDestroyed(address indexed user, uint256 flowId);
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

    function startFlow(uint256 flowId) external;

    function pauseFlow(uint256 flowId) external;

    function destroyFlow(uint256 flowId) external;

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

    function withdrawFundByUser(address tokenAdress, uint256 amount) external;

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

    event WalletCreated(address indexed user, address wallet, uint256);

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
        require(value != uint256(0), "LibAddressSet: value can't be 0x0");
        require(!contains(self, value), "LibAddressSet: value already exists in the set.");
        self.values.push(value);
        self.indexMapping[value] = self.values.length;
    }

    function contains(UintSet storage self, uint256 value) internal view returns (bool) {
        return self.indexMapping[value] != 0;
    }

    function remove(UintSet storage self, uint256 value) internal {
        require(contains(self, value), "LibAddressSet: value doesn't exist.");
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

    function execFlow(address flow, bytes calldata execData) external;

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

    // event SetMinGasTokenBal(address indexed user, uint256 amount);
    // event SetMinGasEthBal(address indexed user, uint256 amount);
    // event SetFeeToken(address indexed user, address feeToken);

    // event SetWalletFactory(address indexed user, address factory);
    event SetControl(address indexed user, address control);
    event SetBatchFlowNum(address indexed user, uint32 num);

    function control() external view returns (address);

    function setControl(address control_) external;

    // function getWalletFactory() external view returns (address);

    // function setWalletFactory(address factory) external;

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

    // function getKeepBotSize() external view returns (uint32);

    // function getAllKeepBots() external returns (address[] memory);

    // function setMinGasTokenBal(uint256 amount) external;

    // function setMinGasEthBal(uint256 amount) external;

    // function setFeeToken(address feeToken) external;

    // function getMinGasTokenBal() external view returns (uint256);

    // function getMinGasEthBal() external view returns (uint256);

    // function setFeeRecived(address feeRecived) external;

    // function setPaymentPrePPB(uint256 amount) external;

    // function setBlockCountPerTurn(uint256 count) external;

    // function getFeeToken() external view returns (address);

    // function getFeeRecived() external view returns (address);

    // event SetPaymentPrePPB(address indexed user, uint256 amount);
    // event SetFeeRecived(address indexed user, address feeRecived);
    // event SetBlockCountPerTurn(address indexed user, uint256 count);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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