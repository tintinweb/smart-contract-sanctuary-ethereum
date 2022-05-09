/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

contract Math {
    function Add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function Sub (uint a, uint b) public pure returns (uint c) {
        c = a - b;
        require(b <= a);

    }

    function Mult (uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);

    }

    function Div (uint a, uint b) public pure returns (uint c) {
        c = a / b;
        require(b > 0);

    }

    function Precentage (uint a, uint b) public pure returns (uint c) {
        uint d = a * b;
        c = d / b;
    }
}

contract etherBank is Math{
    mapping(address => uint) eth;
    uint totalEther;

    constructor(){
        totalEther = 0;
    }

    function deposit() public payable returns (bool success) {
        eth[msg.sender] = Add(eth[msg.sender], msg.value);
        totalEther = Add(totalEther, msg.value);
        return true;
    }

    function withdrawl() public payable returns (bool success) {
        require(eth[msg.sender] >= msg.value);
        eth[msg.sender] = Sub(eth[msg.sender], msg.value);
        totalEther = Sub(totalEther, msg.value);
        payable(msg.sender).transfer(msg.value);
        return true;
    }

    function viewAccountBalance() public view returns (uint) {
        return eth[msg.sender];
    }

    function viewTotalContractEther() public view returns (uint){
        return totalEther;
    }

}