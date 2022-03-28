// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";

contract NitroPayments is Ownable, ReentrancyGuard {
    address public beneficiary;

    mapping(address => bool) public allowedERC20;

    AggregatorV3Interface internal AVAXUSD;
    AggregatorV3Interface internal BTCUSD;
    AggregatorV3Interface internal ETHUSD;
    AggregatorV3Interface internal DAIUSD;
    AggregatorV3Interface internal USDCUSD;
    AggregatorV3Interface internal USDTUSD;

    // Testnet - Rinkeby
    address public constant WAVAX = address(0);
    address public constant WBTC = 0x577D296678535e4903D59A4C929B718e1D575e0A;
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public constant DAI = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address public constant USDC = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address public constant USDT = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;

    // production - Avax
    /*
        address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        address public constant WBTC = 0x50b7545627a5162F82A992c33b87aDc75187B218;
        address public constant WETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
        address public constant DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
        address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
        address public constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    */

    event AllowedERC20Updated(address erc20, bool status, uint256 when);

    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);

    event PendingPaid(
        address erc20,
        uint256 price,
        address who,
        address to,
        uint256 when,
        uint256 tier
    );

    constructor(address _beneficiary) {
        require(
            _beneficiary != address(0),
            "Initiate:: Invalid Beneficiary Address"
        );
        beneficiary = _beneficiary;

        // updateERC20(WAVAX, true);
        updateERC20(WBTC, true);
        updateERC20(WETH, true);
        updateERC20(DAI, true);
        updateERC20(USDC, true);
        updateERC20(USDT, true);

        // Testnet - Rinkeby
        AVAXUSD = AggregatorV3Interface(address(0));
        BTCUSD = AggregatorV3Interface(
            0xECe365B379E1dD183B20fc5f022230C044d51404
        );
        ETHUSD = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        DAIUSD = AggregatorV3Interface(
            0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF
        );
        USDCUSD = AggregatorV3Interface(
            0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB
        );
        USDTUSD = AggregatorV3Interface(address(0));

        // production - Avax
        /* 
            AVAXUSD = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
            DAIUSD = AggregatorV3Interface(0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300);
            USDCUSD = AggregatorV3Interface(0xF096872672F44d6EBA71458D74fe67F9a77a23B9);
            BTCUSD = AggregatorV3Interface(0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743);
            USDTUSD = AggregatorV3Interface(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);
            ETHUSD = AggregatorV3Interface(0x976B3D034E162d8bD72D6b9C989d545b839003b0);
        */
    }

    function updateERC20(address _erc20, bool _status) public onlyOwner {
        require(_erc20 != address(0), "UpdateERC20:: Invalid Address");
        allowedERC20[_erc20] = _status;
        emit AllowedERC20Updated(_erc20, _status, block.timestamp);
    }

    function safeApprove(address _erc20, uint256 _amount) external {
        TransferHelper.safeApprove(_erc20, address(this), _amount);
    }

    function isAlreadyApproved(
        address _erc20,
        address _user,
        address _spender,
        uint256 _amount
    ) external view returns (bool) {
        return IERC20(_erc20).allowance(_user, _spender) > _amount;
    }

    function payPending(
        address _erc20,
        uint256 _toPayinUSD,
        uint256 _tier
    ) external nonReentrant {
        require(allowedERC20[_erc20], "PayPending:: Unsupported ERC20");

        uint256 _toPay = getAmountToPay(_erc20, _toPayinUSD);

        require(
            IERC20(_erc20).balanceOf(msg.sender) >= _toPay,
            "PayPending:: Insufficient Balance"
        );
        require(
            transferERC20(_erc20, beneficiary, _toPay),
            "PayPending:: Transfer Failed"
        );
        emit PendingPaid(
            _erc20,
            _toPay,
            msg.sender,
            beneficiary,
            block.timestamp,
            _tier
        );
    }

    function transferERC20(
        address _erc20,
        address _recipient,
        uint256 _toPay
    ) internal returns (bool) {
        return IERC20(_erc20).transferFrom(msg.sender, _recipient, _toPay);
    }

    function updateBeneficiary(address payable _newBeneficiary)
        external
        onlyOwner
    {
        require(
            _newBeneficiary != address(0),
            "UpdateBeneficiary:: New Beneficiary can not be Zero Address"
        );
        emit BeneficiaryUpdated(beneficiary, _newBeneficiary);
        beneficiary = _newBeneficiary;
    }

    function getAmountToPay(address _token, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        if (_token == WAVAX) {
            return getPriceToPayAVAXUSD(_amount);
        } else if (_token == DAI) {
            return getPriceToPayDAIUSD(_amount);
        } else if (_token == USDC) {
            return getPriceToPayUSDCUSD(_amount);
        } else if (_token == USDT) {
            return getPriceToPayUSDTUSD(_amount);
        } else if (_token == WBTC) {
            return getPriceToPayBTCUSD(_amount);
        } else if (_token == WETH) {
            return getPriceToPayETHUSD(_amount);
        } else {
            revert("GetAmountToPay:: Invalid Token");
        }
    }

    function getPriceToPayAVAXUSD(uint256 amount)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = AVAXUSD.latestRoundData();
        uint256 toPay = ((amount * 1e18) / uint256(price)) * 1e8;
        return toPay;
    }

    function getPriceToPayDAIUSD(uint256 amount) public view returns (uint256) {
        (, int256 price, , , ) = DAIUSD.latestRoundData();
        uint256 toPay = ((amount * 1e18) / uint256(price)) * 1e8;
        return toPay;
    }

    function getPriceToPayUSDCUSD(uint256 amount)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = USDCUSD.latestRoundData();
        uint256 toPay = ((amount * 1e18) / uint256(price)) * 1e8;
        return toPay;
    }

    function getPriceToPayUSDTUSD(uint256 amount)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = USDTUSD.latestRoundData();
        uint256 toPay = ((amount * 1e18) / uint256(price)) * 1e8;
        return toPay;
    }

    function getPriceToPayBTCUSD(uint256 amount) public view returns (uint256) {
        (, int256 price, , , ) = BTCUSD.latestRoundData();
        uint256 toPay = ((amount * 1e18) / uint256(price)) * 1e8;
        return toPay;
    }

    function getPriceToPayETHUSD(uint256 amount) public view returns (uint256) {
        (, int256 price, , , ) = ETHUSD.latestRoundData();
        uint256 toPay = ((amount * 1e18) / uint256(price)) * 1e8;
        return toPay;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}