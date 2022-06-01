// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./ERC721Enumerable.sol";

import "./wnft_interfaces.sol";
import "./ArrayUtils.sol";

abstract contract BaseWrappedNFT is Ownable, ReentrancyGuard, ERC721, ERC2981, IBaseWrappedNFT {
    using ArrayUtils for uint256[];
    
    string public constant NAME_PREFIX = "Wrapped ";
    string public constant SYMBOL_PREFIX = "W";

    IWrappedNFTFactory public immutable factory;// can not changed
    IERC721Metadata public immutable nft;

    address public delegator; //who can help user to deposit and withdraw NFT, need user to approve

    //only user self and delegator can deposit or withdraw for user.
    modifier userSelfOrDelegator(address _forUser) {
        require(msg.sender == delegator || (_forUser == address(0) || _forUser == msg.sender), "BaseWrappedNFT: not allowed!");
        _;
    }

    constructor(
        IERC721Metadata _nft
    ) ERC721("", "") {
        nft = _nft;
        factory = IWrappedNFTFactory(msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721, ERC2981) returns (bool) {
        return _interfaceId == type(IBaseWrappedNFT).interfaceId || _interfaceId == type(IERC721Receiver).interfaceId 
                || _interfaceId == type(IERC2981Mutable).interfaceId || ERC721.supportsInterface(_interfaceId) || ERC2981.supportsInterface(_interfaceId);
    }

    function setDelegator(address _delegator) external onlyOwner nonReentrant {
        //allow delegator to be zero
        delegator = _delegator;
        emit DelegatorChanged(_delegator);
    }

    function _requireTokenIds(uint256[] memory _tokenIds) internal pure {
        require(_tokenIds.length > 0, "BaseWrappedNFT: tokenIds can not be empty!");
        require(!_tokenIds.hasDuplicate(), "BaseWrappedNFT: tokenIds can not contain duplicate ones!");
    }

    function deposit(address _forUser, uint256[] memory _tokenIds) external nonReentrant userSelfOrDelegator(_forUser) { 
        _requireTokenIds(_tokenIds);

        if(_forUser == address(0)){
            _forUser = msg.sender;
        }
        
        uint256 tokenId;
        for(uint256 i = 0; i < _tokenIds.length; i ++){
            tokenId = _tokenIds[i];
            require(nft.ownerOf(tokenId) == _forUser, "BaseWrappedNFT: can not deposit nft not owned!");
            nft.safeTransferFrom(_forUser, address(this), tokenId);
            if(_exists(tokenId)){
                require(ownerOf(tokenId) == address(this), "BaseWrappedNFT: tokenId owner error!");
                _transfer(address(this), _forUser, tokenId);
            }else{
                _safeMint(_forUser, tokenId);
            }
        }
        emit Deposit(_forUser, _tokenIds);
    }

    function withdraw(address _forUser, uint256[] memory _wnftTokenIds) external nonReentrant userSelfOrDelegator(_forUser) {
        _requireTokenIds(_wnftTokenIds);

        if(_forUser == address(0)){
            _forUser = msg.sender;
        }

        uint256 wnftTokenId;
        for(uint256 i = 0; i < _wnftTokenIds.length; i ++){
            wnftTokenId = _wnftTokenIds[i];
            require(ownerOf(wnftTokenId) == _forUser, "BaseWrappedNFT: can not withdraw nft not owned!");
            safeTransferFrom(_forUser, address(this), wnftTokenId);
            nft.safeTransferFrom(address(this), _forUser, wnftTokenId);
        }

        emit Withdraw(_forUser, _wnftTokenIds);
    }
    
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        return string(abi.encodePacked(NAME_PREFIX, nft.name()));
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        return string(abi.encodePacked(SYMBOL_PREFIX, nft.symbol()));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        require(ERC721._exists(_tokenId), "BaseWrappedNFT: URI query for nonexistent token");
        return nft.tokenURI(_tokenId);
    }
    
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received (
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner nonReentrant {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner nonReentrant {
        _deleteDefaultRoyalty();
    }

    function isEnumerable() external view virtual returns (bool) {
        return false;
    }
}

contract WrappedNFT is IWrappedNFT, BaseWrappedNFT {
    //add total supply for etherscan
    uint256 private _totalSupply;

    constructor(
        IERC721Metadata _nft
    ) BaseWrappedNFT(_nft) {

    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, BaseWrappedNFT) returns (bool) {
        return _interfaceId == type(IWrappedNFT).interfaceId || BaseWrappedNFT.supportsInterface(_interfaceId);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        ERC721._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            _totalSupply ++;
        } else if (to == address(0)) {
            _totalSupply --;
        } 
    }

    function totalSupply() public view virtual override returns (uint256){
        return _totalSupply;
    }
}

contract WrappedNFTEnumerable is IWrappedNFTEnumerable, WrappedNFT, ERC721Enumerable {
    constructor(
        IERC721Metadata _nft
    ) WrappedNFT(_nft) {

    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, WrappedNFT, ERC721Enumerable) returns (bool) {
        return _interfaceId == type(IWrappedNFTEnumerable).interfaceId || WrappedNFT.supportsInterface(_interfaceId) || ERC721Enumerable.supportsInterface(_interfaceId);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(WrappedNFT, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        return BaseWrappedNFT.name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        return BaseWrappedNFT.symbol();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        return BaseWrappedNFT.tokenURI(_tokenId);
    }

    function totalSupply() public view override(IWrappedNFTEnumerable, ERC721Enumerable, WrappedNFT) returns (uint256){
        return ERC721Enumerable.totalSupply();
    }

    function isEnumerable() external view virtual override returns (bool) {
        return true;
    }
}

//support deploy 2 WNFTs: ERC721 and ERC721Enumerable implementation.
contract WrappedNFTFactory is IWrappedNFTFactory, Ownable, ReentrancyGuard {
    address public wnftDelegator; //used to set the delegator in WrappedNFT.

    mapping(IERC721Metadata => IWrappedNFT) public wnfts; //all the deployed WrappedNFTs.
    uint256 public wnftsNumber;

    function deployWrappedNFT(IERC721Metadata _nft, bool _isEnumerable) external onlyOwner nonReentrant returns (IWrappedNFT _wnft) {
        require(address(_nft) != address(0), "WrappedNFTFactory: _nft can not be zero!");
        require(address(wnfts[_nft]) == address(0), "WrappedNFTFactory: wnft has been deployed!");
        if(_isEnumerable){
            _wnft = new WrappedNFTEnumerable(_nft);
        }else{
            _wnft = new WrappedNFT(_nft);
        }
        if(wnftDelegator != address(0)){
            _wnft.setDelegator(wnftDelegator);
        }
        Ownable(address(_wnft)).transferOwnership(owner());
        wnfts[_nft] = _wnft;
        wnftsNumber ++;
        emit WrappedNFTDeployed(_nft, _wnft, _isEnumerable);
    }
    
    //allow wnftDelegator to be zero
    function setWNFTDelegator(address _wnftDelegator) external onlyOwner nonReentrant {
        wnftDelegator = _wnftDelegator;
        emit WNFTDelegatorChanged(_wnftDelegator);
    }
}