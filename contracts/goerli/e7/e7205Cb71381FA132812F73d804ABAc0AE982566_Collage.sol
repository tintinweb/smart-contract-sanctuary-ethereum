pragma solidity ^0.8.12;

// SPDX-License-Identifier: MIT
// Two storage slots for each 

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC721G.sol";
//import "hardhat/console.sol";

interface IRender {
     function tokenURI(uint256 tokenId, ERC721G.LayerStruct[16] memory layerIds) external view returns (string memory); 
    function previewCollage(ERC721G.LayerStruct[16] memory layerIds) external view returns(string memory);
}

interface IPieces {
    function burn( address account, uint256 id, uint256 value) external;
    function getPriceAndBurn(uint16[16] calldata layerIds) external returns (uint256 totalPrice);
}

contract Collage is ERC721G, OwnableUpgradeable {

    event MetadataUpdate(uint256 _tokenId);

    error MaxSupplyReached();
    error mintNotStarted();
    error maxMintsPerWallet();
    error notAValidSender();
    error maxFreeClaimed();
    error notTokenOwner();
    error onlyMinter();
    error payRightAmount();

    IRender public render;
    IPieces public pieces;
    uint256 public COLLAGE_PRICE;


    function initialize() initializer public {
        __ERC721G_init("Collage", "CLG", 1, 30);
        __Ownable_init();
        COLLAGE_PRICE = 0.03 ether;
    }

    // Define the NFT Constant Params
    uint256 public constant maxSupply = 1000;

    function mint() public payable {
        if(totalSupply() + 1 > maxSupply) revert MaxSupplyReached();
        if(msg.value != COLLAGE_PRICE) revert payRightAmount();
        _mint(msg.sender, 1);
    }

    function addLayer(uint256 tokenId, uint8 layer, uint8 scale, uint8 xOffset, uint8 yOffset, uint16 layerId) public {
        if(msg.sender != _tokenData[tokenId].owner) revert notTokenOwner();
        pieces.burn(msg.sender, layerId, 1);
        tokenInfo[tokenId].layers[layer] = LayerStruct(scale, xOffset, yOffset, layerId);
        emit MetadataUpdate(tokenId);
    }

    function mintAndSet(uint16[MAX_LAYERS] calldata layerIds, uint8[MAX_LAYERS] calldata scales, uint8[MAX_LAYERS] calldata xOffsets, uint8[MAX_LAYERS] calldata yOffsets) public payable {
        if(totalSupply() + 1 > maxSupply) revert MaxSupplyReached();
        //if(ERC721G._balanceData[msg.sender].mintedAmount + amount_ > maxPerWallet) revert maxMintsPerWallet();
        //check mint amount
        if(msg.value != COLLAGE_PRICE) revert payRightAmount();
        for(uint8 i; i < MAX_LAYERS; i++) {
            if(layerIds[i] > 0) pieces.burn(msg.sender, layerIds[i], 1);
        }
        _mintAndSet(msg.sender, 1, layerIds, scales, xOffsets, yOffsets);
    }

    function mintAndBuy(uint16[MAX_LAYERS] calldata layerIds, uint8[MAX_LAYERS] calldata scales, uint8[MAX_LAYERS] calldata xOffsets, uint8[MAX_LAYERS] calldata yOffsets) public payable {
        if(totalSupply() + 1 > maxSupply) revert MaxSupplyReached();
        //if(ERC721G._balanceData[msg.sender].mintedAmount + amount_ > maxPerWallet) revert maxMintsPerWallet();
        //check mint amount

        //get total price for pieces and increase mint counter without minting them to an addr
        uint256 totalPrice = pieces.getPriceAndBurn(layerIds);
        if(msg.value != (totalPrice + COLLAGE_PRICE)) revert payRightAmount();
        
        _mintAndSet(msg.sender, 1, layerIds, scales, xOffsets, yOffsets);
    }

        ////////////////////////  Set external contract addresses /////////////////////////////////

    function setRender( address _newRender) public onlyOwner {
        render = IRender(_newRender);
    }

    function setPieces( address _newPieces) public onlyOwner {
        pieces = IPieces(_newPieces);
    }

    function setCollagePrice(uint256 _newCollagePrice) external onlyOwner {
        COLLAGE_PRICE = _newCollagePrice;
    }

    ////////////////////////  TokenURI /////////////////////////////////

    function tokenURI(uint256 tokenId) override public view returns (string memory) { 
        return render.tokenURI(tokenId, tokenInfo[tokenId].layers);
    }

    function previewTokenCollage(uint256 tokenId, uint8 layerNr, uint8 scale, uint8 xOffset, uint8 yOffset, uint8 pieceId) public view returns (string memory) { 
        LayerStruct[MAX_LAYERS] memory _tokenLayers = tokenInfo[tokenId].layers;
        _tokenLayers[layerNr] = LayerStruct(scale, xOffset, yOffset, pieceId);
        return render.previewCollage(_tokenLayers);
    }

    function previewCollage(uint16[MAX_LAYERS] memory pieceIds, uint8[MAX_LAYERS] memory scale, uint8[MAX_LAYERS] memory xOffsets, uint8[MAX_LAYERS] memory yOffsets) public view returns (string memory) { 
        LayerStruct[MAX_LAYERS] memory _layers;// = new LayerStruct[](MAX_LAYERS);
        for(uint8 i; i < MAX_LAYERS; i++) {
            if(pieceIds[i] > 0) _layers[i] = LayerStruct(scale[i], xOffsets[i], yOffsets[i], pieceIds[i]);
        }
        return render.previewCollage(_layers);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./sharedStructs.sol";

abstract contract ERC721G is Initializable, SharedStructs {

    // Standard ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved,
        uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator,
        bool approved);

    // Standard ERC721 Global Variables
    string public name; // Token Name
    string public symbol; // Token Symbol

    // ERC721G Global Variables
    uint256 public tokenIndex; // The running index for the next TokenId

    uint256 public startTokenId; // Bytes Storage for the starting TokenId // removed immuntable
    uint256 public maxBatchSize;    // removed immuntable


    uint256 public constant MAX_LAYERS = 16;

    /** @dev instructions:
     *  name_ sets the token name
     *  symbol_ sets the token symbol
     *  startId_ sets the starting tokenId (recommended 0-1)
     *  maxBatchSize_ sets the maximum batch size for each mint (recommended 5-20)
     */
    
    // constructor(
    // string memory name_, string memory symbol_, 
    // uint256 startId_, uint256 maxBatchSize_) {
    //     name = name_;
    //     symbol = symbol_;
    //     tokenIndex = startId_;
    //     startTokenId = startId_;
    //     maxBatchSize = maxBatchSize_;
    // }

    function __ERC721G_init(string memory name_, string memory symbol_, 
    uint256 startId_, uint256 maxBatchSize_) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        tokenIndex = startId_;
        startTokenId = startId_;
        maxBatchSize = maxBatchSize_;
    }

    // ERC721G Structs
    struct OwnerStruct {
        address owner; // stores owner address for OwnerOf 
    }

    struct TokenInfoStruct {
        address creator;
        LayerStruct[MAX_LAYERS] layers; //could change this into seperate layers... 
    }

    struct BalanceStruct {
        uint32 balance; // stores the token balance of the address
        uint32 mintedAmount; // stores the minted amount of the address on mint
        uint32 allowListMinted;
        // 24 Free Bytes
    }

    // ERC721G Mappings
    mapping(uint256 => OwnerStruct) public _tokenData; // ownerOf replacement
    mapping(address => BalanceStruct) public _balanceData; // balanceOf replacement
    mapping(uint256 => OwnerStruct) public mintIndex; // uninitialized ownerOf pointer

    //tokenInfo mappings
    mapping(uint256 => address) public royaltyReciever; // ownerOf replacement
    mapping(uint256 => TokenInfoStruct) public tokenInfo; // balanceOf replacement

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved; // for single token approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll; // approveall

    ///// ERC721G: ERC721-Like Simple Read Outputs /////
    function totalSupply() public virtual view returns (uint256) {
        return tokenIndex - startTokenId;
    }
    function balanceOf(address address_) public virtual view returns (uint256) {
        return _balanceData[address_].balance;
    }

    ///// ERC721G: Range-Based Logic /////
    
    /** @dev explanation:
     *  _getTokenDataOf() finds and returns either the (and in priority)
     *      - the initialized storage pointer from _tokenData
     *      - the uninitialized storage pointer from mintIndex
     * 
     *  if the _tokenData storage slot is populated, return it
     *  otherwise, do a reverse-lookup to find the uninitialized pointer from mintIndex
     */
    function _getTokenDataOf(uint256 tokenId_) public virtual view
    returns (OwnerStruct memory) {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");
        
        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (_tokenData[tokenId_].owner != address(0)
            || tokenId_ >= tokenIndex) {
            return _tokenData[tokenId_];
        }

        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else { unchecked {
            uint256 _lowerRange = tokenId_;
            while (mintIndex[_lowerRange].owner == address(0)) { _lowerRange--; }
            return mintIndex[_lowerRange];
        }}
    }

    /** @dev explanation: 
     *  ownerOf calls _getTokenDataOf() which returns either the initialized or 
     *  uninitialized pointer. 
     *  Then, it checks if the token is staked or not through stakeTimestamp.
     *  If the token is staked, return the stakingAddress, otherwise, return the owner.
     */
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return _OwnerStruct.owner;
    }

    /** @dev explanation:
     *  _trueOwnerOf() calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  It returns the owner directly without any checks. 
     *  Used internally for proving the staker address on unstake.
     */
    function _trueOwnerOf(uint256 tokenId_) public virtual view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721G: Internal Single-Contract Staking Logic /////
    
    /** @dev explanation:
     *  _initializeTokenIf() is used as a beginning-hook to functions that require
     *  that the token is explicitly INITIALIZED before the function is able to be used.
     *  It will check if the _tokenData slot is initialized or not. 
     *  If it is not, it will initialize it.
     *  Used internally for staking logic.
     */
    function _initializeTokenIf(uint256 tokenId_, OwnerStruct memory _OwnerStruct) 
    internal virtual {
        // If the target _tokenData is not initialized, initialize it.
        if (_tokenData[tokenId_].owner == address(0)) {
            _tokenData[tokenId_] = _OwnerStruct;
        }
    }

    /** @dev explanation:
     *  _setStakeTimestamp() is our staking / unstaking logic.
     *  If timestamp_ is > 0, the action is "stake"
     *  If timestamp_ is == 0, the action is "unstake"
     * 
     *  We grab the tokenData using _getTokenDataOf and then read its values.
     *  As this function requires INITIALIZED tokens only, we call _initializeTokenIf()
     *  to initialize any token using this function first.
     * 
     *  Processing of the function is explained in in-line comments.
     */


    ///// ERC721G Range-Based Internal Minting Logic /////
    
    /** @dev explanation:
     *  _mintInternal() is our internal batch minting logic. 
     *  First, we store the uninitialized pointer at mintIndex of _startId
     *  Then, we process the balances changes
     *  Finally, we phantom-mint the tokens using Transfer events loop.
     */
    function _mintInternal(address to_, uint256 amount_) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(amount_ <= maxBatchSize, 
            "ERC721G: _mintInternal over maxBatchSize");

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        //mintIndex[_startId].owner = to_;
        //_tokenData[_startId] = OwnerStruct();
        _tokenData[_startId].owner = to_;
        
        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked { 
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    function _mintAndSet(address to_, uint256 amount_, uint16[MAX_LAYERS] calldata layerIds, uint8[MAX_LAYERS] calldata scales, uint8[MAX_LAYERS] calldata xOffsets, uint8[MAX_LAYERS] calldata yOffsets) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(amount_ <= maxBatchSize, 
            "ERC721G: _mintInternal over maxBatchSize");

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        //mintIndex[_startId].owner = to_;
        // _tokenData[_startId] = OwnerStruct(to_, [LayerStruct(layerIds[0], xOffsets[0], yOffsets[0]),LayerStruct(layerIds[1], xOffsets[1], yOffsets[1]),LayerStruct(layerIds[2], xOffsets[2], yOffsets[2]), LayerStruct(layerIds[3], xOffsets[3], yOffsets[3])]);
        // _owner;

        //this is not great because of all the storage write, I guess to avoid this need to change the way layers are stored
        for(uint8 i; i < MAX_LAYERS; i++) {
            if(layerIds[i] > 0) tokenInfo[_startId].layers[i] = LayerStruct(scales[i] , xOffsets[i], yOffsets[i], layerIds[i]);
        }
        _tokenData[_startId].owner = to_;
        tokenInfo[_startId].creator = to_;

        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked { 
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mint() is the function that calls _mintInternal() using a while-loop
     *  based on the maximum batch size (maxBatchSize)
     */
    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    /** @dev explanation:
     *  _transfer() is the internal function that transfers the token from_ to to_
     *  it has ERC721-standard require checks
     *  and then uses solmate-style approval clearing
     * 
     *  afterwards, it sets the _tokenData to the data of the to_ (transferee) as well as
     *  set the balanceData.
     *  
     *  this results in INITIALIZATION of the token, if it has not been initialized yet. 
     */
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        // the from_ address must be the ownerOf
        require(from_ == ownerOf(tokenId_), "ERC721G: _transfer != ownerOf");
        // cannot transfer to 0x0
        require(to_ != address(0), "ERC721G: _transfer to 0x0");

        // delete any approvals
        delete getApproved[tokenId_];

        // set _tokenData to to_
        _tokenData[tokenId_].owner = to_;

        // update the balance data
        unchecked { 
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    /** @dev explanation:
     *  balanceOf of the address returns UNSTAKED tokens only.
     *  to get the total balance of the user containing both STAKED and UNSTAKED tokens,
     *  we use this function. 
     * 
     *  this is mainly for external view only.
     *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
     */
    function totalBalanceOf(address address_) public virtual view returns (uint256) {
        return balanceOf(address_);
    }

    ///// ERC721G: ERC721 Standard Logic /////
    /** @dev clarification:
     *  no explanations here as these are standard ERC721 logics.
     *  the reason that we can use standard ERC721 logics is because
     *  the ERC721G logic is compartmentalized and supports internally 
     *  these ERC721 logics without any need of modification.
     */
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        address _owner = ownerOf(tokenId_);
        return (
            // "i am the owner of the token, and i am transferring it"
            _owner == spender_
            // "the token's approved spender is me"
            || getApproved[tokenId_] == spender_
            // "the owner has approved me to spend all his tokens"
            || isApprovedForAll[_owner][spender_]);
    }
    
    /** @dev clarification:
     *  sets a specific address to be able to spend a specific token.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(
            // "i am the owner, and i am approving this token."
            _owner == msg.sender 
            // "i am isApprovedForAll, so i can approve this token too."
            || isApprovedForAll[_owner][msg.sender],
            "ERC721G: approve not authorized");

        _approve(to_, tokenId_);
    }

    function _setApprovalForAll(address owner_, address operator_, bool approved_) 
    internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        // this function can only be used as self-approvalforall for others. 
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function _exists(uint256 tokenId_) internal virtual view returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        ////add EIP5050
        return iid_ == 0x01ffc9a7 || iid_ == 0x80ac58cd || iid_ == 0x5b5e139f || iid_ == 0x7f5828d0 || iid_ == 0x49064906 || iid_ == 0x2a55205a; 
    }

    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) == address_) { _tokens[_currentIndex++] = i; }
            unchecked { ++i; }
        }
        return _tokens;
    }

    function totalMinted(address address_) public virtual view returns(uint256) {
        return _balanceData[address_].mintedAmount;
    }

    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface SharedStructs {
    struct Trait {
        address data;
        uint16 destLen;
        ImageType imageType;
        uint8 xSize;
        uint8 ySize;
        string name;
    }

    // struct TraitStore {
    //     address data;
    //     uint16 destLen;
    // }

    struct LayerStruct {
        uint8 scale;
        uint8 xOffset;
        uint8 yOffset;
        uint16 layerId;
    }

    struct LayerInfo {
        address creator;
        uint8 maxSupply;
        uint8 supplyMinted;
        uint8 royalties;
        uint8 maxPerWallet;
        uint64 price;
    }

    enum ImageType {
        png,
        gif
    }
}