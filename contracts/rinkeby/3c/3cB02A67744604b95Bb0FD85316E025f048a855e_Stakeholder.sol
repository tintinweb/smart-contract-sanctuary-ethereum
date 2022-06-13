// SPDX-License-Identifire: MIT

pragma solidity >=0.6.0 <0.9.0;

contract Stakeholder {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    // 1 - spadnie, 2 - wzrosnie, 3 - utrzyma sie
    uint256 obstawienie;

    constructor() public {
        owner = msg.sender;
    }

    struct Obstawienie {
        address adres;
        uint256 obstawienie;
    }
    Obstawienie[] public obstawianie;
    mapping(address => uint256) public adresToObstawienie;

    function store(uint256 _obstawienie) public {
        require(
            _obstawienie == 1 || _obstawienie == 2 || _obstawienie == 3,
            "Zle liczby"
        );
        obstawianie.push(Obstawienie(msg.sender, _obstawienie));
        adresToObstawienie[msg.sender] = _obstawienie;
    }

    function retrieve() public view returns (uint256) {
        return adresToObstawienie[msg.sender];
    }

    function fund() public payable {
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

    function withdraw(uint256 _mnoznik) public payable onlyOwner {
        msg.sender.transfer(address(this).balance * _mnoznik);

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