// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "Bounty.sol";

contract BountyFactory is Bounty {
    Bounty[] public bountyArray;

    constructor()
        Bounty("Bounty Factory Contract", "Not Applicable", 0, msg.sender)
    {}

    function createBountyContract(
        string memory _bounty_name,
        string memory _bounty_link,
        uint256 _bounty_lockup_seconds,
        address _owner_address
    ) public {
        Bounty bounty = new Bounty(
            _bounty_name,
            _bounty_link,
            _bounty_lockup_seconds,
            _owner_address
        );
        bountyArray.push(bounty);
    }

    function bfViewBounty(uint256 _bountyIndex)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            BOUNTY_STATE,
            uint256,
            uint256,
            string memory,
            address
        )
    {
        return Bounty(address(bountyArray[_bountyIndex])).view_bounty();
    }

    function bfReturnBountyAddress(uint256 _bountyIndex)
        public
        view
        returns (address)
    {
        return address(bountyArray[_bountyIndex]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Bounty {
    address public owner_address;
    address public oracle;
    address public hunter_address;
    string public hunter_github_id;
    string public bounty_name;
    string public bounty_link;
    uint256 public bounty_amount;
    uint256 bounty_creation_time;
    uint256 bounty_lockup_seconds;

    enum BOUNTY_STATE {
        OPEN,
        AWAITING_CLAIM,
        CLOSED,
        CANCELED
    }
    BOUNTY_STATE public bounty_state;

    constructor(
        string memory _bounty_name,
        string memory _bounty_link,
        uint256 _bounty_lockup_seconds,
        address _owner_address
    ) {
        owner_address = _owner_address;
        bounty_name = _bounty_name;
        bounty_link = _bounty_link;
        bounty_state = BOUNTY_STATE.OPEN;
        oracle = 0xFd1A5a86f7017E600b84087f4f0071565f42C1B7;
        bounty_creation_time = block.timestamp;
        bounty_lockup_seconds = _bounty_lockup_seconds;
    }

    function view_bounty()
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            BOUNTY_STATE,
            uint256,
            uint256,
            string memory,
            address
        )
    {
        return (
            owner_address,
            bounty_name,
            bounty_link,
            bounty_amount,
            bounty_state,
            bounty_creation_time,
            bounty_lockup_seconds,
            hunter_github_id,
            hunter_address
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner_address);
        _;
    }

    function withdraw_bounty() public payable onlyOwner {
        require(
            bounty_state == BOUNTY_STATE.OPEN,
            "This bounty is already closed."
        );
        require(
            block.timestamp > bounty_creation_time + bounty_lockup_seconds,
            "Bounties must be open for at least the lockup duration before they can be closed and have their funds withdrawn by the owner."
        );
        payable(msg.sender).transfer(address(this).balance);
        bounty_amount = address(this).balance;
        bounty_state = BOUNTY_STATE.CANCELED;
    }

    function fund_bounty() public payable onlyOwner {
        require(
            bounty_state == BOUNTY_STATE.OPEN,
            "This bounty is already closed."
        );
        bounty_amount = address(this).balance;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle);
        _;
    }

    function close_bounty(address _bounty_winner) public payable onlyOracle {
        require(
            bounty_state == BOUNTY_STATE.OPEN,
            "This bounty is already closed."
        );
        payable(_bounty_winner).transfer(address(this).balance);
        bounty_amount = address(this).balance;
        bounty_state = BOUNTY_STATE.CLOSED;
    }

    function change_hunter_github_id(string memory _hunter_github_id)
        public
        onlyOracle
    {
        require(
            bounty_state == BOUNTY_STATE.OPEN,
            "This bounty is already closed."
        );
        hunter_github_id = _hunter_github_id;
        bounty_state = BOUNTY_STATE.AWAITING_CLAIM;
    }

    function change_hunter_address(address _hunter_address) public onlyOracle {
        require(
            bounty_state == BOUNTY_STATE.AWAITING_CLAIM,
            "This bounty is either open, closed, or canceled."
        );
        hunter_address = _hunter_address;
        bounty_state = BOUNTY_STATE.CLOSED;
    }
}