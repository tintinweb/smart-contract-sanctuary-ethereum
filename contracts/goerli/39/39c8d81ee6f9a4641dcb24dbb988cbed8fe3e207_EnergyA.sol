/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// File: contracts/Proxiable.sol



pragma solidity ^0.8.7;

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
// File: contracts/EnergyA.sol



pragma solidity ^0.8.7;


contract EnergyA is Proxiable {

    uint  constant totalSupply = 10000 ;
    uint public circulatingSupply;
    string constant name  = "Energy";
    string constant symbol = "ERG";
    address owner;

    mapping(address => uint) public _balance;

    function constructorish() public {
        owner = msg.sender;
        mint(10000);

    }

    function _name() public pure returns(string memory){
        return name;
    }

    function _symbol() public pure returns(string memory){
        return symbol;
    }

    function _totalSupply() public pure returns(uint){
        return totalSupply;
    }

    function mint(uint amount) private returns(uint){
        require(owner == msg.sender, "No permission");
        circulatingSupply += amount;  // increase total circulating supply
        require(circulatingSupply <= totalSupply, "totalSupply Exceeded");
        _balance[address(this)] += amount; //increase balance of to
        return amount;

    }

    function transfer(address _to, uint amount) external {
        require(_to != address(0), "Can't tranfer to address zero");
        uint userBalance = _balance[msg.sender];
        require(userBalance >= amount, "insufficient funds");
        _balance[msg.sender] -= amount;
        _balance[_to] += amount;

    }

    function disperse(address receiver, uint256 amount) external {
        require(_balance[address(this)] >= amount);
        _balance[address(this)] -= amount;
        _balance[receiver] += amount;
    }

    function balanceOf(address who) public  view returns (uint){
    return _balance[who];
    }

    function burn(uint256 amount) external view onlyOwner returns (uint) {
        totalSupply - amount;
        return totalSupply;
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    function encode() external pure returns (bytes memory) {
        return abi.encodeWithSignature("constructorish()");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }

}