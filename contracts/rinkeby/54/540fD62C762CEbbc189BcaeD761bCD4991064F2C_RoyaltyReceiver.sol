// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

contract RoyaltyReceiver {
    uint256 numPayees;
    mapping(uint256 => address) private indexer;
    mapping(address => uint256) public royaltySplit;
    mapping(address => uint256) public balances;

    string public name;

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
        require(royaltySplit[msg.sender] > 0, "not a royalty payee");
    }

    constructor(string memory _name, address[] memory payees, uint256[] memory percentages) {
        require(payees.length == percentages.length, "length mismatch");
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

        for (uint256 i = 0; i < numPayees; i++) {
            uint256 split = value/100;
            split*(royaltySplit[indexer[i]]);
            balances[indexer[i]] += split;
            value -= split;
        }

        balances[indexer[0]] += value;
    }

    function getPercentage(address _addr) public view onlyPayee() returns (uint256) {
        return royaltySplit[_addr];
    }

    function withdraw() external onlyPayee() {
        payable(msg.sender).transfer(balances[msg.sender]);
    }
}