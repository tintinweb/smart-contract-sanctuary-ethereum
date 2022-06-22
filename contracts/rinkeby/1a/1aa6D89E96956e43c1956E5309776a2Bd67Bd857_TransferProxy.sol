//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */

interface IERC721 is IERC165 {
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mintAndTransfer(address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, string memory _tokenURI, bytes memory data)external returns(uint256);

}

interface IERC1155 is IERC165 {

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    
    
    function mintAndTransfer(address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, uint256 _supply, string memory _tokenURI, uint256 qty, bytes memory data)external returns(uint256);
}

interface IERC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract TransferProxy {

    event operatorChanged(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    address public owner;
    address public operator;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
    */    

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "OperatorRole: caller does not have the Operator role");
        _;
    }

        /** change the OperatorRole from contract creator address to trade contractaddress
            @param _operator :trade address 
        */

    function changeOperator(address _operator) external onlyOwner returns(bool) {
        require(_operator != address(0), "Operator: new operator is the zero address");
        operator = _operator;
        emit operatorChanged(address(0),operator);
        return true;
    }

        /** change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

    function ownerTransfership(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc721mintAndTransfer(IERC721 token, address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, string memory tokenURI, bytes calldata data) external onlyOperator {
        token.mintAndTransfer(from, to, _royaltyAddress, _royaltyfee, tokenURI,data);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 tokenId, uint256 value, bytes calldata data) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId, value, data);
    }

    function erc1155mintAndTransfer(IERC1155 token, address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee , uint256 supply, string memory tokenURI, uint256 qty, bytes calldata data) external onlyOperator {
        token.mintAndTransfer(from, to, _royaltyAddress, _royaltyfee, supply, tokenURI, qty,data);
    }

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }

    function onERC721Received( address, address, uint256, bytes calldata /*data*/) external pure returns(bytes4) {
        return _ERC721_RECEIVED;
    }
    
    function onERC1155Received( address /*operator*/, address /*from*/, uint256 /*id*/, uint256 /*value*/, bytes calldata /*data*/ ) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
}