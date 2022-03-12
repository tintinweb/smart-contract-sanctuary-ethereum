// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IEthemeralsLike.sol";

contract EthemeralsBurner is ERC721Holder {

  event MeralBurnt(uint256 tokenId);
  event PropsChange(uint16 burnableLimit, uint16 maxTokenId);

  /*///////////////////////////////////////////////////////////////
                  STORAGE
  //////////////////////////////////////////////////////////////*/

  uint16 public count;
  uint16 public burnableLimit;
  uint16 public maxTokenId;

  address public admin;
  address public burnAddress;

  IEthemeralsLike coreContract;

  /*///////////////////////////////////////////////////////////////
                  ADMIN FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  constructor(address _coreAddress) {
    admin = msg.sender;
    coreContract = IEthemeralsLike(_coreAddress);
  }

  function setProps(uint16 _burnableLimit, uint16 _maxTokenId) external {
    require(msg.sender == admin, 'admin only');
    burnableLimit = _burnableLimit;
    maxTokenId = _maxTokenId;
    emit PropsChange(_burnableLimit, _maxTokenId);
  }

  function setBurnAddress(address _burnAddress) external {
    require(msg.sender == admin, 'admin only');
    burnAddress = _burnAddress;
  }

  function transferCoreOwnership(address newOwner) external {
    require(msg.sender == admin, 'admin only');
    coreContract.transferOwnership(newOwner);
  }

  /*///////////////////////////////////////////////////////////////
                  INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/


  function _mintAdmin(address recipient, uint _amount) internal {
    coreContract.mintMeralsAdmin(recipient, _amount);
  }

  /*///////////////////////////////////////////////////////////////
                  PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
    * @dev user can burn meral for new meral:
    * - sends merals to admin controlled 'burn_address'
    * - subgraph marks meral as burn and removes metadata
    * Requirements:
    * - max burnable not reached
    * - max tokenId not reached (generation)\
    */
  function onERC721Received(
    address,
    address from,
    uint tokenId,
    bytes calldata
  ) public override returns (bytes4) {
    require(count + 1 <= burnableLimit, 'max reached');
    require(tokenId <= maxTokenId, 'max gen');

    count ++;
    _mintAdmin(from, 1);
    coreContract.safeTransferFrom(address(this), burnAddress, tokenId);

    emit MeralBurnt(tokenId);
    return this.onERC721Received.selector;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
interface IEthemeralsLike {
  function maxMeralIndex() external view returns (uint256);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 _tokenId) external view returns (address);
  function transferOwnership(address newOwner) external;
  function mintMeralsAdmin(address recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}