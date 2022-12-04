pragma solidity ^0.8.0;

// We import this library to be able to use console.log

// error CustomContract__NotOwner();
// error CustomContract__TransactionFailed();


contract CustomContract {

    string public name;
    bool public verification;
    mapping (address => bool) public members;
    mapping (address => bool) public verificationWaitlist; 

    address payable public owner;

    event Join(address indexed adr);
    event JoinRequest(address indexed adr, string message);

    modifier onlyOwner() {
        // if (msg.sender != owner) revert  CustomContract__NotOwner();
        if (msg.sender != owner) revert();

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
        // if (sent == false) revert CustomContract__TransactionFailed();
        if (sent == false) revert();
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




    receive() external payable {}
}