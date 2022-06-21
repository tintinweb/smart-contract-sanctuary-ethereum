//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import "./interfaces/IGivellet.sol";

import "bizzswap/contracts/interfaces/IBizzSwap.sol";

contract Givellet is IGivellet, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct Organisation {
        address recipient;
        address desiredTokenAddress;
        bool isEthDesired;
        bool doNotConvert;
    }

    IBizzSwap public bizzSwapContract;
    address public weth;
    Counters.Counter private _organisationId;
    mapping(uint256 => Organisation) public organisations;

    event OrganisationCreated(uint256 indexed _organisationId, address indexed _recipient);
    event DesiredTokensChanged(
        uint256 indexed _organisationId,
        address indexed _desiredTokenAddress,
        bool indexed _isEthDesired,
        bool _doNotConvert
    );
    event ContractAddressUpdated(address indexed bizzSwapContractAddress);
    event DonationCompleted(
        address indexed _recipient, 
        address indexed _sender,
        uint256 _exactAmountOut,
        string _emailAddress, 
        address _desiredTokenAddress,
        bool _isEth);
    event WethAddressUpdated(address indexed _weth);

    modifier validAddress(address _address) {
        require(
            _address != address(0) && _address != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            "Givellet: Invalid address"
        );
        _;
    }

    constructor(address _contractAddress, address _weth) {
        setContractAddress(_contractAddress);
        setWethAddress(_weth);
    }

    function setContractAddress(address _contractAddress) public override onlyOwner validAddress(_contractAddress) {
        bizzSwapContract = IBizzSwap(_contractAddress);
        emit ContractAddressUpdated(_contractAddress);
    }

    function setWethAddress(address _weth) public override onlyOwner validAddress(_weth) {
        weth = _weth;
        emit WethAddressUpdated(_weth);
    }

    receive() external payable {}


    function createOrganisation(
        address _desiredTokenAddress,
        bool _isEthDesired,
        bool _doNotConvert
    ) public override validAddress(_desiredTokenAddress) returns (uint256 organisationId) {
        organisationId = _organisationId.current();
        address desiredTokenAddress = _isEthDesired ? weth : _desiredTokenAddress;
        organisations[organisationId] = Organisation(msg.sender, desiredTokenAddress, _isEthDesired, _doNotConvert);
        _organisationId.increment();

        emit OrganisationCreated(organisationId, msg.sender);
    }

    function donate(
        IBizzSwap.SwapParameters memory _params,
        uint256 organisationId,
        address _inputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn,
        string memory _emailAddress
    ) public payable override nonReentrant validAddress(_inputTokenAddress) {
        Organisation memory organisation = organisations[organisationId];
        
        require(
            organisation.recipient != address(0),
            "Givellet::donate: Organisation with specified ID does not exist"
        );

        if (!_params.isPayingWithEth){
                TransferHelper.safeTransferFrom(_inputTokenAddress, msg.sender, address(this), _maximumAmountIn);
                TransferHelper.safeApprove(_inputTokenAddress, address(bizzSwapContract), _maximumAmountIn);
             }

        if (organisation.doNotConvert) {
            if (_params.isPayingWithEth) {
                organisation.isEthDesired = true;
                organisation.desiredTokenAddress = weth;
            } else {
                organisation.isEthDesired = false;
                organisation.desiredTokenAddress = _inputTokenAddress;
            }
        }

        bizzSwapContract.pay{ value: msg.value }(
            _params,
            organisation.isEthDesired,
            organisation.recipient,
            _inputTokenAddress,
            organisation.desiredTokenAddress,
            _exactAmountOut,
            _maximumAmountIn
        );

        // refund leftover
        //pogledaj dal moze ovo da se optizimuje
		if (address(this).balance > 0) {
			TransferHelper.safeTransferETH(msg.sender, address(this).balance);
		}
        else if (IERC20(_inputTokenAddress).balanceOf(address(this))>0) {
             TransferHelper.safeTransferFrom(_inputTokenAddress, 
             address(this),
             msg.sender,
            IERC20(_inputTokenAddress).balanceOf(address(this)));
        }

        emit DonationCompleted(
            organisation.recipient, 
            msg.sender,
             _exactAmountOut, 
            _emailAddress,
            organisation.desiredTokenAddress, 
            organisation.isEthDesired);
    }

    function changeDesiredToken(
        uint256 organisationId,
        address _desiredTokenAddress,
        bool _isEthDesired,
        bool _doNotConvert
    ) public override validAddress(_desiredTokenAddress) {
        Organisation storage organisation = organisations[organisationId];

        require(
            organisation.recipient != address(0),
            "Givellet::changeDesiredToken: Organisation with the given id does not exist"
        );
        require(
            organisation.recipient == msg.sender,
            "Givellet::changeDesiredToken: Only recepinet can change desired token"
        );

        organisation.desiredTokenAddress = _desiredTokenAddress;
        organisation.isEthDesired = _isEthDesired;
        organisation.doNotConvert = _doNotConvert;
        organisations[organisationId] = organisation;

        emit DesiredTokensChanged(organisationId, _desiredTokenAddress, _isEthDesired, _doNotConvert);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "bizzswap/contracts/interfaces/IBizzSwap.sol";

interface IGivellet {
    function setContractAddress(address _contractAddress) external;

    function setWethAddress(address _weth) external;

    function createOrganisation(
        address _desiredTokenAddress,
        bool _isEthDesired,
        bool _doNotConvert

    ) external returns (uint256 organisationId);

    function donate(
        IBizzSwap.SwapParameters memory _params,
        uint256 organisationId,
        address _inputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn,
        string memory _emailAddress
    ) external payable;

    function changeDesiredToken(
        uint256 organisationId,
        address _desiredTokenAddress,
        bool _isEthDesired,
        bool _doNotConvert
    ) external;
}

// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.8.0;

/// @title Interface for BizzSwap
interface IBizzSwap {
	/**
	 * @notice Parameters necessary for Uniswap V3 swap
	 *
	 * @param deadline - transaction will revert if it is pending for more than this period of time
	 * @param fee - the fee of the token pool to consider for the pair
	 * @param sqrtPriceLimitX96 - the price limit of the pool that cannot be exceeded by the swap
	 * @param isMultiSwap - flag to check whether to perform single or multi swap, cheaper than to compare path with abi.encodePacked("")
	 * @param isPayingWithEth - true if sender is paying with native coin, false otherwise; msg.value must be greater than zero if true
	 * @param path - sequence of (tokenAddress - fee - tokenAddress), encoded in reverse order, which are the variables needed to compute each pool contract address in sequence of swaps
	 *
	 * @notice msg.sender executes the payment
	 * @notice path is encoded in reverse order
	 */
	struct SwapParameters {
		uint256 deadline;
		uint24 fee;
		uint160 sqrtPriceLimitX96;
		bool isMultiSwap;
		bool isPayingWithEth;
		bytes path;
	}

	/**
	 * @notice Sets the address of the Router Contract
	 *
	 * @notice Only Administrator multisig can call
	 *
	 * @param _uniswapRouterContract - the address of the Router Contract
	 *
	 * No return, reverts on error
	 */
	function setRouterContract(address _uniswapRouterContract) external;

	/**
	 * @notice Creates payment invoice
	 *
	 * @param _desiredTokenAddress - address of the desired token
	 * @param _recipient - address of the recipient
	 * @param _isEthDesired - true if :_recipient: wants to receive native coin, false otherwise; if true, :_desiredTokenAddress: is irrelevant
	 * @param _exactAmountOut - amount of the desired token that should be paid
	 * @param _ipfsCid - ipfs hash of invoice details
	 *
	 * @return invoiceId - id of the newly created invoice
	 */
	function createInvoice(
		address _desiredTokenAddress,
		address _recipient,
		bool _isEthDesired,
		uint256 _exactAmountOut,
		string memory _ipfsCid
	) external returns (uint256 invoiceId);

	/**
	 * @notice Execute payment where sender pays in one token and recipient receives payment in one token
	 *
	 * @param invoiceId - id of the invoice to be paid
	 * @param _inputTokenAddress - address of the input token
	 * @param _maximumAmountIn - maximum amount of input token one is willing to spend for the payment
	 * @param _params - parameters necessary for the swap
	 *
	 * No return, reverts on error
	 */
	function payOneForOne(
		uint256 invoiceId,
		address _inputTokenAddress,
		uint256 _maximumAmountIn,
		SwapParameters memory _params
	) external payable;

	/**
	 * @notice Executes one on one micropayments
	 *
	 * @param _params - parameters necessary for the swap
	 * @param _isEthDesired - true if :_recipient: wants to receive native coin, false otherwise
	 * @param _recipient - the one who receives output tokens
	 * @param _inputTokenAddress - address of the input token
	 * @param _outputTokenAddress - address of the output token
	 * @param _exactAmountOut - amount of the desired token that should be paid
	 * @param _maximumAmountIn - the maximum amount of input token one is willing to spend for the payment
	 *
	 * No return, reverts on error
	 */
	function pay(
		SwapParameters memory _params,
		bool _isEthDesired,
		address _recipient,
		address _inputTokenAddress,
		address _outputTokenAddress,
		uint256 _exactAmountOut,
		uint256 _maximumAmountIn
	) external payable;
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