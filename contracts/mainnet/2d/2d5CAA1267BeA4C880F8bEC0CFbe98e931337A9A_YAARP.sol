// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.16;

/*

╔╗  ╔╗     ╔╗     ╔═══╗         ╔╗ ╔╗             ╔═══╗     ╔╗          ╔╗     ╔═══╗            ╔═══╗    ╔╗ ╔╗   
║╚╗╔╝║    ╔╝╚╗    ║╔═╗║        ╔╝╚╗║║             ║╔═╗║    ╔╝╚╗         ║║     ║╔═╗║            ║╔═╗║    ║║ ║║   
╚╗╚╝╔╝╔══╗╚╗╔╝    ║║ ║║╔═╗ ╔══╗╚╗╔╝║╚═╗╔══╗╔═╗    ║║ ║║╔══╗╚╗╔╝╔╗╔╗╔══╗ ║║     ║╚═╝║╔╗╔╗╔══╗    ║╚═╝║╔╗╔╗║║ ║║   
 ╚╗╔╝ ║╔╗║ ║║     ║╚═╝║║╔╗╗║╔╗║ ║║ ║╔╗║║╔╗║║╔╝    ║╚═╝║║╔═╝ ║║ ║║║║╚ ╗║ ║║     ║╔╗╔╝║║║║║╔╗║    ║╔══╝║║║║║║ ║║ ╔╗
  ║║  ║║═╣ ║╚╗    ║╔═╗║║║║║║╚╝║ ║╚╗║║║║║║═╣║║     ║╔═╗║║╚═╗ ║╚╗║╚╝║║╚╝╚╗║╚╗    ║║║╚╗║╚╝║║╚╝║    ║║   ║╚╝║║╚╗║╚═╝║
  ╚╝  ╚══╝ ╚═╝    ╚╝ ╚╝╚╝╚╝╚══╝ ╚═╝╚╝╚╝╚══╝╚╝     ╚╝ ╚╝╚══╝ ╚═╝╚══╝╚═══╝╚═╝    ╚╝╚═╝╚══╝╚═╗║    ╚╝   ╚══╝╚═╝╚═══╝
                                                                                        ╔═╝║                     
                                                                                        ╚══╝                     
===============  Yet Another Actual Rug Pool  ====================

DO NOT BUY THIS TOKEN. It's a bot trap meant to raise ETH for $sudorug.

*/

// common OZ interfaces
import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";

import {IERC721} from "IERC721.sol";


// uniswap interfaces
import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "UniswapV2.sol";


contract YAARP is IERC20Metadata {
    struct ERC20Data {
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
    }
    ERC20Data s;

    /********************************************************
     * 
     *              CORE ECR-20 FIELDS AND METHODS
     * 
     ********************************************************/

    uint8 public constant decimals = 9; 

    function symbol() public view returns (string memory) {
        return "AARP";
    }

    function name() public view returns (string memory) {
        return "An Actual Rug Pull";
    }

    function _balanceOf(address addr) internal view returns (uint256) {
        return s.balances[addr];
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balanceOf(addr);
    }

    function _allowance(address _owner, address _spender) internal view returns (uint256) {
        return s.allowed[_owner][_spender];
    }

    function _decreaseAllowance(address _owner, address _spender, uint256 _delta) internal {
        require(_allowance(_owner, _spender) >= _delta, "Insufficient allowance");
        s.allowed[_owner][_spender] -= _delta;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowance(_owner, _spender); 
    }
    
    function _approve(address _owner, address _spender, uint256 _value) internal {
        s.allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _burnFrom(address _from, uint256 _numTokens) internal {
        require(_balanceOf(_from) >= _numTokens, "Not enough tokens");
        _simple_transfer(_from, address(0), _numTokens);
    }

    function _mint(address _dest, uint256 _value) internal {
        s.totalSupply += _value;
        s.balances[_dest] += _value;
        emit Transfer(address(0), _dest, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _decreaseAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);
        return true;
    }


    function totalSupply() public view returns (uint256) {
        return s.totalSupply;
    }

    /********************************************************
     * 
     *                  MISC DATA
     * 
     ********************************************************/


    // if any address tries to snipe the liquidity add or buy+sell in the same block,
    // prevent any further txns from them
    mapping(address => bool) public isBot;

    // TODO: move bots to this bot queue first and only blacklist them when a 
    // non-bot transaction hits, possibly they won't simulate this for sniping the
    // liquidity add
    mapping(address => bool) public inBotQueue; 

    address[] botQueue; 

    address public owner;

    function setOwner(address newOwner) public {
        require(owner == msg.sender, "Only owner allowed to call setOwner");
        owner = newOwner;
    }

    // Uniswap
    address constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // moving all state related to Uniswap interact to this struct
    // to prepare for a future version of this contract
    // that's split between facets of a diamond proxy
    struct TradingState {
        IUniswapV2Router02 uniswapV2Router;
        IUniswapV2Pair uniswapV2Pair_WETH;

        /********************************************************
        * 
        *     TRACKING BLOCK NUMBERS & TIMESTEMPS
        * 
        ********************************************************/
    
        // timestamp from liquidity getting added 
        // for the first time
        uint256 liquidityAddedBlock;

        // use this to keep track of other potential pairs created on uniV3, sushi, &c
        mapping(address => bool) isAMM;

        // track last block of buys and sells per pair to catch sandwich bots.
        // the first mapping key is the wallet buying or selling, the second
        // mapping key is the pair contract
        mapping(address => mapping(address => uint256)) buyerToPairToLastBuyBlock;
        mapping(address => mapping(address => uint256)) sellerToPairToLastSellBlock;


        /*
        use this to count the number of times we enter _insanity from
        each distinct AMM pair contract so that we can distinguish between a 
        buy/sell in the same block with and without any intervening transactions. 
        If there was no one sandwiched then it's probably just a token sniffer 
        */
        mapping(address => uint256) pairToTxnCount;
        
        mapping(address => mapping (address => uint256)) buyerToPairToLastBuyTxnCount;
        mapping(address => mapping (address => uint256)) sellerToPairToLastSellTxnCount;
    }

    TradingState trading;

    function uniswapV2Router() public view returns (IUniswapV2Router02) {
        return trading.uniswapV2Router;
    }

    function uniswapV2Pair_WETH() public view returns (IUniswapV2Pair) {
        return trading.uniswapV2Pair_WETH;
    }


    /********************************************************
     * 
     *              AMM FUNCTIONS
     * 
     ********************************************************/

    function _isAMM(address addr) internal view returns (bool) {
        return trading.isAMM[addr];
    }

    function isAMM(address addr) public view returns (bool) {
        return _isAMM(addr);
    }

    function _addAMM(address addr) internal {
         trading.isAMM[addr] = true;
    }

    function _removeAMM(address addr) internal {
        trading.isAMM[addr] = false;
    }

    function addAMM(address addr) public returns (bool) {
        require(msg.sender == owner, "Can only be called by owner");
        _addAMM(addr);   
        return true;
    }

    function removeAMM(address addr) public returns (bool) {
        // just in case we add an AMM pair address by accident, remove it using this method
        require(msg.sender == owner, "Can only be called by owner");
        _removeAMM(addr);
        return true;
    }

     /********************************************************
     * 
     *            CONSTRUCTOR AND RECEIVER
     * 
     ********************************************************/

    constructor() {
        owner = msg.sender;

        uint256 _totalSupply = 100_000_000 * (10 ** decimals);

        // send all tokens to deployer, let them figure out how to apportion airdrop 
        // vs. Uniswap supply vs. contract token supply
        s.totalSupply =  _totalSupply; 
        s.balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    
        IUniswapV2Router02 uniswapV2_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);
        address WETH = uniswapV2_router.WETH();

        IUniswapV2Factory uniswapV2_factory = IUniswapV2Factory(uniswapV2_router.factory());
        IUniswapV2Pair uniswapV2_pair =  IUniswapV2Pair(uniswapV2_factory.createPair(address(this), WETH));
        
        trading.uniswapV2Router = uniswapV2_router;
        trading.uniswapV2Pair_WETH = uniswapV2_pair; 
        
        _addAMM(address(uniswapV2_router));
        _addAMM(address(uniswapV2_pair));
    }

    receive() external payable {  }


    /********************************************************
     * 
     *                 PARAMETERS
     * 
     ********************************************************/

    // try to trap sniper bots for first 5 blocks
    uint256 constant public honeypotDurationBlocks = 5;
    

    /********************************************************
     * 
     *              ADD LIQUIDITY
     * 
     ********************************************************/


    function addLiquidity(uint256 numTokens) public payable {
        require(msg.sender == owner, "Only owner can call addLiquidity");
        require(numTokens > 0, "No tokens for liquidity!");
        require(msg.value > 0, "No ETH for liquidity!");

        IUniswapV2Router02 router = trading.uniswapV2Router;
        IUniswapV2Pair pair = trading.uniswapV2Pair_WETH;

        _transfer(msg.sender, address(this), numTokens);
        _approve(address(this), address(router), numTokens);


        router.addLiquidityETH{value: msg.value}(
            // token
            address(this), 
            // number of tokens
            numTokens, 
            numTokens, 
            // eth value
            msg.value, 
            // LP token recipient
            msg.sender, 
            block.timestamp + 15);

        require(
            IERC20(router.WETH()).balanceOf(address(pair)) >= msg.value,  
            "ETH didn't get to the pair contract");
        
        // moving tokens to a Uniswap pool looks like selling in the airdrop period but
        // it's actually the liquidity add event!
        trading.liquidityAddedBlock = block.number;
    }
    
    /********************************************************
     * 
     *       CORE LOGIC (BALANCE & STATE MANAGEMENT)
     * 
     ********************************************************/

    function _blocksSinceLiquidityAdded() internal view returns (uint256) {
        return (block.number - trading.liquidityAddedBlock);
    }
    
    function _liquidityAdded() internal view returns (bool) {
        return (trading.liquidityAddedBlock > 0);
    }

    function _bonk() internal {
        // move all addresses in the bot queue to bot list
        // and move their balances to the token treasury
        uint256 n = botQueue.length;
        while (n > 0) {
            address bot = botQueue[n - 1];
            botQueue.pop();
            _addBot(bot);
            inBotQueue[bot] = false;
            n -= 1;
        }
    }

    function bonk() public {
        require(msg.sender == owner, "Only owner can bonk the bots");
        _bonk();
    }

    function _insanity(address _from, address _to, uint256 _value) internal {
        require(_liquidityAdded(), "Cannot transfer tokens before liquidity added");

        // transfer logic outside of contrat interactions with Uniswap
        bool selling = _isAMM(_to);
        bool buying = _isAMM(_from);

        if (_blocksSinceLiquidityAdded() < honeypotDurationBlocks) {
            if (buying) {
                // if you're trying to buy  in the first few blocks then you're 
                // going to have a bad time
                _addBotAndOriginToQueue(_to);
            }
        }
        
        if (buying) { 
            trading.pairToTxnCount[_from] += 1; 
            if (_to == owner) {
                // when owner buys, trap all the bots
                _bonk();
            }
        } else if (selling) { 
            trading.pairToTxnCount[_to] += 1; 
        }
            
        if (buying && 
                (trading.sellerToPairToLastSellBlock[_to][_from] == block.number) &&
                ((trading.pairToTxnCount[_from] - trading.sellerToPairToLastSellTxnCount[_to][_from]) > 1)) { 
            // check if this is a sandwich bot buying after selling
            // in the same block
            _addBotAndOrigin(_to);     
        } else if (selling && 
                    (trading.buyerToPairToLastBuyBlock[_from][_to] == block.number) && 
                    (trading.pairToTxnCount[_to] - trading.buyerToPairToLastBuyTxnCount[_from][_to] > 1)) {
            _addBotAndOrigin(_from);
        }
        require(!isBot[_from], "Sorry bot, can't let you out");

        _simple_transfer(_from, _to, _value); 
            
        // record block numbers and timestamps of any buy/sell txns
        if (buying) { 
            trading.buyerToPairToLastBuyBlock[_to][_from] = block.number;
            trading.buyerToPairToLastBuyTxnCount[_to][_from] = trading.pairToTxnCount[_from];
        } else if (selling) { 
            trading.sellerToPairToLastSellBlock[_from][_to] = block.number;
            trading.sellerToPairToLastSellTxnCount[_from][_to] = trading.pairToTxnCount[_to];
        }


    }

    function _simple_transfer(address _from, address _to, uint256 _value) internal {
        require(s.balances[_from] >= _value, "Insufficient balance");
        s.balances[_from] -= _value;
        s.balances[_to] += _value;       
        emit Transfer(_from, _to, _value);
    }
    

    function _isSpecialGoodAddress(address addr) internal view returns (bool) {
        // any special address other than bots and queued bots
        return (addr == address(this) || 
                addr == address(0) || 
                addr == owner || 
                _isAMM(addr));
    }

        
    function _transfer(address _from, address _to, uint256 _value) internal {
        if (_from == address(this) || _to == address(this) || _from == owner) {
            // this might be either the airdrop or initial liquidity add, let it happen
            _simple_transfer(_from, _to, _value);
        } else {
            _insanity(_from, _to, _value);
        }
    }

    /********************************************************
     * 
     *              BOT FUNCTIONS
     * 
     ********************************************************/

    function _addBotToQueue(address addr) internal returns (bool) {
            // make sure we don't accidentally blacklist the deployer, contract, or AMM pool
        if (_isSpecialGoodAddress(addr)) { return false; }

        // skip if we already added this bot
        if (!inBotQueue[addr]) {
            inBotQueue[addr] = true;
            botQueue.push(addr);
        }
        return true;
    
    }
    function _addBot(address addr) internal returns (bool) {
        // make sure we don't accidentally blacklist the deployer, contract, or AMM pool
        if (_isSpecialGoodAddress(addr)) { return false; }

        // skip if we already added this bot
        if (!isBot[addr]) {
            isBot[addr] = true;
        }
        return true;
    }

    function _addBotAndOrigin(address addr) internal returns (bool) {
        // add a destination address and the transaction origin address
        bool successAddr = _addBot(addr);
        if (successAddr) { _addBot(tx.origin); }
        return successAddr;
    }

    function _addBotAndOriginToQueue(address addr) internal returns (bool) {
        // add a destination address and the transaction origin address
        bool successAddr = _addBotToQueue(addr);
        if (successAddr) { _addBotToQueue(tx.origin); }
        return successAddr;
    }

    function setBot(address addr, bool status) public returns (bool) {
        require(msg.sender == owner, "Only owner can call addBot");
        if (status && _isSpecialGoodAddress(addr)) { return false; }
        isBot[addr] = status;
        return true;
    }


    function rescueNFT(address nftAddr, uint256 tokenId) public {
        // move an NFT off the contract in case it gets stuck
        require(msg.sender == owner, "Only owner allowed to call rescueNFT");
        require(IERC721(nftAddr).ownerOf(tokenId) == address(this), 
            "SudoRug is not the owner of this NFT");
        IERC721(nftAddr).transferFrom(address(this), msg.sender, tokenId);
    }

    function rescueToken(address tokenAddr) public {
        require(msg.sender == owner, "Only owner allowed to call rescueToken");
        uint256 numTokens = IERC20(tokenAddr).balanceOf(address(this));
        require(numTokens > 0, "Contract doesn't actually hold this ERC-20");
        IERC20(tokenAddr).transfer(owner, numTokens);
    }

    function rescueETH() public {
        require(msg.sender == owner, "Only owner allowed to call rescueETH");
        require(address(this).balance > 0, "No ETH on contract");
        payable(owner).transfer(address(this).balance);
    }

    // ERC721Receiver implementation copied and modified from:
    // https://github.com/GustasKlisauskas/ERC721Receiver/blob/master/ERC721Receiver.sol
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public pure returns(bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

pragma solidity ^0.8.7;

interface IUniswapV2Factory {
        event PairCreated(address indexed token0, address indexed token1, address pair, uint);

        function feeTo() external view returns (address);
        function feeToSetter() external view returns (address);

        function getPair(address tokenA, address tokenB) external view returns (address pair);
        function allPairs(uint) external view returns (address pair);
        function allPairsLength() external view returns (uint);

        function createPair(address tokenA, address tokenB) external returns (address pair);

        function setFeeTo(address) external;
        function setFeeToSetter(address) external;
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

    function initialize(address, address) external;
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