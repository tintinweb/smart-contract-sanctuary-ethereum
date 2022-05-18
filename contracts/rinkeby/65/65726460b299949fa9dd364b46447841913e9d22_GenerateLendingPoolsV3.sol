/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/convex/IConvexBooster.sol


/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IConvexBooster {
    function liquidate(
        uint256 _convexPid,
        int128 _curveCoinId,
        address _user,
        uint256 _amount
    ) external returns (address, uint256);

    function depositFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function withdrawFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user,
        bool _freezeTokens
    ) external returns (bool);

    function poolInfo(uint256 _convexPid)
        external
        view
        returns (
            uint256 originConvexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardCrvPool,
            address rewardCvxPool,
            bool shutdown
        );

    function addConvexPool(uint256 _originConvexPid) external;
}


// File contracts/convex/IConvexBoosterV2.sol


/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IConvexBoosterV2 is IConvexBooster {
    function liquidate(
        uint256 _convexPid,
        int128 _curveCoinId,
        address _user,
        uint256 _amount
    ) external override returns (address, uint256);

    function depositFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external override returns (bool);

    function withdrawFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user,
        bool _freezeTokens
    ) external override returns (bool);

    function poolInfo(uint256 _convexPid)
        external
        view
        override
        returns (
            uint256 originConvexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardCrvPool,
            address rewardCvxPool,
            bool shutdown
        );

    function addConvexPool(uint256 _originConvexPid) external override;

    function addConvexPool(
        uint256 _originConvexPid,
        address _curveSwapAddress,
        address _curveZapAddress,
        address _basePoolAddress,
        bool _isMeta,
        bool _isMetaFactory
    ) external;

    function getPoolZapAddress(address _lpToken)
        external
        view
        returns (address);

    function getPoolToken(uint256 _pid) external view returns (address);

    function calculateTokenAmount(
        uint256 _pid,
        uint256 _tokens,
        int128 _curveCoinId
    ) external view returns (uint256);

    function updateMovingLeverage(
        uint256 _pid,
        uint256 _tokens,
        int128 _curveCoinId
    ) external returns (uint256);
}

interface IMovingLeverageBase {
    function get(uint256 _pid, int128 _coinId) external view returns (uint256);
}


// File contracts/supply/ISupplyBooster.sol


/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface ISupplyBooster {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address underlyToken,
            address rewardInterestPool,
            address supplyTreasuryFund,
            address virtualBalance,
            bool isErc20,
            bool shutdown
        );

    function liquidate(bytes32 _lendingId, uint256 _lendingInterest)
        external
        payable
        returns (address);

    function getLendingUnderlyToken(bytes32 _lendingId)
        external
        view
        returns (address);

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest,
        uint256 _borrowNumbers
    ) external;

    // ether
    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingInterest
    ) external payable;

    // erc20
    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) external;

    function addSupplyPool(address _underlyToken, address _supplyTreasuryFund)
        external
        returns (bool);

    function getBorrowRatePerBlock(uint256 _pid)
        external
        view
        returns (uint256);

    function getUtilizationRate(uint256 _pid) external view returns (uint256);
}


// File contracts/GenerateLendingPoolsV3.sol


/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}

interface ILendingMarket {
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) external;
}

interface ISupplyRewardFactoryExtra is ISupplyRewardFactory {
    function addOwner(address _newOwner) external;
}

contract GenerateLendingPoolsV3 {
    address public convexBooster;
    address public lendingMarket;
    address public supplyBooster;
    address public supplyRewardFactory;
    address public deployer;

    constructor(address _deployer) public {
        deployer = _deployer;
    }

    function setLendingContract(
        address _supplyBooster,
        address _convexBooster,
        address _lendingMarket,
        address _supplyRewardFactory
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        supplyBooster = _supplyBooster;
        convexBooster = _convexBooster;
        lendingMarket = _lendingMarket;
        supplyRewardFactory = _supplyRewardFactory;
    }

    function addConvexBoosterPool(uint256 _originConvexPid) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        IConvexBoosterV2(convexBooster).addConvexPool(_originConvexPid);
    }

    function addConvexBoosterPool(
        uint256 _originConvexPid,
        address _curveSwapAddress,
        address _curveZapAddress,
        address _basePoolAddress,
        bool _isMeta,
        bool _isMetaFactory
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        IConvexBoosterV2(convexBooster).addConvexPool(
            _originConvexPid,
            _curveSwapAddress,
            _curveZapAddress,
            _basePoolAddress,
            _isMeta,
            _isMetaFactory
        );
    }

    function addLendingMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        ILendingMarket(lendingMarket).addMarketPool(
            _convexBoosterPid,
            _supplyBoosterPids,
            _curveCoinIds,
            100,
            50
        );
    }

    function addSupplyPool(address _underlyToken, address _supplyTreasuryFund)
        public
    {
        _addSupplyPool(_underlyToken, _supplyTreasuryFund);
    }

    function _addSupplyPool(address _underlyToken, address _supplyTreasuryFund)
        internal
    {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        ISupplyRewardFactoryExtra(supplyRewardFactory).addOwner(
            _supplyTreasuryFund
        );

        ISupplyBooster(supplyBooster).addSupplyPool(
            _underlyToken,
            _supplyTreasuryFund
        );
    }
}