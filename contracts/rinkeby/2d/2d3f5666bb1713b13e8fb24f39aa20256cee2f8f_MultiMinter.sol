// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@openzeppelin/security/Pausable.sol";
import './interface/IERC1155Mintable.sol';

/**
 * @dev Adapted version of Aragon's multi-minter smart contract
 * ref. https://github.com/aragon/aragon-network-token/blob/master/packages/v2/contracts/ANTv2MultiMinter.sol
 * The added feature is that minting can be paused and permission for minting specific ERC1155 id can be
 * granted separately.
 */
contract MultiMinter is Pausable {
    string private constant ERROR_NOT_OWNER = "Not owner";
    string private constant ERROR_NOT_MINTER = "Not minter";

    address public owner;
    IERC1155Mintable public mintable;

    mapping (address => mapping (uint256 => bool)) public canMint;

    event AddedMinter(address indexed minter, uint256 indexed id);
    event RemovedMinter(address indexed minter, uint256 indexed id);
    event ChangedOwner(address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner, ERROR_NOT_OWNER);
        _;
    }

    modifier onlyMinter(uint256 _id) {
        require(canMint[msg.sender][_id] || msg.sender == owner, ERROR_NOT_MINTER);
        _;
    }

    constructor(address _owner, IERC1155Mintable _mintable) {
        owner = _owner;
        mintable = _mintable;
    }

    /**
     * @dev Mint amount of tokens to the address for ERC1155 multi-token standard.
     *
     * @param _to Address of token reciever.
     * @param _id Token id which is minted.
     * @param _amount Amount of minted tokens.
     * @param _data Metadata.
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external whenNotPaused onlyMinter(_id) {
        mintable.mint(_to, _id, _amount, _data);
    }

    /**
     * @dev Mint amount of tokens to the address for ERC1155 multi-token standard.
     *
     * @param _to Address of token reciever.
     * @param _ids Token id which is minted.
     * @param _amounts Amount of minted tokens.
     * @param _data memory _data.
     */
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external whenNotPaused {
        if (msg.sender != owner) {
            for (uint256 _i = 0; _i < _ids.length;) {
                require(canMint[msg.sender][_ids[_i]], ERROR_NOT_MINTER);

                // An array can't have a total length
                // larger than the max uint256 value.
                unchecked {
                    ++_i;
                }
            }
        }
        mintable.mintBatch(_to, _ids, _amounts, _data);
    }

    /**
     * @dev Enable minting rights for some address.
     *
     * @param _minter Address of a new minter.
     * @param _id Token id which is allowed to mint.
     */
    function addMinter(address _minter, uint256 _id) external onlyOwner {
        canMint[_minter][_id] = true;
        emit AddedMinter(_minter, _id);
    }

    /**
     * @dev Disable minting rights for some address.
     *
     * @param _minter Address of a current minter.
     */
    function removeMinter(address _minter, uint256 _id) external onlyOwner {
        canMint[_minter][_id] = false;
        emit RemovedMinter(_minter, _id);
    }

    /**
     * @dev Change address of minter on the token contract.
     *
     * @param _newMinter Address of a new minter contract or wallet.
     */
    function changeMintableMinter(address _newMinter) onlyOwner external {
        mintable.changeMinter(_newMinter);
    }

    /**
     * @dev Change owner address which can assign the new minters.
     *
     * @param _newOwner Address of a new owner.
     */
    function changeOwner(address _newOwner) onlyOwner external {
        owner = _newOwner;
        emit ChangedOwner(_newOwner);
    }

    /**
     * @dev Pauses all mints.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all mints.
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

abstract contract IERC1155Mintable {
    /**
     * @dev ERC1155 which supports minting from multiple addresses.
     *
     * @param _to Address where the newly minted tokens will be allocated.
     * @param _id Id of token to be minted.
     * @param _amount Amount of tokens to be minted.
     * @param _data Metadata.
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) virtual external;

    /**
     * @dev ERC1155 which supports minting from multiple addresses in a batch.
     *
     * @param _to Address where the newly minted tokens will be allocated.
     * @param _ids Ids of tokens to be minted.
     * @param _amounts Amount of tokens to be minted.
     * @param _data Metadata.
     */
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) virtual external;

    /**
     * @dev Change address of minter on the token contract.
     *
     * @param _newMinter Address of a new minter contract or wallet.
     */
    function changeMinter(address _newMinter) virtual external;

    /**
     * @dev Change address of controller contract which manages whitelists.
     *
     * @param _newController Address of a new controller contract.
     */
    function changeController(address _newController) virtual external;
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