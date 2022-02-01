// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AlphaToken.sol";

// alphaToken locker contract.
contract AlphaLocker is Ownable {
    using SafeMath for uint256;
    IERC20 alphaToken;
    address emergencyAddress;
    bool emergencyFlag = false;

    struct LockInfo{
        uint256 _amount;
        uint256 _timestamp;
        bool _isDev;
    }

    uint256 public lockingPeriod;
    uint256 public devLockingPeriod;

    mapping (address => LockInfo[]) public lockInfoByUser;
    mapping (address => uint256) public latestCounterByUser;
    mapping (address => uint256) public unclaimedTokensByUser;

    event LockingPeriod(address indexed user, uint newLockingPeriod, uint newDevLockingPeriod);

    constructor(address _alphaToken, address _emergencyAddress, uint256 _lockingPeriodInDays, uint256 _devLockingPeriodInDays) {
        require(address(_alphaToken) != address(0), "_alpha token is a zero address");
        require(address(_emergencyAddress) != address(0), "_emergencyAddress is a zero address");
        alphaToken = IERC20(_alphaToken);
        emergencyAddress = _emergencyAddress;
        lockingPeriod = _lockingPeriodInDays * 1 days;
        devLockingPeriod = _devLockingPeriodInDays * 1 days;
    }

    // function to lock user reward alpha tokens in token contract, called by onlyOwner that would be TopDog.sol
    function lock(address _holder, uint256 _amount, bool _isDev) external onlyOwner {
        require(_holder != address(0), "Invalid user address");
        require(_amount > 0, "Invalid amount entered");

        lockInfoByUser[_holder].push(LockInfo(_amount, block.timestamp, _isDev));
        unclaimedTokensByUser[_holder] = unclaimedTokensByUser[_holder].add(_amount);
    }

    // function to claim all the tokens locked for a user, after the locking period
    function claimAllForUser(uint256 r, address user) public {
        require(!emergencyFlag, "Emergency mode, cannot access this function");
        require(r>latestCounterByUser[user], "Increase right header, already claimed till this");
        require(r<=lockInfoByUser[user].length, "Decrease right header, it exceeds total length");
        LockInfo[] memory lockInfoArrayForUser = lockInfoByUser[user];
        uint256 totalTransferableAmount = 0;
        uint i;
        for (i=latestCounterByUser[user]; i<r; i++){
            uint256 lockingPeriodHere = lockingPeriod;
            if(lockInfoArrayForUser[i]._isDev){
                lockingPeriodHere = devLockingPeriod;
            }
            if(block.timestamp >= (lockInfoArrayForUser[i]._timestamp.add(lockingPeriodHere))){
                totalTransferableAmount = totalTransferableAmount.add(lockInfoArrayForUser[i]._amount);
                unclaimedTokensByUser[user] = unclaimedTokensByUser[user].sub(lockInfoArrayForUser[i]._amount);
                latestCounterByUser[user] = i.add(1);
            } else {
                break;
            }
        }
        alphaToken.transfer(user, totalTransferableAmount);
    }

    // function to claim all the tokens locked by user, after the locking period
    function claimAll(uint256 r) external {
        claimAllForUser(r, msg.sender);
    }

    // function to get claimable amount for any user
    function getClaimableAmount(address _user) external view returns(uint256) {
        LockInfo[] memory lockInfoArrayForUser = lockInfoByUser[_user];
        uint256 totalTransferableAmount = 0;
        uint i;
        for (i=latestCounterByUser[_user]; i<lockInfoArrayForUser.length; i++){
            uint256 lockingPeriodHere = lockingPeriod;
            if(lockInfoArrayForUser[i]._isDev){
                lockingPeriodHere = devLockingPeriod;
            }
            if(block.timestamp >= (lockInfoArrayForUser[i]._timestamp.add(lockingPeriodHere))){
                totalTransferableAmount = totalTransferableAmount.add(lockInfoArrayForUser[i]._amount);
            } else {
                break;
            }
        }
        return totalTransferableAmount;
    }

    // get the left and right headers for a user, left header is the index counter till which we have already iterated, right header is basically the length of user's lockInfo array
    function getLeftRightCounters(address _user) external view returns(uint256, uint256){
        return(latestCounterByUser[_user], lockInfoByUser[_user].length);
    }

    // in cases of emergency, emergency address can set this to true, which will enable emergencyWithdraw function
    function setEmergencyFlag(bool _emergencyFlag) external {
        require(msg.sender == emergencyAddress, "This function can only be called by emergencyAddress");
        emergencyFlag = _emergencyFlag;
    }

    // function for owner to transfer all tokens to another address
    function emergencyWithdrawOwner(address _to) external onlyOwner{
        uint256 amount = alphaToken.balanceOf(address(this));
        require(alphaToken.transfer(_to, amount), 'MerkleDistributor: Transfer failed.');
    }

    // emergency address can be updated from here
    function setEmergencyAddr(address _newAddr) external {
        require(msg.sender == emergencyAddress, "This function can only be called by emergencyAddress");
        require(_newAddr != address(0), "_newAddr is a zero address");
        emergencyAddress = _newAddr;
    }

    // function to update/change the normal & dev locking period
    function setLockingPeriod(uint256 _newLockingPeriod, uint256 _newDevLockingPeriod) external onlyOwner {
        lockingPeriod = _newLockingPeriod;
        devLockingPeriod = _newDevLockingPeriod;
        emit LockingPeriod(msg.sender, _newLockingPeriod, _newDevLockingPeriod);
    }
}