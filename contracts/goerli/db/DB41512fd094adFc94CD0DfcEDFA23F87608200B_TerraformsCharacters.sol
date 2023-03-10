// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/access/Ownable.sol";

contract TerraformsCharacters is Ownable {
     
     string[9][92] charsets = [
        [unicode'▆', unicode'▇', unicode'▆', unicode'▇', unicode'▉', unicode'▊', unicode'▋', unicode'█', unicode'▊'],
        [unicode'▚', unicode'▛', unicode'▜', unicode'▙', unicode'▗', unicode'▘', unicode'▝', unicode'▟', unicode'▞'],
        [unicode'▇', unicode'▚', unicode'▚', unicode'▚', unicode'▞', unicode'▞', unicode'▞', unicode'▞', unicode'▇'],
        [unicode'▅', unicode'▂', unicode'▅', unicode'▃', unicode'▂', unicode'▃', unicode'▃', unicode'▂', unicode'▅'],
        [unicode'▅', unicode'▂', unicode'▃', unicode'▃', unicode'▂', unicode'▃', unicode'▃', unicode'▂', unicode'▆'],
        [unicode'█', unicode'▂', unicode'▂', unicode'▂', unicode'▂', unicode'▂', unicode'▂', unicode'▂', unicode'█'],
        [unicode'▂', unicode'█', unicode'▂', unicode'▂', unicode'▂', unicode'▂', unicode'█', unicode'█', unicode'▂'],
        [unicode'█', unicode'▄', unicode'░', unicode'░', unicode'▒', unicode'▓', unicode'▀', unicode'░', unicode'▄'],
        [unicode'▝', unicode'▒', unicode'▛', unicode'▒', unicode'▝', unicode'▅', unicode'░', unicode'░', unicode'▒'],
        [unicode'█', unicode'▓', unicode'░', unicode'░', unicode'▒', unicode'▒', unicode'▒', unicode'▒', unicode'▓'],
        [unicode'▌', unicode'▄', unicode'█', unicode'░', unicode'▒', unicode'▓', unicode'▓', unicode'▀', unicode'▐'],
        [unicode'█', unicode'▌', unicode'▐', unicode'▄', unicode'▀', unicode'░', unicode'▒', unicode'▓', unicode'▓'],
        [unicode'▉', unicode'―', unicode'―', unicode'▉', unicode'―', unicode'―', unicode'―', unicode'―', unicode'▆'],
        [unicode'░', unicode'░', unicode'█', unicode'▄', unicode'▒', unicode'▓', unicode'▀', unicode'░', unicode'▄'],
        [unicode'░', unicode'░', unicode'▒', unicode'▓', unicode'▓', unicode'▒', unicode'▒', unicode'▒', unicode'░'],
        [unicode'⛆', unicode'░', unicode'░', unicode'⛆', unicode'⛆', unicode'⛆', unicode'░', unicode'▒', unicode'▒'],
        [unicode'⛆', unicode'▒', unicode'░', unicode'▓', unicode'▓', unicode'▓', unicode'░', unicode'▒', unicode'⛆'],
        [unicode'⛆', unicode'░', '+', '+', '+', '+', unicode'▒', unicode'▒', unicode'▒'],
        [unicode'█', unicode'╔', unicode'╔', unicode'╣', unicode'═', unicode'╣', unicode'═', unicode'╣', unicode'█'],
        [unicode'╚', unicode'░', unicode'░', unicode'╝', unicode'═', unicode'╣', unicode'═', unicode'═', unicode'╝'],
        [unicode'╝', unicode'═', unicode'╣', unicode'░', unicode'░', unicode'╔', unicode'═', unicode'═', unicode'▒'],
        [unicode'═', unicode'╚', unicode'╔', unicode'⾂', unicode'⾂', unicode'⾂', unicode'═', unicode'╝', unicode'═'],
        [unicode'▒', unicode'🏔', unicode'▒', unicode'☎', unicode'☎', unicode'▒', unicode'🏔', unicode'☆', unicode'░'],
        [unicode'🌧', unicode'🌧', unicode'░', unicode'⾂', unicode'▒', unicode'░', unicode'🏔', unicode'🏔', unicode'🏔'],
        [unicode'🏔', unicode'╣', unicode'╔', unicode'╣', unicode'╚', unicode'═', unicode'╔', unicode'🏔', unicode'🏔'],
        [unicode'🖳', unicode'░', unicode'➫', unicode'⋆', '.', unicode'➫', unicode'░', unicode'░', unicode'🕱'],
        [unicode'🗠', unicode'🗠', unicode'░', unicode'♖', unicode'░', unicode'░', unicode'🗠', unicode'░', unicode'♘'],
        [unicode'🗠', unicode'🗠', unicode'░', unicode'🖳', unicode'░', unicode'🗠', unicode'🗠', unicode'░', unicode'♖'],
        [unicode'🗡', unicode'░', unicode'🗡', unicode'⋆', unicode'🗡', unicode'🗡', unicode'░', unicode'░', unicode'🗡'],
        [unicode'🗡', unicode'░', unicode'🗡', unicode'⋆', unicode'🗡', unicode'⛱', unicode'░', unicode'░', unicode'⛱'],
        [unicode'⛓', unicode'░', unicode'❀', unicode'🗠', unicode'❀', unicode'⛓', unicode'❀', unicode'░', unicode'⛓'],
        [unicode'⛓', unicode'░', unicode'🗡', unicode'🗠', unicode'🗡', unicode'⛓', unicode'➫', unicode'░', unicode'⛓'],
        [unicode'🖳', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'𓆏'],
        [unicode'🖳', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'⛓', unicode'🖳'],
        [unicode'🏔', unicode'█', unicode'█', unicode'╣', unicode'═', unicode'╣', unicode'▄', unicode'█', unicode'🏔'],
        [unicode'🏔', unicode'█', unicode'█', unicode'█', unicode'█', unicode'█', unicode'█', unicode'█', unicode'🏔'],
        [unicode'🏔', unicode'▂', unicode'▅', unicode'▅', unicode'▅', unicode'▂', unicode'▂', unicode'🏔', unicode'🏔'],
        [unicode'🖫', unicode'⛓', unicode'🖫', unicode'█', unicode'█', unicode'█', unicode'🖫', unicode'⛓', unicode'🖫'],
        [unicode'♘', unicode'♜', unicode'▂', unicode'▂', unicode'▂', unicode'♜', unicode'♜', unicode'♜', unicode'♖'],
        [unicode'♜', unicode'♘', ' ', ' ', ' ', unicode'♖', unicode'♖', unicode'♖', unicode'♜'],
        [unicode'❀', unicode'⋮', unicode'⋮', unicode'⋮', unicode'❀', unicode'❀', unicode'⋮', unicode'⋮', unicode'❀'],
        [unicode'⛓', unicode'░', unicode'🕱', unicode'🕱', unicode'🕱', unicode'🕈', unicode'▒', unicode'░', unicode'⛓'],
        [unicode'⛆', unicode'༽', unicode'༼', unicode'༼', unicode'༼', unicode'༼', unicode'༼', unicode'༽', unicode'⛆'],
        [unicode'░', unicode'░', unicode'⋆', unicode'░', '.', unicode'░', unicode'░', unicode'░', unicode'🏠'],
        [unicode'🏠', unicode'⛆', unicode'░', unicode'░', unicode'⛱', unicode'⋰', unicode'⋰', unicode'⋰', unicode'⋰'],
        [unicode'⋮', unicode'⋮', unicode'⋮', unicode'⋮', unicode'⋮', unicode'░', unicode'░', unicode'░', unicode'░'],
        [unicode'❀', '.', '.', unicode'⫯', unicode'⫯', '.', '.', unicode'⫯', unicode'❀'],
        [unicode'⛫', unicode'⛫', unicode'⛫', unicode'⋰', unicode'⋰', unicode'⋰', unicode'⛫', unicode'⛫', unicode'⛫'],
        [unicode'⚑', unicode'⋰', unicode'⋰', unicode'⋰', unicode'⋰', unicode'⋰', unicode'⋰', unicode'⋰', unicode'🏔'],
        [unicode'🏔', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'🏔'],
        [unicode'🕈', unicode'🞗', unicode'🞗', unicode'🞗', unicode'⩎', unicode'⛆', unicode'⍝', unicode'⛆', unicode'⍝'],
        [unicode'⍝', '.', unicode'░', unicode'░', unicode'░', '.', '.', unicode'✗', unicode'⍝'],
        [unicode'⋰', unicode'⋰', unicode'⋮', unicode'⋮', unicode'⋮', unicode'⋯', unicode'⋯', unicode'⋱', unicode'⋱'],
        [unicode'🕱', unicode'🕱', unicode'🀰', unicode'🀰', unicode'🀰', unicode'🀰', unicode'⛓', unicode'⛓', unicode'⛓'],
        [unicode'🕱', unicode'🕱', '0', '0', '1', '1', '0', '0', unicode'🖳'],
        [unicode'𓁹', '.', '.', unicode'⇩', unicode'⇩', '.', '.', unicode'🗁', unicode'🗁'],
        [unicode'⟰', unicode'⋮', unicode'⋮', unicode'⫯', unicode'⋮', unicode'⋮', unicode'⟰', unicode'⟰', unicode'⟰'],
        ['.', '.', '#', '#', '#', '#', '#', '#', unicode'⛫'],
        ['0', '0', '0', '.', '.', '1', '1', '1', '1'],
        [unicode'⌬', unicode'╚', unicode'╔', unicode'╣', unicode'╣', unicode'═', unicode'═', unicode'═', unicode'⌬'],
        [unicode'⎛', unicode'⎛', unicode'░', unicode'░', unicode'░', unicode'░', unicode'░', unicode'⎞', unicode'⎞'],
        [unicode'❀', unicode'⋮', unicode'⋮', unicode'༽', unicode'༽', unicode'⋮', unicode'⋮', unicode'⋮', unicode'❀'],
        [unicode'🗡', unicode'🞗', unicode'🞗', unicode'🞗', unicode'🞗', unicode'𓁹', unicode'𓁹', unicode'𓁹', unicode'🗝'],
        [unicode'⌬', unicode'༼', unicode'༼', unicode'༼', unicode'༼', unicode'༼', unicode'༼', unicode'༼', unicode'⌬'],
        [unicode'⋮', unicode'⋮', unicode'⋮', unicode'⌬', unicode'⌬', unicode'⋮', unicode'⋮', unicode'⋮', unicode'🗝'],
        [unicode'༼', unicode'༼', unicode'༼', unicode'༽', unicode'༽', unicode'༽', unicode'༽', unicode'༽', unicode'༽'],
        [unicode'🖳', unicode'🖳', unicode'🖳', unicode'🞗', unicode'🞗', unicode'🗊', unicode'🗊', unicode'🗊', unicode'🗊'],
        [unicode'✎', unicode'༽', unicode'༽', unicode'༽', unicode'༽', unicode'༽', unicode'༽', unicode'༽', unicode'✎'],
        [unicode'♥', unicode'♡', '.', '.', unicode'🗠', unicode'🗠', '.', '.', unicode'♡'],
        [unicode'🖳', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'🖳', unicode'🖳'],
        [unicode'𓆏', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'═', unicode'🖳', unicode'🖳'],
        [unicode'🖳', unicode'♥', unicode'♥', 'g', 'm', unicode'♥', unicode'♥', unicode'♥', unicode'🖳'],
        [unicode'🖳', unicode'♥', unicode'♥', unicode'城', unicode'城', unicode'♥', unicode'♥', unicode'♥', unicode'🖳'],
        [unicode'𝕺', unicode'𝕺', unicode'𝕺', unicode'🞗', unicode'🞗', unicode'🞗', unicode'𝖃', unicode'𝖃', unicode'𝖃'],
        [unicode'░', unicode'░', unicode'░', unicode'🟣', unicode'🟣', unicode'🟣', unicode'🟣', unicode'🟣', unicode'░'],
        [unicode'지', unicode'지', unicode'지', '-', '-', '-', unicode'역', unicode'역', unicode'역'],
        [unicode'𝕺', unicode'🞗', unicode'🞗', unicode'🞗', unicode'城', unicode'城', unicode'𝖃', unicode'𝖃', unicode'𝖃'],
        [unicode'▧', unicode'═', unicode'═', unicode'▧', unicode'═', unicode'═', unicode'═', unicode'▧', unicode'▧'],
        [unicode'▧', unicode'▧', unicode'⬚', unicode'▧', unicode'⬚', unicode'⬚', unicode'⬚', unicode'▧', unicode'▧'],
        [unicode'▩', unicode'▩', unicode'▧', unicode'🞗', unicode'🞗', unicode'🞗', unicode'🞗', unicode'▧', unicode'▩'],
        [unicode'◩', unicode'◩', unicode'◪', '.', '.', unicode'◩', unicode'◩', unicode'◪', unicode'◪'],
        [unicode'◩', unicode'◪', unicode'◪', unicode'⛆', unicode'⛆', unicode'◩', unicode'◩', unicode'◩', unicode'⛆'],
        [unicode'╳', unicode'╱', unicode'╱', unicode'╱', unicode'╳', unicode'╲', unicode'╲', unicode'╲', unicode'╳'],
        [unicode'🌢', unicode'⚑', unicode'⚑', unicode'⚑', unicode'⚑', unicode'⚑', unicode'⚑', unicode'⚑', unicode'★'],
        ['_', '_', '_', '|', '|', '|', '_', '|', '|'],
        [unicode'♜', unicode'♖', unicode'░', unicode'░', unicode'░', unicode'░', unicode'♘', unicode'♘', unicode'♛'],
        [unicode'🖧', unicode'🞗', unicode'🞗', unicode'🞗', unicode'🞗', unicode'🞗', unicode'🖧', unicode'🗈', unicode'🗈'],
        [unicode'▂', unicode'✗', unicode'✗', unicode'⛆', unicode'⛆', unicode'✗', unicode'✗', unicode'⛆', unicode'▂'],
        ['{', '}', '-', '-', '-', '%', '%', '%', '%'],
        ['0', '.', '.', '.', '-', '^', '.', '.', '/'],
        ['_', '~', '~', '~', '~', '.', '*', unicode'⫯', unicode'❀'],
        [unicode'🟣', unicode'╚', unicode'╔', unicode'╣', unicode'╣', unicode'═', unicode'═', unicode'═', unicode'⛓']
    ];

    uint[92] fontIds = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
        1,
        1,
        1,
        2,
        2,
        1,
        5,
        3,
        3,
        5,
        7,
        4,
        5,
        5,
        5,
        1,
        1,
        2,
        2,
        6,
        6,
        9,
        5,
        9,
        7,
        7,
        7,
        13,
        7,
        7,
        1,
        8,
        7,
        7,
        6,
        6,
        9,
        8,
        8,
        6,
        1,
        6,
        9,
        9,
        9,
        9,
        9,
        10,
        9,
        10,
        10,
        10,
        10,
        10,
        11,
        1,
        11,
        11,
        11,
        11,
        11,
        11,
        11,
        12,
        12,
        13,
        6,
        12,
        12,
        13,
        13,
        13,
        1
    ];

    mapping (uint => string) fonts;

    constructor () Ownable() {
    }

    /// @notice Adds a font (only owner)
    /// @param id The id of the font
    /// @param base64 A base64-encoed font
    function addFont(uint id, string memory base64) public onlyOwner {
        fonts[id] = base64;
    }

    /// @notice Retrieves a font
    /// @param id The font's id
    /// @return A base64 encoded font
    function font(uint id) public view returns (string memory) {
        return fonts[id];
    }

    /// @notice Retrieves a character set
    /// @param index The index of the character set in the above array
    /// @return An array of 9 strings
    /// @return The id of the font associated with the characters
    function characterSet(uint index) 
        public 
        view 
        returns (string[9] memory, uint) 
    {
        return (charsets[index], fontIds[index]);
    }
}