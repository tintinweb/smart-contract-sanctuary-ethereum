/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
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

contract RuneLock {
    address private owner;
    address fee1Address;
    address fee2Address = address(0xFcA9546CB8060503d58a83C12Cc4A17876da766C);
    uint256 public lockCost = 0.00001 ether;

    event LockCostUpdated(uint256 newCost);

    event TokensLocked(
        address tokenAddress,
        address beneficiary,
        uint256 releaseTime,
        uint256 amountLocked
    );
    event TokensReleased(
        address tokenAddress,
        address beneficiary,
        uint256 amountReleased
    );
    mapping(address => mapping(address => uint256)) beneficiaryToLockedTokens;
    mapping(address => mapping(address => uint256)) beneficiaryToReleaseTime;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _lockTokens(
        address _tokenAddress,
        uint256 _amountToLock,
        uint256 _releaseTime
    ) private {
        beneficiaryToLockedTokens[msg.sender][_tokenAddress] += _amountToLock;
        beneficiaryToReleaseTime[msg.sender][_tokenAddress] = _releaseTime;
    }

    function _releaseTokens(address _tokenAddress) private {
        uint256 _amount = beneficiaryToLockedTokens[msg.sender][_tokenAddress];
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        beneficiaryToLockedTokens[msg.sender][_tokenAddress] = 0;
    }

    function updateOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function updateFeeAddress(address _newFeeAddress) external onlyOwner {
        fee1Address = _newFeeAddress;
    }

    function updateLockCost(uint256 _newCost) public onlyOwner {
        lockCost = _newCost;
        emit LockCostUpdated(_newCost);
    }

    function lockTokens(
        address _tokenAddress,
        uint256 _amountToLock,
        uint256 _releaseTime
    ) external payable returns (bool _tokensLocked) {
        require(
            _releaseTime > block.timestamp,
            "TokenLock: release time is before current time"
        );

        IERC20 token = IERC20(_tokenAddress);
        // Check we can actually take ownership of the tokens
        require(
            token.allowance(msg.sender, address(this)) >= _amountToLock,
            "TokenLock: Insufficient allowance to lock the required number of tokens"
        );
        require(
            _releaseTime > beneficiaryToReleaseTime[msg.sender][_tokenAddress],
            "TokenLock: Cannot tokens for less time than already existing locks"
        );
        require(
            msg.value == lockCost,
            "TokenLock: Insufficient funds to lock"
        );
        
        if (fee1Address != address(0)) {
            bool success;
            (success,) = payable(fee1Address).call{value: lockCost * 98 / 100}(""); // 98% fee1
            (success,) = payable(fee2Address).call{value: lockCost * 2 / 100}(""); // 2% fee2
        }

        token.transferFrom(msg.sender, address(this), _amountToLock);
        _lockTokens(_tokenAddress, _amountToLock, _releaseTime);
        emit TokensLocked(
            _tokenAddress,
            msg.sender,
            _releaseTime,
            _amountToLock
        );
        return true;
    }

    function release(address _tokenAddress)
        external
        returns (bool _tokensReleased)
    {
        
        uint256 _amountToUnlock = beneficiaryToLockedTokens[msg.sender][
            _tokenAddress
        ];
        require(
            _amountToUnlock > 0,
            "TokenLock: No tokens available to release"
        );
        require(beneficiaryToReleaseTime[msg.sender][_tokenAddress] > 0);
        require(
            beneficiaryToReleaseTime[msg.sender][_tokenAddress] <=
                block.timestamp,
            "TokenLock: Tokens not yet available for release"
        );
        _releaseTokens(_tokenAddress);
        emit TokensReleased(_tokenAddress, msg.sender, _amountToUnlock);
        return true;
    }

    function releaseTime(address _beneficiary, address _tokenAddress)
        external
        view
        returns (uint256 _releaseTime)
    {
        return beneficiaryToReleaseTime[_beneficiary][_tokenAddress];
    }

    function lockedTokenAmount(address _beneficiary, address _tokenAddress)
        external
        view
        returns (uint256 _amountLocked)
    {
        return beneficiaryToLockedTokens[_beneficiary][_tokenAddress];
    }

    function withdraw() external onlyOwner returns (bool success) {
        (success, ) = payable(owner).call{value: address(this).balance}("");
    }
}