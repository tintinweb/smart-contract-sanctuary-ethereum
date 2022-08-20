/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: Marketplace.sol


 pragma solidity 0.8.7;

// contract A{
//     function val()view public returns(address){
//         return tx.origin;
//     }
// }
 contract Marketplace{
// function getVal(address _contract)view public returns(address){
// A cont=A(_contract);
// return cont.val();

// }
address owner;
uint public listingPrice=0.025 ether;
constructor(){
    owner=payable(msg.sender);
}
struct Listed{
    address owner;
    uint tokenID;
    uint price;
    uint amount;
}
mapping (address=> Listed[]) public listedMapping;
// mapping (address =>mapping(uint=> bool))  checkIsAlreadtisted;
// mapping (address => address[]) public Contracts;
// Listed[]  temp1;

address[] Contracts;
//events
event ListedEvent(address indexed owner, uint indexed tokenId, uint indexed price,uint amount);
event UnListedEvent(address indexed owner, uint indexed tokenId, uint indexed amount);
event UpdateListedPriceEvent(address indexed owner, uint indexed tokenId, uint indexed price);
event SellListedEvent(address indexed owner,address indexed to,  uint indexed tokenId, uint price);

// Modifier

   modifier onlyOwner {
      require(msg.sender == owner,"Caller is not Owner");
      _;
   }
IERC1155 public nft;

function updateNftContract(address _nft) public onlyOwner{
    nft= IERC1155(_nft);
}
 //list
 function list( uint id,uint price,uint amount)public payable{
    //  IERC1155 nft= IERC1155(_nft);
     require(msg.value>= listingPrice,"Please enter the correct Listing Amount");
    //  require(!checkIsAlreadtisted[address(_nft)][id],"Already Listed");
     require(nft.balanceOf(msg.sender,id)>=amount,"Please enter the correct nft ammount you own");
   
Listed[] storage temp;
    temp=listedMapping[msg.sender];
    bool tempCheck;
    for(uint i= 0 ; i< temp.length;i++){

        if(temp[i].tokenID== id){
     require(nft.balanceOf(msg.sender,id)>=temp[i].amount+amount,"Please enter the correct nft ammount you own");

            temp[i].amount+=amount;
            temp[i].price+=price;
            tempCheck=true;
        }
    }

if(!tempCheck){

     listedMapping[msg.sender].push(Listed(
        msg.sender,
        id,
        price,
       amount
 ));
}

// checkIsAlreadtisted[address(_nft)][id]=true;
    emit ListedEvent(
        msg.sender,
        id,
        price,
        amount);
    //  _nft.safeTransferFrom(msg.sender,address(this),id);
    //  _nft.safeTransferFrom(msg.sender,owner,id);
    //  _nft.

 }
 //listing Price
 function updateListingPrice(uint price) public onlyOwner{
     listingPrice=price;
 }
//  unlist
function unList(uint _id,uint amount)public{
    Listed[] storage temp;
    temp=listedMapping[msg.sender];
    for(uint i=0;i<temp.length;i++){
        if(temp[i].tokenID==_id){
            require(temp[i].owner==msg.sender,"Only the Person who Listed the Token can unlist them");
            temp[i].amount-=amount;
        }
    }
emit UnListedEvent(
        msg.sender,
        _id,
        amount);
}
//  //updatelist
 function updateList(uint _id,uint newPrice)public{
    Listed[] storage temp;
    temp=listedMapping[msg.sender];
    for(uint i=0;i<temp.length;i++){
        if(temp[i].tokenID==_id){
            require(temp[i].owner==msg.sender,"Only the Person who Listed the Token can update them");
            temp[i].price=newPrice;
        }}

      emit UpdateListedPriceEvent(
        msg.sender,
        _id,
        newPrice);  
    }

 //sell
  function sell(address _owner,uint _id,uint amount)public payable{
    Listed[] storage temp;
    temp=listedMapping[_owner];
    for(uint i=0;i<temp.length;i++){
        if(temp[i].tokenID==_id){
            require(temp[i].amount>= amount,"");
            require(temp[i].price<=msg.value* amount,"Please enter the correct Amount");
            require(nft.balanceOf(_owner,_id)>= amount,"We are having some issue Selling the item");
            // address tempTokenOwnerAddress=IERC1155(contractAddr).ownerOf(_id);
            // require(temp[i].owner== tempTokenOwnerAddress,"OwnerShip Change cannot sell Token");
              payable(_owner).transfer(msg.value* amount);

nft.safeTransferFrom(temp[i].owner,msg.sender,_id,amount,"0x00");
temp[i].amount-=amount;

            // temp[i].price=newPrice;
        }}

      emit SellListedEvent(
        _owner,
        msg.sender,
        
        _id,
        msg.value);  

        emit UnListedEvent(
        msg.sender,_id,amount);
    }

 
//getData
function getListedItems(address _owner) public view returns (Listed[] memory) {
            
        Listed[] memory temp;
        uint c=0;
        uint b=0;
        temp=listedMapping[_owner];
            for(uint i=0;i<temp.length;i++){
                if(temp[i].amount>0){
                    b++;
                }
            }
        Listed[] memory temp1= new Listed[](b);
            for(uint i=0;i<temp.length;i++){
                if(temp[i].amount>0){
                    // temp1.push(temp[i]);
                    temp1[c]=temp[i];
                    c++;
                }
            }
        return  temp1;
    }


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
    function getBalance(address addr)public view returns(uint){
        return addr.balance;

    }
 }