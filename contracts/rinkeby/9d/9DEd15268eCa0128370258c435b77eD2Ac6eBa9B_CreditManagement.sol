pragma solidity ^0.8.10;

import "../interfaces/IJobsRegistry.sol";

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

    function getOrAdd(IJobsRegistry.Credit[] storage _credits, address _token)
        private
        returns (IJobsRegistry.Credit storage)
    {
        for (uint256 _i = 0; _i < _credits.length; _i++) {
            IJobsRegistry.Credit storage _credit = _credits[_i];
            if (_credit.token == _token) return _credit;
        }
        IJobsRegistry.Credit storage _newCredit = _credits.push();
        _newCredit.token = _token;
        return _newCredit;
    }

    function get(IJobsRegistry.Credit[] storage _self, address _token)
        public
        view
        returns (IJobsRegistry.Credit storage, uint256 _index)
    {
        for (uint256 _i = 0; _i < _self.length; _i++) {
            IJobsRegistry.Credit storage _credit = _self[_i];
            if (_credit.token == _token) return (_credit, _i);
        }
        revert NonExistentCredit();
    }

    function add(
        IJobsRegistry.Credit[] storage _self,
        address _token,
        uint256 _amount,
        bool _locked
    ) external {
        IJobsRegistry.Credit storage _credit = getOrAdd(_self, _token);
        _credit.amount += _amount;
        if (_locked) _credit.locked += _amount;
    }

    function remove(
        IJobsRegistry.Credit[] storage _self,
        address _token,
        uint256 _amount,
        bool _consumeLocked
    ) external {
        (IJobsRegistry.Credit storage _credit, uint256 _index) = get(
            _self,
            _token
        );
        if (
            _amount > _credit.amount ||
            (!_consumeLocked && _credit.amount - _credit.locked < _amount)
        ) revert NotEnoughCredit();
        _credit.amount -= _amount;
        uint256 _lockedCredit = _credit.locked;
        if (_consumeLocked && _lockedCredit > 0)
            _credit.locked -= _lockedCredit > _amount ? _amount : _lockedCredit;
        uint256 _selfLength = _self.length;
        if (_credit.amount == 0) {
            if (_selfLength > 1 && _index < _selfLength - 1)
                _self[_index] = _self[_selfLength - 1];
            _self.pop();
        }
    }

    function migrate(
        IJobsRegistry.Credit[] storage _self,
        IJobsRegistry.Credit[] storage _newCredits
    ) external {
        if (_self.length == 0) return; // nothing to migrate
        if (_newCredits.length > 0) revert InvalidNewCredits();
        for (uint256 _i = 0; _i < _self.length; _i++) {
            IJobsRegistry.Credit storage _oldCredit = _self[_i];
            if (_oldCredit.token == address(0)) revert InvalidOldCredit();
            if (_oldCredit.amount == 0) continue; // not migrating empty credits
            _newCredits.push(_oldCredit);
        }
    }
}

pragma solidity ^0.8.10;

/**
 * @title IJobsRegistry
 * @dev IJobsRegistry contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJobsRegistry {
    struct Credit {
        address token;
        uint256 amount;
        uint256 locked;
    }

    struct Job {
        uint256 id;
        address addrezz;
        address owner;
        string specification;
        Credit[] credits;
    }

    event AllowLiquidity(address liquidity, address weightCalculator);
    event DisallowLiquidity(address liquidity);
    event AllowJobsCreator(address indexed creator);
    event DisallowJobsCreator(address indexed creator);
    event AddJob(
        address indexed owner,
        address indexed job,
        string specification
    );
    event UpgradeJob(
        address indexed owner,
        address indexed oldJob,
        address indexed newJob,
        string newSpecification
    );
    event RemoveJob(address indexed owner, address indexed job);
    event AddCredit(
        address indexed account,
        address indexed job,
        address indexed token,
        uint256 amount,
        uint256 fee
    );
    event RemoveCredit(
        address indexed account,
        address indexed job,
        address indexed token,
        uint256 amount,
        uint256 fee
    );
    event AddLiquidityCredit(
        address indexed account,
        address indexed job,
        address indexed liquidity,
        uint256 liquidityAmount,
        uint256 addedCreditAmount
    );
    event RegisterWork(
        address indexed job,
        address indexed worker,
        address indexed token,
        uint256 reward,
        uint256 usedGas
    );
    event SetFee(uint16 fee);
    event SetLiquidityTokenPremium(uint16 fee);
    event SetNativeToken(address nativeToken);
    event SetBonder(address bonder);
    event SetFeeReceiver(address feeReceiver);
    event SetWorkEvaluator(address workEvaluator);

    function liquidityWeightCalculator(address _liquidityToken)
        external
        returns (address);

    function jobsCreator(address _jobsCreator) external returns (bool);

    function fee() external returns (uint16);

    function liquidityTokenPremium() external returns (uint16);

    function nativeToken() external returns (address);

    function bonder() external returns (address);

    function feeReceiver() external returns (address);

    function allowLiquidity(address _liquidity, address _weightCalculator)
        external;

    function disallowLiquidity(address _liquidity) external;

    function allowJobCreator(address _creator) external;

    function disallowJobCreator(address _creator) external;

    function addJob(
        address _job,
        address _owner,
        string calldata _specification
    ) external;

    function upgradeJob(
        address _oldJob,
        address _newJob,
        string calldata _newSpecification
    ) external;

    function removeJob(address _job) external;

    function addCredit(
        address _job,
        address _token,
        uint256 _amount
    ) external;

    function addCreditWithPermit(
        address _job,
        address _token,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function addLiquidityCredit(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function removeCredit(
        address _job,
        address _token,
        uint256 _amount
    ) external;

    function initializeWork() external;

    function initializeWorkWithRequirements(
        address _worker,
        uint256 _minimumBonded,
        uint256 _minimumEarned,
        uint256 _minimumWorksCompleted,
        uint256 _minimumAge
    ) external;

    function finalizeWork(address _worker) external;

    function finalizeWork(
        address _worker,
        address _rewardToken,
        uint256 _amount
    ) external;

    function exists(address _job) external view returns (bool);

    function jobsOfOwner(address _owner) external view returns (Job[] memory);

    function credit(address _job, address _token)
        external
        view
        returns (uint256);

    function setFee(uint16 _fee) external;

    function setLiquidityTokenPremium(uint16 _fee) external;

    function setNativeToken(address _nativeToken) external;

    function setBonder(address _bonder) external;

    function setFeeReceiver(address _feeReceiver) external;

    function setWorkEvaluator(address _workEvaluator) external;
}