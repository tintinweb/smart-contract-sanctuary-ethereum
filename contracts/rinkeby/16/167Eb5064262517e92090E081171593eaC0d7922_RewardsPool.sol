// SPDX-License-Identifier: NONE
pragma solidity 0.8.7;


interface IERC20 {

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value
    );

    function transfer(
        address recipient, 
        uint256 amount
    ) external returns (bool);
    function approve(
        address spender, 
        uint256 amount
    ) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(
        address account
    ) external view returns (uint256);
    function allowance(
        address owner, 
        address spender
    ) external view returns (uint256);

}


library Address {

    function sendValue(
        address payable recipient, 
        uint256 amount
    ) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target, 
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(
        address target, 
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    function functionStaticCall(
        address target, 
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function isContract(
        address account
    ) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}


library SafeERC20 {

    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function _callOptionalReturn(
        IERC20 token, 
        bytes memory data
    ) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }

}


contract RewardsPool {

    using SafeERC20 for IERC20;

    struct Reward {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    IERC20 public rewardToken;
    address public dinoPool;
    address public owner;
    uint256 public vestingPeriod = 600;

    mapping(address => Reward[]) public userClaimedRewards;

    event RewardsWithdrawn(address _receiver, uint256 _withdrawnId);

    constructor() {
        owner = msg.sender;
    }

    function setContractAddresses(
        address _dinoPool, 
        address _rewardToken
    ) external {
        require(msg.sender == owner, "Access Denied!");
        dinoPool = _dinoPool;
        rewardToken = IERC20(_rewardToken);
    }

    // Takes seconds as input for vesting period and changes the vesting period
    function setVestingPeriod(
        uint256 _vestingPeriod
    ) external {
        require(
            msg.sender == owner,
            "Access denied, only contract has access!"
        );
        vestingPeriod = _vestingPeriod;
    }

    // Utility function to change contract owner
    function changeContractOwner(
        address newOwner
    ) external {
        require(msg.sender == owner, "Caller is not contract owner!");
        require(newOwner != address(0), "Invalid address!");
        owner = newOwner;
    }

    // Rewards gets added here which needs to go through vesting period
    function addReward(
        address _receiver, 
        uint256 _amount
    ) external {
        require(msg.sender == dinoPool, "Access Denied!");
        userClaimedRewards[_receiver].push(
            Reward({
                amount: _amount,
                startTime: uint64(block.timestamp),
                endTime: uint64(block.timestamp) + uint64(vestingPeriod)
            })
        );
    }

    // Withdraws rewards and transfers to receiver wallet after vesting period ends
    function withdraw(
        address _receiver, 
        uint256 _withdrawId
    ) external {
        Reward[] storage rewardList = userClaimedRewards[_receiver];
        require(_withdrawId < rewardList.length, "Invalid withdraw id!");
        Reward memory data = rewardList[_withdrawId];
        require(block.timestamp >= data.endTime, "Withdrawing too soon!");
        rewardList[_withdrawId] = rewardList[rewardList.length - 1];
        rewardList.pop();
        rewardToken.safeTransfer(_receiver, data.amount);
        emit RewardsWithdrawn(_receiver, _withdrawId);
    }

    // Returns list of rewards of an address
    function getUserRewardsList(
        address _receiver
    ) public view returns (Reward[] memory) {
        return userClaimedRewards[_receiver];
    }

}