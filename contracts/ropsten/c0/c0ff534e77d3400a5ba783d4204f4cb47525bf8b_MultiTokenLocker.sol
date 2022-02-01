// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AlphaToken.sol";
import "./SafeERC20.sol";

pragma experimental ABIEncoderV2;




contract MultiTokenLocker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct LockInfo {
        address _rewardToken;
        uint256 _amount;
        uint256 _timestamp;
        uint256 _lockingPeriod;
    }

    mapping (address => LockInfo[]) public lockInfoByContract;
    mapping (address => mapping (address => uint256)) public lockedTokensByContract;
    mapping (address => mapping (uint => bool)) public isClaimed;
    mapping (address => bool) public whitelistDistributorContract;

    modifier onlyWhitelisted() {
        require(whitelistDistributorContract[msg.sender], "Can only be called by whitelisted addresses");
        _;
    }


    function receiveApproval(IERC20 _token, uint256 _value, address _distributorContract, uint256 _lockingPeriod) external onlyWhitelisted returns(bool) {
        _token.safeTransferFrom(_distributorContract, address(this), _value);

        lockInfoByContract[_distributorContract].push(LockInfo(address(_token), _value, block.timestamp, _lockingPeriod));
        lockedTokensByContract[_distributorContract][address(_token)] = lockedTokensByContract[_distributorContract][address(_token)].add(_value);
        return true;
    }


    // function for owner to transfer all tokens to another address - paramter: can pass array
    function withdrawTheseToken(address[] calldata _distributorContract, address[][] calldata _to, uint[][] calldata _lockId) public onlyOwner {
        require(_distributorContract.length == _to.length, "Invalid array provided: _distributorContract & _to");
        require(_to.length == _lockId.length, "Invalid array given: _to & _lockId");
        uint i;
        uint j;
        for(i=0;i<_distributorContract.length;i++){
            require(_to[i].length == _lockId[i].length, "Invalid array provided: _to & _lockId");
            for(j=0;j<_to[i].length;j++){
                withdrawThisToken(_distributorContract[i], _to[i][j], _lockId[i][j]);
            }
        }

    }

    // function for owner to transfer a token to another address - paramter: cannot pass array
    function withdrawThisToken(address _distributorContract, address _to, uint _lockId) public onlyOwner {
        require(!isClaimed[_distributorContract][_lockId], "Already claimed");
        LockInfo[] memory lockInfoArray = lockInfoByContract[_distributorContract];
        require(block.timestamp >= lockInfoArray[_lockId]._timestamp.add(lockInfoArray[_lockId]._lockingPeriod), "Cannot claim now, still in locking period");
        uint256 amount = lockInfoArray[_lockId]._amount;
        address rewardToken = lockInfoArray[_lockId]._rewardToken;
        lockedTokensByContract[_distributorContract][rewardToken] = lockedTokensByContract[_distributorContract][rewardToken].sub(amount);
        isClaimed[_distributorContract][_lockId] = true;
        IERC20(rewardToken).safeTransfer(_to, amount);
    }

    // function to get length of _distributorContract lockInfoByContract
    function getLockedTokensLength(address _distributorContract) public view returns (uint256){
        return lockInfoByContract[_distributorContract].length;
    }

    // function to whitelist the _distributorContract (ie xShib/xLeash/tBone-BoneDistributor & SwapRewardDistributor contracts)
    function setWhitelistStatus(address _distributorContract, bool _status) external onlyOwner {
        whitelistDistributorContract[_distributorContract] = _status;
    }

}