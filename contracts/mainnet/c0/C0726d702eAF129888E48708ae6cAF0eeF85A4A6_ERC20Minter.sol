// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IERC20 {
    function mint(address to, uint amount) external;
}

contract ERC20Minter {
    address private signer;
    address public operator;
    address public ERC20;
    bool public paused;

    // daily mints allowed
    uint public DailyLimit;
    // day# => amount (minted per day)
    mapping(uint => uint) public DailyMinted;
    // user => total claimed
    mapping(address => uint) public UserClaimed;
    // user => nonce
    mapping(address => uint) public UserNonce;

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
        return DailyLimit - DailyMinted[block.timestamp / 24 hours];
    }

    // used to add ore or change its existing daily limit
    function setDailyLimit(uint _limit) public onlyOperator {
        DailyLimit = _limit;
        emit SetDailyLimit(_limit);
    }

    function mint(uint _amount, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(!paused, "Contract is paused!");
        // hashing amoun + nonce + caller + callee + chainID
        bytes32 _hash = keccak256(abi.encodePacked(_amount, _nonce, msg.sender, address(this), block.chainid));
        require(ecrecover(_hash, _v, _r, _s) == signer, "Signature is not valid!");
        require(_nonce == (UserNonce[msg.sender] + 1), "Invalid nonce");
        require(getAllowedDailyMint() >= _amount, "Amounts exceeds daily minting limit");
        DailyMinted[block.timestamp / 24 hours] += _amount;
        UserClaimed[msg.sender] += _amount;
        UserNonce[msg.sender] += 1;
        IERC20(ERC20).mint(msg.sender, _amount);
    }

    function changeOperator(address _newOperator) public onlyOperator {
        operator = _newOperator;
        emit ChangeOperator(_newOperator);
    }

    function changeERC20Address(address _newERC20) public onlyOperator {
        ERC20 = _newERC20;
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