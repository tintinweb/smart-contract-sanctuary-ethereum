/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: contracts/mp/mp.sol

/**
 *Submitted for verification at Etherscan.io on 2022-10-22
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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    //Royalty
    struct Royalty {
        uint256 tokenID;
        uint256 per;
        address owner;
    }

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
// import {Array} from "@clemlaflemme.eth/contracts/lib/utils/Array.sol";

contract Marketplace {
    IERC20 public IPCoin;

    address owner;
    uint256 public listingPrice = 0 ether;

    constructor(IERC20 _ipAddress, address _nft) {
        owner = msg.sender;
        setIPCoinAddress(_ipAddress);
        updateNftContract(_nft);
    }

    struct Listed {
        uint256 tokenID;
        uint256 price;
        uint256 amount;
    }
    uint256[] ListedIds;

    function returnListedIds() public view returns (uint256[] memory) {
        return ListedIds;
    }

    function setIPCoinAddress(IERC20 _addr) public onlyOwner {
        IPCoin = _addr;
    }

    mapping(uint256 => Listed) public listedMapping;
    // mapping(uint=> uint) public idAmount;
    // mapping (address =>mapping(uint=> bool))  checkIsAlreadtisted;
    // mapping (address => address[]) public Contracts;
    // Listed[]  temp1;

    address[] Contracts;
    //events
    event ListedEvent(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed price,
        uint256 amount
    );
    event UnListedEvent(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed amount
    );
    event UpdateListedPriceEvent(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed price
    );
    event SellListedEvent(
        address indexed owner,
        address indexed to,
        uint256 indexed tokenId,
        uint256 price
    );

    // Modifier

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not Owner");
        _;
    }
    IERC1155 public nft;

    function updateNftContract(address _nft) public onlyOwner {
        nft = IERC1155(_nft);
    }

    //list
    function list(
        uint256 id,
        uint256 price,
        uint256 amount
    ) public onlyOwner {
        //  require(nft.balanceOf(msg.sender,id)>=amount,"Please enter the correct nft ammount you own");

        // Listed[] storage temp;
        // temp=listedMapping[msg.sender][id];
        // bool tempCheck;
        // for(uint i= 0 ; i< temp.length;i++){

        // if(temp[i].tokenID== id){
        require(
            nft.balanceOf(msg.sender, id) >= listedMapping[id].amount + amount,
            "Please enter the correct nft ammount you own"
        );
        // temp.push(Listed(msg.sender,id,price,amount));
        // temp[i].amount+=amount;
        // temp[i].price+=price;
        // tempCheck=true;
        // }
        // }
        if (listedMapping[id].amount == 0) {
            ListedIds.push(id);
            listedMapping[id].tokenID = id;
            listedMapping[id].price = price;
        }

        // idAmount[id]+=amount;
        //    Listed storage temp = listedMapping[id];

        listedMapping[id].amount += amount;

        // if(!tempCheck){

        // }

        // checkIsAlreadtisted[address(_nft)][id]=true;
        emit ListedEvent(msg.sender, id, price, amount);
        //  _nft.safeTransferFrom(msg.sender,address(this),id);
        //  _nft.safeTransferFrom(msg.sender,owner,id);
        //  _nft.
    }

    //  unlist
    function unList(uint256 _id, uint256 amount) public onlyOwner {
        Listed storage temp;
        temp = listedMapping[_id];
        require(temp.amount >= amount, "Not enough Items to Unlist");
        temp.amount -= amount;
        emit UnListedEvent(msg.sender, _id, amount);
    }

    //  //updatelist
    function updateListedPrice(uint256 _id, uint256 newPrice) public onlyOwner {
        //  require(newPrice>=100,"Minimum Price should be greater than 99 wei");

        Listed storage temp;
        temp = listedMapping[_id];

        temp.price = newPrice;

        emit UpdateListedPriceEvent(msg.sender, _id, newPrice);
    }

    //  //sell
    function sell(uint256 _id, uint256 amount) public {
        require(owner != msg.sender, "Caller is Owner");
        Listed storage temp;
        temp = listedMapping[_id];

        require(temp.amount >= amount, "Not enough Listed");
        require(
            temp.price * amount <= IPCoin.balanceOf(msg.sender),
            "Please enter the correct Amount"
        );
        // require(temp.price* amount<=msg.value,"Please enter the correct Amount");
        require(
            nft.balanceOf(owner, _id) >= amount,
            "We are having some issue Selling the item"
        );

        // address tempTokenOwnerAddress=IERC1155(contractAddr).ownerOf(_id);
        // require(temp[i].owner== tempTokenOwnerAddress,"OwnerShip Change cannot sell Token");
        IPCoin.transferFrom(msg.sender, address(this), temp.price * amount);
        nft.safeTransferFrom(owner, msg.sender, _id, amount, "0x00");
        temp.amount -= amount;

        // temp[i].price=newPrice;

        emit SellListedEvent(owner, msg.sender, _id, temp.price * amount);

        emit UnListedEvent(msg.sender, _id, amount);
    }

    function getListed() external view returns (Listed[] memory) {
        uint256[] memory temp = ListedIds;
        // Listed[] memory array;
        // uint b;
        // for(uint i=0;i<temp.length;i++){
        //     // Listed[] memory tempp= getListedItems(_owner,temp[i]);
        //     b+=getListedItems(temp[i]).length;
        // //   array=  ConcatenateArrays(array,tempp);
        // }
        Listed[] memory temp1 = new Listed[](temp.length);
        uint256 c;
        for (uint256 j = 0; j < temp.length; j++) {
            Listed memory tempp = getListedItems(temp[j]);

            temp1[c] = tempp;
            c++;
        }
        return temp1;
    }

    function getListedItems(uint256 _id) internal view returns (Listed memory) {
        return listedMapping[_id];
    }

    //Widthdraw
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        //    (bool os, ) = payable(owner).call{value: address(this).balance}("");
        // require(os);
        IPCoin.transfer(_to, _amount);
    }

    function IPContractBalance() public view returns (uint256) {
        return IPCoin.balanceOf(address(this));
    }

    // Transfer Ownership
    function trasferOwnerShip(address _owner) public onlyOwner {
        owner = _owner;
    }

    //MarketPlace Current Balance
    function getBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}