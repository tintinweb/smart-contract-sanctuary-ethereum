// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Events.sol";
import "./IBEP20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Staking is ReentrancyGuard, DataStorage, Events, Ownable, Pausable {
    using SafeMath for uint256;

    modifier onlySafe() {
        require(whiteList[msg.sender], "require Safe Address.");
        _;
    }
    
    constructor () {
        levels[1] = 6000 ether;
        levels[2] = 30000 ether;
        levels[3] = 168000 ether;
        levels[4] = 940000 ether;
        levels[5] = 1440000 ether;

    }

    function invest(uint256 amount, uint256 level)
        external
        nonReentrant
        whenNotPaused
    {
        require(levels[level] > 0, "Level not exist");
        require(amount == levels[level], "Invest amount isn't enough");
        require(START_TIME <= block.timestamp, "Campaign not start");
        require(block.timestamp <= END_TIME, "Campaign stopped");
        require(
            IBEP20(ercToken).allowance(_msgSender(), address(this)) >= amount,
            "Token allowance too low"
        );
        _invest(amount, level);
    }

    function _invest(uint256 _amount, uint256 _level) internal {
        UserInfo storage user = userInfos[_level][_msgSender()];
        require(user.totalAmount == 0, "You already staking before");
        require(!user.isUnstake, "staking one time by level");
        IBEP20(ercToken).transferFrom(_msgSender(), address(this), _amount);
        user.registerTime = block.timestamp;
        user.totalAmount = _amount;
        user.level = _level;
        emit NewStake(_msgSender(), _amount, _level);
    }

    function modifyWhiteList(
        address[] memory newAddr,
        address[] memory removedAddr
    ) public onlyOwner {
        for (uint256 index; index < newAddr.length; index++) {
            whiteList[newAddr[index]] = true;
        }
        for (uint256 index; index < removedAddr.length; index++) {
            whiteList[removedAddr[index]] = false;
        }
    }

    function investByAdmin(address[] memory userAddrs, uint256 level) external onlySafe{
        require(levels[level] > 0, "Level not exist");
        for (uint256 index; index < userAddrs.length; index++) {
            emit NewStake(userAddrs[index], levels[level], level);
        }
    }

    function unStake(uint256 level) external nonReentrant whenNotPaused {
        UserInfo storage user = userInfos[level][_msgSender()];
        require(user.totalAmount > 0, "You are not staking before");
        require(!user.isUnstake, "You already unstake before");
        require(
            user.registerTime.add(LOCKED_TIME) <= block.timestamp,
            "Not enough time to unstake"
        );
        IBEP20(ercToken).transfer(_msgSender(), user.totalAmount);
        emit UnStake(_msgSender(), user.totalAmount, user.level);
        user.isUnstake = true;
        user.totalAmount = 0;
    }

    function getUserInfo(address userAddress, uint256 level)
        public
        view
        returns (UserInfo memory userInfo)
    {
        userInfo = userInfos[level][userAddress];
    }

    function setErcToken(address _addr) external onlyOwner {
        ercToken = _addr;
    }

    function setStartTime(uint256 _time) external onlyOwner {
        START_TIME = _time;
    }

    function setEndTime(uint256 _time) external onlyOwner {
        END_TIME = _time;
    }

    function setLockedTime(uint256 _time) external onlyOwner {
        LOCKED_TIME = _time;
    }

    function modifyWhiteList(
        uint256[] memory level,
        uint256[] memory stakeValue
    ) external onlyOwner {
        require(level.length == stakeValue.length, "length not match");
        for (uint256 index; index < level.length; index++) {
            levels[level[index]] = stakeValue[index];
        }
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IBEP20(coinAddress).transfer(to, value);
    }
}