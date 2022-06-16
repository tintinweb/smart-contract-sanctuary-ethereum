// SPDX-License-Identifier: MIT
// Network: BSC test

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract aura_alfa is ERC1155Supply, Ownable  {
    bool public pausedSale = true;
    bool public isAllowListActive = false;
    uint private currentID = 1;
    uint constant MAX_AURA_PER_PURCHASE = 1; 
    uint[] private MAX_AURA = new uint256[](10);
    uint private PriceWL = 0.001 ether; //BNB
    uint[] public price = new uint[](10);   
    uint256 public StartSale;
    uint256 private modi;
    uint256 public reserve = 0;
    event Minted(uint256 _totalSupply); 
    string public name;
    string public symbol;   

    struct Users {
      uint256 balance;
      uint256 countref;
      address[] myref;
      bool[] _auto; 
      bool[] status; 
      bool qalification;
      uint256[] date;
      uint[] _type;
      uint256[] _sum;
      uint256[] _dynrew;
    }

    struct Level {
      uint256 countpay;
      uint256 countid;
      address[] line;
    }

    struct Box {
      address[] all_user;
    }

    mapping(address => uint8) private _allowList;
    mapping(address => Users) private _users;
    mapping(uint => Level) private _level;
    mapping(uint256 => Box) private _box;

    address public w1 = 0xd811459dad4e973dD905857CCFa57Ec3A71c5179;
    address public w2 = 0x8f56d93987659016071e3864B3EE3F3F4a8446Da;
    address wDev;
    address public wStat = 0xE098Ad7d2E174Cb343Eb2E8284ACB1eaD076D8C0;

constructor(string memory _uri, string memory _name, string memory _symbol, uint256 _StartSale, uint256 _modi, address _wDev, uint256 _MAX_AURA) ERC1155(_uri) {
    name = _name;
    symbol = _symbol;
    StartSale = _StartSale;
    modi = _modi;
    wDev = _wDev;
    price[0] = 0.012 ether;
    MAX_AURA[0] = _MAX_AURA;
    Users storage user = _users[wDev];
    Level storage level = _level[0];
    Box storage box = _box[0];
    box.all_user.push(wDev);

    user.balance = 0;
    user.countref = 0;
    user._auto.push(true);
    user.status.push(false);
    user.qalification = false;
    user = _users[wStat];

    user.balance = 0;
    user.countref = 0;
    user._auto.push(true);
    user.status.push(false);
    user.qalification = false;
    level.countpay = 0;
    level.countid = 0;
    for (uint i = 1; i < 10; i++) {
        price[i] = price[i - 1] * 2;
        MAX_AURA[i] = MAX_AURA[i - 1] / 2;
        user = _users[wDev];
        user._auto.push(true);
        user.status.push(false);
        user = _users[wStat];
        user._auto.push(true);
        user.status.push(false);
        _level[i].countpay = 0; 
        _level[i].countid = 0;  
    }
    _mint(wDev, currentID, 1, "");
    emit Minted(totalSupply(currentID));
    }

// Mint for WhiteList
    function mintAllowList(uint8 numberOfTokens) external payable {
    currentID = 1;    
    require(msg.sender != wStat, "Error! The address is intended for collecting statistics!");
    require(isAllowListActive, "Allow list is not active");
    require(block.timestamp < StartSale, "The minting of tokens according to the white lists is completed!");
    require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
    require(totalSupply(1) + numberOfTokens <= MAX_AURA[0], "Purchase would exceed max supply of tokens");
    require(PriceWL * numberOfTokens <= msg.value, "Ether value sent is not correct");
    _allowList[msg.sender] -= numberOfTokens;
    _mint(msg.sender, 1, numberOfTokens, "");
    emit Minted(totalSupply(1));
 }

//Mint
    function mint(uint numberOfTokens, uint tokenID, address refadd) external payable {
    currentID = tokenID;
    require(msg.sender != wStat, "Error! The address is intended for collecting statistics!");
    require(((currentID > 0)&&(currentID < 11)), "Invalid token ID entered!");
    require(pausedSale, "Sale must be active to mint Tokens");
    require(block.timestamp > StartSale, "The time to start the sale of tokens has not come!");
    require(numberOfTokens <= MAX_AURA_PER_PURCHASE, "Exceeded max token purchase");
    require((totalSupply(currentID) + numberOfTokens) <= MAX_AURA[currentID - 1], "Purchase would exceed max supply of tokens");
    require(price[currentID - 1] * numberOfTokens <= msg.value, "Ether value sent is not correct");

    bool ref = false;
    bool newal = false;
    Users storage user;
    Box storage box = _box[0];
    user = _users[msg.sender];
    user.date.push(block.timestamp);
    user._type.push(10);
    user._sum.push(0);
    user._dynrew.push(0);

    if (currentID == 1){
        if (balanceOf(refadd, currentID) > 0) {ref = true;} 
        for (uint i = 1; i < 11; i++){
            if (balanceOf(msg.sender, i) > 0) {
            newal = true;
            i = 11;} 
        }
        
       //FOR TEST
        _mint(msg.sender, currentID, numberOfTokens, "");
        emit Minted(totalSupply(currentID));
 
    if ((!ref)&&(!newal)) {
    //w1 address for collecting direct sales statistics
    user = _users[wStat];
    user.myref.push(msg.sender);
    user.countref += 1;
    user.balance += price[0];
    user.date.push(block.timestamp);
    user._sum.push(price[0]);
    user._dynrew.push(user.balance);
    user._type.push(85);
    user = _users[msg.sender];
    box.all_user.push(msg.sender);
    user.balance = 0;
    user.countref = 0;
    for (uint i = 0; i < 10; i++) {
    user._auto.push(true);
    user.status.push(false);
    }
    user.qalification = false;

    }

    if ((ref)&&(!newal)) {
    box.all_user.push(msg.sender);
    user = _users[refadd];
    user.myref.push(msg.sender);
    user.countref += 1;
    if (!user.qalification) {
        user.balance += price[0];
        reserve += price[0];
    user.date.push(block.timestamp);
    user._type.push(84);
    user._sum.push(price[0]);
    user._dynrew.push(user.balance);
            if (user.countref == 2) {
                user.qalification = true; 
                    user.date.push(block.timestamp);
                    user._sum.push(0);
                    user._dynrew.push(user.balance);
                    user._type.push(82);
                user.balance -= price[0];
                reserve -= price[0];
                user._dynrew.push(user.balance);
                user._sum.push(price[0]); 
                startLine(refadd, 1);   
                }
    }
    else {
        user.balance += (price[0] / 2);
        reserve += (price[0] / 2);
    user.date.push(block.timestamp);
    user._type.push(83);
    user._sum.push(price[0] / 2);
    user._dynrew.push(user.balance);
    }

    user = _users[msg.sender];
    user.balance = 0;
    user.countref = 0;
    for (uint i = 0; i < 10; i++) {
    user._auto.push(true);
    user.status.push(false);
    }
    user.qalification = false;
    }
   }
   else {
// for currentID > 1
    user = _users[msg.sender];
    require(user.qalification, "Error! You are not qualified!");
    uint _i = currentID;
    for (uint i = 1; i <= currentID; i++){
            if (balanceOf(msg.sender, i)==0){
            _i = i;
            i = currentID;
            }
        }
        require(currentID == _i, "Error! There are no NFTs of previous levels in your chain!");
        _mint(msg.sender, currentID, numberOfTokens, "");
        emit Minted(totalSupply(currentID));
        user.date.push(block.timestamp);
        user._type.push(9 + currentID);
        user._sum.push(0);
        user._dynrew.push(0);
        //user = _users[msg.sender];
        if ((!user.status[currentID - 1])&&(user._auto[currentID - 1])){
            user._dynrew.push(user.balance);
            user._sum.push(0); 
            startLine(msg.sender, currentID);
        }

   }
}

//Turbo qualification
function turbo() external payable {
    Users storage user;
    user = _users[msg.sender];
    require(!user.qalification, "You are already qualified!");
    require(balanceOf(msg.sender, 1) > 0, "You don't have level 1 NFTs!");
    require(price[0] * 2 <= msg.value, "Ether value sent is not correct");
    user.qalification = true;
    user.date.push(block.timestamp);
    user._sum.push(0);
    user._dynrew.push(user.balance);
    user._type.push(81);
    user._dynrew.push(user.balance);
    user._sum.push(0); 
    startLine(msg.sender, 1);
}

//Auto 
function autoR (uint _num, bool select) external payable { //0..9
    require(msg.sender != wStat, "Error! The address is intended for collecting statistics!");
    require(((_num > 0)&&(_num < 11)), "Invalid token ID entered!");
    Users storage user;
    user = _users[msg.sender];
    uint _i = _num;
        for (uint i = 1; i <= _num; i++){
            if (balanceOf(msg.sender, i)==0){
            _i = i;
            i = _num;
            }
        }
        require(_num == _i, "Error! There are no NFTs of previous levels in your chain!");
  
    if (user.status[_num - 1]){
        user._auto[_num - 1] = !user._auto[_num - 1]; 
        user.date.push(block.timestamp);
        user._sum.push(0);
        user._dynrew.push(user.balance);
        if (user._auto[_num - 1]) {user._type.push(59 + _num);}
        else {user._type.push(49 + _num);}
    }
    else {
        require(user.qalification, "Error! You are not qualified!");
        //require(!user._auto[_num - 1], "Error! System 0x1.");  

        if (select) {
         //localBalance   
        require(price[_num - 1] <= user.balance, "There are not enough funds on your balance in the Aura system!");
        user.date.push(block.timestamp);
        user._sum.push(price[_num - 1]);
        user._dynrew.push(user.balance);
        user._type.push(89 + _num);
        user.balance -= price[_num - 1];
        user._auto[_num - 1] = !user._auto[_num - 1]; //on auto
        user._dynrew.push(user.balance);
        user._sum.push(price[_num - 1]); 
        startLine(msg.sender, _num);
        }
        else {
        //tx
        require(price[_num - 1] <= msg.value, "Ether value sent is not correct");  
        user.date.push(block.timestamp);
        user._sum.push(0);
        user._dynrew.push(user.balance);
        user._type.push(69 + _num);  
        user._auto[_num - 1] = !user._auto[_num - 1]; //on auto
        user._dynrew.push(user.balance);
        user._sum.push(0); 
        startLine(msg.sender, _num);
        }
        }  
}

//Start Line

function startLine (address _toLine, uint _num) internal {
Level storage level;
Users storage user;
uint _i = _num;
level = _level[_num - 1];
level.line.push(_toLine);
user = _users[_toLine];
level.countid += 1;
user.date.push(block.timestamp);
user._type.push(19 + _num);
//////////////////////////////////////////////////////*///////////////////////////////
//bool[] memory _stat = new bool[](10); 
//_stat = user.status;
//_stat[_num - 1] = true;
//user.status = _stat;
user.status[_num - 1] = true;
/////////////////////////*******************//////////////////////////////// */
if ((level.countid > 0)&&(level.countid % 3==0)) {
    address x = level.line[level.countpay];
    user = _users[x];
     for (uint i = 1; i <= _num; i++){
            if (balanceOf(msg.sender, i)==0){
            _i = i;
            i = _num;
            }
        }
    if (_i == _num){
    if (user._auto[_num - 1]){
        user.balance += price[_num - 1];
        reserve += price[_num - 1];
        level.line.push(x);
        level.countid += 1;  
        user._sum.push(price[_num - 1]); 
        user._type.push(29 + _num);
    }
    else {
        user.balance += (2 * price[_num - 1]);
        reserve += (2 * price[_num - 1]);
        //_stat = user.status;
        //_stat[_num - 1] = false; 
        //user.status = _stat;
        user.status[_num - 1] = true;
        user._sum.push((2 * price[_num - 1]));
        user._type.push(39 + _num);
    }
    }
level.countpay += 1;
        user.date.push(block.timestamp);
        user._dynrew.push(user.balance);
}
}

//Pause or starting a sale
    function pause() public onlyOwner {
        pausedSale = !pausedSale;
    }

//Config WhiteList
    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

//Active WL
    function setIsAllowListActive() public onlyOwner {
    isAllowListActive = !isAllowListActive;
    }

//Only view WL
    function numAvailableToMint(address addr) external view returns (uint8) {
    return _allowList[addr];
    }

//Price for WL
function getPriceWL() public view returns (uint256) {
        return PriceWL;
    }

//Set price for WL
function setPriceWL(uint256 newprice) public onlyOwner {
        PriceWL = newprice;
    }

//Set price
function setPrice(uint256[] calldata newprice) public onlyOwner { //достаточно сделать начальную цену
        price = newprice;
    }

//The time to start the sale of tokens UNIX Time
function getStartTime() public view returns (uint256) {
    return StartSale;
    }

//Set setting the start time of the token sale
function setStartTime(uint256 newTime) public onlyOwner {
    StartSale = newTime;
    }

//Set URI
function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
    }

//URI
function uri(uint256 _id) public view override returns (string memory) {
    require(exists(_id), "URI: nonexistent token");
    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

//Giveaway
    function giveAway(address _to, uint numberOfTokens, uint _currentID) external onlyOwner() {
    currentID = _currentID;
    require(_to != wStat, "Error! The address is intended for collecting statistics!");
    require(((currentID > 0)&&(currentID < 11)), "Invalid token ID entered!");
    require(totalSupply(currentID) + numberOfTokens <= MAX_AURA[currentID], "Purchase would exceed max supply of tokens");
    _mint(_to, currentID, numberOfTokens, "");
    emit Minted(totalSupply(currentID));
    }

//View users
function getUsers() public view returns (address[] memory) {
    Box storage box = _box[0];
    return box.all_user;
    }

//View my balance
function getReward(address myadd) public view returns (uint256) {
    Users storage user = _users[myadd];
    return user.balance;
    }

//View my counter 
function getCountref(address myadd) public view returns (uint256) {
    Users storage user = _users[myadd];
    return user.countref;
    }

//View my auto 
function getAuto(address myadd) public view returns (bool[] memory) {
    Users storage user = _users[myadd];
    return user._auto;
    }

//View tree
function getTree(address myadd) public view returns (address[] memory) {
    return _users[myadd].myref; 
 }

//My status
function getStatus(address myadd) public view returns (bool[] memory) {
    return _users[myadd].status; 
 }

 //View tree
function getQ(address myadd) public view returns (bool) {
    return _users[myadd].qalification; 
 }

 //View levelInfo
function getLevelCount(uint _num) public view returns (uint256) {
    return _level[_num].countpay; 
 }

 //View levelInfo
function getLevelCountId(uint _num) public view returns (uint256) {
    return _level[_num].countid; 
 }

 //View levelInfo
function getLevelLine(uint _num) public view returns (address[] memory) {
    return _level[_num].line; 
 }

//Date Statistics
function getStat1(address myadd) public view returns (uint256[] memory) {
    return _users[myadd].date; 
 }

//Type tx Statistics
function getStat2(address myadd) public view returns (uint[] memory) {
    return _users[myadd]._type; 
 }

 //Date Statistics
function getStat3(address myadd) public view returns (uint256[] memory) {
    return _users[myadd]._sum; 
 }

 //Date Statistics
function getStat4(address myadd) public view returns (uint256[] memory) {
    return _users[myadd]._dynrew; 
 }
//withdraw BNB for owner
   function withdrawAll() public payable onlyOwner {
    uint256 _per = 0;
    if (modi < block.timestamp) { //2592000 for 30 days
            _per = address(this).balance / 100;
    }
    else if ((address(this).balance - reserve) > 0) {
        _per = (address(this).balance - reserve) / 100;
    }
    require(_per > 0, "Your balance has no funds to withdraw!");
    uint256 _part1 = _per * 65;
    uint256 _part2 = _per * 35;
    Users storage user = _users[wStat];
    user.date.push(block.timestamp);
    user._sum.push(_per * 100);
    user._dynrew.push(user.balance);
    user._type.push(86);
    require(payable(w1).send(_part1));
    require(payable(w2).send(_part2));
  }

//withdraw BNB for all
   function myWithdraw() external payable {
    Users storage user = _users[msg.sender];
    uint256 _per = user.balance;
    require(((msg.sender != w1)&&(msg.sender != w2)&&(msg.sender != wStat)), "Developer addresses cannot participate in the system! Withdrawal prohibited!");
    require(user.qalification, "Error! You are not qualified!");
    require(_per > 0, "Your balance has no funds to withdraw!");
    user.balance = 0;
    reserve -= _per;
    user.date.push(block.timestamp);
    user._sum.push(_per);
    user._dynrew.push(user.balance);
    user._type.push(80);
    require(payable(msg.sender).send(_per));
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

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}