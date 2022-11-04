/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@relicprotocol/contracts/lib/Facts.sol";
import "@relicprotocol/contracts/lib/FactSigs.sol";
import "@relicprotocol/contracts/lib/Storage.sol";
import "@relicprotocol/contracts/interfaces/IReliquary.sol";

contract Token is ERC20 {
    mapping(address => bool) public claimed;

    IReliquary immutable reliquary;
    address immutable USDT;
    uint immutable blockNum;

    constructor(
        address _reliquary,
        address _USDT,
        uint _blockNum
    ) ERC20("AirDropExampleUSDT", "ADUSDT") {
        reliquary = IReliquary(_reliquary);
        USDT = _USDT;
        blockNum = _blockNum;
    }

    /// @inheritdoc ERC20
    function decimals() public view virtual override returns (uint8) {
        // match the same value used in USDT
        return 6;
    }

    function slotForUSDTBalance(address who) public pure returns (bytes32) {
        return
            Storage.mapElemSlot(
                bytes32(uint(2)),
                bytes32(uint256(uint160(who)))
            );
    }

    function mint(address who) external {
        require(claimed[who] == false, "already claimed");

        (bool exists, , bytes memory data) = reliquary.verifyFactNoFee(
            USDT,
            FactSigs.storageSlotFactSig(slotForUSDTBalance(who), blockNum)
        );
        require(exists, "storage proof missing");
        claimed[who] = true;

        uint priorUSDTBalance = Storage.parseUint256(data);
        _mint(who, priorUSDTBalance);
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

type FactSignature is bytes32;

/**
 * @title Facts
 * @author Theori, Inc.
 * @notice Helper functions for fact classes (part of fact signature that determines fee).
 */
library Facts {
    uint8 internal constant NO_FEE = 0;

    /**
     * @notice construct a fact signature from a fact class and some unique data
     * @param cls the fact class (determines the fee)
     * @param data the unique data for the signature
     */
    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    /**
     * @notice extracts the fact class from a fact signature
     * @param factSig the input fact signature
     */
    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title Storage
 * @author Theori, Inc.
 * @notice Helper functions for handling storage slot facts and computing storage slots
 */
library Storage {
    /**
     * @notice compute the slot for an element of a mapping
     * @param base the slot of the struct base
     * @param key the mapping key, padded to 32 bytes
     */
    function mapElemSlot(bytes32 base, bytes32 key) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(key, base));
    }

    /**
     * @notice compute the slot for an element of a static array
     * @param base the slot of the struct base
     * @param idx the index of the element
     * @param slotsPerElem the number of slots per element
     */
    function staticArrayElemSlot(
        bytes32 base,
        uint256 idx,
        uint256 slotsPerElem
    ) internal pure returns (bytes32) {
        return bytes32(uint256(base) + idx * slotsPerElem);
    }

    /**
     * @notice compute the slot for an element of a dynamic array
     * @param base the slot of the struct base
     * @param idx the index of the element
     * @param slotsPerElem the number of slots per element
     */
    function dynamicArrayElemSlot(
        bytes32 base,
        uint256 idx,
        uint256 slotsPerElem
    ) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(base))) + idx * slotsPerElem);
    }

    /**
     * @notice compute the slot for a struct field given the base slot and offset
     * @param base the slot of the struct base
     * @param offset the slot offset in the struct
     */
    function structFieldSlot(
        bytes32 base,
        uint256 offset
    ) internal pure returns (bytes32) {
        return bytes32(uint256(base) + offset);
    }

    function _parseUint256(bytes memory data) internal pure returns (uint256) {
        return uint256(bytes32(data)) >> (256 - 8 * data.length);
    }

    /**
     * @notice parse a uint256 from storage slot bytes
     * @param data the storage slot bytes
     * @return address the parsed address
     */
    function parseUint256(bytes memory data) internal pure returns (uint256) {
        require(data.length <= 32, 'data is not a uint256');
        return _parseUint256(data);
    }

    /**
     * @notice parse a uint64 from storage slot bytes
     * @param data the storage slot bytes
     */
    function parseUint64(bytes memory data) internal pure returns (uint64) {
        require(data.length <= 8, 'data is not a uint64');
        return uint64(_parseUint256(data));
    }

    /**
     * @notice parse an address from storage slot bytes
     * @param data the storage slot bytes
     */
    function parseAddress(bytes memory data) internal pure returns (address) {
        require(data.length <= 20, 'data is not an address');
        return address(uint160(_parseUint256(data)));
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Facts.sol";

/**
 * @title FactSigs
 * @author Theori, Inc.
 * @notice Helper functions for computing fact signatures
 */
library FactSigs {
    /**
     * @notice Produce the fact signature for a birth certificate fact
     * @return A FactSignature with no verification fee
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, abi.encode("BirthCertificate"));
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     * @return A FactSignature with no verification fee
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, abi.encode("StorageSlot", slot, blockNum));
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     * @return A FactSignature with no verification fee for the event
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return
            Facts.toFactSignature(Facts.NO_FEE, abi.encode("EventAttendance", "EventID", eventId));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../lib/Facts.sol";

/**
 * @title Holder of Relics and Artifacts
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary.
 */
interface IReliquary {
    /**
     * @notice Issued when a new prover is accepted into the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that will always be associated with the prover
     */
    event NewProver(address prover, uint64 version);

    /**
     * @notice Issued when a new prover is placed under consideration for acceptance
     *         into the Reliquary
     * @param prover the address of the prover contract
     * @param version the proposed identifier to always be associated with the prover
     * @param timestamp the earliest this prover can be brought into the Reliquary
     */
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);

    /**
     * @notice Issued when an existing prover is banished from the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that can never be used again
     * @dev revoked provers may not issue new Relics or Artifacts. The meaning of
     *      any previously introduced Relics or Artifacts is implementation dependent.
     */
    event ProverRevoked(address prover, uint64 version);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    /**
     * @notice activates a pending prover once the delay has passed. Callable by anyone.
     * @param prover the address of the pending prover
     */
    function activateProver(address prover) external;

    /**
     * @notice Add credits to an account. Requires the CREDITS_ROLE.
     * @param user The account to which more credits should be granted
     * @param amount The number of credits to be added
     */
    function addCredits(address user, uint192 amount) external;

    /**
     * @notice Add/propose a new prover to prove facts. Requires the ADD_PROVER_ROLE.
     * @param prover the address of the prover in question
     * @param version the unique version string to associate with this prover
     * @dev Provers and proposed provers must have unique version IDs
     * @dev After the Reliquary is initialized, a review period of 64k blocks
     *      must conclude before a prover may be added. The request must then
     *      be re-submitted to take effect. Before initialization is complete,
     *      the review period is skipped.
     * @dev Emits PendingProverAdded when a prover is proposed for inclusion
     */
    function addProver(address prover, uint64 version) external;

    /**
     * @notice Add/update a subscription. Requires the SUBSCRIPTION_ROLE.
     * @param user The subscriber account to modify
     * @param ts The new block timestamp at which the subscription expires
     */
    function addSubscriber(address user, uint64 ts) external;

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    /**
     * @notice Asserts that a particular block had a particular hash. Callable only from provers.
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    /**
     * @notice Require that an appropriate fee is paid for proving a fact
     * @param sender The account wanting to prove a fact
     * @dev The fee is derived from the prover which calls this  function
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be called by a prover
     */
    function checkProveFactFee(address sender) external payable;

    /**
     * @notice Helper function to query the status of a prover
     * @param prover the ProverInfo associated with the prover in question
     * @dev reverts if the prover is invalid or revoked
     */
    function checkProver(ProverInfo memory prover) external pure;

    /**
     * @notice Check how many credits a given account possesses
     * @param user The account in question
     * @return The number of credits
     */
    function credits(address user) external view returns (uint192);

    /**
     * @notice Verify if a particular block had a particular hash. Only callable by address(0),
               for debug
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Query for associated information for a fact. Only callable by address(0), for debug
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8) external view returns (FeeInfo memory);

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    /**
     * @notice Query for associated information for a fact. Only callable from provers.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Determine the appropriate ETH fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getProveFactNativeFee(address prover) external view returns (uint256);

    /**
     * @notice Determine the appropriate token fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getProveFactTokenFee(address prover) external view returns (uint256);

    /**
     * @notice Determine the appropriate ETH fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    /**
     * @notice Determine the appropriate token fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function initialized() external view returns (bool);

    /**
     * @notice Check if an account has an active subscription
     * @param user The account in question
     * @return True if the account is active, otherwise false
     */
    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address)
        external
        view
        returns (
            uint64 version,
            FeeInfo memory feeInfo,
            bool revoked
        );

    /**
     * @notice Remove credits from an account. Requires the CREDITS_ROLE.
     * @param user The account from which credits should be removed
     * @param amount The number of credits to be removed
     */
    function removeCredits(address user, uint192 amount) external;

    /**
     * @notice Remove a subscription. Requires the SUBSCRIPTION_ROLE.
     * @param user The subscriber account to modify
     */
    function removeSubscriber(address user) external;

    /**
     * @notice Deletes the fact from the Reliquary. Only callable from provers.
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being deleted
     * @dev May only be called by non-revoked provers
     */
    function resetFact(address account, FactSignature factSig) external;

    /**
     * @notice Stop accepting proofs from this prover. Requires the GOVERNANCE_ROLE.
     * @param prover The prover to banish from the reliquary
     * @dev Emits ProverRevoked
     * @dev Note: existing facts proved by the prover may still stand
     */
    function revokeProver(address prover) external;

    function setCredits(address user, uint192 amount) external;

    /**
     * @notice Adds the given information to the Reliquary. Only callable from provers.
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being proven
     * @param data Associated data to store with this item
     * @dev May only be called by non-revoked provers
     */
    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    /**
     * @notice Sets the FeeInfo for a particular fee class. Requires the GOVERNANCE_ROLE.
     * @param cls The fee class
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    /**
     * @notice Initialize the Reliquary, enforcing the time lock for new provers. Requires the
               ADD_PROVER_ROLE.
     */
    function setInitialized() external;

    /**
     * @notice Sets the FeeInfo for a particular prover. Requires the GOVERNANCE_ROLE.
     * @param prover The prover in question
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    /**
     * @notice Sets the FeeInfo for block verification. Requires the GOVERNANCE_ROLE.
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    /**
     * @notice Verify if a particular block had a particular hash. Only callable from provers.
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice FeeInfo struct for block hash queries
     */
    function verifyBlockFeeInfo() external view returns (FeeInfo memory);

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev A fee may be required based on the factSig
     */
    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Query for associated information for a fact which requires no query fee.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Query for the prover version for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev A fee may be required based on the factSig
     */
    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    /**
     * @notice Query for the prover version for a fact which requires no query fee.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    /**
     * @notice Reverse mapping of version information to the unique prover able
     *         to issue statements with that version
     */
    function versions(uint64) external view returns (address);

    /**
     * @notice Extract accumulated fees. Requires the GOVERNANCE_ROLE.
     * @param token The ERC20 token from which to extract fees. Or the 0 address for
     *        native ETH
     * @param dest The address to which fees should be transferred
     */
    function withdrawFees(address token, address dest) external;
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