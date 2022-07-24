// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "hardhat/console.sol";

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
   
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(address _address, uint256 amount, address to) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return payable(address(uint160(account)));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:(amount)}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IPool {
    function notifyReward() external payable ;
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
         
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CAPsStakingPool is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 startTime = 0;
    bool firstNotify;

    IERC20 public CAPs;

    constructor(IERC20 CAPs_Address){
        CAPs = CAPs_Address;
    }


    modifier checkStart() {
        require(
            firstNotify,
            "Error : CAPs-Token Staking pool not started yet."
        );
        _;
    }

    uint256 _totalSupply;
    mapping(address => uint256) _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) private {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        CAPs.safeTransferFrom(msg.sender, address(this), amount);
    }


    mapping (address => User) public users;
    mapping (address => bool) public isActiveStakerInPool;
    mapping(address => uint256) public calculatedAmount;
    mapping(address => uint256) public rewardEarned;
    address[] public activeStakers;
    uint256 public _reward;


    struct User {
        mapping(uint => uint) withdrawThreshold; // vault timelock based on betCounter
        mapping(uint => uint) distributedRewardPerBet; // bet wise reward
        mapping(uint => bool) isWithdrawed;
        mapping(uint => uint) amountStaked;   
        uint totalStakedTokensInPool;
        uint totalEligibleWithdrawAmount;
        uint betCounter;
    }



    function Stake(uint _amount) public  returns(uint,bool) {
        require(_amount > 0, "Error : Cannot stake 0");
        stake(_amount);
        isActiveStakerInPool[msg.sender] = true;
        if(checkAddressExistance(msg.sender) == false) activeStakers.push(msg.sender);
        users[msg.sender].totalStakedTokensInPool += _amount;
        users[msg.sender].betCounter += 1;
        users[msg.sender].withdrawThreshold[users[msg.sender].betCounter] = block.timestamp + 600;
        users[msg.sender].amountStaked[users[msg.sender].betCounter] = _amount;    

        distributeReceivedAmount();

        return (_amount,true);
    }


    function checkAddressExistance(address _user) public view returns(bool) {
        for(uint i; i < activeStakers.length; i++) {
            if(_user == activeStakers[i]) {
                return true;
            }
        }
        return false;
    }


    function distributeReceivedAmount() public returns(bool) {
        if(activeStakers.length != 0 && _totalSupply != 0) {
            for(uint i=0; i < activeStakers.length; i++) {
                if(isAddressValid(activeStakers[i]) && balanceOf(activeStakers[i]) != 0) {
                    //console.log(activeStakers[i]);
                    //console.log(uint(((_reward).mul(1e18).div(_totalSupply)).mul((balanceOf(activeStakers[i]).div(1e18)))));
                    calculatedAmount[activeStakers[i]] += uint(((_reward).mul(1e18).div(_totalSupply)).mul((balanceOf(activeStakers[i]).div(1e18))));
                    //console.log(calculatedAmount[activeStakers[i]]);
                    uint bet = users[activeStakers[i]].betCounter;
                    //console.log(bet);
                    users[activeStakers[i]].distributedRewardPerBet[bet] += calculatedAmount[activeStakers[i]];
                    //console.log(users[activeStakers[i]].distributedRewardPerBet[bet]);
                    users[activeStakers[i]].totalEligibleWithdrawAmount += calculatedAmount[activeStakers[i]];
                    //console.log(users[activeStakers[i]].totalEligibleWithdrawAmount);
                    calculatedAmount[activeStakers[i]] = 0;
                }  
                //else console.log("revert");
            }
            _reward = 0;
        }
        else _reward;
        return true;
    }


    function isAddressValid(address _user) public view returns(bool) {
        bool status_;
        if(isActiveStakerInPool[_user]) {
            status_ = true;
        }

        return status_;
    }


    function countEligibleAddresses() public view returns(uint) {
        uint eligibleAddress;
        for(uint i; i < activeStakers.length; i++) {
            if(isActiveStakerInPool[activeStakers[i]]) {
                eligibleAddress += 1;
            }
        }

        return eligibleAddress;
    }



    function calculateWithdrawalAmount(address _user) public view returns(uint) {
        uint counter = users[_user].betCounter;
        uint amount;
        for(uint i=1; i <= counter; i++) {
            //console.log(i);
            if(users[_user].withdrawThreshold[i] <= block.timestamp) {
                //console.log(users[_user].distributedRewardPerBet[i]);
                amount += users[_user].distributedRewardPerBet[i];
                //console.log(amount);
            }
            //else console.log("ok");
        }

        return amount;
    }


    function checkEarnedAmount(address _user) public view returns(uint) {
        uint counter = users[_user].betCounter;
        uint amount;
        for(uint i=1; i <= counter; i++) {
            amount += users[_user].distributedRewardPerBet[i];
        }
        return amount;
    }



    function eligibleTokenstoBurn(address _user) public view returns(uint) {    
        uint counter = users[_user].betCounter;
        uint tokenAmount;

        for(uint i=1; i <= counter; i++) {
            if(users[_user].withdrawThreshold[i] <= block.timestamp) {
                tokenAmount += users[_user].amountStaked[i];
            }
        }
        return tokenAmount;
    }

    
    
    function claimCAPs() public returns(uint) {                   // Allows users to claim rewards
        require(eligibleTokenstoBurn(msg.sender) != 0, "You are not eligible to claim!");
        rewardEarned[msg.sender] += calculateWithdrawalAmount(msg.sender);

        uint256 amount = eligibleTokenstoBurn(msg.sender);
        CAPs.burn(address(this), amount, address(0));                  // burns the claimed tokens
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        uint counter = users[msg.sender].betCounter;
        for(uint i=1; i <= counter; i++) {
            if(users[msg.sender].withdrawThreshold[i] <= block.timestamp) {
                users[msg.sender].amountStaked[i] = 0;
                users[msg.sender].distributedRewardPerBet[i] = 0;    
            }
        }
        return(calculateWithdrawalAmount(msg.sender));
    }




    function withdrawAmount(uint _amount) public {       // Allows users to withdraw rewards
        require(_amount <= rewardEarned[msg.sender],"Withdrawal amount is more than earned!");
        payable(address(msg.sender)).transfer(_amount); 
        rewardEarned[msg.sender] -= _amount;       
    }



    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function notifyReward() external payable {           // gets rewards from betting contract and starts the pool
        _reward += msg.value;

        if (_reward > 0) {
            startTime = block.timestamp;
            firstNotify = true; 
        }
        distributeReceivedAmount();
        
    }

}