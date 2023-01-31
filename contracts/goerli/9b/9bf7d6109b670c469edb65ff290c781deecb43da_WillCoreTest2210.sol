/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-10-22
*/

pragma solidity ^0.5.0;

/**
 * @title - K-Will
K  K     W     W III L    L    
K K      W     W  I  L    L    
KK   --- W  W  W  I  L    L    
K K       W W W   I  L    L    
K  K       W W   III LLLL LLLL 

 * ---
 *
 * POWERED BY K-group Corp.
 * 
 **/
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract AdminRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

contract WillAccessControl is AdminRole {

    /// @dev Emitted when contract is upgraded - See README.md for upgrade plan
    event ContractUpgrade(address newContract);

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract WillBase is WillAccessControl {
    /*** EVENTS ***/

    /// @dev The Birth event is fired whenever a new will comes into existence. This obviously
    ///  includes any time a will is created through the creatWill method.
    event MakingDate(
        address owner,
        uint256 id,
        string uniquewillId,
        string willNumber,
        string hash);

    /*** DATA TYPES ***/
    
    //enum willStatus {NONE, READY, TRANSFERRED, REJECTED}
    
    /** @dev The main will struct. */
    struct will {
        address owner;
        string hash;
        string uniquewillId;
        string willNumber;
        address minter;
    }
    
    will[] wills;
    
    /*struct Minter {
        string userName;
        uint256 userTax;
        string userAddress;
        string userWebsite;
        address userWallet;
    }
    Minter[] minters;*/
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

contract ERC721 is IERC165 {

    // IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    // IERC721Metadata
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) public view returns (string memory);

    // IERC721Enumerable
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract WillOwnership is ERC721, WillBase {

    using SafeMath for uint256;
    using Address for address;

    //------------------------------------

    // Token name
    string private constant _name = "Will";

    // Token symbol
    string private constant _symbol = "Will";

    // Token metadata base URI
    string private tokenMetadataBaseURI = "https://";

    //----------------------------------------------

    /// @dev Mapping from will ID to owner
    mapping (uint256 => address) internal willOwner;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedwillsCount;

    // Mapping from will ID to approved address
    mapping (uint256 => address) internal willApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    //------------------------------------------------

    // Mapping from owner to list of owned will IDs
    mapping(address => uint256[]) internal ownedwills;

    // Mapping from will ID to index of the owner wills list
    mapping(uint256 => uint256) internal ownedwillsIndex;

    // Array with all will ids, used for enumeration
    uint256[] internal allwills;

    // Mapping from will id to position in the allwills array
    mapping(uint256 => uint256) internal allwillsIndex;

    //------------------------------------------------

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7; // this.supportsInterface.selector
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256('balanceOf(address)')) ^
     *     bytes4(keccak256('ownerOf(uint256)')) ^
     *     bytes4(keccak256('approve(address,uint256)')) ^
     *     bytes4(keccak256('getApproved(uint256)')) ^
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *     bytes4(keccak256('name()')) ^
     *     bytes4(keccak256('symbol()')) ^
     *     bytes4(keccak256('tokenURI(uint256)'))
     */

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    /**
     * 0x780e9d63 ===
     *     bytes4(keccak256('totalSupply()')) ^
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
     *     bytes4(keccak256('tokenByIndex(uint256)'))
     */

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 constant _ERC721_RECEIVED = 0x150b7a02;

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((_INTERFACE_ID_ERC165 == 0x01ffc9a7)
        // && (_INTERFACE_ID_ERC721 == 0x80ac58cd)
        // && (_INTERFACE_ID_ERC721_METADATA = 0x5b5e139f)
        // && (_INTERFACE_ID_ERC721_METADATA = 0x780e9d63);

        return ((_interfaceID == _INTERFACE_ID_ERC165)
        || (_interfaceID == _INTERFACE_ID_ERC721)
        || (_interfaceID == _INTERFACE_ID_ERC721_METADATA)
        || (_interfaceID == _INTERFACE_ID_ERC721_ENUMERABLE));
    }

    /**
      * @dev Gets the balance of the specified address
      * @param _owner address to query the balance of
      * @return uint256 representing the amount owned by the passed address
      */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedwillsCount[_owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _willId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _willId) public view returns (address) {
        address owner = willOwner[_willId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _willId uint256 ID of the token to be approved
     */
    function approve(address _to, uint256 _willId) public {
        address owner = ownerOf(_willId);

        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        willApprovals[_willId] = _to;
        emit Approval(owner, _to, _willId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param _willId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 _willId) public view returns (address) {
        require(_exists(_willId));
        return willApprovals[_willId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param _to operator address to set the approval
     * @param _approved representing the status of the approval to be set
     */
    function setApprovalForAll(address _to, bool _approved) public whenNotPaused {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param _owner owner address which you want to query the approval of
     * @param _operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _willId uint256 ID of the token to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _willId) public whenNotPaused {

        require(_isApprovedOrOwner(msg.sender, _willId));

        _transferFrom(_from, _to, _willId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _willId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address _from, address _to, uint256 _willId) public whenNotPaused {
        safeTransferFrom(_from, _to, _willId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _willId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address _from, address _to, uint256 _willId, bytes memory _data) public whenNotPaused {
        transferFrom(_from, _to, _willId);
        require(_checkOnERC721Received(_from, _to, _willId, _data));
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _willId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function _exists(uint256 _willId) internal view returns (bool) {
        address owner = willOwner[_willId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _willId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address _spender, uint256 _willId) internal view returns (bool) {
        address owner = ownerOf(_willId);
        return (_spender == owner || getApproved(_willId) == _spender || isApprovedForAll(owner, _spender));
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _willId uint256 ID of the token to be transferred
    */
    function _transferFrom(address _from, address _to, uint256 _willId) internal {
        require(ownerOf(_willId) == _from);
        require(_to != address(0));

        _clearApproval(_willId);

        ownedwillsCount[_from] = ownedwillsCount[_from].sub(1);
        ownedwillsCount[_to] = ownedwillsCount[_to].add(1);

        willOwner[_willId] = _to;

        emit Transfer(_from, _to, _willId);

        _removeTokenFromOwnerEnumeration(_from, _willId);

        _addTokenToOwnerEnumeration(_to, _willId);
        
        wills[_willId].owner = _to;
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _willId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address _from, address _to, uint256 _willId, bytes memory _data)
    internal returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(_to).onERC721Received.gas(50000)(msg.sender, _from, _willId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID
     * @param _willId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 _willId) internal {
        if (willApprovals[_willId] != address(0)) {
            willApprovals[_willId] = address(0);
        }
    }

    //-------------------------------------------------------

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Sets metadata URI
     */
    function setTokenMetadataBaseURI(string calldata _newBaseURI) external onlyAdmin {
        tokenMetadataBaseURI = _newBaseURI;
    }

    /**
     * @dev Returns an URI for a given will ID
     * Throws if the will ID does not exist. May return an empty string.
     * @param _willId uint256 ID of the token to query
     */
    function tokenURI(uint256 _willId) public view returns (string memory infoUrl)
    {
        require(_exists(_willId));
        return Strings.strConcat(
            tokenMetadataBaseURI,
            Strings.uint2str(_willId));
    }

    //-------------------------------------------------------

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedwills[_owner][_index];
    }

    /**
     * @dev Gets the total amount of wills stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return allwills.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allwills[_index];
    }

    /**
     * @dev Gets the list of token IDs of the requested owner
     * @param _owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address _owner) internal view returns (uint256[] storage) {
        return ownedwills[_owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param _to address representing the new owner of the given token ID
     * @param _willId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address _to, uint256 _willId) internal {
        ownedwillsIndex[_willId] = ownedwills[_to].length;
        ownedwills[_to].push(_willId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param _willId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 _willId) internal {
        allwillsIndex[_willId] = allwills.length;
        allwills.push(_willId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param _from address representing the previous owner of the given token ID
     * @param _willId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address _from, uint256 _willId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastwillIndex = ownedwills[_from].length.sub(1);
        uint256 willIndex = ownedwillsIndex[_willId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (willIndex != lastwillIndex) {
            uint256 lastwillId = ownedwills[_from][lastwillIndex];

            ownedwills[_from][willIndex] = lastwillId; // Move the last token to the slot of the to-delete token
            ownedwillsIndex[lastwillId] = willIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        ownedwills[_from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occcupied by
        // lasTokenId, or just over the end of the array if the token was the last one).
    }
}

contract WillMaking is WillOwnership {

    /* @dev we can create new wills. Only callable by Captain
     * @param _category the categories of the will to be created, any value is accepted
     * @param _owner the future owner of the created wills. Default to contract Captain
     */
    function createNewwill(
        string calldata _hash,
        string calldata _uniquewillId,
        string calldata _willNumber,
        address _owner
        ) external {
        address willOwner = _owner;
        
        if (willOwner == address(0)) {
            willOwner = msg.sender;
        }
        // It's probably never going to happen, 4 willion wills is A LOT, but
        // let's just be 100% sure we never let this happen.
        //require(newwillId == uint256(uint32(newwillId)));
        //require(!_exists(newwillId));

        _creatWill(_hash, _uniquewillId, _willNumber, willOwner);
    }
    
    //event NewwillStatusUpdated(uint256 willId, willStatus newStatus);
    
    /*function setwillStatus(uint256 _willId, willStatus _newStatus) external {
        require(_exists(_willId));
        
        uint256 index = allwillsIndex[_willId];
        will storage will = wills[index];
        
        will.status = _newStatus;
        
        emit NewwillStatusUpdated(_willId, _newStatus);
    }*/
    
    /* @dev An internal method that creates a new will and stores it. This
     *  method doesn't do any checking and should only be called when the
     *  input data is known to be valid. Will generate both a Birth event
     *  and a Transfer event.
     * @param _willId The id of will
     * @param _owner The inital owner of this will, must be non-zero (except for the unwill, ID 0)
     */
    function _creatWill(
        string memory _hash,
        string memory _uniquewillId,
        string memory _willNumber,
        address _owner
    ) internal returns (uint){
        
        will memory _will = will({
            owner: _owner, hash: _hash, uniquewillId: _uniquewillId, willNumber: _willNumber, minter: msg.sender 
            });
        uint256 newwillId = wills.length;

        wills.push(_will);

        // emit the birth event
        emit MakingDate(_owner, newwillId, _uniquewillId, _willNumber, _hash);

        // This will assign ownership, and also emit the Transfer event as per ERC721
        _mint(_owner, newwillId);

        return newwillId;
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param _to The address that will own the minted token
     * @param _newwillId uint256 ID of the token to be minted
     */
    function _mint(address _to, uint256 _newwillId) internal {
        willOwner[_newwillId] = _to;
        ownedwillsCount[_to] = ownedwillsCount[_to].add(1);

        emit Transfer(address(0), _to, _newwillId);

        _addTokenToOwnerEnumeration(_to, _newwillId);

        _addTokenToAllTokensEnumeration(_newwillId);
    }
}

contract WillCoreTest2210 is WillMaking {
    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

        /// @notice Creates the main will smart contract instance.
    constructor() public {
        // start with the mythical will 0
        _creatWill("none", "none", "none", msg.sender);
    }

    /* @dev Used to mark the smart contract as upgraded, in case there is a serious
     *  breaking bug. This method does nothing but keep track of the new contract and
     *  emit a message indicating that the new address is set. It's up to clients of this
     *  contract to update to the new contract address in that case. (This contract will
     *  be paused indefinitely if such an upgrade takes place.)
     * @param _v2Address new address
     */
    function setNewAddress(address _v2Address) external onlyAdmin whenPaused {
        // See README.md for upgrade plan
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    /** @notice No tipping!
     * @dev Reject all Ether from being sent here, unless it's from one of the
     *  two auction contracts. (Hopefully, we can prevent user accidents.)
     */
    function() external payable {}

    /** @notice Returns all the relevant information about a specific will.
     * @param _willId The ID of the will of interest.
     */
    function getwill(uint256 _willId)
    external
    view
    returns (address owner, string memory hash, string memory uniquewillId, string memory willNumber, address minter) {
        uint256 index = allwillsIndex[_willId];
        will storage will = wills[index];
        
        owner = will.owner;
        hash = will.hash;
        uniquewillId = will.uniquewillId;
        willNumber = will.willNumber;
        minter = will.minter;
    }

    /* @dev Override unpause so it requires all external contract addresses
     *  to be set before contract can be unpaused. Also, we can't have
     *  newContractAddress set either, because then the contract was upgraded.
     * @notice This is public rather than external so we can call super.unpause
     *  without using an expensive CALL.
     */
    function unpause() public onlyAdmin whenPaused {
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the pilot to capture the balance available to the contract.
    function withdrawBalance() external onlyAdmin {
        uint256 balance = address(this).balance;

        msg.sender.transfer(balance);
    }
}