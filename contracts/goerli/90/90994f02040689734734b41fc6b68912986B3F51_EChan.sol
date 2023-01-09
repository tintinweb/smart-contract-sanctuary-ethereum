// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

//This is an imageboard but without images.
//Inspired by 4Chan
contract EChan
{
    //This mapping creates the structure Boards["Board Name"]["Thread Name"][Post #]
    mapping(string => mapping (string => string[])) public Boards;

    // p_Board: The board you want.
    // p_Thread: The thread you want to post in.
    // p_Post: The text of your post.
    function post(string memory p_Board, string memory p_Thread, string memory p_Post) public
    {
        Boards[p_Board][p_Thread].push(p_Post);
    }
	
    // p_Board: The board you wish to see.
    // p_Thread: The thread to look at.
    // p_Post: The post to begin at.
    // p_Count: How many posts to see.
    function view_Thread(string memory p_Board, string memory p_Thread, uint p_Post, uint p_Count) public view returns (string[] memory)
	{
        //Check to make sure the number of posts specified actually exist.
        if ((p_Post + p_Count) > Boards[p_Board][p_Thread].length)
        {
            //If the number of posts given is too high it will set them to the current limit.
            p_Count = Boards[p_Board][p_Thread].length - p_Post;
        }

        //Setting up and initializing the array used to return the posts to the user.
        string[] memory tmp_Thread = new string[](p_Count);

        //Loop through the posts and add them to the tmp_Thread output variable.
		for (uint cou = 0; cou < p_Count; cou++)
        {
            tmp_Thread[cou] = (Boards[p_Board][p_Thread][cou + p_Post]);
        }

        //Return the thread results.
        return tmp_Thread;
	}
}