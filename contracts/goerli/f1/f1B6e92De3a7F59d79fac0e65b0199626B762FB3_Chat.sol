/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Chat{

    string private ERR_NAME_IS_NOT_AVAILABLE = " THE NAME IS NOT AVAILABLE";
    string private ERR_INEXISTENT_ROOM = "THE ROOM DOES NOT EXIST";

    struct Message{
        address _sender;
        string _content;
    }

    struct Room{
        address _owner;
        string _name;
    }

    Room[] private _rooms;
    mapping(string => bool) private _used_names;
    mapping(string => Message[]) private _messages;

    function roomExists(string memory room_name)
        internal
        view
        returns(bool)
    {
        return _used_names[room_name];
    }

    function createRoom(string memory room_name)
        public
    {
        require(!roomExists(room_name), ERR_NAME_IS_NOT_AVAILABLE);
        _rooms.push(Room(address(msg.sender), room_name));
        _used_names[room_name] = true;
    }

    function getRooms()
        public
        view
        returns(Room[] memory)
    {
        return _rooms;
    }

    function sendMessage(string memory room_name, string memory content)
        public
    {
        require(roomExists(room_name), ERR_INEXISTENT_ROOM);
        _messages[room_name].push(Message(address(msg.sender), content));
    }

    function getMessages(string memory room_name)
        public
        view
        returns(Message[] memory)
    {
        return _messages[room_name];
    }

}