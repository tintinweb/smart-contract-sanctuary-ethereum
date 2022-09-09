// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

error DiaryError__NotOwner(address writer, string cid);

contract Diary {
    mapping(string => address) cidToWriter;

    event Write(address indexed writer, string cid);
    event Delete(address indexed writer, string cid);

    function writeCid(string calldata cid) external {
        cidToWriter[cid] = msg.sender;
        emit Write(msg.sender, cid);
    }

    function deleteCid(string calldata cid) external {
        if (cidToWriter[cid] != msg.sender) {
            revert DiaryError__NotOwner(msg.sender, cid);
        }
        cidToWriter[cid] = address(0);
    }
}