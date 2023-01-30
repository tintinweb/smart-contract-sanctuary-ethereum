// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Voting {
    // state variables
    // address public owner;
    // uint fortune;
    // bool deceased;

    // address payable[] familyWallets;
    // mapping (address => uint) inheritance;
	// enum State { Created, Locked, Inactive }  

    struct Voter 
    {
        address delegate; // person delegated to vote
        uint vote;        // index of the voted proposal
        uint weight;      // weight of the voter
        bool voted;       // whether voter has voted or not
    }

    struct Proposal
    {
        bytes32 name;     // short name (up to 32 bytes aka 32 characters)
        uint voteCount;   // number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;


    // events
    // event LogString(string message);

    // constructor
    constructor()
	{
        chairperson = msg.sender;
    }
	
	
	//Modifiers

	modifier onlyChairperson() 
    {
        require(msg.sender == chairperson, "Only the owner can call this function");
        _;
    }


    // functions
    function setChairperson(address newOwner) public onlyChairperson
	{
        chairperson = newOwner;
    }

    function giveRightToVote(address voter) public onlyChairperson
    {
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0, "The voter already has voting rights");
        voters[voter].weight = 1;
    }

    // function addWeightToVoter(address voter, uint weight) public onlyChairperson
    // {
    //     require(!voters[voter].voted, "The voter already voted");
    //     require(voters[voter].weight == 0, "The voter already has voting rights");
    //     voters[voter].weight = weight;
    // }

    //  This function delegates your vote to the voter `to`.
    function delegateTo(address to) public
    {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        Voter storage delegate_ = voters[to]; 

        require(!sender.voted, "You already voted");
        require(to != msg.sender, "Self-delegation is disallowed");
        require(sender.weight != 0, "You have no voting rights");
        require(delegate_.weight != 0, "The delegate has no voting rights");


        // Forward the delegation as long as `to` also delegated.
        // prevents infinite loops in delegation
        // a -> b -> c -> a
        while (delegate_.delegate != address(0)) // 0x0 is the null address
        {
            to = delegate_.delegate;
            require(to != msg.sender, "Found loop in delegation");
        }

        
        sender.voted = true; // The caller is registered as having voted
        sender.delegate = to; // the callers delegate is set to the address of the person they delegated to
        
        

        // If the delegate already voted,
        if (delegate_.voted)
        {
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        }
        // If the delegate did not vote yet,
        else
        {
            // add to delegates weight.
            delegate_.weight += sender.weight;
        }
    }

    // Give your vote (including votes delegated to you)
    function vote(uint proposal) public
    {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted");
        require(sender.weight != 0, "Has no voting rights");
        require(proposal < proposals.length, "Proposal requested does not exist");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }


    
    function addProposal(bytes32 proposalName) public onlyChairperson
    {
        proposals.push(Proposal({
            name: proposalName,
            voteCount: 0
        }));
    }

    // Computes the winning proposal taking all previous votes into account.
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        uint tie = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
                tie = 0;
            } else if (proposals[p].voteCount == winningVoteCount) {
                tie++;
            }
        }
        require(tie == 0, "There is a tie between proposals");
    }

    // function winningProposal() public view returns (uint winningProposal_)
    // {
    //     uint winningVoteCount = 0;
    //     for (uint p = 0; p < proposals.length; p++)
    //     {
    //         if (proposals[p].voteCount > winningVoteCount)
    //         {
    //             winningVoteCount = proposals[p].voteCount;
    //             winningProposal_ = p;
    //         }
    //     }
    // }

    // Calls winningProposal() to get the index of the winner contained in the proposals 
    // array and then returns the name of the winner
    function winnerName() public view returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

    // Returns the total number of proposals
    function getProposalName(uint proposal) public view returns (bytes32 proposalName_)
    {
        proposalName_ = proposals[proposal].name;
    }

    // Returns the total number of proposals
    function getProposalVoteCount(uint proposalIndex) public view returns (uint voteCount_)
    {
        voteCount_ = proposals[proposalIndex].voteCount;
    }

    /*
	function logString(string memory message) public 
	{
        emit LogString(message);
    }
	*/
	
	// function funcName(int _var, string memory _var2) visSpec funcMod1..n modSpec returns(int)
	// {
	// 	...
	// }
}

/*
    Variables

-   `public`: 
	- anyone can get the value of a variable.
-   `external`: 
	- only external functions can get the value of a local variable. It is not used on state variables.
-   `internal`: 
	- only functions in this contract and related contracts can get values.
-   `private`: 
	- access limited to functions from this contract.
*/

/*
    Functions

    public
- visible **everywhere** (within the **contract itself** and **other contracts or addresses**).

- Therefore, it is part of the contract interface (ABI). It can be called internally or via messages.

### private
- visible **only by the contract it is defined in**, not derived contracts.
- These functions are not part of the contract interface (ABI).

### internal
- visible by the contract itself and contracts deriving from it.

- Those functions can be accessed internally, without using `this`. 
- Moreover, they are not part of the contract interface (ABI)

### external
- visible only by external contracts / addresses.

- Like `public` functions, `external` functions are part of the contract interface (ABI).
- However, they canâ€™t be called internally by a function within the contract. For instance, calling `f()` does not work, but call `this.f()` works.

/*

### View vs Pure
- **View** functions can read contractâ€™s storage, but canâ€™t modify the contract storage. 
	- Therefore, they are used for _getters._

- **View** functions do not require any gas in order to be executed if :
	-   It is called _externally_
	-   It is called _internally_ by another `view` function.

- If a **view** function is called _internally_ (within the same contract) from another function **which is not a view function,** it will still cost gas. 

- This is because this other function creates a transaction on the Ethereum blockchain, and will need to be verified by every node on the network.

- **Pure** functions can neither read, nor modify the contractâ€™s storage. 
	- They are used for _pure computation_, like functions that perform mathematic or cryptographic operations.
	
	*/