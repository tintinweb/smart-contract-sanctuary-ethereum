/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

//"SPDX-License-Identifier: MIT"
//Neolithic DeFi Instruments Developed by The Suns Of DeFi [StraightSwap] 2022

//SOD: IBN5X && Pro. Kalito

pragma solidity ^0.8.0;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);


    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.7;

contract straightswap {

    address public owner;
    address public StraightSwap;
    uint256 public tradingFee;
    uint256 public tradeId;
    bool public PAUSED;

    uint256 private constant _NON_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier truHolder(address _giveAddress){
        IERC721 giveAddress = IERC721(_giveAddress);
        require(giveAddress.balanceOf(msg.sender) > 0, "You dont own this NFT");
        _;
    }

    modifier canTransferNFT(address nftContract, uint256 tokenId)
        {
                IERC721 nftContract = IERC721(nftContract);
                require(nftContract.getApproved(tokenId) == address(this), "You need  Straight Swap permission first"); 
                _;
        }  
   
    modifier onlyOwner{
        require(msg.sender == owner, "Only Owner can use function");
        _;
    } 

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    } 


    constructor(){

        owner = msg.sender;
        StraightSwap = payable(address(this));
        tradeId = 1;
        tradingFee = 0.004 ether;
        PAUSED = false;
        _status = _NON_ENTERED;


    }

    mapping(uint256 => bool) public tradeInit;
    mapping(uint256 => bool) public doneDeal;
    mapping(uint256 => bool) public dealsOff;
    
    mapping(address => bool) public waved;
    mapping(address => bool) public approvedERC20;
    mapping(address => uint256) public tokenPrice;

    struct singleTrade{
        uint256 tradeId;
        address trader;
        address giveNFT;
        uint256 giveId;
        address wantNFT;
        uint256 wantID;
        uint256 endTime;
    }

    event tradeStarted (uint256 tradeId, address trader, address NFT, uint256 tokenId, address wantNFT, uint256 wantTokenId, string tokenType, uint256 tradeTime);
    event tradeCompleted (uint256 tradeId, address trader, address NFT, uint256 tokenId,  address otherparty, address wantNFT, uint256 wantTokenId, string tokenType, uint256 tradeTime);
    event tradeWithdrawn(uint256 tradeId, address trader, address NFT, uint256 tokenId, address wantNFT, uint256 wantTokenId, string tokenType, uint256 cancelTime);



    singleTrade [] public SingleTrader;
   
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external  pure returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    
    //Reentracy over kill 
    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NON_ENTERED;
    }

    //Trade for ERC721
    function init721Trade(address _giveNFT, uint256 _giveId, address _wantNFT, uint256 _wantID, uint256 _endtime) public payable truHolder(_giveNFT)  canTransferNFT(_giveNFT, _giveId) returns(bool){
            require(PAUSED != true , "New Trades have been paused");
            require(tradeInit[tradeId] != true, "This trade has already been setup");
            
            if(waved[_giveNFT] != true){
                require(msg.value >= tradingFee, "Not enough funds to cover fee!");
            }
            
            tradeInit[tradeId] = true;

            IERC721(_giveNFT).safeTransferFrom(msg.sender, address(this), _giveId);

            uint256 timer = block.timestamp + _endtime;

            SingleTrader.push(singleTrade(tradeId,msg.sender, _giveNFT, _giveId,  _wantNFT, _wantID, timer));
            
            doneDeal[tradeId] = false;

            emit tradeStarted (tradeId, msg.sender, _giveNFT, _giveId, _wantNFT, _wantID, "ERC721", timer);

            tradeId++;

            return true;

    }


    function makeTrade721(uint256 _tradeId, address _wantNFT, uint256 _wantID ) public truHolder(_wantNFT) returns(bool){
            require(PAUSED != true , "paused");

            singleTrade storage trade =  SingleTrader[_tradeId - 1];
 
            require(trade.wantNFT == _wantNFT && trade.wantID == _wantID, "invalid");
           

            if(block.timestamp >= trade.endTime){
                require(dealsOff[_tradeId] != true, "canceled");
            }

            doneDeal[trade.tradeId] = true;
            
            IERC721(_wantNFT).safeTransferFrom(msg.sender, trade.trader, _wantID); //send NFT to trade
            IERC721(trade.giveNFT).safeTransferFrom(address(this), msg.sender, trade.giveId); //retrieve NFT from contract


            emit tradeCompleted (_tradeId, trade.trader, trade.giveNFT, trade.giveId, msg.sender, trade.wantNFT, trade.wantID, "ERC721", block.timestamp);

            delete SingleTrader[_tradeId - 1];

            return true;
    }


    function withdrawTrade721(uint256 _tradeId) public returns(bool){
        require(doneDeal[_tradeId] != true, "deal already complete");
        
        singleTrade storage trade =  SingleTrader[_tradeId - 1];

        require(msg.sender == trade.trader, "This is not your trade");
        require(block.timestamp >= trade.endTime, "Trade period not over");

        dealsOff[_tradeId] = true;

        IERC721(trade.giveNFT).safeTransferFrom(address(this), trade.trader, trade.giveId);

        emit tradeWithdrawn(_tradeId, msg.sender, trade.giveNFT, trade.giveId, trade.wantNFT, trade.wantID, "ERC721", block.timestamp);

        delete SingleTrader[_tradeId - 1];

        return true;

    }
 
    //Utils and views
    function getTradeDetails721(uint256 _tradeId) public view returns(singleTrade memory){
        return SingleTrader[_tradeId - 1];
    }

    function getAllTrades() public view returns(uint256){
        return SingleTrader.length;
    }

    //Owner Functions
    function setFee(uint256 _fee) public onlyOwner returns(uint256) {
        tradingFee = _fee;

        return tradingFee;
    }
    
    function waveContract(address _contract, bool stat) public onlyOwner returns(bool){
        waved[_contract] = stat;

        return waved[_contract];
    }
    
    function withdraw() public payable onlyOwner {

        (bool hs, ) = payable(0x625Cd0169A8B36E138D84a00BCa1d9d1c8b45f51).call{value: address(this).balance * 45 / 100}("");
        require(hs);

        (bool sb, ) = payable(0xca22CBe44Ad307c1f2F5498f71dDE4fA25251136).call{value: address(this).balance * 45 / 100}("");
        require(sb);
        
        //expenses payout.
        // =============================================================================
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
  }

}