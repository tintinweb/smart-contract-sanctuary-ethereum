// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IProRataActionRewards.sol";
import "./IActionHook.sol";
import "./SafeERC20Upgradeable.sol";

contract ProRataActionRewards is
    IProRataActionRewards,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private _periodLength;
    uint256 private _userActionLimitPerPeriod;
    uint256 private _rewardAmountPerPeriod;
    IERC20Upgradeable private _rewardToken;
    uint256 private _totalCurrActionCount;
    uint256 private _totalPrevActionCount;
    mapping(uint256 => uint256) private _userPeriodHashToActionCount;
    mapping(uint256 => uint256) private _periodHashToTotalActionCount;
    IActionHook private _actionHook;

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function setPeriodLength(uint256 _newPeriodLength)
        external
        override
        onlyOwner
    {
        _periodLength = _newPeriodLength;
    }

    function setUserActionLimitPerPeriod(uint256 _newUserActionLimitPerPeriod)
        external
        override
        onlyOwner
    {
        _userActionLimitPerPeriod = _newUserActionLimitPerPeriod;
    }

    function setRewardAmountPerPeriod(uint256 _newRewardAmountPerPeriod)
        external
        override
        onlyOwner
    {
        _rewardAmountPerPeriod = _newRewardAmountPerPeriod;
    }

    function setRewardToken(address _newRewardToken)
        external
        override
        onlyOwner
    {
        _rewardToken = IERC20Upgradeable(_newRewardToken);
    }

    function setActionHook(address _newActionHook)
        external
        override
        onlyOwner
    {
        _actionHook = IActionHook(_newActionHook);
    }

    function action() external override nonReentrant {
        if (address(_actionHook) != address(0)) {
            _actionHook.hook(msg.sender);
        }
        if (_userActionLimitPerPeriod > 0) {
            require(
                getCurrActionCount(tx.origin) < _userActionLimitPerPeriod,
                "Action limit exceeded"
            );
        }
        ++_userPeriodHashToActionCount[
            _getUserPeriodHash(
                tx.origin,
                _getPeriodHash(block.timestamp / _periodLength)
            )
        ];
        ++_periodHashToTotalActionCount[
            _getPeriodHash(block.timestamp / _periodLength)
        ];
    }

    function claim() external override nonReentrant {
        require(getPrevActionCount(tx.origin) > 0, "No amount to claim");
        uint256 _claimAmount =
            (_rewardAmountPerPeriod * getPrevActionCount(tx.origin)) /
                getTotalPrevActionCount();
        _userPeriodHashToActionCount[
            _getUserPeriodHash(
                tx.origin,
                _getPeriodHash(block.timestamp / _periodLength - 1)
            )
        ] = 0;
        _rewardToken.safeTransfer(tx.origin, _claimAmount);
    }

    function withdrawERC20(address _token, uint256 _amount)
        external
        override
        onlyOwner
        nonReentrant
    {
        IERC20Upgradeable(_token).safeTransfer(owner(), _amount);
    }

    function getPeriodLength() external view override returns (uint256) {
        return _periodLength;
    }

    function getUserActionLimitPerPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _userActionLimitPerPeriod;
    }

    function getRewardAmountPerPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _rewardAmountPerPeriod;
    }

    function getRewardToken()
        external
        view
        override
        returns (IERC20Upgradeable)
    {
        return _rewardToken;
    }

    function getTotalCurrActionCount()
        external
        view
        override
        returns (uint256)
    {
        return
            _periodHashToTotalActionCount[
                _getPeriodHash(block.timestamp / _periodLength)
            ];
    }

    function getActionHook() external view override returns (IActionHook) {
        return _actionHook;
    }

    function getTotalPrevActionCount() public view override returns (uint256) {
        return
            _periodHashToTotalActionCount[
                _getPeriodHash(block.timestamp / _periodLength - 1)
            ];
    }

    function getCurrActionCount(address _user)
        public
        view
        override
        returns (uint256)
    {
        return
            _userPeriodHashToActionCount[
                _getUserPeriodHash(
                    _user,
                    _getPeriodHash(block.timestamp / _periodLength)
                )
            ];
    }

    function getPrevActionCount(address _user)
        public
        view
        override
        returns (uint256)
    {
        return
            _userPeriodHashToActionCount[
                _getUserPeriodHash(
                    _user,
                    _getPeriodHash(block.timestamp / _periodLength - 1)
                )
            ];
    }

    /**
     * @dev Period hash is defined as the hash of period number and period length
     * to avoid collision of period number when period length changes.
     */
    function _getPeriodHash(uint256 _periodNumber)
        private
        view
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(_periodNumber, _periodLength)));
    }

    /**
     * @dev The key for the `_userPeriodHashToActionCount` mapping is defined
     * as the hash of the user's address and a particular period's hash.
     */
    function _getUserPeriodHash(address _user, uint256 _periodHash)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_user, _periodHash)));
    }
}