/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract AbsPool is Ownable {
    struct UserMinterInfo {
        uint256 minterAmount;
        uint256 minterClaimedReward;
    }

    struct MinterRecord {
        uint256 minterAmount;
        uint256 minterStart;
        uint256 minterEnd;
        uint256 rewardPerDay;
        uint256 lastMinterRewardTime;
        uint256 claimedMinterReward;
    }

    mapping(address => UserMinterInfo) private _minterInfos;
    uint256 public _maxActiveRecordLen = 20;
    mapping(address => MinterRecord[]) private _minterRecords;

    address public _minterReceiveAddress = address(0x000000000000000000000000000000000000dEaD);

    address private _mintRewardToken;
    address private _minterToken;
    uint256 public _minterTokenUnit;

    bool private _pause;
    uint256 private _minterDuration = 90 days;
    uint256 private _minterRewardPerAmountPerDay;
    uint256 private _minterTotalAmount;
    uint256 private _minterActiveAmount;
    uint256 private _totalMinterReward;

    constructor(
        address MinterToken, address MintRewardToken
    ){
        _mintRewardToken = MintRewardToken;
        _minterToken = MinterToken;
        _minterTokenUnit = 10 ** IERC20(MinterToken).decimals();
        _minterRewardPerAmountPerDay = 14 * 10 ** IERC20(MintRewardToken).decimals() / 100;
    }

    receive() external payable {}

    function getBaseInfo() external view returns (
        address mintRewardToken,
        uint256 mintRewardTokenDecimals,
        string memory mintRewardTokenSymbol,
        address minterToken,
        uint256 minterTokenDecimals,
        string memory minterTokenSymbol,
        uint256 blockTime,
        bool pause,
        uint256 minterDuration,
        uint256 minterRewardPerAmountPerDay,
        uint256 minterTotalAmount,
        uint256 minterActiveAmount,
        uint256 totalMinterReward
    ){
        mintRewardToken = _mintRewardToken;
        mintRewardTokenDecimals = IERC20(mintRewardToken).decimals();
        mintRewardTokenSymbol = IERC20(mintRewardToken).symbol();
        minterToken = _minterToken;
        minterTokenDecimals = IERC20(minterToken).decimals();
        minterTokenSymbol = IERC20(minterToken).symbol();
        blockTime = block.timestamp;
        pause = _pause;
        minterDuration = _minterDuration;
        minterRewardPerAmountPerDay = _minterRewardPerAmountPerDay;
        minterTotalAmount = _minterTotalAmount;
        minterActiveAmount = _minterActiveAmount;
        totalMinterReward = _totalMinterReward;
    }

    function setMintRewardToken(address rewardToken) external onlyOwner {
        _mintRewardToken = rewardToken;
    }

    function claimBalance(address to, uint256 amount) external onlyOwner {
        safeTransferETH(to, amount);
    }

    function claimToken(address token, address to, uint256 amount) external onlyOwner {
        safeTransfer(token, to, amount);
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (success && data.length > 0) {

        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,bytes memory data) = to.call{value : value}(new bytes(0));
        if (success && data.length > 0) {

        }
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if (success && data.length > 0) {

        }
    }

    function _giveToken(address tokenAddress, address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "PTNE");
        safeTransfer(tokenAddress, account, amount);
    }

    function _takeToken(address tokenAddress, address from, address to, uint256 tokenNum) private {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(from)) >= tokenNum, "TNE");
        safeTransferFrom(tokenAddress, from, to, tokenNum);
    }

    function mint(uint256 amount) external {
        require(!_pause, "pause");
        require(amount > 0, "0");
        address account = msg.sender;

        UserMinterInfo storage minterInfo = _minterInfos[account];
        uint256 userRecordLen = _minterRecords[account].length;
        require(_maxActiveRecordLen > userRecordLen, "ML");
        _takeToken(_minterToken, account, _minterReceiveAddress, amount * _minterTokenUnit);

        uint256 startTime = block.timestamp;
        _addRecord(account, amount, startTime, startTime + _minterDuration);
        minterInfo.minterAmount += amount;

        _minterTotalAmount += amount;
        _minterActiveAmount += amount;
    }

    function _addRecord(address account, uint256 amount, uint256 startTime, uint256 endTime) private {
        _minterRecords[account].push(
            MinterRecord(amount, startTime, endTime, _minterRewardPerAmountPerDay, startTime, 0)
        );
    }

    function claimMinterReward() external {
        address account = msg.sender;
        _claimMinterReward(account);
    }

    function _claimMinterReward(address account) private {
        UserMinterInfo storage minterInfo = _minterInfos[account];
        uint256 recordLen = _minterRecords[account].length;
        uint256 blockTime = block.timestamp;
        MinterRecord storage record;
        uint256 pendingReward;
        for (uint256 i = 0; i < recordLen;) {
            record = _minterRecords[account][i];
            uint256 rewardPerAmountPerDay = record.rewardPerDay;
            uint256 lastRewardTime = record.lastMinterRewardTime;
            uint256 endTime = record.minterEnd;
            uint256 amount = record.minterAmount;
            if (lastRewardTime < endTime && lastRewardTime < blockTime) {
                if (endTime > blockTime) {
                    endTime = blockTime;
                } else {
                    _minterActiveAmount -= amount;
                    minterInfo.minterAmount -= amount;
                }
                record.lastMinterRewardTime = endTime;
                uint256 reward = amount * rewardPerAmountPerDay * (endTime - lastRewardTime) / 1 days;
                record.claimedMinterReward += reward;
                pendingReward += reward;
            }
        unchecked{
            ++i;
        }
        }
        _giveToken(_mintRewardToken, account, pendingReward);
        minterInfo.minterClaimedReward += pendingReward;
        _totalMinterReward += pendingReward;
    }

    function getRecordLength(address account) public view returns (uint256){
        return _minterRecords[account].length;
    }

    function getRecords(
        address account,
        uint256 start,
        uint256 length
    ) external view returns (
        uint256 returnCount,
        uint256[] memory amount,
        uint256[] memory startTime,
        uint256[] memory endTime,
        uint256[] memory lastRewardTime,
        uint256[] memory claimedRewards,
        uint256[] memory totalRewards,
        uint256[] memory rewardPerDays
    ){
        uint256 recordLen = _minterRecords[account].length;
        if (0 == length) {
            length = recordLen;
        }
        returnCount = length;

        amount = new uint256[](length);
        startTime = new uint256[](length);
        endTime = new uint256[](length);
        lastRewardTime = new uint256[](length);
        claimedRewards = new uint256[](length);
        totalRewards = new uint256[](length);
        rewardPerDays = new uint256[](length);
        uint256 index = 0;
        for (uint256 i = start; i < start + length; i++) {
            if (i >= recordLen) {
                return (index, amount, startTime, endTime, lastRewardTime, claimedRewards, totalRewards, rewardPerDays);
            }
            (amount[index], startTime[index], endTime[index], lastRewardTime[index], claimedRewards[index], rewardPerDays[index]) = getRecord(account, i);
            totalRewards[index] = getPendingMinterRecordReward(account, i);
            index++;
        }
    }

    function getUserMinterInfo(address account) public view returns (
        uint256 minterAmount,
        uint256 minterClaimedReward,
        uint256 minterPendingReward,
        uint256 minterTokenBalance,
        uint256 minterTokenAllowance
    ){
        UserMinterInfo storage minterInfo = _minterInfos[account];
        minterAmount = minterInfo.minterAmount;
        minterClaimedReward = minterInfo.minterClaimedReward;
        minterPendingReward = getPendingMinterReward(account);
        minterTokenBalance = IERC20(_minterToken).balanceOf(account);
        minterTokenAllowance = IERC20(_minterToken).allowance(account, address(this));
    }

    function getPendingMinterRecordReward(address account, uint256 i) public view returns (uint256 pendingReward){
        uint256 blockTime = block.timestamp;
        MinterRecord storage record = _minterRecords[account][i];
        uint256 rewardPerAmountPerDay = record.rewardPerDay;
        uint256 lastRewardTime = record.lastMinterRewardTime;
        uint256 endTime = record.minterEnd;
        if (lastRewardTime < endTime && lastRewardTime < blockTime) {
            if (endTime > blockTime) {
                endTime = blockTime;
            }
            pendingReward += record.minterAmount * rewardPerAmountPerDay * (endTime - lastRewardTime) / 1 days;
        }
    }

    function getRecord(address account, uint256 i) public view returns (
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 lastRewardTime,
        uint256 claimedReward,
        uint256 rewardPerDay
    ){
        MinterRecord storage record = _minterRecords[account][i];
        amount = record.minterAmount;
        startTime = record.minterStart;
        endTime = record.minterEnd;
        lastRewardTime = record.lastMinterRewardTime;
        claimedReward = record.claimedMinterReward;
        rewardPerDay = record.rewardPerDay;
    }

    function getPendingMinterReward(address account) public view returns (uint256 pendingReward){
        uint256 recordLen = _minterRecords[account].length;
        uint256 blockTime = block.timestamp;
        MinterRecord storage record;
        for (uint256 i = 0; i < recordLen;) {
            record = _minterRecords[account][i];
            uint256 lastRewardTime = record.lastMinterRewardTime;
            uint256 endTime = record.minterEnd;
            if (lastRewardTime < endTime && lastRewardTime < blockTime) {
                if (endTime > blockTime) {
                    endTime = blockTime;
                }
                uint256 rewardPerAmountPerDay = record.rewardPerDay;
                pendingReward += record.minterAmount * rewardPerAmountPerDay * (endTime - lastRewardTime) / 1 days;
            }
        unchecked{
            ++i;
        }
        }
    }

    function setMinterRewardPerAmountPerDay(uint256 a) public onlyOwner {
        _minterRewardPerAmountPerDay = a;
    }

    function setMinterDuration(uint256 d) public onlyOwner {
        _minterDuration = d;
    }

    function setMinterToken(address t) public onlyOwner {
        _minterToken = t;
        _minterTokenUnit = 10 ** IERC20(t).decimals();
    }

    function setMaxActiveRecordLen(uint256 l) public onlyOwner {
        _maxActiveRecordLen = l;
    }

    function setMinterReceiveAddress(address r) public onlyOwner {
        _minterReceiveAddress = r;
    }

    function setPause(bool pause) public onlyOwner {
        _pause = pause;
    }

}

contract BurnPool is AbsPool {
    constructor() AbsPool(
    //ZM
        address(0xf315EC7B1063E21d5AbaF12cA3470F57AbF47ea5),
    //ETX
        address(0x469fc807543A766199C07d3a76A3e7A6EC1A2004)
    ){

    }
}