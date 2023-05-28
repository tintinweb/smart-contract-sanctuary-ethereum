// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// WARNING!!!
// Should not be used in any production environment
// This contract is meant to mock Lido Finance and StETH
// Developed exclusively for ZeroLiquid Testnet

contract StETH is IERC20 {
    mapping(address => uint256) private shares;
    mapping(address => mapping(address => uint256)) private allowances;

    uint256 private _totalShares;

    // track total deposits, actual eth will be transferred to the swap contract to ensure sufficient liquidity
    uint256 private _totalDeposit;

    // reward will update with each deposit, rate is fixed at 4500% apy
    uint256 private _dynamicReward;
    uint256 private _lastRewardTimestamp;

    address public admin;
    // address payable public swapContract;

    event TransferShares(address indexed from, address indexed to, uint256 sharesValue);
    event SharesBurnt(
        address indexed account, uint256 preRebaseTokenAmount, uint256 postRebaseTokenAmount, uint256 sharesAmount
    );
    event Submitted(address indexed sender, uint256 amount, address referral);

    constructor() {
        admin = msg.sender;
    }

    // function updateSwapContract(address payable _swapContract) external {
    //     require(admin == msg.sender, "NOT_ADMIN");
    //     swapContract = _swapContract;
    // }

    function name() public pure returns (string memory) {
        return "Liquid staked Ether 2.0";
    }

    function symbol() public pure returns (string memory) {
        return "stETH";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _getTotalPooledEther();
    }

    function getTotalPooledEther() public view returns (uint256) {
        return _getTotalPooledEther();
    }

    function balanceOf(address _account) public view returns (uint256) {
        return getPooledEthByShares(_sharesOf(_account));
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance - _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO");
        _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        return true;
    }

    function getTotalShares() public view returns (uint256) {
        return _getTotalShares();
    }

    function sharesOf(address _account) public view returns (uint256) {
        return _sharesOf(_account);
    }

    function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {
        uint256 totalPooledEther = _getTotalPooledEther();
        if (totalPooledEther == 0) {
            return 0;
        } else {
            return _ethAmount * _getTotalShares() / totalPooledEther;
        }
    }

    function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        uint256 totalShares = _getTotalShares();
        if (totalShares == 0) {
            return 0;
        } else {
            return _sharesAmount * _getTotalPooledEther() / totalShares;
        }
    }

    function transferShares(address _recipient, uint256 _sharesAmount) public returns (uint256) {
        _transferShares(msg.sender, _recipient, _sharesAmount);
        emit TransferShares(msg.sender, _recipient, _sharesAmount);
        uint256 tokensAmount = getPooledEthByShares(_sharesAmount);
        emit Transfer(msg.sender, _recipient, tokensAmount);
        return tokensAmount;
    }

    function _calcRewards() internal view returns (uint256) {
        return (block.timestamp - _lastRewardTimestamp) * 30 * _totalDeposit / 31_536_000;
    }

    // need to track rewards with each deposit to avoid reward calculations on new balance from initial time
    function _accumRewards() internal {
        _dynamicReward += _calcRewards();

        _lastRewardTimestamp = block.timestamp;
    }

    function _getTotalPooledEther() internal view returns (uint256) {
        return _totalDeposit + _dynamicReward + _calcRewards();
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        uint256 _sharesToTransfer = getSharesByPooledEth(_amount);
        _transferShares(_sender, _recipient, _sharesToTransfer);
        emit Transfer(_sender, _recipient, _amount);
        emit TransferShares(_sender, _recipient, _sharesToTransfer);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _getTotalShares() internal view returns (uint256) {
        return _totalShares;
    }

    function _sharesOf(address _account) internal view returns (uint256) {
        return shares[_account];
    }

    function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal {
        require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

        uint256 currentSenderShares = shares[_sender];
        require(_sharesAmount <= currentSenderShares, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");

        shares[_sender] = currentSenderShares - _sharesAmount;
        shares[_recipient] += _sharesAmount;
    }

    function _mintShares(address _recipient, uint256 _sharesAmount) internal returns (uint256) {
        require(_recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");

        _totalShares += _sharesAmount;

        shares[_recipient] += _sharesAmount;

        return _totalShares;
    }

    function _burnShares(address _account, uint256 _sharesAmount) internal returns (uint256) {
        require(_account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");

        uint256 accountShares = shares[_account];
        require(_sharesAmount <= accountShares, "BURN_AMOUNT_EXCEEDS_BALANCE");

        uint256 preRebaseTokenAmount = getPooledEthByShares(_sharesAmount);

        _totalShares -= _sharesAmount;

        shares[_account] = accountShares - _sharesAmount;

        uint256 postRebaseTokenAmount = getPooledEthByShares(_sharesAmount);

        emit SharesBurnt(_account, preRebaseTokenAmount, postRebaseTokenAmount, _sharesAmount);

        return _totalShares;
    }

    function submit(address _referral) external payable returns (uint256) {
        return _submit(_referral);
    }

    function _submit(address _referral) internal returns (uint256) {
        require(msg.value != 0, "ZERO_DEPOSIT");

        uint256 sharesAmount = getSharesByPooledEth(msg.value);
        if (sharesAmount == 0) {
            sharesAmount = msg.value;
        }

        _accumRewards();
        _mintShares(msg.sender, sharesAmount);
        _totalDeposit += msg.value;

        // swapContract.transfer(msg.value);

        emit Submitted(msg.sender, msg.value, _referral);

        emit TransferShares(address(0), msg.sender, sharesAmount);

        return sharesAmount;
    }
}