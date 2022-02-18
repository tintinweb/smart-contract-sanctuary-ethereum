/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
 * @title Jaap_Tick 
 * @dev tick tack toe in a contract, the ultimate waste of resources!
 */
contract Jaap_Tick {

    string[9] board = ["_", "_", "_", "_", "_", "_", "_", "_", "_"];


    /**
     * @dev make a move on a board as player "x" or "o".
     */
    function set(string memory player, uint256 position) public returns (string memory) {
        if (compareStrings(player, "x") || compareStrings(player, "o") && position >= 0 && position<= 8 && compareStrings(board[position], "_")) {
            board[position] = player;
        }
        return get_board();
    }
    /**
     * @dev resets the board
     */
    function reset() public {
        board = ["_", "_", "_", "_", "_", "_", "_", "_", "_"];
    }
    
    /**
     * @dev Return value 
     * @return pretty print board
     */
    function get_board() public view returns (string memory){
        return sc(sc(sc(sc(board[0], " ",board[1]
        , " ", board[2]), "\n", board[3], " ", board[4]),
        " ", board[5], "\n", board[6]), 
        " ", board[7], " ", board[8]);
    }

    function ai_move(string memory player) public returns (string memory){
        if (compareStrings(player, "x") || compareStrings(player, "o")) {
            for (uint256 i=0; i <=8; i++) {
                if (compareStrings(board[i], "_")) {
                    board[i] = player;
                    return get_board();
                }
            }
        }
        return get_board();

    }

    function sc(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}