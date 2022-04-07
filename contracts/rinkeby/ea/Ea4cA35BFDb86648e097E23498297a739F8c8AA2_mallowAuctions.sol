// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./teste_3.sol";
import "./Strings.sol";
import "./IFirepit.sol";

contract mallowAuctions is Ownable{
    using Strings for uint;
    
    event auctionEntry(address indexed _user, uint256 indexed _auctionID, uint256 _entryPrice, uint256 _entryTime);
    
    struct Auction{
        uint256 id;
        uint auctionType;   //0: normal, 1: dutch
        string projectName;
        uint256 startTime;
        uint256 dutchPriceRate;
        uint256 dutchTimeRate;
        uint256 startPrice;
        uint256 minPrice;
        string imgSrc;
        string discordLink;
        string twitterLink;
        uint256 maxWhitelists;
        uint256 req;
        bool exists;
    }
    struct AllInfoRequest{
        Auction auction;
        address[] wlArray;
        uint256 price;
        bool isWL;
    }
    enum State{
        OPEN,
        CLOSED,
        UPCOMING,
        REMOVED
    }

    uint256 public totalAuctions = 0;
    address signer = 0xeFB45a786C8A9fE6D53DdE0E3A4DB6aF54C73DA7;
    mapping(address => bool) public isApprovedAddress;
    mapping(string => bool) public auctionExists;
    mapping(uint256 => Auction) auctionSettings; // map id => auction settings
    mapping(uint256 => address[]) whitelists; // auction id => to WL users
    
    teste_3 public loveContract;   //Reference to LOVE contract
    IFirepit public firepitContract; //Reference to metaMallow contract

    modifier onlyApprovedAddresses{
        require(isApprovedAddress[msg.sender], "UNAUTHORIZED");
        _;
    }
    function setDependency(address _loveAddress, address _firepitAddress) external onlyOwner{
        loveContract = teste_3(_loveAddress);
        firepitContract = IFirepit(_firepitAddress);
    }
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
    function enterAuction(uint256 _auctionId, uint256[] calldata _tokenIds, bytes calldata _signature) external {
        require(auctionSettings[_auctionId].exists, "Auction does not exist or removed");
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, _tokenIds, _auctionId))), _signature) == signer, "INVALID SIGNATURE");
        require(getAuctionState(_auctionId) == State.OPEN, "Auction not open");
        require(!isWhitelisted(msg.sender,_auctionId), "Already whiteListed");
        require(_tokenIds.length >= auctionSettings[_auctionId].req, "Insufficient requirements");
        require(firepitContract.isOwnerOfStakedTokens(_tokenIds, msg.sender), "Not owner of staked tokens");
        uint256 auctionPrice = getCurrentPrice(_auctionId);
        require(loveContract.balanceOf(msg.sender) >= auctionPrice *1 ether, "Not enough LOVE");
        loveContract.burn(msg.sender, auctionPrice * 1 ether);
        whitelists[_auctionId].push(msg.sender);
        emit auctionEntry(msg.sender,_auctionId, auctionPrice, block.timestamp);
    }
    function createDutch (string memory _projectName, uint256 _startTime, uint _dutchRate, uint256 _timeRate, uint256 _startPrice, 
    uint256 _minPrice, string memory _imgSrcLink, string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists, uint256 _req) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name already defined");
        require(!auctionSettings[totalAuctions].exists,"Auction already exists");
        require(_startTime > 0 ,"Incorret time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_minPrice > 0 ,"Incorret min price value");
        require(_maxWhitelists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 1,   //dutch type
            projectName: _projectName,
            startTime: _startTime,
            dutchPriceRate: _dutchRate,
            dutchTimeRate: _timeRate,
            startPrice: _startPrice,
            minPrice: _minPrice,
            imgSrc: _imgSrcLink,
            discordLink: _discordLink,
            twitterLink: _twitterLink,
            maxWhitelists: _maxWhitelists,
            req: _req,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    function createBuyNow (string memory _projectName, uint _startTime, uint256 _startPrice, string memory _imgSrcLink, 
    string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists, uint256 _req) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name already defined");
        require(!auctionSettings[totalAuctions].exists,"Auction already exists");
        require(_startTime > 0 ,"Incorret time value");
        require(_startPrice > 0 ,"Incorret start price value");
        //require(_maxWhitelists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 0,   //buy now type
            projectName: _projectName,
            startTime: _startTime,
            dutchPriceRate: 0,
            dutchTimeRate: 0,
            startPrice: _startPrice,
            minPrice: _startPrice,
            imgSrc: _imgSrcLink,
            discordLink: _discordLink,
            twitterLink: _twitterLink,
            maxWhitelists: _maxWhitelists,
            req: _req,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    function updateAuction(uint256 _auctionId, string memory _projectName, uint256 _startTime, uint _dutchRate,uint256 _timeRate, uint256 _startPrice, 
    uint256 _minPrice, string memory _imgSrcLink, string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists, uint256 _req) external onlyApprovedAddresses{
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        auctionSettings[_auctionId].projectName = _projectName;
        auctionSettings[_auctionId].startTime = _startTime;
        auctionSettings[_auctionId].dutchPriceRate = _dutchRate;
        auctionSettings[_auctionId].dutchTimeRate = _timeRate;
        auctionSettings[_auctionId].startPrice = _startPrice;
        auctionSettings[_auctionId].minPrice = _minPrice;
        auctionSettings[_auctionId].imgSrc = _imgSrcLink;
        auctionSettings[_auctionId].discordLink = _discordLink;
        auctionSettings[_auctionId].twitterLink = _twitterLink;
        auctionSettings[_auctionId].maxWhitelists = _maxWhitelists;
        auctionSettings[_auctionId].req = _req;
    }
    function removeAuction(uint256 _auctionId) external onlyApprovedAddresses{
        auctionSettings[_auctionId].exists = false;
    }
    //VIEW FUNCTIONS
    function getAuctionState(uint256 _auctionId) public view returns (State){
        if(!auctionSettings[_auctionId].exists) return State.REMOVED;
        if(block.timestamp >= auctionSettings[_auctionId].startTime){
            if( getAuctionWhitelists(_auctionId).length < auctionSettings[_auctionId].maxWhitelists){
                return State.OPEN;
            }
            else{
                return State.CLOSED;
            }
        }
        else{
            return State.UPCOMING;
        }
    }
    function getAuction(uint256 _auctionId) external view returns (Auction memory){
        return auctionSettings[_auctionId];
    }
    function getAuctionName(uint256 _auctionId) external view returns (string memory){
        return auctionSettings[_auctionId].projectName;
    }
    function getAuctionWhitelists(uint256 _auctionId) public view returns (address [] memory){
        return whitelists[_auctionId];
    }
    function getCurrentPrice(uint256 _auctionId) public view returns (uint256){
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        Auction memory auxAuction = auctionSettings[_auctionId];
        if(auxAuction.auctionType == 1){    //DUTCH auction
            if(block.timestamp < auxAuction.startTime){
                return auxAuction.startPrice;
            }
            uint256 reduction = (block.timestamp-auxAuction.startTime)/auxAuction.dutchTimeRate
            *auxAuction.dutchPriceRate;
            uint256 newPrice =  auxAuction.startPrice >= reduction ? 
            (auxAuction.startPrice - reduction) : 0;
            return newPrice >= auxAuction.minPrice ? newPrice : auxAuction.minPrice;
        }
        else{    //Buy now auction
            return auxAuction.startPrice;
        }
    }
    function isWhitelisted(address _wallet, uint256 _auctionId) public view returns (bool) {
        for (uint i = 0; i < whitelists[_auctionId].length; i++) {
            if (whitelists[_auctionId][i] == _wallet) {
                return true;
            }
        }
        return false;
    }
    function countTotalOpened() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.OPEN){
                count++;
            }
        }
        return count;
    }
    function countTotalClosed() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.CLOSED){
                count++;
            }
        }
        return count;
    }
    function countTotalUpcoming() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.UPCOMING){
                count++;
            }
        }
        return count;
    }
    function countTotalRemoved() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.REMOVED){
                count++;
            }
        }
        return count;
    }
    function getAuctionsOpened() public view returns (Auction[] memory){
        Auction[] memory opened = new Auction[](countTotalOpened());
        uint i =0;
        for(uint f = totalAuctions; f > 0; f--){
            if(getAuctionState(f-1) == State.OPEN){
                opened[i] = auctionSettings[f-1];
                i++;
            }
        }
        return opened;
    }
    function getAuctionsClosed() public view returns (Auction[] memory){
        Auction[] memory closed = new Auction[](countTotalClosed());
        uint i =0;
        for(uint f = totalAuctions; f > 0; f--){
            if(getAuctionState(f-1) == State.CLOSED){
                closed[i] = auctionSettings[f-1];
                i++;
            }
        }
        return closed;
    }
    function getAuctionsUpcoming() public view returns (Auction[] memory){
        Auction[] memory upcoming = new Auction[](countTotalUpcoming());
        uint i =0;
        for(uint f = totalAuctions; f > 0; f--){
            if(getAuctionState(f-1) == State.UPCOMING){
                upcoming[i] = auctionSettings[f-1];
                i++;
            }
        }
        return upcoming;
    }
    function getXAuctions(uint256 _start, uint256 _x, address _wallet) external view returns 
    (AllInfoRequest[] memory, AllInfoRequest[] memory, AllInfoRequest[] memory){
        Auction[] memory opened = getAuctionsOpened();
        Auction[] memory closed = getAuctionsClosed();
        Auction[] memory upcoming = getAuctionsUpcoming();
        AllInfoRequest[] memory Xopened = new AllInfoRequest[](_x);
        AllInfoRequest[] memory Xclosed = new AllInfoRequest[](_x);
        AllInfoRequest[] memory Xupcoming = new AllInfoRequest[](upcoming.length);
        uint t = 0;
        uint256 i;
        for(i = _start; i < _x + _start; i++){
            if(i >= opened.length){
                break;
            }
            Xopened[t].auction = opened[i];
            Xopened[t].wlArray = getAuctionWhitelists(opened[i].id);
            Xopened[t].price = getCurrentPrice(opened[i].id);
            Xopened[t].isWL = isWhitelisted(_wallet,opened[i].id);
            t++;
        }
        t = 0;
        for(i; i < _x + _start; i++){
            if(i >= (closed.length + opened.length)){
                break;
            }
            Xclosed[t].auction = closed[i-opened.length];
            Xclosed[t].wlArray = getAuctionWhitelists(closed[i-opened.length].id);
            Xclosed[t].price = getCurrentPrice(closed[i-opened.length].id);
            Xclosed[t].isWL = isWhitelisted(_wallet,closed[i-opened.length].id);
            t++;
        }
        for(i = 0; i < upcoming.length; i++){
            Xupcoming[i].auction = upcoming[i];
            Xupcoming[i].wlArray = getAuctionWhitelists(upcoming[i].id);
            Xupcoming[i].price = getCurrentPrice(upcoming[i].id);
            Xupcoming[i].isWL = isWhitelisted(_wallet,upcoming[i].id);
        }
        return (Xopened, Xclosed, Xupcoming);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract teste_3 is ERC20, Ownable{

    mapping(address => bool) isApprovedAddress;

    constructor (
        string memory _name,
        string memory _symbol
    )ERC20(_name,_symbol){ }
    modifier onlyApprovedAddresses{
        require(isApprovedAddress[msg.sender], "You are not authorized!");
        _;
    }
    function mint(address _to, uint256 _amount) external onlyApprovedAddresses{
        _mint(_to, _amount);
    }
    function burn(address _to, uint256 _amount) external onlyApprovedAddresses{
        _burn(_to, _amount);
    }
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
    
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";
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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

interface IFirepit {
    function isOwnerOfStakedTokens(uint256[] calldata _tokenIds, address _owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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