pragma solidity 0.8.12;

import "../interfaces/IMaster.sol";

/**
 * @title CreditManagement
 * @dev CreditManagement library
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
library CreditManagement {
    error NonExistentCredit();
    error InvalidNewCredits();
    error InvalidOldCredit();
    error NotEnoughCredit();

    function add(
        IMaster.Credit storage _self,
        uint256 _amount,
        bool _locked
    ) external {
        _self.amount += _amount;
        if (_locked) _self.locked += _amount;
    }

    function remove(
        IMaster.Credit storage _self,
        uint256 _amount,
        bool _consumeLocked
    ) external {
        uint256 _currentCreditAmount = _self.amount; // gas savings
        if (
            _amount > _currentCreditAmount ||
            (!_consumeLocked && _currentCreditAmount - _self.locked < _amount)
        ) revert NotEnoughCredit();
        _self.amount -= _amount;
        uint256 _lockedCredit = _self.locked; // gas savingd
        if (_consumeLocked && _lockedCredit > 0)
            _self.locked -= _lockedCredit > _amount ? _amount : _lockedCredit;
    }
}

pragma solidity >=0.8.10;

/**
 * @title IMaster
 * @dev IMaster contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IMaster {
    struct Worker {
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingBlock;
        uint256 unbonding;
        uint256 unbondingBlock;
    }

    struct WorkerInfo {
        address addrezz;
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingBlock;
        uint256 unbonding;
        uint256 unbondingBlock;
    }

    struct Credit {
        uint256 amount;
        uint256 locked;
    }

    struct Job {
        address addrezz;
        address owner;
        string specification;
        Credit credit;
    }

    struct JobInfo {
        uint256 id;
        address addrezz;
        address owner;
        string specification;
        Credit credit;
    }

    struct EnumerableJobSet {
        mapping(uint256 => Job) byId;
        mapping(address => uint256) idForAddress;
        mapping(address => uint256[]) byOwner;
        uint256[] keys;
        uint256 ids;
    }

    struct EnumerableWorkerSet {
        mapping(address => Worker) byAddress;
        address[] keys;
    }

    function bond(uint256 _amount) external;

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function consolidateBond() external;

    function cancelBonding() external;

    function unbond(uint256 _amount) external;

    function consolidateUnbonding() external;

    function cancelUnbonding() external;

    function slash(address _worker, uint256 _amount) external;

    function disallow(address _worker) external;

    function allowLiquidity(address _liquidity, address _weightCalculator)
        external;

    function disallowLiquidity(address _liquidity) external;

    function allowJobCreator(address _creator) external;

    function disallowJobCreator(address _creator) external;

    function addJob(
        address _address,
        address _owner,
        string calldata _specification
    ) external;

    function upgradeJob(
        uint256 _id,
        address _newJob,
        string calldata _newSpecification
    ) external;

    function removeJob(uint256 _id) external;

    function addCredit(uint256 _id, uint256 _amount) external;

    function addCreditWithPermit(
        uint256 _id,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function addLiquidityCredit(
        uint256 _id,
        address _liquidity,
        uint256 _amount
    ) external;

    function removeCredit(uint256 _id, uint256 _amount) external;

    function workable(address _worker, uint256 _jobId)
        external
        view
        returns (bool, bytes memory);

    function work(uint256 _id, bytes calldata _data) external;

    function setFee(uint16 _fee) external;

    function setLiquidityTokenPremium(uint16 _fee) external;

    function setAssignedTurnBlocks(uint32 _assignedTurnBlocks) external;

    function setCompetitiveTurnBlocks(uint32 _competitiveTurnBlocks) external;

    function setJolt(address _jolt) external;

    function setFeeReceiver(address _feeReceiver) external;

    function setWorkEvaluator(address _workEvaluator) external;

    function setBondingBlocks(uint32 _bondingBlocks) external;

    function setUnbondingBlocks(uint32 _unbondingBlocks) external;

    function totalBonded() external view returns (uint256);

    function epochCheckpoint() external view returns (uint256);

    function bondingBlocks() external view returns (uint32);

    function unbondingBlocks() external view returns (uint32);

    function fee() external view returns (uint16);

    function liquidityTokenPremium() external view returns (uint16);

    function assignedTurnBlocks() external view returns (uint32);

    function competitiveTurnBlocks() external view returns (uint32);

    function jolt() external view returns (address);

    function feeReceiver() external view returns (address);

    function bonded(address _address) external view returns (uint256);

    function earned(address _address) external view returns (uint256);

    function disallowed(address _address) external view returns (bool);

    function liquidityWeightCalculator(address _liquidityToken)
        external
        view
        returns (address);

    function jobsCreator(address _jobsCreator) external view returns (bool);

    function workersAmount() external view returns (uint256);

    function worker(address _address) external view returns (WorkerInfo memory);

    function workersSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (WorkerInfo[] memory);

    function jobsAmount() external view returns (uint256);

    function job(uint256 _id) external view returns (JobInfo memory);

    function credit(uint256 _id) external view returns (Credit memory);

    function jobsSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (JobInfo[] memory);

    function jobsOfOwner(address _owner)
        external
        view
        returns (JobInfo[] memory);
}