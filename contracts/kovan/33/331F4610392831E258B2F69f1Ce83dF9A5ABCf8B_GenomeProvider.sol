// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "IGenomeProvider.sol";
import "IRoachNFT.sol";
import "Operators.sol";

contract GenomeProvider is IGenomeProvider, Operators {

    IRoachNFT public roachContract;
    uint constant TRAIT_COUNT = 6;
    uint constant MAX_BONUS = 25;

    struct TraitWeight {
        uint sum;
        uint[] weight;
        uint[] weightMaxBonus;
    }

    mapping(uint => TraitWeight) public traitWeight; // slot -> array of trait weight

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
    }

    function requestGenome(uint tokenId, uint32 traitBonus) external {
        require(msg.sender == address(roachContract), 'Access denied');
        _requestGenome(tokenId, traitBonus);
    }

    function _requestGenome(uint256 _tokenId, uint32 _traitBonus) internal virtual {
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        _onGenomeArrived(_tokenId, randomSeed, _traitBonus);
    }

    function _onGenomeArrived(uint256 _tokenId, uint256 _randomness, uint32 _traitBonus) internal {
        bytes memory genome = _normalizeGenome(_randomness, _traitBonus);
        roachContract.setGenome(_tokenId, genome);
    }

    function setTraitWeight(uint traitType, uint[] calldata _traitWeight, uint[] calldata _traitWeightMaxBonus)
        external onlyOperator
    {
        require(_traitWeight.length < 0xff, 'trait variant count');
        require(_traitWeight.length == _traitWeightMaxBonus.length, 'weight length mismatch');
        uint sum = 0;
        for (uint i = 0; i < _traitWeight.length; i++) {
            sum += _traitWeight[i];
        }
        traitWeight[traitType] = TraitWeight(sum, _traitWeight, _traitWeightMaxBonus);
    }

    function getWeightedRandom(uint traitType, uint randomSeed, uint bonus)
        internal view
        returns (uint choice, uint newRandomSeed)
    {
        TraitWeight storage w = traitWeight[traitType];
        uint div = w.sum * MAX_BONUS;
        uint r = randomSeed % div;
        uint i = 0;
        uint acc = 0;
        while (true) {
            acc += w.weight[i] * (MAX_BONUS - bonus) + (w.weightMaxBonus[i] * bonus);
            if (acc > r) {
                choice = i;
                newRandomSeed = randomSeed / div;
                break;
            }
            i++;
        }
    }

    function _normalizeGenome(uint256 _randomness, uint32 _traitBonus) internal view returns (bytes memory) {
        bytes memory result = new bytes(32);
        result[0] = 0; // version
        for (uint i = 1; i <= TRAIT_COUNT; i++) {
            uint trait;
            (trait, _randomness) = getWeightedRandom(i, _randomness, _traitBonus);
            result[i] = bytes1(uint8(trait));
        }
        for (uint i = TRAIT_COUNT + 1; i < 32; i++) {
            result[i] = bytes1(uint8(_randomness & 0xFF));
            _randomness >>= 8;
        }
        return result; // TODO: traitBonus
    }

}

// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IGenomeProvider {
    function requestGenome(uint tokenId, uint32 traitBonus) external;
}

// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IRoachNFT {

    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance) external;
    function mintGen0(address to, uint32 traitBonus) external;
    function setGenome(uint tokenId, bytes calldata genome) external;

}

// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.8.10;

import "IERC20.sol";
import "Ownable.sol";

contract Operators is Ownable {
    mapping (address=>bool) operatorAddress;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner() == _addr;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || isOwner(_addr);
    }

    function _addOperator(address _newOperator) internal {
        operatorAddress[_newOperator] = true;
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");
        _addOperator(_newOperator);
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    /**
     * @dev Owner can claim any tokens that transferred
     * to this contract address
     */
    function withdrawERC20(IERC20 _tokenContract, address _admin) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_admin, balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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