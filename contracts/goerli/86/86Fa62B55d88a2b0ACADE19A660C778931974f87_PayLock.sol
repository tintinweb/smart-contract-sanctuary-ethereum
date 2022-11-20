// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
// ERC2771Context and Forwarder for relaying issued transactions ( Withdraw OR Redeem)
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
// IERC20 - ERC20 Interface for transfering ERC20 tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Chainlink Aggregator for PriceFeedS
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Imports token price conversioner library
import "./PriceConverter.sol";

// Reverting Errors
error __AmountEmpty();
error __NotSenderOrNotActive();
error __NoReedemablePayments();
error __InvalidCode();
error __TransferFailed();
error __TransferWithdrawn();

contract PayLock is ERC2771Context, Ownable {
    // Libraries
    // ./PriceConverter gets token price conversions for detrmining max transaction fee
    using PriceConverter for uint256;
    // Immutables
    address private immutable i_forwarder;
    // Chainlink PriceFeeds - (token / USD)
    AggregatorV3Interface private immutable i_priceFeedNative;
    AggregatorV3Interface private immutable i_priceFeedUSDC;
    AggregatorV3Interface private immutable i_priceFeedUSDT;
    AggregatorV3Interface private immutable i_priceFeedDAI;
    AggregatorV3Interface private immutable i_priceFeedBTC;
    // Token Addresses
    address private immutable i_USDCAddress;
    address private immutable i_USDTAddress;
    address private immutable i_DAIAddress;
    address private immutable i_WBTCAddress;
    // constants
    uint256 public constant MAXIMUM_FEE_USD = 50 * 1e18;

    /**
     * @dev Constructor (Initializor).
     * Chainlink's priceFeed Addresses
     * Supported ERC20 token Addresses
     * `_MinimalForwarder` Trusted Fowarder address `.
     * `_AggregatorNative` Native token Chainlink aggregator address `.
     * `_AggregatorUSDC` USDC Chainlink aggregator address `.
     * `_AggregatorUSDT` USDT token Chainlink aggregator address `.
     * `_AggregatorDAI` DAI token Chainlink aggregator address `.
     * `_AggregatordBTC` WBTC token Chainlink aggregator address `.
     *
     * `_USDCAddress`  ERC20 token Address`.
     * `_USDTAddress`  ERC20 token Address`.
     * `_DAIAddress`  ERC20 token Address`.
     * `_WBTCAddress`  ERC20 token Address`.
     */

    constructor(
        MinimalForwarder forwarder,
        address AggregatorNative,
        address AggregatorUSDC,
        address AggregatorUSDT,
        address AggregatorDAI,
        address AggregatordBTC,
        address USDCAddress,
        address USDTAddress,
        address DAIAddress,
        address WBTCAddress
    ) ERC2771Context(address(forwarder)) {
        i_forwarder = address(forwarder);
        i_priceFeedNative = AggregatorV3Interface(AggregatorNative);
        i_priceFeedUSDC = AggregatorV3Interface(AggregatorUSDC);
        i_priceFeedUSDT = AggregatorV3Interface(AggregatorUSDT);
        i_priceFeedDAI = AggregatorV3Interface(AggregatorDAI);
        i_priceFeedBTC = AggregatorV3Interface(AggregatordBTC);

        i_USDCAddress = USDCAddress;
        i_USDTAddress = USDTAddress;
        i_DAIAddress = DAIAddress;
        i_WBTCAddress = WBTCAddress;
    }

    // Enums
    enum PaymentState {
        ACTIVE,
        WITHDRAWN,
        RECEIVED
    }
    // Structs
    struct payment {
        uint256 value;
        address payable issuer;
        address payable receiver;
        uint256 issuerId;
        uint256 receiverId;
        uint256 code;
        address tokenAddress;
        PaymentState state;
    }
    // State
    // Paylock fee collection
    uint256 public s_PaySafe;
    mapping(address => uint256) public s_PaySafeTokenBalances;
    // A user has 2 arrays of issued & redeemable payments
    mapping(address => payment[]) public s_issuedPayments;
    mapping(address => payment[]) public s_redeemablePayments;
    // Events
    event PaymentIssued(address indexed sender, payment indexed receipt);
    event PaymentReedemed(address indexed receiver, payment indexed receipt);
    event PaymentWithdrawn(address indexed sender, payment indexed receipt);

    /**
     * @dev CreatePayement Issues a payment.
     * `_receiver` Receiver address`.
     * `_code` A random 4 digit number`.
     * _tokenAddress if native token value should be 0x0000.. if approved ERC20 address
     * _tokenAmount Amount to transfer if native token 0.. or approved ERC20 address
     * Requirements:
     * if sending a native token `msg.value` needs to have value i,e not empty.
     * if sending a ERC20 token `_tokenAmount` needs to have value i,e not empty.
     * Emits a {PaymentIssued} event.
     */
    function CreatePayement(
        address payable _receiver,
        uint256 _code,
        address _tokenAddress,
        uint256 _tokenAmount
    ) public payable {
        if (_tokenAddress == address(0)) {
            // If payment is empty revert transaction
            bool AmountEmpty = msg.value == 0;
            if (AmountEmpty) {
                revert __AmountEmpty();
            }
            // prepare new memory payment struct
            payment memory newPayment;
            //If USD fee value equals more than 50USD, cap fee at 50 USD
            if (
                (msg.value / 200).getConversionRate(i_priceFeedNative) >
                MAXIMUM_FEE_USD
            ) {
                newPayment.value =
                    msg.value -
                    MAXIMUM_FEE_USD.getMaxRate(i_priceFeedNative);
                s_PaySafe += MAXIMUM_FEE_USD.getMaxRate(i_priceFeedNative);
            } else {
                newPayment.value = msg.value - msg.value / 200;
                s_PaySafe += msg.value / 200;
            }

            // Issue payment
            newPayment.issuer = payable(msg.sender);
            newPayment.receiver = payable(_receiver);
            newPayment.issuerId = s_issuedPayments[msg.sender].length;
            newPayment.receiverId = s_redeemablePayments[_receiver].length;
            newPayment.code = _code;
            newPayment.tokenAddress = _tokenAddress;
            newPayment.state = PaymentState.ACTIVE;
            // ADD payment to both arrays of issuer and reedemable transactions
            s_issuedPayments[msg.sender].push(newPayment);
            s_redeemablePayments[_receiver].push(newPayment);
            // Emit PaymentIssued event
            emit PaymentIssued(msg.sender, newPayment);
        } else {
            // If _tokenAmount is empty revert transaction
            bool AmountEmpty = _tokenAmount == 0;
            if (AmountEmpty) {
                revert __AmountEmpty();
            }
            // prepare new memory payment struct
            payment memory newPayment;
            // Determines which price feed and ERC20 contract to interact with
            if (_tokenAddress == i_USDCAddress) {
                // Transfer tokens
                bool success = IERC20(i_USDCAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount
                );
                if (!success) {
                    revert __TransferFailed();
                }
                // IF USD value (0.5%) a of transaction  equals more than 50USD, cap fee at 50 USD
                if (
                    (_tokenAmount / 200).getConversionRate(i_priceFeedUSDC) >=
                    MAXIMUM_FEE_USD
                ) {
                    newPayment.value =
                        _tokenAmount -
                        MAXIMUM_FEE_USD.getMaxRate(i_priceFeedUSDC);
                    s_PaySafeTokenBalances[i_USDCAddress] += MAXIMUM_FEE_USD
                        .getMaxRate(i_priceFeedUSDC);
                } else {
                    newPayment.value = _tokenAmount - _tokenAmount / 200;
                    s_PaySafeTokenBalances[i_USDCAddress] += _tokenAmount / 200;
                }
            } else if (_tokenAddress == i_USDTAddress) {
                // Transfer tokens
                bool success = IERC20(i_USDTAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount
                );
                if (!success) {
                    revert __TransferFailed();
                }
                // If the fee USD value (0.5%) a of transaction amount equals more than 50USD, cap fee at 50 USD else use (0.5%) of _tokenAmount
                if (
                    (_tokenAmount / 200).getConversionRate(i_priceFeedUSDT) >=
                    MAXIMUM_FEE_USD
                ) {
                    newPayment.value =
                        _tokenAmount -
                        MAXIMUM_FEE_USD.getMaxRate(i_priceFeedUSDT);
                    s_PaySafeTokenBalances[i_USDTAddress] += MAXIMUM_FEE_USD
                        .getMaxRate(i_priceFeedUSDT);
                } else {
                    newPayment.value = _tokenAmount - _tokenAmount / 200;
                    s_PaySafeTokenBalances[i_USDTAddress] += _tokenAmount / 200;
                }
            } else if (_tokenAddress == i_DAIAddress) {
                // Transfer tokens
                bool success = IERC20(i_DAIAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount
                );
                if (!success) {
                    revert __TransferFailed();
                }
                // If the fee USD value (0.5%) a of transaction amount equals more than 50USD, cap fee at 50 USD else use (0.5%) of _tokenAmount
                if (
                    (_tokenAmount / 200).getConversionRate(i_priceFeedDAI) >=
                    MAXIMUM_FEE_USD
                ) {
                    newPayment.value =
                        _tokenAmount -
                        MAXIMUM_FEE_USD.getMaxRate(i_priceFeedDAI);
                    s_PaySafeTokenBalances[i_DAIAddress] += MAXIMUM_FEE_USD
                        .getMaxRate(i_priceFeedDAI);
                } else {
                    newPayment.value = _tokenAmount - _tokenAmount / 200;
                    s_PaySafeTokenBalances[i_DAIAddress] += _tokenAmount / 200;
                }
            } else if (_tokenAddress == i_WBTCAddress) {
                // Transfer tokens
                bool success = IERC20(i_WBTCAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount
                );
                if (!success) {
                    revert __TransferFailed();
                }
                // If the fee USD value (0.5%) a of transaction amount equals more than 50USD, cap fee at 50 USD else use (0.5%) of _tokenAmount
                if (
                    (_tokenAmount / 200).getConversionRate(i_priceFeedBTC) >=
                    MAXIMUM_FEE_USD
                ) {
                    newPayment.value =
                        _tokenAmount -
                        MAXIMUM_FEE_USD.getMaxRate(i_priceFeedBTC);
                    s_PaySafeTokenBalances[i_WBTCAddress] += MAXIMUM_FEE_USD
                        .getMaxRate(i_priceFeedBTC);
                } else {
                    newPayment.value = _tokenAmount - _tokenAmount / 200;
                    s_PaySafeTokenBalances[i_WBTCAddress] += _tokenAmount / 200;
                }
            }
            // Issue payment
            newPayment.issuer = payable(msg.sender);
            newPayment.receiver = payable(_receiver);
            newPayment.issuerId = s_issuedPayments[msg.sender].length;
            newPayment.receiverId = s_redeemablePayments[_receiver].length;
            newPayment.code = _code;
            newPayment.tokenAddress = _tokenAddress;
            newPayment.state = PaymentState.ACTIVE;
            // ADD payment to both arrays of issuer and reedemable transactions
            s_issuedPayments[msg.sender].push(newPayment);
            s_redeemablePayments[_receiver].push(newPayment);
            // Emit PaymentIssued event
            emit PaymentIssued(msg.sender, newPayment);
        }
    }

    /**
     * @dev Withdraw issued payment.
     *  _code 4 digit number entered by the user
     * _receiverId Sent by the front-end automatically when correct code is entered by the user `.
     *
     * Requirements:
     * - `Active` Payment state needs to be active i.e Not withdrawn or Received.
     * - `notReceiver` Only issuer address (_msgSender) will be able to withdraw.
     * - _code must match same number used to issue payment
     * Emits a {PaymentWithdrawn} event.
     */

    function withdrawIssuerPayment(uint256 _code, uint256 _receiverId)
        public
        payable
    {
        // Lookup issued payment in issuer's issued transactions
        payment[] memory issuedPayments = s_issuedPayments[_msgSender()];
        // No reedemable payments
        if (issuedPayments.length == 0) {
            revert __NoReedemablePayments();
        }
        // Loop for reedemable payments with the code entered for the caller.
        for (uint256 i = 0; i < issuedPayments.length; i++) {
            // If code is valid and Requirements are met transfer payment.
            if (
                issuedPayments[i].code == _code &&
                issuedPayments[i].receiverId == _receiverId
            ) {
                // Payment must be active and sender must be the payment issuer.
                bool notActive = issuedPayments[i].state != PaymentState.ACTIVE;
                bool notSender = issuedPayments[i].issuer != _msgSender();
                bool conditions = (notActive || notSender);
                if (conditions) {
                    revert __NotSenderOrNotActive();
                }
                //Change payment state to Withdrawn.
                s_redeemablePayments[issuedPayments[i].receiver][
                    issuedPayments[i].receiverId
                ].state = PaymentState.WITHDRAWN;

                s_issuedPayments[_msgSender()][i].state = PaymentState
                    .WITHDRAWN;
                // Emit PaymentWithdrawn event
                emit PaymentWithdrawn(_msgSender(), issuedPayments[i]);
                // Value transfer either native or erc20 transfer.
                if (issuedPayments[i].tokenAddress == address(0)) {
                    (bool success, ) = _msgSender().call{
                        value: issuedPayments[i].value
                    }("");
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (issuedPayments[i].tokenAddress == i_USDCAddress) {
                    // Transfer tokens
                    bool success = IERC20(i_USDCAddress).transfer(
                        _msgSender(),
                        issuedPayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (issuedPayments[i].tokenAddress == i_USDTAddress) {
                    // Transfer tokens
                    bool success = IERC20(i_USDTAddress).transfer(
                        _msgSender(),
                        issuedPayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (issuedPayments[i].tokenAddress == i_DAIAddress) {
                    // Transfer tokens
                    bool success = IERC20(i_DAIAddress).transfer(
                        _msgSender(),
                        issuedPayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (issuedPayments[i].tokenAddress == i_WBTCAddress) {
                    // Transfer tokens
                    bool success = IERC20(i_WBTCAddress).transfer(
                        _msgSender(),
                        issuedPayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                }
            } else {}
        }
    }

    /**
     * @dev Redeem _code to receive Payment.
     * `_code` 4 digit number entered by the user `.
     * _receiverId Sent by the front-end automatically when correct code is entered by the user `.
     *
     * Requirements:
     * - `Active` Payment needs to be active i.e Not withdrawn or Received.
     * - `notReceiver` sender must be recepient address in payment.
     * - _code must match same number used to issue payment
     * Emits a {PaymentReedemed} event.
     */
    function RedeemPayment(uint256 _code, uint256 _receiverId) public payable {
        payment[] memory reedemablePayments = s_redeemablePayments[
            _msgSender()
        ];
        // No reedemable payments
        if (reedemablePayments.length == 0) {
            revert __NoReedemablePayments();
        }
        // Loop for reedemable payments with the code entered for the caller.
        for (uint256 i = 0; i < reedemablePayments.length; i++) {
            // If code is valid and Requirements are met transfer payment.
            if (
                reedemablePayments[i].code == _code &&
                reedemablePayments[i].receiverId == _receiverId
            ) {
                bool notActive = reedemablePayments[i].state !=
                    PaymentState.ACTIVE;
                bool notReceiver = reedemablePayments[i].receiver !=
                    _msgSender();

                bool conditions = (notActive || notReceiver);

                if (conditions) {
                    revert __NotSenderOrNotActive();
                }
                // Change payment state in both issuer and reedemable maps.
                s_issuedPayments[reedemablePayments[i].issuer][
                    reedemablePayments[i].issuerId
                ].state = PaymentState.RECEIVED;
                s_redeemablePayments[_msgSender()][i].state = PaymentState
                    .RECEIVED;
                emit PaymentReedemed(_msgSender(), reedemablePayments[i]);

                // Value transfer either native or erc20 transfer.
                if (reedemablePayments[i].tokenAddress == address(0)) {
                    (bool success, ) = _msgSender().call{
                        value: reedemablePayments[i].value
                    }("");
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (
                    reedemablePayments[i].tokenAddress == i_USDCAddress
                ) {
                    // Transfer tokens
                    bool success = IERC20(i_USDCAddress).transfer(
                        _msgSender(),
                        reedemablePayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (
                    reedemablePayments[i].tokenAddress == i_USDTAddress
                ) {
                    // Transfer tokens
                    bool success = IERC20(i_USDTAddress).transfer(
                        _msgSender(),
                        reedemablePayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (reedemablePayments[i].tokenAddress == i_DAIAddress) {
                    // Transfer tokens
                    bool success = IERC20(i_DAIAddress).transfer(
                        _msgSender(),
                        reedemablePayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                } else if (
                    reedemablePayments[i].tokenAddress == i_WBTCAddress
                ) {
                    // Transfer tokens
                    bool success = IERC20(i_WBTCAddress).transfer(
                        _msgSender(),
                        reedemablePayments[i].value
                    );
                    if (!success) {
                        revert __TransferFailed();
                    }
                }
            } else {
                // revert __InvalidCode();
            }
        }
    }

    // onlyOwner function - Withdraws native protocol fees
    function withdrawPaySafeBalance() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: s_PaySafe}("");
        if (!success) {
            revert __TransferFailed();
        }
        s_PaySafe = 0;
    }

    // onlyOwner function -  Withdraws ERC20 protocol fees
    function withdrawPaySafeBalance(address _tokenAddress)
        public
        payable
        onlyOwner
    {
        if (_tokenAddress == i_USDCAddress) {
            bool success = IERC20(i_USDCAddress).transfer(
                msg.sender,
                s_PaySafeTokenBalances[i_USDCAddress]
            );
            if (!success) {
                revert __TransferFailed();
            }
            s_PaySafeTokenBalances[i_USDCAddress] = 0;
        } else if (_tokenAddress == i_USDTAddress) {
            // Transfer tokens
            bool success = IERC20(i_USDTAddress).transfer(
                msg.sender,
                s_PaySafeTokenBalances[i_USDTAddress]
            );
            if (!success) {
                revert __TransferFailed();
            }
            s_PaySafeTokenBalances[i_USDTAddress] = 0;
        } else if (_tokenAddress == i_DAIAddress) {
            // Transfer tokens
            bool success = IERC20(i_DAIAddress).transfer(
                msg.sender,
                s_PaySafeTokenBalances[i_DAIAddress]
            );
            if (!success) {
                revert __TransferFailed();
            }
            s_PaySafeTokenBalances[i_DAIAddress] = 0;
        } else if (_tokenAddress == i_WBTCAddress) {
            // Transfer tokens
            bool success = IERC20(i_WBTCAddress).transfer(
                msg.sender,
                s_PaySafeTokenBalances[i_WBTCAddress]
            );
            if (!success) {
                revert __TransferFailed();
            }
            s_PaySafeTokenBalances[i_WBTCAddress] = 0;
        }
    }

    // gets all issued payments
    function getIssuedPayments(address user)
        public
        view
        returns (payment[] memory)
    {
        return s_issuedPayments[user];
    }

    // gets all redeemable payments
    function getRedeemablePayments(address user)
        public
        view
        returns (payment[] memory)
    {
        return s_redeemablePayments[user];
    }

    // Overiders for ERC2711Context
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        sender = ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address passed on from constructor in Paylock.sol

        (, int256 price, , , ) = priceFeed.latestRoundData();
        //    typecaseting & ETH/USD rate in 18 digit
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 tokenAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 tokenPrice = getPrice(priceFeed);
        uint256 tokenAmountInUsd = (tokenAmount * tokenPrice) / 1e18;
        return tokenAmountInUsd;
    }

    function getMaxRate(
        uint256 MAXIMUM_FEE_USD,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 tokenPrice = getPrice(priceFeed);
        uint256 MaxFee = (MAXIMUM_FEE_USD / tokenPrice);
        return MaxFee;
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}