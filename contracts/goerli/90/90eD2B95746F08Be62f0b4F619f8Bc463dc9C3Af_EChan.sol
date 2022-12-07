// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;
 
contract EChan
{
    mapping(string => mapping (string => string[])) public Boards;

    function post(string memory p_Board, string memory p_Thread, string memory p_Post) public
    {
        Boards[p_Board][p_Thread].push(p_Post);
    }
	
	function view_Thread(string memory p_Board, string memory p_Thread, uint p_Post, uint p_Count) public view returns (string[] memory)
	{
        if ((p_Post + p_Count) > Boards[p_Board][p_Thread].length)
        {
            p_Count = Boards[p_Board][p_Thread].length - p_Post;
        }

        string[] memory tmp_Thread = new string[](p_Count);

		for (uint cou = 0; cou < p_Count; cou++)
        {
            tmp_Thread[cou] = (Boards[p_Board][p_Thread][cou + p_Post]);
        }

        return tmp_Thread;
	}
}