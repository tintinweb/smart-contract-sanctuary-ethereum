/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Staking {

    // constants
    uint8 public constant MAX_VALIDATORS = 100;         // validators
    uint32 public constant PUBKEY_LENGTH = 48;          // public key length
    uint32 public constant SIGNATURE_LENGTH = 96;       // signature length
    uint32 public constant CREDENTIALS_LENGTH = 32;     // credentials length
    uint256 public constant DEPOSIT_AMOUNT = 32 ether;  // deposit amount

    // system info
    struct System {
        bool  enable;       // status
        address owner;      // manager
        address operator;   // operator
        address eth2;       // eth2.0 contract (0x00000000219ab540356cBB839Cbe05303d7705Fa)
        uint256 fee;        // fee 0.1
        uint256 minimum;    // deposit minimum 0.1
        uint256 deposit;    // deposit amount
        uint256 devfee;     // dev fee
    }
    System private _system;

    // events
    event OnDeposit(address indexed payer,uint256 amount,uint256 time,bool startValidator);
    event OnDepositBatch(address indexed payer,uint256 amount,uint256 fee,uint256 time,bytes pubkeys,bytes withdrawal_credentials,bytes signatures,bytes32[] deposit_data_roots);
    event OnValidatorCreated(address indexed owner,uint256 remain,uint256 time,bytes pubkey,bytes withdrawal_credential,bytes signature,bytes32 deposit_data_root);
    event OnFeeTakeOut(address indexed owner, address indexed receiver, uint256 fee);
    event OnFeeChanged(address indexed owner, uint256 fee);
    event OnStatusChanged(address indexed owner,bool status);
    event OnOwnerChanged(address indexed owner,address ownership);
    event OnOperatorChanged(address indexed owner,address operator);
    event OnMinimumChanged(address indexed owner,uint256 amount);

    // initialize
    constructor(address eth2, uint256 fee) {
        _system.fee = fee;
        _system.eth2 = eth2;
        _system.owner = msg.sender;
        _system.operator = msg.sender;
        _system.enable = true;
        _system.minimum = 1**17;
    }

    // deposit
    function deposit() external payable onlyEnable {
        require(msg.value >= _system.minimum, "The amount cannot be less than minimum");
        _system.deposit += msg.value;
         emit OnDeposit(msg.sender,msg.value,block.timestamp,_system.deposit % DEPOSIT_AMOUNT == 0);
    }

    // deposit 32eth to ETH2.0
    function depositBatch(bytes calldata pubkeys,bytes calldata withdrawal_credentials,bytes calldata signatures,bytes32[] calldata deposit_data_roots) external payable onlyEnable 
    {
        // check parameters
        require(msg.value > DEPOSIT_AMOUNT, "Invalid eth amount");
        require(pubkeys.length >= PUBKEY_LENGTH && pubkeys.length % PUBKEY_LENGTH == 0, "You should deposit at least one validator");
        require(pubkeys.length <= PUBKEY_LENGTH * MAX_VALIDATORS, "You can deposit max 100 validators at a time");
        require(signatures.length >= SIGNATURE_LENGTH && signatures.length % SIGNATURE_LENGTH == 0, "Invalid signature length");
        require(withdrawal_credentials.length == CREDENTIALS_LENGTH, "Invalid withdrawal_credentials length");

        // check signature count
        uint32 pubkeyCount = uint32(pubkeys.length / PUBKEY_LENGTH);
        require(pubkeyCount == signatures.length / SIGNATURE_LENGTH && pubkeyCount == deposit_data_roots.length, "Data count don't match");

        // check deposit amount
        uint256 amount = (_system.fee+DEPOSIT_AMOUNT) * pubkeyCount;
        require(msg.value == amount, "Amount is not aligned with pubkeys number");

        // deposit to ETH2.0 contract
        for (uint32 i = 0; i < pubkeyCount; ++i) {
            bytes memory pubkey = bytes(pubkeys[i*PUBKEY_LENGTH:(i+1)*PUBKEY_LENGTH]);
            bytes memory signature = bytes(signatures[i*SIGNATURE_LENGTH:(i+1)*SIGNATURE_LENGTH]);
            IDepositContract(_system.eth2).deposit{value: DEPOSIT_AMOUNT}(
                pubkey,
                withdrawal_credentials,
                signature,
                deposit_data_roots[i]
            );
        }

        // calculate fee
        uint256 fee = _system.fee * pubkeyCount;
        _system.devfee += fee;

        // emit event
        emit OnDepositBatch(msg.sender,DEPOSIT_AMOUNT * pubkeyCount,fee,block.timestamp,pubkeys,withdrawal_credentials,signatures,deposit_data_roots);
    }

    // create validator
    function createValidator(bytes calldata pubkey,bytes calldata withdrawal_credential,bytes calldata signature,bytes32 deposit_data_root) external onlyEnable onlyOperator {
        require(pubkey.length == PUBKEY_LENGTH, "Invalid validator public key");
        require(signature.length == SIGNATURE_LENGTH, "Invalid deposit signature");
        require(withdrawal_credential.length == CREDENTIALS_LENGTH, "Invalid withdrawal_credential length");
        require(_system.deposit >= DEPOSIT_AMOUNT, "Invalid deposit amount");
        require(address(this).balance>=_system.deposit, "Invalid balance");

        IDepositContract(_system.eth2).deposit{value: DEPOSIT_AMOUNT}(
            pubkey,
            withdrawal_credential,
            signature,
            deposit_data_root
        );

        _system.deposit -= DEPOSIT_AMOUNT;

        emit OnValidatorCreated(msg.sender,_system.deposit,block.timestamp,pubkey,withdrawal_credential,signature,deposit_data_root);
    }

    // take out fee
    function takeOutFee(address receiver) public onlyOwner {    
        require(receiver != address(0), "Invalid receiver");
        require(_system.devfee>0 && address(this).balance>=_system.devfee, "Invalid fee");
        payable(receiver).transfer(_system.devfee);
        _system.devfee = 0;
        emit OnFeeTakeOut(msg.sender,receiver,_system.devfee);
    }

    // change fee 
    function changeFee(uint256 fee) public onlyOwner {
        require(fee != _system.fee, "Fee must be different from current one");
        require(fee % 1 gwei == 0, "Fee must be a multiple of gwei");
        _system.fee = fee;
        emit OnFeeChanged(msg.sender, fee);
    }

    // change enable
    function changeEnable() public onlyOwner{
        _system.enable = !_system.enable;
        emit OnStatusChanged(msg.sender, _system.enable);
    }

    // change ownership
    function changeOwner(address owner) public onlyOwner {
        require(owner != address(0) && owner != _system.owner, "Error owner");
        _system.owner = owner;
        emit OnOwnerChanged(msg.sender, owner);
    }

    // change operator
    function changeOperator(address operator) public onlyOwner {
        require(operator != address(0) && operator != _system.operator, "Error operator");
        _system.operator = operator;
        emit OnOperatorChanged(msg.sender, operator);
    }

    // change minimum
    function changeMinimum(uint256 amount) public onlyOwner {
        _system.minimum = amount;
        emit OnMinimumChanged(msg.sender, amount);
    }

    // get system info
    function getSystemInfo() public view returns(System memory system){
        return _system;
    }

    // check owner
    modifier onlyOwner {
        require(_system.owner == msg.sender,"Error owner");
        _;
    }

    // check operator
    modifier onlyOperator {
        require(_system.operator == msg.sender,"Error operator");
        _;
    }

    // check pause
    modifier onlyEnable {
        require(_system.enable == true,"Deposit disabled");
        _;
    }
    
}


// Deposit contract interface
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}