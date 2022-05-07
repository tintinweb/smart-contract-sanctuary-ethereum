// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Airdrop.sol";

interface IWASNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract WAS is ERC20, Airdrop, Ownable, IERC721Receiver {

    //Max supply control
    uint256 private _maxSupply;
    uint256 private _totalSupply;
    uint256 private _claimedTokens;
    
    //Airdrop status & related settings
    bool private _airdropEnabled;
    bool private _airdropExpired;
    address private _communityLiquidityAddress;
    //Addresses eligible for airdrop -- ovo mi mozda ne treba uopste, s obzirom da se vuce iz drugog contracta
    // mapping(address => uint256) private _airdrop;

    //Hell - Resurrection
    bool private _selfHellResurrectionStatus;
    bool private _hellResurrectionStatus;
    uint256 _publicResurrectionCost; //Cost of public resurrection in WAS utility tokens
    uint256 _selftResurrectionCost; //Cost of self-resurrection
    
    // Mapping of all Satoshis currently in hell / heaven - where the unit index is the satoshi #
    mapping(uint256 => bool) private _satoshisInHell;
    mapping(uint256 => bool) private _hellVersionSatoshis;
    mapping(uint256 => bool) private _heavenVersionSatoshis;
    mapping(uint256 => bool) private _restrictedSatoshis; //Unique and Flying satoshis can not be resurrected
    uint256[] private _resurrectedSatoshisHell; //Simple array holding all WAS NFT Ids ever resurrected in Hell State
    uint256[] private _resurrectedSatoshisHeaven; //Simple array holding all WAS NFT Ids ever resurrected in Heaven State


    //Fires when a genesis Satoshi is turned into Hell version Satoshi
    event SatoshiHellResurrection(uint256 satoshiId, address newOwner);

    //Fires when a genesis Satoshi is turned into Heaven version Satoshi
    event SatoshiHeavenResurrection(uint256 satoshiId, address newOwner);

    //Fires when a new genesis Satoshi is added to hell and is now available for public resurrection
    event SatoshiAddedToHell(uint256 satoshiId);

    //Control events fired on reciving a new NFT
    event incomingNftOperator(address operatorAddress);
    event incomingNftFrom(address fromAddress);
    event incomingNftId(uint256 nftId);

    //WAS NFT Smart contract and OS Satoshi Hell address
    address private _wasNFTSmartContract;
    address private _satoshiHellOSAddress;
    address private _vaultAddress;

    IWASNFT wasNFTContract = IWASNFT(_wasNFTSmartContract);

    constructor(uint256 maxTokenSupply, address wasNftScAddress, address satoshisHellOsAddress) ERC20("WAS Utility Token", "WAS") public {
        _maxSupply = maxTokenSupply * 1000000000000000000;
        _claimedTokens = 0;
        _airdropEnabled = true;
        _airdropExpired = false;
        _communityLiquidityAddress = 0x73C38e9975e648437b857aFf16Bc84df6F82d02B; //Ovo treba da se prebaci u metodu mozda
        _selfHellResurrectionStatus = true;
        _hellResurrectionStatus = true;
        _publicResurrectionCost = 25000000000000000000000; //i ovo mozda treba da ide u metodu
        _selftResurrectionCost = 100000000000000000000000;
        _wasNFTSmartContract = wasNftScAddress; // 0x3D13BFE69EE3357AA93a52fD27e56ab55f2471C7;
        _satoshiHellOSAddress = satoshisHellOsAddress;
        
        // Set restricted satoshis
        _restrictedSatoshis[1] = true;
        _restrictedSatoshis[4] = true;
        _restrictedSatoshis[191] = true;
        _restrictedSatoshis[350] = true;
        _restrictedSatoshis[587] = true;
        _restrictedSatoshis[78] = true;
        _restrictedSatoshis[989] = true;
        _restrictedSatoshis[204] = true;
        _restrictedSatoshis[570] = true;
        _restrictedSatoshis[122] = true;
        _restrictedSatoshis[923] = true;
    }

    // Airdrop methods
    //2do: max supply mora da se ispravi na private i total sypply se smanjuje kada se burnuje, ova metoda ne valja
    function claimAirdrop(address to)
    public
    {
        uint256 claimableAmount = getAirdropAmount(to);
        require(claimableAmount > 0,"This address is not eligible for WAS utility token airdrop.");
        require(_maxSupply >= (_claimedTokens + claimableAmount),"Invalid claim operation would exceed max token supply limit.");
        invalidateAirdrop(to);
        _claimedTokens = _claimedTokens + claimableAmount;
        _mint(to, claimableAmount);
        
    }

    function getClaimableTokensAmount(address to)
    public
    view
    returns (uint256)
    {
        uint256 claimableAmount = getAirdropAmount(to);
        return claimableAmount;
    }

    function setSelfResurrectionPrice(uint256 newPrice)
    public
    onlyOwner
    {
        _selftResurrectionCost = newPrice * 1000000000000000000;
    }

    function setPublicResurrectionPrice(uint256 newPrice)
    public
    onlyOwner 
    {
        _publicResurrectionCost = newPrice * 1000000000000000000;
    }

    function toggleAirdrop()
    public
    onlyOwner
    {
        _airdropEnabled = !_airdropEnabled;
    }

    // Mint all utility tokens that were not claimed during the airdrop and transer them to the community wallet.
    function expireAirdrop()
    public
    onlyOwner
    {
        require(_airdropEnabled == false, "Can not expire the airdrop until it's enabled.");
        require(_airdropExpired == false, "Airdrop already expired. Can not expire the airdrop again.");
        _airdropExpired = true;
        uint256 remainingTokens = _maxSupply - _claimedTokens;
        _mint(_communityLiquidityAddress, remainingTokens);
    }

    //If needed, to change the interfacing address for WAS NFT smart contract
    function setWasSmartContractAddress(address newSCAddress)
    public
    onlyOwner
    {
        _wasNFTSmartContract = newSCAddress;
    }

    function setSatoshisHellOsAddress(address newSatoshisHellOsAddresss)
    public
    onlyOwner 
    {
        _satoshiHellOSAddress = newSatoshisHellOsAddresss;
    }

    //How many tokens left?
    function getRemainingTokens()
    public
    view
    returns (uint256)
    {
        uint256 remainingTokens = _maxSupply - _claimedTokens;
        return remainingTokens;
    }


    //Satoshi Hell Resurrection Methods

    //This method is called by users to buy and resurrect Satoshis that are currently in hell
    function resurrectHellPublic(uint256 satoshiId, address tokenOwner)
    public
    {
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_satoshisInHell[satoshiId],"This Satoshi is not in Hell and it can not be resurrected.");
        require(_hellVersionSatoshis[satoshiId] == false, "This Satoshi is already a hell version");
        require(balanceOf(msg.sender) >= _publicResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");
        require(_vaultAddress == tokenOwner);

        _burn(msg.sender, _publicResurrectionCost);

        delete _satoshisInHell[satoshiId];
        _hellVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHell.push(satoshiId); //Record this Satoshi as Hell Version resurrection occured
        
        wasNFTContract.safeTransferFrom(tokenOwner, msg.sender, satoshiId);
        emit SatoshiHellResurrection(satoshiId,msg.sender);
    }

    //This method is called by users to self-resurrect Satoshis they own
    //This method should check if the sender owns the Satoshi being resurrected
    function selfResurrectHell(uint256 satoshiId)
    public
    {
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_hellVersionSatoshis[satoshiId] == false, "This Satoshi is already a hell version");
        require(balanceOf(msg.sender) >= _selftResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");
        _burn(msg.sender, _selftResurrectionCost);
        delete _satoshisInHell[satoshiId];
        _hellVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHell.push(satoshiId); //Record the ressurrection
        emit SatoshiHellResurrection(satoshiId,msg.sender);
    }


    // Heaven resurrection methods
    function resurrectHeavenPublic(uint256 satoshiId, address tokenOwner)
    public
    {
        //Is satoshi already a hell version?
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_hellVersionSatoshis[satoshiId] == true, "Satoshi must be a hell version before turning it to heaven version");
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into heaven Satoshi.");
        //Is satoshi in hell / available for resurrection?
        require(_satoshisInHell[satoshiId] == true,"This Satoshi is not in Hell and it can not be resurrected.");
        require(_vaultAddress == tokenOwner);
        //Does sender have enough funds to resurrect this Satoshi?
        require(balanceOf(msg.sender) >= _publicResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        // Burn the resurrection payment
        _burn(msg.sender, _publicResurrectionCost);

        //Remove Satoshi from hell and list of hell version Satoshis
        delete _satoshisInHell[satoshiId];
        delete _hellVersionSatoshis[satoshiId];

        //Move satoshi to the list of heaven version satoshis
        _heavenVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHeaven.push(satoshiId);

       wasNFTContract.safeTransferFrom(tokenOwner, msg.sender, satoshiId);
        
        //Notify the world about this resurrection
        emit SatoshiHeavenResurrection(satoshiId,msg.sender);
    }

    function selfResurrectHeaven(uint256 satoshiId)
    public
    {
        //Is satoshi already a hell version?
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_hellVersionSatoshis[satoshiId] == true, "Satoshi must be a hell version before turning it to heaven version");
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into heaven Satoshi.");

        //Does sender have enough funds to resurrect this Satoshi?
        require(balanceOf(msg.sender) >= _selftResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        // Burn the resurrection payment
        _burn(msg.sender, _selftResurrectionCost);

        //Remove Satoshi from the list of hell version satoshis
        delete _hellVersionSatoshis[satoshiId];

        //Move satoshi to the list of heaven version satoshis
        _heavenVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHeaven.push(satoshiId);
        
        //Notify the world about this resurrection
        emit SatoshiHeavenResurrection(satoshiId,msg.sender);
    }

    /**
        H&H utility methods
     */
    function setVaultAddress(address vaultAddress)
    public
    onlyOwner 
    {
        _vaultAddress = vaultAddress;
    }
    function manualAddSatoshiToHell(uint256 satoshiId)
    public
    onlyOwner 
    {
        _addSatoshiToHell(satoshiId);
    }

    function _addSatoshiToHell(uint256 satoshiId)
    internal 
    {
        require(satoshiId <= 1024,"Satoshi outside of the NFT collection size.");
        require(satoshiId > 0,"Satoshi outside of the NFT collection size.");
        require(_satoshisInHell[satoshiId] == false,"Satoshi already in hell.");
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
         
        _satoshisInHell[satoshiId] = true;
        emit SatoshiAddedToHell(satoshiId);
    }

    function isSatoshiInHell(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _satoshisInHell[satoshiId];
    }


/////////////////// OVDE
    function getResurrectedSatoshisHell()
    external
    view
    returns(uint256[] memory) {
        return _resurrectedSatoshisHell;
    }

    function getResurrectedSatoshisHeaven()
    external
    view
    returns(uint256[] memory) {
        return _resurrectedSatoshisHeaven;
    }

    function isSatoshiHellVersion(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _hellVersionSatoshis[satoshiId];
    }

    function isSatoshiHeavenVersion(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _heavenVersionSatoshis[satoshiId];
    }

    function setSatoshiHellOsAddress(address shAddress)
    public
    onlyOwner
    {
        _satoshiHellOSAddress = shAddress;
    }

    //Only accept satoshis from WAS OS Satoshi Hell wallet
    function onERC721Received(address operator, address from, uint256 satoshiId, bytes memory)
    public
    virtual
    override
    returns (bytes4) {
        require(from == _satoshiHellOSAddress, "No thank you, I am not sure this is a WAS NFT.");
        if (from == _satoshiHellOSAddress) {
            _addSatoshiToHell(satoshiId);
            emit incomingNftOperator(operator);
            emit incomingNftFrom(from);
            emit incomingNftId(satoshiId);
            return this.onERC721Received.selector;
      //      return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
contract Airdrop {
    mapping(address => uint256) private _airdrop;
	constructor() {
        _airdrop[0x35246183CAC7081048c88eDF87453713A707987e] = 1000000000000000000000000;
        _airdrop[0x70224f4E69f0FE6084cD9719fAc5fE46CEB3E9e0] = 1000000000000000000000000;
        _airdrop[0x2e3f86a333438f8deAf408340828ABF92a2d021A] = 1000000000000000000000000;
        _airdrop[0xD3600d3A5cbEE1589cf390A14741E3A32126Ebbb] = 1000000000000000000000000;
	}

    function invalidateAirdrop(address airdropAddress) 
    internal
    {
        delete _airdrop[airdropAddress];
    }

    function getAirdropAmount(address to)
    internal
    view
    returns (uint256)
    {
        return _airdrop[to];
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