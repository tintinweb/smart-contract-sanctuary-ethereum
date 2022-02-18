/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity 0.8.0;


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


/**
 * _Available since v3.1._
 */
interface IERC1155Burnable is IERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}


interface IERC1155Mintable is IERC1155Burnable {
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}


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




contract RubikGame is Ownable {

    // Colors
    uint256 constant COLORS = 6;

    // Rubik ID
    uint256 constant RUBIKS = 12;
    
    // Quantity of cubes per side
    uint256 constant QUANTITY = 9;

    struct TradeType {
        uint256 color_ask;
        uint256 color_bid;
        uint256 quantity_ask;
        uint256 quantity_bid;
        address wallet;
    }

    // Direccion del minteador
    address public minter;

    // Start trade id
    uint256 private tid = 1;
    mapping ( uint256 => TradeType ) trades;

    mapping ( uint256 => uint256[] ) trades_by_ask;
    mapping ( address => uint256[] ) trades_by_address;

    IERC1155Mintable assets;

    function setAssetsContract(IERC1155Mintable _contract) external onlyOwner {
        assets = _contract;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    modifier onlyMinter {
        require(_msgSender() == minter, "Only Minter can mint");
        _;
    }

    /** 
     * ToDo: 
     *     - mintEnvelope(): Envia 9 cuadraditos
     *     - change(): Cambia una cara por una guitarra
     *     - change(): Cambia 6 guitarras por un rubiks
     */
    function mint(address to, uint256[] memory ids, uint256[] memory quantity) external onlyMinter {
        uint256 total;

        require (ids.length == COLORS, "Invalid number of ids");
        require (ids.length == quantity.length, "Invalid argument, different array size");

        for (uint256 i = 0; i < 6; i++) {
            require(ids[i] < COLORS, "Invalid color id");
            total = total + quantity[i];
        }
        require(total == QUANTITY, "Invalid total quantity");
    
        assets.mintBatch(to, ids, quantity);
    }

    function getGuitar(uint256 color) external {
        require(assets.balanceOf(_msgSender(), color) == QUANTITY, "Invalid balance");
        
        assets.burn(_msgSender(), color, QUANTITY);
        assets.mint(_msgSender(), COLORS+color, 1);
    }

    function getRubik() external {
        address sender = _msgSender();
        for (uint256 i = COLORS; i < 2*COLORS; i++) {
            require(assets.balanceOf(sender, i) > 0, "Missing asset");
            assets.burn(sender, i, 1);
        }
        assets.mint(sender, RUBIKS, 1);
    }

    function getCQfromCode(uint256 code) internal pure returns (uint256 color, uint256 quantity) {
        color = code / QUANTITY;
        quantity = code % QUANTITY;
    }

    function getCodefromCQ(uint256 color, uint256 quantity) internal pure returns (uint256 code) {
        code = (color * QUANTITY) + quantity;
    }

    function getTradesByAsk(uint256 color, uint256 quantity) external view returns(uint256[] memory tradeIds) {
        uint256[] storage ptr = trades_by_ask[getCodefromCQ(color, quantity)];
        
        tradeIds = new uint256[](ptr.length);
    
        for (uint256 i = 0; i < ptr.length; i++) {
            tradeIds[i] = ptr[i];
        }
    }

    function getTradesByAddress(address player) external view returns(uint256[] memory tradeIds) {
        uint256[] storage ptr = trades_by_address[player];
        tradeIds = new uint256[](ptr.length);
    
        for (uint256 i = 0; i < ptr.length; i++) {
            tradeIds[i] = ptr[i];
        }
    }

    function getTrade(uint256 id) external view returns(uint256 color_ask, uint256 quantity_ask, uint256 color_bid, uint256 quantity_bid, address wallet) {
        TradeType storage trade = trades[id];
        color_ask = trade.color_ask;
        quantity_ask = trade.quantity_ask;
        color_bid = trade.color_bid;
        quantity_bid = trade.quantity_bid;
        wallet = trade.wallet;
    }


    function addTrade(uint256 color_bid, uint256 quantity_bid, uint256 color_ask, uint256 quantity_ask ) external {

        require (assets.balanceOf(_msgSender(), color_bid) >= quantity_bid, "Insufficient balance to create the trade");
        
        assets.safeTransferFrom(_msgSender(), address(this), color_bid, quantity_bid, bytes(""));


        TradeType storage trade = trades[tid];

        trade.color_ask = color_ask;
        trade.color_bid = color_bid;
        trade.quantity_ask = quantity_ask;
        trade.quantity_bid = quantity_bid;
        trade.wallet = _msgSender();

        // Guardo la referencia en trade.ask
        trades_by_ask[getCodefromCQ(color_ask, quantity_ask)].push(tid);
        trades_by_address[trade.wallet].push(tid);

        tid = tid + 1;
    }

    function acceptTrade(uint256 id) external {
        TradeType storage trade = trades[id];
    
        require (assets.balanceOf(_msgSender(), trade.color_ask) >= trade.quantity_ask, "Insufficient balance to accept the trade");

        assets.safeTransferFrom(_msgSender(), trade.wallet, trade.color_ask, trade.quantity_ask, bytes(""));
        assets.safeTransferFrom(address(this), _msgSender(), trade.color_bid, trade.quantity_bid, bytes(""));

        deleteTrade(id);
    }


    function deleteTrade(uint256 id) internal {
        TradeType storage trade = trades[id];
        uint256 ask = getCodefromCQ(trade.color_ask, trade.quantity_ask);
        uint256 len = trades_by_ask[ask].length;
        
        for (uint256 i = 0; i < len; i++) {
            if (trades_by_ask[ask][i] == id) {
                if (i < len - 1) {
                    trades_by_ask[ask][i] = trades_by_ask[ask][len-1];
                }
                trades_by_ask[ask].pop();
            }
        }    

        len = trades_by_address[trade.wallet].length;
        for (uint256 i = 0; i < len; i++) {
            if (trades_by_address[trade.wallet][i] == id) {
                if ( i < len -1) {
                    trades_by_address[trade.wallet][i] = trades_by_address[trade.wallet][len-1];
                }
                trades_by_address[trade.wallet].pop();
            }
        }  
        delete trades[id];
    }


    function cancelTrade(uint256 id) external {
        TradeType storage trade = trades[id];

        require(trade.wallet == _msgSender(), "Only owner can cancel a trade");
        deleteTrade(id);
    }
}