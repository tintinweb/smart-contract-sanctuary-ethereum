// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Dependencies/ICollateralToken.sol";
import "../Dependencies/ICollateralTokenOracle.sol";

interface IEbtcInternalPool {
    function receiveColl(uint _value) external;
}

// based on WETH9 contract
contract CollateralTokenTester is ICollateralToken, ICollateralTokenOracle {
    string public override name = "Collateral Token Tester in eBTC";
    string public override symbol = "CollTester";
    uint8 public override decimals = 18;

    event Transfer(address indexed src, address indexed dst, uint wad, uint _share);
    event Deposit(address indexed dst, uint wad, uint _share);
    event Withdrawal(address indexed src, uint wad, uint _share);

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) public override allowance;

    uint private _ethPerShare = 1e18;
    uint private _totalBalance;

    uint private epochsPerFrame = 225;
    uint private slotsPerEpoch = 32;
    uint private secondsPerSlot = 12;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        uint _share = getSharesByPooledEth(msg.value);
        balances[msg.sender] += _share;
        _totalBalance += _share;
        emit Deposit(msg.sender, msg.value, _share);
    }

    /// @dev Deposit collateral without ether for testing purposes
    function forceDeposit(uint ethToDeposit) external {
        uint _share = getSharesByPooledEth(ethToDeposit);
        balances[msg.sender] += _share;
        _totalBalance += _share;
        emit Deposit(msg.sender, ethToDeposit, _share);
    }

    function withdraw(uint wad) public {
        uint _share = getSharesByPooledEth(wad);
        require(balances[msg.sender] >= _share);
        balances[msg.sender] -= _share;
        _totalBalance -= _share;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad, _share);
    }

    function totalSupply() public view override returns (uint) {
        return _totalBalance;
    }

    // helper to set allowance in test
    function nonStandardSetApproval(address owner, address guy, uint wad) external returns (bool) {
        allowance[owner][guy] = wad;
        emit Approval(owner, guy, wad);
        return true;
    }

    function receiveCollToInternalPool(address _pool, uint _value) external {
        IEbtcInternalPool(_pool).receiveColl(_value);
    }

    function approve(address guy, uint wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public override returns (bool) {
        uint _share = getSharesByPooledEth(wad);
        require(balances[src] >= _share, "ERC20: transfer amount exceeds balance");

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balances[src] -= _share;
        balances[dst] += _share;

        emit Transfer(src, dst, wad, _share);

        return true;
    }

    // tests should adjust the ratio by this function
    function setEthPerShare(uint _ePerS) external {
        _ethPerShare = _ePerS;
    }

    function getSharesByPooledEth(uint256 _ethAmount) public view override returns (uint256) {
        uint _tmp = _mul(1e18, _ethAmount);
        return _div(_tmp, _ethPerShare);
    }

    function getPooledEthByShares(uint256 _sharesAmount) public view override returns (uint256) {
        uint _tmp = _mul(_ethPerShare, _sharesAmount);
        return _div(_tmp, 1e18);
    }

    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) public override returns (uint256) {
        uint _tknAmt = getPooledEthByShares(_sharesAmount);
        transfer(_recipient, _tknAmt);
        return _tknAmt;
    }

    function sharesOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    function getOracle() external view override returns (address) {
        return address(this);
    }

    function getBeaconSpec() public view override returns (uint64, uint64, uint64, uint64) {
        return (
            uint64(epochsPerFrame),
            uint64(slotsPerEpoch),
            uint64(secondsPerSlot),
            uint64(block.timestamp)
        );
    }

    function setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot
    ) external {
        epochsPerFrame = _epochsPerFrame;
        slotsPerEpoch = _slotsPerEpoch;
        secondsPerSlot = _secondsPerSlot;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external override returns (bool) {
        approve(spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    function balanceOf(address _usr) external view override returns (uint256) {
        uint _tmp = _mul(_ethPerShare, balances[_usr]);
        return _div(_tmp, 1e18);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external override returns (bool) {
        approve(spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    // internal helper functions
    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function _div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: zero denominator");
        uint256 c = a / b;
        return c;
    }

    // dummy test purpose
    function feeRecipientAddress() external view returns (address) {
        return address(this);
    }

    function authority() external view returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralToken is IERC20 {
    // Returns the amount of shares that corresponds to _ethAmount protocol-controlled Ether
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    // Returns the amount of Ether that corresponds to _sharesAmount token shares
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    // Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.
    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);

    // Returns the amount of shares owned by _account
    function sharesOf(address _account) external view returns (uint256);

    // Returns authorized oracle address
    function getOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralTokenOracle {
    // Return beacon specification data.
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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