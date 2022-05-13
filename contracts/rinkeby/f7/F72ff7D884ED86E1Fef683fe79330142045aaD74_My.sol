/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

contract My {

    mapping(address => Cesur) addressesToFund;

    struct Cesur {
        string message;
        uint256 amount;
    }


    function fund(string memory _message) public payable {
        Cesur memory cesur = addressesToFund[msg.sender];
        if (cesur.amount == 0) {
            cesur = Cesur(_message, 0);
        }
        cesur.message = _message;  
        cesur.amount += msg.value;
        addressesToFund[msg.sender] = cesur;
    }

    function myCesur() public view returns (Cesur memory) {
        return addressesToFund[msg.sender];
    }

}