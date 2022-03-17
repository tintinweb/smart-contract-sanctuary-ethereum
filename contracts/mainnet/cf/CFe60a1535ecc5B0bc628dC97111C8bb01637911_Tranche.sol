// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interfaces/IYearnVault.sol";
import "../libraries/Authorizable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITranche.sol";

contract ZapYearnShares is Authorizable {
    // Store the accessibility state of the contract
    bool public isFrozen = false;
    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;

    /// @param __trancheFactory Address of the TrancheFactory contract
    /// @param __trancheBytecodeHash Hash of the Tranche bytecode.
    constructor(address __trancheFactory, bytes32 __trancheBytecodeHash)
        Authorizable()
    {
        _authorize(msg.sender);
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
    }

    /// @dev Requires that the contract is not frozen
    modifier notFrozen() {
        require(!isFrozen, "Contract frozen");
        _;
    }

    /// @dev Allows an authorized address to freeze or unfreeze this contract
    /// @param _newState True for frozen and false for unfrozen
    function setIsFrozen(bool _newState) external onlyAuthorized {
        isFrozen = _newState;
    }

    /// @notice Mints a Principal/Interest token pair from yearn vault shares.
    ///      then returns the tokens to the caller.
    /// @param _underlying The underlying ERC20 token contract of the yearn vault.
    /// @param _vault The address of the target yearn vault.
    /// @param _amount The amount of yearn shares to turn into tokens
    /// @param _expiration The expiration time of the Tranche contract.
    /// @param _position The contract which manages pooled deposits.
    /// @param _ptExpected The minimum amount of principal tokens to mint.
    /// @return returns the minted amounts of principal and yield tokens (PT and YT)
    function zapSharesIn(
        IERC20 _underlying,
        IYearnVault _vault,
        uint256 _amount,
        uint256 _expiration,
        address _position,
        uint256 _ptExpected
    ) external notFrozen returns (uint256, uint256) {
        _vault.transferFrom(msg.sender, address(this), _amount);
        _vault.withdraw(_amount, _position, 0);

        ITranche tranche = _deriveTranche(address(_position), _expiration);
        uint256 balance = _underlying.balanceOf(_position);

        (uint256 ptMinted, uint256 ytMinted) = tranche.prefundedDeposit(
            msg.sender
        );
        require(ytMinted >= balance, "Not enough YT minted");
        require(ptMinted >= _ptExpected, "Not enough PT minted");
        return (ptMinted, ytMinted);
    }

    /// @dev This internal function produces the deterministic create2
    ///      address of the Tranche contract from a wrapped position contract and expiration
    /// @param _position The wrapped position contract address
    /// @param _expiration The expiration time of the tranche
    /// @return The derived Tranche contract
    function _deriveTranche(address _position, uint256 _expiration)
        internal
        view
        virtual
        returns (ITranche)
    {
        bytes32 salt = keccak256(abi.encodePacked(_position, _expiration));
        bytes32 addressBytes = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                _trancheFactory,
                salt,
                _trancheBytecodeHash
            )
        );
        return ITranche(address(uint160(uint256(addressBytes))));
    }

    /// @dev This contract can hold yearn vault share allowances for addresses so if it is deprecated
    ///      it should be removed so that users do not have to remove allowances.
    ///      Note - onlyOwner is a stronger check than onlyAuthorized, many addresses can be
    ///      authorized to freeze or unfreeze the contract but only the owner address can kill
    function deprecate() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IYearnVault is IERC20 {
    function deposit(uint256, address) external returns (uint256);

    function withdraw(
        uint256,
        address,
        uint256
    ) external returns (uint256);

    // Returns the amount of underlying per each unit [1e18] of yearn shares
    function pricePerShare() external view returns (uint256);

    function governance() external view returns (address);

    function setDepositLimit(uint256) external;

    function totalSupply() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function apiVersion() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "./IInterestToken.sol";

interface ITranche is IERC20Permit {
    function deposit(uint256 _shares, address destination)
        external
        returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (uint256, uint256);

    function withdrawPrincipal(uint256 _amount, address _destination)
        external
        returns (uint256);

    function withdrawInterest(uint256 _amount, address _destination)
        external
        returns (uint256);

    function interestToken() external view returns (IInterestToken);

    function interestSupply() external view returns (uint128);

    function underlying() external view returns (IERC20);

    function unlockTimestamp() external view returns (uint256);
}

// Forked from openzepplin
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";

interface IInterestToken is IERC20Permit {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interfaces/IYearnVault.sol";
import "../libraries/Authorizable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITranche.sol";

contract ZapTrancheHop is Authorizable {
    // Store the accessibility state of the contract
    bool public isFrozen = false;
    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;

    /// @param __trancheFactory Address of the TrancheFactory contract
    /// @param __trancheBytecodeHash Hash of the Tranche bytecode.
    constructor(address __trancheFactory, bytes32 __trancheBytecodeHash)
        Authorizable()
    {
        _authorize(msg.sender);
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
    }

    /// @dev Requires that the contract is not frozen
    modifier notFrozen() {
        require(!isFrozen, "Contract frozen");
        _;
    }

    /// @dev Allows an authorized address to freeze or unfreeze this contract
    /// @param _newState True for frozen and false for unfrozen
    function setIsFrozen(bool _newState) external onlyAuthorized {
        isFrozen = _newState;
    }

    /// @notice Redeems Principal and Yield tokens and deposits the underlying assets received into
    /// a new tranche. The target tranche must use the same underlying asset.
    /// @param _underlying The underlying ERC20 token contract of the yearn vault.
    /// @param _positionFrom The wrapped position of the originating tranche.
    /// @param _expirationFrom The expiration timestamp of the originating tranche.
    /// @param _positionTo The wrapped position of the target tranche.
    /// @param _expirationTo The expiration timestamp of the target tranche.
    /// @param _amountPt Amount of principal tokens to redeem and deposit into the new tranche.
    /// @param _amountYt Amount of yield tokens to redeem and deposit into the new tranche.
    /// @param _ptExpected The minimum amount of principal tokens to mint.
    /// @param _ytExpected The minimum amount of yield tokens to mint.
    /// @return returns the minted amounts of principal and yield tokens (PT and YT)
    function hopToTranche(
        IERC20 _underlying,
        address _positionFrom,
        uint256 _expirationFrom,
        address _positionTo,
        uint256 _expirationTo,
        uint256 _amountPt,
        uint256 _amountYt,
        uint256 _ptExpected,
        uint256 _ytExpected
    ) public notFrozen returns (uint256, uint256) {
        ITranche trancheFrom = _deriveTranche(
            address(_positionFrom),
            _expirationFrom
        );
        ITranche trancheTo = _deriveTranche(
            address(_positionTo),
            _expirationTo
        );

        uint256 balance;
        if (_amountPt > 0) {
            trancheFrom.transferFrom(msg.sender, address(this), _amountPt);
            balance += trancheFrom.withdrawPrincipal(_amountPt, _positionTo);
        }

        if (_amountYt > 0) {
            IERC20 yt = IERC20(trancheFrom.interestToken());
            yt.transferFrom(msg.sender, address(this), _amountYt);
            balance += trancheFrom.withdrawInterest(_amountYt, _positionTo);
        }

        (uint256 ptMinted, uint256 ytMinted) = trancheTo.prefundedDeposit(
            msg.sender
        );

        require(
            ytMinted >= balance && ytMinted >= _ytExpected,
            "Not enough YT minted"
        );
        require(ptMinted >= _ptExpected, "Not enough PT minted");
        return (ptMinted, ytMinted);
    }

    /// @notice There should never be any tokens in this contract.
    /// This function can rescue any possible ERC20 tokens.
    /// @dev This function does not rescue ETH. There is no fallback function so getting
    /// ETH stuck here would be a very deliberate act.
    /// @param token The token to rescue.
    /// @param amount The amount to rescue.
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20 want = IERC20(token);
        want.transfer(msg.sender, amount);
    }

    /// @dev This internal function produces the deterministic create2
    ///      address of the Tranche contract from a wrapped position contract and expiration
    /// @param _position The wrapped position contract address
    /// @param _expiration The expiration time of the tranche
    /// @return The derived Tranche contract
    function _deriveTranche(address _position, uint256 _expiration)
        internal
        view
        virtual
        returns (ITranche)
    {
        bytes32 salt = keccak256(abi.encodePacked(_position, _expiration));
        bytes32 addressBytes = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                _trancheFactory,
                salt,
                _trancheBytecodeHash
            )
        );
        return ITranche(address(uint160(uint256(addressBytes))));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IYearnVault.sol";
import "./WrappedPosition.sol";
import "./libraries/Authorizable.sol";

/// SECURITY - This contract has an owner address which can migrate funds to a new yearn vault [or other contract
///            with compatible interface] as well as pause deposits and withdraws. This means that any deposited funds
///            have the same security as that address.

/// @author Element Finance
/// @title Yearn Vault v1 Asset Proxy
contract YVaultAssetProxy is WrappedPosition, Authorizable {
    // The addresses of the current yearn vault
    IYearnVault public vault;
    // 18 decimal fractional form of the multiplier which is applied after
    // a vault upgrade. 0 when no upgrade has happened
    uint88 public conversionRate;
    // Bool packed into the same storage slot as vault and conversion rate
    bool public paused;
    uint8 public immutable vaultDecimals;

    /// @notice Constructs this contract and stores needed data
    /// @param vault_ The yearn v2 vault
    /// @param _token The underlying token.
    ///               This token should revert in the event of a transfer failure.
    /// @param _name The name of the token created
    /// @param _symbol The symbol of the token created
    /// @param _governance The address which can upgrade the yearn vault
    /// @param _pauser address which can pause this contract
    constructor(
        address vault_,
        IERC20 _token,
        string memory _name,
        string memory _symbol,
        address _governance,
        address _pauser
    ) WrappedPosition(_token, _name, _symbol) Authorizable() {
        // Authorize the pauser
        _authorize(_pauser);
        // set the owner
        setOwner(_governance);
        // Set the vault
        vault = IYearnVault(vault_);
        // Approve the vault so it can pull tokens from this address
        _token.approve(vault_, type(uint256).max);
        // Load the decimals and set them as an immutable
        uint8 localVaultDecimals = IERC20(vault_).decimals();
        vaultDecimals = localVaultDecimals;
        require(
            uint8(_token.decimals()) == localVaultDecimals,
            "Inconsistent decimals"
        );
    }

    /// @notice Checks that the contract has not been paused
    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    /// @notice Makes the actual deposit into the yearn vault
    /// @return Tuple (the shares minted, amount underlying used)
    function _deposit() internal override notPaused returns (uint256, uint256) {
        // Get the amount deposited
        uint256 amount = token.balanceOf(address(this));

        // Deposit and get the shares that were minted to this
        uint256 shares = vault.deposit(amount, address(this));

        // If we have migrated our shares are no longer 1 - 1 with the vault shares
        if (conversionRate != 0) {
            // conversionRate is the fraction of yearnSharePrice1/yearnSharePrices2 at time of migration
            // and so this multiplication will convert between yearn shares in the new vault and
            // those in the old vault
            shares = (shares * conversionRate) / 1e18;
        }

        // Return the amount of shares the user has produced, and the amount used for it.
        return (shares, amount);
    }

    /// @notice Withdraw the number of shares
    /// @param _shares The number of wrapped position shares to withdraw
    /// @param _destination The address to send the output funds
    // @param _underlyingPerShare The possibly precomputed underlying per share
    /// @return returns the amount of funds freed by doing a yearn withdraw
    function _withdraw(
        uint256 _shares,
        address _destination,
        uint256
    ) internal override notPaused returns (uint256) {
        // If the conversion rate is non-zero we have upgraded and so our wrapped shares are
        // not one to one with the original shares.
        if (conversionRate != 0) {
            // Then since conversion rate is yearnSharePrice1/yearnSharePrices2 we divide the
            // wrapped position shares by it because they are equivalent to the first yearn vault shares
            _shares = (_shares * 1e18) / conversionRate;
        }
        // Withdraws shares from the vault. Max loss is set at 100% as
        // the minimum output value is enforced by the calling
        // function in the WrappedPosition contract.
        uint256 amountReceived = vault.withdraw(_shares, _destination, 10000);

        // Return the amount of underlying
        return amountReceived;
    }

    /// @notice Get the underlying amount of tokens per shares given
    /// @param _amount The amount of shares you want to know the value of
    /// @return Value of shares in underlying token
    function _underlying(uint256 _amount)
        internal
        view
        override
        returns (uint256)
    {
        // We may have to convert before using the vault price per share
        if (conversionRate != 0) {
            // Imitate the _withdraw logic and convert this amount to yearn vault2 shares
            _amount = (_amount * 1e18) / conversionRate;
        }
        return (_amount * _pricePerShare()) / (10**vaultDecimals);
    }

    /// @notice Get the price per share in the vault
    /// @return The price per share in units of underlying;
    function _pricePerShare() internal view returns (uint256) {
        return vault.pricePerShare();
    }

    /// @notice Function to reset approvals for the proxy
    function approve() external {
        token.approve(address(vault), 0);
        token.approve(address(vault), type(uint256).max);
    }

    /// @notice Allows an authorized address or the owner to pause this contract
    /// @param pauseStatus true for paused, false for not paused
    /// @dev the caller must be authorized
    function pause(bool pauseStatus) external onlyAuthorized {
        paused = pauseStatus;
    }

    /// @notice Function to transition between two yearn vaults
    /// @param newVault The address of the new vault
    /// @param minOutputShares The min of the new yearn vault's shares the wp will receive
    /// @dev WARNING - This function has the capacity to steal all user funds from this
    ///                contract and so it should be ensured that the owner is a high quorum
    ///                governance vote through the time lock.
    function transition(IYearnVault newVault, uint256 minOutputShares)
        external
        onlyOwner
    {
        // Load the current vault's price per share
        uint256 currentPricePerShare = _pricePerShare();
        // Load the new vault's price per share
        uint256 newPricePerShare = newVault.pricePerShare();
        // Load the current conversion rate or set it to 1
        uint256 newConversionRate = conversionRate == 0 ? 1e18 : conversionRate;
        // Calculate the new conversion rate, note by multiplying by the old
        // conversion rate here we implicitly support more than 1 upgrade
        newConversionRate =
            (newConversionRate * newPricePerShare) /
            currentPricePerShare;
        // We now withdraw from the old yearn vault using max shares
        // Note - Vaults should be checked in the future that they still have this behavior
        vault.withdraw(type(uint256).max, address(this), 10000);
        // Approve the new vault
        token.approve(address(newVault), type(uint256).max);
        // Then we deposit into the new vault
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 outputShares = newVault.deposit(currentBalance, address(this));
        // We enforce a min output
        require(outputShares >= minOutputShares, "Not enough output");
        // Change the stored variables
        vault = newVault;
        // because of the truncation yearn vaults can't have a larger diff than ~ billion
        // times larger
        conversionRate = uint88(newConversionRate);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWrappedPosition.sol";

import "./libraries/ERC20Permit.sol";

/// @author Element Finance
/// @title Wrapped Position Core
abstract contract WrappedPosition is ERC20Permit, IWrappedPosition {
    IERC20 public immutable override token;

    /// @notice Constructs this contract
    /// @param _token The underlying token.
    ///               This token should revert in the event of a transfer failure.
    /// @param _name the name of this contract
    /// @param _symbol the symbol for this contract
    constructor(
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) ERC20Permit(_name, _symbol) {
        token = _token;
        // We set our decimals to be the same as the underlying
        _setupDecimals(_token.decimals());
    }

    /// We expect that the following logic will be present in an integration implementation
    /// which inherits from this contract

    /// @dev Makes the actual deposit into the 'vault'
    /// @return Tuple (shares minted, amount underlying used)
    function _deposit() internal virtual returns (uint256, uint256);

    /// @dev Makes the actual withdraw from the 'vault'
    /// @return returns the amount produced
    function _withdraw(
        uint256,
        address,
        uint256
    ) internal virtual returns (uint256);

    /// @dev Converts between an internal balance representation
    ///      and underlying tokens.
    /// @return The amount of underlying the input is worth
    function _underlying(uint256) internal view virtual returns (uint256);

    /// @notice Get the underlying balance of an address
    /// @param _who The address to query
    /// @return The underlying token balance of the address
    function balanceOfUnderlying(address _who)
        external
        view
        override
        returns (uint256)
    {
        return _underlying(balanceOf[_who]);
    }

    /// @notice Returns the amount of the underlying asset a certain amount of shares is worth
    /// @param _shares Shares to calculate underlying value for
    /// @return The value of underlying assets for the given shares
    function getSharesToUnderlying(uint256 _shares)
        external
        view
        override
        returns (uint256)
    {
        return _underlying(_shares);
    }

    /// @notice Entry point to deposit tokens into the Wrapped Position contract
    ///         Transfers tokens on behalf of caller so the caller must set
    ///         allowance on the contract prior to call.
    /// @param _amount The amount of underlying tokens to deposit
    /// @param _destination The address to mint to
    /// @return Returns the number of Wrapped Position tokens minted
    function deposit(address _destination, uint256 _amount)
        external
        override
        returns (uint256)
    {
        // Send tokens to the proxy
        token.transferFrom(msg.sender, address(this), _amount);
        // Calls our internal deposit function
        (uint256 shares, ) = _deposit();
        // Mint them internal ERC20 tokens corresponding to the deposit
        _mint(_destination, shares);
        return shares;
    }

    /// @notice Entry point to deposit tokens into the Wrapped Position contract
    ///         Assumes the tokens were transferred before this was called
    /// @param _destination the destination of this deposit
    /// @return Returns (WP tokens minted, used underlying,
    ///                  senders WP balance before mint)
    /// @dev WARNING - The call which funds this method MUST be in the same transaction
    //                 as the call to this method or you risk loss of funds
    function prefundedDeposit(address _destination)
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Calls our internal deposit function
        (uint256 shares, uint256 usedUnderlying) = _deposit();

        uint256 balanceBefore = balanceOf[_destination];

        // Mint them internal ERC20 tokens corresponding to the deposit
        _mint(_destination, shares);
        return (shares, usedUnderlying, balanceBefore);
    }

    /// @notice Exit point to withdraw tokens from the Wrapped Position contract
    /// @param _destination The address which is credited with tokens
    /// @param _shares The amount of shares the user is burning to withdraw underlying
    /// @param _minUnderlying The min output the caller expects
    /// @return The amount of underlying transferred to the destination
    function withdraw(
        address _destination,
        uint256 _shares,
        uint256 _minUnderlying
    ) public override returns (uint256) {
        return _positionWithdraw(_destination, _shares, _minUnderlying, 0);
    }

    /// @notice This function burns enough tokens from the sender to send _amount
    ///          of underlying to the _destination.
    /// @param _destination The address to send the output to
    /// @param _amount The amount of underlying to try to redeem for
    /// @param _minUnderlying The minium underlying to receive
    /// @return The amount of underlying released, and shares used
    function withdrawUnderlying(
        address _destination,
        uint256 _amount,
        uint256 _minUnderlying
    ) external override returns (uint256, uint256) {
        // First we load the number of underlying per unit of Wrapped Position token
        uint256 oneUnit = 10**decimals;
        uint256 underlyingPerShare = _underlying(oneUnit);
        // Then we calculate the number of shares we need
        uint256 shares = (_amount * oneUnit) / underlyingPerShare;
        // Using this we call the normal withdraw function
        uint256 underlyingReceived = _positionWithdraw(
            _destination,
            shares,
            _minUnderlying,
            underlyingPerShare
        );
        return (underlyingReceived, shares);
    }

    /// @notice This internal function allows the caller to provide a precomputed 'underlyingPerShare'
    ///         so that we can avoid calling it again in the internal function
    /// @param _destination The destination to send the output to
    /// @param _shares The number of shares to withdraw
    /// @param _minUnderlying The min amount of output to produce
    /// @param _underlyingPerShare The precomputed shares per underlying
    /// @return The amount of underlying released
    function _positionWithdraw(
        address _destination,
        uint256 _shares,
        uint256 _minUnderlying,
        uint256 _underlyingPerShare
    ) internal returns (uint256) {
        // Burn users shares
        _burn(msg.sender, _shares);

        // Withdraw that many shares from the vault
        uint256 withdrawAmount = _withdraw(
            _shares,
            _destination,
            _underlyingPerShare
        );

        // We revert if this call doesn't produce enough underlying
        // This security feature is useful in some edge cases
        require(withdrawAmount >= _minUnderlying, "Not enough underlying");
        return withdrawAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "./IERC20.sol";

interface IWrappedPosition is IERC20Permit {
    function token() external view returns (IERC20);

    function balanceOfUnderlying(address who) external view returns (uint256);

    function getSharesToUnderlying(uint256 shares)
        external
        view
        returns (uint256);

    function deposit(address sender, uint256 amount) external returns (uint256);

    function withdraw(
        address sender,
        uint256 _shares,
        uint256 _minUnderlying
    ) external returns (uint256);

    function withdrawUnderlying(
        address _destination,
        uint256 _amount,
        uint256 _minUnderlying
    ) external returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IERC20Permit.sol";

// This default erc20 library is designed for max efficiency and security.
// WARNING: By default it does not include totalSupply which breaks the ERC20 standard
//          to use a fully standard compliant ERC20 use 'ERC20PermitWithSupply"
abstract contract ERC20Permit is IERC20Permit {
    // --- ERC20 Data ---
    // The name of the erc20 token
    string public name;
    // The symbol of the erc20 token
    string public override symbol;
    // The decimals of the erc20 token, should default to 18 for new tokens
    uint8 public override decimals;

    // A mapping which tracks user token balances
    mapping(address => uint256) public override balanceOf;
    // A mapping which tracks which addresses a user allows to move their tokens
    mapping(address => mapping(address => uint256)) public override allowance;
    // A mapping which tracks the permit signature nonces for users
    mapping(address => uint256) public override nonces;

    // --- EIP712 niceties ---
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public override DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Initializes the erc20 contract
    /// @param name_ the value 'name' will be set to
    /// @param symbol_ the value 'symbol' will be set to
    /// @dev decimals default to 18 and must be reset by an inheriting contract for
    ///      non standard decimal values
    constructor(string memory name_, string memory symbol_) {
        // Set the state variables
        name = name_;
        symbol = symbol_;
        decimals = 18;

        // By setting these addresses to 0 attempting to execute a transfer to
        // either of them will revert. This is a gas efficient way to prevent
        // a common user mistake where they transfer to the token address.
        // These values are not considered 'real' tokens and so are not included
        // in 'total supply' which only contains minted tokens.
        balanceOf[address(0)] = type(uint256).max;
        balanceOf[address(this)] = type(uint256).max;

        // Optional extra state manipulation
        _extraConstruction();

        // Computes the EIP 712 domain separator which prevents user signed messages for
        // this contract to be replayed in other contracts.
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice An optional override function to execute and change state before immutable assignment
    function _extraConstruction() internal virtual {}

    // --- Token ---
    /// @notice Allows a token owner to send tokens to another address
    /// @param recipient The address which will be credited with the tokens
    /// @param amount The amount user token to send
    /// @return returns true on success, reverts on failure so cannot return false.
    /// @dev transfers to this contract address or 0 will fail
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // We forward this call to 'transferFrom'
        return transferFrom(msg.sender, recipient, amount);
    }

    /// @notice Transfers an amount of erc20 from a spender to a receipt
    /// @param spender The source of the ERC20 tokens
    /// @param recipient The destination of the ERC20 tokens
    /// @param amount the number of tokens to send
    /// @return returns true on success and reverts on failure
    /// @dev will fail transfers which send funds to this contract or 0
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // Load balance and allowance
        uint256 balance = balanceOf[spender];
        require(balance >= amount, "ERC20: insufficient-balance");
        // We potentially have to change allowances
        if (spender != msg.sender) {
            // Loading the allowance in the if block prevents vanilla transfers
            // from paying for the sload.
            uint256 allowed = allowance[spender][msg.sender];
            // If the allowance is max we do not reduce it
            // Note - This means that max allowances will be more gas efficient
            // by not requiring a sstore on 'transferFrom'
            if (allowed != type(uint256).max) {
                require(allowed >= amount, "ERC20: insufficient-allowance");
                allowance[spender][msg.sender] = allowed - amount;
            }
        }
        // Update the balances
        balanceOf[spender] = balance - amount;
        // Note - In the constructor we initialize the 'balanceOf' of address 0 and
        //        the token address to uint256.max and so in 8.0 transfers to those
        //        addresses revert on this step.
        balanceOf[recipient] = balanceOf[recipient] + amount;
        // Emit the needed event
        emit Transfer(spender, recipient, amount);
        // Return that this call succeeded
        return true;
    }

    /// @notice This internal minting function allows inheriting contracts
    ///         to mint tokens in the way they wish.
    /// @param account the address which will receive the token.
    /// @param amount the amount of token which they will receive
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _mint(address account, uint256 amount) internal virtual {
        // Add tokens to the account
        balanceOf[account] = balanceOf[account] + amount;
        // Emit an event to track the minting
        emit Transfer(address(0), account, amount);
    }

    /// @notice This internal burning function allows inheriting contracts to
    ///         burn tokens in the way they see fit.
    /// @param account the account to remove tokens from
    /// @param amount  the amount of tokens to remove
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _burn(address account, uint256 amount) internal virtual {
        // Reduce the balance of the account
        balanceOf[account] = balanceOf[account] - amount;
        // Emit an event tracking transfers
        emit Transfer(account, address(0), amount);
    }

    /// @notice This function allows a user to approve an account which can transfer
    ///         tokens on their behalf.
    /// @param account The account which will be approve to transfer tokens
    /// @param amount The approval amount, if set to uint256.max the allowance does not go down on transfers.
    /// @return returns true for compatibility with the ERC20 standard
    function approve(address account, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // Set the senders allowance for account to amount
        allowance[msg.sender][account] = amount;
        // Emit an event to track approvals
        emit Approval(msg.sender, account, amount);
        return true;
    }

    /// @notice This function allows a caller who is not the owner of an account to execute the functionality of 'approve' with the owners signature.
    /// @param owner the owner of the account which is having the new approval set
    /// @param spender the address which will be allowed to spend owner's tokens
    /// @param value the new allowance value
    /// @param deadline the timestamp which the signature must be submitted by to be valid
    /// @param v Extra ECDSA data which allows public key recovery from signature assumed to be 27 or 28
    /// @param r The r component of the ECDSA signature
    /// @param s The s component of the ECDSA signature
    /// @dev The signature for this function follows EIP 712 standard and should be generated with the
    ///      eth_signTypedData JSON RPC call instead of the eth_sign JSON RPC call. If using out of date
    ///      parity signing libraries the v component may need to be adjusted. Also it is very rare but possible
    ///      for v to be other values, those values are not supported.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // The EIP 712 digest for this function
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );
        // Require that the owner is not zero
        require(owner != address(0), "ERC20: invalid-address-0");
        // Require that we have a valid signature from the owner
        require(owner == ecrecover(digest, v, r, s), "ERC20: invalid-permit");
        // Require that the signature is not expired
        require(
            deadline == 0 || block.timestamp <= deadline,
            "ERC20: permit-expired"
        );
        // Format the signature to the default format
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ERC20: invalid signature 's' value"
        );
        // Increment the signature nonce to prevent replay
        nonces[owner]++;
        // Set the allowance to the new value
        allowance[owner][spender] = value;
        // Emit an approval event to be able to track this happening
        emit Approval(owner, spender, value);
    }

    /// @notice Internal function which allows inheriting contract to set custom decimals
    /// @param decimals_ the new decimal value
    function _setupDecimals(uint8 decimals_) internal {
        // Set the decimals
        decimals = decimals_;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../WrappedPosition.sol";
import "./TestERC20.sol";

contract TestWrappedPosition is WrappedPosition {
    uint256 public underlyingUnitValue = 100;

    constructor(IERC20 _token)
        WrappedPosition(_token, "ELement Finance", "TestWrappedPosition")
    {} // solhint-disable-line no-empty-blocks

    function _deposit() internal override returns (uint256, uint256) {
        // Check how much was deposited
        uint256 deposited = token.balanceOf(address(this));
        // Pretend to send it somewhere else
        TestERC20(address(token)).setBalance(address(this), 0);
        // Return how many shares it's worth and the deposit amount
        return (deposited / underlyingUnitValue, deposited);
    }

    // This withdraw just uses the set balance function in test erc20
    // to set the output location correctly
    function _withdraw(
        uint256 amount,
        address destination,
        uint256
    ) internal override returns (uint256) {
        // Send the requested amount converted to underlying
        TestERC20(address(token)).uncheckedTransfer(
            destination,
            amount * underlyingUnitValue
        );
        // Returns the amount of output transferred
        return (amount * underlyingUnitValue);
    }

    function setSharesToUnderlying(uint256 _value) external {
        underlyingUnitValue = _value;
    }

    function _underlying(uint256 _shares)
        internal
        view
        override
        returns (uint256)
    {
        return _shares * underlyingUnitValue;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/ERC20Permit.sol";

// An ERC20 with specified decimals, we may add unlimited mint and other test functions
contract TestERC20 is ERC20Permit {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20Permit(name_, symbol_) {
        _setupDecimals(decimals_);
    }

    function setBalance(address destination, uint256 amount) external {
        balanceOf[destination] = amount;
        emit Transfer(address(0), destination, amount);
    }

    function uncheckedTransfer(address destination, uint256 amount) external {
        balanceOf[destination] += amount;
        emit Transfer(address(0), destination, amount);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IYearnVault.sol";

import "../libraries/ERC20PermitWithSupply.sol";

import "../libraries/ERC20Permit.sol";
import "./TestERC20.sol";

contract TestYVault is ERC20PermitWithSupply {
    address public token;

    constructor(address _token, uint8 _decimals)
        ERC20Permit("test ytoken", "yToken")
    {
        token = _token;
        _setupDecimals(_decimals);
    }

    function deposit(uint256 _amount, address destination)
        external
        returns (uint256)
    {
        uint256 _shares;
        if (totalSupply == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount * (10**decimals)) / pricePerShare(); // calculate shares
        }
        IERC20(token).transferFrom(msg.sender, address(this), _amount); // pull deposit from sender
        _mint(destination, _shares); // mint shares for sender
        return _shares;
    }

    function apiVersion() external pure virtual returns (string memory) {
        return ("0.3.2");
    }

    function withdraw(
        uint256 _shares,
        address destination,
        uint256
    ) external returns (uint256) {
        // Yearn supports this
        if (_shares == type(uint256).max) {
            _shares = balanceOf[msg.sender];
        }
        uint256 _amount = (_shares * pricePerShare()) / (10**decimals);
        _burn(msg.sender, _shares);
        IERC20(token).transfer(destination, _amount);
        return _amount;
    }

    function pricePerShare() public view returns (uint256) {
        uint256 balance = ERC20Permit(token).balanceOf(address(this));
        if (balance == 0) return (10**decimals);
        return (balance * (10**decimals)) / totalSupply;
    }

    function updateShares() external {
        uint256 balance = ERC20Permit(token).balanceOf(address(this));
        TestERC20(token).mint(address(this), balance / 10);
    }

    function totalAssets() public view returns (uint256) {
        return ERC20Permit(token).balanceOf(address(this));
    }

    function governance() external pure returns (address) {
        revert("Unimplemented");
    }

    function setDepositLimit(uint256) external pure {
        revert("Unimplemented");
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./ERC20Permit.sol";

// This contract adds a total supply variable to the ERC20 lib to increase compatibility with standard
abstract contract ERC20PermitWithSupply is ERC20Permit {
    // The stored totalSupply, it equals all tokens minted - all tokens burned
    uint256 public totalSupply;

    /// @notice This function overrides the ERC20Permit Library's _mint and causes it
    ///          to track total supply.
    /// @param account the account to add tokens to
    /// @param amount the amount of tokens to add
    function _mint(address account, uint256 amount) internal override {
        // Increase account balance
        balanceOf[account] = balanceOf[account] + amount;
        // Increase total supply
        totalSupply += amount;
        // Emit a transfer from zero to emulate a mint
        emit Transfer(address(0), account, amount);
    }

    /// @notice This function overrides the ERC20Permit Library's _burn to decrement total supply
    /// @param account the account to burn from
    /// @param amount the amount of token to burn
    function _burn(address account, uint256 amount) internal override {
        // Decrease user balance
        balanceOf[account] = balanceOf[account] - amount;
        // Decrease total supply
        totalSupply -= amount;
        // Emit an event tracking the burn
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TestYVault.sol";

// NOTE - the test y vault uses the formula of 0.4.2 and versions prior to
//        0.3.2, so when we test the YAssetProxyV4 we actually want the same logic
//        except that we want to return a diff version.
//        The subtly of 0.3.2 - 0.3.5 yearn vaults is tested in the mainnet tests.

contract TestYVaultV4 is TestYVault {
    constructor(address _token, uint8 _decimals)
        TestYVault(_token, _decimals)
    {}

    function apiVersion() external pure override returns (string memory) {
        return ("0.4.2");
    }
}

pragma solidity ^0.8.0;
import "../interfaces/IYearnVault.sol";
import "../libraries/Authorizable.sol";
import "../libraries/ERC20Permit.sol";

contract MockERC20YearnVault is IYearnVault, Authorizable, ERC20Permit {
    // total amount of vault shares in existence
    uint256 public totalShares;

    // a large number used to offset potential division precision errors
    uint256 public precisionFactor;

    // underlying token
    ERC20Permit public token;

    // variables for the profit time-lock
    uint256 public constant DEGRADATION_COEFFICIENT = 1e18;
    uint256 public lockedProfitDegradation;

    // last time someone deposited value through report()
    uint256 public lastReport;
    // the amount of tokens locked after a report()
    uint256 public lockedProfit;

    /**
    @param _token The ERC20 token the vault accepts
     */
    constructor(address _token)
        Authorizable()
        ERC20Permit("Mock Yearn Vault", "MYV")
    {
        _authorize(msg.sender);
        token = ERC20Permit(_token);
        decimals = token.decimals();
        precisionFactor = 10**(18 - decimals);
        // 6 hours in blocks
        // 6*60*60 ~= 1e6 / 46
        lockedProfitDegradation = (DEGRADATION_COEFFICIENT * 46) / 1e6;
    }

    function apiVersion() external pure override returns (string memory) {
        return ("0.3.2");
    }

    /**
    @notice Add tokens to the vault. Increases totalAssets.
    @param _deposit The amount of tokens to deposit
    @dev There is no logic to rebalance lockedAmount.
    Repeat calls will just reset it.
    */
    function report(uint256 _deposit) external onlyAuthorized {
        lastReport = block.timestamp;
        // mock vault does not take performance or management fee
        // so the full deposit is locked profit.
        lockedProfit = _deposit;
        token.transferFrom(msg.sender, address(this), _deposit);
    }

    /**
    @notice Deposit `_amount` of tokens into the yearn vault. 
    `_recipient` receives shares.
    @param _amount The amount of underlying tokens to deposit.
    @param _recipient The recipient of the vault shares.
    @return The vault shares received.

     */
    function deposit(uint256 _amount, address _recipient)
        external
        override
        returns (uint256)
    {
        require(_amount > 0, "depositing 0 value");
        uint256 shares = _issueSharesForAmount(_recipient, _amount);
        token.transferFrom(msg.sender, address(this), _amount);
        return shares;
    }

    /**
    @notice Withdraw `_maxShares` of shares from caller `_recipient`
    receives underlying tokens.
    @param _maxShares The amount of shares to redeem for underlying.
    @param _recipient The recipient of the underlying tokens.
    @param _maxLoss The max permitted withdrawal loss. (1 = 0.01%, 10000 = 100%).
    @return The amount of underlying tokens that were redeemed from _maxShares shares.
     */
    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external override returns (uint256) {
        require(_maxShares > 0, "Can't withdraw zero");
        require(balanceOf[msg.sender] >= _maxShares, "Shares exceed balance");
        uint256 value = _shareValue(_maxShares);

        totalShares -= _maxShares;
        balanceOf[msg.sender] -= _maxShares;

        token.transfer(_recipient, value);
        return value;
    }

    /**
    @notice Returns the amount of underlying per each unit [10^decimals] of yearn shares
     */
    function pricePerShare() public view override returns (uint256) {
        return _shareValue(10**decimals);
    }

    /**
    @notice Get the governance address. It will be address(0)
    it is not used for this mock.
     */
    function governance() public view override returns (address) {
        return address(0);
    }

    /**
    @notice The deposit limit for this vault.
    @dev Can only be unlimited for this mock.
     */
    function setDepositLimit(uint256 _limit) public override {
        require(msg.sender == governance(), "!governance");
    }

    /**
    @notice Returns total assets held by the contract.
    @dev This is a mock and there is no debt. The total assets are just the
    underlying tokens held by the contract.
     */
    function totalAssets() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
    @param _to The address to receive the shares.
    @param _amount The amount of underlying tokens to convert to shares.
    @return The amount of shares _amount yields.
     */
    function _issueSharesForAmount(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 shares;
        if (totalShares > 0) {
            shares =
                (precisionFactor * _amount * totalShares) /
                totalAssets() /
                precisionFactor;
        } else {
            shares = _amount;
        }
        totalShares += shares;
        balanceOf[_to] += shares;
        return shares;
    }

    /**
    @notice Return the amount of underlying tokens an amount of `_shares`
    is worth at any given time. 
    @param _shares The amount of shares to check.
    @return The amount of underlying tokens the `_shares` can be redeemed for.
     */
    function _shareValue(uint256 _shares) internal view returns (uint256) {
        if (totalShares == 0) {
            return _shares;
        }
        // determine the current value of the shares
        uint256 lockedFundsRatio = (block.timestamp - lastReport) *
            lockedProfitDegradation;
        uint256 freeFunds = totalAssets();
        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            freeFunds -= (lockedProfit -
                ((precisionFactor * lockedFundsRatio * lockedProfit) /
                    DEGRADATION_COEFFICIENT /
                    precisionFactor));
        }
        return ((precisionFactor * _shares * freeFunds) /
            totalShares /
            precisionFactor);
    }

    /**
    @notice Get the total number of vault shares.
    @return Total vault shares.
     */
    function totalSupply() external view override returns (uint256) {
        return totalShares;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IWrappedPosition.sol";
import "./interfaces/ITranche.sol";
import "./interfaces/ITrancheFactory.sol";
import "./interfaces/IInterestToken.sol";

import "./libraries/ERC20Permit.sol";
import "./libraries/DateString.sol";

/// @author Element Finance
/// @title Tranche
contract Tranche is ERC20Permit, ITranche {
    IInterestToken public immutable override interestToken;
    IWrappedPosition public immutable position;
    IERC20 public immutable override underlying;
    uint8 internal immutable _underlyingDecimals;

    // The outstanding amount of underlying which
    // can be redeemed from the contract from Principal Tokens
    // NOTE - we use smaller sizes so that they can be one storage slot
    uint128 public valueSupplied;
    // The total supply of interest tokens
    uint128 public override interestSupply;
    // The timestamp when tokens can be redeemed.
    uint256 public immutable override unlockTimestamp;
    // The amount of slippage allowed on the Principal token redemption [0.1 basis points]
    uint256 internal constant _SLIPPAGE_BP = 1e13;
    // The speedbump variable records the first timestamp where redemption was attempted to be
    // performed on a tranche where loss occurred. It blocks redemptions for 48 hours after
    // it is triggered in order to (1) prevent atomic flash loan price manipulation (2)
    // give 48 hours to remediate any other loss scenario before allowing withdraws
    uint256 public speedbump;
    // Const which is 48 hours in seconds
    uint256 internal constant _FORTY_EIGHT_HOURS = 172800;
    // An event to listen for when negative interest withdraw are triggered
    event SpeedBumpHit(uint256 timestamp);

    /// @notice Constructs this contract
    constructor() ERC20Permit("Element Principal Token ", "eP") {
        // Assume the caller is the Tranche factory.
        ITrancheFactory trancheFactory = ITrancheFactory(msg.sender);
        (
            address wpAddress,
            uint256 expiration,
            IInterestToken interestTokenTemp,
            // solhint-disable-next-line
            address unused
        ) = trancheFactory.getData();
        interestToken = interestTokenTemp;

        IWrappedPosition wpContract = IWrappedPosition(wpAddress);
        position = wpContract;

        // Store the immutable time variables
        unlockTimestamp = expiration;
        // We use local because immutables are not readable in construction
        IERC20 localUnderlying = wpContract.token();
        underlying = localUnderlying;
        // We load and store the underlying decimals
        uint8 localUnderlyingDecimals = localUnderlying.decimals();
        _underlyingDecimals = localUnderlyingDecimals;
        // And set this contract to have the same
        _setupDecimals(localUnderlyingDecimals);
    }

    /// @notice We override the optional extra construction function from ERC20 to change names
    function _extraConstruction() internal override {
        // Assume the caller is the Tranche factory and that this is called from constructor
        // We have to do this double load because of the lack of flexibility in constructor ordering
        ITrancheFactory trancheFactory = ITrancheFactory(msg.sender);
        (
            address wpAddress,
            uint256 expiration,
            // solhint-disable-next-line
            IInterestToken unused,
            address dateLib
        ) = trancheFactory.getData();

        string memory strategySymbol = IWrappedPosition(wpAddress).symbol();

        // Write the strategySymbol and expiration time to name and symbol

        // This logic was previously encoded as calling a library "DateString"
        // in line and directly. However even though this code is only in the constructor
        // it both made the code of this contract much bigger and made the factory
        // un deployable. So we needed to use the library as an external contract
        // but solidity does not have support for address to library conversions
        // or other support for working directly with libraries in a type safe way.
        // For that reason we have to use this ugly and non type safe hack to make these
        // contracts deployable. Since the library is an immutable in the factory
        // the security profile is quite similar to a standard external linked library.

        // We load the real storage slots of the symbol and name storage variables
        uint256 namePtr;
        uint256 symbolPtr;
        assembly {
            namePtr := name.slot
            symbolPtr := symbol.slot
        }
        // We then call the 'encodeAndWriteTimestamp' function on our library contract
        (bool success1, ) = dateLib.delegatecall(
            abi.encodeWithSelector(
                DateString.encodeAndWriteTimestamp.selector,
                strategySymbol,
                expiration,
                namePtr
            )
        );
        (bool success2, ) = dateLib.delegatecall(
            abi.encodeWithSelector(
                DateString.encodeAndWriteTimestamp.selector,
                strategySymbol,
                expiration,
                symbolPtr
            )
        );
        // Assert that both calls succeeded
        assert(success1 && success2);
    }

    /// @notice An aliasing of the getter for valueSupplied to improve ERC20 compatibility
    /// @return The number of principal tokens which exist.
    function totalSupply() external view returns (uint256) {
        return uint256(valueSupplied);
    }

    /**
    @notice Deposit wrapped position tokens and receive interest and Principal ERC20 tokens.
            If interest has already been accrued by the wrapped position
            tokens held in this contract, the number of Principal tokens minted is
            reduced in order to pay for the accrued interest.
    @param _amount The amount of underlying to deposit
    @param _destination The address to mint to
    @return The amount of principal and yield token minted as (pt, yt)
     */
    function deposit(uint256 _amount, address _destination)
        external
        override
        returns (uint256, uint256)
    {
        // Transfer the underlying to be wrapped into the position
        underlying.transferFrom(msg.sender, address(position), _amount);
        // Now that we have funded the deposit we can call
        // the prefunded deposit
        return prefundedDeposit(_destination);
    }

    /// @notice This function calls the prefunded deposit method to
    ///         create wrapped position tokens held by the contract. It should
    ///         only be called when a transfer has already been made to
    ///         the wrapped position contract of the underlying
    /// @param _destination The address to mint to
    /// @return the amount of principal and yield token minted as (pt, yt)
    /// @dev WARNING - The call which funds this method MUST be in the same transaction
    //                 as the call to this method or you risk loss of funds
    function prefundedDeposit(address _destination)
        public
        override
        returns (uint256, uint256)
    {
        // We check that this it is possible to deposit
        require(block.timestamp < unlockTimestamp, "expired");
        // Since the wrapped position contract holds a balance we use the prefunded deposit method
        (
            uint256 shares,
            uint256 usedUnderlying,
            uint256 balanceBefore
        ) = position.prefundedDeposit(address(this));
        // The implied current value of the holding of this contract in underlying
        // is the balanceBefore*(usedUnderlying/shares) since (usedUnderlying/shares)
        // is underlying per share and balanceBefore is the balance of this contract
        // in position tokens before this deposit.
        uint256 holdingsValue = (balanceBefore * usedUnderlying) / shares;
        // This formula is inputUnderlying - inputUnderlying*interestPerUnderlying
        // Accumulated interest has its value in the interest tokens so we have to mint less
        // principal tokens to account for that.
        // NOTE - If a pool has more than 100% interest in the period this will revert on underflow
        //        The user cannot discount the principal token enough to pay for the outstanding interest accrued.
        (uint256 _valueSupplied, uint256 _interestSupply) = (
            uint256(valueSupplied),
            uint256(interestSupply)
        );
        // We block deposits in negative interest rate regimes
        // The +2 allows for very small rounding errors which occur when
        // depositing into a tranche which is attached to a wp which has
        // accrued interest but the tranche has not yet accrued interest
        // and the first deposit into the tranche is substantially smaller
        // than following ones.
        require(_valueSupplied <= holdingsValue + 2, "E:NEG_INT");

        uint256 adjustedAmount;
        // Have to split on the initialization case and negative interest case
        if (_valueSupplied > 0 && holdingsValue > _valueSupplied) {
            adjustedAmount =
                usedUnderlying -
                ((holdingsValue - _valueSupplied) * usedUnderlying) /
                _interestSupply;
        } else {
            adjustedAmount = usedUnderlying;
        }
        // We record the new input of reclaimable underlying
        (valueSupplied, interestSupply) = (
            uint128(_valueSupplied + adjustedAmount),
            uint128(_interestSupply + usedUnderlying)
        );
        // We mint interest token for each underlying provided
        interestToken.mint(_destination, usedUnderlying);
        // We mint principal token discounted by the accumulated interest.
        _mint(_destination, adjustedAmount);
        // We return the number of principal token and yield token
        return (adjustedAmount, usedUnderlying);
    }

    /**
    @notice Burn principal tokens to withdraw underlying tokens.
    @param _amount The number of tokens to burn.
    @param _destination The address to send the underlying too
    @return The number of underlying tokens released
    @dev This method will return 1 underlying for 1 principal except when interest
         is negative, in which case the principal tokens is redeemable pro rata for
         the assets controlled by this vault.
         Also note: Redemption has the possibility of at most _SLIPPAGE_BP
         numerical error on each redemption so each principal token may occasionally redeem
         for less than 1 unit of underlying. Max loss defaults to 0.1 BP ie 0.001% loss
     */
    function withdrawPrincipal(uint256 _amount, address _destination)
        external
        override
        returns (uint256)
    {
        // No redemptions before unlock
        require(block.timestamp >= unlockTimestamp, "E:Not Expired");
        // If the speedbump == 0 it's never been hit so we don't need
        // to change the withdraw rate.
        uint256 localSpeedbump = speedbump;
        uint256 withdrawAmount = _amount;
        uint256 localSupply = uint256(valueSupplied);
        if (localSpeedbump != 0) {
            // Load the assets we have in this vault
            uint256 holdings = position.balanceOfUnderlying(address(this));
            // If we check and the interest rate is no longer negative then we
            // allow normal 1 to 1 withdraws [even if the speedbump was hit less
            // than 48 hours ago, to prevent possible griefing]
            if (holdings < localSupply) {
                // We allow the user to only withdraw their percent of holdings
                // NOTE - Because of the discounting mechanics this causes account loss
                //        percentages to be slightly perturbed from overall loss.
                //        ie: tokens holders who join when interest has accumulated
                //        will get slightly higher percent loss than those who joined earlier
                //        in the case of loss at the end of the period. Biases are very
                //        small except in extreme cases.
                withdrawAmount = (_amount * holdings) / localSupply;
                // If the interest rate is still negative and we are not 48 hours after
                // speedbump being set we revert
                require(
                    localSpeedbump + _FORTY_EIGHT_HOURS < block.timestamp,
                    "E:Early"
                );
            }
        }
        // Burn from the sender
        _burn(msg.sender, _amount);
        // Remove these principal token from the interest calculations for future interest redemptions
        valueSupplied = uint128(localSupply) - uint128(_amount);
        // Load the share balance of the vault before withdrawing [gas note - both the smart
        // contract and share value is warmed so this is actually quite a cheap lookup]
        uint256 shareBalanceBefore = position.balanceOf(address(this));
        // Calculate the min output
        uint256 minOutput = withdrawAmount -
            (withdrawAmount * _SLIPPAGE_BP) /
            1e18;
        // We make the actual withdraw from the position.
        (uint256 actualWithdraw, uint256 sharesBurned) = position
            .withdrawUnderlying(_destination, withdrawAmount, minOutput);

        // At this point we check that the implied contract holdings before this withdraw occurred
        // are more than enough to redeem all of the principal tokens for underlying ie that no
        // loss has happened.
        uint256 balanceBefore = (shareBalanceBefore * actualWithdraw) /
            sharesBurned;
        if (balanceBefore < localSupply) {
            // Require that that the speedbump has been set.
            require(localSpeedbump != 0, "E:NEG_INT");
            // This assert should be very difficult to hit because it is checked above
            // but may be possible with  complex reentrancy.
            assert(localSpeedbump + _FORTY_EIGHT_HOURS < block.timestamp);
        }
        return (actualWithdraw);
    }

    /// @notice This function allows someone to trigger the speedbump and eventually allow
    ///         pro rata withdraws
    function hitSpeedbump() external {
        // We only allow setting the speedbump once
        require(speedbump == 0, "E:AlreadySet");
        // We only allow setting it when withdraws can happen
        require(block.timestamp >= unlockTimestamp, "E:Not Expired");
        // We require that the total holds are less than the supply of
        // principal token we need to redeem
        uint256 totalHoldings = position.balanceOfUnderlying(address(this));
        if (totalHoldings < valueSupplied) {
            // We emit a notification so that if a speedbump is hit the community
            // can investigate.
            // Note - this is a form of defense mechanism because any flash loan
            //        attack must be public for at least 48 hours before it has
            //        affects.
            emit SpeedBumpHit(block.timestamp);
            // Set the speedbump
            speedbump = block.timestamp;
        } else {
            revert("E:NoLoss");
        }
    }

    /**
    @notice Burn interest tokens to withdraw underlying tokens.
    @param _amount The number of interest tokens to burn.
    @param _destination The address to send the result to
    @return The number of underlying token released
    @dev Due to slippage the redemption may receive up to _SLIPPAGE_BP less
         in output compared to the floating rate.
     */
    function withdrawInterest(uint256 _amount, address _destination)
        external
        override
        returns (uint256)
    {
        require(block.timestamp >= unlockTimestamp, "E:Not Expired");
        // Burn tokens from the sender
        interestToken.burn(msg.sender, _amount);
        // Load the underlying value of this contract
        uint256 underlyingValueLocked = position.balanceOfUnderlying(
            address(this)
        );
        // Load a stack variable to avoid future sloads
        (uint256 _valueSupplied, uint256 _interestSupply) = (
            uint256(valueSupplied),
            uint256(interestSupply)
        );
        // Interest is value locked minus current value
        uint256 interest = underlyingValueLocked > _valueSupplied
            ? underlyingValueLocked - _valueSupplied
            : 0;
        // The redemption amount is the interest per token times the amount
        uint256 redemptionAmount = (interest * _amount) / _interestSupply;
        uint256 minRedemption = redemptionAmount -
            (redemptionAmount * _SLIPPAGE_BP) /
            1e18;
        // Store that we reduced the supply
        interestSupply = uint128(_interestSupply - _amount);
        // Redeem position tokens for underlying
        (uint256 redemption, ) = position.withdrawUnderlying(
            _destination,
            redemptionAmount,
            minRedemption
        );
        return (redemption);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../InterestToken.sol";
import "../libraries/DateString.sol";

interface ITrancheFactory {
    function getData()
        external
        returns (
            address,
            uint256,
            InterestToken,
            address
        );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library DateString {
    uint256 public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 public constant SECONDS_PER_HOUR = 60 * 60;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    int256 public constant OFFSET19700101 = 2440588;

    // This function was forked from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    // solhint-disable-next-line private-vars-leading-underscore
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);
        // solhint-disable-next-line var-name-mixedcase
        int256 L = __days + 68569 + OFFSET19700101;
        // solhint-disable-next-line var-name-mixedcase
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /// @dev Writes a prefix and an timestamp encoding to an output storage location
    ///      This function is designed to only work with ASCII encoded strings. No emojis please.
    /// @param _prefix The string to write before the timestamp
    /// @param _timestamp the timestamp to encode and store
    /// @param _output the storage location of the output string
    /// NOTE - Current cost ~90k if gas is problem revisit and use assembly to remove the extra
    ///        sstore s.
    function encodeAndWriteTimestamp(
        string memory _prefix,
        uint256 _timestamp,
        string storage _output
    ) external {
        _encodeAndWriteTimestamp(_prefix, _timestamp, _output);
    }

    /// @dev Sn internal version of the above function 'encodeAndWriteTimestamp'
    // solhint-disable-next-line
    function _encodeAndWriteTimestamp(
        string memory _prefix,
        uint256 _timestamp,
        string storage _output
    ) internal {
        // Cast the prefix string to a byte array
        bytes memory bytePrefix = bytes(_prefix);
        // Cast the output string to a byte array
        bytes storage bytesOutput = bytes(_output);
        // Copy the bytes from the prefix onto the byte array
        // NOTE - IF PREFIX CONTAINS NON-ASCII CHARS THIS WILL CAUSE AN INCORRECT STRING LENGTH
        for (uint256 i = 0; i < bytePrefix.length; i++) {
            bytesOutput.push(bytePrefix[i]);
        }
        // Add a '-' to the string to separate the prefix from the the date
        bytesOutput.push(bytes1("-"));
        // Add the date string
        timestampToDateString(_timestamp, _output);
    }

    /// @dev Converts a unix second encoded timestamp to a date format (year, month, day)
    ///      then writes the string encoding of that to the output pointer.
    /// @param _timestamp the unix seconds timestamp
    /// @param _outputPointer the storage pointer to change.
    function timestampToDateString(
        uint256 _timestamp,
        string storage _outputPointer
    ) public {
        _timestampToDateString(_timestamp, _outputPointer);
    }

    /// @dev Sn internal version of the above function 'timestampToDateString'
    // solhint-disable-next-line
    function _timestampToDateString(
        uint256 _timestamp,
        string storage _outputPointer
    ) internal {
        // We pretend the string is a 'bytes' only push UTF8 encodings to it
        bytes storage output = bytes(_outputPointer);
        // First we get the day month and year
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            _timestamp / SECONDS_PER_DAY
        );
        // First we add encoded day to the string
        {
            // Round out the second digit
            uint256 firstDigit = day / 10;
            // add it to the encoded byte for '0'
            output.push(bytes1(uint8(bytes1("0")) + uint8(firstDigit)));
            // Extract the second digit
            uint256 secondDigit = day % 10;
            // add it to the string
            output.push(bytes1(uint8(bytes1("0")) + uint8(secondDigit)));
        }
        // Next we encode the month string and add it
        if (month == 1) {
            stringPush(output, "J", "A", "N");
        } else if (month == 2) {
            stringPush(output, "F", "E", "B");
        } else if (month == 3) {
            stringPush(output, "M", "A", "R");
        } else if (month == 4) {
            stringPush(output, "A", "P", "R");
        } else if (month == 5) {
            stringPush(output, "M", "A", "Y");
        } else if (month == 6) {
            stringPush(output, "J", "U", "N");
        } else if (month == 7) {
            stringPush(output, "J", "U", "L");
        } else if (month == 8) {
            stringPush(output, "A", "U", "G");
        } else if (month == 9) {
            stringPush(output, "S", "E", "P");
        } else if (month == 10) {
            stringPush(output, "O", "C", "T");
        } else if (month == 11) {
            stringPush(output, "N", "O", "V");
        } else if (month == 12) {
            stringPush(output, "D", "E", "C");
        } else {
            revert("date decoding error");
        }
        // We take the last two digits of the year
        // Hopefully that's enough
        {
            uint256 lastDigits = year % 100;
            // Round out the second digit
            uint256 firstDigit = lastDigits / 10;
            // add it to the encoded byte for '0'
            output.push(bytes1(uint8(bytes1("0")) + uint8(firstDigit)));
            // Extract the second digit
            uint256 secondDigit = lastDigits % 10;
            // add it to the string
            output.push(bytes1(uint8(bytes1("0")) + uint8(secondDigit)));
        }
    }

    function stringPush(
        bytes storage output,
        bytes1 data1,
        bytes1 data2,
        bytes1 data3
    ) internal {
        output.push(data1);
        output.push(data2);
        output.push(data3);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./libraries/ERC20Permit.sol";
import "./libraries/DateString.sol";

import "./interfaces/IInterestToken.sol";
import "./interfaces/ITranche.sol";

contract InterestToken is ERC20Permit, IInterestToken {
    // The tranche address which controls the minting
    ITranche public immutable tranche;

    /// @dev Initializes the ERC20 and writes the correct names
    /// @param _tranche The tranche contract address
    /// @param _strategySymbol The symbol of the associated WrappedPosition contract
    /// @param _timestamp The unlock time on the tranche
    /// @param _decimals The decimal encoding for this token
    constructor(
        address _tranche,
        string memory _strategySymbol,
        uint256 _timestamp,
        uint8 _decimals
    )
        ERC20Permit(
            _processName("Element Yield Token ", _strategySymbol, _timestamp),
            _processSymbol("eY", _strategySymbol, _timestamp)
        )
    {
        tranche = ITranche(_tranche);
        _setupDecimals(_decimals);
    }

    /// @notice We use this function to add the date to the name string
    /// @param _name start of the name
    /// @param _strategySymbol the strategy symbol
    /// @param _timestamp the unix second timestamp to be encoded and added to the end of the string
    function _processName(
        string memory _name,
        string memory _strategySymbol,
        uint256 _timestamp
    ) internal returns (string memory) {
        // Set the name in the super
        name = _name;
        // Use the library to write the rest
        DateString._encodeAndWriteTimestamp(_strategySymbol, _timestamp, name);
        // load and return the name
        return name;
    }

    /// @notice We use this function to add the date to the name string
    /// @param _symbol start of the symbol
    /// @param _strategySymbol the strategy symbol
    /// @param _timestamp the unix second timestamp to be encoded and added to the end of the string
    function _processSymbol(
        string memory _symbol,
        string memory _strategySymbol,
        uint256 _timestamp
    ) internal returns (string memory) {
        // Set the symbol in the super
        symbol = _symbol;
        // Use the library to write the rest
        DateString._encodeAndWriteTimestamp(
            _strategySymbol,
            _timestamp,
            symbol
        );
        // load and return the name
        return symbol;
    }

    /// @dev Aliasing of the lookup method for the supply of yield tokens which
    ///      improves our ERC20 compatibility.
    /// @return The total supply of yield tokens
    function totalSupply() external view returns (uint256) {
        return uint256(tranche.interestSupply());
    }

    /// @dev Prevents execution if the caller isn't the tranche
    modifier onlyMintAuthority() {
        require(
            msg.sender == address(tranche),
            "caller is not an authorized minter"
        );
        _;
    }

    /// @dev Mints tokens to an address
    /// @param _account The account to mint to
    /// @param _amount The amount to mint
    function mint(address _account, uint256 _amount)
        external
        override
        onlyMintAuthority
    {
        _mint(_account, _amount);
    }

    /// @dev Burns tokens from an address
    /// @param _account The account to burn from
    /// @param _amount The amount of token to burn
    function burn(address _account, uint256 _amount)
        external
        override
        onlyMintAuthority
    {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../libraries/DateString.sol";

contract TestDate {
    string public testString = "Tester";

    // This function will try encoding a timestamp and output-ing what happens
    function encodeTimestamp(uint256 timestamp)
        external
        returns (string memory)
    {
        // Will encode and store the result
        DateString._timestampToDateString(timestamp, testString);
        // We load and return the result
        return testString;
    }

    // This function allows access to encodeAndWriteTimestamp from DateString lib
    function encodePrefixTimestamp(string calldata prefix, uint256 timestamp)
        external
        returns (string memory)
    {
        // Will encode and store the result
        DateString._encodeAndWriteTimestamp(prefix, timestamp, testString);
        // We load and return the result
        return testString;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../InterestToken.sol";

interface IInterestTokenFactory {
    function deployInterestToken(
        address tranche,
        string memory strategySymbol,
        uint256 expiration,
        uint8 underlyingDecimals
    ) external returns (InterestToken interestToken);
}

// SPDX-License-Identifier: Apache-2.0

import "../Tranche.sol";
import "../interfaces/IWrappedPosition.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IInterestTokenFactory.sol";
import "../interfaces/IInterestToken.sol";

pragma solidity ^0.8.0;

/// @author Element Finance
/// @title Tranche Factory
contract TrancheFactory {
    /// @dev An event to track tranche creations
    /// @param trancheAddress the address of the tranche contract
    /// @param wpAddress the address of the wrapped position
    /// @param expiration the expiration time of the tranche
    event TrancheCreated(
        address indexed trancheAddress,
        address indexed wpAddress,
        uint256 indexed expiration
    );

    IInterestTokenFactory internal immutable _interestTokenFactory;
    address internal _tempWpAddress;
    uint256 internal _tempExpiration;
    IInterestToken internal _tempInterestToken;
    bytes32 public constant TRANCHE_CREATION_HASH =
        keccak256(type(Tranche).creationCode);
    // The address of our date library
    address internal immutable _dateLibrary;

    /// @notice Create a new Tranche.
    /// @param _factory Address of the interest token factory.
    constructor(address _factory, address dateLibrary) {
        _interestTokenFactory = IInterestTokenFactory(_factory);
        _dateLibrary = dateLibrary;
    }

    /// @notice Deploy a new Tranche contract.
    /// @param _expiration The expiration timestamp for the tranche.
    /// @param _wpAddress Address of the Wrapped Position contract the tranche will use.
    /// @return The deployed Tranche contract.
    function deployTranche(uint256 _expiration, address _wpAddress)
        public
        returns (Tranche)
    {
        _tempWpAddress = _wpAddress;
        _tempExpiration = _expiration;

        IWrappedPosition wpContract = IWrappedPosition(_wpAddress);
        bytes32 salt = keccak256(abi.encodePacked(_wpAddress, _expiration));
        string memory wpSymbol = wpContract.symbol();
        IERC20 underlying = wpContract.token();
        uint8 underlyingDecimals = underlying.decimals();

        // derive the expected tranche address
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            TRANCHE_CREATION_HASH
                        )
                    )
                )
            )
        );

        _tempInterestToken = _interestTokenFactory.deployInterestToken(
            predictedAddress,
            wpSymbol,
            _expiration,
            underlyingDecimals
        );

        Tranche tranche = new Tranche{ salt: salt }();
        emit TrancheCreated(address(tranche), _wpAddress, _expiration);
        require(
            address(tranche) == predictedAddress,
            "CREATE2 address mismatch"
        );

        // set back to 0-value for some gas savings
        delete _tempWpAddress;
        delete _tempExpiration;
        delete _tempInterestToken;

        return tranche;
    }

    /// @notice Callback function called by the Tranche.
    /// @dev This is called by the Tranche contract constructor.
    /// The return data is used for Tranche initialization. Using this, the Tranche avoids
    /// constructor arguments which can make the Tranche bytecode needed for create2 address
    /// derivation non-constant.
    /// @return Wrapped Position contract address, expiration timestamp, and interest token contract
    function getData()
        external
        view
        returns (
            address,
            uint256,
            IInterestToken,
            address
        )
    {
        return (
            _tempWpAddress,
            _tempExpiration,
            _tempInterestToken,
            _dateLibrary
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Permit.sol";
import "./interfaces/ITranche.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWrappedPosition.sol";
import "./libraries/Authorizable.sol";

/// @author Element Finance
/// @title User Proxy
contract UserProxy is Authorizable {
    // This contract is a convenience library to consolidate
    // the actions needed to create interest or principal tokens to one call.
    // It will hold user allowances, and can be disabled by authorized addresses
    // for security.
    // If frozen users still control their own tokens so can manually redeem them.

    // Store the accessibility state of the contract
    bool public isFrozen = false;
    // Constant wrapped ether address
    IWETH public immutable weth;
    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;
    // A constant which represents ether
    address internal constant _ETH_CONSTANT =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @dev Marks the msg.sender as authorized and sets them
    ///      as the owner in authorization library
    /// @param _weth The constant weth contract address
    /// @param __trancheFactory Address of the TrancheFactory contract
    /// @param __trancheBytecodeHash Hash of the Tranche bytecode.
    constructor(
        IWETH _weth,
        address __trancheFactory,
        bytes32 __trancheBytecodeHash
    ) Authorizable() {
        _authorize(msg.sender);
        weth = _weth;
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
    }

    /// @dev Requires that the contract is not frozen
    modifier notFrozen() {
        require(!isFrozen, "Contract frozen");
        _;
    }

    /// @dev Allows an authorized address to freeze or unfreeze this contract
    /// @param _newState True for frozen and false for unfrozen
    function setIsFrozen(bool _newState) external onlyAuthorized {
        isFrozen = _newState;
    }

    // Memory encoding of the permit data
    struct PermitData {
        IERC20Permit tokenContract;
        address who;
        uint256 amount;
        uint256 expiration;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @dev Takes the input permit calls and executes them
    /// @param data The array which encodes the set of permit calls to make
    modifier preApproval(PermitData[] memory data) {
        // If permit calls are provided we make try to make them
        if (data.length != 0) {
            // We make permit calls for each indicated call
            for (uint256 i = 0; i < data.length; i++) {
                _permitCall(data[i]);
            }
        }
        _;
    }

    /// @dev Makes permit calls indicated by a struct
    /// @param data the struct which has the permit calldata
    function _permitCall(PermitData memory data) internal {
        // Make the permit call to the token in the data field using
        // the fields provided.
        // Security note - This fairly open call is safe because it cannot
        // call 'transferFrom' or other sensitive methods despite the open
        // scope. Do not make more general without security review.
        data.tokenContract.permit(
            msg.sender,
            data.who,
            data.amount,
            data.expiration,
            data.v,
            data.r,
            data.s
        );
    }

    /// @notice Mints a Principal/Interest token pair from either underlying token or Eth
    ///      then returns the tokens to the caller.
    /// @dev This function assumes that it already has an allowance for the token in question.
    /// @param _amount The amount of underlying to turn into tokens
    /// @param _underlying Either (1) The underlying ERC20 token contract
    ///                   or (2) the _ETH_CONSTANT to indicate the user has sent eth.
    ///                   This token should revert in the event of a transfer failure.
    /// @param _expiration The expiration time of the Tranche contract
    /// @param _position The contract which manages pooled deposits
    /// @param _permitCallData Encoded array of permit calls to make prior to minting
    ///                        the data should be encoded with abi.encode(data, "PermitData[]")
    ///                        each PermitData struct provided will be executed as a call.
    ///                        An example use of this is if using a token with permit like USDC
    ///                        to encode a permit which gives this contract allowance before minting.
    /// @return returns the minted amounts of PT and YT
    // NOTE - It is critical that the notFrozen modifier is listed first so it gets called first.
    function mint(
        uint256 _amount,
        IERC20 _underlying,
        uint256 _expiration,
        address _position,
        PermitData[] calldata _permitCallData
    )
        external
        payable
        notFrozen
        preApproval(_permitCallData)
        returns (uint256, uint256)
    {
        // If the underlying token matches this predefined 'ETH token'
        // then we create weth for the user and go from there
        if (address(_underlying) == _ETH_CONSTANT) {
            // Check that the amount matches the amount provided
            require(msg.value == _amount, "Incorrect amount provided");
            // Create weth from the provided eth
            weth.deposit{ value: msg.value }();
            weth.transfer(address(_position), _amount);
        } else {
            // Check for the fact that this branch should not be payable
            require(msg.value == 0, "Non payable");
            // Move the user's funds to the wrapped position contract
            _underlying.transferFrom(msg.sender, address(_position), _amount);
        }

        // Proceed to internal minting steps
        (uint256 ptMinted, uint256 ytMinted) = _mint(_expiration, _position);
        // This sanity check ensure that at least as much was minted as was transferred
        require(ytMinted >= _amount, "Not enough minted");
        return (ptMinted, ytMinted);
    }

    /// @dev Allows a user to withdraw and unwrap weth in the same transaction
    ///      likely quite a bit more expensive than direct unwrapping but useful
    ///      for those who want to do one tx instead of two
    /// @param _expiration The tranche expiration time
    /// @param _position The contract which interacts with the yield bearing strategy
    /// @param _amountPT The amount of principal token to withdraw
    /// @param _amountYT The amount of yield token to withdraw.
    /// @param _permitCallData Encoded array of permit calls to make prior to withdrawing,
    ///                        should be used to get allowances for PT and YT
    // NOTE - It is critical that the notFrozen modifier is listed first so it gets called first.
    function withdrawWeth(
        uint256 _expiration,
        address _position,
        uint256 _amountPT,
        uint256 _amountYT,
        PermitData[] calldata _permitCallData
    ) external notFrozen preApproval(_permitCallData) {
        // Post the Berlin hardfork this call warms the address so only cost ~100 gas overall
        require(IWrappedPosition(_position).token() == weth, "Non weth token");
        // Only allow access if the user is actually attempting to withdraw
        require(((_amountPT != 0) || (_amountYT != 0)), "Invalid withdraw");
        // Because of create2 we know this code is exactly what is expected.
        ITranche derivedTranche = _deriveTranche(_position, _expiration);

        uint256 wethReceivedPt = 0;
        uint256 wethReceivedYt = 0;
        // Check if we need to withdraw principal token
        if (_amountPT != 0) {
            // If we have to withdraw PT first transfer it to this contract
            derivedTranche.transferFrom(msg.sender, address(this), _amountPT);
            // Then we withdraw that PT with the resulting weth going to this address
            wethReceivedPt = derivedTranche.withdrawPrincipal(
                _amountPT,
                address(this)
            );
        }
        // Check if we need to withdraw yield token
        if (_amountYT != 0) {
            // Post Berlin this lookup only costs 100 gas overall as well
            IERC20Permit yieldToken = derivedTranche.interestToken();
            // Transfer the YT to this contract
            yieldToken.transferFrom(msg.sender, address(this), _amountYT);
            // Withdraw that YT
            wethReceivedYt = derivedTranche.withdrawInterest(
                _amountYT,
                address(this)
            );
        }

        // A sanity check that some value was withdrawn
        if (_amountPT != 0) {
            require((wethReceivedPt != 0), "Rugged");
        }
        if (_amountYT != 0) {
            require((wethReceivedYt != 0), "No yield accrued");
        }
        // Withdraw the ether from weth
        weth.withdraw(wethReceivedPt + wethReceivedYt);
        // Send the withdrawn eth to the caller
        payable(msg.sender).transfer(wethReceivedPt + wethReceivedYt);
    }

    /// @dev The receive function allows WETH and only WETH to send
    ///      eth directly to this contract. Note - It Cannot be assumed
    ///      that this will prevent this contract from having an ETH balance
    receive() external payable {
        require(msg.sender == address(weth));
    }

    /// @dev This internal mint function performs the core minting logic after
    ///      the contract has already transferred to WrappedPosition contract
    /// @param _expiration The tranche expiration time
    /// @param _position The contract which interacts with the yield bearing strategy
    /// @return the principal token yield token returned
    function _mint(uint256 _expiration, address _position)
        internal
        returns (uint256, uint256)
    {
        // Use create2 to derive the tranche contract
        ITranche tranche = _deriveTranche(address(_position), _expiration);
        // Move funds into the Tranche contract
        // it will credit the msg.sender with the new tokens
        return tranche.prefundedDeposit(msg.sender);
    }

    /// @dev This internal function produces the deterministic create2
    ///      address of the Tranche contract from a wrapped position contract and expiration
    /// @param _position The wrapped position contract address
    /// @param _expiration The expiration time of the tranche
    /// @return The derived Tranche contract
    function _deriveTranche(address _position, uint256 _expiration)
        internal
        view
        virtual
        returns (ITranche)
    {
        bytes32 salt = keccak256(abi.encodePacked(_position, _expiration));
        bytes32 addressBytes = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                _trancheFactory,
                salt,
                _trancheBytecodeHash
            )
        );
        return ITranche(address(uint160(uint256(addressBytes))));
    }

    /// @dev This contract holds a number of allowances for addresses so if it is deprecated
    ///      it should be removed so that users do not have to remove allowances.
    ///      Note - onlyOwner is a stronger check than onlyAuthorized, many addresses can be
    ///      authorized to freeze or unfreeze the contract but only the owner address can kill
    function deprecate() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { ERC20PermitWithSupply, ERC20Permit, IERC20Permit } from "../../libraries/ERC20PermitWithSupply.sol";
import { IWrappedPosition } from "../../interfaces/IWrappedPosition.sol";
import { ITranche } from "../../interfaces/ITranche.sol";
import { IWrappedCoveredPrincipalToken } from "./interfaces/IWrappedCoveredPrincipalToken.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @author Element Finance
/// @title WrappedCoveredPrincipalToken
contract WrappedCoveredPrincipalToken is
    ERC20PermitWithSupply,
    AccessControl,
    IWrappedCoveredPrincipalToken
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // Address of the base/underlying token which is used to buy the yield bearing token from the wrapped position.
    // Ex - Dai is used to buy the yvDai yield bearing token
    address public immutable override baseToken;

    // Enumerable address list, It contains the list of allowed wrapped positions that are covered by this contract
    // Criteria to choose the wrapped position are -
    // a). Wrapped position should have same underlying/base token (i.e ETH, BTC, USDC).
    // b). Should have the similar risk profiles.
    EnumerableSet.AddressSet private _allowedWrappedPositions;

    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;

    // Role identifier that can use to do some operational stuff.
    bytes32 public constant ADMIN_ROLE = bytes32("ADMIN_ROLE");

    // Role identifier that allow a particular account to reap principal tokens out of the contract.
    bytes32 public constant RECLAIM_ROLE = bytes32("RECLAIM_ROLE");

    // Emitted when new wrapped position get whitelisted.
    event WrappedPositionAdded(address _wrappedPosition);

    // Emitted when the principal tokens get reclaimed.
    event Reclaimed(address _tranche, uint256 _amount);

    /// @notice Modifier to validate the wrapped position is whitelisted or not.
    modifier isValidWp(address _wrappedPosition) {
        require(!isAllowedWp(_wrappedPosition), "WFP:ALREADY_EXISTS");
        _;
    }

    ///@notice Initialize the wrapped token.
    ///@dev    Wrapped token have 18 decimals, It is independent of the baseToken decimals.
    constructor(
        address _baseToken,
        address _owner,
        address __trancheFactory,
        bytes32 __trancheBytecodeHash
    )
        ERC20Permit(
            _processName(IERC20Metadata(_baseToken).symbol()),
            _processSymbol(IERC20Metadata(_baseToken).symbol())
        )
    {
        baseToken = _baseToken;
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
        _setupRole(ADMIN_ROLE, _owner);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RECLAIM_ROLE, ADMIN_ROLE);
    }

    ///@notice Allows to create the name for the wrapped token.
    function _processName(string memory _tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked("Wrapped", _tokenSymbol, "Covered Principal")
            );
    }

    ///@notice Allows to create the symbol for the wrapped token.
    function _processSymbol(string memory _tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("W", _tokenSymbol));
    }

    /// @notice Add wrapped position within the allowed wrapped position enumerable set.
    /// @dev    It is only allowed to execute by the owner of the contract.
    ///         wrapped position which has underlying token equals to the base token are
    ///         only allowed to add, Otherwise it will revert.
    /// @param  _wrappedPosition Address of the Wrapped position which needs to add.
    function addWrappedPosition(address _wrappedPosition)
        external
        override
        isValidWp(_wrappedPosition)
        onlyRole(ADMIN_ROLE)
    {
        require(
            address(IWrappedPosition(_wrappedPosition).token()) == baseToken,
            "WFP:INVALID_WP"
        );
        _allowedWrappedPositions.add(_wrappedPosition);
        emit WrappedPositionAdded(_wrappedPosition);
    }

    /// @notice Allows the defaulter to mint wrapped tokens (Covered position) by
    ///         sending the de-pegged token to the contract.
    /// @dev    a) Only allow minting the covered position when the derived tranche got expired otherwise revert.
    ///         b) Sufficient allowance of the principal token (i.e tranche) should be provided
    ///            to the contract by the `msg.sender` to make execution successful.
    /// @param  _amount Amount of covered position / wrapped token `msg.sender` wants to mint.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    function mint(
        uint256 _amount,
        uint256 _expiration,
        address _wrappedPosition,
        PermitData calldata _permitCallData
    ) external override {
        require(isAllowedWp(_wrappedPosition), "WFP:INVALID_WP");
        address _tranche = address(
            _deriveTranche(_wrappedPosition, _expiration)
        );
        _usePermitData(_tranche, _permitCallData);
        // Only allow minting when the position get expired.
        require(_expiration < block.timestamp, "WFP:POSITION_NOT_EXPIRED");
        // Assumed that msg.sender provides the sufficient approval the contract.
        IERC20(_tranche).safeTransferFrom(
            msg.sender,
            address(this),
            _fromWad(_amount, _tranche)
        );
        // Mint the corresponding wrapped token to the `msg.sender`.
        _mint(msg.sender, _amount);
    }

    /// @notice Tell whether the given `_wrappedPosition` is whitelisted or not.
    /// @param  _wrappedPosition Address of the wrapped position.
    /// @return returns boolean, True -> allowed otherwise false.
    function isAllowedWp(address _wrappedPosition)
        public
        view
        override
        returns (bool)
    {
        return _allowedWrappedPositions.contains(_wrappedPosition);
    }

    /// @notice Returns the list of wrapped positions that are whitelisted with the contract.
    ///         Order is not maintained.
    /// @return Array of addresses.
    function allWrappedPositions()
        external
        view
        override
        returns (address[] memory)
    {
        return _allowedWrappedPositions.values();
    }

    /// @notice Reclaim tranche token (i.e principal token) by the authorized account.
    /// @dev    Only be called by the address which has the `RECLAIM_ROLE`, Should be Nexus Treasury.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    /// @param  _to Address whom funds gets transferred.
    function reclaimPt(
        uint256 _expiration,
        address _wrappedPosition,
        address _to
    ) external override onlyRole(RECLAIM_ROLE) {
        require(isAllowedWp(_wrappedPosition), "WFP:INVALID_WP");
        address _tranche = address(
            _deriveTranche(_wrappedPosition, _expiration)
        );
        uint256 amount = IERC20(_tranche).balanceOf(address(this));
        IERC20(_tranche).safeTransfer(_to, amount);
        emit Reclaimed(_tranche, amount);
    }

    function _usePermitData(address _tranche, PermitData memory _d) internal {
        if (_d.spender != address(0)) {
            IERC20Permit(_tranche).permit(
                msg.sender,
                _d.spender,
                _d.value,
                _d.deadline,
                _d.v,
                _d.r,
                _d.s
            );
        }
    }

    /// @notice Converts the decimal precision of given `_amount` to `_tranche` decimal.
    function _fromWad(uint256 _amount, address _tranche)
        internal
        view
        returns (uint256)
    {
        return (_amount * 10**IERC20Metadata(_tranche).decimals()) / 1e18;
    }

    /// @dev This internal function produces the deterministic create2
    ///      address of the Tranche contract from a wrapped position contract and expiration
    /// @param _position The wrapped position contract address
    /// @param _expiration The expiration time of the tranche
    /// @return The derived Tranche contract
    function _deriveTranche(address _position, uint256 _expiration)
        internal
        view
        returns (ITranche)
    {
        bytes32 salt = keccak256(abi.encodePacked(_position, _expiration));
        bytes32 addressBytes = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                _trancheFactory,
                salt,
                _trancheBytecodeHash
            )
        );
        return ITranche(address(uint160(uint256(addressBytes))));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { IERC20Permit } from "../../../interfaces/IERC20Permit.sol";

interface IWrappedCoveredPrincipalToken is IERC20Permit {
    // Memory encoding of the permit data
    struct PermitData {
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Address of the base/underlying token which is used to buy the yield bearing token from the wrapped position.
    // Ex - Dai is used to buy the yvDai yield bearing token.
    function baseToken() external view returns (address);

    /// @notice Add wrapped position within the allowed wrapped position enumerable set.
    /// @dev    It is only allowed to execute by the owner of the contract.
    ///         wrapped position which has underlying token equals to the base token are
    ///         only allowed to add, Otherwise it will revert.
    /// @param  _wrappedPosition Address of the Wrapped position which needs to add.
    function addWrappedPosition(address _wrappedPosition) external;

    /// @notice Allows the defaulter to mint wrapped tokens (Covered position) by
    ///         sending the de-pegged token to the contract.
    /// @dev    a) Only allow minting the covered position when the derived tranche got expired otherwise revert.
    ///         b) Sufficient allowance of the principal token (i.e tranche) should be provided
    ///            to the contract by the `msg.sender` to make execution successful.
    /// @param  _amount Amount of covered position / wrapped token `msg.sender` wants to mint.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    function mint(
        uint256 _amount,
        uint256 _expiration,
        address _wrappedPosition,
        PermitData calldata _permitCallData
    ) external;

    /// @notice Tell whether the given `_wrappedPosition` is whitelisted or not.
    /// @param  _wrappedPosition Address of the wrapped position.
    /// @return returns boolean, True -> allowed otherwise false.
    function isAllowedWp(address _wrappedPosition) external view returns (bool);

    /// @notice Returns the list of wrapped positions that are whitelisted with the contract.
    ///         Order is not maintained.
    /// @return Array of addresses.
    function allWrappedPositions() external view returns (address[] memory);

    /// @notice Reclaim tranche token (i.e principal token) by the authorized account.
    /// @dev    Only be called by the address which has the `RECLAIM_ROLE`, Should be Nexus Treasury.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    /// @param  _to Address whom funds gets transferred.
    function reclaimPt(
        uint256 _expiration,
        address _wrappedPosition,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { WrappedCoveredPrincipalToken, EnumerableSet } from "./WrappedCoveredPrincipalToken.sol";

/// @author Element Finance
/// @title WrappedCoveredPrincipalTokenFactory
contract WrappedCoveredPrincipalTokenFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Enumerable list of wrapped tokens that get created from the factory.
    EnumerableSet.AddressSet private _WrappedCoveredPrincipalTokens;

    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;

    // Emitted when new wrapped principal token get created.
    event WrappedCoveredPrincipalTokenCreated(
        address indexed _baseToken,
        address indexed _owner,
        address _wcPrincipalToken
    );

    /// @notice Initializing the owner of the contract.
    constructor(address __trancheFactory, bytes32 __trancheBytecodeHash) {
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
    }

    /// @notice Allow the owner to create the new wrapped token.
    /// @param  _baseToken Address of the base token / underlying token that is used to buy the wrapped positions.
    /// @param  _owner Address of the owner of wrapped futures.
    /// @return address of wrapped futures token.
    function create(address _baseToken, address _owner)
        external
        returns (address)
    {
        // Validate the given params
        _zeroAddressCheck(_owner);
        _zeroAddressCheck(_baseToken);
        address wcPrincipal = address(
            new WrappedCoveredPrincipalToken(
                _baseToken,
                _owner,
                _trancheFactory,
                _trancheBytecodeHash
            )
        );
        _WrappedCoveredPrincipalTokens.add(wcPrincipal);
        emit WrappedCoveredPrincipalTokenCreated(
            _baseToken,
            _owner,
            wcPrincipal
        );
        return wcPrincipal;
    }

    /// @notice Returns the list of wrapped tokens that are whitelisted with the contract.
    ///         Order is not maintained.
    /// @return Array of addresses.
    function allWrappedCoveredPrincipalTokens()
        public
        view
        returns (address[] memory)
    {
        return _WrappedCoveredPrincipalTokens.values();
    }

    /// @notice Sanity check for the zero address check.
    function _zeroAddressCheck(address _target) internal pure {
        require(_target != address(0), "WFPF:ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import "../libraries/Authorizable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ICurvePool.sol";

// TODO Due to the nature of the curve contracts, there are a number of design
// decisions made in this contract which primarily aim to generalize integration
// with curve. Curve contracts have often an inconsistent interface to many
// functions in their contracts which has influenced the design of this contract
// to target curve pool functions using function signatures computed off-chain.
// The validation of this and other features of this contract stem from this
// problem, for instance, the curve pool contracts target their underlying
// tokens using fixed-length dimensional arrays of length 2 or 3. We could
// harden this contract further by utilizing the "coins" function on the curve
// contract which would enable this contract validate that our input structure
// is correct. However, this would also run into problems as the guarantee of
// consistency of the "coins" function is also in question across the suite of
// pools in the curve ecosystem. There may be a solution to mitigate this
// problem but may be more trouble than it's worth.

/// @title ZapCurveTokenToPrincipalToken
/// @notice Allows the user to buy and sell principal tokens using a wider
/// array of tokens
/// @dev This contract introduces the concept of "root tokens" which are the
/// set of constituent tokens for a given curve pool. Each principal token
/// is constructed by a yield-generating position which in this case will be
/// represented by a curve LP token. This is referred to as the "base token"
/// and in the case where the user wishes to purchase or sell a principal token,
/// it can only be done so by using this token.
///
/// What this contract intends to do is enable the user purchase or sell
/// a position using those "root tokens" which would garner significant UX
/// improvements. The flow in the case of purchasing is as follows, the root
/// tokens are added as liquidity into the correct curve pool, giving a curve
/// "LP token" or "base token". Subsequently this is then used to purchase the
/// principal token. Selling works similarly but in the reverse direction.
///
/// Ex- Alice bought (x) amount curve LP token (let's say crvLUSD token) using LUSD (root token)
/// purchased (x) amount can be used to purchase the principal token by putting that amount
/// in the wrapped position contract.
contract ZapSwapCurve is Authorizable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    // Store the accessibility state of the contract
    bool public isFrozen;

    // A constant to represent ether
    address internal constant _ETH_CONSTANT =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Reference to the main balancer vault
    IVault internal immutable _balancer;

    /////////////////////////
    /// Zap In Data Structure
    /////////////////////////

    struct ZapInInfo {
        // The balancerPoolId references the particular pool in the balancer
        // contract which is used to exchange for the principal token
        bytes32 balancerPoolId;
        // The recipient is a target address the sender can send the resulting
        // principal tokens to
        address recipient;
        // Address of the principalToken
        IAsset principalToken;
        // The minimum amount of principal tokens the user expects to receive
        uint256 minPtAmount;
        // The time into the future for which the trade can happen
        uint256 deadline;
        // Some curvePools have themselves a dependent lpToken "root" which
        // this contract accommodates zapping through. This flag indicates if
        // such an action is necessary
        bool needsChildZap;
    }

    struct ZapCurveLpIn {
        // Address of target curvePool for which liquidity will be added
        // giving this contract the lpTokens necessary to swap for the
        // principalTokens
        address curvePool;
        // The target lpToken which will be received
        IERC20 lpToken;
        // Array of amounts which are structured in reference to the
        // "add_liquidity" function in the related curvePool. These in all
        // cases come in either fixed-length arrays of length 2 or 3
        uint256[] amounts;
        // Similar to "amounts", these are the reference token contract
        // addresses also ordered as per the inconsistent interface of the
        // "add_liquidity" curvePool function
        address[] roots;
        // Only relevant when there is a childZap, it references what
        // index in the amounts array of the main "zap" the resultant
        // number of lpTokens should be added to
        uint256 parentIdx;
        // The minimum amount of LP tokens expected to receive when adding
        // liquidity
        uint256 minLpAmount;
    }

    ///////////////////////////
    /// Zap Out Data Structure
    //////////////////////////

    struct ZapCurveLpOut {
        // Address of the curvePool for which an amount of lpTokens
        // is swapped for an amount of single root tokens
        address curvePool;
        // The contract address of the curve pools lpToken
        IERC20 lpToken;
        // This is the index of the target root we are swapping for
        int128 rootTokenIdx;
        // Address of the rootToken we are swapping for
        address rootToken;
        // This is the selector for deciding between the two differing curve
        // interfaces for the add
        bool curveRemoveLiqFnIsUint256;
    }

    struct ZapOutInfo {
        // Pool id of balancer pool that is used to exchange a users
        // amount of principal tokens
        bytes32 balancerPoolId;
        // Address of the principal token
        IAsset principalToken;
        // Amount of principal tokens the user wishes to swap for
        uint256 principalTokenAmount;
        // The recipient is the address the tokens which are to be swapped for
        // will be sent to
        address payable recipient;
        // The minimum amount base tokens the user is expecting
        uint256 minBaseTokenAmount;
        // The minimum amount root tokens the user is expecting
        uint256 minRootTokenAmount;
        // Timestamp into the future for which a transaction is valid for
        uint256 deadline;
        // If the target root token is sourced via two curve pool swaps, then
        // this is to be flagged as true
        bool targetNeedsChildZap;
    }

    /// @notice Memory encoding of the permit data
    struct PermitData {
        IERC20Permit tokenContract;
        address spender;
        uint256 amount;
        uint256 expiration;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @notice Sets the msg.sender as authorized and also set it as the owner
    ///         in the authorizable contract.
    /// @param __balancer The balancer vault contract
    constructor(IVault __balancer) {
        _authorize(msg.sender);
        _balancer = __balancer;
        isFrozen = false;
    }

    /// @notice Requires that the contract is not frozen
    modifier notFrozen() {
        require(!isFrozen, "Contract frozen");
        _;
    }

    // Allow this contract to receive ether
    receive() external payable {}

    /// @notice Allows an authorized address to freeze or unfreeze this contract
    /// @param _newState True for frozen and false for unfrozen
    function setIsFrozen(bool _newState) external onlyAuthorized {
        isFrozen = _newState;
    }

    /// @notice Takes the input permit calls and executes them
    /// @param data The array which encodes the set of permit calls to make
    modifier preApproval(PermitData[] memory data) {
        // If permit calls are provided we make try to make them
        _permitCall(data);
        _;
    }

    /// @notice Makes permit calls indicated by a struct
    /// @param data the struct which has the permit calldata
    function _permitCall(PermitData[] memory data) internal {
        // Make the permit call to the token in the data field using
        // the fields provided.
        if (data.length != 0) {
            // We make permit calls for each indicated call
            for (uint256 i = 0; i < data.length; i++) {
                data[i].tokenContract.permit(
                    msg.sender,
                    data[i].spender,
                    data[i].amount,
                    data[i].expiration,
                    data[i].v,
                    data[i].r,
                    data[i].s
                );
            }
        }
    }

    /// @notice This function sets approvals on all ERC20 tokens.
    /// @param tokens An array of token addresses which are to be approved
    /// @param spenders An array of contract addresses, most likely curve and
    /// balancer pool addresses
    /// @param amounts An array of amounts for which at each index, the spender
    /// from the same index in the spenders array is approved to use the token
    /// at the equivalent index of the token array on behalf of this contract
    function setApprovalsFor(
        address[] memory tokens,
        address[] memory spenders,
        uint256[] memory amounts
    ) external onlyAuthorized {
        require(tokens.length == spenders.length, "Incorrect length");
        require(tokens.length == amounts.length, "Incorrect length");
        for (uint256 i = 0; i < tokens.length; i++) {
            // Below call is to make sure that previous allowance shouldn't revert the transaction
            // It is just a safety pattern to use.
            IERC20(tokens[i]).safeApprove(spenders[i], uint256(0));
            IERC20(tokens[i]).safeApprove(spenders[i], amounts[i]);
        }
    }

    /// @notice zapIn Exchanges a number of tokens which are used in a specific
    /// curve pool(s) for a principal token.
    /// @param _info See ZapInInfo struct
    /// @param _zap See ZapCurveLpIn struct - This is the "main" or parent zap
    /// which produces the lp token necessary to swap for the principal token
    /// @param _childZap See ZapCurveLpIn - This is used only in cases where
    /// the "main" or "parent" zap itself is composed of another curve lp token
    /// which can be accessed more readily via another swap via curve
    function zapIn(
        ZapInInfo memory _info,
        ZapCurveLpIn memory _zap,
        ZapCurveLpIn memory _childZap,
        PermitData[] memory _permitData
    )
        external
        payable
        nonReentrant
        notFrozen
        preApproval(_permitData)
        returns (uint256 ptAmount)
    {
        // Instantiation of the context amount container which is used to track
        // amounts to be swapped in the final curve zap.
        uint256[3] memory ctx;

        // Only execute the childZap if it is necessary
        if (_info.needsChildZap) {
            uint256 _amount = _zapCurveLpIn(
                _childZap,
                // The context array is unnecessary for the childZap and so we
                // can just put a dud array in place of it
                [uint256(0), uint256(0), uint256(0)]
            );
            // When a childZap happens, we add the amount of lpTokens gathered
            // from it to the relevant root index of the "main" zap
            ctx[_childZap.parentIdx] += _amount;
        }

        // Swap an amount of "root" tokens on curve for the lp token that is
        // used to then purchase the principal token
        uint256 baseTokenAmount = _zapCurveLpIn(_zap, ctx);

        // Purchase of "ptAmount" of principal tokens
        ptAmount = _balancer.swap(
            IVault.SingleSwap({
                poolId: _info.balancerPoolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(_zap.lpToken)),
                assetOut: _info.principalToken,
                amount: baseTokenAmount,
                userData: "0x00"
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(_info.recipient),
                toInternalBalance: false
            }),
            _info.minPtAmount,
            _info.deadline
        );
    }

    /// @notice This function will add liquidity to a target curve pool,
    /// returning some amount of LP tokens as a result. This is effectively
    /// swapping amounts of the dependent curve pool tokens for the LP token
    /// which will be used elsewhere
    /// @param _zap ZapCurveLpIn struct
    /// @param _ctx fixed length array used as an amounts container between the
    /// zap and childZap and also makes the transition from a dynamic-length
    /// array to a fixed-length which is required for the actual call to add
    /// liquidity to the curvePool
    function _zapCurveLpIn(ZapCurveLpIn memory _zap, uint256[3] memory _ctx)
        internal
        returns (uint256)
    {
        // All curvePools have either 2 or 3 "root" tokens
        require(
            _zap.amounts.length == 2 || _zap.amounts.length == 3,
            "!(2 >= amounts.length <= 3)"
        );

        // Flag to detect if a zap to curve should be made
        bool shouldMakeZap = false;
        for (uint8 i = 0; i < _zap.amounts.length; i++) {
            bool zapIndexHasAmount = _zap.amounts[i] > 0;
            // If either the _ctx or zap amounts array has an index with an
            // amount > 0 we must zap curve
            shouldMakeZap = (zapIndexHasAmount || _ctx[i] > 0)
                ? true
                : shouldMakeZap;

            // if there is no amount at this index we can escape the loop earlier
            if (!zapIndexHasAmount) continue;

            if (_zap.roots[i] == _ETH_CONSTANT) {
                // Must check we do not unintentionally send ETH
                require(msg.value == _zap.amounts[i], "incorrect value");

                // We build the context container with our amounts
                _ctx[i] += _zap.amounts[i];
            } else {
                uint256 beforeAmount = _getBalanceOf(IERC20(_zap.roots[i]));

                // In the case of swapping an ERC20 "root" we must transfer them
                // to this contract in order to make the exchange
                IERC20(_zap.roots[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _zap.amounts[i]
                );

                // Due to rounding issues of some tokens, we use the
                // differential token balance of this contract
                _ctx[i] += _getBalanceOf(IERC20(_zap.roots[i])) - beforeAmount;
            }
        }

        // When there is nothing to swap for on curve we short-circuit
        if (!shouldMakeZap) {
            return 0;
        }
        uint256 beforeLpTokenBalance = _getBalanceOf(_zap.lpToken);

        if (_zap.amounts.length == 2) {
            ICurvePool(_zap.curvePool).add_liquidity{ value: msg.value }(
                [_ctx[0], _ctx[1]],
                _zap.minLpAmount
            );
        } else {
            ICurvePool(_zap.curvePool).add_liquidity{ value: msg.value }(
                [_ctx[0], _ctx[1], _ctx[2]],
                _zap.minLpAmount
            );
        }

        return _getBalanceOf(_zap.lpToken) - beforeLpTokenBalance;
    }

    /// @notice zapOut Allows users sell their principalTokens and subsequently
    /// swap the resultant curve LP token for one of its dependent "root tokens"
    /// @param _info See ZapOutInfo
    /// @param _zap See ZapCurveLpOut
    /// @param _childZap See ZapCurveLpOut
    function zapOut(
        ZapOutInfo memory _info,
        ZapCurveLpOut memory _zap,
        ZapCurveLpOut memory _childZap,
        PermitData[] memory _permitData
    )
        external
        payable
        nonReentrant
        notFrozen
        preApproval(_permitData)
        returns (uint256 amount)
    {
        // First, principalTokenAmount of principal tokens transferred
        // from sender to this contract
        IERC20(address(_info.principalToken)).safeTransferFrom(
            msg.sender,
            address(this),
            _info.principalTokenAmount
        );

        // Swaps an amount of users principal tokens for baseTokens, which
        // are the lpToken specified in the zap argument
        uint256 baseTokenAmount = _balancer.swap(
            IVault.SingleSwap({
                poolId: _info.balancerPoolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: _info.principalToken,
                assetOut: IAsset(address(_zap.lpToken)),
                amount: _info.principalTokenAmount,
                userData: "0x00"
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            _info.minBaseTokenAmount,
            _info.deadline
        );

        // Swap the baseTokens for a target root. In the case of where the
        // specified token the user wants is part of the childZap, the zap that
        // occurs is to swap the baseTokens to the lpToken specified in the
        // childZap struct. If there is no childZap, then the contract sends
        // the tokens to the recipient
        amount = _zapCurveLpOut(
            _zap,
            baseTokenAmount,
            _info.targetNeedsChildZap ? 0 : _info.minRootTokenAmount,
            _info.targetNeedsChildZap ? payable(address(this)) : _info.recipient
        );

        // Execute the childZap is specified to do so
        if (_info.targetNeedsChildZap) {
            amount = _zapCurveLpOut(
                _childZap,
                amount,
                _info.minRootTokenAmount,
                _info.recipient
            );
        }
    }

    /// @notice Swaps an amount of curve LP tokens for a single root token
    /// @param _zap See ZapCurveLpOut
    /// @param _lpTokenAmount This is the amount of lpTokens we are swapping
    /// with
    /// @param _minRootTokenAmount This is the minimum amount of "root" tokens
    /// the user expects to swap for. Used only in the final zap when executed
    /// under zapOut
    /// @param _recipient The address which the outputs tokens are to be sent
    /// to. When there is a second zap to occur, in the first zap the recipient
    /// should be this address
    function _zapCurveLpOut(
        ZapCurveLpOut memory _zap,
        uint256 _lpTokenAmount,
        uint256 _minRootTokenAmount,
        address payable _recipient
    ) internal returns (uint256 rootAmount) {
        // Flag to detect if we are sending to recipient
        bool transferToRecipient = address(this) != _recipient;
        uint256 beforeAmount = _zap.rootToken == _ETH_CONSTANT
            ? address(this).balance
            : _getBalanceOf(IERC20(_zap.rootToken));

        if (_zap.curveRemoveLiqFnIsUint256) {
            ICurvePool(_zap.curvePool).remove_liquidity_one_coin(
                _lpTokenAmount,
                uint256(int256(_zap.rootTokenIdx)),
                _minRootTokenAmount
            );
        } else {
            ICurvePool(_zap.curvePool).remove_liquidity_one_coin(
                _lpTokenAmount,
                _zap.rootTokenIdx,
                _minRootTokenAmount
            );
        }

        // ETH case
        if (_zap.rootToken == _ETH_CONSTANT) {
            // Get ETH balance of current contract
            rootAmount = address(this).balance - beforeAmount;
            // if address does not equal this contract we send funds to recipient
            if (transferToRecipient) {
                // Send rootAmount of ETH to the user-specified recipient
                _recipient.transfer(rootAmount);
            }
        } else {
            // Get balance of root token that was swapped
            rootAmount = _getBalanceOf(IERC20(_zap.rootToken)) - beforeAmount;
            // Send tokens to recipient
            if (transferToRecipient) {
                IERC20(_zap.rootToken).safeTransferFrom(
                    address(this),
                    _recipient,
                    rootAmount
                );
            }
        }
    }

    function _getBalanceOf(IERC20 _token) internal view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "./IAsset.sol";

// This interface is used instead of importing one from balancer contracts to
// resolve version conflicts
interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function getPool(bytes32 poolId)
        external
        view
        returns (address, PoolSpecialization);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICurvePool {
    function add_liquidity(uint256[2] memory amountCtx, uint256 minAmount)
        external
        payable;

    function add_liquidity(uint256[3] memory amountCtx, uint256 minAmount)
        external
        payable;

    function remove_liquidity_one_coin(
        uint256 amountLp,
        uint256 idx,
        uint256 minAmount
    ) external payable;

    function remove_liquidity_one_coin(
        uint256 amount,
        int128 idx,
        uint256 minAmount
    ) external payable;
}

pragma solidity ^0.8.0;

// This interface is used instead of importing one from balancer contracts to
// resolve version conflicts
interface IAsset {

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../UserProxy.sol";
import "../interfaces/IWETH.sol";

// This contract is a user proxy which exposes deriveTranche for testing
contract TestUserProxy is UserProxy {
    constructor(
        address _weth,
        address _trancheFactory,
        bytes32 _trancheBytecodeHash
    ) UserProxy(IWETH(_weth), _trancheFactory, _trancheBytecodeHash) {} // solhint-disable-line no-empty-blocks

    // solhint-disable-next-line private-vars-leading-underscore
    function deriveTranche(address position, uint256 expiration)
        public
        view
        returns (ITranche)
    {
        return _deriveTranche(position, expiration);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../InterestToken.sol";
import "../interfaces/IERC20.sol";

contract InterestTokenFactory {
    /// @dev Emitted when a new InterestToken is created.
    /// @param token the token address
    /// @param tranche the tranche address
    event InterestTokenCreated(address indexed token, address indexed tranche);

    /// @notice Deploy a new interest token contract
    /// @param _tranche The Tranche contract associated with this interest token.
    /// The Tranche contract is also the mint authority.
    /// @param _strategySymbol The symbol of the associated Wrapped Position contract.
    /// @param _expiration Expiration timestamp of the Tranche contract.
    /// @param _underlyingDecimals The number of decimal places the underlying token adheres to.
    /// @return The deployed interest token contract
    function deployInterestToken(
        address _tranche,
        string memory _strategySymbol,
        uint256 _expiration,
        uint8 _underlyingDecimals
    ) public returns (InterestToken) {
        InterestToken token = new InterestToken(
            _tranche,
            _strategySymbol,
            _expiration,
            _underlyingDecimals
        );

        emit InterestTokenCreated(address(token), _tranche);

        return token;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "./interfaces/IERC20.sol";
import "./WrappedPosition.sol";
import "./interfaces/external/CTokenInterfaces.sol";
import "./interfaces/external/ComptrollerInterface.sol";
import "./libraries/Authorizable.sol";

/// @author Element Finance
/// @title Compound Asset Proxy
contract CompoundAssetProxy is WrappedPosition, Authorizable {
    uint8 public immutable underlyingDecimals;
    // The ctoken contract
    CErc20Interface public immutable ctoken;
    // The Compound comptroller contract
    ComptrollerInterface public immutable comptroller;
    // Constant comp token address
    IERC20 public immutable comp;

    /// @notice Constructs this contract and stores needed data
    /// @param _ctoken The underlying ctoken
    /// @param _comptroller The Compound comptroller
    /// @param _comp The address of the COMP governance token
    /// @param _token The underlying token
    /// @param _name The name of the token created
    /// @param _symbol The symbol of the token created
    /// @param _owner The contract owner who is authorized to collect rewards
    constructor(
        address _ctoken,
        address _comptroller,
        IERC20 _comp,
        IERC20 _token,
        string memory _name,
        string memory _symbol,
        address _owner
    ) WrappedPosition(_token, _name, _symbol) {
        _authorize(_owner);
        // Authorize the contract owner
        setOwner(_owner);

        ctoken = CErc20Interface(_ctoken);
        comptroller = ComptrollerInterface(_comptroller);
        comp = _comp;
        // Set approval for the proxy
        _token.approve(_ctoken, type(uint256).max);
        underlyingDecimals = _token.decimals();
        // We must assume the ctoken has 8 decimals to make the correct calculation for exchangeRate
        require(
            IERC20(_ctoken).decimals() == 8,
            "breaks our assumption in exchange rate"
        );
        // Check that the underlying token is the same as ctoken's underlying
        require(address(_token) == CErc20Storage(_ctoken).underlying());
    }

    /// @notice Makes the actual ctoken deposit
    /// @return Tuple (the shares minted, amount underlying used)
    function _deposit() internal override returns (uint256, uint256) {
        // Load balance of contract
        uint256 depositAmount = token.balanceOf(address(this));

        // Since ctoken's mint function returns success codes
        // we get the balance before and after minting to calculate shares
        uint256 beforeBalance = ctoken.balanceOfUnderlying(address(this));

        // Deposit into compound
        uint256 mintStatus = ctoken.mint(depositAmount);
        require(mintStatus == 0, "compound mint failed");

        // StoGetre ctoken balance after minting
        uint256 afterBalance = ctoken.balanceOfUnderlying(address(this));
        // Calculate ctoken shares minted
        uint256 shares = afterBalance - beforeBalance;
        // Return the amount of shares the user has produced and the amount of underlying used for it.
        return (shares, depositAmount);
    }

    /// @notice Withdraw the number of shares
    /// @param _shares The number of shares to withdraw
    /// @param _destination The address to send the output funds
    // @param _underlyingPerShare The possibly precomputed underlying per share
    /// @return Amount of funds freed by doing a withdraw
    function _withdraw(
        uint256 _shares,
        address _destination,
        uint256
    ) internal override returns (uint256) {
        // Since ctoken's redeem function returns sucess codes
        // we get the balance before and after minting to calculate amount
        uint256 beforeBalance = token.balanceOf(address(this));

        // Do the withdraw
        uint256 redeemStatus = ctoken.redeem(_shares);
        require(redeemStatus == 0, "compound redeem failed");

        // Get underlying balance after withdrawing
        uint256 afterBalance = token.balanceOf(address(this));
        // Calculate the amount of funds that were freed
        uint256 amountReceived = afterBalance - beforeBalance;
        // Transfer the underlying to the destination
        // 'token' is an immutable in WrappedPosition
        token.transfer(_destination, amountReceived);

        // Return the amount of underlying
        return amountReceived;
    }

    /// @notice Get the underlying amount of tokens per shares given
    /// @param _amount The amount of shares you want to know the value of
    /// @return Value of shares in underlying token
    function _underlying(uint256 _amount)
        internal
        view
        override
        returns (uint256)
    {
        // Load exchange rate
        uint256 exchangeRate = ctoken.exchangeRateStored();

        // Calculate mantissa for the scaled exchange rate
        // 18 point decimal fix + difference in decimals between underlying and ctoken
        uint256 mantissa = 18 + underlyingDecimals - 8;

        // Multiply _amount by exchange rate & correct for decimals
        return ((_amount * exchangeRate) / (10**mantissa));
    }

    /// @notice Collect the comp rewards accrued
    /// @param _destination The address to send the rewards to
    function collectRewards(address _destination) external onlyAuthorized {
        // Set up input params for claimComp
        CErc20Interface[] memory cTokens = new CErc20Interface[](1);
        // Store cToken as an array
        cTokens[0] = ctoken;

        // claim the rewards
        comptroller.claimComp(address(this), cTokens);
        // look up the comp balance to send
        uint256 balance = comp.balanceOf(address(this));
        // send to destination address
        comp.transfer(_destination, balance);
    }
}

pragma solidity >=0.5.16;

import "./ComptrollerInterface.sol";

// import "./InterestRateModel.sol";
// import "./EIP20NonStandardInterface.sol";
/* solhint-disable private-vars-leading-underscore */

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // /**
    //  * @notice Maximum borrow rate that can ever be applied (.0005% / block)
    //  */

    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    // /**
    //  * @notice Maximum fraction of interest that can be set aside for reserves
    //  */
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    // /**
    //  * @notice Model which tells what the current interest rate should be
    //  */
    // InterestRateModel public interestRateModel;

    // /**
    //  * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    //  */
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    // /**
    //  * @notice Official record of token balances for each account
    //  */
    mapping(address => uint256) internal accountTokens;

    // /**
    //  * @notice Approved token transfer amounts on behalf of others
    //  */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    // /**
    //  * @notice Mapping of account addresses to outstanding borrow balances
    //  */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(
        ComptrollerInterface oldComptroller,
        ComptrollerInterface newComptroller
    );

    // /**
    //  * @notice Event emitted when interestRateModel is changed
    //  */
    // event NewMarketInterestRateModel(
    //     InterestRateModel oldInterestRateModel,
    //     InterestRateModel newInterestRateModel
    // );

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    /*** User Interface ***/

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256);

    function balanceOfUnderlying(address owner)
        external
        virtual
        returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view virtual returns (uint256);

    function supplyRatePerBlock() external view virtual returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function borrowBalanceCurrent(address account)
        external
        virtual
        returns (uint256);

    function borrowBalanceStored(address account)
        public
        view
        virtual
        returns (uint256);

    function exchangeRateCurrent() public virtual returns (uint256);

    function exchangeRateStored() public view virtual returns (uint256);

    function getCash() external view virtual returns (uint256);

    function accrueInterest() public virtual returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin)
        external
        virtual
        returns (uint256);

    function _acceptAdmin() external virtual returns (uint256);

    // function _setComptroller(ComptrollerInterface newComptroller)
    //     public
    //     returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        virtual
        returns (uint256);

    function _reduceReserves(uint256 reduceAmount)
        external
        virtual
        returns (uint256);

    // function _setInterestRateModel(InterestRateModel newInterestRateModel)
    //     public
    //     returns (uint256);
}

interface CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    // address public underlying;
    function underlying() external returns (address);
}

interface CErc20Interface is CErc20Storage {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        CTokenInterface cTokenCollateral
    ) external returns (uint256);

    // function sweepToken(EIP20NonStandardInterface token) external;

    // Copied from CTokenInterface
    function balanceOfUnderlying(address owner) external returns (uint256);

    function exchangeRateCurrent() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public virtual;
}

abstract contract CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public virtual;
}

pragma solidity >=0.5.16;

import "./CTokenInterfaces.sol";

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        virtual
        returns (uint256[] memory);

    function exitMarket(address cToken) external virtual returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external virtual returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external virtual;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external virtual returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external virtual;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external virtual;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external virtual;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view virtual returns (uint256, uint256);

    // Claim all the COMP accrued by holder in specific markets
    function claimComp(address holder, CErc20Interface[] memory cTokens)
        external
        virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { IERC20 } from "../interfaces/IERC20.sol";

contract TestTranche {
    IERC20 private _baseToken;
    uint256 private _timestamp;

    constructor(address baseToken, uint256 timestamp) {
        _baseToken = IERC20(baseToken);
        _timestamp = timestamp;
    }

    function underlying() external view returns (IERC20) {
        return _baseToken;
    }

    function unlockTimestamp() external view returns (uint256) {
        return _timestamp;
    }
}