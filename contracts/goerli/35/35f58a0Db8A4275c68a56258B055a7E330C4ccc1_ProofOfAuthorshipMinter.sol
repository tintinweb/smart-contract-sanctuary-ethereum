// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io
// Proof of authorship burner contract

pragma solidity ^0.8.17;

import "./Ownable.sol";

interface AuthorshipContract {
    function newAuthorshipToken(
        uint256 _assetTokenId,
        bytes32 _authorsMerkleRoot,
        address _assetContract,
        address _authorWallet,
        string calldata _contentIdentifier,
        string calldata _authorName,
        string calldata _license,
        string memory _tokenUri) external payable;

    function coauthorMint(
        address _coauthor,
        uint256 _tokenId,
        bytes32[] calldata _proof) external payable;
}

interface PioneerPassContract {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract ProofOfAuthorshipMinter is Ownable {
    AuthorshipContract public authorshipContract;
    PioneerPassContract public pioneerPassContract;
    uint8 maxPassId;

    function setAuthorshipContract(address foo) external onlyOwner {
        authorshipContract = AuthorshipContract(foo);
    }

    function setPioneerPass(address bar) external onlyOwner {
        pioneerPassContract = PioneerPassContract(bar);
    }

    function setMaxPassId(uint8 baz) external onlyOwner {
        maxPassId = baz + 1;
    }

    function verifyAuthTokenRequiredAssets(address wallet) public view returns (bool){
        bool a;
        for (uint foo = 2; foo < maxPassId; foo++) {
            a = pioneerPassContract.balanceOf(wallet, foo) != 0 ? true : false;
            if (a) {
                return true;
            }
        }
        return false;
    }

    function mintFreeAuthToken(
        uint256 _assetTokenId,
        bytes32 _authorsMerkleRoot,
        address _assetContract,
        address _authorWallet,
        string calldata _contentIdentifier,
        string calldata _authorName,
        string calldata _license,
        string memory _tokenUri
    ) external payable {
        require(_authorWallet == msg.sender, "Wrong wallet");
        require(verifyAuthTokenRequiredAssets(msg.sender), "Not owner of required 1CU tokens");
        authorshipContract.newAuthorshipToken(
            _assetTokenId,
            _authorsMerkleRoot,
            _assetContract,
            _authorWallet,
            _contentIdentifier,
            _authorName,
            _license,
            _tokenUri
        );
    }

    function coauthorMintFreeAuthToken(
        uint256 _tokenId,
        bytes32[] calldata _proof) external payable {
        authorshipContract.coauthorMint(msg.sender, _tokenId, _proof);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import "./Context.sol";

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

pragma solidity ^0.8.17;

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