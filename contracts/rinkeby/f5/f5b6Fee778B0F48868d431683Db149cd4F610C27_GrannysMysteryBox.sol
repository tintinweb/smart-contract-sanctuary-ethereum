// SPDX-License-Identifier: MIT
/*****************************************************************************************************************************************************
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@                &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@        @@        [email protected]@@@@@@@@@@@@@@         @         @@                       @@,        @@@@@@@@@,                  @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@        @@@@         @@@@@@@@@@@@@@                   @@                       @@,        @@@@@@@                        @@@@@@@@@@@@
 @@@@@@@@@@@@@@@        @@@@@@         @@@@@@@@@@@@@                   @@                       @@,        @@@@@          (@@@@@@          @@@@@@@@@@@
 @@@@@@@@@@@@@(        @@@@@@@@         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@@         @@@@@@@@@@@         @@@@@@@@@@
 @@@@@@@@@@@@         @@@@@@@@@@         @@@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@&%         @@@@@@@@@
 @@@@@@@@@@@                              @@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@@                                @@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@                                  @@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@                                    @@@@@@@         @@@@@@@@@@@@@@@@@@          @@@@@@@@@.        @@@@         @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
 @@@@@@@         @@@@@@@@@@@@@@@@@@@@         @@@@@@         @@@@@@@@@@@@@@@@@@                 @@,        @@@@@            @@@@@         @@@@@@@@@@@@
 @@@@@@         @@@@@@@@@@@@@@@@@@@@@@         @@@@@         @@@@@@@@@@@@@@@@@@@                @@,        @@@@@@@                         @@@@@@@@@@@
 @@@@@         @@@@@@@@@@@@@@@@@@@@@@@@         @@@@         @@@@@@@@@@@@@@@@@@@@               @@,        @@@@@@@@@@                   @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     (@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*****************************************************************************************************************************************************/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IDispensary {
    function safeMint(address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBurn(address to, uint256 tokenID, uint256 amount) external;
}

interface IHashGenerator {
    function generateHash(uint256 i) external view returns (bytes32);
}

contract GrannysMysteryBox {
    IDispensary private immutable dispensary;
    IHashGenerator private immutable hashGenerator;
    uint256 private immutable burnID;
    uint16[] private maxDroppable;
    uint16[] private dropped;
    uint256[] private tokenIds;
    uint256[] private autoDropTokenIds;
    uint256[] private dropRates;


    constructor(address _dispensary, address _hashGenerator, uint256 _burnID, uint256[] memory _tokenIds, uint256[] memory _autoDropTokenIds, uint256[] memory _dropRates, uint16[] memory _maxDroppable) {
        require(_tokenIds.length == _dropRates.length && _tokenIds.length == _maxDroppable.length, "ARRAY LENGTH MISMATCH");
        uint256 sum = 0;
        for (uint256 i = 0; i < _dropRates.length; i++) {
            sum += _dropRates[i];
        }
        require(sum == 2**256 - 1, "Sum of drop rates does not equal MAX_INT");

        dispensary = IDispensary(_dispensary);
        hashGenerator = IHashGenerator(_hashGenerator);
        burnID = _burnID;
        tokenIds = _tokenIds;
        autoDropTokenIds = _autoDropTokenIds;
        dropRates = _dropRates;
        maxDroppable = _maxDroppable;
        dropped = new uint16[](_tokenIds.length);
    }

    function getNextRandomHash(uint256 seed, uint256 index, uint256 rotation, uint256 hash) internal pure returns (uint256) {
        //Rotates the given hash around the uint256 bytespace given a rotation value
        //XOR with the current value of the hash to get a continuous stream of new values
        unchecked {
            uint256 rotation_mod = ((rotation * index) % 256);
            return (seed << rotation_mod | seed >> (256 - rotation_mod)) ^ hash;
        }
    }


    //Gas optimization: https://0xmacro.com/blog/solidity-gas-optimizations-cheat-sheet/
    function burn(uint16 amount) external {
        require(amount > 0, "You can't burn 0 tokens");
        //burn the token, will only succeed if the msg.sender has a sufficient amount of burnID in their wallet
        dispensary.safeBurn(msg.sender, burnID, amount);


        //Local Variable initialization
        uint16 leftover;
        uint16 delta;
        //Generate the random hash
        uint256 seed = uint256(hashGenerator.generateHash(amount));
        uint256 hash;
        uint256 rotation;

        //SLOAD optimization
        uint16[] memory _dropped = dropped;
        uint16[] memory _maxDroppable = maxDroppable;
        uint16[] memory dropping = new uint16[](_maxDroppable.length);
        uint256[] memory _tokenIds = autoDropTokenIds;
        //Drop all of the tokenIds that have a 100% drop rate
        for (uint256 i = 0; i < _tokenIds.length;) {
            dispensary.safeMint(msg.sender, _tokenIds[i], amount, '');
            unchecked {
                i++;
            }
        }
        _tokenIds = tokenIds;
        uint256[] memory _dropRates = dropRates;


        unchecked {
            //Select which tokenId should be won based off of a given hash from 0 -> uint256_MAX_INT
            for (uint256 j = 0; j < amount; j++) {
                rotation = seed>>((hash % 32) * 8);
                hash = getNextRandomHash(seed, j, rotation, hash);
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (hash <= _dropRates[i]) {
                        dropping[i]++;
                        break;
                    } else {
                        hash -= _dropRates[i];
                    }
                }
            }
            //Mint won tokens, if the tokens won exceeds the maxDroppable then add the remainder to the leftover value
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (dropping[i] > 0) {
                    if (_maxDroppable[i] >= _dropped[i] + dropping[i]) {
                        dispensary.safeMint(msg.sender, _tokenIds[i], dropping[i], '');
                        _dropped[i] += dropping[i];
                    } else {
                        delta = _maxDroppable[i] - _dropped[i];
                        leftover += dropping[i] - delta;
                        if (delta > 0) {
                            dispensary.safeMint(msg.sender, _tokenIds[i], delta, '');
                            _dropped[i] += delta;
                        }
                    }
                }
            }
            //If the leftover value is not zero then assign the leftovers in the priority order of the tokenIds array if possible
            if (leftover > 0) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (_maxDroppable[i] > _dropped[i] && leftover > 0) {
                        if (_maxDroppable[i] >= _dropped[i] + leftover) {
                            dispensary.safeMint(msg.sender, _tokenIds[i], leftover, '');
                            _dropped[i] += leftover;
                            break;
                        } else {
                            delta = _maxDroppable[i] - _dropped[i];
                            dispensary.safeMint(msg.sender, _tokenIds[i], delta, '');
                            leftover -= delta;
                            _dropped[i] += delta;
                        }
                    }
                }
            }
        }
        dropped = _dropped;
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