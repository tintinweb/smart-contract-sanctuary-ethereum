/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Referral is Ownable {
    using SafeMath for uint256;
    string public name = "Referral";

    struct UserInfo {
		uint256 index;
        address referrer;
        uint256 followers;
        uint256 totalReward;
        uint256 claimed;
	}

    // The Alefaa Bitcoin!
    address public abtc;
    uint256 public constant rFee = 2; // 2%

    mapping(address => bool) internal isOperator;
    mapping(address => UserInfo) internal usersInfo;

    event RewardClaim(address indexed claimer, uint256 rewardToTransfer);
    event RewardNotify(address indexed user, uint256 amount, uint256 time);

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    constructor(address _abtc, address _initializer) {
        abtc = _abtc;
        _transferOwnership(_initializer);
    }

    function pendingAbtc(address _user) external view returns (uint256) {
        UserInfo memory user = usersInfo[_user];
        return user.totalReward.sub(user.claimed);
    }

    function claim() external {
        UserInfo memory user = usersInfo[msg.sender];
        require(user.totalReward > user.claimed, "no Reward");
        uint256 _rewardToTransfer = user.totalReward.sub(user.claimed);
        IERC20(abtc).transfer(msg.sender, _rewardToTransfer);
        user.claimed = user.totalReward;

        emit RewardClaim(msg.sender, _rewardToTransfer);
    }

    function notifyReward(address _user, uint256 _amount) external onlyOperator{
        UserInfo memory user = usersInfo[_user];
        user.totalReward = user.totalReward.add(_amount);

        emit RewardNotify(_user, _amount, block.timestamp);
    }

    function setReferrer(address _investor, address _referrer) external onlyOperator {
        if (usersInfo[_investor].referrer == address(0)) {
            usersInfo[_investor].referrer = _referrer;
            usersInfo[_referrer].followers++;
        }
    }

    function clearReferrer(address _investor) external onlyOperator {
        address _referrer = usersInfo[_investor].referrer;
        if (_referrer != address(0)) {
            usersInfo[_investor].referrer = address(0);
            usersInfo[_referrer].followers = usersInfo[_referrer].followers.sub(1);
        }
    }

    function setOperator(address _operator, bool _flag) external onlyOwner {
        isOperator[_operator] = _flag;
    }

    function checkOperator(address _user) external view returns (bool) {
        return isOperator[_user];
    }

    function getReferrer(address _investor) external view returns (address) {
        return usersInfo[_investor].referrer;
    }

    function getTotalFollowers(address _investor) external view returns (uint256) {
        return usersInfo[_investor].followers;
    }

    function viewUserInfo(
        address _user
    ) external view returns (
        UserInfo memory _userInfo
    ) {
        _userInfo = usersInfo[_user];
    }

}