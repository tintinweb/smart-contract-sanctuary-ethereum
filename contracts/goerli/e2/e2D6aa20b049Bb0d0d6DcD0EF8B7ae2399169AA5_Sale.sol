// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Interface/ISpaceCows.sol";

import "./Modules/Whitelisted.sol";
import "./Modules/Random.sol";

contract Sale is Ownable, Whitelisted {
    using Random for Random.Manifest;
    Random.Manifest internal _manifest;

    uint256 public whitelistSalePrice;
    uint256 public publicSalePrice;
    uint256 public maxMintsPerTxn;
    uint256 public maxPresaleMintsPerWallet;
    uint256 public maxTokenSupply;
    uint256 public maxSales;
    uint256 public tribeId;
    uint256 private salesCounter;

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _allowBuys;

    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN
    }
    SaleState public saleState;

    ISpaceCows public spaceCows;

    constructor(
        uint256 _whitelistSalePrice,
        uint256 _publicSalePrice,
        uint256 _maxSupply,
        uint256 _maxMintsPerTxn,
        uint256 _maxPresaleMintsPerWallet,
        uint256 _maxSales,
        uint256 _tribeId
    ) {
        whitelistSalePrice = _whitelistSalePrice;
        publicSalePrice = _publicSalePrice;
        maxTokenSupply = _maxSupply;
        maxMintsPerTxn = _maxMintsPerTxn;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        maxSales = _maxSales;
        salesCounter = 1;
        tribeId = _tribeId;
        _manifest.setup(_maxSupply);

        saleState = SaleState(0);
    }

    /**
    =========================================
    Owner Functions
    @dev these functions can only be called 
        by the owner of contract. some functions
        here are meant only for backup cases.
        separate maxpertxn and maxperwallet for
        max flexibility
    =========================================
    */
    function setWhitelistPrice(uint256 _newPrice) external onlyOwner {
        whitelistSalePrice = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicSalePrice = _newPrice;
    }

    function setMaxTokenSupply(uint256 _newMaxSupply) external onlyOwner {
        maxTokenSupply = _newMaxSupply;
    }

    function setMaxMintsPerTxn(uint256 _newMaxMintsPerTxn) external onlyOwner {
        maxMintsPerTxn = _newMaxMintsPerTxn;
    }

    function setMaxPresaleMintsPerWallet(uint256 _newLimit) external onlyOwner {
        maxPresaleMintsPerWallet = _newLimit;
    }

    function setTribeId(uint256 _newId) external onlyOwner {
        tribeId = _newId;
    }

    function setMaxSale(uint256 _newLimit) external onlyOwner {
        maxSales = _newLimit;
    }

    function resetSalesCounter() external onlyOwner {
        salesCounter = 1;
    }

    function setSpaceCowsAddress(address _newNftContract) external onlyOwner {
        spaceCows = ISpaceCows(_newNftContract);
    }

    function setSaleState(uint256 _state) external onlyOwner {
        saleState = SaleState(_state);
    }

    function setWhitelistRoot(bytes32 _newWhitelistRoot) external onlyOwner {
        _setWhitelistRoot(_newWhitelistRoot);
    }

    function givewayReserved(address _user, uint256 _amount) external onlyOwner {
        uint256 totalSupply = spaceCows.totalSupply();
        require(totalSupply + _amount < maxTokenSupply + 1, "Not enough tokens!");
        
        uint256 index = 0;
        uint256[] memory tmpTokenIds = new uint256[](_amount);
        while (index < _amount) {
            uint256 tokenId = _manifest.draw();
            bool doExists = spaceCows.exists(tokenId);

            if (!doExists) {
                tmpTokenIds[index] = tokenId;
                index++;
            }
        }

        spaceCows.cowMint(_user, tmpTokenIds);
        salesCounter += _amount;
    }

    function withdraw() external onlyOwner {
        uint256 marketingPayment = address(this).balance / 4;
        require(marketingPayment > 0, "Empty balance");
        sendToMarketing(marketingPayment);

        uint256 teamPayment = address(this).balance / 4;
        require(teamPayment > 0, "Empty balance");
        sendToOwners(teamPayment);
    }
    
    /**
    =========================================
    Mint Functions
    @dev these functions are relevant  
        for minting purposes only
    =========================================
    */
    function whitelistPurchase(uint256 numberOfTokens, bytes32[] calldata proof)
    external
    payable
    onlyWhitelisted(msg.sender, address(this), proof) {
        address user = msg.sender;
        uint256 buyAmount = whitelistSalePrice * numberOfTokens;

        require(saleState == SaleState.PRESALE, "Allow list is not active");
        require(numberOfTokens + _allowBuys[user][tribeId][1] < maxPresaleMintsPerWallet + 1, "Exceeded max available to purchase");
        require(getSalesCounter() + numberOfTokens < maxSales + 1, "Purchase would exceed max tokens");
        require(msg.value > buyAmount - 1, "Ether value sent is not correct");

        uint256 index = 0;
        uint256[] memory tmpTokenIds = new uint256[](numberOfTokens);
        while (index < numberOfTokens) {
            uint256 tokenId = _manifest.draw();
            bool doExists = spaceCows.exists(tokenId);

            if (!doExists) {
                tmpTokenIds[index] = tokenId;
                index++;
            }
        }

        spaceCows.cowMint(user, tmpTokenIds);
        _allowBuys[user][tribeId][1] += numberOfTokens;
        salesCounter += numberOfTokens;
    }

    function publicPurchase(uint256 numberOfTokens)
    external
    payable {
        address user = msg.sender;
        uint256 buyAmount = publicSalePrice * numberOfTokens;

        require(saleState == SaleState.OPEN, "Sale must be active to mint tokens");
        require(numberOfTokens + _allowBuys[user][tribeId][2] < maxMintsPerTxn + 1, "Exceeded max available to purchase");
        require(getSalesCounter() + numberOfTokens < maxSales + 1, "Purchase would exceed max tokens");
        require(msg.value > buyAmount - 1, "Ether value sent is not correct");

        uint256 index = 0;
        uint256[] memory tmpTokenIds = new uint256[](numberOfTokens);
        while (index < numberOfTokens) {
            uint256 tokenId = _manifest.draw();
            bool doExists = spaceCows.exists(tokenId);

            if (!doExists) {
                tmpTokenIds[index] = tokenId;
                index++;
            }
        }

        spaceCows.cowMint(user, tmpTokenIds);
        _allowBuys[user][tribeId][2] += numberOfTokens;
        salesCounter += numberOfTokens;
    }

    /**
    ============================================
    Public & External Functions
    @dev functions that can be called by anyone
    ============================================
    */
    function remaining() public view returns (uint256) {
        return _manifest.remaining();
    }

    function getSaleState() public view returns (uint256) {
        return uint256(saleState);
    }

    function getSalesCounter() public view returns (uint256) {
        return salesCounter - 1;
    }

    function getAllowPublicPurchase(address _user) public view returns (uint256) {
        return maxMintsPerTxn - _allowBuys[_user][tribeId][2];
    }

    function getAllowWhitelistPurchase(address _user) public view returns (uint256) {
        return maxPresaleMintsPerWallet - _allowBuys[_user][tribeId][1];
    }

    /**
    ============================================
    Internal Functions
    @dev functions that can be use inside the contract
    ============================================
    */
    function sendToMarketing(uint256 payment) internal {
        sendValue(payable(0x12691AEd0668A44411066C518B4DAE6fd3E8F274), payment);
    } 

    function sendToOwners(uint256 payment) internal {
        sendValue(payable(0xced6ACCbEbF5cb8BD23e2B2E8B49C78471FaAe20), payment);
        sendValue(payable(0x4386103c101ce063C668B304AD06621d6DEF59c9), payment);
        sendValue(payable(0x19Bb04164f17FF2136A1768aA4ed22cb7f1dAa00), payment);
        sendValue(payable(0x910040fA04518c7D166e783DB427Af74BE320Ac7), payment);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
pragma solidity 0.8.13;

interface ISpaceCows {
    function totalSupply() external view returns(uint256);
	function getMintingRate(address _address) external view returns(uint256);
    function cowMint(address _user, uint256[] memory _tokenId) external;
    function exists(uint256 _tokenId) external view returns(bool);
    function balanceOf(address owner) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelisted {
    bytes32 private _whitelistRoot;

    modifier onlyWhitelisted(address _user, address _contract, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(_user, _contract));

        require(MerkleProof.verify(merkleProof, _whitelistRoot, node), "You are not whitelisted!");
        _;
    }

    function _setWhitelistRoot(bytes32 root) internal {
        _whitelistRoot = root;
    }

    function getWhitelistRoot() public view returns (bytes32) {
        return _whitelistRoot;
    }

    function isWhitelisted(bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, address(this)));
        if (MerkleProof.verify(merkleProof, _whitelistRoot, node)) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, "Can't setup empty");
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;

        uint256 dl = data.length;
        uint256 di = uint256(seed) % dl;
        uint256 dx = data[di];
        uint256 dy = data[--dl];
        if (dx == 0) { dx = di + 1;   }
        if (dy == 0) { dy = dl + 1;   }
        if (di != dl) { data[di] = dy; }
        data.pop();
        return dx;
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}