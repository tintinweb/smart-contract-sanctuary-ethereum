/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/NftMultMint.sol

/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/aiNFT.sol



pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;







////////////////////////////////////////////////////////////////////


interface mintNFT{
      function mint(
        uint256 _category,
        bytes memory _data,
        bytes memory _signature
    ) external ;
}


interface transNFT{
      function safeBatchTransferFrom(
       address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external ;
}




 

contract NaiveHodler {}


//////////////////////////////////////////
//普通NFT批量mint
interface nftTotalSupply {
      function totalSupply() external view returns (uint256);
}

interface mintZerionNFT{
      function mint() external ;
}

interface passNFT{
      function safeTransferFrom(address from, address to, uint256 tokenId) external ;
}



contract CommonClaimer   is   ERC1155Holder   , ERC721Holder{

         // 定义事件
    event adressEvent(uint256 indexed tokenId);
    address public contra ;
    constructor(address codntrAddress){
        contra = codntrAddress;
    }

    function mint() public{
        uint256  totalSupply = nftTotalSupply(contra).totalSupply();
        mintZerionNFT(contra).mint();
        uint256 tokenId =  totalSupply +1;
          emit adressEvent(tokenId);
        // passNFT(contra).safeTransferFrom( address(this),  address(tx.origin),tokenId);
        // selfdestruct(payable(address(msg.sender)));
     }



     function multMint(uint times ) public{
        for(uint i=0;i<times;i++){
            uint256  totalSupply = nftTotalSupply(contra).totalSupply();
            mintZerionNFT(contra).mint();
            uint256 tokenId =  totalSupply +1;
              emit adressEvent(tokenId);
            // passNFT(contra).safeTransferFrom( address(this),  address(tx.origin),tokenId);
        }
        // selfdestruct(payable(address(msg.sender)));
     }
     

}
/////////////////////////////////////////////////

contract Claims  is   ERC1155Holder{
      

     // 定义事件
    event adressEvent(address indexed originOp, address indexed sender,address indexed myaddress);


    uint public countNumber ;


       uint256[] public ids =     [1,2,3,4,5,6,7,8,9];
        uint256[]  public amounts = [1,1,1,1,1,1,1,1,1];
        //  uint256[] public ids =     [1];
        // uint256[]  public amounts = [1];
        bytes public  data ="0x";
  
    constructor(uint num){
          // 触发事件
        emit adressEvent(tx.origin, msg.sender,  address(this));
        countNumber = num ;
    } 

   // function doMint(address  contra ,bytes[] memory datas, bytes[] memory signatures) public  {
   function doMint(address  contra , bytes[] memory signatures) public  {
        mintNFT(contra).mint(1, data, signatures[0] ) ;
        mintNFT(contra).mint(2,data, signatures[1] ) ;
        mintNFT(contra).mint(3,data, signatures[2] ) ;
        mintNFT(contra).mint(4,data, signatures[3] ) ;
        mintNFT(contra).mint(5,data, signatures[4] ) ;
        mintNFT(contra).mint(6,data, signatures[5] ) ;
        mintNFT(contra).mint(7,data, signatures[6] ) ;
        mintNFT(contra).mint(8,data, signatures[7] ) ;
        mintNFT(contra).mint(9,data, signatures[8] ) ;

        transNFT(contra).safeBatchTransferFrom( 
           address(this), 
           address(tx.origin) ,
           ids,
           amounts,
           data
        );
        selfdestruct(payable(address(tx.origin)));
    }


}

contract  NftMultiClaimCeshi{
    address constant contra = address(0xc169B28d3eA128ACe729fb7E7C27f6Ec0a95f549);
  //  address constant nftContra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);//主网合约
  // address constant nftContra = address(0xc169B28d3eA128ACe729fb7E7C27f6Ec0a95f549);//ROPSTEN测试网

    //address constant contra = address(0x951331F36F27ebe99c1008AF68dC11D5A802E340);//RK 测试

    //  address public nowAdr;
    //  address public prenowAdr;

    struct Record {
       uint countNumber;
      // bytes[]  data;
       bytes[]  signature;
    }


   //单个钱包mint
   // function singleMint(bytes32 salt,uint countNumber,  bytes[] memory _data, bytes[] memory _signature) public  {
   function singleMint(bytes32 salt,uint countNumber,  bytes[] memory _signature) public  {
          // bytes32 mintsalt =0x1;
           Claims claims = new Claims{salt: salt}(countNumber);
           claims.doMint(  contra ,  _signature) ;
           // claims.doMint(  contra , _data,  _signature) ;
   } 

     //duo个钱包mint
   function mulMint(bytes32 salt,  Record[] memory records) public  {
           // bytes32 mintsalt =0x1;
         for(uint i= 0;i<records.length ;i++ ){
              Record memory record =  records[i];
              uint countNumber = record.countNumber;
             // bytes[]  memory data = record.data;
               bytes[]  memory signature = record.signature;
             Claims claims = new Claims{salt: salt}(countNumber);
            // claims.doMint(  contra , data,  signature) ;
              claims.doMint(  contra ,  signature) ;
         }
       
   } 

    function getAddress(bytes32 salt,uint arg) public view returns (address) {
         address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(Claims).creationCode,
                arg
            ))
        )))));
        return predictedAddress;
    }




    //普通mint方法
    address constant zerionContra = address(0xB86cBC82Ae295DfF283bA5998Ae6B53782f70513);
    //RK   0xB86cBC82Ae295DfF283bA5998Ae6B53782f70513
    function  zerionCall(uint times) public {
        for(uint i=0;i<times;i++){
              CommonClaimer comClaims = new CommonClaimer(zerionContra);
              comClaims.mint() ;
        }
    }

     function zerionSingleMultMint(uint times) public {
           CommonClaimer comClaims = new CommonClaimer(zerionContra);
            comClaims.multMint(times) ;
     }

    function commonCall(uint times ,address cAdress) public {
        for(uint i=0;i<times;i++){
            CommonClaimer comClaims = new CommonClaimer(cAdress);
              comClaims.mint() ;
        }
    }


     function commonSingleMultMint(uint times ,address cAdress) public {
           CommonClaimer comClaims = new CommonClaimer(cAdress);
            comClaims.multMint(times) ;
     }
   

}