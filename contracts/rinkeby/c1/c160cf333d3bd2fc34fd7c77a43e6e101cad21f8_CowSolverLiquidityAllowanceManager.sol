/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract CowSolverLiquidityAllowanceManager {

    address public constant settlementContract = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
    address public owner;
    address public sender;
    address public allowedOrigin;

    constructor() {
        owner = msg.sender;
    }

    function setAllowedOrigin(address allowedOrigin_) public onlyOwner {
        allowedOrigin = allowedOrigin_;
    }

    function setSender(address sender_) public onlyOwner {
        sender = sender_;
    }

    function send(ERC20 token, uint256 amount) public onlyAllowedOrigin {
        token.transferFrom(sender, settlementContract, amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyAllowedOrigin() {
        require(tx.origin == allowedOrigin, "Only Allowed Origin");
        _;
    }
}