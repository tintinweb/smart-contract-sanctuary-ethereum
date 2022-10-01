//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAdminTools.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IFundingSinglePanel.sol";

/**
 * @notice This smart contract represents a Fund Token in the platform. It's an ERC20 with whitelisting capabilities.
 */
contract Token is IToken, ERC20, Ownable {
    using SafeMath for uint256;

    IAdminTools private ATContract;
    address private ATAddress;

    bytes1 private constant STATUS_ALLOWED = 0x11;
    bytes1 private constant STATUS_DISALLOWED = 0x10;

    address public fspAddress;
    address public factoryAddress;

    bool private _paused;

    struct contractsFeatures {
        bool permission;
        uint256 tokenRateExchange;
    }

    mapping(address => contractsFeatures) private contractsToImport;

    event Paused(address account);
    event Unpaused(address account);

    /**
     * @notice Initialise the Fund Token
     * @param tokname The name of the token
     * @param toksymbol The symbol of the token
     * @param _ATAddress The address of the Admin Tools related to this Fund Token
     * @param _factoryAddress The address of the factory
     */
    constructor(string memory tokname, string memory toksymbol, address _ATAddress, address _factoryAddress /*, uint8 _tokenDecimals*/) ERC20(tokname, toksymbol) {
        //_setupDecimals(_tokenDecimals);

        factoryAddress = _factoryAddress;

        ATAddress = _ATAddress;
        ATContract = IAdminTools(ATAddress);
        _paused = false;
    }

    modifier onlyMinterAddress() {
        require(ATContract.getMinterAddress() == msg.sender, "Address can not mint!");
        _;
    }

    /**
     * @notice Ensures that the function can only be called if the campaign is over
     */
    modifier onlyWhenCampaignFinished() {
        bool isCampaignOver = IFundingSinglePanel(fspAddress).isCampaignOver();
        require(isCampaignOver, "/campaign-not-finished");
        _;
    }

    /**
     * @notice Ensures that the function can only be called by the factory
     */
    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "/not-factory");
        _;
    }

    /**
     * @notice Ensures that the function can only be called when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Token Contract paused...");
        _;
    }

    /**
     * @notice Ensures that the function can only be called when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Token Contract not paused");
        _;
    }

    /**
     * @notice Returns if the token is paused or not
     * @return isPaused bool True if the token is paused, false otherwise.
     */
    function getPaused() external view override returns (bool) {
        return _paused;
    }

    /**
     * @notice Pauses the token
     * @dev This method can only be called by the owner of the token
     */
    function pause() external override onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the token
     * @dev This method can only be called by the owner of the token
     */
    function unpause() external override onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Check if the contract can be imported to change with this token
     * @param _contract The address of token to be imported
     * @return isImported bool True if the can be used to change with this token
     */
    function isImportedContract(address _contract) external override view returns (bool) {
        return contractsToImport[_contract].permission;
    }

    /**
     * @notice Get the exchange rate between token to be imported and this token
     * @param _contract The address of token to be exchange
     * @return exchangeRate uint256 The exchange rate with 18 decimals
     */
    function getImportedContractRate(address _contract) external override view returns (uint256) {
        return contractsToImport[_contract].tokenRateExchange;
    }

    /**
     * @notice Set the address of the token to be imported and its exchange rate
     * @param _contract The address of token to be imported
     * @param _exchRate The exchange rate between token to be imported and this token
     * @dev This method can only be called by the owner
     */
    function setImportedContract(address _contract, uint256 _exchRate) external override onlyOwner {
        require(_contract != address(0), "Address not allowed!");
        require(_exchRate >= 0, "Rate exchange not allowed!");
        contractsToImport[_contract].permission = true;
        contractsToImport[_contract].tokenRateExchange = _exchRate;
    }

    /**
     * @notice Transfer tokens from the caller to another account
     * @param _to The address of the receiver
     * @param _value The quantity of tokens to transfer
     * @dev Checks if the transfer can be done via the Admin Tools
     */
    function transfer(address _to, uint256 _value) public override whenNotPaused onlyWhenCampaignFinished returns (bool) {
        require(checkTransferAllowed(msg.sender, _to, _value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transfer(_to, _value);
    }

    /**
     * @notice Transfer tokens between two accounts
     * @param _from The address of the sender
     * @param _to The address of the receiver
     * @param _value The quantity of tokens to transfer
     * @dev Checks if the transfer can be done via the Admin Tools
     */
    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused onlyWhenCampaignFinished returns (bool) {
        require(checkTransferFromAllowed(_from, _to, _value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transferFrom(_from, _to,_value);
    }

    /**
     * @notice Mints new token to a specified address
     * @param _account The address of the receiver
     * @param _amount The quantity of tokens to mint
     * @dev Checks if the mint is allowed and if the receiver can receive the tokens via the Admin Tools
     */
    function mint(address _account, uint256 _amount) public whenNotPaused onlyMinterAddress {
        // require(checkMintAllowed(_account, _amount) == STATUS_ALLOWED, "mint must be allowed");
        require(okToReceiveTokens(_account, _amount), "Receiver not allowed to receive tokens!");
        ERC20._mint(_account, _amount);
    }

    /**
     * @notice Burns token from a specified address
     * @param _account The address from which tokens will be burned
     * @param _amount The quantity of tokens to burn
     * @dev Checks if the burn is allowed via the Admin Tools
     */
    function burn(address _account, uint256 _amount) public whenNotPaused onlyMinterAddress {
        // require(checkBurnAllowed(_account, _amount) == STATUS_ALLOWED, "burn must be allowed");
        ERC20._burn(_account, _amount);
    }

    /**
     * @notice Check if the sender address could receive new tokens on emission
     * @param _recipient The address of the receiver
     * @param _amountToAdd The amount of tokens to be added to sender balance on emission
     * @return canReceive bool True if the recipient can receive the specified amount of tokens
     */
    function okToReceiveTokens(address _recipient, uint256 _amountToAdd) public view override returns (bool){
        uint256 holderBalanceToBe = balanceOf(_recipient).add(_amountToAdd);
        bool okToTransfer = ATContract.isWhitelisted(_recipient) && holderBalanceToBe <= ATContract.getMaxEmissionAmount(_recipient) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdEmissionAmount() ? true : false;
        return okToTransfer;
    }

    /**
     * @notice Check if the sender address could receive new tokens on transfer
     * @param _holder The address of the sender
     * @param _amountToAdd The amount of tokens to be added to sender balance on transfer
     * @return canTransfer bool True if the holder can transfer the specified amount of tokens
     */
    function okToTransferTokens(address _holder, uint256 _amountToAdd) public view override returns (bool){
        uint256 holderBalanceToBe = balanceOf(_holder).add(_amountToAdd);
        bool okToTransfer = ATContract.isWhitelisted(_holder) && holderBalanceToBe <= ATContract.getMaxTransferAmount(_holder) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdTransferAmount() ? true : false;
        return okToTransfer;
    }

    /**
     * @notice Check if a transfer can be done
     * @param _sender The address that will transfer the tokens
     * @param _receiver The address that will receive the tokens
     * @param _amount The amount of tokens that will be transferred
     * @return status bytes1 Returns STATUS_ALLOWED if the receiver can receiver the specified amount of tokens
     */
    function checkTransferAllowed (address _sender, address _receiver, uint256 _amount) public view override returns (bytes1) {
        require(_sender != address(0), "Sender can not be 0!");
        require(_receiver != address(0), "Receiver can not be 0!");
        require(balanceOf(_sender) >= _amount, "Sender does not have enough tokens!");
        require(okToTransferTokens(_receiver, _amount), "Receiver not allowed to perform transfer!");
        return STATUS_ALLOWED;
    }

    /**
     * @notice Check if a transferFrom can be done
     * @param _sender The address that will transfer the tokens
     * @param _receiver The address that will receive the tokens
     * @param _amount The amount of tokens that will be transferred
     * @return status bytes1 Returns STATUS_ALLOWED if the receiver can receiver the specified amount of tokens
     */
    function checkTransferFromAllowed (address _sender, address _receiver, uint256 _amount) public view override returns (bytes1) {
        require(_sender != address(0), "Sender can not be 0!");
        require(_receiver != address(0), "Receiver can not be 0!");
        require(balanceOf(_sender) >= _amount, "Sender does not have enough tokens!");
        require(okToTransferTokens(_receiver, _amount), "Receiver not allowed to perform transfer!");
        return STATUS_ALLOWED;
    }

    /**
     * @notice Set the address of the FSP related to this Fund Token
     * @param _fspAddress The address of the FSP
     * @dev This method can only be called by the factory
     */
    function setFSPAddress(address _fspAddress) external onlyFactory override {
        require(fspAddress == address(0), "/fsp-address-already-set");
        fspAddress = _fspAddress;
    }


    // function checkMintAllowed (address, uint256) public pure override returns (bytes1) {
    //     // require(ATContract.isOperator(_minter), "Not Minter!");
    //     return STATUS_ALLOWED;
    // }

    // function checkBurnAllowed (address, uint256) public pure override returns (bytes1) {
    //     // default
    //     return STATUS_ALLOWED;
    // }

}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IToken {
    function getPaused() external view returns (bool);
    function pause() external;
    function unpause() external;
    function isImportedContract(address) external view returns (bool);
    function getImportedContractRate(address) external view returns (uint256);
    function setImportedContract(address, uint256) external;
    function checkTransferAllowed (address, address, uint256) external view returns (bytes1);
    function checkTransferFromAllowed (address, address, uint256) external view returns (bytes1);
    // function checkMintAllowed (address, uint256) external pure returns (bytes1);
    // function checkBurnAllowed (address, uint256) external pure returns (bytes1);
    function setFSPAddress (address) external;
    function okToReceiveTokens(address _recipient, uint256 _amountToAdd) external view returns (bool);
    function okToTransferTokens(address _holder, uint256 _amountToAdd) external view returns (bool);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IFundingSinglePanel {
    function getFactoryDeployIndex() external view returns(uint _deployIndex);
    // function changeTokenExchangeRate(uint256 _newExchRate) external;
    // function changeTokenExchangeOnTopRate(uint256 _newExchRateOnTop) external;
    function getOwnerData() external view returns (string memory _docURL, bytes32 _docHash);
    function setOwnerData(string calldata _docURL, bytes32 _docHash) external;
    function setEconomicData(uint256 _exchRate, 
            uint256 _exchRateOnTop,
            address _paymentTokenAddress, 
            uint256 _paymentTokenMinSupply, 
            uint256 _paymentTokenMaxSupply,
            uint256 _minSeedToHold,
            bool _shouldDepositSeedGuarantee) external;
    function setCampaignDuration(uint _campaignDurationBlocks) external;
    function getCampaignPeriod() external returns (uint256 _campStartingBlock, uint256 _campEndingBlock);
    // function setCashbackAddress(address _cashback) external returns (address _newCashbackAddr);
    // function setNewPaymentTokenMaxSupply(uint256 _newMaxPTSupply) external returns (uint256 _ptMaxSupply);
    function holderSendPaymentToken(uint256 _amount, address _receiver) external;
    function burnFundTokens(uint256 _amount) external;
    function importOtherTokens(address _tokenAddress, uint256 _tokenAmount) external;
    function getSentTokens(address _investor) external returns (uint256);
    function getTotalSentTokens() external returns (uint256 _amount);
    function setFSPFinanceable() external;
    // function isFSPFinanceable() external returns (bool _isFinanceable);
    function isCampaignOver() external returns (bool _isOver);
    function isCampaignSuccessful() external returns (bool _isSuccessful);
    function claimExitPaymentTokens(uint256 _amount) external returns (uint);
    function campaignExitFlag() external view returns (bool);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IAdminTools {
    function setFFSPAddresses(address, address) external;
    function setMinterAddress(address) external returns(address);
    function getMinterAddress() external view returns(address);
    function getWalletOnTopAddress() external view returns (address);
    function setWalletOnTopAddress(address) external returns(address);

    function addWLManagers(address) external;
    function removeWLManagers(address) external;
    function isWLManager(address) external view returns (bool);
    function addWLOperators(address) external;
    function removeWLOperators(address) external;
    function renounceWLManager() external;
    function isWLOperator(address) external view returns (bool);
    function renounceWLOperators() external;

    function addFundingManagers(address) external;
    function removeFundingManagers(address) external;
    function isFundingManager(address) external view returns (bool);
    function addFundingOperators(address) external;
    function removeFundingOperators(address) external;
    function renounceFundingManager() external;
    function isFundingOperator(address) external view returns (bool);
    function renounceFundingOperators() external;

    function addFundsUnlockerManagers(address) external;
    function removeFundsUnlockerManagers(address) external;
    function isFundsUnlockerManager(address) external view returns (bool);
    function addFundsUnlockerOperators(address) external;
    function removeFundsUnlockerOperators(address) external;
    function renounceFundsUnlockerManager() external;
    function isFundsUnlockerOperator(address) external view returns (bool);
    function renounceFundsUnlockerOperators() external;

    function isWhitelisted(address) external view returns(bool);
    function getWLThresholdEmissionAmount() external view returns (uint256);
    function getWLThresholdTransferAmount() external view returns (uint256);
    function getMaxEmissionAmount(address) external view returns(uint256);
    function getMaxTransferAmount(address) external view returns(uint256);
    function getWLLength() external view returns(uint256);
    function setNewEmissionThreshold(uint256) external;
    function setNewTransferThreshold(uint256) external;
    function changeMaxWLAmount(address, uint256, uint256) external;
    function addToWhitelist(address, uint256, uint256) external;
    function addToWhitelistMassive(address[] calldata, uint256[] calldata,  uint256[] calldata) external returns (bool);
    function removeFromWhitelist(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}