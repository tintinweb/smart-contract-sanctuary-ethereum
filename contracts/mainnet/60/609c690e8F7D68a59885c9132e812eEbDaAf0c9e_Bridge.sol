// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBridge, MessengerProtocol} from "./interfaces/IBridge.sol";
import {Router} from "./Router.sol";
import {Messenger} from "./Messenger.sol";
import {MessengerGateway} from "./MessengerGateway.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {GasUsage} from "./GasUsage.sol";
import {WormholeMessenger} from "./WormholeMessenger.sol";
import {HashUtils} from "./libraries/HashUtils.sol";

/**
 * @title Bridge
 * @dev A contract with functions to facilitate bridging tokens across different blockchains.
 */
contract Bridge is GasUsage, Router, MessengerGateway, IBridge {
    using SafeERC20 for IERC20;
    using HashUtils for bytes32;

    uint public immutable override chainId;
    mapping(bytes32 messageHash => uint isProcessed) public override processedMessages;
    mapping(bytes32 messageHash => uint isSent) public override sentMessages;
    // Info about bridges on other chains
    mapping(uint chainId => bytes32 bridgeAddress) public override otherBridges;
    // Info about tokens on other chains
    mapping(uint chainId => mapping(bytes32 tokenAddress => bool isSupported)) public override otherBridgeTokens;

    /**
     * @dev Emitted when tokens are sent on the source blockchain.
     */
    event TokensSent(
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger
    );

    /**
     * @dev Emitted when the tokens are received on the destination blockchain.
     */
    event TokensReceived(uint amount, bytes32 recipient, uint nonce, MessengerProtocol messenger, bytes32 message);

    /**
     * @dev Emitted when this contract receives the bridging fee.
     */
    event ReceiveFee(uint bridgeTransactionCost, uint messageTransactionCost);

    /**
     * @dev Emitted when this contract charged the sender with the tokens for the bridging fee.
     */
    event BridgingFeeFromTokens(uint gas);

    /**
     * @dev Emitted when the contract receives native tokens (e.g. Ether on the Ethereum network) from the admin to
     * supply the gas for bridging.
     */
    event Received(address sender, uint amount);

    constructor(
        uint chainId_,
        uint chainPrecision_,
        Messenger allbridgeMessenger_,
        WormholeMessenger wormholeMessenger_,
        IGasOracle gasOracle_
    ) Router(chainPrecision_) MessengerGateway(allbridgeMessenger_, wormholeMessenger_) GasUsage(gasOracle_) {
        chainId = chainId_;
    }

    /**
     * @notice Initiates a swap and bridge process of a given token for a token on another blockchain.
     * @dev This function is used to initiate a cross-chain transfer. The specified amount of token is first transferred
     * to the pool on the current chain, and then an event `TokensSent` is emitted to signal that tokens have been sent
     * on the source chain. See the function `receiveTokens`.
     * The bridging fee required for the cross-chain transfer can be paid in two ways:
     * - by sending the required amount of native gas token along with the transaction
     *   (See `getTransactionCost` in the `GasUsage` contract and `getMessageCost` in the `MessengerGateway` contract).
     * - by setting the parameter `feeTokenAmount` with the bridging fee amount in the source tokens
     *   (See the function `getBridgingCostInTokens`).
     * @param token The token to be swapped.
     * @param amount The amount of tokens to be swapped (including `feeTokenAmount`).
     * @param destinationChainId The ID of the destination chain.
     * @param receiveToken The token to receive in exchange for the swapped token.
     * @param nonce An identifier that is used to ensure that each transfer is unique and can only be processed once.
     * @param messenger The chosen way of delivering the message across chains.
     * @param feeTokenAmount The amount of tokens to be deducted from the transferred amount as a bridging fee.
     *
     */
    function swapAndBridge(
        bytes32 token,
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint feeTokenAmount
    ) external payable override whenCanSwap {
        require(amount > feeTokenAmount, "Bridge: amount too low for fee");
        require(recipient != 0, "Bridge: bridge to the zero address");
        uint bridgingFee = msg.value + _convertBridgingFeeInTokensToNativeToken(msg.sender, token, feeTokenAmount);
        uint amountAfterFee = amount - feeTokenAmount;

        uint vUsdAmount = _sendAndSwapToVUsd(token, msg.sender, amountAfterFee);
        _sendTokens(vUsdAmount, recipient, destinationChainId, receiveToken, nonce, messenger, bridgingFee);
    }

    /**
     * @notice Completes the bridging process by sending the tokens on the destination chain to the recipient.
     * @dev This function is called only after a bridging has been initiated by a user
     *      through the `swapAndBridge` function on the source chain.
     * @param amount The amount of tokens being bridged.
     * @param recipient The recipient address for the bridged tokens.
     * @param sourceChainId The ID of the source chain.
     * @param receiveToken The address of the token being received.
     * @param nonce A unique nonce for the bridging transaction.
     * @param messenger The protocol used to relay the message.
     * @param receiveAmountMin The minimum amount of receiveToken required to be received.
     */
    function receiveTokens(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint receiveAmountMin
    ) external payable override whenCanSwap {
        require(otherBridges[sourceChainId] != bytes32(0), "Bridge: source not registered");
        bytes32 messageWithSender = this
            .hashMessage(amount, recipient, sourceChainId, chainId, receiveToken, nonce, messenger)
            .hashWithSender(otherBridges[sourceChainId]);

        require(processedMessages[messageWithSender] == 0, "Bridge: message processed");
        // mark the transfer as received on the destination chain
        processedMessages[messageWithSender] = 1;

        // check if tokens has been sent on the source chain
        require(this.hasReceivedMessage(messageWithSender, messenger), "Bridge: no message");

        uint receiveAmount = _receiveAndSwapFromVUsd(
            receiveToken,
            address(uint160(uint(recipient))),
            amount,
            receiveAmountMin
        );
        // pass extra gas to the recipient
        if (msg.value > 0) {
            // ignore if passing extra gas failed
            // solc-ignore-next-line unused-call-retval
            payable(address(uint160(uint(recipient)))).call{value: msg.value}("");
        }
        emit TokensReceived(receiveAmount, recipient, nonce, messenger, messageWithSender);
    }

    /**
     * @notice Allows the admin to add new supported chain destination.
     * @dev Registers the address of a bridge deployed on a different chain.
     * @param chainId_ The chain ID of the bridge to register.
     * @param bridgeAddress The address of the bridge contract to register.
     */
    function registerBridge(uint chainId_, bytes32 bridgeAddress) external override onlyOwner {
        otherBridges[chainId_] = bridgeAddress;
    }

    /**
     * @notice Allows the admin to add a new supported destination token.
     * @dev Adds the address of a token on another chain to the list of supported tokens for the specified chain.
     * @param chainId_ The chain ID where the token is deployed.
     * @param tokenAddress The address of the token to add as a supported token.
     */
    function addBridgeToken(uint chainId_, bytes32 tokenAddress) external override onlyOwner {
        otherBridgeTokens[chainId_][tokenAddress] = true;
    }

    /**
     * @notice Allows the admin to remove support for a destination token.
     * @dev Removes the address of a token on another chain from the list of supported tokens for the specified chain.
     * @param chainId_ The chain ID where the token is deployed.
     * @param tokenAddress The address of the token to remove from the list of supported tokens.
     */
    function removeBridgeToken(uint chainId_, bytes32 tokenAddress) external override onlyOwner {
        otherBridgeTokens[chainId_][tokenAddress] = false;
    }

    /**
     * @notice Allows the admin to withdraw the bridging fee collected in native tokens.
     */
    function withdrawGasTokens(uint amount) external override onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Allows the admin to withdraw the bridging fee collected in tokens.
     * @param token The address of the token contract.
     */
    function withdrawBridgingFeeInTokens(IERC20 token) external onlyOwner {
        uint toWithdraw = token.balanceOf(address(this));
        if (toWithdraw > 0) {
            token.safeTransfer(msg.sender, toWithdraw);
        }
    }

    /**
     * @dev Calculates the amount of bridging fee nominated in a given token, which includes:
     * - the gas cost of making the receive transaction on the destination chain,
     * - the gas cost of sending the message to the destination chain using the specified messenger protocol.
     * @param destinationChainId The ID of the destination chain.
     * @param messenger The chosen way of delivering the message across chains.
     * @param tokenAddress The address of the token contract on the source chain.
     * @return The total price of bridging, with the precision according to the token's `decimals()` value.
     */
    function getBridgingCostInTokens(
        uint destinationChainId,
        MessengerProtocol messenger,
        address tokenAddress
    ) external view override returns (uint) {
        return
            gasOracle.getTransactionGasCostInUSD(
                destinationChainId,
                gasUsage[destinationChainId] + getMessageGasUsage(destinationChainId, messenger)
            ) / fromGasOracleScalingFactor[tokenAddress];
    }

    /**
     * @dev Produces a hash of transfer parameters, which is used as a message to the bridge on the destination chain
     *      to notify that the tokens on the source chain has been sent.
     * @param amount The amount of tokens being transferred.
     * @param recipient The address of the recipient on the destination chain.
     * @param sourceChainId The ID of the source chain.
     * @param destinationChainId The ID of the destination chain.
     * @param receiveToken The token being received on the destination chain.
     * @param nonce The unique nonce.
     * @param messenger The chosen way of delivering the message across chains.
     */
    function hashMessage(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger
    ) external pure override returns (bytes32) {
        return
            keccak256(abi.encodePacked(amount, recipient, sourceChainId, receiveToken, nonce, messenger))
                .replaceChainBytes(uint8(sourceChainId), uint8(destinationChainId));
    }

    function _sendTokens(
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint bridgingFee
    ) internal {
        require(destinationChainId != chainId, "Bridge: wrong destination chain");
        require(otherBridgeTokens[destinationChainId][receiveToken], "Bridge: unknown chain or token");
        bytes32 message = this.hashMessage(
            amount,
            recipient,
            chainId,
            destinationChainId,
            receiveToken,
            nonce,
            messenger
        );

        require(sentMessages[message] == 0, "Bridge: tokens already sent");
        // mark the transfer as sent on the source chain
        sentMessages[message] = 1;

        uint bridgeTransactionCost = this.getTransactionCost(destinationChainId);
        uint messageTransactionCost = _sendMessage(message, messenger);
        emit ReceiveFee(bridgeTransactionCost, messageTransactionCost);
        unchecked {
            require(bridgingFee >= bridgeTransactionCost + messageTransactionCost, "Bridge: not enough fee");
        }
        emit TokensSent(amount, recipient, destinationChainId, receiveToken, nonce, messenger);
    }

    /**
     * @dev Charges the bridging fee in tokens and calculates the amount of native tokens that correspond
     *      to the charged fee using the current exchange rate.
     * @param user The address of the user who is paying the bridging fee
     * @param tokenAddress The address of the token used to pay the bridging fee
     * @param feeTokenAmount The amount of tokens to pay as the bridging fee
     * @return bridging fee amount in the native tokens (e.g. in wei for Ethereum)
     */
    function _convertBridgingFeeInTokensToNativeToken(
        address user,
        bytes32 tokenAddress,
        uint feeTokenAmount
    ) internal returns (uint) {
        if (feeTokenAmount == 0) return 0;
        address tokenAddress_ = address(uint160(uint(tokenAddress)));

        IERC20 token = IERC20(tokenAddress_);
        token.safeTransferFrom(user, address(this), feeTokenAmount);

        uint fee = (bridgingFeeConversionScalingFactor[tokenAddress_] * feeTokenAmount) / gasOracle.price(chainId);

        emit BridgingFeeFromTokens(fee);
        return fee;
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";

/**
 * @title GasOracle
 * @dev A contract that provides gas price and native token USD price data on other blockchains.
 */
contract GasOracle is Ownable, IGasOracle {
    struct ChainData {
        // price of the chain's native token in USD
        uint128 price;
        // price of a gas unit in the chain's native token with precision according to the const ORACLE_PRECISION
        uint128 gasPrice;
    }
    uint private constant ORACLE_PRECISION = 18;
    uint private constant ORACLE_SCALING_FACTOR = 10 ** ORACLE_PRECISION;
    // number to divide by to change precision from gas oracle price precision to chain precision
    uint private immutable fromOracleToChainScalingFactor;

    mapping(uint chainId => ChainData) public override chainData;
    // current chain ID
    uint public immutable override chainId;

    constructor(uint chainId_, uint chainPrecision) {
        chainId = chainId_;
        fromOracleToChainScalingFactor = 10 ** (ORACLE_PRECISION - chainPrecision);
    }

    /**
     * @notice Sets the chain data for a given chain ID.
     * @param chainId_ The ID of the given chain to set data for.
     * @param price_ The price of the given chain's native token in USD.
     * @param gasPrice The price of a gas unit in the given chain's native token (with precision according to the const
     * `ORACLE_PRECISION`).
     */
    function setChainData(uint chainId_, uint128 price_, uint128 gasPrice) external override onlyOwner {
        chainData[chainId_].price = price_;
        chainData[chainId_].gasPrice = gasPrice;
    }

    /**
     * @notice Sets only the price for a given chain ID.
     * @param chainId_ The ID of the given chain to set the price for.
     * @param price_ The price of the given chain's native token in USD.
     */
    function setPrice(uint chainId_, uint128 price_) external override onlyOwner {
        chainData[chainId_].price = price_;
    }

    /**
     * @notice Sets only the gas price for a given chain ID.
     * @param chainId_ The ID of the given chain to set the gas price for.
     * @param gasPrice The price of a gas unit in the given chain's native token (with precision according to the const
     * `ORACLE_PRECISION`).
     */
    function setGasPrice(uint chainId_, uint128 gasPrice) external override onlyOwner {
        chainData[chainId_].gasPrice = gasPrice;
    }

    /**
     * @notice Calculates the gas cost of a transaction on another chain in the current chain's native token.
     * @param otherChainId The ID of the chain for which to get the gas cost.
     * @param gasAmount The amount of gas used in a transaction.
     * @return The gas cost of a transaction in the current chain's native token
     */
    function getTransactionGasCostInNativeToken(
        uint otherChainId,
        uint gasAmount
    ) external view override returns (uint) {
        return
            (chainData[otherChainId].gasPrice * gasAmount * chainData[otherChainId].price) /
            chainData[chainId].price /
            fromOracleToChainScalingFactor;
    }

    /**
     * @notice Calculates the gas cost of a transaction on another chain in USD.
     * @param otherChainId The ID of the chain for which to get the gas cost.
     * @param gasAmount The amount of gas used in a transaction.
     * @return The gas cost of a transaction in USD with precision of `ORACLE_PRECISION`
     */
    function getTransactionGasCostInUSD(uint otherChainId, uint gasAmount) external view override returns (uint) {
        return (chainData[otherChainId].gasPrice * gasAmount * chainData[otherChainId].price) / ORACLE_SCALING_FACTOR;
    }

    /**
     * @notice Get the cross-rate between the two chains' native tokens.
     * @param otherChainId The ID of the other chain to get the cross-rate for.
     */
    function crossRate(uint otherChainId) external view override returns (uint) {
        return (chainData[otherChainId].price * ORACLE_SCALING_FACTOR) / chainData[chainId].price;
    }

    /**
     * @notice Get the price of a given chain's native token in USD.
     * @param chainId_ The ID of the given chain to get the price.
     * @return the price of the given chain's native token in USD with precision of const ORACLE_PRECISION
     */
    function price(uint chainId_) external view override returns (uint) {
        return chainData[chainId_].price;
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        revert("Unsupported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";

/**
 * @dev Contract module which allows children to store typical gas usage of a certain transaction on another chain.
 */
abstract contract GasUsage is Ownable {
    IGasOracle internal gasOracle;
    mapping(uint chainId => uint amount) public gasUsage;

    constructor(IGasOracle gasOracle_) {
        gasOracle = gasOracle_;
    }

    /**
     * @dev Sets the amount of gas used for a transaction on a given chain.
     * @param chainId The ID of the chain.
     * @param gasAmount The amount of gas used on the chain.
     */
    function setGasUsage(uint chainId, uint gasAmount) external onlyOwner {
        gasUsage[chainId] = gasAmount;
    }

    /**
     * @dev Sets the Gas Oracle contract address.
     * @param gasOracle_ The address of the Gas Oracle contract.
     */
    function setGasOracle(IGasOracle gasOracle_) external onlyOwner {
        gasOracle = gasOracle_;
    }

    /**
     * @notice Get the gas cost of a transaction on another chain in the current chain's native token.
     * @param chainId The ID of the chain for which to get the gas cost.
     * @return The calculated gas cost of the transaction in the current chain's native token
     */
    function getTransactionCost(uint chainId) external view returns (uint) {
        unchecked {
            return gasOracle.getTransactionGasCostInNativeToken(chainId, gasUsage[chainId]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum MessengerProtocol {
    None,
    Allbridge,
    Wormhole,
    LayerZero
}

interface IBridge {
    function chainId() external view returns (uint);

    function processedMessages(bytes32) external view returns (uint);

    function sentMessages(bytes32) external view returns (uint);

    function otherBridges(uint) external view returns (bytes32);

    function otherBridgeTokens(uint, bytes32) external view returns (bool);

    function getBridgingCostInTokens(
        uint destinationChainId,
        MessengerProtocol messenger,
        address tokenAddress
    ) external view returns (uint);

    function hashMessage(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger
    ) external pure returns (bytes32);

    function receiveTokens(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint receiveAmountMin
    ) external payable;

    function withdrawGasTokens(uint amount) external;

    function registerBridge(uint chainId, bytes32 bridgeAddress) external;

    function addBridgeToken(uint chainId, bytes32 tokenAddress) external;

    function removeBridgeToken(uint chainId, bytes32 tokenAddress) external;

    function swapAndBridge(
        bytes32 token,
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint feeTokenAmount
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IGasOracle {
    function chainData(uint chainId) external view returns (uint128 price, uint128 gasPrice);

    function chainId() external view returns (uint);

    function crossRate(uint otherChainId) external view returns (uint);

    function getTransactionGasCostInNativeToken(uint otherChainId, uint256 gasAmount) external view returns (uint);

    function getTransactionGasCostInUSD(uint otherChainId, uint256 gasAmount) external view returns (uint);

    function price(uint chainId) external view returns (uint);

    function setChainData(uint chainId, uint128 price, uint128 gasPrice) external;

    function setGasPrice(uint chainId, uint128 gasPrice) external;

    function setPrice(uint chainId, uint128 price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMessenger {
    function sentMessagesBlock(bytes32 message) external view returns (uint);

    function receivedMessages(bytes32 message) external view returns (uint);

    function sendMessage(bytes32 message) external payable;

    function receiveMessage(bytes32 message, uint v1v2, bytes32 r1, bytes32 s1, bytes32 r2, bytes32 s2) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MessengerProtocol} from "./IBridge.sol";

interface IRouter {
    function canSwap() external view returns (uint8);

    function swap(uint amount, bytes32 token, bytes32 receiveToken, address recipient, uint receiveAmountMin) external;
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.18;

interface Structs {
    struct Provider {
        uint16 chainId;
        uint16 governanceChainId;
        bytes32 governanceContract;
    }

    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }
}

interface IWormhole is Structs {
    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(
        bytes calldata encodedVM
    ) external view returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(
        bytes32 hash,
        Structs.Signature[] memory signatures,
        Structs.GuardianSet memory guardianSet
    ) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library HashUtils {
    function replaceChainBytes(
        bytes32 data,
        uint8 sourceChainId,
        uint8 destinationChainId
    ) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, data)
            mstore8(0x00, sourceChainId)
            mstore8(0x01, destinationChainId)
            result := mload(0x0)
        }
    }

    function hashWithSender(bytes32 message, bytes32 sender) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            mstore(0x20, sender)
            result := or(
                and(
                    message,
                    0xffff000000000000000000000000000000000000000000000000000000000000 // First 2 bytes
                ),
                and(
                    keccak256(0x00, 0x40),
                    0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Last 30 bytes
                )
            )
        }
    }

    function hashWithSenderAddress(bytes32 message, address sender) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            mstore(0x20, sender)
            result := or(
                and(
                    message,
                    0xffff000000000000000000000000000000000000000000000000000000000000 // First 2 bytes
                ),
                and(
                    keccak256(0x00, 0x40),
                    0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Last 30 bytes
                )
            )
        }
    }

    function hashed(bytes32 message) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            result := keccak256(0x00, 0x20)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {IMessenger} from "./interfaces/IMessenger.sol";
import {GasUsage} from "./GasUsage.sol";
import {HashUtils} from "./libraries/HashUtils.sol";

/**
 * @dev This contract implements the Allbridge messenger cross-chain communication protocol.
 */
contract Messenger is Ownable, GasUsage, IMessenger {
    using HashUtils for bytes32;
    // current chain ID
    uint public immutable chainId;
    // supported destination chain IDs
    bytes32 public otherChainIds;

    // the primary account that is responsible for validation that a message has been sent on the source chain
    address private primaryValidator;
    // the secondary accounts that are responsible for validation that a message has been sent on the source chain
    mapping(address => bool) private secondaryValidators;
    mapping(bytes32 messageHash => uint blockNumber) public override sentMessagesBlock;
    mapping(bytes32 messageHash => uint isReceived) public override receivedMessages;

    event MessageSent(bytes32 indexed message);
    event MessageReceived(bytes32 indexed message);

    /**
     * @dev Emitted when the contract receives native gas tokens (e.g. Ether on the Ethereum network).
     */
    event Received(address, uint);

    /**
     * @dev Emitted when the mapping of secondary validators is updated.
     */
    event SecondaryValidatorsSet(address[] oldValidators, address[] newValidators);

    constructor(
        uint chainId_,
        bytes32 otherChainIds_,
        IGasOracle gasOracle_,
        address primaryValidator_,
        address[] memory validators
    ) GasUsage(gasOracle_) {
        chainId = chainId_;
        otherChainIds = otherChainIds_;
        primaryValidator = primaryValidator_;

        uint length = validators.length;
        for (uint index; index < length; ) {
            secondaryValidators[validators[index]] = true;
            unchecked {
                index++;
            }
        }
    }

    /**
     * @notice Sends a message to another chain.
     * @dev Emits a {MessageSent} event, which signals to the off-chain messaging service to invoke the `receiveMessage`
     * function on the destination chain to deliver the message.
     *
     * Requirements:
     *
     * - the first byte of the message must be the current chain ID.
     * - the second byte of the message must be the destination chain ID.
     * - the same message cannot be sent second time.
     * - messaging fee must be payed. (See `getTransactionCost` of the `GasUsage` contract).
     * @param message The message to be sent to the destination chain.
     */
    function sendMessage(bytes32 message) external payable override {
        require(uint8(message[0]) == chainId, "Messenger: wrong chainId");
        require(otherChainIds[uint8(message[1])] != 0, "Messenger: wrong destination");

        bytes32 messageWithSender = message.hashWithSenderAddress(msg.sender);

        require(sentMessagesBlock[messageWithSender] == 0, "Messenger: has message");
        sentMessagesBlock[messageWithSender] = block.number;

        require(msg.value >= this.getTransactionCost(uint8(message[1])), "Messenger: not enough fee");

        emit MessageSent(messageWithSender);
    }

    /**
     * @notice Delivers a message to the destination chain.
     * @dev Emits an {MessageReceived} event indicating the message has been delivered.
     *
     * Requirements:
     *
     * - a valid signature of the primary validator.
     * - a valid signature of one of the secondary validators.
     * - the second byte of the message must be the current chain ID.
     */
    function receiveMessage(
        bytes32 message,
        uint v1v2,
        bytes32 r1,
        bytes32 s1,
        bytes32 r2,
        bytes32 s2
    ) external override {
        bytes32 hashedMessage = message.hashed();
        require(ecrecover(hashedMessage, uint8(v1v2 >> 8), r1, s1) == primaryValidator, "Messenger: invalid primary");
        require(secondaryValidators[ecrecover(hashedMessage, uint8(v1v2), r2, s2)], "Messenger: invalid secondary");

        require(uint8(message[1]) == chainId, "Messenger: wrong chainId");

        receivedMessages[message] = 1;

        emit MessageReceived(message);
    }

    /**
     * @dev Allows the admin to withdraw the messaging fee collected in native gas tokens.
     */
    function withdrawGasTokens(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Allows the admin to set the primary validator address.
     */
    function setPrimaryValidator(address value) external onlyOwner {
        primaryValidator = value;
    }

    /**
     * @dev Allows the admin to set the addresses of secondary validators.
     */
    function setSecondaryValidators(address[] memory oldValidators, address[] memory newValidators) external onlyOwner {
        uint length = oldValidators.length;
        uint index;
        for (; index < length; ) {
            secondaryValidators[oldValidators[index]] = false;
            unchecked {
                index++;
            }
        }
        length = newValidators.length;
        index = 0;
        for (; index < length; ) {
            secondaryValidators[newValidators[index]] = true;
            unchecked {
                index++;
            }
        }
        emit SecondaryValidatorsSet(oldValidators, newValidators);
    }

    /**
     * @dev Allows the admin to update a list of supported destination chain IDs
     * @param value Each byte of the `value` parameter represents whether a chain ID with such index is supported
     *              as a valid message destination.
     */
    function setOtherChainIds(bytes32 value) external onlyOwner {
        otherChainIds = value;
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {Messenger} from "./Messenger.sol";
import {MessengerProtocol} from "./interfaces/IBridge.sol";
import {WormholeMessenger} from "./WormholeMessenger.sol";

/**
 * @dev This abstract contract provides functions for cross-chain communication and supports different messaging
 *      protocols.
 */
abstract contract MessengerGateway is Ownable {
    Messenger private allbridgeMessenger;
    WormholeMessenger private wormholeMessenger;

    constructor(Messenger allbridgeMessenger_, WormholeMessenger wormholeMessenger_) {
        allbridgeMessenger = allbridgeMessenger_;
        wormholeMessenger = wormholeMessenger_;
    }

    /**
     * @dev Sets the Allbridge Messenger contract address.
     * @param allbridgeMessenger_ The address of the Messenger contract.
     */
    function setAllbridgeMessenger(Messenger allbridgeMessenger_) external onlyOwner {
        allbridgeMessenger = allbridgeMessenger_;
    }

    /**
     * @dev Sets the Wormhole Messenger contract address.
     * @param wormholeMessenger_ The address of the WormholeMessenger contract.
     */
    function setWormholeMessenger(WormholeMessenger wormholeMessenger_) external onlyOwner {
        wormholeMessenger = wormholeMessenger_;
    }

    /**
     * @notice Get the gas cost of a messaging transaction on another chain in the current chain's native token.
     * @param chainId The ID of the chain where to send the message.
     * @param protocol The messenger used to send the message.
     * @return The calculated gas cost of the messaging transaction in the current chain's native token.
     */
    function getMessageCost(uint chainId, MessengerProtocol protocol) external view returns (uint) {
        if (protocol == MessengerProtocol.Allbridge) {
            return allbridgeMessenger.getTransactionCost(chainId);
        } else if (protocol == MessengerProtocol.Wormhole) {
            return wormholeMessenger.getTransactionCost(chainId);
        }
        return 0;
    }

    /**
     * @notice Get the amount of gas a messaging transaction uses on a given chain.
     * @param chainId The ID of the chain where to send the message.
     * @param protocol The messenger used to send the message.
     * @return The amount of gas a messaging transaction uses.
     */
    function getMessageGasUsage(uint chainId, MessengerProtocol protocol) public view returns (uint) {
        if (protocol == MessengerProtocol.Allbridge) {
            return allbridgeMessenger.gasUsage(chainId);
        } else if (protocol == MessengerProtocol.Wormhole) {
            return wormholeMessenger.gasUsage(chainId);
        }
        return 0;
    }

    /**
     * @notice Checks whether a given message has been received via the specified messenger protocol.
     * @param message The message to check.
     * @param protocol The messenger used to send the message.
     * @return A boolean indicating whether the message has been received.
     */
    function hasReceivedMessage(bytes32 message, MessengerProtocol protocol) external view returns (bool) {
        if (protocol == MessengerProtocol.Allbridge) {
            return allbridgeMessenger.receivedMessages(message) != 0;
        } else if (protocol == MessengerProtocol.Wormhole) {
            return wormholeMessenger.receivedMessages(message) != 0;
        } else {
            revert("Not implemented");
        }
    }

    /**
     * @notice Checks whether a given message has been sent.
     * @param message The message to check.
     * @return A boolean indicating whether the message has been sent.
     */
    function hasSentMessage(bytes32 message) external view returns (bool) {
        return allbridgeMessenger.sentMessagesBlock(message) != 0 || wormholeMessenger.sentMessages(message) != 0;
    }

    function _sendMessage(bytes32 message, MessengerProtocol protocol) internal returns (uint messageCost) {
        if (protocol == MessengerProtocol.Allbridge) {
            messageCost = allbridgeMessenger.getTransactionCost(uint8(message[1]));
            allbridgeMessenger.sendMessage{value: messageCost}(message);
        } else if (protocol == MessengerProtocol.Wormhole) {
            messageCost = wormholeMessenger.getTransactionCost(uint8(message[1]));
            wormholeMessenger.sendMessage{value: messageCost}(message);
        } else {
            revert("Not implemented");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {RewardManager} from "./RewardManager.sol";

/**
 * 4AD - D = 4A(x + y) - (D³ / 4xy)
 * X - is value of real stable token
 * Y - is value of virtual usd
 */
contract Pool is RewardManager {
    using SafeERC20 for ERC20;
    uint private constant SYSTEM_PRECISION = 3;
    int private constant PP = 1e4; // Price Precision
    uint private constant MAX_TOKEN_BALANCE = 2 ** 40; // Max possible token balance

    /**
     * @dev Gas optimization: both the 'feeShareBP' and 'router' fields are used during the 'swapFromVUsd', 'swapToVUsd'
     * operations and can occupy the same slot.
     */
    uint16 public feeShareBP;
    address public router;
    uint public tokenBalance;
    uint public vUsdBalance;
    uint public balanceRatioMinBP;
    uint public reserves;
    uint public immutable a;
    uint public d;

    uint private immutable tokenAmountReduce;
    uint private immutable tokenAmountIncrease;

    // can restrict deposit or withdraw operations
    address private stopAuthority;
    // is deposit operation allowed
    uint public canDeposit = 1;
    // is withdraw operation allowed
    uint public canWithdraw = 1;

    event SwappedToVUsd(address sender, address token, uint amount, uint vUsdAmount, uint fee);
    event SwappedFromVUsd(address recipient, address token, uint vUsdAmount, uint amount, uint fee);

    constructor(
        address router_,
        uint a_,
        ERC20 token_,
        uint16 feeShareBP_,
        uint balanceRatioMinBP_,
        string memory lpName,
        string memory lpSymbol
    ) RewardManager(token_, lpName, lpSymbol) {
        a = a_;
        router = router_;
        stopAuthority = owner();
        feeShareBP = feeShareBP_;
        balanceRatioMinBP = balanceRatioMinBP_;

        uint decimals = token_.decimals();
        tokenAmountReduce = decimals > SYSTEM_PRECISION ? 10 ** (decimals - SYSTEM_PRECISION) : 0;
        tokenAmountIncrease = decimals < SYSTEM_PRECISION ? 10 ** (SYSTEM_PRECISION - decimals) : 0;
    }

    /**
     * @dev Throws if called by any account other than the router.
     */
    modifier onlyRouter() {
        require(router == msg.sender, "Pool: is not router");
        _;
    }

    /**
     * @dev Throws if called by any account other than the stopAuthority.
     */
    modifier onlyStopAuthority() {
        require(stopAuthority == msg.sender, "Pool: is not stopAuthority");
        _;
    }

    /**
     * @dev Modifier to prevent function from disbalancing the pool over a threshold defined by `balanceRatioMinBP`
     */
    modifier validateBalanceRatio() {
        _;
        if (tokenBalance > vUsdBalance) {
            require((vUsdBalance * BP) / tokenBalance >= balanceRatioMinBP, "Pool: low vUSD balance");
        } else if (tokenBalance < vUsdBalance) {
            require((tokenBalance * BP) / vUsdBalance >= balanceRatioMinBP, "Pool: low token balance");
        }
    }

    /**
     * @dev Modifier to make a function callable only when the deposit is allowed.
     */
    modifier whenCanDeposit() {
        require(canDeposit == 1, "Pool: deposit prohibited");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the withdraw is allowed.
     */
    modifier whenCanWithdraw() {
        require(canWithdraw == 1, "Pool: withdraw prohibited");
        _;
    }

    /**
     * @dev Calculates the price and deposit token according to the amount and price, then adds the same amount to the X
     * and to the Y
     * @param amount The deposited amount
     */
    function deposit(uint amount) external whenCanDeposit {
        uint oldD = d;

        uint amountSP = _toSystemPrecision(amount);
        require(amountSP > 0, "Pool: too little");

        token.safeTransferFrom(msg.sender, address(this), amount);

        // Add deposited amount to reserves
        reserves += amountSP;

        uint oldBalance = (tokenBalance + vUsdBalance);
        if (oldD == 0 || oldBalance == 0) {
            // Split balance equally on the first deposit
            uint halfAmount = amountSP >> 1;
            tokenBalance += halfAmount;
            vUsdBalance += halfAmount;
        } else {
            // Add amount proportionally to each pool
            tokenBalance += (amountSP * tokenBalance) / oldBalance;
            vUsdBalance += (amountSP * vUsdBalance) / oldBalance;
        }
        _updateD();
        // Deposit as many LP tokens as the D increase
        _depositLp(msg.sender, d - oldD);

        require(tokenBalance < MAX_TOKEN_BALANCE, "Pool: too much");
    }

    /*
     * @dev Subtracts X and Y for that amount, calculates current price and withdraw the token to the user according to
     * the price
     * @param amount The deposited amount
     */
    function withdraw(uint amountLp) external whenCanWithdraw {
        uint oldD = d;
        _withdrawLp(msg.sender, amountLp);

        // Always withdraw tokens in amount equal to amountLp

        // Withdraw proportionally from token and vUsd balance
        uint oldBalance = (tokenBalance + vUsdBalance);
        tokenBalance -= (amountLp * tokenBalance) / oldBalance;
        vUsdBalance -= (amountLp * vUsdBalance) / oldBalance;

        require(tokenBalance + vUsdBalance < oldBalance, "Pool: zero changes");

        // Check if there is enough funds in reserve to withdraw
        require(amountLp <= reserves, "Pool: reserves");

        // Adjust reserves by withdraw amount
        reserves -= amountLp;

        // Update D and transfer tokens to the sender
        _updateD();
        require(d < oldD, "Pool: zero D changes");

        token.safeTransfer(msg.sender, _fromSystemPrecision(amountLp));
    }

    /**
     * @notice Calculates new virtual USD value from the given amount of tokens.
     * @dev Calculates new Y according to new X.
     * NOTICE: Prior to calling this the router must transfer tokens from the user to the pool.
     * @param amount The amount of tokens to swap.
     * @param zeroFee When true it allows to swap without incurring any fees. It is intended for use with service
     * accounts.
     * @return returns the difference between the old and the new value of vUsdBalance
     */
    function swapToVUsd(
        address user,
        uint amount,
        bool zeroFee
    ) external onlyRouter validateBalanceRatio returns (uint) {
        uint result; // 0 by default
        uint fee;
        if (amount > 0) {
            if (!zeroFee) {
                fee = (amount * feeShareBP) / BP;
            }
            uint amountIn = _toSystemPrecision(amount - fee);
            // Incorporate rounding dust into the fee
            fee = amount - _fromSystemPrecision(amountIn);

            // Adjust token and reserve balances after the fee is applied
            tokenBalance += amountIn;
            reserves += amountIn;

            uint vUsdNewAmount = this.getY(tokenBalance);
            if (vUsdBalance > vUsdNewAmount) {
                result = vUsdBalance - vUsdNewAmount;
            }
            vUsdBalance = vUsdNewAmount;
            _addRewards(fee);
        }

        emit SwappedToVUsd(user, address(token), amount, result, fee);
        return result;
    }

    /**
     * @notice Calculates the amount of tokens from the given virtual USD value, and transfers it to the user.
     * @dev Calculates new X according to new Y.
     * @param user The address of the recipient.
     * @param amount The amount of vUSD to swap.
     * @param receiveAmountMin The minimum amount of tokens required to be received during the swap, otherwise the
     * transaction reverts.
     * @param zeroFee When true it allows to swap without incurring any fees. It is intended for use with service
     * accounts.
     * @return returns the difference between the old and the new value of vUsdBalance
     */
    function swapFromVUsd(
        address user,
        uint amount,
        uint receiveAmountMin,
        bool zeroFee
    ) external onlyRouter validateBalanceRatio returns (uint) {
        uint resultSP; // 0 by default
        uint result; // 0 by default
        uint fee;
        if (amount > 0) {
            vUsdBalance += amount;
            uint newAmount = this.getY(vUsdBalance);
            if (tokenBalance > newAmount) {
                resultSP = tokenBalance - newAmount;
                result = _fromSystemPrecision(resultSP);
            } // Otherwise result/resultSP stay 0

            // Check if there is enough funds in reserve to pay
            require(resultSP <= reserves, "Pool: reserves");
            // Remove from reserves including fee, apply fee later
            reserves -= resultSP;
            if (!zeroFee) {
                fee = (result * feeShareBP) / BP;
            }
            // We can use unchecked here because feeShareBP <= BP
            unchecked {
                result -= fee;
            }

            tokenBalance = newAmount;
            require(result >= receiveAmountMin, "Pool: slippage");
            token.safeTransfer(user, result);
            _addRewards(fee);
        }
        emit SwappedFromVUsd(user, address(token), amount, result, fee);
        return result;
    }

    /**
     * @dev Sets admin fee share.
     */
    function setFeeShare(uint16 feeShareBP_) external onlyOwner {
        require(feeShareBP_ <= BP, "Pool: too large");
        feeShareBP = feeShareBP_;
    }

    function adjustTotalLpAmount() external onlyOwner {
        if (d > totalSupply()) {
            _depositLp(owner(), d - totalSupply());
        }
    }

    /**
     * @dev Sets the threshold over which the pool can't be disbalanced.
     */
    function setBalanceRatioMinBP(uint balanceRatioMinBP_) external onlyOwner {
        require(balanceRatioMinBP_ <= BP, "Pool: too large");
        balanceRatioMinBP = balanceRatioMinBP_;
    }

    /**
     * @dev Switches off the possibility to make deposits.
     */
    function stopDeposit() external onlyStopAuthority {
        canDeposit = 0;
    }

    /**
     * @dev Switches on the possibility to make deposits.
     */
    function startDeposit() external onlyOwner {
        canDeposit = 1;
    }

    /**
     * @dev Switches off the possibility to make withdrawals.
     */
    function stopWithdraw() external onlyStopAuthority {
        canWithdraw = 0;
    }

    /**
     * @dev Switches on the possibility to make withdrawals.
     */
    function startWithdraw() external onlyOwner {
        canWithdraw = 1;
    }

    /**
     * @dev Sets the address of the stopAuthority account.
     */
    function setStopAuthority(address stopAuthority_) external onlyOwner {
        stopAuthority = stopAuthority_;
    }

    /**
     * @dev Sets the address of the Router contract.
     */
    function setRouter(address router_) external onlyOwner {
        router = router_;
    }

    /**
     * @dev y = (sqrt(x(4AD³ + x (4A(D - x) - D )²)) + x (4A(D - x) - D ))/8Ax.
     */
    function getY(uint x) external view returns (uint) {
        uint d_ = d; // Gas optimization
        uint a4 = a << 2;
        uint a8 = a4 << 1;
        // 4A(D - x) - D
        int part1 = int(a4) * (int(d_) - int(x)) - int(d_);
        // x * (4AD³ + x(part1²))
        uint part2 = x * (a4 * d_ * d_ * d_ + x * uint(part1 * part1));
        // (sqrt(part2) + x(part1)) / 8Ax)
        return SafeCast.toUint256(int(_sqrt(part2)) + int(x) * part1) / (a8 * x) + 1; // +1 to offset rounding errors
    }

    /**
     * @dev price = (1/2) * ((D³ + 8ADx² - 8Ax³ - 2Dx²) / (4x * sqrt(x(4AD³ + x (4A(D - x) - D )²))))
     */
    function getPrice() external view returns (uint) {
        uint x = tokenBalance;
        uint a8 = a << 3;
        uint dCubed = d * d * d;

        // 4A(D - x) - D
        int p1 = int(a << 2) * (int(d) - int(x)) - int(d);
        // x * 4AD³ + x(p1²)
        uint p2 = x * ((a << 2) * dCubed + x * uint(p1 * p1));
        // D³ + 8ADx² - 8Ax³ - 2Dx²
        int p3 = int(dCubed) + int((a << 3) * d * x * x) - int(a8 * x * x * x) - int((d << 1) * x * x);
        // 1/2 * p3 / (4x * sqrt(p2))
        return SafeCast.toUint256((PP >> 1) + ((PP * p3) / int((x << 2) * _sqrt(p2))));
    }

    function _updateD() internal {
        uint x = tokenBalance;
        uint y = vUsdBalance;
        // a = 8 * Axy(x+y)
        // b = 4 * xy(4A - 1) / 3
        // c = sqrt(a² + b³)
        // D = cbrt(a + c) + cbrt(a - c)
        uint xy = x * y;
        uint a_ = a;
        // Axy(x+y)
        uint p1 = a_ * xy * (x + y);
        // xy(4A - 1) / 3
        uint p2 = (xy * ((a_ << 2) - 1)) / 3;
        // p1² + p2³
        uint p3 = _sqrt((p1 * p1) + (p2 * p2 * p2));
        unchecked {
            uint d_ = _cbrt(p1 + p3);
            if (p3 > p1) {
                d_ -= _cbrt(p3 - p1);
            } else {
                d_ += _cbrt(p1 - p3);
            }
            d = (d_ << 1);
        }
    }

    function _toSystemPrecision(uint amount) internal view returns (uint) {
        if (tokenAmountReduce > 0) {
            return amount / tokenAmountReduce;
        } else if (tokenAmountIncrease > 0) {
            return amount * tokenAmountIncrease;
        }
        return amount;
    }

    function _fromSystemPrecision(uint amount) internal view returns (uint) {
        if (tokenAmountReduce > 0) {
            return amount * tokenAmountReduce;
        } else if (tokenAmountIncrease > 0) {
            return amount / tokenAmountIncrease;
        }
        return amount;
    }

    function _sqrt(uint n) internal pure returns (uint) {
        unchecked {
            if (n > 0) {
                uint x = (n >> 1) + 1;
                uint y = (x + n / x) >> 1;
                while (x > y) {
                    x = y;
                    y = (x + n / x) >> 1;
                }
                return x;
            }
            return 0;
        }
    }

    function _cbrt(uint n) internal pure returns (uint) {
        unchecked {
            uint x = 0;
            for (uint y = 1 << 255; y > 0; y >>= 3) {
                x <<= 1;
                uint z = 3 * x * (x + 1) + 1;
                if (n / y >= z) {
                    n -= y * z;
                    x += 1;
                }
            }
            return x;
        }
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        revert("Unsupported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardManager is Ownable, ERC20 {
    using SafeERC20 for ERC20;
    uint private constant P = 52;
    uint internal constant BP = 1e4;

    // Accumulated rewards per share, shifted left by P bits
    uint public accRewardPerShareP;

    // Reward token
    ERC20 public immutable token;
    // Info of each user reward debt
    mapping(address user => uint amount) public userRewardDebt;

    // Admin fee share (in basis points)
    uint public adminFeeShareBP;
    // Unclaimed admin fee amount
    uint public adminFeeAmount;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event RewardsClaimed(address indexed user, uint amount);

    constructor(ERC20 token_, string memory lpName, string memory lpSymbol) ERC20(lpName, lpSymbol) {
        token = token_;
        // Default admin fee is 20%
        adminFeeShareBP = BP / 5;
    }

    /**
     * @notice Claims pending rewards for the current staker without updating the stake balance.
     */
    function claimRewards() external {
        uint userLpAmount = balanceOf(msg.sender);
        if (userLpAmount > 0) {
            uint rewards = (userLpAmount * accRewardPerShareP) >> P;
            uint pending = rewards - userRewardDebt[msg.sender];
            if (pending > 0) {
                userRewardDebt[msg.sender] = rewards;
                token.safeTransfer(msg.sender, pending);
                emit RewardsClaimed(msg.sender, pending);
            }
        }
    }

    /**
     * @notice Sets the basis points of the admin fee share from rewards.
     */
    function setAdminFeeShare(uint adminFeeShareBP_) external onlyOwner {
        require(adminFeeShareBP_ <= BP, "RewardManager: too high");
        adminFeeShareBP = adminFeeShareBP_;
    }

    /**
     * @notice Allows the admin to claim the collected admin fee.
     */
    function claimAdminFee() external onlyOwner {
        if (adminFeeAmount > 0) {
            token.safeTransfer(msg.sender, adminFeeAmount);
            adminFeeAmount = 0;
        }
    }

    /**
     * @notice Returns pending rewards for the staker.
     * @param user The address of the staker.
     */
    function pendingReward(address user) external view returns (uint) {
        return ((balanceOf(user) * accRewardPerShareP) >> P) - userRewardDebt[user];
    }

    /**
     * @dev Returns the number of decimals used to get user representation of LP tokens.
     */
    function decimals() public pure override returns (uint8) {
        return 3;
    }

    /**
     * @dev Adds reward to the pool, splits admin fee share and updates the accumulated rewards per share.
     */
    function _addRewards(uint rewardAmount) internal {
        if (totalSupply() > 0) {
            uint adminFeeRewards = (rewardAmount * adminFeeShareBP) / BP;
            unchecked {
                rewardAmount -= adminFeeRewards;
            }
            accRewardPerShareP += (rewardAmount << P) / totalSupply();
            adminFeeAmount += adminFeeRewards;
        }
    }

    /**
     * @dev Deposits LP amount for the user, updates user reward debt and pays pending rewards.
     */
    function _depositLp(address to, uint lpAmount) internal {
        uint pending;
        uint userLpAmount = balanceOf(to); // Gas optimization
        if (userLpAmount > 0) {
            pending = ((userLpAmount * accRewardPerShareP) >> P) - userRewardDebt[to];
        }
        userLpAmount += lpAmount;
        _mint(to, lpAmount);
        userRewardDebt[to] = (userLpAmount * accRewardPerShareP) >> P;
        if (pending > 0) {
            token.safeTransfer(to, pending);
            emit RewardsClaimed(to, pending);
        }
        emit Deposit(to, lpAmount);
    }

    /**
     * @dev Withdraws LP amount for the user, updates user reward debt and pays out pending rewards.
     */
    function _withdrawLp(address from, uint lpAmount) internal {
        uint userLpAmount = balanceOf(from); // Gas optimization
        require(userLpAmount >= lpAmount, "RewardManager: not enough amount");
        uint pending;
        if (userLpAmount > 0) {
            pending = ((userLpAmount * accRewardPerShareP) >> P) - userRewardDebt[from];
        }
        userLpAmount -= lpAmount;
        _burn(from, lpAmount);
        userRewardDebt[from] = (userLpAmount * accRewardPerShareP) >> P;
        if (pending > 0) {
            token.safeTransfer(from, pending);
            emit RewardsClaimed(from, pending);
        }
        emit Withdraw(from, lpAmount);
    }

    function _transfer(address, address, uint) internal pure override {
        revert("Unsupported");
    }

    function _approve(address, address, uint) internal pure override {
        revert("Unsupported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {MessengerProtocol} from "./interfaces/IBridge.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pool} from "./Pool.sol";

abstract contract Router is Ownable, IRouter {
    using SafeERC20 for ERC20;
    uint private immutable chainPrecision;
    uint internal constant ORACLE_PRECISION = 18;

    mapping(bytes32 tokenId => Pool) public pools;
    // precomputed values to divide by to change the precision from the Gas Oracle precision to the token precision
    mapping(address tokenAddress => uint scalingFactor) internal fromGasOracleScalingFactor;
    // precomputed values of the scaling factor required for paying the bridging fee with stable tokens
    mapping(address tokenAddress => uint scalingFactor) internal bridgingFeeConversionScalingFactor;

    // can restrict swap operations
    address private stopAuthority;

    /**
     * @dev The rebalancer is an account responsible for balancing the liquidity pools. It ensures that the pool is
     * balanced by executing zero-fee swaps when the pool is imbalanced.
     *
     * Gas optimization: both the 'rebalancer' and 'canSwap' fields are used in the 'swap' and 'swapAndBridge'
     * functions and can occupy the same slot.
     */
    address private rebalancer;
    uint8 public override canSwap = 1;

    /**
     * @dev Emitted during the on-chain swap of tokens.
     */
    event Swapped(
        address sender,
        address recipient,
        bytes32 sendToken,
        bytes32 receiveToken,
        uint sendAmount,
        uint receiveAmount
    );

    constructor(uint chainPrecision_) {
        chainPrecision = chainPrecision_;
        stopAuthority = owner();
    }

    /**
     * @dev Modifier to make a function callable only when the swap is allowed.
     */
    modifier whenCanSwap() {
        require(canSwap == 1, "Router: swap prohibited");
        _;
    }

    /**
     * @dev Throws if called by any account other than the stopAuthority.
     */
    modifier onlyStopAuthority() {
        require(stopAuthority == msg.sender, "Router: is not stopAuthority");
        _;
    }

    /**
     * @notice Swaps a given pair of tokens on the same blockchain.
     * @param amount The amount of tokens to be swapped.
     * @param token The token to be swapped.
     * @param receiveToken The token to receive in exchange for the swapped token.
     * @param recipient The address to receive the tokens.
     * @param receiveAmountMin The minimum amount of tokens required to receive during the swap.
     */
    function swap(
        uint amount,
        bytes32 token,
        bytes32 receiveToken,
        address recipient,
        uint receiveAmountMin
    ) external override whenCanSwap {
        uint vUsdAmount = _sendAndSwapToVUsd(token, msg.sender, amount);
        uint receivedAmount = _receiveAndSwapFromVUsd(receiveToken, recipient, vUsdAmount, receiveAmountMin);
        emit Swapped(msg.sender, recipient, token, receiveToken, amount, receivedAmount);
    }

    /**
     * @notice Allows the admin to add new supported liquidity pools.
     * @dev Adds the address of the `Pool` contract to the list of supported liquidity pools.
     * @param pool The address of the `Pool` contract.
     * @param token The address of the token in the liquidity pool.
     */
    function addPool(Pool pool, bytes32 token) external onlyOwner {
        pools[token] = pool;
        address tokenAddress = address(uint160(uint(token)));
        uint tokenDecimals = ERC20(tokenAddress).decimals();
        bridgingFeeConversionScalingFactor[tokenAddress] = 10 ** (ORACLE_PRECISION - tokenDecimals + chainPrecision);
        fromGasOracleScalingFactor[tokenAddress] = 10 ** (ORACLE_PRECISION - tokenDecimals);
    }

    /**
     * @dev Switches off the possibility to make swaps.
     */
    function stopSwap() external onlyStopAuthority {
        canSwap = 0;
    }

    /**
     * @dev Switches on the possibility to make swaps.
     */
    function startSwap() external onlyOwner {
        canSwap = 1;
    }

    /**
     * @dev Allows the admin to set the address of the stopAuthority.
     */
    function setStopAuthority(address stopAuthority_) external onlyOwner {
        stopAuthority = stopAuthority_;
    }

    /**
     * @dev Allows the admin to set the address of the rebalancer.
     */
    function setRebalancer(address rebalancer_) external onlyOwner {
        rebalancer = rebalancer_;
    }

    function _receiveAndSwapFromVUsd(
        bytes32 token,
        address recipient,
        uint vUsdAmount,
        uint receiveAmountMin
    ) internal returns (uint) {
        Pool tokenPool = pools[token];
        require(address(tokenPool) != address(0), "Router: no receive pool");
        return tokenPool.swapFromVUsd(recipient, vUsdAmount, receiveAmountMin, recipient == rebalancer);
    }

    function _sendAndSwapToVUsd(bytes32 token, address user, uint amount) internal virtual returns (uint) {
        Pool pool = pools[token];
        require(address(pool) != address(0), "Router: no pool");
        ERC20(address(uint160(uint(token)))).safeTransferFrom(user, address(pool), amount);
        return pool.swapToVUsd(user, amount, user == rebalancer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IBridge, MessengerProtocol} from "../interfaces/IBridge.sol";
import {Router} from "../Router.sol";

contract TestBridgeForSwap is IBridge, Router {
    uint public chainId;
    mapping(bytes32 messageHash => uint isProcessed) public override processedMessages;
    mapping(bytes32 messageHash => uint isSent) public override sentMessages;
    // Info about bridges on other chains
    mapping(uint chainId => bytes32 bridgeAddress) public override otherBridges;
    // Info about tokens on other chains
    mapping(uint chainId => mapping(bytes32 tokenAddress => bool isSupported)) public override otherBridgeTokens;

    event vUsdSent(uint amount);

    constructor() Router(18) {}

    function swapAndBridge(
        bytes32 token,
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint feeTokenAmount
    ) external payable override {}

    function receiveTokens(
        uint amount,
        bytes32,
        uint,
        bytes32 receiveToken,
        uint,
        MessengerProtocol,
        uint receiveAmountMin
    ) external payable override {}

    function withdrawGasTokens(uint amount) external override onlyOwner {}

    function registerBridge(uint chainId_, bytes32 bridgeAddress_) external override onlyOwner {}

    function addBridgeToken(uint chainId_, bytes32 tokenAddress_) external override onlyOwner {}

    function removeBridgeToken(uint chainId_, bytes32 tokenAddress_) external override onlyOwner {}

    function getBridgingCostInTokens(
        uint,
        MessengerProtocol,
        address
    ) external pure override returns (uint) {
        return 0;
    }

    function hashMessage(
        uint,
        bytes32,
        uint,
        uint,
        bytes32,
        uint,
        MessengerProtocol
    ) external pure override returns (bytes32) {
        return 0;
    }

    function _sendAndSwapToVUsd(bytes32 token, address user, uint amount) internal override returns (uint) {
        uint vUsdAmount = super._sendAndSwapToVUsd(token, user, amount);
        emit vUsdSent(vUsdAmount);
        return vUsdAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pool} from "../Pool.sol";
import {RewardManager} from "../RewardManager.sol";

contract TestPool is Pool {
    constructor(
        address router_,
        uint a_,
        ERC20 token_,
        uint16 feeShareBP_,
        uint balanceRatioMinBP_
    ) Pool(router_, a_, token_, feeShareBP_, balanceRatioMinBP_, "LP", "LP") {}

    function setVUsdBalance(uint vUsdBalance_) public {
        vUsdBalance = vUsdBalance_;
    }

    function setTokenBalance(uint tokenBalance_) public {
        tokenBalance = tokenBalance_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RewardManager} from "../RewardManager.sol";

contract TestPoolForRewards is RewardManager {
    // solhint-disable-next-line no-empty-blocks
    constructor(ERC20 token) RewardManager(token, "LP", "LP") {}

    function deposit(uint amount) external {
        _depositLp(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        _withdrawLp(msg.sender, amount);
    }

    function addRewards(uint amount) external {
        _addRewards(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {IMessenger} from "./interfaces/IMessenger.sol";
import {IWormhole} from "./interfaces/IWormhole.sol";
import {GasUsage} from "./GasUsage.sol";
import {GasOracle} from "./GasOracle.sol";
import {HashUtils} from "./libraries/HashUtils.sol";

contract WormholeMessenger is Ownable, GasUsage {
    using HashUtils for bytes32;

    IWormhole private immutable wormhole;
    uint public immutable chainId;
    bytes32 public otherChainIds;

    uint32 private nonce;
    uint8 private commitmentLevel;

    mapping(uint16 chainId => bytes32 wormholeMessengerAddress) private otherWormholeMessengers;

    mapping(bytes32 messageHash => uint isReceived) public receivedMessages;
    mapping(bytes32 messageHash => uint isSent) public sentMessages;

    event MessageSent(bytes32 indexed message, uint64 sequence);
    event MessageReceived(bytes32 indexed message, uint64 sequence);
    event Received(address, uint);

    constructor(
        uint chainId_,
        bytes32 otherChainIds_,
        IWormhole wormhole_,
        uint8 commitmentLevel_,
        IGasOracle gasOracle_
    ) GasUsage(gasOracle_) {
        chainId = chainId_;
        otherChainIds = otherChainIds_;
        wormhole = wormhole_;
        commitmentLevel = commitmentLevel_;
    }

    function sendMessage(bytes32 message) external payable {
        require(uint8(message[0]) == chainId, "WormholeMessenger: wrong chainId");
        require(otherChainIds[uint8(message[1])] != 0, "Messenger: wrong destination");
        bytes32 messageWithSender = message.hashWithSenderAddress(msg.sender);

        uint32 nonce_ = nonce;

        uint64 sequence = wormhole.publishMessage(nonce_, abi.encodePacked(messageWithSender), commitmentLevel);

        unchecked {
            nonce = nonce_ + 1;
        }

        require(sentMessages[messageWithSender] == 0, "WormholeMessenger: has message");
        sentMessages[messageWithSender] = 1;

        emit MessageSent(messageWithSender, sequence);
    }

    function receiveMessage(bytes memory encodedMsg) external {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(encodedMsg);

        require(valid, reason);
        require(vm.payload.length == 32, "WormholeMessenger: wrong length");

        bytes32 messageWithSender = bytes32(vm.payload);
        require(uint8(messageWithSender[1]) == chainId, "WormholeMessenger: wrong chainId");

        require(otherWormholeMessengers[vm.emitterChainId] == vm.emitterAddress, "WormholeMessenger: wrong emitter");

        receivedMessages[messageWithSender] = 1;

        emit MessageReceived(messageWithSender, vm.sequence);
    }

    function setCommitmentLevel(uint8 value) external onlyOwner {
        commitmentLevel = value;
    }

    function setOtherChainIds(bytes32 value) external onlyOwner {
        otherChainIds = value;
    }

    function registerWormholeMessenger(uint16 chainId_, bytes32 address_) external onlyOwner {
        otherWormholeMessengers[chainId_] = address_;
    }

    function withdrawGasTokens(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}