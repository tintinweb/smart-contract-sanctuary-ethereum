// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256 balance);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IGTC {
    function transfer(address recipient, uint256 amount) external;
}

contract GarbageNFTS is Ownable {
    uint256 public fee = 0.002 ether;
    address public feeReceiver = 0xe78D3AFD0649fB489148f154Bf01E72C77EFcfBE;
    address public nftReceiver = 0xe78D3AFD0649fB489148f154Bf01E72C77EFcfBE;
    address public GarbageTrolls = 0xFBD200bbC75600c62CD6603feb6B567D1B22983b;

    function setGarbageTrolls(address _address) external onlyOwner {
        GarbageTrolls = _address;
    }

    function isOwnerOfAllOrApproved(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenTypes
    ) public view returns (bool) {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            IERC721 token = IERC721(_tokenAddresses[i]);
            bool isERC1155 = _tokenTypes[i] == 1;
            bool isApproved = (
                token.isApprovedForAll(msg.sender, address(this))
            );

            if (!isERC1155) {
                if (token.ownerOf(_tokenIds[i]) != msg.sender) {
                    return false;
                }
            } else {
                IERC1155 token1155 = IERC1155(_tokenAddresses[i]);

                if (token1155.balanceOf(msg.sender, _tokenIds[i]) == 0) {
                    return false;
                }
            }

            if (!isApproved) {
                return false;
            }
        }
        return true;
    }

    function dumpNfts(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenTypes
    ) external payable {
        require(
            isOwnerOfAllOrApproved(_tokenAddresses, _tokenIds, _tokenTypes),
            "Not an Owner of an Asset"
        );
        require(msg.value >= fee, "Pay Fee to Proceed");
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            bool isERC1155 = _tokenTypes[i] == 1;
            if (isERC1155) {
                IERC1155 token = IERC1155(_tokenAddresses[i]);
                uint256 balance = token.balanceOf(msg.sender, _tokenIds[i]);
                token.safeTransferFrom(
                    msg.sender,
                    nftReceiver,
                    _tokenIds[i],
                    balance,
                    ""
                );
            } else {
                IERC721 token = IERC721(_tokenAddresses[i]);
                token.transferFrom(msg.sender, nftReceiver, _tokenIds[i]);
            }
        }
        
        IGTC(GarbageTrolls).transfer(msg.sender, 1000000000000000000);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setNftReceiver(address _nftReceiver) external onlyOwner {
        nftReceiver = _nftReceiver;
    }

    function withdraw() external onlyOwner {
        payable(feeReceiver).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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