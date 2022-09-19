// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/GMX_Governable.sol";
import "../peripherals/interfaces/GMX_ITimelock.sol";

contract GMX_RewardManager is GMX_Governable {

    bool public isInitialized;

    GMX_ITimelock public timelock;
    address public rewardRouter;

    address public glpManager;

    address public stakedGmxTracker;
    address public bonusGmxTracker;
    address public feeGmxTracker;

    address public feeGlpTracker;
    address public stakedGlpTracker;

    address public stakedGmxDistributor;
    address public stakedGlpDistributor;

    address public esGmx;
    address public bnGmx;

    address public gmxVester;
    address public glpVester;

    function initialize(
        GMX_ITimelock _timelock,
        address _rewardRouter,
        address _glpManager,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _feeGlpTracker,
        address _stakedGlpTracker,
        address _stakedGmxDistributor,
        address _stakedGlpDistributor,
        address _esGmx,
        address _bnGmx,
        address _gmxVester,
        address _glpVester
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        glpManager = _glpManager;

        stakedGmxTracker = _stakedGmxTracker;
        bonusGmxTracker = _bonusGmxTracker;
        feeGmxTracker = _feeGmxTracker;

        feeGlpTracker = _feeGlpTracker;
        stakedGlpTracker = _stakedGlpTracker;

        stakedGmxDistributor = _stakedGmxDistributor;
        stakedGlpDistributor = _stakedGlpDistributor;

        esGmx = _esGmx;
        bnGmx = _bnGmx;

        gmxVester = _gmxVester;
        glpVester = _glpVester;
    }

    function updateEsGmxHandlers() external onlyGov {
        timelock.managedSetHandler(esGmx, rewardRouter, true);

        timelock.managedSetHandler(esGmx, stakedGmxDistributor, true);
        timelock.managedSetHandler(esGmx, stakedGlpDistributor, true);

        timelock.managedSetHandler(esGmx, stakedGmxTracker, true);
        timelock.managedSetHandler(esGmx, stakedGlpTracker, true);

        timelock.managedSetHandler(esGmx, gmxVester, true);
        timelock.managedSetHandler(esGmx, glpVester, true);
    }

    function enableRewardRouter() external onlyGov {
        timelock.managedSetHandler(glpManager, rewardRouter, true);

        timelock.managedSetHandler(stakedGmxTracker, rewardRouter, true);
        timelock.managedSetHandler(bonusGmxTracker, rewardRouter, true);
        timelock.managedSetHandler(feeGmxTracker, rewardRouter, true);

        timelock.managedSetHandler(feeGlpTracker, rewardRouter, true);
        timelock.managedSetHandler(stakedGlpTracker, rewardRouter, true);

        timelock.managedSetHandler(esGmx, rewardRouter, true);

        timelock.managedSetMinter(bnGmx, rewardRouter, true);

        timelock.managedSetMinter(esGmx, gmxVester, true);
        timelock.managedSetMinter(esGmx, glpVester, true);

        timelock.managedSetHandler(gmxVester, rewardRouter, true);
        timelock.managedSetHandler(glpVester, rewardRouter, true);

        timelock.managedSetHandler(feeGmxTracker, gmxVester, true);
        timelock.managedSetHandler(stakedGlpTracker, glpVester, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract GMX_Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface GMX_ITimelock {
    function setAdmin(address _admin) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
    function managedSetHandler(address _target, address _handler, bool _isActive) external;
    function managedSetMinter(address _target, address _minter, bool _isActive) external;
}