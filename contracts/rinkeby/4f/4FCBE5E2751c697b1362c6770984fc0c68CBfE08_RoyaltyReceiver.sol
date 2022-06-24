// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

contract RoyaltyReceiver {
    uint256 numPayees;
    mapping(uint256 => address) private indexer;
    mapping(address => uint256) public royaltySplit;
    mapping(address => uint256) public balances;

    string public name;

//    event Value(uint256 _value);
//    event ValueOver100(uint256 _res);
//    event Allocation(uint256 _allocation);

    /**
     * @dev Throws if called by any account other than a royalty receiver/payee.
     */
    modifier onlyPayee() {
        _isPayee();
        _;
    }

    /**
     * @dev Throws if the sender is not on the royalty receiver/payee list.
     */
    function _isPayee() internal view virtual {
        require(royaltySplit[address(msg.sender)] > 0, "not a royalty payee");
    }

    constructor(string memory _name, address[] memory payees, uint256[] memory percentages) {
        require(payees.length == percentages.length, "lengths must match");
        numPayees = payees.length;
        for (uint i = 0; i < numPayees; i++) {
            indexer[i] = payees[i];
            royaltySplit[payees[i]] = percentages[i];
            balances[payees[i]] = 0;
        }
        name = _name;
    }

    receive() external payable {
        uint256 value = msg.value;
        uint256 split = value/100;
        for (uint256 i = 0; i < numPayees; i++) {
            uint256 allocation = split*(royaltySplit[indexer[i]]);
            balances[indexer[i]] += allocation;
            value -= allocation;
        }
        balances[indexer[0]] += value;
    }

    function withdraw() external onlyPayee() {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success, "Transfer failed.");
    }

    function messageSender() public view returns (address) {
        return msg.sender;
    }
}