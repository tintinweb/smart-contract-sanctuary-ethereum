// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.8.17;

// interface for chainlink random time interval
interface ITournamentConsumer {

    // @dev request a random number if current epoch has not been filled
	function update() external;

    // @dev return current epoch
    function currentEpoch() external view returns (uint256);

    // @dev return if update is possible
    function canUpdate() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITournamentToken is IERC20 {
	function burn(uint256 amount) external;
	function setPauseStatus(bool status) external;
    function setWhitelistStatus(address from, address to, bool status) external;
    function initialize(uint256 initialBalance, string memory name_, string memory symbol_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { TournamentManager } from "../TournamentManager.sol";

contract MockTournamentManager is TournamentManager {
	constructor(
		uint64 _subscriptionId, 
		address coordinatorAddress
	) TournamentManager(_subscriptionId, coordinatorAddress) {}

	function mockFulfillRandomWords(
		uint256 _requestId, 
		uint256[] memory _randomWords) 
	public {
		fulfillRandomWords(_requestId, _randomWords);
	}

	// @dev mock start tournament
	function mockStart() public {
		require(!isTournamentActive, "startTournament: Tournament already active");
		uint256 tournamentUsdc = usdc.balanceOf(address(this)) - pendingRewards - pendingFees;
		isTournamentActive = true;
		tournaments[id].bracket = INITIAL_BRACKET;
		round = 0;
		deployTokens();
		addUniswapLiquidity();
		startRound();
		emit TournamentStarted(id, tournamentUsdc);
	}

	// @dev mock end round
	function mockStop() public {
		stop();
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ITournamentConsumer } from "./interfaces/ITournamentConsumer.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 *
 * Randomness
 * - Trading is divided into 30 minute epochs (e)
 * - Random number is generated by chainlink VRF
 * - Every 30 minutes a public function update() can be called
 * - update() has a e/120 chance of ending a round
 * - As e increases, the chance of the round ending also increases
 * - p(e) = 1 - Σ(n = 0, e) ( (120 - e) / 120 )
 * - Epoch (e), minutes (t), probability (p)
 *  |----------------|
 *  |  e    t    p   |
 *  |----------------|
 *  |  0    0   0.00 |
 *  |  1    30  0.01 | ~ 1% chance round has ended
 *  |  2    60  0.02 |
 *  |  3    90  0.05 |
 *  |  4    120 0.08 |
 *  |  5    150 0.12 |
 *  |  6    180 0.16 |
 *  |  7    210 0.21 |
 *  |  8    240 0.26 | ~25% chance round has ended
 *  |  9    270 0.32 |
 *  | 10    300 0.38 |
 *  | 11    330 0.43 |
 *  | 12    360 0.49 | ~50% chance round has ended
 *  | 13    390 0.55 |
 *  | 14    420 0.60 |
 *  | 15    450 0.65 |
 *  | 16    480 0.70 |
 *  | 17    510 0.74 | ~75% chance round had ended
 *  | 18    540 0.78 |
 *  | 19    570 0.81 |
 *  | 20    600 0.84 |
 *  | 21    630 0.87 |
 *  | 22    660 0.90 |
 *  | 23    690 0.92 |
 *  | 24    720 0.93 |
 *  | 25    750 0.95 |
 *  | 26    780 0.96 |
 *  | 27    810 0.97 |
 *  | 28    840 0.97 |
 *  | 29    870 0.98 |
 *  | 30    900 0.99 | ~99% chance round has ended
 *  |----------------|
 * 
 **/
contract TournamentConsumer is VRFConsumerBaseV2, ITournamentConsumer {
    address public owner;
    address public pendingOwner;

    // HARDCODED FOR MUMBAI
    address constant COORDINATOR_ADDRESS = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

    // Chainlink VRF Parameters. See: https://docs.chain.link/vrf/v2/subscription/supported-networks
    VRFCoordinatorV2Interface public coordinator;

    // 500 GWEI POLYGON
    bytes32 public keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
    uint32 public callbackGasLimit = 25000000;
    uint32 public numWords = 1;
    uint64 public subscriptionId;
    uint16 public requestConfirmations = 2;

    // time interval storage
    bool public isActive;
    uint256 public intervalId;
	uint256 public maxEpoch;
	uint256 public epochTime;
    uint256 public lastEpochFilled;
    uint256 public startTime;
    uint256 public delay;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(uint64 _subscriptionId, address _coordinator) VRFConsumerBaseV2(_coordinator) {
        coordinator = VRFCoordinatorV2Interface(_coordinator);
        subscriptionId = _subscriptionId;
        maxEpoch = 140;
        epochTime = 30 minutes;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner: sender is not owner");
        _;
    }

    // @dev transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
    }

    // @dev claim ownership
    function claimOwnership() external {
        require(msg.sender == pendingOwner, "claimOwnership: sender is not pending owner");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    // @dev set delay before starting
    function setDelay(uint256 newDelay) external onlyOwner {
        delay = newDelay;
    }

    // @dev set subscription ID
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    // @dev set subscription ID
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    // @dev set coordinator
    function setCoordinator(address _coordinator) external onlyOwner {
        coordinator = VRFCoordinatorV2Interface(_coordinator);
    }

    // @dev set key hash
    function setkeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    // @dev start interval
	function start() internal virtual {
		require(!isActive, "VRF start: already active.");
        lastEpochFilled = 0;
        startTime = block.timestamp;
		isActive = true;
        // tournament.start();
	}

    // stop interval
    function stop() internal virtual {
        require(isActive, "VRF stop: not active.");
        isActive = false;
        intervalId++;
        // tournament.stop();
    }

    // @dev request a random number if current epoch has not been filled
	function update() public {
		require(isActive, "VRF update: must be active.");
        require(currentEpoch() > lastEpochFilled, "VRF update: current epoch already filled.");

        // Will revert if subscription is not set and funded.
        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RequestSent(requestId, numWords);
        lastEpochFilled = currentEpoch();
	}

    // @dev return current epoch
    function currentEpoch() public view returns (uint256) {
        if (!isActive) { return 0; }
        if (block.timestamp < startTime + delay) { return 0; }
        return (block.timestamp - startTime - delay) / epochTime;
    }

    // @dev return if update is possible
    function canUpdate() public view returns (bool) {
        return currentEpoch() > lastEpochFilled;
    }

    // @dev Chainlink callback function
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 value = _randomWords[0] % maxEpoch;
        lastEpochFilled = currentEpoch();
        if(value <= currentEpoch() || currentEpoch() == maxEpoch) {
            stop();
        }
        emit RequestFulfilled(_requestId, _randomWords);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { TournamentToken } from "./TournamentToken.sol";
import { ITournamentToken } from "./interfaces/ITournamentToken.sol";
import { TournamentConsumer } from "./TournamentConsumer.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IUniswapV2FactoryCustomFee } from "./uniswap/interfaces/IUniswapV2FactoryCustomFee.sol";
import { IUniswapV2PairCustomFee } from "./uniswap/interfaces/IUniswapV2PairCustomFee.sol";
import { IUniswapV2Router02CustomFee } from "./uniswap/interfaces/IUniswapV2Router02CustomFee.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev
 * Token IDs
 * - Each tokenId is stored in a mapping (uint8 => address)
 * 
 * Bracket storage
 * - Tournament bracket is a uint8[16]
 * - Each byte contains a uint8 representing tokenId
 * - 0xff represents unresolved game state uint8(-1)
 * - Winner of each round is stored in the next empty slot
 * 
 * MatchId: (tokenId, tokenId) -> winnerId
 * 
 * Round      0               1               2
 * 		 0: (0,1) -> A   4: (A,B) -> E   6: (E,F) -> Winner
 * 		 1: (2,3) -> B   5: (C,D) -> F
 * 		 2: (4,5) -> C
 * 		 3: (6,7) -> D
 * 
 * Bracket (each slot uint8)
 *  
 *  0 \
 *     8 
 *  1 /  \
 *        12
 *  2 \  /  \
 *     9     \
 *  3 /       \
 *            14 (winner)
 *  4 \       /
 *     10    /
 *  5 /  \  /
 *        13
 *  6 \  /
 *     11
 *  7 /
 * 
 * Lifecycle
 * startTournament() -> startRound() -> endRound() -> endTournament()
 * 
 * Redemption
 * - Winning token can be burned for usdc at end of each tournament
 * - tournaments[id].reward = tournament_usdc_amount / winning_token_supply
 * - redeem() fuction used to transfer + burn winning tokens for reward_usdc/token
 * - Pending rewards tracked in contract, burning tokens limits reward to token supply
 * 
 **/
contract TournamentManager is TournamentConsumer {
	using SafeERC20 for IERC20;
	using SafeERC20 for ERC20;
	using SafeERC20 for ITournamentToken;

	address public manager;
	address public tokenImplementation;

	IUniswapV2FactoryCustomFee public factory;
	IUniswapV2Router02CustomFee public router;
	address public usdcAddress;
	IERC20 public usdc;
	uint256 constant PRECISION = 1e18;
	uint256 constant BASIS_PRECISION = 10000;

	// initial balance of each token = 10,000
	uint256 constant public STARTING_BALANCE = 10000000000000000000000;
	string[8] NAMES = [
		"Sith", "Jedi", "Mandalorian", "Hutts Cartel", "Tusken Raiders",
		"Techno Union", "Nightsisters", "Death Watch"
	];
	string[8] SYMBOLS = ["SITH", "JEDI", "MANDO", "HUTT", "TUSK", "TECH", "NSIS", "DEAW"];
	uint8[16] INITIAL_BRACKET = [0, 1, 2, 3, 4, 5, 6, 7, 255, 255, 255, 255, 255, 255, 255, 255];

	// data for current tournament in progress
	uint8 public round;
	bool public isTournamentActive;
	bool public isRoundActive;
	bool public isTradingPaused;
	bool public initialized;

	// rewards & fees in USDC
	uint256 public pendingRewards;
	uint256 public pendingFees;

	// tournaments
	uint256 public id; // tournament ID
	mapping(uint256 => Tournament) public tournaments;

	// Previous k value for a token pair. Used to calculate fees.
	mapping(address => uint256) kLast;

	struct Tournament {
		address[8] tokens;	// array of tournament tokens
		uint8[16] bracket;	// tournament bracket
		uint256 reward;		// reward per winning token
	}

	constructor(
		uint64 _subscriptionId,
		address coordinatorAddress
	) TournamentConsumer(_subscriptionId, coordinatorAddress) {}

	event ManagementTransferred(address newManager);
	event TokenImplementationChanged(address newImplementation);
	event TournamentStarted(uint256 indexed tournamentId, uint256 tournamentUsdc);
	event RoundStarted(uint256 indexed tournamentId, uint8 round);
	event TradingPauseStatusSet(bool status);
	event RoundEnded(uint256 indexed tournamentId, uint8 round, uint8[16] bracket);
	event MatchResolved(uint256 indexed tournamentId, uint8 tokenA, uint8 tokenB, uint8 winningId, uint256 totalUsdc);
	event TournamentResolved(uint256 indexed tournamentId, address indexed winningToken, uint256 reward);
	event Redeem(uint256 tournamentId, uint256 amount, address indexed sender);
	event FeeCollected(uint256 amount);
	event EmergencyPauseTrading(bool status);

	function initialize(IUniswapV2Router02CustomFee _router, address _usdcAddress, address _tokenImplementation) external {
		require(!initialized, "already initialized");
		initialized = true;
		owner = msg.sender;
		manager = msg.sender;
		router = _router;
		tokenImplementation = _tokenImplementation;
		factory = IUniswapV2FactoryCustomFee(router.factory());
		usdcAddress = _usdcAddress;
		usdc = IERC20(_usdcAddress);
		usdc.approve(address(router), type(uint).max);
	}

	modifier onlyManager() {
		require(msg.sender == manager, "onlyManger: sender is not manager");
		_;
	}

	// @dev Transfer Management
	function transferManagement(address newManager) external onlyOwner {
		manager = newManager;
		emit ManagementTransferred(newManager);
	}

	// @dev Set Tournament token implementation
	function setTokenImplementation(address _tokenImplementation) external onlyOwner {
		require(_tokenImplementation != address(0), "Cannot be zero address");
		tokenImplementation = _tokenImplementation;
		emit TokenImplementationChanged(_tokenImplementation);
	}

	// @dev set router and factory
	function setRouter(address _router) external onlyOwner {
		require(_router != address(0), "Cannot be zero address");
		router = IUniswapV2Router02CustomFee(_router);
		factory = IUniswapV2FactoryCustomFee(router.factory());
	}

	// @dev collect fee
	function collectFee() external onlyOwner {
		uint256 pending = pendingFees;
		pendingFees = 0; // check-effects-interactions
		usdc.safeTransfer(owner, pending);
		emit FeeCollected(pending);
	}

	// @dev withdraw all usdc liquidity in emergency
	function emergencyWithdraw() external onlyOwner {
		if (isTradingPaused) {
			setTokenPauseStatus(false);
		}
		IUniswapV2PairCustomFee pair;
		address tokenAddress;
		for (uint8 i = 0; i < 8; i ++) {
			tokenAddress = tournaments[id].tokens[i];
			pair = IUniswapV2PairCustomFee(factory.getPair(tokenAddress, usdcAddress));
			router.removeLiquidity(
				tokenAddress, usdcAddress, pair.balanceOf(address(this)), 0, 0, address(this), block.timestamp
			);
		}
		usdc.safeTransfer(owner, usdc.balanceOf(address(this)));
	}

	// @dev set token pause status in emergency
	function emergencySetTradingPauseStatus(bool status) external onlyOwner {
		setTokenPauseStatus(status);
		emit EmergencyPauseTrading(status);
	}

	// @dev seed liquidity, create pools, mint tokens
	// @dev whitelist manager & factory to transfer between each other during pauses
	function startTournament() external onlyManager {
		require(!isTournamentActive, "startTournament: Tournament already active");
		uint256 tournamentUsdc = usdc.balanceOf(address(this)) - pendingRewards - pendingFees;
		isTournamentActive = true;
		tournaments[id].bracket = INITIAL_BRACKET;
		round = 0;
		deployTokens();
		addUniswapLiquidity();
		startRound();
		emit TournamentStarted(id, tournamentUsdc);
	}

	// @dev start next round
	// set round active, start random interval, unpause tokens if round > 0
	function startRound() internal {
		require(isTournamentActive, "startRound: Tournament is not active.");
		require(!isRoundActive, "startRound: A round is currently active.");

		isRoundActive = true;
		start();
		if (round > 0) {
			setTokenPauseStatus(false);
		}
		emit RoundStarted(id, round);
	}

	// @dev Pause or unpause
	function setTokenPauseStatus(bool status) internal {
		for (uint8 i = 0; i < 8; i++) {
			ITournamentToken(tournaments[id].tokens[i]).setPauseStatus(status);
		}
		isTradingPaused = status;
		emit TradingPauseStatusSet(status);
	}

	// @def Triggered by Tournament Coordinator
	// End round and stop VRF.
	function stop() internal override {
		super.stop();
		endRound();
	}

	// @dev End current round and start next round
	// Update matches, increment round, set round inactive, pause trading
	function endRound() internal {
		require(isTournamentActive, "endRound: Tournament is not active.");
		require(isRoundActive, "endRound: Round is not active.");

		updateMatches();
		emit RoundEnded(id, round, tournaments[id].bracket);
		round++;
		isRoundActive = false;
		if (round == 3) {
			endTournament();
		}
		else {
			setTokenPauseStatus(true);
			startRound();
		}
	}

	/// @dev seed liquidity, create pools, mint tokens
	function endTournament() internal {
		require(isTournamentActive, "endTournament: Tournament is not active");
		require(round == 3, "endTournament: Tournament cannot be ended");
		resolveTournament();
		id++;
		isTournamentActive = false;
	}

	// @dev logic to resolve matches based on round
	function updateMatches() internal {
		if (round == 0) {
			tournaments[id].bracket[8]  = resolveMatch(0, 1);
			tournaments[id].bracket[9]  = resolveMatch(2, 3);
			tournaments[id].bracket[10] = resolveMatch(4, 5);
			tournaments[id].bracket[11] = resolveMatch(6, 7);
		}
		else if (round == 1) {
			tournaments[id].bracket[12] = resolveMatch(
				tournaments[id].bracket[8],
				tournaments[id].bracket[9]
			);
			tournaments[id].bracket[13] = resolveMatch(
				tournaments[id].bracket[10],
				tournaments[id].bracket[11]
			);
		}
		else if (round == 2) {
			tournaments[id].bracket[14] = resolveMatch(
				tournaments[id].bracket[12], 
				tournaments[id].bracket[13]
			);
		}
	}

	// @dev Resolve a single match between two tokenIds
	// 1. Calculate winning/losing tokens based on highest uniswap price
	// 2. Calculate fees (change in k)
	// 3. Remove fee liquidity and swap tokens for USDC
	// 4. Remove losing token liquidity
	// 5. Swap USDC from losing pair for winning tokens
	// 6. Burn remaining tokens and return winning ID
	function resolveMatch(uint8 tokenA, uint8 tokenB) internal returns (uint8 winningId) {
		// cache variables to save gas costs
		ITournamentToken winningToken;
		ITournamentToken losingToken;
		IUniswapV2PairCustomFee winningPair;
		IUniswapV2PairCustomFee losingPair;
		uint256 winningLpFee;
		uint256 losingLpFee;

		// scope to avoid stack too deep
		// calculate winning pair
		{
			IUniswapV2PairCustomFee tokenAPair;
			IUniswapV2PairCustomFee tokenBPair;
			uint256 tokenAPrice;
			uint256 tokenBPrice;

			(tokenAPrice, tokenAPair) = getSpotPriceAndPair(tournaments[id].tokens[tokenA]);
			(tokenBPrice, tokenBPair) = getSpotPriceAndPair(tournaments[id].tokens[tokenB]);

			if (tokenAPrice >= tokenBPrice) {
				winningToken = ITournamentToken(tournaments[id].tokens[tokenA]);
				losingToken = ITournamentToken(tournaments[id].tokens[tokenB]);
				winningId = tokenA;
				winningPair = tokenAPair;
				losingPair = tokenBPair;
			} else {
				winningToken = ITournamentToken(tournaments[id].tokens[tokenB]);
				losingToken = ITournamentToken(tournaments[id].tokens[tokenA]);
				winningId = tokenB;
				winningPair = tokenBPair;
				losingPair = tokenAPair;
			}
		}

		// calculate LP fee as % growth in k
		{
			uint256 losingFee = calculateFee(losingPair);
			losingLpFee = (losingFee * losingPair.balanceOf(address(this))) / 1e18;
			uint256 winningFee = calculateFee(winningPair);
			winningLpFee = (winningFee * winningPair.balanceOf(address(this))) / 1e18;
		}

		// cache usdc balance before fees
		uint256 usdcBalanceBefore = usdc.balanceOf(address(this));

		// remove fee liquidity and swap for USDC
		address[] memory path = new address[](2);
		path[1] = address(usdc);

		// remove & sell losing liquidity tokens
		if (losingLpFee > 0) {
			router.removeLiquidity(
				address(losingToken), address(usdc), losingLpFee, 0, 0, address(this), block.timestamp
			);
			path[0] = address(losingToken);
			router.swapExactTokensForTokens(
				losingToken.balanceOf(address(this)), 0, path, address(this), block.timestamp
			);
		}

		// remove & sell winning liquidity tokens
		if (winningLpFee > 0) {
			router.removeLiquidity(
				address(winningToken), address(usdc), winningLpFee, 0, 0, address(this), block.timestamp
			);
			path[0] = address(winningToken);
			router.swapExactTokensForTokens(
				winningToken.balanceOf(address(this)), 0, path, address(this), block.timestamp
			);
		}

		// update k for winning pair
		kLast[address(winningPair)] = getKValue(winningPair);

		// save pending fees
		pendingFees += usdc.balanceOf(address(this)) - usdcBalanceBefore;
		usdcBalanceBefore = usdc.balanceOf(address(this));

		// remove remaining losing liquidity
		router.removeLiquidity(
			address(losingToken),
			address(usdc),
			losingPair.balanceOf(address(this)), // liquidity
			0, 					// amountAMin
			0, 					// amountBMin
			address(this), 		// to, 
			block.timestamp 	// deadline
		);

		// swap USDC for winning token
    	path[0] = address(usdc);
    	path[1] = address(winningToken);

		router.swapExactTokensForTokens(
			usdc.balanceOf(address(this)) - usdcBalanceBefore, 	// amountIn
			0, 													// amountOutMin
			path,  												// path
			address(this), 										// to
			block.timestamp										// deadline
		);

		// burn remaining tokens and emit event
		losingToken.burn(losingToken.balanceOf(address(this)));
		winningToken.burn(winningToken.balanceOf(address(this)));
		emit MatchResolved(id, tokenA, tokenB, winningId, usdc.balanceOf(address(winningPair)));
		
		return winningId;
	}

	// Get percentage growth in k with 18 decimals of precision
	// growth_percentage = 1 - sqrt(k1) / sqrt(k2)
	function calculateFee(IUniswapV2PairCustomFee pair) internal view returns (uint256) {
		uint256 k1 = kLast[address(pair)];
		uint256 k2 = getKValue(pair);
		if (k2 == 0) { return 1e18; }
		return 1e18 - (Math.sqrt(k1) * 1e18) / Math.sqrt(k2);
	}

	// @dev Get k value from uniswap pair by multiplying rewards
	function getKValue(IUniswapV2PairCustomFee pair) internal view returns (uint256) {
		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
		return reserve0 * reserve1;
	}

	// @dev Remove liquidity for winning token and calculate reward
	function resolveTournament() internal {
		ITournamentToken winningToken = ITournamentToken(getWinningToken(id));
		IERC20 pair = IERC20(factory.getPair(address(winningToken), address(usdc)));

		router.removeLiquidity(
			address(winningToken),			// tokenA
			address(usdc),					// tokenB
			pair.balanceOf(address(this)), 	// liquidity 
			0, 								// amountAMin
			0, 								// amountBMin
			address(this), 					// to,
			block.timestamp 				// deadline
		);

		// burn tokens owned by this contract
		winningToken.burn(winningToken.balanceOf(address(this)));

		// calculate reward based on remaining usdc and total supply
		uint256 supply = winningToken.totalSupply();
		uint256 balance = usdc.balanceOf(address(this)) - pendingRewards - pendingFees;

		uint256 reward =
		(
			(balance * 1e12 * PRECISION) / supply
		) / 1e12;
		tournaments[id].reward = reward;
		pendingRewards += balance;
		emit TournamentResolved(id, address(winningToken), reward);
	}

	// @dev Redeem `amount` tokens
	// Only winning token for valid tournament can be redeemed
	function redeem(uint256 tournamentId, uint256 amount) external {
		ITournamentToken winningToken = ITournamentToken(getWinningToken(tournamentId));
		winningToken.safeTransferFrom(msg.sender, address(this), amount);
		winningToken.burn(amount);
		uint256 usdcReward = (getReward(tournamentId) * amount) / PRECISION;
		usdc.safeTransfer(msg.sender, usdcReward);
		emit Redeem(tournamentId, amount, msg.sender);
	}

    // @dev Deploy tokens behind minimal proxy and set whitelist status
	function deployTokens() internal {
		address token;
		for (uint8 i = 0; i < 8; i++) {
			token = Clones.clone(tokenImplementation);
			ITournamentToken(token).initialize(STARTING_BALANCE, NAMES[i], SYMBOLS[i]);
			tournaments[id].tokens[i] = token;
			ITournamentToken(token).setWhitelistStatus(address(this), address(factory), true);
			ITournamentToken(token).setWhitelistStatus(address(factory), address(this), true);
		}
	}

	// @dev Add uniswap liquidity for game tokens
	function addUniswapLiquidity() internal {
		uint256 tournamentUsdc = usdc.balanceOf(address(this)) 
			- pendingRewards - pendingFees;

		require(tournamentUsdc >= 8000000, "require USDC liquidity above 8000000");
		// each pool gets 1/8 balance
		uint256 reward = usdc.balanceOf(address(this)) / 8;

		// loop through tokens and add liquidity
		IERC20 token;
		for (uint8 i = 0; i < 8; i++) {
			// cache token and create pair
			token = IERC20(tournaments[id].tokens[i]);
			token.approve(address(router), type(uint).max);

			// (uint amountA, uint amountB, uint liquidity) = 
			router.addLiquidity(
				address(usdc),						// tokenA
				address(token),						// tokenB
				reward, 							// amountADesired
				token.balanceOf(address(this)),		// amountBDesired
				1, 									// uint amountAMin
				1,									// uint amountBMin
				address(this), 						// address to
				block.timestamp 					// uint deadline
			);
			address pairAddress = factory.getPair(address(token), address(usdc));
			IERC20(pairAddress).approve(address(router), type(uint).max);
			kLast[pairAddress] = getKValue(IUniswapV2PairCustomFee(pairAddress));
		}
	}

	/// @dev View function to get tournament token price in USDC for amount
    function getAmountsOut(address token, uint256 amount) public view returns (uint256) {
    	address[] memory path = new address[](2);
    	path[0] = token;
    	path[1] = address(usdc);
    	return router.getAmountsOutWithFee(amount, path)[1];
    }

    // @dev View function to get spot price and pair of token in USDC using reserves
    function getSpotPriceAndPair(address token) public view returns (uint256 spotPrice, IUniswapV2PairCustomFee) {
    	IUniswapV2PairCustomFee pair = IUniswapV2PairCustomFee(factory.getPair(token, usdcAddress));
    	(uint256 reserves0, uint256 reserves1, ) = pair.getReserves();
    	if (pair.token0() == usdcAddress) {
    		spotPrice = (reserves0 * PRECISION) / reserves1;
    	}
    	else {
    		spotPrice = (reserves1 * PRECISION) / reserves0;
    	}
    	return (spotPrice, pair);
    }

    // @dev View function to get spot price of token in USDC using reserves
    function getSpotPrice(address token) public view returns (uint256 spotPrice) {
    	IUniswapV2PairCustomFee pair = IUniswapV2PairCustomFee(factory.getPair(token, usdcAddress));
    	(uint256 reserves0, uint256 reserves1, ) = pair.getReserves();
    	if (pair.token0() == usdcAddress) {
    		return (reserves0 * PRECISION) / reserves1;
    	}
    	else {
    		return (reserves1 * PRECISION) / reserves0;
    	}
    }

    // @dev View function to get token by ID
    function getTokenById(uint256 tournamentId, uint8 tokenId) public view returns (address) {
    	require(tokenId < 8, "getTokenById: id out of bounds");
    	return tournaments[tournamentId].tokens[tokenId];
    }

    // @dev Get winning token for a tournament ID
    // 14th slot in bracket is winner
    function getWinningToken(uint256 tournamentId) public view returns (address) {
    	require(tournamentId <= id, "no tournament with this id");
    	require(tournaments[tournamentId].bracket[14] != 255, "getWinningToken: no winner for this tournament");
    	return tournaments[tournamentId].tokens[tournaments[tournamentId].bracket[14]];
    }

    function getBracket(uint256 tournamentId) public view returns (uint8[16] memory) {
    	return tournaments[tournamentId].bracket;
    }

    function getTokens(uint256 tournamentId) public view returns (address[8] memory) {
    	return tournaments[tournamentId].tokens;
    }

    function getReward(uint256 tournamentId) public view returns (uint256) {
    	return tournaments[tournamentId].reward;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Token for Tournaments. Includes initial mint function and burn function
// Token is pausable
contract TournamentToken is ERC20 {
    mapping(address => mapping(address => bool)) public transferWhitelist;
    address public owner;
    string internal _name;
    string internal _symbol;

    bool initialized;
    bool public isPaused;

    constructor() ERC20("Tournament", "TT") {}

    function initialize(
        uint256 initialBalance,
        string memory name_,
        string memory symbol_
    ) external {
        require(!initialized, "already initialized");
        initialized = true;
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _mint(owner, initialBalance);
    }

    event PauseStatusChanged(bool status);
    event WhiteListStatusChanged(address indexed from, address indexed to, bool status);

    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner: sender is not owner");
        _;
    }

    // @dev Set pause status. Only owner
    function setPauseStatus(bool status) external onlyOwner {
        isPaused = status;
        emit PauseStatusChanged(status);
    }

    // @dev Set whitelist status between two accounts
    function setWhitelistStatus(address from, address to, bool status) external onlyOwner {
        transferWhitelist[from][to] = status;
        emit WhiteListStatusChanged(from, to, status);
    }

    // @dev If paused, revert transaction for non-whitelisted transfers
    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal override view {
        if (!isPaused) {
            return;
        }
        else { 
            require(transferWhitelist[from][to], "_beforeTokenTransfer: transfers paused"); 
        }
    }

    /**
     * @dev Burn tokens from sender
     */
    function burn(uint256 amount) external virtual {
        _burn(msg.sender, amount);
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
}

/* solhint-disable */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IUniswapV2FactoryCustomFee {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    // CUSTOM FEE: CUSTOM FEE FUNCTIONS
    function fee() external view returns (uint256);
    function owner() external view returns (uint256);
    function pendingOwner() external view returns (uint256);
    function setWhitelistStatus(address tokenA, address tokenB, address account, bool status) external;
}
/* solhint-enable */

/* solhint-disable */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// @dev UniswapV2Pair with Custom Fees
interface IUniswapV2PairCustomFee {
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

    // CUSTOM FEE: Add fee initialization
    function initializeFee(uint256 _fee) external;
    function fee() external pure returns (uint256);
    function setWhitelistStatus(address account, bool status) external;
}

/* solhint-disable */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

// CUSTOM FEE:
// Interface to add get amounts in/out with custom fee amount
interface IUniswapV2Router02CustomFee is IUniswapV2Router02 {
	function getAmountOutWithFee(uint amountIn, uint reserveIn, uint reserveOut, uint fee)
        external
        view
        returns (uint amountOut);

    function getAmountInWithFee(uint amountOut, uint reserveIn, uint reserveOut, uint fee)
        external
        view
        returns (uint amountIn);

    function getAmountsOutWithFee(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsInWithFee(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}
/* solhint-disable */