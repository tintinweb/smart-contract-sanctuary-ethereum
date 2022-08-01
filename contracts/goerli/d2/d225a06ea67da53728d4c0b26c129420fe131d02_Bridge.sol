// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./proxies/CommonOwnerProxy.sol";
import "./proxies/BridgeOwnerProxy.sol";
import "./proxies/MessageOwnerProxy.sol";
import "./proxies/SgnOwnerProxy.sol";
import "./proxies/UpgradeableOwnerProxy.sol";

contract GovernedOwnerProxy is
    CommonOwnerProxy,
    BridgeOwnerProxy,
    MessageOwnerProxy,
    SgnOwnerProxy,
    UpgradeableOwnerProxy
{
    constructor(address _initializer) OwnerProxyBase(_initializer) {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./OwnerProxyBase.sol";
import "../interfaces/ICommonOwner.sol";
import {SimpleGovernance as sg} from "../SimpleGovernance.sol";
import {OwnerDataTypes as dt} from "./OwnerDataTypes.sol";

abstract contract CommonOwnerProxy is OwnerProxyBase {
    event TransferOwnershipProposalCreated(uint256 proposalId, address target, uint256 newOwner);
    event UpdatePauserProposalCreated(uint256 proposalId, address target, dt.Action action, address account);

    function proposeTransferOwnership(address _target, uint256 _newOwner) external {
        bytes memory data = abi.encodeWithSelector(ICommonOwner.transferOwnership.selector, _newOwner);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit TransferOwnershipProposalCreated(proposalId, _target, _newOwner);
    }

    function proposeUpdatePauser(
        address _target,
        dt.Action _action,
        address _account
    ) external {
        bytes4 selector;
        if (_action == dt.Action.Add) {
            selector = ICommonOwner.addPauser.selector;
        } else if (_action == dt.Action.Remove) {
            selector = ICommonOwner.removePauser.selector;
        } else {
            revert("invalid action");
        }
        bytes memory data = abi.encodeWithSelector(selector, _account);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalFastPass);
        emit UpdatePauserProposalCreated(proposalId, _target, _action, _account);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./OwnerProxyBase.sol";
import "../interfaces/IBridgeOwner.sol";
import {SimpleGovernance as sg} from "../SimpleGovernance.sol";
import {OwnerDataTypes as dt} from "./OwnerDataTypes.sol";

abstract contract BridgeOwnerProxy is OwnerProxyBase {
    // for bridges
    event ResetSignersProposalCreated(uint256 proposalId, address target, address[] signers, uint256[] powers);
    event NotifyResetSignersProposalCreated(uint256 proposalId, address target);
    event IncreaseNoticePeriodProposalCreated(uint256 proposalId, address target, uint256 period);
    event SetNativeWrapProposalCreated(uint256 proposalId, address target, address token);
    event UpdateSupplyProposalCreated(
        uint256 proposalId,
        address target,
        dt.Action action,
        address token,
        uint256 supply
    );
    event UpdateGovernorProposalCreated(uint256 proposalId, address target, dt.Action action, address account);

    // for bridge tokens
    event UpdateBridgeProposalCreated(uint256 proposalId, address target, address bridgeAddr);
    event UpdateBridgeSupplyCapProposalCreated(uint256 proposalId, address target, address bridge, uint256 cap);
    event SetBridgeTokenSwapCapProposalCreated(uint256 proposalId, address target, address bridgeToken, uint256 cap);

    function proposeResetSigners(
        address _target,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes memory data = abi.encodeWithSelector(IBridgeOwner.resetSigners.selector, _signers, _powers);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit ResetSignersProposalCreated(proposalId, _target, _signers, _powers);
    }

    function proposeNotifyResetSigners(address _target) external {
        bytes memory data = abi.encodeWithSelector(IBridgeOwner.notifyResetSigners.selector);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalFastPass);
        emit NotifyResetSignersProposalCreated(proposalId, _target);
    }

    function proposeIncreaseNoticePeriod(address _target, uint256 _period) external {
        bytes memory data = abi.encodeWithSelector(IBridgeOwner.increaseNoticePeriod.selector, _period);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit IncreaseNoticePeriodProposalCreated(proposalId, _target, _period);
    }

    function proposeSetNativeWrap(address _target, address _token) external {
        bytes memory data = abi.encodeWithSelector(IBridgeOwner.setWrap.selector, _token);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetNativeWrapProposalCreated(proposalId, _target, _token);
    }

    function proposeUpdateSupply(
        address _target,
        dt.Action _action,
        address _token,
        uint256 _supply
    ) external {
        bytes4 selector;
        if (_action == dt.Action.Set) {
            selector = IBridgeOwner.setSupply.selector;
        } else if (_action == dt.Action.Add) {
            selector = IBridgeOwner.increaseSupply.selector;
        } else if (_action == dt.Action.Remove) {
            selector = IBridgeOwner.decreaseSupply.selector;
        } else {
            revert("invalid action");
        }
        bytes memory data = abi.encodeWithSelector(selector, _token, _supply);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalFastPass);
        emit UpdateSupplyProposalCreated(proposalId, _target, _action, _token, _supply);
    }

    function proposeUpdateGovernor(
        address _target,
        dt.Action _action,
        address _account
    ) external {
        bytes4 selector;
        if (_action == dt.Action.Add) {
            selector = IBridgeOwner.addGovernor.selector;
        } else if (_action == dt.Action.Remove) {
            selector = IBridgeOwner.removeGovernor.selector;
        } else {
            revert("invalid action");
        }
        bytes memory data = abi.encodeWithSelector(selector, _account);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalFastPass);
        emit UpdateGovernorProposalCreated(proposalId, _target, _action, _account);
    }

    function proposeUpdateBridgeSupplyCap(
        address _target,
        address _bridge,
        uint256 _cap
    ) external {
        bytes memory data = abi.encodeWithSelector(IBridgeOwner.updateBridgeSupplyCap.selector, _bridge, _cap);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit UpdateBridgeSupplyCapProposalCreated(proposalId, _target, _bridge, _cap);
    }

    function proposeSetBridgeTokenSwapCap(
        address _target,
        address _bridgeToken,
        uint256 _swapCap
    ) external {
        bytes memory data = abi.encodeWithSelector(IBridgeOwner.setBridgeTokenSwapCap.selector, _bridgeToken, _swapCap);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetBridgeTokenSwapCapProposalCreated(proposalId, _target, _bridgeToken, _swapCap);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./OwnerProxyBase.sol";
import "../interfaces/IMessageOwner.sol";
import {SimpleGovernance as sg} from "../SimpleGovernance.sol";
import {OwnerDataTypes as dt} from "./OwnerDataTypes.sol";

abstract contract MessageOwnerProxy is OwnerProxyBase {
    event SetMsgFeeProposalCreated(uint256 proposalId, address target, dt.MsgFeeType feeType, uint256 fee);
    event SetBridgeAddressProposalCreated(
        uint256 proposalId,
        address target,
        dt.BridgeType bridgeType,
        address bridgeAddr
    );
    event SetPreExecuteMessageGasUsageProposalCreated(uint256 proposalId, address target, uint256 usage);

    function proposeSetMsgFee(
        address _target,
        dt.MsgFeeType _feeType,
        uint256 _fee
    ) external {
        bytes4 selector;
        if (_feeType == dt.MsgFeeType.PerByte) {
            selector = IMessageOwner.setFeePerByte.selector;
        } else if (_feeType == dt.MsgFeeType.Base) {
            selector = IMessageOwner.setFeeBase.selector;
        } else {
            revert("invalid fee type");
        }
        bytes memory data = abi.encodeWithSelector(selector, _fee);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalFastPass);
        emit SetMsgFeeProposalCreated(proposalId, _target, _feeType, _fee);
    }

    function proposeSetBridgeAddress(
        address _target,
        dt.BridgeType _bridgeType,
        address _bridgeAddr
    ) external {
        bytes4 selector;
        if (_bridgeType == dt.BridgeType.Liquidity) {
            selector = IMessageOwner.setLiquidityBridge.selector;
        } else if (_bridgeType == dt.BridgeType.PegBridge) {
            selector = IMessageOwner.setPegBridge.selector;
        } else if (_bridgeType == dt.BridgeType.PegVault) {
            selector = IMessageOwner.setPegVault.selector;
        } else if (_bridgeType == dt.BridgeType.PegBridgeV2) {
            selector = IMessageOwner.setPegBridgeV2.selector;
        } else if (_bridgeType == dt.BridgeType.PegVaultV2) {
            selector = IMessageOwner.setPegVaultV2.selector;
        } else {
            revert("invalid bridge type");
        }
        bytes memory data = abi.encodeWithSelector(selector, _bridgeAddr);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetBridgeAddressProposalCreated(proposalId, _target, _bridgeType, _bridgeAddr);
    }

    function proposeSetPreExecuteMessageGasUsage(address _target, uint256 _usage) external {
        bytes memory data = abi.encodeWithSelector(IMessageOwner.setPreExecuteMessageGasUsage.selector, _usage);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetPreExecuteMessageGasUsageProposalCreated(proposalId, _target, _usage);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./OwnerProxyBase.sol";
import "../interfaces/ISgnOwner.sol";
import {SimpleGovernance as sg} from "../SimpleGovernance.sol";
import {OwnerDataTypes as dt} from "./OwnerDataTypes.sol";

abstract contract SgnOwnerProxy is OwnerProxyBase {
    event SetWhitelistEnableProposalCreated(uint256 proposalId, address target, bool enabled);
    event UpdateWhitelistedProposalCreated(uint256 proposalId, address target, dt.Action action, address account);
    event SetGovContractProposalCreated(uint256 proposalId, address target, address addr);
    event SetRewardContractProposalCreated(uint256 proposalId, address target, address addr);
    event SetMaxSlashFactorProposalCreated(uint256 proposalId, address target, uint256 maxSlashFactor);
    event DrainTokenProposalCreated(uint256 proposalId, address target, address token, uint256 amount);

    function proposeSetWhitelistEnable(address _target, bool _enable) external {
        bytes memory data = abi.encodeWithSelector(ISgnOwner.setWhitelistEnabled.selector, _enable);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetWhitelistEnableProposalCreated(proposalId, _target, _enable);
    }

    function proposeUpdateWhitelisted(
        address _target,
        dt.Action _action,
        address _account
    ) external {
        bytes4 selector;
        if (_action == dt.Action.Add) {
            selector = ISgnOwner.addWhitelisted.selector;
        } else if (_action == dt.Action.Remove) {
            selector = ISgnOwner.removeWhitelisted.selector;
        } else {
            revert("invalid action");
        }
        bytes memory data = abi.encodeWithSelector(selector, _account);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalFastPass);
        emit UpdateWhitelistedProposalCreated(proposalId, _target, _action, _account);
    }

    function proposeSetGovContract(address _target, address _addr) external {
        bytes memory data = abi.encodeWithSelector(ISgnOwner.setGovContract.selector, _addr);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetGovContractProposalCreated(proposalId, _target, _addr);
    }

    function proposeSetRewardContract(address _target, address _addr) external {
        bytes memory data = abi.encodeWithSelector(ISgnOwner.setRewardContract.selector, _addr);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetRewardContractProposalCreated(proposalId, _target, _addr);
    }

    function proposeSetMaxSlashFactor(address _target, uint256 _maxSlashFactor) external {
        bytes memory data = abi.encodeWithSelector(ISgnOwner.setMaxSlashFactor.selector, _maxSlashFactor);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit SetMaxSlashFactorProposalCreated(proposalId, _target, _maxSlashFactor);
    }

    function proposeDrainToken(
        address _target,
        address _token,
        uint256 _amount
    ) external {
        bytes memory data;
        if (_token == address(0)) {
            data = abi.encodeWithSelector(bytes4(keccak256(bytes("drainToken(uint256"))), _amount);
        } else {
            data = abi.encodeWithSelector(bytes4(keccak256(bytes("drainToken(address,uint256"))), _token, _amount);
        }
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit DrainTokenProposalCreated(proposalId, _target, _token, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./OwnerProxyBase.sol";
import "../interfaces/IUpgradeableOwner.sol";
import {SimpleGovernance as sg} from "../SimpleGovernance.sol";
import {OwnerDataTypes as dt} from "./OwnerDataTypes.sol";

abstract contract UpgradeableOwnerProxy is OwnerProxyBase {
    event ChangeProxyAdminProposalCreated(uint256 proposalId, address target, address proxy, address newAdmin);
    event UpgradeProposalCreated(uint256 proposalId, address target, address proxy, address implementation);
    event UpgradeAndCallProposalCreated(
        uint256 proposalId,
        address target,
        address proxy,
        address implementation,
        bytes data
    );
    event UpgradeToProposalCreated(uint256 proposalId, address target, address implementation);
    event UpgradeToAndCallProposalCreated(uint256 proposalId, address target, address implementation, bytes data);

    function proposeChangeProxyAdmin(
        address _target,
        address _proxy,
        address _newAdmin
    ) external {
        bytes memory data = abi.encodeWithSelector(IUpgradeableOwner.changeProxyAdmin.selector, _proxy, _newAdmin);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit ChangeProxyAdminProposalCreated(proposalId, _target, _proxy, _newAdmin);
    }

    function proposeUpgrade(
        address _target,
        address _proxy,
        address _implementation
    ) external {
        bytes memory data = abi.encodeWithSelector(IUpgradeableOwner.upgrade.selector, _proxy, _implementation);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit UpgradeProposalCreated(proposalId, _target, _proxy, _implementation);
    }

    function proposeUpgradeAndCall(
        address _target,
        address _proxy,
        address _implementation,
        bytes calldata _data
    ) external {
        bytes memory data = abi.encodeWithSelector(
            IUpgradeableOwner.upgradeAndCall.selector,
            _proxy,
            _implementation,
            _data
        );
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit UpgradeAndCallProposalCreated(proposalId, _target, _proxy, _implementation, _data);
    }

    function proposeUpgradeTo(address _target, address _implementation) external {
        bytes memory data = abi.encodeWithSelector(IUpgradeableOwner.upgradeTo.selector, _implementation);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit UpgradeToProposalCreated(proposalId, _target, _implementation);
    }

    function proposeUpgradeToAndCall(
        address _target,
        address _implementation,
        bytes calldata _data
    ) external {
        bytes memory data = abi.encodeWithSelector(IUpgradeableOwner.upgradeToAndCall.selector, _implementation, _data);
        uint256 proposalId = gov.createProposal(msg.sender, _target, data, sg.ProposalType.ExternalDefault);
        emit UpgradeToAndCallProposalCreated(proposalId, _target, _implementation, _data);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../SimpleGovernance.sol";

abstract contract OwnerProxyBase {
    SimpleGovernance public gov;
    address private initializer;

    constructor(address _initializer) {
        initializer = _initializer;
    }

    function initGov(SimpleGovernance _gov) public {
        require(msg.sender == initializer, "only initializer can init");
        require(address(gov) == address(0), "gov addr already set");
        gov = _gov;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ICommonOwner {
    function transferOwnership(address _newOwner) external;

    function addPauser(address _account) external;

    function removePauser(address _account) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// mainly used for governed-owner to do infrequent sgn/cbridge owner operations,
// relatively prefer easy-to-use over gas-efficiency
contract SimpleGovernance {
    uint256 public constant THRESHOLD_DECIMAL = 100;
    uint256 public constant MIN_ACTIVE_PERIOD = 3600; // one hour
    uint256 public constant MAX_ACTIVE_PERIOD = 2419200; // four weeks

    using SafeERC20 for IERC20;

    enum ParamName {
        ActivePeriod,
        QuorumThreshold, // default threshold for votes to pass
        FastPassThreshold // lower threshold for less critical operations
    }

    enum ProposalType {
        ExternalDefault,
        ExternalFastPass,
        InternalParamChange,
        InternalVoterUpdate,
        InternalProxyUpdate,
        InternalTransferToken
    }

    mapping(ParamName => uint256) public params;

    struct Proposal {
        bytes32 dataHash; // hash(proposalType, targetAddress, calldata)
        uint256 deadline;
        mapping(address => bool) votes;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    address[] public voters;
    mapping(address => uint256) public voterPowers; // voter addr -> voting power

    // NOTE: proxies must be audited open-source non-upgradable contracts with following requirements:
    // 1. Truthfully pass along tx sender who called the proxy function as the governance proposer.
    // 2. Do not allow arbitrary fastpass proposal with calldata constructed by the proxy callers.
    // See ./proxies/CommonOwnerProxy.sol for example.
    mapping(address => bool) public proposerProxies;

    event Initiated(
        address[] voters,
        uint256[] powers,
        address[] proxies,
        uint256 activePeriod,
        uint256 quorumThreshold,
        uint256 fastPassThreshold
    );

    event ProposalCreated(
        uint256 proposalId,
        ProposalType proposalType,
        address target,
        bytes data,
        uint256 deadline,
        address proposer
    );
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    event ParamChangeProposalCreated(uint256 proposalId, ParamName name, uint256 value);
    event VoterUpdateProposalCreated(uint256 proposalId, address[] voters, uint256[] powers);
    event ProxyUpdateProposalCreated(uint256 proposalId, address[] addrs, bool[] ops);
    event TransferTokenProposalCreated(uint256 proposalId, address receiver, address token, uint256 amount);

    constructor(
        address[] memory _voters,
        uint256[] memory _powers,
        address[] memory _proxies,
        uint256 _activePeriod,
        uint256 _quorumThreshold,
        uint256 _fastPassThreshold
    ) {
        require(_voters.length > 0 && _voters.length == _powers.length, "invalid init voters");
        require(_activePeriod <= MAX_ACTIVE_PERIOD && _activePeriod >= MIN_ACTIVE_PERIOD, "invalid active period");
        require(
            _quorumThreshold < THRESHOLD_DECIMAL && _fastPassThreshold <= _quorumThreshold,
            "invalid init thresholds"
        );
        for (uint256 i = 0; i < _voters.length; i++) {
            _setVoter(_voters[i], _powers[i]);
        }
        for (uint256 i = 0; i < _proxies.length; i++) {
            proposerProxies[_proxies[i]] = true;
        }
        params[ParamName.ActivePeriod] = _activePeriod;
        params[ParamName.QuorumThreshold] = _quorumThreshold;
        params[ParamName.FastPassThreshold] = _fastPassThreshold;
        emit Initiated(_voters, _powers, _proxies, _activePeriod, _quorumThreshold, _fastPassThreshold);
    }

    /*********************************
     * External and Public Functions *
     *********************************/

    function createProposal(address _target, bytes memory _data) external returns (uint256) {
        return _createProposal(msg.sender, _target, _data, ProposalType.ExternalDefault);
    }

    // create proposal through proxy
    function createProposal(
        address _proposer,
        address _target,
        bytes memory _data,
        ProposalType _type
    ) external returns (uint256) {
        require(proposerProxies[msg.sender], "sender is not a valid proxy");
        require(_type == ProposalType.ExternalDefault || _type == ProposalType.ExternalFastPass, "invalid type");
        return _createProposal(_proposer, _target, _data, _type);
    }

    function createParamChangeProposal(ParamName _name, uint256 _value) external returns (uint256) {
        bytes memory data = abi.encode(_name, _value);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalParamChange);
        emit ParamChangeProposalCreated(proposalId, _name, _value);
        return proposalId;
    }

    function createVoterUpdateProposal(address[] calldata _voters, uint256[] calldata _powers)
        external
        returns (uint256)
    {
        require(_voters.length == _powers.length, "voters and powers length not match");
        bytes memory data = abi.encode(_voters, _powers);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalVoterUpdate);
        emit VoterUpdateProposalCreated(proposalId, _voters, _powers);
        return proposalId;
    }

    function createProxyUpdateProposal(address[] calldata _addrs, bool[] calldata _ops) external returns (uint256) {
        require(_addrs.length == _ops.length, "_addrs and _ops length not match");
        bytes memory data = abi.encode(_addrs, _ops);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalProxyUpdate);
        emit ProxyUpdateProposalCreated(proposalId, _addrs, _ops);
        return proposalId;
    }

    function createTransferTokenProposal(
        address _receiver,
        address _token,
        uint256 _amount
    ) external returns (uint256) {
        bytes memory data = abi.encode(_receiver, _token, _amount);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalTransferToken);
        emit TransferTokenProposalCreated(proposalId, _receiver, _token, _amount);
        return proposalId;
    }

    function voteProposal(uint256 _proposalId, bool _vote) external {
        require(voterPowers[msg.sender] > 0, "invalid voter");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "deadline passed");
        p.votes[msg.sender] = _vote;
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(
        uint256 _proposalId,
        ProposalType _type,
        address _target,
        bytes calldata _data
    ) external {
        require(voterPowers[msg.sender] > 0, "only voter can execute a proposal");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "deadline passed");
        require(keccak256(abi.encodePacked(_type, _target, _data)) == p.dataHash, "data hash not match");
        p.deadline = 0;

        p.votes[msg.sender] = true;
        (, , bool pass) = countVotes(_proposalId, _type);
        require(pass, "not enough votes");

        if (_type == ProposalType.ExternalDefault || _type == ProposalType.ExternalFastPass) {
            (bool success, bytes memory res) = _target.call(_data);
            require(success, _getRevertMsg(res));
        } else if (_type == ProposalType.InternalParamChange) {
            (ParamName name, uint256 value) = abi.decode((_data), (ParamName, uint256));
            params[name] = value;
            if (name == ParamName.ActivePeriod) {
                require(value <= MAX_ACTIVE_PERIOD && value >= MIN_ACTIVE_PERIOD, "invalid active period");
            } else if (name == ParamName.QuorumThreshold || name == ParamName.FastPassThreshold) {
                require(
                    params[ParamName.QuorumThreshold] >= params[ParamName.FastPassThreshold] &&
                        value < THRESHOLD_DECIMAL &&
                        value > 0,
                    "invalid threshold"
                );
            }
        } else if (_type == ProposalType.InternalVoterUpdate) {
            (address[] memory addrs, uint256[] memory powers) = abi.decode((_data), (address[], uint256[]));
            for (uint256 i = 0; i < addrs.length; i++) {
                if (powers[i] > 0) {
                    _setVoter(addrs[i], powers[i]);
                } else {
                    _removeVoter(addrs[i]);
                }
            }
        } else if (_type == ProposalType.InternalProxyUpdate) {
            (address[] memory addrs, bool[] memory ops) = abi.decode((_data), (address[], bool[]));
            for (uint256 i = 0; i < addrs.length; i++) {
                if (ops[i]) {
                    proposerProxies[addrs[i]] = true;
                } else {
                    delete proposerProxies[addrs[i]];
                }
            }
        } else if (_type == ProposalType.InternalTransferToken) {
            (address receiver, address token, uint256 amount) = abi.decode((_data), (address, address, uint256));
            _transfer(receiver, token, amount);
        }
        emit ProposalExecuted(_proposalId);
    }

    receive() external payable {}

    /**************************
     *  Public View Functions *
     **************************/

    function getVoters() public view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](voters.length);
        uint256[] memory powers = new uint256[](voters.length);
        for (uint32 i = 0; i < voters.length; i++) {
            addrs[i] = voters[i];
            powers[i] = voterPowers[voters[i]];
        }
        return (addrs, powers);
    }

    function getVote(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposals[_proposalId].votes[_voter];
    }

    function countVotes(uint256 _proposalId, ProposalType _type)
        public
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        uint256 yesVotes;
        uint256 totalPower;
        for (uint32 i = 0; i < voters.length; i++) {
            if (getVote(_proposalId, voters[i])) {
                yesVotes += voterPowers[voters[i]];
            }
            totalPower += voterPowers[voters[i]];
        }
        uint256 threshold;
        if (_type == ProposalType.ExternalFastPass) {
            threshold = params[ParamName.FastPassThreshold];
        } else {
            threshold = params[ParamName.QuorumThreshold];
        }
        bool pass = (yesVotes >= (totalPower * threshold) / THRESHOLD_DECIMAL);
        return (totalPower, yesVotes, pass);
    }

    /**********************************
     * Internal and Private Functions *
     **********************************/

    // create a proposal and vote yes
    function _createProposal(
        address _proposer,
        address _target,
        bytes memory _data,
        ProposalType _type
    ) private returns (uint256) {
        require(voterPowers[_proposer] > 0, "only voter can create a proposal");
        uint256 proposalId = nextProposalId;
        nextProposalId += 1;
        Proposal storage p = proposals[proposalId];
        p.dataHash = keccak256(abi.encodePacked(_type, _target, _data));
        p.deadline = block.timestamp + params[ParamName.ActivePeriod];
        p.votes[_proposer] = true;
        emit ProposalCreated(proposalId, _type, _target, _data, p.deadline, _proposer);
        return proposalId;
    }

    function _setVoter(address _voter, uint256 _power) private {
        require(_power > 0, "zero power");
        if (voterPowers[_voter] == 0) {
            // add new voter
            voters.push(_voter);
        }
        voterPowers[_voter] = _power;
    }

    function _removeVoter(address _voter) private {
        require(voterPowers[_voter] > 0, "not a voter");
        uint256 lastIndex = voters.length - 1;
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _voter) {
                if (i < lastIndex) {
                    voters[i] = voters[lastIndex];
                }
                voters.pop();
                voterPowers[_voter] = 0;
                return;
            }
        }
        revert("voter not found"); // this should never happen
    }

    function _transfer(
        address _receiver,
        address _token,
        uint256 _amount
    ) private {
        if (_token == address(0)) {
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "failed to send native token");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function _getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

library OwnerDataTypes {
    enum Action {
        Set,
        Add,
        Remove
    }

    enum MsgFeeType {
        PerByte,
        Base
    }

    enum BridgeType {
        Liquidity,
        PegBridge,
        PegVault,
        PegBridgeV2,
        PegVaultV2
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridgeOwner {
    // for bridges

    function resetSigners(address[] calldata _signers, uint256[] calldata _powers) external;

    function notifyResetSigners() external;

    function increaseNoticePeriod(uint256 _period) external;

    function setWrap(address _token) external;

    function setSupply(address _token, uint256 _supply) external;

    function increaseSupply(address _token, uint256 _delta) external;

    function decreaseSupply(address _token, uint256 _delta) external;

    function addGovernor(address _account) external;

    function removeGovernor(address _account) external;

    // for bridge tokens

    function updateBridge(address _bridge) external;

    function updateBridgeSupplyCap(address _bridge, uint256 _cap) external;

    function setBridgeTokenSwapCap(address _bridgeToken, uint256 _swapCap) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageOwner {
    function setFeePerByte(uint256 _fee) external;

    function setFeeBase(uint256 _fee) external;

    function setLiquidityBridge(address _addr) external;

    function setPegBridge(address _addr) external;

    function setPegVault(address _addr) external;

    function setPegBridgeV2(address _addr) external;

    function setPegVaultV2(address _addr) external;

    function setPreExecuteMessageGasUsage(uint256 _usage) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ISgnOwner {
    function setWhitelistEnabled(bool _whitelistEnabled) external;

    function addWhitelisted(address _account) external;

    function removeWhitelisted(address _account) external;

    function setGovContract(address _addr) external;

    function setRewardContract(address _addr) external;

    function setMaxSlashFactor(uint256 _maxSlashFactor) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IUpgradeableOwner {
    function changeProxyAdmin(address _proxy, address _newAdmin) external;

    function upgrade(address _proxy, address _implementation) external;

    function upgradeAndCall(
        address _proxy,
        address _implementation,
        bytes calldata _data
    ) external;

    function upgradeTo(address _implementation) external;

    function upgradeToAndCall(address _implementation, bytes calldata _data) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DummySwap {
    using SafeERC20 for IERC20;

    uint256 fakeSlippage; // 100% = 100 * 1e4
    uint256 hundredPercent = 100 * 1e4;

    constructor(uint256 _fakeSlippage) {
        fakeSlippage = _fakeSlippage;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline != 0 && deadline > block.timestamp, "deadline exceeded");
        require(path.length > 1, "path must have more than 1 token in it");
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        // fake simulate slippage
        uint256 amountAfterSlippage = (amountIn * (hundredPercent - fakeSlippage)) / hundredPercent;
        require(amountAfterSlippage > amountOutMin, "bad slippage");

        IERC20(path[path.length - 1]).safeTransfer(to, amountAfterSlippage);
        uint256[] memory ret = new uint256[](2);
        ret[0] = amountIn;
        ret[1] = amountAfterSlippage;
        return ret;
    }

    function setFakeSlippage(uint256 _fakeSlippage) public {
        fakeSlippage = _fakeSlippage;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes as dt} from "./DataTypes.sol";
import "../safeguard/Pauser.sol";
import "./Staking.sol";

/**
 * @title A contract to hold and distribute CELR staking rewards.
 */
contract StakingReward is Pauser {
    using SafeERC20 for IERC20;

    Staking public immutable staking;

    // recipient => CELR reward amount
    mapping(address => uint256) public claimedRewardAmounts;

    event StakingRewardClaimed(address indexed recipient, uint256 reward);
    event StakingRewardContributed(address indexed contributor, uint256 contribution);

    constructor(Staking _staking) {
        staking = _staking;
    }

    /**
     * @notice Claim reward
     * @dev Here we use cumulative reward to make claim process idempotent
     * @param _rewardRequest reward request bytes coded in protobuf
     * @param _sigs list of validator signatures
     */
    function claimReward(bytes calldata _rewardRequest, bytes[] calldata _sigs) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "StakingReward"));
        staking.verifySignatures(abi.encodePacked(domain, _rewardRequest), _sigs);
        PbStaking.StakingReward memory reward = PbStaking.decStakingReward(_rewardRequest);

        uint256 cumulativeRewardAmount = reward.cumulativeRewardAmount;
        uint256 newReward = cumulativeRewardAmount - claimedRewardAmounts[reward.recipient];
        require(newReward > 0, "No new reward");
        claimedRewardAmounts[reward.recipient] = cumulativeRewardAmount;
        staking.CELER_TOKEN().safeTransfer(reward.recipient, newReward);
        emit StakingRewardClaimed(reward.recipient, newReward);
    }

    /**
     * @notice Contribute CELR tokens to the reward pool
     * @param _amount the amount of CELR token to contribute
     */
    function contributeToRewardPool(uint256 _amount) external whenNotPaused {
        address contributor = msg.sender;
        IERC20(staking.CELER_TOKEN()).safeTransferFrom(contributor, address(this), _amount);

        emit StakingRewardContributed(contributor, _amount);
    }

    /**
     * @notice Owner drains CELR tokens when the contract is paused
     * @dev emergency use only
     * @param _amount drained CELR token amount
     */
    function drainToken(uint256 _amount) external whenPaused onlyOwner {
        IERC20(staking.CELER_TOKEN()).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

library DataTypes {
    uint256 constant CELR_DECIMAL = 1e18;
    uint256 constant MAX_INT = 2**256 - 1;
    uint256 constant COMMISSION_RATE_BASE = 10000; // 1 commissionRate means 0.01%
    uint256 constant MAX_UNDELEGATION_ENTRIES = 10;
    uint256 constant SLASH_FACTOR_DECIMAL = 1e6;

    enum ValidatorStatus {
        Null,
        Unbonded,
        Unbonding,
        Bonded
    }

    enum ParamName {
        ProposalDeposit,
        VotingPeriod,
        UnbondingPeriod,
        MaxBondedValidators,
        MinValidatorTokens,
        MinSelfDelegation,
        AdvanceNoticePeriod,
        ValidatorBondInterval,
        MaxSlashFactor
    }

    struct Undelegation {
        uint256 shares;
        uint256 creationBlock;
    }

    struct Undelegations {
        mapping(uint256 => Undelegation) queue;
        uint32 head;
        uint32 tail;
    }

    struct Delegator {
        uint256 shares;
        Undelegations undelegations;
    }

    struct Validator {
        ValidatorStatus status;
        address signer;
        uint256 tokens; // sum of all tokens delegated to this validator
        uint256 shares; // sum of all delegation shares
        uint256 undelegationTokens; // tokens being undelegated
        uint256 undelegationShares; // shares of tokens being undelegated
        mapping(address => Delegator) delegators;
        uint256 minSelfDelegation;
        uint64 bondBlock; // cannot become bonded before this block
        uint64 unbondBlock; // cannot become unbonded before this block
        uint64 commissionRate; // equal to real commission rate * COMMISSION_RATE_BASE
    }

    // used for external view output
    struct ValidatorTokens {
        address valAddr;
        uint256 tokens;
    }

    // used for external view output
    struct ValidatorInfo {
        address valAddr;
        ValidatorStatus status;
        address signer;
        uint256 tokens;
        uint256 shares;
        uint256 minSelfDelegation;
        uint64 commissionRate;
    }

    // used for external view output
    struct DelegatorInfo {
        address valAddr;
        uint256 tokens;
        uint256 shares;
        Undelegation[] undelegations;
        uint256 undelegationTokens;
        uint256 withdrawableUndelegationTokens;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./Ownable.sol";

abstract contract Pauser is Ownable, Pausable {
    mapping(address => bool) public pausers;

    event PauserAdded(address account);
    event PauserRemoved(address account);

    constructor() {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "Caller is not pauser");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function isPauser(address account) public view returns (bool) {
        return pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) private {
        require(!isPauser(account), "Account is already pauser");
        pausers[account] = true;
        emit PauserAdded(account);
    }

    function _removePauser(address account) private {
        require(isPauser(account), "Account is not pauser");
        pausers[account] = false;
        emit PauserRemoved(account);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DataTypes as dt} from "./DataTypes.sol";
import "../interfaces/ISigsVerifier.sol";
import "../libraries/PbStaking.sol";
import "../safeguard/Pauser.sol";
import "../safeguard/Whitelist.sol";

/**
 * @title A Staking contract shared by all external sidechains and apps
 */
contract Staking is ISigsVerifier, Pauser, Whitelist {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    IERC20 public immutable CELER_TOKEN;

    uint256 public bondedTokens;
    uint256 public nextBondBlock;
    address[] public valAddrs;
    address[] public bondedValAddrs;
    mapping(address => dt.Validator) public validators; // key is valAddr
    mapping(address => address) public signerVals; // signerAddr -> valAddr
    mapping(uint256 => bool) public slashNonces;

    mapping(dt.ParamName => uint256) public params;
    address public govContract;
    address public rewardContract;
    uint256 public forfeiture;

    /* Events */
    event ValidatorNotice(address indexed valAddr, string key, bytes data, address from);
    event ValidatorStatusUpdate(address indexed valAddr, dt.ValidatorStatus indexed status);
    event DelegationUpdate(
        address indexed valAddr,
        address indexed delAddr,
        uint256 valTokens,
        uint256 delShares,
        int256 tokenDiff
    );
    event Undelegated(address indexed valAddr, address indexed delAddr, uint256 amount);
    event Slash(address indexed valAddr, uint64 nonce, uint256 slashAmt);
    event SlashAmtCollected(address indexed recipient, uint256 amount);

    /**
     * @notice Staking constructor
     * @param _celerTokenAddress address of Celer Token Contract
     * @param _proposalDeposit required deposit amount for a governance proposal
     * @param _votingPeriod voting timeout for a governance proposal
     * @param _unbondingPeriod the locking time for funds locked before withdrawn
     * @param _maxBondedValidators the maximum number of bonded validators
     * @param _minValidatorTokens the global minimum token amount requirement for bonded validator
     * @param _minSelfDelegation minimal amount of self-delegated tokens
     * @param _advanceNoticePeriod the wait time after the announcement and prior to the effective date of an update
     * @param _validatorBondInterval min interval between bondValidator
     * @param _maxSlashFactor maximal slashing factor (1e6 = 100%)
     */
    constructor(
        address _celerTokenAddress,
        uint256 _proposalDeposit,
        uint256 _votingPeriod,
        uint256 _unbondingPeriod,
        uint256 _maxBondedValidators,
        uint256 _minValidatorTokens,
        uint256 _minSelfDelegation,
        uint256 _advanceNoticePeriod,
        uint256 _validatorBondInterval,
        uint256 _maxSlashFactor
    ) {
        CELER_TOKEN = IERC20(_celerTokenAddress);

        params[dt.ParamName.ProposalDeposit] = _proposalDeposit;
        params[dt.ParamName.VotingPeriod] = _votingPeriod;
        params[dt.ParamName.UnbondingPeriod] = _unbondingPeriod;
        params[dt.ParamName.MaxBondedValidators] = _maxBondedValidators;
        params[dt.ParamName.MinValidatorTokens] = _minValidatorTokens;
        params[dt.ParamName.MinSelfDelegation] = _minSelfDelegation;
        params[dt.ParamName.AdvanceNoticePeriod] = _advanceNoticePeriod;
        params[dt.ParamName.ValidatorBondInterval] = _validatorBondInterval;
        params[dt.ParamName.MaxSlashFactor] = _maxSlashFactor;
    }

    receive() external payable {}

    /*********************************
     * External and Public Functions *
     *********************************/

    /**
     * @notice Initialize a validator candidate
     * @param _signer signer address
     * @param _minSelfDelegation minimal amount of tokens staked by the validator itself
     * @param _commissionRate the self-declaimed commission rate
     */
    function initializeValidator(
        address _signer,
        uint256 _minSelfDelegation,
        uint64 _commissionRate
    ) external whenNotPaused onlyWhitelisted {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status == dt.ValidatorStatus.Null, "Validator is initialized");
        require(validators[_signer].status == dt.ValidatorStatus.Null, "Signer is other validator");
        require(signerVals[valAddr] == address(0), "Validator is other signer");
        require(signerVals[_signer] == address(0), "Signer already used");
        require(_commissionRate <= dt.COMMISSION_RATE_BASE, "Invalid commission rate");
        require(_minSelfDelegation >= params[dt.ParamName.MinSelfDelegation], "Insufficient min self delegation");
        validator.signer = _signer;
        validator.status = dt.ValidatorStatus.Unbonded;
        validator.minSelfDelegation = _minSelfDelegation;
        validator.commissionRate = _commissionRate;
        valAddrs.push(valAddr);
        signerVals[_signer] = valAddr;

        delegate(valAddr, _minSelfDelegation);
        emit ValidatorNotice(valAddr, "init", abi.encode(_signer, _minSelfDelegation, _commissionRate), address(0));
    }

    /**
     * @notice Update validator signer address
     * @param _signer signer address
     */
    function updateValidatorSigner(address _signer) external {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator not initialized");
        require(signerVals[_signer] == address(0), "Signer already used");
        if (_signer != valAddr) {
            require(validators[_signer].status == dt.ValidatorStatus.Null, "Signer is other validator");
        }

        delete signerVals[validator.signer];
        validator.signer = _signer;
        signerVals[_signer] = valAddr;

        emit ValidatorNotice(valAddr, "signer", abi.encode(_signer), address(0));
    }

    /**
     * @notice Candidate claims to become a bonded validator
     * @dev caller can be either validator owner or signer
     */
    function bondValidator() external {
        address valAddr = msg.sender;
        if (signerVals[msg.sender] != address(0)) {
            valAddr = signerVals[msg.sender];
        }
        dt.Validator storage validator = validators[valAddr];
        require(
            validator.status == dt.ValidatorStatus.Unbonded || validator.status == dt.ValidatorStatus.Unbonding,
            "Invalid validator status"
        );
        require(block.number >= validator.bondBlock, "Bond block not reached");
        require(block.number >= nextBondBlock, "Too frequent validator bond");
        nextBondBlock = block.number + params[dt.ParamName.ValidatorBondInterval];
        require(hasMinRequiredTokens(valAddr, true), "Not have min tokens");

        uint256 maxBondedValidators = params[dt.ParamName.MaxBondedValidators];
        // if the number of validators has not reached the max_validator_num,
        // add validator directly
        if (bondedValAddrs.length < maxBondedValidators) {
            _bondValidator(valAddr);
            _decentralizationCheck(validator.tokens);
            return;
        }
        // if the number of validators has already reached the max_validator_num,
        // add validator only if its tokens is more than the current least bonded validator tokens
        uint256 minTokens = dt.MAX_INT;
        uint256 minTokensIndex;
        for (uint256 i = 0; i < maxBondedValidators; i++) {
            if (validators[bondedValAddrs[i]].tokens < minTokens) {
                minTokensIndex = i;
                minTokens = validators[bondedValAddrs[i]].tokens;
                if (minTokens == 0) {
                    break;
                }
            }
        }
        require(validator.tokens > minTokens, "Insufficient tokens");
        _replaceBondedValidator(valAddr, minTokensIndex);
        _decentralizationCheck(validator.tokens);
    }

    /**
     * @notice Confirm validator status from Unbonding to Unbonded
     * @param _valAddr the address of the validator
     */
    function confirmUnbondedValidator(address _valAddr) external {
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status == dt.ValidatorStatus.Unbonding, "Validator not unbonding");
        require(block.number >= validator.unbondBlock, "Unbond block not reached");

        validator.status = dt.ValidatorStatus.Unbonded;
        delete validator.unbondBlock;
        emit ValidatorStatusUpdate(_valAddr, dt.ValidatorStatus.Unbonded);
    }

    /**
     * @notice Delegate CELR tokens to a validator
     * @dev Minimal amount per delegate operation is 1 CELR
     * @param _valAddr validator to delegate
     * @param _tokens the amount of delegated CELR tokens
     */
    function delegate(address _valAddr, uint256 _tokens) public whenNotPaused {
        address delAddr = msg.sender;
        require(_tokens >= dt.CELR_DECIMAL, "Minimal amount is 1 CELR");

        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        uint256 shares = _tokenToShare(_tokens, validator.tokens, validator.shares);

        dt.Delegator storage delegator = validator.delegators[delAddr];
        delegator.shares += shares;
        validator.shares += shares;
        validator.tokens += _tokens;
        if (validator.status == dt.ValidatorStatus.Bonded) {
            bondedTokens += _tokens;
            _decentralizationCheck(validator.tokens);
        }
        CELER_TOKEN.safeTransferFrom(delAddr, address(this), _tokens);
        emit DelegationUpdate(_valAddr, delAddr, validator.tokens, delegator.shares, int256(_tokens));
    }

    /**
     * @notice Undelegate shares from a validator
     * @dev Tokens are delegated by the msgSender to the validator
     * @param _valAddr the address of the validator
     * @param _shares undelegate shares
     */
    function undelegateShares(address _valAddr, uint256 _shares) external {
        require(_shares >= dt.CELR_DECIMAL, "Minimal amount is 1 share");
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        uint256 tokens = _shareToToken(_shares, validator.tokens, validator.shares);
        _undelegate(validator, _valAddr, tokens, _shares);
    }

    /**
     * @notice Undelegate shares from a validator
     * @dev Tokens are delegated by the msgSender to the validator
     * @param _valAddr the address of the validator
     * @param _tokens undelegate tokens
     */
    function undelegateTokens(address _valAddr, uint256 _tokens) external {
        require(_tokens >= dt.CELR_DECIMAL, "Minimal amount is 1 CELR");
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        uint256 shares = _tokenToShare(_tokens, validator.tokens, validator.shares);
        _undelegate(validator, _valAddr, _tokens, shares);
    }

    /**
     * @notice Complete pending undelegations from a validator
     * @param _valAddr the address of the validator
     */
    function completeUndelegate(address _valAddr) external {
        address delAddr = msg.sender;
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        dt.Delegator storage delegator = validator.delegators[delAddr];

        uint256 unbondingPeriod = params[dt.ParamName.UnbondingPeriod];
        bool isUnbonded = validator.status == dt.ValidatorStatus.Unbonded;
        // for all pending undelegations
        uint32 i;
        uint256 undelegationShares;
        for (i = delegator.undelegations.head; i < delegator.undelegations.tail; i++) {
            if (isUnbonded || delegator.undelegations.queue[i].creationBlock + unbondingPeriod <= block.number) {
                // complete undelegation when the validator becomes unbonded or
                // the unbondingPeriod for the pending undelegation is up.
                undelegationShares += delegator.undelegations.queue[i].shares;
                delete delegator.undelegations.queue[i];
                continue;
            }
            break;
        }
        delegator.undelegations.head = i;

        require(undelegationShares > 0, "No undelegation ready to be completed");
        uint256 tokens = _shareToToken(undelegationShares, validator.undelegationTokens, validator.undelegationShares);
        validator.undelegationShares -= undelegationShares;
        validator.undelegationTokens -= tokens;
        CELER_TOKEN.safeTransfer(delAddr, tokens);
        emit Undelegated(_valAddr, delAddr, tokens);
    }

    /**
     * @notice Update commission rate
     * @param _newRate new commission rate
     */
    function updateCommissionRate(uint64 _newRate) external {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        require(_newRate <= dt.COMMISSION_RATE_BASE, "Invalid new rate");
        validator.commissionRate = _newRate;
        emit ValidatorNotice(valAddr, "commission", abi.encode(_newRate), address(0));
    }

    /**
     * @notice Update minimal self delegation value
     * @param _minSelfDelegation minimal amount of tokens staked by the validator itself
     */
    function updateMinSelfDelegation(uint256 _minSelfDelegation) external {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        require(_minSelfDelegation >= params[dt.ParamName.MinSelfDelegation], "Insufficient min self delegation");
        if (_minSelfDelegation < validator.minSelfDelegation) {
            require(validator.status != dt.ValidatorStatus.Bonded, "Validator is bonded");
            validator.bondBlock = uint64(block.number + params[dt.ParamName.AdvanceNoticePeriod]);
        }
        validator.minSelfDelegation = _minSelfDelegation;
        emit ValidatorNotice(valAddr, "min-self-delegation", abi.encode(_minSelfDelegation), address(0));
    }

    /**
     * @notice Slash a validator and its delegators
     * @param _slashRequest slash request bytes coded in protobuf
     * @param _sigs list of validator signatures
     */
    function slash(bytes calldata _slashRequest, bytes[] calldata _sigs) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Slash"));
        verifySignatures(abi.encodePacked(domain, _slashRequest), _sigs);

        PbStaking.Slash memory request = PbStaking.decSlash(_slashRequest);
        require(block.timestamp < request.expireTime, "Slash expired");
        require(request.slashFactor <= dt.SLASH_FACTOR_DECIMAL, "Invalid slash factor");
        require(request.slashFactor <= params[dt.ParamName.MaxSlashFactor], "Exceed max slash factor");
        require(!slashNonces[request.nonce], "Used slash nonce");
        slashNonces[request.nonce] = true;

        address valAddr = request.validator;
        dt.Validator storage validator = validators[valAddr];
        require(
            validator.status == dt.ValidatorStatus.Bonded || validator.status == dt.ValidatorStatus.Unbonding,
            "Invalid validator status"
        );

        // slash delegated tokens
        uint256 slashAmt = (validator.tokens * request.slashFactor) / dt.SLASH_FACTOR_DECIMAL;
        validator.tokens -= slashAmt;
        if (validator.status == dt.ValidatorStatus.Bonded) {
            bondedTokens -= slashAmt;
            if (request.jailPeriod > 0 || !hasMinRequiredTokens(valAddr, true)) {
                _unbondValidator(valAddr);
            }
        }
        if (validator.status == dt.ValidatorStatus.Unbonding && request.jailPeriod > 0) {
            validator.bondBlock = uint64(block.number + request.jailPeriod);
        }
        emit DelegationUpdate(valAddr, address(0), validator.tokens, 0, -int256(slashAmt));

        // slash pending undelegations
        uint256 slashUndelegation = (validator.undelegationTokens * request.slashFactor) / dt.SLASH_FACTOR_DECIMAL;
        validator.undelegationTokens -= slashUndelegation;
        slashAmt += slashUndelegation;

        uint256 collectAmt;
        for (uint256 i = 0; i < request.collectors.length; i++) {
            PbStaking.AcctAmtPair memory collector = request.collectors[i];
            if (collectAmt + collector.amount > slashAmt) {
                collector.amount = slashAmt - collectAmt;
            }
            if (collector.amount > 0) {
                collectAmt += collector.amount;
                if (collector.account == address(0)) {
                    CELER_TOKEN.safeTransfer(msg.sender, collector.amount);
                    emit SlashAmtCollected(msg.sender, collector.amount);
                } else {
                    CELER_TOKEN.safeTransfer(collector.account, collector.amount);
                    emit SlashAmtCollected(collector.account, collector.amount);
                }
            }
        }
        forfeiture += slashAmt - collectAmt;
        emit Slash(valAddr, request.nonce, slashAmt);
    }

    function collectForfeiture() external {
        require(forfeiture > 0, "Nothing to collect");
        CELER_TOKEN.safeTransfer(rewardContract, forfeiture);
        forfeiture = 0;
    }

    /**
     * @notice Validator notice event, could be triggered by anyone
     */
    function validatorNotice(
        address _valAddr,
        string calldata _key,
        bytes calldata _data
    ) external {
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        emit ValidatorNotice(_valAddr, _key, _data, msg.sender);
    }

    function setParamValue(dt.ParamName _name, uint256 _value) external {
        require(msg.sender == govContract, "Caller is not gov contract");
        if (_name == dt.ParamName.MaxBondedValidators) {
            require(bondedValAddrs.length <= _value, "invalid value");
        }
        params[_name] = _value;
    }

    function setGovContract(address _addr) external onlyOwner {
        govContract = _addr;
    }

    function setRewardContract(address _addr) external onlyOwner {
        rewardContract = _addr;
    }

    /**
     * @notice Set max slash factor
     */
    function setMaxSlashFactor(uint256 _maxSlashFactor) external onlyOwner {
        params[dt.ParamName.MaxSlashFactor] = _maxSlashFactor;
    }

    /**
     * @notice Owner drains tokens when the contract is paused
     * @dev emergency use only
     * @param _amount drained token amount
     */
    function drainToken(uint256 _amount) external whenPaused onlyOwner {
        CELER_TOKEN.safeTransfer(msg.sender, _amount);
    }

    /**************************
     *  Public View Functions *
     **************************/

    /**
     * @notice Validate if a message is signed by quorum tokens
     * @param _msg signed message
     * @param _sigs list of validator signatures
     */
    function verifySignatures(bytes memory _msg, bytes[] memory _sigs) public view returns (bool) {
        bytes32 hash = keccak256(_msg).toEthSignedMessageHash();
        uint256 signedTokens;
        address prev = address(0);
        uint256 quorum = getQuorumTokens();
        for (uint256 i = 0; i < _sigs.length; i++) {
            address signer = hash.recover(_sigs[i]);
            require(signer > prev, "Signers not in ascending order");
            prev = signer;
            dt.Validator storage validator = validators[signerVals[signer]];
            if (validator.status != dt.ValidatorStatus.Bonded) {
                continue;
            }
            signedTokens += validator.tokens;
            if (signedTokens >= quorum) {
                return true;
            }
        }
        revert("Quorum not reached");
    }

    /**
     * @notice Verifies that a message is signed by a quorum among the validators.
     * @param _msg signed message
     * @param _sigs the list of signatures
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata,
        uint256[] calldata
    ) public view override {
        require(verifySignatures(_msg, _sigs), "Failed to verify sigs");
    }

    /**
     * @notice Get quorum amount of tokens
     * @return the quorum amount
     */
    function getQuorumTokens() public view returns (uint256) {
        return (bondedTokens * 2) / 3 + 1;
    }

    /**
     * @notice Get validator info
     * @param _valAddr the address of the validator
     * @return Validator token amount
     */
    function getValidatorTokens(address _valAddr) public view returns (uint256) {
        return validators[_valAddr].tokens;
    }

    /**
     * @notice Get validator info
     * @param _valAddr the address of the validator
     * @return Validator status
     */
    function getValidatorStatus(address _valAddr) public view returns (dt.ValidatorStatus) {
        return validators[_valAddr].status;
    }

    /**
     * @notice Check the given address is a validator or not
     * @param _addr the address to check
     * @return the given address is a validator or not
     */
    function isBondedValidator(address _addr) public view returns (bool) {
        return validators[_addr].status == dt.ValidatorStatus.Bonded;
    }

    /**
     * @notice Get the number of validators
     * @return the number of validators
     */
    function getValidatorNum() public view returns (uint256) {
        return valAddrs.length;
    }

    /**
     * @notice Get the number of bonded validators
     * @return the number of bonded validators
     */
    function getBondedValidatorNum() public view returns (uint256) {
        return bondedValAddrs.length;
    }

    /**
     * @return addresses and token amounts of bonded validators
     */
    function getBondedValidatorsTokens() public view returns (dt.ValidatorTokens[] memory) {
        dt.ValidatorTokens[] memory infos = new dt.ValidatorTokens[](bondedValAddrs.length);
        for (uint256 i = 0; i < bondedValAddrs.length; i++) {
            address valAddr = bondedValAddrs[i];
            infos[i] = dt.ValidatorTokens(valAddr, validators[valAddr].tokens);
        }
        return infos;
    }

    /**
     * @notice Check if min token requirements are met
     * @param _valAddr the address of the validator
     * @param _checkSelfDelegation check self delegation
     */
    function hasMinRequiredTokens(address _valAddr, bool _checkSelfDelegation) public view returns (bool) {
        dt.Validator storage v = validators[_valAddr];
        uint256 valTokens = v.tokens;
        if (valTokens < params[dt.ParamName.MinValidatorTokens]) {
            return false;
        }
        if (_checkSelfDelegation) {
            uint256 selfDelegation = _shareToToken(v.delegators[_valAddr].shares, valTokens, v.shares);
            if (selfDelegation < v.minSelfDelegation) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Get the delegator info of a specific validator
     * @param _valAddr the address of the validator
     * @param _delAddr the address of the delegator
     * @return DelegatorInfo from the given validator
     */
    function getDelegatorInfo(address _valAddr, address _delAddr) public view returns (dt.DelegatorInfo memory) {
        dt.Validator storage validator = validators[_valAddr];
        dt.Delegator storage d = validator.delegators[_delAddr];
        uint256 tokens = _shareToToken(d.shares, validator.tokens, validator.shares);

        uint256 undelegationShares;
        uint256 withdrawableUndelegationShares;
        uint256 unbondingPeriod = params[dt.ParamName.UnbondingPeriod];
        bool isUnbonded = validator.status == dt.ValidatorStatus.Unbonded;
        uint256 len = d.undelegations.tail - d.undelegations.head;
        dt.Undelegation[] memory undelegations = new dt.Undelegation[](len);
        for (uint256 i = 0; i < len; i++) {
            undelegations[i] = d.undelegations.queue[i + d.undelegations.head];
            undelegationShares += undelegations[i].shares;
            if (isUnbonded || undelegations[i].creationBlock + unbondingPeriod <= block.number) {
                withdrawableUndelegationShares += undelegations[i].shares;
            }
        }
        uint256 undelegationTokens = _shareToToken(
            undelegationShares,
            validator.undelegationTokens,
            validator.undelegationShares
        );
        uint256 withdrawableUndelegationTokens = _shareToToken(
            withdrawableUndelegationShares,
            validator.undelegationTokens,
            validator.undelegationShares
        );

        return
            dt.DelegatorInfo(
                _valAddr,
                tokens,
                d.shares,
                undelegations,
                undelegationTokens,
                withdrawableUndelegationTokens
            );
    }

    /**
     * @notice Get the value of a specific uint parameter
     * @param _name the key of this parameter
     * @return the value of this parameter
     */
    function getParamValue(dt.ParamName _name) public view returns (uint256) {
        return params[_name];
    }

    /*********************
     * Private Functions *
     *********************/

    function _undelegate(
        dt.Validator storage validator,
        address _valAddr,
        uint256 _tokens,
        uint256 _shares
    ) private {
        address delAddr = msg.sender;
        dt.Delegator storage delegator = validator.delegators[delAddr];
        delegator.shares -= _shares;
        validator.shares -= _shares;
        validator.tokens -= _tokens;
        if (validator.tokens != validator.shares && delegator.shares <= 2) {
            // Remove residual share caused by rounding error when total shares and tokens are not equal
            validator.shares -= delegator.shares;
            delegator.shares = 0;
        }
        require(delegator.shares == 0 || delegator.shares >= dt.CELR_DECIMAL, "not enough remaining shares");

        if (validator.status == dt.ValidatorStatus.Unbonded) {
            CELER_TOKEN.safeTransfer(delAddr, _tokens);
            emit Undelegated(_valAddr, delAddr, _tokens);
            return;
        } else if (validator.status == dt.ValidatorStatus.Bonded) {
            bondedTokens -= _tokens;
            if (!hasMinRequiredTokens(_valAddr, delAddr == _valAddr)) {
                _unbondValidator(_valAddr);
            }
        }
        require(
            delegator.undelegations.tail - delegator.undelegations.head < dt.MAX_UNDELEGATION_ENTRIES,
            "Exceed max undelegation entries"
        );

        uint256 undelegationShares = _tokenToShare(_tokens, validator.undelegationTokens, validator.undelegationShares);
        validator.undelegationShares += undelegationShares;
        validator.undelegationTokens += _tokens;
        dt.Undelegation storage undelegation = delegator.undelegations.queue[delegator.undelegations.tail];
        undelegation.shares = undelegationShares;
        undelegation.creationBlock = block.number;
        delegator.undelegations.tail++;

        emit DelegationUpdate(_valAddr, delAddr, validator.tokens, delegator.shares, -int256(_tokens));
    }

    /**
     * @notice Set validator to bonded
     * @param _valAddr the address of the validator
     */
    function _setBondedValidator(address _valAddr) private {
        dt.Validator storage validator = validators[_valAddr];
        validator.status = dt.ValidatorStatus.Bonded;
        delete validator.unbondBlock;
        bondedTokens += validator.tokens;
        emit ValidatorStatusUpdate(_valAddr, dt.ValidatorStatus.Bonded);
    }

    /**
     * @notice Set validator to unbonding
     * @param _valAddr the address of the validator
     */
    function _setUnbondingValidator(address _valAddr) private {
        dt.Validator storage validator = validators[_valAddr];
        validator.status = dt.ValidatorStatus.Unbonding;
        validator.unbondBlock = uint64(block.number + params[dt.ParamName.UnbondingPeriod]);
        bondedTokens -= validator.tokens;
        emit ValidatorStatusUpdate(_valAddr, dt.ValidatorStatus.Unbonding);
    }

    /**
     * @notice Bond a validator
     * @param _valAddr the address of the validator
     */
    function _bondValidator(address _valAddr) private {
        bondedValAddrs.push(_valAddr);
        _setBondedValidator(_valAddr);
    }

    /**
     * @notice Replace a bonded validator
     * @param _valAddr the address of the new validator
     * @param _index the index of the validator to be replaced
     */
    function _replaceBondedValidator(address _valAddr, uint256 _index) private {
        _setUnbondingValidator(bondedValAddrs[_index]);
        bondedValAddrs[_index] = _valAddr;
        _setBondedValidator(_valAddr);
    }

    /**
     * @notice Unbond a validator
     * @param _valAddr validator to be removed
     */
    function _unbondValidator(address _valAddr) private {
        uint256 lastIndex = bondedValAddrs.length - 1;
        for (uint256 i = 0; i < bondedValAddrs.length; i++) {
            if (bondedValAddrs[i] == _valAddr) {
                if (i < lastIndex) {
                    bondedValAddrs[i] = bondedValAddrs[lastIndex];
                }
                bondedValAddrs.pop();
                _setUnbondingValidator(_valAddr);
                return;
            }
        }
        revert("Not bonded validator");
    }

    /**
     * @notice Check if one validator has too much power
     * @param _valTokens token amounts of the validator
     */
    function _decentralizationCheck(uint256 _valTokens) private view {
        uint256 bondedValNum = bondedValAddrs.length;
        if (bondedValNum == 2 || bondedValNum == 3) {
            require(_valTokens < getQuorumTokens(), "Single validator should not have quorum tokens");
        } else if (bondedValNum > 3) {
            require(_valTokens < bondedTokens / 3, "Single validator should not have 1/3 tokens");
        }
    }

    /**
     * @notice Convert token to share
     */
    function _tokenToShare(
        uint256 tokens,
        uint256 totalTokens,
        uint256 totalShares
    ) private pure returns (uint256) {
        if (totalTokens == 0) {
            return tokens;
        }
        return (tokens * totalShares) / totalTokens;
    }

    /**
     * @notice Convert share to token
     */
    function _shareToToken(
        uint256 shares,
        uint256 totalTokens,
        uint256 totalShares
    ) private pure returns (uint256) {
        if (totalShares == 0) {
            return shares;
        }
        return (shares * totalTokens) / totalShares;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0-only

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
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/staking.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbStaking {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct StakingReward {
        address recipient; // tag: 1
        uint256 cumulativeRewardAmount; // tag: 2
    } // end struct StakingReward

    function decStakingReward(bytes memory raw) internal pure returns (StakingReward memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.recipient = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.cumulativeRewardAmount = Pb._uint256(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder StakingReward

    struct Slash {
        address validator; // tag: 1
        uint64 nonce; // tag: 2
        uint64 slashFactor; // tag: 3
        uint64 expireTime; // tag: 4
        uint64 jailPeriod; // tag: 5
        AcctAmtPair[] collectors; // tag: 6
    } // end struct Slash

    function decSlash(bytes memory raw) internal pure returns (Slash memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256[] memory cnts = buf.cntTags(6);
        m.collectors = new AcctAmtPair[](cnts[6]);
        cnts[6] = 0; // reset counter for later use

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.validator = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.nonce = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.slashFactor = uint64(buf.decVarint());
            } else if (tag == 4) {
                m.expireTime = uint64(buf.decVarint());
            } else if (tag == 5) {
                m.jailPeriod = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.collectors[cnts[6]] = decAcctAmtPair(buf.decBytes());
                cnts[6]++;
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Slash

    struct AcctAmtPair {
        address account; // tag: 1
        uint256 amount; // tag: 2
    } // end struct AcctAmtPair

    function decAcctAmtPair(bytes memory raw) internal pure returns (AcctAmtPair memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.account = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.amount = Pb._uint256(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder AcctAmtPair
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Ownable.sol";

abstract contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    bool public whitelistEnabled;

    event WhitelistedAdded(address account);
    event WhitelistedRemoved(address account);

    modifier onlyWhitelisted() {
        if (whitelistEnabled) {
            require(isWhitelisted(msg.sender), "Caller is not whitelisted");
        }
        _;
    }

    /**
     * @notice Set whitelistEnabled
     */
    function setWhitelistEnabled(bool _whitelistEnabled) external onlyOwner {
        whitelistEnabled = _whitelistEnabled;
    }

    /**
     * @notice Add an account to whitelist
     */
    function addWhitelisted(address account) external onlyOwner {
        require(!isWhitelisted(account), "Already whitelisted");
        whitelist[account] = true;
        emit WhitelistedAdded(account);
    }

    /**
     * @notice Remove an account from whitelist
     */
    function removeWhitelisted(address account) external onlyOwner {
        require(isWhitelisted(account), "Not whitelisted");
        whitelist[account] = false;
        emit WhitelistedRemoved(account);
    }

    /**
     * @return is account whitelisted
     */
    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag) internal pure returns (uint256[] memory cnts) {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf) internal pure returns (uint256[] memory t) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import {DataTypes as dt} from "./DataTypes.sol";
import "./Staking.sol";

/**
 * @title Viewer of the staking contract
 * @notice Using a separate viewer contract to reduce staking contract size
 */
contract Viewer {
    Staking public immutable staking;

    constructor(Staking _staking) {
        staking = _staking;
    }

    function getValidatorInfos() public view returns (dt.ValidatorInfo[] memory) {
        uint256 valNum = staking.getValidatorNum();
        dt.ValidatorInfo[] memory infos = new dt.ValidatorInfo[](valNum);
        for (uint32 i = 0; i < valNum; i++) {
            infos[i] = getValidatorInfo(staking.valAddrs(i));
        }
        return infos;
    }

    function getBondedValidatorInfos() public view returns (dt.ValidatorInfo[] memory) {
        uint256 bondedValNum = staking.getBondedValidatorNum();
        dt.ValidatorInfo[] memory infos = new dt.ValidatorInfo[](bondedValNum);
        for (uint32 i = 0; i < bondedValNum; i++) {
            infos[i] = getValidatorInfo(staking.bondedValAddrs(i));
        }
        return infos;
    }

    function getValidatorInfo(address _valAddr) public view returns (dt.ValidatorInfo memory) {
        (
            dt.ValidatorStatus status,
            address signer,
            uint256 tokens,
            uint256 shares,
            ,
            ,
            uint256 minSelfDelegation,
            ,
            ,
            uint64 commissionRate
        ) = staking.validators(_valAddr);
        return
            dt.ValidatorInfo({
                valAddr: _valAddr,
                status: status,
                signer: signer,
                tokens: tokens,
                shares: shares,
                minSelfDelegation: minSelfDelegation,
                commissionRate: commissionRate
            });
    }

    function getDelegatorInfos(address _delAddr) public view returns (dt.DelegatorInfo[] memory) {
        uint256 valNum = staking.getValidatorNum();
        dt.DelegatorInfo[] memory infos = new dt.DelegatorInfo[](valNum);
        uint32 num = 0;
        for (uint32 i = 0; i < valNum; i++) {
            address valAddr = staking.valAddrs(i);
            infos[i] = staking.getDelegatorInfo(valAddr, _delAddr);
            if (infos[i].shares != 0 || infos[i].undelegationTokens != 0) {
                num++;
            }
        }
        dt.DelegatorInfo[] memory res = new dt.DelegatorInfo[](num);
        uint32 j = 0;
        for (uint32 i = 0; i < valNum; i++) {
            if (infos[i].shares != 0 || infos[i].undelegationTokens != 0) {
                res[j] = infos[i];
                j++;
            }
        }
        return res;
    }

    function getDelegatorTokens(address _delAddr) public view returns (uint256, uint256) {
        dt.DelegatorInfo[] memory infos = getDelegatorInfos(_delAddr);
        uint256 tokens;
        uint256 undelegationTokens;
        for (uint32 i = 0; i < infos.length; i++) {
            tokens += infos[i].tokens;
            undelegationTokens += infos[i].undelegationTokens;
        }
        return (tokens, undelegationTokens);
    }

    /**
     * @notice Get the minimum staking pool of all bonded validators
     * @return the minimum staking pool of all bonded validators
     */
    function getMinValidatorTokens() public view returns (uint256) {
        uint256 bondedValNum = staking.getBondedValidatorNum();
        if (bondedValNum < staking.params(dt.ParamName.MaxBondedValidators)) {
            return 0;
        }
        uint256 minTokens = dt.MAX_INT;
        for (uint256 i = 0; i < bondedValNum; i++) {
            uint256 tokens = staking.getValidatorTokens(staking.bondedValAddrs(i));
            if (tokens < minTokens) {
                minTokens = tokens;
                if (minTokens == 0) {
                    return 0;
                }
            }
        }
        return minTokens;
    }

    function shouldBondValidator(address _valAddr) public view returns (bool) {
        (dt.ValidatorStatus status, , uint256 tokens, , , , , uint64 bondBlock, , ) = staking.validators(_valAddr);
        if (status == dt.ValidatorStatus.Null || status == dt.ValidatorStatus.Bonded) {
            return false;
        }
        if (block.number < bondBlock) {
            return false;
        }
        if (!staking.hasMinRequiredTokens(_valAddr, true)) {
            return false;
        }
        if (tokens <= getMinValidatorTokens()) {
            return false;
        }
        uint256 nextBondBlock = staking.nextBondBlock();
        if (block.number < nextBondBlock) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes as dt} from "./DataTypes.sol";
import "../libraries/PbSgn.sol";
import "../safeguard/Pauser.sol";
import "./Staking.sol";

/**
 * @title contract of SGN chain
 */
contract SGN is Pauser {
    using SafeERC20 for IERC20;

    Staking public immutable staking;
    bytes32[] public deposits;
    // account -> (token -> amount)
    mapping(address => mapping(address => uint256)) public withdrawnAmts;
    mapping(address => bytes) public sgnAddrs;

    /* Events */
    event SgnAddrUpdate(address indexed valAddr, bytes oldAddr, bytes newAddr);
    event Deposit(uint256 depositId, address account, address token, uint256 amount);
    event Withdraw(address account, address token, uint256 amount);

    /**
     * @notice SGN constructor
     * @dev Need to deploy Staking contract first before deploying SGN contract
     * @param _staking address of Staking Contract
     */
    constructor(Staking _staking) {
        staking = _staking;
    }

    /**
     * @notice Update sgn address
     * @param _sgnAddr the new address in the layer 2 SGN
     */
    function updateSgnAddr(bytes calldata _sgnAddr) external {
        address valAddr = msg.sender;
        if (staking.signerVals(msg.sender) != address(0)) {
            valAddr = staking.signerVals(msg.sender);
        }

        dt.ValidatorStatus status = staking.getValidatorStatus(valAddr);
        require(status == dt.ValidatorStatus.Unbonded, "Not unbonded validator");

        bytes memory oldAddr = sgnAddrs[valAddr];
        sgnAddrs[valAddr] = _sgnAddr;

        staking.validatorNotice(valAddr, "sgn-addr", _sgnAddr);
        emit SgnAddrUpdate(valAddr, oldAddr, _sgnAddr);
    }

    /**a
     * @notice Deposit to SGN
     * @param _amount subscription fee paid along this function call in CELR tokens
     */
    function deposit(address _token, uint256 _amount) external whenNotPaused {
        address msgSender = msg.sender;
        deposits.push(keccak256(abi.encodePacked(msgSender, _token, _amount)));
        IERC20(_token).safeTransferFrom(msgSender, address(this), _amount);
        uint64 depositId = uint64(deposits.length - 1);
        emit Deposit(depositId, msgSender, _token, _amount);
    }

    /**
     * @notice Withdraw token
     * @dev Here we use cumulative amount to make withdrawal process idempotent
     * @param _withdrawalRequest withdrawal request bytes coded in protobuf
     * @param _sigs list of validator signatures
     */
    function withdraw(bytes calldata _withdrawalRequest, bytes[] calldata _sigs) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Withdrawal"));
        staking.verifySignatures(abi.encodePacked(domain, _withdrawalRequest), _sigs);
        PbSgn.Withdrawal memory withdrawal = PbSgn.decWithdrawal(_withdrawalRequest);

        uint256 amount = withdrawal.cumulativeAmount - withdrawnAmts[withdrawal.account][withdrawal.token];
        require(amount > 0, "No new amount to withdraw");
        withdrawnAmts[withdrawal.account][withdrawal.token] = withdrawal.cumulativeAmount;

        IERC20(withdrawal.token).safeTransfer(withdrawal.account, amount);
        emit Withdraw(withdrawal.account, withdrawal.token, amount);
    }

    /**
     * @notice Owner drains one type of tokens when the contract is paused
     * @dev emergency use only
     * @param _amount drained token amount
     */
    function drainToken(address _token, uint256 _amount) external whenPaused onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/sgn.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbSgn {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct Withdrawal {
        address account; // tag: 1
        address token; // tag: 2
        uint256 cumulativeAmount; // tag: 3
    } // end struct Withdrawal

    function decWithdrawal(bytes memory raw) internal pure returns (Withdrawal memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.account = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.cumulativeAmount = Pb._uint256(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Withdrawal
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/ISigsVerifier.sol";
import "../interfaces/IPeggedToken.sol";
import "../interfaces/IPeggedTokenBurnFrom.sol";
import "../libraries/PbPegged.sol";
import "../safeguard/Pauser.sol";
import "../safeguard/VolumeControl.sol";
import "../safeguard/DelayedTransfer.sol";

/**
 * @title The bridge contract to mint and burn pegged tokens
 * @dev Work together with OriginalTokenVault deployed at remote chains.
 */
contract PeggedTokenBridgeV2 is Pauser, VolumeControl, DelayedTransfer {
    ISigsVerifier public immutable sigsVerifier;

    mapping(bytes32 => bool) public records;
    mapping(address => uint256) public supplies;

    mapping(address => uint256) public minBurn;
    mapping(address => uint256) public maxBurn;

    event Mint(
        bytes32 mintId,
        address token,
        address account,
        uint256 amount,
        // ref_chain_id defines the reference chain ID, taking values of:
        // 1. The common case: the chain ID on which the remote corresponding deposit or burn happened;
        // 2. Refund for wrong burn: this chain ID on which the burn happened
        uint64 refChainId,
        // ref_id defines a unique reference ID, taking values of:
        // 1. The common case of deposit/burn-mint: the deposit or burn ID on the remote chain;
        // 2. Refund for wrong burn: the burn ID on this chain
        bytes32 refId,
        address depositor
    );
    event Burn(
        bytes32 burnId,
        address token,
        address account,
        uint256 amount,
        uint64 toChainId,
        address toAccount,
        uint64 nonce
    );
    event MinBurnUpdated(address token, uint256 amount);
    event MaxBurnUpdated(address token, uint256 amount);
    event SupplyUpdated(address token, uint256 supply);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused returns (bytes32) {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Mint"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _request), _sigs, _signers, _powers);
        PbPegged.Mint memory request = PbPegged.decMint(_request);
        bytes32 mintId = keccak256(
            // len = 20 + 20 + 32 + 20 + 8 + 32 + 20 = 152
            abi.encodePacked(
                request.account,
                request.token,
                request.amount,
                request.depositor,
                request.refChainId,
                request.refId,
                address(this)
            )
        );
        require(records[mintId] == false, "record exists");
        records[mintId] = true;
        _updateVolume(request.token, request.amount);
        uint256 delayThreshold = delayThresholds[request.token];
        if (delayThreshold > 0 && request.amount > delayThreshold) {
            _addDelayedTransfer(mintId, request.account, request.token, request.amount);
        } else {
            IPeggedToken(request.token).mint(request.account, request.amount);
        }
        supplies[request.token] += request.amount;
        emit Mint(
            mintId,
            request.token,
            request.account,
            request.amount,
            request.refChainId,
            request.refId,
            request.depositor
        );
        return mintId;
    }

    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external whenNotPaused returns (bytes32) {
        bytes32 burnId = _burn(_token, _amount, _toChainId, _toAccount, _nonce);
        IPeggedToken(_token).burn(msg.sender, _amount);
        return burnId;
    }

    // same with `burn` above, use openzeppelin ERC20Burnable interface
    function burnFrom(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external whenNotPaused returns (bytes32) {
        bytes32 burnId = _burn(_token, _amount, _toChainId, _toAccount, _nonce);
        IPeggedTokenBurnFrom(_token).burnFrom(msg.sender, _amount);
        return burnId;
    }

    function _burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) private returns (bytes32) {
        require(_amount > minBurn[_token], "amount too small");
        require(maxBurn[_token] == 0 || _amount <= maxBurn[_token], "amount too large");
        supplies[_token] -= _amount;
        bytes32 burnId = keccak256(
            // len = 20 + 20 + 32 + 8 + 20 + 8 + 8 + 20 = 136
            abi.encodePacked(
                msg.sender,
                _token,
                _amount,
                _toChainId,
                _toAccount,
                _nonce,
                uint64(block.chainid),
                address(this)
            )
        );
        require(records[burnId] == false, "record exists");
        records[burnId] = true;
        emit Burn(burnId, _token, msg.sender, _amount, _toChainId, _toAccount, _nonce);
        return burnId;
    }

    function executeDelayedTransfer(bytes32 id) external whenNotPaused {
        delayedTransfer memory transfer = _executeDelayedTransfer(id);
        IPeggedToken(transfer.token).mint(transfer.receiver, transfer.amount);
    }

    function setMinBurn(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minBurn[_tokens[i]] = _amounts[i];
            emit MinBurnUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMaxBurn(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            maxBurn[_tokens[i]] = _amounts[i];
            emit MaxBurnUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setSupply(address _token, uint256 _supply) external onlyOwner {
        supplies[_token] = _supply;
        emit SupplyUpdated(_token, _supply);
    }

    function increaseSupply(address _token, uint256 _delta) external onlyOwner {
        supplies[_token] += _delta;
        emit SupplyUpdated(_token, supplies[_token]);
    }

    function decreaseSupply(address _token, uint256 _delta) external onlyOwner {
        supplies[_token] -= _delta;
        emit SupplyUpdated(_token, supplies[_token]);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedToken {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

// used for pegged token with openzeppelin ERC20Burnable interface
// only compatible with PeggedTokenBridgeV2
interface IPeggedTokenBurnFrom {
    function mint(address _to, uint256 _amount) external;

    function burnFrom(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/pegged.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbPegged {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct Mint {
        address token; // tag: 1
        address account; // tag: 2
        uint256 amount; // tag: 3
        address depositor; // tag: 4
        uint64 refChainId; // tag: 5
        bytes32 refId; // tag: 6
    } // end struct Mint

    function decMint(bytes memory raw) internal pure returns (Mint memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.account = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 4) {
                m.depositor = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.refChainId = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.refId = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Mint

    struct Withdraw {
        address token; // tag: 1
        address receiver; // tag: 2
        uint256 amount; // tag: 3
        address burnAccount; // tag: 4
        uint64 refChainId; // tag: 5
        bytes32 refId; // tag: 6
    } // end struct Withdraw

    function decWithdraw(bytes memory raw) internal pure returns (Withdraw memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 4) {
                m.burnAccount = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.refChainId = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.refId = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Withdraw
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Governor.sol";

abstract contract VolumeControl is Governor {
    uint256 public epochLength; // seconds
    mapping(address => uint256) public epochVolumes; // key is token
    mapping(address => uint256) public epochVolumeCaps; // key is token
    mapping(address => uint256) public lastOpTimestamps; // key is token

    event EpochLengthUpdated(uint256 length);
    event EpochVolumeUpdated(address token, uint256 cap);

    function setEpochLength(uint256 _length) external onlyGovernor {
        epochLength = _length;
        emit EpochLengthUpdated(_length);
    }

    function setEpochVolumeCaps(address[] calldata _tokens, uint256[] calldata _caps) external onlyGovernor {
        require(_tokens.length == _caps.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            epochVolumeCaps[_tokens[i]] = _caps[i];
            emit EpochVolumeUpdated(_tokens[i], _caps[i]);
        }
    }

    function _updateVolume(address _token, uint256 _amount) internal {
        if (epochLength == 0) {
            return;
        }
        uint256 cap = epochVolumeCaps[_token];
        if (cap == 0) {
            return;
        }
        uint256 volume = epochVolumes[_token];
        uint256 timestamp = block.timestamp;
        uint256 epochStartTime = (timestamp / epochLength) * epochLength;
        if (lastOpTimestamps[_token] < epochStartTime) {
            volume = _amount;
        } else {
            volume += _amount;
        }
        require(volume <= cap, "volume exceeds cap");
        epochVolumes[_token] = volume;
        lastOpTimestamps[_token] = timestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Governor.sol";

abstract contract DelayedTransfer is Governor {
    struct delayedTransfer {
        address receiver;
        address token;
        uint256 amount;
        uint256 timestamp;
    }
    mapping(bytes32 => delayedTransfer) public delayedTransfers;
    mapping(address => uint256) public delayThresholds;
    uint256 public delayPeriod; // in seconds

    event DelayedTransferAdded(bytes32 id);
    event DelayedTransferExecuted(bytes32 id, address receiver, address token, uint256 amount);

    event DelayPeriodUpdated(uint256 period);
    event DelayThresholdUpdated(address token, uint256 threshold);

    function setDelayThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) external onlyGovernor {
        require(_tokens.length == _thresholds.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            delayThresholds[_tokens[i]] = _thresholds[i];
            emit DelayThresholdUpdated(_tokens[i], _thresholds[i]);
        }
    }

    function setDelayPeriod(uint256 _period) external onlyGovernor {
        delayPeriod = _period;
        emit DelayPeriodUpdated(_period);
    }

    function _addDelayedTransfer(
        bytes32 id,
        address receiver,
        address token,
        uint256 amount
    ) internal {
        require(delayedTransfers[id].timestamp == 0, "delayed transfer already exists");
        delayedTransfers[id] = delayedTransfer({
            receiver: receiver,
            token: token,
            amount: amount,
            timestamp: block.timestamp
        });
        emit DelayedTransferAdded(id);
    }

    // caller needs to do the actual token transfer
    function _executeDelayedTransfer(bytes32 id) internal returns (delayedTransfer memory) {
        delayedTransfer memory transfer = delayedTransfers[id];
        require(transfer.timestamp > 0, "delayed transfer not exist");
        require(block.timestamp > transfer.timestamp + delayPeriod, "delayed transfer still locked");
        delete delayedTransfers[id];
        emit DelayedTransferExecuted(id, transfer.receiver, transfer.token, transfer.amount);
        return transfer;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Ownable.sol";

abstract contract Governor is Ownable {
    mapping(address => bool) public governors;

    event GovernorAdded(address account);
    event GovernorRemoved(address account);

    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "Caller is not governor");
        _;
    }

    constructor() {
        _addGovernor(msg.sender);
    }

    function isGovernor(address _account) public view returns (bool) {
        return governors[_account];
    }

    function addGovernor(address _account) public onlyOwner {
        _addGovernor(_account);
    }

    function removeGovernor(address _account) public onlyOwner {
        _removeGovernor(_account);
    }

    function renounceGovernor() public {
        _removeGovernor(msg.sender);
    }

    function _addGovernor(address _account) private {
        require(!isGovernor(_account), "Account is already governor");
        governors[_account] = true;
        emit GovernorAdded(_account);
    }

    function _removeGovernor(address _account) private {
        require(isGovernor(_account), "Account is not governor");
        governors[_account] = false;
        emit GovernorRemoved(_account);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/ISigsVerifier.sol";
import "../interfaces/IPeggedToken.sol";
import "../libraries/PbPegged.sol";
import "../safeguard/Pauser.sol";
import "../safeguard/VolumeControl.sol";
import "../safeguard/DelayedTransfer.sol";

/**
 * @title The bridge contract to mint and burn pegged tokens
 * @dev Work together with OriginalTokenVault deployed at remote chains.
 */
contract PeggedTokenBridge is Pauser, VolumeControl, DelayedTransfer {
    ISigsVerifier public immutable sigsVerifier;

    mapping(bytes32 => bool) public records;

    mapping(address => uint256) public minBurn;
    mapping(address => uint256) public maxBurn;

    event Mint(
        bytes32 mintId,
        address token,
        address account,
        uint256 amount,
        // ref_chain_id defines the reference chain ID, taking values of:
        // 1. The common case: the chain ID on which the remote corresponding deposit or burn happened;
        // 2. Refund for wrong burn: this chain ID on which the burn happened
        uint64 refChainId,
        // ref_id defines a unique reference ID, taking values of:
        // 1. The common case of deposit/burn-mint: the deposit or burn ID on the remote chain;
        // 2. Refund for wrong burn: the burn ID on this chain
        bytes32 refId,
        address depositor
    );
    event Burn(bytes32 burnId, address token, address account, uint256 amount, address withdrawAccount);
    event MinBurnUpdated(address token, uint256 amount);
    event MaxBurnUpdated(address token, uint256 amount);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Mint"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _request), _sigs, _signers, _powers);
        PbPegged.Mint memory request = PbPegged.decMint(_request);
        bytes32 mintId = keccak256(
            // len = 20 + 20 + 32 + 20 + 8 + 32 = 132
            abi.encodePacked(
                request.account,
                request.token,
                request.amount,
                request.depositor,
                request.refChainId,
                request.refId
            )
        );
        require(records[mintId] == false, "record exists");
        records[mintId] = true;
        _updateVolume(request.token, request.amount);
        uint256 delayThreshold = delayThresholds[request.token];
        if (delayThreshold > 0 && request.amount > delayThreshold) {
            _addDelayedTransfer(mintId, request.account, request.token, request.amount);
        } else {
            IPeggedToken(request.token).mint(request.account, request.amount);
        }
        emit Mint(
            mintId,
            request.token,
            request.account,
            request.amount,
            request.refChainId,
            request.refId,
            request.depositor
        );
    }

    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault.
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _withdrawAccount The account to receive the original tokens withdrawn on the remote chain.
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external whenNotPaused {
        require(_amount > minBurn[_token], "amount too small");
        require(maxBurn[_token] == 0 || _amount <= maxBurn[_token], "amount too large");
        bytes32 burnId = keccak256(
            // len = 20 + 20 + 32 + 20 + 8 + 8 = 108
            abi.encodePacked(msg.sender, _token, _amount, _withdrawAccount, _nonce, uint64(block.chainid))
        );
        require(records[burnId] == false, "record exists");
        records[burnId] = true;
        IPeggedToken(_token).burn(msg.sender, _amount);
        emit Burn(burnId, _token, msg.sender, _amount, _withdrawAccount);
    }

    function executeDelayedTransfer(bytes32 id) external whenNotPaused {
        delayedTransfer memory transfer = _executeDelayedTransfer(id);
        IPeggedToken(transfer.token).mint(transfer.receiver, transfer.amount);
    }

    function setMinBurn(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minBurn[_tokens[i]] = _amounts[i];
            emit MinBurnUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMaxBurn(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            maxBurn[_tokens[i]] = _amounts[i];
            emit MaxBurnUpdated(_tokens[i], _amounts[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ISigsVerifier.sol";
import "../interfaces/IWETH.sol";
import "../libraries/PbPegged.sol";
import "../safeguard/Pauser.sol";
import "../safeguard/VolumeControl.sol";
import "../safeguard/DelayedTransfer.sol";

/**
 * @title the vault to deposit and withdraw original tokens
 * @dev Work together with PeggedTokenBridge contracts deployed at remote chains
 */
contract OriginalTokenVaultV2 is ReentrancyGuard, Pauser, VolumeControl, DelayedTransfer {
    using SafeERC20 for IERC20;

    ISigsVerifier public immutable sigsVerifier;

    mapping(bytes32 => bool) public records;

    mapping(address => uint256) public minDeposit;
    mapping(address => uint256) public maxDeposit;

    address public nativeWrap;

    event Deposited(
        bytes32 depositId,
        address depositor,
        address token,
        uint256 amount,
        uint64 mintChainId,
        address mintAccount,
        uint64 nonce
    );
    event Withdrawn(
        bytes32 withdrawId,
        address receiver,
        address token,
        uint256 amount,
        // ref_chain_id defines the reference chain ID, taking values of:
        // 1. The common case of burn-withdraw: the chain ID on which the corresponding burn happened;
        // 2. Pegbridge fee claim: zero / not applicable;
        // 3. Refund for wrong deposit: this chain ID on which the deposit happened
        uint64 refChainId,
        // ref_id defines a unique reference ID, taking values of:
        // 1. The common case of burn-withdraw: the burn ID on the remote chain;
        // 2. Pegbridge fee claim: a per-account nonce;
        // 3. Refund for wrong deposit: the deposit ID on this chain
        bytes32 refId,
        address burnAccount
    );
    event MinDepositUpdated(address token, uint256 amount);
    event MaxDepositUpdated(address token, uint256 amount);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Lock original tokens to trigger cross-chain mint of pegged tokens at a remote chain's PeggedTokenBridge.
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _token The original token address.
     * @param _amount The amount to deposit.
     * @param _mintChainId The destination chain ID to mint tokens.
     * @param _mintAccount The destination account to receive the minted pegged tokens.
     * @param _nonce A number input to guarantee unique depositId. Can be timestamp in practice.
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external nonReentrant whenNotPaused returns (bytes32) {
        bytes32 depId = _deposit(_token, _amount, _mintChainId, _mintAccount, _nonce);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(depId, msg.sender, _token, _amount, _mintChainId, _mintAccount, _nonce);
        return depId;
    }

    /**
     * @notice Lock native token as original token to trigger cross-chain mint of pegged tokens at a remote chain's
     * PeggedTokenBridge.
     * @param _amount The amount to deposit.
     * @param _mintChainId The destination chain ID to mint tokens.
     * @param _mintAccount The destination account to receive the minted pegged tokens.
     * @param _nonce A number input to guarantee unique depositId. Can be timestamp in practice.
     */
    function depositNative(
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        require(msg.value == _amount, "Amount mismatch");
        require(nativeWrap != address(0), "Native wrap not set");
        bytes32 depId = _deposit(nativeWrap, _amount, _mintChainId, _mintAccount, _nonce);
        IWETH(nativeWrap).deposit{value: _amount}();
        emit Deposited(depId, msg.sender, nativeWrap, _amount, _mintChainId, _mintAccount, _nonce);
        return depId;
    }

    function _deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) private returns (bytes32) {
        require(_amount > minDeposit[_token], "amount too small");
        require(maxDeposit[_token] == 0 || _amount <= maxDeposit[_token], "amount too large");
        bytes32 depId = keccak256(
            // len = 20 + 20 + 32 + 8 + 20 + 8 + 8 + 20 = 136
            abi.encodePacked(
                msg.sender,
                _token,
                _amount,
                _mintChainId,
                _mintAccount,
                _nonce,
                uint64(block.chainid),
                address(this)
            )
        );
        require(records[depId] == false, "record exists");
        records[depId] = true;
        return depId;
    }

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused returns (bytes32) {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Withdraw"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _request), _sigs, _signers, _powers);
        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);
        bytes32 wdId = keccak256(
            // len = 20 + 20 + 32 + 20 + 8 + 32 + 20 = 152
            abi.encodePacked(
                request.receiver,
                request.token,
                request.amount,
                request.burnAccount,
                request.refChainId,
                request.refId,
                address(this)
            )
        );
        require(records[wdId] == false, "record exists");
        records[wdId] = true;
        _updateVolume(request.token, request.amount);
        uint256 delayThreshold = delayThresholds[request.token];
        if (delayThreshold > 0 && request.amount > delayThreshold) {
            _addDelayedTransfer(wdId, request.receiver, request.token, request.amount);
        } else {
            _sendToken(request.receiver, request.token, request.amount);
        }
        emit Withdrawn(
            wdId,
            request.receiver,
            request.token,
            request.amount,
            request.refChainId,
            request.refId,
            request.burnAccount
        );
        return wdId;
    }

    function executeDelayedTransfer(bytes32 id) external whenNotPaused {
        delayedTransfer memory transfer = _executeDelayedTransfer(id);
        _sendToken(transfer.receiver, transfer.token, transfer.amount);
    }

    function setMinDeposit(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minDeposit[_tokens[i]] = _amounts[i];
            emit MinDepositUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMaxDeposit(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            maxDeposit[_tokens[i]] = _amounts[i];
            emit MaxDepositUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setWrap(address _weth) external onlyOwner {
        nativeWrap = _weth;
    }

    function _sendToken(
        address _receiver,
        address _token,
        uint256 _amount
    ) private {
        if (_token == nativeWrap) {
            // withdraw then transfer native to receiver
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "failed to send native token");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    receive() external payable {}
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ISigsVerifier.sol";
import "../interfaces/IWETH.sol";
import "../libraries/PbPegged.sol";
import "../safeguard/Pauser.sol";
import "../safeguard/VolumeControl.sol";
import "../safeguard/DelayedTransfer.sol";

/**
 * @title the vault to deposit and withdraw original tokens
 * @dev Work together with PeggedTokenBridge contracts deployed at remote chains
 */
contract OriginalTokenVault is ReentrancyGuard, Pauser, VolumeControl, DelayedTransfer {
    using SafeERC20 for IERC20;

    ISigsVerifier public immutable sigsVerifier;

    mapping(bytes32 => bool) public records;

    mapping(address => uint256) public minDeposit;
    mapping(address => uint256) public maxDeposit;

    address public nativeWrap;

    event Deposited(
        bytes32 depositId,
        address depositor,
        address token,
        uint256 amount,
        uint64 mintChainId,
        address mintAccount
    );
    event Withdrawn(
        bytes32 withdrawId,
        address receiver,
        address token,
        uint256 amount,
        // ref_chain_id defines the reference chain ID, taking values of:
        // 1. The common case of burn-withdraw: the chain ID on which the corresponding burn happened;
        // 2. Pegbridge fee claim: zero / not applicable;
        // 3. Refund for wrong deposit: this chain ID on which the deposit happened
        uint64 refChainId,
        // ref_id defines a unique reference ID, taking values of:
        // 1. The common case of burn-withdraw: the burn ID on the remote chain;
        // 2. Pegbridge fee claim: a per-account nonce;
        // 3. Refund for wrong deposit: the deposit ID on this chain
        bytes32 refId,
        address burnAccount
    );
    event MinDepositUpdated(address token, uint256 amount);
    event MaxDepositUpdated(address token, uint256 amount);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Lock original tokens to trigger cross-chain mint of pegged tokens at a remote chain's PeggedTokenBridge.
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _token The original token address.
     * @param _amount The amount to deposit.
     * @param _mintChainId The destination chain ID to mint tokens.
     * @param _mintAccount The destination account to receive the minted pegged tokens.
     * @param _nonce A number input to guarantee unique depositId. Can be timestamp in practice.
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external nonReentrant whenNotPaused {
        bytes32 depId = _deposit(_token, _amount, _mintChainId, _mintAccount, _nonce);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(depId, msg.sender, _token, _amount, _mintChainId, _mintAccount);
    }

    /**
     * @notice Lock native token as original token to trigger cross-chain mint of pegged tokens at a remote chain's
     * PeggedTokenBridge.
     * @param _amount The amount to deposit.
     * @param _mintChainId The destination chain ID to mint tokens.
     * @param _mintAccount The destination account to receive the minted pegged tokens.
     * @param _nonce A number input to guarantee unique depositId. Can be timestamp in practice.
     */
    function depositNative(
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable nonReentrant whenNotPaused {
        require(msg.value == _amount, "Amount mismatch");
        require(nativeWrap != address(0), "Native wrap not set");
        bytes32 depId = _deposit(nativeWrap, _amount, _mintChainId, _mintAccount, _nonce);
        IWETH(nativeWrap).deposit{value: _amount}();
        emit Deposited(depId, msg.sender, nativeWrap, _amount, _mintChainId, _mintAccount);
    }

    function _deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) private returns (bytes32) {
        require(_amount > minDeposit[_token], "amount too small");
        require(maxDeposit[_token] == 0 || _amount <= maxDeposit[_token], "amount too large");
        bytes32 depId = keccak256(
            // len = 20 + 20 + 32 + 8 + 20 + 8 + 8 = 116
            abi.encodePacked(msg.sender, _token, _amount, _mintChainId, _mintAccount, _nonce, uint64(block.chainid))
        );
        require(records[depId] == false, "record exists");
        records[depId] = true;
        return depId;
    }

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Withdraw"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _request), _sigs, _signers, _powers);
        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);
        bytes32 wdId = keccak256(
            // len = 20 + 20 + 32 + 20 + 8 + 32 = 132
            abi.encodePacked(
                request.receiver,
                request.token,
                request.amount,
                request.burnAccount,
                request.refChainId,
                request.refId
            )
        );
        require(records[wdId] == false, "record exists");
        records[wdId] = true;
        _updateVolume(request.token, request.amount);
        uint256 delayThreshold = delayThresholds[request.token];
        if (delayThreshold > 0 && request.amount > delayThreshold) {
            _addDelayedTransfer(wdId, request.receiver, request.token, request.amount);
        } else {
            _sendToken(request.receiver, request.token, request.amount);
        }
        emit Withdrawn(
            wdId,
            request.receiver,
            request.token,
            request.amount,
            request.refChainId,
            request.refId,
            request.burnAccount
        );
    }

    function executeDelayedTransfer(bytes32 id) external whenNotPaused {
        delayedTransfer memory transfer = _executeDelayedTransfer(id);
        _sendToken(transfer.receiver, transfer.token, transfer.amount);
    }

    function setMinDeposit(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minDeposit[_tokens[i]] = _amounts[i];
            emit MinDepositUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMaxDeposit(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            maxDeposit[_tokens[i]] = _amounts[i];
            emit MaxDepositUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setWrap(address _weth) external onlyOwner {
        nativeWrap = _weth;
    }

    function _sendToken(
        address _receiver,
        address _token,
        uint256 _amount
    ) private {
        if (_token == nativeWrap) {
            // withdraw then transfer native to receiver
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "failed to send native token");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../framework/MessageBusAddress.sol";
import "../framework/MessageSenderApp.sol";
import "../framework/MessageReceiverApp.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IUniswapV2.sol";

/**
 * @title Demo application contract that facilitates swapping on a chain, transferring to another chain,
 * and swapping another time on the destination chain before sending the result tokens to a user
 */
contract TransferSwap is MessageSenderApp, MessageReceiverApp {
    using SafeERC20 for IERC20;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not EOA");
        _;
    }

    struct SwapInfo {
        // if this array has only one element, it means no need to swap
        address[] path;
        // the following fields are only needed if path.length > 1
        address dex; // the DEX to use for the swap
        uint256 deadline; // deadline for the swap
        uint256 minRecvAmt; // minimum receive amount for the swap
    }

    struct SwapRequest {
        SwapInfo swap;
        // the receiving party (the user) of the final output token
        address receiver;
        // this field is best to be per-user per-transaction unique so that
        // a nonce that is specified by the calling party (the user),
        uint64 nonce;
        // indicates whether the output token coming out of the swap on destination
        // chain should be unwrapped before sending to the user
        bool nativeOut;
    }

    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    // emitted when requested dstChainId == srcChainId, no bridging
    event DirectSwap(
        bytes32 id,
        uint64 srcChainId,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
    );
    event SwapRequestSent(bytes32 id, uint64 dstChainId, uint256 srcAmount, address srcToken, address dstToken);
    event SwapRequestDone(bytes32 id, uint256 dstAmount, SwapStatus status);

    mapping(address => uint256) public minSwapAmounts;
    mapping(address => bool) supportedDex;

    // erc20 wrap of gas token of this chain, eg. WETH
    address public nativeWrap;

    constructor(
        address _messageBus,
        address _supportedDex,
        address _nativeWrap
    ) {
        messageBus = _messageBus;
        supportedDex[_supportedDex] = true;
        nativeWrap = _nativeWrap;
    }

    function transferWithSwapNative(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfo calldata _srcSwap,
        SwapInfo calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut
    ) external payable onlyEOA {
        require(msg.value >= _amountIn, "Amount insufficient");
        require(_srcSwap.path[0] == nativeWrap, "token mismatch");
        IWETH(nativeWrap).deposit{value: _amountIn}();
        _transferWithSwap(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _nativeOut,
            msg.value - _amountIn
        );
    }

    function transferWithSwap(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfo calldata _srcSwap,
        SwapInfo calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce
    ) external payable onlyEOA {
        IERC20(_srcSwap.path[0]).safeTransferFrom(msg.sender, address(this), _amountIn);
        _transferWithSwap(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            false,
            msg.value
        );
    }

    /**
     * @notice Sends a cross-chain transfer via the liquidity pool-based bridge and sends a message specifying a wanted swap action on the
               destination chain via the message bus
     * @param _receiver the app contract that implements the MessageReceiver abstract contract
     *        NOTE not to be confused with the receiver field in SwapInfo which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _transferWithSwap(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfo memory _srcSwap,
        SwapInfo memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee
    ) private {
        require(_srcSwap.path.length > 0, "empty src swap path");
        address srcTokenOut = _srcSwap.path[_srcSwap.path.length - 1];

        require(_amountIn > minSwapAmounts[_srcSwap.path[0]], "amount must be greater than min swap amount");
        uint64 chainId = uint64(block.chainid);
        require(_srcSwap.path.length > 1 || _dstChainId != chainId, "noop is not allowed"); // revert early to save gas

        uint256 srcAmtOut = _amountIn;

        // swap source token for intermediate token on the source DEX
        if (_srcSwap.path.length > 1) {
            bool ok = true;
            (ok, srcAmtOut) = _trySwap(_srcSwap, _amountIn);
            if (!ok) revert("src swap failed");
        }

        if (_dstChainId == chainId) {
            _directSend(_receiver, _amountIn, chainId, _srcSwap, _nonce, srcTokenOut, srcAmtOut);
        } else {
            _crossChainTransferWithSwap(
                _receiver,
                _amountIn,
                chainId,
                _dstChainId,
                _srcSwap,
                _dstSwap,
                _maxBridgeSlippage,
                _nonce,
                _nativeOut,
                _fee,
                srcTokenOut,
                srcAmtOut
            );
        }
    }

    function _directSend(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        SwapInfo memory _srcSwap,
        uint64 _nonce,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        // no need to bridge, directly send the tokens to user
        IERC20(srcTokenOut).safeTransfer(_receiver, srcAmtOut);
        // use uint64 for chainid to be consistent with other components in the system
        bytes32 id = keccak256(abi.encode(msg.sender, _chainId, _receiver, _nonce, _srcSwap));
        emit DirectSwap(id, _chainId, _amountIn, _srcSwap.path[0], srcAmtOut, srcTokenOut);
    }

    function _crossChainTransferWithSwap(
        address _receiver,
        uint256 _amountIn,
        uint64 _chainId,
        uint64 _dstChainId,
        SwapInfo memory _srcSwap,
        SwapInfo memory _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        bool _nativeOut,
        uint256 _fee,
        address srcTokenOut,
        uint256 srcAmtOut
    ) private {
        require(_dstSwap.path.length > 0, "empty dst swap path");
        bytes memory message = abi.encode(
            SwapRequest({swap: _dstSwap, receiver: msg.sender, nonce: _nonce, nativeOut: _nativeOut})
        );
        bytes32 id = _computeSwapRequestId(msg.sender, _chainId, _dstChainId, message);
        // bridge the intermediate token to destination chain along with the message
        // NOTE In production, it's better use a per-user per-transaction nonce so that it's less likely transferId collision
        // would happen at Bridge contract. Currently this nonce is a timestamp supplied by frontend
        sendMessageWithTransfer(
            _receiver,
            srcTokenOut,
            srcAmtOut,
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            _fee
        );
        emit SwapRequestSent(id, _dstChainId, _amountIn, _srcSwap.path[0], _dstSwap.path[_dstSwap.path.length - 1]);
    }

    /**
     * @notice called by MessageBus when the tokens are checked to be arrived at this contract's address.
               sends the amount received to the receiver. swaps beforehand if swap behavior is defined in message
     * NOTE: if the swap fails, it sends the tokens received directly to the receiver as fallback behavior
     * @param _token the address of the token sent through the bridge
     * @param _amount the amount of tokens received at this contract through the cross-chain bridge
     * @param _srcChainId source chain ID
     * @param _message SwapRequest message that defines the swap behavior on this destination chain
     */
    function executeMessageWithTransfer(
        address, // _sender
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        SwapRequest memory m = abi.decode((_message), (SwapRequest));
        require(_token == m.swap.path[0], "bridged token must be the same as the first token in destination swap path");
        bytes32 id = _computeSwapRequestId(m.receiver, _srcChainId, uint64(block.chainid), _message);
        uint256 dstAmount;
        SwapStatus status = SwapStatus.Succeeded;

        if (m.swap.path.length > 1) {
            bool ok = true;
            (ok, dstAmount) = _trySwap(m.swap, _amount);
            if (ok) {
                _sendToken(m.swap.path[m.swap.path.length - 1], dstAmount, m.receiver, m.nativeOut);
                status = SwapStatus.Succeeded;
            } else {
                // handle swap failure, send the received token directly to receiver
                _sendToken(_token, _amount, m.receiver, false);
                dstAmount = _amount;
                status = SwapStatus.Fallback;
            }
        } else {
            // no need to swap, directly send the bridged token to user
            _sendToken(m.swap.path[0], _amount, m.receiver, m.nativeOut);
            dstAmount = _amount;
            status = SwapStatus.Succeeded;
        }
        emit SwapRequestDone(id, dstAmount, status);
        // always return success since swap failure is already handled in-place
        return ExecutionStatus.Success;
    }

    /**
     * @notice called by MessageBus when the executeMessageWithTransfer call fails. does nothing but emitting a "fail" event
     * @param _srcChainId source chain ID
     * @param _message SwapRequest message that defines the swap behavior on this destination chain
     */
    function executeMessageWithTransferFallback(
        address, // _sender
        address, // _token
        uint256, // _amount
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        SwapRequest memory m = abi.decode((_message), (SwapRequest));
        bytes32 id = _computeSwapRequestId(m.receiver, _srcChainId, uint64(block.chainid), _message);
        emit SwapRequestDone(id, 0, SwapStatus.Failed);
        // always return fail to mark this transfer as failed since if this function is called then there nothing more
        // we can do in this app as the swap failures are already handled in executeMessageWithTransfer
        return ExecutionStatus.Fail;
    }

    function _trySwap(SwapInfo memory _swap, uint256 _amount) private returns (bool ok, uint256 amountOut) {
        uint256 zero;
        if (!supportedDex[_swap.dex]) {
            return (false, zero);
        }
        IERC20(_swap.path[0]).safeIncreaseAllowance(_swap.dex, _amount);
        try
            IUniswapV2(_swap.dex).swapExactTokensForTokens(
                _amount,
                _swap.minRecvAmt,
                _swap.path,
                address(this),
                _swap.deadline
            )
        returns (uint256[] memory amounts) {
            return (true, amounts[amounts.length - 1]);
        } catch {
            return (false, zero);
        }
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut
    ) private {
        if (_nativeOut) {
            require(_token == nativeWrap, "token mismatch");
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "failed to send native");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function _computeSwapRequestId(
        address _sender,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes memory _message
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _srcChainId, _dstChainId, _message));
    }

    function setMinSwapAmount(address _token, uint256 _minSwapAmount) external onlyOwner {
        minSwapAmounts[_token] = _minSwapAmount;
    }

    function setSupportedDex(address _dex, bool _enabled) external onlyOwner {
        supportedDex[_dex] = _enabled;
    }

    function setNativeWrap(address _nativeWrap) external onlyOwner {
        nativeWrap = _nativeWrap;
    }

    // This is needed to receive ETH when calling `IWETH.withdraw`
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../../safeguard/Ownable.sol";

abstract contract MessageBusAddress is Ownable {
    event MessageBusUpdated(address messageBus);

    address public messageBus;

    function setMessageBus(address _messageBus) public onlyOwner {
        messageBus = _messageBus;
        emit MessageBusUpdated(messageBus);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/MsgDataTypes.sol";
import "../libraries/MessageSenderLib.sol";
import "../messagebus/MessageBus.sol";
import "./MessageBusAddress.sol";

abstract contract MessageSenderApp is MessageBusAddress {
    using SafeERC20 for IERC20;

    // ============== Utility functions called by apps ==============

    /**
     * @notice Sends a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        uint256 _fee
    ) internal {
        MessageSenderLib.sendMessage(_receiver, _dstChainId, _message, messageBus, _fee);
    }

    /**
     * @notice Sends a message associated with a transfer to a contract on another chain.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     *        If message is empty, only the token transfer will be sent
     * @param _bridgeSendType One of the {BridgeSendType} enum.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        uint256 _fee
    ) internal returns (bytes32) {
        return
            MessageSenderLib.sendMessageWithTransfer(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                _message,
                _bridgeSendType,
                messageBus,
                _fee
            );
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @dev sendMessageWithTransfer with empty message
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _bridgeSendType One of the {BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType
    ) internal returns (bytes32) {
        return
            MessageSenderLib.sendMessageWithTransfer(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                "", // empty message, which will not trigger sendMessage
                _bridgeSendType,
                messageBus,
                0
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IMessageReceiverApp.sol";
import "./MessageBusAddress.sol";

abstract contract MessageReceiverApp is IMessageReceiverApp, MessageBusAddress {
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "caller is not message bus");
        _;
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IUniswapV2 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

library MsgDataTypes {
    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../interfaces/IMessageBus.sol";
import "./MsgDataTypes.sol";

library MessageSenderLib {
    using SafeERC20 for IERC20;

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal {
        IMessageBus(_messageBus).sendMessage{value: _fee}(_receiver, _dstChainId, _message);
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        (bytes32 transferId, address bridge) = sendTokenTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _bridgeSendType,
            _messageBus
        );
        if (_message.length > 0) {
            IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
                _receiver,
                _dstChainId,
                bridge,
                transferId,
                _message
            );
        }
        return transferId;
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _messageBus
    ) internal returns (bytes32 transferId, address bridge) {
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            bridge = IMessageBus(_messageBus).liquidityBridge();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            IBridge(bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
            transferId = computeLiqBridgeTransferId(_receiver, _token, _amount, _dstChainId, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            bridge = IMessageBus(_messageBus).pegVault();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            IOriginalTokenVault(bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
            transferId = computePegV1DepositId(_receiver, _token, _amount, _dstChainId, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            bridge = IMessageBus(_messageBus).pegBridge();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            IPeggedTokenBridge(bridge).burn(_token, _amount, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(bridge, 0);
            transferId = computePegV1BurnId(_receiver, _token, _amount, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit) {
            bridge = IMessageBus(_messageBus).pegVaultV2();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            transferId = IOriginalTokenVaultV2(bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn) {
            bridge = IMessageBus(_messageBus).pegBridgeV2();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            transferId = IPeggedTokenBridgeV2(bridge).burn(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(bridge, 0);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2BurnFrom) {
            bridge = IMessageBus(_messageBus).pegBridgeV2();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            transferId = IPeggedTokenBridgeV2(bridge).burnFrom(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(bridge, 0);
        } else {
            revert("bridge type not supported");
        }
    }

    function computeLiqBridgeTransferId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
            );
    }

    function computePegV1DepositId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
    }

    function computePegV1BurnId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _token, _amount, _receiver, _nonce, uint64(block.chainid)));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./MessageBusSender.sol";
import "./MessageBusReceiver.sol";

contract MessageBus is MessageBusSender, MessageBusReceiver {
    constructor(
        ISigsVerifier _sigsVerifier,
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    )
        MessageBusSender(_sigsVerifier)
        MessageBusReceiver(_liquidityBridge, _pegBridge, _pegVault, _pegBridgeV2, _pegVaultV2)
    {}

    // this is only to be called by Proxy via delegateCall as initOwner will require _owner is 0.
    // so calling init on this contract directly will guarantee to fail
    function init(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) external {
        // MUST manually call ownable init and must only call once
        initOwner();
        // we don't need sender init as _sigsVerifier is immutable so already in the deployed code
        initReceiver(_liquidityBridge, _pegBridge, _pegVault, _pegBridgeV2, _pegVaultV2);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVault {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVaultV2 {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridge {
    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridgeV2 {
    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    // same with `burn` above, use openzeppelin ERC20Burnable interface
    function burnFrom(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../libraries/MsgDataTypes.sol";

interface IMessageBus {
    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    /**
     * @notice Sends a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain..
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Sends a message associated with a transfer to a contract on another chain.
     * If messages with the same srcTransferId are sent, only one of them will succeed at dst chain..
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../../safeguard/Ownable.sol";
import "../../interfaces/ISigsVerifier.sol";

contract MessageBusSender is Ownable {
    ISigsVerifier public immutable sigsVerifier;

    uint256 public feeBase;
    uint256 public feePerByte;
    mapping(address => uint256) public withdrawnFees;

    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);

    event MessageWithTransfer(
        address indexed sender,
        address receiver,
        uint256 dstChainId,
        address bridge,
        bytes32 srcTransferId,
        bytes message,
        uint256 fee
    );

    event FeeBaseUpdated(uint256 feeBase);
    event FeePerByteUpdated(uint256 feePerByte);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Sends a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        emit Message(msg.sender, _receiver, _dstChainId, _message, msg.value);
    }

    /**
     * @notice Sends a message associated with a transfer to a contract on another chain.
     * If messages with the same srcTransferId are sent, only one of them will succeed.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        // SGN needs to verify
        // 1. msg.sender matches sender of the src transfer
        // 2. dstChainId matches dstChainId of the src transfer
        // 3. bridge is either liquidity bridge, peg src vault, or peg dst bridge
        emit MessageWithTransfer(msg.sender, _receiver, _dstChainId, _srcBridge, _srcTransferId, _message, msg.value);
    }

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "withdrawFee"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _account, _cumulativeFee), _sigs, _signers, _powers);
        uint256 amount = _cumulativeFee - withdrawnFees[_account];
        require(amount > 0, "No new amount to withdraw");
        withdrawnFees[_account] = _cumulativeFee;
        (bool sent, ) = _account.call{value: amount, gas: 50000}("");
        require(sent, "failed to withdraw fee");
    }

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) public view returns (uint256) {
        return feeBase + _message.length * feePerByte;
    }

    // -------------------- Admin --------------------

    function setFeePerByte(uint256 _fee) external onlyOwner {
        feePerByte = _fee;
        emit FeePerByteUpdated(feePerByte);
    }

    function setFeeBase(uint256 _fee) external onlyOwner {
        feeBase = _fee;
        emit FeeBaseUpdated(feeBase);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../libraries/MsgDataTypes.sol";
import "../interfaces/IMessageReceiverApp.sol";
import "../interfaces/IMessageBus.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../../safeguard/Ownable.sol";

contract MessageBusReceiver is Ownable {
    mapping(bytes32 => MsgDataTypes.TxStatus) public executedMessages;

    address public liquidityBridge; // liquidity bridge address
    address public pegBridge; // peg bridge address
    address public pegVault; // peg original vault address
    address public pegBridgeV2; // peg bridge address
    address public pegVaultV2; // peg original vault address

    // minimum amount of gas needed by this contract before it tries to
    // deliver a message to the target contract.
    uint256 public preExecuteMessageGasUsage;

    event Executed(
        MsgDataTypes.MsgType msgType,
        bytes32 msgId,
        MsgDataTypes.TxStatus status,
        address indexed receiver,
        uint64 srcChainId,
        bytes32 srcTxHash
    );
    event NeedRetry(MsgDataTypes.MsgType msgType, bytes32 msgId, uint64 srcChainId, bytes32 srcTxHash);
    event CallReverted(string reason); // help debug

    event LiquidityBridgeUpdated(address liquidityBridge);
    event PegBridgeUpdated(address pegBridge);
    event PegVaultUpdated(address pegVault);
    event PegBridgeV2Updated(address pegBridgeV2);
    event PegVaultV2Updated(address pegVaultV2);

    constructor(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) {
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    function initReceiver(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) internal {
        require(liquidityBridge == address(0), "liquidityBridge already set");
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    // ============== functions called by executor ==============

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public payable {
        // For message with token transfer, message Id is computed through transfer info
        // in order to guarantee that each transfer can only be used once.
        bytes32 messageId = verifyTransfer(_transfer);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "transfer already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransfer"));
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message, _transfer.srcTxHash),
            _sigs,
            _signers,
            _powers
        );
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessageWithTransfer(_transfer, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(
                MsgDataTypes.MsgType.MessageWithTransfer,
                messageId,
                _transfer.srcChainId,
                _transfer.srcTxHash
            );
            return;
        } else {
            est = executeMessageWithTransferFallback(_transfer, _message);
            if (est == IMessageReceiverApp.ExecutionStatus.Success) {
                status = MsgDataTypes.TxStatus.Fallback;
            } else {
                status = MsgDataTypes.TxStatus.Fail;
            }
        }
        executedMessages[messageId] = status;
        emitMessageWithTransferExecutedEvent(messageId, status, _transfer);
    }

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public payable {
        // similar to executeMessageWithTransfer
        bytes32 messageId = verifyTransfer(_transfer);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "transfer already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransferRefund"));
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message, _transfer.srcTxHash),
            _sigs,
            _signers,
            _powers
        );
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessageWithTransferRefund(_transfer, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(
                MsgDataTypes.MsgType.MessageWithTransfer,
                messageId,
                _transfer.srcChainId,
                _transfer.srcTxHash
            );
            return;
        } else {
            status = MsgDataTypes.TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emitMessageWithTransferExecutedEvent(messageId, status, _transfer);
    }

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _route The info about the sender and the receiver.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // For message without associated token transfer, message Id is computed through message info,
        // in order to guarantee that each message can only be applied once
        bytes32 messageId = computeMessageOnlyId(_route, _message);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "message already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Message"));
        IBridge(liquidityBridge).verifySigs(abi.encodePacked(domain, messageId), _sigs, _signers, _powers);
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessage(_route, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(MsgDataTypes.MsgType.MessageOnly, messageId, _route.srcChainId, _route.srcTxHash);
            return;
        } else {
            status = MsgDataTypes.TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emitMessageOnlyExecutedEvent(messageId, status, _route);
    }

    // ================= utils (to avoid stack too deep) =================

    function emitMessageWithTransferExecutedEvent(
        bytes32 _messageId,
        MsgDataTypes.TxStatus _status,
        MsgDataTypes.TransferInfo calldata _transfer
    ) private {
        emit Executed(
            MsgDataTypes.MsgType.MessageWithTransfer,
            _messageId,
            _status,
            _transfer.receiver,
            _transfer.srcChainId,
            _transfer.srcTxHash
        );
    }

    function emitMessageOnlyExecutedEvent(
        bytes32 _messageId,
        MsgDataTypes.TxStatus _status,
        MsgDataTypes.RouteInfo calldata _route
    ) private {
        emit Executed(
            MsgDataTypes.MsgType.MessageOnly,
            _messageId,
            _status,
            _route.receiver,
            _route.srcChainId,
            _route.srcTxHash
        );
    }

    function executeMessageWithTransfer(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransfer.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function executeMessageWithTransferFallback(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferFallback.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function executeMessageWithTransferRefund(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferRefund.selector,
                _transfer.token,
                _transfer.amount,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function verifyTransfer(MsgDataTypes.TransferInfo calldata _transfer) private view returns (bytes32) {
        bytes32 transferId;
        address bridgeAddr;
        if (_transfer.t == MsgDataTypes.TransferType.LqRelay) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.sender,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.srcChainId,
                    uint64(block.chainid),
                    _transfer.refId
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).transfers(transferId) == true, "bridge relay not exist");
        } else if (_transfer.t == MsgDataTypes.TransferType.LqWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    uint64(block.chainid),
                    _transfer.wdseq,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).withdraws(transferId) == true, "bridge withdraw not exist");
        } else if (
            _transfer.t == MsgDataTypes.TransferType.PegMint || _transfer.t == MsgDataTypes.TransferType.PegWithdraw
        ) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId
                )
            );
            if (_transfer.t == MsgDataTypes.TransferType.PegMint) {
                bridgeAddr = pegBridge;
                require(IPeggedTokenBridge(bridgeAddr).records(transferId) == true, "mint record not exist");
            } else {
                // _transfer.t == MsgDataTypes.TransferType.PegWithdraw
                bridgeAddr = pegVault;
                require(IOriginalTokenVault(bridgeAddr).records(transferId) == true, "withdraw record not exist");
            }
        } else if (
            _transfer.t == MsgDataTypes.TransferType.PegV2Mint || _transfer.t == MsgDataTypes.TransferType.PegV2Withdraw
        ) {
            if (_transfer.t == MsgDataTypes.TransferType.PegV2Mint) {
                bridgeAddr = pegBridgeV2;
            } else {
                // MsgDataTypes.TransferType.PegV2Withdraw
                bridgeAddr = pegVaultV2;
            }
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId,
                    bridgeAddr
                )
            );
            if (_transfer.t == MsgDataTypes.TransferType.PegV2Mint) {
                require(IPeggedTokenBridgeV2(bridgeAddr).records(transferId) == true, "mint record not exist");
            } else {
                // MsgDataTypes.TransferType.PegV2Withdraw
                require(IOriginalTokenVaultV2(bridgeAddr).records(transferId) == true, "withdraw record not exist");
            }
        }
        return keccak256(abi.encodePacked(MsgDataTypes.MsgType.MessageWithTransfer, bridgeAddr, transferId));
    }

    function computeMessageOnlyId(MsgDataTypes.RouteInfo calldata _route, bytes calldata _message)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    MsgDataTypes.MsgType.MessageOnly,
                    _route.sender,
                    _route.receiver,
                    _route.srcChainId,
                    _route.srcTxHash,
                    uint64(block.chainid),
                    _message
                )
            );
    }

    function executeMessage(MsgDataTypes.RouteInfo calldata _route, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_route.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessage.selector,
                _route.sender,
                _route.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function handleExecutionRevert(uint256 _gasLeftBeforeExecution, bytes memory _returnData) private {
        uint256 gasLeftAfterExecution = gasleft();
        uint256 maxTargetGasLimit = block.gaslimit - preExecuteMessageGasUsage;
        if (_gasLeftBeforeExecution < maxTargetGasLimit && gasLeftAfterExecution <= _gasLeftBeforeExecution / 64) {
            // if this happens, the executor must have not provided sufficient gas limit,
            // then the tx should revert instead of recording a non-retryable failure status
            // https://github.com/wolflo/evm-opcodes/blob/main/gas.md#aa-f-gas-to-send-with-call-operations
            assembly {
                invalid()
            }
        }
        emit CallReverted(getRevertMsg(_returnData));
    }

    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    // ================= helper functions =====================

    /**
     * @notice combine bridge transfer and msg execution calls into a single tx
     * @dev caller needs to get the required input params from SGN
     * @param _transferParams params to call bridge transfer
     * @param _msgParams params to execute message
     */
    function transferAndExecuteMsg(
        MsgDataTypes.BridgeTransferParams calldata _transferParams,
        MsgDataTypes.MsgWithTransferExecutionParams calldata _msgParams
    ) external {
        _bridgeTransfer(_msgParams.transfer.t, _transferParams);
        executeMessageWithTransfer(
            _msgParams.message,
            _msgParams.transfer,
            _msgParams.sigs,
            _msgParams.signers,
            _msgParams.powers
        );
    }

    /**
     * @notice combine bridge refund and msg execution calls into a single tx
     * @dev caller needs to get the required input params from SGN
     * @param _transferParams params to call bridge transfer for refund
     * @param _msgParams params to execute message for refund
     */
    function refundAndExecuteMsg(
        MsgDataTypes.BridgeTransferParams calldata _transferParams,
        MsgDataTypes.MsgWithTransferExecutionParams calldata _msgParams
    ) external {
        _bridgeTransfer(_msgParams.transfer.t, _transferParams);
        executeMessageWithTransferRefund(
            _msgParams.message,
            _msgParams.transfer,
            _msgParams.sigs,
            _msgParams.signers,
            _msgParams.powers
        );
    }

    function _bridgeTransfer(MsgDataTypes.TransferType t, MsgDataTypes.BridgeTransferParams calldata _transferParams)
        private
    {
        if (t == MsgDataTypes.TransferType.LqRelay) {
            IBridge(liquidityBridge).relay(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.LqWithdraw) {
            IBridge(liquidityBridge).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegMint) {
            IPeggedTokenBridge(pegBridge).mint(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegV2Mint) {
            IPeggedTokenBridgeV2(pegBridgeV2).mint(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegWithdraw) {
            IOriginalTokenVault(pegVault).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegV2Withdraw) {
            IOriginalTokenVaultV2(pegVaultV2).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        }
    }

    // ================= contract config =================

    function setLiquidityBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        liquidityBridge = _addr;
        emit LiquidityBridgeUpdated(liquidityBridge);
    }

    function setPegBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridge = _addr;
        emit PegBridgeUpdated(pegBridge);
    }

    function setPegVault(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVault = _addr;
        emit PegVaultUpdated(pegVault);
    }

    function setPegBridgeV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridgeV2 = _addr;
        emit PegBridgeV2Updated(pegBridgeV2);
    }

    function setPegVaultV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVaultV2 = _addr;
        emit PegVaultV2Updated(pegVaultV2);
    }

    function setPreExecuteMessageGasUsage(uint256 _usage) public onlyOwner {
        preExecuteMessageGasUsage = _usage;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageReceiverApp {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "../framework/MessageSenderApp.sol";
import "../framework/MessageReceiverApp.sol";

interface ISwapToken {
    // function sellBase(address to) external returns (uint256);
    // uniswap v2
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory);
}

contract CrossChainSwap is MessageSenderApp, MessageReceiverApp {
    using SafeERC20 for IERC20;

    address public dex; // needed on swap chain

    struct SwapInfo {
        address wantToken; // token user want to receive on dest chain
        address user;
        bool sendBack; // if true, send wantToken back to start chain
        uint32 cbrMaxSlippage; // _maxSlippage for cbridge send
    }

    constructor(address dex_) {
        dex = dex_;
    }

    // ========== on start chain ==========

    uint64 nonce; // required by IBridge.send

    // this func could be called by a router contract
    function startCrossChainSwap(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        SwapInfo calldata swapInfo // wantToken on destChain and actual user address as receiver when send back
    ) external payable {
        nonce += 1;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        bytes memory message = abi.encode(swapInfo);
        sendMessageWithTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            nonce,
            swapInfo.cbrMaxSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            msg.value
        );
    }

    // ========== on swap chain ==========
    // do dex, send received asset to src chain via bridge
    function executeMessageWithTransfer(
        address, // _sender
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        SwapInfo memory swapInfo = abi.decode((_message), (SwapInfo));
        IERC20(_token).approve(dex, _amount);
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = swapInfo.wantToken;
        if (swapInfo.sendBack) {
            nonce += 1;
            uint256[] memory swapReturn = ISwapToken(dex).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                type(uint256).max
            );
            // send received token back to start chain. swapReturn[1] is amount of wantToken
            sendTokenTransfer(
                swapInfo.user,
                swapInfo.wantToken,
                swapReturn[1],
                _srcChainId,
                nonce,
                swapInfo.cbrMaxSlippage,
                MsgDataTypes.BridgeSendType.Liquidity
            );
        } else {
            // swap to wantToken and send to user
            ISwapToken(dex).swapExactTokensForTokens(_amount, 0, path, swapInfo.user, type(uint256).max);
        }
        // bytes memory notice; // send back to src chain to handleMessage
        // sendMessage(_sender, _srcChainId, notice);
        return ExecutionStatus.Success;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../framework/MessageSenderApp.sol";
import "../framework/MessageReceiverApp.sol";

/** @title Application to test message with transfer refund flow */
contract MsgTest is MessageSenderApp, MessageReceiverApp {
    using SafeERC20 for IERC20;
    uint64 nonce;

    event MessageReceivedWithTransfer(
        address token,
        uint256 amount,
        address sender,
        uint64 srcChainId,
        address receiver,
        bytes message
    );
    event Refunded(address receiver, address token, uint256 amount, bytes message);
    event MessageReceived(address sender, uint64 srcChainId, uint64 nonce, bytes message);

    constructor(address _messageBus) {
        messageBus = _messageBus;
    }

    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint32 _maxSlippage,
        bytes calldata _message,
        MsgDataTypes.BridgeSendType _bridgeSendType
    ) external payable {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        bytes memory message = abi.encode(msg.sender, _message);
        sendMessageWithTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            nonce,
            _maxSlippage,
            message,
            _bridgeSendType,
            msg.value
        );
        nonce++;
    }

    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        (address receiver, bytes memory message) = abi.decode((_message), (address, bytes));
        IERC20(_token).safeTransfer(receiver, _amount);
        emit MessageReceivedWithTransfer(_token, _amount, _sender, _srcChainId, receiver, message);
        return ExecutionStatus.Success;
    }

    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        (address receiver, bytes memory message) = abi.decode((_message), (address, bytes));
        IERC20(_token).safeTransfer(receiver, _amount);
        emit Refunded(receiver, _token, _amount, message);
        return ExecutionStatus.Success;
    }

    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes calldata _message
    ) external payable {
        bytes memory message = abi.encode(nonce, _message);
        nonce++;
        sendMessage(_receiver, _dstChainId, message, msg.value);
    }

    function sendMessages(
        address _receiver,
        uint64 _dstChainId,
        bytes[] calldata _messages,
        uint256[] calldata _fees
    ) external payable {
        for (uint256 i = 0; i < _messages.length; i++) {
            bytes memory message = abi.encode(nonce, _messages[i]);
            nonce++;
            sendMessage(_receiver, _dstChainId, message, _fees[i]);
        }
    }

    function sendMessageWithNonce(
        address _receiver,
        uint64 _dstChainId,
        bytes calldata _message,
        uint64 _nonce
    ) external payable {
        bytes memory message = abi.encode(_nonce, _message);
        sendMessage(_receiver, _dstChainId, message, msg.value);
    }

    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        (uint64 n, bytes memory message) = abi.decode((_message), (uint64, bytes));
        require(n != 100000000000001, "invalid nonce"); // test revert with reason
        if (n == 100000000000002) {
            // test revert without reason
            revert();
        } else if (n == 100000000000003) {
            return ExecutionStatus.Retry;
        }
        emit MessageReceived(_sender, _srcChainId, n, message);
        return ExecutionStatus.Success;
    }

    function drainToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../../../safeguard/Ownable.sol";

interface IMultiBridgeToken {
    function updateBridgeSupplyCap(address _bridge, uint256 _cap) external;
}

// restrict multi-bridge token to effectively only have one bridge (minter)
contract RestrictedMultiBridgeTokenOwner is Ownable {
    address public immutable token;
    address public bridge;

    constructor(address _token, address _bridge) {
        token = _token;
        bridge = _bridge;
    }

    function updateBridgeSupplyCap(uint256 _cap) external onlyOwner {
        IMultiBridgeToken(token).updateBridgeSupplyCap(bridge, _cap);
    }

    function changeBridge(address _bridge, uint256 _cap) external onlyOwner {
        // set previous bridge cap to 1 to disable mint but still allow burn
        // till its total supply becomes zero
        IMultiBridgeToken(token).updateBridgeSupplyCap(bridge, 1);
        // set new bridge and cap
        IMultiBridgeToken(token).updateBridgeSupplyCap(_bridge, _cap);
        bridge = _bridge;
    }

    function revokeBridge(address _bridge) external onlyOwner {
        // set previous bridge cap to 0 to disable both mint and burn
        IMultiBridgeToken(token).updateBridgeSupplyCap(_bridge, 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../safeguard/Ownable.sol";

/**
 * @title Example Multi-Bridge Pegged ERC20 token
 */
contract MultiBridgeToken is ERC20, Ownable {
    struct Supply {
        uint256 cap;
        uint256 total;
    }
    mapping(address => Supply) public bridges; // bridge address -> supply

    uint8 private immutable _decimals;

    event BridgeSupplyCapUpdated(address bridge, uint256 supplyCap);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    /**
     * @notice Mints tokens to an address. Increases total amount minted by the calling bridge.
     * @param _to The address to mint tokens to.
     * @param _amount The amount to mint.
     */
    function mint(address _to, uint256 _amount) external returns (bool) {
        Supply storage b = bridges[msg.sender];
        require(b.cap > 0, "invalid caller");
        b.total += _amount;
        require(b.total <= b.cap, "exceeds bridge supply cap");
        _mint(_to, _amount);
        return true;
    }

    /**
     * @notice Burns tokens for msg.sender.
     * @param _amount The amount to burn.
     */
    function burn(uint256 _amount) external returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    /**
     * @notice Burns tokens from an address. Decreases total amount minted if called by a bridge.
     * Alternative to {burnFrom} for compatibility with some bridge implementations.
     * See {_burnFrom}.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function burn(address _from, uint256 _amount) external returns (bool) {
        return _burnFrom(_from, _amount);
    }

    /**
     * @notice Burns tokens from an address. Decreases total amount minted if called by a bridge.
     * See {_burnFrom}.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function burnFrom(address _from, uint256 _amount) external returns (bool) {
        return _burnFrom(_from, _amount);
    }

    /**
     * @dev Burns tokens from an address, deducting from the caller's allowance.
     *      Decreases total amount minted if called by a bridge.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function _burnFrom(address _from, uint256 _amount) internal returns (bool) {
        Supply storage b = bridges[msg.sender];
        if (b.cap > 0 || b.total > 0) {
            // set cap to 1 would effectively disable a deprecated bridge's ability to burn
            require(b.total >= _amount, "exceeds bridge minted amount");
            unchecked {
                b.total -= _amount;
            }
        }
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
        return true;
    }

    /**
     * @notice Returns the decimals of the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Updates the supply cap for a bridge.
     * @param _bridge The bridge address.
     * @param _cap The new supply cap.
     */
    function updateBridgeSupplyCap(address _bridge, uint256 _cap) external onlyOwner {
        // cap == 0 means revoking bridge role
        bridges[_bridge].cap = _cap;
        emit BridgeSupplyCapUpdated(_bridge, _cap);
    }

    /**
     * @notice Returns the owner address. Required by BEP20.
     */
    function getOwner() external view returns (address) {
        return owner();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../MultiBridgeToken.sol";

/**
 * @title Example Multi-Bridge Pegged ERC20Permit token
 */
contract MultiBridgeTokenPermit is ERC20Permit, MultiBridgeToken {
    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) MultiBridgeToken(name_, symbol_, decimals_) ERC20Permit(name_) {
        _decimals = decimals_;
    }

    function decimals() public view override(ERC20, MultiBridgeToken) returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../SingleBridgeToken.sol";

/**
 * @title Example Pegged ERC20Permit token
 */
contract SingleBridgeTokenPermit is ERC20Permit, SingleBridgeToken {
    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address bridge_
    ) SingleBridgeToken(name_, symbol_, decimals_, bridge_) ERC20Permit(name_) {
        _decimals = decimals_;
    }

    function decimals() public view override(ERC20, SingleBridgeToken) returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Example Pegged ERC20 token
 */
contract SingleBridgeToken is ERC20, Ownable {
    address public bridge;

    uint8 private immutable _decimals;

    event BridgeUpdated(address bridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address bridge_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        bridge = bridge_;
    }

    /**
     * @notice Mints tokens to an address.
     * @param _to The address to mint tokens to.
     * @param _amount The amount to mint.
     */
    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    /**
     * @notice Burns tokens for msg.sender.
     * @param _amount The amount to burn.
     */
    function burn(uint256 _amount) external returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    /**
     * @notice Burns tokens from an address.
     * Alternative to {burnFrom} for compatibility with some bridge implementations.
     * See {_burnFrom}.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function burn(address _from, uint256 _amount) external returns (bool) {
        return _burnFrom(_from, _amount);
    }

    /**
     * @notice Burns tokens from an address.
     * See {_burnFrom}.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function burnFrom(address _from, uint256 _amount) external returns (bool) {
        return _burnFrom(_from, _amount);
    }

    /**
     * @dev Burns tokens from an address, deducting from the caller's allowance.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function _burnFrom(address _from, uint256 _amount) internal returns (bool) {
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
        return true;
    }

    /**
     * @notice Returns the decimals of the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Updates the bridge address.
     * @param _bridge The bridge address.
     */
    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    /**
     * @notice Returns the owner address. Required by BEP20.
     */
    function getOwner() external view returns (address) {
        return owner();
    }
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Use pegged model to support no-slippage liquidity pool
contract WrappedBridgeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // The PeggedTokenBridge
    address public bridge;
    // The canonical
    address public immutable canonical;

    mapping(address => uint256) public liquidity;

    event BridgeUpdated(address bridge);
    event LiquidityAdded(address provider, uint256 amount);
    event LiquidityRemoved(address provider, uint256 amount);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address canonical_
    ) ERC20(name_, symbol_) {
        bridge = bridge_;
        canonical = canonical_;
    }

    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(address(this), _amount);
        IERC20(canonical).safeTransfer(_to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyBridge returns (bool) {
        _burn(address(this), _amount);
        IERC20(canonical).safeTransferFrom(_from, address(this), _amount);
        return true;
    }

    function addLiquidity(uint256 _amount) external {
        liquidity[msg.sender] += _amount;
        IERC20(canonical).safeTransferFrom(msg.sender, address(this), _amount);
        emit LiquidityAdded(msg.sender, _amount);
    }

    function removeLiquidity(uint256 _amount) external {
        liquidity[msg.sender] -= _amount;
        IERC20(canonical).safeTransfer(msg.sender, _amount);
        emit LiquidityRemoved(msg.sender, _amount);
    }

    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(canonical).decimals();
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    constructor() ERC20("WETH", "WETH") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        _burn(msg.sender, _amount);
        (bool sent, ) = msg.sender.call{value: _amount, gas: 50000}("");
        require(sent, "failed to send");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title A test ERC20 token.
 */
contract TestERC20 is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 1e28;

    /**
     * @dev Constructor that gives msg.sender all of the existing tokens.
     */
    constructor() ERC20("TestERC20", "TERC20") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISwapCanoToken {
    function swapBridgeForCanonical(address, uint256) external returns (uint256);

    function swapCanonicalForBridge(address, uint256) external returns (uint256);
}

/**
 * @title Per bridge intermediary token that supports swapping with a canonical token.
 */
contract SwapBridgeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public bridge;
    address public immutable canonical; // canonical token that support swap

    event BridgeUpdated(address bridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address canonical_
    ) ERC20(name_, symbol_) {
        bridge = bridge_;
        canonical = canonical_;
    }

    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(address(this), _amount); // add amount to myself so swapBridgeForCanonical can transfer amount
        uint256 got = ISwapCanoToken(canonical).swapBridgeForCanonical(address(this), _amount);
        // now this has canonical token, next step is to transfer to user
        IERC20(canonical).safeTransfer(_to, got);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyBridge returns (bool) {
        IERC20(canonical).safeTransferFrom(_from, address(this), _amount);
        uint256 got = ISwapCanoToken(canonical).swapCanonicalForBridge(address(this), _amount);
        _burn(address(this), got);
        return true;
    }

    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    // approve canonical token so swapBridgeForCanonical can work. or we approve before call it in mint w/ added gas
    function approveCanonical() external onlyOwner {
        _approve(address(this), canonical, type(uint256).max);
    }

    function revokeCanonical() external onlyOwner {
        _approve(address(this), canonical, 0);
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(canonical).decimals();
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Intermediary token that automatically transfers the canonical token when interacting with approved bridges.
 */
contract IntermediaryOriginalToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public bridges;
    address public immutable canonical; // canonical token

    event BridgeUpdated(address bridge, bool enable);

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory bridges_,
        address canonical_
    ) ERC20(name_, symbol_) {
        for (uint256 i = 0; i < bridges_.length; i++) {
            bridges[bridges_[i]] = true;
        }
        canonical = canonical_;
    }

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        bool success = super.transfer(_to, _amount);
        if (bridges[msg.sender]) {
            _burn(_to, _amount);
            IERC20(canonical).safeTransfer(_to, _amount);
        }
        return success;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        if (bridges[msg.sender]) {
            _mint(_from, _amount);
            IERC20(canonical).safeTransferFrom(_from, address(this), _amount);
        }
        return super.transferFrom(_from, _to, _amount);
    }

    function updateBridge(address _bridge, bool _enable) external onlyOwner {
        bridges[_bridge] = _enable;
        emit BridgeUpdated(_bridge, _enable);
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(canonical).decimals();
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20MintableBurnable is IERC20 {
    function mint(address receiver, uint256 amount) external;

    function burn(uint256 amount) external;
}

/**
 * @title Per bridge intermediary token that delegates to a canonical token.
 * Useful for canonical tokens that don't support the burn / burnFrom function signature required by
 * PeggedTokenBridge.
 */
contract IntermediaryBridgeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public bridge;
    address public immutable canonical; // canonical token that support swap

    event BridgeUpdated(address bridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address canonical_
    ) ERC20(name_, symbol_) {
        bridge = bridge_;
        canonical = canonical_;
    }

    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(address(this), _amount); // totalSupply == bridge liquidity
        IERC20MintableBurnable(canonical).mint(_to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyBridge returns (bool) {
        _burn(address(this), _amount);
        IERC20(canonical).safeTransferFrom(_from, address(this), _amount);
        IERC20MintableBurnable(canonical).burn(_amount);
        return true;
    }

    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(canonical).decimals();
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IOntologyBridgeTokenWrapper {
    function swapBridgeForCanonical(
        address bridgeToken,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function swapCanonicalForBridge(
        address bridgeToken,
        address _to,
        uint256 _amount
    ) external payable returns (uint256);
}

/**
 * @title Intermediary bridge token that supports swapping with the Ontology bridge token wrapper.
 * NOTE: The bridge wrapper is NOT the canonical token itself.
 */
contract OntologyBridgeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // The PeggedTokenBridge
    address public bridge;
    // Bridge token wrapper for swapping
    address public immutable wrapper;
    // The canonical token
    address public immutable canonical;

    event BridgeUpdated(address bridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address wrapper_,
        address canonical_
    ) ERC20(name_, symbol_) {
        bridge = bridge_;
        wrapper = wrapper_;
        canonical = canonical_;
    }

    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(address(this), _amount);
        _approve(address(this), wrapper, _amount);
        // NOTE: swapBridgeForCanonical automatically transfers canonical token to _to.
        IOntologyBridgeTokenWrapper(wrapper).swapBridgeForCanonical(address(this), _to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyBridge returns (bool) {
        IERC20(canonical).safeTransferFrom(_from, address(this), _amount);
        IERC20(canonical).safeIncreaseAllowance(address(wrapper), _amount);
        // NOTE: swapCanonicalForBridge automatically transfers bridge token to _from.
        uint256 got = IOntologyBridgeTokenWrapper(wrapper).swapCanonicalForBridge(address(this), _from, _amount);
        _burn(_from, got);
        return true;
    }

    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(canonical).decimals();
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMaiBridgeHub {
    // send bridge token, get asset
    function swapIn(address, uint256) external;

    // send asset, get bridge token back
    function swapOut(address, uint256) external;

    // asset address
    function asset() external view returns (address);
}

/**
 * @title Intermediary bridge token that supports swapping with the Mai hub.
 * NOTE: Mai hub is NOT the canonical token itself. The asset is set in the hub constructor.
 */
contract MaiBridgeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // The PeggedTokenBridge
    address public bridge;
    // Mai hub for swapping
    address public immutable maihub;
    // The canonical Mai token
    address public immutable asset;

    event BridgeUpdated(address bridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address maihub_
    ) ERC20(name_, symbol_) {
        bridge = bridge_;
        maihub = maihub_;
        asset = IMaiBridgeHub(maihub_).asset();
    }

    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(address(this), _amount); // add amount to myself so swapIn can transfer amount to hub
        _approve(address(this), maihub, _amount);
        IMaiBridgeHub(maihub).swapIn(address(this), _amount);
        // now this has canonical token, next step is to transfer to user
        IERC20(asset).safeTransfer(_to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyBridge returns (bool) {
        IERC20(asset).safeTransferFrom(_from, address(this), _amount);
        IERC20(asset).safeIncreaseAllowance(address(maihub), _amount);
        IMaiBridgeHub(maihub).swapOut(address(this), _amount);
        _burn(address(this), _amount);
        return true;
    }

    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(asset).decimals();
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFraxCanoToken {
    function exchangeOldForCanonical(address, uint256) external returns (uint256);

    function exchangeCanonicalForOld(address, uint256) external returns (uint256);
}

/**
 * @title Intermediary bridge token that supports swapping with the canonical Frax token.
 */
contract FraxBridgeToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // The PeggedTokenBridge
    address public bridge;
    // The canonical Frax token that supports swapping
    address public immutable canonical;

    event BridgeUpdated(address bridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not bridge");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address bridge_,
        address canonical_
    ) ERC20(name_, symbol_) {
        bridge = bridge_;
        canonical = canonical_;
    }

    function mint(address _to, uint256 _amount) external onlyBridge returns (bool) {
        _mint(address(this), _amount); // add amount to myself so exchangeOldForCanonical can transfer amount
        _approve(address(this), canonical, _amount);
        uint256 got = IFraxCanoToken(canonical).exchangeOldForCanonical(address(this), _amount);
        // now this has canonical token, next step is to transfer to user
        IERC20(canonical).safeTransfer(_to, got);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyBridge returns (bool) {
        IERC20(canonical).safeTransferFrom(_from, address(this), _amount);
        uint256 got = IFraxCanoToken(canonical).exchangeCanonicalForOld(address(this), _amount);
        _burn(address(this), got);
        return true;
    }

    function updateBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(bridge);
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC20(canonical).decimals();
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../safeguard/Ownable.sol";
import "../interfaces/ISigsVerifier.sol";

/**
 * @title Multi-sig verification and management functions for {Bridge}.
 */
contract Signers is Ownable, ISigsVerifier {
    using ECDSA for bytes32;

    bytes32 public ssHash;
    uint256 public triggerTime; // timestamp when last update was triggered

    // reset can be called by the owner address for emergency recovery
    uint256 public resetTime;
    uint256 public noticePeriod; // advance notice period as seconds for reset
    uint256 constant MAX_INT = 2**256 - 1;

    event SignersUpdated(address[] _signers, uint256[] _powers);

    event ResetNotification(uint256 resetTime);

    /**
     * @notice Verifies that a message is signed by a quorum among the signers
     * The sigs must be sorted by signer addresses in ascending order.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public view override {
        bytes32 h = keccak256(abi.encodePacked(_signers, _powers));
        require(ssHash == h, "Mismatch current signers");
        _verifySignedPowers(keccak256(_msg).toEthSignedMessageHash(), _sigs, _signers, _powers);
    }

    /**
     * @notice Update new signers.
     * @param _newSigners sorted list of new signers
     * @param _curPowers powers of new signers
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _curSigners sorted list of current signers
     * @param _curPowers powers of current signers
     */
    function updateSigners(
        uint256 _triggerTime,
        address[] calldata _newSigners,
        uint256[] calldata _newPowers,
        bytes[] calldata _sigs,
        address[] calldata _curSigners,
        uint256[] calldata _curPowers
    ) external {
        // use trigger time for nonce protection, must be ascending
        require(_triggerTime > triggerTime, "Trigger time is not increasing");
        // make sure triggerTime is not too large, as it cannot be decreased once set
        require(_triggerTime < block.timestamp + 3600, "Trigger time is too large");
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "UpdateSigners"));
        verifySigs(abi.encodePacked(domain, _triggerTime, _newSigners, _newPowers), _sigs, _curSigners, _curPowers);
        _updateSigners(_newSigners, _newPowers);
        triggerTime = _triggerTime;
    }

    /**
     * @notice reset signers, only used for init setup and emergency recovery
     */
    function resetSigners(address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        require(block.timestamp > resetTime, "not reach reset time");
        resetTime = MAX_INT;
        _updateSigners(_signers, _powers);
    }

    function notifyResetSigners() external onlyOwner {
        resetTime = block.timestamp + noticePeriod;
        emit ResetNotification(resetTime);
    }

    function increaseNoticePeriod(uint256 period) external onlyOwner {
        require(period > noticePeriod, "notice period can only be increased");
        noticePeriod = period;
    }

    // separate from verifySigs func to avoid "stack too deep" issue
    function _verifySignedPowers(
        bytes32 _hash,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) private pure {
        require(_signers.length == _powers.length, "signers and powers length not match");
        uint256 totalPower; // sum of all signer.power
        for (uint256 i = 0; i < _signers.length; i++) {
            totalPower += _powers[i];
        }
        uint256 quorum = (totalPower * 2) / 3 + 1;

        uint256 signedPower; // sum of signer powers who are in sigs
        address prev = address(0);
        uint256 index = 0;
        for (uint256 i = 0; i < _sigs.length; i++) {
            address signer = _hash.recover(_sigs[i]);
            require(signer > prev, "signers not in ascending order");
            prev = signer;
            // now find match signer add its power
            while (signer > _signers[index]) {
                index += 1;
                require(index < _signers.length, "signer not found");
            }
            if (signer == _signers[index]) {
                signedPower += _powers[index];
            }
            if (signedPower >= quorum) {
                // return early to save gas
                return;
            }
        }
        revert("quorum not reached");
    }

    function _updateSigners(address[] calldata _signers, uint256[] calldata _powers) private {
        require(_signers.length == _powers.length, "signers and powers length not match");
        address prev = address(0);
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] > prev, "New signers not in ascending order");
            prev = _signers[i];
        }
        ssHash = keccak256(abi.encodePacked(_signers, _powers));
        emit SignersUpdated(_signers, _powers);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "../framework/MessageReceiverApp.sol";
import "../interfaces/IMessageBus.sol";
import "../../safeguard/Pauser.sol";

// interface for NFT contract, ERC721 and metadata, only funcs needed by NFTBridge
interface INFT {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    // we do not support NFT that charges transfer fees
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // impl by NFToken contract, mint an NFT with id and uri to user or burn
    function bridgeMint(
        address to,
        uint256 id,
        string memory uri
    ) external;

    function burn(uint256 id) external;
}

/** @title NFT Bridge */
contract NFTBridge is MessageReceiverApp, Pauser {
    /// per dest chain id executor fee in this chain's gas token
    mapping(uint64 => uint256) public destTxFee;
    /// per dest chain id NFTBridge address
    mapping(uint64 => address) public destBridge;
    /// first key is NFT address on this chain, 2nd key is dest chain id, value is address on dest chain
    mapping(address => mapping(uint64 => address)) public destNFTAddr;

    /// only set to true if NFT addr on this chain is the orig, so we will use deposit/withdraw instead of burn/mint.
    /// not applicable for mcn nft (always burn/mint)
    mapping(address => bool) public origNFT;

    struct NFTMsg {
        address user; // receiver of minted or withdrawn NFT
        address nft; // NFT contract on mint/withdraw chain
        uint256 id; // token ID
        string uri; // tokenURI from source NFT
    }
    // emit in deposit or burn
    event Sent(address sender, address srcNft, uint256 id, uint64 dstChid, address receiver, address dstNft);
    // emit for mint or withdraw message
    event Received(address receiver, address nft, uint256 id, uint64 srcChid);

    // emit when params change
    event SetDestNFT(address srcNft, uint64 dstChid, address dstNft);
    event SetTxFee(uint64 chid, uint256 fee);
    event SetDestBridge(uint64 dstChid, address dstNftBridge);
    event FeeClaimed(uint256 amount);
    event SetOrigNFT(address nft, bool isOrig);
    // emit if executeMessage calls nft transfer or bridgeMint returns error
    event ExtCallErr(bytes returnData);

    constructor(address _msgBus) {
        messageBus = _msgBus;
    }

    // only to be called by Proxy via delegatecall and will modify Proxy state
    // initOwner will fail if owner is already set, so only delegateCall will work
    function init(address _msgBus) external {
        initOwner();
        messageBus = _msgBus;
    }

    /**
     * @notice totalFee returns gas token value to be set in user tx, includes both cbridge msg fee and executor fee on dest chain
     * @dev we use _nft address for user as it's same length so same msg cost
     * @param _dstChid dest chain ID
     * @param _nft address of source NFT contract
     * @param _id token ID to bridge (need to get accurate tokenURI length)
     * @return total fee needed for user tx
     */
    function totalFee(
        uint64 _dstChid,
        address _nft,
        uint256 _id
    ) external view returns (uint256) {
        string memory _uri = INFT(_nft).tokenURI(_id);
        bytes memory message = abi.encode(NFTMsg(_nft, _nft, _id, _uri));
        return IMessageBus(messageBus).calcFee(message) + destTxFee[_dstChid];
    }

    // ===== called by user
    /**
     * @notice locks or burn user's NFT in this contract and send message to mint (or withdraw) on dest chain
     * @param _nft address of source NFT contract
     * @param _id nft token ID to bridge
     * @param _dstChid dest chain ID
     * @param _receiver receiver address on dest chain
     */
    function sendTo(
        address _nft,
        uint256 _id,
        uint64 _dstChid,
        address _receiver
    ) external payable whenNotPaused {
        require(msg.sender == INFT(_nft).ownerOf(_id), "not token owner");
        string memory _uri = INFT(_nft).tokenURI(_id);
        if (origNFT[_nft] == true) {
            // deposit
            INFT(_nft).transferFrom(msg.sender, address(this), _id);
            require(INFT(_nft).ownerOf(_id) == address(this), "transfer NFT failed");
        } else {
            // burn
            INFT(_nft).burn(_id);
        }
        (address _dstBridge, address _dstNft) = checkAddr(_nft, _dstChid);
        msgBus(_dstBridge, _dstChid, abi.encode(NFTMsg(_receiver, _dstNft, _id, _uri)));
        emit Sent(msg.sender, _nft, _id, _dstChid, _receiver, _dstNft);
    }

    // ===== called by MCN NFT after NFT is burnt
    function sendMsg(
        uint64 _dstChid,
        address _sender,
        address _receiver,
        uint256 _id,
        string calldata _uri
    ) external payable whenNotPaused {
        address _nft = msg.sender;
        (address _dstBridge, address _dstNft) = checkAddr(_nft, _dstChid);
        msgBus(_dstBridge, _dstChid, abi.encode(NFTMsg(_receiver, _dstNft, _id, _uri)));
        emit Sent(_sender, _nft, _id, _dstChid, _receiver, _dstNft);
    }

    // ===== called by msgbus
    function executeMessage(
        address sender,
        uint64 srcChid,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        // Must check sender to ensure msg is from another nft bridge
        // but we allow retry later in case it's a temporary config error
        // risk is invalid sender will be retried but this can be easily filtered
        // in executor or require manual trigger for retry
        if (paused() || sender != destBridge[srcChid]) {
            return ExecutionStatus.Retry;
        }
        // withdraw original locked nft back to user, or mint new nft depending on if this is the orig chain of nft
        NFTMsg memory nftMsg = abi.decode((_message), (NFTMsg));
        // if we are on nft orig chain, use transfer, otherwise, use mint
        if (origNFT[nftMsg.nft] == true) {
            try INFT(nftMsg.nft).transferFrom(address(this), nftMsg.user, nftMsg.id) {
                // do nothing here to move on to emit Received event and return success
            } catch (bytes memory returnData) {
                emit ExtCallErr(returnData);
                return ExecutionStatus.Retry;
            }
        } else {
            try INFT(nftMsg.nft).bridgeMint(nftMsg.user, nftMsg.id, nftMsg.uri) {
                // do nothing here to move on to emit Received event and return success
            } catch (bytes memory returnData) {
                emit ExtCallErr(returnData);
                return ExecutionStatus.Retry;
            }
        }
        emit Received(nftMsg.user, nftMsg.nft, nftMsg.id, srcChid);
        return ExecutionStatus.Success;
    }

    // ===== internal utils
    // check _nft and destChid are valid, return dstBridge and dstNft
    function checkAddr(address _nft, uint64 _dstChid) internal view returns (address dstBridge, address dstNft) {
        dstBridge = destBridge[_dstChid];
        require(dstBridge != address(0), "dest NFT Bridge not found");
        dstNft = destNFTAddr[_nft][_dstChid];
        require(dstNft != address(0), "dest NFT not found");
    }

    // check fee and call msgbus sendMessage
    function msgBus(
        address _dstBridge,
        uint64 _dstChid,
        bytes memory message
    ) internal {
        uint256 fee = IMessageBus(messageBus).calcFee(message);
        require(msg.value >= fee + destTxFee[_dstChid], "insufficient fee");
        IMessageBus(messageBus).sendMessage{value: fee}(_dstBridge, _dstChid, message);
    }

    // only owner
    // set per NFT, per chain id, address
    function setDestNFT(
        address srcNft,
        uint64 dstChid,
        address dstNft
    ) external onlyOwner {
        destNFTAddr[srcNft][dstChid] = dstNft;
        emit SetDestNFT(srcNft, dstChid, dstNft);
    }

    // set all dest chains
    function setDestNFTs(
        address srcNft,
        uint64[] calldata dstChid,
        address[] calldata dstNft
    ) external onlyOwner {
        require(dstChid.length == dstNft.length, "length mismatch");
        for (uint256 i = 0; i < dstChid.length; i++) {
            destNFTAddr[srcNft][dstChid[i]] = dstNft[i];
        }
    }

    // set destTxFee
    function setTxFee(uint64 chid, uint256 fee) external onlyOwner {
        destTxFee[chid] = fee;
        emit SetTxFee(chid, fee);
    }

    // set per chain id, nft bridge address
    function setDestBridge(uint64 dstChid, address dstNftBridge) external onlyOwner {
        destBridge[dstChid] = dstNftBridge;
        emit SetDestBridge(dstChid, dstNftBridge);
    }

    // batch set nft bridge addresses for multiple chainids
    function setDestBridges(uint64[] calldata dstChid, address[] calldata dstNftBridge) external onlyOwner {
        for (uint256 i = 0; i < dstChid.length; i++) {
            destBridge[dstChid[i]] = dstNftBridge[i];
        }
    }

    // only called on NFT's orig chain, not applicable for mcn nft
    function setOrigNFT(address _nft) external onlyOwner {
        origNFT[_nft] = true;
        emit SetOrigNFT(_nft, true);
    }

    // remove origNFT entry
    function delOrigNFT(address _nft) external onlyOwner {
        delete origNFT[_nft];
        emit SetOrigNFT(_nft, false);
    }

    // send all gas token this contract has to owner
    function claimFee() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit FeeClaimed(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./PbBridge.sol";
import "./PbPegged.sol";
import "./PbPool.sol";
import "../interfaces/IBridge.sol";
import "../interfaces/IOriginalTokenVault.sol";
import "../interfaces/IOriginalTokenVaultV2.sol";
import "../interfaces/IPeggedTokenBridge.sol";
import "../interfaces/IPeggedTokenBridgeV2.sol";

interface INativeWrap {
    function nativeWrap() external view returns (address);
}

library BridgeTransferLib {
    using SafeERC20 for IERC20;

    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    enum BridgeReceiveType {
        Null,
        LqRelay,
        LqWithdraw,
        PegMint,
        PegWithdraw,
        PegV2Mint,
        PegV2Withdraw
    }

    struct ReceiveInfo {
        bytes32 transferId;
        address receiver;
        address token; // 0 address for native token
        uint256 amount;
        bytes32 refid; // reference id, e.g., srcTransferId for refund
    }

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Send a cross-chain transfer either via liquidity pool-based bridge or in the form of pegged mint / burn.
     * @param _receiver The address of the receiver.
     * @param _token The address of the token.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {BridgeSendType.Liquidity}.
     * @param _bridgeSendType The type of the bridge used by this transfer. One of the {BridgeSendType} enum.
     * @param _bridgeAddr The address of the bridge used.
     */
    function sendTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage, // slippage * 1M, eg. 0.5% -> 5000
        BridgeSendType _bridgeSendType,
        address _bridgeAddr
    ) internal returns (bytes32) {
        bytes32 transferId;
        IERC20(_token).safeIncreaseAllowance(_bridgeAddr, _amount);
        if (_bridgeSendType == BridgeSendType.Liquidity) {
            IBridge(_bridgeAddr).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
            transferId = keccak256(
                abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
            );
        } else if (_bridgeSendType == BridgeSendType.PegDeposit) {
            IOriginalTokenVault(_bridgeAddr).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
        } else if (_bridgeSendType == BridgeSendType.PegBurn) {
            IPeggedTokenBridge(_bridgeAddr).burn(_token, _amount, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _receiver, _nonce, uint64(block.chainid))
            );
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridgeAddr, 0);
        } else if (_bridgeSendType == BridgeSendType.PegV2Deposit) {
            transferId = IOriginalTokenVaultV2(_bridgeAddr).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == BridgeSendType.PegV2Burn) {
            transferId = IPeggedTokenBridgeV2(_bridgeAddr).burn(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridgeAddr, 0);
        } else if (_bridgeSendType == BridgeSendType.PegV2BurnFrom) {
            transferId = IPeggedTokenBridgeV2(_bridgeAddr).burnFrom(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridgeAddr, 0);
        } else {
            revert("bridge send type not supported");
        }
        return transferId;
    }

    /**
     * @notice Receive a cross-chain transfer.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeReceiveType The type of the received transfer. One of the {BridgeReceiveType} enum.
     * @param _bridgeAddr The address of the bridge used.
     */
    function receiveTransfer(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        BridgeReceiveType _bridgeReceiveType,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        if (_bridgeReceiveType == BridgeReceiveType.LqRelay) {
            return receiveLiquidityRelay(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.LqWithdraw) {
            return receiveLiquidityWithdraw(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegWithdraw) {
            return receivePegWithdraw(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegMint) {
            return receivePegMint(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegV2Withdraw) {
            return receivePegV2Withdraw(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegV2Mint) {
            return receivePegV2Mint(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else {
            revert("bridge receive type not supported");
        }
    }

    /**
     * @notice Receive a liquidity bridge relay.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of liquidity bridge.
     */
    function receiveLiquidityRelay(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbBridge.Relay memory request = PbBridge.decRelay(_request);
        recv.transferId = keccak256(
            abi.encodePacked(
                request.sender,
                request.receiver,
                request.token,
                request.amount,
                request.srcChainId,
                uint64(block.chainid),
                request.srcTransferId
            )
        );
        recv.refid = request.srcTransferId;
        recv.receiver = request.receiver;
        recv.token = request.token;
        recv.amount = request.amount;
        if (!IBridge(_bridgeAddr).transfers(recv.transferId)) {
            IBridge(_bridgeAddr).relay(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive a liquidity bridge withdrawal.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of liquidity bridge.
     */
    function receiveLiquidityWithdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPool.WithdrawMsg memory request = PbPool.decWithdrawMsg(_request);
        recv.transferId = keccak256(
            abi.encodePacked(request.chainid, request.seqnum, request.receiver, request.token, request.amount)
        );
        recv.refid = request.refid;
        recv.receiver = request.receiver;
        if (INativeWrap(_bridgeAddr).nativeWrap() == request.token) {
            recv.token = address(0);
        } else {
            recv.token = request.token;
        }
        recv.amount = request.amount;
        if (!IBridge(_bridgeAddr).withdraws(recv.transferId)) {
            IBridge(_bridgeAddr).withdraw(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive an OriginalTokenVault withdrawal.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of OriginalTokenVault.
     */
    function receivePegWithdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);
        recv.transferId = keccak256(
            abi.encodePacked(
                request.receiver,
                request.token,
                request.amount,
                request.burnAccount,
                request.refChainId,
                request.refId
            )
        );
        recv.refid = request.refId;
        recv.receiver = request.receiver;
        if (INativeWrap(_bridgeAddr).nativeWrap() == request.token) {
            recv.token = address(0);
        } else {
            recv.token = request.token;
        }
        recv.amount = request.amount;
        if (!IOriginalTokenVault(_bridgeAddr).records(recv.transferId)) {
            IOriginalTokenVault(_bridgeAddr).withdraw(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive a PeggedTokenBridge mint.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of PeggedTokenBridge.
     */
    function receivePegMint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Mint memory request = PbPegged.decMint(_request);
        recv.transferId = keccak256(
            abi.encodePacked(
                request.account,
                request.token,
                request.amount,
                request.depositor,
                request.refChainId,
                request.refId
            )
        );
        recv.refid = request.refId;
        recv.receiver = request.account;
        recv.token = request.token;
        recv.amount = request.amount;
        if (!IPeggedTokenBridge(_bridgeAddr).records(recv.transferId)) {
            IPeggedTokenBridge(_bridgeAddr).mint(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive an OriginalTokenVaultV2 withdrawal.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A request must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of OriginalTokenVaultV2.
     */
    function receivePegV2Withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);
        if (IOriginalTokenVaultV2(_bridgeAddr).records(request.refId)) {
            recv.transferId = keccak256(
                abi.encodePacked(
                    request.receiver,
                    request.token,
                    request.amount,
                    request.burnAccount,
                    request.refChainId,
                    request.refId,
                    _bridgeAddr
                )
            );
        } else {
            recv.transferId = IOriginalTokenVaultV2(_bridgeAddr).withdraw(_request, _sigs, _signers, _powers);
        }
        recv.refid = request.refId;
        recv.receiver = request.receiver;
        if (INativeWrap(_bridgeAddr).nativeWrap() == request.token) {
            recv.token = address(0);
        } else {
            recv.token = request.token;
        }
        recv.amount = request.amount;
        return recv;
    }

    /**
     * @notice Receive a PeggedTokenBridgeV2 mint.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A request must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of PeggedTokenBridgeV2.
     */
    function receivePegV2Mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Mint memory request = PbPegged.decMint(_request);
        if (IPeggedTokenBridgeV2(_bridgeAddr).records(request.refId)) {
            recv.transferId = keccak256(
                abi.encodePacked(
                    request.account,
                    request.token,
                    request.amount,
                    request.depositor,
                    request.refChainId,
                    request.refId,
                    _bridgeAddr
                )
            );
        } else {
            recv.transferId = IPeggedTokenBridgeV2(_bridgeAddr).mint(_request, _sigs, _signers, _powers);
        }
        recv.refid = request.refId;
        recv.receiver = request.account;
        recv.token = request.token;
        recv.amount = request.amount;
        return recv;
    }

    function bridgeRefundType(BridgeSendType _bridgeSendType) internal pure returns (BridgeReceiveType) {
        if (_bridgeSendType == BridgeSendType.Liquidity) {
            return BridgeReceiveType.LqWithdraw;
        }
        if (_bridgeSendType == BridgeSendType.PegDeposit) {
            return BridgeReceiveType.PegWithdraw;
        }
        if (_bridgeSendType == BridgeSendType.PegBurn) {
            return BridgeReceiveType.PegMint;
        }
        if (_bridgeSendType == BridgeSendType.PegV2Deposit) {
            return BridgeReceiveType.PegV2Withdraw;
        }
        if (_bridgeSendType == BridgeSendType.PegV2Burn || _bridgeSendType == BridgeSendType.PegV2BurnFrom) {
            return BridgeReceiveType.PegV2Mint;
        }
        return BridgeReceiveType.Null;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: bridge.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbBridge {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct Relay {
        address sender; // tag: 1
        address receiver; // tag: 2
        address token; // tag: 3
        uint256 amount; // tag: 4
        uint64 srcChainId; // tag: 5
        uint64 dstChainId; // tag: 6
        bytes32 srcTransferId; // tag: 7
    } // end struct Relay

    function decRelay(bytes memory raw) internal pure returns (Relay memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.sender = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 5) {
                m.srcChainId = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.dstChainId = uint64(buf.decVarint());
            } else if (tag == 7) {
                m.srcTransferId = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Relay
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/pool.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbPool {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    } // end struct WithdrawMsg

    function decWithdrawMsg(bytes memory raw) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IWETH.sol";
import "../libraries/PbPool.sol";
import "../safeguard/Pauser.sol";
import "../safeguard/VolumeControl.sol";
import "../safeguard/DelayedTransfer.sol";
import "./Signers.sol";

/**
 * @title Liquidity pool functions for {Bridge}.
 */
contract Pool is Signers, ReentrancyGuard, Pauser, VolumeControl, DelayedTransfer {
    using SafeERC20 for IERC20;

    uint64 public addseq; // ensure unique LiquidityAdded event, start from 1
    mapping(address => uint256) public minAdd; // add _amount must > minAdd

    // map of successful withdraws, if true means already withdrew money or added to delayedTransfers
    mapping(bytes32 => bool) public withdraws;

    // erc20 wrap of gas token of this chain, eg. WETH, when relay ie. pay out,
    // if request.token equals this, will withdraw and send native token to receiver
    // note we don't check whether it's zero address. when this isn't set, and request.token
    // is all 0 address, guarantee fail
    address public nativeWrap;

    // liquidity events
    event LiquidityAdded(
        uint64 seqnum,
        address provider,
        address token,
        uint256 amount // how many tokens were added
    );
    event WithdrawDone(
        bytes32 withdrawId,
        uint64 seqnum,
        address receiver,
        address token,
        uint256 amount,
        bytes32 refid
    );
    event MinAddUpdated(address token, uint256 amount);

    /**
     * @notice Add liquidity to the pool-based bridge.
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _token The address of the token.
     * @param _amount The amount to add.
     */
    function addLiquidity(address _token, uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > minAdd[_token], "amount too small");
        addseq += 1;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit LiquidityAdded(addseq, msg.sender, _token, _amount);
    }

    /**
     * @notice Add native token liquidity to the pool-based bridge.
     * @param _amount The amount to add.
     */
    function addNativeLiquidity(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(msg.value == _amount, "Amount mismatch");
        require(nativeWrap != address(0), "Native wrap not set");
        require(_amount > minAdd[nativeWrap], "amount too small");
        addseq += 1;
        IWETH(nativeWrap).deposit{value: _amount}();
        emit LiquidityAdded(addseq, msg.sender, nativeWrap, _amount);
    }

    /**
     * @notice Withdraw funds from the bridge pool.
     * @param _wdmsg The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        // decode and check wdmsg
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        // len = 8 + 8 + 20 + 20 + 32 = 88
        bytes32 wdId = keccak256(
            abi.encodePacked(wdmsg.chainid, wdmsg.seqnum, wdmsg.receiver, wdmsg.token, wdmsg.amount)
        );
        require(withdraws[wdId] == false, "withdraw already succeeded");
        withdraws[wdId] = true;
        _updateVolume(wdmsg.token, wdmsg.amount);
        uint256 delayThreshold = delayThresholds[wdmsg.token];
        if (delayThreshold > 0 && wdmsg.amount > delayThreshold) {
            _addDelayedTransfer(wdId, wdmsg.receiver, wdmsg.token, wdmsg.amount);
        } else {
            _sendToken(wdmsg.receiver, wdmsg.token, wdmsg.amount);
        }
        emit WithdrawDone(wdId, wdmsg.seqnum, wdmsg.receiver, wdmsg.token, wdmsg.amount, wdmsg.refid);
    }

    function executeDelayedTransfer(bytes32 id) external whenNotPaused {
        delayedTransfer memory transfer = _executeDelayedTransfer(id);
        _sendToken(transfer.receiver, transfer.token, transfer.amount);
    }

    function setMinAdd(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minAdd[_tokens[i]] = _amounts[i];
            emit MinAddUpdated(_tokens[i], _amounts[i]);
        }
    }

    function _sendToken(
        address _receiver,
        address _token,
        uint256 _amount
    ) internal {
        if (_token == nativeWrap) {
            // withdraw then transfer native to receiver
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "failed to send native token");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    // set nativeWrap, for relay requests, if token == nativeWrap, will withdraw first then transfer native to receiver
    function setWrap(address _weth) external onlyOwner {
        nativeWrap = _weth;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/BridgeTransferLib.sol";
import "../safeguard/Pauser.sol";

/**
 * @title Example contract to send cBridge transfers. Supports the liquidity pool-based {Bridge}, the {OriginalTokenVault} for pegged
 * deposit and the {PeggedTokenBridge} for pegged burn. Includes handling of refunds for failed transfers.
 * @notice For the bad Bridge.send/PeggedTokenBridge.deposit of native token(eg.ETH) or wrapped native token(eg.WETH),
 * its refund asset depends on whether the nativeWrap of Bridge/PeggedTokenBridge is set or not AT THE MOMENT OF REFUNDING.
 * If the nativeWrap is set, the refund asset would always be native token (eg.ETH), even though the original sending asset
 * is wrapped native token. If the nativeWrap isn't set, the refund asset would always be wrapped native token.
 */
contract ContractAsSender is ReentrancyGuard, Pauser {
    using SafeERC20 for IERC20;

    mapping(BridgeTransferLib.BridgeSendType => address) public bridges;
    mapping(bytes32 => address) public records;
    address public nativeWrap;

    event Deposited(address depositor, address token, uint256 amount);
    event BridgeUpdated(BridgeTransferLib.BridgeSendType bridgeSendType, address bridgeAddr);

    /**
     * @notice Send a cross-chain transfer either via liquidity pool-based bridge or in form of mint/burn.
     * @param _receiver The address of the receiver.
     * @param _token The address of the token.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {BridgeSendType.Liquidity}.
     * @param _bridgeSendType The type of bridge used by this transfer. One of the {BridgeSendType} enum.
     */
    function transfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage, // slippage * 1M, eg. 0.5% -> 5000
        BridgeTransferLib.BridgeSendType _bridgeSendType
    ) external nonReentrant whenNotPaused onlyOwner returns (bytes32) {
        address _bridgeAddr = bridges[_bridgeSendType];
        require(_bridgeAddr != address(0), "unknown bridge type");
        bytes32 transferId = BridgeTransferLib.sendTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _bridgeSendType,
            _bridgeAddr
        );
        require(records[transferId] == address(0), "record exists");
        records[transferId] = msg.sender;
        return transferId;
    }

    /**
     * @notice Refund a failed cross-chain transfer.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeSendType The type of bridge used by this failed transfer. One of the {BridgeSendType} enum.
     */
    function refund(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        BridgeTransferLib.BridgeSendType _bridgeSendType
    ) external nonReentrant whenNotPaused onlyOwner returns (bytes32) {
        address _bridgeAddr = bridges[_bridgeSendType];
        require(_bridgeAddr != address(0), "unknown bridge type");
        BridgeTransferLib.ReceiveInfo memory refundInfo = BridgeTransferLib.receiveTransfer(
            _request,
            _sigs,
            _signers,
            _powers,
            BridgeTransferLib.bridgeRefundType(_bridgeSendType),
            _bridgeAddr
        );
        require(refundInfo.receiver == address(this), "invalid refund");
        address _receiver = records[refundInfo.refid];
        require(_receiver != address(0), "unknown transfer id or already refunded");
        delete records[refundInfo.refid];
        _sendToken(_receiver, refundInfo.token, refundInfo.amount);
        return refundInfo.transferId;
    }

    /**
     * @notice Send token to user. For native token and wrapped native token, this contract may not have enough _token to
     * send to _receiver. This may caused by others refund an original transfer that is sent from this contract via cBridge
     * contract right before you call refund function of this contract and then the nativeWrap of cBridge contract is
     * modified right after that the refund triggered by that guy completes.
     * As a consequence, native token and wrapped native token possessed by this contract are mixed. But don't worry,
     * the total sum of two tokens keeps correct. So in order to avoid deadlocking any token, we'd better have a
     * balance check before sending out native token or wrapped native token. If the balance of _token is not sufficient,
     * we change to sent the other token.
     */
    function _sendToken(
        address _receiver,
        address _token,
        uint256 _amount
    ) internal {
        if (_token == address(0)) {
            // refund asset is ETH
            if (address(this).balance >= _amount) {
                (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
                require(sent, "failed to send native token");
            } else {
                // in case of refund asset is WETH
                IERC20(_token).safeTransfer(_receiver, _amount);
            }
        } else if (_token == nativeWrap) {
            // refund asset is WETH
            if (IERC20(_token).balanceOf(address(this)) >= _amount) {
                IERC20(_token).safeTransfer(_receiver, _amount);
            } else {
                // in case of refund asset is ETH
                (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
                require(sent, "failed to send native token");
            }
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    // ----------------------Admin operation-----------------------

    /**
     * @notice Lock tokens.
     * @param _token The deposited token address.
     * @param _amount The amount to deposit.
     */
    function deposit(address _token, uint256 _amount) external nonReentrant whenNotPaused onlyOwner {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _token, _amount);
    }

    function setBridgeAddress(BridgeTransferLib.BridgeSendType _bridgeSendType, address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        bridges[_bridgeSendType] = _addr;
        emit BridgeUpdated(_bridgeSendType, _addr);
    }

    // set nativeWrap
    function setWrap(address _weth) external onlyOwner {
        nativeWrap = _weth;
    }

    // This is needed to receive ETH if a refund asset is ETH
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IWithdrawInbox.sol";
import "../safeguard/Pauser.sol";

/**
 * @title Example contract to provide liquidity to {Bridge}. Supports withdrawing liquidity via {WithdrawInbox}.
 */
contract ContractAsLP is ReentrancyGuard, Pauser {
    using SafeERC20 for IERC20;

    address public bridge;
    address public inbox;

    event Deposited(address depositor, address token, uint256 amount);

    constructor(address _bridge, address _inbox) {
        bridge = _bridge;
        inbox = _inbox;
    }

    /**
     * @notice Deposit tokens.
     * @param _token The deposited token address.
     * @param _amount The amount to deposit.
     */
    function deposit(address _token, uint256 _amount) external nonReentrant whenNotPaused onlyOwner {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _token, _amount);
    }

    /**
     * @notice Add liquidity to the pool-based bridge.
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _token The address of the token.
     * @param _amount The amount to add.
     */
    function addLiquidity(address _token, uint256 _amount) external whenNotPaused onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "insufficient balance");
        IERC20(_token).safeIncreaseAllowance(bridge, _amount);
        IPool(bridge).addLiquidity(_token, _amount);
    }

    /**
     * @notice Withdraw liquidity from the pool-based bridge.
     * NOTE: Each of your withdrawal request should have different _wdSeq.
     * NOTE: Tokens to withdraw within one withdrawal request should have the same symbol.
     * @param _wdSeq The unique sequence number to identify this withdrawal request.
     * @param _receiver The receiver address on _toChain.
     * @param _toChain The chain Id to receive the withdrawn tokens.
     * @param _fromChains The chain Ids to withdraw tokens.
     * @param _tokens The token to withdraw on each fromChain.
     * @param _ratios The withdrawal ratios of each token.
     * @param _slippages The max slippages of each token for cross-chain withdraw.
     */
    function withdraw(
        uint64 _wdSeq,
        address _receiver,
        uint64 _toChain,
        uint64[] calldata _fromChains,
        address[] calldata _tokens,
        uint32[] calldata _ratios,
        uint32[] calldata _slippages
    ) external whenNotPaused onlyOwner {
        IWithdrawInbox(inbox).withdraw(_wdSeq, _receiver, _toChain, _fromChains, _tokens, _ratios, _slippages);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPool {
    function addLiquidity(address _token, uint256 _amount) external;

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IWithdrawInbox {
    function withdraw(
        uint64 _wdSeq,
        address _receiver,
        uint64 _toChain,
        uint64[] calldata _fromChains,
        address[] calldata _tokens,
        uint32[] calldata _ratios,
        uint32[] calldata _slippages
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/PbBridge.sol";
import "./Pool.sol";

/**
 * @title The liquidity-pool based bridge.
 */
contract Bridge is Pool {
    using SafeERC20 for IERC20;

    // liquidity events
    event Send(
        bytes32 transferId,
        address sender,
        address receiver,
        address token,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    );
    event Relay(
        bytes32 transferId,
        address sender,
        address receiver,
        address token,
        uint256 amount,
        uint64 srcChainId,
        bytes32 srcTransferId
    );
    // gov events
    event MinSendUpdated(address token, uint256 amount);
    event MaxSendUpdated(address token, uint256 amount);

    mapping(bytes32 => bool) public transfers;
    mapping(address => uint256) public minSend; // send _amount must > minSend
    mapping(address => uint256) public maxSend;

    // min allowed max slippage uint32 value is slippage * 1M, eg. 0.5% -> 5000
    uint32 public minimalMaxSlippage;

    /**
     * @notice Send a cross-chain transfer via the liquidity pool-based bridge.
     * NOTE: This function DOES NOT SUPPORT fee-on-transfer / rebasing tokens.
     * @param _receiver The address of the receiver.
     * @param _token The address of the token.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     */
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage // slippage * 1M, eg. 0.5% -> 5000
    ) external nonReentrant whenNotPaused {
        bytes32 transferId = _send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Send(transferId, msg.sender, _receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
    }

    /**
     * @notice Send a cross-chain transfer via the liquidity pool-based bridge using the native token.
     * @param _receiver The address of the receiver.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A unique number. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     */
    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable nonReentrant whenNotPaused {
        require(msg.value == _amount, "Amount mismatch");
        require(nativeWrap != address(0), "Native wrap not set");
        bytes32 transferId = _send(_receiver, nativeWrap, _amount, _dstChainId, _nonce, _maxSlippage);
        IWETH(nativeWrap).deposit{value: _amount}();
        emit Send(transferId, msg.sender, _receiver, nativeWrap, _amount, _dstChainId, _nonce, _maxSlippage);
    }

    function _send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) private returns (bytes32) {
        require(_amount > minSend[_token], "amount too small");
        require(maxSend[_token] == 0 || _amount <= maxSend[_token], "amount too large");
        require(_maxSlippage > minimalMaxSlippage, "max slippage too small");
        bytes32 transferId = keccak256(
            // uint64(block.chainid) for consistency as entire system uses uint64 for chain id
            // len = 20 + 20 + 20 + 32 + 8 + 8 + 8 = 116
            abi.encodePacked(msg.sender, _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
        );
        require(transfers[transferId] == false, "transfer exists");
        transfers[transferId] = true;
        return transferId;
    }

    /**
     * @notice Relay a cross-chain transfer sent from a liquidity pool-based bridge on another chain.
     * @param _relayRequest The serialized Relay protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Relay"));
        verifySigs(abi.encodePacked(domain, _relayRequest), _sigs, _signers, _powers);
        PbBridge.Relay memory request = PbBridge.decRelay(_relayRequest);
        // len = 20 + 20 + 20 + 32 + 8 + 8 + 32 = 140
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.sender,
                request.receiver,
                request.token,
                request.amount,
                request.srcChainId,
                request.dstChainId,
                request.srcTransferId
            )
        );
        require(transfers[transferId] == false, "transfer exists");
        transfers[transferId] = true;
        _updateVolume(request.token, request.amount);
        uint256 delayThreshold = delayThresholds[request.token];
        if (delayThreshold > 0 && request.amount > delayThreshold) {
            _addDelayedTransfer(transferId, request.receiver, request.token, request.amount);
        } else {
            _sendToken(request.receiver, request.token, request.amount);
        }

        emit Relay(
            transferId,
            request.sender,
            request.receiver,
            request.token,
            request.amount,
            request.srcChainId,
            request.srcTransferId
        );
    }

    function setMinSend(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minSend[_tokens[i]] = _amounts[i];
            emit MinSendUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMaxSend(address[] calldata _tokens, uint256[] calldata _amounts) external onlyGovernor {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            maxSend[_tokens[i]] = _amounts[i];
            emit MaxSendUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMinimalMaxSlippage(uint32 _minimalMaxSlippage) external onlyGovernor {
        minimalMaxSlippage = _minimalMaxSlippage;
    }

    // This is needed to receive ETH when calling `IWETH.withdraw`
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/farming.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbFarming {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct FarmingRewards {
        address recipient; // tag: 1
        address[] tokenAddresses; // tag: 2
        uint256[] cumulativeRewardAmounts; // tag: 3
    } // end struct FarmingRewards

    function decFarmingRewards(bytes memory raw) internal pure returns (FarmingRewards memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256[] memory cnts = buf.cntTags(3);
        m.tokenAddresses = new address[](cnts[2]);
        cnts[2] = 0; // reset counter for later use
        m.cumulativeRewardAmounts = new uint256[](cnts[3]);
        cnts[3] = 0; // reset counter for later use

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.recipient = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.tokenAddresses[cnts[2]] = Pb._address(buf.decBytes());
                cnts[2]++;
            } else if (tag == 3) {
                m.cumulativeRewardAmounts[cnts[3]] = Pb._uint256(buf.decBytes());
                cnts[3]++;
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder FarmingRewards
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ISigsVerifier.sol";
import "../libraries/PbFarming.sol";
import "../safeguard/Pauser.sol";

/**
 * @title A contract to hold and distribute farming rewards.
 */
contract FarmingRewards is Pauser {
    using SafeERC20 for IERC20;

    ISigsVerifier public immutable sigsVerifier;

    // recipient => tokenAddress => amount
    mapping(address => mapping(address => uint256)) public claimedRewardAmounts;

    event FarmingRewardClaimed(address indexed recipient, address indexed token, uint256 reward);
    event FarmingRewardContributed(address indexed contributor, address indexed token, uint256 contribution);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Claim rewards
     * @dev Here we use cumulative reward to make claim process idempotent
     * @param _rewardsRequest rewards request bytes coded in protobuf
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function claimRewards(
        bytes calldata _rewardsRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "FarmingRewards"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _rewardsRequest), _sigs, _signers, _powers);
        PbFarming.FarmingRewards memory rewards = PbFarming.decFarmingRewards(_rewardsRequest);
        bool hasNewReward;
        for (uint256 i = 0; i < rewards.tokenAddresses.length; i++) {
            address token = rewards.tokenAddresses[i];
            uint256 cumulativeRewardAmount = rewards.cumulativeRewardAmounts[i];
            uint256 newReward = cumulativeRewardAmount - claimedRewardAmounts[rewards.recipient][token];
            if (newReward > 0) {
                hasNewReward = true;
                claimedRewardAmounts[rewards.recipient][token] = cumulativeRewardAmount;
                IERC20(token).safeTransfer(rewards.recipient, newReward);
                emit FarmingRewardClaimed(rewards.recipient, token, newReward);
            }
        }
        require(hasNewReward, "No new reward");
    }

    /**
     * @notice Contribute reward tokens to the reward pool
     * @param _token the address of the token to contribute
     * @param _amount the amount of the token to contribute
     */
    function contributeToRewardPool(address _token, uint256 _amount) external whenNotPaused {
        address contributor = msg.sender;
        IERC20(_token).safeTransferFrom(contributor, address(this), _amount);

        emit FarmingRewardContributed(contributor, _token, _amount);
    }

    /**
     * @notice Owner drains tokens when the contract is paused
     * @dev emergency use only
     * @param _token the address of the token to drain
     * @param _amount drained token amount
     */
    function drainToken(address _token, uint256 _amount) external whenPaused onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PegNFT is ERC721URIStorage {
    address public immutable nftBridge;

    constructor(
        string memory name_,
        string memory symbol_,
        address _nftBridge
    ) ERC721(name_, symbol_) {
        nftBridge = _nftBridge;
    }

    modifier onlyNftBridge() {
        require(msg.sender == nftBridge, "caller is not bridge");
        _;
    }

    function bridgeMint(
        address to,
        uint256 id,
        string memory uri
    ) external onlyNftBridge {
        _mint(to, id);
        _setTokenURI(id, uri);
    }

    function burn(uint256 id) external onlyNftBridge {
        _burn(id);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../../safeguard/Ownable.sol";

contract OrigNFT is ERC721URIStorage, Ownable {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(
        address to,
        uint256 id,
        string memory uri
    ) external onlyOwner {
        _mint(to, id);
        _setTokenURI(id, uri);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../../safeguard/Pauser.sol";

interface INFTBridge {
    function sendMsg(
        uint64 _dstChid,
        address _sender,
        address _receiver,
        uint256 _id,
        string calldata _uri
    ) external payable;

    function sendMsg(
        uint64 _dstChid,
        address _sender,
        bytes calldata _receiver,
        uint256 _id,
        string calldata _uri
    ) external payable;

    function totalFee(
        uint64 _dstChid,
        address _nft,
        uint256 _id
    ) external view returns (uint256);
}

// Multi-Chain Native NFT, same contract on all chains. User interacts with this directly.
contract MCNNFT is ERC721URIStorage, Pauser {
    event NFTBridgeUpdated(address);
    address public nftBridge;

    constructor(
        string memory name_,
        string memory symbol_,
        address _nftBridge
    ) ERC721(name_, symbol_) {
        nftBridge = _nftBridge;
    }

    modifier onlyNftBridge() {
        require(msg.sender == nftBridge, "caller is not bridge");
        _;
    }

    function bridgeMint(
        address to,
        uint256 id,
        string memory uri
    ) external onlyNftBridge {
        _mint(to, id);
        _setTokenURI(id, uri);
    }

    // calls nft bridge to get total fee for crossChain msg.Value
    function totalFee(uint64 _dstChid, uint256 _id) external view returns (uint256) {
        return INFTBridge(nftBridge).totalFee(_dstChid, address(this), _id);
    }

    // called by user, burn token on this chain and mint same id/uri on dest chain
    function crossChain(
        uint64 _dstChid,
        uint256 _id,
        address _receiver
    ) external payable whenNotPaused {
        require(msg.sender == ownerOf(_id), "not token owner");
        string memory _uri = tokenURI(_id);
        _burn(_id);
        INFTBridge(nftBridge).sendMsg{value: msg.value}(_dstChid, msg.sender, _receiver, _id, _uri);
    }

    // support chains using bytes for address
    function crossChain(
        uint64 _dstChid,
        uint256 _id,
        bytes calldata _receiver
    ) external payable whenNotPaused {
        require(msg.sender == ownerOf(_id), "not token owner");
        string memory _uri = tokenURI(_id);
        _burn(_id);
        INFTBridge(nftBridge).sendMsg{value: msg.value}(_dstChid, msg.sender, _receiver, _id, _uri);
    }

    // ===== only Owner
    function mint(
        address to,
        uint256 id,
        string memory uri
    ) external onlyOwner {
        _mint(to, id);
        _setTokenURI(id, uri);
    }

    function setNFTBridge(address _newBridge) public onlyOwner {
        nftBridge = _newBridge;
        emit NFTBridgeUpdated(_newBridge);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title A mintable {ERC20} token.
 */
contract MintableERC20 is ERC20Burnable, Ownable {
    uint8 private _decimals;

    /**
     * @dev Constructor that gives msg.sender an initial supply of tokens.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Faucet is Ownable {
    using SafeERC20 for IERC20;

    uint256 public minDripBlkInterval;
    mapping(address => uint256) public lastDripBlk;

    /**
     * @dev Sends 0.01% of each token to the caller.
     * @param tokens The tokens to drip.
     */
    function drip(address[] calldata tokens) public {
        require(block.number - lastDripBlk[msg.sender] >= minDripBlkInterval, "too frequent");
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "Faucet is empty");
            token.safeTransfer(msg.sender, balance / 10000); // 0.01%
        }
        lastDripBlk[msg.sender] = block.number;
    }

    /**
     * @dev Owner set minDripBlkInterval
     *
     * @param _interval minDripBlkInterval value
     */
    function setMinDripBlkInterval(uint256 _interval) external onlyOwner {
        minDripBlkInterval = _interval;
    }

    /**
     * @dev Owner drains one type of tokens
     *
     * @param _asset drained asset address
     * @param _amount drained asset amount
     */
    function drainToken(address _asset, uint256 _amount) external onlyOwner {
        IERC20(_asset).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../MintSwapCanonicalToken.sol";

/**
 * @title MintSwapCanonicalToke with ERC20Permit
 */
contract MintSwapCanonicalTokenPermit is ERC20Permit, MintSwapCanonicalToken {
    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) MintSwapCanonicalToken(name_, symbol_, decimals_) ERC20Permit(name_) {
        _decimals = decimals_;
    }

    function decimals() public view override(ERC20, MultiBridgeToken) returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MultiBridgeToken.sol";

/**
 * @title Canonical token that supports multi-bridge minter and multi-token swap
 */
contract MintSwapCanonicalToken is MultiBridgeToken {
    using SafeERC20 for IERC20;

    // bridge token address -> minted amount and cap for each bridge
    mapping(address => Supply) public swapSupplies;

    event TokenSwapCapUpdated(address token, uint256 cap);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) MultiBridgeToken(name_, symbol_, decimals_) {}

    /**
     * @notice msg.sender has bridge token and wants to get canonical token.
     * @param _bridgeToken The intermediary token address for a particular bridge.
     * @param _amount The amount.
     */
    function swapBridgeForCanonical(address _bridgeToken, uint256 _amount) external returns (uint256) {
        Supply storage supply = swapSupplies[_bridgeToken];
        require(supply.cap > 0, "invalid bridge token");
        require(supply.total + _amount <= supply.cap, "exceed swap cap");

        supply.total += _amount;
        _mint(msg.sender, _amount);

        // move bridge token from msg.sender to canonical token _amount
        IERC20(_bridgeToken).safeTransferFrom(msg.sender, address(this), _amount);
        return _amount;
    }

    /**
     * @notice msg.sender has canonical token and wants to get bridge token (eg. for cross chain burn).
     * @param _bridgeToken The intermediary token address for a particular bridge.
     * @param _amount The amount.
     */
    function swapCanonicalForBridge(address _bridgeToken, uint256 _amount) external returns (uint256) {
        Supply storage supply = swapSupplies[_bridgeToken];
        require(supply.cap > 0, "invalid bridge token");

        supply.total -= _amount;
        _burn(msg.sender, _amount);

        IERC20(_bridgeToken).safeTransfer(msg.sender, _amount);
        return _amount;
    }

    /**
     * @dev Update existing bridge token swap cap or add a new bridge token with swap cap.
     * Setting cap to 0 will disable the bridge token.
     * @param _bridgeToken The intermediary token address for a particular bridge.
     * @param _swapCap The new swap cap.
     */
    function setBridgeTokenSwapCap(address _bridgeToken, uint256 _swapCap) external onlyOwner {
        swapSupplies[_bridgeToken].cap = _swapCap;
        emit TokenSwapCapUpdated(_bridgeToken, _swapCap);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "./MintSwapCanonicalToken.sol";

/**
 * @title Upgradable canonical token that supports multi-bridge minter and multi-token swap
 */

// First deploy this contract, constructor will set name, symbol and owner in contract state, but these are NOT used.
// decimal isn't saved in state because it's immutable in MultiBridgeToken and will be set in the code binary.
// Then deploy proxy contract with this contract as impl, proxy constructor will delegatecall this.init which sets name, symbol and owner in proxy contract state.
// why we need to shadow name and symbol: ERC20 only allows set them in constructor which isn't available after deploy so proxy state can't be updated.
contract MintSwapCanonicalTokenUpgradable is MintSwapCanonicalToken {
    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) MintSwapCanonicalToken(name_, symbol_, decimals_) {}

    // only to be called by Proxy via delegatecall and will modify Proxy state
    // this func has no access control because initOwner only allows delegateCall
    function init(string memory name_, string memory symbol_) external {
        initOwner(); // this will fail if Ownable._owner is already set
        _name = name_;
        _symbol = symbol_;
    }

    // override name, symbol and owner getters
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Freezable.sol";
import "../MintSwapCanonicalTokenUpgradable.sol";

/**
 * @title Upgradable canonical token that supports multi-bridge minter and multi-token swap. Support freezable erc20 transfer
 */
contract MintSwapCanonicalTokenUpgradableFreezable is MintSwapCanonicalTokenUpgradable, Freezable {
    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) MintSwapCanonicalTokenUpgradable(name_, symbol_, decimals_) {}

    // freezable related
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!isFrozen(from), "ERC20Freezable: from account is frozen");
        require(!isFrozen(to), "ERC20Freezable: to account is frozen");
    }

    function freeze(address _account) public onlyOwner {
        freezes[_account] = true;
        emit Frozen(_account);
    }

    function unfreeze(address _account) public onlyOwner {
        freezes[_account] = false;
        emit Unfrozen(_account);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

abstract contract Freezable {
    event Frozen(address account);
    event Unfrozen(address account);
    mapping(address => bool) internal freezes;

    function isFrozen(address _account) public view virtual returns (bool) {
        return freezes[_account];
    }

    modifier whenAccountNotFrozen(address _account) {
        require(!isFrozen(_account), "Freezable: frozen");
        _;
    }

    modifier whenAccountFrozen(address _account) {
        require(isFrozen(_account), "Freezable: not frozen");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../safeguard/Ownable.sol";

/**
 * @title A contract to initiate withdrawal requests for contracts tha provide liquidity to {Bridge}.
 */
contract WithdrawInbox is Ownable {
    // min allowed max slippage uint32 value is slippage * 1M, eg. 0.5% -> 5000
    uint32 public minimalMaxSlippage;
    // the period of time during which a withdrawal request is intended to be valid
    uint256 public validityPeriod;

    // contract LP withdrawal request
    event WithdrawalRequest(
        uint64 seqNum,
        address sender,
        address receiver,
        uint64 toChain,
        uint64[] fromChains,
        address[] tokens,
        uint32[] ratios,
        uint32[] slippages,
        uint256 deadline
    );

    constructor() {
        // default validityPeriod is 2 hours
        validityPeriod = 7200;
    }

    /**
     * @notice Withdraw liquidity from the pool-based bridge.
     * NOTE: Each of your withdrawal request should have different _wdSeq.
     * NOTE: Tokens to withdraw within one withdrawal request should have the same symbol.
     * @param _wdSeq The unique sequence number to identify this withdrawal request.
     * @param _receiver The receiver address on _toChain.
     * @param _toChain The chain Id to receive the withdrawn tokens.
     * @param _fromChains The chain Ids to withdraw tokens.
     * @param _tokens The token to withdraw on each fromChain.
     * @param _ratios The withdrawal ratios of each token.
     * @param _slippages The max slippages of each token for cross-chain withdraw.
     */
    function withdraw(
        uint64 _wdSeq,
        address _receiver,
        uint64 _toChain,
        uint64[] calldata _fromChains,
        address[] calldata _tokens,
        uint32[] calldata _ratios,
        uint32[] calldata _slippages
    ) external {
        require(_fromChains.length > 0, "empty withdrawal request");
        require(
            _tokens.length == _fromChains.length &&
                _ratios.length == _fromChains.length &&
                _slippages.length == _fromChains.length,
            "length mismatch"
        );
        for (uint256 i = 0; i < _ratios.length; i++) {
            require(_ratios[i] > 0 && _ratios[i] <= 1e8, "invalid ratio");
            require(_slippages[i] >= minimalMaxSlippage, "slippage too small");
        }
        uint256 _deadline = block.timestamp + validityPeriod;
        emit WithdrawalRequest(
            _wdSeq,
            msg.sender,
            _receiver,
            _toChain,
            _fromChains,
            _tokens,
            _ratios,
            _slippages,
            _deadline
        );
    }

    // ------------------------Admin operations--------------------------

    function setMinimalMaxSlippage(uint32 _minimalMaxSlippage) external onlyOwner {
        minimalMaxSlippage = _minimalMaxSlippage;
    }

    function setValidityPeriod(uint256 _validityPeriod) external onlyOwner {
        validityPeriod = _validityPeriod;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../framework/MessageSenderApp.sol";
import "../framework/MessageReceiverApp.sol";

/** @title Sample app to test message passing flow, not for production use */
contract BatchTransfer is MessageSenderApp, MessageReceiverApp {
    using SafeERC20 for IERC20;

    struct TransferRequest {
        uint64 nonce;
        address[] accounts;
        uint256[] amounts;
        address sender;
    }

    enum TransferStatus {
        Null,
        Success,
        Fail
    }

    struct TransferReceipt {
        uint64 nonce;
        TransferStatus status;
    }

    constructor(address _messageBus) {
        messageBus = _messageBus;
    }

    // ============== functions and states on source chain ==============

    uint64 nonce;

    struct BatchTransferStatus {
        bytes32 h; // hash(receiver, dstChainId)
        TransferStatus status;
    }
    mapping(uint64 => BatchTransferStatus) public status; // nonce -> BatchTransferStatus

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not EOA");
        _;
    }

    function batchTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external payable onlyEOA {
        uint256 totalAmt;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmt += _amounts[i];
        }
        // commented out the slippage check below to trigger failure case for handleFailedMessageWithTransfer testing
        // uint256 minRecv = _amount - (_amount * _maxSlippage) / 1e6;
        // require(minRecv > totalAmt, "invalid maxSlippage");
        nonce += 1;
        status[nonce] = BatchTransferStatus({
            h: keccak256(abi.encodePacked(_receiver, _dstChainId)),
            status: TransferStatus.Null
        });
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        bytes memory message = abi.encode(
            TransferRequest({nonce: nonce, accounts: _accounts, amounts: _amounts, sender: msg.sender})
        );
        // MsgSenderApp util function
        sendMessageWithTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            nonce,
            _maxSlippage,
            message,
            _bridgeSendType,
            msg.value
        );
    }

    // called on source chain for handling of bridge failures (bad liquidity, bad slippage, etc...)
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        TransferRequest memory transfer = abi.decode((_message), (TransferRequest));
        IERC20(_token).safeTransfer(transfer.sender, _amount);
        return ExecutionStatus.Success;
    }

    // ============== functions on destination chain ==============

    // handler function required by MsgReceiverApp
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        TransferReceipt memory receipt = abi.decode((_message), (TransferReceipt));
        require(status[receipt.nonce].h == keccak256(abi.encodePacked(_sender, _srcChainId)), "invalid message");
        status[receipt.nonce].status = receipt.status;
        return ExecutionStatus.Success;
    }

    // handler function required by MsgReceiverApp
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        TransferRequest memory transfer = abi.decode((_message), (TransferRequest));
        uint256 totalAmt;
        for (uint256 i = 0; i < transfer.accounts.length; i++) {
            IERC20(_token).safeTransfer(transfer.accounts[i], transfer.amounts[i]);
            totalAmt += transfer.amounts[i];
        }
        uint256 remainder = _amount - totalAmt;
        if (_amount > totalAmt) {
            // transfer the remainder of the money to sender as fee for executing this transfer
            IERC20(_token).safeTransfer(transfer.sender, remainder);
        }
        bytes memory message = abi.encode(TransferReceipt({nonce: transfer.nonce, status: TransferStatus.Success}));
        // MsgSenderApp util function
        sendMessage(_sender, _srcChainId, message, msg.value);
        return ExecutionStatus.Success;
    }

    // handler function required by MsgReceiverApp
    // called only if handleMessageWithTransfer above was reverted
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        TransferRequest memory transfer = abi.decode((_message), (TransferRequest));
        IERC20(_token).safeTransfer(transfer.sender, _amount);
        bytes memory message = abi.encode(TransferReceipt({nonce: transfer.nonce, status: TransferStatus.Fail}));
        sendMessage(_sender, _srcChainId, message, msg.value);
        return ExecutionStatus.Success;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes as dt} from "./DataTypes.sol";
import "./Staking.sol";

/**
 * @title Governance module for Staking contract
 */
contract Govern {
    using SafeERC20 for IERC20;

    Staking public immutable staking;
    IERC20 public immutable celerToken;

    enum ProposalStatus {
        Uninitiated,
        Voting,
        Closed
    }

    enum VoteOption {
        Null,
        Yes,
        Abstain,
        No
    }

    struct ParamProposal {
        address proposer;
        uint256 deposit;
        uint256 voteDeadline;
        dt.ParamName name;
        uint256 newValue;
        ProposalStatus status;
        mapping(address => VoteOption) votes;
    }

    mapping(uint256 => ParamProposal) public paramProposals;
    uint256 public nextParamProposalId;

    uint256 public forfeiture;
    address public immutable collector;

    event CreateParamProposal(
        uint256 proposalId,
        address proposer,
        uint256 deposit,
        uint256 voteDeadline,
        dt.ParamName name,
        uint256 newValue
    );
    event VoteParam(uint256 proposalId, address voter, VoteOption vote);
    event ConfirmParamProposal(uint256 proposalId, bool passed, dt.ParamName name, uint256 newValue);

    constructor(
        Staking _staking,
        address _celerTokenAddress,
        address _collector
    ) {
        staking = _staking;
        celerToken = IERC20(_celerTokenAddress);
        collector = _collector;
    }

    /**
     * @notice Get the vote type of a voter on a parameter proposal
     * @param _proposalId the proposal id
     * @param _voter the voter address
     * @return the vote type of the given voter on the given parameter proposal
     */
    function getParamProposalVote(uint256 _proposalId, address _voter) public view returns (VoteOption) {
        return paramProposals[_proposalId].votes[_voter];
    }

    /**
     * @notice Create a parameter proposal
     * @param _name the key of this parameter
     * @param _value the new proposed value of this parameter
     */
    function createParamProposal(dt.ParamName _name, uint256 _value) external {
        ParamProposal storage p = paramProposals[nextParamProposalId];
        nextParamProposalId = nextParamProposalId + 1;
        address msgSender = msg.sender;
        uint256 deposit = staking.getParamValue(dt.ParamName.ProposalDeposit);

        p.proposer = msgSender;
        p.deposit = deposit;
        p.voteDeadline = block.number + staking.getParamValue(dt.ParamName.VotingPeriod);
        p.name = _name;
        p.newValue = _value;
        p.status = ProposalStatus.Voting;

        celerToken.safeTransferFrom(msgSender, address(this), deposit);

        emit CreateParamProposal(nextParamProposalId - 1, msgSender, deposit, p.voteDeadline, _name, _value);
    }

    /**
     * @notice Vote for a parameter proposal with a specific type of vote
     * @param _proposalId the id of the parameter proposal
     * @param _vote the type of vote
     */
    function voteParam(uint256 _proposalId, VoteOption _vote) external {
        address valAddr = msg.sender;
        require(staking.getValidatorStatus(valAddr) == dt.ValidatorStatus.Bonded, "Voter is not a bonded validator");
        ParamProposal storage p = paramProposals[_proposalId];
        require(p.status == ProposalStatus.Voting, "Invalid proposal status");
        require(block.number < p.voteDeadline, "Vote deadline passed");
        require(p.votes[valAddr] == VoteOption.Null, "Voter has voted");
        require(_vote != VoteOption.Null, "Invalid vote");

        p.votes[valAddr] = _vote;

        emit VoteParam(_proposalId, valAddr, _vote);
    }

    /**
     * @notice Confirm a parameter proposal
     * @param _proposalId the id of the parameter proposal
     */
    function confirmParamProposal(uint256 _proposalId) external {
        uint256 yesVotes;
        uint256 bondedTokens;
        dt.ValidatorTokens[] memory validators = staking.getBondedValidatorsTokens();
        for (uint32 i = 0; i < validators.length; i++) {
            if (getParamProposalVote(_proposalId, validators[i].valAddr) == VoteOption.Yes) {
                yesVotes += validators[i].tokens;
            }
            bondedTokens += validators[i].tokens;
        }
        bool passed = (yesVotes >= (bondedTokens * 2) / 3 + 1);

        ParamProposal storage p = paramProposals[_proposalId];
        require(p.status == ProposalStatus.Voting, "Invalid proposal status");
        require(block.number >= p.voteDeadline, "Vote deadline not reached");

        p.status = ProposalStatus.Closed;
        if (passed) {
            staking.setParamValue(p.name, p.newValue);
            celerToken.safeTransfer(p.proposer, p.deposit);
        } else {
            forfeiture += p.deposit;
        }

        emit ConfirmParamProposal(_proposalId, passed, p.name, p.newValue);
    }

    function collectForfeiture() external {
        require(forfeiture > 0, "Nothing to collect");
        celerToken.safeTransfer(collector, forfeiture);
        forfeiture = 0;
    }
}