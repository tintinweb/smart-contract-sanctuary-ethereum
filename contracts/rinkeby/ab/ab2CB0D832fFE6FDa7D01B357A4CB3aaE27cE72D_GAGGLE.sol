// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";





contract GAGGLE is  Initializable,  OwnableUpgradeable, IERC20Upgradeable{
    using SafeMath for uint256;
    using Address for address;

    address public tokenPairAddress;
    address public teamAddress = 0x99990Ab0E073Ecf018ad5d6C4D1D0815Aa3D33A1;
    address public treasuryAddress = 0xeB2B7dbf1D37B1495f855aCb2d251Fa68e1202ce;
    address public psWallet = 0xfCbDdbe9DC61cB5e4Ebf6135C52be50B9cab0837;
    address public cmoAddress = 0xed564EF21C2A46FcA92fB9fF29cb5b53a10C90B0;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _reserveTokenBalance;
    mapping(address => uint256) private _circulatingTokenBalance;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    // The highest possible number.
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalSupply = 20000000000 * 10**9;
    uint256 private _totalReserve = (MAX - (MAX % _totalSupply));
    uint256 private _transactionFeeTotal;

    bool private initialSellTaxActive = false;
    bool private initialSellTaxSet = false;

    uint8 private _decimals = 9;
    string private _symbol = "$GIGGLE";
    string private _name = "Giggle";
// Struct for storing calculated transaction reserve values, fixes the error of too many local variables.
       struct ReserveValues {
        uint256 reserveAmount;
        uint256 reserveTransferAmountMarketing;
        uint256 reserveTransferAmount;
        uint256 reserveTransferAmountTeam;
        uint256 reserveTransferAmountBurnEm;
    }

        struct TransactionValues {
        uint256 transactionFee;
        uint256 transferAmount;
        uint256 netTransferAmount;
        uint256 marketingFee;
        uint256 teamTax;
        uint256 burnEm;
    }
    function initialize() initializer public {
        uint256 blackHole = _totalSupply.div(2);
        uint256 presale = blackHole.mul(23).div(100);
        uint256 lp = blackHole.mul(30).div(100);
        uint256 team = blackHole.mul(18).div(100);
        uint256 cmo = blackHole.mul(10).div(1000);
        uint256 treasury = blackHole.mul(28).div(100);

         uint256 rate = getRate();
        

        _reserveTokenBalance[burnAddress] = blackHole.mul(rate);
        _reserveTokenBalance[_msgSender()] = presale.mul(rate) + lp.mul(rate);
        _reserveTokenBalance[treasuryAddress] = treasury.mul(rate);
        _reserveTokenBalance[cmoAddress] = cmo.mul(rate);
        _reserveTokenBalance[teamAddress] = team.mul(rate);


        emit Transfer(address(0), burnAddress, blackHole);
        emit Transfer(address(0), _msgSender(), presale);
        emit Transfer(address(0), _msgSender(), lp);
        emit Transfer(address(0), teamAddress, team);
        emit Transfer(address(0), treasuryAddress, treasury);
        emit Transfer(address(0), cmoAddress, cmo);
    }



    function deathTaxOn() public onlyOwner {
        initialSellTaxActive = true;
    }

    function deathTaxOff() public onlyOwner {
        initialSellTaxActive = false;
    }

    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }

    function setTokenPairAddress(address _tokenPairAddress) public onlyOwner {
        tokenPairAddress = _tokenPairAddress;
    }

    /// @notice Gets the token's name
    /// @return Name
    function name() public view  returns (string memory) {
        return _name;
    }

    /// @notice Gets the token's symbol
    /// @return Symbol
    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    /// @notice Gets the token's decimals
    /// @return Decimals
    function decimals() public view  returns (uint8) {
        return _decimals;
    }

    /// @notice Gets the total token supply (circulating supply from the reserve)
    /// @return Total token supply
    function totalSupply() public pure  returns (uint256) {
        return _totalSupply;
    }

    /// @notice Gets the token balance of given account
    /// @param account - Address to get the balance of
    /// @return Account's token balance
    function balanceOf(address account) public view  returns (uint256) {
        if (_isExcluded[account]) return _circulatingTokenBalance[account];
        return tokenBalanceFromReserveAmount(_reserveTokenBalance[account]);
    }

    /// @notice Transfers tokens from msg.sender to recipient
    /// @param recipient - Recipient of tokens
    /// @param amount - Amount of tokens to send
    /// @return true
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @notice Gets the token spend allowance for spender of owner
    /// @param owner - Owner of the tokens
    /// @param spender - Account with allowance to spend owner's tokens
    /// @return allowance amount
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /// @notice Approve token transfers from a 3rd party
    /// @param spender - The account to approve for spending funds on behalf of msg.senderds
    /// @param amount - The amount of tokens to approve
    /// @return true
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @notice Transfer tokens from a 3rd party
    /// @param sender - The account sending the funds
    /// @param recipient - The account receiving the funds
    /// @param amount - The amount of tokens to send
    /// @return true
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /// @notice Increase 3rd party allowance to spend funds
    /// @param spender - The account being approved to spend on behalf of msg.sender
    /// @param addedValue - The amount to add to spending approval
    /// @return true
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /// @notice Decrease 3rd party allowance to spend funds
    /// @param spender - The account having approval revoked to spend on behalf of msg.sender
    /// @param subtractedValue - The amount to remove from spending approval
    /// @return true
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /// @notice Gets the contract owner
    /// @return contract owner's address
    function getOwner() external view  returns (address) {
        return owner();
    }

    /// @notice Tells whether or not the address is excluded from owning reserve balance
    /// @param account - The account to test
    /// @return true or false
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /// @notice Gets the total amount of fees spent
    /// @return Total amount of transaction fees
    function totalFees() public view returns (uint256) {
        return _transactionFeeTotal;
    }

    /// @notice Distribute tokens from the msg.sender's balance amongst all holders
    /// @param transferAmount - The amount of tokens to distribute
    function distributeToAllHolders(uint256 transferAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (, ReserveValues memory reserveValues, ) = _getValues(transferAmount);
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _totalReserve = _totalReserve.sub(reserveValues.reserveAmount);
        _transactionFeeTotal = _transactionFeeTotal.add(transferAmount);
    }

    /// @notice Gets the reserve balance based on amount of tokens
    /// @param transferAmount - The amount of tokens to distribute
    /// @param deductTransferReserveFee - Whether or not to deduct the transfer fee
    /// @return Reserve balance
    function reserveBalanceFromTokenAmount(
        uint256 transferAmount,
        bool deductTransferReserveFee
    ) public view returns (uint256) {
        (, ReserveValues memory reserveValues, ) = _getValues(transferAmount);
        require(
            transferAmount <= _totalSupply,
            "Amount must be less than supply"
        );
        if (!deductTransferReserveFee) {
            return reserveValues.reserveAmount;
        } else {
            return reserveValues.reserveTransferAmount;
        }
    }

    /// @notice Gets the token balance based on the reserve amount
    /// @param reserveAmount - The amount of reserve tokens owned
    /// @dev Dividing the reserveAmount by the currentRate is identical to multiplying the reserve amount by the ratio of totalSupply to totalReserve, which will be much less than 100%
    /// @return Token balance
    function tokenBalanceFromReserveAmount(uint256 reserveAmount)
        public
        view
        returns (uint256)
    {
        require(
            reserveAmount <= _totalReserve,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = getRate();
        return reserveAmount.div(currentRate);
    }

    /// @notice Excludes an account from owning reserve balance. Useful for exchange and pool addresses.
    /// @param account - The account to exclude
    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_reserveTokenBalance[account] > 0) {
            _circulatingTokenBalance[account] = tokenBalanceFromReserveAmount(
                _reserveTokenBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /// @notice Includes an excluded account from owning reserve balance
    /// @param account - The account to include
    function includeAccount(address account) external onlyOwner {
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _circulatingTokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /// @notice Approves spender to spend owner's tokens
    /// @param owner - The account approving spender to spend tokens
    /// @param spender - The account to spend the tokens
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Transfers 4.5% of every transaction to the LFG DAO
    /// @notice Transfers 0.5% of every transaction for contract license.
    /// @dev These addresses will never be excluded from receiving reflect, so we only increase their reserve balances
    function applyExternalTransactionTax(
        ReserveValues memory reserveValues,
        TransactionValues memory transactionValues,
        address sender
    ) private {
        _reserveTokenBalance[teamAddress] = _reserveTokenBalance[teamAddress]
            .add(reserveValues.reserveTransferAmountTeam);
        _reserveTokenBalance[treasuryAddress] = _reserveTokenBalance[
            treasuryAddress
        ].add(reserveValues.reserveTransferAmountMarketing);
        _reserveTokenBalance[burnAddress] = _reserveTokenBalance[burnAddress]
            .add(reserveValues.reserveTransferAmountBurnEm);

        emit Transfer(sender, teamAddress, transactionValues.teamTax);
        emit Transfer(sender, treasuryAddress, transactionValues.teamTax);
        emit Transfer(sender, burnAddress, transactionValues.burnEm);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _transferStandard(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(
            reserveValues.reserveTransferAmount
        );
        emit Transfer(sender, recipient, transactionValues.netTransferAmount);
        applyExternalTransactionTax(reserveValues, transactionValues, sender);
        // _applyFees(reserveValues.reserveFee, transactionValues.transactionFee);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);

        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );

        // No tx fees for funding initial Token Pair contract. Only for transferToExcluded, all pools will be excluded from receiving reflect.
        if (recipient == tokenPairAddress) {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveAmount);
            _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
                recipient
            ].add(transferAmount);

            emit Transfer(sender, recipient, transferAmount);
        } else {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveTransferAmount);
            _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
                recipient
            ].add(transactionValues.netTransferAmount);
            emit Transfer(
                sender,
                recipient,
                transactionValues.netTransferAmount
            );
            applyExternalTransactionTax(
                reserveValues,
                transactionValues,
                sender
            );
            // _applyFees(
            //     reserveValues.reserveFee,
            //     transactionValues.transactionFee
            // );
        }
    }

    /// @notice Transfers tokens from excluded sender to included recipient
    /// @param sender - The account sending tokens
    /// @param recipient - The account receiving tokens
    /// @param transferAmount = The amount of tokens to send
    /// @dev Transferring tokens from an excluded address reduces the circulatingTokenBalance directly but adds only reserve balance to the included recipient
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(
            transferAmount
        );
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );

        // only matters when transferring from the Pair contract (which is excluded)
        if (!initialSellTaxActive) {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveTransferAmount);
            emit Transfer(
                sender,
                recipient,
                transactionValues.netTransferAmount
            );
            applyExternalTransactionTax(
                reserveValues,
                transactionValues,
                sender
            );
            // _applyFees(
            //     reserveValues.reserveFee,
            //     transactionValues.transactionFee
            // );
        } else {
            // Sell tax of 90% to prevent bots from sniping the liquidity pool. Should be active for a few hours after liquidity pool launch.
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveAmount.div(10));
            emit Transfer(sender, recipient, transferAmount.div(10));
        }
    }

    /// @notice Transfers tokens from excluded sender to excluded recipient
    /// @param sender - The account sending tokens
    /// @param recipient - The account receiving tokens
    /// @param transferAmount = The amount of tokens to send
    /// @dev Transferring tokens from and to excluded addresses modify both the circulatingTokenBalance & reserveTokenBalance on both sides, in case one address is included in the future
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(
            transferAmount
        );
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(
            reserveValues.reserveTransferAmount
        );
        _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
            recipient
        ].add(transactionValues.netTransferAmount);

        emit Transfer(sender, recipient, transactionValues.netTransferAmount);
        applyExternalTransactionTax(reserveValues, transactionValues, sender);
        // _applyFees(reserveValues.reserveFee, transactionValues.transactionFee);
    }

    // function _applyFees(uint256 reserveFee, uint256 transactionFee) private {
    //     _totalReserve = _totalReserve.sub(reserveFee);
    //     _transactionFeeTotal = _transactionFeeTotal.add(transactionFee);
    // }

    function _getValues(uint256 transferAmount)
        private
        view
        returns (
            TransactionValues memory,
            ReserveValues memory,
            uint256
        )
    {
        TransactionValues memory transactionValues = _getTValues(
            transferAmount
        );
        uint256 currentRate = getRate();
        ReserveValues memory reserveValues = _getRValues(
            transferAmount,
            transactionValues,
            currentRate
        );

        return (transactionValues, reserveValues, currentRate);
    }

    function _getTValues(uint256 transferAmount)
        private
        pure
        returns (TransactionValues memory)
    {
        TransactionValues memory transactionValues;

        transactionValues.transactionFee = transferAmount.mul(2).div(100);

        transactionValues.teamTax = transferAmount.mul(2).div(100);

        transactionValues.burnEm = transferAmount.mul(10).div(1000);

        transactionValues.netTransferAmount = transferAmount
            .sub(transactionValues.transactionFee)
            .sub(transactionValues.teamTax)
            .sub(transactionValues.burnEm);

        return transactionValues;
    }

    function _getRValues(
        uint256 transferAmount,
        TransactionValues memory transactionValues,
        uint256 currentRate
    ) private pure returns (ReserveValues memory) {
        ReserveValues memory reserveValues;
        reserveValues.reserveAmount = transferAmount.mul(currentRate);
        reserveValues.reserveTransferAmountMarketing = transactionValues
            .transactionFee
            .mul(currentRate);
        reserveValues.reserveTransferAmountTeam = transactionValues.teamTax.mul(
            currentRate
        );
        reserveValues.reserveTransferAmountBurnEm = transactionValues
            .burnEm
            .mul(currentRate);

        reserveValues.reserveTransferAmount = reserveValues
            .reserveAmount
            .sub(reserveValues.reserveTransferAmountMarketing)
            .sub(reserveValues.reserveTransferAmountTeam)
            .sub(reserveValues.reserveTransferAmountBurnEm);

        return reserveValues;
    }

    /// @notice Utility function - gets the current reserve rate - totalReserve / totalSupply
    /// @return Reserve rate
    function getRate() public view returns (uint256) {
        (uint256 reserveSupply, uint256 totalTokenSupply) = getCurrentSupply();
        return reserveSupply.div(totalTokenSupply);
    }

    /// @notice Utility function - gets total reserve and circulating supply
    /// @return Reserve supply, total token supply
    function getCurrentSupply() public view returns (uint256, uint256) {
        uint256 reserveSupply = _totalReserve;
        uint256 totalTokenSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reserveTokenBalance[_excluded[i]] > reserveSupply ||
                _circulatingTokenBalance[_excluded[i]] > totalTokenSupply
            ) return (_totalReserve, _totalSupply);
            reserveSupply = reserveSupply.sub(
                _reserveTokenBalance[_excluded[i]]
            );
            totalTokenSupply = totalTokenSupply.sub(
                _circulatingTokenBalance[_excluded[i]]
            );
        }
        if (reserveSupply < _totalReserve.div(_totalSupply))
            return (_totalReserve, _totalSupply);
        return (reserveSupply, totalTokenSupply);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Upgradeable {
  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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