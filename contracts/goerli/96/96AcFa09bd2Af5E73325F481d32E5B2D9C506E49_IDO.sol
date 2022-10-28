pragma solidity 0.6.12;

import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";

contract IDO {
    using SafeMath for uint256;

    address public immutable usdt;
    address public plexus;
    address public dev;
    uint256 public idoStartTime;
    uint256 public idoEndTime;
    uint256 public idoStartTimeP2;
    uint256 public idoEndTimeP2;
    uint256 public lockupBlock;
    uint256 public claimDuringBlock;
    uint256 public plexusTotalValue;
    uint256 public plexusTotalValueP2;

    uint256 public usdtHardCap; // 플랙서스 최대 모금액 300000
    uint256 public usdtSoftCap; // 플랙서스 최소 모금액 50000
    uint256 public userHardCap; // 한 유저가 살수있는 최대 금액 50000
    uint256 public userSoftCap; // 한 유저가 한번에 살수있는 최소 금액  500

    
    uint256 public usdtHardCapP2;
    uint256 public usdtSoftCapP2;
    uint256 public userHardCapP2;
    uint256 public userSoftCapP2;
    uint256 public usdtTotalReciveAmount;
    uint256 public usdtTotalReciveAmountP2;
    address[] public userAddress;
    address[] public userAddressP2;
    uint256 public USDT_ACC_PRECESION = 1e6;
    uint256 public PLX_ACC_PRECESION = 1e18;
    struct UserInfo {
        uint256 amount;
        uint256 amountP2;
        uint256 totalReward;
        uint256 lastRewardBlock;
        uint256 recivePLX;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public userId;
    mapping(address => uint256) public userIdP2;
    event Deposit(address user, uint256 userDepositAmount, uint256 userPLXTotalReward);
    event Claim(address user, uint256 userClaimAmount, uint256 userRecivePLX);

    constructor(address _usdt, address _plexus) public {
        // mainnet ERC20 usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
        usdt = _usdt;
        plexus = _plexus;
        // claim During 3month ( 3 * 30 * 24 * 60 * 4) = 518400
        claimDuringBlock = 100;
        dev = msg.sender;
    }

    function init(
        uint256 _plxTotalValue, // 5000000
        uint256 _usdtHardCap,   // 300000
        uint256 _usdtSoftCap,   // 50000
        uint256 _userHardCap,   // 50000
        uint256 _userSoftCap    // 500 // 유저가 한번에 넣어야하는 최소 금액. 
    ) public {
        require(msg.sender == dev);
        plexusTotalValue = _plxTotalValue;
        usdtHardCap = _usdtHardCap;
        usdtSoftCap = _usdtSoftCap;
        userHardCap = _userHardCap;
        userSoftCap = _userSoftCap;
        IERC20(plexus).transferFrom(msg.sender, address(this), plexusTotalValue);
    }

    function initP2(
        uint256 _plxTotalValueP2,
        uint256 _usdtHardCapP2,
        uint256 _usdtSoftCapP2,
        uint256 _userHardCapP2,
        uint256 _userSoftCapP2
    ) public {
        require(msg.sender == dev);
        plexusTotalValueP2 = _plxTotalValueP2;
        usdtHardCapP2 = _usdtHardCapP2;
        usdtSoftCapP2 = _usdtSoftCapP2;
        userHardCapP2 = _userHardCapP2;
        userSoftCapP2 = _userSoftCapP2;
        IERC20(plexus).transferFrom(msg.sender, address(this), plexusTotalValueP2);
    }

    function userLength() public view returns (uint256 user) {
        return userAddress.length;
    }

    function userP2Length() public view returns (uint256 user) {
        return userAddressP2.length;
    }

    function deposit(uint256 _userDepositAmount) public {
        require(block.timestamp >= idoStartTime && block.timestamp <= idoEndTime, "PLEXUS : This is not IDO time.");
        require(IERC20(usdt).balanceOf(msg.sender) >= _userDepositAmount, "PLEXUS : Insufficient amount.");

        require(
            _userDepositAmount >= userSoftCap && _userDepositAmount <= userHardCap,
            "PLEXUS : The amount is less than softcap. or The amount exceeds your personal hardcap. "
        );

        uint256 price = (usdtHardCap / (plexusTotalValue / PLX_ACC_PRECESION));
        //  (usdtHardCap / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) / (plexusTotalValue / PLX_ACC_PRECESION)
        uint256 userDepositAmountInt = (_userDepositAmount / price) * price;

        require(
            usdtHardCap.sub(usdtTotalReciveAmount).sub(userDepositAmountInt) >= 0,
            "PLEXUS : The deposit amount exceeds the hardcap."
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), userDepositAmountInt);
        if (userAddress.length == 0 || (userId[msg.sender] == 0 && userAddress[0] != msg.sender)) {
            userAddress.push(msg.sender);
            userId[msg.sender] = userAddress.length - 1;
        }
        UserInfo memory user = userInfo[msg.sender];
        user.amount += userDepositAmountInt;

        require(user.amount <= userHardCap, "PLEXUS : The deposit amount exceeds the hardcap.");

        usdtTotalReciveAmount += userDepositAmountInt;
        user.totalReward += (userDepositAmountInt)
            .div((usdtHardCap / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) / (plexusTotalValue / PLX_ACC_PRECESION))
            .mul(PLX_ACC_PRECESION);
        userInfo[msg.sender] = user;

        emit Deposit(msg.sender, user.amount, user.totalReward);
    }

    function depositP2(uint256 _userDepositAmount) public {
        require(block.timestamp >= idoStartTimeP2 && block.timestamp <= idoEndTimeP2, "PLEXUS : This is not IDO time.");
        require(IERC20(usdt).balanceOf(msg.sender) >= _userDepositAmount, "PLEXUS : Insufficient amount.");
        require(
            usdtHardCapP2.sub(usdtTotalReciveAmountP2) >= _userDepositAmount,
            "PLEXUS : The deposit amount exceeds the hardcap."
        );
        require(
            _userDepositAmount >= userSoftCapP2 && _userDepositAmount <= userHardCapP2,
            "PLEXUS : The amount is less than softcap. or The amount exceeds your personal hardcap. "
        );
        uint256 price = (usdtHardCapP2 / (plexusTotalValueP2 / PLX_ACC_PRECESION));
        //  (usdtHardCap / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) / (plexusTotalValue / PLX_ACC_PRECESION)
        uint256 userDepositAmountInt = (_userDepositAmount / price) * price;

        require(
            usdtHardCapP2.sub(usdtTotalReciveAmountP2).sub(userDepositAmountInt) >= 0,
            "PLEXUS : The deposit amount exceeds the hardcap."
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), userDepositAmountInt);
        if (userAddressP2.length == 0 || (userIdP2[msg.sender] == 0 && userAddressP2[0] != msg.sender)) {
            userAddressP2.push(msg.sender);
            userIdP2[msg.sender] = userAddressP2.length - 1;
        }
        UserInfo memory user = userInfo[msg.sender];
        user.amountP2 += userDepositAmountInt;

        require(user.amountP2 <= usdtHardCapP2);
        usdtTotalReciveAmountP2 += userDepositAmountInt;
        user.totalReward += (userDepositAmountInt)
            .div(
                (usdtHardCapP2 / USDT_ACC_PRECESION).mul(USDT_ACC_PRECESION) / (plexusTotalValueP2 / PLX_ACC_PRECESION)
            )
            .mul(PLX_ACC_PRECESION);
        userInfo[msg.sender] = user;

        emit Deposit(msg.sender, user.amountP2, user.totalReward);
    }

    function pendingClaim(address _user) public view returns (uint256 pendingAmount) {
        UserInfo memory user = userInfo[_user];
        if (block.number > lockupBlock && lockupBlock != 0) {
            uint256 claimBlock;
            if (block.number > lockupBlock.add(claimDuringBlock)) {
                if (user.lastRewardBlock <= lockupBlock.add(claimDuringBlock)) {
                    pendingAmount = user.totalReward.sub(user.recivePLX);
                } else pendingAmount = 0;
            } else {
                claimBlock = block.number.sub(user.lastRewardBlock);
                uint256 perBlock = (user.totalReward.mul(PLX_ACC_PRECESION)) / claimDuringBlock;
                pendingAmount = claimBlock.mul(perBlock) / PLX_ACC_PRECESION;
            }
        } else pendingAmount = 0;
    }

    function claim(address _user) public {
        require(block.number >= lockupBlock && lockupBlock != 0, "PLEXUS : lockupBlock not set.");
        if (userInfo[_user].lastRewardBlock < lockupBlock) {
            userInfo[_user].lastRewardBlock = lockupBlock;
        }
        UserInfo memory user = userInfo[_user];

        uint256 claimAmount = pendingClaim(_user);
        require(claimAmount != 0, "PLEXUS : There is no claimable amount.");
        if (IERC20(plexus).balanceOf(address(this)) <= claimAmount) {
            claimAmount = IERC20(plexus).balanceOf(address(this));
        }
        TransferHelper.safeTransfer(plexus, _user, claimAmount);
        user.lastRewardBlock = block.number;
        user.recivePLX += claimAmount;
        userInfo[_user] = user;

        emit Claim(_user, claimAmount, user.recivePLX);
    }

    function close(uint256 roopStart, uint256 roopEnd) public {
        require(msg.sender == dev);
        require(block.timestamp > idoEndTime);
        if (usdtTotalReciveAmount < usdtSoftCap) {
            if (roopEnd >= userAddress.length) {
                roopEnd = userAddress.length;
            }
            for (roopStart; roopStart < roopEnd; roopStart++) {
                if (userInfo[userAddress[roopStart]].amount != 0) {
                    TransferHelper.safeTransfer(usdt, userAddress[roopStart], userInfo[userAddress[roopStart]].amount);
                    userInfo[userAddress[roopStart]].amount = 0;
                }
            }
            TransferHelper.safeTransfer(plexus, dev, IERC20(plexus).balanceOf(address(this)));
        } else {
            TransferHelper.safeTransfer(usdt, dev, IERC20(usdt).balanceOf(address(this)));
        }
    }

    function closeP2(uint256 roopStart, uint256 roopEnd) public {
        require(msg.sender == dev);
        require(block.timestamp > idoEndTime);
        if (usdtTotalReciveAmountP2 < usdtSoftCapP2) {
            if (roopEnd >= userAddressP2.length) {
                roopEnd = userAddressP2.length;
            }
            for (roopStart; roopStart < roopEnd; roopStart++) {
                if (userInfo[userAddressP2[roopStart]].amountP2 != 0) {
                    TransferHelper.safeTransfer(
                        usdt,
                        userAddressP2[roopStart],
                        userInfo[userAddressP2[roopStart]].amountP2
                    );
                    userInfo[userAddressP2[roopStart]].amountP2 = 0;
                }
            }
            TransferHelper.safeTransfer(plexus, dev, IERC20(plexus).balanceOf(address(this)));
        } else {
            TransferHelper.safeTransfer(usdt, dev, IERC20(usdt).balanceOf(address(this)));
        }
    }

    function emergencyWithdraw() public {
        require(msg.sender == dev);
        TransferHelper.safeTransfer(plexus, dev, IERC20(plexus).balanceOf(address(this)));
        TransferHelper.safeTransfer(usdt, dev, IERC20(usdt).balanceOf(address(this)));
    }

    function setLockupBlock(uint256 _launchingBlock) public {
        require(msg.sender == dev);
        // lockupBlock = _launchingBlock.add(172800); ( lunchingBlock + 1month)
        lockupBlock = _launchingBlock;
    }

    function setIdoTime(uint256 _startTime, uint256 _endTime) public {
        require(msg.sender == dev);
        idoStartTime = _startTime;
        idoEndTime = _endTime;
    }

    function setIdoTimeP2(uint256 _startTime, uint256 _endTime) public {
        require(msg.sender == dev);
        idoStartTimeP2 = _startTime;
        idoEndTimeP2 = _endTime;
    }

    function idoClosePlxWithdraw() public {
        require(msg.sender == dev);
        uint256 plxWithdrawAmount = (usdtTotalReciveAmount / USDT_ACC_PRECESION).mul(
            (usdtHardCap / USDT_ACC_PRECESION).mul(PLX_ACC_PRECESION) / (plexusTotalValue / PLX_ACC_PRECESION)
        );
        TransferHelper.safeTransfer(plexus, dev, plxWithdrawAmount);
    }

    function idoClosePlxWithdrawP2() public {
        require(msg.sender == dev);
        uint256 plxWithdrawAmount = (usdtTotalReciveAmountP2 / USDT_ACC_PRECESION).mul(
            (usdtHardCapP2 / USDT_ACC_PRECESION).mul(PLX_ACC_PRECESION) / (plexusTotalValueP2 / PLX_ACC_PRECESION)
        );
        TransferHelper.safeTransfer(plexus, dev, plxWithdrawAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper: KLAY_TRANSFER_FAILED");
    }
}