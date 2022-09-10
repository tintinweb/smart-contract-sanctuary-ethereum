/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *  @dev Contract module which provides a basic access control mechanism, where
 *  there is an account (an owner) that can be granted exclusive access to
 *  specific functions.
 *
 *  By default, the owner account will be the one that deploys the contract. This
 *  can later be changed with {transferOwnership}.
 *
 *  This module is used through inheritance. It will make available the modifier
 *  `onlyOwner`, which can be applied to your functions to restrict their use to
 *  the owner.
 */

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 *  @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
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
    function approve(address spender, uint256 amount) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract IDO is Ownable {
    address public token;
    uint256 public tokenDecimal;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public tokenRate;

    uint256 public soldAmount;
    uint256 public totalRaise;
    uint256 public totalRewardTokens;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokenRate,
        uint256 _totalRewardTokens
    ) {
        require(IERC20(_token).decimals() > 0);
        require(_startTime < _endTime);
        require(_tokenRate > 0);
        require(_totalRewardTokens > 0);

        token = _token;
        tokenDecimal = IERC20(_token).decimals();

        startTime = _startTime;
        endTime = _endTime;
        tokenRate = _tokenRate;
        totalRewardTokens = _totalRewardTokens;
    }

    function isActive() public view returns (bool) {
        return startTime <= block.timestamp && block.timestamp <= endTime;
    }

    function getTokenInETH(uint256 _tokens) public view returns (uint256) {
        uint256 _tokenDecimal = 10**tokenDecimal;
        return (_tokens * tokenRate) / _tokenDecimal;
    }

    function calculateAmount(uint256 _acceptedAmount)
        public
        view
        returns (uint256)
    {
        uint256 _tokenDecimal = 10**tokenDecimal;
        return (_acceptedAmount * _tokenDecimal) / tokenRate;
    }

    function getRemainingReward() public view returns (uint256) {
        return totalRewardTokens - soldAmount;
    }

    function buyTokens() external payable {
        address payable _senderAddress = _msgSender();
        uint256 _acceptedAmount = msg.value;

        require(isActive(), "Sale is not Active");
        require(_acceptedAmount > 0, "Accepted amount is zero");

        uint256 _rewardedAmount = calculateAmount(_acceptedAmount);
        uint256 _unsoldTokens = getRemainingReward();

        if (_rewardedAmount > _unsoldTokens) {
            _rewardedAmount = _unsoldTokens;

            uint256 _excessAmount = _acceptedAmount -
                getTokenInETH(_unsoldTokens);
            _senderAddress.transfer(_excessAmount);
        }

        require(_rewardedAmount > 0, "Zero rewarded amount");

        IERC20(token).transfer(_senderAddress, _rewardedAmount);

        soldAmount = soldAmount + _rewardedAmount;
        totalRaise = totalRaise + getTokenInETH(_rewardedAmount);
    }

    function withdrawETHBalance() external onlyOwner {
        address payable _sender = _msgSender();

        uint256 _balance = address(this).balance;
        _sender.transfer(_balance);
    }

    function withdrawRemainingTokens() external onlyOwner {
        require(!isActive(), "Token SALE still active.");

        address payable _sender = _msgSender();
        uint256 _remainingAmount = getRemainingReward();

        IERC20(token).transfer(_sender, _remainingAmount);
    }
}