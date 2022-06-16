// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IDistributor.sol";
import "./interface/IGovernance.sol";
import "./interface/IERC20Meta.sol";
import "./interface/IWrapped.sol";
import "./library/LibTrade.sol";
import "./library/LibTransfer.sol";


contract OscilloExchange is Ownable {
    using LibTrade for LibTrade.MatchExecution;
    using LibTransfer for IERC20Meta;

    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 private constant _DOMAIN_NAME = 0xd8847acffb1e80c967781c9cefc950c79c285c67014ab8ca7bfb053adcb94e20;

    uint private constant GAS_EXPECTATION_BUFFERED = 270000;
    uint private constant RESERVE_MAX = 2500;
    uint private constant RESERVE_DENOM = 1000000;
    uint private constant PRICE_DENOM = 1000000;

    bytes32 private immutable _domainSeparator;
    mapping(uint => uint) private _fills;
    mapping(address => bool) private _executors;

    IGovernance public governance;
    IDistributor public distributor;
    IWrapped public immutable nativeToken;

    event Executed(uint indexed matchId, uint[3] askTransfers, uint[3] bidTransfers);
    event Cancelled(uint indexed matchId, uint code);

    modifier onlyExecutor {
        require(msg.sender != address(0) && _executors[msg.sender], "!executor");
        _;
    }

    receive() external payable {}

    constructor(address _governance, address _nativeToken) {
        _domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, _DOMAIN_NAME, _DOMAIN_VERSION, block.chainid, address(this)));
        governance = IGovernance(_governance);
        nativeToken = IWrapped(_nativeToken);
    }

    /** Views **/

    function toAmountQuote(address base, address quote, uint amount, uint price) public view returns (uint) {
        return amount * price * (10 ** IERC20Meta(quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(base).decimals());
    }

    function toAmountsInOut(LibTrade.MatchExecution memory exec) public view returns (uint[2] memory askTransfers, uint[2] memory bidTransfers) {
        uint baseUnit = 10 ** IERC20Meta(exec.base).decimals();
        uint quoteUnit = 10 ** IERC20Meta(exec.quote).decimals();

        uint bidReserve = exec.amount * exec.reserve / RESERVE_DENOM;
        uint askReserve = bidReserve * exec.price * quoteUnit / PRICE_DENOM / baseUnit;
        uint amountQ = exec.amount * exec.price * quoteUnit / PRICE_DENOM / baseUnit;
        askTransfers = [exec.amount, amountQ - askReserve];
        bidTransfers = [amountQ, exec.amount - bidReserve];
    }

    function reserves(address base, address quote, uint amount, uint price, uint reserve) public view returns (uint askReserve, uint bidReserve) {
        bidReserve = amount * (reserve > RESERVE_MAX ? RESERVE_MAX : reserve) / RESERVE_DENOM;
        askReserve = toAmountQuote(base, quote, bidReserve, price);
    }

    function txCosts(LibTrade.MatchExecution memory exec, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Meta(exec.base).decimals();
        uint txCost = gasprice * gasUsed * exec.priceN / exec.price / (10 ** (18 - baseDecimals));
        askTx = _fills[exec.ask.id] == 0 ? txCost * exec.price * (10 ** IERC20Meta(exec.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = _fills[exec.bid.id] == 0 ? txCost : 0;
    }

    function acceptance(LibTrade.MatchExecution[] memory chunk, uint gasprice) public view returns (LibTrade.Acceptance[] memory) {
        LibTrade.Acceptance[] memory accepts = new LibTrade.Acceptance[](chunk.length);
        for (uint i = 0; i < chunk.length; i++) {
            LibTrade.MatchExecution memory e = chunk[i];
            accepts[i].mid = e.mid;

            if (!e.recover(_domainSeparator) || e.reserve > RESERVE_MAX) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxSignature);
            if (e.price < e.ask.lprice || e.price > e.bid.lprice) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxPrice);
            if (e.ask.amount < _fills[e.ask.id] + e.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskFilled);
            if (e.bid.amount < _fills[e.bid.id] + e.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidFilled);

            uint amountQ = toAmountQuote(e.base, e.quote, e.amount, e.price);
            (uint askReserve, uint bidReserve) = reserves(e.base, e.quote, e.amount, e.price, e.reserve);
            (uint askTx, uint bidTx) = txCosts(e, gasprice, GAS_EXPECTATION_BUFFERED);
            if (askReserve + askTx > amountQ) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskCost);
            if (bidReserve + bidTx > e.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidCost);

            (uint[2] memory askTransfers, uint[2] memory bidTransfers) = toAmountsInOut(e);
            if (IERC20Meta(e.base).available(e.ask.account, address(this)) < askTransfers[0]) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskBalance);
            if (IERC20Meta(e.quote).available(e.bid.account, address(this)) < bidTransfers[0]) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidBalance);

            accepts[i].askTransfers = [askTransfers[0], askTransfers[1], askTx];
            accepts[i].bidTransfers = [bidTransfers[0], bidTransfers[1], bidTx];
        }
        return accepts;
    }

    /** Interactions **/

    function execute(LibTrade.MatchExecution[] calldata chunk, uint gasUsed) external onlyExecutor {
        gasUsed = gasUsed == 0 ? GAS_EXPECTATION_BUFFERED : gasUsed;
        for (uint i = 0; i < chunk.length; i++) {
            uint code;
            LibTrade.MatchExecution memory e = chunk[i];

            uint amountQ = e.amount * e.price * (10 ** IERC20Meta(e.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(e.base).decimals());
            if (IERC20Meta(e.base).available(e.ask.account, address(this)) < e.amount) code = code | (1 << LibTrade.CodeIdxAskBalance);
            if (IERC20Meta(e.quote).available(e.bid.account, address(this)) < amountQ) code = code | (1 << LibTrade.CodeIdxBidBalance);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            if (!e.recover(_domainSeparator) || e.reserve > RESERVE_MAX) code = code | (1 << LibTrade.CodeIdxSignature);
            if (e.price < e.ask.lprice || e.price > e.bid.lprice) code = code | (1 << LibTrade.CodeIdxPrice);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            (uint askFilled, uint bidFilled) = (_fills[e.ask.id], _fills[e.bid.id]);
            if (e.ask.amount < askFilled + e.amount) code = code | (1 << LibTrade.CodeIdxAskFilled);
            if (e.bid.amount < bidFilled + e.amount) code = code | (1 << LibTrade.CodeIdxBidFilled);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            uint bidReserve = e.amount * e.reserve / RESERVE_DENOM;
            uint askReserve = bidReserve * e.price * (10 ** IERC20Meta(e.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(e.base).decimals());
            (uint askTx, uint bidTx) = _txCosts(e, askFilled, bidFilled, tx.gasprice, gasUsed);
            if (askReserve + askTx > amountQ) code = code | (1 << LibTrade.CodeIdxAskCost);
            if (bidReserve + bidTx > e.amount) code = code | (1 << LibTrade.CodeIdxBidCost);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            _fills[e.ask.id] = askFilled + e.amount;
            _fills[e.bid.id] = bidFilled + e.amount;

            IERC20Meta(e.base).safeTransferFrom(e.ask.account, address(this), e.amount);
            IERC20Meta(e.quote).safeTransferFrom(e.bid.account, address(this), amountQ);

            IERC20Meta(e.quote).safeTransfer(e.ask.account, amountQ - askReserve - askTx);
            if (e.unwrap && e.base == address(nativeToken)) {
                uint balance = address(this).balance;
                nativeToken.withdraw(e.amount - bidReserve - bidTx);
                LibTransfer.safeTransferETH(e.bid.account, address(this).balance - balance);
            } else {
                IERC20Meta(e.base).safeTransfer(e.bid.account, e.amount - bidReserve - bidTx);
            }

            if (askTx > 0) IERC20Meta(e.quote).safeTransfer(msg.sender, askTx);
            if (bidTx > 0) IERC20Meta(e.base).safeTransfer(msg.sender, bidTx);
            emit Executed(e.mid, [e.amount, amountQ - askReserve, askTx], [amountQ, e.amount - bidReserve, bidTx]);
        }
    }

    /** Restricted **/

    function setExecutor(address target, bool on) external onlyOwner {
        require(target != address(0), "!target");
        _executors[target] = on;
    }

    function setDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != address(0) && newDistributor != address(distributor), "!distributor");
        if (address(distributor) != address(0)) {
            IERC20Meta(distributor.rewardToken()).safeApprove(address(distributor), 0);
        }

        distributor = IDistributor(newDistributor);
        IERC20Meta rewardToken = IERC20Meta(distributor.rewardToken());
        rewardToken.safeApprove(address(distributor), 0);
        rewardToken.safeApprove(address(distributor), type(uint).max);
    }

    function distribute(uint checkpoint, uint accVolume, uint rewardAmount) external onlyOwner {
        require(address(distributor) != address(0), "!distributor");
        governance.notifyAccVolumeUpdated(checkpoint, accVolume);
        distributor.notifyRewardDistributed(rewardAmount);
    }

    function sweep(address[] calldata tokens) external onlyOwner {
        address rewardToken = distributor.rewardToken();
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == rewardToken) continue;

            IERC20Meta token = IERC20Meta(tokens[i]);
            uint leftover = token.balanceOf(address(this));
            if (leftover > 0) token.safeTransfer(owner(), leftover);
        }
    }

    /** Privates **/

    function _txCosts(LibTrade.MatchExecution memory exec, uint askFilled, uint bidFilled, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Meta(exec.base).decimals();
        uint txCost = gasprice * gasUsed * exec.priceN / exec.price / (10 ** (18 - baseDecimals));
        askTx = askFilled == 0 ? txCost * exec.price * (10 ** IERC20Meta(exec.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = bidFilled == 0 ? txCost : 0;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IDistributor {
    function rewardToken() external view returns (address);
    function reserves() external view returns (uint);

    function stake(uint amount) external;
    function unstake(uint amount) external;
    function claim() external;
    function exit() external;

    function notifyRewardDistributed(uint rewardAmount) external;
    function stakeBehalf(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IGovernance {
    function notifyAccVolumeUpdated(uint checkpoint, uint accVolumeX2) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IERC20Meta {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWrapped {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


library LibTrade {
    bytes32 constant _ORDER_TYPEHASH = 0x287d88810c333c982eb76bb0816bf9f46aed64f1f5378d80081fbfdc7928ab5e;

    uint constant CodeIdxSignature = 7;
    uint constant CodeIdxPrice = 6;
    uint constant CodeIdxAskFilled = 5;
    uint constant CodeIdxBidFilled = 4;
    uint constant CodeIdxAskCost = 3;
    uint constant CodeIdxBidCost = 2;
    uint constant CodeIdxAskBalance = 1;
    uint constant CodeIdxBidBalance = 0;

    /// @dev code [signature|price|ask.fill|bid.fill|ask.cost|bid.cost|ask.available|bid.available]
    struct Acceptance {
        uint mid;
        uint code;
        uint[3] askTransfers;
        uint[3] bidTransfers;
    }

    struct Order {
        address account;
        address tokenIn;
        address tokenOut;
        uint amount;
        uint lprice;
    }

    struct OrderPacked {
        uint id;
        address account;
        uint amount;
        uint lprice;
        bytes sig;
    }

    struct MatchExecution {
        uint mid;
        address base;
        address quote;
        OrderPacked ask;
        OrderPacked bid;
        uint amount;
        uint price;
        uint priceN;
        uint reserve;
        bool unwrap;
    }

    function recover(MatchExecution memory exec, bytes32 domainSeparator) internal pure returns (bool) {
        Order memory ask = Order(exec.ask.account, exec.base, exec.quote, exec.ask.amount, exec.ask.lprice);
        Order memory bid = Order(exec.bid.account, exec.quote, exec.base, exec.bid.amount, exec.bid.lprice);
        return recoverOrder(ask, domainSeparator, exec.ask.sig) && recoverOrder(bid, domainSeparator, exec.bid.sig);
    }

    function recoverOrder(Order memory order, bytes32 domainSeparator, bytes memory signature) private pure returns (bool) {
        require(signature.length == 65, "invalid signature length");

        bytes32 structHash;
        bytes32 orderDigest;

        // Order struct (5 fields) and type hash (5 + 1) * 32 = 192
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, _ORDER_TYPEHASH)
            structHash := keccak256(dataStart, 192)
            mstore(dataStart, temp)
        }

        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");

        address signer;

        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, "invalid signature 'v' value");
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderDigest)), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "invalid signature 'v' value");
            signer = ecrecover(orderDigest, v, r, s);
        }
        return signer != address(0) && signer == order.account;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "../interface/IERC20Meta.sol";

library LibTransfer {
    function available(IERC20Meta token, address owner, address spender) internal view returns (uint) {
        uint _allowance = token.allowance(owner, spender);
        uint _balance = token.balanceOf(owner);
        return _allowance < _balance ? _allowance : _balance;
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }

    function safeApprove(IERC20Meta token, address to, uint value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(IERC20Meta token, address to, uint value) internal {
        bytes4 selector_ = token.transfer.selector;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(_getLastTransferResult(token), "!safeTransfer");
    }

    function safeTransferFrom(IERC20Meta token, address from, address to, uint value) internal {
        bytes4 selector_ = token.transferFrom.selector;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(_getLastTransferResult(token), "!safeTransferFrom");
    }

    function _getLastTransferResult(IERC20Meta token) private view returns (bool success) {
        assembly {
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            case 0 {
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "!contract")
                }
                success := 1
            }
            case 32 {
                returndatacopy(0, 0, returndatasize())
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "!transferResult")
            }
        }
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