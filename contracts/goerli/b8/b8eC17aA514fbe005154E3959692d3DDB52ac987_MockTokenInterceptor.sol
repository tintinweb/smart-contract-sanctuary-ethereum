// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../interfaces/IBNFT.sol";
import "../interfaces/IBNFTInterceptor.sol";

contract MockTokenInterceptor is IBNFTInterceptor {
  bool public isPreHandleMintCalled;
  bool public isPreHandleBurnCalled;

  event PreHandleMint(address indexed nftAsset, uint256 nftTokenId);
  event PreHandleBurn(address indexed nftAsset, uint256 nftTokenId);

  function resetCallState() public {
    isPreHandleMintCalled = false;
    isPreHandleBurnCalled = false;
  }

  function preHandleMint(address nftAsset, uint256 nftTokenId) public override returns (bool) {
    nftAsset;
    nftTokenId;
    isPreHandleMintCalled = true;
    emit PreHandleMint(nftAsset, nftTokenId);
    return true;
  }

  function preHandleBurn(address nftAsset, uint256 nftTokenId) public override returns (bool) {
    nftAsset;
    nftTokenId;
    isPreHandleBurnCalled = true;
    emit PreHandleBurn(nftAsset, nftTokenId);
    return true;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFT {
  /**
   * @dev Emitted when an bNFT is initialized
   * @param underlyingAsset_ The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset_);

  /**
   * @dev Emitted when the ownership is transferred
   * @param oldOwner The address of the old owner
   * @param newOwner The address of the new owner
   **/
  event OwnershipTransferred(address oldOwner, address newOwner);

  /**
   * @dev Emitted when the claim admin is updated
   * @param oldAdmin The address of the old admin
   * @param newAdmin The address of the new admin
   **/
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the bNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned bNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on flashLoan
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param nftAsset address of the underlying asset of NFT
   * @param tokenId The token id of the asset being flash borrowed
   **/
  event FlashLoan(address indexed target, address indexed initiator, address indexed nftAsset, uint256 tokenId);

  event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

  event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

  event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

  event ExecuteAirdrop(address indexed airdropContract);

  event FlashLoanApprovalForAll(address indexed owner, address indexed operator, bool approved);

  event TokenInterceptorUpdated(address indexed minter, uint256 tokenId, address indexed interceptor, bool approved);

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset_ The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset_,
    string calldata bNftName,
    string calldata bNftSymbol,
    address owner_,
    address claimAdmin_
  ) external;

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Allows smartcontracts to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashLoanReceiver interface
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address receiverAddress,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external;

  /**
   * @dev Approve or remove the flash loan `operator` as an operator for the caller.
   * Operators can call {flashLoan} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   */
  function setFlashLoanApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns if the `operator` is allowed to call flash loan of the assets of `owner`.
   */
  function isFlashLoanApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Add the `interceptor` as an interceptor for the minter.
   * Interceptors will be called when {mint} and {burn} executed for any token owned by the minter.
   *
   */
  function addTokenInterceptor(uint256 tokenId, address interceptor) external;

  /**
   * @dev Delete the `interceptor` as an interceptor for the minter.
   *
   */
  function deleteTokenInterceptor(uint256 tokenId, address interceptor) external;

  /**
   * @dev Returns the interceptors are allowed to be called for the assets of `minter`.
   */
  function getTokenInterceptors(address tokenMinter, uint256 tokenId) external view returns (address[] memory);

  function claimERC20Airdrop(
    address token,
    address to,
    uint256 amount
  ) external;

  function claimERC721Airdrop(
    address token,
    address to,
    uint256[] calldata ids
  ) external;

  function claimERC1155Airdrop(
    address token,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  function executeAirdrop(address airdropContract, bytes calldata airdropParams) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);

  /**
   * @dev Returns the address of the underlying asset.
   */
  function underlyingAsset() external view returns (address);

  /**
   * @dev Returns the contract-level metadata.
   */
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFTInterceptor {
  /**
   * @dev Handles when mint is executed by the owner
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param nftTokenId The token id of the underlying asset of the BNFT
   **/
  function preHandleMint(address nftAsset, uint256 nftTokenId) external returns (bool);

  /**
   * @dev Handles when mint is executed by the owner
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param nftTokenId The token id of the underlying asset of the BNFT
   **/
  function preHandleBurn(address nftAsset, uint256 nftTokenId) external returns (bool);
}