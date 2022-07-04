// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

contract Stakeholder {
    address public owner;

    // 1 - spadnie, 2 - wzrosnie, 3 - utrzyma sie
    mapping(address => uint256[]) public addressToAmountFunded;
    mapping(address => uint256[]) public addressToObstawienie;
    mapping(address => uint256[]) public addressToMnoznik;
    address[] public funders;

    constructor(){
        owner = msg.sender;
    }

    function storeObstawienieMnoznik(uint256 _obstawienie, uint256 _mnoznik) public{
        require(
            _obstawienie == 1 || _obstawienie == 2 || _obstawienie == 3,
            "Zle liczby"
        );
        addressToObstawienie[msg.sender].push(_obstawienie);
        addressToMnoznik[msg.sender].push(_mnoznik);
    }

    function retrieveObstawienie(address _address) public view returns (uint256) {
        return addressToObstawienie[_address][addressToObstawienie[_address].length-1];
    }

    function retrieveMnoznik(address _address) public view returns (uint256){
        return addressToMnoznik[_address][addressToMnoznik[_address].length-1];
    }

    function retrieveAmount(address _address) public view returns (uint256){
        return addressToAmountFunded[_address][addressToAmountFunded[_address].length-1];
    }

    function fund() public payable onlyOwner{
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
    }

    function bet() public payable {
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
        addressToAmountFunded[msg.sender].push(msg.value);
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
        payable(_address).transfer(retrieveAmount(_address)*retrieveMnoznik(_address));

        addressToAmountFunded[_address].pop();
        funders = new address[](0);
    }
}