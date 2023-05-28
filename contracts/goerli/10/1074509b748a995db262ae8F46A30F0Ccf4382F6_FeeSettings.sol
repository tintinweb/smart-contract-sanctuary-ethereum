// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../lib/ownable/Ownable.sol';
import './IFeeSettings.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract FeeSettings is IFeeSettings, Ownable {
    address _feeAddress;
    uint256 _feePercent = 300; // 0.3%
    uint256 constant _maxFeePercent = 1000; // max fee is 1%
    uint256 _feeEth = 1e16;
    uint256 constant _maxFeeEth = 35e15; // max fixed eth fee is 0.035 eth
    IERC20 immutable gigaToken;

    constructor(address gigaTokenAddress) {
        _feeAddress = msg.sender;
        gigaToken = IERC20(gigaTokenAddress);
    }

    function zeroFeeShare() external view returns (uint256) {
        return gigaToken.totalSupply() / 100;
    }

    function feeAddress() external view returns (address) {
        return _feeAddress;
    }

    function feePercent() external view returns (uint256) {
        return _feePercent;
    }

    function feePercentFor(address account) external view returns (uint256) {
        uint256 balance = gigaToken.balanceOf(account);
        uint256 zeroShare = this.zeroFeeShare();
        if (balance >= zeroShare) return 0;
        uint256 maxFee = this.feePercent();
        return maxFee - (balance * maxFee) / zeroShare;
    }

    function feeDecimals() external pure returns (uint256) {
        return 100000;
    }

    function feeEth() external view returns (uint256) {
        return _feeEth;
    }

    function feeEthFor(address account) external view returns (uint256) {
        uint256 balance = gigaToken.balanceOf(account);
        uint256 zeroShare = this.zeroFeeShare();
        if (balance >= zeroShare) return 0;
        uint256 maxFee = this.feeEth();
        return maxFee - (balance * maxFee) / zeroShare;
    }

    function setFeeAddress(address newFeeAddress) public onlyOwner {
        _feeAddress = newFeeAddress;
    }

    function setFeePercent(uint256 newFeePercent) external onlyOwner {
        require(newFeePercent >= 0 && newFeePercent <= _maxFeePercent);
        _feePercent = newFeePercent;
    }

    function setFeeEth(uint256 newFeeEth) external onlyOwner {
        require(newFeeEth >= 0 && newFeeEth <= _maxFeeEth);
        _feeEth = newFeeEth;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IOwnable.sol';

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IFeeSettings {
    function feeAddress() external view returns (address); // address to pay fee

    function feePercent() external view returns (uint256); // fee in 1/decimals for deviding values

    function feePercentFor(address account) external view returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns (uint256); // fee decimals

    function feeEth() external view returns (uint256); // fee value for not dividing deal points

    function feeEthFor(address account) external view returns (uint256); // fee in 1/decimals for deviding values

    function zeroFeeShare() external view returns (uint256); // if this account balance than zero fee
}

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}