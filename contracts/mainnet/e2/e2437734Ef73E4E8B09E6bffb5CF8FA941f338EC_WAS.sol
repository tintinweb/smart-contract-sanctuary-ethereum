// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Airdrop.sol";

interface IWASNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

contract WAS is ERC20, Airdrop, Ownable, IERC721Receiver {
    //Master switch
    bool private _isContractActive;

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

    //Fires on public resurrections
    event PublicResurrection(uint256 satoshiId, address resurrectorAddress);

    //Control events fired on reciving a new NFT
    event incomingNftOperator(address operatorAddress);
    event incomingNftFrom(address fromAddress);
    event incomingNftId(uint256 nftId);
    event incomingNftOwner(address nftOwnerAddress);

    //WAS NFT Smart contract and OS Satoshi Hell address
    address private _wasNFTSmartContract;
    address private _satoshiHellOSAddress;

    IWASNFT wasNFTContract = IWASNFT(_wasNFTSmartContract);

    constructor(uint256 maxTokenSupply, address wasNftScAddress, address satoshisHellOsAddress, address communityLiquidityAddress) ERC20("WAS Utility Token", "WAS") public {
        _isContractActive = true;
        _maxSupply = maxTokenSupply * 1000000000000000000;
        _claimedTokens = 0;
        _airdropEnabled = true;
        _airdropExpired = false;
        _communityLiquidityAddress = communityLiquidityAddress; //Ovo treba da se prebaci u metodu mozda
        _selfHellResurrectionStatus = true;
        _hellResurrectionStatus = true;
        _publicResurrectionCost = 25000000000000000000000; //i ovo mozda treba da ide u metodu
        _selftResurrectionCost = 100000000000000000000000;
        _wasNFTSmartContract = wasNftScAddress;
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
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        uint256 claimableAmount = getAirdropAmount(to);
        require(claimableAmount > 0,"This address is not eligible for WAS utility token airdrop.");
        require(_airdropEnabled, "Sorry, WAS utility token airdrop claiming is not enabled at the moment.");
        require(_airdropExpired == false, "Sorry, WAS utility airdrop claiming window has expired.");
        require(_maxSupply >= (_claimedTokens + claimableAmount),"Invalid claim operation would exceed max token supply limit.");
        invalidateAirdrop(to);
        _claimedTokens = _claimedTokens + claimableAmount;
        _mint(to, claimableAmount);
        if (_claimedTokens == _maxSupply) {
            _airdropExpired = true;
            _airdropEnabled = false;
        }
    }

    function getClaimableTokensAmount(address to)
    public
    view
    returns (uint256)
    {
        uint256 claimableAmount = 0;
        if (_airdropExpired == false && _airdropEnabled) {
            claimableAmount = getAirdropAmount(to);
        }
        return claimableAmount;
    }

    /**
    * Resurrection methods
    */

    //This method is called by users to buy and resurrect Satoshis that are currently in hell
    function resurrectHellPublic(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into hell Satoshi.");
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_satoshisInHell[satoshiId],"This Satoshi is not in Hell and it can not be resurrected.");
        require(_hellVersionSatoshis[satoshiId] == false, "This Satoshi is already a hell version.");
        require(balanceOf(msg.sender) >= _publicResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        _burn(msg.sender, _publicResurrectionCost);

        delete _satoshisInHell[satoshiId];
        _hellVersionSatoshis[satoshiId] = true;
        _resurrectedSatoshisHell.push(satoshiId); //Record this Satoshi as Hell Version resurrection occured
        IWASNFT(_wasNFTSmartContract).safeTransferFrom(address(this), msg.sender, satoshiId);
        //wasNFTContract.safeTransferFrom(tokenOwner, msg.sender, satoshiId);
        emit SatoshiHellResurrection(satoshiId,msg.sender);
        emit PublicResurrection(satoshiId,msg.sender);
    }

    //This method is called by users to self-resurrect Satoshis they own
    //This method should check if the sender owns the Satoshi being resurrected
    function selfResurrectHell(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        //You can not turn heaven Satoshis into hell Satoshis
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into hell Satoshi.");
        //You can not turn unique and super rare satoshis into hell Satoshis
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        //You can not turn hell Satoshis into hell Satoshis
        require(_hellVersionSatoshis[satoshiId] == false, "This Satoshi is already a hell version");
        //You need to have enough WAS tokens to resurrect a Satoshi
        require(balanceOf(msg.sender) >= _selftResurrectionCost, "You do not have enough tokens to resurrect this Satoshi.");
        //You must own this Satoshi
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == msg.sender, "You must own the Satoshi you wish to resurrect.");
        
        
        // Burn utility tokens for the resurrection
        _burn(msg.sender, _selftResurrectionCost);

        //Add this Satoshi to the map of hell version Satoshis
        _hellVersionSatoshis[satoshiId] = true;
        
        //Make a public record of this resurrection (needed for metadarta conversion)
        _resurrectedSatoshisHell.push(satoshiId); //Record the ressurrection

        //Resurrection completed, emit the event
        emit SatoshiHellResurrection(satoshiId,msg.sender);
    }

    // Heaven resurrection methods
    function resurrectHeavenPublic(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        //You can not turn unique and super rare satoshis into heaven Satoshis
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");

        //You can only turn hell Satoshi into heaven Satoshis
        require(_hellVersionSatoshis[satoshiId] == true, "Satoshi must be a hell version before turning it to heaven version");
        
        //You can not turn heaven Satoshis into heaven Satoshis
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into heaven Satoshi.");
        
        //Is satoshi in hell / available for resurrection?
        require(_satoshisInHell[satoshiId] == true,"This Satoshi is not in Hell and it can not be resurrected.");
        
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

        //Transfer the resurrected Satoshi to the resurrector
        IWASNFT(_wasNFTSmartContract).safeTransferFrom(address(this), msg.sender, satoshiId);
        
        //Notify the world about this resurrection
        emit SatoshiHeavenResurrection(satoshiId,msg.sender);
        emit PublicResurrection(satoshiId,msg.sender);
    }

    function selfResurrectHeaven(uint256 satoshiId)
    public
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");

        //You can not turn unique and super rare satoshis into heaven Satoshis
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");

        //You can only turn hell Satoshis into heaven Satoshis
        require(_hellVersionSatoshis[satoshiId] == true, "Satoshi must be a hell version before turning it to heaven version");
        
        //You can not turn heaven Satoshis into heaven Satoshis
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not turn a heaven Satoshi into heaven Satoshi.");

        //Does sender have enough funds to resurrect this Satoshi?
        require(balanceOf(msg.sender) >= _selftResurrectionCost, "You do not have enough tokens to resurrect this Satoshi");

        //You must own this Satoshi
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == msg.sender, "You must own the Satoshi you wish to resurrect.");
        

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

    function _addSatoshiToHell(uint256 satoshiId)
    internal 
    {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");
        require(satoshiId <= 1024,"Satoshi outside of the NFT collection size.");
        require(satoshiId > 0,"Satoshi outside of the NFT collection size.");
        require(_satoshisInHell[satoshiId] == false,"Satoshi already in hell.");
        require(_restrictedSatoshis[satoshiId] == false, "Resurrection of this Satoshi is restricted.");
        require(_heavenVersionSatoshis[satoshiId] == false,"Can not add heaven Satoshis to hell.");
         
        _satoshisInHell[satoshiId] = true;
        emit SatoshiAddedToHell(satoshiId);
    }

    //Only accept satoshis from WAS OS Satoshi Hell wallet
    function onERC721Received(address operator, address from, uint256 satoshiId, bytes memory)
    public
    virtual
    override
    returns (bytes4) {
        require(_isContractActive, "We'll be back in 5. (Contract is not active at this moment)");
        require(from == _satoshiHellOSAddress, "No thank you, I am not sure this is a WAS NFT.");
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == address(this), "This Satoshi does not belong to this smart contract.");
       
        if (from == _satoshiHellOSAddress) {
            _addSatoshiToHell(satoshiId);
            emit incomingNftOperator(operator);
            emit incomingNftFrom(from);
            emit incomingNftId(satoshiId);
            return this.onERC721Received.selector;
        }
    }


    /**
    * Setters
    * The methods below are ownerOnly methods used to configure various properties of the smart contract.
    * These methods are also used to control various states of the contract.
    */
    function manualAddSatoshiToHell(uint256 satoshiId)
    public
    onlyOwner 
    {
        require(IWASNFT(_wasNFTSmartContract).ownerOf(satoshiId) == address(this), "This Satoshi does not belong to this smart contract.");
        _addSatoshiToHell(satoshiId);
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

    function toggleContract()
    public
    onlyOwner
    {
        _isContractActive = !_isContractActive;
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
        if (remainingTokens > 0) {
            _mint(_communityLiquidityAddress, remainingTokens);
            _claimedTokens = _claimedTokens + remainingTokens;
        }
    }

    function setCommunityLiquidityAddress(address newCommunityAddress)
    public
    onlyOwner
    {
        _communityLiquidityAddress = newCommunityAddress;
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






    // Public getters
    /**
    * The methods below are used to get/read various internal vars/information from the contract.
    */
    function isSatoshiInHell(uint256 satoshiId)
    public
    view
    returns (bool)
    {
        return _satoshisInHell[satoshiId];
    }

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

    function getMaxSupply()
    public
    view
    returns (uint256) {
        return _maxSupply;
    }

    function getTotalTokensClaimed()
    public
    view
    returns(uint256)
    {
        return _claimedTokens;
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

    function getAirdropStatus()
    public
    view
    returns (bool)
    {
        return _airdropEnabled;
    }

    function getPublicResurrectionCost()
    public
    view
    returns(uint256) {
        return _publicResurrectionCost;
    }

    function getSelfResurrectionCost()
    public
    view
    returns(uint256) {
        return _selftResurrectionCost;
    }

    function getWASNftContract()
    public
    view
    returns(address) {
        return _wasNFTSmartContract;
    }

    function getWasCommunityWallet()
    public
    view
    returns(address)
    {
        return _communityLiquidityAddress;
    }

    function getWasOsHellAddress()
    public
    view
    returns(address)
    {
        return _satoshiHellOSAddress;
    }

    function getContractState()
    public
    view
    returns(bool)
    {
        return _isContractActive;
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
        _airdrop[0x48E0Bb3A663529887982B94787E9E6C7fc497449] = 30000000000000000000000;
        _airdrop[0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9] = 50000000000000000000000;
        _airdrop[0x204Ce9E684DdCEADaEfbBB0d5A4bC7eb481b57E4] = 50000000000000000000000;
        _airdrop[0x63EE9d3BF50bD5315E53Cd2C723719e6Cf0e3C96] = 30000000000000000000000;
        _airdrop[0x7358B3dD144332377c14D8A47844E05A1b6f50aC] = 10000000000000000000000;
        _airdrop[0x615dd68D8254a0D29b212A5Be73b00674D540c02] = 10000000000000000000000;
        _airdrop[0xDf3759cc2277aDcDB0a97b8AC1469a6EddBC6A8d] = 10000000000000000000000;
        _airdrop[0x64C9fb6C978f0f5dd46CB36325b56c04243bAB75] = 30000000000000000000000;
        _airdrop[0xa4D26fC0814a8dacef55A79166291DD0898a8194] = 20000000000000000000000;
        _airdrop[0xA4f6F09F546e2B0E160906564DD8e396c891318F] = 40000000000000000000000;
        _airdrop[0xb9C5878a4891942C43A20b11C53a76961426bAD2] = 50000000000000000000000;
        _airdrop[0xA23A702Df9d7a2b5C7c2Aa87Df295F85A4CE3ac3] = 10000000000000000000000;
        _airdrop[0xcAC21e79De5FAc9FcA03fbe3cE050B9116689eB2] = 90000000000000000000000;
        _airdrop[0x1e27F3175a52877CC8C4e3115B2669037381DeDc] = 50000000000000000000000;
        _airdrop[0x017395053f29De984F0bB008C20A99365CD9172c] = 10000000000000000000000;
        _airdrop[0xF0ba012eC6090369E623eE5EE8a3D3A99e2977b2] = 20000000000000000000000;
        _airdrop[0xF2E81438e26FcE88cC8deBf8C178b80A506cE435] = 50000000000000000000000;
        _airdrop[0xb1D610fB451b5cdee4eADcA4538816122ad40E1d] = 70000000000000000000000;
        _airdrop[0x2d907A917Dc848843Cc3397D4a9d3B10023fDeE4] = 10000000000000000000000;
        _airdrop[0x8cD0E99c9ED5D40cE84737Bf9C9969C6b7c13a53] = 10000000000000000000000;
        _airdrop[0x4384293860C81Dc6a8A248a648B6dCa35fF3aA33] = 70000000000000000000000;
        _airdrop[0xBD513191C04051fC789BC0274095b8137ec2C790] = 20000000000000000000000;
        _airdrop[0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2] = 90000000000000000000000;
        _airdrop[0xD53B7F0bf1f1ccd199B46BE2fE79087154EFcdDA] = 10000000000000000000000;
        _airdrop[0x3052Dd6cFC8A09611D4d3d2430Ff5d8F43B2A22b] = 30000000000000000000000;
        _airdrop[0x0E862E0F9dFc849F95a0B5D64D5f16295373ff92] = 10000000000000000000000;
        _airdrop[0x2476c7F826339679dD3CfAFCaD72fA2fFa700b9d] = 60000000000000000000000;
        _airdrop[0x405EB35A58a0C88d9E193D4cB7e61c4Adf2fbcdF] = 30000000000000000000000;
        _airdrop[0xa214c5d496e7Dfa5c4DD3df5F6500b00aD746E96] = 20000000000000000000000;
        _airdrop[0x97874cf634457f07E7f1888C5C47D70DFAA542cb] = 80000000000000000000000;
        _airdrop[0x2e76E93931238E2eDFc245f16BD96f8779e21B51] = 80000000000000000000000;
        _airdrop[0x72a0726Ae7a9054476a8C7E759962A4dA667175F] = 30000000000000000000000;
        _airdrop[0x45BB3A3f57061f590Fa8AB7170D60f0C95Ce6eeB] = 10000000000000000000000;
        _airdrop[0xE008C844625CE7Eb4528d5E17fC2B6D782582cA7] = 10000000000000000000000;
        _airdrop[0xA219F044dc6d726f61249c7279EcFa457D6Aaea2] = 20000000000000000000000;
        _airdrop[0xA7bD22BcFC1eAE5f9944978d81ff71Bd5f5eAF42] = 20000000000000000000000;
        _airdrop[0xFD8E43431Bcdc2b42a28A95818077af7924c8F83] = 70000000000000000000000;
        _airdrop[0x6cb603c1967a32bb7b0726EcbCbB8c3A16b1c299] = 60000000000000000000000;
        _airdrop[0x5c4668d494C6Af375a20782727Ec2084605DDB64] = 30000000000000000000000;
        _airdrop[0x034B76cb6539F40be7853FD3F76aeb69E6A62677] = 30000000000000000000000;
        _airdrop[0x81083379a8c41501B39986D5C74428Dd618EB440] = 30000000000000000000000;
        _airdrop[0x7F2a2d2B16e889f954C79ec67CD42c2d4A1524Ee] = 30000000000000000000000;
        _airdrop[0xBa94281fC202399b77daC078722548Bd0faDB530] = 100000000000000000000000;
        _airdrop[0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2] = 100000000000000000000000;
        _airdrop[0x8951A87Adf50b555034B47D103875A1613B003B6] = 10000000000000000000000;
        _airdrop[0xf4015e422b95255671F4338B0a0819cfcDFC3517] = 10000000000000000000000;
        _airdrop[0x4bb74e3F27A41f0cC58A1696D61EFd4E4A754eD7] = 180000000000000000000000;
        _airdrop[0x197d43E5E7A3F662FEFF43119654AF1d6C7852E0] = 10000000000000000000000;
        _airdrop[0xBFc007C6D7dEb895643bf457060519137BbD2C8C] = 30000000000000000000000;
        _airdrop[0x3D75392bF1aC7C0617e639DCb5F58a156BE74fF8] = 10000000000000000000000;
        _airdrop[0x537DB9f04E5Be41dDE98d2684E0576638de3bF3D] = 10000000000000000000000;
        _airdrop[0xaEabe7513BB61325E22c0D7Fd7B2804b3e2C9C28] = 20000000000000000000000;
        _airdrop[0x7cA7Db1299e7Da45aBB55d274A18ec6eA53d66b8] = 60000000000000000000000;
        _airdrop[0xb87E63c791568E2ebE4b6E2DdB8a078F5B0B6BA5] = 100000000000000000000000;
        _airdrop[0x8093dda1fEdAC34a23540D6E75831800Dd9ea77A] = 60000000000000000000000;
        _airdrop[0x38aB518405bF4F84Add1508819d3beEe005976dB] = 50000000000000000000000;
        _airdrop[0x369DCD945f2ec96EFC489D9541b47cCa9594E9Fc] = 10000000000000000000000;
        _airdrop[0x2C42E8F3dBA3C17E765702FbC6918DeFeb76cd5f] = 10000000000000000000000;
        _airdrop[0x38c05b9B18f8B512CFDCE9bCFD0e57030344f602] = 20000000000000000000000;
        _airdrop[0xf98a9aCC1aAd53Abe8fD91A9BeB4537845960C76] = 40000000000000000000000;
        _airdrop[0xB0B7aBccD78a560955eaD86a34eae2F0B6f0199E] = 20000000000000000000000;
        _airdrop[0xdc90C6705c148e28970b108Efd1b5d4B5DAa0e46] = 10000000000000000000000;
        _airdrop[0x9309F2Ed55De312FDf51368593db75dE39369173] = 20000000000000000000000;
        _airdrop[0x72988B423c86afed473278E8d19a79456C404995] = 70000000000000000000000;
        _airdrop[0xA14B8d5E0687e63F9991E85DC17287f17d858731] = 10000000000000000000000;
        _airdrop[0x75AbF28b9CAe8edb0c1209efF172f9420CC63549] = 30000000000000000000000;
        _airdrop[0x5aDa65374aeF473fdD122feB78a17f4be5688ED0] = 130000000000000000000000;
        _airdrop[0xE037e26E4eB6ed3FE6d1383bc24217B461C82FA5] = 80000000000000000000000;
        _airdrop[0xF193B488B0384708ec4F0a1c6be3eD9BefC1Ee86] = 60000000000000000000000;
        _airdrop[0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34] = 80000000000000000000000;
        _airdrop[0x004196E84C7320EbB2e90e8dC4e0a766d3aaC8Db] = 20000000000000000000000;
        _airdrop[0xC649195a06E36041a394aEB3f3dF5F381724fFC8] = 20000000000000000000000;
        _airdrop[0x4e96CA2FC750520d508FadeD30C8B4bb479eE5BB] = 10000000000000000000000;
        _airdrop[0x60F444A38d8792EeD42E6E091E64216F93ceEeb8] = 20000000000000000000000;
        _airdrop[0xb261F055621fb3D19b86CD87d499b5aD9a561115] = 20000000000000000000000;
        _airdrop[0x85D3c6be944F7fF76968C79Fa7CE409F0a3734B6] = 30000000000000000000000;
        _airdrop[0x995418c315Ff98763dCe8e57695f1C05548b4eF5] = 20000000000000000000000;
        _airdrop[0x2CD99E5F701aEBE4E44e64c8062afad53F290BD3] = 10000000000000000000000;
        _airdrop[0xC93e7FEc09E54ECbbAE66754159989E44FB12aD2] = 20000000000000000000000;
        _airdrop[0xeBC5258E2810d9f1CE9e545930E5b931D2706191] = 20000000000000000000000;
        _airdrop[0x4C7688fB4Dc24F34E837ee6D5D25EB2Fa2B07235] = 40000000000000000000000;
        _airdrop[0x1C163b72D5a6bCA2Fc0535A1df2Bbc39fBaed2F5] = 10000000000000000000000;
        _airdrop[0x0e0bDf28A0324dD3639520Cd189983F194132825] = 30000000000000000000000;
        _airdrop[0x1aFF55f3BAfE7b83BE9Fbc82237a95Fb8d557e60] = 30000000000000000000000;
        _airdrop[0xd9a83959B85F191a5A9FFEf6B4A99b27d1edF40D] = 30000000000000000000000;
        _airdrop[0x2628d76a52ef36CD1E440f061D81D155907c500b] = 10000000000000000000000;
        _airdrop[0x01C9a2bbb109a24E86535bB41007cd15a0177C11] = 50000000000000000000000;
        _airdrop[0xE18bB67496ee8d43D1dd63d63ff0cBF672a65fef] = 10000000000000000000000;
        _airdrop[0xbda1825F4DD9B737e4719812f278F354433A6c4E] = 110000000000000000000000;
        _airdrop[0xe0d9A11C43079a6fd38d4F0F9D27282AbB8c71Cd] = 10000000000000000000000;
        _airdrop[0x82072FDB7EB0CCB624fd2914A4e8a712C782FA8f] = 20000000000000000000000;
        _airdrop[0x5Ae546E442355e4F3c7b48fFe575FD40dFcbFa4a] = 10000000000000000000000;
        _airdrop[0xEd62B641dB277c9C6A2bA6D7246A1d76E483C11C] = 20000000000000000000000;
        _airdrop[0x07142d97b560Bf6B630f8B74747e707C4B139fb0] = 20000000000000000000000;
        _airdrop[0xefc90868fB7397D13Bf542eda85D03FEbDDe28BB] = 80000000000000000000000;
        _airdrop[0x2A17068BC37705fA1710dC8bFd1EE49Bc0b432b0] = 50000000000000000000000;
        _airdrop[0x3061E89523544f002D49cDff2e4825eC05e574C7] = 10000000000000000000000;
        _airdrop[0x835feEBEbe8b607eFf3ca85a4E22Bf712f19ed21] = 20000000000000000000000;
        _airdrop[0x5A6bdC17B9F89Cb52b38dad319dF293b037a43d4] = 30000000000000000000000;
        _airdrop[0x66aB275551Fa8f0E3F823858ED744F74fd9067bD] = 10000000000000000000000;
        _airdrop[0x208Eff61de4d585bf1983fdaA5eE9E6c0A92D938] = 40000000000000000000000;
        _airdrop[0x35d50ceB03933Da0e3d0D970aBCAfA32F269181d] = 250000000000000000000000;
        _airdrop[0x4a8A003acC8a2c0329286e46650bE18dfe2cb12d] = 50000000000000000000000;
        _airdrop[0x682ae71bae517bcc4179a1d66223fcDfFb186581] = 50000000000000000000000;
        _airdrop[0xCb7566fd2C7F63794C31E63Bc261e437F0ccCb28] = 20000000000000000000000;
        _airdrop[0xd469CD19CEFA18e4eb9112e57A47e09398d98766] = 20000000000000000000000;
        _airdrop[0xe8F7B0F38c288D49D19857e96Ec88cDd7eb9A2B9] = 20000000000000000000000;
        _airdrop[0x6dDa282E7d11C38eb06e1cBad60c0767be39a3F6] = 20000000000000000000000;
        _airdrop[0x4d140380DE92396cE3Fa583393257a7024a2b653] = 100000000000000000000000;
        _airdrop[0x4B9fC228C687f8Ae3C7889579c9723b65882Ebd9] = 40000000000000000000000;
        _airdrop[0x87689C4e28200de1f0313A98080B4428490F7285] = 10000000000000000000000;
        _airdrop[0x1d4eb3b64Cee406B087591C5d8933005E5145e4a] = 30000000000000000000000;
        _airdrop[0xE96Db1b8ea6432E692a1CaA9dCf07662610AC04D] = 10000000000000000000000;
        _airdrop[0xD77D92f3C97B5ce6430560bd1Ab298E82ed4E058] = 30000000000000000000000;
        _airdrop[0x6955e29a59BF3748F62C2e8b8877A36d503D6d45] = 10000000000000000000000;
        _airdrop[0xa94c5f196a8C76c869AA712253d35102d1EAd6D5] = 10000000000000000000000;
        _airdrop[0xb78D0133b00Cb701887D5b009a9e9BD92459D46f] = 10000000000000000000000;
        _airdrop[0xC15f55d4381473A51830196d0307c2987e9A39d9] = 30000000000000000000000;
        _airdrop[0x822166Dc6A1ADc21ae1B7fbA3b700167cf0f0a6c] = 40000000000000000000000;
        _airdrop[0xdDafB7c4fEd00D11080f53b9EfaAA0CB1aB5cEf8] = 20000000000000000000000;
        _airdrop[0x2BEa720a5fe5e7738d775e8BfD3a37Fa072Cd46c] = 10000000000000000000000;
        _airdrop[0xCb46d80af2FCbC442E644fC360593d6abF4d3258] = 20000000000000000000000;
        _airdrop[0xaA4ba5752ED40b31BDDcD450b17649D88994dE2b] = 30000000000000000000000;
        _airdrop[0x13bCF25E17a633FAE7cfb62bfe92b53F227d722f] = 30000000000000000000000;
        _airdrop[0x087e269f123F479aE3Cf441657A8739236d36aEe] = 20000000000000000000000;
        _airdrop[0x876b32129a32B21d86c82b0630fb3c6DDBB0e7B8] = 20000000000000000000000;
        _airdrop[0x3C132E2d16f7452bdfAEFaE6C37b81e0FF83e749] = 70000000000000000000000;
        _airdrop[0x2c1a74debC7f797972EdbdA51554BE887594008F] = 20000000000000000000000;
        _airdrop[0x2F3282c956B65641E9d6D5F70262724FD32d2513] = 120000000000000000000000;
        _airdrop[0x635123F0a1e192B03F69b3d082e79C969A5eE9b0] = 150000000000000000000000;
        _airdrop[0xe4125A48C86C4281E8c02d71F5073516684da9dA] = 20000000000000000000000;
        _airdrop[0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611] = 50000000000000000000000;
        _airdrop[0x7d48f0AD0b2187C30Bb1cc6e930fB960161d3d6c] = 10000000000000000000000;
        _airdrop[0x42Ba24C0E282cB2F2732D305960ede5eDC3a6896] = 10000000000000000000000;
        _airdrop[0x69AE208ea38d55649dc6a49431557393a72149e9] = 10000000000000000000000;
        _airdrop[0xf6152a61dd9E41bc4b1DE9563fEe3b4162e6AdEE] = 140000000000000000000000;
        _airdrop[0xfd04340F02398520296bE10f785e6Ee1f0F36b85] = 50000000000000000000000;
        _airdrop[0x70Eb382597C564c6eAbFbf2971Cb48bD98A4bEdb] = 30000000000000000000000;
        _airdrop[0x2eea4706F85b9A2D5DD9e9ff007F27C07443EAB1] = 30000000000000000000000;
        _airdrop[0x2B7cD3Fec35fb21eFc8913E7383639adb088384B] = 20000000000000000000000;
        _airdrop[0x3f6a989786FD0FDAE539F356d99944e5aA4fBae1] = 20000000000000000000000;
        _airdrop[0xcD79853e46082e521E20f31c39Aff11adE79b8c6] = 10000000000000000000000;
        _airdrop[0x5Ee580933a9579c21Ef9187Bf485A4C8F35D3a92] = 20000000000000000000000;
        _airdrop[0x1D33BBe15f7CBe45676F3663340Ae6e8B2Bc5DE4] = 20000000000000000000000;
        _airdrop[0x215867219e590352f50f5c3B8cE2587236138494] = 20000000000000000000000;
        _airdrop[0x9c8bd5847971f024491b893063bE77b31E091117] = 10000000000000000000000;
        _airdrop[0x8bc3A620F67C4e0039AAD661Ed069C2E6Ad5faa3] = 20000000000000000000000;
        _airdrop[0x1877e5A2B21dBC2EB73eC1b8838461e080932A9f] = 20000000000000000000000;
        _airdrop[0xedE6D8113CF88bbA583a905241abdf23089b312D] = 20000000000000000000000;
        _airdrop[0xd8BD12bcdbDbf8F216127640F2590942b5E2F336] = 30000000000000000000000;
        _airdrop[0xc8c626980f06e95825cf2e12F762D2eaB8CA7b46] = 30000000000000000000000;
        _airdrop[0xA47603B00307Bf81A2f49176BBfbf600322Dc2a1] = 20000000000000000000000;
        _airdrop[0xcE9135ab7aEBe4a1Ff175e0bE2f9a25a0fb78a83] = 10000000000000000000000;
        _airdrop[0x399190C47dD486A553dEDCbD5465f811ab15C32B] = 50000000000000000000000;
        _airdrop[0x131E8fbB001DaFb01d96B87B2bb58Aa524c6BdA5] = 10000000000000000000000;
        _airdrop[0xC992c764a5dD14dd5Bd6F662a14377E1Cf7e31df] = 50000000000000000000000;
        _airdrop[0x4A90601B49605B3998A5339833763931D9BD4918] = 20000000000000000000000;
        _airdrop[0x7705cCfC1E1aAf09d24070F17e6eb64629e0F361] = 10000000000000000000000;
        _airdrop[0x140Eef04d2392C72403C046509555A779aF40957] = 10000000000000000000000;
        _airdrop[0xDCC15c04963095154aBa0131462C5F4b5284b7c0] = 30000000000000000000000;
        _airdrop[0xc4dFEa5E0D1DDAABca605E86Cc57ab7df9665a0a] = 20000000000000000000000;
        _airdrop[0x7fc0aB0667981a5F8cd18306360327386e217310] = 80000000000000000000000;
        _airdrop[0xBa6A7deF11Cc2d880D9cB3663350F6D571878af2] = 10000000000000000000000;
        _airdrop[0xa7BFc3Fb947Bd41B85Cf759900012456B0d39090] = 20000000000000000000000;
        _airdrop[0xd8FA256F9Fa47De1091441CD7D50644CE7CF5C50] = 10000000000000000000000;
        _airdrop[0x5AC15cF56DFFc5240Fa9e559FAEfE9cD31aDFDAC] = 10000000000000000000000;
        _airdrop[0x3723DDeC18A8F59CFC2bED4AEDe5e5Bebdf21712] = 20000000000000000000000;
        _airdrop[0x6dF83e206951f9C421e6ef9d2dC7BE0b5112D031] = 10000000000000000000000;
        _airdrop[0xE4E83eF0AA0e22506cf920434A3b1d9685DBD171] = 20000000000000000000000;
        _airdrop[0xFA9E14bAf401253e478Cb2378b911A76A535e697] = 20000000000000000000000;
        _airdrop[0xf64980B3f3EA14b1235f248B9BCA6853F0356F7F] = 50000000000000000000000;
        _airdrop[0xc564D44045a70646BeEf777469E7Aa4E4B6e692A] = 20000000000000000000000;
        _airdrop[0x81b4EA3D93f36506c0Ab3559a2401fe6698D5FdA] = 20000000000000000000000;
        _airdrop[0x632Ba722F95008963Be23dcd37CbaC3598182dAE] = 20000000000000000000000;
        _airdrop[0x06Df3F02E84F7034CF70f52cdf5Cdc0Ab02F6Fea] = 50000000000000000000000;
        _airdrop[0x8a9dF68963A68379Ad48245377eE172CbA56b92E] = 10000000000000000000000;
        _airdrop[0xb6ddE9a985c77d7bC62B171582819D995a51C3bf] = 30000000000000000000000;
        _airdrop[0xEF815e51fdf1Dc91877933bEF8B55375Aa3c34C6] = 10000000000000000000000;
        _airdrop[0x386c2f5aAB7392F86e5aF3de097673b7BFc4aE64] = 10000000000000000000000;
        _airdrop[0x22a6C7EAE21e6197d2F180673B8f939e0B2fAe8B] = 10000000000000000000000;
        _airdrop[0xE4324E43Ae3e8a611E927dF10795D3A20152aE4a] = 10000000000000000000000;
        _airdrop[0xb7153a50412beAebA3E9384460B75A7abcBF7d15] = 10000000000000000000000;
        _airdrop[0xF8f18ff9969aB94299e763e038902262002341CD] = 20000000000000000000000;
        _airdrop[0x4624865DAE01e0A152155e853b6cABBBe9eD24b9] = 80000000000000000000000;
        _airdrop[0x3f632222501F1342DCE8dE9D50d58E979bae5e2f] = 10000000000000000000000;
        _airdrop[0xDbfBc6B71CD26A88aaC7eBf01806614592d046d5] = 10000000000000000000000;
        _airdrop[0x9Fe658b1487E392b778B9d256020D532a3Cc19c2] = 10000000000000000000000;
        _airdrop[0x2711831f3EbCc36541aAc7cA4B0dDfaC56D0E2e0] = 30000000000000000000000;
        _airdrop[0x3908176C1802C43Cf5F481f53243145AcaA76bcc] = 20000000000000000000000;
        _airdrop[0xeFf626B4beBBd3f26cbA77b47e9ae6C9326cfebB] = 50000000000000000000000;
        _airdrop[0xE057B08e0D2DEda77BAFe0B7797bb0bb8d174E11] = 100000000000000000000000;
        _airdrop[0xd42F1B8778811aD583dc82ebe2814B3CC21192DF] = 20000000000000000000000;
        _airdrop[0x8Bf52d54578d06724A989906D47c7B021612E502] = 20000000000000000000000;
        _airdrop[0xC27e35f8AeE69c978d3360d30f973e798a1702Ef] = 20000000000000000000000;
        _airdrop[0x8A808Ac0a317E1a76C82831037204C9d3D9F9f3F] = 40000000000000000000000;
        _airdrop[0x9DB99D5FDedC50F333f3d128b91c435584D55cFC] = 10000000000000000000000;
        _airdrop[0xe4EBad58c7B418ACDBb4910cB29cB366DC6B31f8] = 10000000000000000000000;
        _airdrop[0xCf13EF0C1C77593902d76701d683141D26fcaB29] = 10000000000000000000000;
        _airdrop[0x9dC4568fC6ee6F6c2A00E1C392b23A8E7a401359] = 10000000000000000000000;
        _airdrop[0x461B5DD073BE81CaD6752bFcc355d5A252b8E910] = 50000000000000000000000;
        _airdrop[0xDA44F55C5ed083E579F0D343DDc97B473bAd9977] = 20000000000000000000000;
        _airdrop[0x86C0Cc4EF96577A2B2fAFc6eC62C26Fa30D8c735] = 20000000000000000000000;
        _airdrop[0x1c7B307CC027ec9163B1D4AE9d771c16F65598c2] = 10000000000000000000000;
        _airdrop[0xcCc487e0b99647d0D699C1FAfD1AEe16f2512fA6] = 10000000000000000000000;
        _airdrop[0x6B354c4505F30aDB4B70643a7a3e3Bc375194AA0] = 20000000000000000000000;
        _airdrop[0xA613e95408dbEfc3aeCB4630BDE04E757Bc46fD8] = 10000000000000000000000;
        _airdrop[0x6424094AaF8D7131C48e865Ad7a9F0A96E9b1329] = 10000000000000000000000;
        _airdrop[0xb0B56557092d87DE2A9648Cd9ab1c9B28a4A2B43] = 10000000000000000000000;
        _airdrop[0x7515a84722Be2eaACc7308892E21fae8B8D136d8] = 10000000000000000000000;
        _airdrop[0xA11c38BD820Ae3e3236e2EE750Ec2A6577173C49] = 10000000000000000000000;
        _airdrop[0x3D352A5063eAcfCc67187Db69080dFc219C553eA] = 10000000000000000000000;
        _airdrop[0xED114f78CbACf13E33450170162f341277292d54] = 10000000000000000000000;
        _airdrop[0x589a22fd4011d46B95891D1610aeBb25A39A1A9B] = 20000000000000000000000;
        _airdrop[0x050f062FA14B9da77C12b555656DE1C05dfC8Ab8] = 20000000000000000000000;
        _airdrop[0x86161076B6B234B6A56644a03c29aDd03e23eB91] = 10000000000000000000000;
        _airdrop[0xFf5772aD26453CD2c5Af595313435Cb825426Fc9] = 10000000000000000000000;
        _airdrop[0x96C075f295431C5D9fce55593902579b80fAF4A0] = 20000000000000000000000;
        _airdrop[0xB64614e28ccE4eC769c38fB979493016278ce440] = 30000000000000000000000;
        _airdrop[0xd968c650d86B6d576B746e31944016773E074f4a] = 10000000000000000000000;
        _airdrop[0xcDa8bec81F5090EE74509606FEDaF533148d0b26] = 20000000000000000000000;
        _airdrop[0x3090Ae063988b205b7d265121687ff1537c68F1D] = 10000000000000000000000;
        _airdrop[0xba4Ac4Db0EbA3da64Aba5D968CDf74CDfd2a6b9a] = 30000000000000000000000;
        _airdrop[0xE543F7311d4f97ed2d67Be409cfa353127D7F42B] = 30000000000000000000000;
        _airdrop[0xA96329580a8d31d47D2C083DB97066754188dd51] = 20000000000000000000000;
        _airdrop[0x0d6E832e8188c308904DE51EA62B43920FE1da46] = 20000000000000000000000;
        _airdrop[0x3c0EDd62018cb3c0E4044E3909c58d64CACB8dc3] = 30000000000000000000000;
        _airdrop[0x71D645C3CDe10912f98933c7BbA2cd971485A8c0] = 10000000000000000000000;
        _airdrop[0x2eE88422FBC9Ed5C4689089b05154887d737d76B] = 30000000000000000000000;
        _airdrop[0x27174e4cd394801D6fC316831dEfC16F43a07f55] = 10000000000000000000000;
        _airdrop[0xB35Abb65F67fd942fbD0a9fB96Eb2db8791357B2] = 10000000000000000000000;
        _airdrop[0x59164085e872594CB33F198C24a3485329dd09D5] = 10000000000000000000000;
        _airdrop[0x66B471Cf3ED57Cf8BDA6948ec1B412CFe7c4c266] = 10000000000000000000000;
        _airdrop[0x828cDcDc2a006E5EBCA06EEd673BFa8DF897852D] = 50000000000000000000000;
        _airdrop[0xA0ac4824CB006EeC9Ee510aac84cF9BB983c9494] = 10000000000000000000000;
        _airdrop[0xec7dA9b90713B119969a8309607197e5A8606493] = 20000000000000000000000;
        _airdrop[0xFEE8f55463e64b8E252269EF105F31B164619958] = 20000000000000000000000;
        _airdrop[0xB7f3045e4EF29D45C0AEbC9E93Ff3053882c5DC9] = 10000000000000000000000;
        _airdrop[0x1d2290Ed86055F96526AFB0ff8Fbe201C4eFce39] = 10000000000000000000000;
        _airdrop[0x1FC9aD1d4b2Ec8D78CfDA9FC35Cf729b9B49E7B6] = 20000000000000000000000;
        _airdrop[0x0E10CCf2995AD7a77908984F134778243D1052A5] = 10000000000000000000000;
        _airdrop[0x500bB12d7D453c8a8D16b4167946F11C98F5Aa5E] = 10000000000000000000000;
        _airdrop[0x8bfb27fe31e39959Bcc3Ec14ED5031f4F75b6041] = 10000000000000000000000;
        _airdrop[0x175F02F6473EcD2E87d450Ef33400C4eE673C387] = 20000000000000000000000;
        _airdrop[0xdc9121d70FDb1d997821F8B6146B41f347798dE0] = 40000000000000000000000;
        _airdrop[0x8aA2d6C90a402491B325B0cf7d93Ef582754a99e] = 20000000000000000000000;
        _airdrop[0xB7752f329b72E71a6066c7d944b0B69fEE970e4d] = 30000000000000000000000;
        _airdrop[0x5c5D1c68957EF6E9e46303e3CB02a0e3AecE1678] = 30000000000000000000000;
        _airdrop[0x6B4ee11d28ebeee4B933E17865F66d810D14297D] = 10000000000000000000000;
        _airdrop[0x5f0Fa6E54B9296622235CC146E02aaEaC667325a] = 70000000000000000000000;
        _airdrop[0x015732d3b7cda5826Ae3177a5A16ca0e271eA13F] = 20000000000000000000000;
        _airdrop[0xc7Cc0b1e40116574E1750Bc3FbA54f12c97F2319] = 10000000000000000000000;
        _airdrop[0xA01481b6fBE54BE00661290f1cE49e14E3Af82Ef] = 50000000000000000000000;
        _airdrop[0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1] = 60000000000000000000000;
        _airdrop[0x826ae03F697BbD3dAD37E9b34e7a8989d9317fc4] = 30000000000000000000000;
        _airdrop[0x1105bF50bE63cdaD34Ff7ac9425C1645e6275E1e] = 20000000000000000000000;
        _airdrop[0x0e45305f2203f0a4E430ca046C49Cf1e278a9013] = 10000000000000000000000;
        _airdrop[0xd7382dE5A85485Da6a79885E6757B108EBebc758] = 10000000000000000000000;
        _airdrop[0xDAFB6e907fC8589894F7d9d44D02c3fb50ffCE31] = 10000000000000000000000;
        _airdrop[0x53D881C09448da0112A2FEA60c954D4495B20e71] = 10000000000000000000000;
        _airdrop[0xfeAaB37506558E5cF3120A86E597943F89E8B8bE] = 20000000000000000000000;
        _airdrop[0xC709ACBD5531E461e39D04A28E36B81F4f6b995d] = 20000000000000000000000;
        _airdrop[0x2e47814BaA1Dd59F1e604f26E113Aa37B83276E5] = 20000000000000000000000;
        _airdrop[0x2F44B0D306B302edbef4DA019ae4e1005D58De35] = 30000000000000000000000;
        _airdrop[0x828B5Fa560a19D8aB8fAf05DE6E3F403e8D5AF21] = 10000000000000000000000;
        _airdrop[0xCBF8168418E618C57ea52a6128CDdbC096D3DB37] = 10000000000000000000000;
        _airdrop[0xE8d6001443d83E152FDf56d71a79E87B1c55b41b] = 10000000000000000000000;
        _airdrop[0xE95B8E7Ba16A19EFE3Ed3eD53fB47aa2319837e2] = 10000000000000000000000;
        _airdrop[0xD8eBaD35a992d5A460254383d7e5e5556516e4dA] = 10000000000000000000000;
        _airdrop[0x7ac34ed389d1D23BD85eC5edcBABA7C7eB2CD4Ac] = 80000000000000000000000;
        _airdrop[0x2b3a7d2b25Cc976F299080cD6A56eb3DB84C55b6] = 10000000000000000000000;
        _airdrop[0x7dA052e64fFA097A9819E7cc5F0e2b78f152e145] = 10000000000000000000000;
        _airdrop[0xe0debbB1A8b830B0D7A3Fe45A42A7dAd85B21f80] = 50000000000000000000000;
        _airdrop[0x206A95f8f2b60ea9D6642b5116e6D46aaa19CBB0] = 10000000000000000000000;
        _airdrop[0xC26990939740aAA4a8f4EF7eb212EcD6c31b4C06] = 90000000000000000000000;
        _airdrop[0x71a650C9bfF9D83a48Cf6d857D188Ba39C19bB01] = 20000000000000000000000;
        _airdrop[0x7403BDD9283EBd871630Fb5deB07cc427A67B3f9] = 10000000000000000000000;
        _airdrop[0xFf78bef83d6916b7d4f026C9EFd1E40099031A8B] = 10000000000000000000000;
        _airdrop[0x91115D501BC84d9CAf2f09AA3eDe863483FBA19A] = 20000000000000000000000;
        _airdrop[0x84FbB28e368946Ec4488fC74aB9E5d3BDfA6fEC2] = 10000000000000000000000;
        _airdrop[0x11f1908a8b6DbbDcEd43E920E21B78D9e32e3493] = 50000000000000000000000;
        _airdrop[0xe3863A499B65350BB13FB88BdF97Cbbe117cc0a3] = 10000000000000000000000;
        _airdrop[0xb08458E7bb184C0a0206d8c0Ce124D331983C1f9] = 10000000000000000000000;
        _airdrop[0x057E3520e130d62344C7AfF216568B3d78B89CD0] = 20000000000000000000000;
        _airdrop[0x80f3EEe5De1F656369860506d927533210077C5B] = 10000000000000000000000;
        _airdrop[0xb994bA33eaB3744020454a843b6FD5008Cea29c0] = 10000000000000000000000;
        _airdrop[0x0f15E698556f2c96e8Ed8f0964318dff378eA17f] = 30000000000000000000000;
        _airdrop[0x37F12bC1974843aA9657Fd1614a3eF9b08427E51] = 80000000000000000000000;
        _airdrop[0xC9793E1129322e28D657c803ac3354e4D9bFaf3E] = 50000000000000000000000;
        _airdrop[0xE0cc67a04705D0C7E946C9C5FFBb5a427bC24545] = 10000000000000000000000;
        _airdrop[0xcA8A7EFc165a9f31fc46eA7f3A85902bfb478CBD] = 10000000000000000000000;
        _airdrop[0xf508cDD187CFEb8Ec46E5430bfaEA449C82698Fe] = 20000000000000000000000;
        _airdrop[0xfe8129f030A205eAf338af2dDd34c306B769c090] = 10000000000000000000000;
        _airdrop[0x9E688a25aCaA94f4172Cc89B56DD06f4ea22Ff77] = 10000000000000000000000;
        _airdrop[0xD7cA49f6E3C90864BC7475a3B2e1B20377D6D820] = 20000000000000000000000;
        _airdrop[0x1Cda38092C37cC0D4008f69Da364FcA7E858CE78] = 30000000000000000000000;
        _airdrop[0xC4b4f3d707CC2A9C023E2e83fd87D39075f44f05] = 110000000000000000000000;
        _airdrop[0x5F4C5ef5Be53Db7631d5257348BBcD354159269A] = 10000000000000000000000;
        _airdrop[0xF02068333cB17993CEc1948f42A2244c5Dc5bdd0] = 10000000000000000000000;
        _airdrop[0x9945F42389497071Bd0d284B8819D57a2f88D312] = 10000000000000000000000;
        _airdrop[0xAC85BCE64Fcf6420a767fD438c9A20c9dBABc2D8] = 10000000000000000000000;
        _airdrop[0x46c48a7f5459aC749a1A4AbccED7796e112Da005] = 10000000000000000000000;
        _airdrop[0x79B3A621E3e0ce4F240763130C56eAd96f10565E] = 10000000000000000000000;
        _airdrop[0x0eaB7c25146423e9CA921D608aC3D436892183AB] = 10000000000000000000000;
        _airdrop[0xF3ebaD21AE3f6D5882d097F8EB1D0deAC2C66D00] = 10000000000000000000000;
        _airdrop[0x507b621DA61CB0F3581EEC2898E041275E9e4c61] = 10000000000000000000000;
        _airdrop[0xf040E96b19B385EEAFDD48487cAec748e80D15f9] = 10000000000000000000000;
        _airdrop[0x347E694f5e396924f8Ca8558E9d6600A27c00A07] = 10000000000000000000000;
        _airdrop[0x2121287C008f0b52D79d9FC9e9Db0F9F059Fdc49] = 10000000000000000000000;
        _airdrop[0xb2D1272E1169497A5d941490FDF0bC6328F5C13e] = 10000000000000000000000;
        _airdrop[0x9E750599aFD252b38f5bFF6cb223195346A03592] = 10000000000000000000000;
        _airdrop[0x445b34aaab922Ef104eD195D396dA020AFf432Cf] = 10000000000000000000000;
        _airdrop[0x18B1146573cEbdF82D8Ce7D7698D172499C95755] = 20000000000000000000000;
        _airdrop[0xCC9dA06FCE4750728806a1F324D2bDd2eA84eBe0] = 20000000000000000000000;
        _airdrop[0x100cC7048A3290bF5d94dAe865d308fBDdf332CC] = 10000000000000000000000;
        _airdrop[0x16dde7bDf083a0A41b6617237a2Af27034cb79eA] = 10000000000000000000000;
        _airdrop[0x2758DF847b870e2eD2B343d0c5d2437dDAc70A38] = 10000000000000000000000;
        _airdrop[0xe91d95bA259C6D8001a06DeaF02F811baA3e2DFA] = 10000000000000000000000;
        _airdrop[0x0045770bbA2805E1631631E7DDc917BA9D4Fc523] = 10000000000000000000000;
        _airdrop[0x1Adc7C20666167F49Bc2d1C80C73D157804b6F69] = 20000000000000000000000;
        _airdrop[0xC7A7A0c0F1B6b47703792D82185B0624cC3E79A2] = 10000000000000000000000;
        _airdrop[0x7F37e41b3C4aBF5500f2c5226A526FC99cCFeE61] = 10000000000000000000000;
        _airdrop[0x8B18824aA942bD4cd8410c561Fa4d05B6a0a5f4A] = 10000000000000000000000;
        _airdrop[0x3cA33bCcbA02Af638857bE53C18A4e5E622BC406] = 10000000000000000000000;
        _airdrop[0x898929d50566138bed1dEB1688919b52AB80aE63] = 10000000000000000000000;
        _airdrop[0x4C0D1Ea8a7F7BC2d74ca4E6cCBeFC97CAED8A2f5] = 20000000000000000000000;
        _airdrop[0x6b867Ed44Fd4042202156848D9824F9dA255fa43] = 20000000000000000000000;
        _airdrop[0x63847477f40C2C1125c3FaCb961A9Fc5a4eD51Db] = 10000000000000000000000;
        _airdrop[0xa84a906da6e3EDF1e320fc5e55163738b8B5Dd5F] = 110000000000000000000000;
        _airdrop[0xffB20706Ad48Bce88F119C9662364c02078C0280] = 10000000000000000000000;
        _airdrop[0xa51d3bEFE1bAF4A0128282163E7A7f3816aDC6B6] = 10000000000000000000000;
        _airdrop[0x8D0E10138a1B59D0b47f3ec149715509a21fAc87] = 10000000000000000000000;
        _airdrop[0x97843e39b6D0Db171568Bf472C59F75BdD32180f] = 10000000000000000000000;
        _airdrop[0x3b6DE55766c443475eE99AFffa42866d845793Ef] = 10000000000000000000000;
        _airdrop[0x0Ff987DF044265c19fbDe9586974902279a88FeC] = 10000000000000000000000;
        _airdrop[0xb8758CE976308464062C107C264D57dc1a744C69] = 10000000000000000000000;
        _airdrop[0xF17f0fE554559441f64Cf2427b8d508cc8D39782] = 10000000000000000000000;
        _airdrop[0xCb2544047e2965650df1D12CE1aAcB8E304245a6] = 10000000000000000000000;
        _airdrop[0x377fC3b608A46eFC254A21D4B665D1eAc990d08c] = 20000000000000000000000;
        _airdrop[0x55c254fe3eC4e8a5d4AA51044359fa0571cDa0db] = 10000000000000000000000;
        _airdrop[0xFfa246C39083704ED6b6e82A5a03E3Ed658E3d83] = 860000000000000000000000;
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