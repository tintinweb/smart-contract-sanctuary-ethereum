// SPDX-License-Identifire: MIT

pragma solidity >=0.6.0 <0.9.0;

contract Stakeholder {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    // 1 - spadnie, 2 - wzrosnie
    uint256 obstawianie;

    constructor() public {
        owner = msg.sender;
    }

    function store(uint256 _obstawianie) public {
        require(_obstawianie == 1 || _obstawianie == 2, "Zle liczby");
        obstawianie = _obstawianie;
    }

    function retrieve() public view returns (uint256) {
        return obstawianie;
    }

    function fund() public payable {
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "You need to spend more ETH!");
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

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

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