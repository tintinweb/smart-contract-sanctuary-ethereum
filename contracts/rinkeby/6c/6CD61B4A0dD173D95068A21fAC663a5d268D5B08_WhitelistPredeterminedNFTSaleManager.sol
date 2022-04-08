// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/MerkleProof.sol";
import "./OwnerWithdrawable.sol";
import "../token/erc721/interfaces/IMintable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error InvalidProof();
error SaleIsNotActive();
error InvalidEtherAmount();
error TokenBalanceToLow();
error NotEnoughTokensAllowed();
error UnsupportedERC20TokenUsedAsPayment();

/**
 * @title WhitelistPredeterminedNFTSaleManager
 * @notice Contract for a selling and minting NFTs
 */
contract WhitelistPredeterminedNFTSaleManager is OwnerWithdrawable {
    event SaleCreate(uint256 indexed saleId, bytes32 merkleRoot);
    event NFTClaim(
        uint256 indexed saleId,
        address indexed account,
        uint256 tokenId
    );

    struct Sale {
        mapping(address => uint256) erc20Prices;
        bytes32 merkleRoot;
        uint256 ethPrice;
        //The NFT contract that will be used for minting
        IMintable nftContract;
        address treasuryAddress;
        bool active;
    }

    mapping(uint256 => Sale) public sales;
    uint256 public saleCount;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function createSale(
        IMintable nftContract,
        address treasuryAddress,
        bytes32 merkleRoot,
        uint256 ethPrice,
        address[] memory erc20Addresses,
        uint256[] memory erc20Prices
    ) public onlyOwner {
        saleCount++;

        sales[saleCount].active = true;
        sales[saleCount].merkleRoot = merkleRoot;
        sales[saleCount].nftContract = nftContract;
        sales[saleCount].treasuryAddress = treasuryAddress;
        sales[saleCount].ethPrice = ethPrice;

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            sales[saleCount].erc20Prices[erc20Addresses[i]] = erc20Prices[i];
        }

        emit SaleCreate(saleCount, merkleRoot);
    }

    function endSale(uint256 saleId) public onlyOwner {
        sales[saleId].active = false;
    }

    function buy(
        uint256 saleId,
        uint256 tokenId,
        bytes32[] memory merkleProof,
        address erc20Address
    ) public payable {
        Sale storage sale = sales[saleId];

        if (!sale.active) {
            revert SaleIsNotActive();
        }

        if (erc20Address == address(0)) {
            payWithETH(sale, 1);
        } else {
            payWithERC20(erc20Address, sale, 1);
        }

        verifyAndMint(saleId, sale, merkleProof, tokenId);
    }

    function buyMultiple(
        uint256 saleId,
        uint256[] memory tokenIds,
        bytes32[][] memory merkleProofs,
        address erc20Address
    ) public payable {
        Sale storage sale = sales[saleId];

        if (!sale.active) {
            revert SaleIsNotActive();
        }

        uint256 tokenCount = merkleProofs.length;

        if (erc20Address == address(0)) {
            payWithETH(sale, tokenCount);
        } else {
            payWithERC20(erc20Address, sale, tokenCount);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            bytes32[] memory merkleProof = merkleProofs[i];
            uint256 tokenId = tokenIds[i];

            verifyAndMint(saleId, sale, merkleProof, tokenId);
        }
    }

    function verifyAndMint(
        uint256 saleId,
        Sale storage sale,
        bytes32[] memory merkleProof,
        uint256 tokenId
    ) private {
        verify(sale.merkleRoot, merkleProof, _msgSender(), tokenId);

        address msgSender = _msgSender();

        sale.nftContract.mintById(msgSender, tokenId);

        emit NFTClaim(saleId, msgSender, tokenId);
    }

    function payWithETH(Sale storage sale, uint256 tokenCount) private {
        uint256 amount = sale.ethPrice * tokenCount;
        address paymentRecipient = sale.treasuryAddress;

        //If the treasury address is not specified, the payment is done to the contract itself
        if (paymentRecipient == address(0)) {
            paymentRecipient = address(this);
        }

        if (msg.value != amount) {
            revert InvalidEtherAmount();
        } else {
            //If the recipient is not the contract itself, then redirect the ETH to the recipient
            //Otherwise, it is kept with the contract
            if (paymentRecipient != address(this)) {
                (bool sent, ) = paymentRecipient.call{value: amount}("");

                if (!sent) {
                    revert FailedToSendEther();
                }
            }
        }
    }

    function payWithERC20(
        address erc20Address,
        Sale storage sale,
        uint256 tokenCount
    ) private {
        address paymentRecipient = sale.treasuryAddress;

        //If the treasury address is not specified, the payment is done to the contract itself
        if (paymentRecipient == address(0)) {
            paymentRecipient = address(this);
        }

        //Check if the ERC20 token is allowed as payment
        if (sale.erc20Prices[erc20Address] == 0) {
            revert UnsupportedERC20TokenUsedAsPayment();
        }

        //Get the price of the NFT in the ERC20 token
        uint256 price = sale.erc20Prices[erc20Address];
        uint256 amount = price * tokenCount;

        //Get the ERC20 token used for payment
        IERC20 token = IERC20(erc20Address);

        //Check if the buyer has enough tokens
        uint256 tokenBalance = token.balanceOf(address(_msgSender()));
        if (tokenBalance < amount) {
            revert TokenBalanceToLow();
        }

        //Get the amount of tokens allowed to be spent
        uint256 allowance = token.allowance(msg.sender, address(this));

        //Check if the buyer allowed enough tokens to be used for the payment
        if (allowance < amount) {
            revert NotEnoughTokensAllowed();
        }

        token.transferFrom(msg.sender, paymentRecipient, amount);
    }

    function verify(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        address account,
        uint256 tokenId
    ) private pure {
        bytes32 node = keccak256(abi.encodePacked(account, tokenId));

        bool isValid = MerkleProof.verify(merkleProof, merkleRoot, node);

        if (!isValid) {
            revert InvalidProof();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error FailedToSendEther();

/**
 * @title OwnerWithdrawable
 * @dev Contract where the owner can withdraw eth and erc20 tokens
 */
contract OwnerWithdrawable is Ownable {
    function withdraw(
        address receiver,
        uint256 ethAmount,
        address[] memory erc20Addresses,
        uint256[] memory erc20Amounts
    ) external onlyOwner {
        //If eth amount to withdraw is not zero then withdraw it
        if (ethAmount != 0) {
            (bool sent, ) = receiver.call{value: ethAmount}("");

            if (!sent) {
                revert FailedToSendEther();
            }
        }

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            uint256 amount = erc20Amounts[i];

            IERC20 token = IERC20(erc20Addresses[i]);

            token.approve(receiver, amount);
            token.transfer(receiver, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IMintable
 * Interface for the contracts that delegate minting to other accounts
 */
interface IMintable {

    /**
     * @notice Checks if a given account is a minter
     */
    function isMinter(address account) external view returns (bool);

    /**
     * @dev Set the token ID counter to a specific value
     * @param tokenIdCounter the number of the next token to mint when minting with auto-increment
     */
    function setTokenIdCounter(uint256 tokenIdCounter) external;

    /**
     * @notice Mints a token to a given address
     */
    function mintTo(address to) external;

     /**
     * @notice Mints a token with a given ID to a given address
     */
    function mintById(address to, uint256 tokenId) external;

    /**
     * @notice Mints a token to a given address and sets a tokenURI for that token
     */
    function mintToWithTokenURI(address to, string memory tokenURI) external;

    /**
     * @notice Mints a token with a given ID to a given address and sets a tokenURI for that token
     */
    function mintByIdWithTokenURI(address to, uint256 tokenId, string memory tokenURI) external;

    /**
     * @notice Mints a many tokens to many accounts
     * Can specify a different number of tokens for each account
     */
    function mintMany(address[] memory recipients, uint256[] memory tokenCounts) external;
    
    /**
     * @notice Mints a many tokens to many accounts
     * Can specify a different tokenIds for each account
     */
    function mintManyByIds(address[] memory recipients, uint256[][] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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