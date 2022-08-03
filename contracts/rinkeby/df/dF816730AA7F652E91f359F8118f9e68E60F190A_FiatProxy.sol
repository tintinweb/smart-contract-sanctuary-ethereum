//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// exposing the methods we care about
interface IMaruBandNFT {
  function publicSaleMint(uint256 quantity) external payable;

  function totalSupply() external returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract FiatProxy is Ownable, IERC721Receiver {
  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // bytes4(150b7a023d4804d13e8c85fb27262cb750cf6ba9f9dd3bb30d90f482ceeb4b1f)
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  address public maruNFTContract;
  uint256 public numberOfburntNFTs;
  uint256 public constant PUBLIC_SALE_PRICE = 0.0001 ether;

  event MintAndTransferProxy(
    address indexed minter,
    address indexed receiver,
    uint256 quantity,
    uint256 fromIndex
  );

  constructor(address _maruNFTContract) {
    maruNFTContract = _maruNFTContract;
    numberOfburntNFTs = 0;
  }

  receive() external payable {}

  function setMaruNFTContract(address _maruNFTContract) public onlyOwner {
    maruNFTContract = _maruNFTContract;
  }

  function setNumberOfburntNFTs(uint256 _numberOfburntNFTs) public onlyOwner {
    numberOfburntNFTs = _numberOfburntNFTs;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    // necessary when using safeMint from a contract, otherwise the transaction will revert
    // https://ethereum.stackexchange.com/questions/68461/onerc721recieved-implementation
    return _ERC721_RECEIVED;
  }

  function publicMintAndTransfer(address _to, uint256 _amount)
    external
    payable
  {
    // https://www.quicknode.com/guides/solidity/how-to-call-another-smart-contract-from-your-solidity-code
    // minting the tokens
    IMaruBandNFT(maruNFTContract).publicSaleMint{
      value: _amount * PUBLIC_SALE_PRICE
    }(_amount);
    // note: the Maru contract emits an event but doesn't return the tokenIds minted, so we have to use getTotalSupply() + numberOfburntNFTs guess the tokenIds
    uint256 _lastTokenId = IMaruBandNFT(maruNFTContract).totalSupply() +
      numberOfburntNFTs;

    // transferring the tokens which were just minted
    uint256 j;
    for (j = 0; j != _amount; j++) {
      IMaruBandNFT(maruNFTContract).transferFrom(
        address(this),
        _to,
        _lastTokenId - j
      );
    }

    // emit event success transfered tokens
    emit MintAndTransferProxy(
      msg.sender,
      _to,
      _amount,
      _lastTokenId - _amount + 1
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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