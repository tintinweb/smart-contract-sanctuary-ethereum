// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "./ICryptoPie.sol";
import "./MinimalForwarder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


contract CryptoPie is ICryptoPie, Pausable, AccessControl, ERC2771Context {

    function _msgSender() internal view override(ERC2771Context, Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant ASSISTANT_ROLE = keccak256("ASSISTANT_ROLE");

    uint256 public subscriptions_total;
    mapping(address => TokenConfig) private _token_config;
    mapping(uint256 => Subscription) private _subscriptions;
    mapping(uint256 => mapping(address => uint256)) private _user_last_payment;
    mapping(uint256 => SpecialFees) private _special_fees_subscription;
    mapping(address => SpecialFees) private _special_fees_one_time_payment;
    mapping(address => uint256[]) private _user_subscriptions_events;
    mapping(address => uint256[]) private _creator_subscriptions;
    
    constructor() ERC2771Context(address(this)) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getTokenConfigNumeratorFee(address token_address) external view override returns (uint256) {
        return _token_config[token_address].numerator_fee;
    }

    function getTokenConfigDenumeratorFee(address token_address) external view override returns (uint256) {
        return _token_config[token_address].denumerator_fee;
    }

    function getTokenConfigMinimumFee(address token_address) external view override returns (uint256) {
        return _token_config[token_address].minimum_fee;
    }

    function getTokenConfigMinimumPrice(address token_address) external view override returns (uint256) {
        return _token_config[token_address].minimum_price;
    }

    function getTokenConfigMinimumDelay(address token_address) external view override returns (uint256) {
        return _token_config[token_address].minimum_delay;
    }

    function getSubscriptionPrice(uint256 subscription_id) external view override returns (uint256) {
        return _subscriptions[subscription_id].price_decimals;
    }

    function getSubscriptionDelay(uint256 subscription_id) external view override returns (uint256) {
        return _subscriptions[subscription_id].delay_seconds;
    }

    function getSubscriptionTokenAddress(uint256 subscription_id) external view override returns (address) {
        return _subscriptions[subscription_id].token_address;
    }

    function getSubscriptionFundsReceiver(uint256 subscription_id) external view override returns (address) {
        return _subscriptions[subscription_id].funds_receiver;
    }

    function getUserSubscriptionsEvents(address user) external view returns (uint256[] memory) {
        return _user_subscriptions_events[user];
    }

    function getSubscriptionUserLastPayment(uint256 subscription_id, address user) external view override returns (uint256) {
        return _user_last_payment[subscription_id][user];
    }

    function getSubscriptionSpecialMinimumFee(uint256 subscription_id) external view override returns (uint256) {
        return _special_fees_subscription[subscription_id].minimum_fee;
    }

    function getSubscriptionSpecialNumeratorFee(uint256 subscription_id) external view override returns (uint256) {
        return _special_fees_subscription[subscription_id].numerator_fee;
    }

    function getSubscriptionSpecialDenumeratorFee(uint256 subscription_id) external view override returns (uint256) {
        return _special_fees_subscription[subscription_id].denumerator_fee;
    }

    function getCreatorSubscriptions(address creator) external view returns (uint256[] memory) {
        return _creator_subscriptions[creator];
    }

    function getOneTimePaymentSpecialMinimumFee(address funds_receiver) external view override returns (uint256) {
        return _special_fees_one_time_payment[funds_receiver].minimum_fee;
    }

    function getOneTimePaymentSpecialNumeratorFee(address funds_receiver) external view override returns (uint256) {
        return _special_fees_one_time_payment[funds_receiver].numerator_fee;
    }

    function getOneTimePaymentSpecialDenumeratorFee(address funds_receiver) external view override returns (uint256) {
        return _special_fees_one_time_payment[funds_receiver].denumerator_fee;
    }

    function pauseTokensFlow() external override onlyRole(MODERATOR_ROLE) {
        _pause();
    }

    function unpauseTokensFlow() external override onlyRole(MODERATOR_ROLE) {
        _unpause();
    }

    function add_token(
        address token_address,
        uint256 numerator_fee,
        uint256 denumerator_fee,
        uint256 minimum_fee,
        uint256 minimum_price,
        uint256 minimum_delay
    ) external override onlyRole(MODERATOR_ROLE) {
        require(denumerator_fee > 0, "Denumerator Fee is zero");
        require(numerator_fee <= denumerator_fee, "Denumerator fee < numerator fee");
        _token_config[token_address] = TokenConfig({
            numerator_fee: numerator_fee,
            denumerator_fee: denumerator_fee,
            minimum_fee: minimum_fee,
            minimum_price: minimum_price,
            minimum_delay: minimum_delay
        });
        emit AddToken(_msgSender(), token_address, numerator_fee, denumerator_fee, minimum_fee, minimum_price, minimum_delay);
    }

    function add_special_fees_subscription(uint256 subscription_id, uint256 minimum_fee, uint256 numerator_fee, uint256 denumerator_fee) external override onlyRole(MODERATOR_ROLE) {
        require(denumerator_fee > 0, "Denumerator Fee is zero");
        require(numerator_fee <= denumerator_fee, "Denumerator fee < numerator fee");

        _special_fees_subscription[subscription_id].numerator_fee = numerator_fee;
        _special_fees_subscription[subscription_id].denumerator_fee = denumerator_fee;
        _special_fees_subscription[subscription_id].minimum_fee = minimum_fee;

        emit AddSpecialFeesSubscription(_msgSender(), subscription_id, minimum_fee, numerator_fee, denumerator_fee);
    }

    function add_special_fees_one_time_payment(address funds_receiver, uint256 minimum_fee, uint256 numerator_fee, uint256 denumerator_fee) external override onlyRole(MODERATOR_ROLE) {
        require(denumerator_fee > 0, "Denumerator Fee is zero");
        require(numerator_fee <= denumerator_fee, "Denumerator fee < numerator fee");

        _special_fees_one_time_payment[funds_receiver].numerator_fee = numerator_fee;
        _special_fees_one_time_payment[funds_receiver].denumerator_fee = denumerator_fee;
        _special_fees_one_time_payment[funds_receiver].minimum_fee = minimum_fee;

        emit AddSpecialFeesOneTimePayment(_msgSender(), funds_receiver, minimum_fee, numerator_fee, denumerator_fee);
    }

    function withdrawal(address withdrawal_address, address[] memory tokens) external override onlyRole(MODERATOR_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 amount = token.balanceOf(address(this));
            token.transfer(withdrawal_address, amount);

            emit Withdrawal(_msgSender(), withdrawal_address, tokens[i], amount);
        }
    }

    function _make_transfer(
        address from,
        address to,
        address token_address,
        uint256 amount_decimals,
        uint256 numerator_fee,
        uint256 denumerator_fee,
        uint256 minimum_fee
    ) internal returns (bool) {
        IERC20 token = IERC20(token_address);
        if (token.allowance(from, address(this)) >= amount_decimals) {
            token.transferFrom(from, address(this), amount_decimals);
            uint256 funds_fee = amount_decimals / denumerator_fee * numerator_fee;
            if (minimum_fee > funds_fee) {
                funds_fee = minimum_fee;
            }
            if (funds_fee < amount_decimals) {
                token.transfer(to, amount_decimals - funds_fee);
            }
            emit MakeTransfer(_msgSender(), from, to, token_address, amount_decimals, funds_fee);
            return true;
        }
        return false;
    }

    function _process(uint256 subscription_id, address user, Subscription memory subscription, TokenConfig memory token_config) internal returns (bool) {
        uint256 subscription_minimumfee = token_config.minimum_fee;
        uint256 subscription_numerator_fee = token_config.numerator_fee;
        uint256 subscription_denumerator_fee = token_config.denumerator_fee;
        uint256 user_last_payment = _user_last_payment[subscription_id][user];

        if (_special_fees_subscription[subscription_id].numerator_fee > 0) {
            subscription_minimumfee = _special_fees_subscription[subscription_id].minimum_fee;
            subscription_numerator_fee = _special_fees_subscription[subscription_id].numerator_fee;
            subscription_denumerator_fee = _special_fees_subscription[subscription_id].denumerator_fee;
        }

        if (user_last_payment > 0 && block.timestamp >= user_last_payment + subscription.delay_seconds) {
            _user_last_payment[subscription_id][user] = block.timestamp;
            return _make_transfer(
                user,
                subscription.funds_receiver,
                subscription.token_address,
                subscription.price_decimals,
                subscription_numerator_fee,
                subscription_denumerator_fee,
                subscription_minimumfee
            );
        }
        return false;
    }

    function process(uint256 subscription_id, address[] memory users) external override onlyRole(ASSISTANT_ROLE) {
        Subscription memory subscription = _subscriptions[subscription_id];
        require(subscription.price_decimals > 0, "Subscription not found");
        TokenConfig memory token_config = _token_config[subscription.token_address];
        
        uint256 successful_claims = 0;
        uint256 failed_claims = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (_process(subscription_id, users[i], subscription, token_config)) {
                successful_claims++;
            } else {
                failed_claims++;
            }
        }

        emit Process(_msgSender(), subscription_id, successful_claims, failed_claims);
    }

    function create_subscription(
        uint256 price_decimals,
        uint256 delay_seconds,
        address token_address,
        address funds_receiver
    ) external override whenNotPaused {
        require(_token_config[token_address].minimum_price > 0, "Token is not authorized");
        require(_token_config[token_address].minimum_price <= price_decimals, "Price is low");
        require(_token_config[token_address].minimum_delay <= delay_seconds, "Delay is low");

        _subscriptions[subscriptions_total].price_decimals = price_decimals;
        _subscriptions[subscriptions_total].delay_seconds = delay_seconds;
        _subscriptions[subscriptions_total].token_address = token_address;
        _subscriptions[subscriptions_total].funds_receiver = funds_receiver;

        _creator_subscriptions[_msgSender()].push(subscriptions_total);

        subscriptions_total += 1;

        emit CreateSubscription(_msgSender(), funds_receiver, token_address, price_decimals, delay_seconds);
    }

    function subscribe(
        uint256 subscription_id,
        uint256 subscription_price_decimals,
        uint256 subscription_delay_seconds,
        address subscription_token_address,
        address subscription_funds_receiver
    ) external override whenNotPaused {
        Subscription memory subscription = _subscriptions[subscription_id];

        require(subscription.price_decimals > 0, "Subscription not found");
        require(_user_last_payment[subscription_id][_msgSender()] == 0, "User is already subscribed");
        require(subscription_price_decimals == subscription.price_decimals, "Wrong subscription price in signature");
        require(subscription_delay_seconds == subscription.delay_seconds, "Wrong subscription delay in signature");
        require(subscription_token_address == subscription.token_address, "Wrong subscription token in signature");
        require(subscription_funds_receiver == subscription.funds_receiver, "Wrong subscription receiver in signature");
        
        TokenConfig memory token_config = _token_config[subscription.token_address];
        _user_last_payment[subscription_id][_msgSender()] = 1;
        require(_process(subscription_id, _msgSender(), subscription, token_config), "Payment fail");

        _user_subscriptions_events[_msgSender()].push(subscription_id);
        emit Subscribe(_msgSender(), subscription_id);
    }

    function unsubscribe(
        uint256 subscription_id,
        uint256 subscription_price_decimals,
        uint256 subscription_delay_seconds,
        address subscription_token_address,
        address subscription_funds_receiver
    ) external override whenNotPaused {
        Subscription memory subscription = _subscriptions[subscription_id];

        require(subscription.price_decimals > 0, "Subscription not found");
        require(_user_last_payment[subscription_id][_msgSender()] > 0, "User is not subscribed");
        require(subscription_price_decimals == subscription.price_decimals, "Wrong subscription price in signature");
        require(subscription_delay_seconds == subscription.delay_seconds, "Wrong subscription delay in signature");
        require(subscription_token_address == subscription.token_address, "Wrong subscription token in signature");
        require(subscription_funds_receiver == subscription.funds_receiver, "Wrong subscription receiver in signature");

        delete _user_last_payment[subscription_id][_msgSender()];
        _user_subscriptions_events[_msgSender()].push(subscription_id);

        emit Unsubscribe(_msgSender(), subscription_id);
    }

    function single_payment(address funds_receiver, address token_address, uint256 amount_decimals) external override whenNotPaused {
        require(_token_config[token_address].minimum_price > 0, "Token is not authorized");
        if (_special_fees_one_time_payment[funds_receiver].numerator_fee == 0) {
            require(_make_transfer(
                _msgSender(),
                funds_receiver,
                token_address,
                amount_decimals,
                _token_config[token_address].numerator_fee,
                _token_config[token_address].denumerator_fee,
                _token_config[token_address].minimum_fee
            ), "Transfer failed");
        } else {
            require(_make_transfer(
                _msgSender(),
                funds_receiver,
                token_address,
                amount_decimals,
                _special_fees_one_time_payment[funds_receiver].numerator_fee,
                _special_fees_one_time_payment[funds_receiver].denumerator_fee,
                _special_fees_one_time_payment[funds_receiver].minimum_fee
            ), "Transfer failed");
        }
        emit SinglePayment(_msgSender(), funds_receiver, amount_decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICryptoPie {
    event AddToken(address indexed caller, address indexed token_address,
        uint256 numerator_fee, uint256 denumerator_fee, uint256 minimum_fee, uint256 minimum_price, uint256 minimum_delay);
    
    event CreateSubscription(address indexed caller, address indexed funds_receiver,
        address indexed token_address, uint256 price, uint256 delay_between_payments_seconds);
    
    event AddSpecialFeesSubscription(address indexed caller, uint256 indexed subscription_id,
        uint256 minimum_fee, uint256 numerator_fee, uint256 denumerator_fee);

    event AddSpecialFeesOneTimePayment(address indexed caller, address indexed funds_receiver,
        uint256 minimum_fee, uint256 numerator_fee, uint256 denumerator_fee);
    
    event MakeTransfer(address indexed caller, address from, address to, address token_address,
        uint256 amount_decimals, uint256 funds_fee);
    
    event Process(address indexed caller, uint256 indexed subscription_id, uint256 successful_claims, uint256 failed_claims);
    
    event Subscribe(address indexed caller, uint256 indexed subscription_id);
    
    event Unsubscribe(address indexed caller, uint256 indexed subscription_id);

    event SinglePayment(address indexed caller, address indexed to, uint256 amount);
    
    event Withdrawal(address indexed caller, address indexed withdrawal_address,
        address indexed token_address,uint256 amount);

    struct TokenConfig {
        uint256 numerator_fee;
        uint256 denumerator_fee;
        uint256 minimum_fee;
        uint256 minimum_price;
        uint256 minimum_delay;
    }
    
    struct SpecialFees {
        uint256 numerator_fee;
        uint256 denumerator_fee;
        uint256 minimum_fee;
    }

    struct Subscription {
        uint256 price_decimals;
        uint256 delay_seconds;
        address token_address;
        address funds_receiver;
    }
    
    function getTokenConfigNumeratorFee(address token_address) external view returns (uint256);
    function getTokenConfigDenumeratorFee(address token_address) external view returns (uint256);
    function getTokenConfigMinimumFee(address token_address) external view returns (uint256);
    function getTokenConfigMinimumPrice(address token_address) external view returns (uint256);
    function getTokenConfigMinimumDelay(address token_address) external view returns (uint256);
    
    function getSubscriptionPrice(uint256 subscription_id) external view returns (uint256);
    function getSubscriptionDelay(uint256 subscription_id) external view returns (uint256);
    function getSubscriptionTokenAddress(uint256 subscription_id) external view returns (address);
    function getSubscriptionFundsReceiver(uint256 subscription_id) external view returns (address);

    function getUserSubscriptionsEvents(address user) external view returns (uint256[] memory);
    function getSubscriptionUserLastPayment(uint256 subscription_id, address user) external view returns (uint256);
    
    function getSubscriptionSpecialMinimumFee(uint256 subscription_id) external view returns (uint256);
    function getSubscriptionSpecialNumeratorFee(uint256 subscription_id) external view returns (uint256);
    function getSubscriptionSpecialDenumeratorFee(uint256 subscription_id) external view returns (uint256);
    
    function getCreatorSubscriptions(address creator) external view returns (uint256[] memory);
    
    function getOneTimePaymentSpecialMinimumFee(address funds_receiver) external view returns (uint256);
    function getOneTimePaymentSpecialNumeratorFee(address funds_receiver) external view returns (uint256);
    function getOneTimePaymentSpecialDenumeratorFee(address funds_receiver) external view returns (uint256);
    
    function pauseTokensFlow() external;
    function unpauseTokensFlow() external;

    function add_token(address token_address,
        uint256 numerator_fee,
        uint256 denumerator_fee,
        uint256 minimum_fee,
        uint256 minimum_price_decimals,
        uint256 minimum_delay
    ) external;
    function add_special_fees_subscription(uint256 subscription_id, uint256 minimum_fee, uint256 numerator_fee, uint256 denumerator_fee) external;
    function add_special_fees_one_time_payment(address funds_receiver, uint256 minimum_fee, uint256 numerator_fee, uint256 denumerator_fee) external;
    function withdrawal(address withdrawal_address, address[] memory tokens) external;

    function process(uint256 subscription_id, address[] memory users) external;

    function create_subscription(
        uint256 price_decimals,
        uint256 delay_seconds,
        address token_address,
        address funds_receiver
    ) external;
    function subscribe(
        uint256 subscription_id,
        uint256 subscription_price_decimals,
        uint256 subscription_delay_seconds,
        address subscription_token_address,
        address subscription_funds_receiver
    ) external;
    function unsubscribe(
        uint256 subscription_id, 
        uint256 subscription_price_decimals, 
        uint256 subscription_delay_seconds,
        address subscription_token_address,
        address subscription_funds_receiver
    ) external;
    function single_payment(address funds_receiver, address token_address, uint256 amount_decimals) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";


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

        (bool success, bytes memory returndata) = address(this).call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            assembly {
                invalid()
            }
        }

        return (success, returndata);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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