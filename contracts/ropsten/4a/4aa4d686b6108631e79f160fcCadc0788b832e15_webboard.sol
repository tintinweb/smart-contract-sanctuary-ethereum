/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity 0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract webboard{
    uint id_counter = 1;
    uint totalVote = 0;
    uint totalPost = 0;
    IERC20 token_interface = IERC20(0x62e272326BCCa4c4F5977FC4025a4A122695F044);

    struct post{
        int voteCount;
        int internalVoteCount;
        address author;
        string hashVerify;
        mapping(address => bool) alrVoted;
    }
    
    post[] webboardDirectory;

    // create post
    function create_post(uint _checkID, string memory _hash) external{
        require(_checkID == id_counter, "Mismatch ID Please try again");
        webboardDirectory.push();
        post storage d = webboardDirectory[id_counter-1];
        d.voteCount = 0;
        d.author = msg.sender;
        d.hashVerify = _hash;
        totalPost +=1;
        id_counter +=1;
    }

    // function to verify data
    function verify(uint _id, string memory _hash) external view returns(bool){
        return compareStrings(_hash,webboardDirectory[_id-1].hashVerify);
    }

    //check owner of the data for delete
    function check_owner(uint _id, address _address) external view returns(bool){
        return (webboardDirectory[_id-1].author == _address ? true: false);
    }

    //increase vote button
    function increaseVote(uint _id) external{
        require(checkVote(_id,msg.sender) == false, "You have already voted");
        webboardDirectory[_id-1].voteCount += 1;
        webboardDirectory[_id-1].internalVoteCount += 1;
        webboardDirectory[_id-1].alrVoted[msg.sender] = true;
        totalVote +=1;
    }

    //decease vote button
    function decreaseVote(uint _id) external {
        require(checkVote(_id, msg.sender) == false, "You have already voted");
        webboardDirectory[_id-1].voteCount -= 1;
        webboardDirectory[_id-1].internalVoteCount -= 1;
        webboardDirectory[_id-1].alrVoted[msg.sender] = true;
        totalVote +=1;
    }

    // check if alr voted
    function checkVote(uint _id, address _address) public view returns(bool){
        return (webboardDirectory[_id-1].alrVoted[_address] == true ? true: false);
    }
    
    //get total vote
    function getVote(uint _id) public view returns(int){
        return (webboardDirectory[_id-1].voteCount);
    }

    function getInternalVote(uint _id) public view returns(int){
        return (webboardDirectory[_id-1].internalVoteCount);
    }

    // aux function for checking string
    function compareStrings(string memory a, string memory b) public view returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    ////////////////////////////////////////// Snapshot part //////////////////////////////////////////

    //reset Vote in 00.00
    function resetVote() public{
        uint countTotalPositiveVote = 0;
        for(uint i = 0; i < totalPost; i++){
            if (webboardDirectory[i].internalVoteCount > 0){
                countTotalPositiveVote += uint(webboardDirectory[i].internalVoteCount);
            }
        }
        for(uint i = 0; i < totalPost; i++){
            uint totalSupply = (token_interface.balanceOf(address(this)));
            if (webboardDirectory[i].internalVoteCount > 0){
                // int reward_percentage = webboardDirectory[i].internalVoteCount/countTotalPositiveVote;
                uint transferAmount = (uint(webboardDirectory[i].internalVoteCount)*totalSupply)/(countTotalPositiveVote * 1000);
                token_interface.transfer(webboardDirectory[i].author, transferAmount);
                webboardDirectory[i].internalVoteCount = 0;
            }
        }
        //reset total vote
        totalVote = 0;
    }

    function checkTotalPositiveVote() public view returns(int){
        int countTotalPositiveVote = 0;
        for(uint i = 0; i < totalPost; i++){
            if (webboardDirectory[i].internalVoteCount > 0){
                countTotalPositiveVote += webboardDirectory[i].internalVoteCount;
            }
        }
        return countTotalPositiveVote;
    }

    function checkReward(uint _id) public view returns(uint){
        int countTotalPositiveVote = 0;
        for(uint i = 0; i < totalPost; i++){
                if (webboardDirectory[i].internalVoteCount > 0){
                    countTotalPositiveVote += webboardDirectory[i].internalVoteCount;
                }
            }
        int totalSupply = int(token_interface.balanceOf(address(this)));
        int reward_percentage = webboardDirectory[_id].internalVoteCount/countTotalPositiveVote;
        return uint(reward_percentage*totalSupply/1000);
    }
    
    function checkTotalSupply() public view returns(int){
        return int(token_interface.balanceOf(address(this)));
    }

    function checkReward3() public view returns(int){
        int countTotalPositiveVote = 0;
        for(uint i = 0; i < totalPost; i++){
                if (webboardDirectory[i].internalVoteCount > 0){
                    countTotalPositiveVote += webboardDirectory[i].internalVoteCount;
                }
            }
        return webboardDirectory[0].internalVoteCount/countTotalPositiveVote;
    }
}