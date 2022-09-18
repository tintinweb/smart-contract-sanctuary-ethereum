/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// File: contracts/Proxiable.sol



pragma solidity >=0.7.0 <0.9.0;

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
// File: contracts/ERC20.sol



pragma solidity >=0.7.0 <0.9.0;


contract unitedToken is Proxiable{

    uint public totalSupply;
    string public name = "unitedToken";
    string public symbol = "UNT";
    uint8 public decimals = 18;
    address public owner;
    bool public initalized = false;

    mapping(address => uint) public balanceOf;

    function initialize() public {
    require(owner == address(0), "Already initalized");
    require(!initalized, "Already initalized");
    owner = msg.sender;
    initalized = true;
    }
    
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        
    }


    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "not owner");
        _;
    }
}