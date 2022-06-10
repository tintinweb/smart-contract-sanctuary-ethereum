/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
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

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract BlockstarLockupStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 lockupDuration;
        uint returnPer;
        uint256 starttime;
        uint256 endtime;
    }

    struct UserHistory {
        uint256 amount;
        uint256 lockupDuration;
        uint returnPer;
        uint256 starttime;
        uint256 endtime;
    }

    struct PoolInfo {
        uint256 lockupDuration;
        uint returnPer;
    }


    IERC20 public token;
    bool public started = true;
    uint256 public emergencyWithdrawFess = 2500;
     

    mapping(address =>  UserInfo[]) private _userinfo;
    mapping(address =>  UserHistory[]) private _userhistory;
    mapping(uint256 => PoolInfo) public pooldata;
    mapping(address => uint) public rewardEarned;

    uint public totalStake = 0;
    uint public totalWithdrawal = 0;
    uint public totalRewardsDistribution = 0;
    
    constructor(
       address _token,
       bool _started
    ) public {
        token = IERC20(_token);
        started = _started;
    }

    event Deposit(address indexed user, uint256 indexed lockupDuration, uint256 amount , uint returnPer);
    event Withdraw(address indexed user, uint256 amount , uint256 reward , uint256 total );
    event WithdrawAll(address indexed user, uint256 amount);
    
    
    function addPool(uint256 _lockupDuration , uint _returnPer ) external onlyOwner {
        PoolInfo storage pool = pooldata[_lockupDuration];
        pool.lockupDuration = _lockupDuration;
        pool.returnPer = _returnPer;

    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function toggleStaking(bool _start) external onlyOwner {
        started = _start;
    }

    function getUserDeposite(address _userAddress) public view returns (UserInfo[] memory)
    {
        return _userinfo[_userAddress];
    }

    function getUserDepositeHistory(address _userAddress) public view returns (UserHistory[] memory)
    {
        return _userhistory[_userAddress];
    }

    function getUserTotalDepositeAmount(address _userAddress) public view returns (uint)
    {
        UserInfo[] storage userdata = _userinfo[_userAddress];
        uint len = userdata.length;
        uint total = 0;
        for (uint256 i = 0; i < len; i++) {
            total += userdata[i].amount;
        }
        return total;
    }

    
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo[] storage userdata = _userinfo[_user];
        uint len = userdata.length;
        uint256 total = 0;
        for (uint256 i = 0; i < len; i++) {
            if( block.timestamp > userdata[i].endtime && userdata[i].amount > 0 ){
                total += ((userdata[i].amount * userdata[i].returnPer / 10000) / 365) * userdata[i].lockupDuration;
            }
        }
        return total;
    }

    function pendingWithdraw(address _user) external view returns (uint256) {
        UserInfo[] storage userdata = _userinfo[_user];
        uint len = userdata.length;
        uint256 total = 0;
        for (uint256 i = 0; i < len; i++) {
            if( block.timestamp > userdata[i].endtime &&  userdata[i].amount > 0){
                total += userdata[i].amount ;
            }
        }
        return total;
    }

    
    function deposit(uint256 _amount , uint256 _lockupDuration) external {
        require(address(token) != address(0), "Token Not Set Yet");
        require(address(msg.sender) != address(0), "please Enter Valid Adderss");
        require(started == true, "Not Stared yet!");
        require(_amount > 0, "Amount must be greater than Zero!");
        PoolInfo storage pool = pooldata[_lockupDuration];
        
        require(pool.lockupDuration > 0 && pool.returnPer > 0 , "No Pool exist With Locktime !");
        
        token.safeTransferFrom(address(msg.sender), address(this), _amount);
       
        _userinfo[msg.sender].push(
            UserInfo
            (
            _amount,
            _lockupDuration,
            pool.returnPer,
            block.timestamp,
            block.timestamp + (_lockupDuration*86400)
         ));

         _userhistory[msg.sender].push(
            UserHistory
            (
            _amount,
            _lockupDuration,
            pool.returnPer,
            block.timestamp,
            block.timestamp + (_lockupDuration*86400)
         ));

         totalStake += _amount;
        emit Deposit(msg.sender , _lockupDuration , _amount ,pool.returnPer );
    }

   

    function checkAvaliblereward() internal
        view
        returns (bool){
        UserInfo[] storage userdata = _userinfo[msg.sender];
        uint len = userdata.length;
        bool total = false;
        for (uint256 i = 0; i < len; i++) {
            if( block.timestamp > userdata[i].endtime && userdata[i].amount > 0){
                total = true;
            }
        }
        if(total){
            return true;
        }
        else{
            return false;
        }
    }

    function withdraw() external {
        require(address(token) != address(0), "Token Not Set Yet");
        require(address(msg.sender) != address(0), "please Enter Valid Adderss");
        //Need Avlible Balance
        uint256 avalible = totalStake - totalWithdrawal;
        require(token.balanceOf(address(this)) > avalible, "Currently Withdraw not Avalible");
        //Check Is Reward Avalible For Withdraw
        bool avalibleReward = checkAvaliblereward();
        require(avalibleReward, "No Reward Avalible For Withdraw !");
        UserInfo[] storage userdata = _userinfo[msg.sender];
        uint len = userdata.length;
        uint256 withdraw_total = 0;
        uint256 total_reward = 0;
        uint256 total_amount = 0;
        for (uint256 i = 0; i < len; i++) {
            if( block.timestamp > userdata[i].endtime && userdata[i].amount > 0){
                uint256 amount =  userdata[i].amount;
                uint256 reward = ((amount * userdata[i].returnPer / 10000) / 365) * userdata[i].lockupDuration;
                
                uint256 total = amount  +  reward  ;
                
                token.transfer(address(msg.sender) , total);
                delete _userinfo[msg.sender][i];
                total_reward += reward;
                withdraw_total += total;
                total_amount += amount; 
                totalWithdrawal += amount;
                totalRewardsDistribution += reward;
                
            }
        }
        rewardEarned[msg.sender] += total_reward;
      emit Withdraw(msg.sender , total_amount , total_reward , withdraw_total);
    }

    function getNextRewardTime(address _user) external view returns (uint) {

        UserInfo[] storage userdata = _userinfo[_user];
        uint len = userdata.length;
        uint next = 0;

        if(len > 0){
            next = userdata[0].endtime;
        }
        
        for (uint256 i = 0; i < len; i++) {
            if (userdata[i].starttime < block.timestamp && userdata[i].amount > 0 && userdata[i].endtime >=  block.timestamp && userdata[i].endtime < next ) {
                next = userdata[i].endtime;
            }
        }

        return next;
    }


    function emergencyWithdraw() external {
        require(address(token) != address(0), "Token Not Set Yet");
        require(address(msg.sender) != address(0), "please Enter Valid Adderss");
        //Need Avlible Balance
        uint256 avalible = totalStake - totalWithdrawal;
        require(token.balanceOf(address(this)) > avalible, "Currently Withdraw not Avalible");
        //Check Is Reward Avalible For Withdraw
        
        UserInfo[] storage userdata = _userinfo[msg.sender];
        uint len = userdata.length;
        uint256 withdraw_total = 0;
        uint256 total_amount = 0;
        for (uint256 i = 0; i < len; i++) {
            if( userdata[i].amount > 0){
                uint256 fees = (userdata[i].amount * emergencyWithdrawFess) / 10000;
                uint256 amount =  userdata[i].amount;
                uint256 total = amount - fees;
                
                token.transfer(address(msg.sender) , total);
                delete _userinfo[msg.sender][i];
                withdraw_total += total;
                total_amount += amount; 
                totalWithdrawal += total;
            }
        }
      emit WithdrawAll(msg.sender , total_amount);
    } 

    function bnbLiquidity(address payable _reciever, uint256 _amount) public onlyOwner {
        _reciever.transfer(_amount); 
    }

    function transferAnyERC20Token( address payaddress ,address tokenAddress, uint256 tokens ) public onlyOwner 
    {
       IERC20(tokenAddress).transfer(payaddress, tokens);
    }

}