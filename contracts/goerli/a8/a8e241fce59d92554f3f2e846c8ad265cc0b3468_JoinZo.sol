/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol



pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: openzeppelin-solidity/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: openzeppelin-solidity/contracts/utils/Context.sol



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

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/JoinZo.sol


pragma solidity ^0.8.0;




interface IERC721Receiver {
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data
    ) external returns (
        bytes4
    );
}

contract ERC721A {
    function mint(
    ) public payable {}
    
    function mintGrant(
        address[] calldata addresses, 
        uint256[] calldata amounts
    ) public {}
    
    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) external {}
    
    function transferOwnership(
        address newOwner
    ) public virtual {}

    function balanceOf(
        address account
    ) public view virtual returns (
        uint256
    ) {}

    function tokenOfOwnerByIndex(
        address owner, 
        uint256 index
    ) public view returns (
        uint256
    ) {}
}


contract JoinZo is IERC721Receiver, Ownable {
    address private signingWallet;
    ERC721A private founderContract;
    uint256 private maxMintCount = 1;
    uint256 private minTokenId = 789;
    uint256 public pricePerMint = 0.25 ether;
    uint256 public mintStart;
    uint256 public tokenMintStart;
    uint256 public publicMintStart;

    uint256[322] private availableTokens;
    mapping(address => uint256) private mintedCount;

    
    constructor(
        address _signingWallet,
        address _founderContract
    ) {
        signingWallet = _signingWallet;
        founderContract = ERC721A(_founderContract);
    }

    function available(
    ) public view returns (
        uint256
    ) {
        return founderContract.balanceOf(
            address(this)
        );
    }
    
    function mintsAllowed(
        address _addr
    ) public view returns (
        uint256
    ) {
        if (mintedCount[_addr] >= maxMintCount) {
            return 0;
        } else {
            return maxMintCount - mintedCount[_addr];
        }
    }

    function mint(
        bytes memory _signature
    ) external payable {
        require(
            mintStart > 0, 
            "mint not started"
        );
        require(
            block.timestamp >= mintStart,
            "Mint not started"
        );
        require(
            verifyMessage(_msgSender(), _signature) == signingWallet,
            "signature mismatch"
        );
        uint256 _availableMints = available();
        uint256 _tokenId = getRandomToken(_availableMints);
        _mint(_tokenId, _availableMints);
    }

    function mintToken(
        uint256 _tokenId,
        bytes memory _signature
    ) external payable {
        require(
            tokenMintStart > 0, 
            "mint not started"
        );
        require(
            block.timestamp >= tokenMintStart,
            "Mint not started"
        );
        require(
            verifyMessage(_msgSender(), _signature) == signingWallet,
            "signature mismatch"
        );
        _mint(_tokenId, available());
    }

    function mintPublic(
    ) external payable {
        require(
            publicMintStart > 0, 
            "mint not started"
        );
        require(
            block.timestamp >= publicMintStart,
            "Mint not started"
        );
        uint256 _availableMints = available();
        uint256 _tokenId = getRandomToken(_availableMints);
        _mint(_tokenId, _availableMints);
    }
    
    function setPricePerMint(
        uint256 _price
    ) external onlyOwner {
        pricePerMint = _price;
    }
    
    function setSigningWallet(
        address _addr
    ) external onlyOwner {
        signingWallet = _addr;
    }
    
    function setMintTime(
        uint256 _timestamp
    ) external onlyOwner {
        mintStart = _timestamp;
    }
    
    function setMaxMintCount(
        uint256 _maxMint
    ) external onlyOwner {
        maxMintCount = _maxMint;
    }
    
    function setMinTokenId(
        uint256 _minTokenId
    ) external onlyOwner {
        minTokenId = _minTokenId;
    }
    
    function setPublicMintTime(
        uint256 _timestamp
    ) external onlyOwner {
        publicMintStart = _timestamp;
    }
    
    function setTokenMintTime(
        uint256 _timestamp
    ) external onlyOwner {
        tokenMintStart = _timestamp;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (
        bytes4
    ) {
        return this.onERC721Received.selector;
    }
    
    function withdrawAmount(
        uint256 _amount
    ) external onlyOwner {
        payable(
            _msgSender()
        ).transfer(
            _amount
        );
    }
    
    function withdrawFounder(
        uint256 _tokenId,
        address _addr
    ) external onlyOwner {
        updateAvailableTokens(_tokenId - minTokenId, available());
        founderContract.transferFrom(
            address(this), 
            _addr, 
            _tokenId
        );
    }
    
    function withdrawAllFounder(
        address _addr
    ) external onlyOwner {
        for (uint256 i = 0; i < available(); i++) {
            uint256 tokenId;
            if (availableTokens[i] == 0) {
                tokenId = i + minTokenId;
            } else {
                tokenId = availableTokens[i] + minTokenId;
            }
            founderContract.transferFrom(
                address(this), 
                _addr, 
                tokenId
            );  
        }
    }

    function getRandomToken(
        uint256 _availableMints
    ) internal returns (
        uint256
    ) {
        uint256 indexToUse = random(_availableMints);
        return updateAvailableTokens(indexToUse, _availableMints);
    }

    function updateAvailableTokens(
        uint256 indexToUse,
        uint256 _availableMints
    ) internal returns (
        uint256
    ) {
        uint256 lastIndex = _availableMints - 1;
        uint256 valAtIndex = availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }
        if (indexToUse != lastIndex) {
            uint256 lastValInArray = availableTokens[lastIndex];
            if (lastValInArray == 0) {
                availableTokens[indexToUse] = lastIndex;
            } else {
                availableTokens[indexToUse] = lastValInArray;
            }
        }
        return result + minTokenId;
    }

    function random(
        uint256 _maxNum
    ) internal view returns (
        uint256
    ) {
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    block.timestamp,
                    block.number,
                    block.coinbase,
                    blockhash(block.number - 1),
                    _maxNum
                )
            )
        ) % _maxNum;
        return randomnumber;
    }

    function splitSignature(
        bytes memory _signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getMessageHash(
        address _addr
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }

    function verifyMessage(
        address _addr, 
        bytes memory _signature
    ) internal pure returns (
        address
    ) {
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                getMessageHash(_addr)
            )
        );
        (bytes32 _r, bytes32 _s, uint8 _v) = splitSignature(_signature);
        address signer = ecrecover(
            prefixedHashMessage, _v, _r, _s
        );
        return signer;
    }

    function _mint(
        uint256 _tokenId,
        uint256 _availableMints
    ) internal {
        require(
            mintsAllowed(_msgSender()) > 0,
            "limit reached"
        );
        require(
            _availableMints > 0,
            "nothing left"
        );
        require(
            msg.value >= pricePerMint,
            "Not enough ETH sent"
        );
        mintedCount[_msgSender()] += 1;
        updateAvailableTokens(_tokenId - minTokenId, _availableMints);
        founderContract.transferFrom(
            address(this), 
            _msgSender(), 
            _tokenId
        );
    }

}