/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

     function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract _CollarStake_ is Ownable, ReentrancyGuard, Pausable, SafeERC20 {

    address[9] public approvedTokens;
    address public rewardToken;
    uint128 constant public max_staking_amount = 500 * 1e12 * 1e18;
    uint128 public max_reward_amount = 200 * 1e6 * 1e18;
    uint128 public lp_reward ;
    uint128 public native_reward;
    uint64 public currentID;
    uint64 constant public max_staking_days = 365 * 7;

    struct User{
        address user;
        address stakeToken;
        uint256 stakeAmount;
        uint256 rewardEarned;
        uint128 lastClaimTime;
        uint128 withdrawTime;
        uint128 rewardEndTime;
        uint128 allocateReward;
        bool isLPStaked;
    }

    mapping (address => bool) public isLPApproved;
    mapping (address => bool) public isNativeApproved;
    mapping (address => mapping (uint256 => User)) public userDetails;

    error tokenNotApproved();
    error stakingAmountReached();
    error alreadyWithdraw();
    error rewardAmountExceed();

    event Deposit(address indexed user, uint indexed stakeID, uint tokenAmount, uint depositTime);
    event Withdraw(address indexed user, uint indexed stakeID, uint withdrawTime);
    event Claim(address indexed user, uint indexed stakeID, uint claimAmount, uint claimTime);
    event FailSafe(address indexed caller, address indexed receiver, uint tokenAmount);
    event updateTokens(address indexed OldToken, address indexed NewToken, address indexed caller );

    constructor(address[6] memory _LPtokens, address[3] memory _nativeToken, address _rewardToken) {

        rewardToken = _rewardToken;
        for(uint8 i = 0; i < _LPtokens.length; i++){
            isLPApproved[_LPtokens[i]] = true;
            approvedTokens[i] = _LPtokens[i];
            isContract(_LPtokens[i]);

            if(i < _nativeToken.length ) {

                isContract(_nativeToken[i]);
                isNativeApproved[_nativeToken[i]] = true;
                approvedTokens[i + 6] = _nativeToken[i];
            }
        }
    }

    function isContract(address _addr) public view {
        require(_addr.code.length != 0,"non-contract address");
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function depositTokens(address _tokenAddress, uint256 _tokenAmount) external whenNotPaused nonReentrant {
        
        currentID++ ;

        User storage user = userDetails[_msgSender()][currentID];

        uint256 reward = calculateReward(_tokenAmount, (max_staking_days * 86400));
        if(!checkTokenLimit(_tokenAddress, reward)) revert stakingAmountReached();

        if(isLPApproved[_tokenAddress]) {
            lp_reward += uint128(reward);
            user.isLPStaked = true;
        } else if(isNativeApproved[_tokenAddress]) {
            native_reward += uint128(reward);
        }

        user.user = _msgSender();
        user.stakeToken = _tokenAddress;
        user.stakeAmount = _tokenAmount;
        user.allocateReward = uint128(reward);
        user.lastClaimTime = uint128(block.timestamp);
        user.rewardEndTime = uint128(block.timestamp + (max_staking_days * 86400));

        safeTransferFrom(IERC20(_tokenAddress), _msgSender(), address(this), _tokenAmount);

        emit Deposit(_msgSender(), currentID, _tokenAmount, block.timestamp);

    }

    function checkTokenLimit(address _tokenAddress, uint256 _tokenAmount) public view returns(bool) {

        if(isLPApproved[_tokenAddress]) {
            return (lp_reward + _tokenAmount) <= max_reward_amount * 80 / 100 ;
        } else if(isNativeApproved[_tokenAddress]) {
            return (native_reward + _tokenAmount) <= max_reward_amount * 20 / 100 ;
        } else revert tokenNotApproved();
    }

    function pendingReward(address _user, uint256 _stakeID) public view returns(uint256 reward) {
        User storage user = userDetails[_user][_stakeID];
        if(user.withdrawTime != 0) revert alreadyWithdraw();
        uint RewardEnd = block.timestamp;
        if(user.rewardEndTime < block.timestamp) RewardEnd = user.rewardEndTime;

        uint256 stakeTime = RewardEnd - user.lastClaimTime;
        reward = calculateReward(user.stakeAmount, stakeTime);
    }

    function calculateReward(uint _tokenAmount, uint _stakeDays) private pure returns(uint){
        uint perToken = (200e6 * 1e24 * 1e18) / (500e12 * 1e18);
        uint perDay = perToken / max_staking_days;
        return _tokenAmount * perDay * _stakeDays / 1e24 / 86400;
    }

    function claimReward(uint256 _stakeID) public whenNotPaused {
        User storage user = userDetails[_msgSender()][_stakeID];
        if(user.withdrawTime != 0) revert alreadyWithdraw();

        uint reward = pendingReward(user.user, _stakeID);
        user.lastClaimTime = uint128(block.timestamp);

        if(user.rewardEndTime < block.timestamp) user.lastClaimTime = user.rewardEndTime;
        user.rewardEarned += reward;
        safeTransfer(IERC20(rewardToken), _msgSender(), reward);

        emit Claim(_msgSender(), _stakeID, reward, block.timestamp);
    }

    function withdraw(uint256 _stakeID) external whenNotPaused nonReentrant {
        User storage user = userDetails[_msgSender()][_stakeID];
        if(user.withdrawTime != 0) revert alreadyWithdraw();

        claimReward(_stakeID);
        
        user.withdrawTime = uint128(block.timestamp);
        safeTransfer(IERC20(user.stakeToken), msg.sender, user.stakeAmount);

        if(user.isLPStaked){
            lp_reward -= uint128( user.allocateReward - user.rewardEarned);
        }else {
            native_reward -= uint128( user.allocateReward - user.rewardEarned);
        }

        emit Withdraw(_msgSender(), _stakeID, block.timestamp);
    }

    function updateToken(uint _index, address _tokenAddress, bool isLP) external onlyOwner {
        require(_index < 9,"invalid index");
        address previousToken = approvedTokens[_index];
        approvedTokens[_index] = _tokenAddress;
        if(isLP) {
            require(isLPApproved[previousToken],"is not LP token");
            isLPApproved[previousToken] = false;
            isLPApproved[_tokenAddress] = true;
        } else {
            require(isNativeApproved[previousToken],"is not native token");
            isNativeApproved[previousToken] = false;
            isNativeApproved[_tokenAddress] = true;
        }

        emit updateTokens(previousToken , _tokenAddress, msg.sender);
    }

    function failSafe(address _tokenAddress, address _receiver,uint256 _tokenAmount) external onlyOwner {
        safeTransfer(IERC20(_tokenAddress), _receiver, _tokenAmount);
        emit FailSafe(_msgSender(), _receiver, _tokenAmount);
    }

}