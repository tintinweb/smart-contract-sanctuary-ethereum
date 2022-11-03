// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.17;

import "./Ownable.sol";

//Interface for interacting with erc20
interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external returns (uint256);

    function decimals() external returns (uint256);
}

contract SingleTokenMigrate is Ownable {

    address constant OLD_CELL_TOKEN = 0x09757DabaC779e8420b40df0315962Bbc9833C73; //0xf3E1449DDB6b218dA2C9463D4594CEccC8934346;
    address constant  CELL_ERC20_V2 = 0x09c9db537De8ffCf280A717Ab10d0F8Ccb8e7550; //0xd98438889Ae7364c7E2A3540547Fad042FB24642;
    address addrMigrate = 0x9219d3Fa809b0CC3Cbf994eb3db9C4Ab346D90A9;


    mapping (address => uint) private migrationUserBalance;
    mapping (address => uint) public migrationBlock;
    mapping (address => bool) private blocked;

    address[] private nodes;

    modifier onlyNodes() {
        bool confirmation;
        for (uint8 i = 0; i < nodes.length; i++){
            if(nodes[i] == msg.sender){
                confirmation = true;
                break;
            }
        }

        require(confirmation ,"You are not on the list of nodes");
        _;

    }

    event migration(
        address sender,
        uint amount,
        uint blocknum
    );


    function migrateToken(uint amount) external {

        migrationUserBalance[msg.sender] += amount;
        migrationBlock[msg.sender] = block.number + 4;

        IERC20(OLD_CELL_TOKEN).transferFrom(
            msg.sender,
            addrMigrate,
            amount
            );

        emit migration(msg.sender, amount, block.number);

    }

    function claimToken() external {
        require(
            migrationBlock[msg.sender] <= block.number,
            "Wait next block"
            );
        require(!blocked[msg.sender],"Your blocked");
        require(
            migrationUserBalance[msg.sender] > 0,
            "Your need balance");

        IERC20(CELL_ERC20_V2).transfer(
            msg.sender,
            migrationUserBalance[msg.sender]
            );

        delete migrationUserBalance[msg.sender];

    }


    function addNode(address newBridgeNode) external onlyOwner{
        require(newBridgeNode != address(0),"Error address 0");

        nodes.push(newBridgeNode);

    }

    function delNode (uint index) external onlyOwner {
        require(
            index <= nodes.length,
            "Node index cannot be higher than their number"
            ); // index must be less than or equal to array length

        for (uint i = index; i < nodes.length-1; i++){
            nodes[i] = nodes[i+1];

        }

        delete nodes[nodes.length-1];
        nodes.pop();

    }

    function blockUser (address user) external onlyNodes{
        blocked[user] = true;

    }


    function newMigrateAddress(address newMigrateaddr) external onlyOwner{
        require(newMigrateaddr != address(0),"Error zero address");

        addrMigrate = newMigrateaddr;

    }

    function unBlocked(address sender) external onlyOwner{
        require(blocked[sender], "Sender not blocked");

        blocked[sender] = false;

    }

    function delBalance(address sender) external onlyOwner{
        delete migrationUserBalance[sender];
    }


    function balanceMigrate(address sender) public view returns (uint) {
        return migrationUserBalance[sender];

    }

    function seeBridgeNode() public view returns(address[] memory){
        return nodes;

    }


}