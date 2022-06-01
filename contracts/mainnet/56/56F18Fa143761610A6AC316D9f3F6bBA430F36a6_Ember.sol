//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IEmber.sol";
import "./interfaces/IProxy.sol";
import "./factory.sol";
import "./proxy.sol";

contract Ember is factory, IEmber{

    // A unique Id for each NFT to be lended
    uint256 private lendingId;

    // represent seconds in one day
    uint256 public ONE_DAY = 86400;

    // A uint to struct mapping to store lending & renting data against Id
    mapping(uint256 => IEmber.LendingRenting) private lendingRenting;

    //A address BorrowerProxy struct to store newBorrower address & proxyAddress
    mapping(address => IEmber.BorrowerProxy) private BorrowerProxyAddress;
    
    /**
    * @notice lend NFT for renting.
    * @dev A unique lending Id will be associated with each NFT staked.
    * @param _nft - nft address
    * @param _adapter - adapter address: adapters include functions allowed by lender
    * to be executed using it's nft by borrower
    * @param _tokenId - nft's tokenId
    * @param _maxRentDuration - rent duration for NFT
    * @param _perDayRentCharges - per day rent charges  
    * Emits a {lend} event.
    */
     
    function lend(
        address _nft,
        address _adapter, 
        uint256 _tokenId,
        uint256 _maxRentDuration,
        uint256 _perDayRentCharges
    ) external override {

        createLendData(_tokenId, lendingId, _maxRentDuration, _perDayRentCharges, msg.sender, _adapter);

        ensureLendable(_nft, _maxRentDuration, _perDayRentCharges);

        IERC721(_nft).transferFrom(msg.sender,address(this),_tokenId);

        emit Lent(
        _nft,
        msg.sender,
        _tokenId,
        lendingId,
        _perDayRentCharges,
        lendingRenting[lendingId].lending.stakedTill,
        block.timestamp
        );

        lendingId++;
        
    }


    /**
    * @notice Rent NFT.
    * @dev for each unique borrower a proxy contract will be deployed and that
    * borrowed nft will be transffered to that proxy contract
    * payable - Amount in ETH for renting the NFT will be transffered to NFT lender 
    * @param _nft - nft address
    * @param _tokenId - nft's tokenId
    * @param _lendingId - lendingID for that NFT  
    * Emits a {rent} event.
    */

    function rent(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId,
        uint256 _rentDuration
    ) external override payable returns(address){
        uint256 amount = msg.value;
        address proxy = getProxy(_lendingId, msg.sender);

        if(IERC721(_nft).ownerOf(_tokenId) != address(this)){
            
            IProxy(proxy).getNFT(_nft, _tokenId, _lendingId);    

        }

        createRentData(_lendingId, _rentDuration, _tokenId, _nft, msg.sender);
        
        ensureRentable(_nft, _tokenId, _lendingId, _rentDuration);
        
        payable(lendingRenting[_lendingId].lending.lenderAddress).transfer(address(this).balance);
        
        IERC721(_nft).transferFrom(address(this),proxy,_tokenId);
        
        emit Rented(
        msg.sender,
        lendingRenting[_lendingId].lending.lenderAddress,
        _nft,
        _tokenId,
        _lendingId,
        _rentDuration,
        amount,
        block.timestamp
        );
        
        return proxy;   
    }


    /**
    * @notice unLend the the NFT.
    * @dev  get NFT from proxy if it's not in this contract and then transfer to the lender 
    * @param _nft - nft address
    * @param _tokenId - nft's tokenId
    * @param _lendingId - lendingID for that NFT 
    * Emits a {LendingStopped} event.
    */

    function stopLending(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId
    ) external override {

        ensureStopable(_nft,_tokenId,_lendingId);

        if(IERC721(_nft).ownerOf(_tokenId)!= address(this)){
    
            IProxy(checkProxy(lendingRenting[_lendingId].renting.renterAddress)).getNFT(_nft, _tokenId, _lendingId);
           
        }

            IERC721(_nft).transferFrom(address(this),msg.sender,_tokenId);
            emit LendingStopped(msg.sender, block.timestamp, _nft);
            delete lendingRenting[_lendingId];
    }


    /**
    * @notice  update the renting struct agianst lendingId.
    * @param _lendingId - lendingID 
    * @param _rentDuration -  rent duration for NFT
    * @param msgSender - Renter address
    */

    function createRentData(uint256 _lendingId,  uint256 _rentDuration, uint256 _tokenId, address _nft,address msgSender) internal {

        lendingRenting[_lendingId].renting.renterAddress = payable(msgSender);
        lendingRenting[_lendingId].renting.rentedTill = block.timestamp + _rentDuration;
        lendingRenting[_lendingId].renting.rentDuration = _rentDuration;
        lendingRenting[_lendingId].renting.tokenId = _tokenId;
        lendingRenting[_lendingId].renting.nft = _nft;
        
    
    }


    /**
    * @notice  update the lending struct agianst lendingId.
    * @param _tokenId - lendingID 
    * @param _lendingId - lendingID 
    * @param _maxRentDuration - NFT lend duration i.e for 30 days
    * @param _perDayRentPrice - _perDayrentPrice
    * @param msgSender - lender address
    * @param _adapter - adapter address
    */

    function createLendData(uint256 _tokenId,uint256 _lendingId, uint256 _maxRentDuration, uint256 _perDayRentPrice, address msgSender, address _adapter) internal{

        lendingRenting[_lendingId].lending.lenderAddress = msgSender;
        lendingRenting[_lendingId].lending.adapter = _adapter;
        lendingRenting[_lendingId].lending.dailyRentPrice = _perDayRentPrice;
        lendingRenting[_lendingId].lending.stakedTill = block.timestamp + _maxRentDuration;
        lendingRenting[_lendingId].lending.tokenId = _tokenId; 
    
    }

    /**
    * @notice  returns the proxy address for after delopying new proxy contract cond: unique borrrower
    * @dev check that isnewBorrower then deploy new Proxy; update Borrowerproxy struct & return proxy Address
    * @param _lendingId - lendingID 
    * @param _borrower - borrower address
    */
    


    function getProxy(uint256 _lendingId, address _borrower) internal returns(address){
        
        if(!BorrowerProxyAddress[_borrower].newBorrower) // new borrower
        {   
            
            bytes memory bytecode = getbytecode(address(this), _borrower);
            getAddress(bytecode, _lendingId);
            address _proxyAddress = deploy(bytecode, _lendingId);
            BorrowerProxyAddress[_borrower].newBorrower = true;
            BorrowerProxyAddress[_borrower].proxyAddress = _proxyAddress;
            
        }

        return BorrowerProxyAddress[_borrower].proxyAddress;

    }

    // view functions 

    /**
     * @dev ensure the NFT is lendable by passing through require checks
     * @param _nft - nft address
     * @param _maxRentDuration - lended till
     * @param _dailyRentPrice  - per day rent charges 
    */

    function ensureLendable(address _nft, uint256 _maxRentDuration, uint256 _dailyRentPrice) internal view{

        require(is721(_nft),"Ember:: Not ERC721 token");
        require(_maxRentDuration!=0 && _dailyRentPrice!=0,"Ember :: Invalid Parameters");
    
    }


    /**
     * @dev ensure the NFT is rentable by passing through require checks
     * @param _nft - nft address
     * @param _tokenId - tokenid
     * @param _lendingId - lendingId
     * @param _rentDuration - rent duration for NFT 
    */

    function ensureRentable(address _nft, uint256 _tokenId, uint256 _lendingId, uint256 _rentDuration) internal view{

        require(lendingRenting[_lendingId].lending.lenderAddress!=msg.sender, "Lender can't be borrower for it's own NFT");
        require(_rentDuration!=0,"Ember :: Invalid RentDuaration");
        require(is721(_nft),"Ember:: Not ERC721 token");
        require(lendingRenting[_lendingId].lending.tokenId == _tokenId,"Ember::invalid tokenId || _lendingId");
        require(lendingRenting[_lendingId].renting.rentedTill <= lendingRenting[_lendingId].lending.stakedTill,"Ember::Rent duration>staked duration");
        require(lendingRenting[_lendingId].lending.dailyRentPrice * (lendingRenting[_lendingId].renting.rentDuration)/ONE_DAY == msg.value, "Invalid Amount");
    
    }

    /**
     * @dev ensure the NFT is can unlendable by passing through require checks
     * @param _nft - nft address
     * @param _tokenId - tokenId
     * @param _lendingId - lendingId
    */

    function ensureStopable(address _nft, uint256 _tokenId, uint256 _lendingId) internal view{

        require(lendingRenting[_lendingId].lending.lenderAddress == msg.sender, "Ember::not lender");
        require(is721(_nft),"Ember:: Not ERC721 token");
        require(lendingRenting[_lendingId].lending.tokenId == _tokenId,"Ember:: invalid tokenId || _lendingId");
    
    }

    // Getter Functions


    /**
     * @dev checks whether NFT is type of ERC721 & returns true if success 
     * @param _nft nft address
    */

    function is721(address _nft) private view returns (bool) {

        return IERC165(_nft).supportsInterface(type(IERC721).interfaceId);
    }

    /**
     * @dev Returns the adapter address against lendingId
     * @notice this function can be called from proxy contract  
     * @param _lendingId - lendingId
    */

    function getNFTAdapter(uint256 _lendingId) external override view returns(address){

        return lendingRenting[_lendingId].lending.adapter;
        
    }

    /**
     * @dev Returns the proxy address against borrower  
     * @param _borrower - borrower address
    */

    function checkProxy(address _borrower) public override view returns(address){

        return BorrowerProxyAddress[_borrower].proxyAddress;
        
    }


    /**
     * @dev Returns the NFT staked Till  
     * @param _lendingId - lendingId
    */
    function getStakedTill(uint256 _lendingId) external override view returns(uint256){

        return lendingRenting[_lendingId].lending.stakedTill; 
    
    }

    /**
     * @dev Returns the NFT rented Till  
     * @param _lendingId - lendingId
    */
    function getRentedTill(uint256 _lendingId) external override view returns(uint256){

        return lendingRenting[_lendingId].renting.rentedTill; 
    
    }


    /**
     * @dev Returns the NFT per day rent charges  
     * @param _lendingId - lendingId
    */
    function getDailyRentCharges(uint256 _lendingId) external override view returns(uint256){

        return lendingRenting[_lendingId].lending.dailyRentPrice; 
    
    }

    /**
     * @dev Returns the NFT address & tokenId associated to the lendingId  
     * @param _lendingId - lendingId
    */

    function getNFTtokenID(uint256 _lendingId) external override view returns(address,uint256){

        return (lendingRenting[_lendingId].renting.nft,lendingRenting[_lendingId].renting.tokenId);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IEmber {

    struct Lending {
        address lenderAddress;
        address adapter;
        uint256 dailyRentPrice;
        uint256 stakedTill;
        uint256 tokenId;
    }


    struct Renting {
        address payable renterAddress;
        address nft;
        uint256 tokenId;
        uint256 rentedTill;
        uint256 rentedAt;
        uint256 rentDuration;
    }

    struct LendingRenting {
       Lending lending;
       Renting renting;
    }

    struct BorrowerProxy{
        bool newBorrower;
        address proxyAddress;
    }
    
    event Lent(
        address indexed nftAddress,
        address indexed lenderAddress,
        uint256 tokenId,
        uint256 lendingId, 
        uint256 dailyRentPrice,
        uint256 stakedTill,
        uint256 lentAt
    );

    event Rented(
        address indexed renterAddress,
        address indexed lenderAddress,
        address indexed nft,
        uint256 tokenId,
        uint256 lendingId,
        uint256 rentDuration,
        uint256 amountPaid,
        uint256 rentedAt
    );

    event LendingStopped(address msgSender, uint256 stoppedAt, address nft);

    function lend(
        address _nft,
        address _adapter, 
        uint256 _tokenId,
        uint256 _maxRentDuration,
        uint256 _dailyRentPrice
    ) external;

    
    function rent(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId,
        uint256 _rentDuration
    ) external payable returns(address);

    function stopLending(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId
    ) external;

    function checkProxy(address _borrower) external view returns(address);

    function getRentedTill(uint256 _lendingId) external view returns(uint256);

    function getStakedTill(uint256 _lendingId) external view returns(uint256);

    function getDailyRentCharges(uint256 _lendingId) external view returns(uint256);

    function getNFTAdapter(uint256 _lendingId) external view returns(address);

    function getNFTtokenID(uint256 _lendingId) external view returns(address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IProxy{

    function getNFT(address _nft, uint256 _tokenId, uint256 _lendingId) external;
    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./proxy.sol";
contract factory {
    event deployed(address addr,  uint256 _salt);

    //1:get bytecode contract to be deployed 
    function getbytecode(address stakingAddress, address proxyOwner) public pure returns(bytes memory) {
        
        bytes memory bytecode = type(Proxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(stakingAddress, proxyOwner)); //constructor argument of bytecode
        
    }

    //2:compute address of contract to be deployed
    function getAddress(bytes memory bytecode, uint256 _salt) public view returns(address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),//address of deployer: proxy will be deployed from factory
                _salt, // a random number
                keccak256(bytecode)
                )
        );

        //cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    //3 deploy contract
    function deploy(bytes memory bytecode, uint256 _salt) public payable returns(address){
        address addr;
        //how to call create2
            //create2(v,p,n,s)
            //1:v-amount of ETH to send 
            //2:p-pointer to start of the code in memory
            //3:n-size of code
            //4:s-salt
        assembly{
            addr:= create2(
                0, // wei sent with current call
                add(bytecode,0x20), //actual code start after skipping the first 32 bytes
                mload(bytecode), //load the size of the code contained in the first 32 bytes
                _salt // a random number
            )
            //check contract is deployed: if not zero else revert the whole process
            if iszero(extcodesize(addr)) { 
                revert(0, 0) 
                }
        }
        emit deployed(addr, _salt);
        
        return addr;
           
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IEmber.sol";


// Proxy contract deployed at run time for each unique borrower & NFT transffered to proxy
// it holds the all NFTs borrowed by a single borrower address
// it serve as msg.sender for games contract
// this contract delegates call to suitable adapters which further calls to game contract

 contract Proxy {

    // store borrower address as proxyOwner   
    address proxyOwner;

    // store staking contract address
    address stakingAddress;

    constructor(address _staking, address _proxyOwner){

        proxyOwner = _proxyOwner;  
        stakingAddress = _staking;
    }
    

    /**
     * @dev fallback function executed when no other function signature matches in this contract
     * for each function signature that exexuted using fallback must have type
     * uint256 lendingId as a last paramter of that function signature  
     * extract lendingId from msg.data to get NFT adapter & to pass through few require checks
     * returns the success value or error  
    */
    
    fallback () external payable {

        bytes calldata data = msg.data;
        bytes memory lendId =bytes(data[msg.data.length-32:]); //last parameter must be lendingId
        uint256 _lendingId = uint256(abi.decode(lendId,(uint256)));
        address adapter = IEmber(stakingAddress).getNFTAdapter(_lendingId);
        ensureCallable(_lendingId, msg.sender);

        assembly {
            
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the adapter
            //gas	addr	argsOffset	argsLength	retOffset	retLength	
            let result := delegatecall(gas(), adapter, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
    }


    /**
     * @notice this function can be called uisng staking contract
     * @dev transfers the nft back to satking contract after passing through require
     * @param _nft - nft address
     * @param _tokenId - nft's tokenId
     * @param _lendingId - lendingId
    */


    function getNFT(address _nft, uint256 _tokenId, uint256 _lendingId) external {
        
        require(stakingAddress == msg.sender,"Invalid::Call");
        require(IEmber(stakingAddress).getRentedTill(_lendingId)< block.timestamp, "Rent duration not Expired");
        IERC721(_nft).transferFrom(address(this),stakingAddress,_tokenId);
    
    }

    /**
     * @notice this function called from above fallback function to ensure the valididity 
     * @param _lendingId - lendingId
     * @param msgSender - msg.sender address
    */

    function ensureCallable(uint256 _lendingId, address msgSender) internal view{
        
        (address _nft, uint256 _tokenId) = IEmber(stakingAddress).getNFTtokenID(_lendingId);
        require(_nft != address(0),"Invalid::ID");
        require(IERC721(_nft).ownerOf(_tokenId) == address(this),"NFT not in proxy");
        require(proxyOwner == msgSender,"caller must be owner");
        require(IEmber(stakingAddress).getRentedTill(_lendingId)> block.timestamp, "Rent duration Expired");
            
    }

    receive() external payable {}

    
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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