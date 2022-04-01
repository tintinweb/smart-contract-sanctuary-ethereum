//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Upgradeable.sol';
import './ERC721HolderUpgradeable.sol';
import './IERC721.sol';
import './IERC20.sol';

contract NFTBasket is ERC721Upgradeable, ERC721HolderUpgradeable {
    //the token id + 1 of the nft contract nft
    mapping(address => mapping(uint => uint)) public nftToTokenIdToIndexPlus1;
    address[] public nftContractAddresses;
    uint[] public tokenIds;
    uint public nftCount;
    string public metadataURI;
    
    event Desposit(address indexed nftContractAddress, uint indexed tokenId, address indexed user);
    event Withdraw(address indexed nftContractAddress, uint indexed tokenId, address indexed user);
    
    function initialize(string memory _name, string memory _symbol, address _owner, string memory _metadataURI) initializer public {
        __ERC721_init(_name, _symbol);
        __ERC721Holder_init();
        _mint(_owner, 0);
        metadataURI = _metadataURI;
    }
    
    function setMetadataURI(string memory _metadataURI) public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        metadataURI = _metadataURI;
    }
    
    //opensea will call the tokenURI to show the info of the NFT
    //the tokenURI will return a json include the info of the NFT
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return metadataURI;
    }
    
    function depositNFTs(address _nftContractAddress, uint[] memory _tokenIds) public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        //transfer all selected contract nft to the basket
        for (uint i = 0; i < _tokenIds.length; i++) {
            IERC721(_nftContractAddress).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            nftContractAddresses.push(_nftContractAddress);
            tokenIds.push(_tokenIds[i]);
            nftToTokenIdToIndexPlus1[_nftContractAddress][_tokenIds[i]] = i + 1;
            emit Desposit(_nftContractAddress, _tokenIds[i], msg.sender);
        }
        nftCount += _tokenIds.length;
    }
    
    function depositCollectionsOfNFTs(address[] memory _nftContractAddresses, uint[] memory _tokenIds) public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        require(_nftContractAddresses.length == _tokenIds.length);
        //transfer the selected token from the selected nft address to the basket
        for (uint i = 0; i < _nftContractAddresses.length; i++) {
            IERC721(_nftContractAddresses[i]).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            nftContractAddresses.push(_nftContractAddresses[i]);
            tokenIds.push(_tokenIds[i]);
            nftToTokenIdToIndexPlus1[_nftContractAddresses[i]][_tokenIds[i]] = i + 1;
            emit Desposit(_nftContractAddresses[i], _tokenIds[i], msg.sender);
        }
        nftCount += _tokenIds.length;
    }
    
    //if there are some token that is not deposite from this contract, you can also use this function to withdraw it
    function withdrawNFTs(address _nftContractAddress, uint[] memory _tokenIds) public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        uint depostByFunctionNFTCount = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            IERC721(_nftContractAddress).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            if (nftToTokenIdToIndexPlus1[_nftContractAddress][_tokenIds[i]] > 0) {
                depostByFunctionNFTCount++;
                nftToTokenIdToIndexPlus1[_nftContractAddress][_tokenIds[i]] = 0;
            }
            emit Withdraw(_nftContractAddress, _tokenIds[i], msg.sender);
        }
        
        nftCount -= depostByFunctionNFTCount;
    }
    
    function withdrawAllNFTs() public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        for (uint i = 0; i < nftContractAddresses.length; i++) {
            if (nftToTokenIdToIndexPlus1[nftContractAddresses[i]][tokenIds[i]] > 0) {
                IERC721(nftContractAddresses[i]).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                nftToTokenIdToIndexPlus1[nftContractAddresses[i]][tokenIds[i]] = 0;
                emit Withdraw(nftContractAddresses[i], tokenIds[i], msg.sender);
            }
        }
        delete nftContractAddresses;
        delete tokenIds;
        nftCount = 0;
    }
    
    function withdrawERC20Tokens(address[] memory _contractAddresses) public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        for (uint i = 0; i < _contractAddresses.length; i++) {
            IERC20(_contractAddresses[i]).transfer(msg.sender, IERC20(_contractAddresses[i]).balanceOf(address(this)));
        }
    }
    
    function withdraw() public {
        require(_isApprovedOrOwner(msg.sender, 0), "You are not approved nor owner");
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    
    function getListOfDepositedNFTs() public view returns (address[] memory _contractAddresses, uint [] memory _tokenIds) {
        _contractAddresses = new address[](nftCount);
        _tokenIds = new uint[](nftCount);
        uint count = 0;
        for (uint i = 0; i < nftContractAddresses.length; i++) {
            if (nftToTokenIdToIndexPlus1[nftContractAddresses[i]][tokenIds[i]] > 0) {
                _contractAddresses[count] = nftContractAddresses[i];
                _tokenIds[count] = tokenIds[i];
                count++;
            }
        }
    }
}