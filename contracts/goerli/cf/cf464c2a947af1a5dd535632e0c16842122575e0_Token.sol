/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity 0.8.9;


contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }

}

contract Token is Proxiable {
    uint256 TotalSupply;
    string TokenName;
    string TokenSymbol;
    bool public initialized;
    address public owner;


    mapping(address => uint256) balances;
    //Approver to aprovee to amount approved
    mapping(address => mapping(address => uint256)) Approve;  

    function initialize() public{
        require(!initialized, "Contract already initialized");
        initialized = true;
        TokenName = "firstToken";
        TokenSymbol = "FST";
        TotalSupply = 2000 * (10**18);
        mint(0x924843c0c1105b542c7e637605f95F40FD07b4B0);
        owner = msg.sender;
    }

    function ConstructData() public pure returns(bytes memory data ){
        data = abi.encodeWithSignature("initialize()");
    }


    function mint(address _addr) internal {
        balances[_addr] += TotalSupply;
    }
    function balanceOf(address _addr) public view returns(uint256){
       return balances[_addr];
    } 
    function transfer(address _address, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient Fund");
        balances[msg.sender] -= amount;
        balances[_address] += amount;
    }

    function approve(address to, uint256 amount) public{
        require(balanceOf(msg.sender) >= amount, "You can't approve what you don't have");
        Approve[msg.sender][to] = amount;
    }

    function TransferFrom(address from, address to, uint256 amount) public {
        uint256 initBal = Approve[from][to];
        require(initBal >= amount, "Amount not approved");
        Approve[from][to] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
    }

    function allowance(address _addr) public view returns(uint256){
        return(Approve[msg.sender][_addr]);
    }

    function upgradeable(address _newAddress) public {
        require(msg.sender == owner, "You are not allowed to upgrade");
        updateCodeAddress(_newAddress);
    }

}