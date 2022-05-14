/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig()
        external
        view
        returns (
            uint16,
            uint32,
            bytes32[] memory
        );

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;
}

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ILizzieWizzie {
    function mintFromGame(address to) external;

    function balanceOf(address) external view returns (uint256);

    function encounteredLizzieWizzie(address who) external view returns (bool);

    function rememberEncounter(address who) external;

    function getAmountMintedFromGame() external view returns (uint256);

    function getMaxMintedFromGame() external view returns (uint256);
}

contract FuLeoVesmirny is ERC20, Ownable, VRFConsumerBaseV2 {
    // Basic units
    uint256 private constant ONE_HOUR = 60 * 60;
    uint256 private constant PERCENT_DENOMENATOR = 1000;
    address private constant DEAD = address(0xdead);

    // Mandatory things for Chainlink VRF
    VRFCoordinatorV2Interface vrfCoord;
    LinkTokenInterface link;
    uint64 private _vrfSubscriptionId;
    bytes32 private _vrfKeyHash;
    uint32 private _vrfCallbackGasLimit = 600000;

    // Wager Amounts

    mapping(uint256 => address) private _wagerInit;
    // Who wagered how much
    mapping(address => uint256) private _wagerInitAmount;
    // Total wagered amount
    uint256 private _wagerBalance;

    // Possible Moves (experimental)
    enum Move {
        ROCK,
        PAPER,
        SCISSORS,
        LIZARD,
        SPOCK
    }

    event LizardWizard(address who, uint256 wagerAmount);
    event Rektage(address who, uint256 wagerAmount);

    // What the player played against Chainlink
    mapping(uint256 => Move) private _playedAgainstChainlink;

    // The least amount of % needed for a bet
    uint256 public RPSLSMinBalancePerc = (PERCENT_DENOMENATOR * 30) / 100; // 30% user's balance

    // How much one gets for a win
    uint256 public RPSLSWinPercentage = (PERCENT_DENOMENATOR * 80) / 100; // 80% wager amount

    // How much is returned upon draw
    uint256 public RPSLSDrawPercentage = (PERCENT_DENOMENATOR * 97) / 100; // uint256 = 970 => 97% wager amount

    // How much is taxed upon a loss (the rest is burned)
    uint256 public RPSLSLoseTaxPercentage = (PERCENT_DENOMENATOR * 10) / 100; // 10% is sent to the treasury (Dev & Marketing + LP Nuke & Reward Pool), the rest is burnt

    // RPSLS stats
    struct rpsls {
        uint256 wins;
        uint256 loses;
        uint256 draws;
        uint256 amountWon;
        uint256 amountLost;
    }
    mapping(Move => rpsls) rlspsStats;

    // Hourly Biggest Buyer Rewards
    uint256 public biggestBuyRewardPercentage =
        (PERCENT_DENOMENATOR * 50) / 100; // 50%
    mapping(uint256 => address) public biggestBuyer;
    mapping(uint256 => uint256) public biggestBuyerAmount;
    mapping(uint256 => uint256) public biggestBuyerPaid;

    // recording player stats
    struct stats {
        uint256 wins;
        uint256 amountWon;
        uint256 loses;
        uint256 amountLost;
        uint256 draws;
    }
    mapping(address => stats) public playerStats;

    // LP Nuke Mechanism
    address private _nukeRecipient = DEAD;
    uint256 public lpNukeBuildup;
    uint256 public nukePercentPerSell = (PERCENT_DENOMENATOR * 25) / 100; // 25%
    bool public lpNukeEnabled = true;

    address public treasury;

    address public devAndMarketingWallet =
        0x2E06678014abe962451Dc50eB8379E1c46793B4d;

    // The Government does not pay taxes
    mapping(address => bool) private _isTaxExcluded;
    uint256 public taxLp = (PERCENT_DENOMENATOR * 1) / 100; // 1%
    uint256 public taxBuyer = (PERCENT_DENOMENATOR * 1) / 100; // 1%
    uint256 public taxMarketingAndDevelopment = (PERCENT_DENOMENATOR * 1) / 100; // 1%
    uint256 public sellTaxUnwageredMultiplier = 4; // init 12% (3% * 4) (Note: 3% is the sum of TaxLp + taxBuyer + taxMarketingAndDevelopment)
    uint256 private _totalTax;
    bool private _taxesOff;
    mapping(address => bool) public canSellWithoutElevation;

    // Adding to Liquidity
    uint256 private _liquifyRate = (PERCENT_DENOMENATOR * 1) / 100; // 1%

    // Time units
    uint256 public launchTime;
    uint256 private _launchBlock;

    // Uniswap addresses
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Lizzy Wizzy Contract
    ILizzieWizzie public LizzieWizzieNFTs;

    // Blacklisted Bots
    mapping(address => bool) private _isBot;

    // Top players
    struct topStat {
        address who;
        uint256 amount;
    }

    topStat public biggestWin = topStat(DEAD, 0);
    topStat public biggestLoss = topStat(DEAD, 0);

    event newBiggestWinner(address who, uint256 amount);
    event newBiggestLoser(address who, uint256 amount);

    // Swapping variables and swapLock
    bool private _swapEnabled = true;
    bool private _swapping = false;

    modifier swapLock() {
        _swapping = true;
        _;
        _swapping = false;
    }

    // Events
    event InitiatedRPSLSvsChainlink(
        address indexed wagerer,
        uint256 indexed requestId,
        Move hand,
        uint256 amountWagered
    );

    event SettledRPSLSvsChainlink(
        address indexed wagerer,
        uint256 indexed requestId,
        uint256 amountWagered,
        Move hand,
        uint256 chainlinkPlayed,
        uint8 result
    );

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        address _linkToken,
        bytes32 _keyHash,
        address _NFTaddress
    ) ERC20("Fu Leo Vesmirny", "FLV") VRFConsumerBaseV2(_vrfCoordinator) {
        _mint(address(this), 1_000_000 * 10**18);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _setTotalTax();
        _isTaxExcluded[address(this)] = true;
        _isTaxExcluded[msg.sender] = true;

        vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
        link = LinkTokenInterface(_linkToken);
        _vrfSubscriptionId = _subscriptionId;
        _vrfKeyHash = _keyHash;

        LizzieWizzieNFTs = ILizzieWizzie(_NFTaddress);
    }

    // _percent: 1 == 0.1%, 1000 = 100%
    function launch(uint16 _percent) external payable onlyOwner {
        require(_percent <= PERCENT_DENOMENATOR, "must be between 0-100%");
        require(launchTime == 0, "already launched");
        require(_percent == 0 || msg.value > 0, "need ETH for initial LP");

        uint256 _lpSupply = (totalSupply() * _percent) / PERCENT_DENOMENATOR;
        uint256 _leftover = totalSupply() - _lpSupply;
        if (_lpSupply > 0) {
            _addLp(_lpSupply, msg.value);
        }
        if (_leftover > 0) {
            _transfer(address(this), owner(), _leftover);
        }
        launchTime = block.timestamp;
        _launchBlock = block.number;
    }

    // Game logic with Chainlink
    function playWithChainlink(uint16 _percent, Move _hand) public {
        require(balanceOf(msg.sender) > 0, "must have a bag to wager");
        require(
            _percent >= RPSLSMinBalancePerc && _percent <= PERCENT_DENOMENATOR,
            "must wager between minimum % amount and your entire bag"
        );

        uint256 _finalWagerAmount = (balanceOf(msg.sender) * _percent) /
            PERCENT_DENOMENATOR;
        require(_wagerInitAmount[msg.sender] == 0, "already initiated");

        _transfer(msg.sender, address(this), _finalWagerAmount);
        _wagerBalance += _finalWagerAmount;

        uint256 requestId = vrfCoord.requestRandomWords(
            _vrfKeyHash,
            _vrfSubscriptionId,
            uint16(3),
            _vrfCallbackGasLimit,
            uint16(2)
        );

        _playedAgainstChainlink[requestId] = _hand;
        _wagerInit[requestId] = msg.sender;
        _wagerInitAmount[msg.sender] = _finalWagerAmount;
        canSellWithoutElevation[msg.sender] = true;

        emit InitiatedRPSLSvsChainlink(
            msg.sender,
            requestId,
            _hand,
            _finalWagerAmount
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        _settleRPSLSvsChainlink(requestId, randomWords[0], randomWords[1]);
    }

    function manualFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external onlyOwner {
        _settleRPSLSvsChainlink(requestId, randomWords[0], randomWords[1]);
    }

    function _settleRPSLSvsChainlink(
        uint256 requestId,
        uint256 randomNumber,
        uint256 lizzieWizzieRektage
    ) private {
        address _user = _wagerInit[requestId];
        require(_user != address(0), "rpslp record does not exist");

        uint256 _amountWagered = _wagerInitAmount[_user];
        Move _move = _playedAgainstChainlink[requestId];
        uint256 rektageOrNot = lizzieWizzieRektage % 100;
        bool lizzyWizzy = false;
        bool rektage = false;
        uint256 rng = randomNumber % 5;
        uint8 result;

        // There is a special chance for a Lizard Wizard, only when Lizard is played
        uint8 lizzyWizzyTolerance = 50;

        if (LizzieWizzieNFTs.balanceOf(_user) > 0) {
            lizzyWizzyTolerance += 50;
        }

        if (rektageOrNot < 1) {
            // Rektage Finger
            rektage = true;
            emit Rektage(_user, _amountWagered);
        } else if (rektageOrNot < lizzyWizzyTolerance) {
            // Lizard Wizard
            lizzyWizzy = true;
        }

        if (_move == Move.LIZARD && lizzyWizzy) {
            // Instantly wins
            uint256 _amountToWin = (_amountWagered * RPSLSWinPercentage) /
                PERCENT_DENOMENATOR;
            _transfer(address(this), _user, _amountWagered);
            _mint(_user, _amountToWin);
            playerStats[_user].wins++;
            playerStats[_user].amountWon += _amountToWin;
            rlspsStats[_move].wins++;
            rlspsStats[_move].amountWon += _amountToWin;
            // won
            result = 1;
            if (_amountToWin > biggestWin.amount) {
                biggestWin = topStat(_user, _amountToWin);
                emit newBiggestWinner(_user, _amountToWin);
            }
            emit LizardWizard(_user, _amountWagered);

            if (!LizzieWizzieNFTs.encounteredLizzieWizzie(_user)) {
                if (
                    LizzieWizzieNFTs.getAmountMintedFromGame() <
                    LizzieWizzieNFTs.getMaxMintedFromGame()
                ) {
                    LizzieWizzieNFTs.rememberEncounter(_user);
                    LizzieWizzieNFTs.mintFromGame(_user);
                }
            }
        } else if (rektage || rng > 2) {
            _burn(
                address(this),
                _amountWagered *
                    ((PERCENT_DENOMENATOR - RPSLSLoseTaxPercentage) /
                        PERCENT_DENOMENATOR)
            );
            _transfer(
                address(this),
                devAndMarketingWallet,
                ((_amountWagered * RPSLSLoseTaxPercentage) /
                    PERCENT_DENOMENATOR) / 2
            );
            playerStats[_user].loses++;
            playerStats[_user].amountLost += _amountWagered;
            rlspsStats[_move].loses++;
            rlspsStats[_move].amountLost += _amountWagered;
            // lost
            result = 0;
            if (_amountWagered > biggestLoss.amount) {
                biggestLoss = topStat(_user, _amountWagered);
                emit newBiggestLoser(_user, _amountWagered);
            }
        } else if (rng > 0) {
            uint256 _amountToWin = (_amountWagered * RPSLSWinPercentage) /
                PERCENT_DENOMENATOR;
            _transfer(address(this), _user, _amountWagered);
            _mint(_user, _amountToWin);
            playerStats[_user].wins++;
            playerStats[_user].amountWon += _amountToWin;
            rlspsStats[_move].wins++;
            rlspsStats[_move].amountWon += _amountToWin;
            // won
            result = 1;
            if (_amountToWin > biggestWin.amount) {
                biggestWin = topStat(_user, _amountToWin);
                emit newBiggestWinner(_user, _amountToWin);
            }
        } else {
            _transfer(
                address(this),
                _user,
                (_amountWagered * RPSLSDrawPercentage) / PERCENT_DENOMENATOR
            );
            playerStats[_user].draws++;
            rlspsStats[_move].draws++;
            // draw
            result = 2;
        }

        _wagerBalance -= _amountWagered;
        delete _wagerInit[requestId];
        // reset to allow wagering again
        delete _wagerInitAmount[_user];
        emit SettledRPSLSvsChainlink(
            _user,
            requestId,
            _amountWagered,
            _move,
            rng,
            result
        );
        delete _playedAgainstChainlink[requestId];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        require(
            _isOwner || amount <= _maxTx(sender, recipient),
            "ERC20: exceed max transaction"
        );
        uint256 contractTokenBalance = balanceOf(address(this)) - _wagerBalance;

        bool _isContract = sender == address(this) ||
            recipient == address(this);
        bool _isBuy = sender == uniswapV2Pair &&
            recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;
        bool _taxIsElevated = !canSellWithoutElevation[sender];
        uint256 _hourAfterLaunch = getHour();

        if (_isBuy) {
            canSellWithoutElevation[recipient] = false;
            if (block.number <= _launchBlock + 2) {
                _isBot[recipient] = true;
            } else if (amount > biggestBuyerAmount[_hourAfterLaunch]) {
                biggestBuyer[_hourAfterLaunch] = recipient;
                biggestBuyerAmount[_hourAfterLaunch] = amount;
            }
        } else {
            require(!_isBot[recipient], "Stop botting!");
            require(!_isBot[sender], "Stop botting!");
            require(!_isBot[_msgSender()], "Stop botting!");

            if (!_isSell && !_isContract) {
                canSellWithoutElevation[recipient] = false;
            }
        }

        _checkAndPayBiggestBuyer(_hourAfterLaunch);

        uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) /
            PERCENT_DENOMENATOR;
        bool _overMin = contractTokenBalance >= _minSwap;
        if (
            _swapEnabled &&
            !_swapping &&
            !_isOwner &&
            _overMin &&
            launchTime != 0 &&
            sender != uniswapV2Pair
        ) {
            _swap(_minSwap);
        }

        uint256 tax = 0;
        if (
            launchTime != 0 &&
            _isSwap &&
            !_taxesOff &&
            !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
        ) {
            tax = (amount * _totalTax) / PERCENT_DENOMENATOR;
            if (tax > 0) {
                if (_isSell && _taxIsElevated) {
                    tax *= (sellTaxUnwageredMultiplier - 1);
                    super._transfer(
                        sender,
                        address(this),
                        tax * ((taxLp + taxBuyer) / _totalTax)
                    );
                    super._transfer(
                        sender,
                        devAndMarketingWallet,
                        tax * (taxMarketingAndDevelopment / _totalTax)
                    );
                    _burn(address(this), tax);
                } else {
                    super._transfer(
                        sender,
                        address(this),
                        tax * ((taxLp + taxBuyer) / _totalTax)
                    );
                    super._transfer(
                        sender,
                        devAndMarketingWallet,
                        tax * (taxMarketingAndDevelopment / _totalTax)
                    );
                }
            }
        }

        super._transfer(sender, recipient, amount - (tax));

        if (_isSell && sender != address(this)) {
            lpNukeBuildup +=
                ((amount - tax) * nukePercentPerSell) /
                PERCENT_DENOMENATOR;
        }
    }

    function _maxTx(address sender, address recipient)
        private
        view
        returns (uint256)
    {
        bool _isOwner = sender == owner() || recipient == owner();
        uint256 expiration = 60 * 15; // 15 minutes
        if (
            _isOwner ||
            launchTime == 0 ||
            block.timestamp > launchTime + expiration
        ) {
            return totalSupply();
        }
        return (totalSupply() * 2) / 100; // 2%
    }

    function _swap(uint256 _amountToSwap) private swapLock {
        uint256 balBefore = address(this).balance;
        uint256 liquidityTokens = (_amountToSwap * taxLp) / _totalTax / 2;
        uint256 tokensToSwap = _amountToSwap - liquidityTokens;

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokensToSwap);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balToProcess = address(this).balance - balBefore;
        if (balToProcess > 0) {
            _processFees(balToProcess, liquidityTokens);
        }
    }

    function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            treasury == address(0) ? owner() : treasury,
            block.timestamp
        );
        // uniswapV2Router.addLiquidity(
        //     uniswapV2Router.WETH(),
        //     address(this),
        //     ethAmount,
        //     tokenAmount,
        //     0,
        //     0,
        //     owner(),
        //     block.timestamp
        // );
    }

    function _processFees(uint256 amountETH, uint256 amountLpTokens) private {
        uint256 lpETH = (amountETH * taxLp) / _totalTax;
        if (amountLpTokens > 0) {
            _addLp(amountLpTokens, lpETH);
        }
    }

    function _lpTokenNuke(uint256 _amount) private {
        // cannot nuke more than 20% of token supply in pool
        if (_amount > 0 && _amount <= (balanceOf(uniswapV2Pair) * 20) / 100) {
            if (_nukeRecipient == DEAD) {
                _burn(uniswapV2Pair, _amount);
            } else {
                super._transfer(uniswapV2Pair, _nukeRecipient, _amount);
            }
            IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
            pair.sync();
        }
    }

    function _checkAndPayBiggestBuyer(uint256 _currentHour) private {
        uint256 _prevHour = _currentHour - 1;
        if (
            _currentHour > 1 &&
            biggestBuyerAmount[_prevHour] > 0 &&
            biggestBuyerPaid[_prevHour] == 0
        ) {
            uint256 _before = address(this).balance;
            if (_before > 0) {
                uint256 _buyerAmount = (_before * biggestBuyRewardPercentage) /
                    PERCENT_DENOMENATOR;
                payable(biggestBuyer[_prevHour]).call{value: _buyerAmount}("");
                require(
                    address(this).balance >= _before - _buyerAmount,
                    "too much ser"
                );
                biggestBuyerPaid[_prevHour] = _buyerAmount;
            }
        }
    }

    function nukeLpTokenFromBuildup() external {
        require(
            msg.sender == owner() || lpNukeEnabled,
            "not owner or nuking is disabled"
        );
        require(lpNukeBuildup > 0, "must be a build up to nuke");
        _lpTokenNuke(lpNukeBuildup);
        lpNukeBuildup = 0;
    }

    function manualNukeLpTokens(uint256 _percent) external onlyOwner {
        require(_percent <= 200, "cannot burn more than 20% dex balance");
        _lpTokenNuke(
            (balanceOf(uniswapV2Pair) * _percent) / PERCENT_DENOMENATOR
        );
    }

    function payBiggestBuyer(uint256 _hour) external onlyOwner {
        _checkAndPayBiggestBuyer(_hour);
    }

    // starts at 1 and increments forever every hour after launch
    function getHour() public view returns (uint256) {
        uint256 secondsSinceLaunch = block.timestamp - launchTime;
        return 1 + (secondsSinceLaunch / ONE_HOUR);
    }

    function isBotBlacklisted(address account) external view returns (bool) {
        return _isBot[account];
    }

    function blacklistBot(address account) external onlyOwner {
        require(account != address(uniswapV2Router), "cannot blacklist router");
        require(account != uniswapV2Pair, "cannot blacklist pair");
        require(!_isBot[account], "user is already blacklisted");
        _isBot[account] = true;
    }

    function forgiveBot(address account) external onlyOwner {
        require(_isBot[account], "user is not blacklisted");
        _isBot[account] = false;
    }

    function _setTotalTax() private {
        _totalTax = taxLp + taxBuyer + taxMarketingAndDevelopment;
        require(
            _totalTax <= (PERCENT_DENOMENATOR * 25) / 100,
            "tax cannot be above 25%"
        );
        require(
            _totalTax * sellTaxUnwageredMultiplier <=
                (PERCENT_DENOMENATOR * 49) / 100,
            "total cannot be more than 49%"
        );
    }

    function setTaxLp(uint256 _tax) external onlyOwner {
        taxLp = _tax;
        _setTotalTax();
    }

    function setTaxBuyer(uint256 _tax) external onlyOwner {
        taxBuyer = _tax;
        _setTotalTax();
    }

    function setTaxMarketingAndDevelopment(uint256 _tax) external onlyOwner {
        taxMarketingAndDevelopment = _tax;
        _setTotalTax();
    }

    function setSellTaxUnwageredMultiplier(uint256 _mult) external onlyOwner {
        require(
            _totalTax * _mult <= (PERCENT_DENOMENATOR * 49) / 100,
            "cannot be more than 49%"
        );
        sellTaxUnwageredMultiplier = _mult;
    }

    function setRSLPSWinPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= PERCENT_DENOMENATOR, "cannot exceed 100%");
        RPSLSWinPercentage = _percentage;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setLiquifyRate(uint256 _rate) external onlyOwner {
        require(_rate <= PERCENT_DENOMENATOR / 10, "cannot be more than 10%");
        _liquifyRate = _rate;
    }

    function setRPSLSMinBalancePerc(uint256 _percentage) external onlyOwner {
        require(_percentage <= PERCENT_DENOMENATOR, "cannot exceed 100%");
        RPSLSMinBalancePerc = _percentage;
    }

    function setIsTaxExcluded(address _wallet, bool _isExcluded)
        external
        onlyOwner
    {
        _isTaxExcluded[_wallet] = _isExcluded;
    }

    function setTaxesOff(bool _areOff) external onlyOwner {
        _taxesOff = _areOff;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled;
    }

    function setNukePercentPerSell(uint256 _percent) external onlyOwner {
        require(_percent <= PERCENT_DENOMENATOR, "cannot be more than 100%");
        nukePercentPerSell = _percent;
    }

    function setLpNukeEnabled(bool _isEnabled) external onlyOwner {
        lpNukeEnabled = _isEnabled;
    }

    function setNukeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "cannot be zero address");
        _nukeRecipient = _recipient;
    }

    function setVrfSubscriptionId(uint64 _subId) external onlyOwner {
        _vrfSubscriptionId = _subId;
    }

    function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
        _vrfCallbackGasLimit = _gas;
    }

    function setDevAndMarketingWallet(address _newAddress) external onlyOwner {
        devAndMarketingWallet = _newAddress;
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).call{value: address(this).balance}("");
    }

    receive() external payable {}
}