/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


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

    function RoundDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 a = x / 100;
        uint256 b = x % 100;
        uint256 c = y / 100;
        uint256 d = y % 100;

        return a * c * 100 + a * d + b * c + (b * d) / 100;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface SBToken {
    function excludeFromFee(address account) external;
    function includeInFee(address account) external;
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
 
contract TokenVesting is Ownable {
    using SafeMath for uint256;

    // Token address
    SBToken _token;

    // Crowdsale Address
    address private _operator;

    // Total amount of locked tokens
    mapping(address => uint256) private _totalAllocation;

    // Total amount of tokens have been released
    mapping(address => uint256) private _releasedAmount;

    // Lock duration (in seconds) of each phase
    uint32[] private _lockDurations;

    // Release percent of each phase
    uint32[] private _releasePercents;

    // Start date of the lockup period
    uint64 private _startTime;

    address[] private _beneficiaries;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);   
    event Released(address indexed beneficiary, uint256 releasableAmount);

    modifier onlyOperatorOrOwner() {
        require(_operator == msg.sender || owner() == msg.sender, "operator: caller is not the operator or owner");
        _;
    }
    
    constructor(
        address token_,
        uint32[] memory lockDurations_,
        uint32[] memory releasePercents_
    ) {
        require(lockDurations_.length == releasePercents_.length, "Unlock length does not match");

        uint256 _sum;
        for (uint256 i = 0; i < releasePercents_.length; ++i) {
            _sum += releasePercents_[i];
        }

        require(_sum == 100, "Total unlock percent is not equal to 100");

        require(address(token_) != address(0), "Token address cannot be the zero address");

        _token = SBToken(token_);
        _lockDurations = lockDurations_;
        _releasePercents = releasePercents_;
        
    }

    function token() public view virtual returns (SBToken) {
        return _token;
    }

    function lockDurations() public view virtual returns (uint32[] memory) {
        return _lockDurations;
    }

    function releasePercents() public view virtual returns (uint32[] memory) {
        return _releasePercents;
    }

    function startTime() public view virtual returns (uint64) {
        return _startTime;
    }

    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */

    function transferOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "transferOperator: new operator is the zero address");
        require(newOperator != _operator, "transferOperator: new operator is the zero address");

        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;
    }

    function setStartTime(uint64 startTime_) external onlyOwner {
        require(_startTime == 0 || block.timestamp < _startTime, "TokenVesting: start time cannot be modified once reached");
        _startTime = startTime_;
    }

    function addTokensToVesting(address beneficiary, uint256 amount) external onlyOperatorOrOwner {
        require(_startTime > 0, "TokenVesting: start time not set");
        if (_totalAllocation[beneficiary] == 0) {
            _beneficiaries.push(beneficiary);
        }
        _totalAllocation[beneficiary] = _totalAllocation[beneficiary].add(amount);

        _token.excludeFromFee(msg.sender);

        if (_lockDurations[0] == 0) {
            uint256 firstReleaseAmount = amount.mul(_releasePercents[0]).div(100);
            IERC20(address(_token)).transfer(beneficiary, firstReleaseAmount);
            _releasedAmount[beneficiary] = _releasedAmount[beneficiary].add(firstReleaseAmount);
            emit Released(beneficiary, firstReleaseAmount);
        }

        _token.includeInFee(msg.sender);
    }


    /// @notice Release unlocked tokens to user.
    /// @dev User (sender) can release unlocked tokens by calling this function.
    /// This function will release locked tokens from multiple lock phases that meets unlock requirements
    function release() public virtual returns (bool) {

        _token.excludeFromFee(msg.sender);
    
        uint256 phases = _lockDurations.length;
        _preValidateRelease(phases);

        uint256 releasableAmount = _releasableAmount(msg.sender, phases);

        _releasedAmount[msg.sender] = _releasedAmount[msg.sender].add(releasableAmount);
        IERC20(address(_token)).transfer(msg.sender, releasableAmount);

        if (msg.sender != owner()){

        _token.includeInFee(msg.sender);
        }

        emit Released(msg.sender, releasableAmount);

        return true;
    }

    function releaseAll() external onlyOwner {
        _token.excludeFromFee(msg.sender);
        uint256 totalFunds = IERC20(address(_token)).balanceOf(address(this));
        uint256 totalAllocatedTokens = 0;

        // Calculate the total amount of tokens that were allocated to users
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            totalAllocatedTokens = totalAllocatedTokens.add(_totalAllocation[_beneficiaries[i]]);
        }

        require(totalFunds >= totalAllocatedTokens, "Not enough funds to distribute");

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            uint256 beneficiaryShare = _totalAllocation[beneficiary];
            uint256 amountToDistribute = totalFunds.mul(beneficiaryShare).div(totalAllocatedTokens);

            // Release tokens
            IERC20(address(_token)).transfer(beneficiary, amountToDistribute);
            emit Released(beneficiary, amountToDistribute);
            _token.includeInFee(msg.sender);
        }
    }


    function _preValidateRelease(uint256 phases) internal view virtual {
        require(_startTime != 0, "TokenVesting: start time not set");
        require(_totalAllocation[msg.sender] > 0, "TokenVesting: no tokens allocated");
        require(block.timestamp >= _startTime + _lockDurations[0] * 1 seconds, "TokenVesting: current time is before release time");
        require(_releasedAmount[msg.sender] < _totalAllocation[msg.sender], "TokenVesting: all tokens have already been released");
    }

    function _releasableAmount(address beneficiary, uint256 phases) internal view virtual returns (uint256) {
        uint256 releasableAmount = 0;

        for (uint256 i = 0; i < phases; i++) {
            uint64 releaseTime = _startTime + uint64(_lockDurations[i] * 1 seconds);

            if (block.timestamp >= releaseTime) {
                uint256 stepReleaseAmount = _totalAllocation[beneficiary].mul(_releasePercents[i]).div(100);
                releasableAmount = releasableAmount.add(stepReleaseAmount);
            }
        }

        uint256 alreadyReleased = _releasedAmount[beneficiary];
        return releasableAmount.sub(alreadyReleased);
    }
}