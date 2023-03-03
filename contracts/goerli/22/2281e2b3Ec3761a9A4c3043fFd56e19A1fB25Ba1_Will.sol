// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Percentage {
    // funciton to set a value accordig to the percentage:
    function percentage(
        uint total,
        uint _percentage
    ) internal pure returns (uint) {
        uint all = total * _percentage;
        return all / 100;
    }
}

// SPDX-License-Identifier: MIT
import "./percentage.sol";
pragma solidity ^0.8.17;
// create a will contract
error NotOwner();
error NotInheritor();
error NotAllowed();

contract Will {
    using Percentage for uint;

    // declare a request event :
    event request(string indexed from, uint time);
    // event for withdraw:
    event withdraw(address indexed to, uint value);
    // declare needed variables:
    struct inheritors {
        string inheritor;
        uint balance;
        uint percentage;
    }
    // a struct for requests to withdraw;
    struct requests {
        string inheritor;
        uint requestTime;
    }
    mapping(address => inheritors) Inheritors;
    mapping(address => requests) Requests;
    address[] claims;
    uint percentageAvailable = 100;
    uint balanceAvailableToShare;
    address public immutable owner;
    uint public lockTime;

    // set owner of the contract and lockTime in days;
    constructor(uint _lockTimeInDays) payable {
        owner = msg.sender;
        lockTime = _lockTimeInDays * 24 * 60 * 60;
    }

    // modifier for prove the ownable :
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // modifier to prove inheritor:
    modifier onlyInheritor(address _address) {
        if (Inheritors[_address].balance == 0 || msg.sender != owner)
            revert NotInheritor();
        _;
    }

    // functions to receive funds
    receive() external payable {
        balanceAvailableToShare += msg.value;
    }

    fallback() external payable {
        balanceAvailableToShare += msg.value;
    }

    // function to add inheritors:
    function AddInheritor(
        string memory _name,
        address _address,
        uint _percentage
    ) external onlyOwner {
        uint value = Balance().percentage(_percentage);
        Inheritors[_address] = inheritors(_name, value, _percentage);
        percentageAvailable -= _percentage;
        balanceAvailableToShare -= value;
    }

    // function to change persentage
    function changePercentage(
        address _addressOfInheritor,
        uint _newPercentage
    ) external onlyInheritor(_addressOfInheritor) onlyOwner {
        balanceAvailableToShare += Inheritors[_addressOfInheritor].balance;
        Inheritors[_addressOfInheritor].balance = 0;
        percentageAvailable += Inheritors[_addressOfInheritor].percentage;
        uint value = Balance().percentage(_newPercentage);
        Inheritors[_addressOfInheritor].balance = value;
        balanceAvailableToShare -= value;
        percentageAvailable -= _newPercentage;
    }

    // function allow the owner to withdraw funds:
    function ownerWithdraw(uint _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    // function allow the owner to change lockTime:
    function changeLockTime(uint _newTimeInDays) external onlyOwner {
        lockTime = _newTimeInDays;
    }

    // function allow owner to remove a inheritor
    function deleteInheritor(address _address) external onlyOwner {
        delete Inheritors[_address];
    }

    // function to send a request to withdraw the money :
    // if the owner did not response for 1 year the reqeust will be valid;
    function claim() public onlyInheritor(msg.sender) {
        require(
            Requests[msg.sender].requestTime > block.timestamp + 2592000,
            "You can make one request in a month;"
        );
        claims.push(msg.sender);
        Requests[msg.sender] = requests(
            Inheritors[msg.sender].inheritor,
            block.timestamp
        );
        emit request(Inheritors[msg.sender].inheritor, block.timestamp);
    }

    //function to withdraw the funds:
    function Withdraw() public onlyInheritor(msg.sender) {
        if (Requests[msg.sender].requestTime + lockTime < block.timestamp)
            revert NotAllowed();
        uint amount;
        if (Balance() < Inheritors[msg.sender].balance) {
            payable(msg.sender).transfer(Balance());
            amount = Balance();
        } else {
            payable(msg.sender).transfer(Inheritors[msg.sender].balance);
            amount = Inheritors[msg.sender].balance;
        }
        emit withdraw(msg.sender, amount);
    }

    // function to cancel the requests
    function cancelRequests() external onlyOwner {
        for (uint a = 0; a < claims.length; a++) {
            Requests[claims[a]].requestTime = 0;
        }
    }

    /*#####################################################################################*/

    /* 
    here the read functions 
    */
    // view balance of the smart contract:
    function Balance() public view returns (uint) {
        return address(this).balance;
    }

    // view address smart contract :
    function addressContract() public view returns (address) {
        return address(this);
    }

    // check inheritor:
    function inheritor()
        public
        view
        onlyInheritor(msg.sender)
        returns (inheritors memory)
    {
        return Inheritors[msg.sender];
    }

    // check if there's claims :
    function withdrawRequests() public view returns (uint) {
        return claims.length;
    }

    /*
     */ // Know you can write your 'Will' in a secure way
    /// @author Elhaj
    /// @notice This a Will smart contract that allow any one to choose his inheritons if somthing
    /// happend to him , and it's allow your relatives to withdraw your funds;
}