/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity 0.8.0;

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


interface NFT {
    function ownerOf(uint256 id) external view returns(address);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract QuantumMachine is Context {

    address public metahelmet; 

    event Merge(uint256 indexed tokenId, address indexed nftContract, uint256 indexed nftId);

    event Unmerge(uint256 indexed tokenId);

    constructor(address _metahelmet) {
        metahelmet = _metahelmet;
    }

    function checkTokenOwnership(address nft, address holder, uint256 id) internal view returns(bool) {
        bool success;
        bytes memory data;
        
        /** Check ERC721 */
        (success, data) = nft.staticcall(abi.encodeWithSignature("ownerOf(uint256)", id));
        if (success) {
            address owner = abi.decode(data, (address));
            if (owner == holder) {
                return true;
            }
        } else {
            (success, data) = nft.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", holder, id));
            if (success) {
                uint256 n = abi.decode(data, (uint256));
                if (n > 0) {
                    return true;
                }
            }
        }

        return false;
    }

    function merge(uint256 id, address _contract, uint256 nft) public {
        require(NFT(metahelmet).ownerOf(id) == _msgSender(), "Only owner can merge tokens");
        require(checkTokenOwnership(_contract, _msgSender(), nft), "Only owner can merge tokens");
    
        emit Merge(id, address(_contract), nft);
    }

    function unmerge(uint256 id) public {
        require(NFT(metahelmet).ownerOf(id) == _msgSender(), "Only owner can unmerge tokens");
        emit Unmerge(id);
    }

}