/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

    /**
     * @dev Returns the decimals places of the token.
     */
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

contract VictoriaVRVesting {

    using SafeMath for uint256;

    IERC20 public token = IERC20(0x7d5121505149065b562C789A0145eD750e6E8cdD);

    address public owner;

    uint256[] public unlockTimestamps = [1669989600, 1672668000, 1675346400, 1677765600, 1680444000, 1683036000, 1685714400, 1688306400, 1690984800, 1693663200, 1696255200, 1698933600];

    struct UnlockInfo {
        uint256 amount;
        uint256 unlockTotal;
    }

    mapping(address => UnlockInfo) public userUnlockInfos;

    event EventUnlockToken(address indexed _address, uint256 _amount);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You don't have permission."
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addAddressInfos(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
        for (uint i; i < _addresses.length; i++) {
            addAddressInfo(_addresses[i], _amounts[i]);
        }
    }

    function addAddressInfosNoDecimals(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
        for (uint i; i < _addresses.length; i++) {
            addAddressInfoNoDecimals(_addresses[i], _amounts[i]);
        }
    }

    function tokenDecimals(uint256 _amount) public view returns(uint256) {
        return _amount * (10 ** uint256(token.decimals()));
    }

    function tokenBalanceOf() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
    
    function addAddressInfoNoDecimals(address _address, uint256 _amount) public onlyOwner {
        addAddressInfo(_address, tokenDecimals(_amount));
    }

    function addAddressInfo(address _address, uint256 _amount) public onlyOwner {
        UnlockInfo storage ui = userUnlockInfos[_address];
        require(
            ui.amount == 0,
            "This wallet has been added to the unlock contract."
        );
        ui.amount = _amount;
    }

    function deleteAddressInfo(address _address) public onlyOwner {
        UnlockInfo storage ui = userUnlockInfos[_address];
        require(
            ui.amount > 0,
            "This wallet is not in the current unlocking plan."
        );
        delete userUnlockInfos[_address];
    }

    function blockTimestamp() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getAvailableMonth() public virtual view returns(uint256) {
        uint i = 0;
        while (i < unlockTimestamps.length && blockTimestamp() >= unlockTimestamps[i]) i++;
        return i;
    }

    function unlockToken() public {
        uint256 availableMonth = getAvailableMonth();
        require(
            availableMonth > 0,
            "Unlocking time has not started yet."
        );
        UnlockInfo storage ui = userUnlockInfos[msg.sender];
        require(
            ui.amount > 0,
            "This wallet is not in the current unlocking plan."
        );
        require(
            ui.amount > ui.unlockTotal,
            "The user has no available unlocking limit."
        );
        uint256 availableAmount = availableMonth.mul(ui.amount.div(unlockTimestamps.length));
        if(availableAmount > ui.amount) {
            availableAmount = ui.amount;
        }
        availableAmount = availableAmount.sub(ui.unlockTotal);
        require(
            availableAmount > 0,
            "The user has no available unlocking limit."
        );
        ui.unlockTotal = ui.unlockTotal.add(availableAmount);
        _safeTransfer(msg.sender, availableAmount);
    }

    function _safeTransfer(address _address, uint256 _amount) private {
        token.transfer(_address, _amount);
        emit EventUnlockToken(_address, _amount);
    }
}