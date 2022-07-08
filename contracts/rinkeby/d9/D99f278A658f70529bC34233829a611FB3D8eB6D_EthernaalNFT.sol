// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title NFT
 */
// contract Erc1155Token is ERC1155Upgradeable {
contract Erc1155Token is ERC1155 {
    using SafeMath for uint256;


    address payable public _owner;
    address[] _emitters;

    struct AssetData {
        uint index;
        address creator;
        string company;
        string assetName;
        string assetSymbol;
        string metadataUrl;
        uint creatorFee; // in percentage (1% = 100)
    }

    mapping(uint => AssetData) public assets;
    uint[] public tokenList;
    mapping(address => uint[]) _assetIndexes;
    mapping(address => int) _investorBalances;
    address[] public _tokenOwners;
    using Counters for Counters.Counter;
    Counters.Counter private maxTokenId;
    mapping(uint256 => mapping(address => uint256)) private salePrice;

    // fee for company (1% = 100)
    uint public orgFee = 100;
    uint public fixedOrgFee = 2e15;

    mapping(uint => AssetData) public lazyAssets;
    //lazyTokenId => amount
    mapping(uint => uint) public lazyBalances;
    Counters.Counter private lazyId;
    mapping(uint256 => uint256) private lazyPrice;

    event NewToken(address tokenOwner, uint tokenId, string tokenUri, uint amount);
    event LazyToken(address creator, uint lazyTokenId, string tokenUri, uint amount);
    event Burned(address tokenOwner, uint tokenId, string tokenUri);

    modifier onlyOwner() {
        require(
            _msgSender() == _owner,
            "only owner can call this function"
        );
        _;
    }

    modifier onlyOwnerOrEmitters() {
        address sender = _msgSender();
        bool doesListContainElement = false;
        for (uint i=0; i < _emitters.length; i++) {
            if (sender == _emitters[i]) {
                doesListContainElement = true;
            }
        }
        require(doesListContainElement ||
            _msgSender() == _owner,
            "only owner or emitters can execute this function"
        );
        _;
    }
    
    modifier onlyHodlerOf(address _hodler, uint256 _tokenId) {
        require(balanceOf(_hodler, _tokenId) > 0, "given wallet does not own this token");
        _;
    }
    
    modifier onlyCreatorOf(address _creator, uint256 _lazyTokenId) {
        require(lazyAssets[_lazyTokenId].creator == _creator, "given wallet is not the creator of this token");
        _;
    }

    modifier onlyOwnerOrEmittersOrHodler(address hodler) {
        address sender = _msgSender();
        bool doesListContainElement = false;
        for (uint i=0; i < _emitters.length; i++) {
            if (sender == _emitters[i]) {
                doesListContainElement = true;
            }
        }
        require(hodler == sender || doesListContainElement ||
            _msgSender() == _owner,
            "Only hodler, owner or emitters can execute this function"
        );
        _;
    }

    constructor(string memory _url) ERC1155(_url) {
        _owner = payable(_msgSender());
        // _baseUri = _url;
    }

    // function initializeNFT(string memory _url)
    //     public
    //     initializer
    // {
    //     _owner = payable(_msgSender());
    //     if(bytes(_url).length > 0 && bytes(_url) != bytes("")) {
    //         _baseUri = _url;
    //     }
    //     __ERC1155_init(_baseUri);
    // }
    
    // function _msgSender() internal view virtual returns (address) {
    //     return msg.sender;
    // }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = payable(newOwner);
    }

    function getOwner() public view onlyOwnerOrEmitters returns (address) {
        return _owner;
    }

    function getEmitters() public view onlyOwnerOrEmitters returns (address[] memory) {
        return _emitters;
    }

    function setOrgFee(uint _fixedOrgFee, uint _fee) external onlyOwner {
        require(_fee < 10000, "fee must be less than 100% (1% = 100)");
        orgFee = _fee;
        fixedOrgFee = _fixedOrgFee;
    }

    function addEmitter(address newEmitter) public onlyOwner {
        _emitters.push(newEmitter);
    }

    fallback() external payable{ }
    receive() external payable {}


    function getBalance() public view onlyOwnerOrEmitters returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No hay nada que retirar");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return assets[tokenId].metadataUrl;
    }

    function mintByEmitters(
        address _to,
        string memory company,
        string memory assetName,
        string memory assetSymbol,
        string memory metadataUrl,
        uint creatorFee,
        uint amount
    ) public onlyOwnerOrEmitters {
        uint lazyTokenId = _setAssetData(
            _msgSender(),
            company,
            assetName,
            assetSymbol,
            metadataUrl,
            creatorFee,
            amount
        );
        _finishMinting(_to, lazyTokenId, amount);
    }

    function startLazyMint(
        string memory company,
        string memory assetName,
        string memory assetSymbol,
        string memory metadataUrl,
        uint creatorFee,
        uint amount) payable external{
        require(msg.value >= fixedOrgFee, "You must cover fixed fee");
        _setAssetData(
            _msgSender(),
            company,
            assetName,
            assetSymbol,
            metadataUrl,
            creatorFee,
            amount
        );
    }

    function buyLazyToken(
        uint _lazyTokenId,
        uint amount) payable external{
        require(amount > 0, "You must buy at least 1 token");
        require(lazyAssets[_lazyTokenId].creator != address(0), "assets not found");
        require(lazyBalances[_lazyTokenId] >= amount, "not enough tokens");
        require(lazyPrice[_lazyTokenId] > 0, "price not set yet");
        uint totalPrice = amount * lazyPrice[_lazyTokenId];
        require(msg.value >= totalPrice, "insufficient funds to buy");
        console.log("totalPrice %s", totalPrice);
        uint fees = totalPrice * orgFee / 10000;
        console.log("orgFee %s", orgFee);
        console.log("fees %s", fees);
        uint earnings = totalPrice - fees;
        _finishMinting(_msgSender(), _lazyTokenId, amount);
        payable(lazyAssets[_lazyTokenId].creator).transfer(earnings);
    }

    function _setAssetData(
        address creator,
        string memory company,
        string memory assetName,
        string memory assetSymbol,
        string memory metadataUrl,
        uint creatorFee,
        uint amount
    ) internal returns (uint256) {
        // require(creatorFee > 0, "creator fee must be greater than 0");
        lazyId.increment();
        uint256 tokenId = lazyId.current();

        AssetData memory entry = assets[tokenId];
        console.log("entry %s", entry.creator);
        require(entry.creator == address(0), "token already created");
        entry = AssetData(tokenId, creator, company,
            assetName, assetSymbol, metadataUrl, creatorFee);
        lazyAssets[entry.index] = entry;
        lazyBalances[entry.index] = amount;
        emit LazyToken(creator, tokenId, metadataUrl, amount);
        return tokenId;
    }

    function _finishMinting(
        address _to,
        uint lazyTokenId,
        uint amount
    ) internal {
        maxTokenId.increment();
        AssetData memory prefilled = lazyAssets[lazyTokenId];
        require(prefilled.creator != address(0), "lazy asset doesn't exist");
        require(lazyBalances[prefilled.index] >= amount, "not enough amount");
        uint tokenId = maxTokenId.current();
        lazyBalances[prefilled.index] -= amount;

        if(_investorBalances[_to] > 0){
            _assetIndexes[_to].push(tokenId);
        } else {
            _assetIndexes[_to] = [tokenId];
            _investorBalances[_to] = int(amount);
            _tokenOwners.push(_to);
        }

        prefilled.index = tokenId;
        bool exist = false;
        for(uint i = 0; i < tokenList.length; i++){
            if(tokenList[i] == prefilled.index){
                exist = true;
                break;
            }
        }
        if(!exist){
            tokenList.push(prefilled.index);
        }
        // shareholdings[entry.index] = entry;
        assets[prefilled.index] = prefilled;

        _mint(_to, tokenId, amount, bytes(""));
        emit NewToken(_to, tokenId, prefilled.metadataUrl, amount);
    }

    function burn(uint _tokenId, uint amount) public {
        require(
            balanceOf(_msgSender(), _tokenId) > 0,
            "Only token owner can burn this token"
        );
        string memory tokenUri = uri(_tokenId);
        _burn(_msgSender(), _tokenId, amount);

        AssetData storage entry = assets[_tokenId];
        if(entry.creator != address(0)){
            // Move last element of array into the vacated key slot.
            uint entryIndex = entry.index;
            uint lastItemIndex = tokenList.length - 1;
            assets[tokenList[lastItemIndex]].index = entryIndex;
            tokenList[entryIndex] = tokenList[lastItemIndex];
            delete tokenList[lastItemIndex];
            delete assets[_tokenId];
        }
        _updateBalances(_msgSender(), _tokenId, amount);
        emit Burned(_msgSender(), _tokenId, tokenUri);
    }

    function _updateBalances(address _tokenOwner, uint _tokenId, uint amount) internal{
        if(_investorBalances[_tokenOwner] > 0){
            _investorBalances[_tokenOwner] = int(_investorBalances[_tokenOwner]) - int(amount);
            if(_investorBalances[_tokenOwner] < 0){
                _investorBalances[_tokenOwner] = 0;
            }
            uint assetsCount = _assetIndexes[_tokenOwner].length;
            for(uint i = 0; i < assetsCount; i++){
                if(_assetIndexes[_tokenOwner][i] == _tokenId){
                    uint currentBalance = balanceOf(_tokenOwner, _tokenId);
                    if(currentBalance == 0){
                        _assetIndexes[_tokenOwner][i] = _assetIndexes[_tokenOwner][assetsCount - 1];
                        delete _assetIndexes[_tokenOwner][assetsCount - 1];
                        break;
                    }
                }
            }
            assetsCount = _assetIndexes[_tokenOwner].length;
            if(assetsCount < 1){
                delete _assetIndexes[_tokenOwner];
                _investorBalances[_tokenOwner] = 0;
                uint ownersCount = _tokenOwners.length;
                for(uint i = 0; i < ownersCount; i++){
                    if(_tokenOwners[i] == _tokenOwner){
                        _tokenOwners[i] = _tokenOwners[ownersCount - 1];
                        delete _tokenOwners[ownersCount - 1];
                    }
                }
                if(ownersCount <= 1){
                    delete _tokenOwners;
                }
            }
        }
    }

    // function getFullURI(uint tokenId) public view virtual returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     string memory baseURI = _baseURI();
    //     return string(abi.encodePacked(baseURI, assets[tokenId].company, "/", shareholdings[tokenId].assetName, "/", tokenId));
    // }

    function getHodlers() public view onlyOwnerOrEmitters returns (address[] memory) {
        return _tokenOwners;
    }

    function getBalanceOf(address hodler) public view onlyOwnerOrEmittersOrHodler(hodler) returns (int) {
        return _investorBalances[hodler];
    }

    function getAssetIndexesOf(address hodler) public view onlyOwnerOrEmittersOrHodler(hodler) returns (uint[] memory) {
        return _assetIndexes[hodler];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
        _updateBalances(_msgSender(), id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(ids.length == amounts.length, "ERC1155: ids and amounts must be of the same length");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for(uint i = 0; i < ids.length; i++){
            _updateBalances(_msgSender(), ids[i], amounts[i]);
        }
    }

    function totalLazySupply() public view virtual returns (uint256) {
        return lazyId.current();
    }

    function totalSupply() public view virtual returns (uint256) {
        return maxTokenId.current();
    }

    function setLazyPrice(uint256 _tokenId, uint256 price) public onlyCreatorOf(_msgSender(), _tokenId) {
        require(price > 0, "Price must be greater than 0");
        lazyPrice[_tokenId] = price;
    }

    function updatePrice(uint256 _tokenId, uint256 price) public onlyHodlerOf(_msgSender(), _tokenId) {
        require(price > 0, "Price must be greater than 0");
        require(balanceOf(_msgSender(), _tokenId) > 0, "You can't update price of token that you don't own");
        salePrice[_tokenId][_msgSender()] = price;
    }

    function getLazyPrice(uint256 _tokenId) public view returns (uint256) {
        return lazyPrice[_tokenId];
    }

    function getSalePrice(uint256 _tokenId, address hodler) public view returns (uint256) {
        return salePrice[_tokenId][hodler];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**  
* @title An NFT Marketplace contract for Ethernaal NF2Ts - Non Fungible Tattoo Tokens
* @author Gnana Lakshmi T C
* @notice This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
* @dev Most function calls are currently implemented with access control
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/* 
* This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
*/
contract EthernaalNF2T is ERC721URIStorage {

    using SafeMath for uint256;
    mapping(uint256 => uint256) private salePrice;
    mapping(address => bool) public creatorWhitelist;
    mapping(uint256 => address) private tokenOwner;
    mapping(uint256 => address) private tokenCreator;
    mapping(address => uint[]) private creatorTokens;
    mapping(uint => bool) private tattooRedeemed;
    //This is to determine the platform royalty for the first sale made by the creator
    mapping(uint => bool) private tokenFirstSale;
    mapping(address => bool) whitelistPartnerMapping;

    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event WhitelistCreator(address indexed _creator);
    event DelistCreator(address indexed _creator);
    event OwnershipGranted(address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Mint(address indexed creator,uint indexed tokenId, string indexed tokenURI);

    uint constant FLOAT_HANDLER_TEN_4 = 10000;

    address owner;
    address _grantedOwner;
    address admin;
    address blackUni_org;
    uint256 sellerFee;
    uint256 orgFee;
    uint256 creatorFee;
    uint256 blackUniFee;
    uint256 sellerFeeInitial;
    uint256 orgFeeInitial;
    uint256 blackUniFeeInital;
    address payable ethernaal_org;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTData {
        uint tokenId;
        string title;
        string description;
        string artistName;
        address creator;
    }

    NFTData[] mintedNfts;

    /**
    * Modifier to allow only minters to mint
    */
    modifier onlyMinter() virtual {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

    /**
    * Modifier to allow only owners of a token to perform certain actions 
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * Modifier to allow only owner of the contract to perform certain actions 
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
    * Modifier to allow only admin of the organization to perform certain actions 
    */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /**
    * Modifier to allow only registered partner or owner to perform certaiin actions
    */
    modifier onlyPartnerOrOwner() {
        require(msg.sender == owner || whitelistPartnerMapping[msg.sender] == true, "Only partner or ownercan call this function");
        _;
    }

    constructor(string memory _name, 
        string memory _symbol,
        address payable org,
        address payable blackUnicornOrg,
        address payable _admin
        )
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
        admin = _admin;
        ethernaal_org = org;
        blackUni_org = blackUnicornOrg;
        //Royalty Fee is fixed to be 1% of sales, org fee to be 1% and black unicorn to 0.5%
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 100;
        creatorFee = 100;
        blackUniFee = 50;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        // Fees for first sale only
        orgFeeInitial = 200;
        blackUniFeeInital = 50;
        sellerFeeInitial = 10000-orgFeeInitial-blackUniFeeInital;
    }

    /**
    * @dev Owner can transfer the ownership of the contract to a new account (`_grantedOwner`).
    * Can only be called by the current owner.
    */
    function grantContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipGranted(newOwner);
        _grantedOwner = newOwner;
    }
    
    /**
    * @dev Claims granted ownership of the contract for a new account (`_grantedOwner`).
    * Can only be called by the currently granted owner.
    */
    function claimContractOwnership() public virtual {
        require(_grantedOwner == msg.sender, "Ownable: caller is not the granted owner");
        emit OwnershipTransferred(owner, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /**
    * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeOrgAddress(address _newOrg) public onlyOwner {
        require(_newOrg != address(0), "New organization cannot be zero address");
        ethernaal_org = payable(_newOrg);
    }

    /**
    * @dev Black Unicorn organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeBlackUniAddress(address _blakcUniOrg) public onlyOwner {
        require(_blakcUniOrg != address(0), "New organization cannot be zero address");
        blackUni_org = payable(_blakcUniOrg);
    }

    /**
    * @dev This function is used to get the seller percentage. 
    * This refers to the amount of money that would be distributed to the seller 
    * after the reduction of royalty and platform fees.
    * The values are multipleied by 100, in order to work easily 
    * with floating point percentages.
    */
    function getSellerFee() public view returns (uint256) {
        //Returning % multiplied by 100 to keep it uniform across contract
        return sellerFee;
    }


     /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist.
    * Each of the organisation, creator royalty and the parent organsation fees
    * are set in this function.
    * The 'sellerFee' indicates the final amount to be sent to the seller.
    */
    function setRoyaltyPercentage(uint256 _orgFee, uint _creatorFee, uint _blackUnicornFee) public onlyOwner returns (bool) {
        //Sum of org fee and creator fee should be 100%
        require(10000 > _orgFee+_creatorFee+_blackUnicornFee, "Sum of creator fee and org fee should be 100%");
        orgFee = _orgFee;
        creatorFee = _creatorFee;
        blackUniFee = _blackUnicornFee;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        return true; 
    }

    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist(who would be the seller) on the first sale.
    * The first iteration of whitepaper has the following stats:
    * orgFee = 2%
    * blackUnicornFee = 0.5%
    * artist royalty/creator fee = 0%
    * The above numbers can be updated later by the DAO
    * @notice _creatorFeeInitial should be sellerFeeInitial - seller fees on first sale
    */
    function setRoyaltyPercentageFirstSale(uint256 _orgFeeInitial, uint _creatorFeeInitial, uint _blackUnicornFeeInitial) public onlyOwner returns (bool) {
        orgFeeInitial = _orgFeeInitial;
        sellerFeeInitial = _creatorFeeInitial;
        _blackUnicornFeeInitial = _blackUnicornFeeInitial;
        return true;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
    * orgFee - % of fees that would go to the org from the total royalty
    * blackUniFee - % of fees for Black Unicorn
    * creatorRoyalty - % of fees that would go to the artist/creator
    * orgInitialRoyalty - % of fees that would go to the organisation on first sale
    * sellerFeeInitial - % of fees for seller on the first sale
    * blackUniFeeInitial - % of fees that would go to Black Unicorn on first sale
    */
    function getRoyalties() public view returns (uint _orgFee, uint _blackUniFee, uint256 _creatorRoyalty, 
    uint256 _orgInitialRoyalty, uint256 _sellerFeeInitial, uint _blakcUniFeeInitial) {
        
        return (orgFee, creatorFee, blackUniFee, orgFeeInitial, sellerFeeInitial, blackUniFeeInital);
    }

    /**
    * This function is used to set the price of a token
    * @notice Only admin is allowed to set the price of a token
    */
    function setPrice(uint256 tokenId, uint256 price) public onlyAdmin {
        salePrice[tokenId] = price;
    }

    /**
    * This function is used to change the price of a token
    * @notice Only token owner is allowed to change the price of a token
    */
    function changePrice(uint256 _tokenId, uint256 price) public onlyOwnerOf(_tokenId) {
        require(price > 0, "changePrice: Price cannot be changed to less than 0");
        salePrice[_tokenId] = price;
    }

    /**
    * This function is used to check if it is the first sale of a token
    * on the Ethernaal marketplace.
    */
    function isTokenFirstSale(uint tokenId) external view returns(bool){
        return tokenFirstSale[tokenId];
    }

    /**
    * This function is used to mint an NFT for the Ethernaal marketplace.
    * @dev The basic information related to the NFT needs to be passeed to this function,
    * in order to store it on chain to avoid disputes in future.
    */
    function mintWithIndex(address _creator, string memory _tokenURI, string memory title,
    string memory description, string memory artistName) public virtual onlyMinter returns (uint256 _tokenId) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenOwner[tokenId] = _creator;

       
        _mint(_creator, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        tokenCreator[tokenId] = _creator;
        
        NFTData memory nftNew = NFTData(tokenId, title, description, artistName, _creator);
        mintedNfts.push(nftNew);
        
        creatorTokens[_creator].push(tokenId);
        emit Mint(_creator,tokenId, _tokenURI);
        return tokenId;
    }
    
    /**
    * This function is used to set an NFT on sale. 
    * @dev The sale price set in this function will be used to perform the sale transaction
    * once the buyer wants to buy an NFT.
    */
    function setSale(uint256 _tokenId, uint256 price) public virtual onlyOwnerOf(_tokenId) {
        address tOwner = ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        salePrice[_tokenId] = price;
        emit SalePriceSet(_tokenId, price);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSale(uint256 tokenId, address _nftAddress)
        public
        payable
    {
        ERC721 nftAddress = ERC721(_nftAddress);

        uint256 price = salePrice[tokenId];
        uint256 sellerFees = getSellerFee();
        uint256 creatorRoyalty = creatorFee;
        uint256 platformFees = orgFee;
        uint256 blackUnicornFee = blackUniFee;

        require(price != 0, "buyToken: price equals 0");
        require(
            msg.value == price,
            "buyToken: price doesn't equal salePrice[tokenId]"
        );
        address tOwner = nftAddress.ownerOf(tokenId);

        nftAddress.safeTransferFrom(tOwner, msg.sender, tokenId);
        salePrice[tokenId] = 0;

        if(tokenFirstSale[tokenId] == false) {
            /* Platform takes 2.5% on each artist's first sale
            *  All values are multiplied by 100 to deal with floating points
            */
            platformFees = orgFeeInitial;
            sellerFees = sellerFeeInitial;
            blackUnicornFee = blackUniFeeInital;
            //No creator royalty/royalties when artist is minting for the first time
            creatorRoyalty = 0;

            tokenFirstSale[tokenId] = true;
        }   
        
        //Dividing by 100*100 as all values are multiplied by 100
        //
        uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toCreator = (msg.value*creatorRoyalty) / FLOAT_HANDLER_TEN_4;
        uint256 toPlatform = (msg.value*platformFees) / FLOAT_HANDLER_TEN_4;
        uint256 toBlackUnicorn = (msg.value*blackUnicornFee) / FLOAT_HANDLER_TEN_4;
        
        address tokenCreatorAddress = tokenCreator[tokenId];
        
        payable(tOwner).transfer(toSeller);
        if(toCreator != 0) {
            payable(tokenCreatorAddress).transfer(toCreator);
        }
        
        ethernaal_org.transfer(toPlatform);
        payable(blackUni_org).transfer(toBlackUnicorn);
        
        emit Sold(msg.sender, tOwner, msg.value,tokenId);
    }

    /** @dev The redeemable status of the tattoo will be set by 
    * the partner or owner based on some conditions
    */
    function setTattooRedeemable(uint tokenId) public view onlyPartnerOrOwner {
        require(tattooRedeemed[tokenId] == false, "Tattoo has been previously redeemed");
        tattooRedeemed[tokenId] == true;
    }

    /**
    * This function is used to return all the tokens created by a specific creator
    */
    function tokenCreators(address _creator) external view onlyOwner returns(uint[] memory) {
            return creatorTokens[_creator];
    }

    /**
    * This function is used to whitelist a creator/ an artist on the platform
    */
    function whitelistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if(creatorWhitelist[_creators[i]]){
                //Do nothing if address is already whitelisted
            }
            else {
                creatorWhitelist[_creators[i]] = true;
                emit WhitelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This function is used to unlist/delist a creator from the platform
    */
    function delistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if (creatorWhitelist[_creators[i]] == true){
                creatorWhitelist[_creators[i]] = false;
                emit DelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This function is used to whitelist a tattoo partner on the platform
    */
    function whitelistPartners(address _partner) public onlyOwner returns(bool) {
        require(_partner != address(0), "Partner address has to be non-zero");
        whitelistPartnerMapping[_partner] = true;
        return whitelistPartnerMapping[_partner];
    }

    /**
    * This function is used to delist a tattoo partner on the platform
    */
    function delistPartners(address partner) public onlyOwner returns(bool){
        require(partner != address(0), "Partner address has to be non-zero");
        require(whitelistPartnerMapping[partner] = true, "Partner is not whitelisted");
        whitelistPartnerMapping[partner] = false;
        return whitelistPartnerMapping[partner];
    }

    /**
    * This is a getter function to get the current price of an NFT.
    */
    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return salePrice[tokenId];
    }

     /**
    * This function returns if a creator is whitelisted on the platform or no
    */
    function isWhitelisted(address _creator) external view returns (bool) {
        return creatorWhitelist[_creator];
    }

    /**
    * This returns the total number of NFTs minted on the platform
    */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
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
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

/**  
* @title An NFT Marketplace contract for Ethernaal Flash NFTs
* @author Gnana Lakshmi T C
* @notice This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
* @dev Most function calls are currently implemented with access control
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
* This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
*/
contract EthernaalFlaNFT is ERC721URIStorage {

    using SafeMath for uint256;
    mapping(uint256 => uint256) private salePrice;
    mapping(address => bool) public creatorWhitelist;
    mapping(uint256 => address) private tokenOwner;
    mapping(uint256 => address) private tokenCreator;
    mapping(address => uint[]) private creatorTokens;
    //This is to determine the platform royalty for the first sale made by the creator
    mapping(uint => bool) private tokenFirstSale;

    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event WhitelistCreator(address indexed _creator);
    event DelistCreator(address indexed _creator);
    event OwnershipGranted(address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Mint(address indexed creator,uint indexed tokenId, string indexed tokenURI);

    uint constant FLOAT_HANDLER_TEN_4 = 10000;

    address owner;
    address _grantedOwner;
    address admin;
    address blackUni_org;
    uint256 sellerFee;
    uint256 orgFee;
    uint256 creatorFee;
    uint256 blackUniFee;
    uint256 sellerFeeInitial;
    uint256 orgFeeInitial;
    uint256 blackUniFeeInital;
    address payable ethernaal_org;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTData {
        uint tokenId;
        string title;
        string description;
        string artistName;
        address creator;
    }

    NFTData[] mintedNfts;

    /**
    * Modifier to allow only minters to mint
    */
    modifier onlyMinter() virtual {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

    /**
    * Modifier to allow only owners of a token to perform certain actions 
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * Modifier to allow only owner of the contract to perform certain actions 
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
    * Modifier to allow only admin of the organization to perform certain actions 
    */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(string memory _name,
        string memory _symbol,
        address payable org,
        address payable blackUnicornOrg,
        address payable _admin
        )
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
        admin = _admin;
        ethernaal_org = org;
        blackUni_org = blackUnicornOrg;
        //Creator royalty Fee is fixed to be 1% of sales, org fee to be 1% and black unicorn to 0.5%
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 100;
        creatorFee = 100;
        blackUniFee = 50;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        //Fees for first sale only
        orgFeeInitial = 200;
        blackUniFeeInital = 50;
        sellerFeeInitial = 10000-orgFeeInitial-blackUniFeeInital;
    }

    /**
    * @dev Owner can transfer the ownership of the contract to a new account (`_grantedOwner`).
    * Can only be called by the current owner.
    */
    function grantContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipGranted(newOwner);
        _grantedOwner = newOwner;
    }

    /**
    * @dev Claims granted ownership of the contract for a new account (`_grantedOwner`).
    * Can only be called by the currently granted owner.
    */
    function claimContractOwnership() public virtual {
        require(_grantedOwner == msg.sender, "Ownable: caller is not the granted owner");
        emit OwnershipTransferred(owner, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /**
    * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeOrgAddress(address _newOrg) public onlyOwner {
        require(_newOrg != address(0), "New organization cannot be zero address");
        ethernaal_org = payable(_newOrg);
    }

    /**
    * @dev Black Unicorn organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeBlackUniAddress(address _blakcUniOrg) public onlyOwner {
        require(_blakcUniOrg != address(0), "New organization cannot be zero address");
        blackUni_org = payable(_blakcUniOrg);
    }

    /**
    * @dev This function is used to get the seller percentage. 
    * This refers to the amount of money that would be distributed to the seller 
    * after the reduction of royalty and platform fees.
    * The values are multiplied by 100, in order to work easily 
    * with floating point percentages.
    */
    function getSellerFee() public view returns (uint256) {
        //Returning % multiplied by 100 to keep it uniform across contract
        return sellerFee;
    }


    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist.
    * Each of the organisation, creator royalty and the parent organsation fees
    * are set in this function.
    * The 'sellerFee' indicates the final amount to be sent to the seller.
    */
    function setRoyaltyPercentage(uint256 _orgFee, uint _creatorFee, uint _blackUnicornFee) public onlyOwner returns (bool) {
        //Sum of org fee and creator fee should be 100%
        require(10000 > _orgFee+_creatorFee+_blackUnicornFee, "Sum of creator fee and org fee should be 100%");
        orgFee = _orgFee;
        creatorFee = _creatorFee;
        blackUniFee = _blackUnicornFee;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        return true; 
    }

    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist(who would be the seller) on the first sale.
    * The first iteration of whitepaper has the following stats:
    * orgFee = 2%
    * blackUnicornFee = 0.5%
    * artist royalty/creator fee = 0%
    * The above numbers can be updated later by the DAO
    * @notice _creatorFeeInitial should be sellerFeeInitial - seller fees on first sale
    */
    function setRoyaltyPercentageFirstSale(uint256 _orgFeeInitial, uint _creatorFeeInitial, uint _blackUnicornFeeInitial) public onlyOwner returns (bool) {
        orgFeeInitial = _orgFeeInitial;
        sellerFeeInitial = _creatorFeeInitial;
        _blackUnicornFeeInitial = _blackUnicornFeeInitial;
        return true;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
    * orgFee - % of fees that would go to the org from the total royalty
    * blackUniFee - % of fees for Black Unicorn
    * creatorRoyalty - % of fees that would go to the artist/creator
    * orgInitialRoyalty - % of fees that would go to the organisation on first sale
    * sellerFeeInitial - % of fees for seller on the first sale
    * blackUniFeeInitial - % of fees that would go to Black Unicorn on first sale
    */
    function getRoyalties() public view returns (uint _orgFee, uint _blackUniFee, uint256 _creatorRoyalty, 
    uint256 _orgInitialRoyalty, uint256 _sellerFeeInitial, uint _blakcUniFeeInitial) {
        
        return (orgFee, creatorFee, blackUniFee, orgFeeInitial, sellerFeeInitial, blackUniFeeInital);
    }

    /**
    * This function is used to set the price of a token
    * @notice Only admin is allowed to set the price of a token
    */
    function setPrice(uint256 tokenId, uint256 price) public onlyAdmin {
        salePrice[tokenId] = price;
    }

    /**
    * This function is used to change the price of a token
    * @notice Only token owner is allowed to change the price of a token
    */
    function changePrice(uint256 _tokenId, uint256 price) public onlyOwnerOf(_tokenId) {
        require(price > 0, "changePrice: Price cannot be changed to less than 0");
        salePrice[_tokenId] = price;
    }

    /**
    * This function is used to check if it is the first sale of a token
    * on the Ethernaal marketplace.
     */
    function isTokenFirstSale(uint tokenId) external view returns(bool){
        return tokenFirstSale[tokenId];
    }

    /**
    * This function is used to mint an NFT for the Ethernaal marketplace.
    * @dev The basic information related to the NFT needs to be passeed to this function,
    * in order to store it on chain to avoid disputes in future.
    */
    function mintWithIndex(address _creator, string memory _tokenURI, string memory title,
    string memory description, string memory artistName) public virtual onlyMinter returns (uint256 _tokenId) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenOwner[tokenId] = _creator;

       
        _mint(_creator, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        tokenCreator[tokenId] = _creator;
        
        NFTData memory nftNew = NFTData(tokenId, title, description, artistName, _creator);
        mintedNfts.push(nftNew);
        
        creatorTokens[_creator].push(tokenId);
        emit Mint(_creator,tokenId, _tokenURI);
        return tokenId;
    }
    
    /**
    * This function is used to set an NFT on sale. 
    * @dev The sale price set in this function will be used to perform the sale transaction
    * once the buyer wants to buy an NFT.
    */
    function setSale(uint256 _tokenId, uint256 price) public virtual onlyOwnerOf(_tokenId) {
        address tOwner = ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        require(price != 0, "setSale: Price cannot be set to zero");
        salePrice[_tokenId] = price;
        emit SalePriceSet(_tokenId, price);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSale(uint256 tokenId, address _nftAddress)
        public
        payable
    {
        ERC721 nftAddress = ERC721(_nftAddress);

        uint256 price = salePrice[tokenId];
        uint256 sellerFees = getSellerFee();
        uint256 creatorRoyalty = creatorFee;
        uint256 platformFees = orgFee;
        uint256 blackUnicornFee = blackUniFee;

        require(price != 0, "buyToken: price equals 0");
        require(
            msg.value == price,
            "buyToken: price doesn't equal salePrice[tokenId]"
        );
        address tOwner = nftAddress.ownerOf(tokenId);

        nftAddress.safeTransferFrom(tOwner, msg.sender, tokenId);
        salePrice[tokenId] = 0;

        if(tokenFirstSale[tokenId] == false) {
            /* Platform takes 2.5% on each artist's first sale
            *  All values are multiplied by 100 to deal with floating points
            */
            platformFees = orgFeeInitial;
            sellerFees = sellerFeeInitial;
            blackUnicornFee = blackUniFeeInital;
            //No creator royalty/royalties when artist is minting for the first time
            creatorRoyalty = 0;

            tokenFirstSale[tokenId] = true;
        }   
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toCreator = (msg.value*creatorRoyalty) / FLOAT_HANDLER_TEN_4;
        uint256 toPlatform = (msg.value*platformFees) / FLOAT_HANDLER_TEN_4;
        uint256 toBlackUnicorn = (msg.value*blackUnicornFee) / FLOAT_HANDLER_TEN_4;
        
        address tokenCreatorAddress = tokenCreator[tokenId];
        
        payable(tOwner).transfer(toSeller);
        if(toCreator != 0) {
            payable(tokenCreatorAddress).transfer(toCreator);
        }
        
        ethernaal_org.transfer(toPlatform);
        payable(blackUni_org).transfer(toBlackUnicorn);
        
        emit Sold(msg.sender, tOwner, msg.value,tokenId);
    }


    /**
    * This function is used to return all the tokens created by a specific creator
    */
    function tokenCreators(address _creator) external view onlyOwner returns(uint[] memory) {
            return creatorTokens[_creator];
    }

    /**
    * This function is used to whitelist a creator/ an artist on the platform
    */
    function whitelistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if(creatorWhitelist[_creators[i]]){
                //Do nothing if address is already whitelisted
            }
            else {
                creatorWhitelist[_creators[i]] = true;
                emit WhitelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This function is used to unlist/delist a creator from the platform
    */
    function delistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if (creatorWhitelist[_creators[i]] == true){
                creatorWhitelist[_creators[i]] = false;
                emit DelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This is a getter function to get the current price of an NFT.
    */
    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return salePrice[tokenId];
    }

    /**
    * This function returns if a creator is whitelisted on the platform or no
    */
    function isWhitelisted(address _creator) external view returns (bool) {
        return creatorWhitelist[_creator];
    }

    /**
    * This returns the total number of NFTs minted on the platform
    */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

/**  
* @title An NFT Marketplace contract for Ethernaal eNFTs
* @author Gnana Lakshmi T C
* @notice This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
* @dev Most function calls are currently implemented with access control
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
* This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
*/
contract EthernaalENFT is ERC721URIStorage {

    using SafeMath for uint256;
    mapping(uint256 => uint256) private salePrice;
    mapping(address => bool) public creatorWhitelist;
    mapping(uint256 => address) private tokenOwner;
    mapping(uint256 => address) private tokenCreator;
    mapping(address => uint[]) private creatorTokens;
    //This is to determine the platform royalty for the first sale made by the creator
    mapping(uint => bool) private tokenFirstSale;

    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event WhitelistCreator(address indexed _creator);
    event DelistCreator(address indexed _creator);
    event OwnershipGranted(address indexed newOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Mint(address indexed creator,uint indexed tokenId, string indexed tokenURI);

    uint constant FLOAT_HANDLER_TEN_4 = 10000;

    address owner;
    address _grantedOwner;
    address admin;
    address blackUni_org;
    uint256 sellerFee;
    uint256 orgFee;
    uint256 creatorFee;
    uint256 blackUniFee;
    uint256 sellerFeeInitial;
    uint256 orgFeeInitial;
    uint256 blackUniFeeInital;
    address payable ethernaal_org;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTData {
        uint tokenId;
        string title;
        string description;
        string artistName;
        address creator;
    }

    NFTData[] mintedNfts;

    /**
    * Modifier to allow only minters to mint
    */
    modifier onlyMinter() virtual {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

    /**
    * Modifier to allow only owners of a token to perform certain actions 
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * Modifier to allow only owner of the contract to perform certain actions 
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
    * Modifier to allow only admin of the organization to perform certain actions 
    */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(string memory _name, 
        string memory _symbol,
        address payable org,
        address payable blackUnicornOrg,
        address payable _admin
        )
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
        admin = _admin;
        ethernaal_org = org;
        blackUni_org = blackUnicornOrg;
        //Creator royalty Fee is fixed to be 1% of sales, org fee to be 1% and black unicorn to 0.5%
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 100;
        creatorFee = 100;
        blackUniFee = 50;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        //Fees for first sale only
        orgFeeInitial = 200;
        blackUniFeeInital = 50;
        sellerFeeInitial = 10000-orgFeeInitial-blackUniFeeInital;
    }

    /**
    * @dev Owner can transfer the ownership of the contract to a new account (`_grantedOwner`).
    * Can only be called by the current owner.
    */
    function grantContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipGranted(newOwner);
        _grantedOwner = newOwner;
    }
    
    /**
    * @dev Claims granted ownership of the contract for a new account (`_grantedOwner`).
    * Can only be called by the currently granted owner.
    */
    function claimContractOwnership() public virtual {
        require(_grantedOwner == msg.sender, "Ownable: caller is not the granted owner");
        emit OwnershipTransferred(owner, _grantedOwner);
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /**
    * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeOrgAddress(address _newOrg) public onlyOwner {
        require(_newOrg != address(0), "New organization cannot be zero address");
        ethernaal_org = payable(_newOrg);
    }

    /**
    * @dev Black Unicorn organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function changeBlackUniAddress(address _blakcUniOrg) public onlyOwner {
        require(_blakcUniOrg != address(0), "New organization cannot be zero address");
        blackUni_org = payable(_blakcUniOrg);
    }

    /**
    * @dev This function is used to get the seller percentage. 
    * This refers to the amount of money that would be distributed to the seller 
    * after the reduction of royalty and platform fees.
    * The values are multiplied by 100, in order to work easily 
    * with floating point percentages.
    */
    function getSellerFee() public view returns (uint256) {
        //Returning % multiplied by 100 to keep it uniform across contract
        return sellerFee;
    }


    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist.
    * Each of the organisation, creator royalty and the parent organsation fees
    * are set in this function.
    * The 'sellerFee' indicates the final amount to be sent to the seller.
    */
    function setRoyaltyPercentage(uint256 _orgFee, uint _creatorFee, uint _blackUnicornFee) public onlyOwner returns (bool) {
        //Sum of org fee and creator fee should be 100%
        require(10000 > _orgFee+_creatorFee+_blackUnicornFee, "Sum of creator fee and org fee should be 100%");
        orgFee = _orgFee;
        creatorFee = _creatorFee;
        blackUniFee = _blackUnicornFee;
        sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        return true; 
    }

    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist(who would be the seller) on the first sale.
    * The first iteration of whitepaper has the following stats:
    * orgFee = 2%
    * blackUnicornFee = 0.5%
    * artist royalty/creator fee = 0%
    * The above numbers can be updated later by the DAO
    * @notice _creatorFeeInitial should be sellerFeeInitial - seller fees on first sale
    */
    function setRoyaltyPercentageFirstSale(uint256 _orgFeeInitial, uint _creatorFeeInitial, uint _blackUnicornFeeInitial) public onlyOwner returns (bool) {
        orgFeeInitial = _orgFeeInitial;
        sellerFeeInitial = _creatorFeeInitial;
        _blackUnicornFeeInitial = _blackUnicornFeeInitial;
        return true;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
    * orgFee - % of fees that would go to the org from the total royalty
    * blackUniFee - % of fees for Black Unicorn
    * creatorRoyalty - % of fees that would go to the artist/creator
    * orgInitialRoyalty - % of fees that would go to the organisation on first sale
    * sellerFeeInitial - % of fees for seller on the first sale
    * blackUniFeeInitial - % of fees that would go to Black Unicorn on first sale
    */
    function getRoyalties() public view returns (uint _orgFee, uint _blackUniFee, uint256 _creatorRoyalty, 
    uint256 _orgInitialRoyalty, uint256 _sellerFeeInitial, uint _blakcUniFeeInitial) {
        
        return (orgFee, creatorFee, blackUniFee, orgFeeInitial, sellerFeeInitial, blackUniFeeInital);
    }


    /**
    * This function is used to set the price of a token
    * @notice Only admin is allowed to set the price of a token
    */
    function setPrice(uint256 tokenId, uint256 price) public onlyAdmin {
        salePrice[tokenId] = price;
    }

    /**
    * This function is used to change the price of a token
    * @notice Only token owner is allowed to change the price of a token
    */
    function changePrice(uint256 _tokenId, uint256 price) public onlyOwnerOf(_tokenId) {
        require(price > 0, "changePrice: Price cannot be changed to less than 0");
        salePrice[_tokenId] = price;
    }

    /**
    * This function is used to check if it is the first sale of a token
    * on the Ethernaal marketplace.
     */
    function isTokenFirstSale(uint tokenId) external view returns(bool){
        return tokenFirstSale[tokenId];
    }

    /**
    * This function is used to mint an NFT for the Ethernaal marketplace.
    * @dev The basic information related to the NFT needs to be passeed to this function,
    * in order to store it on chain to avoid disputes in future.
    */
    function mintWithIndex(address _creator, string memory _tokenURI, string memory title,
    string memory description, string memory artistName) public virtual onlyMinter returns (uint256 _tokenId) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenOwner[tokenId] = _creator;

       
        _mint(_creator, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        tokenCreator[tokenId] = _creator;
        
        NFTData memory nftNew = NFTData(tokenId, title, description, artistName, _creator);
        mintedNfts.push(nftNew);
        
        creatorTokens[_creator].push(tokenId);
        emit Mint(_creator,tokenId, _tokenURI);
        return tokenId;
    }
    
    /**
    * This function is used to set an NFT on sale. 
    * @dev The sale price set in this function will be used to perform the sale transaction
    * once the buyer wants to buy an NFT.
    */
    function setSale(uint256 _tokenId, uint256 price) public virtual onlyOwnerOf(_tokenId) {
        address tOwner = ownerOf(_tokenId);
        require(tOwner != address(0), "setSale: nonexistent token");
        require(price != 0, "setSale: Price cannot be set to zero");
        salePrice[_tokenId] = price;
        emit SalePriceSet(_tokenId, price);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSale(uint256 tokenId, address _nftAddress)
        public
        payable
    {
        ERC721 nftAddress = ERC721(_nftAddress);

        uint256 price = salePrice[tokenId];
        uint256 sellerFees = getSellerFee();
        uint256 creatorRoyalty = creatorFee;
        uint256 platformFees = orgFee;
        uint256 blackUnicornFee = blackUniFee;

        require(price != 0, "buyToken: price equals 0");
        require(
            msg.value == price,
            "buyToken: price doesn't equal salePrice[tokenId]"
        );
        address tOwner = nftAddress.ownerOf(tokenId);

        nftAddress.safeTransferFrom(tOwner, msg.sender, tokenId);
        salePrice[tokenId] = 0;

        if(tokenFirstSale[tokenId] == false) {
            /* Platform takes 2.5% on each artist's first sale
            *  All values are multiplied by 100 to deal with floating points
            */
            platformFees = orgFeeInitial;
            sellerFees = sellerFeeInitial;
            blackUnicornFee = blackUniFeeInital;
            //No creator royalty/royalties when artist is minting for the first time
            creatorRoyalty = 0;

            tokenFirstSale[tokenId] = true;
        }   
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;
        
        //Dividing by 100*100 as all values are multiplied by 100
        uint256 toCreator = (msg.value*creatorRoyalty) / FLOAT_HANDLER_TEN_4;
        uint256 toPlatform = (msg.value*platformFees) / FLOAT_HANDLER_TEN_4;
        uint256 toBlackUnicorn = (msg.value*blackUnicornFee) / FLOAT_HANDLER_TEN_4;
        
        address tokenCreatorAddress = tokenCreator[tokenId];
        
        payable(tOwner).transfer(toSeller);
        if(toCreator != 0) {
            payable(tokenCreatorAddress).transfer(toCreator);
        }
        
        ethernaal_org.transfer(toPlatform);
        payable(blackUni_org).transfer(toBlackUnicorn);
        
        emit Sold(msg.sender, tOwner, msg.value,tokenId);
    }


    /**
    * This function is used to return all the tokens created by a specific creator
    */
    function tokenCreators(address _creator) external view returns(uint[] memory) {
            return creatorTokens[_creator];
    }

    /**
    * This function is used to whitelist a creator/ an artist on the platform
    */
    function whitelistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if(creatorWhitelist[_creators[i]]){
                //Do nothing if address is already whitelisted
            }
            else {
                creatorWhitelist[_creators[i]] = true;
                emit WhitelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This function is used to unlist/delist a creator from the platform
    */
    function delistCreator(address[] memory _creators) public onlyOwner {
        for(uint i = 0; i < _creators.length; i++){
            if (creatorWhitelist[_creators[i]] == true){
                creatorWhitelist[_creators[i]] = false;
                emit DelistCreator(_creators[i]);
            }
        }
        
    }

    /**
    * This is a getter function to get the current price of an NFT.
    */
    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return salePrice[tokenId];
    }

    /**
    * This function returns if a creator is whitelisted on the platform or no
    */
    function isWhitelisted(address _creator) external view returns (bool) {
        return creatorWhitelist[_creator];
    }

    /**
    * This returns the total number of NFTs minted on the platform
    */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

//This contract is for dropping the membership NFT to everyone
contract NFTAirdrop {

  struct Airdrop {
    address nft;
    uint id;
  }

  uint public nextAirdropId;
  address public admin;

  mapping(uint => Airdrop) public airdrops;
  mapping(address => bool) public recipients;

  constructor() {
    admin = msg.sender;
  }

  //Add the list of NFTs we want to airdrop - this contains the NFT address and an ID
  function addAirdrops(Airdrop[] memory _airdrops) external {
    uint _nextAirdropId = nextAirdropId;
    for(uint i = 0; i < _airdrops.length; i++) {
      airdrops[_nextAirdropId] = _airdrops[i];
      //The calling address should own all the NFTs
      IERC721(_airdrops[i].nft).transferFrom(
        msg.sender, 
        address(this), 
        _airdrops[i].id
      );
      _nextAirdropId++;
    }
  }

//Add all the whitelisted recepients addresses
  function addRecipients(address[] memory _recipients) external {
    require(msg.sender == admin, 'only admin');
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = true;
    }
  }

//Remove the whitelisted recepients addresses if required
  function removeRecipients(address[] memory _recipients) external {
    require(msg.sender == admin, 'only admin');
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = false;
    }
  }

//Function to claim the airdrop
  function claim() external {
    require(recipients[msg.sender] == true, 'recipient not registered');
    recipients[msg.sender] = false;
    Airdrop storage airdrop = airdrops[nextAirdropId];
    IERC721(airdrop.nft).transferFrom(address(this), msg.sender, airdrop.id);
    nextAirdropId++;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Standard ERC20 token, with minting and pause functionality.
 *
 */
// Initializable,
// ERC20PresetMinterPauserUpgradeSafe
contract ERC20Token is ERC20 {
    address payable public _owner;
    uint256 constant _initMint = 10e10;
    uint8 customDecimals = 18;
    // mapping(address => uint256) values;

    modifier onlyOwner() {
        require(
            _msgSender() == _owner,
            "solo el owner puede ejecutar esta funcion"
        );
        _;
    }


    // Initializer function (replaces constructor)
    constructor(string memory symbol, string memory name, uint8 _decimals) ERC20(name, symbol)
    {
        customDecimals = _decimals;
        _owner = payable(_msgSender());
        _mint(_owner, _initMint * (10**uint256(decimals())));
    }

    function decimals() public view virtual override returns (uint8) {
        return customDecimals;
    }

    function getBalance() public view onlyOwner() returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner() {
        require(address(this).balance > 0, "No hay nada que retirar");
        payable(_msgSender()).transfer(address(this).balance);
    }

    /*function destroy(uint password) public onlyOwner {
        require(password == 995511, "wrong password to destroy");
        selfdestruct(owner);
    }*/
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**  
* @title An NFT Marketplace contract for Ethernaal NFTs
* @author Ethernaal
* @notice This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
* @dev Most function calls are currently implemented with access control
* This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
*/
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC20{
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


struct AssetData {
    uint256 assetId;
    uint256 lazyTokenId;
    uint256 tokenId;
    address creator;
    string title;
    string artistName;
    string tokenUri;
    bool isForSale;
    string nftType;
    string status;
}

struct SaleData{
    uint256 tokenId;
    uint256 price;
    uint256 naalPrice;
}

struct NftType{
    string nftType;
    bool reqWhitelist;
}

contract EthernaalNFT is ERC721{

    address public owner;
    address[] admins;
    address public blackUniOrg;
    address payable public ethernaalOrg;
    uint256 orgFee;
    uint256 blackUniFee;
    uint256 creatorFee; // in percentage (1% = 100)
    // uint256 sellerFee;
    uint256 orgFeeInitial;
    uint256 blackUniFeeInital;
    IERC20 public naalToken;

    //mapping creator to whitelisted nft types 
    mapping(address => string[]) cWL;
    //mapping creator to asset id
    mapping(address => uint[]) creatorAssetIds;
    //list of allowed NFT types
    NftType[] public listNftTypes;

    uint public lazySupply;
    uint public nftSupply;
    uint public assetSupply;
    mapping(uint => AssetData) public assets;
    //mapping tokenId to token id
    mapping(uint => uint) public nfts;
    //mapping lazy tokenId to lazy token id
    mapping(uint => uint) public lazyAssets;

    //mapping address owner to list of tokens
    mapping(address => uint[]) nftsOf;
    //mapping tokenId to sale data
    mapping(uint => SaleData) public _salePrices;
    //mapping lazy tokenId to sale data
    mapping(uint => SaleData) public _lazyPrices;

    event LazyToken(address creator, uint lazyTokenId, string tokenUri);
    event SalePriceSet(uint256 indexed _tokenId, uint256 _price, uint256 _naalPrice);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId, bool payWithNaal);
    event WhitelistCreator(address indexed _creator, string[] nftTypes);
    event DelistCreator(address indexed _creator);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Mint(address indexed creator, uint indexed tokenId, string indexed tokenURI);
    event Burned(address tokenOwner, uint tokenId, string tokenUri);
    event StatusSet(uint _tokenId, string status);
    event OwnerChanged(address tOwner, address newOwner, uint tokenId, uint price, bool payWithNaal);

    error InsufficientFundsToBuy(uint requested, uint paymentIntent);

    uint constant FLOAT_HANDLER_TEN_4 = 10000;

    /**
    * Modifier to allow only minters to mint
    */
    modifier onlyMinter(string memory nftType) virtual {
        require(isWhitelisted(_msgSender(), nftType), "You are not whitelisted");
        _;
    }

    /**
    * Modifier to allow only owners of a token to perform certain actions 
    */
    modifier onlyHodlerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner");
        _;
    }

    /**
    * Modifier to allow only owner of the contract to perform certain actions 
    */
    modifier onlyOwner() {
        require(_msgSender() == owner, "You are not the owner");
        _;
    }
    
    /**
    * Modifier to allow only admin of the organization to perform certain actions 
    */
    modifier onlyAdmins() {
        require(_msgSender() == owner || _isAdmin(_msgSender(), false), "You are not admin");
        _;
    }

    function _isAdmin(address _a, bool rmIfFound) internal returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _a) {
                if(rmIfFound){
                    admins[i] = admins[admins.length - 1];
                    admins.pop();
                }
                return true;
            }
        }
        return false;
    }

    constructor(string memory _name, 
        string memory _symbol,
        address payable org,
        address payable blackUnicornOrg,
        address naalAddress
    ) ERC721(_name, _symbol) {
        naalToken = IERC20(naalAddress);

        owner = _msgSender();
        ethernaalOrg = org;
        blackUniOrg = blackUnicornOrg;
        //Creator royalty Fee is fixed to be 1% of sales, org fee to be 1% and black unicorn to 0.5%
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 100;
        creatorFee = 100;
        blackUniFee = 50;
        // sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        //Fees for first sale only
        orgFeeInitial = 200;
        blackUniFeeInital = 50;
    }

    function _valAddr(address addr) internal pure{
        require(addr != address(0), "Invalid addr");
    }

    function transferSCOwnership(address newOwner) public virtual onlyOwner{
        _valAddr(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
    * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function setOrgAddress(address _newOrg) public onlyOwner{
        _valAddr(_newOrg);
        ethernaalOrg = payable(_newOrg);
    }

    /**
    * @dev Black Unicorn organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function setBlackUniAddress(address _blackUniOrg) public onlyOwner{
        _valAddr(_blackUniOrg);
        blackUniOrg = payable(_blackUniOrg);
    }

    function addAdmin(address _newAdmin) public onlyAdmins{
        _valAddr(_newAdmin);
        require(!_isAdmin(_newAdmin, false), "is already an admin");
        admins.push(_newAdmin);
    }

    function rmAdmin(address _admin) public onlyAdmins returns(bool){
        _valAddr(_admin);
        return _isAdmin(_admin, true);
    }

    function setNaalAddress(address _naalAddress) public onlyAdmins{
        _valAddr(_naalAddress);
        naalToken = IERC20(_naalAddress);
    }
    
    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist.
    * Each of the organisation, creator royalty and the parent organsation fees
    * are set in this function.
    * The 'sellerFee' indicates the final amount to be sent to the seller.
    * The first iteration of whitepaper has the following stats:
    * orgFee = 2%
    * blackUnicornFee = 0.5%
    * artist royalty/creator fee = 0%
    * The above numbers can be updated later by the DAO
    */
    function setRoyaltyPercentage(uint256 _orgFee, uint _creatorFee, uint _blackUnicornFee, uint256 _orgFeeInitial, uint _blackUnicornFeeInitial) public onlyAdmins {
        //Sum of org fee and creator fee should be 100%
        require(10000 > _orgFee+_creatorFee+_blackUnicornFee, "seller should earn something");
        orgFee = _orgFee;
        creatorFee = _creatorFee;
        blackUniFee = _blackUnicornFee;
        // sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        orgFeeInitial = _orgFeeInitial;
        _blackUnicornFeeInitial = _blackUnicornFeeInitial;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
    * orgFee - % of fees that would go to the org from the total royalty
    * blackUniFee - % of fees for Black Unicorn
    * creatorRoyalty - % of fees that would go to the artist/creator
    * orgInitialRoyalty - % of fees that would go to the organisation on first sale
    * blackUniFeeInitial - % of fees that would go to Black Unicorn on first sale
    */
    function getRoyalties() public view returns (uint _orgFee, uint _blackUniFee, uint256 _creatorRoyalty, 
    uint256 _orgInitialRoyalty, uint _blakcUniFeeInitial) {
        return (orgFee, creatorFee, blackUniFee, orgFeeInitial, blackUniFeeInital);
    }

    function getNftTypes() public view returns (NftType[] memory) {
        return listNftTypes;
    }

    function addNftTypes(string[] memory types, bool[] memory reqWhitelist) public onlyAdmins {
        require(types.length == reqWhitelist.length, "both lists should be same length");
        for(uint j = 0; j < types.length; j++) {
            (bool exists,) = existsNftType(types[j]);
            if(!exists) {
                listNftTypes.push(NftType(types[j], reqWhitelist[j]));
            }
        }
    }

    function removeNftTypes(string[] memory types) public onlyAdmins {
        for(uint j = 0; j < types.length; j++) {
            _rmIfExistsNftType(types[j]);
        }
    }

    function existsNftType(string memory nftType) public view returns (bool, bool) {
        for(uint i = 0; i < listNftTypes.length; i++) {
            if(compareStrings(listNftTypes[i].nftType, nftType)) {
                return (true, listNftTypes[i].reqWhitelist);
            }
        }
        return (false, true);
    }

    function _rmIfExistsNftType(string memory nftType) internal {
        for(uint i = 0; i < listNftTypes.length; i++) {
            if(compareStrings(listNftTypes[i].nftType, nftType)) {
                listNftTypes[i] = listNftTypes[listNftTypes.length-1];
                listNftTypes.pop();
                return;
            }
        }
    }

    /**
    * This function is used to set the price of a token
    * @notice Only hodler of token is allowed to set the price of a token
    */
    function setPrice(uint256 tokenId, uint256 price, uint naalPrice) public onlyHodlerOf(tokenId) {
        require(price > 0, "Price should be greater than 0");
        require(naalPrice > 0, "NAAL Price should be greater than 0");
        require(tokenId > 0, "Token ID cannot be zero");
        require(tokenId <= nftSupply, "Token ID cannot be greater than existing token IDs");
        require(assets[tokenId].tokenId == tokenId, "Token ID does not exist");
        // require(_salePrices[tokenId].tokenId == tokenId, "Token ID does not exist");
        _salePrices[tokenId].price = price;
        _salePrices[tokenId].naalPrice = naalPrice;
    }

    function setLazyPrice(uint256 lazyTokenId, uint256 price, uint256 naalPrice) public {
        require(price > 0, "Price should be greater than 0");
        require(naalPrice > 0, "NAAL Price should be greater than 0");
        require(lazyTokenId > 0, "Token ID cannot be zero");
        require(lazyTokenId <= lazySupply, "Token ID cannot be greater than existing lazy token IDs");
        require(assets[lazyAssets[lazyTokenId]].lazyTokenId == lazyTokenId, "Token ID does not exist");
        require(assets[lazyAssets[lazyTokenId]].tokenId == 0, "Asset is already sold");
        require(assets[lazyAssets[lazyTokenId]].creator == _msgSender(), "Only creator of the token can set the price");
        SaleData storage lazyPrice = _lazyPrices[lazyTokenId];
        if(lazyPrice.tokenId == 0) {
            _lazyPrices[lazyTokenId].tokenId = lazyTokenId;
            _lazyPrices[lazyTokenId].price = price;
            _lazyPrices[lazyTokenId].naalPrice = naalPrice;
        } else {
            require(lazyPrice.tokenId == lazyTokenId, "Token ID does not exist");
            _lazyPrices[lazyTokenId].price = price;
            _lazyPrices[lazyTokenId].naalPrice = naalPrice;
        }
    }

    function mintByCreator(
        address _to,
        string memory title,
        string memory artistName,
        string memory metadataUrl,
        string memory nftType
    ) public virtual onlyMinter(nftType) returns(uint256) {
        uint lazyTokenId = _setAssetData(
            _msgSender(),
            title,
            artistName,
            metadataUrl,
            nftType
        );
        return _finishMinting(_to, lazyTokenId);
    }
    
    function startLazyMint(
        string memory title,
        string memory artistName,
        string memory metadataUrl,
        string memory nftType) payable external returns(uint256) {
        uint lazyTokenId = _setAssetData(
            _msgSender(),
            title,
            artistName,
            metadataUrl,
            nftType
        );
        assets[lazyAssets[lazyTokenId]].isForSale = true;
        return lazyTokenId;
    }
    
    function buyLazyTokenWithNaal(uint _lazyTokenId) external{
        uint allowance = naalToken.allowance(msg.sender, address(this));
        _validateBeforeBuy(_lazyTokenId, true, allowance);
        uint totalPrice = _lazyPrices[_lazyTokenId].naalPrice;

        (uint toSeller, uint _toCreator, uint toPlatform, uint toBlackUnicorn) 
            = _calcPaymentDistribution(totalPrice, 0, orgFeeInitial, blackUniFeeInital);
        require(_toCreator == 0, "creator should not be paid for the first sale");
        address tokenCreatorAddress = assets[lazyAssets[_lazyTokenId]].creator;
        
        uint tokenId = _finishMinting(_msgSender(), _lazyTokenId);
        _sendPayments(true, msg.sender, payable(tokenCreatorAddress), 0, 
            payable(tokenCreatorAddress), toSeller, toPlatform, toBlackUnicorn);
        emit Sold(_msgSender(), tokenCreatorAddress, totalPrice, tokenId, true);
    }

    function buyLazyToken(uint _lazyTokenId) payable external{
        _validateBeforeBuy(_lazyTokenId, false, msg.value);
        uint totalPrice = _lazyPrices[_lazyTokenId].price;
        (uint toSeller, uint _toCreator, uint toPlatform, uint toBlackUnicorn) 
            = _calcPaymentDistribution(totalPrice, 0, orgFeeInitial, blackUniFeeInital);
        require(_toCreator == 0, "creator should not be paid for the first sale");
        address tokenCreatorAddress = assets[lazyAssets[_lazyTokenId]].creator;
        
        uint tokenId = _finishMinting(_msgSender(), _lazyTokenId);
        _sendPayments(false, msg.sender, payable(tokenCreatorAddress), 0, 
            payable(tokenCreatorAddress), toSeller, toPlatform, toBlackUnicorn);
        emit Sold(_msgSender(), tokenCreatorAddress, totalPrice, tokenId, false);
    }

    function _validateBeforeBuy(uint _lazyTokenId, bool payWithNaal, uint payingValue) internal view {
        require(_lazyTokenId > 0 && _lazyTokenId <= lazySupply, "Token ID is not valid");
        require(assets[lazyAssets[_lazyTokenId]].tokenId == 0, "Asset is already sold");
        require(assets[lazyAssets[_lazyTokenId]].lazyTokenId == _lazyTokenId, "Invalid ID");
        require(assets[lazyAssets[_lazyTokenId]].creator != address(0), "assets not found or already minted");
        require(assets[lazyAssets[_lazyTokenId]].isForSale, "Token is not for sale");
        uint price = payWithNaal ? 
            _lazyPrices[_lazyTokenId].naalPrice
            : _lazyPrices[_lazyTokenId].price;
        require(price > 0, "price not set yet");
        if(payingValue < price){
            revert InsufficientFundsToBuy(price, payingValue);
        }
    }
    
    function _setAssetData(
        address creator,
        string memory title,
        string memory artistName,
        string memory tokenUri,
        string memory nftType
    ) internal returns (uint256) {
        (bool allowed, ) = existsNftType(nftType);
        require(allowed, "NFT type is not allowed");
        assetSupply++;
        uint256 lazyTokenId = ++lazySupply;

        AssetData memory entry = assets[lazyAssets[lazyTokenId]];
        require(entry.creator == address(0), "token already created");
        entry = AssetData(assetSupply, lazyTokenId, 0, creator, title,
            artistName, tokenUri,
            false, nftType, "");
        lazyAssets[entry.lazyTokenId] = assetSupply;
        assets[lazyAssets[entry.lazyTokenId]] = entry;
        emit LazyToken(creator, entry.lazyTokenId, tokenUri);
        return entry.lazyTokenId;
    }
    
    function _finishMinting(
        address _to,
        uint lazyTokenId
    ) internal returns (uint256){
        AssetData storage prefilled = assets[lazyAssets[lazyTokenId]];
        require(prefilled.tokenId == 0, "token already minted");
        require(prefilled.creator != address(0), "lazy asset doesn't exist");
        uint tokenId = ++nftSupply;

        if(nftsOf[_to].length == 0) {
            nftsOf[_to] = [tokenId];
        } else {
            nftsOf[_to].push(tokenId);
        }

        prefilled.tokenId = tokenId;
        prefilled.isForSale = false;
        prefilled.status = "SO";
        nfts[prefilled.tokenId] = prefilled.assetId;
        // assets[prefilled.assetId] = prefilled;
        delete _lazyPrices[lazyTokenId];

        creatorAssetIds[prefilled.creator].push(tokenId);
        _mint(_to, tokenId);
        emit Mint(prefilled.creator, tokenId, prefilled.tokenUri);
        return prefilled.tokenId;
    }

    function _calcPaymentDistribution(uint amount, uint creatorRoyalty, 
        uint platformFees, uint blackUnicornFee) 
    internal pure returns (
        uint toSeller, uint toCreator, uint toPlatform, uint toBlackUnicorn
    ){
        //Dividing by 100*100 as all values are multiplied by 100
        // uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;
        toCreator = (amount * creatorRoyalty) / FLOAT_HANDLER_TEN_4;
        toPlatform = (amount * platformFees) / FLOAT_HANDLER_TEN_4;
        toBlackUnicorn = (amount * blackUnicornFee) / FLOAT_HANDLER_TEN_4;
        toSeller = amount - toCreator - toPlatform - toBlackUnicorn;
        // return (toSeller, toCreator, toPlatform, toBlackUnicorn);
    }

    
    /**
    * This function is used to set an NFT for sale. 
    * @dev The sale price set in this function will be used to perform the sale transaction
    * once the buyer wants to buy an NFT.
    */
    function setForSale(uint256 _tokenId, uint256 price, uint naalPrice) public virtual onlyHodlerOf(_tokenId) {
        require(_tokenId > 0 && _tokenId <= nftSupply, "Token ID is not valid");
        require(price > 0, "Price must be greater than 0");
        require(naalPrice > 0, "NAAL Price should be greater than 0");
        require(assets[nfts[_tokenId]].tokenId == _tokenId, "Token ID does not exist");
        _salePrices[_tokenId].price = price;
        _salePrices[_tokenId].naalPrice = naalPrice;
        assets[nfts[_tokenId]].isForSale = true;
        emit SalePriceSet(_tokenId, price, naalPrice);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSaleWithNaal(uint256 tokenId) external {
        uint totalPrice = _salePrices[tokenId].naalPrice;
        uint allowance = naalToken.allowance(msg.sender, address(this));
        _finishSelling(_msgSender(), true, tokenId, totalPrice, allowance);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSale(uint256 tokenId)
        external
        payable
    {
        uint totalPrice = _salePrices[tokenId].price;
        _finishSelling(_msgSender(), false, tokenId, totalPrice, msg.value);
    }

    function _finishSelling(address buyer, bool payWithNaal,
            uint256 tokenId, uint totalPrice, uint availableToSpend) internal {
        require(totalPrice > 0, "price not set yet");
        require(assets[nfts[tokenId]].isForSale, "token is not for sale");
        if(availableToSpend < totalPrice){
            revert InsufficientFundsToBuy(totalPrice, availableToSpend);
        }

        (uint toSeller, uint toCreator, uint toPlatform, uint toBlackUnicorn) 
            = _calcPaymentDistribution(totalPrice, creatorFee, orgFee, blackUniFee);
        
        address tOwner = _changeOwnerOfNft(tokenId, buyer, totalPrice, payWithNaal);
        _salePrices[tokenId].price = 0;
        _salePrices[tokenId].naalPrice = 0;
        assets[nfts[tokenId]].isForSale = false;
        
        address tokenCreatorAddress = assets[nfts[tokenId]].creator;
        _sendPayments(payWithNaal, buyer, payable(tOwner), toSeller, 
            payable(tokenCreatorAddress), toCreator, 
            toPlatform, toBlackUnicorn);
        emit Sold(buyer, tOwner, totalPrice, tokenId, payWithNaal);
    }

    function _changeOwnerOfNft(uint256 tokenId, address newOwner, uint price, bool payWithNaal) internal returns(address){
        require(assets[nfts[tokenId]].tokenId == tokenId, "Token ID does not exist");
        address tOwner = ownerOf(tokenId);

        // remove tokenId from the previous investor/owner list
        for(uint i = 0; i < nftsOf[tOwner].length; i++){
            if(nftsOf[tOwner][i] == tokenId){
                nftsOf[tOwner][i] = nftsOf[tOwner][nftsOf[tOwner].length - 1];
                nftsOf[tOwner].pop();
                break;
            }
        }
        nftsOf[newOwner].push(tokenId);
        _safeTransfer(tOwner, newOwner, tokenId, "");//bytes(price));
        emit OwnerChanged(tOwner, newOwner, tokenId, price, payWithNaal);
        return tOwner;
    }

    function _sendPayments(bool payWithNaal, address sender,
            address payable hodler, uint toHodler, 
            address payable creator, uint toCreator, 
            uint toPlatform, uint toBlackUnicorn) internal {
        require(hodler != address(0), "hodler address is not valid");
        require(creator != address(0), "creator address is not valid");
        if(toPlatform > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, ethernaalOrg, toPlatform);
            }else{
                payable(ethernaalOrg).transfer(toPlatform);
            }
        }
        if(toBlackUnicorn > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, blackUniOrg, toBlackUnicorn);
            }else{
                payable(blackUniOrg).transfer(toBlackUnicorn);
            }
        }
        if(toCreator > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, creator, toCreator);
            }else{
                creator.transfer(toCreator);
            }
        }
        if(toHodler > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, hodler, toHodler);
            }else{
                hodler.transfer(toHodler);
            }
        }
    }

    function setStatus(uint256 _tokenId, string memory status) public onlyHodlerOf(_tokenId) {
        require(_tokenId > 0 && _tokenId <= nftSupply, "Token ID is not valid");
        require(assets[nfts[_tokenId]].tokenId == _tokenId, "Token ID does not exist");
        assets[nfts[_tokenId]].status = status;
        emit StatusSet(_tokenId, status);
    }

    /**
    * This function is used to whitelist a/an creator/artist on the platform
    */
    function whitelist(address[] memory _creators, string[] memory nftTypes) public onlyAdmins{
        require(listNftTypes.length > 0, "NFT types is not set yet");
        bool exists = true;
        bool[] memory listReqWhitelist = new bool[](nftTypes.length);
        uint numReqWhitelist = 0;
        uint i = 0;
        for(i = 0; i < nftTypes.length; i++){
            (bool existsThisNftType, bool reqWhitelist) = existsNftType(nftTypes[i]);
            listReqWhitelist[i] = reqWhitelist;
            if(reqWhitelist){
                numReqWhitelist++;
            }
            exists = exists && existsThisNftType;
        }
        require(exists, "NFT type is not valid");
        string[] memory nftTypesToAdd = new string[](numReqWhitelist);
        i = 0;
        for(uint j = 0; j < nftTypes.length; j++){
            if(listReqWhitelist[j]){
                nftTypesToAdd[i++] = nftTypes[j];
            }
        }
        for(i = 0; i < _creators.length; i++){
            cWL[_creators[i]] = nftTypesToAdd;
            emit WhitelistCreator(_creators[i], nftTypesToAdd);
        }
        
    }

    /**
    * This function is used to unlist/delist a creator from the platform
    */
    function delist(address[] memory _creators) public onlyAdmins{
        for(uint i = 0; i < _creators.length; i++){
            delete cWL[_creators[i]];
            emit DelistCreator(_creators[i]);
        }
    }

    /**
    * This is a getter function to get the current price of an NFT.
    */
    function getSalePrice(uint256 tokenId, bool isLazy) public view returns (uint256 price, uint256 naalPrice) {
        if(isLazy){
            price = _lazyPrices[tokenId].price;
            naalPrice = _lazyPrices[tokenId].naalPrice;
        }else{
            price = _salePrices[tokenId].price;
            naalPrice = _salePrices[tokenId].naalPrice;
        }
    }

    /**
    * This function returns if a creator is whitelisted on the platform or no
    */
    function isWhitelisted(address _creator, string memory nftType) public view returns (bool) {
        (bool existsThisNftType, bool reqWhitelist) = existsNftType(nftType);
        if(!existsThisNftType) return false;
        if(!reqWhitelist) return true;
        for(uint i = 0; i < cWL[_creator].length; i++){
            if(compareStrings(cWL[_creator][i], nftType)){
                return true;
            }
        }
        return false;
    }

    function getPerm(address _creator) external view returns (string[] memory) {
        return cWL[_creator];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(bytes((a))) == keccak256(bytes((b))));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return assets[nfts[tokenId]].tokenUri;
    }

    function getNTFsOf(address _owner) public view returns (uint256[] memory) {
        return nftsOf[_owner];
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
    }
    
    function getCreations(address _creator) external view returns(uint[] memory) {
        return creatorAssetIds[_creator];
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}