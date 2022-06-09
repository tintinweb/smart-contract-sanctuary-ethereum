/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

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

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

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

interface NFToken721 {
    function mintTokenByMinter(address recipient, uint256 tokenId_) external;
}

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract NFTMinter is Ownable {
    using BytesLibrary for bytes32;

    NFToken721 public nfToken721;
    address public mintSigner;

    constructor(address nfToken721_, address mintSigner_) {
        nfToken721 = NFToken721(nfToken721_);
        mintSigner = mintSigner_;
    }

    function setNFToken721(address nfToken721_) external onlyOwner {
        nfToken721 = NFToken721(nfToken721_);
    }

    function setMintSigner(address mintSigner_) external onlyOwner {
        mintSigner = mintSigner_;
    }

    function recoverSigner(bytes32 messageHash, uint8 sig_v, bytes32 sig_r, bytes32 sig_s) internal pure returns (address) {
        bytes32 _ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(_ethSignedMessageHash, sig_v, sig_r, sig_s);
    }

    function purchaseAndMintWithSignature(address payErc20, uint256 payAmount, uint256[] memory tokenIds_, uint256 timeExpire_, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable {
        require(block.timestamp < timeExpire_, "mint time expired");
        bytes32 tokenIdHash = keccak256(abi.encodePacked(tokenIds_));
        bytes32 messageHash = keccak256(abi.encodePacked(this, _msgSender(), payErc20, payAmount, timeExpire_, tokenIdHash));
        address signerFromMessage = recoverSigner(messageHash, sigV, sigR, sigS);
        require(signerFromMessage == mintSigner, "signature mismatch");
        if (payErc20 == address(0x00)) {
            require(msg.value == payAmount, "Invalid ethereum value");
        }
        else {
            require(msg.value == 0, "Ethereum is not payable");
            require(ERC20(payErc20).allowance(_msgSender(), address(this)) >= payAmount, "ERC20 not approved");
            require(ERC20(payErc20).transferFrom(_msgSender(), address(this), payAmount), "Transfer ERC20 failed");
        }
        for (uint i = 0; i < tokenIds_.length; i++) {
            nfToken721.mintTokenByMinter(_msgSender(), tokenIds_[i]);
        }
    }

    function reclaimEther(uint256 etherAmount, address recipient) public onlyOwner {
        payable(recipient).transfer(etherAmount);
    }

    function reclaimErc20(address tokenAddress, uint256 tokenAmount, address recipient) public onlyOwner {
        ERC20(tokenAddress).transfer(recipient, tokenAmount);
    }
}