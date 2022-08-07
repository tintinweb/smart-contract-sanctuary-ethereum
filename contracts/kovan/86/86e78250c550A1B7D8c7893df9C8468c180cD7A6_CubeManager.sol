// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IController.sol";
import "IBox.sol";

contract CubeManager {

    // controlle contract 
    IController private controller;

    // Box contract
    IBox private box;

    constructor(address _controller, address _box) {
        box = IBox(_box);
        controller = IController(_controller);
        require(controller.isSuperAdmin(msg.sender), "Controller: Only Super Admin can deploy a contract");
    }

    // Set the 'isPanno' of the 'tokenId'
    // Requirements: sender must have a NFTManager role.
    function setIsPanno(uint256 tokenId, bool _isPanno) public {
        require(controller.isNFTManager(msg.sender), "Controller: Only NFTManager can change metadata");
        box.setIsPanno(tokenId, _isPanno);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IController {  
       
    /// @notice Get address of the Seller smart contract.
    function getSellerContract() external view returns (address);

    /// @notice Get address of the BoxNFT smart contract.
    function getBoxContract() external view returns (address);
    
    ///@notice Get address of the Treasure smart contract.
    function getTreasureContract() external view returns (address); 

    ///@notice Get the information if whitelist is active or not.  
    function isWhitelistActive() external returns (bool);

    ///@notice Get the information if address is whitelisted or not. 
    function isAddressWhitelisted(address _address) external view returns (bool);

    ///@notice Get the information if address of token is allowed to recieve.
    function isRecieveTokenAllowed(address _tokenToCheck) external view returns (bool);

    /**
     * @notice Checks if the address is assigned the Super_Admin role.
     * @param _address Address for checking.
     */
    function isSuperAdmin(address _address) external view returns (bool);    

    /**
     * @notice Checks if the address is assigned the TokenManager role.
     * @param _address Address for checking.
     */
    function isTokenManager(address _address) external view returns (bool);

    /**
     * @notice Checks if the address is assigned the NFTManager role.
     * @param _address Address for checking.
     */
    function isNFTManager(address _address) external view returns (bool);       
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBox {

    // Rarity of tokens
    enum RarityTypes{Gold, Silver, Bronze}

    /** 
    * struct that save token metadata
    */ 
    struct TokenMeta{
        string Name;
        string Description;
        uint256 ID;
        string URL;
        RarityTypes Rarity;
        bool isPanno;
    }

    /**
     * @dev Returns the name of the contract.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the contract.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns true, if contract supports interface.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /** 
    * Set the token metadata
    * _name - name of the token
    * _description - desxription of the token.
    * _Id - id of the token.
    * _URL - URL of the token.
    * _rarity - rarity of the token.
    * _isPanno - is a token Panno.
    * Requirements:

    * sender must have a NFTManager role.
    */
    function setMetadata(string memory _name, string memory _description, uint256 _Id, string memory _URL, RarityTypes _rarity, bool _isPanno) external;

    /**
     * @dev Returns the URI of the token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    //Set the 'isPanno' of the 'tokenId'
    // Requirements: sender must be the CubeManager contract.
    function setIsPanno(uint256 tokenId, bool _isPanno) external;

    // Returns the name of the token. 
    function getName(uint256 tokenId) external view returns(string memory);

    // Returns the description of the token. 
    function getDescription(uint256 tokenId) external view returns(string memory);

    // Returns the rarity of the token. 
    function getRarity(uint256 tokenId) external view returns(RarityTypes);

    // Returns the isPanno of the token. 
    function getIsPanno(uint256 tokenId) external view returns(bool);

    /**
     * Mints `tokenId` and transfers it to `to`.
     * Requirements:
     * - sender must be the Seller contract or must have a NFTManager role.
     * 'to' can have only 15 tokens.
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * Emits a {Transfer} event.
     */
    function mint(address to, uint tokenId) external;

    
    /**
    * @notice Initialize all addresses of the smart contracts.  
    * Has to be called immidiatly after deployment only by Super Admin.
    * @param  _cubeManager address of the deployed smart contract CubeManager
    * @param _controller address of the deployed smart contract Controller
    */
    function _initializeSC(address _cubeManager, address _controller) external;

    /**
     * Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * Requirements:
     * - sender must have a NFTManager role.
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) external;

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
     * Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     * Requirements:
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}