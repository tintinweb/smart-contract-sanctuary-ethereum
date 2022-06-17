// SPDX-License-Identifire: MIT

pragma solidity >=0.6.0 <0.9.0;

contract Stakeholder {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    // 1 - spadnie, 2 - wzrosnie, 3 - utrzyma sie
    uint256 obstawienie;
    uint256 obstawionaKwota;
    uint256 mnoznik;

    constructor() public {
        owner = msg.sender;
    }

    function store(uint256 _obstawienie, uint256 _mnoznik) public {
        require(
            _obstawienie == 1 || _obstawienie == 2 || _obstawienie == 3,
            "Zle liczby"
        );
        obstawienie = _obstawienie;
        mnoznik = _mnoznik;
    }

    function retrieve() public view returns (uint256) {
        return obstawienie;
    }

    function fund() public payable {
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
        obstawionaKwota = msg.value;
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

        // for (
        //     uint256 funderIndex = 0;
        //     funderIndex < funders.length;
        //     funderIndex++
        // ) {
        //     address funder = funders[funderIndex];
        //     addressToAmountFunded[funder] = 0;
        // }
        // funders = new address[](0);
    }
}