// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IEsAPEX2.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/FullMath.sol";

contract EsAPEX2 is IEsAPEX2, Ownable {
    using FullMath for uint256;

    string public constant override name = "esApeX";
    string public constant override symbol = "esAPEX";
    uint8 public constant override decimals = 18;

    address public immutable override apeXToken;
    address public override treasury;

    uint256 public override forceWithdrawMinRemainRatio; // max:10000, default:1666
    uint256 public override vestTime;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public isMinter;
    mapping(address => VestInfo[]) public userVestInfos;

    constructor(
        address owner_,
        address apeXToken_,
        address treasury_,
        uint256 vestTime_,
        uint256 forceWithdrawMinRemainRatio_
    ) {
        owner = owner_;
        apeXToken = apeXToken_;
        treasury = treasury_;
        vestTime = vestTime_;
        forceWithdrawMinRemainRatio = forceWithdrawMinRemainRatio_;
    }

    function addMinter(address minter) external onlyOwner {
        require(!isMinter[minter], "minter already exist");
        isMinter[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        require(isMinter[minter], "minter not found");
        isMinter[minter] = false;
    }

    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "zero address");
        treasury = newTreasury;
    }

    function updateVestTime(uint256 newVestTime) external onlyOwner {
        emit VestTimeChanged(vestTime, newVestTime);
        vestTime = newVestTime;
    }

    function updateForceWithdrawMinRemainRatio(uint256 newRatio) external onlyOwner {
        require(newRatio <= 10000, "newRatio > 10000");
        emit ForceWithdrawMinRemainRatioChanged(forceWithdrawMinRemainRatio, newRatio);
        forceWithdrawMinRemainRatio = newRatio;
    }

    function mint(address to, uint256 amount) external override returns (bool) {
        require(isMinter[msg.sender], "not minter");
        require(amount > 0, "zero amount");
        TransferHelper.safeTransferFrom(apeXToken, msg.sender, address(this), amount);
        _mint(to, amount);
        return true;
    }

    function vest(uint256 amount) external override {
        require(amount > 0, "zero amount");
        uint256 fromBalance = balanceOf[msg.sender];
        require(fromBalance >= amount, "not enough balance to be vest");
        _transfer(msg.sender, address(this), amount);

        VestInfo memory info = VestInfo({
            startTime: block.timestamp,
            endTime: block.timestamp + vestTime,
            vestAmount: amount,
            claimedAmount: 0,
            forceWithdrawn: false
        });

        uint256 vestId = userVestInfos[msg.sender].length;
        userVestInfos[msg.sender].push(info);

        emit Vest(msg.sender, amount, info.endTime, vestId);
    }

    function withdraw(
        address to,
        uint256 vestId,
        uint256 amount
    ) external override {
        _withdraw(to, vestId, amount);
    }

    function batchWithdraw(
        address to,
        uint256[] memory vestIds,
        uint256[] memory amounts
    ) external override {
        require(vestIds.length == amounts.length, "two arrays' length not the same");
        for (uint256 i = 0; i < vestIds.length; i++) {
            _withdraw(to, vestIds[i], amounts[i]);
        }
    }

    function forceWithdraw(address to, uint256 vestId)
        external
        override
        returns (uint256 withdrawAmount, uint256 penalty)
    {
        return _forceWithdraw(to, vestId);
    }

    function batchForceWithdraw(address to, uint256[] memory vestIds)
        external
        override
        returns (uint256 withdrawAmount, uint256 penalty)
    {
        for (uint256 i = 0; i < vestIds.length; i++) {
            (uint256 withdrawAmount_, uint256 penalty_) = _forceWithdraw(to, vestIds[i]);
            withdrawAmount += withdrawAmount_;
            penalty += penalty_;
        }
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function getVestInfo(address user, uint256 vestId) external view override returns (VestInfo memory) {
        return userVestInfos[user][vestId];
    }

    function getVestInfosLength(address user) external view override returns (uint256 length) {
        return userVestInfos[user].length;
    }

    function getClaimable(address user, uint256 vestId) external view override returns (uint256 claimable) {
        return _getClaimable(user, vestId);
    }

    function getTotalClaimable(address user, uint256[] memory vestIds)
        external
        view
        override
        returns (uint256 claimable)
    {
        for (uint256 i = 0; i < vestIds.length; i++) {
            claimable += _getClaimable(user, vestIds[i]);
        }
    }

    function getLocking(address user, uint256 vestId) external view override returns (uint256 locking) {
        return _getLocking(user, vestId);
    }

    function getTotalLocking(address user, uint256[] memory vestIds) external view override returns (uint256 locking) {
        for (uint256 i = 0; i < vestIds.length; i++) {
            locking += _getLocking(user, vestIds[i]);
        }
    }

    function getForceWithdrawable(address user, uint256 vestId)
        external
        view
        override
        returns (uint256 withdrawable, uint256 penalty)
    {
        return _getForceWithdrawable(user, vestId);
    }

    function getTotalForceWithdrawable(address user, uint256[] memory vestIds)
        external
        view
        override
        returns (uint256 withdrawable, uint256 penalty)
    {
        for (uint256 i = 0; i < vestIds.length; i++) {
            (uint256 withdrawable_, uint256 penalty_) = _getForceWithdrawable(user, vestIds[i]);
            withdrawable += withdrawable_;
            penalty += penalty_;
        }
    }

    function _getClaimable(address user, uint256 vestId) internal view returns (uint256 claimable) {
        VestInfo memory info = userVestInfos[user][vestId];
        if (!info.forceWithdrawn) {
            uint256 pastTime = block.timestamp - info.startTime;
            uint256 wholeTime = info.endTime - info.startTime;
            if (pastTime >= wholeTime) {
                claimable = info.vestAmount;
            } else {
                claimable = info.vestAmount.mulDiv(pastTime, wholeTime);
            }
            claimable = claimable - info.claimedAmount;
        }
    }

    function _getLocking(address user, uint256 vestId) internal view returns (uint256 locking) {
        VestInfo memory info = userVestInfos[user][vestId];
        if (!info.forceWithdrawn) {
            if (block.timestamp >= info.endTime) {
                locking = 0;
            } else {
                uint256 leftTime = info.endTime - block.timestamp;
                uint256 wholeTime = info.endTime - info.startTime;
                locking = info.vestAmount.mulDiv(leftTime, wholeTime);
            }
        }
    }

    function _getForceWithdrawable(address user, uint256 vestId)
        internal
        view
        returns (uint256 withdrawable, uint256 penalty)
    {
        VestInfo memory info = userVestInfos[user][vestId];
        uint256 locking = _getLocking(user, vestId);
        uint256 left = (locking *
            (forceWithdrawMinRemainRatio +
                ((10000 - forceWithdrawMinRemainRatio) * (block.timestamp - info.startTime)) /
                vestTime)) / 10000;
        if (left > locking) left = locking;
        uint256 claimable = _getClaimable(user, vestId);
        withdrawable = claimable + left;
        penalty = locking - left;
    }

    function _withdraw(
        address to,
        uint256 vestId,
        uint256 amount
    ) internal {
        require(to != address(0), "can not withdraw to zero address");
        require(amount > 0, "zero amount");
        VestInfo storage info = userVestInfos[msg.sender][vestId];
        require(!info.forceWithdrawn, "already force withdrawn");

        uint256 claimable = _getClaimable(msg.sender, vestId);
        require(amount <= claimable, "amount > claimable");

        info.claimedAmount += amount;
        TransferHelper.safeTransfer(apeXToken, to, amount);
        _burn(address(this), amount);
        emit Withdraw(msg.sender, to, amount, vestId);
    }

    function _forceWithdraw(address to, uint256 vestId) internal returns (uint256 withdrawAmount, uint256 penalty) {
        require(to != address(0), "can not withdraw to zero address");
        VestInfo storage info = userVestInfos[msg.sender][vestId];
        require(!info.forceWithdrawn, "already force withdrawn");
        info.forceWithdrawn = true;

        (withdrawAmount, penalty) = _getForceWithdrawable(msg.sender, vestId);
        if (withdrawAmount > 0) TransferHelper.safeTransfer(apeXToken, to, withdrawAmount);
        if (penalty > 0) TransferHelper.safeTransfer(apeXToken, treasury, penalty);
        info.claimedAmount += withdrawAmount;

        _burn(address(this), withdrawAmount + penalty);
        emit ForceWithdraw(msg.sender, to, withdrawAmount, penalty, vestId);
    }

    function _spendAllowance(
        address from,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance[from][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(balanceOf[from] >= value, "balance of from < value");
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) private {
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(to != address(0), "can not tranfer to zero address");
        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= value, "transfer amount exceeds balance");
        balanceOf[from] = fromBalance - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

interface IEsAPEX2 is IERC20 {
    event ForceWithdrawMinRemainRatioChanged(uint256 oldRatio, uint256 newRatio);
    event VestTimeChanged(uint256 oldVestTime, uint256 newVestTime);
    event Vest(address indexed user, uint256 amount, uint256 endTime, uint256 vestId);
    event Withdraw(address indexed user, address indexed to, uint256 amount, uint256 vestId);
    event ForceWithdraw(
        address indexed user,
        address indexed to,
        uint256 withdrawAmount,
        uint256 penalty,
        uint256 vestId
    );

    struct VestInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 vestAmount;
        uint256 claimedAmount;
        bool forceWithdrawn;
    }

    function apeXToken() external view returns (address);

    function treasury() external view returns (address);

    function forceWithdrawMinRemainRatio() external view returns (uint256);

    function vestTime() external view returns (uint256);

    function getVestInfo(address user, uint256 vestId) external view returns (VestInfo memory);

    function getVestInfosLength(address user) external view returns (uint256 length);

    function getClaimable(address user, uint256 vestId) external view returns (uint256 claimable);

    function getTotalClaimable(address user, uint256[] memory vestIds) external view returns (uint256 claimable);

    function getLocking(address user, uint256 vestId) external view returns (uint256 locking);

    function getTotalLocking(address user, uint256[] memory vestIds) external view returns (uint256 locking);

    function getForceWithdrawable(address user, uint256 vestId)
        external
        view
        returns (uint256 withdrawable, uint256 penalty);

    function getTotalForceWithdrawable(address user, uint256[] memory vestIds)
        external
        view
        returns (uint256 withdrawable, uint256 penalty);

    function mint(address to, uint256 apeXAmount) external returns (bool);

    function vest(uint256 amount) external;

    function withdraw(
        address to,
        uint256 vestId,
        uint256 amount
    ) external;

    function batchWithdraw(
        address to,
        uint256[] memory vestIds,
        uint256[] memory amounts
    ) external;

    function forceWithdraw(address to, uint256 vestId) external returns (uint256 withdrawAmount, uint256 penalty);

    function batchForceWithdraw(address to, uint256[] memory vestIds)
        external
        returns (uint256 withdrawAmount, uint256 penalty);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}