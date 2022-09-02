/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

contract Test {
    address public owner;
    string private secret;

    modifier onlyOwner() {
        require(msg.sender==owner,"onlyOwner");
        _;
    }

    constructor() {
        owner = msg.sender;
        secret="Abracadabra";
    }

    function setSecret(string memory newSecret) public onlyOwner {
        secret = newSecret;
    }
    function getSecret() public view onlyOwner returns(string memory) {
        return secret;
    }
}