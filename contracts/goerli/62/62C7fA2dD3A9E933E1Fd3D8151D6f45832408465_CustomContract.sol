//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

// We import this library to be able to use console.log
// import "hardhat/console.sol";

error CustomContract__NotOwner();
error CustomContract__NotMember();
error CustomContract__PollDoesntExist();
error CustomContract__AlreadyVoted();
error CustomContract__PollIsFinished();
error CustomContract__TransactionFailed();


contract CustomContract {

    struct Poll {
        string name;
        uint8 n;
        uint16[] numOfVotes;
        string[] options;
        mapping(address=>uint8) votes; 
        uint256 expirationTime;
    }
    

    string public name;
    bool public verification;
    address payable public owner;

    mapping (address => bool) public members;
    mapping (address => bool) public verificationWaitlist; 


    uint8 public numOfPols=0;
    Poll[] public polls;

    event Join(address indexed adr);
    event JoinRequest(address indexed adr, string message);

    modifier onlyOwner() {
        if (msg.sender != owner) revert  CustomContract__NotOwner();
        _;
    }

    modifier onlyMembers() {
        if (!members[msg.sender]) revert  CustomContract__NotMember();
        _;
    }


    /*
     * @notice sends requested funds to contract owner
     * @param _verification should new members be verified to join
     */
    constructor(string memory _name, address _owner, bool _verification) {
        owner = payable(_owner);
        name = _name;
        verification = _verification;
    }


    /*
     * @notice sends requested funds to contract owner
     * @param _amount amount of ETH requested
     */
    function withdrawFunds(uint256 _amount) public onlyOwner {
        uint amount = _amount;
        if (address(this).balance < _amount) 
            amount = address(this).balance;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (sent == false) revert CustomContract__TransactionFailed();
    }

    
    /*
     * @notice join if verification is disabled, enter waitlist otherwise
     * @param _message message to verificator that is saved in event
     */
    function join(string memory _message) public {
        if(!verification){
            if(members[msg.sender])
                return;
            members [msg.sender] = true;
            emit Join(msg.sender);
        }
        else {
            if(verificationWaitlist[msg.sender] || members[msg.sender])
                return;
            verificationWaitlist[msg.sender] = true;
            emit JoinRequest(msg.sender,_message);
        }
    }

    /*
     * @notice verification of user in waitlist
     * @param _user address of user that should be verified
     */
    function verify(address _user) public onlyOwner{
        if(!verification)
            return;
        if(verificationWaitlist[_user]){
            delete verificationWaitlist[_user];
            members[_user] = true;
            emit Join(_user);
            return;
        }
    }

    string[] options;

    /*
     * @notice creation of new poll
     * @param _user address of user that should be verified
     */
    function createPoll(string memory _name, string[] memory _options, uint256 _endTimestamp) public onlyOwner{
        if(_endTimestamp<block.timestamp)
            return;
        uint8 n = uint8(_options.length);
        //options = new string[](n);
        uint16[] memory numOfVotes = new uint16[](n);
        polls.push();
        Poll storage poll = polls[numOfPols];
        // for(uint8 i=0;i<n;i++)
        //     poll.options.push(_options[i]);
        poll.options.push("acab");
        poll.name = _name;
        poll.n = n;
        poll.numOfVotes = numOfVotes;
        poll.options = _options;
        poll.expirationTime = _endTimestamp; // = Poll(_name,n,numOfVotes,_options,_endTimestamp);
        numOfPols++;

        // console.log("createPoll");
        // for(uint i = 0;i<n;i++)
        //     console.log(i," ",_options[i]);
    }

    function voteInPoll(uint pollId, uint8 option) public onlyMembers{
        if(pollId>=numOfPols)
            revert CustomContract__PollDoesntExist();
        Poll storage poll = polls[pollId]; 
        if(poll.votes[msg.sender]>0)
            revert CustomContract__AlreadyVoted();
        if(block.timestamp>=poll.expirationTime)
            revert CustomContract__PollIsFinished();
        poll.numOfVotes[option]++;
        poll.votes[msg.sender] = option+1;
    }


    function getPollOptions(uint pollId) public view returns(string[] memory){
        return polls[pollId].options;
    }

    function getPollVotes(uint pollId) public view onlyOwner returns(uint16[] memory){
        return polls[pollId].numOfVotes;
    }


    receive() external payable {}
}