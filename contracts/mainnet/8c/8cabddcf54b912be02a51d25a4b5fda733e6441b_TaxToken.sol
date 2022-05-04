//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { ITreasury, IUniswapV2Factory, IUniswapV2Router01 } from "./ERC20.sol";

/// @dev    The TaxToken is responsible for supporting generic ERC20 functionality including ERC20Pausable functionality.
///         The TaxToken will generate taxes on transfer() and transferFrom() calls for non-whitelisted addresses.
///         The Admin can specify the tax fee in basis points for buys, sells, and transfers.
///         The TaxToken will forward all taxes generated to a Treasury
contract TaxToken {
 
    // ---------------
    // State Variables
    // ---------------

    // ERC20 Basic
    uint256 _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    // ERC20 Pausable
    bool private _paused;  // ERC20 Pausable state

    // Extras
    address public owner;
    address public treasury;
    address public UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public taxesRemoved;   /// @dev Once true, taxes are permanently set to 0 and CAN NOT be increased in the future.

    uint256 public maxWalletSize;
    uint256 public maxTxAmount;

    // ERC20 Mappings
    mapping(address => uint256) balances;                       // Track balances.
    mapping(address => mapping(address => uint256)) allowed;    // Track allowances.

    // Extras Mappings
    mapping(address => bool) public blacklist;          /// @dev If an address is blacklisted, they cannot perform transfer() or transferFrom().
    mapping(address => bool) public whitelist;          /// @dev Any transfer that involves a whitelisted address, will not incur a tax.
    mapping(address => uint) public senderTaxType;      /// @dev  Identifies tax type for msg.sender of transfer() call.
    mapping(address => uint) public receiverTaxType;    /// @dev  Identifies tax type for _to of transfer() call.
    mapping(uint => uint) public basisPointsTax;        /// @dev  Mapping between taxType and basisPoints (taxed).



    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the TaxToken.
    /// @param  totalSupplyInput    The total supply of this token (this value is multipled by 10**decimals in constructor).
    /// @param  nameInput           The name of this token.
    /// @param  symbolInput         The symbol of this token.
    /// @param  decimalsInput       The decimal precision of this token.
    /// @param  maxWalletSizeInput  The maximum wallet size (this value is multipled by 10**decimals in constructor).
    /// @param  maxTxAmountInput    The maximum tx size (this value is multipled by 10**decimals in constructor).
    constructor(
        uint totalSupplyInput, 
        string memory nameInput, 
        string memory symbolInput, 
        uint8 decimalsInput,
        uint256 maxWalletSizeInput,
        uint256 maxTxAmountInput
    ) {
        _paused = false;    // ERC20 Pausable global state variable, initial state is not paused ("unpaused").
        _name = nameInput;
        _symbol = symbolInput;
        _decimals = decimalsInput;
        _totalSupply = totalSupplyInput * 10**_decimals;

        // Create a uniswap pair for this new token
        address UNISWAP_V2_PAIR = IUniswapV2Factory(
            IUniswapV2Router01(UNIV2_ROUTER).factory()
        ).createPair(address(this), IUniswapV2Router01(UNIV2_ROUTER).WETH());
 
        senderTaxType[UNISWAP_V2_PAIR] = 1;
        receiverTaxType[UNISWAP_V2_PAIR] = 2;

        owner = msg.sender;                                         // The "owner" is the "admin" of this contract.
        balances[msg.sender] = totalSupplyInput * 10**_decimals;    // Initial liquidity, allocated entirely to "owner".
        maxWalletSize = maxWalletSizeInput * 10**_decimals;
        maxTxAmount = maxTxAmountInput * 10**_decimals;      
    }

 

    // ---------
    // Modifiers
    // ---------

    /// @dev whenNotPausedUni() is used if the contract MUST be paused ("paused").
    modifier whenNotPausedUni(address a) {
        require(!paused() || whitelist[a], "ERR: Contract is currently paused.");
        _;
    }

    /// @dev whenNotPausedDual() is used if the contract MUST be paused ("paused").
    modifier whenNotPausedDual(address from, address to) {
        require(!paused() || whitelist[from] || whitelist[to], "ERR: Contract is currently paused.");
        _;
    }

    /// @dev whenNotPausedTri() is used if the contract MUST be paused ("paused").
    modifier whenNotPausedTri(address from, address to, address sender) {
        require(!paused() || whitelist[from] || whitelist[to] || whitelist[sender], "ERR: Contract is currently paused.");
        _;
    }

    /// @dev whenPaused() is used if the contract MUST NOT be paused ("unpaused").
    modifier whenPaused() {
        require(paused(), "ERR: Contract is not currently paused.");
        _;
    }
    
    /// @dev onlyOwner() is used if msg.sender MUST be owner.
    modifier onlyOwner {
       require(msg.sender == owner, "ERR: TaxToken.sol, onlyOwner()"); 
       _;
    }



    // ------
    // Events
    // ------

    event Paused(address account);          /// @dev Emitted when the pause is triggered by `account`.
    event Unpaused(address account);        /// @dev Emitted when the pause is lifted by `account`.

    /// @dev Emitted when approve() is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);   
 
    /// @dev Emitted during transfer() or transferFrom().
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event TransferTax(address indexed _from, address indexed _to, uint256 _value, uint256 _taxType);



    // ---------
    // Functions
    // ---------


    // ~ ERC20 View ~
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    // ~ ERC20 transfer(), transferFrom(), approve() ~

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function transfer(address _to, uint256 _amount) public whenNotPausedDual(msg.sender, _to) returns (bool success) {  

        // taxType 0 => Xfer Tax
        // taxType 1 => Buy Tax
        // taxType 2 => Sell Tax
        uint _taxType;

        if (balances[msg.sender] >= _amount && (!blacklist[msg.sender] && !blacklist[_to])) {

            // Take a tax from them if neither party is whitelisted.
            if (!whitelist[_to] && !whitelist[msg.sender] && _amount <= maxTxAmount) {

                // Determine, if not the default 0, tax type of transfer.
                if (senderTaxType[msg.sender] != 0) {
                    _taxType = senderTaxType[msg.sender];
                }

                if (receiverTaxType[_to] != 0) {
                    _taxType = receiverTaxType[_to];
                }

                // Calculate taxAmt and sendAmt.
                uint _taxAmt = _amount * basisPointsTax[_taxType] / 10000;
                uint _sendAmt = _amount * (10000 - basisPointsTax[_taxType]) / 10000;

                if (balances[_to] + _sendAmt <= maxWalletSize) {

                    balances[msg.sender] -= _amount;
                    balances[_to] += _sendAmt;
                    balances[treasury] += _taxAmt;

                    require(_taxAmt + _sendAmt >= _amount * 999999999 / 1000000000, "Critical error, math.");
                
                    // Update accounting in Treasury.
                    ITreasury(treasury).updateTaxesAccrued(
                        _taxType, _taxAmt
                    );
                    
                    emit Transfer(msg.sender, _to, _sendAmt);
                    emit TransferTax(msg.sender, treasury, _taxAmt, _taxType);

                    return true;
                }

                else {
                    return false;
                }

            }

            else if (!whitelist[_to] && !whitelist[msg.sender] && _amount > maxTxAmount) {
                return false;
            }

            else {
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;
                emit Transfer(msg.sender, _to, _amount);
                return true;
            }
        }
        else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _amount) public whenNotPausedTri(_from, _to, msg.sender) returns (bool success) {

        // taxType 0 => Xfer Tax
        // taxType 1 => Buy Tax
        // taxType 2 => Sell Tax
        uint _taxType;

        if (
            balances[_from] >= _amount && 
            allowed[_from][msg.sender] >= _amount && 
            _amount > 0 && balances[_to] + _amount > balances[_to] && 
            _amount <= maxTxAmount && (!blacklist[_from] && !blacklist[_to])
        ) {
            
            // Reduce allowance.
            allowed[_from][msg.sender] -= _amount;

            // Take a tax from them if neither party is whitelisted.
            if (!whitelist[_to] && !whitelist[_from] && _amount <= maxTxAmount) {

                // Determine, if not the default 0, tax type of transfer.
                if (senderTaxType[_from] != 0) {
                    _taxType = senderTaxType[_from];
                }

                if (receiverTaxType[_to] != 0) {
                    _taxType = receiverTaxType[_to];
                }

                // Calculate taxAmt and sendAmt.
                uint _taxAmt = _amount * basisPointsTax[_taxType] / 10000;
                uint _sendAmt = _amount * (10000 - basisPointsTax[_taxType]) / 10000;

                if (balances[_to] + _sendAmt <= maxWalletSize || _taxType == 2) {

                    balances[_from] -= _amount;
                    balances[_to] += _sendAmt;
                    balances[treasury] += _taxAmt;

                    require(_taxAmt + _sendAmt == _amount, "Critical error, math.");
                
                    // Update accounting in Treasury.
                    ITreasury(treasury).updateTaxesAccrued(
                        _taxType, _taxAmt
                    );
                    
                    emit Transfer(_from, _to, _sendAmt);
                    emit TransferTax(_from, treasury, _taxAmt, _taxType);

                    return true;
                }
                
                else {
                    return false;
                }

            }

            else if (!whitelist[_to] && !whitelist[_from] && _amount > maxTxAmount) {
                return false;
            }

            // Skip taxation if either party is whitelisted (_from or _to).
            else {
                balances[_from] -= _amount;
                balances[_to] += _amount;
                emit Transfer(_from, _to, _amount);
                return true;
            }

        }
        else {
            return false;
        }
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    // ~ ERC20 Pausable ~

    /// @notice Pause the contract, blocks transfer() and transferFrom().
    /// @dev    Contract MUST NOT be paused to call this, caller must be "owner".
    function pause() public onlyOwner whenNotPausedUni(msg.sender) {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause the contract.
    /// @dev    Contract MUST be puased to call this, caller must be "owner".
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @return _paused Indicates whether the contract is paused (true) or not paused (false).
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    // ~ TaxType & Fee Management ~

    /// @notice     Used to store the LP Pair to differ type of transaction. Will be used to mark a BUY.
    /// @dev        _taxType must be lower than 3 because there can only be 3 tax types; buy, sell, & send.
    /// @param      _sender This value is the PAIR address.
    /// @param      _taxType This value must be be 0, 1, or 2. Best to correspond value with the BUY tax type.
    function updateSenderTaxType(address _sender, uint _taxType) public onlyOwner {
        require(_taxType < 3, "err _taxType must be less than 3");
        senderTaxType[_sender] = _taxType;
    }

    /// @notice     Used to store the LP Pair to differ type of transaction. Will be used to mark a SELL.
    /// @dev        _taxType must be lower than 3 because there can only be 3 tax types; buy, sell, & send.
    /// @param      _receiver This value is the PAIR address.
    /// @param      _taxType This value must be be 0, 1, or 2. Best to correspond value with the SELL tax type.
    function updateReceiverTaxType(address _receiver, uint _taxType) public onlyOwner {
        require(_taxType < 3, "err _taxType must be less than 3");
        receiverTaxType[_receiver] = _taxType;
    }

    /// @notice     Used to map the tax type 0, 1 or 2 with it's corresponding tax percentage.
    /// @dev        Must be lower than 2000 which is equivalent to 20%.
    /// @param      _taxType This value is the tax type. Has to be 0, 1, or 2.
    /// @param      _bpt This is the corresponding percentage that is taken for royalties. 1200 = 12%.
    function adjustBasisPointsTax(uint _taxType, uint _bpt) public onlyOwner {
        require(_bpt <= 2000, "err TaxToken.sol _bpt > 2000 (20%)");
        require(!taxesRemoved, "err TaxToken.sol taxation has been removed");
        basisPointsTax[_taxType] = _bpt;
    }

    /// @notice Permanently remove taxes from this contract.
    /// @dev    An input is required here for sanity-check, given importance of this function call (and irreversible nature).
    /// @param  _key This value MUST equal 42 for function to execute.
    function permanentlyRemoveTaxes(uint _key) public onlyOwner {
        require(_key == 42, "err TaxToken.sol _key != 42");
        basisPointsTax[0] = 0;
        basisPointsTax[1] = 0;
        basisPointsTax[2] = 0;
        taxesRemoved = true;
    }


    // ~ Admin ~

    /// @notice This is used to change the owner's wallet address. Used to give ownership to another wallet.
    /// @param  _owner is the new owner address.
    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }

    /// @notice Set the treasury (contract)) which receives taxes generated through transfer() and transferFrom().
    /// @param  _treasury is the contract address of the treasury.
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    /// @notice Adjust maxTxAmount value (maximum amount transferrable in a single transaction).
    /// @dev    Does not affect whitelisted wallets.
    /// @param  _maxTxAmount is the max amount of tokens that can be transacted at one time for a non-whitelisted wallet.
    function updateMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = (_maxTxAmount * 10**_decimals);
    }

    /// @notice This function is used to set the max amount of tokens a wallet can hold.
    /// @dev    Does not affect whitelisted wallets.
    /// @param  _maxWalletSize is the max amount of tokens that can be held on a non-whitelisted wallet.
    function updateMaxWalletSize(uint256 _maxWalletSize) public onlyOwner {
        maxWalletSize = (_maxWalletSize * 10**_decimals);
    }

    /// @notice This function is used to add wallets to the whitelist mapping.
    /// @dev    Whitelisted wallets are not affected by maxWalletSize, maxTxAmount, and taxes.
    /// @param  _wallet is the wallet address that will have their whitelist status modified.
    /// @param  _whitelist use True to whitelist a wallet, otherwise use False to remove wallet from whitelist.
    function modifyWhitelist(address _wallet, bool _whitelist) public onlyOwner {
        whitelist[_wallet] = _whitelist;
    }

    /// @notice This function is used to add or remove wallets from the blacklist.
    /// @dev    Blacklisted wallets cannot perform transfer() or transferFrom().
    /// @param  _wallet is the wallet address that will have their blacklist status modified.
    /// @param  _blacklist use True to blacklist a wallet, otherwise use False to remove wallet from blacklist.
    function modifyBlacklist(address _wallet, bool _blacklist) public onlyOwner {
        blacklist[_wallet] = _blacklist;
    }
    
}