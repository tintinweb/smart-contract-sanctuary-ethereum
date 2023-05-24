// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IAssetTrading.sol";

import "./libraries/Counters.sol";
import "./libraries/Assets.sol";

// Author: @dangvhh
contract AssetTrading is IAssetTrading {

    using Counters for Counters.Counter;
    
    Counters.Counter private counterPairActive;

    uint256 public constant PRICE_DECIMAL = 10**6;

    mapping(address => mapping (address => uint256)) public balances; // addresss owner => address token ERC20, ERC721 , ETH (address(this)) => balance;
    mapping(address => mapping (uint256 => address)) public tokenIdByOwners; //address token => token id => address owner
    Assets.Pair[] public pairs;

    mapping(address => uint256[]) public pairIdsByOwners; // address owner => uint256[] pairIds

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "AssetTrading: LOCK");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier askIsActive(uint256 id){
        require(id < pairs.length, "AssetTrading: ID_OUT_RANGE");
        require(pairs[id]._is_finished == false, "AssetTrading: ASK_FINISHED");
        _;
    }
    modifier validAmount(uint256 amount) {
        require(amount > 0 && amount % PRICE_DECIMAL == 0, "AssetTrading: INVALID_AMOUNT");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event TransferNFT(address indexed from, address indexed to, uint256 indexed tokenId);
    event AskCreated(address indexed owner, uint256 indexed id, address assetOut, uint256 amountOut, Assets.Type assetOutType);
    event AskRemoved(address indexed owner, uint256 indexed id, address assetOut, uint256 amountOut, Assets.Type assetOutType);
    event DoBid(address indexed bidder, uint256 indexed id, uint256 value);
    // TODO: handle deposit, withdraw, balanceOf Token ERC20
    function depositTokens(address token, uint256 amount) external lock override{
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        unchecked {
            balances[msg.sender][token] += amount;
        }
        emit Transfer(msg.sender, address(this), amount);
    }
    function withdrawTokens(address token, uint256 amount) external lock override {
        require(balances[msg.sender][token] >= amount, "AssetTrading: NOT_ENOUGHT_TOKEN");
        IERC20(token).transfer(msg.sender, amount);
        unchecked {
            balances[msg.sender][token] -= amount;
        }
        emit Transfer(address(this), msg.sender, amount);
    }
    function balanceTokenOf(address owner, address token) external view override returns(uint256){
        return balances[owner][token];
    }

    // TODO: handle deposit, withdraw, balanceOf ETH
    function depositETH(uint256 amount) external payable lock override {
        require(msg.value == amount, "AssetTrading: INCORRECT_AMOUNT");
        unchecked {
            balances[msg.sender][address(this)] += amount;
        }
        emit Transfer(msg.sender, address(this), amount);
    }
    function withdrawETH(uint256 amount) external lock override {
        require(balances[msg.sender][address(this)] >= amount, "AssetTrading: NOT_ENOUGHT_ETH");
        payable(msg.sender).transfer(amount);
        unchecked {
            balances[msg.sender][address(this)] -= amount;
        }
        emit Transfer(address(this), msg.sender, amount);
    }
    function balanceETHOf(address owner) external view override returns(uint256){
        return balances[owner][address(this)];
    }

    //TODO: handle deposit, withdraw, balanceOf Token ERC721
    function depositNFT(address token, uint256 tokenId) external lock override {
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        unchecked {
            balances[msg.sender][token] += 1;
        }
        tokenIdByOwners[token][tokenId] = msg.sender;
        emit TransferNFT(msg.sender, address(this), tokenId);
    }
    function withdrawNFT(address token, uint256 tokenId) external lock override {
        require(tokenIdByOwners[token][tokenId] == msg.sender, "AssetTrading: NOT_TOKEN_OWNER");
        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
        tokenIdByOwners[token][tokenId] = address(0);
        unchecked {
            balances[msg.sender][token] -= 1;
        }
        emit TransferNFT(address(this), msg.sender, tokenId);
    }
    function balanceNFTOf(address owner, address token) external view override returns(uint256){
        return balances[owner][token];
    }
    function tokenIdOf(address token, uint256 tokenId) external view override returns(address) {
        return tokenIdByOwners[token][tokenId];
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    //TODO: get metadata pair in contract AssetTrading
    function getAllPairActive() external view override returns(Assets.Pair[] memory){
        Assets.Pair[] memory result = new Assets.Pair[](counterPairActive.current());
        uint256 cnt = 0;
        for (uint256 i = 0; i < pairs.length; i++){
            if (pairs[i]._is_finished) {
                continue;
            }
            result[cnt] = pairs[i];
            unchecked {
                cnt++;
            }
        }
        return result;
    }
    function getPairsByOwner(address owner) external view override returns(Assets.Pair[] memory){
        Assets.Pair[] memory result = new Assets.Pair[](pairIdsByOwners[owner].length);
        for (uint256 i = 0; i < pairIdsByOwners[owner].length; i++){
            result[i] = pairs[pairIdsByOwners[owner][i]];        
        }
        return result;
    }
    function getPairById(uint256 id) external view returns(Assets.Pair memory) {
        return pairs[id];
    }
    //TODO: handle logic core function
    function _getPrice(uint256 amountOut, uint256 amountIn) internal pure returns(uint256){
        return amountOut*PRICE_DECIMAL/amountIn;
    }
    function _createAsk(
        address assetOut,
        uint256 amountOut,
        address assetIn,
        uint256 amountIn
        ) internal returns(uint256){
        require(assetOut != address(0) && assetIn != address(0), "AssetTrading: INVALID_ADDRESS");
        require(balances[msg.sender][assetOut] >= amountOut, "AssetTrading: NOT_ENOUGHT_BALANCE");
        Assets.Pair memory pair;

        pair._id = pairs.length;

        pair._owner = msg.sender;
        pairIdsByOwners[msg.sender].push(pair._id);

        pair._asset_out._asset_address = assetOut;
        pair._asset_out._amount = amountOut;

        pair._asset_in._asset_address = assetIn;
        pair._asset_in._amount = amountIn;

        pairs.push(pair);
        counterPairActive.increment();
        unchecked {
            balances[msg.sender][assetOut] -= amountOut;
        }
        return pair._id;
    }
    //TODO: handle create ask Tokens to Tokens, ETH, NFTs
    function createAskTokensToTokens(
        address tokenOut,
        uint256 amountOut,
        address tokenIn,
        uint256 amountIn
    ) external lock validAmount(amountOut) validAmount(amountIn) override {
        require(tokenOut != tokenIn, "AssetTrading: IDENTICAL_ADDRESSES");
        uint256 price = _getPrice(amountOut, amountIn);
        require(price > 0, "AssetTrading: INVALID_PRICE"); 
        uint256 id = _createAsk(tokenOut, amountOut, tokenIn, amountIn);
        pairs[id]._price = price;
        pairs[id]._asset_out._type = Assets.Type.ERC20;
        pairs[id]._asset_in._type = Assets.Type.ERC20;

        emit AskCreated(msg.sender, id, tokenOut, amountOut, pairs[id]._asset_out._type);
    }
    function createAskTokensToETH(
        address tokenOut,
        uint256 amountOut,
        uint256 amountIn
    ) external lock validAmount(amountOut) validAmount(amountIn) override {
        uint256 price = _getPrice(amountOut, amountIn);
        require(price > 0, "AssetTrading: INVALID_PRICE");                
        uint256 id = _createAsk(tokenOut, amountOut, address(this), amountIn);
        pairs[id]._price = price;
        pairs[id]._asset_out._type = Assets.Type.ERC20;
        pairs[id]._asset_in._type = Assets.Type.ETH;

        emit AskCreated(msg.sender, id, tokenOut, amountOut, pairs[id]._asset_out._type);
    }
    function createAskTokensToNFT(address tokenOut, uint256 amountOut, address tokenIn, uint256 tokenIdIn) external lock validAmount(amountOut) override {
        uint256 id = _createAsk(tokenOut, amountOut, tokenIn, 1);
        pairs[id]._price = amountOut;
        pairs[id]._asset_out._type = Assets.Type.ERC20;
        pairs[id]._asset_in._token_id = tokenIdIn;
        pairs[id]._asset_in._type = Assets.Type.ERC721;

        emit AskCreated(msg.sender, id, tokenOut, amountOut, pairs[id]._asset_out._type);
    }
    
    //TODO: handle create ask ETH to Tokens, NFTs
    function createAskETHToTokens(
        uint256 amountOut,
        address tokenIn,
        uint256 amountIn
    ) external lock validAmount(amountOut) validAmount(amountIn) override {
        uint256 price = _getPrice(amountOut, amountIn);
        require(price > 0, "AssetTrading: INVALID_PRICE");
        uint256 id = _createAsk(address(this), amountOut, tokenIn, amountIn);
        pairs[id]._price = price;
        pairs[id]._asset_out._type = Assets.Type.ETH;
        pairs[id]._asset_in._type = Assets.Type.ERC20;

        emit AskCreated(msg.sender, id, address(0), amountOut, pairs[id]._asset_out._type);
    }
    function createAskETHToNFT(uint256 amountOut, address tokenIn, uint256 tokenIdIn) external lock validAmount(amountOut) override {
        uint256 id = _createAsk(address(this), amountOut, tokenIn, 1);
        pairs[id]._price = amountOut;
        pairs[id]._asset_out._type = Assets.Type.ETH;
        pairs[id]._asset_in._token_id = tokenIdIn;
        pairs[id]._asset_in._type = Assets.Type.ERC721;
    
        emit AskCreated(msg.sender, id, address(0), amountOut, pairs[id]._asset_out._type);
    }

    //TODO: handle create ask NFTs to Tokens, ETH, NFTs
    function createAskNFTToTokens(address tokenOut, uint256 tokenIdOut, address tokenIn, uint256 amountIn) external lock validAmount(amountIn) override {
        require(tokenIdByOwners[tokenOut][tokenIdOut] == msg.sender, "AssetTrading: NOT_TOKEN_OWNER");
        uint256 id = _createAsk(tokenOut, 1, tokenIn, amountIn);
        pairs[id]._price = amountIn;
        pairs[id]._asset_out._type = Assets.Type.ERC721;
        pairs[id]._asset_out._token_id = tokenIdOut;
        pairs[id]._asset_in._type = Assets.Type.ERC20;

        tokenIdByOwners[tokenOut][tokenIdOut] = address(this);
        emit AskCreated(msg.sender, id, tokenOut, 1, pairs[id]._asset_out._type);
    }
    function createAskNFTToETH(address tokenOut, uint256 tokenIdOut, uint256 amountIn) external lock validAmount(amountIn) override {
        require(tokenIdByOwners[tokenOut][tokenIdOut] == msg.sender, "AssetTrading: NOT_TOKEN_OWNER");
        uint256 id = _createAsk(tokenOut, 1, address(this), amountIn);
        pairs[id]._price = amountIn;
        pairs[id]._asset_out._type = Assets.Type.ERC721;
        pairs[id]._asset_out._token_id = tokenIdOut;
        pairs[id]._asset_in._type = Assets.Type.ETH;

        tokenIdByOwners[tokenOut][tokenIdOut] = address(this);
        emit AskCreated(msg.sender, id, tokenOut, 1, pairs[id]._asset_out._type);
    }
    function createAskNFTToNFT(address tokenOut, uint256 tokenIdOut, address tokenIn, uint256 tokenIdIn) external lock override {
        require(tokenIdByOwners[tokenOut][tokenIdOut] == msg.sender, "AssetTrading: NOT_TOKEN_OWNER");
        uint256 id = _createAsk(tokenOut, 1, tokenIn, 1);
        pairs[id]._price = PRICE_DECIMAL;       
        pairs[id]._asset_out._type = Assets.Type.ERC721;
        pairs[id]._asset_out._token_id = tokenIdOut;
        pairs[id]._asset_in._type = Assets.Type.ERC721;
        pairs[id]._asset_in._token_id = tokenIdIn;

        tokenIdByOwners[tokenOut][tokenIdOut] = address(this);
        emit AskCreated(msg.sender, id, tokenOut, 1, pairs[id]._asset_out._type);
    }

    function removeAsk(uint256 id) external lock askIsActive(id) override {
        require(pairs[id]._owner == msg.sender, "AssetTrading: NOT_ASK_OWNER");
        unchecked {
            balances[msg.sender][pairs[id]._asset_out._asset_address] += pairs[id]._asset_out._amount;
        }
        if (pairs[id]._asset_out._type == Assets.Type.ERC721)
        {
            tokenIdByOwners[pairs[id]._asset_out._asset_address][pairs[id]._asset_out._token_id] = msg.sender; 
        }
        uint256 amountOut = pairs[id]._asset_out._amount;
        pairs[id]._asset_out._amount = 0;
        pairs[id]._asset_in._amount = 0;
        pairs[id]._price = 0;
        pairs[id]._is_finished = true;

        counterPairActive.decrement();

        emit AskRemoved(msg.sender, id, pairs[id]._asset_out._asset_address, amountOut, pairs[id]._asset_out._type);
    }
    /*
    amountOut*decimals/AmountIn = price => amountOut*decimals = price*amountIn
    =>  amountBidIn = (price*amountBidOut)/decimals
    =>  newAmountOut = amountOut - amountBidIn = amountOut - (price*amountBidIn)/decimals
    => newAmountIn = amountIn - amountBibIn;
     */
    function _getAmountBidIn(uint256 id, uint256 amountBidOut) internal view returns(uint256){
        if (amountBidOut > pairs[id]._asset_in._amount) {
            return pairs[id]._asset_in._amount;
        }else {
            return pairs[id]._price * amountBidOut / PRICE_DECIMAL;
        }
    }
    function _updatePairAfterDoBid(uint256 id, uint256 amountBidOut, uint256 amountBidIn) internal {
        //  Update new amountIn and amountOut in pair
        if (amountBidOut == pairs[id]._asset_in._amount){
            pairs[id]._is_finished = true;
            counterPairActive.decrement();
        }
        pairs[id]._asset_out._amount = pairs[id]._asset_out._amount - amountBidIn;
        pairs[id]._asset_in._amount = pairs[id]._asset_in._amount - amountBidOut;      
    }
    //TODO: handle do bid TOKEN,ETH => NFT
    function _doBidTokensOrETHToNFT(uint256 id, address bidder, uint256 tokenId) internal {
        unchecked {
            balances[bidder][pairs[id]._asset_in._asset_address] -= 1;
            balances[pairs[id]._owner][pairs[id]._asset_in._asset_address] += 1;
        }
        tokenIdByOwners[pairs[id]._asset_in._asset_address][tokenId] = pairs[id]._owner;
        unchecked {
            balances[bidder][pairs[id]._asset_out._asset_address] += pairs[id]._asset_out._amount;
        }
        _updatePairAfterDoBid(id, 1, pairs[id]._asset_out._amount);
    }
    //TODO: handle do bid TOKEN,ETH => TOKEN,ETH
    function _doBidTokensOrETHNotToNFT(uint256 id, address bidder, uint256 amount) internal {
        unchecked {
            balances[bidder][pairs[id]._asset_in._asset_address] -= amount;
            balances[pairs[id]._owner][pairs[id]._asset_in._asset_address] += amount;
        }
        uint256 amountBidIn = _getAmountBidIn(id, amount);
        unchecked {
            balances[bidder][pairs[id]._asset_out._asset_address] += amountBidIn;
        }
        _updatePairAfterDoBid(id, amount, amountBidIn);
    }
    //TODO: handle do bid NFT => TOKEN, ETH
    function _doBidNFTToTokensOrETH(uint256 id, address bidder, uint256 amount) internal {
        unchecked {
            balances[bidder][pairs[id]._asset_in._asset_address] -= amount;
            balances[pairs[id]._owner][pairs[id]._asset_in._asset_address] += amount;
            balances[bidder][pairs[id]._asset_out._asset_address] += 1;
        }
        tokenIdByOwners[pairs[id]._asset_out._asset_address][pairs[id]._asset_out._token_id] = bidder;
        _updatePairAfterDoBid(id, amount, pairs[id]._asset_out._amount);
    }
    //TODO: handle do bid NFT => NFT
    function _doBidNFTToNFT(uint256 id, address bidder, uint256 tokenId) internal {
        tokenIdByOwners[pairs[id]._asset_in._asset_address][tokenId] = pairs[id]._owner;
        tokenIdByOwners[pairs[id]._asset_out._asset_address][pairs[id]._asset_out._token_id] = bidder;
        _updatePairAfterDoBid(id, 1, 1);
    }
    //TODO: handle bidder do bid Token,ETH,NFT => Token,ETH
    function doBidNotToNFT(uint256 id, uint256 amountBidOut) external lock askIsActive(id) validAmount(amountBidOut) override {
        require(pairs[id]._asset_in._type != Assets.Type.ERC721, "AssetTrading: INVALID_PAIR_ID");
        require(balances[msg.sender][pairs[id]._asset_in._asset_address] >= amountBidOut, "AssetTrading: NOT_ENOUGHT_BALANCE");
        if (pairs[id]._asset_out._type == Assets.Type.ERC721)
        {
            // NFT => TOKEN,ETH
            require(amountBidOut >= pairs[id]._asset_in._amount, "AssetTrading: INCORRECT_AMOUNT");
            _doBidNFTToTokensOrETH(id, msg.sender, amountBidOut);
        }else {
            // TOKEN, ETH => TOKEN,ETH
            _doBidTokensOrETHNotToNFT(id, msg.sender, amountBidOut);
        }
        emit DoBid(msg.sender, id, amountBidOut);
    }
    //TODO: handle bidder do bid TOKEN,ETH,NFT => NFT
    function doBidToNFT(uint256 id, uint256 tokenIdBidOut) external lock askIsActive(id) override {
        require(pairs[id]._asset_in._type == Assets.Type.ERC721, "AssetTrading: INVALID_PAIR_ID");
        require(tokenIdBidOut == pairs[id]._asset_in._token_id, "AssetTrading: INCORRECT_TOKEN_ID");
        require(tokenIdByOwners[pairs[id]._asset_in._asset_address][tokenIdBidOut] == msg.sender, "AssetTrading: NOT_TOKEN_OWNER");
        if (pairs[id]._asset_out._type == Assets.Type.ERC721)
        {
            // NFT => NFT
            _doBidNFTToNFT(id, msg.sender, tokenIdBidOut);
        }else {
            // TOKEN, ETH => NFT
            _doBidTokensOrETHToNFT(id, msg.sender, tokenIdBidOut);
        }
        emit DoBid(msg.sender, id, tokenIdBidOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IERC721Receiver.sol";
import "./IAssetTradingMetadata.sol";
interface IAssetTrading is IAssetTradingMetadata, IERC721Receiver{
    // Token
    function depositTokens(address token, uint256 amount) external;
    function withdrawTokens(address token, uint256 amount) external;
    // ETH
    function depositETH(uint256 amount) external payable;
    function withdrawETH(uint256 amount) external;
    // NFT
    function depositNFT(address token, uint256 tokenId) external;
    function withdrawNFT(address token, uint256 tokenId) external;
    //TODO: Handle logic core function
    
    // Tokens To
    function createAskTokensToTokens(
        address tokenOut,
        uint256 amountOut,
        address tokenIn,
        uint256 amountIn
    ) external;
    function createAskTokensToETH(
        address tokenOut,
        uint256 amountOut,
        uint256 amountIn
    ) external;
    function createAskTokensToNFT(
        address tokenOut,
        uint256 amountOut,
        address tokenIn,
        uint256 tokenIdIn
    ) external;
    // ETH To
    function createAskETHToTokens(
        uint256 amountOut,
        address tokenIn,
        uint256 amountIn
    ) external;
    function createAskETHToNFT(
        uint256 amountOut,
        address tokenIn,
        uint256 tokenIdIn
    ) external;
    //NFTs To
    function createAskNFTToTokens(
        address tokenOut,
        uint256 tokenIdOut,
        address tokenIn,
        uint256 amountIn
    ) external;
    function createAskNFTToETH(
        address tokenOut,
        uint256 tokenIdOut,
        uint256 amountIn
    ) external;
    function createAskNFTToNFT(
        address tokenOut,
        uint256 tokenIdOut,
        address tokenIn,
        uint256 tokenIdIn
    ) external;


    function removeAsk(uint256 id) external;
    
    function doBidNotToNFT(uint256 id, uint256 amount) external;
    function doBidToNFT(uint256 id, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/Assets.sol";

interface IAssetTradingMetadata {
    function balanceTokenOf(address owner, address token) external view returns(uint256);
    function balanceETHOf(address owner) external view returns(uint256);
    function balanceNFTOf(address owner, address token) external view returns(uint256);
    function tokenIdOf(address token, uint256 tokenId) external view returns(address);
    function getAllPairActive() external view returns(Assets.Pair[] memory);
    function getPairsByOwner(address owner) external view returns(Assets.Pair[] memory);
    function getPairById(uint256 id) external view returns(Assets.Pair memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


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
pragma solidity >=0.7.0 <0.9.0;


interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
pragma solidity >=0.7.0 <0.9.0;

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
pragma solidity >=0.7.0 <0.9.0;

// import "./Strings.sol";

library Assets {
    // using Strings for *;
    enum Type {
        ETH,
        ERC20,
        ERC721
    }
    struct Detail {
        address _asset_address;
        uint256 _amount;
        uint256 _token_id;
        Type _type;
    }
    struct Pair {
        uint256 _id;
        address _owner;
        uint256 _price;
        Detail _asset_out;
        Detail _asset_in;
        bool _is_finished;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
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