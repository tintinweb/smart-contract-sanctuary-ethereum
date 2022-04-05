/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Merkle_Voter_Dapp_Contract_Final{
    address owner;
    mapping(address => bool) public has_voted_map; //tracks those who have voted
    mapping(string => uint256) public party_vote_counter; // tracks the number of votes recieved by each party
    string public election_winner= "";
    string[] public parties_name_list;
    bytes32 merkle_root=0xf2b3991c182f7f718818ac9aac4242b83415a2bb8447f09e1698575b380dc1a5;
    
    enum ELECTION_STATUS 
    {
        OPEN, CLOSED, CALCULATING_WINNER,ENDED
    }

    ELECTION_STATUS public election_state;
    constructor(){
        owner = msg.sender;
        election_state = ELECTION_STATUS.CLOSED;
        
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not the owner of this contract. Only the owner can call this function");
        _;
    }

    function merkle_verify(bytes32[] memory proof, address leaf,uint index) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(leaf));

        for (uint i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return (hash == merkle_root);
        
    }

    function start_election() external onlyOwner {
        require(election_state == ELECTION_STATUS.CLOSED,"The election is running. This function can only be called when an election is not in progress.");
        election_state = ELECTION_STATUS.OPEN;
    }

    function end_election() external onlyOwner {
        require(election_state == ELECTION_STATUS.OPEN,"The election is not running.");

        election_state = ELECTION_STATUS.CALCULATING_WINNER;
        calculate_winner();

    }

    function calculate_winner() internal {
        //logic to calculate winner

        //assign value to winner

        election_state = ELECTION_STATUS.ENDED;
    }

    function add_party_list(string[] memory parties) external onlyOwner{
        require(election_state == ELECTION_STATUS.CLOSED,"The election is running. This function can only be called when an election is not in progress.");
        uint256 parties_length = parties.length;
        uint256 i=0;
        for(i=0;i<parties_length;i++)
        {
            party_vote_counter[parties[i]] = 1;
            parties_name_list.push(parties[i]);
        }

    }

    function get_winner() public view returns(string memory){
        //if winner has not been calculated yet, this function will return an empty string ie. winner = "";
        return election_winner;
    }
    
    function cast_test_vote_only_owner(string calldata party_name) external onlyOwner{
        party_vote_counter[party_name] += 1;
    }

    function has_not_voted(address voter_address)public view returns(bool){
        return has_voted_map[voter_address] == false;
    }

    function register_vote(address voter_address,string calldata party_name) internal{
        has_voted_map[voter_address] = true;
        party_vote_counter[party_name] +=1;
    }

    function cast_vote(bytes32[] memory proof,uint index,string calldata party_voted_name)external returns(bool){
        bool voter_exists_in_merkle_tree = merkle_verify(proof,msg.sender,index);
        bool not_repeat_voter = has_not_voted(msg.sender);
        
        if(voter_exists_in_merkle_tree==true && not_repeat_voter==true){
            register_vote(msg.sender,party_voted_name);
            return true;
        }
        else{
            return false;
        }
        

    }


}