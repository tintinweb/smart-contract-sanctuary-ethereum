// SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

import "./ISTRTXCREO.sol";
import "./TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StrtVesting {

    struct UserReward {
        uint256 rewardTotal;
        bool tgeStatus;
        uint256 lastRound;
    }
    
    uint256 public tge;

    address public creoToken;
    address public locking; 

    mapping(uint256=>uint256) public linear_dateTime;
    mapping(address=>UserReward) public reward;

    constructor(uint256 _startLinear, uint256 _tge, address _locking, address _creoToken){
        tge = _tge;
        locking = _locking;
        creoToken = _creoToken;
        for(uint256 i = 1; i <= 12; i++){
            if(i == 1){
                linear_dateTime[i] = _startLinear;
            }
            else{
                linear_dateTime[i] = linear_dateTime[i-1] + 5 minutes;
            }
        }
    }

    function linearRound() public view returns(uint256){
        for(uint256 i = 1; i <= 12; i++){
            if(block.timestamp >= linear_dateTime[i] && block.timestamp <= linear_dateTime[i+1] || 
                block.timestamp >= linear_dateTime[i] && i == 12){
                return i;
            }
        }
    }

    function claim() external{
        require(block.timestamp >= tge, "Can't be claimed yet");
        if(reward[msg.sender].rewardTotal == 0){
            reward[msg.sender].rewardTotal = ISTRTXCREO(locking).UserTotalLocks(msg.sender) / 10;
        }

        require(reward[msg.sender].rewardTotal > 0, "Not enough");
        uint256 amount;
        if(!reward[msg.sender].tgeStatus){
            amount = (reward[msg.sender].rewardTotal * 3) / 100;
            reward[msg.sender].tgeStatus = true;
        }

        uint256 round = linearRound();
        if(round > 0){
            amount += (((reward[msg.sender].rewardTotal * 97) / 100) / 12) * (round - reward[msg.sender].lastRound);
            reward[msg.sender].lastRound = round;
        }
        require(amount > 0 && IERC20(creoToken).balanceOf(address(this)) >= amount, "Not enough");
        TransferHelper.safeTransfer(creoToken, msg.sender, amount);

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
interface ISTRTXCREO {
    function UserTotalLocks(address) external view returns(uint256);
}