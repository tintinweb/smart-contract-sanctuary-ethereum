/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
contract Graffiti{
    /* Buy digital art and get Airdrop
    steps:
       1: took art number, call estimatedPrice()
       2: enter the art number and pay the contract
       3: get your airdrop
       4: our DApp send the art soon to you
          use MetaMask for creating a payment
    */

    address public DApp;
    address public creator;
    address[] public buyer;
    //buyer purchase
    mapping (address => uint) public art;

    uint public balance;
    //buyer discount
    mapping (address => uint) public discount;
    //release flag
    mapping (address => bool) public releaseAirdrop;

    constructor(address _DApp){
        DApp = _DApp;
        creator = msg.sender;
    }

    //event
    event _purchase(address buyer, uint art_number);
    event _airdrop(address buyer);

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }
    
    function estimatedPrice() external view returns(uint){
        uint price = 0.0002 ether - discount[msg.sender];
        return (price);
    }

    function BuyArt(uint art_number) external payable{
        require(msg.value == (0.0002 ether-discount[msg.sender]),'less price');
        art[msg.sender] = art_number;
        buyer.push(msg.sender);
        releaseAirdrop[msg.sender] = true;
        discount[msg.sender] = 0.00005 ether;
        emit _purchase(msg.sender, art_number);
    }

    function AirDrop() external{
        require(releaseAirdrop[msg.sender] == true, 'purchase first');
        uint drop =  0.000098 ether;
        (bool success,) = payable(msg.sender).call{value:drop}("");
        require(success, "transaction failed");
        releaseAirdrop[msg.sender] = false;
        balance -= drop;
        emit _airdrop(msg.sender);
    }

    function BuyerList() external view returns(address[] memory){
        return buyer;
    }

    function chargeAirDrop() onlyCreator external payable{
        require(msg.value > 0, 'zero wei');
        balance += msg.value;
    }

    function withdraw(uint amount) onlyCreator external payable{
        require(address(this).balance > 0, 'contract has no balance');
        bool success = payable(msg.sender).send(amount);
        require(success, "transaction failed");
        balance -= amount;
    }
}