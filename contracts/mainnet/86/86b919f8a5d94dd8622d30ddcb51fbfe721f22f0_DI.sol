/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/DI.sol



pragma solidity ^0.8.4;





contract Divergents {
    function totalSupply() public view returns (uint256) {}

    function saleMint (uint[10] calldata mintList) public payable {}

    function charactersRemaining() public view returns (uint16[10] memory) {}

    function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    safeTransferFrom(from, to, tokenId);
  }

}


contract DI is ERC721Holder, Ownable, ReentrancyGuard {

    address public divergentContractAddress; //

    mapping(address => bool) public approvedTeamMinters; // Approved Minters

    uint public discountedMintPrice = 50000000 gwei;
    uint public mintPrice = 70000000 gwei;
    uint public mainContractPrice = 100000000 gwei;
    uint public paymentGasLimit = 5000;

    //Tracked Variables
    bool public isPublicSaleOpen;
    bool public isWhitelistSaleOpen;

    // Key contract functions
    function setIsSaleOpen(bool _publicStatus, bool _whitelistStatus) external {
        require(approvedTeamMinters[msg.sender], "Requester not approved");
        isPublicSaleOpen = _publicStatus;
        isWhitelistSaleOpen = _whitelistStatus;
    }

    function setMintPrice (uint _mintPriceInWei) external {
        require(approvedTeamMinters[msg.sender], "Requester not approved");
        mintPrice = _mintPriceInWei;
    }

    function setDiscountedMintPrice (uint _discMintPriceInWei) external {
        require(approvedTeamMinters[msg.sender], "Requester not approved");
        discountedMintPrice = _discMintPriceInWei;
    }

    function setMainContractPrice (uint _mainContractPriceInWei) external onlyOwner {
        mainContractPrice = _mainContractPriceInWei;
    }


    // Add address to approved team minters
    function addToApprovedTeamMinters(address[] memory _add) external onlyOwner {
        for (uint i = 0; i < _add.length; i++) {
            approvedTeamMinters[_add[i]] = true;
        }
    }

    // Set divergents contract address
    function setDivergentContractAddress(address _contractAddress) external onlyOwner {
        divergentContractAddress = _contractAddress;
    }

    // Fund this contract to make calls to the divergent contract
    function fundContract() external payable {}

    // Receive funds into the wallet
    receive() external payable { }

    // Get balance held in this contract
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // Withdraw specific amount from the balance held in this contract
    function withdrawBalance(uint _amount, address _recipient) external onlyOwner nonReentrant {
        require(_amount <= address(this).balance, "Withdrawal amount more than balance in contract");
        _recipient.call{ value:_amount, gas: 5000 }("");
    }

    // Helper functions

    // Standalone function to get characters remaining
    function charactersRemaining() public view returns (uint16[10] memory divergentCharacters) {
        Divergents divergent = Divergents(divergentContractAddress);
        return divergent.charactersRemaining();
    }

    // Standalone function to get totalSupply
    function totalSupply() public view returns (uint totalRemaining) {
        Divergents divergent = Divergents(divergentContractAddress);
        return divergent.totalSupply();
    }

    // Sum of arrays
    function _sumOfArray (uint[10] memory array) internal pure returns (uint sum) {
        for(uint i = 0; i < array.length; i++) {
            sum = sum + array[i];
        }
    }



    // Standalone transfer function any token held by the contract to another recipient
    function _transferToken(uint _tokenID, address _recipient) internal {
        Divergents divergent = Divergents(divergentContractAddress);
        divergent.safeTransferFrom(address(this), _recipient, _tokenID);
    }

    // Mint call function to be used
    function _mintCall(uint[10] memory _mintList, address _recipient) internal {
        Divergents divergent = Divergents(divergentContractAddress);
        uint _originalTotalMinted = divergent.totalSupply();

        uint _totalBeingMinted = _sumOfArray(_mintList);
        uint _priceToPay =  mainContractPrice * _totalBeingMinted;

        divergent.saleMint{value: _priceToPay}(_mintList);

        uint _newTotalMinted = divergent.totalSupply();

        for (uint m = _originalTotalMinted; m < _newTotalMinted; m++) {
            divergent.safeTransferFrom(address(this), _recipient, m);
        }

    }

    // Safety hatch to withdraw any NFTs stuck in this contract
    function transferUntransferredToken(uint[] calldata _tokenIDs, address _recipient) external {
        require(approvedTeamMinters[msg.sender], "Minter not approved");
        for (uint i; i < _tokenIDs.length; i++) {
            _transferToken (_tokenIDs[i], _recipient);
        }
    }

    // Mint event - tracking total minted and price
    event TotalMinted (uint totalCharactersMinted, uint pricePaid);

    // Minting functions

    // Minting NFTs for team
    function teamMint(uint[10] memory _mintList) public {
        require(approvedTeamMinters[msg.sender], "Minter not approved");

        for (uint256 i; i < 10; i++) {
            if (_mintList[i] != 0 ) {
                uint256[10] memory _mintRound;
                _mintRound[i] = uint256(_mintList[i]);
                _mintCall(_mintRound, msg.sender);
            }
            
        }
    }

    // Mint event - tracking total minted and price
    event AnyGiveawaysFailed (address[] addressesDidNotReceive);

    // Minting NFTs for giveaways
    function giveawayMint(address[] calldata _winners) external {
        require(approvedTeamMinters[msg.sender], "Minter not approved");

        Divergents divergent = Divergents(divergentContractAddress);
        uint16[10] memory charactersRemaining = divergent.charactersRemaining();
        address[] memory giveawayFailedAddresses;

        for (uint w = 0; w < _winners.length; w++) {
            uint[10] memory _mintCharacters;
            bytes32 newRandomSelection = keccak256(abi.encodePacked(block.difficulty, block.coinbase, w));
            uint pickCharacter = uint(newRandomSelection)%10;
            if(charactersRemaining[pickCharacter] > 1) {
                _mintCharacters[pickCharacter] = 1;
                _mintCall(_mintCharacters, _winners[w]);
                charactersRemaining[pickCharacter] = charactersRemaining[pickCharacter] - 1;
            } else {
                giveawayFailedAddresses[w] = (_winners[w]);
            }
        }
        emit AnyGiveawaysFailed(giveawayFailedAddresses);
    }



    // Minting NFTs for public sale
    function saleMint (uint[10] calldata _mintList, bool _approved) public payable nonReentrant {
        require(isPublicSaleOpen, "Public sale not open");
        uint _totalToBeMinted = _sumOfArray(_mintList);
        uint _mintPriceToCharge;

        if (!_approved && isWhitelistSaleOpen) {
            _mintPriceToCharge = mintPrice;
        } else {
            _mintPriceToCharge = discountedMintPrice;
        }

        uint _mintTotalValue = _mintPriceToCharge * _totalToBeMinted;
        require(msg.value >= _mintTotalValue, "Insufficient Payment Received");

        uint _originalSupply = totalSupply();

        if (_totalToBeMinted <= 10) {
            _mintCall(_mintList, msg.sender);

        } else {
            for (uint i; i < 10; i++) {
                if(_mintList[i] != 0) {
                    uint[10] memory _mintRound;
                    _mintRound[i] = uint256(_mintList[i]);
                    _mintCall(_mintRound, msg.sender);
                }
            }
        }

        uint _netNewSupply = totalSupply() - _originalSupply;

        if (_netNewSupply < _totalToBeMinted) {
            uint returnValue = (_totalToBeMinted - _netNewSupply) * _mintPriceToCharge;
            (bool returnSuccess, ) = msg.sender.call{ value:returnValue, gas: paymentGasLimit }("");
            require(returnSuccess, "Return payment failed");
            emit TotalMinted(_netNewSupply, _mintPriceToCharge);
        } else {
            emit TotalMinted(_netNewSupply, _mintPriceToCharge);
        }


    }

    // Everything specific to free mints
    mapping(address => uint) public approvedFreeMints; // Approved Free Mint Recipients

    //Add to approved free minters
    function addRecipients(address[] calldata _recipients, uint[] calldata _amount) external {
        require(approvedTeamMinters[msg.sender], "Address not approved");
        for (uint r ; r < _recipients.length; r++) {
            approvedFreeMints[_recipients[r]] = _amount[r];
        }
    }

    function freeMint() external nonReentrant {
        require(approvedFreeMints[msg.sender] > 0, "No free mints for this addr");

        uint _availableToMint;

        if(approvedFreeMints[msg.sender] <= 10) {
            _availableToMint = approvedFreeMints[msg.sender];
        } else {
            _availableToMint = 10;
        }

        
        uint _originalSupply = totalSupply();

        uint[10] memory _mintCharacters;

        for (uint i; i < _availableToMint; i++ ) {
            bytes32 newRandomSelection = keccak256(abi.encodePacked(block.difficulty, block.coinbase, i));
            uint pickCharacter = uint(newRandomSelection)%10;
            _mintCharacters[pickCharacter] = _mintCharacters[pickCharacter] + 1;
        }

        _mintCall(_mintCharacters, msg.sender);

        uint _newSupply = totalSupply();

        uint _netNewSupply = _newSupply - _originalSupply;

        approvedFreeMints[msg.sender] = approvedFreeMints[msg.sender] - _netNewSupply;

    }




}