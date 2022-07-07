/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity ^0.8.0;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}





            



pragma solidity ^0.8.0;




interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}





            



pragma solidity ^0.8.0;




interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
}





            



pragma solidity ^0.8.0;




interface IERC721Enumerable is IERC721 {
    
    function totalSupply() external view returns (uint256);

    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    
    function tokenByIndex(uint256 index) external view returns (uint256);
}




pragma solidity ^0.8.0;




contract NFTScanner {
	function getAllTokenId(address nftAddress,address user) external view returns(uint[] memory,string[] memory){
		IERC721Enumerable nft = IERC721Enumerable(nftAddress);
		uint totalSupply = nft.totalSupply();
		uint balance = nft.balanceOf(user);
		uint[] memory tokenIds = new uint[](balance);
		string[] memory uriList = new string[](balance);
		uint index = 0;
		for(uint i = 0; i < totalSupply; i++){
			try nft.tokenOfOwnerByIndex(user, i) returns(uint tokenId){
				string memory tokenUri = IERC721Metadata(nftAddress).tokenURI(tokenId);
				tokenIds[index] = tokenId;
				uriList[index] = tokenUri;
				index++;
			}catch {
			}	
		}
		return (tokenIds,uriList);
	}
}