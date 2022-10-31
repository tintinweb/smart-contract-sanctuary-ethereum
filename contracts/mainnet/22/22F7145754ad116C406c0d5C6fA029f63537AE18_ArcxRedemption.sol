// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "../lib/Ownable.sol";
import {IERC20} from "../token/IERC20.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";


contract ArcxRedemption is Ownable {

    using SafeERC20 for IERC20;

    IERC20 public usdcToken;

    IERC20 public arcxToken;

    uint256 public exchangeRate;

    uint256 public cutoffDate;

    event Redemption(
        address indexed _redeemer,
        uint256 _arcxGiven, 
        uint256 _usdcReturned
    );

    event Withdraw(
        address _token, 
        uint256 _amount, 
        address _destination
    );

    constructor(
        address _usdcAddress,
        address _arcxAddress,
        uint256 _exchangeRate,
        uint256 _cutoffDate
    ) 
    {
        usdcToken = IERC20(_usdcAddress);
        arcxToken = IERC20(_arcxAddress);

        exchangeRate = _exchangeRate;
        cutoffDate = _cutoffDate;
    }

    /**
     * @dev Callable by anyone who supplies ARCx up until the cut off date
     * 
     * @param _amount - How many ARCx tokens you'd like to redeem for USDC
     */
    function redeem(
        uint256 _amount
    ) 
        public 
    {
        // Check cut off date has not passed
        require(
            currentTimestamp() <= cutoffDate,
            "The cut off date to redeem has already passed"
        );

        // Transfer ARCx from user to contract
        arcxToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Calculate how much USDC to give using exchange rate
        uint256 usdcToReturn = (_amount * exchangeRate) / (10 ** 18) / (10 ** 12);

        // Send USDC to user
        usdcToken.safeTransfer(
            msg.sender,
            usdcToReturn
        );

        emit Redemption(
            msg.sender,
            _amount,
            usdcToReturn
        );
    }

    /**
     * @dev Should only be callable by the owner to withdraw funds (USDC or ARCx)
     * 
     * @param _token - Specify to remove USDC or ARCx
     * @param _amount - How much of the amount of tokens to remove
     * @param _destination - Where the tokens should be sent to
     */
    function withdraw(
        address _token,
        uint256 _amount,
        address _destination
    ) 
        public 
        onlyOwner
    {
        // Send the specified token to the destination
        IERC20(_token).safeTransfer(
            _destination,
            _amount
        );
    }

    function currentTimestamp()
        public
        virtual
        view
        returns (uint256)
    {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}