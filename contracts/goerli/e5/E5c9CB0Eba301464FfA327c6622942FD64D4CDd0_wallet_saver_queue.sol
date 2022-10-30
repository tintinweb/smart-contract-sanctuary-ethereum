pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

import "./owner_to_wallet_saver.sol";

contract wallet_saver_queue {
    uint256 public nonce = 0;
    address public owner;

    address[] public tx_content_to;
    uint256[] public tx_content_value;
    bytes[] public tx_content_data;
    uint256[] public block_time_starts;

    uint256 time_delay;
    address panic_address;
    address[] erc20s;

    IERC20 public token;

    modifier _is_owner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        uint256 _time_delay,
        address _panic_address,
        address _owner // address owner_to_wallet_saver_address
    ) {
        owner = _owner;
        time_delay = _time_delay;
        panic_address = _panic_address;
        owner_to_wallet_saver(
            address(0xa2423108AedC829C7DD5Adb08EE12A7745D60337)
        ).add_pair(_owner, address(this));
        // erc20s = _erc20s;
    }

    function queue(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public _is_owner {
        tx_content_to.push(_to);
        tx_content_value.push(_value);
        tx_content_data.push(_data);
        block_time_starts.push(block.timestamp);
        nonce += 1;
    }

    function execute_call(uint256 _nonce) public payable _is_owner {
        require(
            block.timestamp > block_time_starts[_nonce] + time_delay,
            "You can only execute after the time delay"
        );
        (bool success, bytes memory result) = tx_content_to[_nonce].call{
            value: tx_content_value[_nonce]
        }(tx_content_data[_nonce]);
        require(success, "something went wrong - tx failed");
        delete tx_content_to[_nonce];
        delete tx_content_value[_nonce];
        delete tx_content_data[_nonce];
        delete block_time_starts[_nonce];
    }

    function revert_all_txns() public _is_owner {
        for (uint8 i; i < block_time_starts.length; i++) {
            delete tx_content_to[i];
            delete tx_content_value[i];
            delete tx_content_data[i];
            delete block_time_starts[i];
        }
    }

    function revert_this_txn(uint256 _nonce) public payable _is_owner {
        delete tx_content_to[_nonce];
        delete tx_content_value[_nonce];
        delete tx_content_data[_nonce];
        delete block_time_starts[_nonce];
    }

    function add_token(address _erc20) public _is_owner {
        erc20s.push(_erc20);
    }

    function panic() public _is_owner {
        (bool success, bytes memory result) = panic_address.call{
            value: address(this).balance
        }("");
        for (uint8 i; i < erc20s.length; i++) {
            IERC20(erc20s[i]).transfer(
                panic_address,
                IERC20(erc20s[i]).balanceOf(address(this))
            );
        }
    }

    // function change_owner(address new_owner) public _is_owner {
    //     owner = new_owner;
    // }

    receive() external payable {}
}

pragma solidity ^0.8.0;

contract owner_to_wallet_saver {
    mapping(address => address) public mapping_owner_to_wallet_saver;

    function add_pair(address owner_address, address wallet_address) public {
        mapping_owner_to_wallet_saver[owner_address] = wallet_address;
    }

    function read_mapping(address owner_address) public view returns (address) {
        return mapping_owner_to_wallet_saver[owner_address];
    }
}