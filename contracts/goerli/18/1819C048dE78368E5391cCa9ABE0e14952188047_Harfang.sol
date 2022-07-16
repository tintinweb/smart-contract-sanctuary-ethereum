// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Price.sol";
import "./Utils.sol";

contract Harfang is Ownable {
    using Counters for Counters.Counter;

    // storage
    mapping(uint256 => Utils.GlobalElement) private _elements;
    mapping(string => Utils.Element) private _owners;
    mapping(string => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    Counters.Counter public count;
    Counters.Counter public stampCount;
    address public marketplace;
    address public price;
    address public usdc = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;
    address public dai = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

    constructor(address _price, bytes memory cid){
        require(cid[0] == 0x12 && cid[1] == 0x20 && cid.length == 34, "Incorrect cid (v0 only)");
        price = _price;
        count.increment();
        _elements[count.current()] = Utils.createGlobalElement(
            cid,
            667667667667,
            Utils.ElementType.stamp,
            address(0)
        );
        count.increment();
        emit ElementCreated(cid, 667667667667, Utils.ElementType.stamp, 1, address(0));
    }

    // events

    event Transfer(address indexed _from, address indexed _to, string indexed _idEncoded);
    event Approval(address indexed _owner, address indexed _approved, string indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event ElementCreated(bytes cid, uint256 copies, Utils.ElementType indexed t, uint256 indexed id, address indexed owner);
    event SpecificElementCreated(uint256 indexed sid, uint256 indexed id, address indexed owner);
    event Stamp(address indexed operator, string stamp, string card, bytes32 indexed stampId, bytes32 indexed cardId);
    event Unstamp(address indexed operator, string stamp, string card, bytes32 indexed stampId, bytes32 indexed cardId);
    event Burn(address indexed operator, uint256 indexed id, uint256 indexed sid, uint256 copies);
    event Withdraw(address indexed operator, uint256 daiAmount, uint256 usdcAmount);
    event NewPrice(address indexed operator, address price);
    event Marketplace(address indexed operator, address price);

    function createElement(bytes calldata cid, uint256 _copies, Utils.ElementType t, Utils.Currency currency) external {
        require(cid[0] == 0x12 && cid[1] == 0x20 && cid.length == 34, "Incorrect cid (v0 only)");
        uint256 priceToPay = Price(price).cardPrice(_copies);
        require(_copies >= 1, "copies cannot be less than 1");
        if(currency == Utils.Currency.dai) {
            require(ERC20(dai).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
        }else{
            require(ERC20(usdc).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
        }
        _elements[count.current()] = Utils.createGlobalElement(
            cid,
            _copies,
            t,
            msg.sender
        );
        count.increment();
        if(currency == Utils.Currency.dai) {
            ERC20(dai).transferFrom(msg.sender, address(this), priceToPay);
        }else{
            ERC20(usdc).transferFrom(msg.sender, address(this), priceToPay);
        }
        emit ElementCreated(cid, _copies, t, count.current()-1, msg.sender);
    }

    function createSpecificElement(uint256 id, address to) public {
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(global.creator == msg.sender || _operatorApprovals[global.creator][msg.sender], "You do not own the element");
        require(global.copies > global.lastId, "limit of copies hitted");
        require(_owners[Utils.encode(id, global.lastId)].owner == address(0), "Element already exists");
        _owners[Utils.encode(id, global.lastId)] = Utils.createLocalElement(to);
        global.lastId = global.lastId+1;
        emit SpecificElementCreated(global.lastId, id, msg.sender);
    }

    function send(uint256 id, uint256 sid, address to, bytes calldata messageURI) external {
        require(messageURI.length == 0 || messageURI[0] == 0x12 && messageURI[1] == 0x20 && messageURI.length == 34, "Not correct cid");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == msg.sender, "The sender is not the owner");
        if (global.t == Utils.ElementType.stamp){
            require(element.twin == 0 && element.twinSid == 0, "Stamp is attached to a card");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else if(global.t == Utils.ElementType.card){
            // require(string(messageURI).length == 46, "Message URI is not a valid IPFS hash");
            require(element.twin != 0, "Card is not stamped");
            Utils.Element storage lstamp = _owners[Utils.encode(element.twin, element.twinSid)];
            element.owner = to;
            element.messageCID = messageURI;
            lstamp.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else{
            revert("Element does not have a type");
        }
    }

    function transfer(uint256 id, uint256 sid, address from, address to) external {
        require(msg.sender == marketplace, "Can only be executed by the marketplace contract");
        require(_tokenApprovals[Utils.encode(id, sid)] == marketplace || _operatorApprovals[from][marketplace] == true, "Marketplace is not allowed to transfer this element");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == from, "The sender is not the owner");
        if(global.t == Utils.ElementType.stamp){
            require(element.twin == 0 && element.twinSid == 0, "Stamp is linked");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else if(global.t == Utils.ElementType.card){
            require(element.twin == 0 && element.twinSid == 0, "Card is attached to stamp");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else{ 
            revert("Element does not have a type");
        }
    }   

    function stampHarfang(uint256 cardID, uint256 cardSID) internal {
        Utils.Element storage element = _owners[Utils.encode(cardID, cardSID)];
        require(element.owner != address(0), "This specific element does not exist");
        require(element.owner == msg.sender, "The sender is not the owner");
        require(element.twin == 0 && element.twinSid == 0, "Card is already attached to stamp");
        Utils.GlobalElement storage global = _elements[cardID];
        require(global.copies >= 1, "This global card does not exist");
        require(global.t == Utils.ElementType.card, "Provided card is not a card");
        Utils.Element memory lstamp = Utils.createLocalElement(msg.sender);
        lstamp.used = true;
        string memory key = Utils.encode(1, stampCount.current());
        _owners[key] = lstamp;
        _owners[key].twin = cardID;
        _owners[key].twinSid = cardSID;
        element.twin = 1;
        element.twinSid = stampCount.current();
        stampCount.increment();
        emit Stamp(msg.sender, key, Utils.encode(cardID, cardSID), keccak256(bytes(key)), keccak256(bytes(Utils.encode(cardID, cardSID))));
    }

    function stamp(uint256 cardID, uint256 cardSID, uint256 stampID, uint256 stampSID, Utils.Currency currency) external {
        require(_elements[cardID].t == Utils.ElementType.card, "Incorrect type");
        if(stampID == 1){
            uint256 priceToPay = Price(price).stampPrice();
            stampHarfang(cardID, cardSID);
            if(currency == Utils.Currency.dai) {
                require(ERC20(dai).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
                ERC20(dai).transferFrom(msg.sender, address(this), priceToPay);
            }else{
                require(ERC20(usdc).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
                ERC20(usdc).transferFrom(msg.sender, address(this), priceToPay);
            }
        }else{
            Utils.Element storage card = _owners[Utils.encode(cardID, cardSID)];
            require(card.owner != address(0), "This specific card does not exist");
            Utils.GlobalElement storage gcard = _elements[cardID];
            require(gcard.copies >= 1, "This global card does not exist");
            Utils.Element storage lstamp = _owners[Utils.encode(stampID, stampSID)];
            require(lstamp.owner != address(0), "This specific stamp does not exist");
            Utils.GlobalElement storage gstamp = _elements[stampID];
            require(gstamp.copies >= 1, "This global stamp does not exist");
            require(gcard.t == Utils.ElementType.card && gstamp.t == Utils.ElementType.stamp, "Incorrect types");
            require(lstamp.twin == 0 && lstamp.twinSid == 0 && card.twin == 0 && card.twinSid == 0, "Card or Stamp already attached");
            require(card.owner == msg.sender && lstamp.owner == msg.sender, "You are not the owner");
            require(lstamp.used == false, "Stamp has already been used");
            lstamp.used = true;
            lstamp.twin = cardID;
            lstamp.twinSid = cardSID;
            card.twin = stampID;
            card.twinSid = stampSID;
            emit Stamp(msg.sender, Utils.encode(stampID, stampSID), Utils.encode(cardID, cardSID), keccak256(bytes(Utils.encode(stampID, stampSID))), keccak256(bytes(Utils.encode(cardID, cardSID))));
        }
    }

    function unstamp(uint256 id, uint256 sid) public {
        Utils.Element storage elementA = _owners[Utils.encode(id, sid)];
        require(elementA.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage gElementA = _elements[id];
        require(gElementA.copies >= 1, "This global element does not exist");
        Utils.Element storage elementB = _owners[Utils.encode(elementA.twin, elementA.twinSid)];
        require(elementB.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage gElementB = _elements[elementA.twin];
        require(gElementB.copies >= 1, "This global element does not exist");
        require(elementA.owner == msg.sender && elementB.owner == msg.sender, "You are not the owner");
        require(elementB.twin == id && elementB.twinSid == sid, "Elements are not attached together");
        if(gElementA.t == Utils.ElementType.card){
            emit Unstamp(msg.sender, Utils.encode(elementA.twin, elementA.twinSid), Utils.encode(id, sid), keccak256(bytes(Utils.encode(elementA.twin, elementA.twinSid))), keccak256(bytes(Utils.encode(id, sid))));
        }else{
            emit Unstamp(msg.sender, Utils.encode(id, sid), Utils.encode(elementA.twin, elementA.twinSid), keccak256(bytes(Utils.encode(id, sid))), keccak256(bytes(Utils.encode(elementA.twin, elementA.twinSid))));
        }
        elementA.twin = 0;
        elementA.twinSid = 0;
        elementB.twin = 0;
        elementB.twinSid = 0;
    }

    function burn(uint256[2][] calldata elementsToBurn) external {
        for(uint256 i = 0;i<elementsToBurn.length;i++){
            uint256 id = elementsToBurn[i][0];
            uint256 sid = elementsToBurn[i][1];
            Utils.Element storage element = _owners[Utils.encode(id, sid)];
            require(element.owner != address(0), "This specific element does not exist");
            Utils.GlobalElement storage global = _elements[id];
            require(global.copies >= 1, "This global element does not exist");
            require(element.owner == msg.sender, "The sender is not the owner");
            if(element.twin != 0){
                unstamp(id, sid);
            }
            delete _owners[Utils.encode(id, sid)];
            emit Burn(msg.sender, id, sid, global.copies);
        }
    }

    function withdraw() external onlyOwner{
        uint256 daiAmount = ERC20(dai).balanceOf(address(this));
        uint256 usdcAmount = ERC20(usdc).balanceOf(address(this));
        ERC20(dai).transfer(msg.sender, daiAmount);
        ERC20(usdc).transfer(msg.sender, usdcAmount);
        emit Withdraw(msg.sender, daiAmount, usdcAmount);
    }

    function setPrice(address newPrice) external onlyOwner{
        price = newPrice;
        emit NewPrice(msg.sender, newPrice);
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
        emit Marketplace(msg.sender, _marketplace);
    }

    function approve(address to, uint256 id, uint256 sid) external {
        require(to != msg.sender, "Sender cannot be equal to the approved"); 
        require(to != address(0), "To cannot be null");
        require(sid != 0, "SID cannot be null");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == msg.sender || msg.sender == _tokenApprovals[Utils.encode(id, sid)] || _operatorApprovals[element.owner][msg.sender], "The granter is not the owner");
        _tokenApprovals[Utils.encode(id, sid)] = to;
        emit Approval(element.owner, to, Utils.encode(id, sid));
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "operator cannot be null");
        require(operator != msg.sender, "Sender cannot be equal to the operator"); 
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 id, uint256 sid) external view returns(address) {
        return _tokenApprovals[Utils.encode(id, sid)];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns(bool){
        return _operatorApprovals[_owner][_operator];
    }

    function ownerOf(uint256 id, uint256 sid) external view returns(address) {
        return _owners[Utils.encode(id, sid)].owner;
    }

    function getGlobal(uint256 id) external view returns(Utils.GlobalElement memory){
        return _elements[id];
    }

    function getElement(uint256 id, uint256 sid) external view returns (Utils.Element memory) {
        return _owners[Utils.encode(id, sid)];
    }

    function attached(uint256 id, uint256 sid) external view returns(uint256[2] memory) {
        uint256[2] memory _ids;
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        _ids[0] = element.twin;
        _ids[1] = element.twinSid;
        return _ids;
    }

    function uri(uint256 id) external view returns(bytes memory) {
        return _elements[id].cid;
    }

    function messageUri(uint256 id, uint256 sid) external view returns (bytes memory){
        return _owners[Utils.encode(id, sid)].messageCID;
    }

    function copies(uint256 id) external view returns (uint256){
        return _elements[id].copies;
    }
    
    function creator(uint256 id) external view returns(address) {
        return _elements[id].creator;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Price {

    modifier correctQuantity(uint256 quantity){
        require(quantity >= 1, "Cannot get a price less than one");
        _;
    }

    function cardPrice(uint256 copies) external pure correctQuantity(copies) returns(uint256) {
        if (copies <= 4) {
            return 4.667*10**18*copies;
        }else if (copies <= 10) {
            return 3.667*10**18*copies;
        }else if (copies <= 20) {
            return 2.980*10**18*copies;
        }else if (copies <= 100) {
            return 2.3*10**18*copies;
        }else{
            return 2*10**18;
        }
    }

    function stampPrice() external pure returns(uint256) {
        return 0.5*10**18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Harfang.sol";
library Utils {
    enum ElementType {
        card,
        stamp
    }

    enum MarketplaceActionType {
        Auction,
        Direct,
        Bid,
        Offer
    }

    enum Currency {
        usdc,
        dai
    }

    struct Price {
        uint256 price;
        Currency currency;
    }

    struct MarketplaceAction {
        MarketplaceActionType t;
        uint256 id;
        uint256 sid;
        address concerned;
        Price price;
        address highestBidder;
        uint256 ends;
    }

    struct Element {
        address owner;
        uint256 twin;
        uint256 twinSid;
        bytes messageCID;
        bool used;
    }

    struct GlobalElement {
        address creator;
        bytes cid;
        uint256 copies;
        ElementType t;
        uint256 lastId;
    }

    function createGlobalElement(bytes memory cid, uint256 copies, ElementType t, address owner) internal pure returns(GlobalElement memory){
        return GlobalElement(
            owner, // creator
            cid, // uri
            copies, // copies
            t, // type
            0 // lastId
        );
    }

    function createLocalElement(address owner) internal pure returns(Element memory){
        return Element(
            owner, // owner
            0, // twin
            0, // twin sid
            "", // message
            false // used
        );
    }

    function encode(uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(abi.encodePacked(Strings.toString(x),"-"),Strings.toString(y)));
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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