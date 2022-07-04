// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

contract Stakeholder {
    address public owner;

    // 1 - spadnie, 2 - wzrosnie, 3 - utrzyma sie
    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => uint256) public addressToObstawienie;
    mapping(address => uint256) public addressToMnoznik;
    address[] public funders;

    constructor(){
        owner = msg.sender;
    }

    function storeObstawienieMnoznik(uint256 _obstawienie, uint256 _mnoznik) public{
        require(
            _obstawienie == 1 || _obstawienie == 2 || _obstawienie == 3,
            "Zle liczby"
        );
        addressToObstawienie[msg.sender] = _obstawienie;
        addressToMnoznik[msg.sender] = _mnoznik;
    }

    function retrieveObstawienie(address _address) public view returns (uint256) {
        return addressToObstawienie[_address];
    }

    function retrieveMnoznik(address _address) public view returns (uint256){
        return addressToMnoznik[_address];
    }

    function fund() public payable onlyOwner{
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
    }

    function bet() public payable {
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function balanceOf() external view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw(address _address) public onlyOwner {
        payable(_address).transfer(addressToAmountFunded[msg.sender]*addressToMnoznik[_address]);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}