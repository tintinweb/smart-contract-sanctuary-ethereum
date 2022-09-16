// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IDarkBloodStone {
    function mint(address to, uint amount) external;
}

contract StoneMinter {
    address private signer;
    address public operator;
    address public DarkBloodStone;
    bool public paused;

    // daily mints allowed
    uint public stoneDailyLimit;
    // day# => amount (minted per day)
    mapping(uint => uint) public stoneDailyMinted;
    // user => total claimed
    mapping(address => uint) public stoneUserClaimed;

    constructor(
        address _signer
    ) {
        operator = msg.sender;
        signer = _signer;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this function!");
        _;
    }

    // getters
    function getAllowedDailyMint() public view returns (uint) {
        return stoneDailyLimit - stoneDailyMinted[block.timestamp / 24 hours];
    }

    // used to add ore or change its existing daily limit
    function setDailyLimit(uint _limit) public onlyOperator {
        stoneDailyLimit = _limit;
        emit SetDailyLimit(_limit);
    }

    function mintStone(uint _amount, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(!paused, "Contract is paused!");
        // hashing amount + caller + callee + chainID
        bytes32 _hash = keccak256(abi.encodePacked(_amount, msg.sender, address(this), block.chainid));
        require(ecrecover(_hash, _v, _r, _s) == signer, "Signature is not valid!");
        uint withdrawableAmount = _amount - stoneUserClaimed[msg.sender];
        require(getAllowedDailyMint() >= withdrawableAmount, "Amounts exceeds daily minting limit");
        stoneDailyMinted[block.timestamp / 24 hours] += withdrawableAmount;
        stoneUserClaimed[msg.sender] += withdrawableAmount;
        IDarkBloodStone(DarkBloodStone).mint(msg.sender, withdrawableAmount);
    }

    function changeOperator(address _newOperator) public onlyOperator {
        operator = _newOperator;
        emit ChangeOperator(_newOperator);
    }

    function changeDBSTAddress(address _newDBST) public onlyOperator {
        DarkBloodStone = _newDBST;
    }

    function changeSigner(address _newSigner) public onlyOperator {
        signer = _newSigner;
        emit ChangeSigner(_newSigner);
    }

    function setPaused(bool _isPaused) public onlyOperator {
        paused = _isPaused;
        emit SetPaused(_isPaused);
    }

    event SetDailyLimit(uint);
    event ChangeOperator(address);
    event ChangeSigner(address);
    event SetPaused(bool);
}