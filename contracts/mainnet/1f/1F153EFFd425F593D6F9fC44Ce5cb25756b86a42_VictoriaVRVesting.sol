/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

    uint256 public startUnlockTime = 1654174800;  //2022-06-02 13:00:00 UTC

    uint256 public maxUnlockDay = 3 * 365;

    uint256 public unlockCycle = 1 days;

    uint256 public totalTokenLock = 0;

    struct UnlockInfo {
        bool status;
        uint256 amount;
        uint256 unlockDayAmount;
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

    function initializeDefaultWallet() public onlyOwner {
        addAddressInfo(0x35ea0493e66724fb333180E5cB12cAadFaf96E70, tokenDecimals(915254));
        addAddressInfo(0x395b5010425e814E6dCAfBcF2aA97703cD16CE5a, tokenDecimals(1525424));
        addAddressInfo(0x68e41f435a7b5E64deb5eb2992dAd631d2778516, tokenDecimals(915254));
        addAddressInfo(0x86D55d842c4E08bf30429b4363301A4F7427897b, tokenDecimals(1220339));
        addAddressInfo(0x497a2566F804e36eEc34C3dffF79d66761D9B330, tokenDecimals(1220339));
        addAddressInfo(0x90BBCbe91a042558ed9589ddf9f180E736886FC3, tokenDecimals(1220339));
        addAddressInfo(0x228B858cFEE0EAe28231B6AFFb92eec6feca23a2, tokenDecimals(762712));
        addAddressInfo(0x7694eeC0387d0C63C0483D33F48D7DB5b4077c83, tokenDecimals(1525424));
        addAddressInfo(0x96F89B37334dBA99b867ab812C1bbDf2E2103D23, tokenDecimals(610169));
        addAddressInfo(0xe92D80a90bc050A12F1c6fBE0e50e1B5A874B595, tokenDecimals(1830508));
        addAddressInfo(0x565FF310603E3CE035a8433DE6b54Bf2ED925882, tokenDecimals(762712));
        addAddressInfo(0x181348D19d4c5eDdb9383C34bdc7eAfacA6d127D, tokenDecimals(1830508));
        addAddressInfo(0xBBd6e8B4a644a1a511fd95f6a0e81Db3C03a7E16, tokenDecimals(1372881));
        addAddressInfo(0x31ac5eb1Dfe36C8981BCA66Fe0ab962fFE8E2b13, tokenDecimals(457627));
        addAddressInfo(0x0036d68CCab1677179cD7A5c8c8568Dc7907eAc8, tokenDecimals(305085));
        addAddressInfo(0x5bDdac61eF3549041B58347aC4615434E0898f84, tokenDecimals(610169));
        addAddressInfo(0xd98d95dcA7e33bd5725ef56180bDAEe69877d819, tokenDecimals(1830508));
        addAddressInfo(0xa29B56729C9a2F0bcCbD46eacf7DF7C07D9E2f6E, tokenDecimals(1525424));
        addAddressInfo(0xBA715566ebB933102651465B02e8dBa50B29DD43, tokenDecimals(61017));
        addAddressInfo(0x5b1aBc65B45C035108A17638AaC5eA53a83e9B88, tokenDecimals(15254237));
        addAddressInfo(0x754A2193fe7Ede8e4630063E588cb0Ff5a02Fc28, tokenDecimals(15254237));
        addAddressInfo(0x0Ae21aa1EfC542CF183aD0Ef8CD969bb11040aA8, tokenDecimals(15254237));
        addAddressInfo(0xD35504BA8397a9f9ade45E7F20725F7987415425, tokenDecimals(3050847));
        addAddressInfo(0xA47F5DfB53f617cBCE164f29B26273e9332631C4, tokenDecimals(6101695));
        addAddressInfo(0x65Ac6d86c6bEBBfC84522b4E28861eBF66f6A1bA, tokenDecimals(3050847));
        addAddressInfo(0x41E3FE77DE1EcA115902eB058b1FB57395358d62, tokenDecimals(3050847));
        addAddressInfo(0xb73f8AbC0371b1AB67f9dAAEdb7eCBc1b1dD7e79, tokenDecimals(6711864));
        addAddressInfo(0xA938924AA74Db378d77A1639e76D2cCc2226FB67, tokenDecimals(3050847));
        addAddressInfo(0x40e400325Cff0833bcE814ddAEEF8EC6C6f24963, tokenDecimals(30508475));
        addAddressInfo(0xB1799600bB5DB171760C2a9fF6e9795d46EB700D, tokenDecimals(14338983));
        addAddressInfo(0x70031213C95DeECfa44a6C438BcA25134A292eef, tokenDecimals(9152542));
        addAddressInfo(0x1b75c6DC2C2cff9E6eAF54c5d72b3447740f1e76, tokenDecimals(4423729));
        addAddressInfo(0x505Ffa6194f6e443b86F2028b2a97A588c17b962, tokenDecimals(30508475));
        addAddressInfo(0xc6717341508568AC9Da4821BE8e31ca650c42C79, tokenDecimals(15254237));
        addAddressInfo(0x0aD7A09575e3eC4C109c4FaA3BE7cdafc5a4aDBa, tokenDecimals(173076712));
        addAddressInfo(0x6782Be6D8e69C8790EA6079328DA96B7358093C5, tokenDecimals(17602780));
        addAddressInfo(0x52B40914d9d42e0070CbA75A6879E65022D5B218, tokenDecimals(3050847));
        addAddressInfo(0x86B337Be60C942e80f31e7Be097De1cA821c5f7F, tokenDecimals(15254237));
        addAddressInfo(0xE9090c96795F8936b3bF5c72B23D4A244Cd0Db13, tokenDecimals(22881356));
        addAddressInfo(0xfeD3a086D43B60D97E5CEF9E7C34F2c6BB11d2C7, tokenDecimals(7627119));
        addAddressInfo(0x037B1624848Abfc22552f445475CeBb7e2414F18, tokenDecimals(7627119));
        addAddressInfo(0xE72EB31b59F85b19499A0F3b3260011894FA0d65, tokenDecimals(7627119));
        addAddressInfo(0xd61951E5983646AE63d1236cdd112BBB5E10E159, tokenDecimals(6101695));
        addAddressInfo(0xa0fF757077B5D796259582b2b9Db99c906277007, tokenDecimals(9152542));
        addAddressInfo(0xc11B259aF1B7791Ee1D78b19D35a3Caf1fd90cbD, tokenDecimals(3050847));
        addAddressInfo(0xf6269806D9f8cc48B87167a19dbCF0214026D22D, tokenDecimals(342884746));
        addAddressInfo(0xd999074F947f9813bDD161Fb2452332ac6a4D695, tokenDecimals(7932203));
        addAddressInfo(0x704c7A3d5Cf7289751d2B5e2F129982b854C939d, tokenDecimals(15254237));
        addAddressInfo(0xfb4334A5704e29DF37efc9F16255759670018D9A, tokenDecimals(9152542));
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
        totalTokenLock = totalTokenLock.add(_amount);
        UnlockInfo storage ui = userUnlockInfos[_address];
        require(
            ui.status == false,
            "This wallet has been added to the unlock contract."
        );
        ui.status = true;
        ui.amount = _amount;
        ui.unlockDayAmount = _amount.div(maxUnlockDay);
    }

    function deleteAddressInfo(address _address) public onlyOwner {
        UnlockInfo storage ui = userUnlockInfos[_address];
        require(
            ui.status == true,
            "This wallet is not in the current unlocking plan."
        );
        delete userUnlockInfos[_address];
    }

    function blockTimestamp() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getAvailableDay() public virtual view returns(uint256) {
        require(
            blockTimestamp() > startUnlockTime,
            "Unlocking time has not started yet."
        );
        return blockTimestamp().sub(startUnlockTime).div(unlockCycle);
    }

    function unlockToken() public {
        uint256 availableDay = getAvailableDay();
        require(
            availableDay > 0,
            "Unlocking time has not started yet."
        );
        UnlockInfo storage ui = userUnlockInfos[msg.sender];
        require(
            ui.status == true,
            "This wallet is not in the current unlocking plan."
        );
        require(
            ui.amount > ui.unlockTotal,
            "The user has no available unlocking limit."
        );
        uint256 availableAmount = availableDay.mul(ui.unlockDayAmount);
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
        totalTokenLock = totalTokenLock.sub(_amount);
        emit EventUnlockToken(_address, _amount);
    }
}