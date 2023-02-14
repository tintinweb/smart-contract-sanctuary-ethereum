/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.18;

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

// SECTION Interfaces
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}


interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// !SECTION Interfaces

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error UnableGetTokenOwnerByIndex();
error URIQueryForNonexistentToken();


contract RBT_Stacks is ERC721, protected {

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name = "White Rabbit Stacks";

    string public symbol = "STACKS";
    string public baseURI = "https://whiterabbit.mypinata.cloud/ipfs/";
    /*///////////////////////////////////////////////////////////////
                          ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    // Array which maps token ID to address (index is tokenID)
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;
        // Defining uniswap stuff to be used in the contract
        router = IUniswapV2Router02(routerAddress);
        factoryAddress = router.factory();
        factory = IUniswapV2Factory(factoryAddress);
        wethAddress = router.WETH();
        WETH = IERC20(wethAddress);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721ENUMERABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * It is not recommended to call this function on chain from another smart contract,
     * as it can become quite expensive for larger collections.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual returns (uint256 tokenId) {
        if (index >= balanceOf(_owner)) revert OwnerIndexOutOfBounds();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; tokenId < qty; tokenId++) {
                if (_owner == ownerOf(tokenId)) {
                    if (count == index) return tokenId;
                    else count++;
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     *      Iterates through _owners array -- it is not recommended to call this function
     *      from another contract, as it can become quite expensive for larger collections.
     */
    function balanceOf(address _owner) public view virtual returns (uint256) {
        if (_owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty; i++) {
                if (_owner == ownerOf(i)) {
                    count++;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     *      Gas spent here starts off proportional to the maximum mint batch size.
     *      It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; ; tokenId++) {
                if (_owners[tokenId] != address(0)) {
                    return _owners[tokenId];
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address _owner = ownerOf(tokenId);
        if (to == _owner) revert ApprovalToCurrentOwner();

        if (msg.sender != _owner && !isApprovedForAll(_owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(_owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            isApprovedForAll(from, msg.sender));
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        // delete token approvals from previous owner
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        // if token ID below transferred one isnt set, set it to previous owner
        // if tokenid is zero, skip this to prevent underflow
        if (tokenId > 0 && _owners[tokenId - 1] == address(0)) {
            _owners[tokenId - 1] = from;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (!_checkOnERC721Received(from, to, id, data)) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     *      The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length == 0) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Safely mints `qty` tokens and transfers them to `to`.
     *
     *      If `to` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}
     *
     *      Unlike in the standard ERC721 implementation {IERC721Receiver-onERC721Received}
     *      is only called once. If the receiving contract confirms the transfer of one token,
     *      all additional tokens are automatically confirmed too.
     */
    function _safeMint(address to, uint256 qty) internal virtual {
        _safeMint(to, qty, '');
    }

    /**
     * @dev Equivalent to {safeMint(to, qty)}, but accepts an additional data argument.
     */
    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal virtual {
        _mint(to, qty);

        if (!_checkOnERC721Received(address(0), to, _owners.length - 1, data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Mints `qty` tokens and transfers them to `to`.
     *      Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 qty) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (qty == 0) revert MintZeroQuantity();

        uint256 _currentIndex = _owners.length;

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty - 1; i++) {
                _owners.push();
                emit Transfer(address(0), to, _currentIndex + i);
            }
        }

        // set last index to receiver
        _owners.push(to);
        emit Transfer(address(0), to, _currentIndex + (qty - 1));
    }

    // SECTION Stacks
    // Addresses
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public router;
    address public wethAddress;
    IERC20 public WETH;
    address public factoryAddress;
    IUniswapV2Factory public factory;
    address public rbtAddress;
    IERC20 public rbt;
    address public rbtLiquidityAddress;
    IUniswapV2Pair public rbtLiquidity;

    // Prices
    uint public price = 0.04 ether;
    uint private manualPriceRBT = 1000000000000000000000; // 1000 RBT
    bool public autoPriceRBT = true; // St the RBT price automatically based on the RBT/ETH price

    // Stacks on chain metadata
    mapping(uint => bytes32[]) public stackPieces; // Each Stack id is mapped to a piece number
    mapping(uint => string) stackImage; // Each stack id is mapped to an image
    uint public PIECES_PER_STACK = 5; // Number of pieces per stack
    bytes32[] commonPieces;
    bytes32[] uncommonPieces;
    bytes32[] rarePieces;
    mapping (bytes32 => uint) public pieceRarity; // Each piece is mapped to a rarity for reading
    
    // Controls
    bool onlyEthers;
    bool onlyRBT = true;
    bool burnRBT = true;

    // Edition and enviroment
    uint public currentEdition = 1;
    uint private piecesCounter = 0;
    mapping(bytes32 => bool) private pieceExists;

    // SECTION Metadata and URIs
    mapping (uint256 => string) private _editionURIs;
    mapping (uint256 => uint256) private _tokenEditions;
    mapping(uint256 => uint256[]) private _editionStacks;

    function setBaseURI(string memory _baseURI) public onlyAuth {
        baseURI = _baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function setEditionsURIHash(uint256 edition, string memory _hash) public onlyAuth {
        _editionURIs[edition] = _hash;
    }

    function getEditionsURIHash(uint256 edition) public view returns (string memory) {
        return _editionURIs[edition];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URIQueryForNonexistentToken");
        uint tokenEdition = _tokenEditions[tokenId];
        string memory _tokenId = _editionURIs[tokenEdition];
        return string(abi.encodePacked(baseURI, _tokenId));
    }

    function getStacksForEdition(uint256 edition) public view returns (uint256[] memory) {
        return _editionStacks[edition];
    }

    function getCurrentEdition() public view returns (uint256) {
        return currentEdition;
    }
    // !SECTION Metadata and URIs

    // NOTE Public payable mint
    function mint() public safe payable {
        // Getting RBT price
        uint _priceRBT;
        if (autoPriceRBT) {
            _priceRBT = getRBTETHPrice();
        } else {
            _priceRBT = manualPriceRBT;
        }
        // Accepting both ether and RBT
        if (onlyEthers) {
            if (msg.value < price) revert("Not enough ETH");
        } else if (onlyRBT) {
            if (msg.value > 0) revert("No ETH allowed");
            if (rbt.balanceOf(msg.sender) < _priceRBT) revert("Not enough RBT");
            // If the RBT are to burn, burn them
            if (burnRBT) {
                bool success = rbt.transferFrom(msg.sender, address(0), _priceRBT);
                if (!success) revert("RBT transfer failed");
            } else {
                bool success = rbt.transferFrom(msg.sender, address(this), _priceRBT);
                if (!success) revert("RBT transfer failed");
            }
        } else {
            if (msg.value > 0) {
                if (msg.value < price) revert("Not enough ETH");
            } else {
                if (rbt.balanceOf(msg.sender) < _priceRBT) revert("Not enough RBT");
                // If the RBT are to burn, burn them
                if (burnRBT) {
                    bool success = rbt.transferFrom(msg.sender, address(0), _priceRBT);
                    if (!success) revert("RBT transfer failed");
                } else {
                    bool success = rbt.transferFrom(msg.sender, address(this), _priceRBT);
                    if (!success) revert("RBT transfer failed");
                }
            }
        }

        uint random;
        // Randomly select pieces from the array
        bytes32[] memory pieces = new bytes32[](PIECES_PER_STACK);
        // Rarity counter
        uint uncommon = 0;
        uint rare = 0;
        uint rarity_selected = 0; // 0 common, 1 uncommon, 2 rare
        for (uint i = 0; i < PIECES_PER_STACK; i++) {
            // Generate a random number between 0 and 99 (inclusive)
            random = uint(keccak256((abi.encodePacked(block.timestamp,
                                                      msg.sender,
                                                      commonPieces.length,
                                                      uncommonPieces.length,
                                                      rarePieces.length,
                                                      balanceOf(msg.sender),
                                                      block.prevrandao,
                                                      msg.value,
                                                      i)))) % 99;
            // Rarity is determined by the random number
            // NOTE Rarity per stack cannot be more than 1 rare and 2 uncommon pieces per pack
            if ((random > 90) && (rare < 1)) { // 10 %
                rarity_selected = 2;
                rare++;   
            } else if ((random > 40) && (random < 90) && (uncommon < 2)) { // 50 %
               rarity_selected = 1;
               uncommon++;
            } else {
                rarity_selected = 0;
            }
            // Copy the chosen rarity array to a new array
            bytes32[] memory allPieces;
            if (rarity_selected == 0) {
                allPieces = commonPieces;
            } else if (rarity_selected == 1) {
                allPieces = uncommonPieces;
            } else {
                allPieces = rarePieces;
            }
            // Generate a random number between 0 and the length of the chosen rarity array
            random = uint(keccak256((abi.encodePacked(block.timestamp,
                                                      msg.sender,
                                                      commonPieces.length,
                                                      uncommonPieces.length,
                                                      rarePieces.length,
                                                      balanceOf(msg.sender),
                                                      block.prevrandao,
                                                      msg.value,
                                                      i)))) % allPieces.length;
            // Select a piece from the chosen rarity array
            pieces[i] = allPieces[random % allPieces.length];
        }
        // Set the edition of the stack
        _tokenEditions[_owners.length] = currentEdition;
        // Add the stack to the edition
        _editionStacks[currentEdition].push(_owners.length);
        // Assign the pieces to the stack
        stackPieces[_owners.length] = pieces;
        _safeMint(msg.sender, 1);
    }

    // NOTE Returning all the pieces available
    function getAllPieces() public view returns (bytes32[] memory common,
                                                 bytes32[] memory uncommon,
                                                 bytes32[] memory rare) {
        common = commonPieces;
        uncommon = uncommonPieces;
        rare = rarePieces;
    }

    // NOTE Getter for the piece number of a stack
    function getPieces(uint256 stackID) public view returns (bytes32[] memory) {
        return stackPieces[stackID];
    }

    // NOTE Gets the pieces owned by an address
    function getOwnedPieces(address _owner) public view returns (bytes32[] memory) {
        bytes32[] memory ownedPieces = new bytes32[](balanceOf(_owner) * PIECES_PER_STACK);
        for (uint i = 0; i < balanceOf(_owner); i++) {
            // Compose the pieces from all the stacks owned by the address
            bytes32[] memory pieces = stackPieces[tokenOfOwnerByIndex(_owner, i)];
            for (uint j = 0; j < PIECES_PER_STACK; j++) {
                ownedPieces[i * PIECES_PER_STACK + j] = pieces[j];
            }
        }
        return ownedPieces;
    }

    // NOTE Returns the number of pieces per stack
    function getPiecesPerStack() public view returns (uint) {
        return PIECES_PER_STACK;
    }

    // NOTE Returns the rarity of a piece
    function getPieceRarity(bytes32 piece) public view returns (uint) {
        return pieceRarity[piece];
    }
    
    // ANCHOR Admin
    function setRBTAddress(address _rbtAddress) public onlyAuth {
        rbtAddress = _rbtAddress;
        rbt = IERC20(rbtAddress);
    }

    function setOnlyEthers(bool _onlyEthers) public onlyAuth {
        onlyEthers = _onlyEthers;
        if (_onlyEthers) onlyRBT = false;
    }

    function setOnlyRBT(bool _onlyRBT) public onlyAuth {
        onlyRBT = _onlyRBT;
        if (_onlyRBT) onlyEthers = false;
    }

    // If to burn RBT or not when buying a stack
    function setBurnRBT(bool _burnRBT) public onlyAuth {
        burnRBT = _burnRBT;
    }

    // NOTE Prices

    function setAutoRBTPrices(bool _autoPriceRBT) public onlyAuth {
        autoPriceRBT = _autoPriceRBT;
    }

    function setPriceRBT(uint256 _priceRBT) public onlyAuth {
        manualPriceRBT = _priceRBT;
    }

    function priceRBT() public view returns (uint) {
        uint _priceRBT;
        if (autoPriceRBT) {
            _priceRBT = getRBTETHPrice();
        } else {
            _priceRBT = manualPriceRBT;
        }
        return _priceRBT;
    }

    function setPrice(uint256 _price) public onlyAuth {
        price = _price;
    }

    // NOTE Sets a piece image for a piece code
    function setStackImage(uint id, string memory image) public onlyAuth {
        stackImage[id] = image;
    }

    // NOTE Add a piece to the total pieces array
    function addPiece(string memory plainPiece, uint rarity) public onlyAuth {
        bytes32 _piece = keccak256(abi.encodePacked(plainPiece));
        if (rarity == 0) commonPieces.push(_piece);
        else if (rarity == 1) uncommonPieces.push(_piece);
        else if (rarity == 2) rarePieces.push(_piece);
        else revert("Invalid rarity");
        pieceExists[_piece] = true;
        piecesCounter++;
    }

    // NOTE Bulk version
    function addPieces(string[] memory plainPieces, uint rarity) public onlyAuth {
        bytes32 _piece;
        if (rarity == 0) {
            for (uint i = 0; i < plainPieces.length; i++) {
                _piece = keccak256(abi.encodePacked(plainPieces[i]));
                commonPieces.push(_piece);
                pieceRarity[_piece] = 0;
                pieceExists[_piece] = true;
                piecesCounter++;
            }
        } else if (rarity == 1) {
            for (uint i = 0; i < plainPieces.length; i++) {
                _piece = keccak256(abi.encodePacked(plainPieces[i]));
                uncommonPieces.push(_piece);
                pieceRarity[_piece] = 1;
                pieceExists[_piece] = true;
                piecesCounter++;
            }
        } else if (rarity == 2) {
            for (uint i = 0; i < plainPieces.length; i++) {
                _piece = keccak256(abi.encodePacked(plainPieces[i]));
                rarePieces.push(_piece);
                pieceRarity[_piece] = 2;
                pieceExists[_piece] = true;
                piecesCounter++;
            }
        } else revert("Invalid rarity");
    }

    // NOTE Auto version that uses a semi-randomic algorithm to generate the pieces
    function addPiecesAuto(uint number, string memory seed, uint rarity) 
                           public onlyAuth 
                           returns (bytes32[] memory createdPieces, uint cycles) {
        bytes32 random;
        bytes32[] memory _createdPieces = new bytes32[](number);
        uint validPieces;
        uint i;
        for (i=0; validPieces < number; i++) {
            random = keccak256(abi.encodePacked(
                block.timestamp,
                msg.sender,
                commonPieces.length,
                uncommonPieces.length,
                rarePieces.length,
                piecesCounter,
                balanceOf(msg.sender),
                block.prevrandao,
                seed,
                i));
            if (pieceExists[random] == false) {
                _createdPieces[validPieces] = random;
                if (rarity == 0) commonPieces.push(random);
                else if (rarity == 1) uncommonPieces.push(random);
                else if (rarity == 2) rarePieces.push(random);
                else revert("Invalid rarity");
                pieceExists[random] = true;
                piecesCounter++;
                validPieces++;
            }
        }
        cycles = i;
        createdPieces = _createdPieces;
    }

    // NOTE Finds a liquidity pair for rbt and weth
    function findRBTWETHPair() public onlyAuth {
        // Calling factory to get RBT and WETH pair
        rbtLiquidityAddress = IUniswapV2Factory(factory).getPair(rbtAddress, wethAddress);
        // If anything, we create the pair
        if (rbtLiquidityAddress == address(0)) {
            rbtLiquidityAddress = IUniswapV2Factory(factory).createPair(rbtAddress, wethAddress);
        }
    }

    // NOTE Inspects liquidity on Uniswap to always return ETH Price in RBT
    function getRBTETHPrice() public view returns (uint rbtTo005eth) {
        // Both rbt and weth must be defined
        require(rbtAddress != address(0) && wethAddress != address(0), "RBT or WETH not defined");
        // Also the pair of rbt and weth must be existant
        require(rbtLiquidityAddress != address(0), "RBT/WETH pair not found");
        // Getting reserves
        (uint rbtReserve, uint wethReserve, ) = IUniswapV2Pair(rbtLiquidityAddress).getReserves();
        // Calculating 1 ETH in RBT
        uint ethInRBT = rbtReserve / wethReserve;
        // Calculating 0.05 ETH in RBT
        rbtTo005eth = ethInRBT / 20;
    }
    
    function advanceEdition() public onlyAuth {
        currentEdition++;
    }
    // !SECTION Stacks

    // String manipulation functions
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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}