//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract FetcchGovernance {
    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;
    uint256 private BASE_FEE = 100;

    address private constant NATIVE =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public fetcchpool;
    mapping(address => bool) public lpData;
    mapping(address => mapping(address => uint256)) public lpBalance;
    mapping(address => mapping(address => uint256)) public lpRewards;
    mapping(address => mapping(address => uint256)) public lpDisbursedRewards;
    mapping(address => uint256) totalLiquidity;
    mapping(address => uint256) totalExcessLiquidity;
    mapping(address => uint256) rewardsPool;

    address[] lpList;
    // mapping(address => uint) public totalRewardsEarned;

    modifier onlyPool(address _pool) {
        require(
            _pool == fetcchpool,
            "Fetcch: only can be called by FetcchPool"
        );
        _;
    }

    event AddedLP(address lp, address token, uint256 amount);

    constructor(address _fetcchpool) {
        fetcchpool = _fetcchpool;
    }

    function addLP(
        address _lp,
        address _token,
        uint256 _amount
    ) public onlyPool(msg.sender) {
        require(_amount > 0, "Fetcch: amount should be greater than zero");
        require(_lp != address(0), "Fetcch: LP Address cannot be zero");
        require(_token != address(0), "Fetcch: Cannot be address(0)");
        // require(lpData[_lp], "Fetcch: LP already exists");

        lpData[_lp] = true;
        lpBalance[_lp][_token] = _amount;
        lpList.push(_lp);
        emit AddedLP(_lp, _token, _amount);
    }

    function updateLP(
        address _lp,
        address _token,
        uint256 _disbursedAmount,
        uint256 _disbursedReward
    ) public onlyPool(msg.sender) {
        lpBalance[_lp][_token] -= _disbursedAmount;
        lpDisbursedRewards[_lp][_token] += _disbursedReward;
    }

    function addRewards(address _token, uint256 _amount) public {
        uint256 _fees = (_amount * BASE_FEE) / FLOAT_HANDLER_TEN_4;

        require(_token != address(0), "Fetcch: Cannot be address(0)");
        require(_amount > 0, "Fetcch: amount should be greater than zero");
        require(_fees > 0, "Fetcch: fees should be greater than zero");

        unchecked {
            rewardsPool[_token] += _fees;
        }
    }

    function disburseReward(address _token) public {
        uint256 liquidity = totalLiquidity[_token];
        uint256 totalRewards = rewardsPool[_token];

        uint256 leng = lpList.length;
        for (uint256 i = 0; i < leng; ) {
            address lp = lpList[i];
            uint256 lpTokenBalance = lpBalance[lp][_token];

            uint256 position = (lpTokenBalance * 100) / liquidity;
            uint256 userReward = (position * totalRewards) / 100;

            lpRewards[lp][_token] = userReward;

            unchecked {
                i++;
            }
        }
    }
}