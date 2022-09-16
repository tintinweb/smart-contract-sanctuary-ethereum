/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
 
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function buyCars(
        uint256,
        uint256 
       ) external payable;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/For Flatten/flat.sol


 pragma solidity 0.8.7;

// contract A{
//     function val()view public returns(address){
//         return tx.origin;
//     }
// }
 contract CarRacingMarketplace{

address owner;
uint public listingPrice=0;
constructor(){
    owner=payable(0x919F1aF9BC7bB98D7052CB8B080578d8f4a1210d);
}
struct Listed{
    address owner;
    uint tokenID;
    uint price;
    bool isListed;
    // bool isSelled;
}
mapping (address=> Listed[])  listedMapping;
mapping(uint=> bool) public  checkIsAlreadtisted;
mapping (uint=> address[]) public Owners;
// Listed[]  temp1;

// address[] Contracts;
IERC721 public nft;

function updateNftContract(address _nft) public onlyOwner{
    nft= IERC721(_nft);
}
//events
event ListedEvent(address indexed owner, uint indexed tokenId, uint price);
event UnListedEvent(address indexed owner, uint indexed tokenId, bool isListed);
event UpdateListedPriceEvent(address indexed owner, uint indexed tokenId, uint price);
event SellListedEvent(address indexed owner,address indexed to,  uint tokenId, uint price);

// Modifier

   modifier onlyOwner {
      require(msg.sender == owner,"Caller is not Owner");
      _;
   }
//buyCar
function buyCar(uint _carId,uint _amount) external payable{
    nft.buyCars{value:msg.value}(_carId,_amount);
}
 //list
 function listCar( uint id,uint price)public payable{
    //  IERC721 nft= IERC721(_nft);
    // if()
    require(price >=0,"Price should be greater than -1");
     require(msg.value>= listingPrice,"Please enter the correct Listing Amount");
     require(!checkIsAlreadtisted[id],"Already Listed");
     require(nft.ownerOf(id)== msg.sender,"You are not the owner of this NFT");
    // bool checkOwner=false;
//     for(uint i;i<Contracts.length;i++){
//         if(Contracts[i]==address(_nft)){
// checkContract=true;
//         }
//     }
//     if(!checkContract){
//         Contracts.push(address(_nft));
//     }
     listedMapping[msg.sender].push(Listed(
        msg.sender,
        id,
        price,
        true
        // false
 ));

checkIsAlreadtisted[id]=true;
    emit ListedEvent(
        msg.sender,
  
        id,
        price);
    //  _nft.safeTransferFrom(msg.sender,address(this),id);
    //  _nft.safeTransferFrom(msg.sender,owner,id);
    //  _nft.

 }
 //listing Price
 function updateListingPrice(uint price) public onlyOwner{
     listingPrice=price;
 }
 //unlist
function unList(address _owner,uint _id)public{
    Listed[] storage temp;
    temp=listedMapping[_owner];
    for(uint i=0;i<temp.length;i++){
        if(temp[i].tokenID==_id && temp[i].isListed==true){
            require(temp[i].owner==msg.sender,"Only the Person who Listed the Token can unlist them");
            temp[i].isListed=false;
        }
    }
emit UnListedEvent(
        msg.sender,
       
        _id,
        false);
}
 //updatelist
 function updateList(uint _id,uint newPrice)public{
    Listed[] storage temp;
    temp=listedMapping[msg.sender];
    for(uint i=0;i<temp.length;i++){
        if(temp[i].tokenID==_id && temp[i].isListed==true){
            require(temp[i].owner==msg.sender,"Only the Person who Listed the Token can update them");
            temp[i].price=newPrice;
        }}

      emit UpdateListedPriceEvent(
        msg.sender,
     
        _id,
        newPrice);  
    }

 //sell
  function sell(address _owner,uint _id)public payable{
      require(listedMapping[_owner].length>0,"Owner is not Correct");
    Listed[] storage temp;
    temp=listedMapping[_owner];
    for(uint i=0;i<temp.length;i++){
        if(temp[i].tokenID==_id && temp[i].isListed==true){
            require(temp[i].price<=msg.value,"Please enter the correct Amount");
            address tempTokenOwnerAddress=nft.ownerOf(_id);
            require(temp[i].owner== tempTokenOwnerAddress,"OwnerShip Change cannot sell Token");
temp[i].isListed=false;
checkIsAlreadtisted[_id]=false;
nft.safeTransferFrom(temp[i].owner,msg.sender,_id);

            // temp[i].price=newPrice;
        }}

      emit SellListedEvent(
        _owner,
        msg.sender,
        
        _id,
        msg.value);  
        emit UnListedEvent(
        msg.sender,
        
        _id,
        false);
    }

 
//getData
function getListedItems(address _owner) public view returns (Listed[] memory) {
            
        Listed[] memory temp;
        uint c=0;
        uint b=0;
        temp=listedMapping[_owner];
            for(uint i=0;i<temp.length;i++){
                if(temp[i].isListed==true){
                    b++;
                }
            }
        Listed[] memory temp1= new Listed[](b);
            for(uint i=0;i<temp.length;i++){
                if(temp[i].isListed==true){
                    // temp1.push(temp[i]);
                    temp1[c]=temp[i];
                    c++;
                }
            }
        return  temp1;
    }
// function getAllListed() public view returns (Listed[] memory) {
            
//         Listed[] memory temp;
//         uint c=0;
//         uint b=0;
//         temp=listedMapping[_owner];
//             for(uint i=0;i<temp.length;i++){
//                 if(temp[i].isListed==true){
//                     b++;
//                 }
//             }
//         Listed[] memory temp1= new Listed[](b);
//             for(uint i=0;i<temp.length;i++){
//                 if(temp[i].isListed==true){
//                     // temp1.push(temp[i]);
//                     temp1[c]=temp[i];
//                     c++;
//                 }
//             }
//         return  temp1;
//     }

// function getListedContracts() public view returns (address[] memory) {
//         return Contracts;
//     }

    //Widthdraw

    function withdraw()public onlyOwner{
       (bool os, ) = payable(owner).call{value: address(this).balance}("");
    require(os);

    }
    // Transfer Ownership
    function trasferOwnerShip(address _owner)public onlyOwner{
            owner=_owner;
    }
    //MarketPlace Current Balance
    function getMarketPlaceBalance()public view returns(uint){
        return address(this).balance;

    }
 }