pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "interfaces/IERC20.sol";
import "interfaces/IFarm.sol";
import "interfaces/IDysonFactory.sol";
import "./ABDKMath64x64.sol";
import "./SqrtMath.sol";
import "./TransferHelper.sol";

/// @title Fee model for Dyson pair
contract FeeModel {
    using ABDKMath64x64 for *;

    uint internal constant MAX_FEE_RATIO = 2**64;

    /// @dev Fee ratio of token0. Max fee ratio is MAX_FEE_RATIO
    uint64 internal feeRatio0;
    /// @dev Fee ratio of token1. Max fee ratio is MAX_FEE_RATIO
    uint64 internal feeRatio1;
    /// @dev Timestamp when fee ratio of token0 last updated
    uint64 internal lastUpdateTime0;
    /// @dev Timestamp when fee ratio of token1 last updated
    uint64 internal lastUpdateTime1;
    uint64 public halfLife = 720; // Fee /= 2 every 12 minutes

    /// @dev Convenience function to get the stored fee ratio and last update time of token0 and token1
    /// @return _feeRatio0 Stored fee ratio of token0
    /// @return _feeRatio1 Stored fee ratio of token1
    /// @return _lastUpdateTime0 Stored last update time of token0
    /// @return _lastUpdateTime1 Stored last update time of token1
    function _getFeeRatioStored() internal view returns (uint64 _feeRatio0, uint64 _feeRatio1, uint64 _lastUpdateTime0, uint64 _lastUpdateTime1) {
        _feeRatio0 = feeRatio0;
        _feeRatio1 = feeRatio1;
        _lastUpdateTime0 = lastUpdateTime0;
        _lastUpdateTime1 = lastUpdateTime1;
    }

    /// @dev Pure function to calculate new fee ratio when fee ratio increased
    /// Formula shown as below with a as fee ratio before and b as fee ratio added:
    /// 1 - (1 - a)(1 - b) = a + b - ab
    /// new = before + added - before * added
    /// @param _feeRatioBefore Fee ratio before the increase
    /// @param _feeRatioAdded Fee ratio increased
    /// @return _newFeeRatio New fee ratio
    function _calcFeeRatioAdded(uint64 _feeRatioBefore, uint64 _feeRatioAdded) internal pure returns (uint64 _newFeeRatio) {
        uint before = uint(_feeRatioBefore);
        uint added = uint(_feeRatioAdded);
        _newFeeRatio = uint64(before + added - before * added / MAX_FEE_RATIO);
    }

    /// @dev Update fee ratio and last update timestamp of token0
    /// @param _feeRatioBefore Fee ratio before the increase
    /// @param _feeRatioAdded Fee ratio increased
    function _updateFeeRatio0(uint64 _feeRatioBefore, uint64 _feeRatioAdded) internal {
        feeRatio0 = _calcFeeRatioAdded(_feeRatioBefore, _feeRatioAdded);
        lastUpdateTime0 = uint64(block.timestamp);
    }

    /// @dev Update fee ratio and last update timestamp of token1
    /// @param _feeRatioBefore Fee ratio before the increase
    /// @param _feeRatioAdded Fee ratio increased
    function _updateFeeRatio1(uint64 _feeRatioBefore, uint64 _feeRatioAdded) internal {
        feeRatio1 = _calcFeeRatioAdded(_feeRatioBefore, _feeRatioAdded);
        lastUpdateTime1 = uint64(block.timestamp);
    }

    /// @notice Fee ratio halve every `halfLife` seconds
    /// @dev Calculate new fee ratio as time elapsed
    /// newFeeRatio = oldFeeRatio / 2^(elapsedTime / halfLife)
    /// @param _oldFeeRatio Fee ratio from last update
    /// @param _elapsedTime Time since last update
    /// @return _newFeeRatio New fee ratio
    function calcNewFeeRatio(uint64 _oldFeeRatio, uint _elapsedTime) public view returns (uint64 _newFeeRatio) {
        int128 t = _elapsedTime.divu(halfLife);
        int128 r = (-t).exp_2();
        _newFeeRatio = uint64(r.mulu(uint(_oldFeeRatio)));
    }

    /// @notice The fee ratios returned are the stored fee ratios with halving applied
    /// @return _feeRatio0 Fee ratio of token0 after halving update
    /// @return _feeRatio1 Fee ratio of token1 after halving update
    function getFeeRatio() public view returns (uint64 _feeRatio0, uint64 _feeRatio1) {
        uint64 _lastUpdateTime0;
        uint64 _lastUpdateTime1;
        (_feeRatio0, _feeRatio1, _lastUpdateTime0, _lastUpdateTime1) = _getFeeRatioStored();
        _feeRatio0 = calcNewFeeRatio(_feeRatio0, block.timestamp - uint(_lastUpdateTime0));
        _feeRatio1 = calcNewFeeRatio(_feeRatio1, block.timestamp - uint(_lastUpdateTime1));
    }
}

/// @title Contract with basic swap logic and fee mechanism
contract Feeswap is FeeModel {
    using TransferHelper for address;

    address public token0;
    address public token1;
    /// @notice Fee recipient
    address public feeTo;
    /// @dev Used to keep track of fee earned to save gas by not transferring fee away everytime.
    /// Need to discount this amount when calculating reserve
    uint internal accumulatedFee0;
    uint internal accumulatedFee1;

    /// @dev Mutex to prevent re-entrancy
    uint private unlocked = 1;

    event Swap(address indexed sender, bool indexed isSwap0, uint amountIn, uint amountOut, address indexed to);
    event FeeCollected(uint token0Amt, uint token1Amt);

    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function initialize(address _token0, address _token1) public virtual {
        require(token0 == address(0), 'FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint reserve0, uint reserve1) {
        reserve0 = IERC20(token0).balanceOf(address(this)) - accumulatedFee0;
        reserve1 = IERC20(token1).balanceOf(address(this)) - accumulatedFee1;
    }

    /// @param input Amount of token0 to swap
    /// @param minOutput Minimum amount of token1 expected to receive
    /// @return fee Amount of token0 as fee
    /// @return output Amount of token1 swapped
    function _swap0in(uint input, uint minOutput) internal returns (uint fee, uint output) {
        require(input > 0, "INVALID_INPUT_AMOUNT");
        (uint reserve0, uint reserve1) = getReserves();
        (uint64 _feeRatio0, uint64 _feeRatio1) = getFeeRatio();
        fee = uint(_feeRatio0) * input / MAX_FEE_RATIO;
        uint inputLessFee = input - fee;
        output = inputLessFee * reserve1 / (reserve0 + inputLessFee);
        require(output >= minOutput, "SLIPPAGE");
        uint64 feeRatioAdded = uint64(output * MAX_FEE_RATIO / reserve1);
        _updateFeeRatio1(_feeRatio1, feeRatioAdded);
    }

    /// @param input Amount of token1 to swap
    /// @param minOutput Minimum amount of token0 expected to receive
    /// @return fee Amount of token1 as fee
    /// @return output Amount of token0 swapped
    function _swap1in(uint input, uint minOutput) internal returns (uint fee, uint output) {
        require(input > 0, "INVALID_INPUT_AMOUNT");
        (uint reserve0, uint reserve1) = getReserves();
        (uint64 _feeRatio0, uint64 _feeRatio1) = getFeeRatio();
        fee = uint(_feeRatio1) * input / MAX_FEE_RATIO;
        uint inputLessFee = input - fee;
        output = inputLessFee * reserve0 / (reserve1 + inputLessFee);
        require(output >= minOutput, "SLIPPAGE");
        uint64 feeRatioAdded = uint64(output * MAX_FEE_RATIO / reserve0);
        _updateFeeRatio0(_feeRatio0, feeRatioAdded);
    }

    /// @notice Perfrom swap from token0 to token1
    /// Half of the swap fee goes to `feeTo` if `feeTo` is set
    /// @dev Re-entrancy protected
    /// @param to Address that receives swapped token1
    /// @param input Amount of token0 to swap
    /// @param minOutput Minimum amount of token1 expected to receive
    /// @return output Amount of token1 swapped
    function swap0in(address to, uint input, uint minOutput) external lock returns (uint output) {
        uint fee;
        (fee, output) = _swap0in(input, minOutput);
        token0.safeTransferFrom(msg.sender, address(this), input);
        token1.safeTransfer(to, output);
        if(feeTo != address(0)) accumulatedFee0 += fee / 2;
        emit Swap(msg.sender, true, input, output, to);
    }

    /// @notice Perfrom swap from token1 to token0
    /// Half of the swap fee goes to `feeTo` if `feeTo` is set
    /// @dev Re-entrancy protected
    /// @param to Address that receives swapped token0
    /// @param input Amount of token1 to swap
    /// @param minOutput Minimum amount of token0 expected to receive
    /// @return output Amount of token0 swapped
    function swap1in(address to, uint input, uint minOutput) external lock returns (uint output) {
        uint fee;
        (fee, output) = _swap1in(input, minOutput);
        token1.safeTransferFrom(msg.sender, address(this), input);
        token0.safeTransfer(to, output);
        if(feeTo != address(0)) accumulatedFee1 += fee / 2;
        emit Swap(msg.sender, false, input, output, to);
    }

    function collectFee() public lock {
        uint f0 = accumulatedFee0;
        uint f1 = accumulatedFee1;
        accumulatedFee0 = 0;
        accumulatedFee1 = 0;
        token0.safeTransfer(feeTo, f0);
        token1.safeTransfer(feeTo, f1);
        emit FeeCollected(f0, f1);
    }
}

/// @title Dyson pair contract
contract DysonPair is Feeswap {
    using SqrtMath for *;
    using TransferHelper for address;

    /// @dev Square root of `MAX_FEE_RATIO`
    uint private constant MAX_FEE_RATIO_SQRT = 2**32;
    /// @dev Beware that fee ratio and premium base unit are different
    uint private constant PREMIUM_BASE_UNIT = 1e18;
    /// @dev For EIP712
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("withdraw(address operator,uint index,address to,uint deadline)");

    /// @notice A note records the amount of token0 or token1 user gets when the user redeem the note
    /// and the timestamp when user can redeem.
    /// The amount of token0 and token1 include the premium
    struct Note {
        uint token0Amt;
        uint token1Amt;
        uint due;
    }

    /// @dev Factory of this contract
    address public factory;
    IFarm public farm;

    /// @notice Volatility which affects premium and can be set by governance, i.e. controller of factory contract
    uint public basis = 0.7e18;

    /// @notice Total number of notes created by user
    mapping(address => uint) public noteCount;
    /// @notice Notes created by user, indexed by note number
    mapping(address => mapping(uint => Note)) public notes;

    event Deposit(address indexed user, bool indexed isToken0, uint index, uint amountIn, uint token0Amt, uint token1Amt, uint due);
    event Withdraw(address indexed user, bool indexed isToken0, uint index, uint amountOut);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("DysonPair")),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /// @notice Premium = volatility * sqrt(time / 365 days) * 0.4
    /// @dev sqrt(time / 365 days) is pre-calculated to save gas.
    /// Note that premium could be larger than `PREMIUM_BASE_UNIT`
    /// @param time Lock time. It can be either 1 day, 3 days, 7 days or 30 days
    /// @return premium Premium
    function getPremium(uint time) public view returns (uint premium) {
        if(time == 1 days) premium = basis * 20936956903608548 / PREMIUM_BASE_UNIT;
        else if(time == 3 days) premium = basis * 36263873112929960 / PREMIUM_BASE_UNIT;
        else if(time == 7 days) premium = basis * 55393981177425144 / PREMIUM_BASE_UNIT;
        else if(time == 30 days) premium = basis * 114676435816199168 / PREMIUM_BASE_UNIT;
        else revert("INVALID_TIME");
    }

    function initialize(address _token0, address _token1) public override {
        super.initialize(_token0, _token1);
        factory = msg.sender;
    }

    /// @notice `basis` can only be set by governance, i.e., controller of factory contract
    function setBasis(uint _basis) external lock {
        require(IDysonFactory(factory).controller() == msg.sender, "FORBIDDEN");
        basis = _basis;
    }

    /// @notice `halfLife` can only be set by governance, i.e., controller of factory contract
    function setHalfLife(uint64 _halfLife) external lock {
        require(IDysonFactory(factory).controller() == msg.sender, "FORBIDDEN");
        require( _halfLife > 0, "HALF_LIFE_CANNOT_BE_ZERO");
        halfLife = _halfLife;
    }

    /// @notice `farm` can only be set by governance, i.e., controller of factory contract
    function setFarm(address _farm) external lock {
        require(IDysonFactory(factory).controller() == msg.sender, "FORBIDDEN");
        farm = IFarm(_farm);
    }

    /// @notice `feeTo` can only be set by governance, i.e., controller of factory contract
    function setFeeTo(address _feeTo) external lock {
        require(IDysonFactory(factory).controller() == msg.sender, "FORBIDDEN");
        if(feeTo != address(0)) collectFee();
        feeTo = _feeTo;
    }

    /// @notice rescue token stucked in this contract
    /// @param tokenAddress Address of token to be rescued
    /// @param to Address that will receive token
    /// @param amount Amount of token to be rescued
    function rescueERC20(address tokenAddress, address to, uint256 amount) external {
        require(IDysonFactory(factory).controller() == msg.sender, "FORBIDDEN");
        require(tokenAddress != token0);
        require(tokenAddress != token1);
        tokenAddress.safeTransfer(to, amount);
    }

    function _addNote(address to, bool depositToken0, uint token0Amt, uint token1Amt, uint time, uint premium) internal {
        uint index = noteCount[to]++;
        Note storage note = notes[to][index];

        uint inputAmt = depositToken0 ? token0Amt : token1Amt;
        uint token0AmtWithPremium = token0Amt * (premium + PREMIUM_BASE_UNIT) / PREMIUM_BASE_UNIT;
        uint token1AmtWithPremium = token1Amt * (premium + PREMIUM_BASE_UNIT) / PREMIUM_BASE_UNIT;
        uint dueTime = block.timestamp + time;

        note.token0Amt = token0AmtWithPremium;
        note.token1Amt = token1AmtWithPremium;
        note.due = dueTime;

        emit Deposit(to, depositToken0, index, inputAmt, token0AmtWithPremium, token1AmtWithPremium, dueTime);
    }

    function _grantAP(address to, uint input, uint output, uint premium) internal {
        if(address(farm) != address(0)) {
            uint ap = (input * output).sqrt() * premium / PREMIUM_BASE_UNIT;
            farm.grantAP(to, ap);
        }
    }

    /// @notice User deposit token0. This function simulates it as `swap0in`
    /// but only charges fee base on the fee computed and does not perform actual swap.
    /// Half of the swap fee goes to `feeTo` if `feeTo` is set.
    /// If `farm` is set, this function also computes the amount of AP for the user and calls `farm.grantAP()`.
    /// The amount of AP = sqrt(input * output) * (preium / PREMIUM_BASE_UNIT)
    /// @dev Re-entrancy protected
    /// @param to Address that owns the note
    /// @param input Amount of token0 to deposit
    /// @param minOutput Minimum amount of token1 expected to receive if the swap is perfromed
    /// @param time Lock time
    /// @return output Amount of token1 received if the swap is performed
    function deposit0(address to, uint input, uint minOutput, uint time) external lock returns (uint output) {
        require(to != address(0), "TO_CANNOT_BE_ZERO");
        uint fee;
        (fee, output) = _swap0in(input, minOutput);
        uint premium = getPremium(time);

        _addNote(to, true, input, output, time, premium);

        token0.safeTransferFrom(msg.sender, address(this), input);
        if(feeTo != address(0)) accumulatedFee0 += fee / 2;
        _grantAP(to, input, output, premium);
    }

    /// @notice User deposit token1. This function simulates it as `swap1in`
    /// but only charges fee base on the fee computed and does not perform actual swap.
    /// Half of the swap fee goes to `feeTo` if `feeTo` is set.
    /// If `farm` is set, this function also computes the amount of AP for the user and calls `farm.grantAP()`.
    /// The amount of AP = sqrt(input * output) * (preium / PREMIUM_BASE_UNIT)
    /// @dev Re-entrancy protected
    /// @param to Address that owns the note
    /// @param input Amount of token1 to deposit
    /// @param minOutput Minimum amount of token0 expected to receive if the swap is perfromed
    /// @param time Lock time
    /// @return output Amount of token0 received if the swap is performed
    function deposit1(address to, uint input, uint minOutput, uint time) external lock returns (uint output) {
        require(to != address(0), "TO_CANNOT_BE_ZERO");
        uint fee;
        (fee, output) = _swap1in(input, minOutput);
        uint premium = getPremium(time);

        _addNote(to, false, output, input, time, premium);

        token1.safeTransferFrom(msg.sender, address(this), input);
        if(feeTo != address(0)) accumulatedFee1 += fee / 2;
        _grantAP(to, input, output, premium);
    }

    /// @notice When withdrawing, the token to be withdrawn is the one with less impact on the pool if withdrawn
    /// Strike price: `token1Amt` / `token0Amt`
    /// Market price: (reserve1 * sqrt(1 - feeRatio0)) / (reserve0 * sqrt(1 - feeRatio1))
    /// If strike price > market price, withdraw token0 to user, and token1 vice versa
    /// Formula to determine which token to withdraw:
    /// `token0Amt` * sqrt(1 - feeRatio0) / reserve0 < `token1Amt` * sqrt(1 - feeRatio1) / reserve1
    /// @dev Formula can be transformed to:
    /// sqrt((1 - feeRatio0)/(1 - feeRatio1)) * `token0Amt` / reserve0 < `token1Amt` / reserve1
    /// @dev Content of withdrawn note will be cleared
    /// @param from Address of the user withdrawing
    /// @param index Index of the note
    /// @param to Address to receive the redeemed token0 or token1
    /// @return token0Amt Amount of token0 withdrawn
    /// @return token1Amt Amount of token1 withdrawn
    function _withdraw(address from, uint index, address to) internal returns (uint token0Amt, uint token1Amt) {
        Note storage note = notes[from][index];
        require(note.due > 0, "INVALID_NOTE");
        require(note.due <= block.timestamp, "EARLY_WITHDRAWAL");
        (uint reserve0, uint reserve1) = getReserves();
        (uint64 _feeRatio0, uint64 _feeRatio1) = getFeeRatio();

        if((MAX_FEE_RATIO * (MAX_FEE_RATIO - uint(_feeRatio0)) / (MAX_FEE_RATIO - uint(_feeRatio1))).sqrt() * note.token0Amt / reserve0 < MAX_FEE_RATIO_SQRT * note.token1Amt / reserve1) {
            token0Amt = note.token0Amt;
            token0.safeTransfer(to, note.token0Amt);
            uint64 feeRatioAdded = uint64(note.token0Amt * MAX_FEE_RATIO / reserve0);
            _updateFeeRatio0(_feeRatio0, feeRatioAdded);
            emit Withdraw(from, true, index, note.token0Amt);
        }
        else {
            token1Amt = note.token1Amt;
            token1.safeTransfer(to, note.token1Amt);
            uint64 feeRatioAdded = uint64(note.token1Amt * MAX_FEE_RATIO / reserve1);
            _updateFeeRatio1(_feeRatio1, feeRatioAdded);
            emit Withdraw(from, false, index, note.token1Amt);
        }
        note.token0Amt = 0;
        note.token1Amt = 0;
        note.due = 0;
    }

    /// @notice Withdraw the note and receive either one of token0 or token1
    /// @dev Re-entrancy protected
    /// @param index Index of the note owned by user
    /// @return token0Amt Amount of token0 withdrawn
    /// @return token1Amt Amount of token1 withdrawn
    function withdraw(uint index) external lock returns (uint token0Amt, uint token1Amt) {
        return _withdraw(msg.sender, index, msg.sender);
    }

    /// @notice Withdraw the note and receive either one of token0 or token1.
    /// User must also sign over the address calling this function
    /// @dev Re-entrancy protected
    /// @param from Address of the user withdrawing
    /// @param index Index of the note
    /// @param to Address to receive the redeemed token0 or token1
    /// @param deadline deadline
    /// @param sig signature
    /// @return token0Amt Amount of token0 withdrawn
    /// @return token1Amt Amount of token1 withdrawn
    function withdrawWithSig(address from, uint index, address to, uint deadline, bytes calldata sig) external lock returns (uint token0Amt, uint token1Amt) {
        require(block.timestamp <= deadline || deadline == 0, "EXCEED_DEADLINE");
        require(from != address(0), "FROM_CANNOT_BE_ZERO");
        bytes32 structHash = keccak256(abi.encode(WITHDRAW_TYPEHASH, msg.sender, index, to, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        require(from == _ecrecover(digest, sig), "INVALID_SIGNATURE");
        return _withdraw(from, index, to);
    }

    function _ecrecover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }

            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                return address(0);
            } else if (v != 27 && v != 28) {
                return address(0);
            } else {
                return ecrecover(hash, v, r, s);
            }
        } else {
            return address(0);
        }
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IFarm {
    function grantAP(address to, uint amount) external;

    function setPoolRewardRate(address poolId, uint _rewardRate, uint _w) external;
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IDysonFactory {
    function controller() external returns (address);
    function getInitCodeHash() external view returns (bytes32);
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     * -2^127
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     * 2^127-1
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu (int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require (x >= 0);

            uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256 (int256 (x)) * (y >> 128);

            require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require (hi <=
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu (uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require (y != 0);
            uint128 result = divuu (x, y);
            require (result <= uint128 (MAX_64x64));
            return int128 (result);
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2 (int128 x) internal pure returns (int128) {
        unchecked {
            require (x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            if (x & 0x4000000000000000 > 0)
                result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            if (x & 0x2000000000000000 > 0)
                result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            if (x & 0x1000000000000000 > 0)
                result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            if (x & 0x800000000000000 > 0)
                result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            if (x & 0x400000000000000 > 0)
                result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            if (x & 0x200000000000000 > 0)
                result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            if (x & 0x100000000000000 > 0)
                result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            if (x & 0x80000000000000 > 0)
                result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            if (x & 0x40000000000000 > 0)
                result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            if (x & 0x20000000000000 > 0)
                result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            if (x & 0x10000000000000 > 0)
                result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            if (x & 0x8000000000000 > 0)
                result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            if (x & 0x4000000000000 > 0)
                result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            if (x & 0x2000000000000 > 0)
                result = result * 0x1000162E525EE054754457D5995292026 >> 128;
            if (x & 0x1000000000000 > 0)
                result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            if (x & 0x800000000000 > 0)
                result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            if (x & 0x400000000000 > 0)
                result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            if (x & 0x200000000000 > 0)
                result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            if (x & 0x100000000000 > 0)
                result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            if (x & 0x80000000000 > 0)
                result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            if (x & 0x40000000000 > 0)
                result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            if (x & 0x20000000000 > 0)
                result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            if (x & 0x10000000000 > 0)
                result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            if (x & 0x8000000000 > 0)
                result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            if (x & 0x4000000000 > 0)
                result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            if (x & 0x2000000000 > 0)
                result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            if (x & 0x1000000000 > 0)
                result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            if (x & 0x800000000 > 0)
                result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            if (x & 0x400000000 > 0)
                result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            if (x & 0x200000000 > 0)
                result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            if (x & 0x100000000 > 0)
                result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            if (x & 0x80000000 > 0)
                result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            if (x & 0x40000000 > 0)
                result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            if (x & 0x20000000 > 0)
                result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            if (x & 0x10000000 > 0)
                result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            if (x & 0x8000000 > 0)
                result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            if (x & 0x4000000 > 0)
                result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            if (x & 0x2000000 > 0)
                result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            if (x & 0x1000000 > 0)
                result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            if (x & 0x800000 > 0)
                result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            if (x & 0x400000 > 0)
                result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
            if (x & 0x200000 > 0)
                result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
            if (x & 0x100000 > 0)
                result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
            if (x & 0x80000 > 0)
                result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            if (x & 0x40000 > 0)
                result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            if (x & 0x20000 > 0)
                result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            if (x & 0x10000 > 0)
                result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            if (x & 0x8000 > 0)
                result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            if (x & 0x4000 > 0)
                result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            if (x & 0x2000 > 0)
                result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
            if (x & 0x1000 > 0)
                result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            if (x & 0x800 > 0)
                result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            if (x & 0x400 > 0)
                result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
            if (x & 0x200 > 0)
                result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            if (x & 0x100 > 0)
                result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
            if (x & 0x80 > 0)
                result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            if (x & 0x40 > 0)
                result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            if (x & 0x20 > 0)
                result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
            if (x & 0x10 > 0)
                result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            if (x & 0x8 > 0)
                result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            if (x & 0x4 > 0)
                result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            if (x & 0x2 > 0)
                result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
            if (x & 0x1 > 0)
                result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

            result >>= uint256 (int256 (63 - (x >> 64)));
            require (result <= uint256 (int256 (MAX_64x64)));

            return int128 (int256 (result));
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu (uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require (y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
                if (xc >= 0x10000) { xc >>= 16; msb += 16; }
                if (xc >= 0x100) { xc >>= 8; msb += 8; }
                if (xc >= 0x10) { xc >>= 4; msb += 4; }
                if (xc >= 0x4) { xc >>= 2; msb += 2; }
                if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

                result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
                require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert (xh == hi >> 128);

                result += xl / y;
            }

            require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128 (result);
        }
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

//https://github.com/Gaussian-Process/solidity-sqrt/blob/main/src/FixedPointMathLib.sol
library SqrtMath {
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // This segment is to get a reasonable initial estimate for the Babylonian method.
            // If the initial estimate is bad, the number of correct bits increases ~linearly
            // each iteration instead of ~quadratically.
            // The idea is to get z*z*y within a small factor of x.
            // More iterations here gets y in a tighter range. Currently, we will have
            // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
            // between y and y+1 is small. If x < 256 this is not possible, but those cases
            // are easy enough to verify exhaustively.
            z := 181 // The 'correct' value is 1, but this saves a multiply later
            let y := x
            // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
            // this is to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }
            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
            // and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

            // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
            // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
            z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

            // Run the Babylonian method seven times. This should be enough given initial estimate.
            // Possibly with a quadratic/cubic polynomial above we could get 4-6.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
            // The solmate implementation assigns zRoundDown := div(x, z) first, but
            // since this case is rare, we choose to save gas on the assignment and
            // repeat division in the rare case.
            // If you don't care whether floor or ceil is returned, you can skip this.
            if lt(div(x, z), z) {
                z := div(x, z)
            }
        }
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}