/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
contract erc721{
string Name;
string Symbol;
//events
event Transfer(address indexed from, address indexed to, uint indexed id);
event Approval(address indexed owner, address indexed spender, uint indexed id);
event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
);
//to store owners
mapping (uint => address) OwnerIs;
//return no. of NFTs owned by a particular addres
mapping (address => uint) BalanceIs;
//return bool, is an operator or sender is allowed by owner
mapping (address => mapping(address => bool)) isApprovedbyOwnerForAll;
/// approved addresses by owner
mapping (uint => address) approved;
///return url which cootains data about any particular NFT ,(which is any IPFS url that returns NFT metadata.)
mapping (uint => string) TokenMetaData;

constructor(string memory _name, string memory _symbol){
    Name = _name;
    Symbol = _symbol;
}

////modifiers
modifier address_exist(address _addr){
    require(_addr != address(0), 'Invalid address!');
    _;
}

modifier validate_addresses(address _spender,address _owner, uint _id){
    require(OwnerIs[_id]==_owner ,"owner passed in '_from' has no property with this '_id' to transfer!");
    require(approved[_id] == _owner || approved[_id] == _spender || _owner == _spender || isApprovedbyOwnerForAll[_owner][_spender],'Not authorized to make a transfer!');
    _;
}

modifier owner_check(address _owner, uint _id){
    require(OwnerIs[_id] == _owner,'Only owner can authorize the spender!');
    _;
}
//functions 
///for contract testing
function deposit(uint _token_id) public {
    OwnerIs[_token_id] = msg.sender;
    BalanceIs[msg.sender] ++;
}  

function balance_of() public view returns(uint balance){
    require(BalanceIs[msg.sender]>0,'Owner has no-fungible property!');
    balance = BalanceIs[msg.sender]; 
}
function get_name() public view returns(string memory)
{  
    return Name;
}
function get_symbol() public view returns(string memory)
{  
    return Symbol;
}
function set_Token_url(uint _token_id, string memory _token_url) public {
    TokenMetaData[_token_id] = _token_url;
}
function get_Token_url(uint _token_id) public view returns(string memory){
    return TokenMetaData[_token_id];
}

function owner_of(uint _token_id) public view returns(address owner)
{
    require(OwnerIs[_token_id] != address(0) ,'No owner exist with that NFT id!');
    owner = OwnerIs[_token_id];
}

function TransferFrom(address _from, address _to, uint _token_id) address_exist(_to) validate_addresses(msg.sender,_from, _token_id) public {
    OwnerIs[_token_id] = _to;
    BalanceIs[_to] ++;
    BalanceIs[_from] --;
    delete approved[_token_id];
}
//when transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.

//with DATA
function SafeTransferFrom(address _from, address _to, uint _token_id,bytes calldata _data)  public{
TransferFrom(_from, _to, _token_id);
   require(
            _to.code.length == 0 ||
                IERC721Receiver(_to).onERC721Received(msg.sender, _from, _token_id, _data) ==
                IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
}
//without DATA
function SafeTransferFrom(address _from, address _to, uint _token_id) public{
TransferFrom(_from, _to, _token_id);
   require(
            _to.code.length == 0 ||
                IERC721Receiver(_to).onERC721Received(msg.sender, _from, _token_id, "") ==
                IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
}

function approve(address _approve, uint _token_id) address_exist(_approve) owner_check(msg.sender, _token_id) public 
{
    approved[_token_id] = _approve;
}

function get_approved( uint _token_id) public view returns(address) 
{
    require(OwnerIs[_token_id] != address(0), 'NFT not existed!');
    require(approved[_token_id] != address(0), 'Not approved operator!');
    return approved[_token_id];
}

function set_approval_for_all(address _operator, bool _approved) address_exist(_operator) public
{
    require(BalanceIs[msg.sender]>0,'Owner has no NFTs to give approval to any operator!');
    isApprovedbyOwnerForAll[msg.sender][_operator] = _approved;
}

function Is_approved_for_all(address _owner, address _operator) public view returns(bool)
{
    require(isApprovedbyOwnerForAll[_owner][_operator], 'Operator not approved for Owner NFTs!');
    return isApprovedbyOwnerForAll[_owner][_operator];
}
function mint_token(address _to, uint _token_id) address_exist(_to) public {
    require(OwnerIs[_token_id] == address(0),'Token already minted!');
    OwnerIs[_token_id] = _to;
    BalanceIs[_to] += 1;
    emit Transfer(address(0), _to, _token_id);
}
function burn_token(uint _token_id)  public {
    address owner = OwnerIs[_token_id];
    require(owner != address(0),'Token not minted!');
    BalanceIs[owner] -= 1;
    delete OwnerIs[_token_id];
    delete approved[_token_id];
    emit  Transfer(owner, address(0), _token_id);
}
}

/////////////ERC4907 extensions
// Logged when the user of a token assigns a new user or updates expires
/// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
/// The zero address for user indicates that there is no user address

    // event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

/// @notice set the user and expires of a NFT
/// @dev The zero address indicates there is no user
/// Throws if `tokenId` is not valid NFT
/// @param user  The new user of the NFT
/// @param expires  UNIX timestamp, The new user could use the NFT before expires

    // function setUser(uint256 tokenId, address user, uint64 expires) external ;

/// @notice Get the user address of an NFT
/// @dev The zero address indicates that there is no user or the user is expired
/// @param tokenId The NFT to get the user address for
/// @return The user address for this NFT

    // function userOf(uint256 tokenId) external view returns(address);

/// @notice Get the user expires of an NFT
/// @dev The zero value indicates that there is no user
/// @param tokenId The NFT to get the user expires for
/// @return The user expires for this NFT

    // function userExpires(uint256 tokenId) external view returns(uint256);