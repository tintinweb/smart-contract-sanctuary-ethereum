// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;
 
contract c_Challenge_Submission
{
	bytes32 public Message;

    bytes32 public Answer;

    bool public Solved;
    address public Solver;

    address Owner;

    string[] public Thread;

	constructor() 
	{
        Owner = msg.sender;

        Answer = 0x79c9f0394fce118cd154819ff3098d9fb4620adc241484dfcda7bf3bf8f68021;
        Message = 0x495430676447687063773d3d0000000000000000000000000000000000000000;
	}

    function answer(string memory p_Answer) public
    {
        require (Solved == false);
        
        if ((keccak256(abi.encodePacked(p_Answer)) == Answer))
        { 
            Solved = true; 
            Solver = msg.sender;
        }
    }

	function set_Message(bytes32 p_Message) public 
	{
        require(msg.sender == Owner);
		Message = p_Message;
	}

	function set_Answer(bytes32 p_Answer) public 
	{
        require(msg.sender == Owner);
        Solver = address(0);
        Solved = false;
		Answer = p_Answer;
	}

    function post(string memory p_Post) public
    {
        Thread.push(p_Post);
    }
}