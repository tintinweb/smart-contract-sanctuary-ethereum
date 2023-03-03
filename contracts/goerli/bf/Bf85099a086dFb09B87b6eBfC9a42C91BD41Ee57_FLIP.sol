pragma solidity ^0.8.0;

import "ERC20.sol";
import "IFLIP.sol";
import "IKeyManager.sol";
import "AggKeyNonceConsumer.sol";

/**
 * @title    FLIP contract
 * @notice   The FLIP utility token which is used to stake in the FLIP system and pay for
 *           trap fees with
 */
contract FLIP is ERC20, AggKeyNonceConsumer, IFLIP {
    /// @dev    The last block number in which the State Chain updated the totalSupply
    uint256 private _lastSupplyUpdateBlockNum = 0;

    constructor(
        uint256 flipTotalSupply,
        uint256 numGenesisValidators,
        uint256 genesisStake,
        address receiverGenesisValidatorFlip, // Stake Manager
        address receiverGenesisFlip,
        IKeyManager keyManager
    )
        ERC20("Token", "XYZ")
        nzAddr(receiverGenesisValidatorFlip)
        nzAddr(receiverGenesisFlip)
        nzUint(flipTotalSupply)
        AggKeyNonceConsumer(keyManager)
    {
        uint256 genesisValidatorFlip = numGenesisValidators * genesisStake;
        _mint(receiverGenesisValidatorFlip, genesisValidatorFlip);
        _mint(receiverGenesisFlip, flipTotalSupply - genesisValidatorFlip);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Compares a given new FLIP supply against the old supply,
     *          then mints or burns as appropriate. The message must be 
     '          signed by the aggregate key.
     * @param sigData               signature over the abi-encoded function params
     * @param newTotalSupply        new total supply of FLIP
     * @param stateChainBlockNumber State Chain block number for the new total supply
     * @param staker Staking contract owner of the tokens to be minted/burnt
     */
    function updateFlipSupply(
        SigData calldata sigData,
        uint256 newTotalSupply,
        uint256 stateChainBlockNumber,
        address staker
    )
        external
        override
        nzUint(newTotalSupply)
        nzAddr(staker)
        consumesKeyNonce(
            sigData,
            keccak256(
                abi.encodeWithSelector(
                    this.updateFlipSupply.selector,
                    SigData(sigData.keyManAddr, sigData.chainID, 0, 0, sigData.nonce, address(0)),
                    newTotalSupply,
                    stateChainBlockNumber,
                    staker
                )
            )
        )
    {
        require(stateChainBlockNumber > _lastSupplyUpdateBlockNum, "FLIP: old FLIP supply update");
        _lastSupplyUpdateBlockNum = stateChainBlockNumber;
        uint256 oldSupply = totalSupply();
        if (newTotalSupply < oldSupply) {
            uint256 amount = oldSupply - newTotalSupply;
            _burn(staker, amount);
        } else if (newTotalSupply > oldSupply) {
            uint256 amount = newTotalSupply - oldSupply;
            _mint(staker, amount);
        }
        emit FlipSupplyUpdated(oldSupply, newTotalSupply, stateChainBlockNumber);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Non-state-changing functions            //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the last state chain block number of the last supply update
     * @return  The state chain block number of the last supply update
     */
    function getLastSupplyUpdateBlockNumber() external view override returns (uint256) {
        return _lastSupplyUpdateBlockNum;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Context.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IShared.sol";
import "IAggKeyNonceConsumer.sol";

/**
 * @title    FLIP interface for the FLIP utility token
 */
interface IFLIP is IERC20, IAggKeyNonceConsumer {
    event FlipSupplyUpdated(uint256 oldSupply, uint256 newSupply, uint256 stateChainBlockNumber);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Compares a given new FLIP supply against the old supply,
     *          then mints and burns as appropriate
     * @param sigData               signature over the abi-encoded function params
     * @param newTotalSupply        new total supply of FLIP
     * @param stateChainBlockNumber State Chain block number for the new total supply
     * @param staker Staking contract owner of the tokens to be minted/burnt
     */
    function updateFlipSupply(
        SigData calldata sigData,
        uint256 newTotalSupply,
        uint256 stateChainBlockNumber,
        address staker
    ) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Non-state-changing functions            //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the last state chain block number that the supply was updated at
     * @return  The state chain block number of the last update
     */
    function getLastSupplyUpdateBlockNumber() external view returns (uint256);
}

pragma solidity ^0.8.0;
import "IERC20.sol";

/**
 * @title    Shared interface
 * @notice   Holds structs needed by other interfaces
 */
interface IShared {
    /**
     * @dev  SchnorrSECP256K1 requires that each key has a public key part (x coordinate),
     *       a parity for the y coordinate (0 if the y ordinate of the public key is even, 1
     *       if it's odd)
     */
    struct Key {
        uint256 pubKeyX;
        uint8 pubKeyYParity;
    }

    /**
     * @dev  Contains a signature and the msgHash that the signature is over. Kept as a single
     *       struct since they should always be used together
     */
    struct SigData {
        address keyManAddr;
        uint256 chainID;
        uint256 msgHash;
        uint256 sig;
        uint256 nonce;
        address kTimesGAddress;
    }

    /**
     * @param token The address of the token to be transferred
     * @param recipient The address of the recipient of the transfer
     * @param amount    The amount to transfer, in wei (uint)
     */
    struct TransferParams {
        address token;
        address payable recipient;
        uint256 amount;
    }

    /**
     * @param swapID    The unique identifier for this swap (bytes32), used for create2
     * @param token     The token to be transferred
     */
    struct DeployFetchParams {
        bytes32 swapID;
        address token;
    }

    /**
     * @param fetchContract   The address of the deployed Deposit contract
     * @param token     The token to be transferred
     */
    struct FetchParams {
        address payable fetchContract;
        address token;
    }
}

pragma solidity ^0.8.0;

import "IShared.sol";
import "IKeyManager.sol";

/**
 * @title    AggKeyNonceConsumer interface
 */

interface IAggKeyNonceConsumer is IShared {
    event UpdatedKeyManager(address keyManager);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////
    /**
     * @notice  Update KeyManager reference. Used if KeyManager contract is updated
     * @param sigData   The keccak256 hash over the msg (uint) (here that's normally
     *                  a hash over the calldata to the function with an empty sigData) and
     *                  sig over that hash (uint) from the aggregate key
     * @param keyManager New KeyManager's address
     */
    function updateKeyManager(SigData calldata sigData, IKeyManager keyManager) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the KeyManager address/interface that's used to validate sigs
     * @return  The KeyManager (IKeyManager)
     */
    function getKeyManager() external view returns (IKeyManager);
}

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    KeyManager interface
 * @notice   The interface for functions KeyManager implements
 */
interface IKeyManager is IShared {
    event AggKeySetByAggKey(Key oldAggKey, Key newAggKey);
    event AggKeySetByGovKey(Key oldAggKey, Key newAggKey);
    event GovKeySetByAggKey(address oldGovKey, address newGovKey);
    event GovKeySetByGovKey(address oldGovKey, address newGovKey);
    event CommKeySetByAggKey(address oldCommKey, address newCommKey);
    event CommKeySetByCommKey(address oldCommKey, address newCommKey);
    event SignatureAccepted(SigData sigData, address signer);
    event AggKeyNonceConsumersSet(address[] addrs);
    event AggKeyNonceConsumersUpdated(address[] currentAddrs, address[] newAddrs);
    event GovernanceAction(bytes32 message);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function setCanConsumeKeyNonce(address[] calldata addrs) external;

    function updateCanConsumeKeyNonce(
        SigData calldata sigData,
        address[] calldata currentAddrs,
        address[] calldata newAddrs
    ) external;

    function consumeKeyNonce(SigData memory sigData, bytes32 contractMsgHash) external;

    function setAggKeyWithAggKey(SigData memory sigData, Key memory newAggKey) external;

    function setAggKeyWithGovKey(Key memory newAggKey) external;

    function setGovKeyWithAggKey(SigData calldata sigData, address newGovKey) external;

    function setGovKeyWithGovKey(address newGovKey) external;

    function setCommKeyWithAggKey(SigData calldata sigData, address newCommKey) external;

    function setCommKeyWithCommKey(address newCommKey) external;

    function govWithdrawNative() external;

    function govAction(bytes32 message) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Non-state-changing functions            //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getAggregateKey() external view returns (Key memory);

    function getGovernanceKey() external view returns (address);

    function getCommunityKey() external view returns (address);

    function isNonceUsedByAggKey(uint256 nonce) external view returns (bool);

    function getLastValidateTime() external view returns (uint256);

    function canConsumeKeyNonce(address addr) external view returns (bool);

    function canConsumeKeyNonceSet() external view returns (bool);

    function getNumberWhitelistedAddresses() external view returns (uint256);
}

pragma solidity ^0.8.0;

import "IKeyManager.sol";
import "IAggKeyNonceConsumer.sol";
import "Shared.sol";

/**
 * @title    AggKeyNonceConsumer contract
 * @notice   Manages the reference to the KeyManager contract. The address
 *           is set in the constructor and can only be updated with a valid
 *           signature validated by the current KeyManager contract. This shall
 *           be done if the KeyManager contract is updated.
 */
contract AggKeyNonceConsumer is Shared, IAggKeyNonceConsumer {
    /// @dev    The KeyManager used to checks sigs used in functions here
    IKeyManager private _keyManager;

    constructor(IKeyManager keyManager) nzAddr(address(keyManager)) {
        _keyManager = keyManager;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Update KeyManager reference. Used if KeyManager contract is updated
     * @param sigData   The keccak256 hash over the msg (uint) (here that's normally
     *                  a hash over the calldata to the function with an empty sigData) and
     *                  sig over that hash (uint) from the aggregate key
     * @param keyManager New KeyManager's address
     */
    function updateKeyManager(
        SigData calldata sigData,
        IKeyManager keyManager
    )
        external
        override
        nzAddr(address(keyManager))
        consumesKeyNonce(
            sigData,
            keccak256(
                abi.encodeWithSelector(
                    this.updateKeyManager.selector,
                    SigData(sigData.keyManAddr, sigData.chainID, 0, 0, sigData.nonce, address(0)),
                    keyManager
                )
            )
        )
    {
        _keyManager = keyManager;
        emit UpdatedKeyManager(address(keyManager));
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the KeyManager address/interface that's used to validate sigs
     * @return  The KeyManager (IKeyManager)
     */
    function getKeyManager() public view override returns (IKeyManager) {
        return _keyManager;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Modifiers                        //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /// @dev    Calls consumeKeyNonce in _keyManager
    modifier consumesKeyNonce(SigData calldata sigData, bytes32 contractMsgHash) {
        getKeyManager().consumeKeyNonce(sigData, contractMsgHash);
        _;
    }
}

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    Shared contract
 * @notice   Holds constants and modifiers that are used in multiple contracts
 * @dev      It would be nice if this could be a library, but modifiers can't be exported :(
 */

abstract contract Shared is IShared {
    /// @dev The address used to indicate whether transfer should send native or a token
    address internal constant _NATIVE_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _ZERO_ADDR = address(0);
    bytes32 internal constant _NULL = "";
    uint256 internal constant _E_18 = 1e18;

    /// @dev    Checks that a uint isn't zero/empty
    modifier nzUint(uint256 u) {
        require(u != 0, "Shared: uint input is empty");
        _;
    }

    /// @dev    Checks that an address isn't zero/empty
    modifier nzAddr(address a) {
        require(a != _ZERO_ADDR, "Shared: address input is empty");
        _;
    }

    /// @dev    Checks that a bytes32 isn't zero/empty
    modifier nzBytes32(bytes32 b) {
        require(b != _NULL, "Shared: bytes32 input is empty");
        _;
    }

    /// @dev    Checks that the pubKeyX is populated
    modifier nzKey(Key memory key) {
        require(key.pubKeyX != 0, "Shared: pubKeyX is empty");
        _;
    }
}