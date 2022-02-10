// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMinter.sol";

contract Administrated {
    address public owner;
    address public administrator;

    constructor(address initialOwner_, address initialAdmin_) {
        owner = initialOwner_;
        administrator = initialAdmin_;
    }

    event OwnershipTransfer(address oldOwner, address newOwner);
    event NewAdministrator(address caller, address newAdministrator);

    modifier onlyOwner{
        require(msg.sender == owner, "Administrated: Sender is not the owner");
        _;
    }
    
    modifier onlyAdmin{
        require(msg.sender == administrator, "Administrated: Sender is not the administrator");
        _;
    }

    function transferOwnership(address newOwner_) public onlyOwner returns (bool){
        owner = newOwner_;
        emit OwnershipTransfer(msg.sender, newOwner_);
        return true;
    }

    function changeAdministrator(address newAdministrator_) public onlyOwner returns (bool){
        require(newAdministrator_ != administrator, "Administrated: Is already the administrator");
        administrator = newAdministrator_;
        emit NewAdministrator(msg.sender, newAdministrator_);
        return true;
    }
}

contract WrigleyTicket is Administrated {
    IMinter public minter;

    bool public operational;

    string public ticketUri;

    mapping(address => bool) public hasRedeemed;

    constructor(IMinter minter_, string memory ticketUri_, address initialOwner_, address initialAdmin_)
        Administrated(initialOwner_, initialAdmin_)
    {
        minter = minter_;
        ticketUri = ticketUri_;
        operational = true;
    }

    event OperationPaused(address pausedBy);
    event OperationResumed(address resumedBy);
    event Minted(address user);

    modifier onlyWhenOperational{
        require(operational, "WrigleyTicket: Operation is paused");
        _;
    }

    function pauseOperation() public onlyAdmin onlyWhenOperational returns (bool) {
        operational = false;
        emit OperationPaused(msg.sender);
        return true;
    }

    function resumeOperation() public onlyAdmin returns (bool) {
        require(!operational, "Administrated: Is already operational");
        operational = true;
        emit OperationResumed(msg.sender);
        return true;
    }

    function claim(
        uint8 numberOfTickets_,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        public
        onlyWhenOperational
        returns (bool)
    {
        require(!hasRedeemed[msg.sender], "WrigleyTicket: Sender already redeemed ticket");

        bytes32 digest = keccak256(abi.encode(numberOfTickets_, msg.sender));

        require(_validClaim(digest, r, s, v), "WrigleyTicket: Invalid claim signature");

        require(mint_(msg.sender, numberOfTickets_), "WrigleyTicket: Minting failed");

        return true;
    }

    function _validClaim(
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        internal view
        returns (bool)
    {
        address signer = ecrecover(digest, v, r, s);
        return signer == administrator;
    }

    function mint_(address user, uint8 numberOfTickets_)
        internal
        onlyWhenOperational
        returns (bool)
    {
        for(uint8 i = 0; i < numberOfTickets_; i++){
            minter.safeMint(user, ticketUri);
        }
        hasRedeemed[user] = true;
        emit Minted(user);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IMinter {
  function safeMint(address to, string memory uri) external;
}