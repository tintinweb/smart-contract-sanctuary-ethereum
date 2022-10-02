// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IUniswap.sol";
import "./Types.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract AmplifiTransistor is Ownable, ReentrancyGuard {
    uint16 public maxMonths = 1;
    uint16 public maxTransistorsPerMinter = 48;
    uint256 public gracePeriod = 30 days;

    uint256 public totalTransistors = 0;
    mapping(uint256 => Types.Transistor) public transistors;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => uint256)) public ownedTransistors;
    mapping(uint256 => uint256) public ownedTransistorsIndex;

    uint256 public creationFee = 0.004 ether;
    uint256 public renewalFee = 0.004 ether;
    uint256 public refundFee = 0.12 ether;
    uint256 public mintPrice = 6e18;
    uint256 public refundAmount = 6e18;
    address public burnAddress;

    uint256[20] public rates = [
        169056603773,
        151305660376,
        135418566037,
        121199616603,
        108473656860,
        97083922889,
        86890110986,
        77766649332,
        69601151153,
        62293030282,
        55752262102,
        49898274581,
        44658955750,
        39969765396,
        35772940030,
        32016781327,
        28655019287,
        25646242262,
        20543281208,
        17236591470
    ];

    IAmplifi public immutable amplifi;
    IUniswapV2Router02 public immutable router;
    IERC20 public immutable USDC;

    Types.TransistorFeeRecipients public feeRecipients;

    uint16 public claimFee = 600;
    uint16 public mintBurn = 9_000;
    uint16 public mintLP = 1_000;
    // Basis for above fee values
    uint16 public constant bps = 10_000;

    constructor(
        IAmplifi _amplifi,
        IUniswapV2Router02 _router,
        IERC20 _usdc,
        address _burnAddress,
        address _standardFeeRecipient,
        address _taxRecipient,
        address _operations,
        address _developers
    ) {
        amplifi = _amplifi;
        router = _router;
        USDC = _usdc;
        burnAddress = _burnAddress;

        feeRecipients = Types.TransistorFeeRecipients(
            _standardFeeRecipient,
            _taxRecipient,
            _standardFeeRecipient,
            _standardFeeRecipient,
            _operations,
            _developers
        );

        amplifi.approve(address(_router), type(uint256).max);
    }

    function createTransistor(uint256 _months, uint256 _amountOutMin) external payable nonReentrant returns (uint256) {
        require(msg.value == getRenewalFeeForMonths(_months) + creationFee, "Invalid Ether value provided");
        chargeFee(feeRecipients.creationFee, msg.value);

        return _createTransistor(_months, _amountOutMin);
    }

    function createTransistorBatch(
        uint256 _amount,
        uint256 _months,
        uint256 _amountOutMin
    ) external payable nonReentrant returns (uint256[] memory ids) {
        require(msg.value == (getRenewalFeeForMonths(_months) + creationFee) * _amount, "Invalid Ether value provided");
        chargeFee(feeRecipients.creationFee, msg.value);

        ids = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; ) {
            ids[i] = _createTransistor(_months, _amountOutMin);
            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function _createTransistor(uint256 _months, uint256 _amountOutMin) internal returns (uint256) {
        require(balanceOf[msg.sender] < maxTransistorsPerMinter, "Too many transistors");
        require(_months > 0 && _months <= maxMonths, "Must be greater than 0 and less than maxMonths");

        require(amplifi.transferFrom(msg.sender, address(this), mintPrice), "Unable to transfer Amplifi");

        // we can't burn from the contract so we have to send to a special address from which the deployer will then burn
        amplifi.transfer(burnAddress, (mintPrice * mintBurn) / bps);

        sell((mintPrice * (mintLP / 2)) / bps, _amountOutMin);
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.transfer(feeRecipients.creationTax, usdcBalance);

        amplifi.transfer(feeRecipients.creationTax, (mintPrice * (mintLP / 2)) / bps);

        uint256 id;
        uint256 length;
        unchecked {
            id = totalTransistors++;
            length = balanceOf[msg.sender]++;
        }

        transistors[id] = Types.Transistor(msg.sender, block.timestamp, block.timestamp + 30 days * _months, 0, 0);
        ownedTransistors[msg.sender][length] = id;
        ownedTransistorsIndex[id] = length;

        return id;
    }

    function renewTransistor(uint256 _id, uint256 _months) external payable nonReentrant {
        require(msg.value == getRenewalFeeForMonths(_months), "Invalid Ether value provided");
        chargeFee(feeRecipients.renewalFee, msg.value);

        _renewTransistor(_id, _months);
    }

    function renewTransistorBatch(uint256[] calldata _ids, uint256 _months) external payable nonReentrant {
        uint256 length = _ids.length;
        require(msg.value == (getRenewalFeeForMonths(_months)) * length, "Invalid Ether value provided");
        chargeFee(feeRecipients.renewalFee, msg.value);

        for (uint256 i = 0; i < length; ) {
            _renewTransistor(_ids[i], _months);
            unchecked {
                ++i;
            }
        }
    }

    function _renewTransistor(uint256 _id, uint256 _months) internal {
        Types.Transistor storage transistor = transistors[_id];

        require(transistor.minter == msg.sender, "Invalid ownership");
        require(transistor.expires + gracePeriod >= block.timestamp, "Grace period expired or transistor reversed");

        uint256 monthsLeft = 0;
        if (block.timestamp > transistor.expires) {
            monthsLeft = (block.timestamp - transistor.expires) / 30 days;
        } else {
            monthsLeft = (transistor.expires - block.timestamp) / 30 days;
        }

        require(_months + monthsLeft <= maxMonths, "Too many months");

        transistor.expires += 30 days * _months;
    }

    function reverseTransistor(uint256 _id) external payable nonReentrant {
        Types.Transistor storage transistor = transistors[_id];

        require(transistor.minter == msg.sender, "Invalid ownership");
        require(transistor.expires > block.timestamp, "Transistor expired");
        require(transistor.numClaims == 0, "Already claimed");
        require(msg.value == refundFee, "Invalid Ether value provided");

        chargeFee(feeRecipients.reverseFee, msg.value);

        transistor.expires = 0;
        amplifi.transfer(msg.sender, refundAmount);
    }

    function claimAMPLIFI(uint256 _id, uint256 _amountOutMin) external nonReentrant {
        _claimAMPLIFI(_id, _amountOutMin);
    }

    function claimAMPLIFIBatch(uint256[] calldata _ids, uint256 _amountOutMin) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            _claimAMPLIFI(_ids[i], _amountOutMin);
            unchecked {
                ++i;
            }
        }
    }

    function _claimAMPLIFI(uint256 _id, uint256 _amountOutMin) internal {
        Types.Transistor storage transistor = transistors[_id];
        require(transistor.minter == msg.sender, "Invalid ownership");
        require(transistor.expires > block.timestamp, "Transistor expired or reversed");

        uint256 amount = getPendingAMPLIFI(_id);
        amount = takeClaimFee(amount, _amountOutMin);
        amplifi.transfer(msg.sender, amount);

        transistor.numClaims++;
        transistor.lastClaimed = block.timestamp;
    }

    function getPendingAMPLIFI(uint256 _id) public view returns (uint256) {
        Types.Transistor memory transistor = transistors[_id];

        uint256 rate = transistor.numClaims >= rates.length ? rates[rates.length - 1] : rates[transistor.numClaims];
        uint256 amount = (block.timestamp - (transistor.numClaims > 0 ? transistor.lastClaimed : transistor.created)) *
            (rate);

        return amount;
    }

    function takeClaimFee(uint256 _amount, uint256 _amountOutMin) internal returns (uint256) {
        uint256 fee = (_amount * claimFee) / bps;

        sell(fee, _amountOutMin);

        uint256 usdcBalance = USDC.balanceOf(address(this));

        USDC.transfer(feeRecipients.claimFeeDevelopers, (usdcBalance * 34) / 100);
        USDC.transfer(feeRecipients.claimFeeOperations, (usdcBalance * 66) / 100);

        return _amount - fee;
    }

    function sell(uint256 _amount, uint256 _amountOutMin) internal {
        address[] memory path = new address[](2);
        path[0] = address(amplifi);
        path[1] = address(USDC);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function getRenewalFeeForMonths(uint256 _months) public view returns (uint256) {
        return renewalFee * _months;
    }

    function airdropTransistors(address[] calldata _users, uint256[] calldata _months)
        external
        onlyOwner
        returns (uint256[] memory ids)
    {
        require(_users.length == _months.length, "Lengths not aligned");

        uint256 length = _users.length;
        ids = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            ids[i] = _airdropTransistor(_users[i], _months[i]);
            unchecked {
                ++i;
            }
        }

        return ids;
    }

    function _airdropTransistor(address _user, uint256 _months) internal returns (uint256) {
        require(_months <= maxMonths, "Too many months");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalTransistors++;
            length = balanceOf[_user]++;
        }

        transistors[id] = Types.Transistor(_user, block.timestamp, block.timestamp + 30 days * _months, 0, 0);
        ownedTransistors[_user][length] = id;
        ownedTransistorsIndex[id] = length;

        return id;
    }

    function removeTransistor(uint256 _id) external onlyOwner {
        uint256 lastTransistorIndex = balanceOf[transistors[_id].minter];
        uint256 transistorIndex = ownedTransistorsIndex[_id];

        if (transistorIndex != lastTransistorIndex) {
            uint256 lastTransistorId = ownedTransistors[transistors[_id].minter][lastTransistorIndex];

            ownedTransistors[transistors[_id].minter][transistorIndex] = lastTransistorId; // Move the last Transistor to the slot of the to-delete token
            ownedTransistorsIndex[lastTransistorId] = transistorIndex; // Update the moved Transistor's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTransistorsIndex[_id];
        delete ownedTransistors[transistors[_id].minter][lastTransistorIndex];

        balanceOf[transistors[_id].minter]--;
        totalTransistors--;

        delete transistors[_id];
    }

    function chargeFee(address _recipient, uint256 _amount) internal {
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Could not send ETH");
    }

    function setRates(uint256[] calldata _rates) external onlyOwner {
        require(_rates.length == rates.length, "Invalid length");

        uint256 length = _rates.length;
        for (uint256 i = 0; i < length; ) {
            rates[i] = _rates[i];
            unchecked {
                ++i;
            }
        }
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMonths(uint16 _maxMonths) external onlyOwner {
        maxMonths = _maxMonths;
    }

    function setFees(
        uint256 _creationFee,
        uint256 _renewalFee,
        uint256 _refundFee,
        uint16 _claimFee,
        uint16 _mintBurn,
        uint16 _mintLP
    ) external onlyOwner {
        creationFee = _creationFee;
        renewalFee = _renewalFee;
        refundFee = _refundFee;
        claimFee = _claimFee;
        mintBurn = _mintBurn;
        mintLP = _mintLP;
    }

    function setRefundAmounts(uint256 _refundAmount) external onlyOwner {
        refundAmount = _refundAmount;
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }

    function setFeeRecipients(Types.TransistorFeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setPeriods(uint256 _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IAmplifi is IERC20 {
    function burnForAmplifier(address _burnee, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Types {
    struct FeeRecipients {
        address operations;
        address validatorAcquisition;
        address PCR;
        address yield;
        address xChainValidatorAcquisition;
        address indexFundPools;
        address gAMPRewardsPool;
        address OTCSwap;
        address rescueFund;
        address protocolImprovement;
        address developers;
    }

    struct Fees {
        uint16 operations;
        uint16 validatorAcquisition;
        uint16 PCR;
        uint16 yield;
        uint16 xChainValidatorAcquisition;
        uint16 indexFundPools;
        uint16 gAMPRewardsPool;
        uint16 OTCSwap;
        uint16 rescueFund;
        uint16 protocolImprovement;
        uint16 developers;
    }

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 started;
        uint256 unlocks;
    }

    enum FuseProduct {
        None,
        OneYear,
        ThreeYears,
        FiveYears
    }

    struct Amplifier {
        FuseProduct fuseProduct;
        address minter;
        uint256 created;
        uint256 expires;
        uint256 numClaims;
        uint256 lastClaimed;
        uint256 fused;
        uint256 unlocks;
        uint256 lastFuseClaimed;
    }

    struct AmplifierFeeRecipients {
        address operations;
        address validatorAcquisition;
        address developers;
    }

    struct Transistor {
        address minter;
        uint256 created;
        uint256 expires;
        uint256 numClaims;
        uint256 lastClaimed;
    }

    struct TransistorFeeRecipients {
        address creationFee;
        address creationTax;
        address renewalFee;
        address reverseFee;
        address claimFeeOperations;
        address claimFeeDevelopers;
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