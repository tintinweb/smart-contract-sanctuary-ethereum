// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./flakecoin.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract FlakeNFT is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string public _symbol;

    // Access Control Parent Contract
    FlakeCoin private _ledger;

    // Where we store our NFTs
    string private _baseURI; 

    //ERC721 Events:
    event Approve(address owner, address operator, uint256 nft_index);  
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
     // _tokenAddress might define in constructor
    constructor(address _tokenAddress) Ownable(){
        _name = 'Art Flake';
        _symbol =  'Flake';
        // Todo: set coin contract address:
        _ledger = FlakeCoin(_tokenAddress);
        _baseURI = 'https://flake.art/n/';
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Make sure the token is possilbe.
        if(tokenId <= _ledger.maxSupply() && tokenId > 0){
            // All flake.art coins are pre-mapped to our CDN, and populated upon minting.
            return string(abi.encodePacked(_baseURI, tokenId.toString()));
        }
        return  "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _ledger.balanceOfNft(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _ledger.getOwnerbyNft(tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        if(_ledger.approveNft(to,tokenId)){
            // Let others know of the sucessful call.
            emit Approval(_msgSender(), to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _ledger.getApprovedNft(tokenId);
    }

    /**_transferNft
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _ledger.setApprovalForAllNfts(operator, approved);
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _ledger.isApprovedForAllNfts(owner,operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if(_ledger.transferNftFrom(from,to,tokenId)){
            emit Transfer(from, to, tokenId);
        }
    }

    // todo capture event for the erc721 reciever needed by this method.
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if(_ledger.safeTransferNftFrom(from,to,tokenId)){
            emit Transfer(from, to, tokenId);
        }
    }

    // todo capture event for the erc721 reciever needed by this method.
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata /*data_*/
    ) public override {
        if(_ledger.safeTransferNftFrom(from,to,tokenId)){
            emit Transfer(from, to, tokenId);
        }
    }    

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     */
    function mint(address /*to*/, uint256 /*tokenId*/) public view virtual {
        revert("Art Flake has a max supply of one million and is not mintable.");
    }

    /**
     * @dev sends tokenId to the owner of the contract.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     */
    function burn(uint256 tokenId) public virtual {
        // "Burned" NFTs are returned to the owner of the contract. 
        _ledger.transferNftFrom(_msgSender(), owner(), tokenId);
    }

}

// SPDX-License-Identifier: CC-BY-NC-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC20NFTAccess.sol";

contract FlakeCoin is IERC20, Ownable {
    using ECDSA for bytes32;

    string private _name;
    string public _symbol;
    // The max number of coins.
    uint256 public _maxSupply;
    // The current number of coins.
    uint256 private _totalSupply;
    // the address that can sign mint requests.
    address private _treasury;

  //using SafeMath for uint256;
    // erc20 token balance 
    mapping(address => uint256) private _balances;

    // erc20 access control
    mapping(address => mapping(address => uint256)) private _allowancesCoin;

    // erc721 access contorl
    mapping(address => mapping(address => uint256[])) private _allowancesNft;

    // NFTs owned by a wallet
    mapping(address => uint256[]) private _OwnerToLiquidCoinMap;

    // NFTs Frozen by a wallet
    mapping(address => uint256[]) private _OwnerToFrozenNftMap;

    // Find the owner of a specific NFT
    mapping(uint256 => address) private _LiquidNftToOwnerMap;

    // Find the allowence of a specific NFT
    mapping(uint256 => address) private _NftToAllowMap;

    // Find the owner of a specific NFT
    mapping(uint256 => address) private _FrozenNftsToOwnerMap;

    // Mapping from token ID to approved address NFT ERC-721
    mapping(uint256 => address) private _tokenApprovals;


    // represents if the address is denylisted with the contract. denylist takes priority before all other permissions
    mapping(address => bool) private _denylist;
    event AddedToDenylist(address[] addrs);
    event RemovedFromDenylist(address[] addrs);
    // custom mint events:
    event MintedNft(address owner, uint256 nft_index);
    event MintedCoin(address owner, uint256 nft_index);
    event UpdatedTreasury(address owner);
      // custom events
    event FreezeNft(address arbiter, uint256 nft_index);
    event UnfreezeNft(address arbiter, uint256 nft_index);

    constructor(){
        // Art Flake Coin
        _name = 'Art Flake';    
        // Globally unique trading symbol
        _symbol = 'Flake';
        // 1 million tokens.
        _maxSupply = 1000000;
        // We start off without a premine, no coins minted.
        _totalSupply = 0;
        // Not sub-devideable, only whole tokens.
        //_setupDecimals(0);
        // The owner can sign mint requests to start:
        _treasury = owner();
    }


    /**
     * @dev Must return 0, NFTs cannot be sub-devided.
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 0;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     *      
     * NOTE: Returns the liquid coin blance.    
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        // Return only liquid balance.
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
        return _allowancesCoin[owner][spender];
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
        if(sender != _msgSender()){
            uint256 currentAllowance = _allowancesCoin[_msgSender()][sender];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            // Approval doesn't need to be chcked twice, it is checked above^
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }            
        }
        _transfer(sender, recipient, amount);
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
     * - `addedValue` must be a positive number.   
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(0 < addedValue, "ERC20: must decrease by a postive number");
        _approve(_msgSender(), spender, _allowancesCoin[_msgSender()][spender] + addedValue);
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
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * - `subtractedValue` must be a postive number.  
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowancesCoin[_msgSender()][spender];
        require(0 < subtractedValue, "ERC20: must decrease by a postive number");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Get list of NFTs based on the owner.
     *     
     * Requirements:
     *
     * - `owner` must the address of the owner you want to lookup.   
     */
    function getNftsByOwner(address owner) public view virtual returns (uint256[] memory) {
        uint256 liquidLength = _OwnerToLiquidCoinMap[owner].length;
        uint256 frozenLength = _OwnerToFrozenNftMap[owner].length;
        uint256[] memory ownership = new uint256[](liquidLength + frozenLength);
        // check both lists to see if the user owns it:
        for(uint256 i=0; i < liquidLength; i++){
            ownership[i]=_OwnerToLiquidCoinMap[owner][i];
        }
        for(uint256 i=0; i < frozenLength; i++){
            ownership[i+liquidLength]=_OwnerToFrozenNftMap[owner][i];
        }
        return ownership;
    }

    /**
     * @dev Get the owner address based on the nft index
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.  
     */
    function getOwnerbyNft(uint256 nft_index) public view virtual returns (address) {
        if(isLiquid(nft_index)){
            // Liquid coin
            return _LiquidNftToOwnerMap[nft_index];
        }else if(isFrozen(nft_index)){
            // Frozen as stricly a flake NFT
            return _FrozenNftsToOwnerMap[nft_index];
        }else{
            return address(0);
        }
    }

    /**
     * @dev Gets the NFT status as a liquid or frozen solid.
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.  
     */
    function isFrozen(uint256 nft_index) public view virtual returns (bool) {
        // Find if an NFT cannot be used an ERC20
        return _FrozenNftsToOwnerMap[nft_index] != address(0);
    }

    /**
     * @dev Gets the NFT status as a liquid or frozen solid.
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.  
     */
    function isLiquid(uint256 nft_index) public view virtual returns (bool) {
        // Find if an NFT cannot be used an ERC20
        return _LiquidNftToOwnerMap[nft_index] != address(0);
    }

    /**
     * @dev allow the owner to freeze their NFT so it cannot be used as an ERC20
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to freeze.       
     */
    function freezeNft(uint256 nft_index) public virtual returns (bool) {
         // This is an ERC20 balance change, check OFAC.
         _beforeTokenTransfer(_msgSender(), _msgSender(), 1);
         // Do we this liquidity to spare?
        if(_LiquidNftToOwnerMap[nft_index] == _msgSender()){
            // Remove from the coin ledger:
            if(_removeCoin(_msgSender(), nft_index)){
                // Add to the NFT ledger:
                if(_addNft(_msgSender(), nft_index)){
                    // Tell everybody about this huge success:
                    emit FreezeNft(_msgSender(), nft_index);
                    return true;   
                }             
            }
        }else{
            revert("Error:  You must own the NFT and it cannot be Frozen.");
        }
        return false;
    }

    /**
     * @dev allow the owner to unlock so it can be used as an ERC20
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function unfreezeNft(uint256 nft_index) public virtual returns (bool) {
        //This is an ERC20 balance change, check OFAC.
        _beforeTokenTransfer(_msgSender(), _msgSender(), 1);
        if(_FrozenNftsToOwnerMap[nft_index] == _msgSender()){
            if(_LiquidNftToOwnerMap[nft_index] == _msgSender()){
                // Remove from the coin ledger:
                if(_removeNft(_msgSender(), nft_index)){
                    // Add to the NFT ledger:
                    if(_addCoin(_msgSender(), nft_index)){
                        // Tell everybody about this huge success:
                        emit UnfreezeNft(_msgSender(), nft_index);
                        return true;                        
                    }
                }
            }else{
                revert("Error: You must own this NFT.");
            }
        }else{
            revert("Error: NFT Must be frozen.");
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out coins, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _addCoin(address owner, uint256 nft_index) internal virtual returns (bool){
        // Make sure this coin isn't owned.
        // This prevents replay attacks - the second message will have no effect.
        if(getOwnerbyNft(nft_index) == address(0)){
            // Add it as liquid to the wallet.
            _OwnerToLiquidCoinMap[owner].push(nft_index);
            // Set owner
            _LiquidNftToOwnerMap[nft_index] = owner;
            // Update liquid balance.
            _balances[owner]+=1;
            return true;
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out tokens, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _addNft(address owner, uint256 nft_index) internal virtual returns (bool){
        // Make sure this coin isn't owned.
        // This prevents replay attacks
        if(getOwnerbyNft(nft_index) == address(0)){
            // Add it as a frozen NFT.
            _OwnerToFrozenNftMap[owner].push(nft_index);
            // set owner
            _FrozenNftsToOwnerMap[nft_index] = owner;
            // The user will have to unfreeze it if they want to use it as an ERC20
            return true;            
        }
        return false;
    }    

    /**
     * @dev allow the owner of the contract to hand out coins, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _removeCoin(address owner, uint256 nft_index) internal virtual returns (bool){
        uint256 nftCount = _OwnerToLiquidCoinMap[owner].length;
        // Check the liquid NFTs first:
        for(uint256 idx=0; idx < nftCount; idx++) {
            // Do we have a balance left?
            if(_balances[owner] < 1){
                // Protective code - prevent int overflow.
                break;
            }
            if(_OwnerToLiquidCoinMap[owner][idx] == nft_index){
                // Update liquid balance.
                _balances[owner] -= 1;                
                // remove from the old user's wallet:
                delete _OwnerToLiquidCoinMap[owner][idx];
                // Delete nft index to ownership lookup.
                delete _LiquidNftToOwnerMap[nft_index];
                // one and done.
                return true;
            }
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out tokens, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _removeNft(address owner, uint256 nft_index) internal virtual returns (bool){
        uint256 nftCount = _OwnerToFrozenNftMap[owner].length;
        for(uint256 idx = 0; idx < nftCount; idx++) {
            if (_OwnerToFrozenNftMap[owner][idx] == nft_index){             
                // remove from the old user's wallet:
                delete _OwnerToFrozenNftMap[owner][idx];
                // Delete nft's coin index to ownership lookup.
                delete _LiquidNftToOwnerMap[nft_index];
                // one and done.
                return true;
            }
        }
        return false;
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
     * - `amount` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address"); 

        require(recipient != address(0), "ERC20: transfer to the zero address");
        // good placeto check additional requirements.
        _beforeTokenTransfer(sender, recipient, amount);

        // Do we have the liqudity?
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        // Access control, does the user own the coin or is there an allowence?
        if(sender != _msgSender()){
            // Or do they have an allowance?
            require(_allowancesCoin[sender][_msgSender()] > 0, "Error: Transfer of this NFT from this address isn't allowed.");
            require(_allowancesCoin[sender][_msgSender()] >= amount, "Error: Ammount exceeds allowence.");
        }

        // change the list of NFTs and the balences.
        if(_transferNftsAsLiquid(sender, recipient, amount)){
            // Notify everyone of the transfer.
            emit Transfer(sender, recipient, amount);
        }
        // end
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
     * - `amount` number of ERC20 tokens to create.
     */
    /*function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }*/

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
    /* function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 memory accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    } */

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
     * - `amount` cannot be the zero address.     
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        if(amount > 0){
            _allowancesCoin[owner][spender] = amount;
        }else{
            //If the approval is zero or less, remove the approval.
            delete _allowancesCoin[owner][spender];
        }
        emit Approval(owner, spender, amount);
    }

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
    ) internal {}

    //NFT compatiblity:
    /**
     * @dev See {IERC721-balanceOf}.
     *
     * Requirements:
     *
     * - `account` Find number of NFTs based on the provided account    
     */
    function balanceOfNft(address account) public view virtual returns (uint256) {
        // Both frozen and unfrozen is the NFT collection for this account.
        // Both lists are added together for getNftsByOwner() - this is consistant.
        return _OwnerToLiquidCoinMap[account].length + _OwnerToFrozenNftMap[account].length;
    }

    /**
     * @dev Transfer an unfrozen NFT as an ERC20 coin
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     */    
    function _transferNftsAsLiquid(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool){
      bool retStatus = false;
      uint256 nftCount = _OwnerToLiquidCoinMap[sender].length;
      for(uint256 i = 0; i < nftCount; i++) {
          // Pop off the head of the list:
          if(_OwnerToLiquidCoinMap[sender][0] >= 0) {
              // Always pop liquid off of the head of the list:
              uint256 transitNft = _OwnerToLiquidCoinMap[sender][0];
              // Make sure there is an NFT here.
              if(transitNft >= 0) {
                    // Remove this coin from the sender's wallet.
                    // This is always the first coin in the list so this operation O(1)
                    if(_removeCoin(sender, transitNft)){
                        // Hand this coin to the recipient, simple append and ledger assignment O(1)
                        _addCoin(recipient, transitNft);
                        amount--;
                    }
              }
          }else{
              // Failed to transfer full amount, _OwnerToLiquidCoinMap[] is empty.
              break;
          }      
          // Fractions of NFTs are not allowed 
          if(amount < 1){
              // all coins have been transfered.
              retStatus = true;
              break;
          }
      }
      return retStatus;
    }

    /**
     * @dev change NFT ownership - Warning: Internal, needs access control before it.
     *
     * Requirements:
     *
     * - `oldOwner` The current owner, which will be changed
     * - `newOwner` The new NFT owner
     * - `nft_index` Which NFT to transfer         
     */     
    function _transferNftsFrozen(address oldOwner, address newOwner, uint256 nft_index) internal virtual returns (bool) {
      bool retStatus = false;
      uint256 startBalance = _balances[oldOwner];
      require(newOwner != address(0), "ERC20: Cannot send to the zero address");
      // Always update the ownership map and freeze the NFT as it was treated as one.
      if(_FrozenNftsToOwnerMap[nft_index] == oldOwner){
        // Remove the NFT from the oldOwner's frozen wallet: 
        if(_removeNft(oldOwner, nft_index)){   
            // Add this NFT to the recepiant's wallet.
            if(_addNft(newOwner, nft_index)){
                retStatus = true;
            }
        }
      // The NFT in quesiton might be in liquid from. That's fine, we'll put it on ice for transfer.
      // It needs to be put on ice so someone doesn't accidentally loose a work of art when doing 
      // liquid transactions that overlap with art auctions.
      }else if(_LiquidNftToOwnerMap[nft_index] == oldOwner){
        // Remove a liquid NFT from the oldOwner's wallet:
        if(_removeCoin(oldOwner, nft_index)){
            // This interface always sends NFTs so it must arrive frozen:
            if(_addNft(newOwner, nft_index)){
                retStatus = true;
            }
        }
      }else{
          revert("Error: You do not own this NFT");
      }
      require(startBalance != _balances[oldOwner], "Error:  You must own the NFT.");
      return retStatus;
    }

    /**
     * @dev Approve NFT for transfer by 3rd party
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     * After approval the NFT is frozen.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `nft_index` must be an owned NFT.   
     */
    function _approveNft(
        address spender,
        uint256 nft_index
    ) internal virtual returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address.");
        // Access-Control - Check if this NFT is currently a liquid
        if(_LiquidNftToOwnerMap[nft_index] == _msgSender()){
            // Freeze it so we don't accidentally use it through the erc20 interface.
            freezeNft(nft_index);
            // Create an allow record so that this `spender` can transfer the `nft_index`
            _allowancesNft[_msgSender()][spender].push(nft_index);
            // update the nft to allow map to reflect the allowance map above.
            _NftToAllowMap[nft_index] = spender;
        // Access-Control - Check if is properly forzen
        }else if(_FrozenNftsToOwnerMap[nft_index] == _msgSender()){
            _allowancesNft[_msgSender()][spender].push(nft_index);
            _NftToAllowMap[nft_index] = spender;
        }else{
            revert("Error: You must own the NFT");
        }
        return true;
    } 

    /**
     * @dev Approves the transfer of `nft_index`  by `sender`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `nft_index` cannot be the zero address.
     */
    function approveNft(address spender, uint256 nft_index) public virtual returns (bool) {
        // The interface needs to send a spender, but we must always use _msgSender()
        return _approveNft(spender, nft_index);
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
     * - `nft_index` must be an owned or allowed nft index.
     */
    function _transferNft(
        address sender,
        address recipient,
        uint256 nft_index
    ) internal virtual returns (bool){
        bool retStatus = false;
        // Error case that would destory coins, _burn() is not allowed:
        require(sender != address(0), "ERC721: transfer from the zero address");
        require(recipient != address(0), "ERC721: transfer to the zero address");
        // Access control, does the user own the coin 
        if(sender != _msgSender()){
            // Or do they have an allowance?
            require(_allowancesNft[sender][_msgSender()].length > 0, "Error: Transfer of this NFT from this address isn't allowed.");
            // Make sure this sender isn't hit by OFAC - this is a 2nd call for the allow case.
            _beforeTokenTransfer(sender, recipient, 1);
        } 

        // Make sure this wallet isn't hit by OFAC.
        _beforeTokenTransfer(_msgSender(), recipient, 1);
        // Do the deed.
        if(_transferNftsFrozen(sender, recipient, nft_index)){
            retStatus = true;
        }
        // call the after event hook.
        _afterTokenTransfer(sender, recipient, 1);
        return retStatus;
    }

    /**
     * @dev transferNft
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transferNft(address sender, address recipient, uint256 index) public virtual returns (bool) {
        return _transferNft(sender, recipient, index);
    }

    /**
     * @dev See {IERC721-getApproved} - returns the address who is approved to transfer this NFT.
     *
     * Requirements:
     *
     * - `tokenId` Must be a minted and owned NFT.  
     */
    function getApprovedNft(uint256 tokenId) public view virtual returns (address) {
        //Who is the most recent account to get approval.
         return _NftToAllowMap[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *     
     * Requirements:
     *
     * - `operator` Allows the sender to approve this wallet for transfer of all NFTs. 
     * - `approved` Turn approvals off and on for this operator.   
     */ 
    function setApprovalForAllNfts(address operator, bool approved) public virtual {
        if(approved){
            //  Approve all of the frozen NFTs as well - it does say *ALL*
            uint256 ownerLength = _OwnerToFrozenNftMap[_msgSender()].length;
            for(uint256 i=0; i<ownerLength; i++){
                // Just approve already forzen NFTs, we don't want to freeze every erc20 token with this call.
                _approveNft(operator, _OwnerToFrozenNftMap[_msgSender()][i]);
            }    
            ownerLength = _OwnerToLiquidCoinMap[_msgSender()].length;
            // check both lists to see if the user owns it:
            for(uint256 i=0; i<ownerLength; i++){
                // Just approve already forzen NFTs, we don't want to freeze every erc20 token with this call.
                // This will add them to the freeze list:
                _approveNft(operator, _OwnerToLiquidCoinMap[_msgSender()][i]);
            }  
        }else{
            // Remove ERC721 approvals:
            delete _allowancesNft[_msgSender()][operator];
            // remove ERC20 approvals:
            delete _allowancesCoin[_msgSender()][operator];
            // This method doesn't act on erc20, if you want to remove erc20 and erc721 approvals call removeAllApprovals().
        }
    }

    /**
     * @dev Secuirty feautre - removes all approvals for this account both ERC20 and ERC721.
     * Public method, must be called by an owner.
     *      
     */     
    function removeAllApprovals() public virtual {
        // Remove all NFT approvals for this wallet
        // Get all NFTs frozen by this user:
        uint256 nftList = _OwnerToFrozenNftMap[_msgSender()].length;
        for(uint256 idx=0;idx<nftList;idx++){
            // Remove all allowance for frozen NFTs.
            delete _NftToAllowMap[_OwnerToFrozenNftMap[_msgSender()][idx]];
        }
        // Delete all allowence maps owned by this sender.
        ////todo:delete _allowancesNft[_msgSender()];

        // Remove all ERC20 coin approvals for this wallet
        ////todo:delete _allowancesCoin[_msgSender()];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAllNfts(address owner, address operator) public view virtual returns (bool) {
        // Get the full list of NFTs, both ERC20 and ERC721:
        uint256[] memory nftList = getNftsByOwner(owner);
        // Check if this operator can access the full list:
        return ((_allowancesNft[owner][operator].length + _allowancesCoin[owner][operator]) != nftList.length);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferNftFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual returns (bool){
        return _transferNft(from,to,tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom} - _transferNft is always safe.
     */
    function safeTransferNftFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual returns (bool){
        return _transferNft(from,to,tokenId);
    }

    //end of coin.

    /**
     * @dev Enforce deny list before the funds are transfered. This is enforcement of the OFAC controlls
     */
    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) view internal {
        require(!_denylist[from], 'Flake.art has blocked sender');
        require(!_denylist[to], 'Flake.art has blocked receiver');
    }
    

    /**
     * @dev add addresses to denylist
     */
    function addToDenylist(address[] calldata addrs) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];
            _denylist[addr] = true;
        }

        emit AddedToDenylist(addrs);
        return true;
    }

    /**
     * @dev remove addresses from denylist
     */
    function removeFromDenylist(address[] calldata addrs) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];
            delete _denylist[addr];
        }

        emit RemovedFromDenylist(addrs);
        return true;
    }

    /**
     * @dev Display the maximum that can be minted. 
     */
    function maxSupply() public view virtual returns (uint256) {
        // Show how many can be minted.
        return _maxSupply;
    }

    /**
     * @dev See {IERC20-totalSupply} - number of coins minted.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Only show number minted.
        return _totalSupply;
    }

    /**
     * @dev Allows the owner to designate a new tresury.
     */
    function setTreasury(address treasury) public onlyOwner returns (bool) {
        // Assign a new treasurer as a persistant member of this class contract.
        _treasury = treasury;
        emit UpdatedTreasury(treasury);
        return true;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature


            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    // recover T's public address
    function _getMintSigner(
        address _account, 
        // uint256[] calldata _nft_indexes,
        uint timeStamp,
        bytes memory _signature
    ) public pure returns(address) {
        // Use the treasury as the key.
        return keccak256(abi.encodePacked(_account, timeStamp)).toEthSignedMessageHash().recover(_signature);
    } 

    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /**
     * @dev Assign ownership to a newly created NFT, in a frozen state.
     */
    function mintNft(address _signer,address _recipient, uint256[] calldata nft_indexes,string memory _message, uint _nonce, bytes calldata signature) public returns (bool) {
        // only callable with a signed request.
        require(verify(
            _signer, 
            _recipient,
             5,
            _message,
            _nonce,
            signature), "Error: Mint signature doesn't match");
        // Set unassigned coins to a new owner.
        for (uint256 i = 0; i < nft_indexes.length; i++) {
            // Make sure we are minting annft within the range.
            require(nft_indexes[i] <= _maxSupply, "Error: NFT index too large.");
            // Unsigned cannot be negitive, the smallest is zero.
            // _addNft() can only be used for unowned tokens, this prevents replay attacks because the coin will be owned.            
            if(_addNft(_recipient, nft_indexes[i])){
                // New coin minted, update the total supply.
                _totalSupply+=1;
                // success
                emit MintedNft(_recipient, nft_indexes[i]);
            }

        }
        return true;
    }

    /**
     * @dev Assign ownership to a newly created coin, in a liquid state.
     */
    function mintCoin(address _signer,address _recipient, uint256[] calldata nft_indexes,string memory _message, uint _nonce, bytes calldata signature) public returns (bool) {
        // only callable with a signed request.
         require(verify(
            _signer, 
            _recipient,
             5,
            _message,
            _nonce,
            signature), "Error: Mint signature doesn't match");
        // Set unassigned coins to a new owner.
        for (uint256 i = 0; i < nft_indexes.length; i++) {
            // Make sure we are minting an nft within the range.
            require((nft_indexes[i] <= _maxSupply), "Error: NFT index too large.");
            // Unsigned cannot be negitive, the smallest is zero.
            // _addCoin() can only be used for unowned tokens, this prevents replay attacks because the coin will be owned.
            if(_addCoin(_recipient, nft_indexes[i])){
                // when a unique coin is created, update supply:
                _totalSupply+=1;
                // success
                emit MintedCoin(_recipient, nft_indexes[i]);
            }
        }
        return true;
    }

    /**
     * @dev Some tokens can be created based on demand. However, in.st is fininate accross all networks.
     */
    function mint(uint256 /*amount*/) public view virtual {
      revert("Art Flake has a max supply of one million - mint() disabled see: mintCoin() and mintNft().");
    }

    /**
     * @dev Tokens must not be allowed to be destoryed, if one isn't needed any longer then the owner will take it back.
     */
    function burn(uint256 amount) public payable {
      // tokens cannot be destroyed, they are returned.
      transfer(owner(), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

//import '@openzeppelin/contracts/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
//import "./flakecoin.sol";
/**
 * @dev Implementation of the {IERC20} + Nft Proxy interface.
 *
 * Exposes an ERC20 interface and an ERC721 proxy interface for treating an ERC20
 * coin as an NFT. 
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 */

/**
  * @dev Exposed proxy interface for the NFT.
  */
/*
contract DeployedFlakeCoin {   
    function changeNftOwner(address newOwner, address _nftAddr) public {}
    function lockNft(uint256 nft_index) public view virtual override returns (bool) {}
    function unlockNft(uint256 nft_index) public view virtual override returns (bool) {}
    function balanceOf(address account) public view virtual override returns (uint256) {}
}
*/

contract ERC20NFTAccess is Context, IERC20, IERC20Metadata {
    //using SafeMath for uint256;
    // erc20 token balance 
    mapping(address => uint256) private _balances;

    // erc20 access control
    mapping(address => mapping(address => uint256)) private _allowancesCoin;

    // erc721 access contorl
    mapping(address => mapping(address => uint256[])) private _allowancesNft;

    // NFTs owned by a wallet
    mapping(address => uint256[]) private _OwnerToLiquidCoinMap;

    // NFTs Frozen by a wallet
    mapping(address => uint256[]) private _OwnerToFrozenNftMap;

    // Find the owner of a specific NFT
    mapping(uint256 => address) private _LiquidNftToOwnerMap;

    // Find the allowence of a specific NFT
    mapping(uint256 => address) private _NftToAllowMap;

    // Find the owner of a specific NFT
    mapping(uint256 => address) private _FrozenNftsToOwnerMap;

    // Mapping from token ID to approved address NFT ERC-721
    mapping(uint256 => address) private _tokenApprovals;

    // This is the number minted
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    // custom events
    event FreezeNft(address arbiter, uint256 nft_index);
    event UnfreezeNft(address arbiter, uint256 nft_index);
    // ERC20 Events:
    //event Transfer(address sender, address recipient, uint256 amount);
    //event Approval(address owner, address operator, uint256 amount);

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
     * @dev Must return 0, NFTs cannot be sub-devided.
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
        return 0;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Only show number minted.
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     *      
     * NOTE: Returns the liquid coin blance.    
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        // Return only liquid balance.
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
        return _allowancesCoin[owner][spender];
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
        if(sender != _msgSender()){
            uint256 currentAllowance = _allowancesCoin[_msgSender()][sender];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            // Approval doesn't need to be chcked twice, it is checked above^
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }            
        }
        _transfer(sender, recipient, amount);
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
     * - `addedValue` must be a positive number.   
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(0 < addedValue, "ERC20: must decrease by a postive number");
        _approve(_msgSender(), spender, _allowancesCoin[_msgSender()][spender] + addedValue);
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
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * - `subtractedValue` must be a postive number.  
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowancesCoin[_msgSender()][spender];
        require(0 < subtractedValue, "ERC20: must decrease by a postive number");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Get list of NFTs based on the owner.
     *     
     * Requirements:
     *
     * - `owner` must the address of the owner you want to lookup.   
     */
    function getNftsByOwner(address owner) public view virtual returns (uint256[] memory) {
        uint256 liquidLength = _OwnerToLiquidCoinMap[owner].length;
        uint256 frozenLength = _OwnerToFrozenNftMap[owner].length;
        uint256[] memory ownership = new uint256[](liquidLength + frozenLength);
        // check both lists to see if the user owns it:
        for(uint256 i=0; i < liquidLength; i++){
            ownership[i]=_OwnerToLiquidCoinMap[owner][i];
        }
        for(uint256 i=0; i < frozenLength; i++){
            ownership[i+liquidLength]=_OwnerToFrozenNftMap[owner][i];
        }
        return ownership;
    }

    /**
     * @dev Get the owner address based on the nft index
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.  
     */
    function getOwnerbyNft(uint256 nft_index) public view virtual returns (address) {
        if(isLiquid(nft_index)){
            // Liquid coin
            return _LiquidNftToOwnerMap[nft_index];
        }else if(isFrozen(nft_index)){
            // Frozen as stricly a flake NFT
            return _FrozenNftsToOwnerMap[nft_index];
        }else{
            return address(0);
        }
    }

    /**
     * @dev Gets the NFT status as a liquid or frozen solid.
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.  
     */
    function isFrozen(uint256 nft_index) public view virtual returns (bool) {
        // Find if an NFT cannot be used an ERC20
        return _FrozenNftsToOwnerMap[nft_index] != address(0);
    }

    /**
     * @dev Gets the NFT status as a liquid or frozen solid.
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.  
     */
    function isLiquid(uint256 nft_index) public view virtual returns (bool) {
        // Find if an NFT cannot be used an ERC20
        return _LiquidNftToOwnerMap[nft_index] != address(0);
    }

    /**
     * @dev allow the owner to freeze their NFT so it cannot be used as an ERC20
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to freeze.       
     */
    function freezeNft(uint256 nft_index) public virtual returns (bool) {
         // This is an ERC20 balance change, check OFAC.
         _beforeTokenTransfer(_msgSender(), _msgSender(), 1);
         // Do we this liquidity to spare?
        if(_LiquidNftToOwnerMap[nft_index] == _msgSender()){
            // Remove from the coin ledger:
            if(_removeCoin(_msgSender(), nft_index)){
                // Add to the NFT ledger:
                if(_addNft(_msgSender(), nft_index)){
                    // Tell everybody about this huge success:
                    emit FreezeNft(_msgSender(), nft_index);
                    return true;   
                }             
            }
        }else{
            revert("Error:  You must own the NFT and it cannot be Frozen.");
        }
        return false;
    }

    /**
     * @dev allow the owner to unlock so it can be used as an ERC20
     *     
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function unfreezeNft(uint256 nft_index) public virtual returns (bool) {
        //This is an ERC20 balance change, check OFAC.
        _beforeTokenTransfer(_msgSender(), _msgSender(), 1);
        if(_FrozenNftsToOwnerMap[nft_index] == _msgSender()){
            if(_LiquidNftToOwnerMap[nft_index] == _msgSender()){
                // Remove from the coin ledger:
                if(_removeNft(_msgSender(), nft_index)){
                    // Add to the NFT ledger:
                    if(_addCoin(_msgSender(), nft_index)){
                        // Tell everybody about this huge success:
                        emit UnfreezeNft(_msgSender(), nft_index);
                        return true;                        
                    }
                }
            }else{
                revert("Error: You must own this NFT.");
            }
        }else{
            revert("Error: NFT Must be frozen.");
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out coins, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _addCoin(address owner, uint256 nft_index) internal virtual returns (bool){
        // Make sure this coin isn't owned.
        // This prevents replay attacks - the second message will have no effect.
        if(getOwnerbyNft(nft_index) == address(0)){
            // Add it as liquid to the wallet.
            _OwnerToLiquidCoinMap[owner].push(nft_index);
            // Set owner
            _LiquidNftToOwnerMap[nft_index] = owner;
            // Update liquid balance.
            _balances[owner]+=1;
            return true;
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out tokens, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _addNft(address owner, uint256 nft_index) internal virtual returns (bool){
        // Make sure this coin isn't owned.
        // This prevents replay attacks
        if(getOwnerbyNft(nft_index) == address(0)){
            // Add it as a frozen NFT.
            _OwnerToFrozenNftMap[owner].push(nft_index);
            // set owner
            _FrozenNftsToOwnerMap[nft_index] = owner;
            // The user will have to unfreeze it if they want to use it as an ERC20
            return true;            
        }
        return false;
    }    

    /**
     * @dev allow the owner of the contract to hand out coins, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _removeCoin(address owner, uint256 nft_index) internal virtual returns (bool){
        uint256 nftCount = _OwnerToLiquidCoinMap[owner].length;
        // Check the liquid NFTs first:
        for(uint256 idx=0; idx < nftCount; idx++) {
            // Do we have a balance left?
            if(_balances[owner] < 1){
                // Protective code - prevent int overflow.
                break;
            }
            if(_OwnerToLiquidCoinMap[owner][idx] == nft_index){
                // Update liquid balance.
                _balances[owner] -= 1;                
                // remove from the old user's wallet:
                delete _OwnerToLiquidCoinMap[owner][idx];
                // Delete nft index to ownership lookup.
                delete _LiquidNftToOwnerMap[nft_index];
                // one and done.
                return true;
            }
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out tokens, 
     * this method cannot overide exsiting ownership
     *     
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.          
     * - `nft_index` must the NFT index that you want to lookup.       
     */
    function _removeNft(address owner, uint256 nft_index) internal virtual returns (bool){
        uint256 nftCount = _OwnerToFrozenNftMap[owner].length;
        for(uint256 idx = 0; idx < nftCount; idx++) {
            if (_OwnerToFrozenNftMap[owner][idx] == nft_index){             
                // remove from the old user's wallet:
                delete _OwnerToFrozenNftMap[owner][idx];
                // Delete nft's coin index to ownership lookup.
                delete _LiquidNftToOwnerMap[nft_index];
                // one and done.
                return true;
            }
        }
        return false;
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
     * - `amount` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address"); 

        require(recipient != address(0), "ERC20: transfer to the zero address");
        // good placeto check additional requirements.
        _beforeTokenTransfer(sender, recipient, amount);

        // Do we have the liqudity?
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        // Access control, does the user own the coin or is there an allowence?
        if(sender != _msgSender()){
            // Or do they have an allowance?
            require(_allowancesCoin[sender][_msgSender()] > 0, "Error: Transfer of this NFT from this address isn't allowed.");
            require(_allowancesCoin[sender][_msgSender()] >= amount, "Error: Ammount exceeds allowence.");
        }

        // change the list of NFTs and the balences.
        if(_transferNftsAsLiquid(sender, recipient, amount)){
            // Notify everyone of the transfer.
            emit Transfer(sender, recipient, amount);
        }
        // end
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
     * - `amount` number of ERC20 tokens to create.
     */
    /*function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }*/

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
    /* function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 memory accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    } */

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
     * - `amount` cannot be the zero address.     
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        if(amount > 0){
            _allowancesCoin[owner][spender] = amount;
        }else{
            //If the approval is zero or less, remove the approval.
            delete _allowancesCoin[owner][spender];
        }
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

    //NFT compatiblity:
    /**
     * @dev See {IERC721-balanceOf}.
     *
     * Requirements:
     *
     * - `account` Find number of NFTs based on the provided account    
     */
    function balanceOfNft(address account) public view virtual returns (uint256) {
        // Both frozen and unfrozen is the NFT collection for this account.
        // Both lists are added together for getNftsByOwner() - this is consistant.
        return _OwnerToLiquidCoinMap[account].length + _OwnerToFrozenNftMap[account].length;
    }

    /**
     * @dev Transfer an unfrozen NFT as an ERC20 coin
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     */    
    function _transferNftsAsLiquid(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool){
      bool retStatus = false;
      uint256 nftCount = _OwnerToLiquidCoinMap[sender].length;
      for(uint256 i = 0; i < nftCount; i++) {
          // Pop off the head of the list:
          if(_OwnerToLiquidCoinMap[sender][0] >= 0) {
              // Always pop liquid off of the head of the list:
              uint256 transitNft = _OwnerToLiquidCoinMap[sender][0];
              // Make sure there is an NFT here.
              if(transitNft >= 0) {
                    // Remove this coin from the sender's wallet.
                    // This is always the first coin in the list so this operation O(1)
                    if(_removeCoin(sender, transitNft)){
                        // Hand this coin to the recipient, simple append and ledger assignment O(1)
                        _addCoin(recipient, transitNft);
                        amount--;
                    }
              }
          }else{
              // Failed to transfer full amount, _OwnerToLiquidCoinMap[] is empty.
              break;
          }      
          // Fractions of NFTs are not allowed 
          if(amount < 1){
              // all coins have been transfered.
              retStatus = true;
              break;
          }
      }
      return retStatus;
    }

    /**
     * @dev change NFT ownership - Warning: Internal, needs access control before it.
     *
     * Requirements:
     *
     * - `oldOwner` The current owner, which will be changed
     * - `newOwner` The new NFT owner
     * - `nft_index` Which NFT to transfer         
     */     
    function _transferNftsFrozen(address oldOwner, address newOwner, uint256 nft_index) internal virtual returns (bool) {
      bool retStatus = false;
      uint256 startBalance = _balances[oldOwner];
      require(newOwner != address(0), "ERC20: Cannot send to the zero address");
      // Always update the ownership map and freeze the NFT as it was treated as one.
      if(_FrozenNftsToOwnerMap[nft_index] == oldOwner){
        // Remove the NFT from the oldOwner's frozen wallet: 
        if(_removeNft(oldOwner, nft_index)){   
            // Add this NFT to the recepiant's wallet.
            if(_addNft(newOwner, nft_index)){
                retStatus = true;
            }
        }
      // The NFT in quesiton might be in liquid from. That's fine, we'll put it on ice for transfer.
      // It needs to be put on ice so someone doesn't accidentally loose a work of art when doing 
      // liquid transactions that overlap with art auctions.
      }else if(_LiquidNftToOwnerMap[nft_index] == oldOwner){
        // Remove a liquid NFT from the oldOwner's wallet:
        if(_removeCoin(oldOwner, nft_index)){
            // This interface always sends NFTs so it must arrive frozen:
            if(_addNft(newOwner, nft_index)){
                retStatus = true;
            }
        }
      }else{
          revert("Error: You do not own this NFT");
      }
      require(startBalance != _balances[oldOwner], "Error:  You must own the NFT.");
      return retStatus;
    }

    /**
     * @dev Approve NFT for transfer by 3rd party
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     * After approval the NFT is frozen.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `nft_index` must be an owned NFT.   
     */
    function _approveNft(
        address spender,
        uint256 nft_index
    ) internal virtual returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address.");
        // Access-Control - Check if this NFT is currently a liquid
        if(_LiquidNftToOwnerMap[nft_index] == _msgSender()){
            // Freeze it so we don't accidentally use it through the erc20 interface.
            freezeNft(nft_index);
            // Create an allow record so that this `spender` can transfer the `nft_index`
            _allowancesNft[_msgSender()][spender].push(nft_index);
            // update the nft to allow map to reflect the allowance map above.
            _NftToAllowMap[nft_index] = spender;
        // Access-Control - Check if is properly forzen
        }else if(_FrozenNftsToOwnerMap[nft_index] == _msgSender()){
            _allowancesNft[_msgSender()][spender].push(nft_index);
            _NftToAllowMap[nft_index] = spender;
        }else{
            revert("Error: You must own the NFT");
        }
        return true;
    } 

    /**
     * @dev Approves the transfer of `nft_index`  by `sender`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `nft_index` cannot be the zero address.
     */
    function approveNft(address spender, uint256 nft_index) public virtual returns (bool) {
        // The interface needs to send a spender, but we must always use _msgSender()
        return _approveNft(spender, nft_index);
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
     * - `nft_index` must be an owned or allowed nft index.
     */
    function _transferNft(
        address sender,
        address recipient,
        uint256 nft_index
    ) internal virtual returns (bool){
        bool retStatus = false;
        // Error case that would destory coins, _burn() is not allowed:
        require(sender != address(0), "ERC721: transfer from the zero address");
        require(recipient != address(0), "ERC721: transfer to the zero address");
        // Access control, does the user own the coin 
        if(sender != _msgSender()){
            // Or do they have an allowance?
            require(_allowancesNft[sender][_msgSender()].length > 0, "Error: Transfer of this NFT from this address isn't allowed.");
            // Make sure this sender isn't hit by OFAC - this is a 2nd call for the allow case.
            _beforeTokenTransfer(sender, recipient, 1);
        } 

        // Make sure this wallet isn't hit by OFAC.
        _beforeTokenTransfer(_msgSender(), recipient, 1);
        // Do the deed.
        if(_transferNftsFrozen(sender, recipient, nft_index)){
            retStatus = true;
        }
        // call the after event hook.
        _afterTokenTransfer(sender, recipient, 1);
        return retStatus;
    }

    /**
     * @dev transferNft
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transferNft(address sender, address recipient, uint256 index) public virtual returns (bool) {
        return _transferNft(sender, recipient, index);
    }

    /**
     * @dev See {IERC721-getApproved} - returns the address who is approved to transfer this NFT.
     *
     * Requirements:
     *
     * - `tokenId` Must be a minted and owned NFT.  
     */
    function getApprovedNft(uint256 tokenId) public view virtual returns (address) {
        //Who is the most recent account to get approval.
         return _NftToAllowMap[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *     
     * Requirements:
     *
     * - `operator` Allows the sender to approve this wallet for transfer of all NFTs. 
     * - `approved` Turn approvals off and on for this operator.   
     */ 
    function setApprovalForAllNfts(address operator, bool approved) public virtual {
        if(approved){
            //  Approve all of the frozen NFTs as well - it does say *ALL*
            uint256 ownerLength = _OwnerToFrozenNftMap[_msgSender()].length;
            for(uint256 i=0; i<ownerLength; i++){
                // Just approve already forzen NFTs, we don't want to freeze every erc20 token with this call.
                _approveNft(operator, _OwnerToFrozenNftMap[_msgSender()][i]);
            }    
            ownerLength = _OwnerToLiquidCoinMap[_msgSender()].length;
            // check both lists to see if the user owns it:
            for(uint256 i=0; i<ownerLength; i++){
                // Just approve already forzen NFTs, we don't want to freeze every erc20 token with this call.
                // This will add them to the freeze list:
                _approveNft(operator, _OwnerToLiquidCoinMap[_msgSender()][i]);
            }  
        }else{
            // Remove ERC721 approvals:
            delete _allowancesNft[_msgSender()][operator];
            // remove ERC20 approvals:
            delete _allowancesCoin[_msgSender()][operator];
            // This method doesn't act on erc20, if you want to remove erc20 and erc721 approvals call removeAllApprovals().
        }
    }

    /**
     * @dev Secuirty feautre - removes all approvals for this account both ERC20 and ERC721.
     * Public method, must be called by an owner.
     *      
     */     
    function removeAllApprovals() public virtual {
        // Remove all NFT approvals for this wallet
        // Get all NFTs frozen by this user:
        uint256 nftList = _OwnerToFrozenNftMap[_msgSender()].length;
        for(uint256 idx=0;idx<nftList;idx++){
            // Remove all allowance for frozen NFTs.
            delete _NftToAllowMap[_OwnerToFrozenNftMap[_msgSender()][idx]];
        }
        // Delete all allowence maps owned by this sender.
        ////todo:delete _allowancesNft[_msgSender()];

        // Remove all ERC20 coin approvals for this wallet
        ////todo:delete _allowancesCoin[_msgSender()];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAllNfts(address owner, address operator) public view virtual returns (bool) {
        // Get the full list of NFTs, both ERC20 and ERC721:
        uint256[] memory nftList = getNftsByOwner(owner);
        // Check if this operator can access the full list:
        return ((_allowancesNft[owner][operator].length + _allowancesCoin[owner][operator]) != nftList.length);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferNftFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual returns (bool){
        return _transferNft(from,to,tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom} - _transferNft is always safe.
     */
    function safeTransferNftFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual returns (bool){
        return _transferNft(from,to,tokenId);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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