// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts, https://www.starblockdao.io/

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./NFTMasterChef_interfaces.sol";

contract CollectionUtils is ICollectionUtils, Ownable, ReentrancyGuard {
    mapping(IERC721 => uint256) public minTokenIds;// must set the minTokenId for the nft token ID not from 0 or 1, and is not IERC721Enumerable, is not WNFT.
    mapping(IERC721 => uint256) public maxTokenIds;// must set the maxTokenId for the nft without totalSupply method, and is not IERC721Enumerable, is not WNFT.

    function addMinTokenIds(IERC721[] memory _nfts, uint256[] memory _minTokenIds) external onlyOwner nonReentrant {
        require(_nfts.length > 0 && (_nfts.length == _minTokenIds.length), "CollectionUtils: invalid parameters!");
        for(uint256 index = 0; index < _nfts.length; index ++){
            minTokenIds[_nfts[index]] = _minTokenIds[index];
        }
    }

    function addMaxTokenIds(IERC721[] memory _nfts, uint256[] memory _maxTokenIds) external onlyOwner nonReentrant {
        require(_nfts.length > 0 && (_nfts.length == _maxTokenIds.length), "CollectionUtils: invalid parameters!");
        for(uint256 index = 0; index < _nfts.length; index ++){
            maxTokenIds[_nfts[index]] = _maxTokenIds[index];
        }
    }

    function ownerMay(address _contract) public view returns (address _owner) {
        // require(isContract(_contract), "CollectionUtils: invalid parameters!");
        try Ownable(_contract).owner() returns (address owner) {
            _owner = owner;
        } catch {
            
        }
    }

    function collectionInfos(IERC721Metadata[] memory _nfts) external view returns (CollectionInfo[] memory _collectionInfos) {
        require(_nfts.length > 0, "CollectionUtils: invalid parameters!");
        _collectionInfos = new CollectionInfo[](_nfts.length);
        for(uint256 index = 0; index < _nfts.length; index ++){
            _collectionInfos[index] = collectionInfo(_nfts[index]);
        }
    }

    function collectionInfo(IERC721Metadata _nft) public view returns (CollectionInfo memory _collectionInfo) {
        require(address(_nft) != address(0), "CollectionUtils: invalid parameters!");
        try _nft.name() returns (string memory name) {
            _collectionInfo.name = name;
        } catch {
            
        }

        try _nft.symbol() returns (string memory symbol) {
            _collectionInfo.symbol = symbol;
        } catch {
            
        }

        _collectionInfo.totalSupply = totalSupplyMay(_nft);
        _collectionInfo.owner = ownerMay(address(_nft));
    }

    function tokenInfos(IERC721Metadata _nft, uint256[] memory _tokenIds) external view returns 
            (CollectionInfo memory _collectionInfo, TokenInfo[] memory _tokenInfos) {
        require(_tokenIds.length > 0, "CollectionUtils: invalid parameters!");
        _collectionInfo = collectionInfo(_nft);

        _tokenInfos = new TokenInfo[](_tokenIds.length);
        for(uint256 index = 0; index < _tokenIds.length; index ++){
            uint256 tokenId = _tokenIds[index];
            try _nft.tokenURI(tokenId) returns (string memory tokenURI) {
                _tokenInfos[index].tokenURI = tokenURI;
            } catch {
                
            }

            _tokenInfos[index].owner = tokenIdOwnerMay(_nft, tokenId);
        }
    }

    function tokenInfosByNfts(IERC721Metadata[] memory _nfts, uint256[] memory _tokenIds) external view returns 
            (CollectionInfo[] memory _collectionInfos, TokenInfo[] memory _tokenInfos) {
        require(_nfts.length > 0 && _nfts.length == _tokenIds.length, "CollectionUtils: invalid parameters!");
        
        _collectionInfos = new CollectionInfo[](_nfts.length);
        _tokenInfos = new TokenInfo[](_nfts.length);
        for(uint256 index = 0; index < _nfts.length; index ++){
            (_collectionInfos[index], _tokenInfos[index]) = tokenInfo(_nfts[index], _tokenIds[index]);
        }
    }

    function tokenInfo(IERC721Metadata _nft, uint256 _tokenId) public view returns 
            (CollectionInfo memory _collectionInfo, TokenInfo memory _tokenInfo) {
        _collectionInfo = collectionInfo(_nft);

        try _nft.tokenURI(_tokenId) returns (string memory tokenURI) {
            _tokenInfo.tokenURI = tokenURI;
        } catch {
            
        }

        _tokenInfo.owner = tokenIdOwnerMay(_nft, _tokenId);
    }

    function tokenIdRangeMay(IERC721 _nft) public view returns (uint256 _minTokenId, uint256 _maxTokenId){
        _minTokenId = minTokenIds[_nft];
        _maxTokenId = maxTokenIds[_nft];
        if(_minTokenId == 0 && _maxTokenId == 0){
            //WFNT not setted, check if NFT setted
        	if(_nft.supportsInterface(type(IWrappedNFT).interfaceId)){
            	_nft = IWrappedNFT(address(_nft)).nft();
			}
			_minTokenId = minTokenIds[_nft];
			uint256 nftTotalSupply = totalSupplyMay(_nft);
			_maxTokenId = maxTokenIds[_nft];
			if(_maxTokenId < nftTotalSupply){
				_maxTokenId = nftTotalSupply;
			}
        }
    }

    //return all the token ids the collection may have
    function allTokenIdsMay(IERC721 _nft) external view returns (uint256[] memory _tokenIds) {
        (uint256 minTokenId, uint256 maxTokenId) = tokenIdRangeMay(_nft);
        if(maxTokenId > minTokenId || maxTokenId != 0){
            _tokenIds = new uint256[](maxTokenId - minTokenId + 1);
            uint256 index = 0;
            for(uint256 tokenId = minTokenId; tokenId <= maxTokenId; tokenId ++){
                _tokenIds[index] = tokenId;
                index ++;
            }
        }
    }

    function ownedNFTTokenIds(IERC721 _nft, address _user) external view returns (uint256[] memory _ownedTokenIds) {
        if(address(_nft) == address(0) || _user == address(0)){
            return _ownedTokenIds;
        }
        (uint256 minTokenId, uint256 maxTokenId) = tokenIdRangeMay(_nft);
        return ownedNFTTokenIdsByIdRange(_nft, _user, minTokenId, maxTokenId);
    }

    function ownedNFTTokenIdsByIdRange(IERC721 _nft, address _user, uint256 _minTokenId, uint256 _maxTokenId) public view returns (uint256[] memory _ownedTokenIds) {
        // if(address(_nft) == address(0) || _user == address(0)){
        //     return _ownedTokenIds;
        // }
        if (_nft.supportsInterface(type(IERC721Enumerable).interfaceId)) {
            IERC721Enumerable nftEnumerable = IERC721Enumerable(address(_nft));
            _ownedTokenIds = ownedNFTTokenIdsEnumerable(nftEnumerable, _user);
        } else if (_nft.supportsInterface(type(IERC721AQueryable).interfaceId) || _nft.supportsInterface(type(IStarBlockCollection).interfaceId)){
            _ownedTokenIds = IERC721AQueryable(address(_nft)).tokensOfOwner(_user);
        } else {
            _ownedTokenIds = ownedNFTTokenIdsNotEnumerable(_nft, _user, _minTokenId, _maxTokenId);
        }
    }

    function ownedNFTTokenIdsEnumerable(IERC721Enumerable _nftEnumerable, address _user) public view returns (uint256[] memory _ownedTokenIds) {
        // if(address(_nftEnumerable) == address(0) || _user == address(0)){
        //     return _ownedTokenIds;
        // }
        uint256 balance = _nftEnumerable.balanceOf(_user);
        if (balance > 0) {
            _ownedTokenIds = new uint256[](balance);
            for (uint256 index = 0; index < balance; index ++) {
                uint256 tokenId = _nftEnumerable.tokenOfOwnerByIndex(_user, index);
                _ownedTokenIds[index] = tokenId;
            }
        }
    }

    function ownedNFTTokenIdsNotEnumerable(IERC721 _nft, address _user, uint256 _minTokenId, uint256 _maxTokenId) public view returns (uint256[] memory _ownedTokenIds) {
        // if(address(_nft) == address(0) || _user == address(0)){
        //     return _ownedTokenIds;
        // }
        uint256 balance = _nft.balanceOf(_user);
        if(balance > 0){
            //one wrong result with all 0: have balanceOf but not totalSupplyMay, not set maxTokenId
            _ownedTokenIds = new uint256[](balance);
            uint256 index = 0;
            for (uint256 tokenId = _minTokenId; tokenId <= _maxTokenId; tokenId ++) {
                address owner = tokenIdOwnerMay(_nft, tokenId);
                if (_user == owner) {
                    _ownedTokenIds[index] = tokenId;
                    index ++;
                    if(index == balance){
                        break;
                    }
                }
            }
        }
    }

    function totalSupplyMay(IERC721 _nft) public view returns (uint256 _totalSupply){
        IERC721TotalSupply nftWithTotalSupply = IERC721TotalSupply(address(_nft));
        try nftWithTotalSupply.totalSupply() returns (uint256 totalSupply) {
            _totalSupply = totalSupply;
        } catch {
            // _totalSupply = 0;
        }
    }

    function tokenIdOwnerMay(IERC721 _nft, uint256 _tokenId) public view returns (address _owner){
        try _nft.ownerOf(_tokenId) returns (address owner) {
            _owner = owner;
        } catch {
            // _owner = address(0);
        }
    }

    function tokenIdExistsMay(IERC721 _nft, uint256 _tokenId) public view returns (bool _exists){
        if(_nft.supportsInterface(type(IWrappedNFT).interfaceId)){
            IWrappedNFT wnft = IWrappedNFT(address(_nft));
            return wnft.exists(_tokenId);
        }
        try _nft.ownerOf(_tokenId) {
            _exists = true;
        } catch {
            // _exists = false;
        }
    }

    //check if NFT is enumerable by itself
    function canEnumerate(IERC721 _nft) external view returns (bool _enumerable) {
    	_enumerable = true;
    	if (!_nft.supportsInterface(type(IWrappedNFT).interfaceId) && !_nft.supportsInterface(type(IERC721Enumerable).interfaceId) && totalSupplyMay(_nft) == 0) {
            _enumerable = false;
		}
    }

    function transferERC20(IERC20 _token, address[] memory _users, uint256[] memory _amounts) external {
        require(address(_token) != address(0) && _users.length > 0 && _users.length == _amounts.length, "CollectionUtils: invalid parameters!");
        for(uint256 index = 0; index < _users.length; index ++){
            _token.transfer(_users[index], _amounts[index]);
        }
    }

    function areContract(address[] memory _accounts) external view returns (bool[] memory _areContract) {
        require(_accounts.length > 0, "CollectionUtils: invalid parameters!");

        _areContract = new bool[](_accounts.length);
        for(uint256 index = 0; index < _accounts.length; index ++){
            _areContract[index] = isContract(_accounts[index]);
        }
    }

    function isContract(address _account) public view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return _account.code.length > 0;
    }

    function supportERC721(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IERC721).interfaceId);
    }

    function supportERC721Metadata(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IERC721Metadata).interfaceId);
    }

    function supportERC721Enumerable(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IERC721Enumerable).interfaceId);
    }

    function supportIWrappedNFT(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IWrappedNFT).interfaceId);
    }

    function supportIWrappedNFTEnumerable(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IWrappedNFTEnumerable).interfaceId);
    }
}