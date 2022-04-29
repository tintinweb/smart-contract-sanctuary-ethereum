/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

//Messenger Contract test, just playing ;) - By gm y td

pragma solidity ^0.8.0;

contract Messenger {
    event Message(
        address _from,
        address _to,
        string _message
    );

    mapping(address => mapping(address => string)) private _messages;
    
    /**
     * @dev Get Message sender      
     */

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

     /**
     * @dev Send message `from`, `to`.
     *
     * Emits an {Message} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function sendMessage(
        address _to,
        string memory _message
    ) public virtual {
        require(_to != address(0), "MESSENGER: SendMessage _to the zero address");
        string memory message = _message;
        _messages[_msgSender()][_to] = message;
        emit Message(_msgSender(), _to, message);
    }

    /**
     * @dev Get messages
     */
    function messages(address from) public view virtual returns (string memory) {
        return _messages[from][_msgSender()];
    }
}