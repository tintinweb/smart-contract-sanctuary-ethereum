/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


contract NoteStore {
    event NoteAdded(
        bytes32 id,
        address indexed sender,
        address indexed author,
        bytes32 indexed note,
        uint256 val
    );

    struct Note {
        address sender;
        address author;
        bytes32 note;
        uint256 val;
    }

    mapping(bytes32 => Note) public notes;

    function noteId(address sender, address author, bytes32 note, uint256 val)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, author, note, val));
    }

    function add(address author, bytes32 note) public payable {
        bytes32 id = noteId(msg.sender, author, note, msg.value);
        require(!exists(id), "Note already added");

        notes[id] = Note({sender: msg.sender, author: author, note: note, val: msg.value});

        emit NoteAdded(id, msg.sender, author, note, msg.value);
    }

    function exists(bytes32 id) public view returns (bool) {
        return notes[id].sender != address(0);
    }
}

contract TestUpgrade {
    function upgrade(NoteStore noteStore, bytes32 note) public {
        noteStore.add(msg.sender, note);
    }

    function upgradeWithValue(NoteStore noteStore, bytes32 note) public payable {
        noteStore.add{value: msg.value}(msg.sender, note);
    }
}