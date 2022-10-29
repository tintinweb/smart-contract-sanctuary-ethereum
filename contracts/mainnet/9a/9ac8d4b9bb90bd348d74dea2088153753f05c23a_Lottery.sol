/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// File: Lottery.sol

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity ^0.8.7;
contract Lottery {
    event WinnerTransferSentEvent(address _from, address _destAddr, uint256 _amount);
    event WinnerindexEvent(uint256 index);

    bytes4 private constant transfer_function = bytes4(keccak256(bytes('transfer(address,uint256)')));
    
    address public owner;
    address public usdt_smart_contract_address;
    uint256 public prize_pool;
    uint256 public decimals =18;
    uint256 public generated_random_number;
    uint256 public total_lottery_participants; 

    string public participants_list_hash;
    string public participants_list_file_address;
    bool public is_participants_listed = false;

    uint256 public winner_index;
    bool public is_lottery_finished =false;

    function random_number_generator()
    public
    {
    generated_random_number = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
    )));
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _usdt_smart_contract_address) {
        owner = msg.sender;
        usdt_smart_contract_address = _usdt_smart_contract_address;
        prize_pool = (10**decimals) * 100;
    }
    function set_participants_data(string memory _participants_list_hash, string memory _participants_list_file_address,uint256 _total_lottery_participants ) public onlyOwner{
        require(!is_participants_listed,"Participants are already listed");
        participants_list_hash = _participants_list_hash;
        participants_list_file_address = _participants_list_file_address;
        total_lottery_participants = _total_lottery_participants;
        is_participants_listed = true;
    }
 
    function run_lottery() public onlyOwner {
        require(!is_lottery_finished,"Lottery is FINISHED !");
        require(is_participants_listed,"Participants are not listed yet !");
        random_number_generator();
        winner_index = generated_random_number%total_lottery_participants;
        emit WinnerindexEvent(winner_index);
        is_lottery_finished = true;
    }

    function USDT_balance() public view returns(uint256){
         IERC20 token = IERC20(usdt_smart_contract_address);
         uint256 usdt_balance = token.balanceOf(address(this));
         return usdt_balance;
    }

    function transferUSDT(address to) public  onlyOwner {
        IERC20 token = IERC20(usdt_smart_contract_address);
        uint256 usdt_balance = token.balanceOf(address(this));
        require(prize_pool <= usdt_balance,"low balance");
        (bool success, bytes memory data) = usdt_smart_contract_address.call(abi.encodeWithSelector(transfer_function, to, prize_pool));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'QPoker Lottery: TRANSFER_FAILED');
        emit WinnerTransferSentEvent(msg.sender, to, prize_pool);
    }
}