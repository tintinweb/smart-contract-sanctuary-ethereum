// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: NFTUtil.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




interface INFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeMint(string memory _tokenURI) external;

    function transferOwnership(address newOwner) external;

    function balanceOf(address owner) external view returns (uint256);

}


contract NFTUtil is Ownable, IERC721Receiver {

    INFT private nft;

    address public nftContract; 

    address public mintAddress;

    uint [] public storeTokenIds;

    mapping(uint => uint) tokenIdIndex;

    event ERC721Received(address, address, uint256 _tokenId, bytes data);

    function setNFTAddress(address _nft) public onlyOwner {
        nftContract = _nft;
        nft = INFT(nftContract);
    }

    function setMintAddress(address _mintAddress) public onlyOwner {
        mintAddress = _mintAddress;
    }

    function batchTransfer(address from, address to, uint [] memory tokenIds) public {
        require(from != address(this),"Please use Owner Function to transfer");
        for (uint i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(from, to, tokenIds[i]);
        }
    }

    function multiAddressTransfer(address from, address[] memory addresses, uint [] memory tokenIds) public {
        require(addresses.length == tokenIds.length, "addresses' length must be equal with tokenIds' length");
        require(from != address(this),"Please use Owner Function to transfer");
        for (uint i = 0; i < addresses.length; i++) {
            nft.safeTransferFrom(from, addresses[i], tokenIds[i]);
        }
    }

    function multiAddressMultiTransfer(address from, address[] memory addresses, uint [] [] memory tokenIdsList) public {
        require(addresses.length == tokenIdsList.length, "addresses' length must be equal with tokenIds' length");
        require(from != address(this),"Please use Owner Function to transfer");

        for (uint i = 0; i < addresses.length; i++) {
            uint [] memory tokenIds = tokenIdsList[i];
            for (uint j = 0; j < tokenIds.length; j++) {
                nft.safeTransferFrom(from, addresses[i], tokenIds[j]);
            }
        }
    }

    function ownerBatchTransfer(address to, uint [] memory tokenIds) public onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), to, tokenIds[i]);
            _removeTokenId(tokenIds[i]);
        }
    }


    function ownerMultiAddressTransfer(address[] memory addresses, uint [] memory tokenIds) public onlyOwner {
        require(addresses.length == tokenIds.length, "addresses' length must be equal with tokenIds' length");
        for (uint i = 0; i < addresses.length; i++) {
            nft.safeTransferFrom(address(this), addresses[i], tokenIds[i]);
            _removeTokenId(tokenIds[i]);
        }
    }


    function ownerMultiAddressMultiTransfer(address[] memory addresses, uint [] [] memory tokenIdsList) public onlyOwner {
        require(addresses.length == tokenIdsList.length, "addresses' length must be equal with tokenIds' length");
        address from = address(this);
        for (uint i = 0; i < addresses.length; i++) {
            uint [] memory tokenIds = tokenIdsList[i];
            for (uint j = 0; j < tokenIds.length; j++) {
                nft.safeTransferFrom(from, addresses[i], tokenIds[j]);
                _removeTokenId(tokenIds[j]);
            }
        }
    }

    function transfer(address [] calldata receivers, uint[] calldata amounts) public onlyOwner {
        require(receivers.length == amounts.length, "receivers' length must be equal with amounts' length");
        address from = address(this);

        for (uint i = 0; i < receivers.length; i++) {

            require(from != receivers[i],"Cannot transfer to this contract");
            uint [] memory tokenIds = _validTokenIds(amounts[i]);

            for (uint j = 0; j < tokenIds.length; j++) {
                nft.safeTransferFrom(from, receivers[i], tokenIds[j]);
                _removeTokenId(tokenIds[j]);
            }
        }
    }

    function batchMint(string [] memory tokenURIs) public onlyOwner {
        for (uint i = 0; i < tokenURIs.length; i++) {
            nft.safeMint(tokenURIs[i]);
        }
    }

    function mintAndTransfer(string memory tokenURI) public returns (uint){

        require(mintAddress != address(0) && msg.sender == mintAddress,"Permission denied");
        nft.safeMint(tokenURI);
        uint tokenId = storeTokenIds[storeTokenIds.length -1];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        _removeTokenId(tokenId);
        return tokenId;

    }


    function onERC721Received(address operator, address from, uint256 _tokenId, bytes memory data) external virtual override returns (bytes4) {
        require(msg.sender == nftContract, "Permission denied");
        storeTokenIds.push(_tokenId);
        tokenIdIndex[_tokenId] = storeTokenIds.length - 1;
        emit ERC721Received(operator, from, _tokenId, data);
        return this.onERC721Received.selector;
    }

    function transferNFTOwnership(address newOwner) public onlyOwner {
        nft.transferOwnership(newOwner);
    }

    function optimizeStoreTokenIds() public onlyOwner {
        uint amount = nft.balanceOf(address(this));
        uint [] memory validTokenIds = new uint[](amount);
        uint index;
        for (uint i = 0; i < storeTokenIds.length; i++) {
            if (storeTokenIds[i] > 0) {
                validTokenIds[index] = storeTokenIds[i];
                index ++;
            }
        }
        delete storeTokenIds;
        for (uint i = 0; i < validTokenIds.length; i++) {
            storeTokenIds.push(validTokenIds[i]);
            tokenIdIndex[validTokenIds[i]] = i;
        }

    }

    function _removeTokenId(uint _tokenId) internal {
        uint index = tokenIdIndex[_tokenId];
        delete storeTokenIds[index];
        delete tokenIdIndex[_tokenId];
    }

    function _validTokenIds(uint _amount) internal view returns (uint[] memory){
        uint [] memory tokenIds = new uint[](_amount);
        uint index;
        for (uint i = 0; i < storeTokenIds.length; i++) {
            if (storeTokenIds[i] > 0) {
                tokenIds[index] = storeTokenIds[i];
                index = index + 1;
                if (index == _amount) {
                    return tokenIds;
                }
            }
        }
        revert("Insufficient token amount!");

    }

    function resetStoreTokenIds(uint[] memory tokenIds) public onlyOwner {
        delete storeTokenIds;
        for (uint i = 0; i < tokenIds.length; i++) {
            storeTokenIds.push(tokenIds[i]);
            tokenIdIndex[tokenIds[i]] = i;
        }
    }

    function balanceOf() public view returns (uint) {
        return nft.balanceOf(address(this));
    }

    function tokenIdsLength() public view returns (uint) {

        return storeTokenIds.length;
    }

    


}