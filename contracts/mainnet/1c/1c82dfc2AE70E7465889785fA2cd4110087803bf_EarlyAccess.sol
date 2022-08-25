// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Reference: https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
abstract contract CloneFactory {
    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function _isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(eq(mload(clone), mload(other)), eq(mload(add(clone, 0xd)), mload(add(other, 0xd))))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./base/CloneFactory.sol";
import "./interfaces/INFTGaugeFactory.sol";
import "./libraries/Integers.sol";
import "./libraries/Tokens.sol";
import "./NFTGauge.sol";

contract NFTGaugeFactory is CloneFactory, Ownable, INFTGaugeFactory {
    using SafeERC20 for IERC20;
    using Integers for int128;
    using Integers for uint256;

    struct Fee {
        uint64 timestamp;
        uint192 amountPerShare;
    }

    address public immutable override tokenURIRenderer;
    address public immutable override minter;
    address public immutable override votingEscrow;

    address public override target;
    uint256 public override targetVersion;

    uint256 public override feeRatio;
    mapping(address => address) public override currencyConverter;
    mapping(address => address) public override gauges;
    mapping(address => bool) public override isGauge;

    mapping(address => Fee[]) public override fees;
    mapping(address => mapping(address => uint256)) public override lastFeeClaimed;

    constructor(
        address _tokenURIRenderer,
        address _minter,
        uint256 _feeRatio
    ) {
        tokenURIRenderer = _tokenURIRenderer;
        minter = _minter;
        votingEscrow = IGaugeController(IMinter(_minter).controller()).votingEscrow();
        feeRatio = _feeRatio;

        emit UpdateFeeRatio(_feeRatio);

        NFTGauge gauge = new NFTGauge();
        gauge.initialize(address(0), address(0), address(0));
        target = address(gauge);
    }

    function feesLength(address token) external view override returns (uint256) {
        return fees[token].length;
    }

    function upgradeTarget(address _target) external override onlyOwner {
        target = _target;

        uint256 version = targetVersion + 1;
        targetVersion = version;

        emit UpgradeTarget(_target, version);
    }

    function updateCurrencyConverter(address token, address converter) external override onlyOwner {
        currencyConverter[token] = converter;

        emit UpdateCurrencyConverter(token, converter);
    }

    function updateFeeRatio(uint256 _feeRatio) external override onlyOwner {
        feeRatio = _feeRatio;

        emit UpdateFeeRatio(_feeRatio);
    }

    function createNFTGauge(address nftContract) external override returns (address gauge) {
        require(gauges[nftContract] == address(0), "NFTGF: GAUGE_CREATED");

        gauge = _createClone(target);
        INFTGauge(gauge).initialize(nftContract, tokenURIRenderer, minter);

        gauges[nftContract] = gauge;
        isGauge[gauge] = true;

        emit CreateNFTGauge(nftContract, gauge);
    }

    function executePayment(
        address currency,
        address from,
        uint256 amount
    ) external override {
        require(isGauge[msg.sender], "NFTGF: FORBIDDEN");
        require(currencyConverter[currency] != address(0), "NFTGF: INVALID_TOKEN");

        IERC20(currency).safeTransferFrom(from, msg.sender, amount);
    }

    function distributeFeesETH() external payable override returns (uint256 amountFee) {
        amountFee = (msg.value * feeRatio) / 10000;
        _distributeFees(address(0), amountFee);
    }

    function distributeFees(address token, uint256 amount) external override returns (uint256 amountFee) {
        amountFee = (amount * feeRatio) / 10000;
        _distributeFees(token, amountFee);
    }

    function _distributeFees(address token, uint256 amount) internal {
        require(isGauge[msg.sender], "NFTGF: FORBIDDEN");

        fees[token].push(
            Fee(uint64(block.timestamp), uint192((amount * 1e18) / IVotingEscrow(votingEscrow).totalSupply()))
        );

        emit DistributeFees(token, fees[token].length - 1, amount);
    }

    /**
     * @notice Claim accumulated fees
     * @param token In which currency fees were paid
     * @param to the last index of the fee (exclusive)
     */
    function claimFees(address token, uint256 to) external override {
        uint256 from = lastFeeClaimed[token][msg.sender];

        (int128 value, , uint256 start, ) = IVotingEscrow(votingEscrow).locked(msg.sender);
        require(value > 0, "NFTGF: LOCK_NOT_FOUND");

        uint256 epoch = IVotingEscrow(votingEscrow).userPointEpoch(msg.sender);
        (int128 bias, int128 slope, uint256 ts, ) = IVotingEscrow(votingEscrow).userPointHistory(msg.sender, epoch);

        uint256 amount;
        for (uint256 i = from; i < to; ) {
            Fee memory fee = fees[token][i];
            if (start < fee.timestamp) {
                int128 balance = bias - slope * (uint256(fee.timestamp) - ts).toInt128();
                if (balance > 0) {
                    amount += (balance.toUint256() * uint256(fee.amountPerShare)) / 1e18;
                }
            }
            unchecked {
                ++i;
            }
        }
        lastFeeClaimed[token][msg.sender] = to;

        emit ClaimFees(token, amount, msg.sender);
        Tokens.transfer(token, msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INFTGaugeFactory {
    event UpgradeTarget(address target, uint256 indexed version);
    event UpdateCurrencyConverter(address indexed token, address indexed converter);
    event CreateNFTGauge(address indexed nftContract, address indexed gauge);
    event UpdateFeeRatio(uint256 feeRatio);
    event DistributeFees(address indexed token, uint256 indexed id, uint256 amount);
    event ClaimFees(address indexed token, uint256 amount, address indexed to);

    function tokenURIRenderer() external view returns (address);

    function minter() external view returns (address);

    function votingEscrow() external view returns (address);

    function target() external view returns (address);

    function targetVersion() external view returns (uint256);

    function feeRatio() external view returns (uint256);

    function currencyConverter(address currency) external view returns (address);

    function gauges(address nftContract) external view returns (address);

    function isGauge(address addr) external view returns (bool);

    function fees(address token, uint256 id) external view returns (uint64 timestamp, uint192 amountPerShare);

    function lastFeeClaimed(address token, address user) external view returns (uint256);

    function feesLength(address token) external view returns (uint256);

    function upgradeTarget(address target) external;

    function updateCurrencyConverter(address token, address converter) external;

    function updateFeeRatio(uint256 feeRatio) external;

    function createNFTGauge(address nftContract) external returns (address gauge);

    function executePayment(
        address currency,
        address from,
        uint256 amount
    ) external;

    function distributeFeesETH() external payable returns (uint256 amountFee);

    function distributeFees(address token, uint256 amount) external returns (uint256 amountFee);

    function claimFees(address token, uint256 to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Integers {
    function toInt128(uint256 u) internal pure returns (int128) {
        return int128(int256(u));
    }

    function toUint256(int128 i) internal pure returns (uint256) {
        return uint256(uint128(i));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Tokens {
    using SafeERC20 for IERC20;

    function transfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "LEVX: FAILED_TO_TRANSFER_ETH");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./base/WrappedERC721.sol";
import "./interfaces/INFTGauge.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/ICurrencyConverter.sol";
import "./libraries/Tokens.sol";
import "./libraries/Math.sol";
import "./libraries/NFTs.sol";

contract NFTGauge is WrappedERC721, INFTGauge {
    struct Snapshot {
        uint64 timestamp;
        uint192 value;
    }

    address public override minter;
    address public override controller;
    address public override votingEscrow;
    uint256 public override futureEpochTime;

    mapping(uint256 => uint256) public override dividendRatios;
    mapping(address => mapping(uint256 => Snapshot[])) public override dividends; // currency -> tokenId -> Snapshot
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override lastDividendClaimed; // currency -> tokenId -> user -> index

    int128 public override period;
    mapping(int128 => uint256) public override periodTimestamp;
    mapping(int128 => uint256) public override integrateInvSupply; // bump epoch when rate() changes

    mapping(uint256 => mapping(address => int128)) public override periodOf; // tokenId -> user -> period
    mapping(uint256 => mapping(address => uint256)) public override integrateFraction; // tokenId -> user -> fraction

    uint256 public override inflationRate;

    bool public override isKilled;

    mapping(address => mapping(uint256 => uint256)) public override userWeight;
    mapping(address => uint256) public override userWeightSum;

    uint256 internal _interval;

    mapping(uint256 => uint256) internal _nonces; // tokenId -> nonce
    mapping(uint256 => mapping(uint256 => mapping(address => Snapshot[]))) internal _points; // tokenId -> nonce -> user -> Snapshot
    mapping(uint256 => mapping(uint256 => Snapshot[])) internal _pointsSum; // tokenId -> nonce -> Snapshot
    Snapshot[] internal _pointsTotal;

    function initialize(
        address _nftContract,
        address _tokenURIRenderer,
        address _minter
    ) external override initializer {
        __WrappedERC721_init(_nftContract, _tokenURIRenderer);

        minter = _minter;
        address _controller = IMinter(_minter).controller();
        controller = _controller;
        votingEscrow = IGaugeController(_controller).votingEscrow();
        periodTimestamp[0] = block.timestamp;
        inflationRate = IMinter(_minter).rate();
        futureEpochTime = IMinter(_minter).futureEpochTimeWrite();
        _interval = IGaugeController(_controller).interval();
    }

    function integrateCheckpoint() external view override returns (uint256) {
        return periodTimestamp[period];
    }

    function points(uint256 tokenId, address user) public view override returns (uint256) {
        return _lastValue(_points[tokenId][_nonces[tokenId]][user]);
    }

    function pointsAt(
        uint256 tokenId,
        address user,
        uint256 timestamp
    ) public view override returns (uint256) {
        return _getValueAt(_points[tokenId][_nonces[tokenId]][user], timestamp);
    }

    function pointsSum(uint256 tokenId) external view override returns (uint256) {
        return _lastValue(_pointsSum[tokenId][_nonces[tokenId]]);
    }

    function pointsSumAt(uint256 tokenId, uint256 timestamp) public view override returns (uint256) {
        return _getValueAt(_pointsSum[tokenId][_nonces[tokenId]], timestamp);
    }

    function pointsTotal() external view override returns (uint256) {
        return _lastValue(_pointsTotal);
    }

    function pointsTotalAt(uint256 timestamp) external view override returns (uint256) {
        return _getValueAt(_pointsTotal, timestamp);
    }

    function dividendsLength(address token, uint256 tokenId) external view override returns (uint256) {
        return dividends[token][tokenId].length;
    }

    /**
     * @notice Toggle the killed status of the gauge
     */
    function killMe() external override {
        require(msg.sender == controller, "NFTG: FORBIDDDEN");
        isKilled = !isKilled;
    }

    function _checkpoint() internal returns (int128 _period, uint256 _integrateInvSupply) {
        address _minter = minter;
        address _controller = controller;
        _period = period;
        uint256 _periodTime = periodTimestamp[_period];
        _integrateInvSupply = integrateInvSupply[_period];
        uint256 rate = inflationRate;
        uint256 newRate = rate;
        uint256 prevFutureEpoch = futureEpochTime;
        if (prevFutureEpoch >= _periodTime) {
            futureEpochTime = IMinter(_minter).futureEpochTimeWrite();
            newRate = IMinter(_minter).rate();
            inflationRate = newRate;
        }
        IGaugeController(_controller).checkpointGauge(address(this));

        uint256 total = _lastValue(_pointsTotal);

        if (isKilled) rate = 0; // Stop distributing inflation as soon as killed

        // Update integral of 1/total
        if (block.timestamp > _periodTime) {
            uint256 interval = _interval;
            uint256 prevWeekTime = _periodTime;
            uint256 weekTime = Math.min(((_periodTime + interval) / interval) * interval, block.timestamp);
            for (uint256 i; i < 250; ) {
                uint256 dt = weekTime - prevWeekTime;
                uint256 w = IGaugeController(_controller).gaugeRelativeWeight(
                    address(this),
                    (prevWeekTime / interval) * interval
                );

                if (total > 0) {
                    if (prevFutureEpoch >= prevWeekTime && prevFutureEpoch < weekTime) {
                        // If we went across one or multiple epochs, apply the rate
                        // of the first epoch until it ends, and then the rate of
                        // the last epoch.
                        // If more than one epoch is crossed - the gauge gets less,
                        // but that'd meen it wasn't called for more than 1 year
                        _integrateInvSupply += (rate * w * (prevFutureEpoch - prevWeekTime)) / total;
                        rate = newRate;
                        _integrateInvSupply += (rate * w * (weekTime - prevFutureEpoch)) / total;
                    } else {
                        _integrateInvSupply += (rate * w * dt) / total;
                    }
                }

                if (weekTime == block.timestamp) break;
                prevWeekTime = weekTime;
                weekTime = Math.min(weekTime + interval, block.timestamp);

                unchecked {
                    ++i;
                }
            }
        }

        ++_period;
        period = _period;
        periodTimestamp[_period] = block.timestamp;
        integrateInvSupply[_period] = _integrateInvSupply;
    }

    /**
     * @notice Checkpoint for a user for a specific token
     * @param tokenId Token Id
     * @param user User address
     */
    function userCheckpoint(uint256 tokenId, address user) public override {
        require(msg.sender == user || user == minter, "NFTG: FORBIDDEN");
        (int128 _period, uint256 _integrateInvSupply) = _checkpoint();

        // Update user-specific integrals
        int128 userPeriod = periodOf[tokenId][user];
        uint256 oldIntegrateInvSupply = integrateInvSupply[userPeriod];
        uint256 dIntegrate = _integrateInvSupply - oldIntegrateInvSupply;
        if (dIntegrate > 0) {
            uint256 nonce = _nonces[tokenId];
            uint256 sum = _lastValue(_pointsSum[tokenId][nonce]);
            uint256 pt = _lastValue(_points[tokenId][nonce][user]);
            integrateFraction[tokenId][user] += (pt * dIntegrate * 2) / 3 / 1e18; // 67% goes to voters
            if (ownerOf(tokenId) == user) {
                integrateFraction[tokenId][user] += (sum * dIntegrate) / 3 / 1e18; // 33% goes to the owner
            }
        }
        periodOf[tokenId][user] = _period;
    }

    /**
     * @notice Mint a wrapped NFT and commit gauge voting to this tokenId
     * @param tokenId Token Id to deposit
     * @param dividendRatio Dividend ratio for the voters in bps (units of 0.01%)
     * @param to The owner of the newly minted wrapped NFT
     * @param _userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function wrap(
        uint256 tokenId,
        uint256 dividendRatio,
        address to,
        uint256 _userWeight
    ) public override {
        require(dividendRatio <= 10000, "NFTG: INVALID_RATIO");

        dividendRatios[tokenId] = dividendRatio;

        _mint(to, tokenId);

        vote(tokenId, _userWeight);

        emit Wrap(tokenId, to);

        NFTs.safeTransferFrom(nftContract, msg.sender, address(this), tokenId);
    }

    function unwrap(uint256 tokenId, address to) public override {
        require(ownerOf(tokenId) == msg.sender, "NFTG: FORBIDDEN");

        dividendRatios[tokenId] = 0;

        _burn(tokenId);

        uint256 nonce = _nonces[tokenId];
        _updateValueAtNow(_pointsTotal, _lastValue(_pointsTotal) - _lastValue(_pointsSum[tokenId][nonce]));
        _nonces[tokenId] = nonce + 1;

        emit Unwrap(tokenId, to);

        NFTs.safeTransferFrom(nftContract, address(this), to, tokenId);
    }

    function vote(uint256 tokenId, uint256 _userWeight) public override {
        require(_exists(tokenId), "NFTG: NON_EXISTENT");

        userCheckpoint(tokenId, msg.sender);

        uint256 balance = IVotingEscrow(votingEscrow).balanceOf(msg.sender);
        uint256 pointNew = (balance * _userWeight) / 10000;
        uint256 pointOld = points(tokenId, msg.sender);

        uint256 nonce = _nonces[tokenId];
        _updateValueAtNow(_points[tokenId][nonce][msg.sender], pointNew);
        _updateValueAtNow(_pointsSum[tokenId][nonce], _lastValue(_pointsSum[tokenId][nonce]) + pointNew - pointOld);
        _updateValueAtNow(_pointsTotal, _lastValue(_pointsTotal) + pointNew - pointOld);

        uint256 userWeightOld = userWeight[msg.sender][tokenId];
        uint256 _userWeightSum = userWeightSum[msg.sender] + _userWeight - userWeightOld;
        userWeight[msg.sender][tokenId] = _userWeight;
        userWeightSum[msg.sender] = _userWeightSum;

        IGaugeController(controller).voteForGaugeWeights(msg.sender, _userWeightSum);

        emit Vote(tokenId, msg.sender, _userWeight);
    }

    function claimDividends(address token, uint256 tokenId) external override {
        uint256 amount;
        uint256 _last = lastDividendClaimed[token][tokenId][msg.sender];
        uint256 i;
        while (i < 250) {
            uint256 id = _last + i;
            if (id >= dividends[token][tokenId].length) break;

            Snapshot memory dividend = dividends[token][tokenId][id];
            uint256 pt = _getValueAt(_points[tokenId][_nonces[tokenId]][msg.sender], dividend.timestamp);
            if (pt > 0) {
                amount += (pt * uint256(dividend.value)) / 1e18;
            }

            unchecked {
                ++i;
            }
        }

        require(i > 0, "NFTG: NO_AMOUNT_TO_CLAIM");
        lastDividendClaimed[token][tokenId][msg.sender] = _last + i;

        emit ClaimDividends(token, tokenId, amount, msg.sender);
        Tokens.transfer(token, msg.sender, amount);
    }

    /**
     * @dev `_getValueAt` retrieves the number of tokens at a given time
     * @param snapshots The history of values being queried
     * @param timestamp The block timestamp to retrieve the value at
     * @return The weight at `timestamp`
     */
    function _getValueAt(Snapshot[] storage snapshots, uint256 timestamp) internal view returns (uint256) {
        if (snapshots.length == 0) return 0;

        // Shortcut for the actual value
        Snapshot storage last = snapshots[snapshots.length - 1];
        if (timestamp >= last.timestamp) return last.value;
        if (timestamp < snapshots[0].timestamp) return 0;

        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = snapshots.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (snapshots[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return snapshots[min].value;
    }

    function _lastValue(Snapshot[] storage snapshots) internal view returns (uint256) {
        uint256 length = snapshots.length;
        return length > 0 ? uint256(snapshots[length - 1].value) : 0;
    }

    /**
     * @dev `_updateValueAtNow` is used to update snapshots
     * @param snapshots The history of data being updated
     * @param _value The new number of weight
     */
    function _updateValueAtNow(Snapshot[] storage snapshots, uint256 _value) internal {
        if ((snapshots.length == 0) || (snapshots[snapshots.length - 1].timestamp < block.timestamp)) {
            Snapshot storage newCheckPoint = snapshots.push();
            newCheckPoint.timestamp = uint64(block.timestamp);
            newCheckPoint.value = uint192(_value);
        } else {
            Snapshot storage oldCheckPoint = snapshots[snapshots.length - 1];
            oldCheckPoint.value = uint192(_value);
        }
    }

    function _settle(
        uint256 tokenId,
        address currency,
        address to,
        uint256 amount
    ) internal override {
        address _factory = factory;
        address converter = INFTGaugeFactory(_factory).currencyConverter(currency);
        uint256 amountETH = ICurrencyConverter(converter).getAmountETH(amount);
        if (amountETH >= 1e18) {
            IGaugeController(controller).increaseGaugeWeight(amountETH / 1e18);
        }

        uint256 fee;
        if (currency == address(0)) {
            fee = INFTGaugeFactory(_factory).distributeFeesETH{value: amount}();
        } else {
            fee = INFTGaugeFactory(_factory).distributeFees(currency, amount);
        }

        uint256 dividend;
        uint256 sum = _lastValue(_pointsSum[tokenId][_nonces[tokenId]]);
        if (sum > 0) {
            dividend = ((amount - fee) * dividendRatios[tokenId]) / 10000;
            dividends[currency][tokenId].push(Snapshot(uint64(block.timestamp), uint192((dividend * 1e18) / sum)));
            emit DistributeDividend(currency, tokenId, dividend);
        }
        Tokens.transfer(currency, to, amount - fee - dividend);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        userCheckpoint(tokenId, from);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../base/ERC721Initializable.sol";
import "../interfaces/IWrappedERC721.sol";
import "../interfaces/ITokenURIRenderer.sol";
import "../interfaces/INFTGaugeFactory.sol";
import "../libraries/Signature.sol";
import "../libraries/Tokens.sol";
import "../libraries/Math.sol";

abstract contract WrappedERC721 is ERC721Initializable, ReentrancyGuard, IWrappedERC721 {
    using Strings for uint256;

    struct Order {
        uint256 price;
        address currency;
        uint64 deadline;
        bool auction;
    }

    struct Bid_ {
        uint256 price;
        address bidder;
        uint64 timestamp;
    }

    address public override nftContract;
    address public override tokenURIRenderer;
    address public override factory;

    mapping(uint256 => mapping(address => Order)) public override sales;
    mapping(uint256 => mapping(address => Bid_)) public override currentBids;
    mapping(uint256 => mapping(address => Order)) public override offers;

    function __WrappedERC721_init(address _nftContract, address _tokenURIRenderer) internal initializer {
        nftContract = _nftContract;
        tokenURIRenderer = _tokenURIRenderer;
        factory = msg.sender;

        string memory name;
        string memory symbol;
        try IERC721Metadata(_nftContract).name() returns (string memory _name) {
            name = _name;
        } catch {
            name = uint256(uint160(nftContract)).toHexString(20);
        }
        try IERC721Metadata(_nftContract).symbol() returns (string memory _symbol) {
            symbol = string(abi.encodePacked("W", _symbol));
        } catch {
            symbol = "WNFT";
        }
        __ERC721_init(string(abi.encodePacked("Wrapped ", name)), symbol);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Initializable, IERC721Metadata)
        returns (string memory output)
    {
        require(_exists(tokenId), "WERC721: TOKEN_NON_EXISTENT");

        return ITokenURIRenderer(tokenURIRenderer).render(nftContract, tokenId);
    }

    function listForSale(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 deadline,
        bool auction
    ) external override {
        require(block.timestamp < deadline, "WERC721: INVALID_DEADLINE");
        require(ownerOf(tokenId) == msg.sender, "WERC721: FORBIDDEN");
        require(currency == address(0), "WERC721: INVALID_CURRENCY");

        sales[tokenId][msg.sender] = Order(price, currency, deadline, auction);

        emit ListForSale(tokenId, msg.sender, price, currency, deadline, auction);
    }

    function cancelListing(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "WERC721: FORBIDDEN");

        delete sales[tokenId][msg.sender];
        delete currentBids[tokenId][msg.sender];

        emit CancelListing(tokenId, msg.sender);
    }

    function buyETH(uint256 tokenId, address owner) external payable override {
        address currency = _buy(tokenId, owner, msg.value);
        require(currency == address(0), "WERC721: ETH_UNACCEPTABLE");

        _settle(tokenId, address(0), owner, msg.value);
    }

    function buy(
        uint256 tokenId,
        address owner,
        uint256 price
    ) external override nonReentrant {
        address currency = _buy(tokenId, owner, price);
        require(currency != address(0), "WERC721: ONLY_ETH_ACCEPTABLE");

        INFTGaugeFactory(factory).executePayment(currency, msg.sender, price);

        _settle(tokenId, currency, owner, price);
    }

    function _buy(
        uint256 tokenId,
        address owner,
        uint256 price
    ) internal returns (address currency) {
        Order memory sale = sales[tokenId][owner];
        require(sale.deadline > 0, "WERC721: NOT_LISTED_FOR_SALE");
        require(block.timestamp <= sale.deadline, "WERC721: EXPIRED");
        require(sale.price == price, "WERC721: INVALID_PRICE");
        require(!sale.auction, "WERC721: BID_REQUIRED");

        _safeTransfer(owner, msg.sender, tokenId, "0x");

        currency = sale.currency;
        emit Buy(tokenId, owner, msg.sender, price, currency);
    }

    function bidETH(uint256 tokenId, address owner) external payable override {
        address currency = _bid(tokenId, owner, msg.value);
        require(currency == address(0), "WERC721: ETH_UNACCEPTABLE");
    }

    function bid(
        uint256 tokenId,
        address owner,
        uint256 price
    ) external override nonReentrant {
        address currency = _bid(tokenId, owner, price);
        require(currency != address(0), "WERC721: ONLY_ETH_ACCEPTABLE");

        INFTGaugeFactory(factory).executePayment(currency, msg.sender, price);
    }

    function _bid(
        uint256 tokenId,
        address owner,
        uint256 price
    ) internal returns (address currency) {
        Order memory sale = sales[tokenId][owner];
        uint256 deadline = sale.deadline;
        require(deadline > 0, "WERC721: NOT_LISTED_FOR_SALE");
        require(sale.auction, "WERC721: NOT_BIDDABLE");

        currency = sale.currency;
        Bid_ memory prevBid = currentBids[tokenId][owner];
        if (prevBid.price == 0) {
            require(price >= sale.price, "WERC721: PRICE_TOO_LOW");
            require(block.timestamp <= deadline, "WERC721: EXPIRED");
        } else {
            require(price >= (prevBid.price * 110) / 100, "WERC721: PRICE_TOO_LOW");
            require(block.timestamp <= Math.max(deadline, prevBid.timestamp + 10 minutes), "WERC721: EXPIRED");

            Tokens.transfer(currency, prevBid.bidder, prevBid.price);
        }
        currentBids[tokenId][owner] = Bid_(price, msg.sender, uint64(block.timestamp));

        emit Bid(tokenId, owner, msg.sender, price, currency);
    }

    function claim(uint256 tokenId, address owner) external override nonReentrant {
        Order memory sale = sales[tokenId][owner];
        require(sale.deadline > 0, "WERC721: NOT_LISTED_FOR_SALE");
        require(sale.auction, "WERC721: NOT_CLAIMABLE");

        Bid_ memory currentBid = currentBids[tokenId][owner];
        require(currentBid.bidder == msg.sender, "WERC721: FORBIDDEN");
        require(currentBid.timestamp + 10 minutes < block.timestamp, "WERC721: BID_NOT_FINISHED");

        Tokens.transfer(owner, msg.sender, tokenId);

        _settle(tokenId, sale.currency, owner, sale.price);

        emit Claim(tokenId, owner, msg.sender, sale.price, sale.currency);
    }

    function makeOfferETH(uint256 tokenId, uint64 deadline) external payable override nonReentrant {
        _makeOffer(tokenId, msg.value, address(0), deadline);
    }

    function makeOffer(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 deadline
    ) external override nonReentrant {
        _makeOffer(tokenId, price, currency, deadline);

        INFTGaugeFactory(factory).executePayment(currency, msg.sender, price);
    }

    function _makeOffer(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 deadline
    ) internal {
        require(_exists(tokenId), "WERC721: INVALID_TOKEN_ID");
        require(price > 0, "WERC721: INVALID_PRICE");
        require(block.timestamp < uint256(deadline), "WERC721: INVALID_DEADLINE");

        Order memory offer = offers[tokenId][msg.sender];
        if (offer.deadline > 0) {
            emit WithdrawOffer(tokenId, msg.sender);

            Tokens.transfer(offer.currency, msg.sender, offer.price);
        }

        offers[tokenId][msg.sender] = Order(price, currency, deadline, false);

        emit MakeOffer(tokenId, msg.sender, price, currency, uint256(deadline));
    }

    function withdrawOffer(uint256 tokenId) external override {
        Order memory offer = offers[tokenId][msg.sender];
        require(offer.deadline > 0, "WERC721: INVALID_OFFER");

        delete offers[tokenId][msg.sender];

        emit WithdrawOffer(tokenId, msg.sender);

        Tokens.transfer(offer.currency, msg.sender, offer.price);
    }

    function acceptOffer(uint256 tokenId, address maker) external override nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "WERC721: FORBIDDEN");

        Order memory offer = offers[tokenId][maker];
        require(offer.deadline > 0, "WERC721: INVALID_OFFER");
        require(block.timestamp <= offer.deadline, "WERC721: EXPIRED");

        delete offers[tokenId][maker];
        _safeTransfer(msg.sender, maker, tokenId, "0x");

        _settle(tokenId, offer.currency, msg.sender, offer.price);

        emit AcceptOffer(tokenId, maker, msg.sender, offer.price, offer.currency, offer.deadline);
    }

    function _settle(
        uint256 tokenId,
        address currency,
        address to,
        uint256 amount
    ) internal virtual;

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 tokenId
    ) internal virtual override {
        if (from != address(0)) {
            delete sales[tokenId][from];
            delete currentBids[tokenId][from];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IWrappedERC721.sol";
import "./IGauge.sol";

interface INFTGauge is IWrappedERC721, IGauge {
    event Wrap(uint256 indexed tokenId, address indexed to);
    event Unwrap(uint256 indexed tokenId, address indexed to);
    event Vote(uint256 indexed tokenId, address indexed user, uint256 weight);
    event DistributeDividend(address indexed token, uint256 indexed tokenId, uint256 amount);
    event ClaimDividends(address indexed token, uint256 indexed tokenId, uint256 amount, address indexed to);

    function initialize(
        address _nftContract,
        address _tokenURIRenderer,
        address _minter
    ) external;

    function controller() external view returns (address);

    function minter() external view returns (address);

    function votingEscrow() external view returns (address);

    function futureEpochTime() external view returns (uint256);

    function dividendRatios(uint256 tokenId) external view returns (uint256);

    function dividends(
        address token,
        uint256 tokenId,
        uint256 id
    ) external view returns (uint64 blockNumber, uint192 amountPerShare);

    function lastDividendClaimed(
        address token,
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    function integrateCheckpoint() external view returns (uint256);

    function period() external view returns (int128);

    function periodTimestamp(int128 period) external view returns (uint256);

    function integrateInvSupply(int128 period) external view returns (uint256);

    function periodOf(uint256 tokenId, address user) external view returns (int128);

    function integrateFraction(uint256 tokenId, address user) external view returns (uint256);

    function inflationRate() external view returns (uint256);

    function isKilled() external view returns (bool);

    function userWeight(address user, uint256 tokenId) external view returns (uint256);

    function userWeightSum(address user) external view returns (uint256);

    function points(uint256 tokenId, address user) external view returns (uint256);

    function pointsAt(
        uint256 tokenId,
        address user,
        uint256 _block
    ) external view returns (uint256);

    function pointsSum(uint256 tokenId) external view returns (uint256);

    function pointsSumAt(uint256 tokenId, uint256 _block) external view returns (uint256);

    function pointsTotal() external view returns (uint256);

    function pointsTotalAt(uint256 _block) external view returns (uint256);

    function dividendsLength(address token, uint256 tokenId) external view returns (uint256);

    function userCheckpoint(uint256 tokenId, address user) external;

    function wrap(
        uint256 tokenId,
        uint256 ratio,
        address to,
        uint256 _userWeight
    ) external;

    function unwrap(uint256 tokenId, address to) external;

    function vote(uint256 tokenId, uint256 _userWeight) external;

    function claimDividends(address token, uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGaugeController {
    event AddType(string name, int128 gaugeType);
    event NewTypeWeight(int128 gaugeType, uint256 time, uint256 weight, uint256 totalWeight);
    event NewGaugeWeight(address addr, uint256 time, uint256 weight, uint256 totalWeight);
    event VoteForGauge(uint256 time, address user, address addr, uint256 weight);
    event NewGauge(address addr, int128 gaugeType, uint256 weight);

    function interval() external view returns (uint256);

    function weightVoteDelay() external view returns (uint256);

    function votingEscrow() external view returns (address);

    function gaugeTypesLength() external view returns (int128);

    function gaugesLength() external view returns (int128);

    function gaugeTypeNames(int128 gaugeType) external view returns (string memory);

    function gauges(int128 gaugeType) external view returns (address);

    function voteUserSlopes(address user, address addr)
        external
        view
        returns (
            uint256 slope,
            uint256 power,
            uint256 end
        );

    function voteUserPower(address user) external view returns (uint256 totalVotePower);

    function lastUserVote(address user, address addr) external view returns (uint256 time);

    function pointsWeight(address addr, uint256 time) external view returns (uint256 bias, uint256 slope);

    function timeWeight(address addr) external view returns (uint256 lastScheduledTime);

    function pointsSum(int128 gaugeType, uint256 time) external view returns (uint256 bias, uint256 slope);

    function timeSum(int128 gaugeType) external view returns (uint256 lastScheduledTime);

    function pointsTotal(uint256 time) external view returns (uint256 totalWeight);

    function timeTotal() external view returns (uint256 lastScheduledTime);

    function pointsTypeWeight(int128 gaugeType, uint256 time) external view returns (uint256 typeWeight);

    function timeTypeWeight(int128 gaugeType) external view returns (uint256 lastScheduledTime);

    function gaugeTypes(address addr) external view returns (int128);

    function getGaugeWeight(address addr) external view returns (uint256);

    function getTypeWeight(int128 gaugeType) external view returns (uint256);

    function getTotalWeight() external view returns (uint256);

    function getWeightsSumPerType(int128 gaugeType) external view returns (uint256);

    function gaugeRelativeWeight(address addr) external view returns (uint256);

    function gaugeRelativeWeight(address addr, uint256 time) external view returns (uint256);

    function addType(string calldata name) external;

    function addType(string calldata name, uint256 weight) external;

    function changeTypeWeight(int128 gaugeType, uint256 weight) external;

    function addGauge(address addr, int128 gaugeType) external;

    function addGauge(
        address addr,
        int128 gaugeType,
        uint256 weight
    ) external;

    function increaseGaugeWeight(uint256 weight) external;

    function killGauge(address addr) external;

    function checkpoint() external;

    function checkpointGauge(address addr) external;

    function gaugeRelativeWeightWrite(address addr) external returns (uint256);

    function gaugeRelativeWeightWrite(address addr, uint256 time) external returns (uint256);

    function voteForGaugeWeights(address user, uint256 userWeight) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMinter {
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
    event Minted(address indexed recipient, address indexed gaugeAddr, uint256 indexed tokenId, uint256 minted);

    function token() external view returns (address);

    function controller() external view returns (address);

    function initialSupply() external view returns (uint256);

    function initialRate() external view returns (uint256);

    function rateReductionTime() external view returns (uint256);

    function rateReductionCoefficient() external view returns (uint256);

    function miningEpoch() external view returns (int128);

    function startEpochTime() external view returns (uint256);

    function rate() external view returns (uint256);

    function availableSupply() external view returns (uint256);

    function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256);

    function minted(
        address gaugeAddr,
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    function updateMiningParameters() external;

    function startEpochTimeWrite() external returns (uint256);

    function futureEpochTimeWrite() external returns (uint256);

    function mint(address gaugeAddr, uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVotingEscrow {
    event SetMigrator(address indexed account);
    event SetDelegate(address indexed account, bool isDelegate);
    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 discount,
        uint256 indexed unlockTime,
        int128 indexed _type,
        uint256 ts
    );
    event Cancel(address indexed provider, uint256 value, uint256 discount, uint256 penaltyRate, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 discount, uint256 ts);
    event Migrate(address indexed provider, uint256 value, uint256 discount, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    function interval() external view returns (uint256);

    function maxDuration() external view returns (uint256);

    function token() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function migrator() external view returns (address);

    function isDelegate(address account) external view returns (bool);

    function supply() external view returns (uint256);

    function migrated(address account) external view returns (bool);

    function delegateAt(address account, uint256 index) external view returns (address);

    function locked(address account)
        external
        view
        returns (
            int128 amount,
            int128 discount,
            uint256 start,
            uint256 end
        );

    function epoch() external view returns (uint256);

    function pointHistory(uint256 epoch)
        external
        view
        returns (
            int128 bias,
            int128 slope,
            uint256 ts,
            uint256 blk
        );

    function userPointHistory(address account, uint256 epoch)
        external
        view
        returns (
            int128 bias,
            int128 slope,
            uint256 ts,
            uint256 blk
        );

    function userPointEpoch(address account) external view returns (uint256);

    function slopeChanges(uint256 epoch) external view returns (int128);

    function delegateLength(address addr) external view returns (uint256);

    function getLastUserSlope(address addr) external view returns (int128);

    function getCheckpointTime(address _addr, uint256 _idx) external view returns (uint256);

    function unlockTime(address _addr) external view returns (uint256);

    function setMigrator(address _migrator) external;

    function setDelegate(address account, bool _isDelegate) external;

    function checkpoint() external;

    function depositFor(address _addr, uint256 _value) external;

    function createLockFor(
        address _addr,
        uint256 _value,
        uint256 _discount,
        uint256 _duration
    ) external;

    function createLock(uint256 _value, uint256 _duration) external;

    function increaseAmountFor(
        address _addr,
        uint256 _value,
        uint256 _discount
    ) external;

    function increaseAmount(uint256 _value) external;

    function increaseUnlockTime(uint256 _duration) external;

    function cancel() external;

    function withdraw() external;

    function migrate() external;

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 _t) external view returns (uint256);

    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICurrencyConverter {
    function getAmountETH(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/ICryptoPunksMarket.sol";

library NFTs {
    address constant CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    function ownerOf(address token, uint256 tokenId) internal view returns (address) {
        if (token == CRYPTOPUNKS) {
            return ICryptoPunksMarket(token).punkIndexToAddress(tokenId);
        } else {
            return IERC721(token).ownerOf(tokenId);
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (token == CRYPTOPUNKS) {
            // ICryptoPunksMarket.offerPunkForSaleToAddress() should have been called by the owner prior to this call
            ICryptoPunksMarket(token).buyPunk(tokenId);
            if (to != address(this)) {
                ICryptoPunksMarket(token).transferPunk(to, tokenId);
            }
        } else {
            IERC721(token).safeTransferFrom(from, to, tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721Initializable is Initializable, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Upper bound of tokenId parked
    uint256 private _toTokenIdParked;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: INVALID_OWNER");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: INVALID_TOKEN_ID");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Initializable.ownerOf(tokenId);
        require(to != owner, "ERC721: INVALID_TO");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: FORBIDDEN");

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: INVALID_TOKEN_ID");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NOT_APPROVED_NOR_OWNER");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: FORBIDDEN");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: INVALID_RECEIVER");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: INVALID_TOKEN_ID");
        address owner = ERC721Initializable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(operator != owner, "ERC721: INVALID_OPERATOR");

        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _parked(uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Initializable.ownerOf(tokenId);
        return owner == address(0) && tokenId < _toTokenIdParked;
    }

    function _parkTokenIds(uint256 toTokenId) internal virtual {
        uint256 fromTokenId = _toTokenIdParked;
        require(toTokenId > fromTokenId, "ERC721: INVALID_TO_TOKEN_ID");

        _toTokenIdParked = toTokenId;
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: INVALID_RECEIVER");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: INVALID_TO");
        require(!_exists(tokenId), "ERC721: ALREADY_MINTED");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Initializable.ownerOf(tokenId);
        require(owner != address(0), "ERC721: INVALID_TOKEN_ID");

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Initializable.ownerOf(tokenId) == from, "ERC721: TRANSFER_FORBIDDEN");
        require(to != address(0), "ERC721: INVALID_RECIPIENT");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Initializable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: INVALID_RECEIVER");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IWrappedERC721 is IERC165, IERC721, IERC721Metadata {
    function nftContract() external view returns (address);

    function tokenURIRenderer() external view returns (address);

    function factory() external view returns (address);

    function sales(uint256 tokenId, address owner)
        external
        view
        returns (
            uint256 price,
            address currency,
            uint64 deadline,
            bool auction
        );

    function currentBids(uint256 tokenId, address owner)
        external
        view
        returns (
            uint256 price,
            address bidder,
            uint64 timestamp
        );

    function offers(uint256 tokenId, address maker)
        external
        view
        returns (
            uint256 price,
            address currency,
            uint64 deadline,
            bool auction
        );

    function listForSale(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 deadline,
        bool auction
    ) external;

    function cancelListing(uint256 tokenId) external;

    function buyETH(uint256 tokenId, address owner) external payable;

    function buy(
        uint256 tokenId,
        address owner,
        uint256 price
    ) external;

    function bidETH(uint256 tokenId, address owner) external payable;

    function bid(
        uint256 tokenId,
        address owner,
        uint256 price
    ) external;

    function claim(uint256 tokenId, address owner) external;

    function makeOfferETH(uint256 tokenId, uint64 deadline) external payable;

    function makeOffer(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 deadline
    ) external;

    function withdrawOffer(uint256 tokenId) external;

    function acceptOffer(uint256 tokenId, address maker) external;

    event ListForSale(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price,
        address currency,
        uint64 deadline,
        bool indexed auction
    );
    event CancelListing(uint256 indexed tokenId, address indexed owner);
    event MakeOffer(uint256 indexed tokenId, address indexed maker, uint256 price, address currency, uint256 deadline);
    event WithdrawOffer(uint256 indexed tokenId, address indexed maker);
    event AcceptOffer(
        uint256 indexed tokenId,
        address indexed maker,
        address indexed taker,
        uint256 price,
        address currency,
        uint256 deadline
    );
    event Buy(uint256 indexed tokenId, address indexed owner, address indexed bidder, uint256 price, address currency);
    event Bid(uint256 indexed tokenId, address indexed owner, address indexed bidder, uint256 price, address currency);
    event Claim(
        uint256 indexed tokenId,
        address indexed owner,
        address indexed bidder,
        uint256 price,
        address currency
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITokenURIRenderer {
    function render(address nftContract, uint256 tokenId) external view returns (string memory output);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library Signature {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "LEVX: INVALID_SIGNATURE_S_VALUE"
        );
        require(v == 27 || v == 28, "LEVX: INVALID_SIGNATURE_V_VALUE");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "LEVX: INVALID_SIGNATURE");

        return signer;
    }

    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            require(
                IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
                "LEVX: UNAUTHORIZED"
            );
        } else {
            require(recover(digest, v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGauge {
    function killMe() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICryptoPunksMarket {
    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    function transferPunk(address to, uint256 punkIndex) external;

    function buyPunk(uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/IMinter.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/INFTGauge.sol";

interface IToken {
    function mint(address account, uint256 value) external;
}

contract Minter is IMinter {
    uint256 constant RATE_DENOMINATOR = 1e18;
    uint256 constant INFLATION_DELAY = 86400;

    address public immutable override token;
    address public immutable override controller;
    uint256 public immutable override initialSupply;
    uint256 public immutable override initialRate;
    uint256 public immutable override rateReductionTime;
    uint256 public immutable override rateReductionCoefficient;

    int128 public override miningEpoch;
    uint256 public override startEpochTime;
    uint256 public override rate;

    mapping(address => mapping(uint256 => mapping(address => uint256))) public override minted; // gauge -> tokenId -> user -> amount

    uint256 internal startEpochSupply;

    constructor(
        address _token,
        address _controller,
        uint256 _initialSupply,
        uint256 _initialRate,
        uint256 _rateReductionTime,
        uint256 _rateReductionCoefficient
    ) {
        token = _token;
        controller = _controller;
        initialSupply = _initialSupply;
        initialRate = _initialRate;
        rateReductionTime = _rateReductionTime;
        rateReductionCoefficient = _rateReductionCoefficient;

        startEpochTime = block.timestamp + INFLATION_DELAY - rateReductionTime;
        miningEpoch = -1;
        rate = 0;
        startEpochSupply = initialSupply;
    }

    /**
     * @notice Current number of tokens in existence (claimed or unclaimed)
     */
    function availableSupply() external view override returns (uint256) {
        return _availableSupply();
    }

    /**
     * @notice How much supply is mintable from start timestamp till end timestamp
     * @param start Start of the time interval (timestamp)
     * @param end End of the time interval (timestamp)
     * @return Tokens mintable from `start` till `end`
     */
    function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256) {
        require(start <= end, "MT: INVALID_TIME_RANGE");
        uint256 toMint = 0;
        uint256 currentEpochTime = startEpochTime;
        uint256 currentRate = rate;

        // Special case if end is in future (not yet minted) epoch
        if (end > currentEpochTime + rateReductionTime) {
            currentEpochTime += rateReductionTime;
            currentRate = (currentRate * RATE_DENOMINATOR) / rateReductionCoefficient;
        }

        require(end <= currentEpochTime + rateReductionTime, "MT: TOO_FAR_IN_FUTURE");

        for (uint256 i; i < 1000; ) {
            if (end >= currentEpochTime) {
                uint256 currentEnd = end;
                if (currentEnd > currentEpochTime + rateReductionTime)
                    currentEnd = currentEpochTime + rateReductionTime;

                uint256 currentStart = start;
                if (currentStart >= currentEpochTime + rateReductionTime) break;
                else if (currentStart < currentEpochTime) currentStart = currentEpochTime;

                toMint += currentRate * (currentEnd - currentStart);

                if (start >= currentEpochTime) break;
            }

            currentEpochTime -= rateReductionTime;
            currentRate = (currentRate * rateReductionCoefficient) / RATE_DENOMINATOR; // double-division with rounding made rate a bit less => good
            require(currentRate <= initialRate, "MT: THIS_SHOULD_NEVER_HAPPEN");

            unchecked {
                ++i;
            }
        }

        return toMint;
    }

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev Callable by any address, but only once per epoch
     *      Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external override {
        require(block.timestamp >= startEpochTime + rateReductionTime, "MT: TOO_SOON");
        _updateMiningParameters();
    }

    /**
     * @notice Get timestamp of the current mining epoch start
     *         while simultaneously updating mining parameters
     * @return Timestamp of the epoch
     */
    function startEpochTimeWrite() external override returns (uint256) {
        uint256 _startEpochTime = startEpochTime;
        if (block.timestamp >= _startEpochTime + rateReductionTime) {
            _updateMiningParameters();
            return startEpochTime;
        } else return _startEpochTime;
    }

    /**
     * @notice Get timestamp of the next mining epoch start
     *         while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external override returns (uint256) {
        uint256 _startEpochTime = startEpochTime;
        if (block.timestamp >= _startEpochTime + rateReductionTime) {
            _updateMiningParameters();
            return startEpochTime + rateReductionTime;
        } else return _startEpochTime + rateReductionTime;
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gaugeAddr `NFTGauge` address to get mintable amount from
     * @param tokenId tokenId
     */
    function mint(address gaugeAddr, uint256 tokenId) external override {
        require(IGaugeController(controller).gaugeTypes(gaugeAddr) >= 0, "MT: GAUGE_NOT_ADDED");

        INFTGauge(gaugeAddr).userCheckpoint(tokenId, msg.sender);
        uint256 total = INFTGauge(gaugeAddr).integrateFraction(tokenId, msg.sender);

        uint256 _minted = minted[gaugeAddr][tokenId][msg.sender];
        if (total > _minted) {
            minted[gaugeAddr][tokenId][msg.sender] = total;

            emit Minted(msg.sender, gaugeAddr, tokenId, total - _minted);
            IToken(token).mint(msg.sender, total - _minted);
        }
    }

    function _availableSupply() internal view returns (uint256) {
        return startEpochSupply + (block.timestamp - startEpochTime) * rate;
    }

    /**
     * @dev Update mining rate and supply at the start of the epoch
     *      Any modifying mining call must also call this
     */
    function _updateMiningParameters() internal {
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += rateReductionTime;
        miningEpoch += 1;

        if (_rate == 0) _rate = initialRate;
        else {
            _startEpochSupply += _rate * rateReductionTime;
            startEpochSupply = _startEpochSupply;
            _rate = (_rate * RATE_DENOMINATOR) / rateReductionCoefficient;
        }

        rate = _rate;

        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IGauge.sol";
import "./libraries/Math.sol";

/**
 * @title Gauge Controller
 * @author LevX ([email protected])
 * @notice Controls liquidity gauges and the issuance of coins through the gauges
 * @dev Ported from vyper (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/GaugeController.vy)
 */
contract GaugeController is Ownable, IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    uint256 internal constant MULTIPLIER = 1e18;

    uint256 public override interval;
    uint256 public override weightVoteDelay;
    address public override votingEscrow;

    // Gauge parameters
    // All numbers are "fixed point" on the basis of 1e18
    int128 public override gaugeTypesLength;
    int128 public override gaugesLength;
    mapping(int128 => string) public override gaugeTypeNames;

    // Needed for enumeration
    mapping(int128 => address) public override gauges;

    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gauge has not been set
    mapping(address => int128) internal _gaugeTypes;

    mapping(address => mapping(address => VotedSlope)) public override voteUserSlopes; // user -> addr -> VotedSlope
    mapping(address => uint256) public override voteUserPower; // Total vote power used by user
    mapping(address => mapping(address => uint256)) public override lastUserVote; // Last user vote's timestamp for each gauge address

    // Past and scheduled points for gauge weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    mapping(address => mapping(uint256 => Point)) public override pointsWeight; // addr -> time -> Point
    mapping(address => mapping(uint256 => uint256)) internal _changesWeight; // addr -> time -> slope
    mapping(address => uint256) public override timeWeight; // addr -> last scheduled time (next week)

    mapping(int128 => mapping(uint256 => Point)) public override pointsSum; // gaugeType -> time -> Point
    mapping(int128 => mapping(uint256 => uint256)) internal _changesSum; // gaugeType -> time -> slope
    mapping(int128 => uint256) public override timeSum; // gaugeType -> last scheduled time (next week)

    mapping(uint256 => uint256) public override pointsTotal; // time -> total weight
    uint256 public override timeTotal; // last scheduled time

    mapping(int128 => mapping(uint256 => uint256)) public override pointsTypeWeight; // gaugeType -> time -> type weight
    mapping(int128 => uint256) public override timeTypeWeight; // gaugeType -> last scheduled time (next week)

    /**
     * @notice Contract constructor
     * @param _interval for how many seconds gauge weights will remain the same
     * @param _weightVoteDelay for how many seconds weight votes cannot be changed
     * @param _votingEscrow `VotingEscrow` contract address
     */
    constructor(
        uint256 _interval,
        uint256 _weightVoteDelay,
        address _votingEscrow
    ) {
        interval = _interval;
        weightVoteDelay = _weightVoteDelay;
        votingEscrow = _votingEscrow;
        timeTotal = (block.timestamp / _interval) * _interval;
    }

    /**
     * @notice Get gauge type for id
     * @param addr Gauge address
     * @return Gauge type id
     */
    function gaugeTypes(address addr) external view override returns (int128) {
        int128 gaugeType = _gaugeTypes[addr];
        require(gaugeType != 0, "GC: INVALID_GAUGE_TYPE");

        return gaugeType - 1;
    }

    /**
     * @notice Get current gauge weight
     * @param addr Gauge address
     * @return Gauge weight
     */
    function getGaugeWeight(address addr) external view override returns (uint256) {
        return pointsWeight[addr][timeWeight[addr]].bias;
    }

    /**
     * @notice Get current type weight
     * @param gaugeType Type id
     * @return Type weight
     */
    function getTypeWeight(int128 gaugeType) external view override returns (uint256) {
        return pointsTypeWeight[gaugeType][timeTypeWeight[gaugeType]];
    }

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view override returns (uint256) {
        return pointsTotal[timeTotal];
    }

    /**
     * @notice Get sum of gauge weights per type
     * @param gaugeType Type id
     * @return Sum of gauge weights
     */
    function getWeightsSumPerType(int128 gaugeType) external view override returns (uint256) {
        return pointsSum[gaugeType][timeSum[gaugeType]].bias;
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address addr) external view override returns (uint256) {
        return _gaugeRelativeWeight(addr, block.timestamp);
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address addr, uint256 time) public view override returns (uint256) {
        return _gaugeRelativeWeight(addr, time);
    }

    /**
     * @notice Add gauge type with name `name` and weight `weight`
     * @param name Name of gauge type
     */
    function addType(string memory name) external override {
        addType(name, 0);
    }

    /**
     * @notice Add gauge type with name `name` and weight `weight`
     * @param name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory name, uint256 weight) public override onlyOwner {
        int128 gaugeType = gaugeTypesLength;
        gaugeTypeNames[gaugeType] = name;
        gaugeTypesLength = gaugeType + 1;
        if (weight != 0) {
            _changeTypeWeight(gaugeType, weight);
        }
        emit AddType(name, gaugeType);
    }

    /**
     * @notice Change type weight
     * @param gaugeType Type id
     * @param weight New type weight
     */
    function changeTypeWeight(int128 gaugeType, uint256 weight) external override onlyOwner {
        _changeTypeWeight(gaugeType, weight);
    }

    /**
     * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
     * @param addr Gauge address
     * @param gaugeType Gauge type
     */
    function addGauge(address addr, int128 gaugeType) external override {
        addGauge(addr, gaugeType, 0);
    }

    /**
     * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
     * @param addr Gauge address
     * @param gaugeType Gauge type
     * @param weight Gauge weight
     */
    function addGauge(
        address addr,
        int128 gaugeType,
        uint256 weight
    ) public override onlyOwner {
        require((gaugeType >= 0) && (gaugeType < gaugeTypesLength), "GC: INVALID_GAUGE_TYPE");
        require(_gaugeTypes[addr] == 0, "GC: DUPLICATE_GAUGE");

        int128 n = gaugesLength;
        gaugesLength = n + 1;
        gauges[n] = addr;

        _gaugeTypes[addr] = gaugeType + 1;
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;

        if (weight > 0) {
            uint256 typeWeight = _getTypeWeight(gaugeType);
            uint256 oldSum = _getSum(gaugeType);
            uint256 oldTotal = _getTotal();

            pointsSum[gaugeType][nextTime].bias = weight + oldSum;
            timeSum[gaugeType] = nextTime;
            pointsTotal[nextTime] = oldTotal + typeWeight * weight;
            timeTotal = nextTime;

            pointsWeight[addr][nextTime].bias = weight;
        }

        if (timeSum[gaugeType] == 0) timeSum[gaugeType] = nextTime;
        timeWeight[addr] = nextTime;

        emit NewGauge(addr, gaugeType, weight);
    }

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param increment Gauge weight to be increased
     */
    function increaseGaugeWeight(uint256 increment) external override {
        _increaseGaugeWeight(increment);
    }

    /**
     * @notice Toggle the killed status of the gauge
     * @param addr Gauge address
     */
    function killGauge(address addr) external override onlyOwner {
        IGauge(addr).killMe();
    }

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external override {
        _getTotal();
    }

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
     * @param addr Gauge address
     */
    function checkpointGauge(address addr) external override {
        _getWeight(addr);
        _getTotal();
    }

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
    values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param addr Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeightWrite(address addr) external override returns (uint256) {
        return gaugeRelativeWeightWrite(addr, block.timestamp);
    }

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
    values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeightWrite(address addr, uint256 time) public override returns (uint256) {
        _getWeight(addr);
        _getTotal(); // Also calculates get_sum
        return gaugeRelativeWeight(addr, time);
    }

    /**
     * @notice Allocate voting power for changing pool weights on behalf of a user (only called by gauges)
     * @param user Actual user whose voting power will be utilized
     * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function voteForGaugeWeights(address user, uint256 userWeight) external override {
        address escrow = votingEscrow;
        uint256 slope = uint256(uint128(IVotingEscrow(escrow).getLastUserSlope(user)));
        uint256 lockEnd = IVotingEscrow(escrow).unlockTime(user);
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;
        require(lockEnd > nextTime, "GC: LOCK_EXPIRES_TOO_EARLY");
        require((userWeight >= 0) && (userWeight <= 10000), "GC: VOTING_POWER_ALL_USED");
        require(block.timestamp >= lastUserVote[user][msg.sender] + weightVoteDelay, "GC: VOTED_TOO_EARLY");

        // Avoid stack too deep error
        {
            int128 gaugeType = _gaugeTypes[msg.sender] - 1;
            require(gaugeType >= 0, "GC: GAUGE_NOT_ADDED");
            // Prepare slopes and biases in memory
            VotedSlope memory oldSlope = voteUserSlopes[user][msg.sender];
            uint256 oldDt;
            if (oldSlope.end > nextTime) oldDt = oldSlope.end - nextTime;
            VotedSlope memory newSlope = VotedSlope({
                slope: (slope * userWeight) / 10000,
                end: lockEnd,
                power: userWeight
            });

            // Check and update powers (weights) used
            uint256 powerUsed = voteUserPower[user];
            powerUsed = powerUsed + newSlope.power - oldSlope.power;
            voteUserPower[user] = powerUsed;
            require((powerUsed >= 0) && (powerUsed <= 10000), "GC: USED_TOO_MUCH_POWER");

            /// Remove old and schedule new slope changes
            _updateSlopeChanges(
                msg.sender,
                nextTime,
                gaugeType,
                oldSlope.slope * oldDt,
                newSlope.slope * (lockEnd - nextTime),
                oldSlope,
                newSlope
            );
        }

        // Record last action time
        lastUserVote[user][msg.sender] = block.timestamp;

        emit VoteForGauge(block.timestamp, user, msg.sender, userWeight);
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _gaugeRelativeWeight(address addr, uint256 time) internal view returns (uint256) {
        uint256 _interval = interval;
        uint256 t = (time / _interval) * _interval;
        uint256 totalWeight = pointsTotal[t];

        if (totalWeight > 0) {
            int128 gaugeType = _gaugeTypes[addr] - 1;
            uint256 typeWeight = pointsTypeWeight[gaugeType][t];
            uint256 gaugeWeight = pointsWeight[addr][t].bias;
            return (MULTIPLIER * typeWeight * gaugeWeight) / totalWeight;
        } else return 0;
    }

    /**
     * @notice Change type weight
     * @param gaugeType Type id
     * @param weight New type weight
     */
    function _changeTypeWeight(int128 gaugeType, uint256 weight) internal {
        uint256 oldWeight = _getTypeWeight(gaugeType);
        uint256 oldSum = _getSum(gaugeType);
        uint256 totalWeight = _getTotal();
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;

        totalWeight = totalWeight + oldSum * weight - oldSum * oldWeight;
        pointsTotal[nextTime] = totalWeight;
        pointsTypeWeight[gaugeType][nextTime] = weight;
        timeTotal = nextTime;
        timeTypeWeight[gaugeType] = nextTime;

        emit NewTypeWeight(gaugeType, nextTime, weight, totalWeight);
    }

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param increment Gauge weight to be increased
     */
    function _increaseGaugeWeight(uint256 increment) internal {
        int128 gaugeType = _gaugeTypes[msg.sender] - 1;
        require(gaugeType >= 0, "GC: GAUGE_NOT_ADDED");

        uint256 oldGaugeWeight = _getWeight(msg.sender);
        uint256 typeWeight = _getTypeWeight(gaugeType);
        uint256 oldSum = _getSum(gaugeType);
        uint256 totalWeight = _getTotal();
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;

        pointsWeight[msg.sender][nextTime].bias = oldGaugeWeight + increment;
        timeWeight[msg.sender] = nextTime;

        uint256 newSum = oldSum + increment;
        pointsSum[gaugeType][nextTime].bias = newSum;
        timeSum[gaugeType] = nextTime;

        totalWeight = totalWeight + newSum * typeWeight - oldSum * typeWeight;
        pointsTotal[nextTime] = totalWeight;
        timeTotal = nextTime;

        emit NewGaugeWeight(msg.sender, block.timestamp, oldGaugeWeight + increment, totalWeight);
    }

    /**
     * @notice Fill historic total weights week-over-week for missed checkins
     * and return the total for the future week
     * @return Total weight
     */
    function _getTotal() internal returns (uint256) {
        uint256 _interval = interval;
        uint256 t = timeTotal;
        int128 nGaugeTypes = gaugeTypesLength;
        // If we have already checkpointed - still need to change the value
        if (t > block.timestamp) t -= _interval;
        uint256 pt = pointsTotal[t];

        for (int128 gaugeType; gaugeType < 100; ) {
            if (gaugeType == nGaugeTypes) break;
            _getSum(gaugeType);
            _getTypeWeight(gaugeType);

            unchecked {
                ++gaugeType;
            }
        }

        for (uint256 i; i < 500; ) {
            if (t > block.timestamp) break;
            t += _interval;
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gaugeType; gaugeType < 100; ) {
                if (gaugeType == nGaugeTypes) break;
                uint256 typeSum = pointsSum[gaugeType][t].bias;
                uint256 typeWeight = pointsTypeWeight[gaugeType][t];
                pt += typeSum * typeWeight;

                unchecked {
                    ++gaugeType;
                }
            }
            pointsTotal[t] = pt;

            if (t > block.timestamp) timeTotal = t;

            unchecked {
                ++i;
            }
        }
        return pt;
    }

    /**
     * @notice Fill sum of gauge weights for the same type week-over-week for
     * missed checkins and return the sum for the future week
     * @param gaugeType Gauge type id
     * @return Sum of weights
     */
    function _getSum(int128 gaugeType) internal returns (uint256) {
        uint256 t = timeSum[gaugeType];
        if (t > 0) {
            Point memory pt = pointsSum[gaugeType][t];
            uint256 _interval = interval;
            for (uint256 i; i < 500; ) {
                if (t > block.timestamp) break;
                t += _interval;
                uint256 dBias = pt.slope * _interval;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    uint256 dSlope = _changesSum[gaugeType][t];
                    pt.slope -= dSlope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                pointsSum[gaugeType][t] = pt;
                if (t > block.timestamp) timeSum[gaugeType] = t;

                unchecked {
                    ++i;
                }
            }
            return pt.bias;
        } else return 0;
    }

    /**
     * @notice Fill historic type weights week-over-week for missed checkins
     * and return the type weight for the future week
     * @param gaugeType Gauge type id
     * @return Type weight
     */
    function _getTypeWeight(int128 gaugeType) internal returns (uint256) {
        uint256 t = timeTypeWeight[gaugeType];
        if (t > 0) {
            uint256 w = pointsTypeWeight[gaugeType][t];
            uint256 _interval = interval;
            for (uint256 i; i < 500; ) {
                if (t > block.timestamp) break;
                t += _interval;
                pointsTypeWeight[gaugeType][t] = w;
                if (t > block.timestamp) timeTypeWeight[gaugeType] = t;

                unchecked {
                    ++i;
                }
            }
            return w;
        } else return 0;
    }

    /**
     * @notice Fill historic gauge weights week-over-week for missed checkins
     * and return the total for the future week
     * @param addr Gauge address
     * @return Gauge weight
     */
    function _getWeight(address addr) internal returns (uint256) {
        uint256 t = timeWeight[addr];
        if (t > 0) {
            Point memory pt = pointsWeight[addr][t];
            uint256 _interval = interval;
            for (uint256 i; i < 500; ) {
                if (t > block.timestamp) break;
                t += _interval;
                uint256 dBias = pt.slope * _interval;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    uint256 dSlope = _changesWeight[addr][t];
                    pt.slope -= dSlope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                pointsWeight[addr][t] = pt;
                if (t > block.timestamp) timeWeight[addr] = t;

                unchecked {
                    ++i;
                }
            }
            return pt.bias;
        } else return 0;
    }

    function _updateSlopeChanges(
        address addr,
        uint256 nextTime,
        int128 gaugeType,
        uint256 oldBias,
        uint256 newBias,
        VotedSlope memory oldSlope,
        VotedSlope memory newSlope
    ) internal {
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for next_time
        pointsWeight[addr][nextTime].bias = Math.max(_getWeight(addr) + newBias, oldBias) - oldBias;
        pointsSum[gaugeType][nextTime].bias = Math.max(_getSum(gaugeType) + newBias, oldBias) - oldBias;
        if (oldSlope.end > nextTime) {
            pointsWeight[addr][nextTime].slope =
                Math.max(pointsWeight[addr][nextTime].slope + newSlope.slope, oldSlope.slope) -
                oldSlope.slope;
            pointsSum[gaugeType][nextTime].slope =
                Math.max(pointsSum[gaugeType][nextTime].slope + newSlope.slope, oldSlope.slope) -
                oldSlope.slope;
        } else {
            pointsWeight[addr][nextTime].slope += newSlope.slope;
            pointsSum[gaugeType][nextTime].slope += newSlope.slope;
        }
        if (oldSlope.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            _changesWeight[addr][oldSlope.end] -= oldSlope.slope;
            _changesSum[gaugeType][oldSlope.end] -= oldSlope.slope;
        }
        // Add slope changes for new slopes
        _changesWeight[addr][newSlope.end] += newSlope.slope;
        _changesSum[gaugeType][newSlope.end] += newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][addr] = newSlope;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IVotingEscrowMigrator.sol";
import "./interfaces/IVotingEscrowDelegate.sol";
import "./libraries/Integers.sol";

/**
 * @title Voting Escrow
 * @author LevX ([email protected])
 * @notice Votes have a weight depending on time, so that users are
 *         committed to the future of (whatever they are voting for)
 * @dev Vote weight decays linearly over time. Lock time cannot be
 *      more than `MAXTIME`.
 * @dev Ported from vyper (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime

contract VotingEscrow is Ownable, ReentrancyGuard, IVotingEscrow {
    using SafeERC20 for IERC20;
    using Integers for int128;
    using Integers for uint256;

    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        int128 discount;
        uint256 start;
        uint256 end;
    }

    int128 public constant DEPOSIT_FOR_TYPE = 0;
    int128 public constant CRETE_LOCK_TYPE = 1;
    int128 public constant INCREASE_LOCK_AMOUNT = 2;
    int128 public constant INCREASE_UNLOCK_TIME = 3;
    uint256 internal constant MULTIPLIER = 1e18;

    uint256 public immutable override interval;
    uint256 public immutable override maxDuration;
    address public immutable override token;
    string public override name;
    string public override symbol;
    uint8 public immutable override decimals;

    address public override migrator;
    mapping(address => bool) public override isDelegate;

    uint256 public override supply;
    mapping(address => bool) public override migrated;
    mapping(address => address[]) public override delegateAt;
    mapping(address => LockedBalance) public override locked;
    uint256 public override epoch;

    mapping(uint256 => Point) public override pointHistory; // epoch -> unsigned point
    mapping(address => mapping(uint256 => Point)) public override userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint256) public override userPointEpoch;
    mapping(uint256 => int128) public override slopeChanges; // time -> signed slope change

    constructor(
        address _token,
        string memory _name,
        string memory _symbol,
        uint256 _interval,
        uint256 _maxDuration
    ) {
        token = _token;
        name = _name;
        symbol = _symbol;
        decimals = IERC20Metadata(_token).decimals();

        interval = _interval;
        maxDuration = (_maxDuration / _interval) * _interval; // rounded down to a multiple of interval

        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;
    }

    modifier beforeMigrated(address addr) {
        require(!migrated[addr], "VE: LOCK_MIGRATED");
        _;
    }

    modifier onlyDelegate {
        require(isDelegate[msg.sender], "VE: NOT_DELEGATE");
        _;
    }

    /**
     * @notice Check if the call is from an EOA or a whitelisted smart contract, revert if not
     */
    modifier authorized {
        if (msg.sender != tx.origin) {
            require(isDelegate[msg.sender], "VE: CONTRACT_NOT_DELEGATE");
        }
        _;
    }

    function delegateLength(address addr) external view returns (uint256) {
        return delegateAt[addr].length;
    }

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `addr`
     * @param addr Address of the user wallet
     * @return Value of the slope
     */
    function getLastUserSlope(address addr) external view override returns (int128) {
        uint256 uepoch = userPointEpoch[addr];
        return userPointHistory[addr][uepoch].slope;
    }

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function getCheckpointTime(address _addr, uint256 _idx) external view override returns (uint256) {
        return userPointHistory[_addr][_idx].ts;
    }

    /**
     * @notice Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function unlockTime(address _addr) external view override returns (uint256) {
        return locked[_addr].end;
    }

    function setMigrator(address _migrator) external override onlyOwner {
        require(migrator == address(0), "VE: MIGRATOR_SET");

        migrator = _migrator;

        emit SetMigrator(_migrator);
    }

    function setDelegate(address account, bool _isDelegate) external override onlyOwner {
        isDelegate[account] = _isDelegate;

        emit SetDelegate(account, _isDelegate);
    }

    /**
     * @notice Record global and per-user data to checkpoint
     * @param addr User's wallet address. No user checkpoint if 0x0
     * @param old_locked Pevious locked amount / end lock time for the user
     * @param new_locked New locked amount / end lock time for the user
     */
    function _checkpoint(
        address addr,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope;
        int128 new_dslope;
        uint256 _epoch = epoch;

        if (addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / maxDuration.toInt128();
                u_old.bias = u_old.slope * (old_locked.end - block.timestamp).toInt128();
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / maxDuration.toInt128();
                u_new.bias = u_new.slope * (new_locked.end - block.timestamp).toInt128();
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slopeChanges[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) new_dslope = old_dslope;
                else new_dslope = slopeChanges[new_locked.end];
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_epoch > 0) last_point = pointHistory[_epoch];
        uint256 last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = Point(last_point.bias, last_point.slope, last_point.ts, last_point.blk);
        uint256 block_slope; // dblock/dt
        if (block.timestamp > last_point.ts)
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        {
            // Go over weeks to fill history and calculate what the current point is
            uint256 t_i = (last_checkpoint / interval) * interval;
            for (uint256 i; i < 255; i++) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += interval;
                int128 d_slope;
                if (t_i > block.timestamp) t_i = block.timestamp;
                else d_slope = slopeChanges[t_i];
                last_point.bias -= last_point.slope * (t_i - last_checkpoint).toInt128();
                last_point.slope += d_slope;
                if (last_point.bias < 0)
                    // This can happen
                    last_point.bias = 0;
                if (last_point.slope < 0)
                    // This cannot happen - just in case
                    last_point.slope = 0;
                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk = initial_last_point.blk + (block_slope * (t_i - initial_last_point.ts)) / MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else pointHistory[_epoch] = last_point;
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) last_point.slope = 0;
            if (last_point.bias < 0) last_point.bias = 0;
        }

        // Record the changed point into history
        pointHistory[_epoch] = last_point;

        if (addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) old_dslope -= u_new.slope; // It was a new deposit, not extension
                slopeChanges[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slopeChanges[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }

            // Now handle user history
            uint256 user_epoch = userPointEpoch[addr] + 1;

            userPointEpoch[addr] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            userPointHistory[addr][user_epoch] = u_new;
        }
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @param _addr User's wallet address
     * @param _value Amount to deposit
     * @param _discount Amount to get discounted out of _value
     * @param unlock_time New time when to unlock the tokens, or 0 if unchanged
     * @param locked_balance Previous locked amount / timestamp
     */
    function _depositFor(
        address _addr,
        uint256 _value,
        uint256 _discount,
        uint256 unlock_time,
        LockedBalance memory locked_balance,
        int128 _type
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint256 supply_before = supply;

        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.discount, old_locked.start, old_locked.end) = (
            _locked.amount,
            _locked.discount,
            _locked.start,
            _locked.end
        );
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += (_value).toInt128();
        if (_discount != 0) _locked.discount += _discount.toInt128();
        if (unlock_time != 0) {
            if (_locked.start == 0) _locked.start = block.timestamp;
            _locked.end = unlock_time;
        }
        locked[_addr] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_addr, old_locked, _locked);

        if (_value > _discount) {
            IERC20(token).safeTransferFrom(_addr, address(this), _value - _discount);
        }

        emit Deposit(_addr, _value, _discount, _locked.end, _type, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    function _pushDelegate(address addr, address delegate) internal {
        bool found;
        address[] storage delegates = delegateAt[addr];
        for (uint256 i; i < delegates.length; ) {
            if (delegates[i] == delegate) found = true;
            unchecked {
                ++i;
            }
        }
        if (!found) delegateAt[addr].push(delegate);
    }

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external override {
        _checkpoint(address(0), LockedBalance(0, 0, 0, 0), LockedBalance(0, 0, 0, 0));
    }

    /**
     * @notice Deposit `_value` tokens for `_addr` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their locktime and deposit for a brand new user
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     */
    function depositFor(address _addr, uint256 _value) external override nonReentrant beforeMigrated(_addr) {
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(_addr, _value, 0, 0, _locked, DEPOSIT_FOR_TYPE);
    }

    /**
     * @notice Deposit `_value` tokens with `_discount` for `_addr` and lock for `_duration`
     * @dev Only delegates can creat a lock for someone else
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     * @param _discount Amount to get discounted out of _value
     * @param _duration Epoch time until tokens unlock from now
     */
    function createLockFor(
        address _addr,
        uint256 _value,
        uint256 _discount,
        uint256 _duration
    ) external override nonReentrant onlyDelegate beforeMigrated(_addr) {
        _pushDelegate(_addr, msg.sender);

        uint256 unlock_time = ((block.timestamp + _duration) / interval) * interval; // Locktime is rounded down to a multiple of interval
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_value >= _discount, "VE: DISCOUNT_TOO_HIGH");
        require(_locked.amount == 0, "VE: EXISTING_LOCK_FOUND");
        require(unlock_time > block.timestamp, "VE: UNLOCK_TIME_TOO_EARLY");
        require(unlock_time <= block.timestamp + maxDuration, "VE: UNLOCK_TIME_TOO_LATE");

        _depositFor(_addr, _value, _discount, unlock_time, _locked, CRETE_LOCK_TYPE);
    }

    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock for `_duration`
     * @param _value Amount to deposit
     * @param _duration Epoch time until tokens unlock from now
     */
    function createLock(uint256 _value, uint256 _duration)
        external
        override
        nonReentrant
        authorized
        beforeMigrated(msg.sender)
    {
        uint256 unlock_time = ((block.timestamp + _duration) / interval) * interval; // Locktime is rounded down to a multiple of interval
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_locked.amount == 0, "VE: EXISTING_LOCK_FOUND");
        require(unlock_time > block.timestamp, "VE: UNLOCK_TIME_TOO_EARLY");
        require(unlock_time <= block.timestamp + maxDuration, "VE: UNLOCK_TIME_TOO_LATE");

        _depositFor(msg.sender, _value, 0, unlock_time, _locked, CRETE_LOCK_TYPE);
    }

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param _addr User's wallet address
     * @param _value Amount of tokens to deposit and add to the lock
     * @param _discount Amount to get discounted out of _value
     */
    function increaseAmountFor(
        address _addr,
        uint256 _value,
        uint256 _discount
    ) external override nonReentrant onlyDelegate beforeMigrated(_addr) {
        _pushDelegate(_addr, msg.sender);

        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_value >= _discount, "VE: DISCOUNT_TOO_HIGH");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(_addr, _value, _discount, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _value) external override nonReentrant authorized beforeMigrated(msg.sender) {
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "VE: INVALID_VALUE");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(msg.sender, _value, 0, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    /**
     * @notice Extend the unlock time for `msg.sender` to `_duration`
     * @param _duration Increased epoch time for unlocking
     */
    function increaseUnlockTime(uint256 _duration)
        external
        override
        nonReentrant
        authorized
        beforeMigrated(msg.sender)
    {
        LockedBalance memory _locked = locked[msg.sender];
        uint256 unlock_time = ((_locked.end + _duration) / interval) * interval; // Locktime is rounded down to a multiple of interval

        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.discount == 0, "VE: LOCK_DISCOUNTED");
        require(unlock_time >= _locked.end + interval, "VE: UNLOCK_TIME_TOO_EARLY");
        require(unlock_time <= block.timestamp + maxDuration, "VE: UNLOCK_TIME_TOO_LATE");

        _depositFor(msg.sender, 0, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME);
    }

    /**
     * @notice Cancel the existing lock of `msg.sender` with penalty
     * @dev Only possible if the lock exists
     */
    function cancel() external override nonReentrant {
        LockedBalance memory _locked = locked[msg.sender];
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        uint256 penaltyRate = _penaltyRate(_locked.start, _locked.end);
        uint256 supply_before = _clear(_locked, penaltyRate);

        uint256 value = _locked.amount.toUint256();
        uint256 discount = _locked.discount.toUint256();

        IERC20(token).safeTransfer(msg.sender, ((value - discount) * (1e18 - penaltyRate)) / 1e18);

        emit Cancel(msg.sender, value, discount, penaltyRate, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function _penaltyRate(uint256 start, uint256 end) internal view returns (uint256 penalty) {
        penalty = (1e18 * (end - block.timestamp)) / (end - start);
        if (penalty < 1e18 / 2) penalty = 1e18 / 2;
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = locked[msg.sender];
        require(block.timestamp >= _locked.end, "VE: LOCK_NOT_EXPIRED");

        uint256 supply_before = _clear(_locked, 0);

        uint256 value = _locked.amount.toUint256();
        uint256 discount = _locked.discount.toUint256();

        if (value > discount) {
            IERC20(token).safeTransfer(msg.sender, value - discount);
        }

        emit Withdraw(msg.sender, value, discount, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function migrate() external override nonReentrant beforeMigrated(msg.sender) {
        require(migrator != address(0), "VE: MIGRATOR_NOT_SET");

        LockedBalance memory _locked = locked[msg.sender];
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        address[] memory delegates = delegateAt[msg.sender];
        uint256 supply_before = _clear(_locked, 0);

        uint256 value = _locked.amount.toUint256();
        uint256 discount = _locked.discount.toUint256();

        IVotingEscrowMigrator(migrator).migrate(
            msg.sender,
            _locked.amount,
            _locked.discount,
            _locked.start,
            _locked.end,
            delegates
        );
        migrated[msg.sender] = true;

        if (value > discount) {
            IERC20(token).safeTransfer(migrator, value - discount);
        }

        emit Migrate(msg.sender, value, discount, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function _clear(LockedBalance memory _locked, uint256 penaltyRate) internal returns (uint256 supply_before) {
        uint256 value = _locked.amount.toUint256();

        locked[msg.sender] = LockedBalance(0, 0, 0, 0);
        supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _locked, LockedBalance(0, 0, 0, 0));

        address[] storage delegates = delegateAt[msg.sender];
        for (uint256 i; i < delegates.length; ) {
            IVotingEscrowDelegate(delegates[i]).withdraw(msg.sender, penaltyRate);
            unchecked {
                ++i;
            }
        }
        delete delegateAt[msg.sender];
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /**
     * @notice Binary search to estimate timestamp for block number
     * @param _block Block to find
     * @param max_epoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function _findBlockEpoch(uint256 _block, uint256 max_epoch) internal view returns (uint256) {
        uint256 _min;
        uint256 _max = max_epoch;
        for (uint256 i; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= _block) _min = _mid;
            else _max = _mid - 1;
        }
        return _min;
    }

    function balanceOf(address addr) public view override returns (uint256) {
        return balanceOf(addr, block.timestamp);
    }

    /**
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function balanceOf(address addr, uint256 _t) public view override returns (uint256) {
        uint256 _epoch = userPointEpoch[addr];
        if (_epoch == 0) return 0;
        else {
            Point memory last_point = userPointHistory[addr][_epoch];
            last_point.bias -= last_point.slope * (_t - last_point.ts).toInt128();
            if (last_point.bias < 0) last_point.bias = 0;
            return last_point.bias.toUint256();
        }
    }

    /**
     * @notice Measure voting power of `addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address addr, uint256 _block) external view override returns (uint256) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number);

        // Binary search
        uint256 _min;
        uint256 _max = userPointEpoch[addr];
        for (uint256 i; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[addr][_mid].blk <= _block) _min = _mid;
            else _max = _mid - 1;
        }

        Point memory upoint = userPointHistory[addr][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = _findBlockEpoch(_block, max_epoch);
        Point memory point_0 = pointHistory[_epoch];
        uint256 d_block;
        uint256 d_t;
        if (_epoch < max_epoch) {
            Point memory point_1 = pointHistory[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint256 block_time = point_0.ts;
        if (d_block != 0) block_time += ((d_t * (_block - point_0.blk)) / d_block);

        upoint.bias -= upoint.slope * (block_time - upoint.ts).toInt128();
        if (upoint.bias >= 0) return upoint.bias.toUint256();
        else return 0;
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
        Point memory last_point = point;
        uint256 t_i = (last_point.ts / interval) * interval;
        for (uint256 i; i < 255; i++) {
            t_i += interval;
            int128 d_slope;
            if (t_i > t) t_i = t;
            else d_slope = slopeChanges[t_i];
            last_point.bias -= last_point.slope * (t_i - last_point.ts).toInt128();
            if (t_i == t) break;
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) last_point.bias = 0;
        return last_point.bias.toUint256();
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply(block.timestamp);
    }

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply(uint256 t) public view override returns (uint256) {
        uint256 _epoch = epoch;
        Point memory last_point = pointHistory[_epoch];
        return _supplyAt(last_point, t);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view override returns (uint256) {
        require(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 target_epoch = _findBlockEpoch(_block, _epoch);

        Point memory point = pointHistory[target_epoch];
        uint256 dt;
        if (target_epoch < _epoch) {
            Point memory point_next = pointHistory[target_epoch + 1];
            if (point.blk != point_next.blk)
                dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
        } else if (point.blk != block.number)
            dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
        // Now dt contains info on how far are we beyond point

        return _supplyAt(point, point.ts + dt);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVotingEscrowMigrator {
    function migrate(
        address account,
        int128 amount,
        int128 discount,
        uint256 start,
        uint256 end,
        address[] calldata delegates
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVotingEscrowDelegate {
    event Withdraw(address indexed addr, uint256 amount, uint256 penaltyRate);

    function withdraw(address addr, uint256 penaltyRate) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IVotingEscrowMigrator.sol";
import "../libraries/Integers.sol";

contract VotingEscrowMigratorMock is IVotingEscrowMigrator {
    using SafeERC20 for IERC20;
    using Integers for int128;
    using Integers for uint256;

    struct LockedBalance {
        int128 amount;
        int128 discount;
        uint256 start;
        uint256 end;
    }

    address public immutable token;
    mapping(address => LockedBalance) public locked;
    mapping(address => address[]) public delegates;

    constructor(address ve) {
        token = IVotingEscrow(ve).token();
    }

    function migrate(
        address account,
        int128 amount,
        int128 discount,
        uint256 start,
        uint256 end,
        address[] calldata _delegates
    ) external override {
        locked[account] = LockedBalance(amount, discount, start, end);
        delegates[account] = _delegates;
    }

    function withdraw() external {
        LockedBalance memory _locked = locked[msg.sender];
        require(block.timestamp >= _locked.end, "VE: LOCK_NOT_EXPIRED");

        uint256 value = _locked.amount.toUint256();
        uint256 discount = _locked.discount.toUint256();

        locked[msg.sender] = LockedBalance(0, 0, 0, 0);

        if (value > discount) {
            IERC20(token).safeTransfer(msg.sender, value - discount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./VotingEscrowDelegate.sol";
import "./interfaces/IVotingEscrowMigrator.sol";

contract LPVotingEscrowDelegate is VotingEscrowDelegate {
    using SafeERC20 for IERC20;

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    bool internal immutable isToken1;
    uint256 public immutable minAmount;
    uint256 public immutable maxBoost;

    uint256 public lockedTotal;
    mapping(address => uint256) public locked;

    constructor(
        address _ve,
        address _lpToken,
        address _discountToken,
        bool _isToken1,
        uint256 _minAmount,
        uint256 _maxBoost
    ) VotingEscrowDelegate(_ve, _lpToken, _discountToken) {
        isToken1 = _isToken1;
        minAmount = _minAmount;
        maxBoost = _maxBoost;
    }

    function _createLock(
        uint256 amount,
        uint256 duration,
        bool discounted
    ) internal override {
        require(amount >= minAmount, "LSVED: AMOUNT_TOO_LOW");

        super._createLock(amount, duration, discounted);

        lockedTotal += amount;
        locked[msg.sender] += amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _increaseAmount(uint256 amount, bool discounted) internal override {
        require(amount >= minAmount, "LSVED: AMOUNT_TOO_LOW");

        super._increaseAmount(amount, discounted);

        lockedTotal += amount;
        locked[msg.sender] += amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _getAmounts(uint256 amount, uint256)
        internal
        view
        override
        returns (uint256 amountVE, uint256 amountToken)
    {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(token).getReserves();
        uint256 reserve = isToken1 ? uint256(reserve1) : uint256(reserve0);

        uint256 totalSupply = IUniswapV2Pair(token).totalSupply();
        uint256 _amountToken = (amount * reserve) / totalSupply;

        amountVE = _amountToken + (_amountToken * maxBoost * (totalSupply - lockedTotal)) / totalSupply / totalSupply;
        uint256 upperBound = (_amountToken * 333) / 10;
        if (amountVE > upperBound) {
            amountVE = upperBound;
        }
        amountToken = 0;
    }

    function withdraw(address addr, uint256 penaltyRate) external override {
        require(msg.sender == ve, "LSVED: FORBIDDEN");

        uint256 amount = locked[addr];
        require(amount > 0, "LSVED: LOCK_NOT_FOUND");

        lockedTotal -= amount;
        locked[addr] = 0;
        IERC20(token).safeTransfer(addr, (amount * (1e18 - penaltyRate)) / 1e18);

        emit Withdraw(addr, amount, penaltyRate);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/IVotingEscrowDelegate.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/INFT.sol";

abstract contract VotingEscrowDelegate is IVotingEscrowDelegate {
    address public immutable ve;
    address public immutable token;
    address public immutable discountToken;

    uint256 internal immutable _maxDuration;
    uint256 internal immutable _interval;

    event CreateLock(address indexed account, uint256 amount, uint256 discount, uint256 indexed locktime);
    event IncreaseAmount(address indexed account, uint256 amount, uint256 discount);

    constructor(
        address _ve,
        address _token,
        address _discountToken
    ) {
        ve = _ve;
        token = _token;
        discountToken = _discountToken;

        _maxDuration = IVotingEscrow(_ve).maxDuration();
        _interval = IVotingEscrow(ve).interval();
    }

    modifier eligibleForDiscount {
        require(INFT(discountToken).balanceOf(msg.sender) > 0, "VED: DISCOUNT_TOKEN_NOT_OWNED");
        _;
    }

    function createLockDiscounted(uint256 amount, uint256 duration) external eligibleForDiscount {
        _createLock(amount, duration, true);
    }

    function createLock(uint256 amount, uint256 duration) external {
        _createLock(amount, duration, false);
    }

    function _createLock(
        uint256 amount,
        uint256 duration,
        bool discounted
    ) internal virtual {
        require(duration <= _maxDuration, "VED: DURATION_TOO_LONG");

        uint256 unlockTime = ((block.timestamp + duration) / _interval) * _interval; // rounded down to a multiple of interval
        uint256 _duration = unlockTime - block.timestamp;
        (uint256 amountVE, uint256 amountToken) = _getAmounts(amount, _duration);
        if (discounted) {
            amountVE = (amountVE * 100) / 90;
        }

        emit CreateLock(msg.sender, amountVE, amountVE - amountToken, unlockTime);
        IVotingEscrow(ve).createLockFor(msg.sender, amountVE, amountVE - amountToken, _duration);
    }

    function increaseAmountDiscounted(uint256 amount) external eligibleForDiscount {
        _increaseAmount(amount, true);
    }

    function increaseAmount(uint256 amount) external {
        _increaseAmount(amount, false);
    }

    function _increaseAmount(uint256 amount, bool discounted) internal virtual {
        uint256 unlockTime = IVotingEscrow(ve).unlockTime(msg.sender);
        require(unlockTime > 0, "VED: LOCK_NOT_FOUND");

        (uint256 amountVE, uint256 amountToken) = _getAmounts(amount, unlockTime - block.timestamp);
        if (discounted) {
            amountVE = (amountVE * 100) / 90;
        }

        emit IncreaseAmount(msg.sender, amountVE, amountVE - amountToken);
        IVotingEscrow(ve).increaseAmountFor(msg.sender, amountVE, amountVE - amountToken);
    }

    function _getAmounts(uint256 amount, uint256 duration)
        internal
        view
        virtual
        returns (uint256 amountVE, uint256 amountToken);

    function withdraw(address, uint256) external virtual override {
        // Empty
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function burn(
        uint256 tokenId,
        uint256 label,
        bytes32 data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/INFT.sol";

contract NFTMock is ERC721, Ownable, INFT {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Empty
    }

    function balanceOf(address owner) public view override(ERC721, INFT) returns (uint256 balance) {
        return ERC721.balanceOf(owner);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, INFT) {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyOwner {
        _safeMint(to, tokenId, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external override onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i], data);
        }
    }

    function burn(
        uint256 tokenId,
        uint256,
        bytes32
    ) external override {
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFTGaugeFactory.sol";
import "./interfaces/INFTGauge.sol";
import "./interfaces/IVotingEscrow.sol";
import "./libraries/NFTs.sol";

contract EarlyAccess is Ownable {
    event AddCollection(address indexed collection);
    event WhitelistNFT(address indexed collection, uint256 tokenId);

    uint256 public immutable amount;
    uint256 public immutable limit;
    address public factory;
    address public votingEscrow;
    uint256 public maxDuration;

    uint256 public totalNumberWhitelisted;
    uint256 public launchedAt;
    mapping(address => bool) public collections;
    mapping(address => mapping(uint256 => bool)) public whitelisted;
    mapping(address => mapping(uint256 => bool)) public wrapped;

    constructor(uint256 _amount, uint256 _limit) {
        amount = _amount;
        limit = _limit;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;

        votingEscrow = INFTGaugeFactory(_factory).votingEscrow();
        maxDuration = IVotingEscrow(_factory).maxDuration();
    }

    function launch() external onlyOwner {
        require(launchedAt == 0, "EA: LAUNCHED");

        launchedAt = block.timestamp;
    }

    function addCollections(address[] calldata _collections) external onlyOwner {
        require(launchedAt == 0, "EA: LAUNCHED");
        for (uint256 i; i < _collections.length; i++) {
            collections[_collections[i]] = true;
            emit AddCollection(_collections[i]);
        }
    }

    function whitelistNFTs(address collection, uint256[] calldata tokenIds) external {
        require(launchedAt == 0, "EA: LAUNCHED");
        require(collections[collection], "EA: COLLECTION_NOT_ALLOWED");
        require(totalNumberWhitelisted + tokenIds.length <= limit, "EA: LIMIT_REACHED");

        for (uint256 i; i < tokenIds.length; i++) {
            require(NFTs.ownerOf(collection, tokenIds[i]) == msg.sender, "EA: FORBIDDEN");
            whitelisted[collection][tokenIds[i]] = true;

            emit WhitelistNFT(collection, tokenIds[i]);
        }
        totalNumberWhitelisted += tokenIds.length;
    }

    function wrapNFT(
        address collection,
        uint256 tokenId,
        uint256 dividendRatio
    ) external {
        require(launchedAt > 0, "EA: NOT_LAUNCHED");
        require(whitelisted[collection][tokenId], "EA: NOT_WHITELISTED");
        require(!wrapped[collection][tokenId], "EA: WRAPPED");

        wrapped[collection][tokenId] = true;

        NFTs.safeTransferFrom(collection, msg.sender, address(this), tokenId);

        address gauge = INFTGaugeFactory(factory).gauges(collection);
        INFTGauge(gauge).wrap(tokenId, dividendRatio, msg.sender, 0);

        IVotingEscrow(votingEscrow).createLockFor(msg.sender, amount, amount, maxDuration);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./VotingEscrowDelegate.sol";

contract BoostedVotingEscrowDelegate is VotingEscrowDelegate {
    uint256 public immutable minDuration;
    uint256 public immutable maxBoost;
    uint256 public immutable deadline;

    constructor(
        address _ve,
        address _token,
        address _discountToken,
        uint256 _minDuration,
        uint256 _maxBoost,
        uint256 _deadline
    ) VotingEscrowDelegate(_ve, _token, _discountToken) {
        minDuration = _minDuration;
        maxBoost = _maxBoost;
        deadline = _deadline;
    }

    function _createLock(
        uint256 amountToken,
        uint256 duration,
        bool discounted
    ) internal override {
        require(block.timestamp < deadline, "BVED: EXPIRED");
        require(duration >= minDuration, "BVED: DURATION_TOO_SHORT");

        super._createLock(amountToken, duration, discounted);
    }

    function _increaseAmount(uint256 amountToken, bool discounted) internal override {
        require(block.timestamp < deadline, "BVED: EXPIRED");

        super._increaseAmount(amountToken, discounted);
    }

    function _getAmounts(uint256 amount, uint256 duration)
        internal
        view
        override
        returns (uint256 amountVE, uint256 amountToken)
    {
        amountVE = (amount * maxBoost * duration) / _maxDuration;
        amountToken = amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";

contract TokenURIRenderer {
    using Strings for uint256;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function render(address nftContract, uint256 tokenId) external view returns (string memory output) {
        string memory _name;
        try IERC721Metadata(nftContract).name() returns (string memory name) {
            _name = name;
        } catch {
            _name = uint256(uint160(nftContract)).toHexString(20);
        }
        string memory color = _toColor(nftContract);
        output = string(
            abi.encodePacked(
                '<svg width="600px" height="600px" viewBox="0 0 600 600" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><polygon points="0 0 200 0 200 232 0 232"></polygon></defs><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g><rect fill="#FFFFFF" fill-rule="nonzero" x="0" y="0" width="600" height="599.999985"></rect><rect fill="',
                color,
                '" fill-rule="nonzero" x="0" y="0" width="600" height="599.999985"></rect><g transform="translate(79.843749, 99.999999)"><g><mask fill="white"><use xlink:href="#path-1"></use></mask><g></g><path d="M199.578125,146.468749 C199.578125,146.119792 199.442709,145.786459 199.192709,145.536459 L165.875,112.161459 L191.755209,86.2239587 C191.947917,86.0468747 192.062501,85.8125 192.114584,85.5625 L199.546876,48.5260413 C199.557292,48.494792 199.505209,48.4739587 199.505209,48.432292 C199.557292,48.0364587 199.494792,47.635416 199.192709,47.3333333 L153.432292,1.48437467 C152.942709,0.989584 152.072917,0.989584 151.578125,1.48437467 L103.505209,49.6718747 L55.432292,1.48437467 C54.9427093,0.989584 54.0729173,1 53.5781253,1.494792 L7.81770933,47.4583333 C7.671876,47.5937493 7.671876,47.7812507 7.609376,47.9583333 C7.57812533,48.0364587 7.47395867,48.0468747 7.45312533,48.119792 L0.0208346667,85.260416 C-0.0624986667,85.6875 0.0625013333,86.130208 0.375,86.442708 L33.5781253,119.713541 L7.807292,145.536459 C7.671876,145.671875 7.66145867,145.869792 7.59895867,146.046875 C7.56770933,146.119792 7.46354267,146.130208 7.45312533,146.218749 L0.0208346667,183.359375 C-0.0624986667,183.786459 0.0625013333,184.229167 0.375,184.541667 L46.1354173,230.390625 C46.1979173,230.453125 46.302084,230.442708 46.3854173,230.494792 C46.427084,230.526041 46.3958347,230.593749 46.4479173,230.625 C46.6458347,230.729167 46.859376,230.781251 47.0677093,230.781251 C47.1927093,230.781251 47.3177093,230.760416 47.4427093,230.729167 C47.5260427,230.708333 47.5260427,230.593749 47.5989587,230.552083 C47.7239587,230.484375 47.8854173,230.494792 47.989584,230.380208 L96.0208347,182.171875 L144.156251,230.390625 C144.218751,230.453125 144.322917,230.442708 144.406251,230.494792 C144.447917,230.526041 144.416667,230.593749 144.468751,230.625 C144.666667,230.729167 144.880209,230.781251 145.088543,230.781251 C145.213543,230.781251 145.338543,230.760416 145.463543,230.718749 C145.536459,230.697917 145.536459,230.604167 145.598959,230.572917 C145.734376,230.505208 145.906251,230.505208 146.010417,230.401041 L191.765625,184.552083 C191.958333,184.364584 192.072917,184.135416 192.125,183.880208 L199.557292,146.739584 C199.567709,146.708333 199.515625,146.6875 199.515625,146.645833 C199.515625,146.583333 199.578125,146.531251 199.578125,146.468749 Z M189.630209,84.6614587 L164.031251,110.3125 L151.119792,97.375 L196.135417,52.2708333 L189.630209,84.6614587 Z M49.2031253,225.463541 L55.7031253,192.979167 L78.984376,169.656251 L101.421876,147.171875 L94.9010427,179.588541 L49.2031253,225.463541 Z M189.630209,182.968749 L147.203125,225.484375 L151.286459,204.833333 L153.609376,193.083333 L196.135417,150.473959 L189.630209,182.968749 Z M152.406251,190.567708 L104.427084,142.489584 C104.427084,142.489584 104.427084,142.489584 104.416667,142.489584 L104.291667,142.364584 C104.041667,142.135416 103.713543,142.010416 103.390625,142.010416 C103.057292,142.010416 102.718751,142.145833 102.468751,142.385416 L54.489584,190.458333 L10.5833333,146.468749 L36.354168,120.656251 C36.354168,120.656251 36.364584,120.656251 36.364584,120.656251 L58.5625013,98.4166667 C59.0781253,97.9010413 59.0781253,97.0729173 58.5625013,96.557292 L10.5937507,48.380208 L54.5,4.27083333 L102.583333,52.4635413 C103.078125,52.9531253 103.947917,52.9531253 104.437501,52.4635413 L152.520835,4.27083333 L196.427084,48.2656253 L181.234376,63.5 L148.354168,96.442708 C148.093751,96.692708 147.958333,97.0416667 147.958333,97.375 C147.958333,97.7135413 148.083333,98.0468747 148.343751,98.3020827 L163.109376,113.093749 C163.109376,113.104167 163.109376,113.104167 163.109376,113.104167 L196.416667,146.468749 L152.406251,190.567708 Z" fill="#FFFFFF" fill-rule="nonzero" mask="url(#mask-2)"></path></g><path d="M147.958333,97.375 C147.958333,97.0416667 148.083333,96.7031253 148.343751,96.442708 L181.223959,63.5 L196.416667,48.2656253 L152.510417,4.27083333 L104.437501,52.4635413 C103.947917,52.9531253 103.078125,52.9531253 102.583333,52.4635413 L54.5,4.27083333 L10.5937507,48.380208 L58.5729173,96.557292 C59.0885427,97.0729173 59.0885427,97.9010413 58.5729173,98.4166667 L36.375,120.656251 C36.375,120.656251 36.364584,120.656251 36.364584,120.656251 L10.5937507,146.468749 L54.5,190.458333 L102.479168,142.385416 C102.729168,142.145833 103.067709,142.010416 103.401043,142.010416 C103.723959,142.010416 104.052084,142.135416 104.302084,142.364584 L104.427084,142.489584 C104.427084,142.489584 104.427084,142.489584 104.437501,142.489584 L152.416667,190.567708 L196.427084,146.468749 L163.119792,113.104167 C163.119792,113.104167 163.119792,113.104167 163.119792,113.093749 L148.354168,98.3020827 C148.093751,98.0468747 147.958333,97.7135413 147.958333,97.375 Z" fill="',
                color,
                '" fill-rule="nonzero"></path></g></g><text font-family="Arial-BoldMT, Arial" font-size="48" font-weight="bold" fill="#FFFFFF"><tspan x="79.5" y="404">Wrapped</tspan><tspan x="79.5" y="457">',
                _name,
                '</tspan><tspan x="79.5" y="510">#',
                tokenId.toString(),
                "</tspan></text></g></svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Wrapped ',
                        _name,
                        " #",
                        tokenId.toString(),
                        '", "description": "Wrapped NFT that earns passive LEVX yield in proportional to the THANO$ staked together", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _toColor(address addr) internal pure returns (string memory) {
        uint160 value = uint160(addr);
        bytes memory buffer = new bytes(7);
        for (uint256 i = 6; i > 0; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "TURIR: HEX_LENGTH_INSUFFICIENT");
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}