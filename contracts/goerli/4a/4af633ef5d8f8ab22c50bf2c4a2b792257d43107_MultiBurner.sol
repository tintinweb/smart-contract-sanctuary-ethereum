// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@openzeppelin/security/Pausable.sol";
import './interface/IERC1155Burnable.sol';

/**
 * @dev Adapted version of Aragon's multi-minter smart contract
 * ref. https://github.com/aragon/aragon-network-token/blob/master/packages/v2/contracts/ANTv2MultiMinter.sol
 * The added feature is that burning can be paused and permission for burning specific ERC1155 id can be
 * granted separately.
 */
contract MultiBurner is Pausable {
    string private constant ERROR_NOT_OWNER = "Not owner";
    string private constant ERROR_NOT_BURNER = "Not burner";

    address public owner;
    IERC1155Burnable public burnable;

    mapping (address => mapping (uint256 => bool)) public canBurn;

    event AddedBurner(address indexed burner, uint256 indexed id);
    event RemovedBurner(address indexed burner, uint256 indexed id);
    event ChangedOwner(address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner, ERROR_NOT_OWNER);
        _;
    }

    modifier onlyBurner(uint256 _id) {
        require(canBurn[msg.sender][_id] || msg.sender == owner, ERROR_NOT_BURNER);
        _;
    }

    constructor(address _owner, IERC1155Burnable _burnable) {
        owner = _owner;
        burnable = _burnable;
    }

    /**
     * @dev Burn amount of tokens from the address for ERC1155 multi-token standard.
     *
     * @param _to Address of token owner.
     * @param _id Token id which is burned.
     * @param _amount Amount of burned tokens.
     */
    function burn(address _to, uint256 _id, uint256 _amount) external whenNotPaused onlyBurner(_id) {
        burnable.burn(_to, _id, _amount);
    }

    /**
     * @dev Mint amount of tokens to the address for ERC1155 multi-token standard.
     *
     * @param _to Address of token owner.
     * @param _ids Token id which is burned.
     * @param _amounts Amount of burned tokens.
     */
    function burnBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts) external whenNotPaused {
        if (msg.sender != owner) {
            for (uint256 _i = 0; _i < _ids.length;) {
                require(canBurn[msg.sender][_ids[_i]], ERROR_NOT_BURNER);

                // An array can't have a total length
                // larger than the max uint256 value.
                unchecked {
                    ++_i;
                }
            }
        }
        burnable.burnBatch(_to, _ids, _amounts);
    }

    /**
     * @dev Enable burning rights for some address.
     *
     * @param _burner Address of a new burner.
     * @param _id Token id which is allowed to burn.
     */
    function addBurner(address _burner, uint256 _id) external onlyOwner {
        canBurn[_burner][_id] = true;
        emit AddedBurner(_burner, _id);
    }

    /**
     * @dev Disable burning rights for some address.
     *
     * @param _burner Address of a current burner.
     */
    function removeBurner(address _burner, uint256 _id) external onlyOwner {
        canBurn[_burner][_id] = false;
        emit RemovedBurner(_burner, _id);
    }

    /**
     * @dev Change address of burner on the token contract.
     *
     * @param _newBurner Address of a new burner contract or wallet.
     */
    function changeBurnableBurner(address _newBurner) onlyOwner external {
        burnable.changeBurner(_newBurner);
    }

    /**
     * @dev Change owner address which can assign the new burners.
     *
     * @param _newOwner Address of a new owner.
     */
    function changeOwner(address _newOwner) onlyOwner external {
        owner = _newOwner;
        emit ChangedOwner(_newOwner);
    }

    /**
     * @dev Pauses all burns.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all burns.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

abstract contract IERC1155Burnable {
    /**
     * @dev ERC1155 which supports burning from multiple addresses.
     *
     * @param _to Address where the newly burned tokens will be allocated.
     * @param _id Id of token to be burned.
     * @param _amount Amount of tokens to be burned.
     */
    function burn(address _to, uint256 _id, uint256 _amount) virtual external;

    /**
     * @dev ERC1155 which supports burning from multiple addresses in a batch.
     *
     * @param _to Address where the newly burned tokens will be allocated.
     * @param _ids Ids of tokens to be burned.
     * @param _amounts Amount of tokens to be burned.
     */
    function burnBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts) virtual external;

    /**
     * @dev Change address of burner on the token contract.
     *
     * @param _newBurner Address of a new burner contract or wallet.
     */
    function changeBurner(address _newBurner) virtual external;
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