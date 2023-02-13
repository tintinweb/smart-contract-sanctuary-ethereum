// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IERC20Permit.sol";
import "./types.sol";

/// @title AuctionHouse.sol
/// @author ~bitful-pannul
/// @notice 
/// @dev 


contract AuctionHouse is Ownable, IERC721Receiver {  // EIP712Decoder
    
    struct Item {
        address seller;
        address nftAddress;
        uint nftId;
        bool isSold;
        uint256 startPrice;
        string tokenURI;
    }

    struct Bid {
        address bidder;
        address seller;
        address tokenAddress;
        uint tokenId;
        uint amount;
        uint deadline;
    }

    struct SignedBid {
        Bid bid;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(uint => Item) public forSale;
    // saleround => itemId[]
    mapping(uint => uint[]) public saleRounds;

    // hacky version of winner storing
    mapping(address => uint) public winners;



    // In case of multiple Auction houses directly in this contract, (not proxy deployment), we'd need: 
    //   -Owner modifiers, used in calling methods
    //   Mappings with mapping(string => mapping(uint => Item)), so auction house uint/string needed for every action.. hmm
    //   Anyway all that is a TODO.

    using Counters for Counters.Counter;

    uint public roundIndex;

    Counters.Counter private itemId;
    Counters.Counter public roundId;

    // Permit hashes not needed for know, Permit's are verified in USDC and in hoon agent.
    address public usdc;
    bool saleOpen;

    uint public currentItem; 

    // hmm, add different auction houses?
    

    function isSaleOpen() external view returns (bool) {
        return saleOpen;
    }

    constructor() {
        // todo derive these from methods in types.sol instead
        usdc = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;  // mainnet: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        saleOpen = false;
    }


    // Events will be important for live auction changes to be synced to frontend.
    event Winner(uint item, address winner);

    event NextItem(uint newItem);

    event RoundStart(uint roundId, uint firstItem);

    event RoundEnd(uint roundId);

    event SaleSuccess(address buyer, address seller, uint item, uint amount);   // include txHash somehow?

    event TransferFromFailed(address buyer);

    
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    function transferItem(
        uint item,
        Bid memory bid
    ) private {
        // todo check itemID mappings in Bid
        IERC721(forSale[item].nftAddress).safeTransferFrom(
            address(this),
            bid.bidder,
            forSale[item].nftId
        );
    }

    // deadline should be customizable, but needing to read it from contract before making a bid is tiresome
    function startAuction(uint[] memory idsToAuction, uint deadlinePerUnit)
        public
        onlyOwner
    {
        roundId.increment();
        uint round = roundId.current();
        saleRounds[round] = idsToAuction;
        saleOpen = true;
    }

    function endRound(
        uint round,
        uint item,
        SignedBid calldata winningBid
    ) public onlyOwner {
        require(
            saleOpen,
            "This contract has already conducted its one sale."
        );

        // Skip invalid bids.
        // Sure, we could throw errors, but why waste gas?
        // Bids that are not signed correctly
        // if (!verifyBid(winningBid)) {
        //     revert("verification of winningbid signature failed");
        // }
        
        // sig verification will happen on usdc side, need to assert that that call succeeded. (and transfer too.)
        // try/catch?
        IERC20Permit(usdc).permit(winningBid.bid.bidder, address(this), winningBid.bid.amount, winningBid.bid.deadline, winningBid.v, winningBid.r, winningBid.s);

        // TODO, implement comission percentages

        bool successComission = IERC20(usdc).transferFrom(
            winningBid.bid.bidder,
            address(this),
            winningBid.bid.amount // <-
        );

        address seller = forSale[item].seller;

        bool successTransfer =  IERC20(usdc).transferFrom(
            winningBid.bid.bidder,
            seller,
            winningBid.bid.amount // <-
        );

        if (successComission && successTransfer) {
            transferItem(
                item,
                winningBid.bid
            );

            // need to implement "winner-flow" but for others too. 
            emit Winner(item, winningBid.bid.bidder);
            winners[winningBid.bid.bidder] = item;

            // TODO, ordering of saleRound uint[], and how to iterate over it. 

            if (roundIndex >= saleRounds[round].length) {
                // we've auction all of the rounds items. 
                emit RoundEnd(round);
                // endRound()?
                roundIndex = 0;
                saleOpen = false;

            } else {
                roundIndex++;
                emit NextItem(saleRounds[round][roundIndex]);
            }

            
        } else {
            emit TransferFromFailed(winningBid.bid.bidder);
            revert();
        }
        
        
    }

    // might be unnecessary if we do if functions in endRound(), gaswise this might be better though?
    function endAuction(uint roundId) onlyOwner public {
        saleOpen = false;
    }

    function depositNft(address nftAddress, uint tokenId, uint minPrice) external {
        require(!saleOpen, "sale is already open");
        // TODO approve first
        // approval done on frontend somewhere/manually... hmm? 
        // probably better as a backend thing, different when 2nd or 3rd auction. want random ppl to also sell their stuff here?mayb
        // (bool approved,) = IERC712(nftAddress).approve()
        // approve box... / moralissdk

        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        // handle if this reverts/not_approved.

        bool success = true;
        if (success) {
            itemId.increment();
            uint id = itemId.current();
            // deadline undeterminable from this state? we can set it later too
            string memory tokenURI = IERC721Metadata(nftAddress).tokenURI(tokenId);
            forSale[id] = Item(msg.sender, nftAddress, tokenId, false, minPrice, tokenURI);
        } else {
            emit TransferFromFailed(msg.sender);
        }
    }

    function withdrawNft(uint id) external {
        require(!saleOpen, "sale is still open, be patient honey");
        require(
            msg.sender == forSale[id].seller,
            "can't withdraw someone elses nft"
        );

        IERC721(forSale[id].nftAddress).safeTransferFrom(address(this), msg.sender, forSale[id].nftId);
    }

    function getNftAddress(uint id) external view returns (address) {
        Item memory i = forSale[id];
        return i.nftAddress;
    }

    function getNftTokenId(uint id) external view returns (uint) {
        Item memory i = forSale[id];
        return i.nftId;
    }

    // this is fetched and set in the depositNFT() method, to verify maybe one should call erc721 address directly
    function getNftURI(uint id) external view returns (string memory) {
        Item memory i = forSale[id];
        return i.tokenURI;
    }

    function getNftInfo(uint id) external view returns (Item memory) {
        // needs compiler => 0.8.0
        return forSale[id];
    }

    function getCurrentSaleRound() external view returns (uint) {
        return roundId.current();
    }

    function getCurrentNftINfo() external view returns (Item memory) {
        return forSale[roundId.current()];
    }

    // EIP712 Signature Related Code:
    // If we sign bids ourselves (2 signatures..?)
  //  function getEIP712DomainHash(
  //      string memory contractName,
  //      string memory version,
  //      uint chainId,
  //      address verifyingContract
  //  ) public pure returns (bytes32) {
  //      return
  //          keccak256(
  //              abi.encode(
  //                  EIP712DOMAIN_TYPEHASH,
  //                  keccak256(bytes(contractName)),
  //                  keccak256(bytes(version)),
  //                  chainId,
  //                  verifyingContract
  //              )
  //          );
  //  }

   // function getBidTypedDataHash(Bid calldata bid)
   //     public
   //     view
   //     returns (bytes32)
   // {
   //     bytes32 packetHash = GET_BID_PACKETHASH(bid);
   //     bytes32 digest = keccak256(
   //         abi.encodePacked("\x19\x01", domainHash, packetHash)
   //     );
   //     return digest;
   // }

  //  function verifyBid(SignedBid calldata signedBid)
  //      public
  //      view
  //      returns (bool)
  //  {
  //      // bytes32 sigHash = getBidTypedDataHash(signedBid.bid);
  //
  //      uint nonce = IERC20Permit(usdc).nonces(signedBid.bid.bidder);
  //
  //      bytes memory data = abi.encode(
  //          usdcPermitHash,
  //          signedBid.bid.bidder,
  //          address(this),
  //          signedBid.bid.amount,
  //          nonce++,
  //          signedBid.bid.deadline
  //      );
  //
  //      address recoveredSignatureSigner = ecrecover(
  //          usdcDomainSeparator,
  //          signedBid.v,
  //          signedBid.r,
  //          signedBid.s
  //      );
  //
  //      require(
  //          signedBid.bid.bidder == recoveredSignatureSigner,
  //          "Invalid signature"
  //      );
  //      return true;
  //  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IERC20Permit {
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
}

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT


struct Bidd {
  address Biddder;
  address token;
  uint256 amount;
}

bytes32 constant Bidd_TYPEHASH = keccak256("Bidd(address Biddder,address token,uint256 amount)");

struct EIP712Domain {
  string name;
  string version;
  uint256 chainId;
  address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");


contract EIP712Decoder {

  /**
  * @dev Recover signer address from a message by using their signature
  * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
  * @param sig bytes signature, the signature is generated using web3.eth.sign()
  */
  function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
// Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

  function GET_Bidd_PACKETHASH (Bidd memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      Bidd_TYPEHASH,
      _input.Biddder,
      _input.token,
      _input.amount
    );
    
    return keccak256(encoded);
  }

  function GET_EIP712DOMAIN_PACKETHASH (EIP712Domain memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      EIP712DOMAIN_TYPEHASH,
      _input.name,
      _input.version,
      _input.chainId,
      _input.verifyingContract
    );
    
    return keccak256(encoded);
  }

}