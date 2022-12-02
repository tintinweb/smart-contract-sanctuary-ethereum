/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity >=0.7.0 <0.9.0;

contract RealEstateAgent {

    address public owner;

    mapping(address => uint256) public brojKuca;
    
    constructor() {
        owner = msg.sender;
        brojKuca[address(this)] = 10;
    }

    function kupiKucu() public payable {
    
        require(brojKuca[msg.sender] == 0, "Vec imas kucu");
        require(brojKuca[address(this)] > 0, "Rasprodate kuce");
        require(msg.value >= 0.5 ether, "Niste poslali dovoljno para!");

        brojKuca[address(this)]--;        
        brojKuca[msg.sender]++;
    }

}