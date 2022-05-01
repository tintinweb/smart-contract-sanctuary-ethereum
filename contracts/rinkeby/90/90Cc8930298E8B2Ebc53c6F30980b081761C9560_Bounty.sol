// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bounty {
    address public owner;
    string public bounty_name;
    uint256 public bounty_amount;
    string public bounty_link;
    address public oracle;
    string public bounty_status;

    constructor(string memory _bounty_name, string memory _bounty_link) {
        owner = msg.sender;
        bounty_name = _bounty_name;
        bounty_link = _bounty_link;
        bounty_status = "OPEN";
        oracle = 0xCad1cA8abB532DcA37Bc3863F9D19A512cEc625a;
    }

    function fund_bounty() public payable {
        bounty_amount = address(this).balance;
    }

    function view_bounty()
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            string memory
        )
    {
        return (owner, bounty_name, bounty_link, bounty_amount, bounty_status);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw_bounty() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        bounty_amount = address(this).balance;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle);
        _;
    }

    function close_bounty(address _bounty_winner) public payable onlyOracle {
        payable(_bounty_winner).transfer(address(this).balance);
        bounty_amount = address(this).balance;
        bounty_status = "CLOSED";
    }
}